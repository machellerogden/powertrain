# POWERTRAIN

**PLEASE NOTE:** Documentation is incomplete. More soon.

## Overview

Powertrain is a wrapper around GNU Make that aims to simplify docker builds and
deployments by enabling a simple declarative configuration for your project and
by providing a concise syntax for control flow.

### What does Powertrain do?

Powertrain does two things:

* The `powertrain` entrypoint script determines the run context for Make and
runs Make using the `powertrain.mk` found in that run context.
* The default powertrain Makefile (`./powertrain.mk`) provides a set of default
variables and targets.

### How Powertrain Determines Run Context?

If a `PT_CONTEXT` environment variable has been set, it will look for a
`powertrain.mk` at the location specified by that variable and use that `powertrain.mk`;
otherwise, if the user's current working directory contains a `powertrain.mk` it will
use that `powertrain.mk`; lastly, if neither of the first two conditions are met, it
will use it's own default `powertrain.mk`.

### What is the Powertrain Makefile?

Powertrain includes it's own Makefile which defines a set of variables and
targets which, taken together, enable the most common docker build and
deployment tasks out-of-the-box. Powertrain allows you to configure your docker
project with a very simple declarative syntax by taking advantage of GNU Make's
override system. When custom logic is needed for any given target, you can
override that target by declaring the location of a shell script which replace
the default target logic.

### Do I need to know how GNU Make works?

You do not need to know everything about Make to use powertrain. All you really
need to know that is specific to Make is how target chaining works and how to
set and override variables.

In additional to these Make-specific items, you will need to know how to write
an executable shell script and a few powertrain specific usage patterns.

Make is a powerful tool, and, if you're interested, full documentation
for GNU Make can be found here: https://www.gnu.org/software/make/manual/


## Install

1. Clone this repo.
2. Make the `powertrain` script executable.
3. Get `powertrain` into your `$PATH` (either by adding a symlink to
`./powertrain/powertrain` to an existing directory in your `$PATH` or by adding
the repo directory to directory in your `$PATH`).


## New Project Setup

__See "Usage" section below for using `powertrain` with an existing project.__

To get started with powertrain, add a Makefile to the root of your project
directory. This should be in the same directory as you Dockerfile.

Here's an example of what the most basic powertrain.mk file can look like:


    NAME=my-app


That's all. Using this configuration, powertrain will use all of it's default
scripts to build a docker image with the project name you've delared, in this
case `my-app`. By default the docker image will be tagged with the
project's current git commit. For a very basic use case, this is all you'll
need. For most projects you'll need to declare additional configuration.

Here's an example of a slightly more complex `powertrain.mk`:

    NAME=my-app
    INSTANCES=4
    REGISTRY=repository.cars.com
    PORTS=1337,9081
    VOLUMES=/app/logs:/app/logs
    LABELS=pool=my-routing-pool
    ENVS=CONFIG=$(SOME_ENV_ON_HOST)
    RUN_SCRIPT=$(CURDIR)/scripts/docker/run.sh   # Use $(CURDIR) for current working directory of project, $(PWD) will evalulate to the powertrain directory
    RUN_MODE=foreground # Use to change run mode [foreground|interactive|detached (default)]
    ENTRY_POINT=bash # Use to override the entrypoint

## Usage

