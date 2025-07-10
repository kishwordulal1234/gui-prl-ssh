#!/usr/bin/perl

use strict;
use warnings;
use Net::OpenSSH;
use Tk;
use Tk::ROText; # For read-only text output
use Tk::ComboBox; # For command history dropdown
use Tk::Checkbutton; # For checkboxes
use Tk::FileDialog; # For file selection dialog
use Term::ReadKey; # For secure password input (though Tk might handle this differently)
use Time::HiRes qw(alarm); # For connection timeout
use File::Basename; # For handling file paths

# Create the main window
my $mw = MainWindow->new;
$mw->title("Perl SSH Login GUI");
$mw->geometry("650x550"); # Slightly larger window

# Global variable for SSH object to allow clean disconnect on exit
my $ssh_connection;

# Protocol for clean exit on window close
$mw->protocol('WM_DELETE_WINDOW' => sub {
    if (defined $ssh_connection && $ssh_connection->connected) {
        # Net::OpenSSH does not have a 'disconnect' method. The connection is implicitly closed
        # when the $ssh object goes out of scope or the script exits.
        # Explicitly undefining it helps with resource management.
        $ssh_connection = undef; # Clear global reference
        print STDERR "Disconnected cleanly on exit.\n";
    }
    exit;
});

# --- Input Fields ---
# Host
$mw->Label(-text => "SSH Host:")->pack(-side => 'top', -anchor => 'w', -padx => 10);
my $host_var = $mw->Entry(-width => 40)->pack(-side => 'top', -pady => 2, -fill => 'x', -padx => 10);
$host_var->insert('end', 'your_ssh_host'); # Default value

# Username
$mw->Label(-text => "SSH Username:")->pack(-side => 'top', -anchor => 'w', -padx => 10);
my $user_var = $mw->Entry(-width => 40)->pack(-side => 'top', -pady => 2, -fill => 'x', -padx => 10);
$user_var->insert('end', 'your_username'); # Default value

# Port
$mw->Label(-text => "SSH Port (default: 22):")->pack(-side => 'top', -anchor => 'w', -padx => 10);
my $port_var = $mw->Entry(-width => 40)->pack(-side => 'top', -pady => 2, -fill => 'x', -padx => 10);
$port_var->insert('end', '22'); # Default value

# Identity File
my $identity_frame = $mw->Frame()->pack(-side => 'top', -pady => 2, -fill => 'x', -padx => 10);
$identity_frame->Label(-text => "Identity File (e.g., ~/.ssh/id_rsa):")->pack(-side => 'left', -anchor => 'w');
my $identity_file_var = $identity_frame->Entry(-width => 30)->pack(-side => 'left', -expand => 1, -fill => 'x', -padx => 5);
my $browse_button = $identity_frame->Button(
    -text => "Browse...",
    -command => sub {
        my $file_dialog = $mw->FileDialog(-Title => "Choose SSH Key");
        my $selected_file = $file_dialog->Show;
        if ($selected_file) {
            $identity_file_var->delete(0, 'end');
            $identity_file_var->insert('end', $selected_file);
        }
    }
)->pack(-side => 'right');

# Password
my $password_frame = $mw->Frame()->pack(-side => 'top', -pady => 2, -fill => 'x', -padx => 10);
$password_frame->Label(-text => "Password:")->pack(-side => 'left', -anchor => 'w');
my $password_var = $password_frame->Entry(-width => 40, -show => '*')->pack(-side => 'left', -expand => 1, -fill => 'x', -padx => 5);

# Key-Only Authentication Checkbox
my $key_only_auth_var = $mw->Checkbutton(
    -text => "Key-Only Authentication (Disable Password)",
    -command => sub {
        if ($key_only_auth_var->get) {
            $password_var->configure(-state => 'disabled');
            $password_var->delete(0, 'end'); # Clear password if key-only is checked
        } else {
            $password_var->configure(-state => 'normal');
        }
    }
)->pack(-side => 'top', -pady => 5, -anchor => 'w', -padx => 10);

# Keep Connection Alive Checkbox
my $keep_alive_var = $mw->Checkbutton(
    -text => "Keep Connection Alive (Don't disconnect after command)",
)->pack(-side => 'top', -pady => 2, -anchor => 'w', -padx => 10);

# Global array for command history
my @command_history = ('ls -la', 'whoami', 'pwd'); # Initial default commands

# Command to Execute (ComboBox for history)
$mw->Label(-text => "Command to Execute:")->pack(-side => 'top', -anchor => 'w', -padx => 10);
my $command_var = $mw->ComboBox(
    -textvariable => \$command_history[0], # Bind to the first element initially
    -values => \@command_history,
    -width => 40,
    -editable => 1, # Allow typing new commands
)->pack(-side => 'top', -pady => 2, -fill => 'x', -padx => 10);

