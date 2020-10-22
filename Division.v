// Division

module Division #(
					parameter	W	 =	8,
								CBIT =  4	// CBIT = log2(W) + 1 
				)(
					input 			clk,    // Clock
					input 			rst, 	// Asynchronous reset active high
					input			start,
					input  [W-1:0]	dvsr,dvnd,
					output reg		ready,done,
					output [W-1:0]	quo,rmd
				);


//	State Declaration
	localparam [1:0]	IDLE	=	2'b00,
						OPERATE	=	2'b01,
						LAST	=	2'b10,
						DONE 	=	2'b11;

//	Signal Declaration
	reg [1:0]		state_reg, state_next;
	reg [W-1:0]		rh_reg, rh_next, rl_reg, rl_next, rh_temp;
	reg [W-1:0]		d_reg, d_next;
	reg [CBIT-1:0]	n_reg, n_next;
	reg 			q_bit;


// 	FSM State & Data Registers
	always@(posedge clk or posedge rst)
		if(rst)
			begin
				state_reg	<=	IDLE;
				rh_reg		<=	0;
				rl_reg		<=	0;
				d_reg		<=	0;
				n_reg		<=	0;
			end
		else
			begin
				state_reg	<=	state_next;
				rh_reg		<=	rh_next;
				rl_reg		<=	rl_next;
				d_reg		<=	d_next;
				n_reg		<=	n_next;
			end

// 	Next State Logic
	always@(*)
		begin
			state_next	=	state_reg;
			ready		=	1'b0;
			done 		= 	1'b0;
			rh_next		=	rh_reg;
			rl_next		=	rl_reg;
			d_next 		=	d_reg;
			n_next 		=	n_reg;

			case (state_reg)
				IDLE	:	begin
								ready	=	1'b1;
								if(start)
									begin
										rh_next		=	0;
										rl_next		=	dvnd;	//	Dividend
										d_next		=	dvsr;	//	Divisor
										n_next 		=	CBIT;	//	Index
										state_next	=	OPERATE;
									end
							end	
				
				OPERATE	:	begin
								// Shift rh and rl left
								rl_next			=	{rl_reg[W-2:0],q_bit};
								rh_next			=	{rh_reg[W-2:0],rl_reg[W-1]}; 

								// Declare Index
								n_next			=	n_reg - 1;
								
								if(n_next == 1)
									state_next	=	LAST;
							end		
				
				// Last Iteration
				LAST 	: 	begin
								rl_next		=	{rl_reg[W-2:0],q_bit};
								rh_next 	=	rh_temp;
								state_next 	=	DONE;
							end

				DONE 	:	begin
								done 		=	1'b1;
								state_next	=	IDLE;
							end
				default	:		state_next	=	IDLE;

			endcase
		end
	

// 	Compare and Subtract
	always@(*)
		if(rh_reg >= d_reg)
			begin
				rh_temp	=	rh_reg - d_reg;
				q_bit 	=	1'b1;
			end
		else
			begin
				rh_temp =	rh_reg;
				q_bit	=	1'b0;
			end

// Outputs
	assign	quo	=	rl_reg;
	assign 	rmd	=	rh_reg; 

endmodule