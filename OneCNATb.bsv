import Vector::*;
import OneCNA::*;
typedef 7 OFFSET;
typedef 4 KERNEL_SIZE;
typedef Bit#(32) OperandType;
module mkTbOneCNA();
	Reg#(Bit#(64)) cycles <- mkReg(0);
	Reg#(Bit#(64)) requests <- mkReg(0);
	Reg#(Bool) isInit <- mkReg(True);	
        //kernel
        Vector#(KERNEL_SIZE, OperandType) kernel; //adjust later 
	//kernel pattern	
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
	operations[9] = 83;
	
	//test cases
	//initialize the vector to 0
	for(Integer j=0;j<1012;j=j+1) begin
			correctOutputs[j] = 0; 	
	end
	//compute the reference values
	for(Integer j=0;j<100;j=j+1) begin
		for(Integer k=0; k<valueOf(KERNEL_SIZE); k=k+1) begin
			correctOutputs[j+valueOf(OFFSET)] = correctOutputs[j+valueOf(OFFSET)]+(kernel[valueOf(KERNEL_SIZE)-1-k]*operations[j+k]); 	
		end
	end
	
	//count the number of cycles
	rule cycle_count;
		cycles <= cycles + 1;
	endrule
	
	OneCNA#(OperandType, KERNEL_SIZE) nna <- mkOneCNA;
	rule first(isInit);
		isInit <= False;	
		nna.initHorizontal(kernel);	
	endrule	
	rule request(!isInit);
		nna.request(operations[requests]);	
		requests <= requests+1;
		//$display("Enqueuing into FIFO: %d", 0);
	endrule	
	
	rule respond(!isInit);
		Bit#(32) outputValue <- nna.response();	
	//	$display("Response Produced: %d",outputValue);
			
		if(correctOutputs[requests] == outputValue) begin
			$display("PASS");
		end
		$display("Was value ready? : %d", nna.isReady());	
		$display("Response Produced: %d and CC: ", outputValue, requests);
		Bit#(32) temp = correctOutputs[requests];
		$display("Actual: %d", temp);

	endrule	
	
	rule finish(requests==100);
		$display("Total number of cycles needed: %d",cycles);
		$finish(0);
	endrule

endmodule
