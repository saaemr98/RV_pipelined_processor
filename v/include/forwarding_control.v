`define LUI    7'b0110111
`define AUIPC  7'b0010111
`define JAL    7'b1101111
`define JALR   7'b1100111
`define BRANCH 7'b1100011
`define LOAD   7'b0000011
`define STORE  7'b0100011
`define IMM    7'b0010011
`define REG    7'b0110011

module forwarding_control_module
    (
        input wire [31:0] insn_d,
        input wire [31:0] insn_x,
        input wire [31:0] insn_m,
        output reg [1:0] Asel,
        output reg [1:0] Bsel,
        output reg dmemW_sel
    );

    always @ (*) begin
        // Asel
        // Both Asel and Bsel will be read by the ALU module
        // mx by passing 
        // check if there is a valid rs1 in D and rd in X insns and then see if they are the same, if so mx bypass.
        if ((insn_d [6:0] == `BRANCH ||
            insn_d [6:0] == `LOAD    ||
            insn_d [6:0] == `STORE   ||
            insn_d [6:0] == `IMM     ||
            insn_d [6:0] == `REG)    &&
            (insn_x [6:0] == `LUI    ||
            insn_x [6:0] == `AUIPC   ||
            insn_x [6:0] == `JAL     ||
            insn_x [6:0] == `JALR    ||
            insn_x [6:0] == `IMM     ||
            insn_x [6:0] == `REG)    &&
            insn_x [11:7] != 0       &&
            insn_d [19:15] == insn_x [11:7]) begin
            Asel = 2'b10;
        end
        // wx by passing by checking if rs2 in D and rd in M are the same
        else if ((insn_d [6:0] == `BRANCH ||
                insn_d [6:0] == `LOAD     ||
                insn_d [6:0] == `STORE    ||
                insn_d [6:0] == `IMM      ||
                insn_d [6:0] == `REG)     &&
                (insn_m [6:0] == `LUI     ||
                insn_m [6:0] == `AUIPC    ||
                insn_m [6:0] == `JAL      ||
                insn_m [6:0] == `JALR     ||
                insn_m [6:0] == `LOAD     ||
                insn_m [6:0] == `IMM      ||
                insn_m [6:0] == `REG)     &&
                insn_m [11:7] != 0        &&
                insn_d [19:15] == insn_m [11:7]) begin
            Asel = 2'b11;
        end
        // If bypassing is not needed for Asel then give it regular logic
        else begin
            case (insn_d [6:0])
                `AUIPC  : Asel = 2'b01;
                `JAL    : Asel = 2'b01;
                `JALR   : Asel = 2'b00;
                `BRANCH : Asel = 2'b01;
                `LOAD   : Asel = 2'b00;
                `STORE  : Asel = 2'b00;
                `IMM    : Asel = 2'b00;
                `REG    : Asel = 2'b00;
            endcase
        end

        // Bsel mx bypassing
        if ((insn_d [6:0] == `BRANCH ||
            insn_d [6:0] == `REG)    &&
            (insn_x [6:0] == `LUI    ||
            insn_x [6:0] == `AUIPC   ||
            insn_x [6:0] == `JAL     ||
            insn_x [6:0] == `JALR    ||
            insn_x [6:0] == `IMM     ||
            insn_x [6:0] == `REG)    &&
            insn_x [11:7] != 0       &&
            insn_d [24:20] == insn_x [11:7]) begin
            Bsel = 2'b10;
        end
        // Bsel wx by passing
        else if ((insn_d [6:0] == `BRANCH ||
                insn_d [6:0] == `REG)     &&
                (insn_m [6:0] == `LUI     ||
                insn_m [6:0] == `AUIPC    ||
                insn_m [6:0] == `JAL      ||
                insn_m [6:0] == `JALR     ||
                insn_m [6:0] == `LOAD     ||
                insn_m [6:0] == `IMM      ||
                insn_m [6:0] == `REG)     &&
                insn_m [11:7] != 0        &&
                insn_d [24:20] == insn_m [11:7]) begin
            Bsel = 2'b11;
        end
        // Bsel regular select signals
        else begin
            case (insn_d [6:0])
                `LUI    : Bsel = 2'b01;
                `AUIPC  : Bsel = 2'b01;
                `JAL    : Bsel = 2'b01;
                `JALR   : Bsel = 2'b01;
                `BRANCH : Bsel = 2'b01;
                `LOAD   : Bsel = 2'b01;
                `STORE  : Bsel = 2'b01;
                `IMM    : Bsel = 2'b01;
                `REG    : Bsel = 2'b00;
            endcase
        end   

        // wm bypass sets another signal on, this will be read by the data memory
        if ((insn_d [6:0] == `STORE)  &&
            (insn_x [6:0] == `LUI     ||
            insn_x [6:0] == `AUIPC    ||
            insn_x [6:0] == `JAL      ||
            insn_x [6:0] == `JALR     ||
            insn_x [6:0] == `LOAD     ||
            insn_x [6:0] == `IMM      ||
            insn_x [6:0] == `REG)     &&
            insn_x [11:7] != 0        &&
            insn_d [24:20] == insn_x [11:7]) begin
            dmemW_sel = 1'b1;
        end
        else begin
            dmemW_sel = 1'b0;
        end
    end
endmodule