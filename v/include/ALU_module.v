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

module ALU_module
    (
        input wire [31:0] dataA,
        input wire [31:0] program_cntr,
        input wire [31:0] dataB,
        input wire [31:0] imm,
        input wire [31:0] alu_m,
        input wire [31:0] wb_w,
        input wire [1:0] Asel,
        input wire [1:0] Bsel,
        input wire [3:0] ALUsel,
        output reg [31:0] ALUout
    );

    reg [31:0] A;
    reg [31:0] B;

    always @ (*) begin
        case(Asel)
            2'b00 : begin
                A = dataA;
            end
            2'b01 : begin
                A = program_cntr;
            end
            2'b10 : begin
                A = alu_m;
            end
            2'b11 : begin
                A = wb_w;
            end
            default : begin
                //$display ("Error: Invalid Asel");
            end
        endcase

        case(Bsel)
            2'b00 : begin
                B = dataB;
            end
            2'b01 : begin
                B = imm;
                //$display("B: %h", B);
            end
            2'b10 : begin
                B = alu_m;
            end
            2'b11 : begin
                B = wb_w;
            end
            default : begin
                //$display ("Error: Invalid Bsel");
            end
        endcase

        case (ALUsel)
            `ADD : begin
            //ADD
                ALUout = $signed(A) + $signed(B);
                //$display ("A: %h, B:%h ,ALUout: %h", A, B, ALUout);
            end
            `SUB : begin
            //SUB
                ALUout = $signed(A) - $signed(B);
            end
            `SLL : begin
            //SLL
                ALUout = A << B [4:0];
            end
            `SLT : begin
            // SLT
                if ($signed(A) < $signed(B)) 
                    ALUout = 32'b1;
                else    
                    ALUout = 32'b0;
            end
            `SLTU : begin
            // SLTU
                if (A < B) 
                    ALUout = 32'b1;
                else    
                    ALUout = 32'b0;
            end
            `XOR : begin
            // XOR
                ALUout = A ^ B;
            end
            `SRL : begin
            // SRL
                ALUout = A >> B [4:0];
            end
            `SRA : begin
            // SRA
                ALUout = $signed(A) >>> B [4:0];
            end
            `OR : begin
            // OR
                ALUout = A | B;
            end
            `AND : begin
            // AND
                ALUout = A & B;
            end
            4'b1010 : begin
            // B
                ALUout = B;
            end
            default : begin
                //$display ("Error: Invalid ALUsel.");
            end
        endcase
    end
endmodule