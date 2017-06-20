
package OneCNA;
import Vector::*;
import SpecialFIFOs::*;
import FIFOF::*;

typedef 4 KERNEL_SIZE;
typedef Bit#(32) OperandType;

interface OneCNA;
        method Action initHorizontal; 
	method Action request(OperandType req);
        method ActionValue#(OperandType) response;

endinterface
module mkOneCNA(OneCNA);
	//if initializing
	Reg#(Bool) isInit <- mkReg(True);
        //horizontal queue vector
        Vector#(KERNEL_SIZE, FIFOF#(OperandType)) horizontalStream <- replicateM(mkLFIFOF);
		
        //depth of the adder tree
        Integer depthSize = log2(valueOf(KERNEL_SIZE));
       	
	Vector#(KERNEL_SIZE, OperandType) kernel; 
	kernel[0] = 0;
	kernel[1] = 1;
	kernel[2] = 2;
	kernel[3] = 3;
	
	//tree queue vector of vectors-may seem as a waste of space but compiler will handle 
        //the optimizations
        Vector#(TAdd#(TLog#(KERNEL_SIZE),1), Vector#(KERNEL_SIZE, FIFOF#(OperandType))) adderTree;
        for(Integer m=0; m<=log2(valueOf(KERNEL_SIZE)); m=m+1) begin
		adderTree[m] <-replicateM(mkLFIFOF);
	end
	    


	//construct the adder trees rules 
       	Integer currentPower = valueOf(KERNEL_SIZE);
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
        for(Integer i=0; i<=valueOf(KERNEL_SIZE)-1; i=i+1) begin
                rule streamRules;
                        if(i == valueOf(KERNEL_SIZE)-1) begin
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
            
                    

        //shift a new value into the currentStream every CC
	method Action initHorizontal();
		for(Integer i=0; i<valueOf(KERNEL_SIZE); i=i+1) begin
			horizontalStream[i].enq(0);
		end		
	endmethod            
        //methods for interaction with accelerator
	method Action request(OperandType req);
		horizontalStream[0].enq(req);  
        endmethod

        method ActionValue#(OperandType) response();
                
                adderTree[log2(valueOf(KERNEL_SIZE))][0].deq();
                return adderTree[log2(valueOf(KERNEL_SIZE))][0].first();
        endmethod           
endmodule
endpackage
