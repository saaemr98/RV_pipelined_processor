`define MEM_DEPTH 1000000
`define TEMP_DEPTH 250000
`define INIT_PROGRAM_CNTR 32'h0100_0000
`define X_FILE "test/demo-friday-31.x"

`define word 2'b00
`define half_word 2'b01
`define byte 2'b10

module data_memory_module
    (
        input wire clock,
        input wire [31:0] address,
        input wire [31:0] rs2_m,
        input wire load_s,                 // This is the bit which determines if the load is unsigned or signed (1 for signed)
        input wire [1:0] access_size,      // This determines the size required for the read or write
        input wire [31:0] wb_w,
        input wire dataW_sel,
        output wire [31:0] data_out,
        input wire read_write,
        input wire print_out
    );

    integer i, f;
    reg [7:0] memory [`MEM_DEPTH-1:0];
    reg [31:0] temp_array [`TEMP_DEPTH-1:0];
    wire [31:0] data_in;

    initial begin
        $readmemh(`X_FILE, temp_array);

        for (i = 0; i < `TEMP_DEPTH - 1; i = i + 1) begin
            memory[4 * i] = temp_array[i] [7:0];
            memory[4 * i + 1] = temp_array[i] [15:8];
            memory[4 * i + 2] = temp_array[i] [23:16];
            memory[4 * i + 3] = temp_array[i] [31:24];
        end
    end

    // Data can be read depending on word and whether signed is needed
    // Combinational logic for reads
    assign data_out [7:0] = (access_size == `word) ? memory[address - `INIT_PROGRAM_CNTR]:
                            (access_size == `half_word) ? memory[address - `INIT_PROGRAM_CNTR]:
                            memory[address - `INIT_PROGRAM_CNTR];

    assign data_out [15:8] = (access_size == `word) ? memory[address + 1  - `INIT_PROGRAM_CNTR]:
                             (access_size == `half_word) ? memory[address + 1  - `INIT_PROGRAM_CNTR]:
                             (load_s & (memory[address - `INIT_PROGRAM_CNTR][7])) ? {8{1'b1}}:
                             {8{1'b0}};

    assign data_out [23:16] = (access_size == `word) ? memory[address + 2  - `INIT_PROGRAM_CNTR]:
                              (load_s & access_size == `half_word & memory[address + 1 - `INIT_PROGRAM_CNTR][7]) ? {8{1'b1}} :
                              (load_s & access_size == `byte  & (memory[address - `INIT_PROGRAM_CNTR][7])) ? {8{1'b1}}:
                              {8{1'b0}};

    assign data_out [31:24] = (access_size == `word) ? memory[address + 3 - `INIT_PROGRAM_CNTR]:
                              (load_s & access_size == `half_word & memory[address + 1 - `INIT_PROGRAM_CNTR][7]) ? {8{1'b1}} :
                              (load_s & access_size == `byte & (memory[address - `INIT_PROGRAM_CNTR][7])) ? {8{1'b1}}:
                              {8{1'b0}};

    assign data_in [31:0] = (dataW_sel == 0) ? rs2_m : wb_w;                  

    always @ (posedge clock) begin
        // The below logic allows for WM bypassing
        // The select signal is determined using the forwarding control module    
        /*if (dataW_sel == 0) begin
            data_in = rs2_m; 
        end
        else begin 
            data_in = wb_w;
        end*/

        if (~read_write) begin
            // Depending on access size given, only a certain number of bytes in memory will be written to
            // Sequential write
            case (access_size)
                `word : begin
                    memory[address - `INIT_PROGRAM_CNTR] <= data_in [7:0];
                    memory[address + 1 - `INIT_PROGRAM_CNTR] <= data_in [15:8];
                    memory[address + 2 - `INIT_PROGRAM_CNTR] <= data_in [23:16];
                    memory[address + 3 - `INIT_PROGRAM_CNTR] <= data_in [31:24];
                end
                `half_word : begin
                    memory[address - `INIT_PROGRAM_CNTR] <= data_in [7:0];
                    memory[address + 1 - `INIT_PROGRAM_CNTR] <= data_in [15:8];
                end
                `byte : begin
                    memory[address - `INIT_PROGRAM_CNTR] <= data_in [7:0];
                end
                default : begin
                    $display ("Error: Wrong access size");
                end
            endcase
        end

        if (print_out) begin
            f = $fopen("memory_output.txt","w");

            for (i = 0; i < `MEM_DEPTH; i = i + 4) begin
                $fwrite(f, "Address: %h, Data: %h\n", `INIT_PROGRAM_CNTR + i, {memory[i + 3], memory[i + 2], memory[i + 1], memory[i]});
            end

            $fclose(f);

            $finish;
        end
    end
endmodule