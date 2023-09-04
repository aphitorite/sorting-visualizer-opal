use uncheckedInsertionSort;
use MaxHeapSort;

new class StaticSort {
    new method __adapt(array) {
        return array + this.offset;
    }

    new method sort(array, a, b) {
        new int min_, max_;
        min_, max_ = findMinMax(array, a, b);

        new int auxLen = b - a;

        new list count = sortingVisualizer.createValueArray(auxLen + 1);
        this.offset    = sortingVisualizer.createValueArray(auxLen + 1);
        sortingVisualizer.setAux(count);
        sortingVisualizer.setAdaptAux(this.__adapt);

        new float CONST = auxLen / (max_ - min_ + 1);

        for i = a; i < b; i++ {
            count[int((array[i].readInt() - min_) * CONST)]++;
        }

        this.offset[0].write(a);
        for i = 1; i < auxLen; i++ {
            this.offset[i].write(count[i - 1] + this.offset[i - 1]);
        }

        for v in range(auxLen) {
            while count[v] > 0 {
                new int origin = this.offset[v].readInt(),
                        from_  = origin;
                new Value num = array[from_].copy();

                array[from_].write(-1);

                do from_ != origin {
                    new int dig = int((num.readInt() - min_) * CONST),
                            to = this.offset[dig].readInt();
                    this.offset[dig]++;
                    count[dig]--;

                    new Value temp = array[to].copy();
                    array[to].write(num);
                    num = temp.copy();
                    from_ = to;
                }
            }
        }

        for i in range(auxLen) {
            new int begin = this.offset[i - 1].readInt() if i > 0 else a,
                    end   = this.offset[i].readInt();

            if end - begin > 1 {
                if end - begin > 16 {
                    MaxHeapSort.sort(array, begin, end);
                } else {
                    uncheckedInsertionSort(array, begin, end);
                }
            }
        }
    }
}



@Sort(
    "Distribution Sorts",
    "Static Sort [Utils.Iterables.fastSort]",
    "Static Sort"
);
new function staticSortRun(array) {
    StaticSort().sort(array, 0, len(array));
}