# --- Output Area with Scrollbar ---
my $output_frame = $mw->Frame()->pack(-side => 'bottom', -pady => 10, -padx => 10, -fill => 'both', -expand => 1);
my $scrollbar = $output_frame->Scrollbar(-orient => 'vertical');
my $output_text = $output_frame->ROText(
    -width => 70,
    -height => 15,
    -wrap => 'word',
    -font => '{Consolas} 10',
    -yscrollcommand => ['set', $scrollbar],
);
$scrollbar->configure(-command => ['yview', $output_text]);
$scrollbar->pack(-side => 'right', -fill => 'y');
$output_text->pack(-side => 'left', -fill => 'both', -expand => 1);


# --- Status Label ---
my $status_label = $mw->Label(-text => "Ready", -relief => 'sunken', -anchor => 'w')->pack(-side => 'bottom', -fill => 'x', -padx => 5, -pady => 2);

# --- Buttons ---
my $button_frame = $mw->Frame()->pack(-side => 'top', -pady => 10);

my $connect_button = $button_frame->Button(
    -text => "Connect & Execute",
    -command => sub { connect_and_execute() }
)->pack(-side => 'left', -padx => 5);

my $clear_button = $button_frame->Button(
    -text => "Clear Output",
    -command => sub { $output_text->delete('1.0', 'end'); }
)->pack(-side => 'left', -padx => 5);

