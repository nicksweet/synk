synk
======

Quick and dirty way to sync up remote ec2 servers with your local code. Just cd in to your local project and run `sync`. If you dont already have a synk.json file for your project, synk will walk you through creating one. A synk.json file is just a json object that tells synk where your remote and local dirs are, the necessary info to rsync over ssh to your ec2 machine, and a series of commands that synk should run on the remote machine after upload to restart servers and what have you. Once your synk.json file is all set up, you can just run `synk` in you project to get your new code live in a few seconds.

usage
=====

````
Usage: synk [OPTIONS]

Options:
  	--remove, -rm            Remove the synk.json config file
 	--config, -c             Show synk.json config file
 	--help, -h               Show this message                               

````

install
=======

```
npm install synk -g
```
