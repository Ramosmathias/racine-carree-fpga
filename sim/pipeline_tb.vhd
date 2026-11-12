library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity pipeline_tb is
end entity;

architecture test of pipeline_tb is
    constant root_width : positive := 16;
    constant latency : positive := root_width + 1;
    constant period : time := 20 ns;

    subtype radicand is unsigned(2 * root_width - 1 downto 0);
    type sample is record
        cycle : natural;
        value : radicand;
    end record;
    type samples is array (natural range <>) of sample;

    -- Les sept entrees du banc historique, puis deux bornes du domaine non signe.
    constant stimuli : samples := (
        (0, x"00000001"),
        (1, x"00000000"),
        (2, x"00000002"),
        (3, x"00000064"),
        (4, x"00000200"),
        (5, to_unsigned(1194877489, radicand'length)),
        (6, x"FFFFFFFE"),
        (8, x"80000000"),
        (9, x"FFFFFFFF")
    );

    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal start, done, passed : std_logic := '0';
    signal input : std_logic_vector(radicand'range) := (others => '0');
    signal result : std_logic_vector(root_width - 1 downto 0);
begin
    clk <= not clk after period / 2;

    dut : entity work.sqrt_core(Sqrt5)
        generic map (n => root_width)
        port map (A => input, start => start, init => reset, clk => clk, Result => result, done => done);

    verify : process
        file trace : text open write_mode is "pipeline.csv";
        variable row : line;
        variable sent, received : natural := 0;
        variable valid_expected : std_logic;
        variable edge_time : time;
        variable q : unsigned(root_width downto 0);
        variable q_next : unsigned(q'range);
        variable lower, upper : unsigned(2 * q'length - 1 downto 0);
        variable value : radicand;
    begin
        write(row, string'("cycle,time_ns,start,input_hex,done,result"));
        writeline(trace, row);

        wait until falling_edge(clk);
        reset <= '0';

        for cycle in 0 to stimuli(stimuli'high).cycle + latency + 2 loop
            start <= '0';
            if sent < stimuli'length then
                if stimuli(sent).cycle = cycle then
                    input <= std_logic_vector(stimuli(sent).value);
                    start <= '1';
                    sent := sent + 1;
                end if;
            end if;

            wait until rising_edge(clk);
            edge_time := now;
            wait for 1 ns;

            valid_expected := '0';
            if received < stimuli'length then
                if cycle = stimuli(received).cycle + latency then
                    valid_expected := '1';
                end if;
            end if;

            assert done = valid_expected
                report "Unexpected done at cycle " & natural'image(cycle)
                severity failure;

            if done = '1' then
                value := stimuli(received).value;
                q := resize(unsigned(result), q'length);
                q_next := q + 1;
                lower := q * q;
                upper := q_next * q_next;
                assert lower <= value and value < upper
                    report "Wrong integer square root at cycle " & natural'image(cycle)
                    severity failure;
                received := received + 1;
            end if;

            write(row, cycle);
            write(row, ',');
            write(row, edge_time / 1 ns);
            write(row, ',');
            write(row, start);
            write(row, ',');
            write(row, to_hstring(input));
            write(row, ',');
            write(row, done);
            write(row, ',');
            write(row, to_integer(unsigned(result)));
            writeline(trace, row);
            wait until falling_edge(clk);
        end loop;

        assert received = stimuli'length report "Missing outputs" severity failure;
        file_close(trace);
        report natural'image(received) & " results checked at a latency of "
            & natural'image(latency) & " clock periods";
        passed <= '1';
        wait;
    end process;
end architecture;
