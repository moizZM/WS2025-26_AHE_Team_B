/******************************************************************************
 * Copyright (C) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
 * SPDX-License-Identifier: MIT
 ******************************************************************************/
/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include "xuartlite.h"
#include "xuartlite_l.h"
#include "xparameters.h"
#include "xstatus.h"
#include "xil_io.h"
#include <stdio.h>
#include <unistd.h>


#define GPIO_BASEADDR XPAR_AXI_GPIO_0_BASEADDR
#define GPIO_CHANNEL 1

void to_binary(u32 value, char *out) {
  for (int i = 31; i >= 0; i--) {
    out[31 - i] = (value & (1u << i)) ? '1' : '0';
  }
  out[32] = 0; // null-terminate
}

void to_binary_grouped(u32 value, char *out) {
  int pos = 0;
  for (int i = 31; i >= 0; i--) {
    out[pos++] = (value & (1u << i)) ? '1' : '0';
    if (i % 4 == 0 && i != 0) {
      out[pos++] = '_';
    }
  }
  out[pos] = 0;
}

void to_binary_16_lower(u32 value, char *out) {
  for (int i = 14; i >= 0; i--) {
    out[14 - i] = (value & (1u << i)) ? '1' : '0';
  }
  out[15] = 0;
}

static void BtUart_DumpRx(XUartLite *Uart)
{
    u8 buf[128];
    int n = 0;

    // Read whatever is available right now (non-blocking)
    while (XUartLite_IsReceiveEmpty(Uart->RegBaseAddress) == 0 && n < (int)sizeof(buf)-1) {
        buf[n++] = XUartLite_ReadReg(Uart->RegBaseAddress, XUL_RX_FIFO_OFFSET);
    }
    if (n > 0) {
        buf[n] = 0;
        printf("BT_RX: %s\r\n", buf);
    }
}

static int BtUart_Init_ByBaseAddr(XUartLite *Uart, UINTPTR BaseAddr)
{
    XUartLite_Config *Cfg = XUartLite_LookupConfig(BaseAddr);
    if (!Cfg) return XST_FAILURE;

    int Status = XUartLite_CfgInitialize(Uart, Cfg, Cfg->RegBaseAddr);
    if (Status != XST_SUCCESS) return Status;

    // optional: reset FIFOs
    XUartLite_ResetFifos(Uart);
    return XST_SUCCESS;
}


int main() {

  printf("Reading 32-bit GPIO...\r\n");
  float speed = 250.0;
  char bin[16]; // 16 bits + null
  
XUartLite BtUart;
int status = BtUart_Init_ByBaseAddr(&BtUart, XPAR_XUARTLITE_1_BASEADDR);

  if (status != XST_SUCCESS) {
    printf("UART initialization failed!\r\n");
    return XST_FAILURE;

  } else {

    printf("UART initialization successful!\r\n");
  }

usleep(1000000);
XUartLite_Send(&BtUart, (u8 *)"$$$", 3);
usleep(200000);
BtUart_DumpRx(&BtUart);   // expect "CMD\r\n" on many modules

XUartLite_Send(&BtUart, (u8 *)"SN,MY_BT2\r", 10);
usleep(200000);
BtUart_DumpRx(&BtUart);   // expect "AOK\r\n" typically

XUartLite_Send(&BtUart, (u8 *)"SM,0\r", 5);
usleep(200000);
BtUart_DumpRx(&BtUart);

XUartLite_Send(&BtUart, (u8 *)"---\r", 4);
usleep(200000);
BtUart_DumpRx(&BtUart);

XUartLite_Send(&BtUart, (u8*)"BT2 READY\r\n", 11);


  while (1) {
    u32 v = Xil_In32(GPIO_BASEADDR);

    to_binary_16_lower(v, bin);

    printf("LOWER16 = %s\r\n", bin);

    // --- Reset before building values ---
    int z = 0;
    int y = 0;
    int x = 0;

    // --- z = first 5 bits (bin[0..4]) ---
    for (int i = 1; i < 5; i++) {
      x <<= 1;
      x |= (bin[i] == '1') ? 1 : 0;
    }

    // --- y = next 5 bits (bin[5..9]) ---
    for (int i = 6; i < 10; i++) {
      y <<= 1;
      y |= (bin[i] == '1') ? 1 : 0;
    }

    // --- x = last 5 bits (bin[10..14]) ---
    for (int i = 11; i < 15; i++) {
      z <<= 1;
      z |= (bin[i] == '1') ? 1 : 0;
    }

    // --- SIGN EXTEND each 5-bit signed value ---
    if (bin[0] == '1')
      x = -x; // signed z
    if (bin[5] == '1')
      y = -y; // signed z
    if (bin[10] == '1')
      z = -z; // signed z

    if (x < 0) {
      x = -x - 16;
    }

    printf("x = %d\r\n", x);
    usleep(200000);

    speed = speed + (x * (650.0f / 70.0f));

    printf("%.2f\r\n", speed);

    char tx_buf[32];
    int len = sprintf(tx_buf, "Speed: %.2f\r\n", speed);
    XUartLite_Send(&BtUart, (u8 *)tx_buf, len);

    usleep(100000); // small delay to avoid spamming
  }

  return 0;
}
 
