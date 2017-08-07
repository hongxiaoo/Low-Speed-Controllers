module uart_controller (
  input  logic       clk,
  input  logic       reset,
  input  logic       parity_en,
  input  logic       rx_uart,
  output logic       tx_uart,
  output logic       tx_data_ready,
  input  logic       tx_data_valid,
  input  logic [7:0] tx_data,
  output logic       rx_data_valid,
  output logic [7:0] rx_data,
  output logic       busy
  );
  
  typedef enum {
    IDLE,
    START,
    ACTIVE,
    PARITY,
    STOP,
    DONE
  } state_type;
  state_type state_tx = IDLE;
  state_type state_rx = IDLE;
  
  logic [7:0] data_buffer;
  logic [6:0] count_tx = 7'b0;
  logic [6:0] count_rx = 7'b0;
  logic parity_tx = 0;
  logic parity_rx = 0;
  
  always_ff @(posedge clk) begin
    if (state_tx == IDLE && tx_data_valid && tx_data_ready) begin
      data_buffer <= tx_data;
    end else if (state_tx == ACTIVE && count_tx[2:0] == 3'b111) begin
      data_buffer <= {1'b0,data_buffer[7:1]};
    end
  end
  
  always_ff @(posedge clk) begin
    if (state_tx == IDLE && tx_data_valid && tx_data_ready) begin
      parity_tx <= ^tx_data;
    end
  end
  
  always_ff @(posedge clk) begin
    if (reset) begin
      tx_data_ready <= 1'b0;
    end else begin
      tx_data_ready <= state_tx == IDLE;
    end
  end
  
  always_ff @(posedge clk) begin
    case (state_tx)
      START   : tx_uart <= 1'b0;
      ACTIVE  : tx_uart <= data_buffer[0];
      PARITY  : tx_uart <= parity_tx;
      default : tx_uart <= 1'b1;
    endcase
  end
  
  always_ff @(posedge clk) begin
    if (reset) begin
      state_tx <= IDLE;
      count_tx <= 0;
    end else begin
      case (state_tx)
        IDLE : begin
          if (tx_data_valid && tx_data_ready) begin
            state_tx <= START;
          end
        end
        START : begin
          if (count_tx >= 15) begin
            state_tx <= ACTIVE;
            count_tx <= 0;
          end else begin
            count_tx <= count_tx + 1;
          end
        end
        ACTIVE : begin
          if (count_tx >= 127) begin
            state_tx <= parity_en ? PARITY : STOP;
            count_tx <= 0;
          end else begin
            count_tx <= count_tx + 1;
          end
        end
        PARITY : begin
          if (count_tx >= 15) begin
            state_tx <= STOP;
            count_tx <= 0;
          end else begin
            count_tx <= count_tx + 1;
          end
        end
        STOP : begin
          if (count_tx >= 15) begin
            state_tx <= DONE;
            count_tx <= 0;
          end else begin
            count_tx <= count_tx + 1;
          end
        end
        DONE : begin
          if (count_tx >= 15) begin
            state_tx <= IDLE;
            count_tx <= 0;
          end else begin
            count_tx <= count_tx + 1;
          end
        end
        default : begin
          state_tx <= IDLE;
          count_tx <= 0;
        end
      endcase
    end
  end
  
endmodule
