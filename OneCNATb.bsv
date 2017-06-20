import Vector::*;
import OneCNA::*;

module mkTbOneCNA();
	Reg#(Bit#(64)) cycles <- mkReg(0);
	Reg#(Bit#(64)) requests <- mkReg(0);
	Reg#(Bool) isInit <- mkReg(True);	
        //kernel
        Vector#(KERNEL_SIZE, OperandType) kernel; //adjust later 
		
	kernel[0] = 0;
	kernel[1] = 1;
	kernel[2] = 2;
	kernel[3] = 3;
	//vector with 1000 elements
	Vector#(1000,Bit#(32)) operations = newVector;	

	//vector of correct outputs	
	Vector#(1013,Bit#(32)) correctOutputs= newVector;	
	
	
	for(Integer i=0;i<1000;i=i+1) begin
		operations[i] = fromInteger(i);
	end
	
	operations[0] = 23;
	operations[1] = 3;
	operations[2] = 53;
	operations[3] = 39;
	operations[4] = 34;
	operations[5] = 14;
	operations[6] = 59;
	operations[7] = 99;
	operations[8] = 35;
	operations[8] = 83;
	
	//test cases
	for(Integer j=0;j<100;j=j+1) begin
		for(Integer k=0; k<valueOf(KERNEL_SIZE); k=k+1) begin
			correctOutputs[j+2] = correctOutputs[j+2]+(kernel[valueOf(KERNEL_SIZE)-1-k]*operations[k]); 	
		end
	end
	//print the autogenerate list
	//count the number of cycles
	rule cycle_count;
		cycles <= cycles + 1;
	endrule

	OneCNA nna <- mkOneCNA;
	rule first(isInit);
		isInit <= False;	
		nna.initHorizontal();	
	endrule	
	rule request(!isInit);
		nna.request(operations[requests]);	
		requests <= requests+1;
		//$display("Enqueuing into FIFO: %d", 0);
	endrule	
	
	rule respond(!isInit);
		Bit#(32) outputValue <- nna.response();	
		if(correctOutputs[requests+4] == outputValue) begin
			$display("PASS");
		end
		$display("Response Produced: %d", outputValue);
	endrule	
	
	rule finish(requests==100);
		$finish(0);
	endrule

endmodule
