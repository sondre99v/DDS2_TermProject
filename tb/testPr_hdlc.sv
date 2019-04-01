//////////////////////////////////////////////////
// Title:   testPr_hdlc
// Author: 
// Date:  
//////////////////////////////////////////////////

/* testPr_hdlc contains the simulation and immediate assertion code of the
   testbench. 

   For this exercise you will write immediate assertions for the Rx module which
   should verify correct values in some of the Rx registers for:
   - Normal behavior
   - Buffer overflow 
   - Aborts

   HINT:
   - A ReadAddress() task is provided, and addresses are documentet in the 
     HDLC Module Design Description
*/

program testPr_hdlc(
  in_hdlc uin_hdlc
);
  
  int TbErrorCnt;

  /****************************************************************************
   *                                                                          *
   *                           Verification Tasks                             *
   *                                                                          *
   ****************************************************************************/


  // VerifyNormalReceive should verify correct value in the Rx status/control
  // register, and that the entire Rx data buffer contains correct data.
  task VerifyNormalReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic all_correct;
    logic all_ready;
    int wrong_index;
    logic[7:0] wrong_data;

    // Read the register Rx_SC and check that all the bits have their correct values
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[4]) 
      $display("PASS: Rx_Overflow bit not set"); 
      else $display("FAIL: Rx_Overflow bit set"); // Assert that Rx_Overflow is not set
    assert(!ReadData[3]) 
      $display("PASS: Rx_AbortSignal bit not set"); 
      else $display("FAIL: Rx_AbortSignal bit set"); // Assert that Rx_AbortSignal is not set
    assert(!ReadData[2]) 
      $display("PASS: Rx_FrameError bit not set"); 
      else $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
    
    // Read the data buffer length (Rx_Len), and check that it is equal to the expected length
    ReadAddress(3'b100, ReadData);
    assert(ReadData == Size) 
      $display("PASS: Rx_Len is equal to the expected size"); 
      else $display("FAIL: Rx_Len is not equal to the expected size");
    

    // Read the data buffer (Rx_Buff) and check that it is equal to the transmitted data
    all_correct = 1'b1;
    all_ready = 1'b1;
    wrong_index = -1;
    for (int i = 0; i < Size; i++) begin
      ReadAddress(3'b010, ReadData);
      if(!ReadData[0]) begin
        all_ready = 1'b0;
        wrong_index = i;
        break;
      end
      ReadAddress(3'b011, ReadData);
      if(ReadData != data[i]) begin
        all_correct = 1'b0;
        wrong_index = i;
        wrong_data = ReadData;
        break;
      end
    end
    
    // Assert that all bytes in RxBuff are equal to the transmitted data
    assert(all_correct)
    $display("PASS: All bytes in RxBuff equal to transmitted data");
    else $display("FAIL: RxBuff[%d] = %h (not equal to transmitted data %h)", 
      wrong_index, wrong_data, data[wrong_index]);
    
    // Assert that Rx_Ready was high for all the read bytes
    assert(all_ready)
    $display("PASS: Rx_Ready was high for all the read bytes");
    else $display("FAIL: Rx_Ready was low after %d received bytes", wrong_index);
    
    // Assert that Rx_Ready goes low after reading all bytes
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[0]) 
    $display("PASS: Rx_Ready was low after reading all bytes");
    else $display("FAIL: Rx_Ready was still high after reading all bytes");

  endtask


  // VerifyErrorOrDroppedReceive should verify correct value in the Rx status/control
  // register, and that the Rx_Buff returns zero
  task VerifyErrorOrDroppedReceive(logic [127:0][7:0] data, int Size, int drop);
    logic [7:0] ReadData;

    // Read the register Rx_SC and check that all the bits have their correct values
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[4]) 
      $display("PASS: Rx_Overflow bit not set"); 
      else $display("FAIL: Rx_Overflow bit set"); // Assert that Rx_Overflow is not set
    assert(!ReadData[3]) 
      $display("PASS: Rx_AbortSignal bit not set"); 
      else $display("FAIL: Rx_AbortSignal bit set"); // Assert that Rx_AbortSignal is not set
    if(drop) begin
      assert(!ReadData[2]) 
        $display("PASS: Rx_FrameError not bit set"); 
        else $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
    end else begin
      assert(ReadData[2]) 
        $display("PASS: Rx_FrameError bit set"); 
        else $display("FAIL: Rx_FrameError not bit set"); // Assert that Rx_FrameError is set
    end
    assert(!ReadData[0]) 
      $display("PASS: Rx_Ready bit not set"); 
      else $display("FAIL: Rx_Ready bit set"); // Assert that Rx_Ready is not set

    VerifyRxBufIsZero128Times();
  endtask


  // VerifyAbortReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer is zero after abort.
  task VerifyAbortReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;

    // Read the register Rx_SC and check that the abort bit is set
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[4]) 
      $display("PASS: Rx_Overflow bit not set"); 
      else $display("FAIL: Rx_Overflow bit set"); // Assert that Rx_Overflow is not set
    assert(ReadData[3]) 
      $display("PASS: Rx_AbortSignal bit set"); 
      else $display("FAIL: Rx_AbortSignal bit not set"); // Assert that Rx_AbortSignal is set
    assert(!ReadData[2]) 
      $display("PASS: Rx_FrameError bit not set"); 
      else $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
    assert(!ReadData[0]) 
      $display("PASS: Rx_Ready bit not set"); 
      else $display("FAIL: Rx_Ready bit set"); // Assert that Rx_Ready is not set
    
    VerifyRxBufIsZero128Times();
  endtask


  // VerifyOverflowReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyOverflowReceive(logic [127:0][7:0] data, int Size);
    logic [7:0] ReadData;
    logic all_correct;
    logic all_ready;
    int wrong_index;
    logic[7:0] wrong_data;

    // Read the register Rx_SC and check that the overflow bit is set
    ReadAddress(3'b010, ReadData);
    assert(ReadData[4]) 
      $display("PASS: Rx_Overflow bit set"); 
      else $display("FAIL: Rx_Overflow bit not set"); // Assert that Rx_Overflow is set
    assert(!ReadData[3]) 
      $display("PASS: Rx_AbortSignal bit not set"); 
      else $display("FAIL: Rx_AbortSignal bit set"); // Assert that Rx_AbortSignal is not set
    assert(!ReadData[2]) 
      $display("PASS: Rx_FrameError bit not set"); 
      else $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
    
    // Read the first 126 bytes of the data buffer (Rx_Buff) and check that it is equal to 
    // the start of the transmitted data
    all_correct = 1'b1;
    all_ready = 1'b1;
    wrong_index = -1;
    for (int i = 0; i < 126; i++) begin
      ReadAddress(3'b010, ReadData);
      if(!ReadData[0]) begin
        all_ready = 1'b0;
        wrong_index = i;
        break;
      end
      ReadAddress(3'b011, ReadData);
      if(ReadData != data[i]) begin
        all_correct = 1'b0;
        wrong_index = i;
        wrong_data = ReadData;
        break;
      end
    end
    
    // Assert that all bytes in RxBuff are equal to the transmitted data
    assert(all_correct)
    $display("PASS: All first 126 bytes in RxBuff equal to transmitted data");
    else $display("FAIL: RxBuff[%d] = %h (not equal to transmitted data %h)", 
      wrong_index, wrong_data, data[wrong_index]);
    
    // Assert that Rx_Ready was high for all the read bytes
    assert(all_ready)
    $display("PASS: Rx_Ready was high for all the read bytes");
    else $display("FAIL: Rx_Ready was low after %d received bytes", wrong_index);
    
    // Assert that Rx_Ready goes low after reading all bytes
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[0]) 
    $display("PASS: Rx_Ready was low after reading 126 bytes");
    else $display("FAIL: Rx_Ready was still high after reading 126 bytes");

    // Verify that subsequent reads return zero
    VerifyRxBufIsZero128Times();
  endtask


  task VerifyRxBufIsZero128Times();
    logic [7:0] ReadData;
    logic all_zero;
    int non_zero_index;
    logic[7:0] non_zero_value;

    // Read Rx_Buff 128 times, and check that it always returns zero
    all_zero = 1'b1;
    non_zero_index = -1;
    for (int i = 0; i < 128; i++) begin
      ReadAddress(3'b011, ReadData);
      if(ReadData != 8'b0) begin
        all_zero = 1'b0;
        non_zero_index = i;
        non_zero_value = ReadData;
        break;
      end
    end
    
    // Assert that all bytes read from RxBuff are zero
    assert(all_zero)
    $display("PASS: All bytes read from RxBuff are zero");
    else $display("FAIL: RxBuff[%d] = %h (not equal to zero)", 
      non_zero_index, non_zero_value);
  endtask

 
  // Verify that Tx_Done is low
  task VerifyTxDoneLow();
    logic [7:0] ReadData;

    ReadAddress(3'b000, ReadData);
    assert(!ReadData[0]) 
    $display("PASS: Tx_Done is low");
    else $display("FAIL: Tx_Done is high");
  endtask

  task VerifyAbortTransmit(logic [127:0][7:0] data, int Size);
  endtask

  task VerifyNormalTransmit(logic [127:0][7:0] data, int Size);
  endtask


  /****************************************************************************
   *                                                                          *
   *                             Simulation code                              *
   *                                                                          *
   ****************************************************************************/

  initial begin
    $display("*************************************************************");
    $display("%t - Starting Test Program", $time);
    $display("*************************************************************");

    Init();

    //Receive: Size, Abort, FCSerr, NonByteAligned, Overflow, Drop, SkipRead
    Receive(  1, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 10, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 25, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 45, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 47, 0, 0, 0, 0, 0, 0); //Normal
    Receive(126, 0, 0, 0, 0, 0, 0); //Normal

    //Receive(  1, 0, 1, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 10, 0, 1, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 25, 0, 1, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 45, 0, 1, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 47, 0, 1, 0, 0, 0, 0); //Normal, wrong FCS
    Receive(126, 0, 1, 0, 0, 0, 0); //Normal, wrong FCS

    Receive(  1, 0, 0, 1, 0, 0, 0); //Non-byte aligned
    Receive( 40, 0, 0, 1, 0, 0, 0); //Non-byte aligned
    Receive(122, 0, 0, 1, 0, 0, 0); //Non-byte aligned
    Receive(126, 0, 0, 1, 0, 0, 0); //Non-byte aligned

    Receive(  1, 1, 0, 0, 0, 0, 0); //Abort
    Receive(  1, 1, 0, 1, 0, 0, 0); //Abort, non-byte aligned
    Receive( 40, 1, 0, 0, 0, 0, 0); //Abort
    Receive( 40, 1, 0, 1, 0, 0, 0); //Abort, non-byte aligned
    Receive(122, 1, 0, 0, 0, 0, 0); //Abort
    Receive(122, 1, 0, 1, 0, 0, 0); //Abort, non-byte aligned
    Receive(126, 1, 0, 0, 0, 0, 0); //Abort

    Receive(126, 0, 0, 0, 1, 0, 0); //Overflow

    // Check that unread frame is properly discarded
    Receive(123, 0, 0, 0, 0, 0, 1); //Normal, skip read
    Receive(10, 0, 0, 0, 0, 0, 0); //Normal

    Receive( 10, 0, 0, 0, 0, 1, 0); //Drop packet halfway
    Receive( 26, 0, 0, 0, 0, 1, 0); //Drop packet halfway
    Receive( 46, 0, 0, 0, 0, 1, 0); //Drop packet halfway
    Receive( 48, 0, 0, 0, 0, 1, 0); //Drop packet halfway
    Receive(126, 0, 0, 0, 0, 1, 0); //Drop packet halfway
    

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: ???\t  *");//, TbErrorCnt + uin_hdlc.ErrCntAssertions);
    $display("*                               *");
    $display("*********************************");

  end

  task Init();
    uin_hdlc.Clk         =   1'b0;
    uin_hdlc.Rst         =   1'b0;
    uin_hdlc.Address     = 3'b000;
    uin_hdlc.WriteEnable =   1'b0;
    uin_hdlc.ReadEnable  =   1'b0;
    uin_hdlc.DataIn      =     '0;
    uin_hdlc.TxEN        =   1'b1;
    uin_hdlc.Rx          =   1'b1;
    uin_hdlc.RxEN        =   1'b1;

    TbErrorCnt = 0;

    #1000ns;
    uin_hdlc.Rst         =   1'b1;
  endtask

  task WriteAddress(input logic [2:0] Address ,input logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address     = Address;
    uin_hdlc.WriteEnable = 1'b1;
    uin_hdlc.DataIn      = Data;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.WriteEnable = 1'b0;
  endtask

  task ReadAddress(input logic [2:0] Address ,output logic [7:0] Data);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Address    = Address;
    uin_hdlc.ReadEnable = 1'b1;
    #100ns;
    Data                = uin_hdlc.DataOut;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.ReadEnable = 1'b0;
  endtask

  task InsertFlagOrAbort(int flag);
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b0;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;
    @(posedge uin_hdlc.Clk);
    if(flag)
      uin_hdlc.Rx = 1'b0;
    else
      uin_hdlc.Rx = 1'b1;
  endtask

  task MakeRxStimulus(logic [127:0][7:0] Data, int Size);
    logic [4:0] PrevData;
    PrevData = '0;
    for (int i = 0; i < Size; i++) begin
      for (int j = 0; j < 8; j++) begin
        if(&PrevData) begin
          @(posedge uin_hdlc.Clk);
          uin_hdlc.Rx = 1'b0;
          PrevData = PrevData >> 1;
          PrevData[4] = 1'b0;
        end

        @(posedge uin_hdlc.Clk);
        uin_hdlc.Rx = Data[i][j];

        PrevData = PrevData >> 1;
        PrevData[4] = Data[i][j];
      end
    end
  endtask

  task Receive(int Size, int Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead);
    logic [127:0][7:0] ReceiveData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;

    string msg;
    if(Abort)
      msg = "- Abort";
    else if(FCSerr)
      msg = "- FCS error";
    else if(NonByteAligned)
      msg = "- Non-byte aligned";
    else if(Overflow)
      msg = "- Overflow";
    else if(Drop)
      msg = "- Drop";
    else if(SkipRead)
      msg = "- Skip read";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Receive %s", $time, msg);
    $display("*************************************************************");

    for (int i = 0; i < Size; i++) begin
      ReceiveData[i] = $urandom;
    end
    ReceiveData[Size]   = '0;
    ReceiveData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    if (FCSerr) begin
      ReceiveData[Size]   = ~FCSBytes[7:0];
      ReceiveData[Size+1] = ~FCSBytes[15:8];
    end else begin
      ReceiveData[Size]   = FCSBytes[7:0];
      ReceiveData[Size+1] = FCSBytes[15:8];
    end

    //Enable FCS
    if(!Overflow && !NonByteAligned)
      WriteAddress(3'b010, 8'h20);
    else
      WriteAddress(3'b010, 8'h00);

    //Generate stimulus
    InsertFlagOrAbort(1);
    
    // Insert three extra bits if a non-byte aligned transmission is wanted
    if(NonByteAligned) begin
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = 1'b0;
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = 1'b1;
      @(posedge uin_hdlc.Clk);
      uin_hdlc.Rx = 1'b0;
    end

    MakeRxStimulus(ReceiveData, Size + 2);

    if(Overflow) begin
      OverflowData[0] = 8'h44;
      OverflowData[1] = 8'hBB;
      OverflowData[2] = 8'hCC;
      MakeRxStimulus(OverflowData, 3);
    end

    if(Abort) begin
      InsertFlagOrAbort(0);
    end else begin
      InsertFlagOrAbort(1);
    end

    @(posedge uin_hdlc.Clk);
    uin_hdlc.Rx = 1'b1;

    repeat(6)
      @(posedge uin_hdlc.Clk);

    if (!Overflow && !Drop && !FCSerr && !NonByteAligned) begin
      // Check that Rx_EoF is asserted
      assert(uin_hdlc.Rx_EoF)
        $display("PASS: Rx_EoF is set");
        else $display("FAIL: Rx_EoF is not set");
    end

    repeat(2)
      @(posedge uin_hdlc.Clk);

    if (Drop) begin
      WriteAddress(3'b010, 8'h02);
    end

    if(Abort)
      VerifyAbortReceive(ReceiveData, Size);
    else if(Overflow)
      VerifyOverflowReceive(ReceiveData, Size);
    else if(Drop)
      VerifyErrorOrDroppedReceive(ReceiveData, Size, 1);
    else if(FCSerr)
      VerifyErrorOrDroppedReceive(ReceiveData, Size, 0);
    else if(NonByteAligned)
      VerifyErrorOrDroppedReceive(ReceiveData, Size, 0);
    else if(!SkipRead)
      VerifyNormalReceive(ReceiveData, Size);

    #5000ns;
  endtask


  task Transmit(int Size, int Abort);
    logic [125:0][7:0] TransmitData;

    string msg;
    if(Abort)
      msg = "- Abort";
    else
      msg = "- Normal";
    $display("*************************************************************");
    $display("%t - Starting task Transmit %s", $time, msg);
    $display("*************************************************************");

    for (int i = 0; i < Size; i++) begin
      TransmitData[i] = $urandom;
      WriteAddress(3'b001, TransmitData[i]);
      VerifyTxDoneLow();
    end

    // Start the transmission by asserting Tx_Enable in Tx_SC
    WriteAddress(3'b000, 8'h2);
    
    // Maybe execute transmission here, and pass the bitstream to the verify tasks below...
    // Remember:
    //  - Bit stuffing
    //  - To wait for the start flag (as CRC takes varying time)
    //  - Check Tx_AbortedTrans with Concurrent Assertion
    //  - Requirement 7, check that in Idle, the device transmits high
    
    if(Abort)
      VerifyAbortTransmit(TransmitData, Size);
    else
      VerifyNormalTransmit(TransmitData, Size);
    
    #5000ns;
  endtask


  task GenerateFCSBytes(logic [127:0][7:0] data, int size, output logic[15:0] FCSBytes);
    logic [23:0] CheckReg;
    CheckReg[15:8]  = data[1];
    CheckReg[7:0]   = data[0];
    for(int i = 2; i < size+2; i++) begin
      CheckReg[23:16] = data[i];
      for(int j = 0; j < 8; j++) begin
        if(CheckReg[0]) begin
          CheckReg[0]    = CheckReg[0] ^ 1;
          CheckReg[1]    = CheckReg[1] ^ 1;
          CheckReg[13:2] = CheckReg[13:2];
          CheckReg[14]   = CheckReg[14] ^ 1;
          CheckReg[15]   = CheckReg[15];
          CheckReg[16]   = CheckReg[16] ^1;
        end
        CheckReg = CheckReg >> 1;
      end
    end
    FCSBytes = CheckReg;
  endtask

endprogram
