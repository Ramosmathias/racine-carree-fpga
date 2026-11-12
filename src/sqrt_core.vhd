library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sqrt_core is
	generic(n:natural:=16);
	PORT
	(
		A: IN std_logic_vector((2*n)-1 DOWNTO 0);
		start: IN std_logic;
		init: IN std_logic;
		clk: IN std_logic;
		Result: OUT std_logic_vector(n-1 DOWNTO 0);
		done: OUT std_logic
	);
end entity;

------------------------------------------------------------
---------------------- Architecture 1 ----------------------
------------------------------------------------------------

architecture Sqrt1 of sqrt_core is

type state is (S0, S1, S2, S3);

signal cur_state : state;
signal fut_state : state:= S0;

signal xn_p  : std_logic_vector((2*n)-1 DOWNTO 0); --present
signal xn_f  : std_logic_vector((2*n)-1 DOWNTO 0); --futur

signal xn1_p : std_logic_vector((2*n)-1 DOWNTO 0); --present
signal xn1_f : std_logic_vector((2*n)-1 DOWNTO 0); --futur

begin


	Seq:process(clk) is
	begin
		if rising_edge(clk) then
			if init='1' then
				cur_state <= S0;
				xn_p <= (others => '0');
				xn1_p <= (others => '0');
			else
				cur_state <= fut_state;
				xn_p <= xn_f;
				xn1_p <= xn1_f;
			end if;
		end if;
	end process;


	Comb:process(A, start, cur_state, xn_p, xn1_p) is


	begin
	  -- valeurs par defaut (hold)
	fut_state <= cur_state;
	xn_f      <= xn_p;
	xn1_f     <= xn1_p;
	done      <= '0';
  Result    <= (others => '0');
	case cur_state is
		when S0 =>
			xn_f <= A;
			xn1_f <= std_logic_vector(unsigned(A)/2);
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));
			fut_state <= S1;


		when S1 =>
			if unsigned(xn_p) <= 1 then
				xn1_f <= xn_p;
				fut_state <= S3;
			else
				if xn1_p = xn_p  then
					fut_state <= S3;
				else
					xn_f <= xn1_p;
					fut_state <= S2;
				end if;
			end if;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));

		when S2 =>
		  if unsigned(xn_p)=0 then
		    xn1_f<=(others => '0');
		  else
			   xn1_f <= std_logic_vector(((unsigned(xn_p) +  (unsigned(A)/unsigned(xn_p)))/2) );
			end if;
			fut_state <= S1;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));


		when S3 =>
			done <= '1';
			Result <= xn_p(n-1 DOWNTO 0);
			if start='1' then
				fut_state <= S0;
			else
				fut_state <= S3;
			end if;

		when others =>
			fut_state <= S0;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));

	end case;
	end process;

end architecture;


----------------------------------------------------------
-------------------- Architecture 2 ----------------------
----------------------------------------------------------

architecture Sqrt2 of sqrt_core is

type state is (S0, S1, S2, S3, S4);

signal cur_state : state;
signal fut_state : state:= S0;

signal Xp: std_logic_vector((2*n)-1 downto 0);
signal Xf: std_logic_vector((2*n)-1 downto 0);-- := ((2*n)-2 => '1', others => '0');
signal Vp: std_logic_vector(n-2 downto 0);
signal Vf: std_logic_vector(n-2 downto 0);-- := (n-2 => '1', others => '0');
signal Zp: std_logic_vector(n-1 downto 0);
signal Zf: std_logic_vector(n-1 downto 0);-- := (n-1 => '1', others => '0');

--signal I_p : std_logic_vector(3 downto 0);--present
--signal I_f : std_logic_vector(3 downto 0);--futur

signal i_p : integer;
signal i_f : integer; --:= n-2; --unsigned(n-1 DOWNTO 0); --:= (n-2 => '1', others => '0');

