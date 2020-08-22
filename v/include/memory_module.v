
`define MEM_DEPTH 1000000
`define TEMP_DEPTH 250000
`define INIT_PROGRAM_CNTR 32'h0100_0000
`define X_FILE "test/demo-friday-31.x"

module memory_module
    (
        input wire clock,
        input wire [31:0] address,
        input wire [31:0] data_in,
        output wire [31:0] data_out,
        input wire read_write
    );

    integer i;
    reg [7:0] memory [`MEM_DEPTH-1:0];
    reg [31:0] temp_array [`TEMP_DEPTH-1:0];

    initial begin
        $readmemh(`X_FILE, temp_array);

        for (i = 0; i < `TEMP_DEPTH - 1; i = i + 1) begin
            memory[4 * i] = temp_array[i] [7:0];
            memory[4 * i + 1] = temp_array[i] [15:8];
            memory[4 * i + 2] = temp_array[i] [23:16];
            memory[4 * i + 3] = temp_array[i] [31:24];
        end
    end

    // Combinational Reads
    assign data_out [7:0]  = (read_write) ? memory[address - `INIT_PROGRAM_CNTR] : {8{1'bz}};
    assign data_out [15:8]  = (read_write) ? memory[address + 1 -`INIT_PROGRAM_CNTR] : {8{1'bz}};
    assign data_out [23:16]  = (read_write) ? memory[address + 2 - `INIT_PROGRAM_CNTR] : {8{1'bz}};
    assign data_out [31:24]  = (read_write) ? memory[address + 3 - `INIT_PROGRAM_CNTR] : {8{1'bz}};


    always @ (posedge clock) begin
        // Sequential Writes
        if (~read_write) begin
            memory[address - `INIT_PROGRAM_CNTR] <= data_in [7:0];
            memory[address + 1 - `INIT_PROGRAM_CNTR] <= data_in [15:8];
            memory[address + 2 - `INIT_PROGRAM_CNTR] <= data_in [23:16];
            memory[address + 3 - `INIT_PROGRAM_CNTR] <= data_in [31:24];
        end
    end
endmodule