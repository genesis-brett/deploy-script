#!/usr/bin/expect
# AUTHOR: teddy.c@gen-game.com
# VERSION: 1.10 2017-06-05 added interact mode, and bug fix for handling host authenticity prompt
#
# HOW TO USE
# sshloop [username] [cmd] [host1 [host2] ...]
# sshloop genesis-teddy 'sudo bash -c "whoami;ls ~/"' 10.200.18.25 10.200.18.26
# sshloop [username] [-interact] [cmd] [host1 [host2] ...]
# sshloop genesis-teddy -interact 'sudo bash' 10.200.18.38 10.200.18.39


# ssh timeout
set ssh_timeout 10


# increase the match buffer from the default (2000)
match_max 4000

set username [lindex $argv 0]
# set the command from the 2nd argument, trimming any leading space which can cause issues
set cmd1 [string trimright [ string trimleft [lindex $argv 1] ] ]
if {$cmd1 == "-interact"} {
    set interactx 1
    set cmd1 [string trimright [ string trimleft [lindex $argv 2] ] ]
} else {
    set interactx 0
}

# number of hosts
set num [llength $argv]
set index 2
if {$interactx == 1} {
    incr index
}
# account for 0-based counting
incr num -1

set timeout -1
# get the password (once!)
stty -echo
send_user "enter user password: "
expect_user -re "(.*)\n"
# assign password to variable
send_user "\n"
set passwd $expect_out(1,string)
stty echo


for {} {$index <= $num} {incr index} {
    set host [lindex $argv $index]
    send_user ">>>>>>>> starting with $host <<<<<<<<\n\n"
    spawn ssh -l $username $host
    set timeout $ssh_timeout
    expect {
        # this has to have \\ to escape the parens
        -re "\\(yes/no\\)\\? " {
            send -- "yes\r"
            expect -re ".*assword: " {
                send -- "$passwd\r"
            }
        }
        -re "(timed out)|(timeout)" {
            continue
        }
        -re ".*assword: " {
            send -- "$passwd\r"
        }
    }

    set timeout -1
    # we expect a prompt when we are logged in successfully
    expect -re "\\\$ $"
    send -- "$cmd1\r"
    # we handle the sudo prompt if needed
    expect {
        -re "sudo.*assword.*: " {
            send -- "$passwd\r"
        }
        # remember that TCL will have to translate the string first
        # "\\\$ $" is interpreted by TCL, and expect is passed "\$ $"
        # here, we have executed the cmd and ready to move to the next host
        -re "\\\$ $" {
            if {$interactx == 1} {
                interact
            }
            send_user "\n>>>>>>>> done with $host <<<<<<<<\n"
            continue
        }
    }
    # when sudo has been called, this is where you end up in
    expect {
        -re "# $" {}
        -re "\\\$ $"
    }
    if {$interactx == 1} {
        interact
    }
    send_user "\n>>>>>>>> done with $host x <<<<<<<<\n"
}