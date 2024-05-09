#!/usr/bin/env perl

####    Pure Perl implementation of a terminal calendar app       ###
#                                                                   #
#  * by default produce a monthly calendar for current month        #
#  * if passed a number less than 12 produces a calendar for        #
#    that month in current year                                     #
#  * if passed two numbers and first is less than 12 then prints    #
#    corresponding month in that year                               #
#  * if passed number greater than 12 prints the calendar for       #
#    the year in a grid form                                        #
#                                                                   #
#####################################################################  

use DateTime;
use Data::Dumper;
use strict;use warnings;
my $local_time_zone = DateTime::TimeZone->new( name => 'local' );


our %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, blink=>5, strikethrough=>9, invert=>7,);


# usage
if ($ARGV[0]  && $ARGV[0] eq "-h"){
   print <<END;
Usage:
$0 help|h|-h      <-- this message
$0 <no parameter> <-- current month current year
$0 year1          <-- all months for year 
$0 year1 year2    <-- all months for year span
$0 month          <-- if less than 12, month this year
$0 month year     <-- month of year
END
exit;
}

my ($yearStart,$yearEnd, @misc)=@ARGV;
$yearStart=2024;
our $today=  DateTime->now;
my $dt = DateTime->now;
if ($yearStart && $yearStart<=12){
	if ($yearEnd){
	    $dt= DateTime->new(year=>$yearEnd,month=>$yearStart);
	}
	else {
		 $dt= DateTime->new(year=>$dt->year,month=>$yearStart);
	}
	
	print drawGrid(monthGrid($dt));
}
elsif ($yearStart){
	$yearEnd//=$yearStart;
	while ($yearStart<=$yearEnd){
	   print drawGrid(yearGrid($yearStart,{showWeek=>1,showYear=>0}));
	   $yearStart++;
	}
}
else{
	print drawGrid(monthGrid($dt));
}

sub drawGrid{
	my $grid=shift;
	#system($^O eq 'MSWin32'?'cls':'clear');
	foreach my $line(@$grid){
		foreach (@$line){print $_ if defined $_}
		print "\n";
		};
}

sub monthGrid{
   my ($date,$options)=@_;
   $options->{showYear}//=1;
   $options->{showWeek}//=1;
   my $cal=[center($date->month_name. ($options->{showYear}?"  ".$date->year:""),21+3*$options->{showWeek})]; # Title
   push @$cal,[($options->{showWeek}?" w|":"")," Mo"," Tu"," We"," Th"," Fr"," Sa"," Su"];          # Header row
   my $firstDay=DateTime->new(year=>$date->year,month=>$date->month);       # date of first day of month
   my $weekNo=int(($firstDay->doy+6)/7);        # week number for first day of month
   my @mDays=((" ") x ($firstDay->day_of_week-1), (1..$date->month_length));# list of days
   @mDays=(@mDays,(" ")x(6-@mDays%7));             # pad out end if needed
   
   foreach my $row (0..@mDays/7){
	   my @r=();
	   push @r,(length $weekNo<2?" ":"").$weekNo++."|" if $options->{showWeek}; # pad out weekNo
	   foreach(0..6){
		   my $md=shift @mDays//"";                 # each date for the week
		   my $ptMd=($today->day eq $md && $today->month eq $date->month && $today->year eq $date->year)?paint($md,"invert"):$md;
		   push @r," " x (3-length $md).$ptMd;          # padded out
	   }
	   push @$cal,[@r] unless ((($r[0] eq "   ")&& ($r[6] eq "   "))||($options->{showWeek} && ($r[1] eq "   ") && ($r[7] eq "   ")))
   }
    while (scalar @$cal < 8){$cal=[@$cal,[("   ")x($options->{showWeek}?8:7)]]}
   return $cal;
}

sub yearGrid{
	my ($year, $options)=@_;
	$options->{monthsPerRow}//=4;
	$options->{hPadding}//=2;
	$options->{vPadding}//=1;
	my $rows=int 12/$options->{monthsPerRow};
	my $grid=textGrid($options->{monthsPerRow}*(7 + ($options->{showWeek}?1:0)+ $options->{hPadding})-1,$rows*(8+$options->{vPadding})-$options->{vPadding});
	my $ypos=0; my $month=1;
	foreach(0..$rows-1){
		my $ypos=$_*(8+$options->{vPadding});
		foreach my $col(0..$options->{monthsPerRow}-1){
			my $mg=monthGrid(DateTime->new(year=>$year,month=>$month),$options);
			 insertBlock($grid,$mg,$col*(7 + ($options->{showWeek}?1:0)+$options->{hPadding}),$ypos);
			 $month++;
		}
	}
	
	return $grid;
}

sub center{
	my ($text,$width)=@_;
	if (length $text<$width){
		return [split(//,(" " x (($width-length $text)/2)).$text.(" " x (($width-length $text)/2)).((length $text)%2?" ":""))];
	}
	return   [split(//,substr ($text,0,$width))];
}

sub textGrid {
     my ($width,$height)=@_;
     my @grid;
     foreach (0..$height){
		 $grid[$_]=[(" ")x$width];
	 }
	return [@grid];
}

sub insertBlock{
	my ($grid,$block,$xPos,$yPos)=@_;
	my $blockWidth=length $block->[0];
	foreach my $y (0..$#$block){
		foreach my $x (0..$#{$block->[$y]}){
			if ($y==0){
				 $grid->[$yPos+$y]->[3*$xPos+$x]=$block->[$y]->[$x];
			}
			else{
				   $grid->[$yPos+$y]->[$xPos+$x]=$block->[$y]->[$x];
			}
		}
	}
	
}

sub paint{
	my ($txt,$fmt)=@_;
	return "" unless $txt;
	if ((ref $txt) && (ref $txt->[0])){
		foreach my $row (@$txt){
			$row->[0]=colour($fmt).$row->[0];
			$row->[-1]=$row->[-1].colour("reset");
		}
		return $txt;
	}
	return $txt unless $fmt;
	return colour($fmt).$txt.colour("reset") unless ref $txt;
	return [map {colour($fmt).$_.colour("reset");} @$txt]
}

sub clearScreen{
	system($^O eq 'MSWin32'?'cls':'clear');
}

sub colour{
  my ($fmts)=@_;
  return "" unless $fmts;
  my @formats=map {lc $_} split / +/,$fmts;  
  return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}
