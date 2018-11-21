module note_sender(input CLOCK_50, input pause, output reg [4:0] exp_notes);
	//*******************************************
	//*              Rate driver                *
	//*******************************************
	
	//drives eighth notes
	
	parameter EIGHTH_NOTE = 25'd13157895;
	
	reg [24:0] CLOCK_COUNT = 25'd0;
	reg EIGHT_PULSE = 1'b0;
	
	always@(posedge CLOCK_50)
	begin
		if (~pause)
			if (CLOCK_COUNT == EIGHTH_NOTE)
			begin
				CLOCK_COUNT <= 25'd0;
				EIGHT_PULSE <= 1'b1;
			end
		
			else
			begin
				CLOCK_COUNT <= CLOCK_COUNT+1;
				EIGHT_PULSE <= 1'b0;
			end
			
	end

	
	reg [8:0] t = 9'd0;
	
	always@(posedge CLOCK_50)
	begin
		if (~pause)
			if (EIGHT_PULSE == 1'b1)
				t <= t+1;
			else if (t == 9'd303)
				t <= 5'd0;
		else if (pause)
			t <= t;
	end
	
	always@(posedge CLOCK_50)
	begin
	
		case(t)
		//CHORUS
			9'd0:
				exp_notes <= 5'b00101;
			9'd2:
				exp_notes <= 5'b01010;
			9'd4:
				exp_notes <= 5'b10100;
			9'd7:
				exp_notes <= 5'b00101;
				
			9'd9:
				exp_notes <= 5'b01010;
			9'd11:
				exp_notes <= 5'b11000;
			9'd12:
				exp_notes <= 5'b10100;
				
			9'd16:
				exp_notes <= 5'b00101;
			9'd18:
				exp_notes <= 5'b01010;
			9'd20:
				exp_notes <= 5'b10100;
			9'd23:
				exp_notes <= 5'b01010;
				
			9'd25:
				exp_notes <= 5'b00101;
				
			9'd32:
				exp_notes <= 5'b00101;
			9'd34:
				exp_notes <= 5'b01010;
			9'd36:
				exp_notes <= 5'b10100;
			9'd39:
				exp_notes <= 5'b00101;
				
			9'd41:
				exp_notes <= 5'b01010;
			9'd43:
				exp_notes <= 5'b11000;
			9'd44:
				exp_notes <= 5'b10100;
				
			9'd48:
				exp_notes <= 5'b00101;
			9'd50:
				exp_notes <= 5'b01010;
			9'd52:
				exp_notes <= 5'b10100;
			9'd55:
				exp_notes <= 5'b01010;
				
			9'd57:
				exp_notes <= 5'b00101;
				
			9'd64:
				exp_notes <= 5'b00101;
			9'd66:
				exp_notes <= 5'b01010;
			9'd68:
				exp_notes <= 5'b10100;
			9'd71:
				exp_notes <= 5'b00101;
				
			9'd73:
				exp_notes <= 5'b01010;
			9'd75:
				exp_notes <= 5'b11000;
			9'd76:
				exp_notes <= 5'b10100;
				
			9'd80:
				exp_notes <= 5'b00101;
			9'd82:
				exp_notes <= 5'b01010;
			9'd84:
				exp_notes <= 5'b10100;
			9'd87:
				exp_notes <= 5'b01010;
				
			9'd89:
				exp_notes <= 5'b00101;
				
			9'd96:
				exp_notes <= 5'b00101;
			9'd98:
				exp_notes <= 5'b01010;
			9'd100:
				exp_notes <= 5'b10100;
			9'd103:
				exp_notes <= 5'b00101;
				
			9'd105:
				exp_notes <= 5'b01010;
			9'd107:
				exp_notes <= 5'b11000;
			9'd108:
				exp_notes <= 5'b10100;
				
			9'd112:
				exp_notes <= 5'b00101;
			9'd114:
				exp_notes <= 5'b01010;
			9'd116:
				exp_notes <= 5'b10100;
			9'd119:
				exp_notes <= 5'b01010;
				
			9'd121:
				exp_notes <= 5'b00101;
				
			//VERSE
			//first four bars
			9'd128:
				exp_notes <= 5'b00111;
			9'd130:
				exp_notes <= 5'b00111;
			9'd132:
				exp_notes <= 5'b00111;
			9'd134:
				exp_notes <= 5'b00111;
				
			9'd136:
				exp_notes <= 5'b00111;
			9'd138:
				exp_notes <= 5'b00111;
			9'd140:
				exp_notes <= 5'b00111;
			9'd142:
				exp_notes <= 5'b00111;
				
			9'd144:
				exp_notes <= 5'b00111;
			9'd147:
				exp_notes <= 5'b01011;
			9'd151:
				exp_notes <= 5'b00111;
				
			9'd154:
				exp_notes <= 5'b00111;
			9'd156:
				exp_notes <= 5'b00111;
			9'd158:
				exp_notes <= 5'b00111;
				
			//second four bars
			9'd160:
				exp_notes <= 5'b00111;
			9'd162:
				exp_notes <= 5'b00111;
			9'd164:
				exp_notes <= 5'b00111;
			9'd166:
				exp_notes <= 5'b00111;
				
			9'd168:
				exp_notes <= 5'b00111;
			9'd170:
				exp_notes <= 5'b00111;
			9'd172:
				exp_notes <= 5'b00111;
			9'd174:
				exp_notes <= 5'b00111;
				
			9'd176:
				exp_notes <= 5'b00111;
			9'd178:
				exp_notes <= 5'b00111;
			9'd180:
				exp_notes <= 5'b01011;
			9'd182:
				exp_notes <= 5'b01011;
				
			9'd184:
				exp_notes <= 5'b00111;
			9'd185:
				exp_notes <= 5'b00111;
			9'd187:
				exp_notes <= 5'b10101;
				
			//third four bars
			9'd192:
				exp_notes <= 5'b00111;
			9'd194:
				exp_notes <= 5'b00111;
			9'd196:
				exp_notes <= 5'b00111;
			9'd198:
				exp_notes <= 5'b00111;
				
			9'd200:
				exp_notes <= 5'b00111;
			9'd202:
				exp_notes <= 5'b00111;
			9'd204:
				exp_notes <= 5'b00111;
			9'd206:
				exp_notes <= 5'b00111;
				
			9'd208:
				exp_notes <= 5'b00111;
			9'd212:
				exp_notes <= 5'b01011;
			9'd215:
				exp_notes <= 5'b00111;
				
			9'd218:
				exp_notes <= 5'b00111;
			9'd220:
				exp_notes <= 5'b00111;
			9'd222:
				exp_notes <= 5'b00111;
				
			//fourth four bars
			9'd224:
				exp_notes <= 5'b00111;
			9'd226:
				exp_notes <= 5'b00111;
			9'd228:
				exp_notes <= 5'b00111;
			9'd230:
				exp_notes <= 5'b00111;
				
			9'd232:
				exp_notes <= 5'b00111;
			9'd234:
				exp_notes <= 5'b00111;
			9'd236:
				exp_notes <= 5'b00111;
			9'd238:
				exp_notes <= 5'b00111;
				
			9'd240:
				exp_notes <= 5'b00111;
			9'd244:
				exp_notes <= 5'b01011;
			9'd247:
				exp_notes <= 5'b00111;
				
			9'd250:
				exp_notes <= 5'b00111;
			9'd252:
				exp_notes <= 5'b00111;
			9'd254:
				exp_notes <= 5'b00111;
				
			//PRE-CHORUS
			9'd256:
				exp_notes <= 5'b10101;
				
			9'd264:
				exp_notes <= 5'b01110;
			9'd268:
				exp_notes <= 5'b01110;
				
			9'd272:
				exp_notes <= 5'b00001;
			9'd274:
				exp_notes <= 5'b00100;
			9'd275:
				exp_notes <= 5'b00001;
			9'd276:
				exp_notes <= 5'b00100;
			9'd277:
				exp_notes <= 5'b00010;
			9'd278:
				exp_notes <= 5'b00001;
			9'd279:
				exp_notes <= 5'b00010;
				
			9'd281:
				exp_notes <= 5'b00001;
			9'd282:
				exp_notes <= 5'b00100;
			9'd283:
				exp_notes <= 5'b00001;
			9'd284:
				exp_notes <= 5'b00100;
			9'd285:
				exp_notes <= 5'b00010;
			9'd286:
				exp_notes <= 5'b00001;
				
			9'd288:
				exp_notes <= 5'b10101;
				
			9'd296:
				exp_notes <= 5'b01110;
			9'd300:
				exp_notes <= 5'b01110;
				
			default: exp_notes <= 5'b00000;
		endcase
	end
	
endmodule
