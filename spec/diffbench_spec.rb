require 'spec_helper'
require "fileutils"

describe DiffBench do

  def to_regexp(output)
    Regexp.compile(Regexp.escape(output).gsub("NUMBERS", "[0-9]+")) 
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
After patch:    0.000000   0.000000   0.000000 (  0.100NUMBERS)
Before patch:   0.000000   0.000000   0.000000 (  0.200NUMBERS)

--------------------------------------------------Sleeper 2
After patch:    0.000000   0.000000   0.000000 (  0.100NUMBERS)
Before patch:   0.000000   0.000000   0.000000 (  0.200NUMBERS)
OUT
    end

    describe "when changes got commit" do

      before(:each) do
        git.add("code.rb")
        git.commit("Commit")
      end

      it "should run benchmark with HEAD and HEAD^" do
        `cd #{repo}; ./../../bin/diffbench bench.rb`.should =~ to_regexp(<<-OUT)
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
After patch:    0.000000   0.000000   0.000000 (  0.100NUMBERS)
Before patch:   0.000000   0.000000   0.000000 (  0.200NUMBERS)

--------------------------------------------------Sleeper 2
After patch:    0.000000   0.000000   0.000000 (  0.100NUMBERS)
Before patch:   0.000000   0.000000   0.000000 (  0.200NUMBERS)
OUT
      end
    end
  end

  
end
