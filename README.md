sshupdate
=========

A simple, extendible, secure, low-dependency driven project to handle patch management written by sysadmins for sysadmins.

We all do it, every day / week / month / quarter. We update servers, we try to make our environment comply with our guidelines. We try and do it frequently, we try to do it in a good way. We try to keep same patchlevels across an entire environment. This is a struggle, especially since there are no good tools to help us. And honestly, those that exist are either very complex or come with a high license fee. 

Keeping our servers up to date shouldn't be that hard.

With this project we aim to simplify the management. Automate the process and keep the dependencies low. All while maintaining the focus on security. With this in mind we turned to a sysadmins best friend, SSH and asked ourselves: What can we do with it?

Essentially, anything. Deployed in a correct manner SSH holds an awesome set of features that help us manage our system. With some clever scripting and some sound descision making in how a patch process should work, we believe it can be turned into the best manager for any environment. 

This is why we created sshupdate.

How it works
============

After you've installed a master server. Each client where you install sshupdate will be controlled by your self-assigned master. The master will communicate via SSH by using keys and pre-configured commands. sshupdate is locked down in such a way that the master can only do a specific set of commands on each client, nothing else.

Let's say you want to patch a server:<br>
 Command: sshupdate patch myspecialserver<br>

 What happens?
  1. sshupdate opens a connection to myspecialserver via SSH using its keys 
  2. sshupdate issues the pre-configured command 'patch' on myspecialserver
  3. sshupdate's wrapper-script on myspecialserver translates the 'patch' command to "yum update -y" since its a CentOS server
  4. Uh, yeah, that's it.

Supported platforms
===================

We are doing what we can to support as many platforms as possible.<br>

Currently tested platforms: EL6, Debian(wheezy), Fedora(19), Ubuntu(13.04), OpenSUSE(12.3)<br>
Planned: EL5
Thinking about: AIX, FreeBSD, Solaris<br>

As we are looking to support more platforms, you're welcome to help out. 

How to get started
==================

Getting started is fairly simple. Please note, the following assumes you're running on a EL6-host.

1. Download sources<br>
   Either download the zip: https://github.com/trams242/sshupdate/archive/master.zip <br>
     or <br>
   If you have git, download via git: git clone https://github.com/trams242/sshupdate.git <br>

2. Enter the source directory and run the command:<br>
   On machine with sources: ./init.sh init

3. Install the server RPM<br>
   On machine with sources: scp &lt;rpm-file-created-from-init.sh> &lt;manager-hostname>: <br>
   On manager: rpm -ivh &lt;rpm-file-created-from-init.sh> <br>

4. Install the client RPM<br>
   On machine with sources: scp &lt;rpm-file-created-from-init.sh> &lt;client-hostname>: <br>
   On client: rpm -ivh &lt;rpm-file-created-from-init.sh> <br>

5. Patch for fun and profit<br>
   On manager: sshupdate patch &lt;client-hostname><br>
