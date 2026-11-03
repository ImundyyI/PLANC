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
        lms_done : in std_logic;
        ada_done : in std_logic;

        fx_en_shift : out std_logic;
        fx_en_weight : out std_logic;
        st_en       : out std_logic;
        reg_en      : out std_logic;
        rd_sel      : out std_logic;
        out_en      : out std_logic
    );
end entity;

architecture Behavioral of ctrl_fsm is
    -- this needs to shift register input, and gate speaker register for when convolution finishes.
    --it also needs to gate weight registers, and x' history registers in parallel.
    type t_state is (IDLE, SPEAKER, STATIC_FIR, WEIGHT_UPDATE);

    signal state        : t_state := IDLE;
    signal state_next   : t_state;
begin
    -- always immediately load these values into the shift register AND standalone error sample register.
    -- s.t we dont waste any cycles.
    reg_en <= err_push or ref_push;

    FSM_STATES : process (state, err_push, st_done, ada_done, lms_done)
    begin
        state_next <= state;
        st_en <= '0';
        fx_en_shift <= '0';
        fx_en_weight <= '0';
        rd_sel <= '0';
        out_en <= '0';
    
        case state is
            when IDLE =>
                if err_push = '1' then
                    st_en <= '1';
                    state_next <= SPEAKER;
                end if; 
            when SPEAKER =>
                if ada_done = '1' then
                    out_en <= '1';
                    state_next <= STATIC_FIR;
                end if;
            when STATIC_FIR =>
                -- now that the shift register has the required values.
                rd_sel <= '1';
                if st_done = '1' then
                    fx_en_shift <= '1';
                    state_next <= WEIGHT_UPDATE;
                end if;
            when WEIGHT_UPDATE =>                
                if lms_done = '1' then
                    fx_en_weight <= '1';
                    state_next <= IDLE;
                end if;
            when others =>
                
        end case;
    end process;
    
    -- weight updates should finish immediately.
    -- FSM state register.
    FSM_REG : process (clk, reset)
    begin
        if (reset = '0') then
            state <= IDLE;
        
        elsif (rising_edge(clk)) then
            state <= state_next;

        end if;

    end process;


end Behavioral;