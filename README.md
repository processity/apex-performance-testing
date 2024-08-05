# Apex Performance Testing

This package helps you to test the performance in a straightforward way, factoring in the variation that we might 
expect to see from one run to another in Apex.

You can set up a test with your own methods to `setup`, `run`, and `teardown` test data. The package will measure CPU time
for the `run` part. Each run is performed inside a Queueable job. The framework then chains together the required runs 
to measure multiple times and at multiple sizes. 

You can specify what size parameters to pass into the code and how many times to repeat at each size. This produces a 
list of `PerformanceMeasureResult__c` records with the results.

These results can then be plotted to see which code performs best. 

## Some free performance tuning advice

Before using this package to optimise for performance, look at the architecture of your system.

What's better than saving 5% or 10% of the CPU time required for an operation?

Realising that you don't need to do the operation at all!

The most painful performance problems come from doing unnecessary work, or using data structures/algorithms that are
inappropriate for the scale of the problem, or trying to squeeze more things into a single transaction when the work
could be split up.

These things are the big gains.

Once you've ruled out all of the above, then you can consider using this package to evaluate different ways of doing
things. Even then, faster is not always better. Readability and flexibility should be balanced against performance.
If your code becomes harder to read for a minor speed improvement, that might not be worthwhile trade.

With all that said, I hope this package does help you to make better informed decisions about efficiency in Apex!


## Example Usage: Types of for loops

There are two ways to write a for loop in Apex:

1. As an iterator
2. Using an integer index 

The first format is generally considered to be more readable. The second is more efficient. But how much more efficient?
That's a good question to be answered by this framework. 

We start to build tests for this by defining the `setup` and `teardown` methods of a `PerformanceScenario`:

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

This creates an in-memory list of integers to process. We have chosen to use inheritance to bring the same `setup` and 
`teardown` methods into each of the scenarios that we will define later. But inheritance is not the only way to achieve 
this - you can do it any way that you like. It is, however, required that each scenario you write implements the 
`PerformanceScenario` interface.

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

We set the name of the suite (the `PerformanceResult__c` records will carry that name so that you can easily query for 
the relevant ones), sizes to run at, the number of iterations, and to clear an existing records for this suite before 
starting.

When you run this code, the testing will begin. There is no callback to tell you that it's complete, so just let it run 
until there are enough results.

The section below describes one way to analyse the data, but you can use any tools/techniques that you prefer. To cut
to the chase, here is a plot of the loop results

![](graphs/loops.png)

You can see from this that the integer-indexed loop where we store the size before going into the loop is the most 
efficient. So we can conclude that for performance-critical code, this is the best method to use. However, the iterator
version does remove potential slips like having nested loops and mixing up the loop variables 
(e.g. writing `i` when you meant `j`), so iterators should be preferred when performance is not critical.

## Analysing the data 

This section describes how to analyse the data with `gnuplot`. This reliable old tool is easy to get for most systems, 
but you may prefer to use something more modern and base your analysis on some of what is described below for `gnuplot`.

### Requirements

This technique requires `sf` (the Salesforce CLI), `jq`, `xargs`, and `gnuplot`.

### Setup

Create empty directories for the CSV files and the graphs:

```zsh
mkdir csv
mkdir graphs
```

### Extract CSV files

```zsh
 sf data query --query "SELECT ExperimentName__c FROM PerformanceMeasureResult__c WHERE SuiteName__c = 'LoopPerformance' GROUP BY ExperimentName__c" --json | jq -r '.result.records[].ExperimentName__c' | xargs -I {} zsh -c "sf data query -q \"SELECT Size__c, CpuTimeInMs__c FROM PerformanceMeasureResult__c WHERE ExperimentName__c = '{}' AND Result__c = 'SUCCESS' ORDER BY Size__c\" -r csv > csv/{}.csv"
 ```

This gets all the experiment names for a given suite, processes the result with `jq`, then feeds them into `xargs` so 
that they can be queried individually and put into CSV files with the experiment name.

### Plot the data

Then use `gnuplot` to plot the data. There is a script included [here in the repository](gnuplot/loopPerformance.gnuplot).
You can modify this script to suit your own data

```zsh
gnuplot -d gnuplot/fieldChanges.gnuplot
```

After plotting, you will see the results in the `graphs/` directory.
