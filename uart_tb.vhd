library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tb is
end entity uart_tb;

architecture simulate_uart of uart_tb is

    -- Signals for the testbench
    signal transmit_data : STD_LOGIC := '0';         -- Initial value for transmit_data
    signal clk : STD_LOGIC := '0';                   -- Initial value for clock
    signal data_in: STD_LOGIC_VECTOR(7 downto 0);    -- Data input signal
    signal tx: STD_LOGIC;                            -- Transmit signal

    -- constants
    constant T : time := 10 ns; -- clock period (10ns clock period gives 100MHz frequency)
    constant clock_frequency : integer := 100_000_000;
    constant baud_rate : integer := 9600; -- baud rate is number of data bits to send per second
    constant single_bit_period : time := 1 sec / baud_rate; -- Time required to transmit one-bit
    constant ten_bits_period : time := 10 * single_bit_period; -- Time required to transmit ten-bits

begin

    -- Declare and instantiate the UART module
    uut: entity work.uart
        generic map (
            baud_rate => baud_rate,
            clock_frequency => clock_frequency
        )
        port map (
            transmit_data => transmit_data,
            clk => clk,
            data_in => data_in,
            tx => tx
        );

    -- Generate a clock of 100MHz
    process
    begin
        clk <= '0';
        wait for T/2;
        clk <= '1';
        wait for T/2;
    end process;

    -- Stimulus process
    -- Transmit the word "Hello" character by character
    process
    begin
        -- Keep waiting in the beginning and do not send any data
        transmit_data <= '0'; -- Do not transmit data
        wait for single_bit_period;

        -- Send first character of "Hello"
        transmit_data <= '1';  -- Start transmission
        data_in <= "01001000";  -- ASCII code for 'H'
        wait for ten_bits_period; -- Wait until all 10-bits have been transferred

        -- Stop transmission and wait some time before sending other characters
        transmit_data <= '0';  -- Stop transmission
        wait for 2 * single_bit_period;

        -- Send second character
        transmit_data <= '1';  -- Resume transmission
        data_in <= "01100101";  -- ASCII code for 'e'
        wait for ten_bits_period;

        -- Stop transmission and wait some time
        transmit_data <= '0';  -- Stop transmission
        wait for 3 * single_bit_period;

        -- Send third character
        transmit_data <= '1';  -- Resume transmission
        data_in <= "01101100";  -- ASCII code for 'l'
        wait for ten_bits_period;

        -- Stop transmission and wait some time
        transmit_data <= '0';  -- Stop transmission
        wait for single_bit_period;

        -- Send fourth character
        transmit_data <= '1';  -- Resume transmission
        data_in <= "01101100";  -- ASCII code for 'l'
        wait for ten_bits_period;

        -- Stop transmission and wait some time
        transmit_data <= '0';  -- Stop transmission
        wait for 2 * single_bit_period;

        -- Send fifth character
        transmit_data <= '1';  -- Resume transmission
        data_in <= "01101111";  -- ASCII code for 'o'
        wait for ten_bits_period;

        -- Stop transmission
        transmit_data <= '0';
        wait; -- End simulation
    end process;

end simulate_uart;

