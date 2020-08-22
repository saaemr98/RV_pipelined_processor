`define ITYPE 3'b000
`define STYPE 3'b001
`define BTYPE 3'b010
`define JTYPE 3'b011
`define UTYPE 3'b100

module imm_generator_module
    (
        input wire [31:0] instruction_in,
        input wire [2:0] imm_select,
        output reg [31:0] imm_out
    );

    always @ (*) begin
        case (imm_select)
            `ITYPE : begin
                // I
                imm_out = $signed(instruction_in [31:20]);
            end
            `STYPE : begin
                // S
                imm_out = $signed({instruction_in [31:25], instruction_in [11:7]});
            end
            `BTYPE : begin
                // B
                imm_out = $signed({instruction_in [31], instruction_in [7], instruction_in [30:25], instruction_in [11:8], 1'b0});
            end
            `JTYPE : begin
                // J
                imm_out = $signed({instruction_in [31], instruction_in [19:12], instruction_in [20], instruction_in [30:21], 1'b0});
            end
            `UTYPE : begin
                // U
                imm_out = $signed({instruction_in [31:12], {12{1'b0}}});
            end
            default : begin
                //$display ("Error: Invalid immediate type.");
            end
        endcase
    end
endmodule