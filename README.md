## RubyNEAT -- Neural Evolution of Augmenting Topologies

For the latest docs, please see http://rubyneat.com

RubyNEAT is under intense development, and then will be under intense documentation, as this is
expected to be a full blown pure Ruby implementation of the NEAT algorithm by Kenneth Stanley:

http://www.cs.ucf.edu/~kstanley/

## Quick and Dirty Docs

There is an (extreme) alpha RubyGEM. Just do:

 gem install rubyneat --pre

Then type:

  neat

to see the list of commands. The workflow aspect of Rails is loosely mirrored here.

To generate a new NEAT project, type:

  neat new PROJECTNAME

and a project directory will be created. Cd into that directory, and type:

  neat generate neater NEATERNAME

and a scaffold Neater will be generated. Note that this generator is still
in alpha, but improvements are coming shortly.

## Also Note

For now, see

https://github.com/flajann2/rubyneat

for the Github version, and this will probably be the better option until this
gets out of alpha. There are a couple of example Neaters there (one of which is
still in development). Basic, but will be a good example of how to implement your own
Neater. Eventually all will be fully documented.

## Copyright Notice

This code is released under the MIT license:

Copyright (c) 2014 LRCSoft.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
