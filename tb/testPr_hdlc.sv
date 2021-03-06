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
  task VerifyNormalReceive(logic [127:0][7:0] data, int Size, int suppressPrintouts);
    logic [7:0] ReadData;
    logic all_correct;
    logic all_ready;
    int wrong_index;
    logic[7:0] wrong_data;

    // Read the register Rx_SC and check that all the bits have their correct values
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[4]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Overflow bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_Overflow bit set"); // Assert that Rx_Overflow is not set
      TbErrorCnt++;
    end
    assert(!ReadData[3]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_AbortSignal bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_AbortSignal bit set"); // Assert that Rx_AbortSignal is not set
      TbErrorCnt++;
    end
    assert(!ReadData[2]) begin
      if (!suppressPrintouts) begin
         $display("PASS: Rx_FrameError bit not set");
      end  
    end else begin
      $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
      TbErrorCnt++;
    end
    
    // Read the data buffer length (Rx_Len), and check that it is equal to the expected length
    ReadAddress(3'b100, ReadData);
    assert(ReadData == Size) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Len is equal to the expected size");
      end
    end else begin
      $display("FAIL: Rx_Len is not equal to the expected size");
      TbErrorCnt++;
    end
    

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
    assert(all_correct) begin
      if (!suppressPrintouts) begin
        $display("PASS: All bytes in RxBuff equal to transmitted data");
      end  
    end else begin
      $display("FAIL: RxBuff[%d] = %h (not equal to transmitted data %h)", 
        wrong_index, wrong_data, data[wrong_index]);
      TbErrorCnt++;
    end

    // Assert that Rx_Ready was high for all the read bytes
    assert(all_ready) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Ready was high for all the read bytes");
      end  
    end else begin
      $display("FAIL: Rx_Ready was low after %d received bytes", wrong_index);
      TbErrorCnt++;
    end
    
    // Assert that Rx_Ready goes low after reading all bytes
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[0]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Ready was low after reading all bytes");
      end  
    end else begin
      $display("FAIL: Rx_Ready was still high after reading all bytes");
      TbErrorCnt++;
    end

  endtask


  // VerifyErrorOrDroppedReceive should verify correct value in the Rx status/control
  // register, and that the Rx_Buff returns zero
  task VerifyErrorOrDroppedReceive(logic [127:0][7:0] data, int Size, int drop, int suppressPrintouts);
    logic [7:0] ReadData;

    // Read the register Rx_SC and check that all the bits have their correct values
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[4]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Overflow bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_Overflow bit set"); // Assert that Rx_Overflow is not set
      TbErrorCnt++;
    end

    assert(!ReadData[3]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_AbortSignal bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_AbortSignal bit set"); // Assert that Rx_AbortSignal is not set
      TbErrorCnt++;
    end

    if(drop) begin
      assert(!ReadData[2]) begin
        if (!suppressPrintouts) begin
          $display("PASS: Rx_FrameError not bit set"); 
        end  
      end else begin
        $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
        TbErrorCnt++;
      end
    end else begin
      assert(ReadData[2]) begin
        if (!suppressPrintouts) begin
          $display("PASS: Rx_FrameError bit set"); 
        end  
      end else begin
        $display("FAIL: Rx_FrameError not bit set"); // Assert that Rx_FrameError is set
        TbErrorCnt++;
      end
    end

    assert(!ReadData[0]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Ready bit not set"); 
      end  
    end else begin
        $display("FAIL: Rx_Ready bit set"); // Assert that Rx_Ready is not set
        TbErrorCnt++;
      end

    VerifyRxBufIsZero128Times(suppressPrintouts);
  endtask


  // VerifyAbortReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer is zero after abort.
  task VerifyAbortReceive(logic [127:0][7:0] data, int Size, int suppressPrintouts);
    logic [7:0] ReadData;

    // Read the register Rx_SC and check that the abort bit is set
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[4]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Overflow bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_Overflow bit set"); // Assert that Rx_Overflow is not set
      TbErrorCnt++;
    end
    assert(ReadData[3]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_AbortSignal bit set"); 
      end  
    end else begin
        $display("FAIL: Rx_AbortSignal bit not set"); // Assert that Rx_AbortSignal is set
        TbErrorCnt++;
    end
    assert(!ReadData[2]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_FrameError bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
      TbErrorCnt++;
    end
    assert(!ReadData[0]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Ready bit not set"); 
      end  
    end else begin
      $display("FAIL: Rx_Ready bit set"); // Assert that Rx_Ready is not set
      TbErrorCnt++;
    end

    VerifyRxBufIsZero128Times(suppressPrintouts);
  endtask


  // VerifyOverflowReceive should verify correct value in the Rx status/control
  // register, and that the Rx data buffer contains correct data.
  task VerifyOverflowReceive(logic [127:0][7:0] data, int Size, int suppressPrintouts);
    logic [7:0] ReadData;
    logic all_correct;
    logic all_ready;
    int wrong_index;
    logic[7:0] wrong_data;

    // Read the register Rx_SC and check that the overflow bit is set
    ReadAddress(3'b010, ReadData);
    assert(ReadData[4]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Overflow bit set");
      end
    end else begin
      $display("FAIL: Rx_Overflow bit not set"); // Assert that Rx_Overflow is set
      TbErrorCnt++;
    end
    assert(!ReadData[3]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_AbortSignal bit not set");
      end
    end else begin
      $display("FAIL: Rx_AbortSignal bit set"); // Assert that Rx_AbortSignal is not set
      TbErrorCnt++;
    end
    assert(!ReadData[2]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_FrameError bit not set"); 
      end
    end else begin
      $display("FAIL: Rx_FrameError bit set"); // Assert that Rx_FrameError is not set
      TbErrorCnt++;
    end
    
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
    assert(all_correct) begin
      if (!suppressPrintouts) begin
        $display("PASS: All first 126 bytes in RxBuff equal to transmitted data");
      end
    end else begin
      $display("FAIL: RxBuff[%d] = %h (not equal to transmitted data %h)", 
        wrong_index, wrong_data, data[wrong_index]);
      TbErrorCnt++;
    end

    // Assert that Rx_Ready was high for all the read bytes
    assert(all_ready) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Ready was high for all the read bytes");
      end 
    end else begin
      $display("FAIL: Rx_Ready was low after %d received bytes", wrong_index);
      TbErrorCnt++;
    end

    
    // Assert that Rx_Ready goes low after reading all bytes
    ReadAddress(3'b010, ReadData);
    assert(!ReadData[0]) begin
      if (!suppressPrintouts) begin
        $display("PASS: Rx_Ready was low after reading 126 bytes");
      end 
    end else begin
      $display("FAIL: Rx_Ready was still high after reading 126 bytes");
      TbErrorCnt++;
    end


    // Verify that subsequent reads return zero
    VerifyRxBufIsZero128Times(suppressPrintouts);
  endtask


  task VerifyRxBufIsZero128Times(int suppressPrintouts);
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
    assert(all_zero) begin
      if (!suppressPrintouts) begin
        $display("PASS: All bytes read from RxBuff are zero");
      end 
    end else begin
      $display("FAIL: RxBuff[%d] = %h (not equal to zero)", 
        non_zero_index, non_zero_value);
      TbErrorCnt++;
    end
      
  endtask

 
  // Verify that Tx_Done is low
  task VerifyTxDoneLow();
    logic [7:0] ReadData;

    ReadAddress(3'b000, ReadData);
    assert(!ReadData[0]) else begin
      $display("FAIL: Tx_Done is high");
      TbErrorCnt++;
    end
  endtask


  task ExtractDataFromBitstream(logic [1247:0] bitstream, output logic[127:0][7:0] data, output int dataSize);
    int index;
    int consecutiveOnes;
    int dataIndex;

    dataIndex = 0;
    
    // Iterate over the bits to extract the bytes
    // Start at index 8 to skip the start flag
    consecutiveOnes = 0;
    for(index = 8; consecutiveOnes < 6; index++) begin
        data[dataIndex / 8][dataIndex % 8] = bitstream[index];
	dataIndex++;

        if (bitstream[index]) begin
            consecutiveOnes++;
            if (consecutiveOnes == 5) begin
                index++;

                if (bitstream[index]) begin
                    consecutiveOnes++;
                end else begin
                    consecutiveOnes = 0;
                end
            end
        end else begin
            consecutiveOnes = 0;
        end
    end
    dataSize = dataIndex / 8;
    
  endtask
  
  task VerifyAbortTransmit(logic [127:0][7:0] data, int Size, logic [1247:0] TxBitstream, int bitstreamLength, int suppressPrintouts);
      logic [7:0] ReadData;

      // Check for flags at the start and end of the bitstream
      assert(TxBitstream[7 -: 8] == 8'b01111110) begin
        if (!suppressPrintouts) begin
          $display("PASS: Flag detected at beginning of bitstream");
        end 
      end else begin
        $display("FAIL: No flag at beginning of bitstream");
        TbErrorCnt++;
      end


      assert(TxBitstream[bitstreamLength-1 -: 8] == 8'b11111110) begin
        if (!suppressPrintouts) begin
          $display("PASS: Abort flag detected at end of bitstream");
        end
      end else begin
        $display("FAIL: No abort flag at end of bitstream");
        TbErrorCnt++;
      end


      // Check Tx_AbortedFrame in Tx_SC
      ReadAddress(3'b000, ReadData);
      assert(ReadData[3]) begin
        if (!suppressPrintouts) begin
          $display("PASS: Tx_AbortedFrame is high after aborted transmission");
        end
      end else begin
        $display("FAIL: Tx_AbortedFrame is low after aborted transmission");
        TbErrorCnt++;
      end

  endtask

  task VerifyNormalTransmit(logic [127:0][7:0] data, int Size, logic [1247:0] TxBitstream, int bitstreamLength, logic [15:0] FCSBytes, int suppressPrintouts);
      logic [127:0][7:0] extractedData;
      logic allDataEqual;
      int dataSize;
      logic [7:0] ReadData;

      // Check for flags at the start and end of the bitstream
      assert(TxBitstream[7 -: 8] == 8'b01111110) begin
        if (!suppressPrintouts) begin
          $display("PASS: Flag detected at beginning of bitstream");
        end
      end else begin
        $display("FAIL: No flag at beginning of bitstream");
        TbErrorCnt++;
      end


      assert(TxBitstream[bitstreamLength-1 -: 8] == 8'b01111110) begin
        if (!suppressPrintouts) begin
          $display("PASS: Flag detected at end of bitstream");
        end
      end else begin
        $display("FAIL: No flag at end of bitstream");
        TbErrorCnt++;
      end


      // Extract the data from the bistream
      ExtractDataFromBitstream(TxBitstream, extractedData, dataSize);

      // Check that the transmitted data is the right length
      assert(dataSize == Size + 2) begin
        if (!suppressPrintouts) begin
          $display("PASS: Bistream matches data size (%d bytes)", Size);
        end 
      end else begin
        $display("FAIL: Bistream does not match data size (%d != %d)", dataSize - 2, Size);
        TbErrorCnt++;
      end

      
      // Check transmitted data for correctness
      allDataEqual = 1;
      for(int i = 0; i < Size; i++) begin
        assert(extractedData[i] == data[i]) else begin
          $display("FAIL: extractedData[%h] (%h) != data[%h] (%h)!",
            i, extractedData[i], i, data[i]);
          allDataEqual = 0;
        end
      end
      assert(allDataEqual) begin
        if (!suppressPrintouts) begin
          $display("PASS: Data in bistream matches data sent");
        end 
      end else begin
        $display("FAIL: Extracted data contains errorrs");
        TbErrorCnt++;
      end

      // Check the FCS bytes for correctness
      assert(FCSBytes == {extractedData[Size + 1], extractedData[Size]}) begin
        if (!suppressPrintouts) begin
          $display("PASS: FCS in bistream matches expected FCS (%h)", FCSBytes);
        end 
      end else begin
        $display("FAIL: Expected FCS = %h, found FCS %h in bitstream", FCSBytes, {extractedData[Size], extractedData[Size + 1]});
        TbErrorCnt++;
      end

      // Check that TX_Done is high
      ReadAddress(3'b000, ReadData);
      assert(ReadData[0]) begin
        if (!suppressPrintouts) begin
          $display("PASS: Tx_Done is high after completed transmission");
        end 
      end else begin
        $display("FAIL: Tx_Done is low after completed transmission");
        TbErrorCnt++;
      end

  endtask


  /****************************************************************************
   *                                                                          *
   *                             Simulation code                              *
   *                                                                          *
   ****************************************************************************/

  initial begin
    int rnd_size;

    $display("*************************************************************");
    $display("%t - Starting Test Program (receive)", $time);
    $display("*************************************************************");

    Init();

    //Receive: Size, Abort, FCSerr, NonByteAligned, Overflow, Drop, SkipRead, Suppress Printouts
    Receive(  1, 0, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 10, 0, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 25, 0, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 45, 0, 0, 0, 0, 0, 0, 0); //Normal
    Receive( 47, 0, 0, 0, 0, 0, 0, 0); //Normal
    Receive(126, 0, 0, 0, 0, 0, 0, 0); //Normal

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      Receive($urandom_range(1, 126), 0, 0, 0, 0, 0, 0, 1); //Normal
    end

    Receive(  1, 0, 1, 0, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 10, 0, 1, 0, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 25, 0, 1, 0, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 45, 0, 1, 0, 0, 0, 0, 0); //Normal, wrong FCS
    Receive( 47, 0, 1, 0, 0, 0, 0, 0); //Normal, wrong FCS
    Receive(126, 0, 1, 0, 0, 0, 0, 0); //Normal, wrong FCS

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      Receive($urandom_range(1, 126), 0, 1, 0, 0, 0, 0, 1); //Normal, wrong FCS
    end

    Receive(  1, 0, 0, 1, 0, 0, 0, 0); //Non-byte aligned
    Receive( 40, 0, 0, 1, 0, 0, 0, 0); //Non-byte aligned
    Receive(122, 0, 0, 1, 0, 0, 0, 0); //Non-byte aligned
    Receive(126, 0, 0, 1, 0, 0, 0, 0); //Non-byte aligned

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      Receive($urandom_range(1, 126), 0, 0, 1, 0, 0, 0, 1); //Non-byte aligned
    end

    Receive(  1, 1, 0, 0, 0, 0, 0, 0); //Abort
    Receive(  1, 1, 0, 1, 0, 0, 0, 0); //Abort, non-byte aligned
    Receive( 40, 1, 0, 0, 0, 0, 0, 0); //Abort
    Receive( 40, 1, 0, 1, 0, 0, 0, 0); //Abort, non-byte aligned
    Receive(122, 1, 0, 0, 0, 0, 0, 0); //Abort
    Receive(122, 1, 0, 1, 0, 0, 0, 0); //Abort, non-byte aligned
    Receive(126, 1, 0, 0, 0, 0, 0, 0); //Abort

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      Receive($urandom_range(1, 126), 1, 0, 0, 0, 0, 0, 1); //Abort
    end

    Receive(126, 0, 0, 0, 1, 0, 0, 0); //Overflow

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      Receive(126, 0, 0, 0, 1, 0, 0, 1); //Overflow
    end

    // Check that unread frame is properly discarded
    Receive(123, 0, 0, 0, 0, 0, 1, 0); //Normal, skip read
    Receive( 10, 0, 0, 0, 0, 0, 0, 0); //Normal

    Receive( 10, 0, 0, 0, 0, 1, 0, 0); //Drop packet halfway
    Receive( 26, 0, 0, 0, 0, 1, 0, 0); //Drop packet halfway
    Receive( 46, 0, 0, 0, 0, 1, 0, 0); //Drop packet halfway
    Receive( 48, 0, 0, 0, 0, 1, 0, 0); //Drop packet halfway
    Receive(126, 0, 0, 0, 0, 1, 0, 0); //Drop packet halfway

    $display("Starting constrained random testing");
    for (int i = 0; i < 1000; i++) begin
      Receive($urandom_range(2, 126), 0, 0, 0, 0, 1, 0, 1); //Drop packet halfway
    end


    $display("*************************************************************");
    $display("%t - Starting Test Program (transmit)", $time);
    $display("*************************************************************");

    Transmit(3, 0, 0); //Normal
    Transmit(26, 0, 0); //Normal
    Transmit(100, 0, 0); //Normal
    Transmit(126, 0, 0); //Normal

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      Transmit($urandom_range(3, 126), 0, 1); //Normal
    end

    Transmit(3, 1, 0); // Abort halfway
    Transmit(26, 1, 0); // Abort halfway
    Transmit(100, 1, 0); // Abort halfway
    Transmit(126, 1, 0); // Abort halfway
    

    $display("Starting constrained random testing");
    for (int i = 0; i < 300; i++) begin
      rnd_size = $urandom_range(3, 126);
      //$display("*** Size: %d", rnd_size);
      Transmit(rnd_size, 1, 1); // Abort halfway
    end

    $display("*************************************************************");
    $display("%t - Finishing Test Program", $time);
    $display("*************************************************************");
    $stop;
  end

  final begin

    $display("*********************************");
    $display("*                               *");
    $display("* \tAssertion Errors: %d\t  *", TbErrorCnt + uin_hdlc.ErrCntAssertions);
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


/////////////////////////////////////
// RECEIVE
/////////////////////////////////////
  task Receive(int Size, int Abort, int FCSerr, int NonByteAligned, int Overflow, int Drop, int SkipRead, int suppressPrintouts);
    logic [127:0][7:0] ReceiveData;
    logic       [15:0] FCSBytes;
    logic   [2:0][7:0] OverflowData;

    if (!suppressPrintouts) begin
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
    end

    for (int i = 0; i < Size; i++) begin
      ReceiveData[i] = $urandom;
    end
    ReceiveData[Size]   = '0;
    ReceiveData[Size+1] = '0;

    //Calculate FCS bits;
    GenerateFCSBytes(ReceiveData, Size, FCSBytes);
    if (FCSerr) begin
      ReceiveData[Size]   = ~FCSBytes[7:0];
      ReceiveData[Size+1] = $urandom;
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
      OverflowData[0] = $urandom;
      OverflowData[1] = $urandom;
      OverflowData[2] = $urandom;
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
      assert(uin_hdlc.Rx_EoF) begin
        if (!suppressPrintouts) begin
          $display("PASS: Rx_EoF is set");
        end
      end else begin
        $display("FAIL: Rx_EoF is not set");
        TbErrorCnt++;
      end
    end

    repeat(2)
      @(posedge uin_hdlc.Clk);

    if (Drop) begin
      WriteAddress(3'b010, 8'h02);
    end

    if(Abort)
      VerifyAbortReceive(ReceiveData, Size, suppressPrintouts);
    else if(Overflow)
      VerifyOverflowReceive(ReceiveData, Size, suppressPrintouts);
    else if(Drop)
      VerifyErrorOrDroppedReceive(ReceiveData, Size, 1, suppressPrintouts);
    else if(FCSerr)
      VerifyErrorOrDroppedReceive(ReceiveData, Size, 0, suppressPrintouts);
    else if(NonByteAligned)
      VerifyErrorOrDroppedReceive(ReceiveData, Size, 0, suppressPrintouts);
    else if(!SkipRead)
      VerifyNormalReceive(ReceiveData, Size, suppressPrintouts);

    #5000ns;
  endtask


/////////////////////////////////////
// TRANSMIT
/////////////////////////////////////
  task Transmit(int Size, int Abort, int suppressPrintouts);
    logic       [125:0][7:0] TransmitData;
    logic       [1247:0]     TxBitstream;
    logic       [15:0]       FCSBytes;
    int                      index;
    int                      consecutiveOnes;
    logic [7:0] ReadData;

    if (!suppressPrintouts) begin
      string msg;
      if(Abort)
        msg = "- Abort";
      else
        msg = "- Normal";
      $display("*************************************************************");
      $display("%t - Starting task Transmit %s", $time, msg);
      $display("*************************************************************");
    end

    for (int i = 0; i < Size; i++) begin
      TransmitData[i] = $urandom;
      WriteAddress(3'b001, TransmitData[i]);
      @(posedge uin_hdlc.Clk);
      VerifyTxDoneLow();
    end
    TransmitData[Size] = 1'b0;
    TransmitData[Size+1] = 1'b0;

    // Check that Tx_Full goes high after writing 126 bytes to the buffer
    if (Size == 126) begin
      ReadAddress(3'b000, ReadData);
      assert(ReadData[4]) begin
        if (!suppressPrintouts) begin
          $display("PASS: Tx_Full is high after writing 126 bytes to the buffer");
        end
      end else begin
        $display("FAIL: Tx_Full is low after writing 126 bytes to the buffer");
        TbErrorCnt++;
      end
    end

    GenerateFCSBytes(TransmitData, Size, FCSBytes);

    // Start the transmission by asserting Tx_Enable in Tx_SC
    WriteAddress(3'b000, 8'h2);
    
    // Maybe execute transmission here, and pass the bitstream to the verify tasks below...
    // Remember:
    //  - Bit stuffing
    //  - To wait for the start flag (as CRC takes varying time)
    //  - Check Tx_AbortedTrans with Concurrent Assertion
    //  - Requirement 7, check that in Idle, the device transmits high
    
    // Wait until FCS calculation is done
    while (uin_hdlc.Tx) begin
        @(posedge uin_hdlc.Clk);
    end

    // Run the device until an abort or done flag sequence is detected
    consecutiveOnes = 0;
    for(index = 0; index < 8 || consecutiveOnes < 6; index++) begin
        TxBitstream[index] = uin_hdlc.Tx;
        if (uin_hdlc.Tx) begin
            consecutiveOnes++;
        end else begin
            consecutiveOnes = 0;
        end
        @(posedge uin_hdlc.Clk);

        // Trigger an abort about halfway in if needed
        if (Abort && index == (8 + Size * 8 / 2)) begin
            WriteAddress(3'b000, 8'h4);
        end
    end

    TxBitstream[index] = uin_hdlc.Tx;
    @(posedge uin_hdlc.Clk);
    index++;

    // Run the applicable verification task
    if(Abort)
      VerifyAbortTransmit(TransmitData, Size, TxBitstream, index, suppressPrintouts);
    else
      VerifyNormalTransmit(TransmitData, Size, TxBitstream, index, FCSBytes, suppressPrintouts);
    
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

