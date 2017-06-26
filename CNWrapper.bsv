package CNWrapper;
import Vector::*;
import FIFOF::*;
import OneCNA::*;
import BuildVector::*;

import MemUtil::*;
import PolymorphicMem::*;
typedef Bit#(32) OperandType;
module mkCNWrapper(CoarseMemServerPort#(32,2));
	//instantiate the CA
	OneCNA#(Bit#(32),4) nna <- mkOneCNA;
	
	Vector#(4, Reg#(Bit#(32))) kernel <- replicateM(mkReg(0));
	//unguarded FIFOs allow enq/deq to be dropped if FIFO is full/empty, respectively	
	FIFOF#(OperandType) inputFIFO <- mkUGFIFOF;	
	FIFOF#(OperandType) outputFIFO <- mkUGFIFOF;
	
	//refill outputFIFO if it is not full
	rule refillOutput(outputFIFO.notFull() && nna.isReady()==1);
		let responseProduced <- nna.response();
		outputFIFO.enq(responseProduced);
	endrule
	//throw away junk values until values are ready
	rule removeJunk(nna.isReady() == 0);
		let temp <- nna.response();
	endrule
	//send a packet to accel if inputFIFO is not empty 
	rule refillInput(inputFIFO.notEmpty());
		nna.request(inputFIFO.first());
		inputFIFO.deq();
	endrule
	Reg#(Bit#(32)) initReg = (interface Reg;
                                    method Action _write(Bit#(32) x);
                                        if (x == 1) begin
                                            nna.initHorizontal(readVReg(kernel));
                                        end
                                    endmethod
                                    method Bit#(32) _read();
                                        return nna.hasInit();
                                    endmethod
                                endinterface);
	
	Reg#(Bit#(32)) enqReg = (interface Reg;
                                    method Action _write(Bit#(32) x);
                                        inputFIFO.enq(x);
                                    endmethod
                                    method Bit#(32) _read;
                                        return inputFIFO.first();
                                    endmethod
                        endinterface);
	Reg#(Bit#(32)) deqReg = (interface Reg;
                                    method Action _write(Bit#(32) x);
                                        outputFIFO.deq();
                                    endmethod
                                    method Bit#(32) _read;
                                        return outputFIFO.first();
                                    endmethod
                        endinterface);
    	Reg#(Bit#(32)) canDeqReg = (interface Reg;
				method Action _write(Bit#(32) x);
				endmethod

				method Bit#(32) _read;
					return zeroExtend(pack(outputFIFO.notEmpty));
				endmethod 
			endinterface);
    	
	Reg#(Bit#(32)) canEnqReg = (interface Reg;
				method Action _write(Bit#(32) x);
				endmethod

				method Bit#(32) _read;
					return zeroExtend(pack(inputFIFO.notFull));
				endmethod 
			endinterface);

    	CoarseMemServerPort#(32,2) memoryInterface <- mkPolymorphicMemFromRegs( vec( asReg(kernel[0]), kernel[1], kernel[2], kernel[3], initReg, enqReg, deqReg, canDeqReg ) );

    	return memoryInterface;
endmodule
endpackage
