// simple_alu_v2.v
module simple_alu_v1 (
    input  wire [6:0] partial_instruction,
    input  wire [2:0] option_bits,
    input  wire [15:0] x,
    input  wire [15:0] y,
    output wire [15:0] r,
    output wire overflow, negative, zero, cout, inf, subnormal, nan
);
    wire [7:0] alu_opcode;
    wire add_sub, signed_unsigned_multiplier, negate, signed_unsigned_comparator, fp_add_sub;
    wire [2:0] shifter_mode;

    alu_decoder DECODER (
        .partial_instruction(partial_instruction),
        .option_bits(option_bits),
        .alu_opcode(alu_opcode),
        .add_sub(add_sub),
        .signed_unsigned_multiplier(signed_unsigned_multiplier),
        .negate(negate),
        .signed_unsigned_comparator(signed_unsigned_comparator),
        .fp_add_sub(fp_add_sub),
        .shifter_mode(shifter_mode)
    );

    alu_core CORE (
        .x(x), .y(y),
        .alu_opcode(alu_opcode),
        .add_sub(add_sub),
        .signed_unsigned_multiplier(signed_unsigned_multiplier),
        .negate(negate),
        .signed_unsigned_comparator(signed_unsigned_comparator),
        .fp_add_sub(fp_add_sub),
        .shifter_mode(shifter_mode),
        .r(r),
        .overflow(overflow),
        .negative(negative),
        .zero(zero),
        .cout(cout),
        .inf(inf),
        .subnormal(subnormal),
        .nan(nan)
    );
endmodule
