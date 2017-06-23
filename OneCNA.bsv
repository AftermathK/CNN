package OneCNA;
import Vector::*;
import SpecialFIFOs::*;
import FIFOF::*;
typedef 4 WAIT_TIME;

interface OneCNA#(type operandType, numeric type kernelSize);
        method Action initHorizontal(Vector#(kernelSize, operandType) inputKernel); 
	method  operandType isReady();	
	method Action request(operandType req);
        method ActionValue#(operandType) response;

endinterface
module mkOneCNA(OneCNA#(operandType, kernelSize)) provisos (Bits#(operandType, a__), Arith#(operandType), Literal#(operandType));
	//if initializing
	Reg#(Bool) isInit <- mkReg(True);
        
	//how long have we waited
	Reg#(Bit#(32)) currWait <- mkReg(0);
	//horizontal queue vector
        Vector#(kernelSize, FIFOF#(operandType)) horizontalStream <- replicateM(mkLFIFOF);
		
        //depth of the adder tree
        Integer depthSize = log2(valueOf(kernelSize));
       	
	Reg#(Vector#(kernelSize, operandType)) kernel <- mkReg(replicate(0)); 
	
	//tree queue vector of vectors-may seem as a waste of space but compiler will handle 
        //the optimizations
        Vector#(TAdd#(TLog#(kernelSize),1), Vector#(kernelSize, FIFOF#(operandType))) adderTree;
        for(Integer m=0; m<=log2(valueOf(kernelSize)); m=m+1) begin
		adderTree[m] <-replicateM(mkLFIFOF);
	end
	    


	//construct the adder trees rules 
       	Integer currentPower = valueOf(kernelSize);
	Integer addRange = currentPower-2; //how far will we have to do allow a level to add all the numbers
        for(Integer i=0; i<depthSize; i=i+1) begin
            for(Integer j=0; j <= addRange; j=j+2) begin
		rule adderTreeRules;
                    //$display("Pushing in %d at level: %d in FIFO: %d", adderTree[i][j].first() + adderTree[i][j+1].first(), i+1,j/2);
                    adderTree[i+1][j/2].enq(adderTree[i][j].first() + adderTree[i][j+1].first());
                    adderTree[i][j].deq();
                    adderTree[i][j+1].deq();
                endrule
            end
	    currentPower = currentPower/2;
	    addRange = currentPower-2;
        end 
            
        //create all of the rules needed for the top horizontal stream
        for(Integer i=0; i<=valueOf(kernelSize)-1; i=i+1) begin
                rule streamRules;
                        if(i == valueOf(kernelSize)-1) begin
			    //$display("Dequeuing from FIFO: %d", i);
                            //perform multiplications needed here
                            adderTree[0][i].enq(horizontalStream[i].first()*kernel[i]); 
		    	    //$display("Pushing %d into adder tree [0, %d]", horizontalStream[i].first()*kernel[i], i);
                            horizontalStream[i].deq();
                        end
                        else begin
                            //$display("Pushing %d into FIFO: %d", horizontalStream[i].first(),i+1);
			    //$display("Dequeuing from FIFO: %d", i);
                            horizontalStream[i+1].enq(horizontalStream[i].first());
                            //perform multiplications needed here
		    	    //$display("Pushing %d into adder tree [0, %d]", horizontalStream[i].first()*kernel[i], i);
                            adderTree[0][i].enq(horizontalStream[i].first()*kernel[i]); 
                            horizontalStream[i].deq();
                        end

                endrule 
        end 
            
                    
	//method for initiating variables
	method Action initHorizontal(Vector#(kernelSize, operandType) kernelInput);
		kernel <= kernelInput;
		for(Integer i=0; i<valueOf(kernelSize); i=i+1) begin
			horizontalStream[i].enq(0);
		end		
	endmethod            
        //methods for interaction with accelerator
	method operandType isReady();
		if(currWait < fromInteger(valueOf(WAIT_TIME))) begin
			return 0;
		end							
		else begin
			return 1;
		end	
	endmethod	
	method Action request(operandType req);
		horizontalStream[0].enq(req);  
        endmethod

        method ActionValue#(operandType) response();
		if(currWait != fromInteger(valueOf(WAIT_TIME))) begin
			currWait <= currWait + 1;
		end		                
                adderTree[log2(valueOf(kernelSize))][0].deq();
                return adderTree[log2(valueOf(kernelSize))][0].first();
        endmethod           
endmodule
endpackage
