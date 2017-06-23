package CNWrapper;
import Vector::*;
import FIFOF::*;
import OneNNA::*;

typedef  enum {
	WriteKernel0,
	WriteKernel1,
	WriteKernel2,
	WriteKernel3,
	InitAccel,
	EnqInputData,
	DeqOutputData,
	ReadKernel0,
	ReadKernel1,
	ReadKernel2,
	ReadKernel3,
	IsAccelInit,
	OutputDataReady,
	ReadOutputData

} ReqCode;
typedef struct{
	ReqCode code;
	Bit#(32) data;
}SpecialAcceleratorRequest(Bits, Eq, FShow);

interface CNWrapper;
	method Action request(SpecialAcceleratorRequest req);
	method ActionValue#(Bit#(32)) response(SpecialAcceleratorRequest req);
endinterface

module mkCNWrapper();
	//instantiate the CA
	OneNNA#(Bit#(32),4) nna <- mkOneCNA;
	
	Vector#(4, Reg#(Bit#(32)) kernel <- replicateM(mkReg(0));
	//unguarded FIFOs allow enq/deq to be dropped if FIFO is full/empty, respectively	
	FIFOF#(SpecialAcceleratorRequest, 2) inputFIFO <- mkUGFIFOF;	
	FIFOF#(SpecialAcceleratorRequest, 2) outputFIFO <- mkUGFIFOF;
	
	//refill outputFIFO if it is not full
	rule refillOutput(!outputFIFO.isFull());
		outputFIFO.enq(nna.response());
	endrule
	//send a packet to accel if inputFIFO is not empty 
	rule refillInput(!inputFIFO.isEmpty());
		nna.request(inputFIFO.first());
		inputFIFO.deq();
	endrule	
	method Action request(SpecialAcceleratorRequest req);
		case(req.code)
			WriteKernel0: 	kernel[0] <= req.data;
			WriteKernel1:	kernel[1] <= req.data;
			WriteKernel2: 	kernel[2] <= req.data;
			WriteKernel3: 	kernel[3] <= req.data;
			InitAccel:  	nna.initHorizontal();
			EnqInputData:	inputFIFO.enq(req.data);
			DeqOutputData:	outputFIFO.deq();
			
		endcase	
	endmethod	
	method ActionValue#(Bit#(32)) response(SpecialAcceleratorRequest req);
		case(req.code)
			OutputDataReady: return nna.isReady();	
			IsAccelInit: return nna.isInit();
			ReadOutputData: return outputFIFO.first();
		endcase	
	endmethod	

endmodule
endpackage
