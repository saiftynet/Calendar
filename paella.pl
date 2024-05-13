#!/usr/bin/env perl

####       Pure Perl implementation of a terminal calendar app            ###
#                                                                           #
#  * by default produce a monthly calendar for current month                #
#  * if passed a number less than 12 produces a calendar for                #
#    that month in current year                                             #
#  * if passed two numbers and first is less than 12 then prints            #
#    corresponding month in that year                                       #
#  * if passed number greater than 12 prints the calendar for               #
#    the year in a grid form                                                #
#  * https://gist.github.com/viviparous/efa21bd6374824ba8332a3a4ac7b4585    #                                                                #
#                                                                           #
############################################################################# 

use strict; use warnings;
my $VERSION=0.03;

# set of functions work on Dates in the form of a YYYYMMDD string
# These could be easily replaced with more robust DateTime  or
# Time::Local modules.  But this way minimises dependencies
# limits needless conversions to a minimum.

my $today=today();
# accummulated days of year
my @acc=(0,31,59,90,120,151,181,212,243,273,304,334);
# Names of days of week
my @wdn=qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/;
# Names of months
my @mn=qw/January February March April May June July August September October November December/;
# Days in month
my @dm=(31,28,31,30,31,30,31,31,30,31,30,31);
#today's date in string form;
sub today{my (undef,undef,undef,$mday,$mon,$year) = localtime;return (1900+$year).sprintf("%02d",$mon+1).sprintf("%02d",$mday)};
# split 8 char date
sub spDt{ return ($_[0]=~/(\d{4})(\d{2})(\d{2})/)};
# test leap year                           
sub ly{my ($y,$m,$d)=spDt($_[0]);return (($y%4) - ($y%100) + ($y%400))?0:1;};
# day 1 of year Gregorian
sub d1greg{my ($y,$m,$d)=spDt($_[0]);return 1+(5*(($y-1)%4)+4*(($y-1)%100)+6*(($y-1)%400))%7;};
# day of year
sub doy{my ($y,$m,$d)=spDt($_[0]);return $d+$acc[$m-1]+((ly($y.$m.$d)&&($m>2))?1:0);}
# week of year
sub woy{return int((doy($_[0])+6)/7);}
# day of date
sub day{my ($doy,$d1y)=(doy($_[0]),d1greg($_[0]));return 1+($doy-$d1y)%7;};
# 1st day of month
sub d1m{my ($y,$m,$d)=spDt($_[0]);return day($y.$m."01")};
# days in month
sub dim{my ($y,$m,$d)=spDt($_[0]);return $dm[$m-1]; }
# named day
sub dn{return $wdn[day($_[0])-1]};
# convert to dd/mm/yyyy format
sub dmy{ join("/",reverse (spDt($_[0])))};
# convert to mm/dd/yyyy format
sub mdy{ join("/",(spDt($_[0]))[1,2,0])};
# check validity of a date string
sub valDate{
	return "Invalid date : $_[0]; should be 8 digits\n" unless ($_[0]=~/^\d{8}$/);
	my ($y,$m,$d) = spDt($_[0]);
	return "Invalid date : $_[0]; month $m out of range" unless ($m<13 && $m>0 );
	return "Invalid date : $_[0];  date too big for month" unless ((($m.$d eq "0229") && ly($y.$m.$d)) || ($dm[$m-1]>=$d) );
	return "Valid";
}


# terminal colouring and printing and clearing: 
# trimmed down version of module XXXX in MetaCPAN

my %colours=(black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, blink=>5, strikethrough=>9, invert=>7,);

my %borders=(
  none=>{tl=>" ", t=>" ", tr=>" ", l=>" ", r=>" ", bl=>" ", b=>" ", br=>" ",ts=>" ",te=>" ",},
  simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",ts=>"|",te=>"|",},
  double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",ts=>"╣",te=>"╠",},
  shadow=>{tl=>"┌", t=>"─", tr=>"╖", l=>"│", r=>"║", bl=>"╘", b=>"═", br=>"╝",ts=>"┨",te=>"┠",},
  thin  =>{tl=>"┌", t=>"─", tr=>"┐", l=>"│", r=>"│", bl=>"└", b=>"─", br=>"┘",ts=>"┤",te=>"├",},  
  thick =>{tl=>"┏", t=>"━", tr=>"┓", l=>"┃", r=>"┃", bl=>"┗", b=>"━", br=>"┛",ts=>"┫",te=>"┣",}, 
);

sub border{
	my ($grid,$style)=@_;;
	my $height=@$grid;
	my $width=2;
	foreach (@$grid){
		my $w=length stripColours(join("",@$_));
		$width=$w if $w>$width;
	}
	foreach (0..$#$grid){
		$grid->[$_]=[$borders{$style}{l},@{$grid->[$_]},$borders{$style}{r}];
	};
	$grid=[[$borders{$style}{tl},($borders{$style}{t}x$width),$borders{$style}{tr}],
	        @$grid,
	        [$borders{$style}{bl},($borders{$style}{b}x$width),$borders{$style}{br}],];
	        return $grid;
	
}

