# Diffbench

Diffbench is a tool I made during many performance patches to:

* Rails
  * ActiveRecord - [#5467](https://github.com/rails/rails/pull/5467)
  * ActiveModel - [#5431](https://github.com/rails/rails/pull/5431)
  * ActiveSupport - [#4493](https://github.com/rails/rails/pull/4493)
  * ActionPack - [#5957](https://github.com/rails/rails/pull/5957)
* Mail - [#396](https://github.com/mikel/mail/pull/369), [#366](https://github.com/mikel/mail/pull/366)

It runs a same benchmark code before and after applying a patch.

## Requirements

* Git

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
    10.times do
      Mail::Header.new("X-Subscriber: 1111\n"* 10)
    end
  end
  report("headers parsing when empty") do
    100.times do
      Mail::Header.new("")
    end
  end
end
```

Run:

``` sh
diffbench <file>
```

If the working tree is dirty than diffbench will run benchmark against dirty and clean tree.
If the working tree is not dirty than diffbench will run benchmark against current HEAD and commit previous to HEAD.


Output:

```
Running benchmark with current working tree
Checkout HEAD^
Running benchmark with HEAD^
Checkout to previous HEAD again

                    user     system      total        real
----------------------------------headers parsing when long
After patch:    0.100000   0.000000   0.100000 (  0.089926)
Before patch:   0.700000   0.000000   0.700000 (  0.697444)

----------------------------------headers parsing when tiny
After patch:    0.000000   0.000000   0.000000 (  0.009930)
Before patch:   0.020000   0.000000   0.020000 (  0.024283)

---------------------------------headers parsing when empty
After patch:    0.010000   0.000000   0.010000 (  0.002160)
Before patch:   0.000000   0.000000   0.000000 (  0.002354)
```
## Is DiffBench safe for my repo?

DiffBench is using `git stash` and `git checkout "HEAD^"` commands to modify code in a repo.
This means that you are able to **recover** your code even **after ruby segfaults**.


## Self-Promotion

Like diffbench?

Follow the [repository on GitHub](https://github.com/bogdan/diffbench).

Read [author blog](http://gusiev.com).
