Learning from Unlabelled Instructions
===

If you do not have any idea about what this code is about, you should visit [this page](http://jgrizou.com/projects/learning-from-unlabelled-instructions/).

If your visit is related to our paper submitted in Plos One, please visit the following repository: https://github.com/flowersteam/self_calibration_BCI_plosOne_2015.

There is one tutorial exemple to explain you how to run one experiment with the current code. You also need to pull my [matlab\_tools](https://github.com/jgrizou/matlab_tools) repository, and checkout the tag called "thesis". 

```
mkdir foldername
cd foldername
git clone https://github.com/jgrizou/lfui
cd lfui
git checkout tags/thesis
cd ..
git clone https://github.com/jgrizou/matlab_tools
cd matlab_tools
git checkout tags/thesis
cd ..
```

Then, using Matlab, run the foldername/lfui/example/init.m script which setup the matlab path and change some default figure thingies. Then you can open the foldername/lfui/example/gridworld/run_gridworld.m script and either have fun reading it or just run it to look at some stuff moving!

Many of the tools you will see are still under test and development, I am here thinking of some classifiers I never used yet. Appart from the provided example which has been tested many times, it is likely there is some buggy code and maybe wrong one. So be your own guide and check whether what you see make sense. I will do my best to answer any question.

Once you are confident with the example, you can start checking out more advanced experiments in my [thesis\_code](https://github.com/jgrizou/thesis_code) repository. 


[![DOI](https://zenodo.org/badge/6228/jgrizou/lfui.png)](http://dx.doi.org/10.5281/zenodo.11804)

