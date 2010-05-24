package Log::Syslog::Fast;

use 5.008005;
use strict;
use warnings;

require Exporter;
use Log::Syslog::Constants ();

our $VERSION = '0.31_01';

our @ISA = qw(Log::Syslog::Constants Exporter);

use constant {
    # protocols
    LOG_UDP         => 0, # UDP
    LOG_TCP         => 1, # TCP
    LOG_UNIX        => 2, # UNIX socket
};

our %EXPORT_TAGS = (
    protos => [qw/ LOG_TCP LOG_UDP LOG_UNIX /],
    %Log::Syslog::Constants::EXPORT_TAGS,
);
push @{ $EXPORT_TAGS{'all'} }, @{ $EXPORT_TAGS{'protos'} };

our @EXPORT_OK = @{ $EXPORT_TAGS{'all'} };
our @EXPORT = qw();

sub AUTOLOAD {
    (my $meth = our $AUTOLOAD) =~ s/.*:://;
    if (Log::Syslog::Constants->can($meth)) {
        return Log::Syslog::Constants->$meth(@_);
    }
    die "Undefined subroutine $AUTOLOAD";
}

require XSLoader;
XSLoader::load('Log::Syslog::Fast', $VERSION);

1;
__END__

=head1 NAME

Log::Syslog::Fast - Perl extension for sending syslog messages over TCP, UDP,
or UNIX sockets with minimal CPU overhead.

=head1 SYNOPSIS

  use Log::Syslog::Fast ':all';
  my $logger = Log::Syslog::Fast->new(LOG_UDP, "127.0.0.1", 514, LOG_LOCAL0, LOG_INFO, "mymachine", "logger");
  $logger->send("log message", time);

=head1 DESCRIPTION

This module sends syslog messages over a network socket. It works like
L<Sys::Syslog> in setlogsock's 'udp', 'tcp', or 'unix' modes, but without the
significant CPU overhead of that module when used for high-volume logging. Use
of this specialized module is only recommended if 1) you must use network
syslog as a messaging transport but 2) need to minimize the time spent in the
logger.

This module supercedes the less general L<Log::Syslog::UDP>.

=head1 METHODS

=over 4

=item Log::Syslog::Fast-E<gt>new($proto, $hostname, $port, $facility, $severity, $sender, $name);

Create a new Log::Syslog::Fast object with the following parameters:

=over 4

=item $proto

The transport protocol: one of LOG_TCP, LOG_UDP, or LOG_UNIX.

If LOG_TCP or LOG_UNIX is used, calls to $logger-E<gt>send() will block until
remote receipt of the message is confirmed. If LOG_UDP is used, the call will
never block and may fail if insufficient buffer space exists in the network
stack.

=item $hostname

For LOG_TCP and LOG_UDP, the destination hostname where a syslogd is running.
For LOG_UNIX, the path to the UNIX socket where syslogd is listening (typically
/dev/log).

=item $port

For LOG_TCP and LOG_UDP, the destination port where a syslogd is listening,
usually 514. Ignored for LOG_UNIX.

=item $facility

The syslog facility constant, eg 16 for 'local0'. See RFC3164 section 4.1.1 (or
E<lt>sys/syslog.hE<gt>) for appropriate constant values. See L<EXPORTS> below
for making these available by name.

=item $severity

The syslog severity constant, eg 6 for 'info'. See RFC3164 section 4.1.1 (or
E<lt>sys/syslog.hE<gt>) for appropriate constant values. See L<EXPORTS> below
for making these available by name.

=item $sender

The originating hostname. Sys::Hostname::hostname is typically a reasonable
source for this.

=item $name

The program name or tag to use for the message.

=back

=item $logger-E<gt>send($logmsg, [$time])

=item $logger-E<gt>emit($logmsg, [$time])

Send a syslog message through the configured logger. If $time is not provided,
CORE::time() will be called for you. That doubles the syscalls per message, so
try to pass it if you're already calling time() yourself.

B<emit> is an alias for B<send>.

=head3 NEWLINE CAVEAT

Note that B<send> does not add any newline character(s) to its input. You will
certainly want to do this yourself for TCP connections, or the server will not
treat each message as a separate line. However with UDP the server should
accept a message without a trailing newline (though some implementations may
have difficulty with that).

=item $logger-E<gt>set_receiver($hostname, $port)

Change the destination host and port. This will force a reconnection in LOG_TCP
or LOG_UNIX mode.

=item $logger-E<gt>set_priority($facility, $severity)

Change the syslog facility and severity.

=item $logger-E<gt>set_sender($sender)

Change what is sent as the hostname of the sender.

=item $logger-E<gt>set_name($name)

Change what is sent as the name of the sending program.

=item $logger-E<gt>set_pid($name)

Change what is sent as the process id of the sending program.

=back

=head1 EXPORTS

Use Log::Syslog::Constants to export priority constants, e.g. LOG_INFO.

=head1 SEE ALSO

L<Log::Syslog::Constants>

L<Sys::Syslog>

=head1 AUTHOR

Adam Thomason, E<lt>athomason@sixapart.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Six Apart, Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
