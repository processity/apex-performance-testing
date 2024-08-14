# Apex Performance Testing

This package helps you to test the performance of Apex code. It factors in the variation that we might expect to see 
from one run to another in Apex tests multiple times and making it easy to plot the results.

You write a test with three parts: `setup`, `run`, and `teardown`. The package will run `setup`, will measure CPU time
for the `run` part, then run `teardown`. Each run is performed inside a Queueable job. The framework then chains 
together the required runs to measure performance multiple times and at multiple input sizes. 

The result of a test run is a number of `PerformanceMeasureResult__c` records with the size and measured CPU time for 
each run.

These results can then be plotted to compare different ways of solving the same problem. Or just to find out how a single
solution scales. 

## Installation

Either:

- Paste this onto the end of your My Domain URL: /packaging/installPackage.apexp?p0=04tWS000000Ht9lYAC
- Include in your SFDX project as "Apex Performance Testing": "04tWS000000Ht9lYAC"

Note that we also built it with our own namespace so that it can be installed into scratch orgs for our ISV packages 
during development (SF does not allow non-namespaced Unlocked Packages to be installed into namespaced scratch orgs). 
You don't need this namespaced version (if you're an ISV, clone the repo and build your own package with your namespace).

## Some free performance tuning advice

Before using this package to optimise for performance, look at the architecture of your system.

What's better than saving 5% or 10% of the CPU time required for an operation?

**Realising that you don't need to do the operation at all!**

The most painful performance problems come from doing unnecessary work, or using data structures/algorithms that are
inappropriate for the scale of the problem, or trying to squeeze more things into a single transaction when the work
could be split up.

Doing fewer things is where the big gains are.

Once you're doing the fewest thing, then you can consider using this package to do them in the fastest way.

Even then, faster is not always better. Readability and flexibility should be balanced against performance.
If your code becomes harder to read for a minor speed improvement, that might not be worthwhile trade.

With all that said, I hope this package does help you to make better informed decisions about efficiency in Apex!


## Example Usage: Types of for loops

There are two ways to write a for loop in Apex:

1. As an iterator
2. Using an integer index 

The first format is generally considered to be more readable. The second is more efficient. But how much more efficient?
That's a good question to be answered by this framework. 

To write a performance scenario to be tested, we implement the `PerformanceScenario` interface. 

In this case, we will do so by defining the `setup` and `teardown` methods of a `PerformanceScenario`:

```apex
public abstract class LoopPerformanceScenario implements PerformanceScenario {

    protected List<Integer> data;

    public void setup(Integer size) {
        data = new List<Integer>(size);

        for (Integer i = 0; i < size; i++) {
            data[i] = i;
        }
    }

    //PMD false positive, no teardown required
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void teardown() {
    }
}
```

This creates an in-memory list of integers to process in the `run` method. We have chosen to use inheritance to bring 
the same `setup` and `teardown` methods into each of the scenarios that we will define later. But inheritance is not 
the only way to achieve this - you can do it any way that you like. It is, however, required that each scenario you 
write implements the `PerformanceScenario` interface.

Given that superclass, each actual test is very small:

Iterator loop:
```apex
public class IteratorLoopPerformanceScenario extends LoopPerformanceScenario {
    
    public void run() {
        Integer sum = 0;
        for(Integer n : data) {
            sum += n;
        }
    }
}
```

All we care about is loop performance, so we sum up the `data` values to give some sort of operation in the loop body. 

Integer-indexed loop:
```apex
public class IntegerLoopPerformanceScenario extends LoopPerformanceScenario {

    public void run() {
        Integer sum = 0;
        for(Integer i=0; i < data.size(); i++) {
            sum += data[i];
        }
    }
}
```

Integer-indexed loop where we store the list length at the beginning of the loop:
```apex
public class IntegerStoredSizeLoopPerformanceScenario extends LoopPerformanceScenario {
    public void run() {
        Integer sum = 0;
        for(Integer i=0, size=data.size(); i < size; i++) {
            sum += data[i];
        }
    }
}
```

To group together running these tests, and to define the parameters for running them, use an instance of the 
`PerformanceSuite` class. It's convenient to put that code into its own class in a method that we can start from 
Anonymous Apex:

```apex
public with sharing class LoopPerformanceSuite {

    public static void run() {
        new PerformanceSuite('LoopPerformance', new List<PerformanceScenario>{
                new IntegerLoopPerformanceScenario(),
                new IteratorLoopPerformanceScenario(),
                new IntegerStoredSizeLoopPerformanceScenario()
        })
                .setStartSize(1000)
                .setStepSize(1000)
                .setEndSize(10000)
                .setRepetitions(20)
                .clearExistingResults()
                .run();
    }
}
```

Here we configure lots of things at once:

 - The name of the suite (the `PerformanceResult__c` records will carry that name so that you can easily query for 
the relevant ones).
 - The list of class instances implementing `PerformanceScenario` that should be run. Note that they are stateful, so you might well need that `teardown` method. `setup` is called before each `run`, though, so that could also be enough.
 - The input sizes to run at. This is just passed to `setup`, so your `PerformanceScenario` can decide what size means for your scenario. 
 - The number of iterations to run at each size
 - An instruction to clear any existing records for this suite before starting.

When you run `LoopPerformanceSuite.run()`, the testing will begin. There is no callback to tell you that it's complete, so just let it run 
until there are enough results.

The section below describes one way to analyse the data, but you can use any tools/techniques that you prefer. To cut
to the chase, here is a plot of the loop results

![](graphs/loops.png)

You can see from this that the integer-indexed loop where we store the size before going into the loop is the most 
efficient.

So we can conclude that for performance-critical code, this is the best method to use. However, the iterator
version does remove potential slips like having nested loops and mixing up the loop variables 
(e.g. writing `i` when you meant `j`), so iterators may be preferred when performance is not critical.

## Analysing the data 

This section describes how to analyse the data with `gnuplot`. This reliable old tool is easy to get for most systems, 
but you may prefer to use something more modern and base your analysis on some of what is described below for `gnuplot`.

### Requirements

This technique requires `sf` (the Salesforce CLI), `jq`, and `gnuplot`.

### Operation

Run the following script:

```zsh
 ./bin/generate_with_gnuplot.sh <MyPerformanceSuiteName>
 ```

This script performs the following steps:

1. Queries all experiment names from the performance suite data in Salesforce
2. For each experiment, queries the data and writes the data to CSV files
3. Constructs a gnuplot script to plot all the experiments onto the same graph
4. Runs gnuplot to generate a PNG file with the graph data

After plotting, you will see the results in the `graphs/` directory. The gnuplot commands will be in `gnuplot/MyPerformanceSuiteName.gnuplot` so 
that you can modify the appearance if you want to (note, this file will get clobbered on the next run so be careful)
