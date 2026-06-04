`default_nettype none

module apb_master	#(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 8)(
	input wire PCLK,			// From Clock source
	input wire PRESETn,			// From System bus reset (active low)
	input wire transfer,		// From Bridge to APB Master
	input wire read_write,		// From Bridge to APB Master
	input wire [ADDR_WIDTH:0] APB_WADDR,	// 9 bit address - (MSB-slave sel) From Bridge to APB Master
	input wire [DATA_WIDTH-1:0] APB_WDATA,	// From Bridge to APB Master
	input wire [ADDR_WIDTH:0] APB_RADDR,	// 9 bit address - (MSB-slave sel) From Bridge to APB Master
	input wire PREADY,			// From Slave to APB Master
	input wire [DATA_WIDTH-1:0] PRDATA,		// From Slave to APB Master
	input wire PSLVERR,			// Error signal from slave to APB Master
	output reg PWRITE,			
	output reg PENABLE,
	output reg PSEL1, PSEL2,
	output reg [ADDR_WIDTH-1:0] PADDR,
	output reg [DATA_WIDTH-1:0] PWDATA,
	output reg [DATA_WIDTH-1:0] PRDATA_OUT
);

// State parameterization
localparam IDLE = 3'b001,
		   SETUP = 3'b010,
		   ACCESS = 3'b100;

// register declaration
reg [2:0] PS, NS;

// Preset State Logic
always@(posedge PCLK)
begin
	if(!PRESETn)
	begin
		PS <= IDLE;
	end
	else
	begin
		PS <= NS;
	end
end

// Next state Logic
always@(*)
begin
	case(PS)
	IDLE: begin
		if(transfer)
		begin
			NS = SETUP;
		end
		else
		begin
			NS = IDLE;
		end
	end
	SETUP: begin
		NS = ACCESS;
	end
	ACCESS: begin
		if(!PREADY)
		begin
			NS = ACCESS;
		end
		else if(PREADY && transfer)
		begin
			NS = SETUP;
		end
		else if(PREADY && (!transfer))
		begin
			NS = IDLE;
		end
		else begin
			NS = IDLE;
		end
	end
	default: NS = IDLE;
	endcase
end

// output Logic
always@(posedge PCLK)
begin
	case(PS)
	IDLE: begin
		PRDATA_OUT <= PRDATA_OUT;
		if(transfer)
		begin
			PWRITE <= read_write;
			PENABLE <= 0;
			if(read_write)
			begin
				PSEL1 <= ~APB_WADDR[ADDR_WIDTH];
				PSEL2 <= APB_WADDR[ADDR_WIDTH];
				PWDATA <= APB_WDATA;
				PADDR <= APB_WADDR[ADDR_WIDTH-1:0];
			end
			else
			begin
				PSEL1 <= ~APB_RADDR[ADDR_WIDTH];
				PSEL2 <= APB_RADDR[ADDR_WIDTH];
				PADDR <= APB_RADDR[ADDR_WIDTH-1:0];
				PWDATA <= PWDATA;
			end
		end
		else begin
			PSEL1 <= 0;
			PSEL2 <= 0;
			PWDATA <= 0;
			PADDR <= 0;
			PWRITE <= 0;
			PENABLE <= 0;
		end
	end
	SETUP: begin
		PWRITE <= read_write;
		PENABLE <= 1;
		PADDR <= PADDR;
		PWDATA <= PWDATA;
		PSEL1 <= PSEL1;
		PSEL2 <= PSEL2;
		if(PREADY && !read_write && !PSLVERR)
		  PRDATA_OUT <= PRDATA;
		else
		  PRDATA_OUT <= PRDATA_OUT;
	end
	ACCESS: begin
		PWRITE <= PWRITE;
		PENABLE <= PENABLE;
		PADDR <= PADDR; 
		PWDATA <= PWDATA;
		PSEL1 <= PSEL1;
		PSEL2 <= PSEL2;
		PRDATA_OUT <= PRDATA_OUT;
	end
	default: begin
		PSEL1 <= 0;
		PSEL2 <= 0;
		PWDATA <= 0;
		PADDR <= 0;
		PWRITE <= 0;
		PENABLE <= 0;
		PRDATA_OUT <= 0;
	end
	endcase
end

endmodule

