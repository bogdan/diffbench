require 'spec_helper'
require "fileutils"

describe DiffBench do
  let(:repo) do
    "#{File.dirname(__FILE__)}/repo"
  end
  let!(:git) do
    FileUtils.rm_rf(repo)
    FileUtils.mkdir(repo)
    git = Git.init(repo)
    FileUtils.cp("spec/code.rb", repo)
    git.add("code.rb")
    git.commit("Init")
    git
  end


  describe "when git tree is dirty" do
    before do
      content = File.read("spec/repo/code.rb")
      File.open("spec/repo/code.rb", "w") do |f|
        f.write(content.gsub(/TIME = 0\.2/, "TIME = 0.1"))
      end
      FileUtils.cp("spec/bench.rb", "spec/repo/bench.rb")
    end

    it "should run benchmark with dirty tree and clean tree" do
      puts `cd spec/repo; ./../../bin/diffbench bench.rb`
    end

    describe "when changes got commit" do

      before(:each) do
        git.add("code.rb")
        git.commit("Commit")
      end

      it "should run benchmark with HEAD and HEAD^" do
        puts `cd spec/repo; ./../../bin/diffbench bench.rb`
      end
    end
  end

  
end