begin

	Seq:process(clk) is
	begin
		if rising_edge(clk) then
			if init='1' then
			  cur_state <= S0;
				Xp <= (others => '0');
				Vp <= (others => '0');
				Zp <= (others => '0');
				i_p <= 0;
			else
				cur_state <= fut_state;
				Xp <= Xf;
				Vp <= Vf;
				Zp <= Zf;
				i_p <= i_f;
			end if;
		end if;
	end process;


	Comb:process(A,start,cur_state,Xp, Vp, Zp, i_p ) is
	-- valeurs par defaut (hold)


	begin
	Xf        <= Xp;
  Vf        <= Vp;
  Zf        <= Zp;
  i_f       <= i_p;
  fut_state <= cur_state;

	case cur_state is
		when S0 =>
      Xf <= std_logic_vector(shift_left(to_unsigned(1, 2*n), 2*n-2));
      Vf <= std_logic_vector(shift_left(to_unsigned(1, n-1), n-2));
      Zf <= std_logic_vector(shift_left(to_unsigned(1, n), n-1));
			i_f <= n-2;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));
			fut_state<=S1;

		when S1 =>
		  if unsigned(A) <= 1 then
		    Result <= A(n-1 DOWNTO 0);
		    fut_state<=S4;
		  else
		      if (i_p>=0) then
				    fut_state<=S2;
			    else
				    fut_state<=S3;
			    end if;
			    Result <= std_logic_vector(to_unsigned(0,n));
			end if;
			done <= '0';

		when S2 =>
			if unsigned(Xp)>unsigned(A) then
				--Xf<=std_logic_vector(unsigned(Xp)- resize((unsigned(Vp)*((unsigned(Zp)*2)-unsigned(Vp))),Xp'length));
				Xf <= std_logic_vector(unsigned(Xp) -resize(resize(unsigned(Vp), Zp'length) *( (unsigned(Zp) * 2) - resize(unsigned(Vp), Zp'length) ),Xp'length));
				--Zf<=std_logic_vector(unsigned(Zp)-unsigned(Vp));
				Zf<=std_logic_vector(unsigned(Zp)-resize(unsigned(Vp), Zp'length));
			elsif unsigned(Xp)<unsigned(A) then

				--Xf<=std_logic_vector(unsigned(Xp)+ resize((unsigned(Vp)*(unsigned(Vp)+(unsigned(Zp)*2))),Xp'length));
			  Xf <= std_logic_vector(unsigned(Xp) +resize(resize(unsigned(Vp), Zp'length) *( resize(unsigned(Vp), Zp'length) + (unsigned(Zp) * 2) ),Xp'length));
			  --Zf<=std_logic_vector(unsigned(Zp)+unsigned(Vp));
			  Zf<=std_logic_vector(unsigned(Zp)+resize(unsigned(Vp), Zp'length));
			else
        Xf <= Xp;
        Zf <= Zp;
			end if;
			Vf<=std_logic_vector((unsigned(Vp)/2));
			i_f<=i_p-1;
			fut_state<=S1;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));

		when S3 =>
			if (unsigned(Xp)> unsigned(A)) then
				 Result <= std_logic_vector(unsigned(Zp)-1);
			else
				 Result <= Zp;
			end if;
			done <= '1';
			fut_state<=S4;

    when S4 =>
      done <= '1';
			if start='1' then
				fut_state<=S0;
			else
				fut_state<=S4;
			end if;

		when others =>
			fut_state <= S0;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));

	end case;
	end process;

end architecture;



------------------------------------------------------------
---------------------- Architecture 3 ----------------------
------------------------------------------------------------

architecture Sqrt3 of sqrt_core is

type state is (S0, S1, S12, S2, S3, S4);

signal cur_state : state;
signal fut_state : state:= S0;

signal Ap: std_logic_vector((2*n)-1 downto 0);
signal Af: std_logic_vector((2*n)-1 downto 0);
signal Vp: std_logic_vector((2*n)-1 downto 0);
signal Vf: std_logic_vector((2*n)-1 downto 0);-- := ((2*n)-2 => '1', others => '0');
signal Zp: std_logic_vector((2*n)-1 downto 0);
signal Zf: std_logic_vector((2*n)-1 downto 0);-- := (n-1 => '1', others => '0');


signal i_p : integer;
signal i_f : integer; --:= n-2; --unsigned(n-1 DOWNTO 0); --:= (n-2 => '1', others => '0');

begin

	Seq:process(clk) is
	begin
		if rising_edge(clk) then
			if init='1' then
				cur_state <= S0;
				Ap <= (others => '0');
				Vp <= (others => '0');
				Zp <= (others => '0');
				i_p <= 0;
			else
				cur_state <= fut_state;
				Ap <= Af;
				Vp <= Vf;
				Zp <= Zf;
				i_p <= i_f;
			end if;
		end if;
	end process;


	Comb:process(A,start,cur_state,Ap,Vp,Zp,i_p) is



	begin
	  -- valeurs par defaut (hold)
	Af        <= Ap;
  Vf        <= Vp;
  Zf        <= Zp;
  i_f       <= i_p;
  fut_state <= cur_state;
  done      <= '0';
  Result    <= (others => '0');
	case cur_state is
		when S0 =>
			Af <= A;
			Vf <= std_logic_vector(shift_left(to_unsigned(1, 2*n), 2*n-2));
			Zf <= std_logic_vector(to_unsigned(0,2*n));
			i_f <= n-1;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));
			fut_state<=S1;

		when S1 =>
		  if unsigned(A) <= 1 then
		    Zf <= A;
			  Result <= std_logic_vector(to_unsigned(0,n));
		    fut_state<=S4;
		  else
		      if (i_p>=0) then
				    fut_state<=S12;
			    else
				    fut_state<=S4;
			    end if;
			    Result <= std_logic_vector(to_unsigned(0,n));
			end if;
			done <= '0';

		when S12 =>
			Zf <= std_logic_vector( unsigned(Zp) + unsigned(Vp));
			done <='0';
			Result <= std_logic_vector(to_unsigned(0,n));
			fut_state<=S2;


		when S2 =>
			if unsigned(Ap)>=unsigned(Zp) then
				Af <= std_logic_vector( unsigned(Ap) - unsigned(Zp));
				Zf <= std_logic_vector( unsigned(Zp) + unsigned(Vp));
			else
				Zf <= std_logic_vector( unsigned(Zp) - unsigned(Vp));
			end if;
			Vf <= std_logic_vector((unsigned(Vp)/4));
			i_f <= i_p-1;
			fut_state<=S3;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));

		when S3 =>
			Zf <= std_logic_vector(unsigned(Zp)/2);
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));
			fut_state<=S1;

		 when S4 =>
			done <= '1';
			Result <= Zp(n-1 DOWNTO 0);
			if start='1' then
				fut_state<=S0;
			else
				fut_state<=S4;
			end if;

		when others =>
			fut_state <= S0;
			done <= '0';
			Result <= std_logic_vector(to_unsigned(0,n));

	end case;
	end process;

