require 'spec_helper'
require "fileutils"

describe DiffBench do

  def to_regexp(output)
    Regexp.compile(Regexp.escape(output).gsub("NUM", "[0-9]+")) 
  end

  def improvement_expression
    DiffBench::Runner.color("Improvement: NUM%", :green)
  end

  let(:repo) do
    "#{File.dirname(__FILE__)}/repo"
  end
  let!(:git) do
    FileUtils.rm_rf(repo)
    FileUtils.mkdir(repo)
    git = Git.init(repo)
    FileUtils.cp("spec/code.rb", repo)
    FileUtils.cp("spec/bench.rb", "#{repo}/bench.rb")
    git.add("code.rb")
    git.commit("Init")
    git
  end


  describe "when git tree is dirty" do
    before do
      content = File.read("#{repo}/code.rb")
      File.open("#{repo}/code.rb", "w") do |f|
        f.write(content.gsub(/TIME = 0\.2/, "TIME = 0.1"))
      end
    end

    it "should run benchmark with dirty tree and clean tree" do
      output =  `cd #{repo}; ./../../bin/diffbench bench.rb`
      output.should =~ to_regexp(<<-OUT)
Running benchmark with current working tree
--> Sleeping
--> Sleeping
Stashing changes
Running benchmark with clean working tree
--> Sleeping
--> Sleeping
Applying stashed changes back

                    user     system      total        real
--------------------------------------------------Sleeper 1
After patch:    0.000000   0.000000   0.000000 (  0.10NUM)
Before patch:   0.000000   0.000000   0.000000 (  0.20NUM)
#{improvement_expression}

--------------------------------------------------Sleeper 2
After patch:    0.000000   0.000000   0.000000 (  0.10NUM)
Before patch:   0.000000   0.000000   0.000000 (  0.20NUM)
#{improvement_expression}
OUT
    end

    it "should suppor before command option" do
      output =  `cd #{repo}; ./../../bin/diffbench -b "echo hello" bench.rb`
      output.should include("hello")
    end

    describe "when changes got commit" do

      before(:each) do
        git.add("code.rb")
        git.commit("Commit")
      end

      it "should run benchmark with HEAD and HEAD^" do
        output = `cd #{repo}; ./../../bin/diffbench bench.rb`
        output.should =~ to_regexp(<<-OUT)
Running benchmark with current working tree
--> Sleeping
--> Sleeping
Checkout HEAD^
Running benchmark with HEAD^
--> Sleeping
--> Sleeping
Checkout to previous HEAD again

                    user     system      total        real
--------------------------------------------------Sleeper 1
After patch:    0.000000   0.000000   0.000000 (  0.10NUM)
Before patch:   0.000000   0.000000   0.000000 (  0.20NUM)
#{improvement_expression}

--------------------------------------------------Sleeper 2
After patch:    0.000000   0.000000   0.000000 (  0.10NUM)
Before patch:   0.000000   0.000000   0.000000 (  0.20NUM)
#{improvement_expression}
OUT
      end

      it "should run benchmark for specified revisions" do
        revs = `cd #{repo};git log --pretty="%h"`.split("\n").reverse
        output = `cd #{repo}; ./../../bin/diffbench -r #{revs.join(",")} bench.rb`
        output.should =~ to_regexp(<<-OUT)
Checkout to #{revs.first}
Run benchmark with #{revs.first}
--> Sleeping
--> Sleeping
Checkout to #{revs.last}
Run benchmark with #{revs.last}
--> Sleeping
--> Sleeping
Checkout to master

                    user     system      total        real
--------------------------------------------------Sleeper 1
#{revs.first}:   0.000000   0.000000   0.000000 (  0.10NUM)
#{revs.last }:   0.000000   0.000000   0.000000 (  0.20NUM)
#{improvement_expression}

--------------------------------------------------Sleeper 2
#{revs.first}:   0.000000   0.000000   0.000000 (  0.10NUM)
#{revs.last }:   0.000000   0.000000   0.000000 (  0.20NUM)
#{improvement_expression}
OUT
      end
    end

  end

  
end
