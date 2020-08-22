`define LUI    7'b0110111
`define AUIPC  7'b0010111
`define JAL    7'b1101111
`define JALR   7'b1100111
`define BRANCH 7'b1100011
`define LOAD   7'b0000011
`define STORE  7'b0100011
`define IMM    7'b0010011
`define REG    7'b0110011

module stall_detect_module
    (
        input wire [31:0] insn_d,
        input wire [31:0] insn_x,
        input wire [31:0] insn_m,
        input wire [31:0] insn_w,
        output reg insn_x_sel,
        output reg reg_W_disable
    );

    always @ (*) begin
        // load use stall
        if ((insn_x [6:0] == `LOAD   &&
            (((insn_d [6:0] == `JALR ||
            insn_d [6:0] == `BRANCH  ||
            insn_d [6:0] == `LOAD    ||
            insn_d [6:0] == `STORE   ||
            insn_d [6:0] == `IMM     ||
            insn_d [6:0] == `REG)    &&
            (insn_d [19:15] == insn_x [11:7])) ||
            ((insn_d [6:0] == `BRANCH ||
            insn_d [6:0] == `REG)    &&
            (insn_d [24:20] == insn_x [11:7]))))&&
            insn_x [11:7] != 0) begin
            insn_x_sel = 0;
            reg_W_disable = 1;
        end
        // if decode stage needs a register in the W stage we need a cycle stall as we cannot bypass into decode stage
        else if (((insn_w [6:0] == `LUI ||
                insn_w [6:0] == `AUIPC  ||
                insn_w [6:0] == `JAL    ||
                insn_w [6:0] == `JALR   ||
                insn_w [6:0] == `LOAD   ||
                insn_w [6:0] == `IMM    ||
                insn_w [6:0] == `REG)   &&
                (((insn_d [6:0] == `JALR  ||
                insn_d [6:0] == `BRANCH ||
                insn_d [6:0] == `LOAD   ||
                insn_d [6:0] == `STORE  ||
                insn_d [6:0] == `IMM    ||
                insn_d [6:0] == `REG)   &&
                (insn_d [19:15] == insn_w [11:7])) ||
                ((insn_d [6:0] == `BRANCH ||
                insn_d [6:0] == `STORE   ||
                insn_d [6:0] == `REG)    &&
                (insn_d [24:20] == insn_w [11:7]))))&&
                insn_w [11:7] != 0) begin
            insn_x_sel = 0;
            reg_W_disable = 1;
        end
        // case where jalr relies on value from memory stage, it will have to be stalled.
        else if (((insn_m [6:0] == `LUI ||
                insn_m [6:0] == `AUIPC  ||
                insn_m [6:0] == `JAL    ||
                insn_m [6:0] == `JALR   ||
                insn_m [6:0] == `LOAD   ||
                insn_m [6:0] == `IMM    ||
                insn_m [6:0] == `REG)   &&
                (insn_d [6:0] == `JALR)) &&
                insn_m [11:7] != 0) begin
            insn_x_sel = 0;
            reg_W_disable = 1;
        end
        // case where store would need to be stalled, as it's address relies on a value in memory stage, cannot bypass to decode stage
        else if ((((insn_m [6:0] == `LUI ||
                insn_m [6:0] == `AUIPC  ||
                insn_m [6:0] == `JAL    ||
                insn_m [6:0] == `JALR   ||
                insn_m [6:0] == `LOAD   ||
                insn_m [6:0] == `IMM    ||
                insn_m [6:0] == `REG)   &&
                (insn_d [6:0] == `STORE)) &&
                (insn_d [24:20] == insn_m [11:7])) &&
                insn_m [11:7] != 0) begin
            insn_x_sel = 0;
            reg_W_disable = 1;            
        end
        else begin
            // Signals for no stalls
            insn_x_sel = 1;
            reg_W_disable = 0;
        end
    end
endmodule