----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/11/2022 05:24:33 PM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY top IS
    GENERIC(
        shift       : INTEGER := 7;
        d_width     : INTEGER := 24;
        coeff1  : integer :=  1;
        coeff2  : integer :=  2;
        coeff3  : integer :=  4;
        coeff4  : integer :=  7;
        coeff5  : integer := 11;
        coeff6  : integer := 14;
        coeff7  : integer := 16;
        coeff8  : integer := 17;
        coeff9  : integer := 16;
        coeff10 : integer := 14;
        coeff11 : integer := 11;
        coeff12 : integer :=  7;
        coeff13 : integer :=  4;
        coeff14 : integer :=  2;
        coeff15 : integer :=  1);                    --data width
    PORT(
        CLK100MHZ   :  IN  STD_LOGIC;                     --system clock (100 MHz on Basys board)
        reset_n     :  IN  STD_LOGIC;                     --active low asynchronous reset
        rst_l       :  IN  STD_LOGIC;                     --reset FIR left
        rst_r       :  IN  STD_LOGIC;                     --reset FIR right
        mclk        :  OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --master clock
        sclk        :  OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --serial clock (or bit clock)
        ws          :  OUT STD_LOGIC_VECTOR(1 DOWNTO 0);  --word select (or left-right clock)
        sd_rx       :  IN  STD_LOGIC;                     --serial data in
        sd_tx       :  OUT STD_LOGIC);                    --serial data out
END top;

ARCHITECTURE rtl OF top IS

    SIGNAL master_clk    :  STD_LOGIC;                             --internal master clock signal
    SIGNAL serial_clk    :  STD_LOGIC := '0';                      --internal serial clock signal
    SIGNAL word_select   :  STD_LOGIC := '0';                      --internal word select signal
    SIGNAL n_word_select :  STD_LOGIC := '0';                      --internal word select signal
    SIGNAL l_data_rx     :  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --left channel data received from I2S Transceiver component
    SIGNAL r_data_rx     :  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --right channel data received from I2S Transceiver component
    SIGNAL l_data_tx     :  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --left channel data to transmit using I2S Transceiver component
    SIGNAL r_data_tx     :  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  --right channel data to transmit using I2S Transceiver component
            
 
    --declare PLL to create 11.29 MHz master clock from 100 MHz system clock
    COMPONENT clk_wiz_0 IS
        PORT(
            clk_in1     :  IN STD_LOGIC  := '0';
            clk_out1    :  OUT STD_LOGIC);
    END COMPONENT;

    --declare I2S Transceiver component
    COMPONENT i2s_transceiver IS
        GENERIC(
            mclk_sclk_ratio :  INTEGER := 4;    --number of mclk periods per sclk period
            sclk_ws_ratio   :  INTEGER := 64;   --number of sclk periods per word select period
            d_width         :  INTEGER := 24);  --data width
        PORT(
            reset_n     :  IN   STD_LOGIC;                              --asynchronous active low reset
            mclk        :  IN   STD_LOGIC;                              --master clock
            sclk        :  OUT  STD_LOGIC;                              --serial clock (or bit clock)
            ws          :  OUT  STD_LOGIC;                              --word select (or left-right clock)
            sd_tx       :  OUT  STD_LOGIC;                              --serial data transmit
            sd_rx       :  IN   STD_LOGIC;                              --serial data receive
            l_data_tx   :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --left channel data to transmit
            r_data_tx   :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --right channel data to transmit
            l_data_rx   :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);   --left channel data received
            r_data_rx   :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0));  --right channel data received
    END COMPONENT;
    
    COMPONENT fir_filter IS
        GENERIC(
            d_width : integer := 24;
            shift   : integer := 7;
            coeff1  : integer :=  1;
            coeff2  : integer :=  2;
            coeff3  : integer :=  4;
            coeff4  : integer :=  7;
            coeff5  : integer := 11;
            coeff6  : integer := 14;
            coeff7  : integer := 16;
            coeff8  : integer := 17;
            coeff9  : integer := 16;
            coeff10 : integer := 14;
            coeff11 : integer := 11;
            coeff12 : integer :=  7;
            coeff13 : integer :=  4;
            coeff14 : integer :=  2;
            coeff15 : integer :=  1);
        PORT(
            clk        : in  std_logic;                        -- system clock
            rst        : in  std_logic;                        -- reset
            i_data     : in  std_logic_vector( d_width-1 downto 0);    -- input at time n
            o_data     : out std_logic_vector( d_width-1 downto 0));   -- output at time n
    END COMPONENT fir_filter;



BEGIN

    --instantiate PLL to create master clock
    i2s_clock: clk_wiz_0 
    PORT MAP(clk_in1 => CLK100MHZ, clk_out1 => master_clk);
  
    --instantiate I2S Transceiver component
    i2s_transceiver_0: i2s_transceiver
    GENERIC MAP(mclk_sclk_ratio => 4, sclk_ws_ratio => 64, d_width => d_width)
    PORT MAP(reset_n => reset_n, mclk => master_clk, sclk => serial_clk, ws => word_select, sd_tx => sd_tx, sd_rx => sd_rx,
             l_data_tx => l_data_tx, r_data_tx => r_data_tx, l_data_rx => l_data_rx, r_data_rx => r_data_rx);
             
    
    n_word_select <= not word_select;
    -- passabasso
    r_fir_filter: fir_filter
    GENERIC MAP(d_width => d_width, shift => shift, 
                coeff1  =>  coeff1,  coeff2  =>  coeff2,  coeff3  =>  coeff3,  coeff4  => coeff4,  coeff5  => coeff5, 
                coeff6  =>  coeff6,  coeff7  =>  coeff7,  coeff8  =>  coeff8,  coeff9  => coeff9,  coeff10 => coeff10, 
                coeff11 =>  coeff11, coeff12 =>  coeff12, coeff13 =>  coeff13, coeff14 => coeff14, coeff15 => coeff15)
    PORT MAP(clk => n_word_select, rst => rst_r, i_data => r_data_rx, o_data => r_data_tx);
    
    -- passaalto
    l_fir_filter: fir_filter
    GENERIC MAP(d_width => d_width, shift => shift, 
                coeff1  =>   0, coeff2  =>   -1, coeff3  =>   -2,  coeff4  =>  -4, coeff5  => -7, 
                coeff6  =>  -9, coeff7  =>  -11, coeff8  =>  116,  coeff9  => -11, coeff10 => -9, 
                coeff11 =>  -7, coeff12 =>   -4, coeff13 =>   -2,  coeff14 =>  -1, coeff15 =>  0)
    PORT MAP(clk => word_select, rst => rst_l, i_data => l_data_rx, o_data => l_data_tx);


    mclk(0) <= master_clk;  --output master clock to ADC
    mclk(1) <= master_clk;  --output master clock to DAC
    sclk(0) <= serial_clk;  --output serial clock (from I2S Transceiver) to ADC
    sclk(1) <= serial_clk;  --output serial clock (from I2S Transceiver) to DAC
    ws(0) <= word_select;   --output word select (from I2S Transceiver) to ADC
    ws(1) <= word_select;   --output word select (from I2S Transceiver) to DAC

    --r_data_tx <= r_data_rx;  --assign right channel received data to transmit (to playback out received data)
    --l_data_tx <= l_data_rx;  --assign left channel received data to transmit (to playback out received data)

END rtl;
