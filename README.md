# CGI Statistics

Use CGI variables, and the Raku programming language, to keep website visit sttaistics

## Anonymous website visits

Use the Raku programming language, and an SQLite database, to record
anonymous website visits. The recording algorithms attempt to reject
web crawlers and other drive-by visitors which exaggerate a website's
"popularity" using website counters as used in the early days of
the Internet.

## Known-user website visits

Additionally, track specific users when they access the site via a TLS client
certificate that includes their e-mail address.

The specific use case is for my college class [website](https://usafa-1965.org)
which uses TLS client certificates to access a classmates-only restricted area.
