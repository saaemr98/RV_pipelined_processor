
module pc_select_module
    (
        input wire BrEq,
        input wire BrLT,
        input wire [31:0] instruction_in,
        output reg PCsel
    );

    always @ (*) begin
        case (instruction_in [6:0])
            7'b1100011 : begin
                case (instruction_in [14:12])
                    3'b000 : begin
                        //$write ("opcode: BEQ");
                        if (BrEq == 1 && BrLT == 0) begin
                            PCsel = 1;
                        end
                        else begin
                            PCsel = 0;
                        end
                    end
                    3'b001 : begin
                        //$write ("opcode: BNE");
                        if (BrEq == 0) begin
                            PCsel = 1;
                        end
                        else begin
                            PCsel = 0;
                        end
                    end
                    3'b100 : begin
                        //$write ("opcode: BLT");
                        if (BrEq == 0 && BrLT == 1) begin
                            PCsel = 1;
                        end
                        else begin
                            PCsel = 0;
                        end
                    end
                    3'b101 : begin
                        //$write ("opcode: BGE");
                        if (BrLT == 0) begin
                            PCsel = 1;
                        end
                        else begin
                            PCsel = 0;
                        end
                    end
                    3'b110 : begin
                        //$write ("opcode: BLTU");
                        if (BrEq == 0 && BrLT == 1) begin
                            PCsel = 1;
                        end
                        else begin
                            PCsel = 0;
                        end
                    end
                    3'b111 : begin
                        //$write ("opcode: BGEU");
                        if (BrLT == 0) begin
                            PCsel = 1;
                        end
                        else begin
                            PCsel = 0;
                        end
                    end
                    default : begin
                        PCsel = 0;
                        $display("Error: PCsel could not be driven due to incorrect instruction");
                    end
                endcase 
            end
            7'b1100111 : begin 
                PCsel = 1;
            end
            7'b1101111 :begin
                PCsel = 1;
            end 
            default : begin
                PCsel = 0;
            end
        endcase
    end
endmodule