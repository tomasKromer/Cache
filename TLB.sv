module TLB_L1 #(parameter TamAddr=16, parameter tag=3, parameter index=6, parameter ubi=3)
            (input logic [TamAddr-1:0] address,pc,
             input logic search,
             output logic [7:0] data,
             output logic hitData,
             output logic [7:0] instr);

logic [67:0] TLB_0_data [0:63];// V,Tag,Data
logic [67:0] TLB_1_data [0:63];
logic [67:0] TLB_0_inst [0:63];
logic [67:0] TLB_1_inst [0:63];
logic LRU_data [0:63];
logic LRU_inst [0:63];    
logic [67:0] indexTag;
logic [7:0] dataOut;

initial
begin
    logic [5:0] i;
    for(i=0; i<64;i++)
    begin
      LRU_inst[i] = 0;
      LRU_data[i] = 0;
      TLB_1_data[i] = 0;
      TLB_0_data[i] = 0;
      TLB_1_inst[i] = 0;
      TLB_0_inst[i] = 0;
    end
end

assign indexTag = TLB_0_data[address[8:3]];
 
 always_comb
    begin
        if(search)
        begin
            hitData = (address[TamAddr-1:TamAddr-1-tag] == indexTag [66:64])? 1 : 0;
            case(address[2:0])
                3'b000:       dataOut=indexTag[7:0];  
                3'b001:       dataOut=indexTag[15:8]; 
                3'b010:       dataOut=indexTag[23:16]; 
                3'b011:       dataOut=indexTag[31:24];
                3'b100:       dataOut=indexTag[39:32];
                3'b101:       dataOut=indexTag[47:40];  
                3'b110:       dataOut=indexTag[55:48];  
                3'b111:       dataOut=indexTag[63:56];
                default:      dataOut=0;
             endcase
        end         
    end

assign data = hitData ? dataOut : 0;
    
endmodule
