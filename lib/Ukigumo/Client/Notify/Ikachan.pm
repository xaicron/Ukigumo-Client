use strict;
use warnings;
use utf8;

package Ukigumo::Client::Notify::Ikachan;
use Mouse;
use Ukigumo::Constants;
use Ukigumo::Helper qw(status_str);
use String::IRC;

has 'url' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'channel' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'ignore_success' => (
    is => 'ro',
    isa => 'Bool',
    required => 0,
    default => 1,
);

has 'method' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'notice',    # you can specify 'privmsg'
);

no Mouse;

sub send {
    my ($self, $c, $status, $last_status, $report_url) = @_;

    if ( $self->ignore_success && $status eq STATUS_SUCCESS && defined($last_status) && $status eq $last_status ) {
        $c->log(
            "The test was succeeded. There is no reason to notify($status, $last_status).");
        return;
    }

    my $ua = $c->user_agent();

    my $url = $self->url;
    $url =~ s!/$!!;    # remove trailing slash

    my $message = sprintf( "%s %s [%s] %s %s",
        $report_url, $c->project, $c->branch, _status_color_message($status),
        $c->vc->get_revision() );
    $c->log("Sending message to irc server: $message");

    my $res =
        $ua->post( "$url/$self->{method}",
        { channel => $self->channel, message => $message } );
    if ( $res->is_success ) {
        $c->log("Sent notification for $self->{url} $self->{channel}");
    }
    else {
        die "Cannot send ikachan notification: "
            . join( ' ',
            'notice', $self->url, $self->channel, $res->status_line );
    }
}

sub _status_color_message {
    my $status = shift;
    my $color = $status eq STATUS_SUCCESS ? 'green'
              : $status eq STATUS_FAIL    ? 'red'
                                          : 'brown';

    String::IRC->new(status_str($status))->$color('white');
}

1;
__END__

=head1 NAME

Ukigumo::Client::Notify::Ikachan - send notification to ikachan.

=head1 DESCRIPTION

This is a notifier class for Ukigumo, send notification to ikachan server.

=head1 ATTRIBUTES

=over 4

=item url

URL of the ikachan server.

=item channel

Channel name to send a message.

=item ignore_success

Ignore the message if it's succeeded.

=item method

Sending method. It's B</notice> by default.

=back

=head1 SEE ALSO

L<App::Ikachan>


