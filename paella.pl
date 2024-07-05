#!/usr/bin/env perl
############################################################################# 
####        Paella:   A Calendar Application for the Terminal             ###
#############################################################################
###                                                                       ### 
#    For more information visit https://github.com/saiftynet/Calendar/      #
###            Copyright SAIFTYNET,      Licence GPL 3.0                  ### 
###                                                                       ### 
#############################################################################

use strict;use warnings;
my $VERSION=0.10;

my $ics=<<ICSFILE;
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//PAELLA//TestObject//EN
BEGIN:VEVENT
SUMMARY:Test RRULE
UID:ff808181-1fd7389e-011f-d7389ef9-00000003
DTSTART;TZID=America/New_York:20240420T120000
DURATION:PT1H
LOCATION:Mo's bar - back room
RRULE:FREQ=DAILY;UNTIL=20240505;INTERVAL=2
EXDATE;TZID=America/New_York:20240427T120000,20240428T120000,
BEGIN:VALARM
TRIGGER:-PT10M
ACTION:DISPLAY
END:VALARM
END:VEVENT
END:VCALENDAR
ICSFILE

my $date=new YMD();

my $paella=new Paella({data=>$ics,dir=>"ICS",splash=>0});
Draw::clearScreen();
$paella->run;

##########################################################################
##################  The Application ######################################
##########################################################################
package Paella;
our @weekdays=qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/;
sub new{
    my ($class,$options)=@_;
    my $self={
        mode=>$options->{mode}//"yearView",
        showWeek=>$options->{showWeek}//1,
        showYear=>$options->{showYear}//1,
        splash=>$options->{splash}//1,
    };
    $self->{current}=YMD->new($options->{date});
    $self->{ui} = new UI;
    $self->{d}  = new Draw($self->{ui}->{windowHeight}, $self->{ui}->{windowWidth});
    $self->{calData}=CalData->new();
    
    $self->{calData}->loadDir($options->{dir}) if $options->{dir};
    $self->{calData}->load($options->{file}  ) if $options->{file};
    $self->{calData}->load($options->{data}  ) if $options->{data};
    bless $self, $class;
    $self->setYearViewSizes();
    $self->setupActions();
    return $self;
}

sub setYearViewSizes{
    my $self=shift;
    $self->{monthsPerRow} =  int($self->{ui}->{windowWidth}/26);
    die unless $self->{monthsPerRow};
    $self->{monthsPerRow} =  4 if ($self->{monthsPerRow} ==5);
    $self->{monthRows}   =  int($self->{ui}->{windowHeight}/10);
    $self->{monthRows}-- while ($self->{monthsPerRow}*$self->{monthRows}>12);
    my $calWidth=23+3*$self->{showWeek};
    $self->{cOffset}      =  int(($self->{ui}->{windowWidth}  - $self->{monthsPerRow}*$calWidth)/2);
    $self->{rOffset}      =  int(($self->{ui}->{windowHeight} - $self->{monthRows}*10)/2)+2;
}

sub setupActions{
    my ($self)=@_;
    my $keyActions={
        yearView=>{
            'home'      =>sub{$self->{current}=YMD::today();},
            't   '      =>sub{$self->{current}=YMD::today();},
            'rightarrow'=>sub{$self->{current}=YMD::addDay($self->{current},1);},
            'leftarrow' =>sub{$self->{current}=YMD::subDay($self->{current},1);},
            'uparrow'   =>sub{$self->{current}=YMD::subDay($self->{current},7);},
            'downarrow' =>sub{$self->{current}=YMD::addDay($self->{current},7);},
            'pagedown'  =>sub{$self->{current}=YMD::addMonth($self->{current});},
            'pageup'    =>sub{$self->{current}=YMD::subMonth($self->{current});},
            'tab'       =>sub{$self->{current}->{y}++},
            'shifttab'  =>sub{$self->{current}->{y}--;},
            '#'         =>sub{$self->setMode("monthView");$self->updateAction()},
            "updateAction"=>sub{$self->updateAction()},
            "windowChange"=>sub{$self->setYearViewSizes();$self->updateAction()},
        },
        monthView=>{
            'home'      =>sub{$self->{current}=YMD::today();},
            't   '      =>sub{$self->{current}=YMD::today();},
            'rightarrow'=>sub{$self->{current}=YMD::addDay($self->{current},1);},
            'leftarrow' =>sub{$self->{current}=YMD::subDay($self->{current},1);},
            'uparrow'   =>sub{$self->{current}=YMD::subDay($self->{current},7);},
            'downarrow' =>sub{$self->{current}=YMD::addDay($self->{current},7);},
            'pagedown'  =>sub{$self->{current}=YMD::addMonth($self->{current});},
            'pageup'    =>sub{$self->{current}=YMD::subMonth($self->{current});},
            '#'         =>sub{$self->setMode("yearView")},
            "updateAction"=>sub{$self->updateAction()},
            "windowChange"=>sub{$self->setYearViewSizes();$self->updateAction()},
        },
    };
    foreach my $mode(qw/yearView monthView/){
        for my $k (keys %{$keyActions->{$mode}}){
            $self->{ui}->setKeyAction($mode,$k,$keyActions->{$mode}->{$k});
        }
    }
}

