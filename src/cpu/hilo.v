`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:59:53 10/20/2016 
// Design Name: 
// Module Name:    hilo 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module hilo(
    input clk,
    input rst_n,
    input we,
    input [63:0] hilo_i, // hilo_i = {hi_i, lo_i}
    output [63:0] hilo_o // hilo_o = {hi_o, lo_o}
    );
    
    always @ (posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hilo_o <= 64'h0;
        end else if (we) begin
            hilo_o <= hilo_i;
        end
    end
    
endmodule
