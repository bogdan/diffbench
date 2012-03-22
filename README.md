# Diffbench

Diffbench is tool the I end up during many many performance patches to:

* Rails
  * ActiveRecord - [#5467](https://github.com/rails/rails/pull/5467)
  * ActiveModel - [#5431](https://github.com/rails/rails/pull/5431)
  * ActiveSupport - [#4493](https://github.com/rails/rails/pull/4493)
* Mail - [#396](https://github.com/mikel/mail/pull/369)

It runs a same benchmark code before and after applying a patch.

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