sub run{
    my $self=shift;
    $self->{d}->splash() if $self->{splash};
    $self->updateAction();
    $self->{ui}->run("yearView");
    exit;
}

sub updateAction{
    my $self=shift;
    $self->{d}->clearScreen();
    if ($self->{mode} eq 'yearView'){
        $self->yearView($self->{current}) ;
    }
    else{        
      $self->monthView($self->{current});;
    }
}

sub setMode{
    my ($self,$mode)=@_;
    $self->{mode}=$mode;
    $self->{ui}->{mode}=$mode;
    $self->updateAction();
}

sub monthTable{
    my ($self,$date)=@_;
    $date=YMD->new($date);
    my $monthGrid=$date->monthGrid();
    my $weekNo=(YMD->new($date->{y},$date->{m},1)->weekOfYear());
    
    my @table=( center3c($date->monthName().($self->{showYear}?" ".$date->{y}:""),$self->{showWeek}?8:7),
                [($self->{showWeek}?(" w|"):()),
                    map {substr($_,0,2)." "}(qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/)]);
    
    foreach my $row(0..$#{$monthGrid}){
        my @cells=(($self->{showWeek}?(sprintf ("%2s",$weekNo++)."│"):()));
        foreach my $cell(0..$#{$monthGrid->[$row]}){
            my $content=sprintf ("%2s",$monthGrid->[$row]->[$cell]->{label});
            my $formats=$content=~/\d/?$self->getFormat( sprintf ("%04d",$date->{y}).
                                   sprintf ("%02d",$date->{m}).
                                   sprintf ("%02d",$monthGrid->[$row]->[$cell]->{label}) ):"";
            push @cells,$self->{d}->paint($content,$formats)." ";
        }
        push (@table,[@cells])
    }
    return $self->{d}->border([@table],$self->{border});
}

sub yearView{
    my ($self,$date)=@_;
    $date=YMD->new($date);
    my $year=$date->{y};
    $self->{startMonth}//=1;
    while ($date->{m}>($self->{startMonth}-1+$self->{monthsPerRow}*$self->{monthRows})){
        $self->{startMonth}+=$self->{monthsPerRow};
    };
    while ($date->{m}<$self->{startMonth}){
        $self->{startMonth}-=$self->{monthsPerRow};
    };
    # an error occurs somethimes when calendar is resized, when the
    # months from the previous year need to be displayed
    if ($self->{startMonth}<0){ 
        $self->{startMonth}+=11;
        $year--;
    };
    
    my $month=$self->{startMonth};    
    my $calWidth=23+3*$self->{showWeek};
    foreach my $row (1..$self->{monthRows}){
        foreach my $col(1..$self->{monthsPerRow}){
            $self->{border}=($month == $date->{m})?"double":"none";
            $self->{d}->printAt (($row-1)*9+$self->{rOffset},($col-1)*$calWidth+$self->{cOffset},
                       $self->monthTable(YMD->new($year,$month,1)));
            $month++;
            if ($month>12){$month=1;$year++}
        }
    }
}

