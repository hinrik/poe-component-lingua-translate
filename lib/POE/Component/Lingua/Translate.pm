package POE::Component::Lingua::Translate;

use strict;
use warnings;
use Carp;
use POE;
use POE::Component::Generic;

our $VERSION = '0.03';

sub new {
    my ($package, %args) = @_;
    my $self = bless \%args, $package;
    
    if (ref $self->{trans_args} ne 'HASH') {
        croak "A 'trans_args' hashref argument is required";
    }
    
    POE::Session->create(
        object_states => [
            $self => {
                # public events
                translate => '_translate',
                shutdown => '_shutdown',
            },
            $self => [ qw(_start _stop _result) ],
        ],
    );

    return $self;
}

sub _start {
    my ($session, $self) = @_[SESSION, OBJECT];
    $self->{session_id} = $session->ID();

    if ( $self->{alias} ) {
        $poe_kernel->alias_set( $self->{alias} );
    }
    else {
        $poe_kernel->refcount_increment( $self->{session_id} => __PACKAGE__ );
    }

    $self->{trans} = POE::Component::Generic->spawn(
        package        => 'Lingua::Translate',
        object_options => [ %{ $self->{trans_args} } ],
        methods        => [ qw(translate) ],
        verbose        => 1,
    );
  
    return;
}

sub _stop {
    return;
}

sub _shutdown {
    my $self = $_[OBJECT];
    $poe_kernel->alias_remove( $_ ) for $poe_kernel->alias_list();
    $poe_kernel->refcount_decrement( $self->{session_id} => __PACKAGE__ ) if !$self->{alias};
    return;
}

sub _translate {
    my ($self, $sender, $args) = @_[OBJECT, SENDER, ARG0];

    $self->{trans}->yield(
        translate =>
            {
                event => '_result',
                data => {
                    recipient => $sender->ID(),
                    context => $args->{context} || { },
                },
            },
            $args->{text},
    );
    return;
}

sub _result {
    my ($ref, $result) = @_[ARG0, ARG1];

    if ($ref->{error}) {
        # do something?
    }

    $poe_kernel->post($ref->{data}->{recipient} => translated => {
        text => $result,
        context => $ref->{data}->{context},
    });
    return;
}

sub session_id {
    my ($self) = @_;
    return $self->{session_id};
}

1;
__END__

=head1 NAME

POE::Component::Lingua::Translate - A non-blocking wrapper around
L<Lingua::Translate|Lingua::Translate>

=head1 SYNOPSIS

 use POE;
 use POE::Component::Lingua::Translate;

 POE::Session->create(
     package_states => [
         main => [ qw(_start translated) ],
     ],
 );

 $poe_kernel->run();

 sub _start {
     my $heap = $_[HEAP];
     $heap->{trans} = POE::Component::Lingua::Translate->new(
         alias => 'translator',
         trans_args => {
             back_end => 'Babelfish',
             src      => 'en',
             dest     => 'de',
         }
     );
     
     $poe_kernel->post(translator => translate => 'this is a sentence');
     return;
 }

 sub translated {
     my $result = $_[ARG0];
     print $result . "\n";
 }

=head1 DESCRIPTION

POE::Component::Lingua::Translate is a L<POE> component that provides a
non-blocking wrapper around L<Lingua::Translate|Lingua::Translate>. It accepts
C<translate> events and emits C<translated> events back.

=head1 CONSTRUCTOR

=over

=item C<new>

Takes two arguments.

'trans_args', a hashref containing arguments that will be passed to
L<Lingua::Translate|Lingua::Translate>'s constructor. This argument is required.

'alias', an optional alias for the component's session.

=back

=head1 METHODS

=over

=item C<session_id>

Takes no arguments. Returns the POE Session ID of the component.

=back

=head1 INPUT

The POE events this component will accept.

=over

=item C<translate>

Takes one argument, a string to translate. It will be passed to the
L<Lingua::Translate|Lingua::Translate> object's C<translate()> method.

=item C<shutdown>

Takes no arguments, terminates the component.

=back

=head1 OUTPUT

The POE events emitted by this component.

=over

=item C<translated>

ARG0 is the translated text, or C<undef> if the translation failed.

=back

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut