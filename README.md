# Paella

Objective is to create a general purpose calendar application in pure perl for the terminal.  A monolithic application, i.e one that is standaolne without any dependencies.  It has  slimmed down versions of DateTime (to work only on YYYYMMDD format dates), Term::ANSIColor, and Term::ReadKey, all built into this single file applicaton.  A version may be made using above dependencies if felt necessary.

* Minimal dependencies
* Customisable (yearview, month view, show week number done in Version 0.01)
* Highlightable (done in Version 0.03)
* Import ICS files and appropriate highlighting (done in version 0,05)
* Interactive calendar  (done in version 0.04)
* Create iCAL files (TODO)
* Year views and month views (TODO)

### Version 0.05

Now uses an ultra-simple ics importer to load dates from an ics file and populates the calendar with these.

* a date index, indexes events by date (surprise)
* Navigating to date displays event name(s) below the calendar coloured as defined when loading ics file
* Multiple ics files may be loaded each with a different colour.
* When a date has events in multiple calendars the colour of the date in the calendar depends on the last calendar imported (of course).

  ![calendar](https://github.com/saiftynet/Calendar/assets/34284663/7a8df133-2a94-46f1-a67f-2fe864c13c2c)



### Version 0.04

`paella` now has interactivity, allowing navigation through days/month years.

* Key detection and action (arrow keys = change days,page up/page down=change months, tab/shift tab = change years
* Simple Calendar arithmetic
* Blinking of current focus of date
* Inverted is todays date
* Randomly generated (for now) date heighlighting;
 
### Version 0.03

The application has been renamed `paella`.

* Dependency on DateTime removed (no extrernal modules required: this will be a monolithic, single file application)
* Decorations added, including borders
* Colours, blinking, underlining etc
* Calendars can be placed anywhere in the terminal window. (May eventually become a Term::Graille Widget)


  ![image](https://github.com/saiftynet/Calendar/assets/34284663/c00a2841-755a-44e8-a896-24cbfaec07b5)

  

### Version 0.01

* Print custosimable month and year calendars
* Experimental ways to colour dates
* A month is a 7/8 X 8 by grid with 3 characters in each
* Customisable horizontal and vertical spacing.
* [Blog introducing this project](https://blogs.perl.org/users/saif/2024/05/making-a-super-cal-if-rage-will-stick-ex-paella-down-us.html)

![Version 0.01](https://github.com/saiftynet/dummyrepo/blob/main/Calendar/cal%20v0.01.png))