sub monthView{
    my ($self,$date)=@_;
    my $columnWidth=int($self->{ui}->{windowWidth}/7);
    my $rOffset=($self->{ui}->{windowWidth}-$columnWidth*7);
    my $rowHeight=$self->{ui}->{windowHeight}/7;
    my $monthGrid=$date->monthGrid();    
    
    # build cnontents for each cell
    foreach my $row(0..$#$monthGrid){
        foreach my $cell (0..$#{$monthGrid->[$row]}){
            if (!$monthGrid->[$row]->[$cell]->{label}){  # blank cells
                $monthGrid->[$row]->[$cell]->{content}  = [$self->{d}->paint(centered(" ",$columnWidth-1),"overline")];
            }
            else{                                        # cells with dates               
                my $cellLabel=$monthGrid->[$row]->[$cell]->{label};
                my $cellDate=$date->setDate($cellLabel);
                my $formats= $self->getFormat($cellDate);    
                $monthGrid->[$row]->[$cell]->{content}  = [$self->{d}->paint(centered($cellLabel,$columnWidth-1),$formats." overline")];
                if ($self->{calData}{dateIndex}{$cellDate->toStr()}){
                    foreach(@{$self->{calData}{dateIndex}{$cellDate->toStr()}{events}}){
                        $monthGrid->[$row]->[$cell]->{content}  =
                             [@{$monthGrid->[$row]->[$cell]->{content}},
                             $self->{d}->paint(centered($self->{calData}{calendar}{events}[$_->{index}]{SUMMARY},$columnWidth-1),$_->{format})];
                    }
                }
                
            }    
        }
    }
    my $rowBorder="╠".join ("╬",("─"x($columnWidth -2))x7) ."╣";
    my $blank=(" "x ($columnWidth-2));
    my $printable=[];
    push @$printable,"╔". join("╦", ("═"x ($columnWidth-2)) x 7)."╗"; 
    push @$printable,"║". join("│", map{centered($_,$columnWidth-1)}(qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/))."║";
    foreach my $row(0..$#$monthGrid){
    #    push @$printable,$rowBorder;
        foreach my $rh (0..$rowHeight-1){
            push @$printable,"║".join ("│", map{$_->{content}->[$rh]?$_->{content}->[$rh]:" "x($columnWidth-2)}@{$monthGrid->[$row]})."║";
        }
    }
    push @$printable, "╚". join("╩", ("═"x ($columnWidth-2)) x 7)."╝"; 
    $self->{d}->printAt(2,$rOffset,centered ($date->monthName." ".$date->{y},$columnWidth*7));
    $self->{d}->printAt(3,$rOffset,$printable);
}

sub getFormat{  #decide formats for each date label based on events and calendar state
    my ($self,$dateStr)=@_;
    my @formats;
    if ($self->{calData}{dateIndex}{$dateStr}){
        push @formats,$self->{calData}{dateIndex}{$dateStr}{events}[0]{format};
    }
    if (YMD->cmp($dateStr,YMD->today())==0){ push @formats,"underline"};
    if (YMD->cmp($dateStr,$self->{current})==0){ push @formats,"bright white on_blue"};
    return join(" ",@formats)
}

sub center3c{  # a 3 character positioned in middle of other 3 character blocks
    my ($text,$width)=@_;
    $text=substr $text,0,3*$width;         # truncate if bigger than the space allocated
    my @split=$text=~/(.{1,3})/g;          # split into 3 character blocks
    $split[-1].=" "x(3-length $split[-1]); # pad out last block if needed
    my $pre=int(($width-scalar @split)/2 + 0.5);my $post=$width-$pre-scalar @split;
    return [("   ")x$pre, @split,("   ")x$post];
}


sub centered{
    my ($text,$width)=@_;
    my $tmp=Draw::stripColours(undef,$text);
    return substr ($tmp,0,$width-1) if ($width<=length $tmp);
    my $prePad=int(($width-length $tmp)/2);
    return (" "x$prePad).$text.(" "x($width-1-$prePad-length $tmp));
}

