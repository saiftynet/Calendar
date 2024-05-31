# Paella

The objective of `paella.pl` is to create a general purpose calendar application in pure perl for the terminal. [Blog introducing this project](https://blogs.perl.org/users/saif/2024/05/making-a-super-cal-if-rage-will-stick-ex-paella-down-us.html) and the reason why it is called Paella instead of Super Cal.  This is a monolithic application, i.e one that is standaolne without any dependencies.  It has  slimmed down versions of DateTime (to work only on YYYYMMDD format dates), Term::ANSIColor, and Term::ReadKey, all built into this single file applicaton.  A version may be made using above dependencies if felt necessary.

* Minimal dependencies
* Customisable (yearview, month view, show week number done in Version 0.01)
* Highlightable (done in Version 0.03)
* Import ICS files and appropriate highlighting (done in version 0,05)
* Interactive calendar  (done in version 0.04)
* Create iCAL files (TODO)
* Year views and month views (TODO)

## Usage

`paella.pl` - runs the application with default parameters, loads ics files from a folder called ICS if one exists, or from current directory if one doesn't;

## Key bindings

Two modes of operation currently
```
Mode 'yearView'
		'home'      => focus on today's date;
		'rightarrow'=> move to next day,
		'leftarrow' => move to previous day,
		'uparrow'   => move to 1 week before,
		'downarrow' => move 1 week later,
		'pagedown'  => move one month later,
		'pageup'    => move back one month,
		'tab'       => move forward one year,
		'shifttab'  => mov back one year,
		'#'         => change modes,
  
Mode monthView
		'home'      => focus on today's date;
		'rightarrow'=> move to next day,
		'leftarrow' => move to previous day,
		'uparrow'   => move to 1 week before,
		'downarrow' => move 1 week later,
		'#'         => change modes,
```
The month view mode *will* show more information about the focused date

