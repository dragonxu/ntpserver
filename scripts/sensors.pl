#!/usr/bin/perl

use Getopt::Std;
use strict;

$0 =~ s:^.*/::g;

my $g_init = 0;

sub usage
{
   my($msg) = @_;

        print "ERROR: $msg\n" if $msg;

        die <<EOF;
Use:
   $0 [options]

Read sensors

Options:
   -h             This message.
   -i             Initialize sensors
EOF

}

sub peek
{
    my($addr) = @_;
    my $val;

    $val = `/root/bin/peek $addr`;

    return (hex($val));
}

sub poke
{
    my($addr, $val) = @_;
    my $ret;

    $ret = `/root/bin/poke $addr $val`;

    return ($ret);
}

sub i2cget
{
    my($bus, $addr, $reg) = @_;
    my $val;

    $val = `i2cget -y $bus $addr $reg`;

    return (hex($val));
}

sub i2cset
{
    my($bus, $addr, $reg, $val) = @_;
    my $ret;

    $val = `i2cset -y $bus $addr $reg $val`;

    return ($ret);
}


sub read_xadc
{
    my $base = 0x43c00000;
    my $temp_raw;
    my $temp;
    my $volt_raw;
    my $volt;

    $temp_raw = peek($base + 0x200) >> 4;
    $temp     = $temp_raw * 503.975 / 4096.0 - 273.15;
    printf("Temp      0x%04x  %f\n", $temp_raw, $temp);

    $volt_raw = peek($base + 0x204) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("Vccint    0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x208) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("Vccaux    0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x20c) >> 4;
    $volt     = $volt_raw / 4096.0 * 1.0;
    printf("Vp/Vn     0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x210) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("Vrefp     0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x214) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("Vrefn     0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x218) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("Vbram     0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x234) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("VccintPSS 0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x238) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("VccauxPSS 0x%04x  %f\n", $volt_raw, $volt);

    $volt_raw = peek($base + 0x23c) >> 4;
    $volt     = $volt_raw / 4096.0 * 3.0;
    printf("VccmemPSS 0x%04x  %f\n", $volt_raw, $volt);
}


sub init_ltc2990
{

    i2cset(1, 0x4c, 1, 0x19);
    i2cset(1, 0x4c, 2, 0);

}


sub read_ltc2990
{
    my $temp_raw_msb;
    my $temp_raw_lsb;
    my $temp_raw;
    my $temp;
    my $volt_raw_msb;
    my $volt_raw_lsb;
    my $volt_raw;
    my $volt;

    $temp_raw_msb  = i2cget(1, 0x4c, 4);
    $temp_raw_lsb  = i2cget(1, 0x4c, 5);
    $temp_raw      = ($temp_raw_msb & 0x1f) << 8 | $temp_raw_lsb;
    $temp          = $temp_raw;
    $temp          = $temp - 0x2000 if ($temp >= 0x1000);
    $temp          = $temp * 0.0625;
    printf("Tint      0x%04x  %f\n", $temp_raw, $temp);
    
    $volt_raw_msb  = i2cget(1, 0x4c, 6);
    $volt_raw_lsb  = i2cget(1, 0x4c, 7);
    $volt_raw      = ($volt_raw_msb & 0x7f) << 8 | $volt_raw_lsb;
    $volt          = $volt_raw;
    $volt         -= 0x8000 if ($volt >= 0x4000);
    $volt          = $volt * 19.42e-6;
    printf("V1-V2     0x%04x  %f\n", $volt_raw, $volt);
    printf("Iv1-v2            %f\n", $volt / 0.1);
    
    $temp_raw_msb  = i2cget(1, 0x4c, 0xa);
    $temp_raw_lsb  = i2cget(1, 0x4c, 0xb);
    $temp_raw      = ($temp_raw_msb & 0x1f) << 8 | $temp_raw_lsb;
    $temp          = $temp_raw;
    $temp          = $temp - 0x2000 if ($temp >= 0x1000);
    $temp          = $temp * 0.0625;
    printf("Tr2       0x%04x  %f\n", $temp_raw, $temp);
    
    $volt_raw_msb  = i2cget(1, 0x4c, 0xe);
    $volt_raw_lsb  = i2cget(1, 0x4c, 0xf);
    $volt_raw      = ($volt_raw_msb & 0x7f) << 8 | $volt_raw_lsb;
    $volt          = $volt_raw;
    $volt         -= 0x8000 if ($volt_raw >= 0x4000);
    $volt          = 2.5 + $volt * 305.18e-6;
    printf("Vcc       0x%04x  %f\n", $volt_raw, $volt);

}


sub init_adt7410
{

    i2cset(2, 0x48, 3, 0x80);
    i2cset(2, 0x49, 3, 0x80);

}


sub read_adt7410
{
    my $temp_raw_msb;
    my $temp_raw_lsb;
    my $temp_raw;
    my $temp;


    $temp_raw_msb  = i2cget(2, 0x48, 0);
    $temp_raw_lsb  = i2cget(2, 0x48, 1);
    $temp_raw      = $temp_raw_msb << 8 | $temp_raw_lsb;
    $temp          = $temp_raw;
    $temp         -= 0x10000 if ($temp >= 0x8000);
    $temp          = $temp * 0.0078125;
    printf("Tcpu      0x%04x  %f\n", $temp_raw, $temp);
    
    $temp_raw_msb  = i2cget(2, 0x49, 0);
    $temp_raw_lsb  = i2cget(2, 0x49, 1);
    $temp_raw      = $temp_raw_msb << 8 | $temp_raw_lsb;
    $temp          = $temp_raw;
    $temp         -= 0x10000 if ($temp >= 0x8000);
    $temp          = $temp * 0.0078125;
    printf("Tedge     0x%04x  %f\n", $temp_raw, $temp);
    
}


getopts('hi');
$g_init = 1 if ($Getopt::Std::opt_i);
usage("")   if $Getopt::Std::opt_h;


if ($g_init) {
    init_ltc2990;
    init_adt7410;
}

read_xadc;
read_ltc2990;
read_adt7410;


my $fan_raw;
my $fan_rpm;

$fan_raw = peek(0x80600100) >> 16;
$fan_rpm = 1.0e4 / $fan_raw / 2.0 * 60.0;
printf("Fan       0x%04x  %f\n", $fan_raw, $fan_rpm);
