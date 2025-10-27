package file_in_out;

import RegFile :: *;

(* synthesize *)
module mkfile_io(Empty);
    RegFile#(Bit#(32), Bit#(32)) memory_rd <- mkRegFileLoad("/home/shakti/Viterbi-Decoder/test-cases/small/N_small.dat", 0, 1);
    RegFile#(Bit#(32), Bit#(32)) memory_a <- mkRegFileLoad("/home/shakti/Viterbi-Decoder/test-cases/small/A_small.dat", 0, 255);

    Reg#(Bit#(32)) n <- mkReg(0);
    Reg#(Bit#(32)) m <- mkReg(0);
    Reg#(Bit#(32)) loop_limit <- mkReg(0);

    Reg#(Bool) config_loaded <- mkReg(False);
    Reg#(Bool) print_started <- mkReg(False);

    Reg#(Bit#(32)) print_index <- mkReg(0);

    rule load_config (!config_loaded);
        n <= memory_rd.sub(0);
        m <= memory_rd.sub(1);
        config_loaded <= True;
    endrule

    rule start_printing (config_loaded && !print_started);
        let new_limit = n * (n + 1); 
        loop_limit <= new_limit;
        $display("Config loaded and stable: n = %d, loop limit = n*(n+1) = %d", n, new_limit);
        print_started <= True;
    endrule

    rule print_chunk (print_started && print_index < loop_limit);
        for (Integer i = 0; i < 5; i = i + 1) begin
            Bit#(32) current_addr = print_index + fromInteger(i);
            if (current_addr < loop_limit && current_addr < 256) begin
                $display("addr = %0d : %h", unpack(current_addr), memory_a.sub(current_addr));
            end
        end
        print_index <= print_index + 5;
    endrule

    rule finish_sim (print_started && print_index >= loop_limit);
        $finish;
    endrule

endmodule: mkfile_io
endpackage
