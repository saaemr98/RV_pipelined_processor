`include "include/decoder_module.v"
`include "include/memory_module.v"
`include "include/register_file_module.v"
`include "include/imm_generator_module.v"
`include "include/ALU_module.v"
`include "include/data_memory_module.v"
`include "include/writeback_module.v"
`include "include/forwarding_control.v"
`include "include/stall_detect_module.v"
`include "include/jump_detect_module.v"


`define INIT_PROGRAM_CNTR 32'h0100_0000

module dut;
    reg [31:0] program_cntr; 
    reg [31:0] data_in; 
    reg read_write;
    reg clock = 1;
    wire [31:0] data_out;

    // Program counter control signals
    wire PCsel;
    wire [1:0] PC_sel; // for program counter control (jumping etc.)

    // Register File control signals
    wire [4:0] addr_rs1;
    wire [4:0] addr_rs2;
    wire [4:0] addr_rd;
    wire [31:0] data_rd;
    wire [31:0] data_rs1;
    wire [31:0] data_rs2;

    // Immediate generator control signals
    wire [2:0] imm_select;
    wire [31:0] immediate;

    // ALU signals
    wire [31:0] ALUout;

    // Control signals
    wire RegWEn;
    wire [1:0] Asel;
    wire [1:0] Bsel;
    wire [3:0] ALUsel;
    wire BrUn;

    // Writeback control
    wire [1:0] WBsel;

    // Data Memory controls
    wire dmem_RW;
    wire [31:0] dmem_out;
    wire [1:0] access_size;
    wire load_s;

    integer lines;
    integer file;
    integer insn;

    // WM bypass select
    wire dmemRW_sel;

    // pipelining registers
    reg [31:0] pc_f;
    reg [31:0] pc_d;
    reg [31:0] pc_x;
    reg [31:0] pc_m;

    reg [31:0] insn_d;
    reg [31:0] insn_x;

    reg [31:0] rs1_x;
    reg [31:0] rs2_x;

    reg [31:0] alu_m;
    reg [31:0] rs2_m;
    reg [31:0] insn_m;

    reg [31:0] wb_w;
    reg [31:0] insn_w;

    // pipelining control registers
    reg RegWEn_x;
    reg RegWEn_m;
    reg RegWEn_w;

    reg [2:0] imm_select_x;

    reg [1:0] Asel_x;
    reg [1:0] Bsel_x;

    reg [3:0] ALUsel_x;

    reg dmem_RW_x;
    reg dmem_RW_m;

    reg load_s_x;
    reg load_s_m;

    reg access_size_x;
    reg access_size_m;

    reg [1:0] WBsel_x;
    reg [1:0] WBsel_m;

    reg dmem_W_sel_x;
    reg dmem_W_sel_m;

    reg BrUn_x;

    // hazard control
    wire insn_x_sel;
    wire reg_W_disable;
    reg insn_x_sel_hold;
    reg reg_W_disable_hold;

    // Jumping 
    wire [31:0] ret_pc;

    wire print_out;

    initial begin
        $dumpfile("SimpleAdd.vcd");
        $dumpvars(0, dut);
        $dumpvars(0, insn_memory);
        $dumpvars(0, decoder);
        $dumpvars(0, register_file);
        $dumpvars(0, imm_generator);
        $dumpvars(0, alu);
        $dumpvars(0, writeback);
        $dumpvars(0, data_memory);
        $dumpvars(0, forwarding_control);
        $dumpvars(0, stall_detect);
        $dumpvars(0, jump_detect);

        read_write = 1;
        pc_f = `INIT_PROGRAM_CNTR;

        file = $fopen(`X_FILE, "r");
        lines = 0;
        while ($fscanf(file, "%h", insn) == 1) begin 
            lines = lines + 1;
        end
    end

    // This is the instruction memory module
    memory_module insn_memory (.clock(clock), .address(pc_f), .data_in(data_in), .data_out(data_out), .read_write(read_write));
    
    // This is the decoder module
    decoder_module decoder (.clock(clock), .instruction_in(insn_d), .rs1(addr_rs1), .rs2(addr_rs2), .rd(addr_rd), .imm_sel(imm_select), .ALUsel(ALUsel), .BrUn(BrUn), .RegWEn(RegWEn), .WBsel(WBsel), .dmem_RW(dmem_RW), .load_s(load_s), .access_size(access_size));
    
    // This is the register file module
    register_file_module register_file (.clock(clock), .addr_rs1(addr_rs1), .addr_rs2(addr_rs2), .addr_rd(insn_w), .data_rd(wb_w), .data_rs1(data_rs1), .data_rs2(data_rs2), .write_enable(RegWEn_w), .print_out(print_out));
    
    // This is a jump detect module (detects is a jump is needed and handles pc)
    jump_detect_module jump_detect (.rs1(data_rs1), .pc_d(pc_d), .insn_d(insn_d), .pc_x(pc_x), .insn_x(insn_x), .rs1_x(rs1_x), .rs2_x(rs2_x), .BrUn(BrUn_x), .wb_w(wb_w), .alu_m(alu_m), .Asel(Asel_x), .Bsel(Bsel_x), .PC_sel(PC_sel), .ret_pc(ret_pc));

    // This is the immediate generator module
    imm_generator_module imm_generator (.instruction_in(insn_x), .imm_select(imm_select_x), .imm_out(immediate));
    
    // This is the ALU module
    ALU_module alu (.dataA(rs1_x), .program_cntr(pc_x), .dataB(rs2_x), .imm(immediate), .alu_m(alu_m), .wb_w(wb_w), .Asel(Asel_x), .Bsel(Bsel_x), .ALUsel(ALUsel_x), .ALUout(ALUout));

    // This is the data memory module
    data_memory_module data_memory (.clock(clock), .address(alu_m), .rs2_m(rs2_m), .load_s(load_s_m), .access_size(access_size), .wb_w(wb_w), .dataW_sel(dmem_W_sel_m), .data_out(dmem_out), .read_write(dmem_RW_m), .print_out(print_out));

    // This is the writeback logic control module
    writeback_module writeback (.data_r(dmem_out), .ALUout(alu_m), .pc_m(pc_m), .WBsel(WBsel_m), .data_rd(data_rd));

    // This is the forwarding/bypassing control module
    forwarding_control_module forwarding_control (.insn_d(insn_d), .insn_x(insn_x), .insn_m(insn_m), .Asel(Asel), .Bsel(Bsel), .dmemW_sel(dmemW_sel));

    // This is the stall detection module (detects if a stall is needed)
    stall_detect_module stall_detect (.insn_d(insn_d), .insn_x(insn_x), .insn_m(insn_m), .insn_w(insn_w), .insn_x_sel(insn_x_sel), .reg_W_disable(reg_W_disable));

    always @ (posedge clock) begin
        // These values below give info on whether stall is needed
        // Since these values need to be found and used within the same cycle they are blocking assignments
        insn_x_sel_hold = insn_x_sel;
        reg_W_disable_hold = reg_W_disable;

        // f/d and d/x stages combined

        // Check for stall
        if (reg_W_disable_hold != 1 || reg_W_disable_hold === 1'bx) begin
            // No stall needed
            // conditional jump
            if (PC_sel == 2'b10) begin
                // For conditonal jumps we need to insert two nops in both the instruction registers at the X and D stage
                pc_f <= ret_pc;
                pc_d <= pc_f;
                insn_d <= 32'h0000_0013;

                pc_x <= pc_d;
                rs2_x <= data_rs2;
                BrUn_x <= BrUn;

                insn_x <= 32'h0000_0013;
                rs1_x <= 32'h0000_0000;

                // setting control signals for the nop insn.
                RegWEn_x <= 1;
                imm_select_x <= 3'b000;
                Asel_x <= 2'b00;
                Bsel_x <= 2'b01;
                ALUsel_x <= 4'b0000;
                dmem_RW_x <= 1;
                WBsel_x <= 1;
            end
            // unconditional_jump
            else if (PC_sel == 2'b01) begin
                // For unconditional jumps we need to insert a nop in the instruction register at the D stage
                pc_f <= ret_pc;
                pc_d <= pc_f;
                insn_d <= 32'h0000_0013;
                
                // Move instructions through the d/x pipeline
                pc_x <= pc_d;
                rs2_x <= data_rs2;
                BrUn_x <= BrUn;
                insn_x <= insn_d;
                rs1_x <= data_rs1;

                // logic for d/x transfer
                RegWEn_x <= RegWEn;
                imm_select_x <= imm_select;
                Asel_x <= Asel;
                Bsel_x <= Bsel;
                dmem_W_sel_x <= dmemW_sel;
                ALUsel_x <= ALUsel;
                load_s_x <= load_s;
                access_size_x <= access_size;
                dmem_RW_x <= dmem_RW;
                WBsel_x <= WBsel;
                //end
            end
            // increment pc by 4 (regular case)
            else begin
                pc_f <= pc_f + 4;
                pc_d <= pc_f;
                insn_d <= data_out;

                // Move instructions through the d/x pipeline
                pc_x <= pc_d;
                rs2_x <= data_rs2;
                BrUn_x <= BrUn;
                insn_x <= insn_d;
                rs1_x <= data_rs1;

                // logic for d/x transfer
                RegWEn_x <= RegWEn;
                imm_select_x <= imm_select;
                Asel_x <= Asel;
                Bsel_x <= Bsel;
                dmem_W_sel_x <= dmemW_sel;
                ALUsel_x <= ALUsel;
                load_s_x <= load_s;
                access_size_x <= access_size;
                dmem_RW_x <= dmem_RW;
                WBsel_x <= WBsel;
            end
        end
        else begin

            pc_x <= pc_d;
            rs2_x <= data_rs2;
            BrUn_x <= BrUn;

            if (insn_x_sel_hold == 0) begin
                // Stall needed
                // insert nop along with necessary control logic
                insn_x <= 32'h0000_0013;
                rs1_x <= 32'h0000_0000;

                RegWEn_x <= 1;
                imm_select_x <= 3'b000;
                Asel_x <= 2'b00;
                Bsel_x <= 2'b01;
                ALUsel_x <= 4'b0000;
                dmem_RW_x <= 1;
                WBsel_x <= 1;
            end
            else begin
                insn_x <= insn_d;
                rs1_x <= data_rs1;

                RegWEn_x <= RegWEn;
                imm_select_x <= imm_select;
                Asel_x <= Asel;
                Bsel_x <= Bsel;
                dmem_W_sel_x <= dmemW_sel;
                ALUsel_x <= ALUsel;
                load_s_x <= load_s;
                access_size_x <= access_size;
                dmem_RW_x <= dmem_RW;
                WBsel_x <= WBsel;
            end
        end
        
        // m/x stage
        pc_m <= pc_x;
        alu_m <= ALUout;
        rs2_m <= rs2_x;
        insn_m <= insn_x;

        // m/x control logic transfer
        RegWEn_m <= RegWEn_x;
        dmem_W_sel_m <= dmem_W_sel_x;
        load_s_m <= load_s_x;
        access_size_m <= access_size_x;
        dmem_RW_m <= dmem_RW_x;
        WBsel_m <= WBsel_x;

        // w/m stage
        wb_w <= data_rd;
        insn_w <= insn_m;

        // w/m control logic transfer
        RegWEn_w <= RegWEn_m;
    end

    always @ (posedge clock) begin
        //$display ("------------------------------------------------------------------------------");
        //$display ("insn_d: %h, insn_x: %h, insn_m: %h, insn_w: %h", insn_d, insn_x, insn_m, insn_w);
        $display ("pc_f: %h", pc_f);
        //$display ("alu_m: %h, rs2_m: %h, dmemRW: %h, wb_w: %h, dmem_sel_m: %h, Aselx: %h, Bselx: %h", alu_m, rs2_m, dmem_RW_m, wb_w, dmem_W_sel_m, Asel_x, Bsel_x);
        //$display ("PC_sel: %h, Asel: %b, Bsel: %b", PC_sel, Asel, Bsel);
        //$display ("Asel_X: %h, Bsel_X: %h", rs1_x, immediate);
    end

    always begin
        #5 clock = ~clock;
    end 
endmodule