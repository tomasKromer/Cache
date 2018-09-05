//Falta implementar logica del estado alocate, y el write

module TLB_L1 #(parameter TamAddr=16, parameter tag=3, parameter index=6, parameter ubi=3)
            (input logic [TamAddr-1:0] address,pc,
             input logic search_i,search_d,clk,rst,
             input logic [63:0] data_write,
             input logic [31:0] inst_write,
             input logic [63:0] dataIn,
             input logic wr_mem,dataComplete,writeComplete,
             output logic [7:0] data,
             output logic hitData,pedirData,
             output logic hitInst,
             output logic [7:0] instr,
             output logic [TamAddr-1:0] address_lvs,pc_lvs);//tag(3),index(6),lugardatos(3)

typedef enum logic[1:0] {idle,buscar,Alocate,write} state_t;
state_t reg_state,next_state;

//Señales adicionales
logic [15:0] address_data,pc_inst;
logic [67:0] TLB_0_data [0:63];// V,Tag,Data
logic [67:0] TLB_1_data [0:63];// V,Tag,Data
logic [67:0] TLB_0_inst [0:63];// V,Tag,Data
logic [67:0] TLB_1_inst [0:63];// V,Tag,Data
logic LRU_data [0:63];//Ultimo dato usado
logic LRU_inst [0:63];//Ultimo dato usado   
logic [67:0] indexTag_data_0,indexTag_data_1,aux;//aux para data 0
logic [67:0] indexTag_inst_0,indexTag_inst_1;//aux para data 1
logic [7:0] dataOut,instruc;//data de salida
logic hitData_0,hitData_1,hitInstruc_0,hitInstruc_1,alocate_i,alocate_d;//aux de hit de dato 0,1 y instruc 0,1

initial//Iniciacion en cero del sistema de memorias
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

//asignacion de señales extra
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
                next_state = (search_i || search_d) ? buscar : idle;// si quiero buscar una instruccion o dato paso a buscar 
        end
    buscar:
        begin
                if(hitData && wr_mem)  
                    next_state = write; // si no encuentro el dato paso a escribir
                else if(hitInst && wr_mem)
                    next_state = write;//si no la encuentro y era escritura paso a escribir 
                else if(hitInst || hitData)
                    next_state = idle;//si encuentro la instruccion paso a esperar o si encuentro el dato paso a esperar 
                else if(~hitInst && wr_mem)
                    next_state = write;//si no la encuentro y era escritura paso a escribir   
                else if(~hitInst)
                    next_state = Alocate;//no tuve hit y no era una escritura
                else if(~hitData && wr_mem)  
                    next_state = write; // si no encuentro el dato paso a escribir
                else if(~hitData)
                    next_state = Alocate;//no tuve hit y no era una escritura
                else
                    next_state = idle;                     
        end                   
    Alocate:          
        begin
                if(dataComplete)
                    next_state = buscar;//Si termine de cargar los datos paso a buscarlos
                else
                    next_state = Alocate;//Si no termine sigo esperando           
        end
    write:
        begin
                if(writeComplete)
                    next_state = idle;//si termine de escribir paso a esperar
                else
                    next_state = write;//si todavia no termine de escribir espero             
        end
    default:
        begin
                next_state = idle;
        end
    endcase


