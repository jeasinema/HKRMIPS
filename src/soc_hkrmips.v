/*-----------------------------------------------------
 File Name : soc_hkrmips.v
 Purpose : top file of HKRMIPS
 Creation Date : 31-10-2016
 Last Modified : Mon Nov  7 16:31:18 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __SOC_HKRMIPS_V__
`define __SOC_HKRMIPS_V__

`timescale 1ns/1ns

module soc_hkrmips(/*autoarg*/
    //Inputs
    clk_in, rst_in_n, clk_uart_in, uart_rxd, 

    //Outputs
    base_ram_addr, base_ram_ce_n, base_ram_oe_n, 
    base_ram_we_n, ext_ram_addr, ext_ram_ce_n, 
    ext_ram_oe_n, ext_ram_we_n, uart_txd, 
    vga_vsync, vga_hsync, vga_pixel, flash_address, 
    flash_we_n, flash_byte_n, flash_oe_n, 
    flash_rp_n, flash_ce, flash_vpen, 

    //Inouts
    base_ram_data, ext_ram_data, gpio0, gpio1, 
    flash_data
);

    input wire clk_in;
    input wire rst_in_n;
    input wire clk_uart_in;

    wire clk;
    wire clk2x;
    wire rst_n;
    wire clk_uart;
    wire clk_tick;
    wire clk_uart_pll;
	 wire locked;
	 
`define EXT_UART_CLK

`ifdef EXT_UART_CLK
    assign clk_uart = clk_uart_in; 
`else
    assign clk_uart = clk_uart_pll;
`endif

