this.setVisual(runOpts["visual"]);

new function runAllSort(size, name, speed, toPush = None, killers = None) {
    if toPush is not None {
        if type(toPush) in (list, tuple) {
            for item in toPush {
                this.pushAutoValue(item);
            }
        } else {
            this.pushAutoValue(toPush);
        }
    }

    this.runSortingProcess(
        runOpts["distribution"], size, autoValue * size // 2, 
        runOpts["shuffle"], ct, name, speed * runOpts["speed"], 
        killers = {} if killers is None else killers
    );
}

new list pivotSelections = [p.name for p in this.pivotSelections],
         distributions   = [d.name for d in this.distributions],
         rotations       = [r.name for r in this.rotations];

new int autoValue;
if runOpts["distribution"] == distributions.index("Perlin Noise") {
    autoValue = -1;
} else {
    autoValue = 1;
}


new str ct;
ct = "Exchange Sorts";
runAllSort(256,    "Bubble Sort", 80);
runAllSort(256,  "Odd-Even Sort", 20);
runAllSort(128,     "Gnome Sort",  3);
runAllSort(128, "Sandpaper Sort",  3);
runAllSort(512,    "Circle Sort",  5);
runAllSort(1024,     "Comb Sort", 10, 1.3);


ct = "Insertion Sorts";
runAllSort(256,  "Insertion Sort",     8);
runAllSort(256,  "Binary Insertion",   6);
runAllSort(256,  "Bin. Double Insert", 5);
runAllSort(256,  "Merge Insert",       5);
runAllSort(512,  "Shell Sort",         3);
runAllSort(1024, "Library Sort",       8, killers = {
    "Linear":    ["Reversed", "Reversed Sawtooth", "Partitioned"], 
    "Quadratic": ["Reversed", "Reversed Sawtooth", "Partitioned"], 
    "Quintic":   ["Reversed", "Reversed Sawtooth", "Partitioned", "Final Merge Pass", "Real Final Merge"], 
    "Sine Wave": [
        "Reversed", "Reversed Sawtooth", "No shuffle", "Sawtooth", 
        "Partitioned", "Final Merge Pass", "Noisy", "Real Final Merge",
        "Scrambled Tail", "Scrambled Head"
    ],
    "Perlin Noise": ["Partitioned", "Real Final Merge"]
});


ct = "Selection Sorts";
runAllSort(128,  "Selection Sort",   3);
runAllSort(128,  "Double Selection", 3);
runAllSort(64,   "Cycle Sort",       2);


ct = "Tree Sorts";
runAllSort(512,  "Tree Sort",        5, killers = {
    "Linear": [
        "Reversed", "Reversed Sawtooth", "No Shuffle", "Sawtooth", 
        "Few Random", "Final Merge Pass", "Real Final Merge", "Noisy",
        "Scrambled Tail", "Scrambled Head", "Sorted"
    ],
    "Quadratic": [
        "Reversed", "Reversed Sawtooth", "No Shuffle", "Sawtooth", 
        "Few Random", "Final Merge Pass", "Real Final Merge", "Noisy",
        "Scrambled Tail", "Scrambled Head", "Sorted"
    ],
    "Quintic":   [
        "Random", "Reversed", "Reversed Sawtooth", "No Shuffle", "Sawtooth", 
        "Few Random", "Final Merge Pass", "Real Final Merge", "Noisy",
        "Scrambled Tail", "Scrambled Head", "Sorted"
    ],
    "Sine Wave": [
        "Reversed", "Reversed Sawtooth", "No Shuffle", "Sawtooth", 
        "Few Random", "Final Merge Pass", "Real Final Merge", "Noisy",
        "Scrambled Tail", "Scrambled Head", "Sorted"
    ],
    "Perlin Noise": [
        "Reversed", "Reversed Sawtooth", "No Shuffle", "Sawtooth", 
        "Few Random", "Final Merge Pass", "Real Final Merge", "Noisy",
        "Scrambled Tail", "Scrambled Head", "Sorted"
    ],
});
runAllSort(2048, "Max Heap Sort",   15);
runAllSort(2048, "Smooth Sort",     10);
runAllSort(2048, "Poplar Heap",     10);
runAllSort(2048, "Weak Heap Sort",  15);
runAllSort(2048, "Patience Sort",   20);


ct = "Concurrent Sorts";
runAllSort(1024, "Bose Nelson",               7);
runAllSort(2048, "Bose Nelson (Parallel)",    1);
runAllSort(1024, "Fold Sort",                 7);
runAllSort(1024, "Bitonic Sort",              5);
runAllSort(2048, "Bitonic Sort (Parallel)",   1);
runAllSort(1024, "Pairwise",                  5);
runAllSort(1024, "Odd Even Merge",            5);
runAllSort(2048, "Odd Even Merge (Parallel)", 1);


ct = "Quick Sorts";

