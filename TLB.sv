module TLB_L1 #(parameter TamAddr=16, parameter tag=3, parameter index=6, parameter ubi=3)
            (input logic [TamAddr-1:0] address,pc,
             input logic search_i,search_d,clk,rst,
             input logic [63:0] data_write,
             input logic wr_mem,dataComplete,writeComplete,
             output logic [7:0] data,
             output logic hitData,
             output logic hitInst,
             output logic [7:0] instr);

typedef enum logic[1:0] {idle,Validar,Alocate,miss_write} state_t;
state_t reg_state,next_state;

//Señales adicionales
logic [67:0] TLB_0_data [0:63];// V,Tag,Data
logic [67:0] TLB_1_data [0:63];// V,Tag,Data
logic [67:0] TLB_0_inst [0:63];// V,Tag,Data
logic [67:0] TLB_1_inst [0:63];// V,Tag,Data
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

//asignacion de señales extras
assign indexTag_data_0 = TLB_0_data[address[8:3]];
assign indexTag_data_1 = TLB_1_data[address[8:3]];
assign indexTag_inst_0 = TLB_0_inst[address[8:3]];
assign indexTag_inst_1 = TLB_1_inst[address[8:3]];
assign hitData_0 = ((address[TamAddr-1:TamAddr-1-tag] == indexTag_data_0 [66:64]) && indexTag_data_0[67])? 1 : 0;
assign hitData_1 = ((address[TamAddr-1:TamAddr-1-tag] == indexTag_data_1 [66:64]) && indexTag_data_1[67])? 1 : 0;
assign hitInstruc_0 = ((address[TamAddr-1:TamAddr-1-tag] == indexTag_inst_0 [66:64]) && indexTag_inst_0 [67])? 1 : 0;
assign hitInstruc_1 = ((address[TamAddr-1:TamAddr-1-tag] == indexTag_inst_1 [66:64]) && indexTag_inst_0 [67])? 1 : 0;


//transiciones de estado en el clk
always_ff@(posedge clk)
begin
    if(rst)
        reg_state <= idle;
    else
        reg_state <= next_state;
end

//Logica de transiciones de estado
always_comb
    case(reg_state)
    idle:
        begin
                next_state = (search_i || search_d) ? Validar : idle; 
        end
    Validar:
        begin
                if(search_i)
                    if(hitInst)
                        next_state = idle;
                    else if(~hitInst & wr_mem)
                        next_state = miss_write;     
                else if (search_d)
                    if(hitInst)                 
                        next_state = idle;      
                    else if(~hitInst & wr_mem)  
                        next_state = miss_write;                            
        end                   
    Alocate:          
        begin
                if(dataComplete)
                    next_state = Validar;
                else
                    next_state = Alocate;           
        end
    miss_write:
        begin
                if(writeComplete)
                    next_state = Validar;
                else
                    next_state = miss_write;             
        end
    default:
        begin
                next_state = idle;
        end
    endcase


//Logica de señales de salida    
always_comb
        case(reg_state)
        idle:
            begin
                    data = 0;
                    hitData = 0;
                    hitInst = 0;
                    instr = 0;
            end
        Validar:
            begin
                    if(search_i)
                    begin
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
                         begin
                                instruc = 0;
                                hitInst = 0;
                         end
                        hitInst = hitInstruc_0 || hitInstruc_1;
                    end        
                    else if (search_d)
                    begin
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
                            begin
                                dataOut = 0;
                                hitData = 0;
                            end
                        hitData = hitData_0 || hitData_1;
                  end                            
            end                   
        Alocate:          
            begin
                    if(dataComplete)
                        next_state = Validar;
                    else
                        next_state = Alocate;           
            end
        miss_write:
            begin
                    if(writeComplete)
                        next_state = Validar;
                    else
                        next_state = miss_write;             
            end
        default:
            begin
                    next_state = idle;
            end
        endcase
 
    
endmodule