end architecture;




------------------------------------------------------------
---------------------- Architecture 4 ----------------------
------------------------------------------------------------

architecture Sqrt4 of sqrt_core is

begin

SqrtCombi:process(A)
variable Ap: std_logic_vector((2*n)-1 downto 0);
variable V: std_logic_vector((2*n)-1 downto 0);
variable Z: std_logic_vector((2*n)-1 downto 0);
begin
  if(unsigned(A) <= 1) then
    Result <= A(n-1 DOWNTO 0);
    done <= '1';
  else
    Ap := A;
    V := std_logic_vector(shift_left(to_unsigned(1, 2*n), 2*n-2));
    Z := std_logic_vector(to_unsigned(0,2*n));
	 for i in 0 to n-1 loop
		Z := std_logic_vector(unsigned(Z)+unsigned(V));
		if(unsigned(Ap)>=unsigned(Z)) then
		  Ap := std_logic_vector(unsigned(Ap) - unsigned(Z));
		  Z := std_logic_vector(unsigned(Z) + unsigned(V));
		else
		  Z := std_logic_vector(unsigned(Z) - unsigned(V));
		end if;
		Z := std_logic_vector(unsigned(Z)/2);
		V := std_logic_vector(unsigned(V)/4);
	 end loop;
	 Result <= Z(n-1 DOWNTO 0);
	 done <= '1';
  end if;
