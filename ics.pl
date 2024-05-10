#!/usr/bin/env perl
#
use strict;use warnings;
use Data::Dumper;
use DateTime;
use utf8;

binmode(STDOUT,"encoding(cp-1252)");
my $calendar={events=>[],};
my @levels;
my $item;
while  (my $line=<DATA>){
   if ($line=~/^ /){
      $item->{value}.=$line;
	  next;
   }
   if ($line=~/BEGIN:V(.*)$/){
     push @levels,$1;
	 next;
   }
   elsif ($line=~/END:V(.*)$/){
   
     if ($levels[-1]=~/EVENT/){
	    push @{$calendar->{events}},{%$item} if %$item;
		pop @levels;
		$item={};
	 }
	 else{
		pop @levels
	 }
	 next;
   }
   my $modifiers=""; my $props={};
   if ($line=~/^[^\;\:]+(\;[^\:]+)\:/){
     $modifiers=$1;
	 substr $modifiers,0,1,"";
	 my @mods=split(";",$modifiers);
	 foreach (@mods){
	    my ($key,$value)=split ("=", $_);
		$props->{$key}=$value if $key;
	 }
     $line=~s/$1//;
   }
   if ($levels[-1]=~/EVENT/){
		if ($line=~/^(DTSTART|DTEND|SUMMARY|CATEGORIES|CLASS|DESCRIPTION|LOCATION)\:(.*)$/){
	    $item->{lc $1}->{value}=$2;
		$item->{lc $1}->{properties}=$props if $modifiers;
	   }
   }
   if ($levels[-1]=~/ALARM/){
       $item->{alarm}//={};
	   if ($line=~/^(TRIGGER|DESCRIPTION|ACTION)\:(.*)$/){
	     $item->{alarm}->{lc $1}=$2;
	   }
   }
   elsif ($line=~/X-WR-CALNAME\:(.*)$/){
         $calendar->{name}=$1;
   }
}

my @sortedEvents=sort{$a->{dtstart}->{value} <=>$b->{dtstart}->{value}} @{$calendar->{events}}; 

print Dumper $calendar;

__DATA__
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Mozilla.org/NONSGML Mozilla Calendar V1.1//EN
BEGIN:VEVENT
SUMMARY:Dita e Vitit të Ri 
DTSTART;VALUE=DATE:20240101
DTEND;VALUE=DATE:20240102
DTSTAMP:20240401T090003Z
UID:albania/new-year-day-2024
CATEGORIES:Holidays
CLASS:public
DESCRIPTION:National holiday -  Dita e Vitit të Ri është dita e parë e
  vitit\, ose 1 janar\, në kalendarin gregorian.
LAST-MODIFIED:20240401T090003Z
TRANSP:transparent
END:VEVENT
BEGIN:VEVENT
SUMMARY:Dita e Vitit të Ri (Dita 2) 
DTSTART;VALUE=DATE:20240102
DTEND;VALUE=DATE:20240103
DTSTAMP:20240401T090003Z
UID:albania/second-day-new-year-2024
CATEGORIES:Holidays
CLASS:public
DESCRIPTION:National holiday -  Dita e Vitit të Ri (Dita 2) është një 
 festë kombëtare në Shqipëri
LAST-MODIFIED:20240401T090003Z
TRANSP:transparent
END:VEVENT
BEGIN:VEVENT
SUMMARY:Dita e verës 
DTSTART;VALUE=DATE:20240314
DTEND;VALUE=DATE:20240315
DTSTAMP:20240401T090003Z
UID:albania/summer-day-2024
CATEGORIES:Holidays
CLASS:public
DESCRIPTION:National holiday -  Dita e verës është një festë kombëta
 re në Shqipëri
LAST-MODIFIED:20240401T090003Z
TRANSP:transparent
END:VEVENT
END:VCALENDAR