/**********************************************************
 * Author: Gopal Srinivasan
 * Descr : Pipelined ripple carry adder with each pipeline
           stage performing 16-bits ripple carry addition
 **********************************************************/

package RippleCarryAdder;

/******************
 * Package imports
 ******************/
import FIFO::*;
import SpecialFIFOs::*;

/************************
 * Structs and Interface
 ************************/
// Struct for adder input type
typedef struct {
  Bit#(32) val1;
  Bit#(32) val2;
} AdderInput
deriving(Bits, Eq);

// Struct for the intermediate pipe stage
typedef struct {
  Bit#(16) val1;
  Bit#(16) val2;
  Bit#(17) sum;
} AdderPipeStage
deriving(Bits, Eq);

// Struct for adder output type
typedef struct {
  Bit#(1)  overflow;
  Bit#(32) sum;
} AdderResult
deriving(Bits, Eq);

// Interface definition for the ripple carry adder
interface RCA_ifc;
  method Action                    start(AdderInput inp);
  method ActionValue#(AdderResult) get_result();
endinterface : RCA_ifc

/*******************************************
 * Module definition for ripple carry adder
 *******************************************/
(* synthesize *)
module mkRippleCarryAdder(RCA_ifc);
  // Declare FIFO for the adder pipeline stages
  FIFO#(AdderInput)     adder_ififo <- mkSizedFIFO(2);
  FIFO#(AdderPipeStage) adder_pfifo <- mkSizedFIFO(2);
  FIFO#(AdderResult)    adder_ofifo <- mkSizedFIFO(2);

  // Function for ripple carry addition
  function Bit#(17) rca_addition(Bit#(16) a, Bit#(16) b, Bit#(1) cin);
    Bit#(16) sum;
    Bit#(17) carry = ?;

    // RCA combinational logic
    carry[0] = cin;

    for (int i = 0; i < 16;  i = i + 1) begin
      sum  [i  ] = (a[i] ^ b[i] ^ carry[i]);
      carry[i+1] = (a[i] & b[i]) | (carry[i] & (a[i] ^ b[i]));
    end

    Bit#(17) rca_result = {carry[16], sum};
    return rca_result;
  endfunction : rca_addition

  // Rule for adder pipeline stage-1
  rule rl_pipe_stage1;
    AdderInput inp_stage1 = adder_ififo.first();
    Bit#(16)   inp_val1   = inp_stage1.val1[15:0];
    Bit#(16)   inp_val2   = inp_stage1.val2[15:0];
    Bit#(1)    cin        = 1'b0;
    Bit#(17)   psum       = rca_addition(inp_val1, inp_val2, cin);

    AdderPipeStage out_stage1;
    out_stage1.val1 = inp_stage1.val1[31:16];
    out_stage1.val2 = inp_stage1.val2[31:16];
    out_stage1.sum  = psum;

    adder_ififo.deq();
    adder_pfifo.enq(out_stage1);
  endrule : rl_pipe_stage1

  // Rule for adder pipeline stage-2
  rule rl_pipe_stage2;
    AdderPipeStage inp_stage2 = adder_pfifo.first();
    Bit#(16)       inp_val1   = inp_stage2.val1;
    Bit#(16)       inp_val2   = inp_stage2.val2;
    Bit#(17)       psum_lsbs  = inp_stage2.sum;
    Bit#(1)        cin        = psum_lsbs[16];
    Bit#(17)       psum_msbs  = rca_addition(inp_val1, inp_val2, cin);

    AdderResult out_stage2;
    out_stage2.overflow = psum_msbs[16];
    out_stage2.sum      = {psum_msbs[15:0], psum_lsbs[15:0]};

    adder_pfifo.deq();
    adder_ofifo.enq(out_stage2);
  endrule : rl_pipe_stage2

  // Define the adder interface methods
  method Action start(AdderInput inp);
    adder_ififo.enq(inp);
  endmethod : start

  method ActionValue#(AdderResult) get_result();
    AdderResult out = adder_ofifo.first();
    adder_ofifo.deq();
    return out;
  endmethod : get_result
endmodule : mkRippleCarryAdder

endpackage : RippleCarryAdder


