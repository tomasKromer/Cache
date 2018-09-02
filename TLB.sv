module TLB_L1 #(parameter TamAddr=16, parameter tag=3, parameter index=6, parameter ubi=3)
            (input logic [TamAddr-1:0] address,pc,
             input logic search,
             output logic [7:0] data,
             output logic hitData,
             output logic hitInst,
             output logic [7:0] instr);

logic [67:0] TLB_0_data [0:63];// V,Tag,Data
logic [67:0] TLB_1_data [0:63];
logic [67:0] TLB_0_inst [0:63];
logic [67:0] TLB_1_inst [0:63];
logic LRU_data [0:63];
logic LRU_inst [0:63];    
logic [67:0] indexTag_data_0,indexTag_data_1;
logic [67:0] indexTag_inst_0,indexTag_inst_1;
logic [7:0] dataOut,instruc;
logic hitData_0,hitData_1,hitInstruc_0,hitInstruc_1;

initial
begin
    logic [6:0] i;
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

assign indexTag_data_0 = TLB_0_data[address[8:3]];
assign indexTag_data_1 = TLB_1_data[address[8:3]];
 
 always_comb
    begin
        if(search)
        begin
            hitData_0 = (address[TamAddr-1:TamAddr-1-tag] == indexTag_data_0 [66:64])? 1 : 0;
            hitData_1 = (address[TamAddr-1:TamAddr-1-tag] == indexTag_data_1 [66:64])? 1 : 0;
            if(hitData_0)
                case(address[2:0])
                            3'b000:       dataOut=indexTag_data_0[7:0];  
                            3'b001:       dataOut=indexTag_data_0[15:8]; 
                            3'b010:       dataOut=indexTag_data_0[23:16]; 
                            3'b011:       dataOut=indexTag_data_0[31:24];
                            3'b100:       dataOut=indexTag_data_0[39:32];
                            3'b101:       dataOut=indexTag_data_0[47:40];  
                            3'b110:       dataOut=indexTag_data_0[55:48];  
                            3'b111:       dataOut=indexTag_data_0[63:56];
                            default:      dataOut=0;
                 endcase
           else if(hitData_1)
                 case(address[2:0])
                                       3'b000:       dataOut=indexTag_data_0[7:0];  
                                       3'b001:       dataOut=indexTag_data_0[15:8]; 
                                       3'b010:       dataOut=indexTag_data_0[23:16]; 
                                       3'b011:       dataOut=indexTag_data_0[31:24];
                                       3'b100:       dataOut=indexTag_data_0[39:32];
                                       3'b101:       dataOut=indexTag_data_0[47:40];  
                                       3'b110:       dataOut=indexTag_data_0[55:48];  
                                       3'b111:       dataOut=indexTag_data_0[63:56];
                                       default:      dataOut=0;
                 endcase
           else
                dataOut = 0;   
        end
        hitInstruc_0 = (address[TamAddr-1:TamAddr-1-tag] == indexTag_inst_0 [66:64])? 1 : 0;
        hitInstruc_1 = (address[TamAddr-1:TamAddr-1-tag] == indexTag_inst_0 [66:64])? 1 : 0;
        if(hitInstruc_0)
            case(pc[2:0])
                                3'b000:       instruc=indexTag_inst_0[7:0];  
                                3'b001:       instruc=indexTag_inst_0[15:8]; 
                                3'b010:       instruc=indexTag_inst_0[23:16]; 
                                3'b011:       instruc=indexTag_inst_0[31:24];
                                3'b100:       instruc=indexTag_inst_0[39:32];
                                3'b101:       instruc=indexTag_inst_0[47:40];  
                                3'b110:       instruc=indexTag_inst_0[55:48];  
                                3'b111:       instruc=indexTag_inst_0[63:56];
                                default:      instruc=0;
               endcase
        else if(hitInstruc_1)
               case(pc[2:0])
                                   3'b000:       instruc=indexTag_inst_0[7:0];  
                                   3'b001:       instruc=indexTag_inst_0[15:8]; 
                                   3'b010:       instruc=indexTag_inst_0[23:16]; 
                                   3'b011:       instruc=indexTag_inst_0[31:24];
                                   3'b100:       instruc=indexTag_inst_0[39:32];
                                   3'b101:       instruc=indexTag_inst_0[47:40];  
                                   3'b110:       instruc=indexTag_inst_0[55:48];  
                                   3'b111:       instruc=indexTag_inst_0[63:56];
                                   default:      instruc=0;
                  endcase
        else
                instruc = 0;         
    end

assign hitData = hitData_0 || hitData_1;
assign hitInst = hitInstruc_0 || hitInstruc_1;
assign data = ((hitData_0 || hitData_1) && indexTag_data_0[67]) ? dataOut : 0;
assign instr = (hitInstruc_0 || hitInstruc_1) ? instruc : 0;
    
endmodule
