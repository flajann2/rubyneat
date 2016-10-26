<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#orgheadline9">1. RubyNEAT &#x2013; Neural Evolution of Augmenting Topologies</a>
<ul>
<li><a href="#orgheadline1">1.1. Gem Version</a></li>
<li><a href="#orgheadline2">1.2. Quick and Dirty Docs</a></li>
<li><a href="#orgheadline3">1.3. Enhanced Substrate HyperNEAT</a></li>
<li><a href="#orgheadline4">1.4. Modularization</a></li>
<li><a href="#orgheadline5">1.5. Examples</a></li>
<li><a href="#orgheadline6">1.6. Also Note</a></li>
<li><a href="#orgheadline7">1.7. Release Notes</a></li>
<li><a href="#orgheadline8">1.8. Copyright Notice &amp; Licensing Info</a></li>
</ul>
</li>
</ul>
</div>
</div>

# RubyNEAT &#x2013; Neural Evolution of Augmenting Topologies<a id="orgheadline9"></a>

[[![img](//gitter.im/flajann2/rubyneat?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge][[[https:/badges.gitter.im/Join%20Chat.svg)]]]]

For the latest news and usage docs, please see:

<http://rubyneat.de>

For code documentation, please see:

<http://www.rubydoc.info/github/flajann2/rubyneat>

RubyNEAT is under intense development, and then will be under intense
documentation, as this is expected to be a full blown pure Ruby
implementation of the NEAT algorithm by Kenneth Stanley:

<http://www.cs.ucf.edu/~kstanley/>

## Gem Version<a id="orgheadline1"></a>

[[![img](//badge.fury.io/rb/rubyneat][[[https:/badge.fury.io/rb/rubyneat.png)]]]]
[[<https://travis-ci.org/flajann2/rubyneat][[[https://travis-ci.org/flajann2/rubyneat.svg?branch=hyper>]]]]

## Quick and Dirty Docs<a id="orgheadline2"></a>

There is an (extreme) alpha RubyGEM. Just do:

gem install rubyneat &#x2013;pre

Then type:

neat

to see the list of commands. The workflow aspect of Rails is loosely
mirrored here.

To generate a new NEAT project, type:

neat new PROJECTNAME

and a project directory will be created. Cd into that directory, and
type:

neat generate neater NEATERNAME

and a scaffold Neater will be generated. Note that this generator is
still in alpha, but improvements are coming shortly.

## Enhanced Substrate HyperNEAT<a id="orgheadline3"></a>

This version (and all subsequent versions) has the iterated ES HyperNEAT
feature added. This represents a significant leap in the power of
RubyNEAT, and as such will make this available to solve a wider class of
problems.

The decision to leapfrog HyperNEAT was made primarily on a number of
fronts. for starters, HyperNEAT is very sensitive to changes in the
CPPN, where ES HyperNEAT regenerates the neurons in the substrate on
each and every change (evolution) of the CPPN. In this way, more
stability can be had. On the other hand, it makes the expression phase
more computationally expensive.

We will seek hard-nosed ways to optimize the expressor performance.

Also, with the dashboard will have to grow some extra abilities to
provides visualization.

## Modularization<a id="orgheadline4"></a>

On the heels of ES HyperNEAT, we needed to add modularization to make
that possible. We expose this modularization for direct usage outside of
HyperNEAT, so that you may compose modules of ANNs and their
relationships, which mirrors how the brain has 'modules' of specific
functionality.

You of course may mix and match ES HyperNEAT modules with NEAT modules.
We'll leave that to your imagination. This modularization should not be
confused with the modularization that may automatically arise within ES
HyperNEAT itself. Please see the Wiki for a deeper exploration of these
ideas,

## Examples<a id="orgheadline5"></a>

For some examples, clone or fork the following:

<https://github.com/flajann2/rubyneat_examples>

Feel free to add your own and do pull requests so that we can have more
examples of using RubyNEAT.

## Also Note<a id="orgheadline6"></a>

For now, see

<https://github.com/flajann2/rubyneat>

for the Github version, and this will probably be the better option
until this gets out of alpha. There are a couple of example Neaters
there (one of which is still in development). Basic, but will be a good
example of how to implement your own Neater. Eventually all will be
fully documented.

## Release Notes<a id="orgheadline7"></a>

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">version</th>
<th scope="col" class="org-left">description</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">hyper branch</td>
<td class="org-left">Many new features related to HyperNEAT amd parallelism will be added here, when merged back to the master branch, the version will be bumped to 1.x. For now, I will use "regular" tags until we reach that point.</td>
</tr>


<tr>
<td class="org-left">0.5.0.hyper.alpha.0</td>
<td class="org-left">Indroduction of multicritter (actually multi-genenome) modularity, ES HyperNEAT (which does not require multi-genome as such, as it's handled mostly in the Expressor)</td>
</tr>


<tr>
<td class="org-left">0.3.5.alpha.7</td>
<td class="org-left">Console made functional.</td>
</tr>


<tr>
<td class="org-left">0.4.0.alpha.0</td>
<td class="org-left">Added a pop parameter to the report hook function. All example code in rubyneat\\<sub>examples</sub> updated. You will need to add the additional parameter to your Neaters on your report hooks.</td>
</tr>
</tbody>
</table>

Also, added stronger support for plugins. In particular, an
attr\\<sub>neat</sub> attribute processor was added to NeatOb, to support
default settings as well as hooks. Now, all plugins need to do is to
hook into these hook functions to get notifications.

## Copyright Notice & Licensing Info<a id="orgheadline8"></a>

This code is released under the MIT license:

Copyright (c) 2014-2017 Fred Mitchell

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
