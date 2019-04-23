//////////////////////////////////////////////////
// Title:   assertions_hdlc
// Author:  
// Date:    
//////////////////////////////////////////////////

/* The assertions_hdlc module is a test module containing the concurrent
   assertions. It is used by binding the signals of assertions_hdlc to the
   corresponding signals in the test_hdlc testbench. This is already done in
   bind_hdlc.sv 

   For this exercise you will write concurrent assertions for the Rx module:
   - Verify that Rx_FlagDetect is asserted two cycles after a flag is received
   - Verify that Rx_AbortSignal is asserted after receiving an abort flag
*/

module assertions_hdlc (
  output int   ErrCntAssertions,
  input  logic Clk,
  input  logic Rst,

  input  logic Rx,
  input  logic Rx_FlagDetect,
  input  logic Rx_ValidFrame,
  input  logic Rx_AbortDetect,
  input  logic Rx_AbortSignal,
  input  logic Rx_Overflow,
  input  logic Rx_WrBuff,
  input  logic Rx_EoF,

  input logic Tx,
  input logic Tx_ValidFrame,
  input logic Tx_AbortFrame
);

  initial begin
    ErrCntAssertions  =  0;
  end

  /*******************************************
   *  Verify correct Rx_FlagDetect behavior  *
   *******************************************/
  
  // Sequence to detect '01111110'
  sequence Rx_flag;
    @(posedge Clk) !Rx ##1 Rx [*6] ##1 !Rx;
  endsequence

  // Check if flag sequence is detected
  property RX_FlagDetect;
    @(posedge Clk) Rx_flag |-> ##2 Rx_FlagDetect;
  endproperty

  RX_FlagDetect_Assert : assert property (RX_FlagDetect) begin
    //$display("PASS: Flag detect");
  end else begin 
    $error("Flag sequence did not generate FlagDetect"); 
    ErrCntAssertions++; 
  end

  /********************************************
   *  Verify correct Rx_AbortSignal behavior  *
   ********************************************/

  // If abort is detected during valid frame. then abort signal should go high
  property RX_AbortSignal;
    @(posedge Clk) Rx_AbortDetect && Rx_ValidFrame |=> Rx_AbortSignal;
  endproperty

  RX_AbortSignal_Assert : assert property (RX_AbortSignal) begin
    //$display("PASS: Abort signal");
  end else begin 
    $error("AbortSignal did not go high after AbortDetect during validframe"); 
    ErrCntAssertions++; 
  end

  /********************************************
   *  Verify correct Tx_AbortFrame behavior   *
   ********************************************/

  sequence Tx_AbortFlag;
    @(posedge Clk) !Tx ##1 Tx[*7];
  endsequence

  // If abort is issued during valid frame. then an abort flag should be transmitted
  property TX_AbortFrameProperty;
    @(posedge Clk) Tx_ValidFrame && Tx_AbortFrame |-> ##4 Tx_AbortFlag;
  endproperty

  TX_AbortFrame_Assert : assert property (TX_AbortFrameProperty) begin
    //$display("PASS: Abort flag generated");
  end else begin 
    $error("FAIL: Abort flag not generated after abort was issued"); 
    ErrCntAssertions++; 
  end

  /********************************************
   *  Verify TX high in idle                  *
   ********************************************/

  // If Tx_ValidFrame has been low for four cycles, the dut is in idle, and Tx should be high
  property TX_TxHighInIdle;
    @(posedge Clk) !Tx_ValidFrame[*10] |-> Tx;
  endproperty

  TX_TxHighInIdle_Assert : assert property (TX_TxHighInIdle)
    else begin 
    $error("FAIL: Tx_ValidFrame is low, but Tx is not high"); 
    ErrCntAssertions++; 
  end


endmodule
