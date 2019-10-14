# CGI Statistics

Use CGI variables, and the Raku programming language, to keep website visit statistics

(Note: This solution set is for my long-running Apache web server running multiple 
virtual hosts. A similar solution set should be available using other web servers,
but that is left as an exercise for others.  Pull requests are welcome!)

## Anonymous website visits

Use the Raku programming language, and an SQLite database, to record
anonymous website visits. The recording algorithms attempt to reject
web crawlers and other drive-by visitors which exaggerate a website's
"popularity" when using website counters commonly found in the early
days of the Internet.

## Known-user website visits

Additionally, track specific users when they access the site via a TLS client
certificate that includes their e-mail address.

The specific use case is for my college class [website](https://usafa-1965.org)
which uses TLS client certificates to access a classmates-only
[restricted](https://usafa-1965.org/login/index.shtml) area.

## Details

The system requires several CGI programs and supporting modules, all written in Raku.
Also required is an SQLite database to keep the data. The interface to the Internet
is via the virtual interface in the home page's index.shtml file. Such an interface
line looks something like this:

    <!--#virtual="/path/to/prrogram.raku.cgi" -->

That line executes the "virtual" program every time the page is accessed.
In order to allow the visitor to see the current statistics we provide
another virtual link that is activated via a click on another page.
For example:


## References

1. [SQLite](https://sqlite.org)
2. [Apache CGI](https://httpd.apache.org/2.4/docs/howto/)cgi.html
3. [Raku](https://raku.org)
