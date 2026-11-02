library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ctrl_fsm is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        st_done : in std_logic;
        err_push : in std_logic;
        ref_push : in std_logic;

        fx_en_shift : out std_logic;
        fx_en_weight : out std_logic;
        st_en       : out std_logic;
        reg_en      : out std_logic
    );
end entity;

architecture Behavioral of ctrl_fsm is
    -- this needs to shift register input, and gate speaker register for when convolution finishes.
    --it also needs to gate weight registers, and x' history registers in parallel.
    type t_receive_state is (IDLE, STATIC_FIR, SPEAKER, WEIGHT_UPDATE);
begin
    -- weight updates should finish immediately.



end Behavioral;