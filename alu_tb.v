`timescale 1ns/1ps

// Self-checking testbench for the 4-bit ALU.
// Directed tests first, then an exhaustive sweep of every a/b/op combination
// (16 * 16 * 8 = 2048 cases) compared against a reference model.

module alu_tb;

    reg  [3:0] a, b;
    reg  [2:0] op;
    wire [3:0] y;
    wire       carry, zero;

    integer errors;
    integer tests;

    alu dut (.a(a), .b(b), .op(op), .y(y), .carry(carry), .zero(zero));

    // Reference model (written differently from the DUT on purpose)
    reg [4:0] exp_full;
    reg [3:0] exp_y;
    reg       exp_carry;
    reg       exp_zero;

    task compute_expected;
        begin
            case (op)
                3'b000: exp_full = a + b;
                3'b001: exp_full = (a >= b) ? (a - b) : (a + 5'd16 - b + 5'd16);
                3'b010: exp_full = a & b;
                3'b011: exp_full = a | b;
                3'b100: exp_full = a ^ b;
                3'b101: exp_full = {1'b0, ~a};
                3'b110: exp_full = a + 1;
                3'b111: exp_full = (a == b) ? 1 : 0;
                default: exp_full = 0;
            endcase
            exp_y     = exp_full[3:0];
            exp_carry = (op == 3'b000) ? ((a + b) > 15) :
                        (op == 3'b001) ? (a < b) :
                        (op == 3'b110) ? (a == 4'd15) : 1'b0;
            exp_zero  = (exp_y == 4'd0);
        end
    endtask

    task check;
        begin
            #1;
            compute_expected;
            tests = tests + 1;
            if (y !== exp_y || carry !== exp_carry || zero !== exp_zero) begin
                errors = errors + 1;
                $display("FAIL: a=%0d b=%0d op=%b | got y=%0d c=%b z=%b | exp y=%0d c=%b z=%b",
                         a, b, op, y, carry, zero, exp_y, exp_carry, exp_zero);
            end
        end
    endtask

    integer i, j, k;

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);
        errors = 0;
        tests  = 0;

        // ---- Directed tests (readable in the waveform) ----
        a = 4'd5;  b = 4'd3;  op = 3'b000; check;  // 5 + 3 = 8
        a = 4'd9;  b = 4'd9;  op = 3'b000; check;  // 9 + 9 = 18 -> y=2, carry=1
        a = 4'd7;  b = 4'd2;  op = 3'b001; check;  // 7 - 2 = 5
        a = 4'd2;  b = 4'd7;  op = 3'b001; check;  // 2 - 7 -> borrow
        a = 4'b1100; b = 4'b1010; op = 3'b010; check; // AND
        a = 4'b1100; b = 4'b1010; op = 3'b011; check; // OR
        a = 4'b1100; b = 4'b1010; op = 3'b100; check; // XOR
        a = 4'b1010; b = 4'd0;    op = 3'b101; check; // NOT
        a = 4'd15; b = 4'd0;  op = 3'b110; check;  // 15 + 1 -> y=0, carry=1, zero=1
        a = 4'd6;  b = 4'd6;  op = 3'b111; check;  // equal
        a = 4'd6;  b = 4'd7;  op = 3'b111; check;  // not equal

        // ---- Exhaustive sweep ----
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 8; k = k + 1) begin
                    a = i; b = j; op = k;
                    check;
                end

        $display("--------------------------------------------");
        if (errors == 0)
            $display("PASS: %0d tests, 0 errors", tests);
        else
            $display("FAIL: %0d tests, %0d errors", tests, errors);
        $display("--------------------------------------------");
        $finish;
    end

endmodule
