#!/usr/bin/env perl

use strict;use warnings;
use Data::Dumper;
my $calendar=loadICS();
sub loadICS{
	my $icsFile=shift;
	our $calendar={events=>[],};
	our @levels;
	my $lastLine="";
	our $item={};
	while  (my $line=<DATA>){
	   chomp $line;
	   if($lastLine eq ""){
		   $lastLine = $line;
	   }
	   elsif ($line=~/^\s/){
		   $lastLine.=$line;
		   parseLine($lastLine);
		}
		else{
			parseLine($lastLine);
			$lastLine=$line;
		}
	}
	print $lastLine;	   
	sub parseLine{
		my $line=shift;
		 if ($line=~/^BEGIN:V(.*)$/){
			 push @levels,$1;
			 return;
		 }
		 elsif ($line=~/^END:V(.*)$/){                          # end of section 
			 if ($levels[-1]=~/EVENT/){
				push @{$calendar->{events}},{%$item} if %$item;
				$item={};
			}
			pop @levels;
		}
		elsif ($levels[-1]=~/EVENT/){
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;\:]+)?(\:.*)$/);
			$item->{$parts[0]}=substr $parts[-1],1 if $parts[0];;
		}
		elsif ($levels[-1]=~/CALENDAR/){
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
			$calendar->{$parts[0]}=substr $parts[-1],1 if $parts[0];;
		}
		else{
			$item->{$levels[-1]}//={};
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
			$item->{$levels[-1]}->{$parts[0]}=substr $parts[-1],1 if $parts[0];;
		}
	}
	return $calendar
}
print Dumper $calendar;

__DATA__
BEGIN:VCALENDAR
PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
VERSION:2.0
BEGIN:VTIMEZONE
TZID:Europe/Berlin
X-LIC-LOCATION:Europe/Berlin
BEGIN:DAYLIGHT
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
TZNAME:CEST
DTSTART:19700329T020000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3
END:DAYLIGHT
BEGIN:STANDARD
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
TZNAME:CET
DTSTART:19701025T030000
RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10
END:STANDARD
END:VTIMEZONE
BEGIN:VEVENT
CREATED:20140107T092011Z
LAST-MODIFIED:20140107T121503Z
DTSTAMP:20140107T121503Z
UID:20f78720-d755-4de7-92e5-e41af487e4db
SUMMARY:Just a Test
DTSTART;TZID=Europe/Berlin:20140102T110000
DTEND;TZID=Europe/Berlin:20140102T120000
X-MOZ-GENERATION:4
DESCRIPTION:Here is a new Class:
END:VEVENT
END:VCALENDAR
