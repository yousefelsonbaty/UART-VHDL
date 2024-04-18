library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart is
    generic (
        -- The baud rate (number of data bits transmitted per second) is 9600
        baud_rate : integer := 9600;
        clock_frequency : integer := 100_000_000
    );
    port (
        transmit_data : in STD_LOGIC; -- controls whether to transmit data_in
        clk : in STD_LOGIC; -- clock signal
        data_in: in STD_LOGIC_VECTOR(7 downto 0); -- 8-bit input data to be transmitted
        tx: out STD_LOGIC -- output transmit signal
    );
end uart;

architecture uart_logic of uart is
    --------------------------- baud_rate_generator signals ---------------------------
    -- To produce the required baud rate of 9600 from our clock
    -- frequency, we divide the clock_frequency by the baud rate
    signal counter : integer range 0 to (clock_frequency / baud_rate) + 1 := 0;
    -- This flag indicates when we can transmit a single bit of data. It stays zero 
    -- all the time and becomes one at the moment when we can send a single bit of data
    signal transmit_one_bit_flag : std_logic := '0';

    --------------------------- data_transmission signals ---------------------------
    type data_transmission_state is (ready, transmitting_data);
    signal current_transmission_state : data_transmission_state := ready; -- current state for data transmission process
    -- This contains the 8-bits of data we want to transmit and 2-bit control signals indicating transfer start and stop
    signal tx_10bits_chunk: std_logic_vector(9 downto 0);
    -- This tracks the index of the bit we are sending out of tx port
    signal bit_out_count : integer range 0 to 9 := 0;
    -- This contains the bit that will be sent out of tx port
    signal tx_bit_out : std_logic := '1';

    ---------------------------------------------------------------------------------
begin

    -- This process generates the required baud rate from our original clock frequency
    baud_rate_generator: process(clk)
    begin
        if(rising_edge(clk)) then
            -- If we are not transmitting data, no need to generate baud rate signals
            if(current_transmission_state = ready) then
                counter <= 0;
                transmit_one_bit_flag <= '0';
            -- Generate the transmit_one_bit_flag to control sending data at the required
            -- baud rate only when we are transmitting data in transmitting_data state
            elsif(counter < (clock_frequency / baud_rate)) then
                counter <= counter + 1;
                transmit_one_bit_flag <= '0';
            else
                transmit_one_bit_flag <= '1';
                counter <= 0;
            end if;
        end if;
    end process;

    -- This process handles data transmission
    data_transmission: process(clk)
    begin
        if(rising_edge(clk)) then
            case(current_transmission_state) is

                -- In ready state, check whether the user wants to send data or stay idle
                when ready =>
                    -- Keep sending idle ones if we did not start data transmission process
                    tx_bit_out <= '1';
                    -- When transmit_data port is '0', it signals that we do
                    -- not want to transmit the data_in. So, stay idle.
                    if(transmit_data = '0') then
                        current_transmission_state <= ready;
                    -- Else, transmit the 8-bits of data and the start/stop indication 2-bits
                    else
                        -- The variable below contains the data of 8-bits we want to transmit
                        -- The LSB of zero indicates the beginning of data transmission
                        -- and the MSB of one indicates the end of data transmission
                        tx_10bits_chunk <= ('1' & data_in & '0');
                        
                        current_transmission_state <= transmitting_data;
                    end if;

                -- Transmit the data out of tx port
                when transmitting_data =>
                    -- If transmission is enabled, keep sending data out 
                    -- or move to next state if transmission is done
                    if(transmit_one_bit_flag = '1') then
                        -- Output one-bit of data
                        tx_bit_out <= tx_10bits_chunk(bit_out_count);
                        -- Keep transmitting data if we are not done with sending all 10-bits
                        if(bit_out_count < 9) then
                            bit_out_count <= bit_out_count + 1;
                            current_transmission_state <= transmitting_data;
                        -- Go to ready state if we have sent all 10-bits out
                        else
                            bit_out_count <= 0;
                            current_transmission_state <= ready;
                        end if;
                    -- If transmission is not enabled, keep waiting
                    else
                        current_transmission_state <= transmitting_data;
                    end if;

                -- If none of the cases match, put the state as the default state of ready
                when others => current_transmission_state <= ready;

            end case;
        end if;
    end process;

    -- Connect the tx output port to tx_bit_out signal
    tx <= tx_bit_out;
    
end uart_logic;

