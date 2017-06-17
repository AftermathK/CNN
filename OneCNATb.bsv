import Vector::*;
import OneCNA::*;

module mkTbOneCNA();
	Reg#(Bit#(64)) cycles <- mkReg(0);
	Reg#(Bit#(64)) requests <- mkReg(0);
	
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
	//vector of correct outputs	
	Vector#(1013,Bit#(32)) actualOutputs= newVector;	
	
	
	for(Integer i=0;i<1000;i=i+1) begin
		operations[i] = fromInteger(i);
	end
		
	//test cases
	for(Integer j=0;j<1000;j=j+1) begin
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
	rule request;
		nna.request(operations[requests]);	
		//$display("Enqueuing into FIFO: %d", 0);
	endrule	
	
	rule respond;
		Bit#(32) outputValue <- nna.response();	
		if(correctOutputs[requests+1] == 0) begin
			$display("PASS");
		end
		requests <= requests+1;
		$display("Response Produced: %d", outputValue);
	endrule	
	
	rule finish(requests==3);
		$finish(0);
	endrule
endmodule