Once you have a `powertrain.mk` file in your project root, you can chain
together the "targets" ([more on GNU Make Targets here](http://www.gnu.org/software/make/manual/make.html#Phony-Targets))
documented below to create simple workflows. Each target will be executed synchronously in the order they are declared.
Override variables in-line with each command or in your project's `powertrain.mk`.

### Examples

To build an image:

    powertrain build

To run a container:

    powertrain run

Or, do both of the above at once:

    powertrain build run

To publish:

    powertrain tag push VERSION=1.0.0

Or, use the `publish` composite target... (this does exactly the same as the above)

    powertrain publish VERSION=1.0.0

To deploy:

    powertrain rm-exited pull run sleep stop-old NAME=my-app VERSION=1.0.0

Or, use the `deploy` composite target... (this does exactly the same as the above)

    powertrain deploy NAME=my-app VERSION=1.0.0

All together now...

    powertrain build publish deploy INSTANCES=4


## Targets

### Build


    powertrain build


The above command will build an image tagged with a specified name and version
number. If no arguments are provided, this will build an image with the name
and version specified in your project's `powertrain.mk`, or if not specified, the
default name and version `powertrain:latest`.


<br>

### Start Container


    powertrain run


The above command will start a container tagged with a specified name and
version number. If no arguments are provided, this will attempt to run an
image with the name and version specified in your project's `powertrain.mk`, or if
not specified, the default name and version `powertrain:latest`.


<br>

### Stop Containers


    powertrain stop


The above command will stop a container tagged with a specified name and
version number. If no arguments are provided, this will attempt to stop any
containers with the name and version specified in your project's `powertrain.mk`,
or if not specified, the default name and version `powertrain:latest`.


    powertrain stop-all


The above command will stop all containers matching the target project's name.


<br>

### Remove Containers


    powertrain rm


The above command will remove all containers tagged with a specified name and
version number. If no arguments are provided, this will attempt to remove any
containers with the name and version specified in your project's `powertrain.mk`,
or if not specified, the default name and version `powertrain:latest`.


    powertrain rm-all


The above command will remove all containers matching the target project's name.


<br>

### Remove Images


    powertrain rmi


The above command will remove all images tagged with a specified name and
version number. If no arguments are provided, this will attempt to remove any
images with the name and version specified in your project's `powertrain.mk`, or if
not specified, the default name and version `powertrain:latest`.


    powertrain rmi-all


The above command will remove all images matching the target project's name.


<br>

### Publish


    powertrain publish


The above command will tag and push an image to our internal docker registry
with a specified name and version number. If no arguments are provided, this
will deploy an image with the name from the project's Makefile and the current
git commit hash (assuming your project is using git for version control).

<br>

### Deploy


    powertrain deploy


The above command will pull an image from your docker registry and then
execute a rolling restart of your containers. `deploy` is a composite target
that execute the following targets: `rm-exited pull run sleep stop-old`.

<br>

### Extract


    powertrain extract EXTRACT_SRC=<comma-separated list of files in container> EXTRACT_DEST=<directory on host where files will be copied to, defaults to working directory>


The above command will extract files from a docker image.

For example, you might want to extract the `powertrain.mk` file from a container so you can run it with it's declared config:

    powertrain extract run NAME=my-app VERSION=1.2.3 EXTRACT_SRC=/app/powertrain.mk

...and maybe it has a custom run script as well which you want to use, but that run script is inside the image...

    powertrain extract run NAME=my-app VERSION=1.2.3 EXTRACT_SRC=/app/powertrain.mk,/app/scripts/docker/run.sh RUN_SCRIPT=$(pwd)/run.sh

<br>

### Attach to Running Container


    powertrain attach


The above command will attached to the most recently executed and still running container.

<br>

### Attach to Running Container in Interactive Mode


    powertrain exec


The above command will attached to the most recently executed and still running container in interactive mode for debugging purposes.

<br>

### View Container Logs


    powertrain logs


The above command will show the logs from the most recently executed container.

<br>

### View Container Status


    powertrain status


The above command will show the exit code from the most recently executed container.

<br>

### View Container Exit Code


    powertrain exit-code


The above command will show the exit code from the most recently executed container.

<br>

### Machine Commands


    powertrain machine-create

This command will create a new machine with the default name of cars.  It will
also setup port forwarding on the machine so that it can be used on and off
the vpn.

<br>

    powertrain machine

This command will help set up docker properly when switching to and from the
VPN.  After the command executes it will provide the eval command that will be
needed for configuring the Docker global variables.

<br>

    powertrain machine-port MACHINE_ALIAS={alias} MACHINE_PORT={port}

When on the VPN it is necessary to set up port forwarding so that when you
need to access a port on Docker container it can be routed properly.  To
create a new Port Forward using this command specifying a unique name for the
rule ALIAS and the PORT number.

<br>

### Machine Workflow

    powertrain machine-create # One time deal
    powertrain machine        # Anytime switching on/off VPN. this will also provide the eval statement for setting up docker env variables
    powertrain machine-port   # Anytime needing a port opened


<br>

### [A note about Ports](#markdown-header-a-note-about-ports)

Firewall rules prevents us from spinning containers on random ports. Powertrain gaurds against it by *only* assiging ports which fall in the below ranges.

```
	8000  -  8099  ( Web Apps )
	9000  -  9099  ( RESTful Services )
	10000 -  10099 ( Composite services )
	1337  -  1357  ( Rendering )
	8446  -  8461  ( Sell )
```

If and when needed, these ranges can be modified in the var/NEXT_PORT.sh file.   

#### Error conditions

##### Port out of range

If a container is configured to run on a port outside of the allowed ranges, Powertrain will fail with the below error message.

```bash
	Configured port [1435] is out of the below allowed ranges
			8000  -  8099  ( Web Apps )
			9000  -  9099  ( RESTful Services )
			10000 -  10099 ( Composite services )
			1337  -  1357  ( Rendering )
			8446  -  8461  ( Sell )
	make: *** [run] Error 1
```

##### No more ports

There could be scenario where a container is configured to run an allowed range, but based on the number of already running containers in that range, Powertrain won't be able to allocate an open port in that range. In this case, it will exit with a FATAL message as below.

```bash
		FATAL : Powertrain cannot allocate port [1358]
	  FATAL : Port [1358] outside of limit allowed by firewall rules
		FATAL : Contact DevOps or the Linux Engineering team to fix this
```
