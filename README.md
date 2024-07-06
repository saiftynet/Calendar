# Paella

The objective of `paella.pl` is to create a general purpose calendar application in Pure Perl for the terminal. [Blog introducing this project](https://blogs.perl.org/users/saif/2024/05/making-a-super-cal-if-rage-will-stick-ex-paella-down-us.html) and the reason why it is called Paella.  (There are more capable calendar applications, so didnt want to be pretentious and call it "Super-Cal")  This is a monolithic application, i.e one that is standalone without any dependencies. It has  slimmed down versions of DateTime (to work only on YYYYMMDD format dates), Term::ANSIColor, and Term::ReadKey, all built into this single file applicaton.  A version may be made using above dependencies if felt necessary.

![calendar-(2)](https://github.com/saiftynet/Calendar/assets/34284663/536154ca-fbb2-40de-ad28-8f88c20a575c)


* Minimal dependencies
* Customisable (yearview, month view, show week number done in Version 0.01)
* Highlightable (done in Version 0.03)
* Import ICS files and appropriate highlighting (done in version 0,05)
* Interactive calendar  (done in version 0.04)
* Responsive to screensize changes
* Year views and month views  (done in version 0.09)
* Handle RRULES EXDATES and RDATES (started in version 0.09)
  Paella is not fine grained enough to handle Time...just dates
  Currently only deals with DAILY, MONTHLY and YEARLY, INTERVAL and COUNT, parameters
  EXDATES handled
  RDATES;PERIOD= ignored as I dont get it
* Integrated help pages (TODO)
* Week and Day views (TODO)
* Create iCAL files (TODO)

#### Year View
![image](https://github.com/saiftynet/Calendar/assets/34284663/4b157754-3318-4667-84d4-572633940eac)


#### Month View
![image](https://github.com/saiftynet/Calendar/assets/34284663/486a842e-7513-4d1b-849e-5075c062f396)

## Usage

`paella.pl` - runs the application with default parameters, loads ics files from a folder called ICS if one exists;

## Key bindings

Two modes of operation currently
```
Mode 'yearView'
		'home'      => focus on today's date;
		't'         => focus on today's date;
		'rightarrow'=> move to next day,
		'leftarrow' => move to previous day,
		'uparrow'   => move to 1 week before,
		'downarrow' => move 1 week later,
		'pagedown'  => move one month later,
		'pageup'    => move back one month,
		'tab'       => move forward one year,
		'shifttab'  => mov back one year,
		'#'         => change modes,
		'Q'         => Quits application,
  
Mode monthView
		'home'      => focus on today's date;
		't'         => focus on today's date;
		'rightarrow'=> move to next day,
		'leftarrow' => move to previous day,
		'uparrow'   => move to 1 week before,
		'downarrow' => move 1 week later,
		'#'         => change modes,
		'Q'         => Quits application,
```
The month view mode *will* show more information about the focused date


### Blog Trail

The evolution of Paella is punctuating blogs at various points in its history.

1) [Making a Super Cal if Rage Will Stick Ex Paella Down Us](https://blogs.perl.org/users/saif/2024/05/making-a-super-cal-if-rage-will-stick-ex-paella-down-us.html)
2) [Making time to waste.](https://blogs.perl.org/users/saif/2024/06/making-time-to-waste.html)
3) [Justifying Embarrassing Errors.](https://blogs.perl.org/users/saif/2024/06/justifying-embarrassing-errors.html)

