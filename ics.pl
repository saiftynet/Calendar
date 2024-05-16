#!/usr/bin/env perl
#  Test program that takes a ics file and loads it
#  into a calendar hash and also generates a cdv arrayref
#  for consumption by paella.

use strict;use warnings;
use Data::Dumper;
my $cdv=[];
my $calendar={};
my ($file,$col)=("example.ics", "red");

loadICS($file,$col);

sub loadICS{
	my ($file,$col)=@_;
	open my $ics,"<",$file;
	$calendar//={events=>[],};
	our @levels;
	my $lastLine="";
	our $item={};
	while  (my $line=<$ics>){
	   chomp $line;
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
	sub parseLine{
		my $line=shift;
		 if ($line=~/^BEGIN:V(.*)$/){
			 push @levels,$1;
			 return;
		 }
		 elsif ($line=~/^END:V(.*)$/){                          # end of section 
			 if ($levels[-1]=~/EVENT/){
				if (%$item){
					push @{$calendar->{events}},{%$item} if %$item;
					$cdv=[@$cdv,{
						  name     =>$item->{SUMMARY},
						  datestart=>substr ($item->{DTSTART},0,6),
						  format   =>$col,}];
				}
				$item={};
			}
			pop @levels;
		}
		elsif ($levels[-1]=~/EVENT/){
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;\:]+)?(\:.*)$/);
			$item->{$parts[0]}=substr $parts[-1],1 if $parts[0];
		}
		elsif ($levels[-1]=~/CALENDAR/){
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
			$calendar->{$parts[0]}=substr $parts[-1],1 if $parts[0];
		}
		else{
			$item->{$levels[-1]}//={};
			my @parts=($line=~/^([A-Z\-]+)(\;[^\;]+)*(\:.*)$/);
			$item->{$levels[-1]}->{$parts[0]}=substr $parts[-1],1 if $parts[0];
		}
	}
	close $ics;
	return $calendar
}


print Dumper $cdv;
