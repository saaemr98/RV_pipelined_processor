// ALU selects
`define ADD 4'b0000
`define SUB 4'b0001
`define SLL 4'b0010
`define SLT 4'b0011
`define SLTU 4'b0100
`define XOR 4'b0101
`define SRL 4'b0110
`define SRA 4'b0111
`define OR 4'b1000
`define AND 4'b1001
`define B 4'b1010

// Immediate selects
`define ITYPE 3'b000
`define STYPE 3'b001
`define BTYPE 3'b010
`define JTYPE 3'b011
`define UTYPE 3'b100

// Access size
`define word 2'b00
`define half_word 2'b01
`define byte 2'b10

module decoder_module
    (
        input wire clock,
        input wire [31:0] instruction_in,
        output reg [4:0] rs1,
        output reg [4:0] rs2,
        output reg [4:0] rd,
        output reg PCsel,
        output reg [1:0] Asel,
        output reg [1:0] Bsel,
        output reg [2:0] imm_sel,
        output reg [3:0] ALUsel,
        output reg BrUn,
        output reg RegWEn,
        output reg [1:0] WBsel,
        output reg dmem_RW,
        output reg load_s,
        output reg [1:0] access_size
    );

    reg [11:0] l_imm;
    reg [19:0] u_imm;
    reg [12:0] l_intermediate;
    reg [20:0] u_intermediate;
    reg [5:0] shamt;

    always @ (*) begin 
        case (instruction_in [6:0])
            7'b0110011 : begin
                // R-type
                rd = instruction_in [11:7];
                rs1 = instruction_in [19:15];
                rs2 = instruction_in [24:20];

                Asel = 2'b00;
                Bsel = 2'b00;
                WBsel = 2'b01;
                dmem_RW = 1;

                case ({instruction_in [31:25], instruction_in [14:12]})
                    10'b00_0000_0000 : begin
                        // $write ("opcode: ADD");
                        ALUsel = `ADD;
                        RegWEn = 1;
                    end
                    10'b01_0000_0000 : begin
                        // $write ("opcode: SUB");
                        ALUsel = `SUB;
                        RegWEn = 1;
                    end
                    10'b00_0000_0001 : begin
                        // $write ("opcode: SLL");
                        ALUsel = `SLL;
                        RegWEn = 1;
                    end
                    10'b00_0000_0010 : begin
                        // $write ("opcode: SLT");
                        ALUsel = `SLT;
                        RegWEn = 1;
                    end
                    10'b00_0000_0011 : begin
                        // $write ("opcode: SLTU");
                        ALUsel = `SLTU;
                        RegWEn = 1;
                    end
                    10'b00_0000_0100 : begin
                        // $write ("opcode: XOR");
                        ALUsel = `XOR;
                        RegWEn = 1;
                    end
                    10'b00_0000_0101 : begin
                        // $write ("opcode: SRL");
                        ALUsel = `SRL;
                        RegWEn = 1;
                    end
                    10'b01_0000_0101 : begin
                        // $write ("opcode: SRA");
                        ALUsel = `SRA;
                        RegWEn = 1;
                    end
                    10'b00_0000_0110 : begin
                        // $write ("opcode: OR");
                        ALUsel = `OR;
                        RegWEn = 1;
                    end
                    10'b00_0000_0111 : begin
                        // $write ("opcode: AND");
                        ALUsel = `AND;
                        RegWEn = 1;
                    end
                    default : begin
                        // $display("Error: Instruction not found.");
                        RegWEn = 0;
                    end
                endcase
                // $display (" rd:x%0d, rs1:x%0d, rs2:x%0d", rd, rs1, rs2);
            end
            7'b0010011 : begin
                // I-type immediate
                rd = instruction_in [11:7];
                rs1 = instruction_in [19:15];

                imm_sel = `ITYPE;
                Asel = 2'b00;
                Bsel = 2'b01;
                WBsel = 2'b01;
                dmem_RW = 1;

                if (instruction_in [14:12] == 3'b001 || instruction_in [14:12] == 3'b101) begin
                    shamt = instruction_in [24:20];

                    case (instruction_in [14:12])
                        3'b001 : begin 
                            // $write ("opcode: SLLI");
                            ALUsel = `SLL;
                            RegWEn = 1;
                        end
                        3'b101 : begin
                            case (instruction_in [31:25])
                                7'b000_0000 : begin
                                    // $write ("opcode: SRLI");
                                    ALUsel = `SRL;
                                    RegWEn = 1;
                                end
                                7'b010_0000 : begin
                                    // $write ("opcode: SRAI");
                                    ALUsel = `SRA;
                                    RegWEn = 1;
                                end
                                default : begin
                                    // $display("Error: Instruction not found.");
                                    RegWEn = 0;
                                end
                            endcase
                        end
                        default : begin
                            // $display("Error: Instruction not found.");
                            RegWEn = 0;
                        end
                    endcase
                    // $display (" rd:x%0d, rs1:x%0d, shamt:%0d", rd, rs1, shamt);
                end
                else begin
                    l_imm = instruction_in [31:20];

                    case (instruction_in [14:12])
                        3'b000 : begin
                            // $write ("opcode: ADDI");
                            ALUsel = `ADD;
                            RegWEn = 1;
                        end
                        3'b010 : begin
                            // $write ("opcode: SLTI");
                            ALUsel = `SLT;
                            RegWEn = 1;
                        end
                        3'b011 : begin
                            // $write ("opcode: SLTIU");
                            ALUsel = `SLTU;
                            RegWEn = 1;
                        end
                        3'b100 : begin
                            // $write ("opcode: XORI");
                            ALUsel = `XOR;
                            RegWEn = 1;
                        end
                        3'b110 : begin
                            // $write ("opcode: ORI");
                            ALUsel = `OR;
                            RegWEn = 1;
                        end
                        3'b111 : begin
                            // $write ("opcode: ANDI");
                            ALUsel = `AND;
                            RegWEn = 1;
                        end
                        default : begin
                            // $display("Error: Instruction not found.");
                        end
                    endcase
                    // $display (" rd:x%0d, rs1:x%0d, imm:%0d", rd, rs1, $signed(l_imm));
                end
            end
            7'b1110011 : begin
                // I-type ECALL
                dmem_RW = 1;
                RegWEn = 0;

                if (instruction_in [31:7] == 25'b0_0000_0000_0000_0000_0000_0000) begin
                    // $display ("opcode: ECALL");
                    $finish;
                end
                else begin
                    // $display("Error: Instruction not found.");
                end
            end
            7'b0000011 : begin
                // I-type load
                rd = instruction_in [11:7];
                rs1 = instruction_in [19:15];
                l_imm = instruction_in [31:20];
                
                Asel = 2'b00;
                Bsel = 2'b01;
                imm_sel = `ITYPE;
                ALUsel = `ADD;
                dmem_RW = 1;
                WBsel = 2'b00;

                case (instruction_in [14:12])
                    3'b000 : begin
                        // $write ("opcode: LB");
                        RegWEn = 1;
                        load_s = 1;
                        access_size = `byte;
                    end
                    3'b001 : begin
                        // $write ("opcode: LH");
                        RegWEn = 1;
                        load_s = 1;
                        access_size = `half_word;
                    end
                    3'b010 : begin
                        // $write ("opcode: LW");
                        RegWEn = 1;
                        load_s = 1;
                        access_size = `word;
                    end
                    3'b100 : begin
                        // $write ("opcode: LBU");
                        RegWEn = 1;
                        load_s = 0;
                        access_size = `byte;
                    end
                    3'b101 : begin
                        // $write ("opcode: LHU");
                        RegWEn = 1;
                        load_s = 0;
                        access_size = `half_word;
                    end
                    default : begin
                        // $display("Error: Instruction not found.");
                        RegWEn = 0;
                    end
                endcase
                // $display (" rd:x%0d, imm:%0d, rs1:x%0d", rd, $signed(l_imm), rs1);
            end
            7'b0100011 : begin
                // S-type
                l_imm = {instruction_in [31:25], instruction_in [11:7]};
                rs1 = instruction_in [19:15];
                rs2 = instruction_in [24:20];

                Asel = 2'b00;
                Bsel = 2'b01;
                imm_sel = `STYPE;
                ALUsel = `ADD;
                RegWEn = 0;

                case (instruction_in [14:12])
                    3'b000 : begin
                        // $write ("opcode: SB");
                        dmem_RW = 0;
                        access_size = `byte;
                    end
                    3'b001 : begin
                        // $write ("opcode: SH");
                        dmem_RW = 0;
                        access_size = `half_word;
                    end
                    3'b010 : begin
                        // $write ("opcode: SW");
                        dmem_RW = 0;
                        access_size = `word;
                    end
                    default : begin
                        // $display("Error: Instruction not found.");
                        dmem_RW = 1;
                    end
                endcase

                // $display (" rs2:x%0d, imm:%0d, rs1:x%0d", rs2, $signed(l_imm), rs1);
            end
            7'b0110111 : begin
                // U-type LUI
                u_imm = instruction_in [31:12];
                rd = instruction_in [11:7];
                RegWEn = 1;
                imm_sel = `UTYPE;
                ALUsel = `B;
                Bsel = 2'b01;
                dmem_RW = 1;
                WBsel = 2'b01;

                // $display ("opcode: LUI rd:x%0d, imm:%0d", rd, $signed(u_imm));
            end
            7'b0010111 : begin
                // U-type AUIPC
                u_imm = instruction_in [31:12];
                rd = instruction_in [11:7];
                RegWEn = 1;
                imm_sel = `UTYPE;
                ALUsel = `ADD;
                Asel = 2'b01;
                Bsel = 2'b01;
                WBsel = 2'b01;
                dmem_RW = 1;

                // $display ("opcode: AUIPC rd:x%0d, imm:%0d", rd, $signed(u_imm));
            end
            7'b1100011 : begin
                // B-type
                rs1 = instruction_in [19:15];
                rs2 = instruction_in [24:20];
                l_imm = {instruction_in [31], instruction_in [7], instruction_in [30:25], instruction_in [11:8]};
                l_intermediate = {l_imm, 1'b0};

                ALUsel = `ADD;
                imm_sel = `BTYPE;
                Asel = 2'b01;
                Bsel = 2'b01;
                RegWEn = 0;
                dmem_RW = 1;

                case (instruction_in [14:12])
                    3'b000 : begin
                        // $write ("opcode: BEQ");
                        BrUn = 0;
                    end
                    3'b001 : begin
                        // $write ("opcode: BNE");
                        BrUn = 0;
                    end
                    3'b100 : begin
                        // $write ("opcode: BLT");
                        BrUn = 0; 
                    end
                    3'b101 : begin
                        // $write ("opcode: BGE");
                        BrUn = 0; 
                    end
                    3'b110 : begin
                        // $write ("opcode: BLTU");
                        BrUn = 1;
                    end
                    3'b111 : begin
                        // $write ("opcode: BGEU");
                        BrUn = 1;
                    end
                    default : begin
                        // $display("Error: Instruction not found.");
                    end
                endcase
                // $display (" rs1:x%0d, rs2:x%0d, imm:%0d", rs1, rs2, $signed(l_intermediate)); 
            end
            7'b1100111 : begin
                // J-type JALR
                rd = instruction_in [11:7];
                rs1 = instruction_in [19:15];
                l_imm = instruction_in [31:20];

                ALUsel = `ADD;
                imm_sel = `ITYPE;
                Asel = 2'b00;
                Bsel = 2'b01;
                dmem_RW = 1;
                WBsel = 2'b10;

                if (instruction_in [14:12] == 3'b000) begin
                    // $write ("opcode: JALR");
                    RegWEn = 1;
                end
                else begin 
                    // $display("Error: Instruction not found.");
                    RegWEn = 0;
                end

                // $display (" rd:x%0d, rs1:x%0d, imm:%0d", rd, rs1, $signed(l_imm));
            end
            7'b1101111 :begin
                // J-type JAL
                rd = instruction_in [11:7];
                u_imm = {instruction_in [31], instruction_in [19:12], instruction_in [20], instruction_in [30:21]};
                u_intermediate = {u_imm, 1'b0};

                RegWEn = 1;
                ALUsel = `ADD;
                imm_sel = `JTYPE;
                Asel = 2'b01;
                Bsel = 2'b01;
                dmem_RW = 1;
                WBsel = 2'b10;

                // $display("opcode: JAL rd:x%0d, imm:%0d", rd, $signed(u_intermediate));
            end
            7'b0001111 : begin
                dmem_RW = 1;
                RegWEn = 0;

                if ({instruction_in [31:28], instruction_in [19:7]} == {17{1'b0}}) begin
                    // $display ("opcode: FENCE pred:%0h, suc:%0h", instruction_in [27:24], instruction_in [23:20]);
                    
                end
                else begin
                    // $display("Error: Instruction not found.");
                end
            end
            default : begin
                // No type found
                // $display("Error: Instruction not found.");
            end
        endcase
    end
endmodule