new dict centerKillers = {
    "Linear":    ["Reversed Sawtooth"], 
    "Quadratic": ["Reversed Sawtooth", "Sawtooth"], 
    "Quintic":   ["Reversed Sawtooth", "Sawtooth"]
};

new dict firstKillers = {
    "Linear": [
        "Reversed", "Reversed Sawtooth", "No shuffle", 
        "Sorted", "Few Random", "Noisy", "Scrambled Tail"
    ], 
    "Quadratic": [
        "Reversed", "Reversed Sawtooth", "Sawtooth", "No shuffle", 
        "Sorted", "Few Random", "Noisy", "Scrambled Tail"
    ],
    "Quintic": [
        "Reversed", "Reversed Sawtooth", "Sawtooth", "No shuffle", 
        "Sorted", "Few Random", "Noisy", "Scrambled Tail", "Random"
    ],
    "Sine Wave": [
        "Reversed", "Reversed Sawtooth", "Sawtooth", "No shuffle", 
        "Sorted", "Few Random", "Final Merge Pass", "Scrambled Head"
    ],
    "Perlin Noise": ["Sorted"]
};

runAllSort(1024, "LL Quick Sort",            4, pivotSelections.index("First"),  firstKillers);
runAllSort(1024, "LL Quick Sort (Parallel)", 4, pivotSelections.index("First"),  firstKillers);
runAllSort(1024, "LR Quick Sort",            4, pivotSelections.index("Middle"), centerKillers);
runAllSort(1024, "LR Quick Sort (Parallel)", 4, pivotSelections.index("Middle"), centerKillers);
centerKillers["Linear"].remove("Reversed Sawtooth");
runAllSort(1024, "Stackless Quick",          4, pivotSelections.index("Median of three (unstable)"), centerKillers);
runAllSort(1024, "Dual Pivot Quick",         4, killers = centerKillers);
runAllSort(2048, "Median-Of-16 A. Quick",   10);
runAllSort(2048, "PDQ Sort",                10); 
runAllSort(2048, "Aeos Quick",               8);
runAllSort(2048, "Log Sort",                 8, 0);


ct = "Merge Sorts";
runAllSort(2048, "Merge Sort",              16);
runAllSort(2048, "Merge Sort (Parallel)",    2);
runAllSort(2048, "Bottom Up Merge",          8);
runAllSort(256,  "Lazy Stable",              4, rotations.index("Gries-Mills"));
runAllSort(1024, "Rotate Merge",             3, rotations.index("Gries-Mills"));
runAllSort(2048, "Rotate Merge (Parallel)",  1, rotations.index("Gries-Mills"));
runAllSort(2048, "Adaptive Rotate Merge",   10, 256);
runAllSort(2048, "Uranium Sort",             6);
runAllSort(2048, "Tim Sort",                10);
runAllSort(2048, "New Shuffle Merge",       12, rotations.index("Gries-Mills"));
runAllSort(2048, "Andrey's Merge",           8);
runAllSort(2048, "Buf Merge 2",              3, rotations.index("Helium"));
runAllSort(2048, "Proportion Extend Merge",  8);


ct = "Block Merge Sorts";
runAllSort(2048, "Wiki Sort",          7, [0, rotations.index("Triple Reversal")]);
runAllSort(2048, "Grail Sort",         7, [0, rotations.index("Gries-Mills")]);
runAllSort(2048, "Helium Sort",        3, 0);
runAllSort(2048, "Hydrogen Sort",      4);
runAllSort(2048, "Kota Sort",          7, rotations.index("Cycle Reverse"));
runAllSort(2048, "Ecta Sort",          6);
runAllSort(2048, "Lithium Sort",       4);
runAllSort(2048, "Kita Sort",          6);
runAllSort(2048, "Chalice Sort",       6);
runAllSort(2048, "Advanced Log Merge", 6, [0, rotations.index("Cycle Reverse")]);
runAllSort(1024, "Remi Sort",          8);


ct = "Hybrid Sorts";
runAllSort(256,  "In-Place Stable Cycle", 0.5, rotations.index("Cycle Reverse"));
runAllSort(1024, "Pache Sort",              5);


ct = "Distribution Sorts";
runAllSort(2048, "Counting Sort",      8);
runAllSort(2048, "LSD Radix Sort",     8, 4);
runAllSort(2048, "MSD Radix Sort",     8, 4);
runAllSort(2048, "American Flag Sort", 8, 128);
runAllSort(2048, "Feature Sort",       6);
runAllSort(2048, "Static Sort",        6);


ct = "Pancake Sorts";
runAllSort(64, "Pancake Sort",      1);
runAllSort(64, "Optimized Pancake", 1);
runAllSort(64, "Adjacency Pancake", 2);


ct = "Impractical Sorts";
runAllSort(64, "Stooge Sort", 7);
runAllSort(8,    "Bogo Sort", 5);
runAllSort(8,    "Bozo Sort", 5);