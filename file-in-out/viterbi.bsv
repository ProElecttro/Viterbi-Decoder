package ViterbiDecoder;

import RegFile::*;
import Vector::*;
import MathHelpers::*;

(* synthesize *)
module mkViterbi(Empty);

    // === Parameters ===
    Integer Nmax = 16;   // limit for simplicity
    Integer Tmax = 32;   // max observation length

    // === Memories ===
    RegFile#(Bit#(32), Bit#(32)) memN  <- mkRegFileLoad("/home/shakti/Viterbi-Decoder/test-cases/small/N_small.dat", 0, 1);
    RegFile#(Bit#(32), Bit#(32)) memA  <- mkRegFileLoad("/home/shakti/Viterbi-Decoder/test-cases/small/A_small.dat", 0, 255);
    RegFile#(Bit#(32), Bit#(32)) memB  <- mkRegFileLoad("/home/shakti/Viterbi-Decoder/test-cases/small/B_small.dat", 0, 255);
    RegFile#(Bit#(32), Bit#(32)) memInput <- mkRegFileLoad("/home/shakti/Viterbi-Decoder/test-cases/small/Input_small.dat", 0, 255);

    // === State variables ===
    Reg#(Bit#(32)) n <- mkReg(0);
    Reg#(Bit#(32)) m <- mkReg(0);
    Reg#(Bit#(32)) t <- mkReg(0);

    Reg#(Bool) initialized <- mkReg(False);
    Reg#(Bool) computing <- mkReg(False);
    Reg#(Bool) done <- mkReg(False);

    // === Arrays ===
    Vector#(16, Reg#(Bit#(32))) prob <- replicateM(mkReg(0));
    Vector#(16, Reg#(Bit#(32))) temp <- replicateM(mkReg(0));
    Vector#(32, Vector#(16, Reg#(Bit#(32)))) bt <- replicateM(replicateM(mkReg(0)));

    // === Loop indices ===
    Reg#(Bit#(32)) i <- mkReg(0);
    Reg#(Bit#(32)) j <- mkReg(0);

    // === Initialization rule ===
    rule rl_init (!initialized);
        n <= memN.sub(0);
        m <= memN.sub(1);
        $display("Loaded config: N=%0d, M=%0d", n, m);

        // Initialize prob[j] = a[0][j] * b[j][o1]
        for (Integer jj = 0; jj < 4; jj = jj + 1) begin
            Bit#(32) a0j = memA.sub(fromInteger(jj));          // a[0][j]
            Bit#(32) bj1 = memB.sub(fromInteger(jj));          // b[j][o1]
            Bit#(32) val = bitwiseAdd(a0j, bj1);               // log domain addition
            prob[jj] <= val;
            bt[0][jj] <= 0; // q0
        end

        t <= 1;
        initialized <= True;
        computing <= True;
    endrule

    // === Iterative computation ===
    rule rl_compute (computing && !done);
        Bit#(32) cur_obs = memInput.sub(t);
        for (Integer jj = 0; jj < 4; jj = jj + 1) begin
            Bit#(32) max_val = 0;
            Bit#(32) max_state = 0;
            for (Integer ii = 0; ii < 4; ii = ii + 1) begin
                Bit#(32) val = bitwiseAdd(prob[ii], memA.sub(fromInteger(ii * 4 + jj)));
                if (val > max_val) begin
                    max_val = val;
                    max_state = fromInteger(ii);
                end
            end
            temp[jj] <= bitwiseAdd(max_val, memB.sub(fromInteger(jj * 4 + cur_obs)));
            bt[t][jj] <= max_state;
        end
        prob <= temp;
        t <= t + 1;
        if (cur_obs == 32'hFFFFFFFF) done <= True;
    endrule

    // === Traceback ===
    rule rl_traceback (done);
        Bit#(32) best_val = 0;
        Bit#(32) best_state = 0;

        for (Integer jj = 0; jj < 4; jj = jj + 1) begin
            if (prob[jj] > best_val) begin
                best_val = prob[jj];
                best_state = fromInteger(jj);
            end
        end

        Vector#(32, Bit#(32)) path = replicate(0);
        path[t - 1] = best_state;
        for (Integer tt = valueOf(Tmax)-2; tt >= 0; tt = tt - 1)
            path[tt] = bt[tt + 1][path[tt + 1]];

        $display("Final Path:");
        for (Integer tt = 0; tt < 4; tt = tt + 1)
            $display("%0d ", path[tt]);

        $display("Final log-prob = %h", best_val);
        $finish;
    endrule

endmodule
endpackage
