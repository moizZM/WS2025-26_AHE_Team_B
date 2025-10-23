//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (win64) Build 5239630 Fri Nov 08 22:35:27 MST 2024
//Date        : Thu Oct 16 16:31:09 2025
//Host        : ISCN5CG2116RM7 running 64-bit major release  (build 9200)
//Command     : generate_target FullAdder_4Bit_wrapper.bd
//Design      : FullAdder_4Bit_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module FullAdder_4Bit_wrapper
   (A,
    B,
    C_in,
    Cout,
    Sum);
  input [3:0]A;
  input [3:0]B;
  input C_in;
  output Cout;
  output [3:0]Sum;

  wire [3:0]A;
  wire [3:0]B;
  wire C_in;
  wire Cout;
  wire [3:0]Sum;

  FullAdder_4Bit FullAdder_4Bit_i
       (.A(A),
        .B(B),
        .C_in(C_in),
        .Cout(Cout),
        .Sum(Sum));
endmodule
