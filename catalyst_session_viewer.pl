#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use DBI;
use SQL::Abstract;

use MIME::Base64;
use Storable qw/thaw/;
use Data::Dumper;

$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 1;

sub main {
    my $is_list = 0;

    my $database = $ENV{PGDATABASE};
    my $host     = $ENV{PGHOST};
    my $user     = $ENV{PGUSER};
    my $table    = 'catalyst_plugin_session';
    my $password;
    my $key;

    my $session;

    GetOptions(
        'database=s' => \$database,
        'host=s'     => \$host,
        'user=s'     => \$user,
        'table=s'    => \$table,
        'password=s' => \$password,
        'key=s'      => \$key,
        'list'       => \$is_list,
        'session=s'  => \$session,
    );


    unless(defined $session){
        print "please set session -s\n";
        exit 1;
    }

    my $dbh = DBI->connect("dbi:Pg:database=$database;host=$host", $user, $password) 
        or die "database connect error [ dbi:Pg:database=$database;host=$host ]\nuser $user\npassword $password";


    my $sql = SQL::Abstract->new;

    # key一覧表示
    my ($stmt, @bind) = $sql->select($table, ['session_data'], { id => mk_session_key($session) });
    my $sth = $dbh->prepare($stmt);
    $sth->execute(@bind);
    my $rs = $sth->fetchrow_arrayref();

    unless ( $rs ) {
        printf "レコードが見つかりませんでした( session_id: $session )\n";
        exit 0;
    }
    my $session_data = thaw( decode_base64($rs->[0]));

    if ( $is_list ) {
        print join("\n", keys %{$session_data}). "\n";
    } else {

        if( defined $key ) {
            print Dumper(
                {
                    map  { $_ => $session_data->{$_} }
                    grep { $_ =~ $key }
                    keys %$session_data
                }
            );
        } else {
            print Dumper($session_data);
        }
    }
}


sub mk_session_key {
    my ($session) = @_;
    return "session:$session";
}

main();