# --- SSH Connection Logic ---
sub connect_and_execute {
    # Disable button during operation
    $connect_button->configure(-state => 'disabled');

    # Check if connection should be kept alive and is already active
    if ($keep_alive_var->get && defined $ssh_connection && $ssh_connection->connected) {
        $output_text->insert('end', "[" . localtime() . "] Using existing connection to " . $ssh_connection->host . "...\n\n");
        $output_text->see('end');
        $status_label->configure(-text => "Status: Using existing connection");
        # Skip connection logic, proceed directly to command execution
    } else {
        # Clear previous output only if establishing a new connection
        $output_text->delete('1.0', 'end');
        $output_text->insert('end', "WARNING: Password entered in GUI is stored in memory and not zeroized. For better security, use key-based authentication.\n\n");
        $status_label->configure(-text => "Status: Connecting...");

        my $host = $host_var->get;
        my $user = $user_var->get;
        my $port = $port_var->get;
        my $identity_file = $identity_file_var->get;
        my $password = $password_var->get;
        my $command = $command_var->get;

        # Input Sanitization and Validation
        unless ($host =~ /^[a-z0-9.\-]+$/i) {
            $output_text->insert('end', "[" . localtime() . "] Error: Invalid SSH Host format.\n");
            $output_text->see('end'); # Scroll to end
            $status_label->configure(-text => "Status: Error - Invalid Host");
            $connect_button->configure(-state => 'normal'); # Re-enable button
            return;
        }
        unless ($user =~ /^[a-z0-9_\-]+$/i) {
            $output_text->insert('end', "[" . localtime() . "] Error: Invalid SSH Username format.\n");
            $output_text->see('end'); # Scroll to end
            $status_label->configure(-text => "Status: Error - Invalid Username");
            $connect_button->configure(-state => 'normal'); # Re-enable button
            return;
        }
        unless ($port =~ /^\d{1,5}$/ && $port >= 1 && $port <= 65535) {
            $output_text->insert('end', "[" . localtime() . "] Error: Invalid SSH Port. Must be a number between 1 and 65535.\n");
            $output_text->see('end'); # Scroll to end
            $status_label->configure(-text => "Status: Error - Invalid Port");
            $connect_button->configure(-state => 'normal'); # Re-enable button
            return;
        }

        $output_text->insert('end', "[" . localtime() . "] Attempting to connect to $user\@$host:$port...\n");
        $output_text->see('end'); # Scroll to end
        $output_text->update; # Update GUI immediately
        $status_label->configure(-text => "Status: Connecting to $host...");

        my %ssh_options = (
            port    => $port,
            user    => $user,
            timeout => 10, # Net::OpenSSH's internal timeout
            # master_opts => [-o => "StrictHostKeyChecking=no"], # Uncomment for testing, but not recommended for production
        );

        if ($identity_file) {
            $ssh_options{identity_file} = $identity_file;
        }

        # If key-only is checked, do not provide password option
        if ($key_only_auth_var->get) {
             delete $ssh_options{password};
        } else {
             $ssh_options{password} = $password;
        }


        my $ssh;
        my $connection_error;

        # Connection Timeout Fallback and Catch
        eval {
            local $SIG{ALRM} = sub { die "Connection timeout\n" };
            alarm 5; # Set a 5-second alarm for the initial connection attempt
            $ssh = Net::OpenSSH->new($host, %ssh_options);
            alarm 0; # Clear the alarm if connection is successful
        };
        if ($@) {
            $connection_error = $@;
            chomp $connection_error;
            $output_text->insert('end', "[" . localtime() . "] Connection attempt timed out: $connection_error\n");
            $output_text->see('end'); # Scroll to end
            $output_text->update;
        }

        # If initial connection failed (either by timeout or Net::OpenSSH error)
        unless ($ssh) {
            $connection_error = $Net::OpenSSH::error || $connection_error; # Prefer Net::OpenSSH error if available

            if ($identity_file && $connection_error !~ /timeout/) { # If identity file was used and it wasn't a timeout
                $output_text->insert('end', "[" . localtime() . "] Warning: Key-based authentication failed or connection error: " . $connection_error . "\n");
                $output_text->insert('end', "[" . localtime() . "] Attempting password authentication as fallback.\n");
            } elsif ($connection_error) { # General connection error
                $output_text->insert('end', "[" . localtime() . "] Connection error: " . $connection_error . "\n");
            }
            $output_text->see('end'); # Scroll to end
            $output_text->update;
            $status_label->configure(-text => "Status: Connection Failed (Retrying with password)");

            # Only try password if it's provided, connection wasn't a timeout, and key-only is NOT checked
            if ($password && $connection_error !~ /timeout/ && !$key_only_auth_var->get) {
                $ssh_options{password} = $password;
                eval {
                    local $SIG{ALRM} = sub { die "Password connection timeout\n" };
                    alarm 5;
                    $ssh = Net::OpenSSH->new($host, %ssh_options);
                    alarm 0;
                };
                if ($@) {
                    $output_text->insert('end', "[" . localtime() . "] Password connection attempt timed out: $@\n");
                    $output_text->see('end'); # Scroll to end
                    $output_text->update;
                }
            }
        }

        # Final check for connection errors
        unless ($ssh) {
            $output_text->insert('end', "[" . localtime() . "] ERROR: Unable to connect to SSH after all attempts.\n");
            $output_text->see('end'); # Scroll to end
            $status_label->configure(-text => "Status: Connection Failed");
            $connect_button->configure(-state => 'normal'); # Re-enable button
            return;
        }

        # Store the active SSH connection globally for clean exit
        $ssh_connection = $ssh;

        $output_text->insert('end', "[" . localtime() . "] Successfully connected to $host as $user.\n");
        $output_text->see('end'); # Scroll to end
        $output_text->update;
        $status_label->configure(-text => "Status: Connected to $host");
    }

    # Execute command using the active connection
    my $command = $command_var->get; # Get command again in case it changed while connecting

    # Add command to history if it's new and not empty, limit to 20 entries
    if ($command && !grep { $_ eq $command } @command_history) {
        unshift @command_history, $command; # Add to the beginning
        splice(@command_history, 20) if @command_history > 20; # Limit to 20 entries
        $command_var->configure(-values => \@command_history);
        $command_var->set($command); # Set the current value in the combobox
    }


    if ($command) {
        $output_text->insert('end', "[" . localtime() . "] Executing command: '$command'\n");
        $output_text->see('end'); # Scroll to end
        $output_text->update;
        $status_label->configure(-text => "Status: Executing command...");

        my ($stdout, $stderr, $exit_code) = $ssh_connection->capture3($command); # Use capture3 for exit code

        if ($ssh_connection->error) { # Check for SSH-level errors during command execution
            $output_text->insert('end', "[" . localtime() . "] SSH Command Execution Error: " . $ssh_connection->error . "\n");
        }
        if (defined $exit_code && $exit_code != 0) {
            $output_text->insert('end', "[" . localtime() . "] Command exited with non-zero status: $exit_code\n");
        }
        if ($stderr) {
            $output_text->insert('end', "[" . localtime() . "] Command Stderr:\n", 'stderr'); # Apply stderr tag
            $output_text->insert('end', "$stderr\n");
        }
        if ($stdout) {
            $output_text->insert('end', "[" . localtime() . "] Command Stdout:\n");
            $output_text->insert('end', "$stdout\n");
        }
    } else {
        $output_text->insert('end', "[" . localtime() . "] No command specified to execute.\n");
    }
    $output_text->see('end'); # Scroll to end
    $output_text->update;
    $status_label->configure(-text => "Status: Command Executed");

    # Disconnect only if "Keep Connection Alive" is NOT checked
    unless ($keep_alive_var->get) {
        # Net::OpenSSH does not have a 'disconnect' method. The connection is implicitly closed
        # when the $ssh object goes out of scope or the script exits.
        # Explicitly undefining it helps with resource management.
        $output_text->insert('end', "[" . localtime() . "] Disconnected from " . $ssh_connection->host . ".\n");
        $output_text->see('end'); # Scroll to end
        $output_text->update;
        $ssh_connection = undef; # Clear global reference
        $status_label->configure(-text => "Status: Disconnected");
    } else {
         $status_label->configure(-text => "Status: Connection to " . $ssh_connection->host . " kept alive.");
    }


    # Password Zeroization (best effort)
    $password_var->delete(0, 'end'); # Clear from GUI
    # Overwriting the scalar is tricky in Perl, relying on undef is more standard
    # $password = 'x' x length($password); # Overwrite in memory
    undef $password; # Undefine the variable

    # Re-enable button after operation
    $connect_button->configure(-state => 'normal');
}

# Configure tag for stderr output
$output_text->tagConfigure('stderr', -foreground => 'red');


# Start the Tk event loop
MainLoop;