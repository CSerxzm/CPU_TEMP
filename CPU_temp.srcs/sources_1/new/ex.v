`include "defines.v"

module ex(

	input wire										rst,
	
	//送到执行阶段的信息
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	
    input wire                    is_in_delayslot_i,
    
    input wire[`RegBus]           inst_i,	
	
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]						wdata_o,
	
	//下面新增的几个输出是为加载、存储指令准备的
    output wire[`AluOpBus]        aluop_o,
    output wire[`RegBus]          mem_addr_o,
    output wire[`RegBus]          reg2_o,
	
	output reg										stallreq
	
);

	reg[`RegBus] logicout;
	reg[`RegBus] shiftres;
	reg[`RegBus] moveres;
	reg[`RegBus] arithmeticres;	

	wire ov_sum;
	wire[`RegBus] reg2_i_mux;//补码
    wire[`RegBus] reg1_i_not;//取反
    wire[`RegBus] result_sum;//加法结果
    
    
    //aluop_o传递到访存阶段，用于加载、存储指令
    assign aluop_o = aluop_i;
    
    //mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
  
    //将两个操作数也传递到访存阶段，也是为记载、存储指令准备的
    assign reg2_o = reg2_i;
		
	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OR_OP:			begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_AND_OP:		begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_NOR_OP:		begin
					logicout <= ~(reg1_i |reg2_i);
				end
				`EXE_XOR_OP:		begin
					logicout <= reg1_i ^ reg2_i;
				end
				default:				begin
					logicout <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always

	always @ (*) begin
		if(rst == `RstEnable) begin
			shiftres <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_SLL_OP:			begin
					shiftres <= reg2_i << reg1_i[4:0] ;
				end
				`EXE_SRL_OP:		begin
					shiftres <= reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP:		begin
					shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) 
												| reg2_i >> reg1_i[4:0];
				end
				default:				begin
					shiftres <= `ZeroWord;
				end
			endcase
		end    //if
	end      //always


	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
											 (aluop_i == `EXE_SLT_OP) ) 
											 ? (~reg2_i)+1 : reg2_i;

	assign result_sum = reg1_i + reg2_i_mux;										 

	assign ov_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
									((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31])); 
									
    assign reg1_i_not = ~reg1_i;
    
	always @ (*) begin
        if(rst == `RstEnable) begin
            arithmeticres <= `ZeroWord;
        end else begin
            case (aluop_i)
                `EXE_ADD_OP,`EXE_ADDI_OP:        begin
                    arithmeticres <= result_sum; 
                end
                `EXE_SUB_OP:        begin
                    arithmeticres <= result_sum; 
                end        
                default:                begin
                    arithmeticres <= `ZeroWord;
                end
            endcase
        end
    end    
    
	always @ (*) begin
		if(rst == `RstEnable) begin
	  	moveres <= `ZeroWord;
	  end else begin
	   moveres <= `ZeroWord;
	   case (aluop_i)
	   	`EXE_MOVZ_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	`EXE_MOVN_OP:		begin
	   		moveres <= reg1_i;
	   	end
	   	default : begin
	   	end
	   endcase
	  end
	end	 

 always @ (*) begin
	 wd_o <= wd_i;
	 	 	 	
	 if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) || 
	      (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
	 	wreg_o <= `WriteDisable;
	 end else begin
	  wreg_o <= wreg_i;
	 end
	 
	 case ( alusel_i ) 
	 	`EXE_RES_LOGIC:		begin
	 		wdata_o <= logicout;
	 	end
	 	`EXE_RES_SHIFT:		begin
	 		wdata_o <= shiftres;
	 	end	 	
	 	`EXE_RES_MOVE:		begin
	 		wdata_o <= moveres;
	 	end	 	
	 	`EXE_RES_ARITHMETIC:	begin
	 		wdata_o <= arithmeticres;
	 	end 		
	 	default:					begin
	 		wdata_o <= `ZeroWord;
	 	end
	 endcase
 end	
		
endmodule