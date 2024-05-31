#!/usr/bin/env perl
############################################################################# 
####        Paella:   A Calendar Application for the Terminal             ###
############################################################################# 

use strict; use warnings;
my $VERSION=0.07;

# variables  for the ics file importer
# Calendar contain events
# $dateIndex contains events for each day, its name and a colour to apply
my $dateIndex={};  
my $calendar={};

my $options={showWeek=>0,showYear=>1, mode=>"yearView"};

loadICSDir();

# set of functions work on Dates in the form of a YYYYMMDD string
# These could be easily replaced with more robust DateTime  or
# Time::Local modules.  But this way minimises dependencies
# limits needless conversions to a minimum.

my $today=today();
$options->{current}=$today;
# die $options->{current};
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
# split 8 char date into ymb
sub spDt{ return ($_[0]=~/(\d{4})(\d{2})(\d{2})/)};
#join ymd numbers into string
sub jDt{ return sprintf ("%04d",$_[0]).sprintf ("%02d",$_[1]).sprintf ("%02d",$_[2])};
# test leap year                           
sub ly{my ($y,$m,$d)=spDt($_[0]);return (($y%4) - ($y%100) + ($y%400))?0:1;};
# day 1 of year Gregorian Guassian Method ( https://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week
sub d1greg{my ($y,$m,$d)=spDt($_[0]	);return (1+5*(($y-1)%4)+4*(($y-1)%100)+6*(($y-1)%400))%7;};
# day 1 of year Gregorian  Zeller
#sub d1greg{ my $Y=substr($_[0],0,4)-1;my $zeller=  (int(13*14/5) + int(($Y%100)/4) + int((int($Y/100))/4)+ 1 +($Y%100)-2*int($Y/100))%7 ; return ($zeller +6)%7};
# day 1 of year Gregorian lookup from list 28 year cycle;
#sub d1greg{ my $Y=substr($_[0],0,4);return (0,2,3,4, 5,0,1,2, 3,5,6,0, 1,3,4,5, 6,1,2,3, 4,6,0,1, 2,4,5,6)[($Y-1996)%28];}
# day of year
sub doy{my ($y,$m,$d)=spDt($_[0]);return $d+$acc[$m-1]+((ly(jDt($y,$m,$d))&&($m>2))?1:0);}
# week of year
sub woy{return int((doy($_[0])+6)/7);}
# day of date
sub day{my ($doy,$d1y)=(doy($_[0]),d1greg($_[0]));return ($doy+$d1y-1)%7;};
# 1st day of month
sub d1m{my ($y,$m,$d)=spDt($_[0]);return day($y.$m."01")};
# days in month
sub dim{my ($y,$m,$d)=spDt($_[0]);return (($m==2)&&ly($y."0101"))?29:$dm[$m-1]; }
# named day
sub dn{return $wdn[day($_[0])-1]};
# add Day(s) to date;
sub addDay{my ($y,$m,$d)=spDt($_[0]);my $dte=$d+($_[1]//1);
	       while ($dte>dim(jDt($y,$m,$d))){$dte-=(dim(jDt($y,$m,$d)));$m++;$d=1;
		   if ($m>12){$y++;$m=1}};
		   return jDt($y,$m,$dte);}
# take away Day(s) from date;
sub subDay{my ($y,$m,$d)=spDt($_[0]);my $dte=$d-($_[1]//1);
	       while ($dte<1){$m--;$dte+=dim(jDt($y,$m,$d));
		   if ($m<1){$y--;$m=12}};
		   return jDt($y,$m,$dte);}
# next months(s) to date;
sub addMonth{my ($y,$m,$d)=spDt($_[0]);$m+=($_[1]//1);
		   while ($m>12){$y++;$m-=12};return jDt($y,$m,1);}
# previousmonths(s) from date;
sub subMonth{my ($y,$m,$d)=spDt($_[0]);$m-=($_[1]//1);;
		   while ($m<1){$y--;$m+=12};  return jDt($y,$m,1);}
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

# terminal colouring, positional printing and clearing: 
# trimmed down version of module Tern::ANSIColor in MetaCPAN

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
	my $width=2;my $w;
	foreach (0..$#$grid){
		$grid->[$_]=[$borders{$style}{l},@{$grid->[$_]},$borders{$style}{r}];
		my $tmp=stripColours(join("",@{$grid->[$_]}));
		$tmp=~s/│/|/g;
		$width=length $tmp if length $tmp>$width;
	};
	$grid=[[$borders{$style}{tl},($borders{$style}{t}x($width-6)),$borders{$style}{tr}],
	        @$grid,
	        [$borders{$style}{bl},($borders{$style}{b}x($width-6)),$borders{$style}{br}],];
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
	my ($date,$dt)=@_; 
	my $painted=$date;
	my @decorations=();
	if ($date ne " "){
	    my $fullDate=substr ($dt,0,6).sprintf("%02d",$date);
	    if ($fullDate eq $today) {push @decorations,"underline";};
	    if ($fullDate eq $options->{current}){push @decorations,"blink invert";};
	    if ($dateIndex->{$fullDate}->{events}->[0]) {push @decorations,$dateIndex->{$fullDate}->{events}->[0]->{format}};
	}
	$painted=paint($date,join(" ",@decorations));

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
sub monthGrid{
	my ($dt)=@_;
	my ($y,$m,$d)=spDt($dt);
	$options->{border}//="thin";
	
	my @paddedMonth=((" ")x(d1m($dt)),(1..dim($dt)) );
	@paddedMonth=(@paddedMonth,(" ")x(6-($#paddedMonth%7)));
	my $grid=[];
	foreach my $row (0..(@paddedMonth/7-1)){
		$grid->[$row]=[map { paintMd($_,$dt,$options)} @paddedMonth[7*$row..7*$row+6]];
	}
	$grid=[[map {" ".substr($_,0,2)}@wdn],@$grid];
	$grid->[0]->[6].=colour("reset");
	if ($options->{showWeek}){
		$grid->[0]=[colour("underline")." w│",@{$grid->[0]}];
		my $weekNo=woy(substr ($dt,0,6)."01"); # for the 1st day of month
		foreach(1..$#$grid){
			$grid->[$_]=[sprintf ("%2s",$weekNo++)."│",@{$grid->[$_]}];
		}
	}
	$grid=[center($mn[$m-1].($options->{showYear}?" ".$y:""),$options->{showWeek}?8:7),@$grid];
	$grid=border($grid,$options->{border});
	return $grid;
}

sub yearGrid{
	my ($dt)=@_;#my ($dt,$options)=@_;
	my ($y,$m,$d)=spDt($dt);
	$options->{startMonth}//=1;
	while ($m>($options->{startMonth}-1+$options->{monthsPerRow}*$options->{monthRows})){
		$options->{startMonth}+=$options->{monthsPerRow};
	};
	while ($m<$options->{startMonth}){
		$options->{startMonth}-=$options->{monthsPerRow};
	};
	while ($m<$options->{startMonth}){
		$options->{startMonth}-=$options->{monthsPerRow};
	};
	# an error occurs somethimes when calendar is resized, when the
	# months from the previous year need to be displayed
	if ($options->{startMonth}<0){ 
		$options->{startMonth}+=11;
		$y--;
		#die $options->{startMonth}." ".$y." ".$y.sprintf ("%02d",$options->{startMonth})."01";
	};
	my $month=$options->{startMonth};	
	my $calWidth=23+3*$options->{showWeek};
	foreach my $row (1..$options->{monthRows}){
		foreach my $col(1..$options->{monthsPerRow}){
			$options->{border}=($month == $m)?"double":"none";
			printAt (($row-1)*10+$options->{rOffset},($col-1)*$calWidth+$options->{cOffset},monthGrid($y.sprintf ("%02d",$month)."01",$options));
			$month++;
			if ($month>12){$month=1;$y++}
		}
	}
}


# interactivity
# shamelessly stolen from ped  by nieka@daansystems.com
# catch terminal resize, # read key presses,act on them;

$| = 1;
$_ = '' for my (
    $update, $filename, $currentDate, $currentView, $windowWidth, $windowHeight,
    $stty,
);
$update=1;


sub updateAction{
	clearScreen();
	if ($options->{mode} eq 'yearView'){
		yearGrid($options->{current},$options) ;
		if ($dateIndex->{$options->{current}}){
			printAt(10*$options->{monthRows}+$options->{rOffset}-2,20,"");
			my $summaries="";
			foreach (@{$dateIndex->{$options->{current}}->{events}}){$summaries.= paint($calendar->{events}->[$_->{index}]->{SUMMARY},$_->{format})." "};
			print $summaries;
		}
	}
	else{		
	  $options->{border}="shadow";
	  printAt(3,3,monthGrid($options->{current}));
	}
}


my $namedKeys={
	32    =>  'space',
	13    =>  'return',
	9     =>  'tab',
	'[Zm' =>  'shifttab',
	'[Am' =>  'uparrow',
	'[Bm' =>  'downarrow',
	'[Cm' =>  'rightarrow',
	'[Dm' =>  'leftarrow',
	'[Hm' =>  'home',
	'[2~m'=>  'insert',
	'[3~m'=>  'delete',
	'[Fm' =>  'end',
	'[5~m'=>  'pageup',
	'[6~m'=>  'pagedown',
	'[Fm' =>  'end',
};
my $keyActions={
	yearView=>{
		'home'      =>sub{$options->{current}=$today;},
		'rightarrow'=>sub{$options->{current}=addDay($options->{current},1);},
		'leftarrow' =>sub{$options->{current}=subDay($options->{current},1);},
		'uparrow'   =>sub{$options->{current}=subDay($options->{current},7);},
		'downarrow' =>sub{$options->{current}=addDay($options->{current},7);},
		'pagedown'  =>sub{$options->{current}=addMonth($options->{current});},
		'pageup'    =>sub{$options->{current}=subMonth($options->{current});},
		'tab'       =>sub{$options->{current}=(substr($options->{current},0,4)+1).substr($options->{current},4,4);},
		'shifttab'  =>sub{$options->{current}=(substr($options->{current},0,4)-1).substr($options->{current},4,4);},
		'#'         =>sub{$options->{mode}="monthView";updateAction()},
    },
    monthView=>{
		'home'      =>sub{$options->{current}=$today;},
		'rightarrow'=>sub{$options->{current}=addDay($options->{current},1);},
		'leftarrow' =>sub{$options->{current}=subDay($options->{current},1);},
		'uparrow'   =>sub{$options->{current}=subDay($options->{current},7);},
		'downarrow' =>sub{$options->{current}=addDay($options->{current},7);},
		'#'         =>sub{$options->{mode}="yearView";updateAction()},
	}
};


# handle terminal window size changes
$SIG{WINCH} = sub {
    get_terminal_size();
    $update = 1;
	updateAction();
};


sub get_terminal_size {
    ( $windowHeight, $windowWidth ) = split( /\s+/, `stty size` );
    $windowHeight -= 2;
    $options->{monthsPerRow} =  int($windowWidth/26);
	die unless $options->{monthsPerRow};
	$options->{monthsPerRow} =  4 if ($options->{monthsPerRow} ==5);
	$options->{monthRows}   =  int($windowHeight/10);
	$options->{monthRows}-- while ($options->{monthsPerRow}*$options->{monthRows}>12);
	my $calWidth=23+3*$options->{showWeek};
	$options->{cOffset}      =  int(($windowWidth- $options->{monthsPerRow}*$calWidth)/2);
	$options->{rOffset}      =  int(($windowHeight- $options->{monthRows}*10)/2)+2;
}

sub ReadKey { my $key = ''; sysread( STDIN, $key, 1 );  return $key;}

sub ReadLine { return <STDIN>;}

sub ReadMode {
    my ($mode) = @_;
    if ( $mode == 5 ) {
        $stty = `stty -g`;
        chomp($stty);
        system( 'stty', 'raw', '-echo' );# find Windows equivalent
    }
    elsif ( $mode == 0 ) {
        system( 'stty', $stty );         # find Windows equivalent
    }
}

sub run {
    get_terminal_size();
    splash();
    binmode(STDIN);
    ReadMode(5);
    my $key;
    while (1) {
        last if ( !dokey($key) );
        updateAction() if ($update); # update screen
        $update=0;
        $key = ReadKey();
    }
    ReadMode(0);
    print "\n";
}

sub dokey {
    my ($key) = @_;
    return 1 unless $key;
    my $ctrl = ord($key);my $esc="";
    return if ($ctrl == 3);                 # Ctrl+c = exit;
    my $pressed="";
    $esc = get_esc() if ($ctrl==27);
    if (exists $namedKeys->{$ctrl}){$pressed=$namedKeys->{$ctrl}}
	elsif (exists $namedKeys->{$esc}){$pressed=$namedKeys->{$esc}}
	else{$pressed= ($esc ne "")?$esc:chr($ctrl);};
    act($pressed);    
    return 1;
}

sub act{ 
	my $key=shift;
	if ($keyActions->{$options->{mode}}->{$key}){
		$keyActions->{$options->{mode}}->{$key}->();
	}
	else{
		$options->{buffer}//="";
		$options->{buffer}.=$key;
	} 
	$update=1;
	
}

sub get_esc {
    my $esc;
    while ( my $key = ReadKey() ) {
        $esc .= $key;
        last if ( $key =~ /[a-z~]/i );
    }
    return $esc."m";
}

# This is an ultra simplistic ics file importer
# Populates $calendar and $dateitems with events from an ics file

sub loadICSDir{
	my $dir=shift//(-d "ICS")?"ICS":".";
	opendir (my $d, $dir) or return;
	my @cols=qw/red green blue yellow magenta cyan/;
	while (my $file_name = readdir($d)) {
		next unless $file_name=~/.ics$/;

		my $col=pop @cols;
		loadICS($dir."/".$file_name,$col);
		unshift @cols,$col;
	}
	close $d;
}

sub loadICS{
	our ($file,$col)=@_;
	open my $ics,"<",$file;
	$calendar//={events=>[],todos=>[],journals=>[]};
	our @levels;
	my $lastLine="";
	our $item={};
	while  (my $line=<$ics>){
	   $line =~s/[\r\n]//g;
	   if($lastLine eq ""){
		   $lastLine = $line;
	   }
	   elsif ($line=~/^\s/){
		   $lastLine.=$line;
		}
		else{
			parseLine($lastLine);
			$lastLine=$line;
		}
	}
	
	close $ics;
	sub parseLine{
		my $line=shift;
		 if ($line=~/^BEGIN:V(.*)$/){
			 push @levels,$1;
			 return;
		 }
		 elsif ($line=~/^END:V(.*)$/){                          # end of section 
			 if ($levels[-1]=~/(EVENT|TODO|JOURNAL)/){
				 my $class=lc $1."s";
				if (%$item){
					push @{$calendar->{$class}},{%$item} if %$item;
					addDateItem($class,$item,$col);
				}
				$item={};
			}
			pop @levels;
		}
		elsif ($levels[-1]=~/EVENT|TODO|JOURNAL/){
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;\:]+)?(\:.*)$/);
			$item->{$parts[0]}=substr $parts[-1],1 if $parts[0];
		}
		elsif ($levels[-1]=~/CALENDAR/){
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
			$calendar->{$parts[0]}=substr $parts[-1],1 if $parts[0];
		}
		else{ #for subcomponents e.g. alarm
			$item->{$levels[-1]}//={};
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
			$item->{$levels[-1]}->{$parts[0]}=substr $parts[-1],1 if $parts[0];
		}
	}
	
	sub addDateItem{
		my ($class,$itm,$clr)=@_;
		my $dateStr=substr ($item->{DTSTART},0,8);
		$dateIndex->{$dateStr}//={events=>[],todos=>[],journal=>[],};
		$dateIndex->{$dateStr}->{$class}=[{index  => $#{$calendar->{$class}},
			                               format => $clr},
			                               @{$dateIndex->{$dateStr}->{$class}},];
	}
}


sub splash{
	clearScreen();
	my @splash=qw/
██████╗░░█████╗░███████╗██╗░░░░░██╗░░░░░░█████╗░
██╔══██╗██╔══██╗██╔════╝██║░░░░░██║░░░░░██╔══██╗
██╔══██╗██╔══██╗██╔════╝██║░░░░░██║░░░░░██╔══██╗
██████╔╝███████║█████╗░░██║░░░░░██║░░░░░███████║
██╔═══╝░██╔══██║██╔══╝░░██║░░░░░██║░░░░░██╔══██║
██╔═══╝░██╔══██║██╔══╝░░██║░░░░░██║░░░░░██╔══██║
██║░░░░░██║░░██║███████╗███████╗███████╗██║░░██║
╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝╚═╝░░╚═╝
T_h_e__P_e_r_l__S_u_p_e_r_C_a_l_e_n_d_a_r__A_p_p

/;

foreach my $step (0..$windowWidth/2+30){
	foreach (0..$#splash){
		printAt($windowHeight/2-3+$_,$windowWidth-$step,substr($splash[$_],0,3*$step)."   ");
		$step++ unless ($windowWidth/2+30-$step)<=0;
	}
	printAt($windowHeight/2+6,0,"                                     ");

	select(undef, undef, undef, 0.01);
}
sleep 1;
}

run();

;
