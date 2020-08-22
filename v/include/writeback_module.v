
module writeback_module
    (
        input wire [31:0] data_r,
        input wire [31:0] ALUout,
        input wire [31:0] pc_m,
        input wire [1:0] WBsel,
        output reg [31:0] data_rd
    );

    // This logic determines which value gets written to the reister file. This is done using the select signal
    always @ (*) begin
        if (WBsel == 2'b00) begin
            data_rd = data_r;           
        end
        else if (WBsel == 2'b01) begin
            data_rd = ALUout;
        end
        else if (WBsel == 2'b10) begin
            data_rd = pc_m + 4;
        end
    end
endmodule