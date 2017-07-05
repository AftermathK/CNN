package CNWMem;
import Vector::*;
import FIFOF::*;
import OneCNA::*;
import BuildVector::*;
import MemUtil::*;
import Port::*;
import PolymorphicMem::*;
typedef Bit#(32) OperandType;
module mkCNWMem#(CoarseMemServerPort#(32,2) mem)(CoarseMemServerPort#(32,2));
	//instantiate the CA
	OneCNA#(Bit#(32),4) nna <- mkOneCNA;
    Reg#(Bit#(32)) requestCounter <- mkReg(0);
    Reg#(Bit#(32)) valuesSent <- mkReg(0);
    Reg#(Bit#(32)) inputPointerReg <- mkReg(0); 
    Reg#(Bit#(32)) inputLengthReg <- mkReg(0); 
    Reg#(Bit#(32)) outputPointerReg <- mkReg(0);
    //load req
    //mem.request.enq(CoarseMemReq { write: False, addr: , data: 0})
    //store req 
    //mem.request.enq(CoarseMemReq { write: True, addr: , data: })
    //receive response 
    //mem.response.first -> returns CoarseMemResp (struct with write: and data:)
	//mem.response.deq()
    Vector#(4, Reg#(Bit#(32))) kernel <- replicateM(mkReg(0));
	
    
    //throw away junk values until values are ready
	rule removeJunk(nna.isReady() == 0);
		let temp <- nna.response();
	endrule
	
	//write to memory accelerator outputs
	rule writeMem(nna.isReady()==1 && inputLengthReg != 0);
		let responseProduced <- nna.response();
		//enqueue the request to write to memory, but disregard any return values--if any
        mem.request.enq(CoarseMemReq {write: True, addr: outputPointerReg, data: responseProduced});
        //increment the address of the current pointer to prepare for the next write
        outputPointerReg <= outputPointerReg+4;
	endrule
	//read a value from memory
    rule readMem(valuesSent != requestCounter);
        //enqueue the request to read from memory, and save the return value
	    mem.request.enq(CoarseMemReq{write: False, addr: inputPointerReg, data: 0});	
        //count the number of values to be sent into the accelerator 
        valuesSent <= valuesSent + 1; 
        //increment the address of the current pointer to prepare for the next read
        inputPointerReg <= inputPointerReg + 4;
	endrule
	//send a packet to accelerator 
    rule sendToAccel(mem.response.first.write == False);
        let temp = mem.response.first.data;
        mem.response.deq();
        nna.request(temp);
    endrule
    //count the number of writes to memory
    rule countWrites(mem.response.first.write == True);
        //decrese inputLengthReg after a successful write to memory
        inputLengthReg <= inputLengthReg-1;
        mem.response.deq();
    endrule
    
    Reg#(Bit#(32)) initReg = (interface Reg;
        method Action _write(Bit#(32) x);
            if (x == 1) begin
                //how many values are we convolving
                requestCounter <= inputLengthReg;
                //initialize accelerator and set the kernel
                nna.initHorizontal(readVReg(kernel));
            end
        endmethod
        method Bit#(32) _read();
            return nna.hasInit();
        endmethod
    endinterface);
	

    CoarseMemServerPort#(32,2) memoryInterface <- mkPolymorphicMemFromRegs( 
                                    vec( 
                                    asReg(kernel[0]), 
                                    kernel[1], 
                                    kernel[2], 
                                    kernel[3], 
                                    initReg, 
                                    inputPointerReg, 
                                    inputLengthReg, 
                                    outputPointerReg));

    return memoryInterface;
endmodule
endpackage
