library	ieee;
use		ieee.std_logic_1164.all;
use		ieee.std_logic_unsigned.all;
use		ieee.std_logic_arith.all;

entity vga640480 is
	 port(
			reset       :         in  STD_LOGIC;
			clk_0       :         in  STD_LOGIC; --100M时钟输入
			hs,vs       :         out STD_LOGIC; --行同步、场同步信号
			vector_x_out   :   out std_LOGIC_VECTOR(9 downto 0);
			vector_y_out :     out std_LOGIC_vector(8 downto 0);
			clk50 : out std_logic;
			data_safe:out std_logic;
			q : in std_logic_vector(9 downto 0);
			r,g,b : out std_logic_vector(2 downto 0)
	  );
end vga640480;

architecture behavior of vga640480 is
						
	signal hs1,vs1    : std_logic;
	signal r1, g1, b1 : std_LOGIC_vector(2 downto 0);	
	signal vector_x : std_logic_vector(9 downto 0);		--X坐标
	signal vector_y : std_logic_vector(8 downto 0);		--Y坐标
	signal clk	:	 std_logic;  --分频后得到的25M时钟
	signal clktmp : std_logic;  --50M时钟
	signal data_safe_tmp:std_logic;
begin

	clk50 <= clk;
 -----------------------------------------------------------------------
	process(clk_0)	--对100M输入信号4分频
   begin
        if(clk_0'event and clk_0='1') then 
             clktmp <= not clktmp;
        end if;
 	end process;
	
	process(clktmp)
	begin
		if(clktmp'event and clktmp = '1') then
			clk <= not clk;
		end if;
	end process;	

 -----------------------------------------------------------------------
	 process(clk,reset)	--行区间像素数（含消隐区）
	 begin
	  	if reset='0' then
	   		vector_x <= (others=>'0');
	  	elsif clk'event and clk='1' then
	   		if vector_x=799 then
	    		vector_x <= (others=>'0');
	   		else
	    		vector_x <= vector_x + 1;
	   		end if;
	  	end if;
	 end process;

  -----------------------------------------------------------------------
	 process(clk,reset)	--场区间行数（含消隐区）
	 begin
	  	if reset='0' then
	   		vector_y <= (others=>'0');
	  	elsif clk'event and clk='1' then
	   		if vector_x=799 then
	    		if vector_y=524 then
	     			vector_y <= (others=>'0');
	    		else
	     			vector_y <= vector_y + 1;
	    		end if;
	   		end if;
	  	end if;
	 end process;
 
  -----------------------------------------------------------------------
	 process(clk,reset) --行同步信号产生（同步宽度96，前沿16）
	 begin
		  if reset='0' then
		   hs1 <= '1';
		  elsif clk'event and clk='1' then
		   	if vector_x>=656 and vector_x<752 then
		    	hs1 <= '0';
		   	else
		    	hs1 <= '1';
		   	end if;
		  end if;
	 end process;
 
 -----------------------------------------------------------------------
	 process(clk,reset) --场同步信号产生（同步宽度2，前沿10）
	 begin
	  	if reset='0' then
	   		vs1 <= '1';
	  	elsif clk'event and clk='1' then
	   		if vector_y>=490 and vector_y<492 then
	    		vs1 <= '0';
	   		else
	    		vs1 <= '1';
	   		end if;
	  	end if;
	 end process;
 -----------------------------------------------------------------------
	 process(clk,reset) --行同步信号输出
	 begin
	  	if reset='0' then
	   		hs <= '0';
	  	elsif clk'event and clk='1' then
	   		hs <=  hs1;
	  	end if;
	 end process;

 -----------------------------------------------------------------------
	 process(clk,reset) --场同步信号输出
	 begin
	  	if reset='0' then
	   		vs <= '0';
	  	elsif clk'event and clk='1' then
	   		vs <=  vs1;
	  	end if;
	 end process;
 -----------------------------------------------------------------------
	process(vector_x, vector_y, clk_0)  -- 判定是否在消隐区并赋值data_safe
	begin
		if rising_edge(clk_0) then
			if vector_y >= 480 then
				data_safe <= '0';
			else
				data_safe <= '1';
			end if;
		end if;
 	end process;
 ----------------------------------------------------------------------- 
	process(hs1, vs1, r1, g1, b1)  --色彩输出
	begin
		if hs1 = '1' and vs1 = '1' then
			r <= r1;
			g <= g1;
			b <= b1;
		else
			r <= (others => '0');
			g <= (others => '0');
			b <= (others => '0');
		end if;
	end process;
------------------------------------------------------------------------
	process(reset, clk, vector_x , vector_y)
	begin
		if reset = '0'then 
			r1 <= "000";
			g1 <= "000";
			b1 <= "000";
		elsif(clk'event and clk = '1')then
			if vector_x < 640 and vector_y < 480 then
				vector_x_out <= vector_x;
				vector_y_out <= vector_y;
				b1 <= q(2 downto 0);
				g1 <= q(5 downto 3);
				r1 <= q(8 downto 6);
			else
				r1 <= "000";
				g1 <= "000";
				b1 <= "000";
			end if;
		end if;
	end process;
--------------------------------------------------------------------------------

end behavior;

