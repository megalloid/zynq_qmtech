
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: -
// Engineer: megaloid
// 
// Create Date: 08/14/2021 02:39:31 PM
// Design Name: Zynq Multichannel Counter
// Module Name: debouncer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Debouncer for input signals from pins
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module debouncer

// Параметры
#(
    parameter CNT_WIDTH = 4 	// Разрядность счётчика, выбрана подходящая для того, 
// чтобы можно было пропустить высокую частоту счетчика но не больше 2МГц
)

// Порты
(
input clk_i,                // Clock input
input rst_i,                // Reset input
input sw_i,                 // Switch input
 
output reg sw_state_o,  	    // Состояние нажатия клавиши
output reg sw_down_o,        // Импульс "кнопка нажата"
output reg sw_up_o           // Импульс "кнопка отпущена"
);

    reg [1:0] sw_r;                    // Триггер для исключения метастабильных состояний

    always @ (negedge rst_i or posedge clk_i)           
        if (~rst_i)
            sw_r   	<= 2'b00;
        else
            sw_r    <= {sw_r[0], ~sw_i};
        
        
    reg [CNT_WIDTH-1:0] sw_count;       // Счетчик для фиксации состояния
        
    wire sw_change_f = (sw_state_o != sw_r[1]);
    wire sw_cnt_max = &sw_count;
    
    
    always @(negedge rst_i or posedge clk_i) // Каждый положительный фронт сигнала clk_i проверяем, состояние на входе sw_i
        if (~rst_i)
        begin
            sw_count <= 0;
            sw_state_o <= 0;
        end 
        else if(sw_change_f)	             // И если оно по прежнему отличается от предыдущего  
        begin                             // стабильного, то счетчик инкрементируется.
            sw_count <= sw_count + 'd1;
                                                                   
            if(sw_cnt_max)                    // Счетчик достиг максимального значения. 
                sw_state_o <= ~sw_state_o;    // Фиксируем смену состояний.    
        end                                                             
        else                                  // А вот если, состояние опять равно зафиксированному стабильному,
            sw_count <= 0;                    // то обнуляем счет. Было ложное срабатывание               

    always @(posedge clk_i)
    begin
        sw_down_o <= sw_change_f & sw_cnt_max & ~sw_state_o; // Формируем импульс при нажатии кнопки
        sw_up_o <= sw_change_f & sw_cnt_max &  sw_state_o;   // Формируем импульс при отпускании кнопки
    end
                                   
endmodule