sub colour{
  my ($fmts)=@_;
  return "" unless $fmts;
  my @formats=map {lc $_} split / +/,$fmts;  
  return join "",map {defined $colours{$_}?"\033[$colours{$_}m":""} @formats;
}

sub paint{
	my ($txt,$fmt)=@_;
	return "" unless $txt;
	return $txt unless $fmt;
	return colour($fmt).$txt.colour("reset") ;
}


sub stripColours{
  my $line=shift;
  return "" unless defined $line;
  $line=~s/\033\[[^m]+m//g;
  return $line;
}


sub clearScreen{
	system($^O eq 'MSWin32'?'cls':'clear');
}

sub printGrid{
	my $grid=shift;
	foreach (@{$grid}){
		print @$_,"\n";
	}
}

sub printAt{
  my ($row,$column,@textRows)=@_;
  @textRows = @{$textRows[0]} if ref $textRows[0];  
  my $blit="\033[?25l";
  $blit.= defined $_?("\033[".$row++.";".$column."H".(ref $_?join("",grep (defined,@$_)):$_)):"" foreach (@textRows) ;
  print $blit;
  print "\n"; # seems to flush the STDOUT buffer...if not then set $| to 1 
};


sub paintMd{
	my ($date,$dt,$options)=@_;
	#return unless $date;
	my $painted=$date;
	if ($date ne " "){
	    if (substr ($dt,0,6).sprintf("%02d",$date) eq $today){$painted=paint($date,"bold red ");};
	}
	
	return " "x(3-length $date).$painted;#paint($date,$dt,$options);
	
}

sub center{  # a 3 character positioned in middle of other 3 character blocks
	my ($text,$width)=@_;
	$text=substr $text,0,3*$width;         # truncate if bigger than the space allocated
	my @split=$text=~/(.{1,3})/g;          # split into 3 character blocks
	$split[-1].=" "x(3-length $split[-1]); # pad out last block in neded
	my $pre=int(($width-scalar @split)/2 + 0.5);my $post=$width-$pre-scalar @split;
	return [("   ")x$pre, @split,("   ")x$post];
}


# Creating grids for month view
# The month view is 
sub monthGrid{
	my ($dt,$options)=@_;
	my ($y,$m,$d)=spDt($dt);
	$options->{border}//="thin";
	$options->{cOffset}//=2;
	$options->{rOffset}//=1;
	
	my @paddedMonth=((" ")x(d1m($dt)-1),(1..dim($dt)) );
	@paddedMonth=(@paddedMonth,(" ")x(6-($#paddedMonth%7)));
	my $grid=[];
	foreach my $row (0..(@paddedMonth/7-1)){
		$grid->[$row]=[map { paintMd($_,$dt,$options)} @paddedMonth[7*$row..7*$row+6]];
	}
	$grid=[[map {" ".substr($_,0,2)}@wdn],@$grid];
	$grid->[0]->[6].=colour("reset");
	if ($options->{showWeek}){
		$grid->[0]=[colour("underline")." w|",@{$grid->[0]}];
		my $weekNo=woy(substr ($dt,0,6)."01");
		foreach(1..$#$grid){
			$grid->[$_]=[sprintf ("%-3s",$weekNo++."|"),@{$grid->[$_]}];
		}
	}
	$grid=[center($mn[$m-1].($options->{showYear}?" ".$y:""),$options->{showWeek}?8:7),@$grid];
	$grid=border($grid,$options->{border});
	return $grid;
}

sub yearGrid{
	my ($dt,$options)=@_;
	my ($y,$m,$d)=spDt($dt);
	$options->{monthsPerRow}//=4;
	$options->{cOffset}//=10;
	$options->{rOffset}//=1;
	my $month=1;
	foreach my $row (1..12/$options->{monthsPerRow}){
		foreach my $col(1..$options->{monthsPerRow}){
			$options->{border}=($month == $m)?"double":"none";
			printAt (($row-1)*9+$options->{rOffset},($col-1)*26+$options->{cOffset},monthGrid($y.sprintf ("%02d",$month)."01",$options));
			$month++;
		}
	}
}
	

#printAt(3,3,monthGrid($today,{showWeek=>1,showYear=>1}));
yearGrid($today,{showWeek=>1,showYear=>1});
printAt(26,4," ");

sub test{
	foreach my $td ("20241231","20220229","20200229","20202229"){
		print "\n";
		print  "Testing validity of $td ..... " ,valDate($td)."\n" ;
		next unless  valDate($td) eq "Valid";
	    print "First day of year  $td should be xxxxx and is: ",d1greg($td),"\n";
	    print "First day of month $td should be xxxxx and is: ",d1m($td),"\n";
	    print "$td is ",(ly($td)?"":" not ")."a leap year\n";
	    print "$td falls on ",(day($td))."  day which is a ".dn($td)."\n";
	    print "$td is the ",(doy($td))." day of the year\n";
	    print "In DD/MM/YYYY form $td is  ",(dmy($td))."\n";
	    print "In mm/DD/YYYY form $td is  ",(mdy($td))."\n";

	}
}
