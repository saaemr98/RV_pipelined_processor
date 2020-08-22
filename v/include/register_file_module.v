`define REG_COUNT 32

module register_file_module
    (
        input wire clock,
        input wire [4:0] addr_rs1,
        input wire [4:0] addr_rs2,
        input wire [31:0] addr_rd,
        input wire [31:0] data_rd,
        output wire [31:0] data_rs1,
        output wire [31:0] data_rs2,
        output reg print_out,
        input wire write_enable
    );

    // 32 32-bit registers
    reg [31:0] register_file [`REG_COUNT - 1:0];
    integer i;

    initial begin
        register_file [0] = 0;
        register_file [1] = 0;
        register_file [2] = 32'h010f_423c;

        $display ("------------------------------------------");
        $display ("Initial Register File State");
        $display ("------------------------------------------");
        for (i = 0; i < `REG_COUNT; i = i + 1) begin
            $display ("x%d: %h", i, register_file[i]);
        end
        $display ("------------------------------------------");
        $display ("");
    end

    assign data_rs1 = register_file[addr_rs1];
    assign data_rs2 = register_file[addr_rs2];

    always @ (posedge clock) begin
        $display ("------------------------------------------");
        for (i = 0; i < `REG_COUNT; i = i + 1) begin
            $display ("x%d: %h", i, register_file[i]);
        end
        $display ("------------------------------------------");

        if (write_enable && addr_rd [11:7] != 32'h0000_0000) begin
            register_file [addr_rd[11:7]] <= data_rd;
        end
    end 

    always @ (*) begin
        #500
        // register_file [2] == 32'h010f_423c
        print_out = 0;
        if (register_file [2] == 32'h010f_423c) begin
            $display ("------------------------------------------");
            $display ("After Execution Registers");
            $display ("------------------------------------------");
            for (i = 0; i < `REG_COUNT; i = i + 1) begin
                $display ("x%d: %h", i, register_file[i]);
            end
            $display ("------------------------------------------");
            $display ("");
            print_out = 1;
        end
    end
endmodule