package CalData;
###########################################################################
################# Calendar Data Consolidation Object ######################
###########################################################################
# This package parses data from ics files and stores and indexes them.
# It will handle Repeat Rules,EXDATES and RDATES (incomplete)

    sub new{
        my ($class,$data)=@_;
        my $self={ calendar=>{events=>[],todos=>[],journals=>[],},
                   dateIndex=>{},
                   lastLine=>"",
                   item=>{},
                   levels=>[],
                   col=>[qw/red green yellow magenta cyan/],
                   emoji=>""};
        bless $self,$class;
        $self->load($data) if $data;
        return $self;
    }
    
    sub loadDir{
        my ($self,$dir)=@_;
        $dir//="./";
        opendir (my $d, $dir) or return;
        while (my $file_name = readdir($d)) {
           next unless $file_name=~/.ics$/;
           $self->load($dir."/".$file_name);
        }
        close $d;
    }
    
    sub load{  # load data line by line
        my ($self,$file)=@_;
        $self->{col}=[@{$self->{col}}[1..$#{$self->{col}}],$self->{col}->[0]];
        if (length $file > 100){
			while($file =~ /([^\n]+)\n?/g){
				$self->nextLine($1);
			}
		}
        elsif (-e $file and !-d $file){ # if a filepath passed read file and parse it line by line;
			open my $ics,"<",$file or return;
			$self->{lastLine}="";
			while  (my $line=<$ics>){
				$self->nextLine($line)
			}
			close $ics;
		}
		elsif (-d $file){
			loadDir($self,$file);
		}
    }
    
    sub nextLine{ # data is read line by line, from files or strings
        my ($self,$line)=@_;
		   $line =~s/[\r\n]//g;
           if($self->{lastLine} eq ""){
               $self->{lastLine} = $line;
           }
           elsif ($line=~/^\s/){
               $self->{lastLine}.=$line;
            }
            else{
                $self->parseLine();
                $self->{lastLine}=$line;
            }
    }

    sub getEvents{
		my ($self,$date) = @_;
		$date=$date->toStr() if ref $date;
		return $self->{dateIndex}{$date}{events}		
	}
    
    sub parseLine{
        my $self=shift;
         if ($self->{lastLine}=~/^BEGIN:V(.*)$/){
             push @{$self->{levels}},$1;
             return;
         }
         elsif ($self->{lastLine}=~/^END:V(.*)$/){                          # end of section 
             if ($self->{levels}->[-1]=~/(EVENT|TODO|JOURNAL)/){
                 my $type=lc $1."s";
                 my $dateStr=substr ($self->{item}->{DTSTART},0,8);
                 if (%{$self->{item}}){
                    # the items goes onto the list
                    push @{$self->{calendar}->{$type}},{%{$self->{item}}} if %{$self->{item}}; 
                    #Then it is added to the indexes based on repetition rules
                    if ($self->{item}->{RRULE}){
                        $self->parseRRule($type,$dateStr,$self->{item}->{RRULE},$#{$self->{calendar}->{$type}},$self->{col});
                    }
                    else{
                        $self->addDateItem($type,$dateStr);
                    }
                }
                $self->{item}={};
            }
            pop @{$self->{levels}};
        }
        elsif ($self->{levels}->[-1]=~/EVENT|TODO|JOURNAL/){
            my @parts=($self->{lastLine}=~/^([A-Z\-]+)(\;[^\;\:]+)?(\:.*)$/);
            $self->{item}->{$parts[0]}=substr $parts[-1],1 if $parts[0];
        }
        elsif ($self->{levels}->[-1]=~/CALENDAR/){
            my @parts=($self->{lastLine}=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
            $self->{calendar}->{$parts[0]}=substr $parts[-1],1 if $parts[0];
        }
        else{ #for subcomponents e.g. alarm
            $self->{item}->{$self->{levels}->[-1]}//={};
            my @parts=($self->{lastLine}=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
            $self->{item}->{$self->{levels}->[-1]}->{$parts[0]}=substr $parts[-1],1 if $parts[0];
        }
    }
    
    sub parseRRule{
        my ($self,$type,$dateStr,$rule,$index,$col)=@_;
        my $rrule={};
        my $date=YMD->new($dateStr);
        foreach (split(";",$rule)){
            my ($key,$value)=split "=";
            $rrule->{$key}=$value;
        }
        $rrule->{INTERVAL}//=1;
        
        my ($step,$fun)=(1,"addDay");
        
        if ($rrule->{FREQ}){
            for($rrule->{FREQ}){
                /DAILY/ && do{
                    $step=$rrule->{INTERVAL};
                    last;
                };
                /WEEKLY/ && do{
                    $step=7*$rrule->{INTERVAL};
                    last;
                };
                /MONTHLY/ && do{
                    $step=$rrule->{INTERVAL};
                    $fun="addMonth";
                    last;
                };
            }
			# do the repeats
			if ($rrule->{COUNT}){
				my $count=$rrule->{COUNT};
				while ($count>0){
						$self->addDateItem($type,$date->toStr());
						$date=$date->$fun($step);
						$count--;
				}
			}
			elsif ($rrule->{UNTIL}){
				while ($date->cmp($rrule->{UNTIL})<=0){
						$self->addDateItem($type,$date->toStr());
						$date=$date->$fun($step);
				}
				
			}            
        }

    }
    
    sub addDateItem{
        my ($self,$type,$date)=@_;# $date can be a string or YMD object
        $date = YMD->new($date);
		my $dateStr=$date->toStr();
        # item is the last one to be indexed
        my $item=(@{$self->{calendar}->{$type}})[-1];
        return if $date->inList($item->{EXDATE});
        $self->{dateIndex}->{$dateStr}//={events=>[],todos=>[],journal=>[],};
        $self->{dateIndex}->{$dateStr}->{$type}=[{index  => $#{$self->{calendar}->{$type}},
                                           format => $self->{col}->[0]},
                                           @{$self->{dateIndex}->{$dateStr}->{$type}},];
    }

package YMD;
############################################################################################
############################## Date Utilities Class  #######################################
############################################################################################
# This allows date calculations and calendar drawing
    our @wdn=(qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/);
    sub new{
        my ($class,$str,$m,$d, $H,$M,$S)=@_;
        my $self={};
        if (!$str){ # if nothing passed, then today
            (undef,undef,undef,$self->{d},$self->{m},$self->{y}) = localtime;
            $self->{y}+= 1900;
            $self->{m}++;
        }
        elsif (ref $str && $str->{y}){ #if a YMD passed, return a clone of it
            ($self->{y},$self->{m},$self->{d})=($str->{y},$str->{m},$str->{d})
        }
        elsif ($str=~/^\d{8}(T\d{6})?/){  # if a dateString Passed
			my $t=$1;
            ($self->{y},$self->{m},$self->{d})=($str=~/^(\d{4})(\d{2})(\d{2})/);
            if ($t){
				die $t;
				($self->{H},$self->{M},$self->{S})=($t=~/(\d{2})(\d{2})(\d{2})/);
				die $self->{H};
			}
        }
        else {  # if passed with y,m,d 
            ($self->{y},$self->{m},$self->{d})=($str,$m,$d);
        }
        bless $self,$class;
        return $self;
    }
    
    sub today{
        return new ("YMD")
    }
    
    sub toStr{
        my ($self,$format)=@_;
        if ($format){
            return $self->{d}."/".$self->{m}."/".$self->{y} if ($format =~/dmy/);
            return $self->{m}."/".$self->{d}."/".$self->{y} if ($format =~/mdy/);
        }
        return sprintf ("%04d",$self->{y}).sprintf ("%02d",$self->{m}).sprintf ("%02d",$self->{d})
    }

    sub leapYear{
        my $self=shift;
        my $y=ref $self?$self->{y}:$self;
        return (($y%4) - ($y%100) + ($y%400))?0:1;
    }
    

# day 1 of year Gregorian Guassian Method ( https://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week
    sub d1greg{
        my $self=shift;
        return (1+5*(($self->{y}-1)%4)+4*(($self->{y}-1)%100)+6*(($self->{y}-1)%400))%7;
    }
    
# calculate which day of the year a date falls in    
    sub dayOfYear{
        my $self=shift;
        return $self->{d}+                             # which day
               (0,31,59,90,120,151,181,212,243,273,304,334)[$self->{m}-1]+ # which month
               ((leapYear($self->{y})&&($self->{m}>2))?1:0); # leap year compensation
    }
    
# calculate which week of the year a date falls in  
    sub weekOfYear{
        my $self=shift;
        return int((dayOfYear($self)+6)/7);
    }

# calculate which week of the year a date falls in  0..6 with 0 being Sunday    
    sub weekday{
        my $self=shift;
        return (dayOfYear($self)+d1greg($self)-1)%7;
    }
# calculate which day first day of month is    
    sub monthFirstDay{
        my $self=shift;
        return weekday(YMD->new($self->{y},$self->{m},1));
    }
    
# return the number of days in the month (month is 1..12   
    sub daysInMonth{
        my $self=shift;
        return (($self->{m}==2)&&leapYear($self->{y}))?29:(31,28,31,30,31,30,31,31,30,31,30,31)[$self->{m}-1];
    }

# return the name of the day
    sub dayName{
        my $self=shift;
        return (qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/)[weekday($self)-1]
    }
    
# set the date to a certain date ....does not check for invalida date
    sub setDate{
        my ($self,$date)=@_;
        my $tmp=new YMD($self);
        $tmp->{d}=$date;
        return $tmp;
    }

# return name of month
    sub monthName{
        my $self=shift;
        return (qw/January February March April May June July August September October November December/)[$self->{m}-1]
    }
    
    
    sub addDay{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{d}+=$days//1;
        while ($tmp->{d}>daysInMonth($tmp)){
            $tmp->{d}-=(daysInMonth($tmp));
            $tmp->{m}++;
            if ($tmp->{m}>12){
                $tmp->{y}++;
                $tmp->{m}=1;
                }
        };
        return $tmp
    }
    sub subDay{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{d}-=$days//1;
        while ($tmp->{d}<1){
            $tmp->{m}--;
            $tmp->{d}+=daysInMonth($tmp);
            if ($tmp->{m}<1){
                $tmp->{y}--;
                $tmp->{m}=12;
                }
        };
        return $tmp
    }
    sub addMonth{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{m}+=($_[1]//1);
        while ($tmp->{m}>12){
            $tmp->{y}++;
            $tmp->{m}-=12;
        }
        $tmp->{d}=$tmp->{d}<daysInMonth($tmp)?$tmp->{d}:daysInMonth($tmp);
        return $tmp;
    }
    sub subMonth{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{m}-=($_[1]//1);
        while ($tmp->{m}<1){
            $tmp->{y}--;
            $tmp->{m}+=12;
        }
        $tmp->{d}=$tmp->{d}<daysInMonth($tmp)?$tmp->{d}:daysInMonth($tmp);
        return $tmp;
    }
    
   # get the next date with dayname e.g the next("sunday"), next("TU"), next(2);
    sub next{  
        my ($self,$day)=@_;
        if ($day=~/^(su|mo|tu|we|th|fr|sa)/i){
			$day={su=>0,mo=>1,tu=>2,we=>3,th=>4,fr=>5,sa=>6}->{lc $1}
		}
		return undef unless($day>=0 && $day<7);
        my $tmp=new("YMD",$self);
        my $tDay=weekday($tmp);
		$tmp=$tmp->addDay($day-$tDay+($day<=$tDay?7:0));
		return $tmp;
	}
	
	sub inList{
        my ($self,@list)=@_;
        @list=map{substr($_,0,8)} map{split "," } @list;
        foreach (@list){
			return 1 if $self->toStr() eq $_
		}
        return 0;
	}
	
	# compares two dates, or a another date to itself;
    sub cmp{
        my ($self,$date1,$date2)=@_;
        if ($date2){
			$date2=new("YMD",$date2);
			$date1=new("YMD",$date1);
		}
		else{
			$date2=new("YMD",$date1);
			$date1=new("YMD",$self);
		};
        
        #return 0  if ($date1->{y}==$date2->{y})&&($date1->{m}==$date2->{m})&&($date1->{d}==$date2->{d});
        return 1  if ($date1->{y}>$date2->{y});
        return -1 if ($date1->{y}<$date2->{y});
        return 1  if ($date1->{m}>$date2->{m});
        return -1 if ($date1->{m}<$date2->{m});
        return 1 if ($date1->{d}>$date2->{d});
        return -1 if ($date1->{d}<$date2->{d});    
        return 0;    
    }
    
    # takes a date in YMD, 8 digit string or y,m,d forms
    #returns a grid of hashes for displaying
    sub monthGrid{ 
        my $date=YMD->new(@_);
        my $preBlanks=($date->monthFirstDay()+6)%7;          # blank days in grid
        my @cells=(("")x$preBlanks,1..$date->daysInMonth()); # dates of month
        push @cells,"" while (@cells%7);                     # full 7 column grid
        # return grid of hashes containing date labels and datestrings (both empty strings if cell is empty)
        @cells=map{{label=>$_,date=>$_?YMD->new($date->{y},$date->{m},$_)->toStr():"",}}@cells;                       # cell contents as hash
        my $grid=[];
        foreach my $row(0..@cells/7-1){
            $grid->[$row]=[@cells[$row*7..$row*7+6]];
        }
        return $grid;                          
    }
    
package UI;    
#######################################################################################
#####################   User Interaction Object #######################################
#######################################################################################

sub new{
    my $class=shift;
    $| = 1;
    my $self={};
    $self->{$_}= '' for (qw/update windowWidth windowHeight stty mode buffer run/);
    $self->{$_}={} for (qw/namedKeys actions mapping/);
    $self->{namedKeys}=setKeys();
    bless $self, $class;
    $self->get_terminal_size;
    $SIG{WINCH} = sub {$self->winSizeChange();};
    return $self;
}

sub run{
    my ($self,$mode)=@_;
    $self->{mode}=$mode//"default";
    $self->{run}=1;
    $self->get_terminal_size();
    binmode(STDIN);
    $self->ReadMode(5);
    my $key;
    while ($self->{run}) {
        last if ( !$self->dokey($key) );
        $self->{actions}->{$self->{mode}}->{updateAction}->() // $self->updateAction() if ($self->{update}); # update screen
        $self->{update}=0;
        $key = $self->ReadKey();
    }
    $self->ReadMode(0);
    print "\n";
}


sub stop{
    my $self=shift;
    $self->{run}=0;
    
}

sub setKeys {# gives the keys pressed a name
    return {
        32     =>  'space',
        13     =>  'return',
        9      =>  'tab',
        '[Zm'  =>  'shifttab',
        '[Am'  =>  'uparrow',
        '[Bm'  =>  'downarrow',
        '[Cm'  =>  'rightarrow',
        '[Dm'  =>  'leftarrow',
        '[Hm'  =>  'home',
        '[2~m' =>  'insert',
        '[3~m' =>  'delete',
        '[Fm'  =>  'end',
        '[5~m' =>  'pageup',
        '[6~m' =>  'pagedown',
        '[Fm'  =>  'end',
        'OPm'  =>  'F1',
        'OQm'  =>  'F2',
        'ORm'  =>  'F3',
        'OSm'  =>  'F4',
        '[15~m'=> 'F5',
        '[17~m'=> 'F6',
        '[18~m'=> 'F7',
        '[19~m'=> 'F8',
        '[21~m'=> 'F10',
        '[24~m'=> 'F12',
    };    
}

sub dokey {
    my ($self,$key) = @_;
    return 1 unless (defined $key);
    my $ctrl = ord($key);my $esc="";
    return if ($ctrl == 3);                 # Ctrl+c = exit;
    my $pressed="";
    if ($ctrl==27){
        while ( my $key = $self->ReadKey() ) {
           $esc .= $key;
           last if ( $key =~ /[a-z~]/i );
        }
        if ($esc eq "O"){# F1-F5
           while ( my $key = $self->ReadKey() ) {
             $esc .= $key;
             last if ( $key =~ /[a-z~]/i );
           }
            
        }    
        $esc.="m"
    };
    
    if (exists $self->{namedKeys}->{$ctrl}){$pressed=$self->{namedKeys}->{$ctrl}}
    elsif (exists $self->{namedKeys}->{$esc}){$pressed=$self->{namedKeys}->{$esc}}
    else{$pressed= ($esc ne "")?$esc:chr($ctrl);};
    $self->act($pressed,$key);    
    return 1;
}

sub act{ 
    my ($self,$pressed,$key)=@_;
    if ($self->{actions}->{$self->{mode}}->{$pressed}){
        $self->{actions}->{$self->{mode}}->{$pressed}->();
    }
    else{
        $self->{buffer}//="";
        $self->{buffer}.=$key;
    } 
    $self->stop() if ($pressed eq "Q");
    print $pressed;
    $self->{update}=1;
    
}

sub get_terminal_size {
    my $self=shift;
    if ($^O eq 'MSWin32'){
        `chcp 65001\n`;
        my $geometry=(split("\n", `powershell -command "&{(get-host).ui.rawui.WindowSize;cls}"`))[3];
        ($self->{windowHeight}, $self->{windowWidth})=(split(/\s+/,$geometry))[1,2];
    }
    else{    
        ( $self->{windowHeight}, $self->{windowWidth} ) = split( /\s+/, `stty size` );
        $self->{windowHeight} -= 2;
    }
}

sub winSizeChange{
    my $self=shift;
    $self->get_terminal_size();
    $self->{actions}->{$self->{mode}}->{"windowChange"}->() if $self->{actions}->{$self->{mode}}->{"windowChange"}->();
}

sub ReadKey {
    my $self=shift;
    my $key = '';
    sysread( STDIN, $key, 1 );
    return $key;
}

sub ReadLine { return <STDIN>;}

sub ReadMode {
    my ($self,$mode)=@_;
    if ( $mode == 5 ) {  
        $self->{stty} = `stty -g`;
        chomp($self->{stty});
        system( 'stty', 'raw', '-echo' );# find Windows equivalent
    }
    elsif ( $mode == 0 ) {
        system( 'stty', $self->{stty} ); # find Windows equivalent
    }
}

### actions to update the screen need to be setup for interactive applications 
sub setKeyAction{
    my ($self,$mode,$key,$uAction)=@_;
    $self->{actions}->{$mode}->{$key}=$uAction;
}


sub updateAction{
    print "\n\r";
}

package Draw;
###########################################################################
######################### Screen drawing object   #########################
###########################################################################
    sub new{
        my $class=shift;
        my $self={};
        ($self->{windowHeight},$self->{windowWidth})=@_;
        $self->{colours}={black   =>30,red   =>31,green   =>32,yellow   =>33,blue   =>34,magenta   =>35,cyan  =>36,white   =>37,
               on_black=>40,on_red=>41,on_green=>42,on_yellow=>43,on_blue=>44,on_magenta=>4,on_cyan=>46,on_white=>47,
               reset=>0, bold=>1, italic=>3, underline=>4, blink=>5, strikethrough=>9, invert=>7, bright=>1, overline=>53};
        $self->{borders}={
              none=>  {tl=>"", t=>"", tr=>"", l=>" ", r=>" ", bl=>"", b=>"", br=>"",ts=>"",te=>"",},
             # none=>  {tl=>" ", t=>" ", tr=>" ", l=>" ", r=>" ", bl=>" ", b=>" ", br=>" ",ts=>" ",te=>Z" ",},
              simple=>{tl=>"+", t=>"-", tr=>"+", l=>"|", r=>"|", bl=>"+", b=>"-", br=>"+",ts=>"|",te=>"|",},
              double=>{tl=>"╔", t=>"═", tr=>"╗", l=>"║", r=>"║", bl=>"╚", b=>"═", br=>"╝",ts=>"╣",te=>"╠",},
              shadow=>{tl=>"┌", t=>"─", tr=>"╖", l=>"│", r=>"║", bl=>"╘", b=>"═", br=>"╝",ts=>"┨",te=>"┠",},
              thin  =>{tl=>"┌", t=>"─", tr=>"┐", l=>"│", r=>"│", bl=>"└", b=>"─", br=>"┘",ts=>"┤",te=>"├",},  
              thick =>{tl=>"┏", t=>"━", tr=>"┓", l=>"┃", r=>"┃", bl=>"┗", b=>"━", br=>"┛",ts=>"┫",te=>"┣",}, 
            };
        bless $self,$class;
        return $self;
    }
    
sub border{
    my ($self,$grid,$style)=@_;
    my $height=@$grid;
    my $width=2;my $w;
    foreach (0..$#$grid){
        $grid->[$_]=[$self->{borders}->{$style}->{l},@{$grid->[$_]},$self->{borders}->{$style}->{r}];
        my $tmp=$self->stripColours(join("",@{$grid->[$_]}));
        $tmp=~s/│/|/g;
        $width=length $tmp if length $tmp>$width;
    };
    $grid=[[$self->{borders}->{$style}->{tl},($self->{borders}->{$style}->{t}x($width-6)),$self->{borders}->{$style}->{tr}],
            @$grid,
            [$self->{borders}->{$style}->{bl},($self->{borders}->{$style}->{b}x($width-6)),$self->{borders}->{$style}->{br}],];
    return $grid;
}

sub colour{
  my ($self,$fmts)=@_;
  return "" unless $fmts;
  my @formats=map {lc $_} split / +/,$fmts;  
  return join "",map {defined $self->{colours}->{$_}?"\033[$self->{colours}->{$_}m":""} @formats;
}

sub paint{
    my ($self,$txt,$fmt)=@_;
    return "" unless $txt;
    return $txt unless $fmt;
    return $self->colour($fmt).$txt. $self->colour("reset") ;
}

sub stripColours{
  my ($self,$line)=@_;
  return "" unless defined $line;
  $line=~s/\033\[[^m]+m//g;
  return $line;
}

sub clearScreen{
    system($^O eq 'MSWin32'?'cls':'clear');
}

sub printGrid{
    my ($self,$grid)=@_;
    foreach (@{$grid}){
        print @$_,"\n";
    }
}    

sub printAt{
  my ($self,$row,$column,@textRows)=@_;
  @textRows = @{$textRows[0]} if ref $textRows[0];  
  my $blit="\033[?25l";
  $blit.= defined $_?("\033[".$row++.";".$column."H".(ref $_?join("",grep (defined,@$_)):$_)):"" foreach (@textRows) ;
  print $blit;
  print "\n"; # seems to flush the STDOUT buffer...if not then set $| to 1 
};


sub splash{
    my $self=shift;

    my @splash=qw/
██████╗░░█████╗░███████╗██╗░░░░░██╗░░░░░░█████╗░
██╔══██╗██╔══██╗██╔════╝██║░░░░░██║░░░░░██╔══██╗
██║░░██║██║░░██║██║░░░░░██║░░░░░██║░░░░░██║░░██║
██████╔╝███████║█████╗░░██║░░░░░██║░░░░░███████║
██╔═══╝░██╔══██║██╔══╝░░██║░░░░░██║░░░░░██╔══██║
██║░░░░░██║░░██║██║░░░░░██║░░░░░██║░░░░░██║░░██║
██║░░░░░██║░░██║███████╗███████╗███████╗██║░░██║
╚═╝░░░░░╚═╝░░╚═╝╚══════╝╚══════╝╚══════╝╚═╝░░╚═╝
T_h_e__P_e_r_l__S_u_p_e_r_C_a_l_e_n_d_a_r__A_p_p
/;
my @rowColours=qw/red red yellow yellow yellow red red blue white/;
my $ci=0;
@splash=map{$self->colour($rowColours[$ci++]).$_.colour("reset")}@splash;
print colour("reset");
foreach my $step (0..$self->{windowWidth}/2+30){
    foreach (0..$#splash){
        $self->printAt($self->{windowHeight}/2-3+$_,$self->{windowWidth}-$step,substr($splash[$_],0,3*$step)."   ");
        $step++ unless ($self->{windowWidth}/2+30-$step)<=0;     # creates a slanting text until last position
    }
    $self->printAt($self->{windowHeight}/2+6,0,"                                     ");

    select(undef, undef, undef, 0.01);
}
sleep 2;
}

1;

__DATA__
