// Copyright (c) 2018 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.
//
// Bug fixes and contributions will eventually be released under the
// SolderPad open hardware license in the context of the PULP platform
// (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
// University of Bologna.
//
// Author: Michael Schaffner <schaffner@iis.ee.ethz.ch>, ETH Zurich
// Date: 15.08.2018
// Description: testbench package with some helper functions.


package tb_pkg;

  // // for abs(double) function
  // import mti_cstdlib::*; 

  // for timestamps
  import "DPI-C" \time = function int _time (inout int tloc[4]);
  import "DPI-C" function string ctime(inout int tloc[4]);

///////////////////////////////////////////////////////////////////////////////
// parameters
///////////////////////////////////////////////////////////////////////////////
  
  // creates a 10ns ATI timing cycle 
  time CLK_HI               = 5ns;     // set clock high time                    
  time CLK_LO               = 5ns;     // set clock low time             
  time APPL_DEL             = 2ns;     // set stimuli application delay          
  time ACQ_DEL              = 8ns;     // set response aquisition delay          

  parameter ERROR_CNT_STOP_LEVEL = 1; // use 1 for debugging. 0 runs the complete simulation...

 //////////////////////////////////////////////////////////////////////////////
// use to ensure proper ATI timing      
///////////////////////////////////////////////////////////////////////////////

  task automatic applWaitCyc(ref logic Clk_C, input int unsigned n);                            
     if (n > 0) begin                                                                 
       repeat (n) @(posedge(Clk_C));                                       
       #(APPL_DEL);                                                        
     end                                                                   
  endtask                                                                  
                                                                           
  task automatic acqWaitCyc(ref logic Clk_C, input int unsigned n);                               
     if (n > 0) begin                                                                 
       repeat (n) @(posedge(Clk_C));                                       
       #(ACQ_DEL);                                                         
     end                                                                   
  endtask     
  
  // sample right on active clock edge 
  task automatic applWait(ref logic Clk_C, ref logic SigToWaitFor_S);                              
     do begin
       @(posedge(Clk_C));                                       
     end while(SigToWaitFor_S == 1'b0);                                                                  
     #(APPL_DEL);                                               
  endtask

    // sample right on active clock edge 
  task automatic acqWait(ref logic Clk_C, ref logic SigToWaitFor_S);                              
     do begin
       @(posedge(Clk_C));                                       
     end while(SigToWaitFor_S == 1'b0);                                                                  
     //#(ACQ_DEL);                                               
  endtask      

///////////////////////////////////////////////////////////////////////////////
// progress 
///////////////////////////////////////////////////////////////////////////////
 
  class progress;
    real newState, oldState;
    longint numResp, acqCnt, errCnt, totAcqCnt, totErrCnt;

    function new();
      begin
          this.acqCnt   = 0;
          this.errCnt   = 0;
          this.newState = 0.0;
          this.oldState = 0.0;
          this.numResp  = 1;
          this.totAcqCnt = 0;
          this.totErrCnt = 0;

      end  
    endfunction : new
    
    function void reset(longint numResp_);
      begin
          this.acqCnt   = 0;
          this.errCnt   = 0;
          this.newState = 0.0;
          this.oldState = 0.0;
          this.numResp  = numResp_;        
      end  
    endfunction : reset

    function void addRes(int isError); 
      begin
          this.acqCnt++;
          this.totAcqCnt++;
          this.errCnt += isError;
          this.totErrCnt += isError;

          if(ERROR_CNT_STOP_LEVEL <= this.errCnt && ERROR_CNT_STOP_LEVEL > 0) begin
            $error("TB> simulation stopped (ERROR_CNT_STOP_LEVEL = %d reached).", ERROR_CNT_STOP_LEVEL); 
            $stop();
          end 
      end  
    endfunction : addRes

    function void print(); 
      begin
        this.newState = $itor(this.acqCnt) / $itor(this.numResp);
        if(this.newState - this.oldState >= 0.01) begin  
          $display("TB> validated %03d%% -- %01d failed (%03.3f%%) ",
                  $rtoi(this.newState*100.0),
                  this.errCnt,
                  $itor(this.errCnt) / $itor(this.acqCnt) * 100.0);
          // $fflush();
          this.oldState = this.newState;
        end
      end
    endfunction : print

    function void printToFile(string file, bit summary = 0); 
      begin
        int fptr;
        
        // sanitize string
        for(fptr=0; fptr<$size(file);fptr++) begin
          if(file[fptr] == " " || file[fptr] == "/" || file[fptr] == "\\") begin
            file[fptr] = "_";
          end
        end


        fptr = $fopen(file,"w");
        if(summary) begin
          $fdisplay(fptr, "Simulation Summary");
          $fdisplay(fptr, "total: %01d of %01d vectors failed (%03.3f%%) ",
                    this.totErrCnt,
                    this.totAcqCnt,
                    $itor(this.totErrCnt) / $itor(this.totAcqCnt) * 100.0);
          if(this.totErrCnt == 0) begin
            $fdisplay(fptr, "CI: PASSED");
          end else begin
            $fdisplay(fptr, "CI: FAILED");
          end
        end else begin 
          $fdisplay(fptr, "test name: %s", file);
          $fdisplay(fptr, "this test: %01d of %01d vectors failed (%03.3f%%) ",
                    this.errCnt,
                    this.acqCnt,
                    $itor(this.errCnt) / $itor(this.acqCnt) * 100.0);
          
          $fdisplay(fptr, "total so far: %01d of %01d vectors failed (%03.3f%%) ",
                    this.totErrCnt,
                    this.totAcqCnt,
                    $itor(this.totErrCnt) / $itor(this.totAcqCnt) * 100.0);
        end
        $fclose(fptr);
      end
    endfunction : printToFile

  endclass : progress

endpackage : tb_pkg

