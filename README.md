# Diffbench

Diffbench is tool the I end up during many many performance patches to:

* Rails
  * ActiveRecord
  * ActiveModel
  * ActiveSupport
* Mail

It runs a same benchmark code before and after applying a patch
TODO links to original PRs

## Installation

``` sh
gem install diffbench
```

## Usage

Create the following benchmark file in the git root of the project:

``` ruby
require 'diffbench'

$LOAD_PATH << "./lib"
require "mail"

DiffBench.bm do
  report("headers parsing when long") do
    Mail::Header.new("X-Subscriber: 1111\n"* 1000)
  end
  report("headers parsing when tiny") do
    Mail::Header.new("X-Subscriber: 1111\n"* 10)
  end
  report("headers parsing when empty") do
    Mail::Header.new("")
  end
end
```

Run:

``` sh
diffbench <file>
```

If the working tree is dirty than diffbench will run benchmark against dirty and clean tree.
If the working tree is not dirty than diffbench will run benchmark against current HEAD and commit previous to HEAD.



