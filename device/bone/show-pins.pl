#!/usr/bin/perl

# Matthijs van Duin - Dutch & Dutch

use v5.14;
use strict;
use warnings qw( FATAL all );
use utf8;

binmode STDOUT, ':utf8'  or die;



package style;

use base 'Tie::Hash';

sub TIEHASH {
	my( $class, @attrs ) = @_;
	my $style = "\e[" . join( ';', @attrs ) . 'm';
	bless \$style, $class
}

sub FETCH {
	my( $this, $key ) = @_;
       	"$$this$key\e[m"
}

package main;

tie my %R, style => 31;
tie my %G, style => 32;
tie my %Y, style => 33;
tie my %D, style => 2;
tie my %BR, style => 31, 1;
tie my %DR, style => 31, 2;
tie my %DG, style => 32, 2;



# parse options

my $verbose = 0;

while( @ARGV && $ARGV[0] =~ s/^-v/-/ ) {
	++$verbose;
	shift if $ARGV[0] eq '-';
}
die "unexpected argument: $ARGV[0]\n"  if @ARGV;


@ARGV = '/sys/kernel/debug/pinctrl/44e10800.pinmux/pinmux-pins';
my @usage;
while( <> ) {
	local $SIG{__DIE__} = sub { die "@_$_\n" };
	/^pin/gc  or next;
	/\G +(0|[1-9]\d*) +\((\w+)\.0\):/gc  or die;
	my $pin = 0 + $1;
	my $addr = hex $2;
	( $addr & 0x7ff ) == 4 * $pin  or die;
	next if /\G \(MUX UNCLAIMED\)/gc;
	/\G (\S+)/gc  or die;
	my @path = split m!:!, $1;
	s/^(.*)\.([^.]+)\z/$2\@$1/ for @path;
	$addr = join '/', @path;
	/\G \(GPIO UNCLAIMED\)/gc  or die;
	/\G function (\S+) group (\S+)\s*\z/gc && $1 eq $2  or die;
	$usage[ $pin ] = [ $addr, $1 ];
}


