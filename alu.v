`timescale 1ns/1ps

// 4-bit ALU
// Inputs : a, b (4-bit operands), op (3-bit operation select)
// Outputs: y (4-bit result), carry (carry/borrow out), zero (result is 0)
//
// op  | operation
// 000 | ADD       y = a + b        (carry = carry-out)
// 001 | SUB       y = a - b        (carry = 1 when a < b, i.e. borrow)
// 010 | AND       y = a & b
// 011 | OR        y = a | b
// 100 | XOR       y = a ^ b
// 101 | NOT A     y = ~a
// 110 | INC A     y = a + 1
// 111 | CMP       y = 4'b0001 if a == b else 4'b0000

module alu (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [2:0] op,
    output reg  [3:0] y,
    output reg        carry,
    output wire       zero
);

    // 5 bits wide so the carry/borrow bit is not lost
    reg [4:0] result;

    // Purely combinational: sensitive to every input, and every
    // branch assigns result, so no latch is inferred.
    always @(*) begin
        case (op)
            3'b000: result = {1'b0, a} + {1'b0, b};
            3'b001: result = {1'b0, a} - {1'b0, b};
            3'b010: result = {1'b0, a & b};
            3'b011: result = {1'b0, a | b};
            3'b100: result = {1'b0, a ^ b};
            3'b101: result = {1'b0, ~a};
            3'b110: result = {1'b0, a} + 5'd1;
            3'b111: result = (a == b) ? 5'd1 : 5'd0;
            default: result = 5'd0;
        endcase

        y     = result[3:0];
        carry = result[4];
    end

    assign zero = (y == 4'b0000);

endmodule
