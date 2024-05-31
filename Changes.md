### Version 0.07
* Adds a splash routine
* Adds modes of views with corresponding set of key actions
* protoype month view mode (use '#' key to change modes)


### Version 0.06

* Now detects terminal window size changes and displays the number of months that fit
* Keeps current month visible during navigation
* Shows summaries for the current date derived from loaded calendar files.
* Loads multiple ICS files from a given directory

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


![Version 0.01](https://github.com/saiftynet/dummyrepo/blob/main/Calendar/cal%20v0.01.png))
