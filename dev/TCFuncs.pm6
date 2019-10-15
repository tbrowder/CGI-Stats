unit module TCFuncs;

sub get-datehour is export {
    # desired format: yyyymmddhh [UTC]
    my $dt = DateTime.now.utc;
    my $y = $dt.year;
    my $m = $dt.month;
    my $d = $dt.day;
    my $h = $dt.hour;
    my $dh = sprintf "%04d%02d%02d%02d", $y, $m, $d, $h;
    return $dh;
}

# CGI envvars of interest
# same as table column names
our %cgivars is export = set <
    HTTPS
    HTTP_HOST
    HTTP_REFERER
    HTTP_USER_AGENT
    QUERY_STRING
    REMOTE_ADDR
    REQUEST_SCHEME
    REQUEST_URI
    SERVER_ADDR
    SERVER_NAME
    SSL_CLIENT_S_DN_Email
    SSL_TLS_SNI
>;

# domain to column mapping
# this should be auto-generated
# from my namecheap tools
# put in separate module
our %dom-list is export = %(
    'nwflug.org' => 'nwflug_org',
);

our $data is export = q:to/HERE/;
CREATE TABLE IF NOT EXISTS data (
    datehour              text,
    HTTPS                 text,
    HTTP_HOST             text,
    HTTP_REFERER          text,
    HTTP_USER_AGENT       text,
    QUERY_STRING          text,
    REMOTE_ADDR           text,
    REQUEST_SCHEME        text,
    REQUEST_URI           text,
    SERVER_ADDR           text,
    SERVER_NAME           text,
    SSL_CLIENT_S_DN_Email text,
    SSL_TLS_SNI           text
);
HERE

our $qstring is export = q:to/HERE/;
INSERT INTO data (
    datehour              , -- 1
    HTTPS                 , -- 2
    HTTP_HOST             , -- 3
    HTTP_REFERER          , -- 4
    HTTP_USER_AGENT       , -- 5
    QUERY_STRING          , -- 6
    REMOTE_ADDR           , -- 7
    REQUEST_SCHEME        , -- 8
    REQUEST_URI           , -- 9
    SERVER_ADDR           , -- 10
    SERVER_NAME           , -- 11
    SSL_CLIENT_S_DN_Email , -- 12
    SSL_TLS_SNI)            -- 13
VALUES (?,?,?,?,?,
        ?,?,?,?,?,
        ?,?,?);
HERE
