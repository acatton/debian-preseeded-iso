Debian ISO Preseed
==================

Easily generate a preseeded debian ISO, and massively deploy debian.

This is very useful to provision VMs, or do Fully Automatic Installations on
many boxes.

ISO are fully generated in user mode, no root access is needed. (You just need
genisoimage and 7z installed.)

Quickstart
----------

~~~
$ aria2c -x2 "http://cdimage.debian.org/debian-cd/8.1.0/amd64/iso-cd/debian-8.1.0-amd64-netinst.iso" -o debian.iso
$ cp preseed.example.cfg preseed.cfg
$ ./build.sh
~~~

Now you can use debian-preseed.cfg


Help
----

~~~
$ ./build --help
~~~

Bugs
----

Report issues to this git repository

Notes
-----
- 2022-10-13 - Support for UEFI & USB boot
