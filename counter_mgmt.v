`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: -
// Engineer: Andrey Zaostrovnykh
// 
// Create Date: 08/14/2021 02:39:31 PM
// Design Name: Zynq Multichannel Counter
// Module Name: counter_mgmt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Management module for counters
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module counter_mgmt(
    input clk_i,                // Вход для сигнала тактирования
    input rst_i,                // Вход для сброса автомата
    input [31:0] cnt_0_data,    // Значение 1-го счетчика
    input [31:0] cnt_1_data,    // Значение 2-го счетчика
    input [31:0] cnt_2_data,    // Значение 3-го счетчика
    output cnt_0_en,           // Включение 1-го счетчика
    output cnt_0_rst,           // Сброс 1-го счетчика
    output cnt_1_en,           // Включение 1-го счетчика
    output cnt_1_rst,           // Сброс 1-го счетчика
    output cnt_2_en,           // Включение 1-го счетчика
    output cnt_2_rst,           // Сброс 1-го счетчика
    output we,            // Сигнал Write Enable
    output [31:0] addr,         // Адрес чтения-записи
    output [31:0] dout,         // Выходные данные для записи в память
    input [31:0] din           // Входные данные при чтении из памяти
    );
    
    reg [31:0] cnt_rst;
    reg [31:0] cnt_en;
    
    assign cnt_0_rst = cnt_rst[0];
    assign cnt_1_rst = cnt_rst[1];
    assign cnt_2_rst = cnt_rst[2];    
    
    assign cnt_0_en = cnt_en[0];
    assign cnt_1_en = cnt_en[1];
    assign cnt_2_en = cnt_en[2];
    
    localparam IDLE = 4'd1;
    localparam EN = 4'd2;
    localparam EN_W = 4'd3;
    localparam EN_R = 4'd4;
    localparam RST = 4'd5;
    localparam RST_W = 4'd6;
    localparam RST_R = 4'd7;
    localparam WRT = 4'd8;
    localparam WRT_W = 4'd9;
    localparam WRT_R = 4'd10;
    
    reg [3:0] state = IDLE;
    
    reg we_r = 1'd0;	
    assign we = we_r;
    
    reg [31:0] addr_r = 32'd0;
    assign addr = addr_r;
    
    reg [31:0] dout_r = 32'd0;
    assign dout = dout_r;    
    
    reg [3:0] reg_choose = 4'h0;
    
    always @(posedge clk_i)
    begin        
       case(state)                
            IDLE: begin			        // Пока состояние IDLE читаем адрес 0x0
                we_r <= 1'b0;
                addr_r <= 32'd0;
            end            
                
            EN: begin			        // Когда получена команда EN читаем адрес 0x4 
                we_r <= 1'b0;		
                addr_r <= 32'd4;
            end
            
            EN_W: begin			        // Получаем значения вкл\выкл счетчиков 
                we_r <= 1'b0;		    // и прочитав переходим к записи в управляющие выходы
                addr_r <= 32'd4;
            end
                
            EN_R: begin			        // Сбрасываем регистр команды
                we_r <= 1'b1;
                addr_r <= 32'd0;
            end
            
            RST: begin			        // Когда получена команда RST читаем адрес 0x8 
                we_r <= 1'b0;		
                addr_r <= 32'd8;
            end
            
            RST_W: begin			    // Получаем значения какие счетчики надо сбросить
                we_r <= 1'b0;		    // и прочитав переходим к записи в управляющие выходы
                addr_r <= 32'd8;
            end
                
            RST_R: begin			    // Сбрасываем регистр команды
                we_r <= 1'b1;
                addr_r <= 32'd0;
            end
            
            WRT: begin			        // Когда получена команда WRT включаем режим записи
                we_r <= 1'b1; 
                addr_r <= 32'h0;                    
            end
            
            WRT_W: begin			    // Делаем пробег по всем адресам и записываем значения
                we_r <= 1'b1;   
                case (reg_choose)
                
                    4'd0: begin 
                    	addr_r <= 32'hC; // Сохраняем по адресу 0xC значение первого счетчика
				        reg_choose <= 4'h1;
                    end  
                    
                    4'd1: begin 
                    	addr_r <= 32'h10; // Сохраняем по адресу 0x10 значение второго счетчика
				        reg_choose <= 4'h2;
                    end  
                    
                    4'd2: begin 
                    	addr_r <= 32'h14; // Сохраняем по адресу 0x14 значение третьего счетчика
				        reg_choose <= 4'h3;
                    end
                    
                    default: begin
                        addr_r <= 32'h0;
                    end
                    
                endcase
            end
            
            WRT_R: begin			// Сбрасываем значения команды
                we_r <= 1'b1;
                addr_r <= 32'd0;  
                reg_choose <= 4'h0;              
            end
            
            default: begin
                we_r <= 1'b0;
                addr_r <= 32'd0;
            end
                            
        endcase
    end
    
    always @(posedge clk_i)		
    begin
        if (rst_i == 1'b1) begin
			state = IDLE;
		end
		else begin
            case(state)	
                
                IDLE: begin			// Если мы находимся в режиме IDLE
                
                    case(din) 		// Смотрим на сигнал din подключенный к BRAM
                    
                        32'd1: begin		// Если получена команда 0x1
                            state <= EN;		// Переходим в EN
                        end
                            
                        32'd2: begin		// Если получена команда 0x2
                            state <= RST;	// Переходим в RST
                        end
                            
                        32'd3: begin		// Если получена команда 0x3
                            state <= WRT;	// Переходим в WRT
                        end
                        
                        default: begin		// Если ни одно из значений не подошло
                            state <= state;	// То остаёмся в том же состоянии
                        end
                        
                    endcase
                end
            
                EN: begin 				
                    state <= EN_W;                    
                end               
                    
                EN_W: begin
                    state <= EN_R; 
                end                
                    
                EN_R: begin                 
                    state <= IDLE;
                end
                
                RST: begin 
                    state <= RST_W;                    
                end
                    
                RST_W: begin
                    state <= RST_R; 
                end
                    
                RST_R: begin                   
                    state <= IDLE;
                end
                
                WRT: begin 
                    state <= WRT_W;                    
                end
       
                WRT_W: begin
                    case (reg_choose)
                            
                        4'd2: begin  
                            state <= WRT_R;
                        end
                            
                        default: begin
                            state <= IDLE;   
                        end
                        
                    endcase
                end
                    
                    
                WRT_R: begin
                    state <= IDLE;
                end
                    
                default: begin
                    state <= IDLE;
                end
                           
            endcase        
        end
    end
    
    always @(posedge clk_i)		
    begin
        
        case(state)               
                    
            EN_R: begin    
                cnt_en[0] <= din[0];
                cnt_en[1] <= din[1];
                cnt_en[2] <= din[2];
                        
                dout_r <= 32'b0;
            end
                    
            RST_R: begin    
                cnt_rst[0] <= din[0];
                cnt_rst[1] <= din[1];
                cnt_rst[2] <= din[2];
                        
                dout_r <= 32'b0;      
            end
       
            WRT_W: begin
                case (reg_choose)
                    
                    4'd0: begin
                        dout_r <= cnt_0_data; 
                    end  
                            
                    4'd1: begin 
                        dout_r <= cnt_1_data;
                    end  
                            
                    4'd2: begin 
                        dout_r <= cnt_2_data;
                    end
                            
                    default: begin
                        dout_r <= 32'h0;
                    end
                        
                endcase
             end
                    
             WRT_R: begin
                dout_r <= 32'b0;
             end
                           
       endcase  
    end
    
endmodule
