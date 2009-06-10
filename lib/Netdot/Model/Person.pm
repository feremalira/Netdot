package Netdot::Model::Person;

use base 'Netdot::Model';
use Digest::SHA qw(sha256_base64);
use warnings;
use strict;

=head1 NAME

Netdot::Model::Person - Manipulate Person objects

=head1 SYNOPSIS
    
    $person->verify_passwd($pass);
    
=cut

my $logger = Netdot->log->get_logger('Netdot::Model');

=head1 INSTANCE METHODS
=cut

##################################################################
=head2 verify_passwd - Verify password for this person

  Arguments:
    Plaintext password
  Returns:
    True or False
  Example:
    if ( $person->verify_passwd($plaintext) ){
    ...

=cut
sub verify_passwd {
    my ($self, $plaintext) = @_;

    return 1 if ( sha256_base64($plaintext) eq $self->password );
    return 0;
}

##################################################################
=head2 get_allowed_objects

    'Allowed' objects are objects for which this Person, or a group
    to which this Person belongs, has access rights, either RO or RW.

  Arguments:
    None
  Returns:
    Hashref
  Example:
    my $hashref = $person->get_allowed_objects();

=cut
sub get_allowed_objects {
    my ($self, %argv) = @_;
    
    my $id  = $self->id;
    my $dbh = $self->db_Main();

    my %results;

    my $gq  = "SELECT  accessright.object_class, accessright.object_id, accessright.access
               FROM    contact, contactlist, accessright, groupright
               WHERE   contact.person=$id
                   AND contact.contactlist=contactlist.id
                   AND groupright.contactlist=contactlist.id
                   AND groupright.accessright=accessright.id";

    my $gqr = $dbh->selectall_arrayref($gq);

    my $uq = "SELECT    accessright.object_class, accessright.object_id, accessright.access
              FROM      accessright, userright 
              WHERE     userright.person=$id 
                 AND    userright.accessright=accessright.id";

    my $uqr = $dbh->selectall_arrayref($uq);

    foreach my $row ( @$gqr, @$uqr ){
	my ($oclass, $oid, $access) = @$row;
	$results{$oclass}{$oid}{$access} = 1;
    }
    return \%results;
}

##################################################################
# PRIVATE METHODS
##################################################################

##################################################################
# Stores a SHA-256 base64-encoded digest of given password 
#
sub _encrypt_passwd { 
    my ($self) = @_;
    my $plaintext = ($self->_attrs('password'))[0];
    my $digest = sha256_base64($plaintext);
    $self->_attribute_store(password=>$digest);  
    return 1;
}

__PACKAGE__->add_trigger( deflate_for_create => \&_encrypt_passwd );
__PACKAGE__->add_trigger( deflate_for_update => \&_encrypt_passwd );


=head1 AUTHORS

Carlos Vicente, C<< <cvicente at ns.uoregon.edu> >> 

=head1 COPYRIGHT & LICENSE

Copyright 2009 University of Oregon, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut

# Make sure to return 1
1;
