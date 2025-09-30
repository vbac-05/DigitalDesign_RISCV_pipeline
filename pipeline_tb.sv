module tb_riscv;

    reg clk;
    reg rst_n;

    integer total_error;

parameter CLOCK_CYCLE = 2;
parameter STOP_CYCLE  = 3;

initial clk = 0;
always #(CLOCK_CYCLE/2) clk = ~clk;

riscv_pipeline_5stages  DUT (
        .clk(clk), 
        .rst_n(rst_n)
    );

task reset_register_file();
    begin
        for (int i = 0; i < 32; i = i + 1) begin
            DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] = 32'b0;
        end
    end
endtask

task reset_imem();
    begin
        for (int i = 0; i < 256; i = i + 1) begin
            DUT.u_imem.imem[i] = 32'bx;
        end
    end
endtask

reg [31:0] golden_register_file [31:0];

task R_type_instruction();
    integer error_count;
    integer cycle;
    integer extra_cycles;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/R-type/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting R-type instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) begin
                extra_cycles = STOP_CYCLE;
                while(extra_cycles > 0) begin
                    @(posedge clk);
                    extra_cycles = extra_cycles - 1;
                end
                break;
            end
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test R-type instruction failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/R-type/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t R-type instruction test passed!", $time);
        end else begin
            $display("%t R-type instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        // $finish; 
    end
endtask

task I_type_arithmetic_instruction();
    integer error_count;
    integer cycle;
    integer extra_cycles;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/I-type(arithmetic&logic)/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting I-type arithmetic instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) begin
                extra_cycles = STOP_CYCLE;
                while(extra_cycles > 0) begin
                    @(posedge clk);
                    extra_cycles = extra_cycles - 1;
                end
                break;
            end
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test I-type arithmetic & logic instruction failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/I-type(arithmetic&logic)/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t I-type arithmetic instruction test passed!", $time);
        end else begin
            $display("%t I-type arithmetic instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        // $finish; 
    end
endtask

task I_type_load_instruction();
    integer error_count;
    integer extra_cycles;
    integer cycle;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/I-type(load)/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting I-type load instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) begin
                extra_cycles = STOP_CYCLE;
                while(extra_cycles > 0) begin
                    @(posedge clk);
                    extra_cycles = extra_cycles - 1;
                end
                break;
            end
            #(CLOCK_CYCLE/2);
            if(cycle > 200) begin
                $display("Test I-type load failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/I-type(load)/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t I-type load instruction test passed!", $time);
        end else begin
            $display("%t I-type load instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        // $finish; 
    end
endtask

task S_type_instruction();
    integer error_count;
    integer cycle;
    integer i;
    integer mem_data [0:63];
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/S-type/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting S-type instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) break;
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test S-type failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/S-type/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t S-type instruction test passed!", $time);
        end else begin
            $display("%t S-type instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        $finish; 
    end
endtask

task JAL_instruction();
    integer error_count;
    integer cycle;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/J-type/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting JAL instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) break;
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test JAL failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/J-type/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t JAL instruction test passed!", $time);
        end else begin
            $display("%t JAL instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        $finish; 
    end
endtask

task B_type_instruction();
    integer error_count;
    integer extra_cycles;
    integer cycle;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/B-type/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting B-type instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) begin
                extra_cycles = STOP_CYCLE;
                while(extra_cycles > 0) begin
                    @(posedge clk);
                    extra_cycles = extra_cycles - 1;
                end
                break;
            end
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test B-type failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/B-type/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t B-type instruction test passed!", $time);
        end else begin
            $display("%t B-type instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        // $finish; 
    end
endtask

task JALR_instruction();    
    integer error_count;
    integer cycle;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/I-type(JALR)/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting JALR instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) break;
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test JALR failed! (Time out)");
                $finish;
            end
        end

        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/I-type(JALR)/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t JALR instruction test passed!", $time);
        end else begin
            $display("%t JALR instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        // $finish; 
    end
endtask

task U_type_instruction();
    integer error_count;
    integer extra_cycles;
    integer cycle;
    begin
        error_count = 0;
        cycle = 1;
        rst_n = 0;
        #(CLOCK_CYCLE);
        @(negedge clk) rst_n = 1;
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/U-type/IMEM_hex.txt", DUT.u_imem.imem);
        reset_register_file();
        $display("%t Starting U-type instruction test...", $time);

        wait(DUT.u_pipeline_5stages_core.InstrD !== 32'hx);
        @(posedge clk);
        while(DUT.u_pipeline_5stages_core.InstrD !== 32'hx) begin
            cycle = cycle + 1;
            #(CLOCK_CYCLE/2);
            @(negedge clk) if(DUT.u_pipeline_5stages_core.InstrD === 32'hx) begin
                extra_cycles = STOP_CYCLE;
                while(extra_cycles > 0) begin
                    @(posedge clk);
                    extra_cycles = extra_cycles - 1;
                end
                break;
            end
            #(CLOCK_CYCLE/2);
            if(cycle > 100) begin
                $display("Test U-type failed! (Time out)");
                $finish;
            end
        end
        
        $readmemh("C:/Users/Do Viet Dung/Downloads/datapath_pipeline_test/r32i/U-type/golden_register_file_hex.txt", golden_register_file);
        for (int i = 0; i < 32; i = i + 1) begin
            if (DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i] !== golden_register_file[i]) begin
                $display("Mismatch at register x%0d: DUT = %h, Golden = %h", i, DUT.u_pipeline_5stages_core.u_datapath.u_rf.regs[i], golden_register_file[i]);
                error_count = error_count + 1;
            end
        end

        if(error_count == 0) begin
            $display("%t U-type instruction test passed!", $time);
        end else begin
            $display("%t U-type instruction test failed with %0d errors.",$time, error_count);
            total_error = total_error + error_count;
        end
        reset_register_file();
        reset_imem();
        // $finish; 
    end
endtask


initial begin
    total_error = 0;
    R_type_instruction();
    // I_type_arithmetic_instruction();
    // S_type_instruction(); // Prerequisite for I_type_load_instruction test
    // I_type_load_instruction();
    // JALR_instruction();
    // JAL_instruction();
    // B_type_instruction();
    // U_type_instruction();
    $display("Total error count: %0d", total_error);

    if(total_error == 0)begin
        $display("\n");

        $display(" **********************************************");   
        $display(" *****************************                *");
        $display(" **                         **       |\__||    *");
        $display(" **   Congratulations !!    **      / O.O  |  *");
        $display(" **                         **    /_____   |  *");
        $display(" ** RV32I Simulation PASS!! **   /^ ^ ^ \\  |  *");
        $display(" **                         **  |^ ^ ^ ^ |w|  *");
        $display(" *****************************   \\m___m__|_|  *");
        $display(" **********************************************");   
    end
    else begin
        $display("\n");
        $display(" ****************************               ");
        $display(" **                        **       |\__||  ");
        $display(" **  OOPS!!                **      / X,X  | ");
        $display(" **                        **    /_____   | ");
        $display(" **  Simulation Failed!!   **   /^ ^ ^ \\  |");
        $display(" **                        **  |^ ^ ^ ^ |w| ");
        $display(" ****************************   \\m___m__|_|");
    end  
    $finish;
end

endmodule