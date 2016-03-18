OSX inotify helper
==================

Sends file changes over the network. Neat if you write code locally and
need some watching process in a vm (like Vagrant) to detect the change
immediately and take some action.
 
Inspired ny https://github.com/themylogin/nfs_inotify. 
OSX lack the inotify in the kernel, but instead supplies its own
FSEvents API. Also, this program uses UDP to avoid handling connections 
when there's really no need to.