//Logica de señales de salida    
always_comb
        case(reg_state)
        idle://si estoy esperando todas las señales en cero
            begin
                    data = 0;
                    hitData = 0;
                    hitInst = 0;
                    instr = 0;
                    pedirData = 0;
            end
        buscar:
            begin
                    if(search_d && wr_mem)//Si estoy buscando un dato para escribir
                    begin
                        if(hitData_0)//si lo encontre lo escribo
                        begin
                            TLB_0_data[address[8:3]] = data_write;
                            LRU_data[address[8:3]] = 0;
                        end
                        else if(hitData_1)//si lo encontre lo escribo
                        begin
                            TLB_1_data[address[8:3]] = data_write;
                            LRU_data[address[8:3]] = 1;
                        end
                        hitData = hitData_0 || hitData_1; //aviso del hit
                    end
                    else if (search_d)//estoy buscando un dato
                    begin
                        if(hitData_0)// si lo encontre en el TLB_0
                        begin
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
                            hitData = hitData_0;//aviso de hit
                            LRU_data [address[8:3]] = 0;
                        end
                        else if(hitData_1)// si lo encontre en el TLB_1
                        begin
                            case(address[2:0])
                                               3'b000:       dataOut=indexTag_data_1[7:0];  
                                               3'b001:       dataOut=indexTag_data_1[15:8]; 
                                               3'b010:       dataOut=indexTag_data_1[23:16]; 
                                               3'b011:       dataOut=indexTag_data_1[31:24];
                                               3'b100:       dataOut=indexTag_data_1[39:32];
                                               3'b101:       dataOut=indexTag_data_1[47:40];  
                                               3'b110:       dataOut=indexTag_data_1[55:48];  
                                               3'b111:       dataOut=indexTag_data_1[63:56];
                                               default:      dataOut=0;
                            endcase
                            hitData = hitData_1;//aviso de hit
                            LRU_data [address[8:3]] = 1;
                        end 
                        else
                            begin
                                alocate_d = search_d;
                                dataOut = 0;
                                hitData = 0;//aviso de no encontre nada
                                address_data = address;
                                pedirData = 0;
                            end
                    if(search_i && wr_mem)//Si estoy buscando una instruc para escribir
                    begin
                        if(hitInstruc_0)//Si la encontre escribo
                        begin
                            TLB_0_inst[address[8:3]] = inst_write;
                            LRU_inst[address[8:3]] = 0;
                        end
                        else if(hitInstruc_1)//Si la encontre escribo
                        begin
                            TLB_1_inst[address[8:3]] = inst_write;
                            LRU_inst[address[8:3]] = 1;
                        end
                        hitInst = hitInstruc_0 || hitInstruc_1; //aviso del hit
                    end
                    else if(search_i)//Si estoy buscando una instruc para leer
                    begin
                         if(hitInstruc_0)//Si la encontre saco la instruc
                         begin
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
                            hitInst = hitInstruc_0;//Aviso de hit
                            LRU_inst[address[8:3]] = 0;
                         end
                         else if(hitInstruc_1)//Si la encontre saco la instruc
                            begin
                               case(pc[2:0])
                                                   3'b000:       instruc=indexTag_inst_1[7:0];  
                                                   3'b001:       instruc=indexTag_inst_1[15:8]; 
                                                   3'b010:       instruc=indexTag_inst_1[23:16]; 
                                                   3'b011:       instruc=indexTag_inst_1[31:24];
                                                   3'b100:       instruc=indexTag_inst_1[39:32];
                                                   3'b101:       instruc=indexTag_inst_1[47:40];  
                                                   3'b110:       instruc=indexTag_inst_1[55:48];  
                                                   3'b111:       instruc=indexTag_inst_1[63:56];
                                                   default:      instruc=0;
                                endcase
                                hitInst = hitInstruc_1;//Aviso de hit
                                LRU_inst[address[8:3]] = 1;
                            end
                         else//no hubo hit, aviso 
                         begin
                                instruc = 0;
                                hitInst = 0;
                                alocate_i = search_i;
                                pc_inst = pc;
                                pedirData = 0;
                         end
                    end        
                  end                            
            end                   
        Alocate:          
            begin
                  if(alocate_d)//necesito alocar datos
                  begin
                    pedirData = 1;//pido data
                    address_lvs = address_data;//Paso el adress al nivel siguiente
                    if(~dataComplete)//si no termino el paso de datos
                       if(LRU_data[address_lvs[9:3]])//cual es el mas reciente
                            begin
                                aux = TLB_0_data[address_lvs[9:3]];
                                aux [67] = 1;
                                TLB_0_data[address_lvs[9:3]] = {aux[67:64],dataIn};
                            end 
                       else
                            begin
                                aux = TLB_1_data[address_lvs[9:3]];
                                aux [67] = 1;
                                TLB_1_data[address_lvs[9:3]] = {aux[67:64],dataIn};
                            end
                  end
                  else if(alocate_i)//necesito alocar instrucciones
                  begin
                    pedirData = 1;//pido data
                    address_lvs = pc_inst;//Paso el address al nivel siguiente
                    if(~dataComplete)//si no termino el paso de datos
                       if(LRU_inst[address_lvs[9:3]])//cual es el mas reciente
                       begin
                          aux = TLB_0_inst[address_lvs[9:3]];
                          aux [67] = 1;
                          TLB_0_inst[address_lvs[9:3]] = {aux[67:64],dataIn};
                       end 
                       else
                       begin
                          aux = TLB_0_inst[address_lvs[9:3]];
                          aux [67] = 1;
                          TLB_1_inst[address_lvs[9:3]][63:0] = {aux[67:64],dataIn};
                       end
                  end            
            end
        write:
            begin
                  //agregar logica            
            end
        default:
            begin             
                 data=0;
                 hitData = 0;
                 hitInst = 0;
                 instr = 0;
            end
        endcase
 
    
endmodule
