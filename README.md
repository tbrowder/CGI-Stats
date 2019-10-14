# CGI Statistics

Use CGI variables, and the Raku programming language, to keep website
visit statistics

**(Note: This solution set is for my long-running Apache web server
running multiple virtual hosts. A similar solution set should be
available using other web servers, but that is left as an exercise for
others.  Pull requests are welcome!)**

## Anonymous website visits

Use the Raku programming language, and an SQLite database, to record
anonymous website visits. The recording algorithms attempt to reject
web crawlers and other drive-by visitors which exaggerate a website's
"popularity" when using website counters commonly found in the early
days of the Internet.

## Known-user website visits

Additionally, track specific users when they access the site via a TLS
client certificate that includes their e-mail address.

The specific use case is for my college class
[website](https://usafa-1965.org) which uses TLS client certificates
to access a classmates-only
[restricted](https://usafa-1965.org/login/index.shtml) area.

## Details

The system requires several CGI programs and supporting modules, all
written in Raku.  Also required is an SQLite database to keep the
data. One interface to the Internet is via the **Server Side
Includes** (SSI) interface in the `<head>` section of the home page's
`index.shtml` file. Such an interface line looks something like this:

    <!--#virtual="/path/to/cgi-stats.raku.cgi update" -->

That line executes the "virtual" program `cgi-stats.raku.cgi` with
option `update` every time the page is accessed, and that program
updates the database.  In order to allow the visitor to see the
current statistics we provide another interface via an href in the
`<body>` section with a link that calls the same program with another
option. For example:

    <a href="/path/to/cgi-stats.raku.cgi show">Site Statistics</a>

## Files

## Directory structure

## References

1. [SQLite](https://sqlite.org)
2. [Apache SSI](https://httpd.apache.org/docs/2.4/howto/ssi.html)
3. [Apache CGI](https://httpd.apache.org/docs/2.4/howto/cgi.html)
4. [Raku](https://raku.org)

AUTHOR
======

Tom Browder, `<tom.browder@gmail.com>`

COPYRIGHT & LICENSE
===================

Copyright (c) 2019 Tom Browder, all rights reserved.

This program is free software; you can redistribute it or modify
it under the same terms as Perl 6 itself.

See that license [here](./LICENSE).
