library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity sin_input is

    port (  
            bclk : in std_logic;
            lrcl : in std_logic;
            data : out std_logic
    );

end entity;



architecture Behavioral of sin_input is
    constant N_SAMPLES        : integer := 128;
    type t_sin_array is array (0 to N_SAMPLES - 1) of integer;
    -- sinusoid samples. Generate in matlab using sin(2 * pi * (1:128) / 128) or whatever N you wanna use.
    constant data_arr         : t_sin_array := (   8, 16, 23, 31, 39, 47, 55, 63,
                                                    70, 78, 86, 94, 102, 109, 117, 125,
                                                    133, 141, 148, 156, 164, 172, 180, 188,
                                                    195, 203, 211, 219, 227, 234, 242, 250,
                                                    258, 266, 273, 281, 289, 297, 305, 313,
                                                    320, 328, 336, 344, 352, 359, 367, 375,
                                                    383, 391, 398, 406, 414, 422, 430, 438,
                                                    445, 453, 461, 469, 477, 484, 492, 500,
                                                    508, 516, 523, 531, 539, 547, 555, 563,
                                                    570, 578, 586, 594, 602, 609, 617, 625,
                                                    633, 641, 648, 656, 664, 672, 680, 688,
                                                    695, 703, 711, 719, 727, 734, 742, 750,
                                                    758, 766, 773, 781, 789, 797, 805, 813,
                                                    820, 828, 836, 844, 852, 859, 867, 875,
                                                    883, 891, 898, 906, 914, 922, 930, 938,
                                                    945, 953, 961, 969, 977, 984, 992, 1000);
    signal count            : unsigned(6 downto 0) := X"0" & "001";
    
    signal lrcl_prev        : std_logic;
    signal curr_out         : std_logic_vector(31 downto 0) := std_logic_vector(unsigned(to_signed(data_arr(0), 18))) & X"000" & "00";
    -- signal curr_out         : std_logic_vector(31 downto 0) := (Others => '0');
begin
    process (bclk)
    begin
        if (rising_edge(bclk)) then
            lrcl_prev <= lrcl;
            -- changed ws value, we need to use a new sample.
            if (lrcl_prev /= lrcl) then
                curr_out <= std_logic_vector(unsigned(to_signed(data_arr(to_integer(count)), 18))) & X"000" & "00";
                if (count < data_arr'length - 1) then
                    count <= count + 1;
                else
                    count <= (Others => '0');
                end if;
            else
                curr_out <= curr_out(30 downto 0) & '0';
            end if;
        end if;
        

    end process;

    data <= curr_out(31);
    -- data <= curr_bit;
    
    


end architecture;