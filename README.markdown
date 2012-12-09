# Southwest Checkin Script #

This is a command line python script that will, given a confirmation code and
passenger name, will do the following:

* Look up flight info and display when the flights leave and where they are
  going.
* Wait until 24 hours the first flight
* Drive the web site to check in all users for that reservation.
* Optionally send email with the boarding pass as an attachment
* Repeat with any unchecked in flights

If you don't have the script email you, you will still need to print your boarding pass, but you should have a decent place in line.

If southwest changes the checkin process, the script might stop working. If you see a bug, file an issue or fork and create a pull request with the fix.

## Installation ##

The easiest way to install the dependencies is with [pip](http://pypi.python.org/pypi/pip), a python package manager. It is also good practice to isolate your environment with a [virtual environment](http://www.virtualenv.org/en/latest/). If you are unfamiliar with pip or virtualenv, I would recommend reading [this](http://mirnazim.org/writings/python-ecosystem-introduction/).

    $ pip install -r requirements.txt

## Usage ##

Run the script:

    $ python sw_checkin_email.py John Doe ABC123

Run the script in the background:

    $ python sw_checkin_email.py John Doe ABC123 &

Run the script in the background and log to file:

    $ python sw_checkin_email.py John Doe ABC123 > sw_checkin_email.log 2>&1 &

Run the script in the background, log to file, and allow yourself to logout (you cannot retake ownership of this command and must use `kill` to stop it)

    $ nohup python sw_checkin_email.py John Doe ABC123 &> sw_checkin_email.log

For more expanation on these commands, you may want to read about [nohup and disown](http://www.basicallytech.com/blog/index.php?/archives/70-Shell-stuff-job-control-and-screen.html#bash_disown).