end process;

end architecture;

------------------------------------------------------------
---------------------- Architecture 5 ----------------------
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture Sqrt5 of sqrt_core is
  -- 1) Declarations : registres de pipeline (0..n) et ?valid?
  type u2n_vec  is array (natural range <>) of unsigned(2*n-1 downto 0);
  type vld_vec  is array (natural range <>) of std_logic;

  signal A_pipe  : u2n_vec(0 to n);
  signal V_pipe  : u2n_vec(0 to n);
  signal Z_pipe  : u2n_vec(0 to n);          -- Z sur 2n bits (comme Archi 4 corrigee)
  signal VLD     : vld_vec(0 to n);

  signal result_r : std_logic_vector(n-1 downto 0) := (others=>'0');
  signal done_r   : std_logic := '0';
begin
  Result <= result_r;
  done   <= done_r;

  process(clk)

    -- Variables d'etage
    variable Ap, Vp, Zp           : unsigned(2*n-1 downto 0);
    variable Z1, Z2, Z3, Ap_n, Vp_n : unsigned(2*n-1 downto 0);
  begin
    if rising_edge(clk) then
      -- 3) Reset pipeline
      if init = '1' then
        for i in 0 to n loop
          A_pipe(i) <= (others => '0');
          V_pipe(i) <= (others => '0');
          Z_pipe(i) <= (others => '0');
          VLD(i)    <= '0';
        end loop;
        result_r <= (others => '0');
        done_r   <= '0';

      else
        -- 4) Entree : capture de A quand start=1
        if start = '1' then
          A_pipe(0) <= unsigned(A);
          V_pipe(0) <= (others => '0');          -- V0 = 1 << (2n-2) sans sll/srl
          V_pipe(0)(2*n-2) <= '1';
          Z_pipe(0) <= (others => '0');          -- Z0 = 0
          VLD(0)    <= '1';                      -- echantillon valide
        else
          VLD(0)    <= '0';
        end if;

        -- 5) Corps du pipeline : S1 ? S2 ? S3 a chaque etage k
        for k in 0 to n-1 loop
          if VLD(k) = '1' then
            Ap := A_pipe(k);
            Vp := V_pipe(k);
            Zp := Z_pipe(k);

            -- S1) tentative : Z1 = Z + V
            Z1 := Zp + Vp;

            -- S2) test & MAJ :
            --    si Ap ? Z1 : Ap := Ap ? Z1 ; Z2 := Z1 + V
            --    sinon       : Ap := Ap      ; Z2 := Z1 ? V
            if Ap >= Z1 then
              Ap_n := Ap - Z1;
              Z2   := Z1 + Vp;
            else
              Ap_n := Ap;
              Z2   := Z1 - Vp;
            end if;

            -- S3) realignements (sans sll/srl) : Z /= 2 ; V /= 4
            Z3   := Z2 / 2;
            Vp_n := Vp / 4;

            -- Passage a etage suivant
            A_pipe(k+1) <= Ap_n;
            V_pipe(k+1) <= Vp_n;
            Z_pipe(k+1) <= Z3;
            VLD(k+1)    <= '1';
          else
            -- Pas de donnee valide : on ?vide? l?etage suivant
            A_pipe(k+1) <= (others => '0');
            V_pipe(k+1) <= (others => '0');
            Z_pipe(k+1) <= (others => '0');
            VLD(k+1)    <= '0';
          end if;
        end loop;

        -- 6) Sortie : n LSB de Z et ?done? aligne
        --result_r <= std_logic_vector(Z_pipe(n)(n-1 downto 0));
        if VLD(n) = '1' then
          result_r <= std_logic_vector(Z_pipe(n)(n-1 downto 0));
          done_r <= '1';
        else
          done_r <= '0';
        end if;
        --done_r   <= VLD(n);
      end if;
    end if;
  end process;
end architecture;
