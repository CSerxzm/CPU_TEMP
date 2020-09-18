`include "defines.v"

module data_ram(

	input	wire	clk,
	input wire		ce,
	input wire		we,
	input wire[`DataAddrBus]	addr,
	input wire			sel,
	input wire[`DataBus]		data_i,
	output reg[`DataBus]		data_o
	
);

	reg[`ByteWidth]  data_mem0[0:`DataMemNum-1];
	reg[`ByteWidth]  data_mem1[0:`DataMemNum-1];
	reg[`ByteWidth]  data_mem2[0:`DataMemNum-1];
	reg[`ByteWidth]  data_mem3[0:`DataMemNum-1];

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
            //
		end else if(we == `WriteEnable) begin
			{data_mem3[addr[`DataMemNumLog2+1:2]],
             data_mem2[addr[`DataMemNumLog2+1:2]],
             data_mem1[addr[`DataMemNumLog2+1:2]],
             data_mem0[addr[`DataMemNumLog2+1:2]]}<=data_i;		   	    
		end
	end
	
	always @ (*) begin
		if (ce == `ChipDisable) begin
			data_o <= `ZeroWord;
	  end else if(we == `WriteDisable) begin
		    data_o <= {data_mem3[addr[`DataMemNumLog2+1:2]],
		               data_mem2[addr[`DataMemNumLog2+1:2]],
		               data_mem1[addr[`DataMemNumLog2+1:2]],
		               data_mem0[addr[`DataMemNumLog2+1:2]]};
		end else begin
				data_o <= `ZeroWord;
		end
	end		

endmodule