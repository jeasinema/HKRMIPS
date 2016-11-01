/*-----------------------------------------------------
 File Name : soc_hkrmips.v
 Purpose : top file of HKRMIPS
 Creation Date : 31-10-2016
 Last Modified : Mon Oct 31 15:21:51 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __SOC_HKRMIPS_V__
`define __SOC_HKRMIPS_V__

`timescale 1ns/1ps

module soc_hkrmips(/*autoarg*/);

    input wire clk;
    input wire rst_n;

    inst_bus ibus0(/*autoinst*/);

    bootrom bootrom(/*autoinst*/); 

    hkr_mips cpu0(/*autoinst*/);
    
    two_port ram(/*autoinst*/);

    data_bus dbus0(/*autoinst*/);

    uart_top uart0(/*autoinst*/);

    flash_top disk0(/*autoinst*/);

    gpio_top gpio0(/*autoinst*/);

    ticker ticker0(/*autoinst*/);

    gpu vga0(/*autoinst*/);

    
    always @(*)
    begin

    end

endmodule

`endif
