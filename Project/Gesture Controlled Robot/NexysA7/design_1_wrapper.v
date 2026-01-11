//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
//Date        : Mon Dec 15 15:57:48 2025
//Host        : LAB49-05 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (SPIclk,
    annode,
    clock,
    csn,
    decimal,
    led,
    miso,
    mosi,
    reset_rtl_0,
    rx_0,
    rx_1,
    seg,
    tx_0,
    tx_1);
  output SPIclk;
  output [7:0]annode;
  input clock;
  output csn;
  output decimal;
  output [14:0]led;
  input miso;
  output mosi;
  input reset_rtl_0;
  input rx_0;
  input rx_1;
  output [6:0]seg;
  output tx_0;
  output tx_1;

  wire SPIclk;
  wire [7:0]annode;
  wire clock;
  wire csn;
  wire decimal;
  wire [14:0]led;
  wire miso;
  wire mosi;
  wire reset_rtl_0;
  wire rx_0;
  wire rx_1;
  wire [6:0]seg;
  wire tx_0;
  wire tx_1;

  design_1 design_1_i
       (.SPIclk(SPIclk),
        .annode(annode),
        .clock(clock),
        .csn(csn),
        .decimal(decimal),
        .led(led),
        .miso(miso),
        .mosi(mosi),
        .reset_rtl_0(reset_rtl_0),
        .rx_0(rx_0),
        .rx_1(rx_1),
        .seg(seg),
        .tx_0(tx_0),
        .tx_1(tx_1));
endmodule
