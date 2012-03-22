$LOAD_PATH.unshift "./lib"
require 'diffbench'
load File.dirname(__FILE__) + "/code.rb"

DiffBench.bm do
  report "Sleeper" do
    Sleeper.run
  end
end
