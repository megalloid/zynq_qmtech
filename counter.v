`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: -
// Engineer: megalloid
// 
// Create Date: 08/14/2021 02:51:56 PM
// Design Name: Zynq Multichannel Counter
// Module Name: counter
// Project Name: -
// Target Devices: -
// Tool Versions: -
// Description: Pulses counter
// 
// Dependencies: -
// 
// Revision: -
// Revision 0.01 - File Created
// Additional Comments: -
// 
//////////////////////////////////////////////////////////////////////////////////


module counter(
    input pulse_i,          // Входной порт для сгенерированных импульсов
    input rst_i,            // Вход для сигнала сброса значения счетчика
    input ena_i,            // Вход для сигнала на разрешение считать импульсы
    output [31:0] cnt_o       // Выходной сигнал значения счётчика
    );
    
   reg[31:0] cnt_r = 0;     // Регистр для хранения значения счётчика
    
   assign cnt_o = cnt_r;      // Присваиваем регистр к выходному порту
        
   always @ (posedge pulse_i or negedge rst_i) begin    // Каждый раз когда будет получен сигнал сброса или импульса
	
		if (~rst_i) begin 
			cnt_r <= 32'b0;                              // Сбрасываем счетчик
		end
		else if(pulse_i && ena_i) begin
			cnt_r <= cnt_r + 1'b1;                       // Или считаем если было разрешение на счёт
		end
	end
    
endmodule