my @data = map { chomp; [ split /\t+/ ] } grep /^[^#]/, <DATA>;



@ARGV = '/sys/kernel/debug/pinctrl/44e10800.pinmux/pins';

while( <> ) {
	s/\s*\z//;
	/^pin / or next;

	/^pin (\d+) \(44e1([0-9a-f]{4})\.0\) 000000([0-7][0-9a-f]) pinctrl-single\z/ or die "parse error";
	my $pin = $1;
	my $reg = hex $2;
	my $mux = hex $3;
	0x800 + 4 * $pin == $reg  or die "sanity check failed";

	my $zcz_ball = $data[ $pin ][ 9 ] || "";

	my $label = $data[ $pin ][ 8 ] // next;
	my $boring = $label =~ s/^-// ? 2 : $label !~ /^P[89]\./;
        next if $boring > $verbose;

	my $slew = ( "$D{fast}", "$R{slow}" )[ $mux >> 6 & 1 ];
	my $rx = ( "  ", "$G{rx}" )[ $mux >> 5 & 1 ];
	my $pull = ( "$DG{down}", " $DR{up} " )[ $mux >> 4 & 1 ];
	$pull = "    " if $mux >> 3 & 1;
	$mux &= 7;

	my $function = $data[ $pin ][ $mux ];
	$function = "$BR{INVALID}"  if $function eq '-';

	if( $usage[ $pin ] ) {
		my( $dev, $group ) = @{ $usage[ $pin ] };
		$function = sprintf "%-16s", $function;
		$function = join ' ', $function, $Y{$dev}, $D{"($group)"};
	} elsif( $function =~ /^gpio / || $boring > 1 ) {
		$function = $D{$function};
	}

	$function = qq/$slew $rx $pull $Y{$mux} $function/;

	printf "%-32s $Y{'%3s'} $G{'%3s'} %s\n", $label, $pin, $zcz_ball, $function;
}

__DATA__
gpmc d0			mmc 1 d0		-			-			-			-			-			gpio 1.00		P8.25 / eMMC d0	U7
gpmc d1			mmc 1 d1		-			-			-			-			-			gpio 1.01		P8.24 / eMMC d1	V7
gpmc d2			mmc 1 d2		-			-			-			-			-			gpio 1.02		P8.05 / eMMC d2	R8
gpmc d3			mmc 1 d3		-			-			-			-			-			gpio 1.03		P8.06 / eMMC d3	T8
gpmc d4			mmc 1 d4		-			-			-			-			-			gpio 1.04		P8.23 / eMMC d4	U8
gpmc d5			mmc 1 d5		-			-			-			-			-			gpio 1.05		P8.22 / eMMC d5	V8
gpmc d6			mmc 1 d6		-			-			-			-			-			gpio 1.06		P8.03 / eMMC d6	R9
gpmc d7			mmc 1 d7		-			-			-			-			-			gpio 1.07		P8.04 / eMMC d7	T9
gpmc d8			lcd d23			mmc 1 d0		mmc 2 d4		pwm 2 out A		pru mii 0 txclk		-			gpio 0.22		P8.19	U10
gpmc d9			lcd d22			mmc 1 d1		mmc 2 d5		pwm 2 out B		pru mii 0 col		-			gpio 0.23		P8.13	T10
gpmc d10		lcd d21			mmc 1 d2		mmc 2 d6		pwm 2 tripzone		pru mii 0 txen		-			gpio 0.26		P8.14	T11
gpmc d11		lcd d20			mmc 1 d3		mmc 2 d7		pwm sync out		pru mii 0 txd3		-			gpio 0.27		P8.17	U12
gpmc d12		lcd d19			mmc 1 d4		mmc 2 d0		qep 2 in A		pru mii 0 txd2		pru 0 out 14		gpio 1.12		P8.12	T12
gpmc d13		lcd d18			mmc 1 d5		mmc 2 d1		qep 2 in B		pru mii 0 txd1		pru 0 out 15		gpio 1.13		P8.11	R12
gpmc d14		lcd d17			mmc 1 d6		mmc 2 d2		qep 2 index		pru mii 0 txd0		pru 0 in 14		gpio 1.14		P8.16	V13
gpmc d15		lcd d16			mmc 1 d7		mmc 2 d3		qep 2 strobe		pru eCAP		pru 0 in 15		gpio 1.15		P8.15	U13
gpmc a0			mii 1 txen		rgmii 1 txctl		rmii 1 txen		gpmc a16		pru mii 1 txclk		pwm 1 tripzone		gpio 1.16		P9.15	R13
gpmc a1			mii 1 rxdv		rgmii 1 rxctl		mmc 2 d0		gpmc a17		pru mii 1 txd3		pwm sync out		gpio 1.17		P9.23	V14
gpmc a2			mii 1 txd3		rgmii 1 txd3		mmc 2 d1		gpmc a18		pru mii 1 txd2		pwm 1 out A		gpio 1.18		P9.14	U14
gpmc a3			mii 1 txd2		rgmii 1 txd2		mmc 2 d2		gpmc a19		pru mii 1 txd1		pwm 1 out B		gpio 1.19		P9.16	T14
gpmc a4			mii 1 txd1		rgmii 1 txd1		rmii 1 txd1		gpmc a20		pru mii 1 txd0		qep 1 in A		gpio 1.20		eMMC reset	R14
gpmc a5			mii 1 txd0		rgmii 1 txd0		rmii 1 txd0		gpmc a21		pru mii 1 rxd3		qep 1 in B		gpio 1.21		user led 0	V15
gpmc a6			mii 1 txclk		rgmii 1 txclk		mmc 2 d4		gpmc a22		pru mii 1 rxd2		qep 1 index		gpio 1.22		user led 1	U15
gpmc a7			mii 1 rxclk		rgmii 1 rxclk		mmc 2 d5		gpmc a23		pru mii 1 rxd1		qep 1 strobe		gpio 1.23		user led 2	T15
gpmc a8			mii 1 rxd3		rgmii 1 rxd3		mmc 2 d6		gpmc a24		pru mii 1 rxd0		asp 0 tx clk		gpio 1.24		user led 3	V16
gpmc a9			mii 1 rxd2		rgmii 1 rxd2		mmc 2 d7		gpmc a25		pru mii 1 rxclk		asp 0 tx fs		gpio 1.25		hdmi irq	U16
gpmc a10		mii 1 rxd1		rgmii 1 rxd1		rmii 1 rxd1		gpmc a26		pru mii 1 rxdv		asp 0 data 0		gpio 1.26		usb A vbus overcurrent	T16
gpmc a11		mii 1 rxd0		rgmii 1 rxd0		rmii 1 rxd0		gpmc a27		pru mii 1 rxer		asp 0 data 1		gpio 1.27		audio osc enable	V17
gpmc wait 0		mii 1 crs		gpmc cs 4		rmii 1 crs/rxdv		mmc 1 cd		pru mii 1 col		uart 4 rxd		gpio 0.30		P9.11	T17
gpmc wp			mii 1 rxer		gpmc cs 5		rmii 1 rxer		mmc 2 cd		pru mii 1 txen		uart 4 txd		gpio 0.31		P9.13	U17
gpmc be1		mii 1 col		gpmc cs 6		mmc 2 d3		gpmc dir		pru mii 1 rxlink	asp 0 rx clk		gpio 1.28		P9.12	U18
gpmc cs 0		-			-			-			-			-			-			gpio 1.29		P8.26	V6
gpmc cs 1		gpmc clk		mmc 1 clk		pru edio in 6		pru edio out 6		pru 1 out 12		pru 1 in 12		gpio 1.30		P8.21 / eMMC clk	U9
gpmc cs 2		gpmc be1		mmc 1 cmd		pru edio in 7		pru edio out 7		pru 1 out 13		pru 1 in 13		gpio 1.31		P8.20 / eMMC cmd	V9
gpmc cs 3		gpmc a3			rmii 1 crs/rxdv		mmc 2 cmd		pru mii 0 crs		pru mdio data		jtag emu 4		gpio 2.00		P9.15	T13
gpmc clk		lcd mclk		gpmc wait 1		mmc 2 clk		pru mii 1 crs		pru mdio clock		asp 0 rx fs		gpio 2.01		P8.18	V12
gpmc adv/ale		-			timer 4			-			-			-			-			gpio 2.02		P8.07	R7
gpmc oe/re		-			timer 7			-			-			-			-			gpio 2.03		P8.08	T7
gpmc we			-			timer 6			-			-			-			-			gpio 2.04		P8.10	U6
gpmc be0/cle		-			timer 5			-			-			-			-			gpio 2.05		P8.09	T6
lcd d0			gpmc a0			pru mii 0 txclk		pwm 2 out A		-			pru 1 out 0		pru 1 in 0		gpio 2.06		P8.45 / hdmi / sysboot 0	R1
lcd d1			gpmc a1			pru mii 0 txen		pwm 2 out B		-			pru 1 out 1		pru 1 in 1		gpio 2.07		P8.46 / hdmi / sysboot 1	R2
lcd d2			gpmc a2			pru mii 0 txd3		pwm 2 tripzone		-			pru 1 out 2		pru 1 in 2		gpio 2.08		P8.43 / hdmi / sysboot 2	R3
lcd d3			gpmc a3			pru mii 0 txd2		pwm sync out		-			pru 1 out 3		pru 1 in 3		gpio 2.09		P8.44 / hdmi / sysboot 3	R4
lcd d4			gpmc a4			pru mii 0 txd1		qep 2 in A		-			pru 1 out 4		pru 1 in 4		gpio 2.10		P8.41 / hdmi / sysboot 4	T1
lcd d5			gpmc a5			pru mii 0 txd0		qep 2 in B		-			pru 1 out 5		pru 1 in 5		gpio 2.11		P8.42 / hdmi / sysboot 5	T2
lcd d6			gpmc a6			pru edio in 6		qep 2 index		pru edio out 6		pru 1 out 6		pru 1 in 6		gpio 2.12		P8.39 / hdmi / sysboot 6	T3
lcd d7			gpmc a7			pru edio in 7		qep 2 strobe		pru edio out 7		pru 1 out 7		pru 1 in 7		gpio 2.13		P8.40 / hdmi / sysboot 7	T4
lcd d8			gpmc a12		pwm 1 tripzone		asp 0 tx clk		uart 5 txd		pru mii 0 rxd3		uart 2 cts		gpio 2.14		P8.37 / hdmi / sysboot 8	U1
lcd d9			gpmc a13		pwm sync out		asp 0 tx fs		uart 5 rxd		pru mii 0 rxd2		uart 2 rts		gpio 2.15		P8.38 / hdmi / sysboot 9	U2
lcd d10			gpmc a14		pwm 1 out A		asp 0 data 0		-			pru mii 0 rxd1		uart 3 cts		gpio 2.16		P8.36 / hdmi / sysboot 10	U3
lcd d11			gpmc a15		pwm 1 out B		asp 0 rx hclk		asp 0 data 2		pru mii 0 rxd0		uart 3 rts		gpio 2.17		P8.34 / hdmi / sysboot 11	U4
lcd d12			gpmc a16		qep 1 in A		asp 0 rx clk		asp 0 data 2		pru mii 0 rxlink	uart 4 cts		gpio 0.08		P8.35 / hdmi / sysboot 12	V2
lcd d13			gpmc a17		qep 1 in B		asp 0 rx fs		asp 0 data 3		pru mii 0 rxer		uart 4 rts		gpio 0.09		P8.33 / hdmi / sysboot 13	V3
lcd d14			gpmc a18		qep 1 index		asp 0 data 1		uart 5 rxd		pru mii 0 rxclk		uart 5 cts		gpio 0.10		P8.31 / hdmi / sysboot 14	V4
lcd d15			gpmc a19		qep 1 strobe		asp 0 tx hclk		asp 0 data 3		pru mii 0 rxdv		uart 5 rts		gpio 0.11		P8.32 / hdmi / sysboot 15	T5
lcd vsync		gpmc a8			gpmc a1			pru edio in 2		pru edio out 2		pru 1 out 8		pru 1 in 8		gpio 2.22		P8.27 / hdmi	U5
lcd hsync		gpmc a9			gpmc a2			pru edio in 3		pru edio out 3		pru 1 out 9		pru 1 in 9		gpio 2.23		P8.29 / hdmi	R5
lcd pclk		gpmc a10		pru mii 0 crs		pru edio in 4		pru edio out 4		pru 1 out 10		pru 1 in 10		gpio 2.24		P8.28 / hdmi	V5
lcd oe/acb		gpmc a11		pru mii 1 crs		pru edio in 5		pru edio out 5		pru 1 out 11		pru 1 in 11		gpio 2.25		P8.30 / hdmi	R6
mmc 0 d3		gpmc a20		uart 4 cts		timer 5			uart 1 dcd		pru 0 out 8		pru 0 in 8		gpio 2.26		μSD d3	F17
mmc 0 d2		gpmc a21		uart 4 rts		timer 6			uart 1 dsr		pru 0 out 9		pru 0 in 9		gpio 2.27		μSD d2	F18
mmc 0 d1		gpmc a22		uart 5 cts		uart 3 rxd		uart 1 dtr		pru 0 out 10		pru 0 in 10		gpio 2.28		μSD d1	G15
mmc 0 d0		gpmc a23		uart 5 rts		uart 3 txd		uart 1 ri		pru 0 out 11		pru 0 in 11		gpio 2.29		μSD d0	G16
mmc 0 clk		gpmc a24		uart 3 cts		uart 2 rxd		can 1 tx		pru 0 out 12		pru 0 in 12		gpio 2.30		μSD clk	G17
mmc 0 cmd		gpmc a25		uart 3 rts		uart 2 txd		can 1 rx		pru 0 out 13		pru 0 in 13		gpio 2.31		μSD cmd	G18
mii 0 col		rmii 1 refclk		spi 1 clk		uart 5 rxd		asp 1 data 2		mmc 2 d3		asp 0 data 2		gpio 3.00		eth mii col	H16
mii 0 crs		rmii 0 crs/rxdv		spi 1 data 0		i²c 1 sda		asp 1 tx clk		uart 5 cts		uart 2 rxd		gpio 3.01		eth mii crs	H17
mii 0 rxer		rmii 0 rxer		spi 1 data 1		i²c 1 scl		asp 1 tx fs		uart 5 rts		uart 2 txd		gpio 3.02		eth mii rx err	J15
mii 0 txen		rmii 0 txen		rgmii 0 txctl		timer 4			asp 1 data 0		qep 0 index		mmc 2 cmd		gpio 3.03		eth mii tx en	J16
mii 0 rxdv		lcd mclk		rgmii 0 rxctl		uart 5 txd		asp 1 tx clk		mmc 2 d0		asp 0 rx clk		gpio 3.04		eth mii rx dv	J17
mii 0 txd3		can 0 tx		rgmii 0 txd3		uart 4 rxd		asp 1 tx fs		mmc 2 d1		asp 0 rx fs		gpio 0.16		eth mii tx d3	J18
mii 0 txd2		can 0 rx		rgmii 0 txd2		uart 4 txd		asp 1 data 0		mmc 2 d2		asp 0 tx hclk		gpio 0.17		eth mii tx d2	K15
mii 0 txd1		rmii 0 txd1		rgmii 0 txd1		asp 1 rx fs		asp 1 data 1		qep 0 in A		mmc 1 cmd		gpio 0.21		eth mii tx d1	K16
mii 0 txd0		rmii 0 txd0		rgmii 0 txd0		asp 1 data 2		asp 1 rx clk		qep 0 in B		mmc 1 clk		gpio 0.28		eth mii tx d0	K17
mii 0 txclk		uart 2 rxd		rgmii 0 txclk		mmc 0 d7		mmc 1 d0		uart 1 dcd		asp 0 tx clk		gpio 3.09		eth mii tx clk	K18
mii 0 rxclk		uart 2 txd		rgmii 0 rxclk		mmc 0 d6		mmc 1 d1		uart 1 dsr		asp 0 tx fs		gpio 3.10		eth mii rx clk	L18
mii 0 rxd3		uart 3 rxd		rgmii 0 rxd3		mmc 0 d5		mmc 1 d2		uart 1 dtr		asp 0 data 0		gpio 2.18		eth mii rx d3	L17
mii 0 rxd2		uart 3 txd		rgmii 0 rxd2		mmc 0 d4		mmc 1 d3		uart 1 ri		asp 0 data 1		gpio 2.19		eth mii rx d2	L16
mii 0 rxd1		rmii 0 rxd1		rgmii 0 rxd1		asp 1 data 3		asp 1 rx fs		qep 0 strobe		mmc 2 clk		gpio 2.20		eth mii rx d1	L15
mii 0 rxd0		rmii 0 rxd0		rgmii 0 rxd0		asp 1 tx hclk		asp 1 rx hclk		asp 1 rx clk		asp 0 data 3		gpio 2.21		eth mii rx d0	M16
rmii 0 refclk		dma event 2		spi 1 cs 0		uart 5 txd		asp 1 data 3		mmc 0 pow		asp 1 tx hclk		gpio 0.29		-eth unused	H18
mdio data		timer 6			uart 5 rxd		uart 3 cts		mmc 0 cd		mmc 1 cmd		mmc 2 cmd		gpio 0.00		eth mdio	M17
mdio clk		timer 5			uart 5 txd		uart 3 rts		mmc 0 wp		mmc 1 clk		mmc 2 clk		gpio 0.01		eth mdc	M18
spi 0 clk		uart 2 rxd		i²c 2 sda		pwm 0 out A		uart pru cts		pru edio sof		jtag emu 2		gpio 0.02		P9.22 / spi boot clk	A17
spi 0 data 0		uart 2 txd		i²c 2 scl		pwm 0 out B		uart pru rts		pru edio latch		jtag emu 3		gpio 0.03		P9.21 / spi boot in	B17
spi 0 data 1		mmc 1 wp		i²c 1 sda		pwm 0 tripzone		uart pru rxd		pru edio in 0		pru edio out 0		gpio 0.04		P9.18 / spi boot out	B16
spi 0 cs 0		mmc 2 wp		i²c 1 scl		pwm sync in		uart pru txd		pru edio in 1		pru edio out 1		gpio 0.05		P9.17 / spi boot cs	A16
spi 0 cs 1		uart 3 rxd		eCAP 1			mmc 0 pow		dma event 2		mmc 0 cd		jtag emu 4		gpio 0.06		μSD cd / jtag emu4	C15
eCAP 0			uart 3 txd		spi 1 cs 1		pru eCAP		spi 1 clk		mmc 0 wp		dma event 2		gpio 0.07		P9.42a	C18
uart 0 cts		uart 4 rxd		can 1 tx		i²c 1 sda		spi 1 data 0		timer 7			pru edc sync 0 out	gpio 1.08		-×	E18
uart 0 rts		uart 4 txd		can 1 rx		i²c 1 scl		spi 1 data 1		spi 1 cs 0		pru edc sync 1 out	gpio 1.09		-TP9	E17
uart 0 rxd		spi 1 cs 0		can 0 tx		i²c 2 sda		eCAP 2			pru 1 out 14		pru 1 in 14		gpio 1.10		console in	E15
uart 0 txd		spi 1 cs 1		can 0 rx		i²c 2 scl		eCAP 1			pru 1 out 15		pru 1 in 15		gpio 1.11		console out	E16
uart 1 cts		timer 6			can 0 tx		i²c 2 sda		spi 1 cs 0		uart pru cts		pru edc latch 0		gpio 0.12		P9.20 / cape i²c sda	D18
uart 1 rts		timer 5			can 0 rx		i²c 2 scl		spi 1 cs 1		uart pru rts		pru edc latch 1		gpio 0.13		P9.19 / cape i²c scl	D17
uart 1 rxd		mmc 1 wp		can 1 tx		i²c 1 sda		-			uart pru rxd		pru 1 in 16		gpio 0.14		P9.26	D16
uart 1 txd		mmc 2 wp		can 1 rx		i²c 1 scl		-			uart pru txd		pru 0 in 16		gpio 0.15		P9.24	D15
i²c 0 sda		timer 4			uart 2 cts		eCAP 2			-			-			-			gpio 3.05		local i²c sda	C17
i²c 0 scl		timer 7			uart 2 rts		eCAP 1			-			-			-			gpio 3.06		local i²c scl	C16
asp 0 tx clk		pwm 0 out A		-			spi 1 clk		mmc 0 cd		pru 0 out 0		pru 0 in 0		gpio 3.14		P9.31 / hdmi audio clk	A13
asp 0 tx fs		pwm 0 out B		-			spi 1 data 0		mmc 1 cd		pru 0 out 1		pru 0 in 1		gpio 3.15		P9.29 / hdmi audio fs	B13
asp 0 data 0		pwm 0 tripzone		-			spi 1 data 1		mmc 2 cd		pru 0 out 2		pru 0 in 2		gpio 3.16		P9.30	D12
asp 0 rx hclk		pwm sync in		asp 0 data 2		spi 1 cs 0		eCAP 2			pru 0 out 3		pru 0 in 3		gpio 3.17		P9.28 / hdmi audio data	C12
asp 0 rx clk		qep 0 in A		asp 0 data 2		asp 1 tx clk		mmc 0 wp		pru 0 out 4		pru 0 in 4		gpio 3.18		P9.42b	B12
asp 0 rx fs		qep 0 in B		asp 0 data 3		asp 1 tx fs		jtag emu 2		pru 0 out 5		pru 0 in 5		gpio 3.19		P9.27	C13
asp 0 data 1		qep 0 index		-			asp 1 data 0		jtag emu 3		pru 0 out 6		pru 0 in 6		gpio 3.20		P9.41	D13
asp 0 tx hclk		qep 0 strobe		asp 0 data 3		asp 1 data 1		jtag emu 4		pru 0 out 7		pru 0 in 7		gpio 3.21		P9.25 / audio osc	A14
dma event 0		-			timer 4			clkout 0		spi 1 cs 1		pru 1 in 16		jtag emu 2		gpio 0.19		hdmi cec / jtag emu2	A15
dma event 1		-			timer clkin		clkout 1		timer 7			pru 0 in 16		jtag emu 3		gpio 0.20		P9.41 / jtag emu3	D14
reset in/out		-			-			-			-			-			-			-			-reset	A10
por			-			-			-			-			-			-			-			-pmic	B15
mpu irq			-			-			-			-			-			-			-			pmic irq	B18
osc 0 in		-			-			-			-			-			-			-			-xtal
osc 0 out		-			-			-			-			-			-			-			-xtal
osc 0 gnd		-			-			-			-			-			-			-			-xtal
jtag tms		-			-			-			-			-			-			-			-jtag	C11
jtag tdi		-			-			-			-			-			-			-			-jtag	B11
jtag tdo		-			-			-			-			-			-			-			-jtag	A11
jtag tck		-			-			-			-			-			-			-			-jtag	A12
jtag trst		-			-			-			-			-			-			-			-jtag	B10
emu 0			-			-			-			-			-			-			gpio 3.07		jtag emu0	C14
emu 1			-			-			-			-			-			-			gpio 3.08		jtag emu1	B14
osc 1 (rtc) in		-			-			-			-			-			-			-			-rtc xtal
osc 1 (rtc) out		-			-			-			-			-			-			-			-rtc xtal
rtc gnd			-			-			-			-			-			-			-			-rtc xtal
rtc por			-			-			-			-			-			-			-			-pmic	B5
power en		-			-			-			-			-			-			-			-pmic
wakeup			-			-			-			-			-			-			-			-pmic
rtc ldo en		-			-			-			-			-			-			-			-pmic
usb 0 d−		-			-			-			-			-			-			-			-usb B
usb 0 d+		-			-			-			-			-			-			-			-usb B
usb 0 charge en		-			-			-			-			-			-			-			-x
usb 0 id		-			-			-			-			-			-			-			-usb B id
usb 0 vbus in		-			-			-			-			-			-			-			-usb B vbus
usb 0 vbus out en	-			-			-			-			-			-			gpio 0.18		-×	F16
usb 1 d−		-			-			-			-			-			-			-			-usb A
usb 1 d+		-			-			-			-			-			-			-			-usb A
usb 1 charge en		-			-			-			-			-			-			-			-×
usb 1 id		-			-			-			-			-			-			-			-gnd
usb 1 vbus in		-			-			-			-			-			-			-			-usb A vbus
usb 1 vbus out en	-			-			-			-			-			-			gpio 3.13		usb A vbus en	F15
# vim: ts=8:sts=0:noet:nowrap
