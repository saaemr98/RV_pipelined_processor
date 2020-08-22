
`define BRANCH 7'b1100011
`define JAL    7'b1101111
`define JALR   7'b1100111

module jump_detect_module
    (
        input wire [31:0] rs1,
        input wire [31:0] pc_d,
        input wire [31:0] insn_d,
        input wire [31:0] pc_x,
        input wire [31:0] insn_x,
        input wire [31:0] rs1_x,
        input wire [31:0] rs2_x,
        input wire BrUn,
        input wire [31:0] wb_w,
        input wire [31:0] alu_m,
        input wire [1:0] Asel,
        input wire [1:0] Bsel,
        output reg [1:0] PC_sel,
        output reg [31:0] ret_pc
    );

    reg BrEq;
    reg BrLT;

    reg [31:0] input1;
    reg [31:0] input2;

    always @ (*) begin
        // JAL
        if (insn_d [6:0] == `JAL && (insn_x [6:0] != `BRANCH || insn_x [6:0] === 7'bxxx_xxxx)) begin
            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
            PC_sel = 2'b01;
        end
        // JALR
        else if (insn_d [6:0] == `JALR && (insn_x [6:0] != `BRANCH || insn_x [6:0] === 7'bxxx_xxxx)) begin
            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
            PC_sel = 2'b01;
        end
        // BRANCH (there maybe a unconditonal jump instruction after it, in which case the branch insn is handled first, and if condition not met then the unconditional jump is examined)
        else if (insn_x [6:0] == `BRANCH) begin
            // bypassing values of input1 and input2 into the comparator, using Asel and Bsel we can get the correct values of the input
            if (Asel == 2'b11) begin
                input1 = wb_w;
            end
            else if (Asel == 2'b10) begin
                input1 = alu_m;
            end
            else begin
                input1 = rs1_x;
            end

            if (Bsel == 2'b11) begin
                input2 = wb_w;
            end
            else if (Bsel == 2'b10) begin
                input2 = alu_m;
            end
            else begin
                input2 = rs2_x;
            end

            // Set BrEq and BrLT (Branch comparator)
            if (BrUn == 1) begin
                if (input1 < input2) begin
                    BrEq = 0;
                    BrLT = 1;
                end
                else if (input1 == input2) begin
                    BrEq = 1;
                    BrLT = 0;
                end
                else begin
                    BrEq = 0;
                    BrLT = 0;
                end                  
            end
            else begin
                if ($signed(input1) < $signed(input2)) begin
                    BrEq = 0;
                    BrLT = 1;
                end
                else if (input1 == input2) begin
                    BrEq = 1;
                    BrLT = 0;
                end
                else begin
                    BrEq = 0;
                    BrLT = 0;
                end   
            end

            // Logic setting pc select and calculating the new pc to jump to, should it be needed. If no jump required then we only need to increment pc by 4 (dont by the PC select signal)
            case (insn_x [14:12])
                3'b000 : begin
                    // BEQ
                    if (BrEq == 1 && BrLT == 0) begin
                        ret_pc = $signed(pc_x) + $signed({insn_x [31], insn_x [7], insn_x [30:25], insn_x [11:8], 1'b0});
                        PC_sel = 2'b10;
                    end
                    else begin
                        if (insn_d [6:0] == `JAL) begin
                            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
                            PC_sel = 2'b01;
                        end
                        else if (insn_d [6:0] == `JALR) begin
                            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
                            PC_sel = 2'b01;
                        end
                        else begin
                            PC_sel = 2'b00;
                        end
                    end
                end
                3'b001 : begin
                    // BNE
                    if (BrEq == 0) begin
                        ret_pc = $signed(pc_x) + $signed({insn_x [31], insn_x [7], insn_x [30:25], insn_x [11:8], 1'b0});
                        PC_sel = 2'b10;
                    end
                    else begin
                        if (insn_d [6:0] == `JAL) begin
                            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
                            PC_sel = 2'b01;
                        end
                        else if (insn_d [6:0] == `JALR) begin
                            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
                            PC_sel = 2'b01;
                        end
                        else begin
                            PC_sel = 2'b00;
                        end
                    end
                end
                3'b100 : begin
                    // BLT
                    if (BrEq == 0 && BrLT == 1) begin
                        ret_pc = $signed(pc_x) + $signed({insn_x [31], insn_x [7], insn_x [30:25], insn_x [11:8], 1'b0});
                        PC_sel = 2'b10;
                    end
                    else begin
                        if (insn_d [6:0] == `JAL) begin
                            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
                            PC_sel = 2'b01;
                        end
                        else if (insn_d [6:0] == `JALR) begin
                            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
                            PC_sel = 2'b01;
                        end
                        else begin
                            PC_sel = 2'b00;
                        end
                    end
                end
                3'b101 : begin
                    // BGE
                    if (BrLT == 0) begin
                        ret_pc = $signed(pc_x) + $signed({insn_x [31], insn_x [7], insn_x [30:25], insn_x [11:8], 1'b0});
                        PC_sel = 2'b10;
                    end
                    else begin
                        if (insn_d [6:0] == `JAL) begin
                            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
                            PC_sel = 2'b01;
                        end
                        else if (insn_d [6:0] == `JALR) begin
                            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
                            PC_sel = 2'b01;
                        end
                        else begin
                            PC_sel = 2'b00;
                        end
                    end
                end
                3'b110 : begin
                    // BLTU
                    if (BrEq == 0 && BrLT == 1) begin
                        ret_pc = $signed(pc_x) + $signed({insn_x [31], insn_x [7], insn_x [30:25], insn_x [11:8], 1'b0});
                        PC_sel = 2'b10;
                    end
                    else begin
                        if (insn_d [6:0] == `JAL) begin
                            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
                            PC_sel = 2'b01;
                        end
                        else if (insn_d [6:0] == `JALR) begin
                            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
                            PC_sel = 2'b01;
                        end
                        else begin
                            PC_sel = 2'b00;
                        end
                    end
                end
                3'b111 : begin
                    // BGEU
                    if (BrLT == 0) begin
                        ret_pc = $signed(pc_x) + $signed({insn_x [31], insn_x [7], insn_x [30:25], insn_x [11:8], 1'b0});
                        PC_sel = 2'b10;
                    end
                    else begin
                        if (insn_d [6:0] == `JAL) begin
                            ret_pc = $signed(pc_d) + $signed({insn_d [31], insn_d [19:12], insn_d [20], insn_d [30:21], 1'b0});
                            PC_sel = 2'b01;
                        end
                        else if (insn_d [6:0] == `JALR) begin
                            ret_pc = $signed(insn_d [31:20]) + $signed(rs1);
                            PC_sel = 2'b01;
                        end
                        else begin
                            PC_sel = 2'b00;
                        end
                    end
                end
                default : begin
                    PC_sel = 2'b00;
                    $display("Error: PCsel could not be driven due to incorrect instruction");
                end
            endcase 
        end
        else begin
            PC_sel = 2'b00;
        end
    end
endmodule