sys_pll unique_pll
   (// Clock in ports
    .CLK_IN1(clk_in),      // IN
    // Clock out ports
    .CLK_OUT1(clk),     // OUT
    .CLK_OUT2(clk2x),     // OUT
    .CLK_OUT3(clk_uart_pll),     // OUT
    .CLK_OUT4(clk_tick),     // OUT
    // Status and control signals
    .RESET(!rst_in_n),// IN
    .LOCKED(locked)
); 
 clk_ctrl instance_name (
    .rst_out_n(rst_n), // output
    .clk(clk),             // input
    .rst_in_n(locked)    // input
 );

    inout wire[31:0] base_ram_data;
    output wire[19:0] base_ram_addr;
    output wire base_ram_ce_n;
    output wire base_ram_oe_n;
    output wire base_ram_we_n;

    inout wire[31:0] ext_ram_data;
    output wire[19:0] ext_ram_addr;
    output wire ext_ram_ce_n;
    output wire ext_ram_oe_n;
    output wire ext_ram_we_n;

    wire[4:0] irq_line;

    // inst_bust
    wire[31:0] ibus_addr;
    wire[3:0] ibus_byte_enable;
    wire ibus_read;
    wire ibus_write;
    wire[31:0] ibus_write_data;
    wire[31:0] ibus_read_data;
    wire ibus_stall;
    wire ibus_uncached;         

    // data_bus
    wire[31:0] dbus_addr;
    wire[3:0] dbus_byte_enable;
    wire dbus_read;
    wire dbus_write;
    wire[31:0] dbus_write_data;
    wire[31:0] dbus_read_data;
    wire dbus_stall;
    wire dbus_uncached;         

    // bootrom
    wire[12:0] bootrom_addr;
    wire[31:0] data_from_bootrom;
    
    // sram: inst_bus
    wire[23:0] ibus_ram_addr;
    wire[31:0] ibus_read_data_from_ram;
    wire[31:0] ibus_write_data_to_ram;
    wire[3:0] ibus_ram_byte_enable;
    wire ibus_ram_read_enable;
    wire ibus_ram_write_enable;
    wire ibus_ram_stall;

    // sram: data_bus
    wire[23:0] dbus_ram_addr;
    wire[31:0] dbus_write_data_to_ram;
    wire[31:0] dbus_read_data_from_ram;
    wire[3:0] dbus_ram_byte_enable;
    wire dbus_ram_write_enable;
    wire dbus_ram_read_enable;
    wire dbus_ram_stall;
    wire[31:0] conv_write_data_to_ram;

    // sram: 2sram
    wire[31:0] ram_addr;
    wire ram_write_enable;             
    wire ram_read_enable;           
    wire[31:0] read_data_from_ram;
    wire[31:0] write_data_to_ram;
    wire[3:0] ram_byte_enable;
    wire conv_ram_read_enable;
    wire conv_ram_write_enable;

    // uart
    wire[3:0] uart_addr;
    wire[31:0] write_data_to_uart;
    wire[31:0] read_data_from_uart;
    wire uart_write_enable;
    wire uart_read_enable;
    wire uart_irq;
    input wire uart_rxd;
    output wire uart_txd;

    // ticker
    wire[7:0] ticker_addr;
    wire[31:0] write_data_to_ticker;
    wire[31:0] read_data_from_ticker;
    wire ticker_write_enable;
    wire ticker_read_enable;

    // gpio
    wire[7:0] gpio_addr;
    wire[31:0] write_data_to_gpio;
    wire[31:0] read_data_from_gpio;
    wire gpio_write_enable;
    wire gpio_read_enable;
    inout wire[31:0] gpio0;
    inout wire[31:0] gpio1;

    // gpu & vga
    wire[23:0] gpu_addr;
    wire[31:0] write_data_to_gpu;
    wire[31:0] read_data_from_gpu;
    wire gpu_write_enable;
    wire gpu_read_enable;
    output wire vga_vsync;
    output wire vga_hsync;
    output wire[8:0] vga_pixel;
	 
	 assign vga_vsync = 1'b0;
	 assign vga_hsync = 1'b0;
	 assign vga_pixel = 8'b0;

    // rom & flash
    wire[23:0] rom_addr;
    wire[31:0] write_data_to_rom;
    wire[31:0] read_data_from_rom;
    wire[3:0] rom_enable;
    wire rom_write_enable;
    wire rom_read_enable;
    wire rom_stall;
    // flash
    output wire[21:0] flash_address;
    inout wire[15:0] flash_data;
    output wire flash_we_n;
    output wire flash_byte_n;
    output wire flash_oe_n;
    output wire flash_rp_n;
    output wire[2:0] flash_ce;
    output wire flash_vpen;

    assign base_ram_ce_n = ram_addr[22];
    assign base_ram_oe_n = ram_read_enable;
    assign base_ram_we_n = ram_write_enable;
    assign base_ram_addr = ram_addr[21:2];
    assign base_ram_data = (~base_ram_ce_n && ~base_ram_we_n) ? write_data_to_ram : {32{1'hz}};

    assign ext_ram_ce_n = ~ram_addr[22];
    assign ext_ram_oe_n = ram_read_enable;
    assign ext_ram_we_n = ram_write_enable;
    assign ext_ram_addr = ram_addr[21:2];
    assign ext_ram_data  = (~ext_ram_ce_n && ~ext_ram_we_n) ? write_data_to_ram : {32{1'hz}};

    assign read_data_from_ram = (~base_ram_ce_n) ? base_ram_data : ext_ram_data;

    assign irq_line = {2'b0,uart_irq,2'b0};

    inst_bus ibus0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // dev access interface
    .dev_access_addr            (ibus_addr[31:0]          ), // input
    .dev_ram_byte_enable        (ibus_byte_enable[3:0]       ), // input
    .dev_access_read            (ibus_read                ), // input
    .dev_access_write           (ibus_write               ), // input
    .dev_access_write_data      (ibus_write_data[31:0]          ), // input
    .dev_access_read_data       (ibus_read_data[31:0]           ), // output
    .inst_bus_stall             (ibus_stall                 ), // output

        // bootrom
    .bootrom_addr               (bootrom_addr[12:0]             ), // output
    .data_from_bootrom          (data_from_bootrom[31:0]        ), // output

        // sram
    .ram_addr                   (ibus_ram_addr[23:0]                 ), // output
    .read_data_from_ram         (ibus_read_data_from_ram[31:0]       ), // input
    .write_data_to_ram          (ibus_write_data_to_ram[31:0]        ), // output
    .ram_byte_enable            (ibus_ram_byte_enable[3:0]           ), // output
    .ram_read_enable            (ibus_ram_read_enable                ), // output
    .ram_write_enable           (ibus_ram_write_enable               ), // output
    .ram_stall                  (ibus_ram_stall                      )  // input
);

    data_bus dbus0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

        // dev access interface  
    .dev_access_addr            (dbus_addr[31:0]          ), // input
    .dev_ram_byte_enable        (dbus_byte_enable[3:0]       ), // input
    .dev_access_read            (dbus_read                ), // input
    .dev_access_write           (dbus_write               ), // input
    .dev_access_write_data      (dbus_write_data[31:0]    ), // input
    .dev_access_read_data       (dbus_read_data[31:0]     ), // output
    .data_bus_stall             (dbus_stall                 ), // output

        // uart
    .uart_addr                  (uart_addr[3:0]                 ), // output
    .write_data_to_uart         (write_data_to_uart[31:0]       ), // output
    .read_data_from_uart        (read_data_from_uart[31:0]      ), // input
    .uart_write_enable          (uart_write_enable              ), // output
    .uart_read_enable           (uart_read_enable               ), // output

        // ticker
    .ticker_addr                (ticker_addr[7:0]               ), // output
    .write_data_to_ticker       (write_data_to_ticker[31:0]     ), // output
    .read_data_from_ticker      (read_data_from_ticker[31:0]    ), // input
    .ticker_write_enable        (ticker_write_enable            ), // output
    .ticker_read_enable         (ticker_read_enable             ), // output

        // gpio
    .gpio_addr                  (gpio_addr[7:0]                 ), // output
    .write_data_to_gpio         (write_data_to_gpio[31:0]       ), // output
    .read_data_from_gpio        (read_data_from_gpio[31:0]      ), // input
    .gpio_write_enable          (gpio_write_enable              ), // output
    .gpio_read_enable           (gpio_read_enable               ), // output

        // vga(gpu)
    .gpu_addr                   (gpu_addr[23:0]                 ), // output
    .write_data_to_gpu          (write_data_to_gpu[31:0]        ), // output
    .read_data_from_gpu         (read_data_from_gpu[31:0]       ), // input
    .gpu_write_enable           (gpu_write_enable               ), // output
    .gpu_read_enable            (gpu_read_enable                ), // output
    
        // sram 
    .ram_addr                   (dbus_ram_addr[23:0]                 ), // output
    .write_data_to_ram          (dbus_write_data_to_ram[31:0]        ), // output
    .read_data_from_ram         (dbus_read_data_from_ram[31:0]       ), // input
    .ram_byte_enable            (dbus_ram_byte_enable[3:0]           ), // output
    .ram_write_enable           (dbus_ram_write_enable               ), // output
    .ram_read_enable            (dbus_ram_read_enable                ), // output
    .ram_stall                  (dbus_ram_stall                      ), // input
  
        // flash(rom)
    .rom_addr                   (rom_addr[23:0]                 ), // output
    .write_data_to_rom          (write_data_to_rom[31:0]        ), // output
    .read_data_from_rom         (read_data_from_rom[31:0]       ), // input
    .rom_enable                 (rom_enable[3:0]                ), // output
    .rom_write_enable           (rom_write_enable               ), // output
    .rom_read_enable            (rom_read_enable                ), // output
    .rom_stall                  (rom_stall                      )  // input
);

    bootrom bootrom(/*autoinst*/
    .address                    (bootrom_addr[12:2]                  ), // input
    .clock                      (~clk                         ), // input
    .q                          (data_from_bootrom[31:0]                        )  // output
);

    hkr_mips cpu0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // external interrupts input 
    .hardware_int_in            (irq_line[4:0]           ), // input

        // inst_bus
    .ibus_addr                  (ibus_addr[31:0]                ), // output
    .ibus_read                  (ibus_read                      ), // output
    .ibus_write                 (ibus_write                     ), // output
    .ibus_write_data            (ibus_write_data[31:0]          ), // output
    .ibus_uncached              (ibus_uncached                  ), // output
    .ibus_byte_en               (ibus_byte_enable[3:0]              ), // output
    .ibus_read_data             (ibus_read_data[31:0]           ), // input
    .ibus_stall                 (ibus_stall                     ), // input

        // data_bus
    .dbus_addr                  (dbus_addr[31:0]                ), // output
    .dbus_read                  (dbus_read                      ), // output
    .dbus_write                 (dbus_write                     ), // output
    .dbus_write_data            (dbus_write_data[31:0]          ), // output
    .dbus_uncached              (dbus_uncached                  ), // output
    .dbus_byte_en               (dbus_byte_enable[3:0]              ), // output
    .dbus_read_data             (dbus_read_data[31:0]           ), // input
    .dbus_stall                 (dbus_stall                    ) // input
);
    
    two_port ram(/*autoinst*/
    .rst_n                      (rst_n                          ), // input
    .clk2x                      (clk2x                          ), // input

    .address1                   (ibus_ram_addr[23:0]                 ), // input
    .wrdata1                    (ibus_write_data_to_ram[31:0]                  ), // input
    .rddata1                    (ibus_read_data_from_ram[31:0]                  ), // output
    .dataenable1                (ibus_ram_byte_enable[3:0]               ), // input
    .rd1                        (ibus_ram_read_enable                            ), // input
    .wr1                        (ibus_ram_write_enable                            ), // input

    .address2                   (dbus_ram_addr[23:0]                 ), // input
    .wrdata2                    (conv_write_data_to_ram[31:0]                  ), // input
    .rddata2                    (dbus_read_data_from_ram[31:0]                  ), // output
    .dataenable2                (dbus_ram_byte_enable[3:0]               ), // input
    .rd2                        (conv_ram_read_enable                            ), // input
    .wr2                        (conv_ram_write_enable                            ), // input

    .ram_address                (ram_addr[29:0]              ), // output
    .ram_data_i                 (read_data_from_ram[31:0]               ), // input
    .ram_data_o                 (write_data_to_ram[31:0]               ), // output
    .ram_wr_n                   (ram_write_enable                       ), // output
    .ram_rd_n                   (ram_read_enable                       ), // output
    .dataenable                 (ram_byte_enable[3:0]                )  // output
);
    
    bytes_conv mem_conv(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    .byteenable_i               (dbus_ram_byte_enable[3:0]              ), // input
    .address                    (dbus_ram_addr[23:0]                  ), // input
    .data_ram_rd                (dbus_read_data_from_ram[31:0]              ), // input
    .data_ram_wr                (conv_write_data_to_ram[31:0]              ), // output
    .data_master_wr             (dbus_write_data_to_ram[31:0]           ), // input
    .stall_o                    (dbus_ram_stall                        ), // output
    .read_i                     (dbus_ram_read_enable                         ), // input
    .write_i                    (dbus_ram_write_enable                        ), // input
    .read_o                     (conv_ram_read_enable                        ), // output
    .write_o                    (conv_ram_write_enable                        )  // output
);

    uart_top uart0(/*autoinst*/
    .clk_bus                    (clk                        ), // input
    .clk_uart                   (clk_uart                       ), // input
    .rst_n                      (rst_n                          ), // input

    .bus_address                (uart_addr[3:0]               ), // input
    .bus_data_i                 (write_data_to_uart[31:0]               ), // input
    .bus_data_o                 (read_data_from_uart[31:0]               ), // output
    .bus_read                   (uart_read_enable                       ), // input
    .bus_write                  (uart_write_enable                      ), // input

    .uart_irq                   (uart_irq                       ), // output

    .rxd                        (uart_rxd                            ), // input
    .txd                        (uart_txd                            )  // output
);

    flash_top disk0(/*autoinst*/
    .clk_bus                    (clk                        ), // input
    .rst_n                      (rst_n                          ), // input

    .bus_address                (rom_addr[23:0]              ), // input
    .bus_data_i                 (write_data_to_rom[31:0]               ), // input
    .bus_data_o                 (read_data_from_rom[31:0]               ), // output
    .bus_read                   (rom_read_enable                       ), // input
    .bus_write                  (rom_write_enable                      ), // input
    .bus_stall                  (rom_stall                      ), // output

    .flash_address              (flash_address[21:0]            ), // output
    .flash_data                 (flash_data[15:0]               ), // inout
    .flash_we_n                 (flash_we_n                     ), // output
    .flash_byte_n               (flash_byte_n                   ), // output
    .flash_oe_n                 (flash_oe_n                     ), // output
    .flash_rp_n                 (flash_rp_n                     ), // output
    .flash_ce                   (flash_ce[2:0]                  ), // output
    .flash_vpen                 (flash_vpen                     )  // output
);

    gpio_top gpio_instance(/*autoinst*/
    .clk_bus                    (clk                        ), // input
    .rst_n                      (rst_n                          ), // input

    .bus_address                (gpio_addr[7:0]               ), // input
    .bus_data_i                 (write_data_to_gpio[31:0]               ), // input
    .bus_data_o                 (read_data_from_gpio[31:0]               ), // output
    .bus_read                   (gpio_read_enable                       ), // input
    .bus_write                  (gpio_write_enable                      ), // input

    .gpio0                      (gpio0[31:0]                    ), // inout
    .gpio1                      (gpio1[31:0]                    )  // inout
);

    ticker ticker0(/*autoinst*/
    .clk_bus                    (clk                        ), // input
    .rst_n                      (rst_n                          ), // input
  
    .clk_tick                   (clk_tick                       ), // input
    .rst_tick_n                 (rst_n                     ), // input

      //bus
    .bus_data_o                 (read_data_from_ticker[31:0]               ), // output
    .bus_address                (ticker_addr[7:0]               ), // input
    .bus_data_i                 (write_data_to_ticker[31:0]               ), // input
    .bus_read                   (ticker_read_enable                       ), // input
    .bus_write                  (ticker_write_enable                      )  // input
);

//    gpu vga0(/*autoinst*/
//    .clk_bus                    (clk                        ), // input
//    .clk_pixel                  (clk_in                      ), // input
//    .rst_n                      (rst_n                          ), // input
//
//      //bus
//      //output
//    .bus_data_o                 (read_data_from_gpu[31:0]               ), // output
//      //input
//    .bus_address                (gpu_addr[23:0]              ), // input
//    .bus_data_i                 (write_data_to_gpu[31:0]               ), // input
//    .bus_read                   (gpu_read_enable                       ), // input
//    .bus_write                  (gpu_write_enable                      ), // input
//
//      //vga
//    .de                         (                             ), // output
//    .vsync                      (vga_vsync                          ), // output
//    .hsync                      (vga_hsync                          ), // output
//    .pxlData                    (vga_pixel[8:0]                   )  // output
//);

endmodule

`endif
