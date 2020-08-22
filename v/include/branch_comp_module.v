
module branch_comp_module
    (
        input wire [31:0] input1,
        input wire [31:0] input2,
        input wire BrUn,
        output reg BrEq,
        output reg BrLT
    );

    always @ (*) begin
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
    end
endmodule