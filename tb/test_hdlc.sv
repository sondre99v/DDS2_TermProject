//////////////////////////////////////////////////
// Title:   test_hdlc
// Author:  Karianne Krokan Kragseth
// Date:    20.10.2017
//////////////////////////////////////////////////

/* test_hdlc is the testbench module of this design, it sets up the testing
   enviroment by connecting the DUT to an interface (in_hdlc.sv) in with all the
   signals used by the test program. 
   All simulation code and immediate assertions are found in testPr_hdlc.sv.
*/

module test_hdlc ();

  //Hdlc interface
  in_hdlc uin_hdlc();

  //Internal assignments
  assign uin_hdlc.Tx_Done            = u_dut.Tx_Done;
  assign uin_hdlc.Tx_FCSDone         = u_dut.Tx_FCSDone;
  assign uin_hdlc.Tx_ValidFrame      = u_dut.Tx_ValidFrame;
  assign uin_hdlc.Tx_AbortFrame      = u_dut.Tx_AbortFrame;
  assign uin_hdlc.Tx_Data            = u_dut.Tx_Data;			// [7:0]

  assign uin_hdlc.Rx_ValidFrame      = u_dut.Rx_ValidFrame;
  assign uin_hdlc.Rx_Data            = u_dut.Rx_Data;			// [7:0]
  assign uin_hdlc.Rx_AbortSignal     = u_dut.Rx_AbortSignal;
  assign uin_hdlc.Rx_WrBuff          = u_dut.Rx_WrBuff;
  assign uin_hdlc.Rx_EoF             = u_dut.Rx_EoF;
  assign uin_hdlc.Rx_FrameSize       = u_dut.Rx_FrameSize;
  assign uin_hdlc.Rx_Overflow        = u_dut.Rx_Overflow;
  assign uin_hdlc.Rx_FCSerr          = u_dut.Rx_FCSerr;
  assign uin_hdlc.Rx_FCSen           = u_dut.Rx_FCSen;
  assign uin_hdlc.Rx_DataBuffOut     = u_dut.Rx_DataBuffOut;
  assign uin_hdlc.Rx_RdBuff          = u_dut.Rx_RdBuff;
  assign uin_hdlc.Rx_NewByte         = u_dut.Rx_NewByte;
  assign uin_hdlc.Rx_StartZeroDetect = u_dut.Rx_StartZeroDetect;
  assign uin_hdlc.Rx_FlagDetect      = u_dut.Rx_FlagDetect;
  assign uin_hdlc.Rx_AbortDetect     = u_dut.Rx_AbortDetect;
  assign uin_hdlc.Rx_FrameError      = u_dut.Rx_FrameError;
  assign uin_hdlc.Rx_Drop            = u_dut.Rx_Drop;
  assign uin_hdlc.Rx_StartFCS        = u_dut.Rx_StartFCS;
  assign uin_hdlc.Rx_StopFCS         = u_dut.Rx_StopFCS;
  assign uin_hdlc.RxD                = u_dut.RxD;
  assign uin_hdlc.ZeroDetect         = u_dut.u_RxChannel.ZeroDetect;


  //Clock
  always #250ns uin_hdlc.Clk = ~uin_hdlc.Clk;

  //Dut
  Hdlc u_dut(
    .Clk         (uin_hdlc.Clk),
    .Rst         (uin_hdlc.Rst),
    // Address
    .Address     (uin_hdlc.Address),
    .WriteEnable (uin_hdlc.WriteEnable),
    .ReadEnable  (uin_hdlc.ReadEnable),
    .DataIn      (uin_hdlc.DataIn),
    .DataOut     (uin_hdlc.DataOut),
    // RX
    .Rx          (uin_hdlc.Rx),
    .RxEN        (uin_hdlc.RxEN),
    .Rx_Ready    (uin_hdlc.Rx_Ready),
    // TX
    .Tx          (uin_hdlc.Tx),
    .TxEN        (uin_hdlc.TxEN)
  );

  // Coverage checks
  covergroup hdlc_cg @(posedge uin_hdlc.Clk);
    // RX
    rx_data: coverpoint uin_hdlc.Rx_Data
    {
      bins bin_zero = {0};
      bins bin_small = {[1:15]};
      bins bin_large = {[16:254]};
      bins bin_max = {255};
      bins bin_others = default;
    }

    rx_drop: coverpoint uin_hdlc.Rx_Drop
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    rx_frame_error: coverpoint uin_hdlc.Rx_FrameError
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    rx_overflow: coverpoint uin_hdlc.Rx_Overflow
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    rx_flag_detect: coverpoint uin_hdlc.Rx_FlagDetect
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    rx_abort_detect: coverpoint uin_hdlc.Rx_AbortDetect
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    rx_data_drop:         cross rx_data, rx_drop;
    rx_data_frame_error:  cross rx_data, rx_frame_error;
    rx_data_overflow:     cross rx_data, rx_overflow;
    rx_data_flag_detect:  cross rx_data, rx_flag_detect;
    rx_data_abort_detect: cross rx_data, rx_abort_detect;
  


    // TX
    tx_data: coverpoint uin_hdlc.Tx_Data
    {
      bins bin_zero = {0};
      bins bin_small = {[1:15]};
      bins bin_large = {[16:254]};
      bins bin_max = {255};
      bins bin_others = default;
    }

    tx_done: coverpoint uin_hdlc.Tx_Done
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    tx_valid_frame: coverpoint uin_hdlc.Tx_ValidFrame
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    tx_abort_frame: coverpoint uin_hdlc.Tx_AbortFrame
    {
      bins bin_low = {0};
      bins bin_high = {1};
      bins bin_others = default;
    }

    tx_data_done:         cross tx_data, tx_done;
    tx_data_valid_frame:  cross tx_data, tx_valid_frame;
    tx_data_abort_frame:  cross tx_data, tx_abort_frame;

  endgroup

  hdlc_cg hdlc_cg_Inst = new();
  always @(posedge uin_hdlc.Clk) hdlc_cg_Inst.sample();



  //Test program
  testPr_hdlc u_testPr(
    .uin_hdlc (uin_hdlc)
  );

endmodule
