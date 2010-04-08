=head1 NAME

VertRes::Utils::VRTrackFactory - factory class for getting VRTrack objects

=head1 SYNOPSIS

use VertRes::Utils::VRTrackFactory;

my $vrtrack = VertRes::Utils::VRTrackFactory->instantiate(database => 'mouse',
                                                          mode => 'r');

my @database_names = VertRes::Utils::VRTrackFactory->databases();

=head1 DESCRIPTION

A simple factory class that returns VRTrack objects to centralise the database
connection information.

Database host, port, username and password are set by environment variables:
VRTRACK_HOST
VRTRACK_PORT
VRTRACK_RO_USER  (for the 'r' mode read-only capable username)
VRTRACK_RW_USER  (for the 'rw' mode read-write capable username)
VRTRACK_PASSWORD

=head1 AUTHOR

Thomas Keane tk2@sanger.ac.uk

=cut

package VertRes::Utils::VRTrackFactory;
use base qw(VertRes::Base);

use strict;
use warnings;

use DBI;
use VRTrack::VRTrack;

my $HOST = $ENV{VRTRACK_HOST} || 'mcs4a';
my $PORT = $ENV{VRTRACK_PORT} || 3306;
my $READ_USER = $ENV{VRTRACK_RO_USER} || 'vreseq_ro';
my $WRITE_USER = $ENV{VRTRACK_RW_USER} || 'vreseq_rw';
my $WRITE_PASS = $ENV{VRTRACK_PASSWORD} || 't3aml3ss';


=head2 new

 Title   : instantiate
 Usage   : my $vrtrack = VertRes::Utils::VRTrackFactory->instantiate(
                                                            database => 'mouse',
                                                            mode => 'r');
 Function: Ask the factory to return a VRTrack object to the database specified.
 Returns : VRTrack object
 Args    : database name: a valid VRTrack database,
           mode: either 'r' or 'rw' connection

=cut

sub instantiate {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    my $database = $self->{database} || $self->throw("A database name must be provided!");
    my $mode = lc($self->{mode}) || $self->throw("A connection mode name must be provided!");
    
    my %details = VertRes::Utils::VRTrackFactory->connection_details($mode);
    $details{database} = $database;
    
    my $vrtrack = VRTrack::VRTrack->new({%details});
    
    return $vrtrack;
}

=head2 connection_details

 Title   : connection_details
 Usage   : my %details = VertRes::Utils::VRTrackFactory->connection_details('r');
 Function: Find out what connection details are being used to instantiate().
 Returns : hash with keys: host, port, user, password
 Args    : mode string (r|rw)

=cut

sub connection_details {
    my ($class, $mode) = @_;
    my $self = $class->SUPER::new(@_);
    
    $mode = lc($mode) || $self->throw("A connection mode name must be provided!");
    
    $self->throw("Invalid connection mode (r or rw valid): $mode\n") unless $mode =~ /^(?:r|rw)$/;
    
    my $user = $mode eq 'rw' ? $WRITE_USER : $READ_USER;
    my $pass = $mode eq 'rw' ? $WRITE_PASS : '';
    
    return (host => $HOST, port => $PORT, user => $user, password => $pass);
}

=head2 databases

 Title   : databases
 Usage   : my @db_names = VertRes::Utils::VRTrackFactory->databases();
 Function: Find out what databases are available to instantiate. Excludes any
           test databases.
 Returns : list of strings
 Args    : n/a

=cut

sub databases {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    my %dbparams = VertRes::Utils::VRTrackFactory->connection_details('r');
    
    my @databases = DBI->data_sources("mysql", \%dbparams);
    @databases = grep(s/^DBI:mysql://, @databases); 
    
    # we skip information_schema and any test databases
    @databases = grep(!/^information_schema|test/, @databases);
    
    return @databases;
}

1;
