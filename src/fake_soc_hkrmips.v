/*-----------------------------------------------------
 File Name : fake_soc_hkrmips.v
 Purpose : top file of HKRMIPS, only using fake ram/rom
 Creation Date : 31-10-2016
 Last Modified : Mon Oct 31 23:36:54 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __FAKE_SOC_HKRMIPS_V__
`define __FAKE_SOC_HKRMIPS_V__

`timescale 1ns/1ps

module fake_soc_hkrmips(/*autoarg*/
    //Inputs
    clk, rst_n
);

    input wire clk;
    input wire rst_n;


    wire[4:0] hardware_int_in;
    wire[31:0] ibus_addr;
    wire ibus_read;             
    wire[31:0] ibus_write_data;
    wire ibus_uncached;         
    wire[3:0] ibus_byte_en;
    wire[31:0] ibus_read_data;
    wire ibus_stall;            
    wire[31:0] dbus_addr;
    wire dbus_read;             
    wire[31:0] dbus_write_data;
    wire dbus_uncached;         
    wire[3:0] dbus_byte_en;
    wire[31:0] dbus_read_data;
    wire[31:0] dbus_stall;

    // boot rom
    wire[12:0] bootrom_addr;
    wire[31:0] data_from_bootrom;

    // fake_inst_ram
    wire[23:0] inst_ram_addr;
    wire[31:0] read_data_from_inst_ram;
    wire[31:0] write_data_to_inst_ram;
    wire[3:0] inst_ram_enable;        
    wire inst_ram_read_enable;         
    wire inst_ram_write_enable;        
    wire inst_ram_stall;                

    // fake_data_ram 
    wire[23:0] data_ram_addr;
    wire[31:0] write_data_to_data_ram;
    wire[31:0] read_data_from_data_ram;
    wire[3:0] data_ram_enable;
    wire data_ram_write_enable;           
    wire data_ram_read_enable;            
    wire data_ram_stall;                  

    // fake_rom
    wire[23:0] rom_addr;
    wire[31:0] write_data_to_rom;
    wire[31:0] read_data_from_rom;
    wire[3:0] rom_enable;
    wire rom_write_enable;           
    wire rom_read_enable;            
    wire rom_stall;                  

    // useless devices
    wire[3:0] uart_addr;
    wire[31:0] write_data_to_uart;
    wire[31:0] read_data_from_uart;
    wire uart_write_enable;          
    wire uart_read_enable;           
    wire[7:0] ticker_addr;
    wire[31:0] write_data_to_ticker;
    wire[31:0] read_data_from_ticker;
    wire ticker_write_enable;        
    wire ticker_read_enable;         
    wire[7:0] gpio_addr;
    wire[31:0] write_data_to_gpio;
    wire[31:0] read_data_from_gpio;
    wire gpio_write_enable;          
    wire gpio_read_enable;           
    wire[23:0] gpu_addr;
    wire[31:0] write_data_to_gpu;
    wire[31:0] read_data_from_gpu;
    wire gpu_write_enable;           
    wire gpu_read_enable;            

    inst_bus ibus0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // dev access interface
    .dev_access_addr            (ibus_addr[31:0]          ), // input
    .dev_access_read            (ibus_read                ), // input
    .dev_access_write           (ibus_write               ), // input
    .dev_access_write_data      (ibus_write_data          ), // input
    .dev_access_read_data       (ibus_read_data           ), // output
    .inst_bus_stall             (ibus_stall                 ), // output

        // bootrom
    .bootrom_addr               (bootrom_addr[12:0]          ), // output
    .data_from_bootrom          (data_from_bootrom[31:0]        ), // output

        // sram
    .ram_addr                   (inst_ram_addr[23:0]              ), // output
    .read_data_from_ram         (read_data_from_inst_ram[31:0]       ), // output
    .write_data_to_ram          (write_data_to_inst_ram[31:0]        ), // output
    .ram_enable                 (inst_ram_enable[3:0]                ), // output
    .ram_read_enable            (inst_ram_read_enable                ), // output
    .ram_write_enable           (inst_ram_write_enable               ), // output
    .ram_stall                  (inst_ram_stall                      )  // input
);

    data_bus dbus0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

        // dev access interface  
    .dev_access_addr            (dbus_addr[31:0]          ), // input
    .dev_access_read            (dbus_read              ), // input
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
    .read_data_from_ticker      (read_data_from_ticker[31:0]    ), // output
    .ticker_write_enable        (ticker_write_enable            ), // output
    .ticker_read_enable         (ticker_read_enable             ), // output

        // gpio
    .gpio_addr                  (gpio_addr[7:0]                 ), // output
    .write_data_to_gpio         (write_data_to_gpio[31:0]       ), // output
    .read_data_from_gpio        (read_data_from_gpio[31:0]      ), // output
    .gpio_write_enable          (gpio_write_enable              ), // output
    .gpio_read_enable           (gpio_read_enable               ), // output

        // vga(gpu)
    .gpu_addr                   (gpu_addr[23:0]                 ), // output
    .write_data_to_gpu          (write_data_to_gpu[31:0]        ), // output
    .read_data_from_gpu         (read_data_from_gpu[31:0]       ), // output
    .gpu_write_enable           (gpu_write_enable               ), // output
    .gpu_read_enable            (gpu_read_enable                ), // output
    
        // sram 
    .ram_addr                   (data_ram_addr[23:0]                 ), // output
    .write_data_to_ram          (write_data_to_data_ram[31:0]        ), // output
    .read_data_from_ram         (read_data_from_data_ram[31:0]       ), // output
    .ram_enable                 (data_ram_enable[3:0]                ), // output
    .ram_write_enable           (data_ram_write_enable               ), // output
    .ram_read_enable            (data_ram_read_enable                ), // output
    .ram_stall                  (data_ram_stall                      ), // input
  
        // flash(rom)
    .rom_addr                   (rom_addr[23:0]                 ), // output
    .write_data_to_rom          (write_data_to_rom[31:0]        ), // output
    .read_data_from_rom         (read_data_from_rom[31:0]       ), // output
    .rom_enable                 (rom_enable[3:0]                ), // output
    .rom_write_enable           (rom_write_enable               ), // output
    .rom_read_enable            (rom_read_enable                ), // output
    .rom_stall                  (rom_stall                      )  // input
);


    hkr_mips cpu0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // external interrupts input 
    .hardware_int_in            (hardware_int_in[4:0]           ), // input

        // inst_bus
    .ibus_addr                  (ibus_addr[31:0]                ), // output
    .ibus_read                  (ibus_read                      ), // output
    .ibus_write_data            (ibus_write_data[31:0]          ), // output
    .ibus_uncached              (ibus_uncached                  ), // output
    .ibus_byte_en               (ibus_byte_en[3:0]                  ), // output
    .ibus_read_data             (ibus_read_data[31:0]           ), // input
    .ibus_stall                 (ibus_stall                     ), // input

        // data_bus
    .dbus_addr                  (dbus_addr[31:0]                ), // output
    .dbus_read                  (dbus_read                      ), // output
    .dbus_write_data            (dbus_write_data[31:0]          ), // output
    .dbus_uncached              (dbus_uncached                  ), // output
    .dbus_byte_en               (dbus_byte_en[3:0]                  ), // output
    .dbus_read_data             (dbus_read_data[31:0]           ), // input
    .dbus_stall                 (dbus_stall[31:0]               )  // input
);

    fake_ram ram0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

    .address                    (inst_ram_addr[29:0]                  ), // input
    .data_i                     (write_data_to_inst_ram[31:0]                   ), // input
    .data_o                     (read_data_from_inst_ram[31:0]                   ), // output
    .rd                         (inst_ram_read_enable                             ), // input
    .wr                         (inst_ram_write_enable                             ), // input
    .byte_enable                (ibus_byte_en[3:0]               )  // input
);

    fake_ram ram1(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

    .address                    (data_ram_addr[29:0]                  ), // input
    .data_i                     (write_data_to_data_ram[31:0]                   ), // input
    .data_o                     (read_data_from_data_ram[31:0]                   ), // output
    .rd                         (data_ram_read_enable                             ), // input
    .wr                         (data_ram_write_enable                             ), // input
    .byte_enable                (dbus_byte_en[3:0]              )  // input
);

    fake_rom disk0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

    .address                    (rom_addr[31:0]                  ), // input
    .data                       (read_data_from_rom[31:0]                     )  // output
);

endmodule

`endif
