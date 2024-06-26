# Copyright (c) 2023 thatsOven
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Lithium Sort
# 
# A conceptually optimal in-place block merge sorting algorithm.
# This algorithm introduces some ideas, that in conjunction with a heavier usage of
# scrolling buffers, code optimizations and other tricks (like the ones in Holy GrailSort),
# minimizes moves and comparisons for every step of the in-place block merge sorting procedure.
# 
# Time complexity: O(n log n) best/average/worst
# Space complexity: O(1)
# Stable: Yes
# 
# Special thanks to aphitorite for creating the kota merging algorithm, which enables
# strategy 1's block merging routine to be optimal; the dualMerge routine, which simplifies
# the rest of the code as well as improving performance; the buffer redistribution algorithm, 
# found in Adaptive Grailsort; the smarter block selection algorithm, used in the blockSelect
# routine, and part of the code for some of the other routines.
 
use blockSwap, backwardBlockSwap, compareValues,
    compareIntToValue, insertToRight, lrBinarySearch, 
    binaryInsertionSort, log2, BufMerge2, BitArray;

new class LithiumSort {
    new int RUN_SIZE           = 32,
            SMALL_SORT         = 256,
            MAX_STRAT4_UNIQUE  = 8,
            SMALL_MERGE        = 16;

    new method __init__() {
        this.bufLen = 0;
    }

    new method rotate(array, a, m, b) {
        new int rl   = b - m,
                ll   = m - a,
                bl   = this.bufLen,
                min_ = bl if rl != ll && min(bl, rl, ll) > LithiumSort.SMALL_MERGE else 1;

        while ll > min_ and rl > min_ {
            if rl < ll {
                blockSwap(array, a, m, rl);
                a  += rl;
                ll -= rl;
            } else {
                b  -= ll;
                rl -= ll;
                backwardBlockSwap(array, a, b, ll);
            }
        }

        if rl == 1 {
            insertToLeft(array, m, a);
        } elif ll == 1 {
            insertToRight(array, a, b - 1);
        }

        if min == 1 || rl <= 1 || ll <= 1 {
            return;
        }            
        
        if rl < ll {
            backwardBlockSwap(array, m, this.bufPos, rl);

            for i = m + rl - 1; i >= a + rl; i-- {
                array[i].swap(array[i - rl]);
            }

            backwardBlockSwap(array, this.bufPos, a, rl);
        } else {
            blockSwap(array, a, this.bufPos, ll);

            for i = a; i < b - ll; i++ {
                array[i].swap(array[i + ll]);
            }

            blockSwap(array, this.bufPos, b - ll, ll);
        }
    }

    new method findKeys(array, a, b, q) {
        new int n = 1,
                p = b - 1;

        for i = p; i > a && n < q; i-- {
            new int l = lrBinarySearch(array, p, p + n, array[i - 1], True) - p;
            if l == n || array[i - 1] < array[p + l] {
                this.rotate(array, i, p, p + n);
                n++;
                p = i - 1;
                insertToRight(array, i - 1, p + l);
            }
        }

        this.rotate(array, p, p + n, b);
        return n;
    }

    new method sortRuns(array, a, b) {
        new dynamic speed = sortingVisualizer.speed;
        sortingVisualizer.setSpeed(max(int(10 * (len(array) / 2048)), speed * 2));

        for i = a; i < b - LithiumSort.RUN_SIZE; i += LithiumSort.RUN_SIZE {
            binaryInsertionSort(array, i, i + LithiumSort.RUN_SIZE);
        }

        if i < b {
            binaryInsertionSort(array, i, b);
        }

        sortingVisualizer.setSpeed(speed);
    }

    new method mergeInPlaceBW(array, a, m, b, left) {
        new int s = b - 1,
                l = m - 1;

        while s > l && l >= a {
            new int cmp = compareValues(array[l], array[s]);
            if cmp > 0 if left else cmp >= 0 {
                new int p = lrBinarySearch(array, a, l, array[s], !left);
                this.rotate(array, p, l + 1, s + 1);
                s -= l + 1 - p;
                l = p - 1;
            } else {
                s--;
            }
        }
    }

    new method mergeWithBufferBW(array, a, m, b, left) {
        new int rl = b - m;

        if rl <= LithiumSort.SMALL_MERGE || rl > this.bufLen {
            this.mergeInPlaceBW(array, a, m, b, left);
            return;
        }

        backwardBlockSwap(array, m, this.bufPos, rl);

        new int l = m - 1,
                r = this.bufPos + rl - 1,
                o = b - 1;

        for ; l >= a && r >= this.bufPos; o-- {
            new int cmp = compareValues(array[r], array[l]);
            if cmp >= 0 if left else cmp > 0 {
                array[o].swap(array[r]);
                r--;
            } else {
                array[o].swap(array[l]);
                l--;
            }
        }

        for ; r >= this.bufPos; o--, r-- {
            array[o].swap(array[r]);
        }
    }

    new classmethod shift(array, a, m, b, left) {
        if left {
            if m == b {
                return;
            }

            while m > a {
                b--; m--;
                array[b].swap(array[m]);
            }
        } else {
            if (m == a) {
                return;
            }

            for ; m < b; a++, m++ {
                array[a].swap(array[m]);
            }
        }
    }

    new method dualMergeFW(array, a, m, b, r) {
        new int i = a,
                j = m,
                k = a - r;

        for ; k < i && i < m; k++ {
            if array[i] <= array[j] {
                array[k].swap(array[i]);
                i++;
            } else {
                array[k].swap(array[j]);
                j++;
            }
        }

        if k < i {
            this.shift(array, j - r, j, b, False);
        } else {
            new int i2 = m - 1,
                    j2 = b - 1;
            k = i2 + b - j;

            for ; i2 >= i && j2 >= j; k-- {
                if array[i2] > array[j2] {
                    array[k].swap(array[i2]);
                    i2--;
                } else {
                    array[k].swap(array[j2]);
                    j2--;
                }
            }

            for ; j2 >= j; k--, j2-- {
                array[k].swap(array[j2]);
            }
        }
    }

    new method swapKeys(array, bits, a, b) {
        if bits is None {
            array[this.keyPos + a].swap(array[this.keyPos + b]);
        } else {
            bits.swap(a, b);
        }
    }

    new method compareKeys(array, bits, a, b) {
        if bits is None {
            return compareValues(array[this.keyPos + a], array[this.keyPos + b]);
        } else {
            return compareValues(bits.get(a), bits.get(b));
        }
    }

    new method blockSelect(array, bits, a, leftBlocks, rightBlocks, blockLen) {
        new int i1 = 0,
                tm = leftBlocks,
                j1 = tm,
                k  = 0,
                tb = tm + rightBlocks;

        while k < j1 && j1 < tb {
            if array[a + (i1 + 1) * blockLen - 1] <= 
               array[a + (j1 + 1) * blockLen - 1] 
            {
                if i1 > k {
                    blockSwap(
                        array, 
                        a + k * blockLen, 
                        a + i1 * blockLen, 
                        blockLen
                    );
                }

                this.swapKeys(array, bits, k, i1);
                k++;

                i1 = k;
                for i = max(k + 1, tm); i < j1; i++ {
                    if this.compareKeys(array, bits, i, i1) < 0 {
                        i1 = i;
                    }
                }
            } else {
                blockSwap(
                    array, 
                    a + k * blockLen, 
                    a + j1 * blockLen, 
                    blockLen
                );

                this.swapKeys(array, bits, k, j1);
                j1++;

                if i1 == k {
                    i1 = j1 - 1;
                }
                k++;
            }
        }

        while k < j1 - 1 {
            if i1 > k {
                blockSwap(
                    array, 
                    a + k * blockLen, 
                    a + i1 * blockLen, 
                    blockLen
                );
            }

            this.swapKeys(array, bits, k, i1);
            k++;

            i1 = k;
            for i = k + 1; i < j1; i++ {
                if this.compareKeys(array, bits, i, i1) < 0 {
                    i1 = i;
                }
            }
        }
    }

    new method compareMidKey(array, bits, i, midKey) {
        if bits is None {
            return array[this.keyPos + i] < midKey;
        } else {
            return bits.get(i) < midKey;
        }
    }

    new method mergeBlocks(array, a, midKey, blockQty, blockLen, lastLen, bits) {
        new int f = a;
        new bool left = this.compareMidKey(array, bits, 0, midKey);
        
        for i = 1; i < blockQty; i++ {
            if left ^ this.compareMidKey(array, bits, i, midKey) {
                new int next    = a + i * blockLen,
                        nextEnd = lrBinarySearch(array, next, next + blockLen, array[next - 1], left);

                this.mergeWithBufferBW(array, f, next, nextEnd, left);
                f = nextEnd;
                !left;
            }
        }

        if left && lastLen != 0 {
            new int lastFrag = a + blockQty * this.blockLen;
            this.mergeWithBufferBW(array, f, lastFrag, lastFrag + lastLen, left);
        }
    }

    new method blockCycle(array, a, b, blockLen, bits) {
        new int total = (b - a) // blockLen;
        for i = 0; i < total; i++ {
            new int k = bits.get(i);
            if k != i {
                new int j = i;

                do {
                    blockSwap(array, a + k * blockLen, a + j * blockLen, blockLen);
                    bits.set(j, j);

                    j = k;
                    k = bits.get(k);
                } while k != i;
            
                bits.set(j, j);
            }
        }
    }
    
    new method kotaMerge(array, a, m, b, blockLen, bits) {
        new int c = 0,
                t = 2,
                i = a,
                j = m,
                k = this.bufPos,
                l = 0,
                r = 0; 
        
        for ; c < this.bufLen; k++, c++ {
            if array[i] <= array[j] {
                array[k].swap(array[i]);
                i++; l++;
            } else {
                array[k].swap(array[j]);
                j++; r++;
            }
        }

        new bool left = l >= r;
        k = i - l if left else j - r;
        c = 0;

        do {
            if i < m && (j == b || array[i] <= array[j]) {
                array[k].swap(array[i]);
                i++; l++;
            } else {
                array[k].swap(array[j]);
                j++; r++;
            }
            k++; 

            c++;
            if c == blockLen {
                bits.set(t, (k - a) // blockLen - 1);
                t++;

                if left {
                    l -= blockLen;
                } else {
                    r -= blockLen;
                }

                left = l >= r;
                k = i - l if left else j - r;
                c = 0;
            }
        } while i < m || j < b;

        new int b1 = b - c;

        blockSwap(array, k - c, b1, c);
        r -= c;

        t = 0;
        k = this.bufPos;

        while l > 0 {
            blockSwap(array, k, m - l, blockLen);
            bits.set(t, (m - a - l) // blockLen);
            t++;
            k += blockLen;
            l -= blockLen;
        }

        while r > 0 {
            blockSwap(array, k, b1 - r, blockLen);
            bits.set(t, (b1 - a - r) // blockLen);
            t++;
            k += blockLen;
            r -= blockLen;
        }
    }

    new method prepareKeys(bits, q) {
        for i in range(q) {
            bits.set(i, i);
        }
    }

    new method combine(array, a, m, b, bits) {
        if b - m <= this.bufLen {
            this.mergeWithBufferBW(array, a, m, b, True);
            return;
        }

        if this.dualBuf {
            this.kotaMerge(array, a, m, b, this.blockLen, bits);
            this.blockCycle(array, a, b, this.blockLen, bits);
        } else {
            new int leftBlocks  = (m - a) / this.blockLen,
                    rightBlocks = (b - m) / this.blockLen,
                    blockQty    = leftBlocks + rightBlocks,
                    frag        = (b - a) - blockQty * this.blockLen;

            new dynamic midKey;
            if bits is None {
                binaryInsertionSort(array, this.keyPos, this.keyPos + blockQty + 1);
                midKey = array[this.keyPos + leftBlocks];
            } else {
                this.prepareKeys(bits, blockQty);
                midKey = leftBlocks;
            }

            this.blockSelect(
                array, bits, a, leftBlocks,
                rightBlocks, this.blockLen
            );

            this.mergeBlocks(
                array, a, midKey,
                blockQty, this.blockLen,
                frag, bits
            );
        }
    }

    new method strat3BLenCalc(twoR, r) {
        new int sqrtTwoR = 1;
        for ; sqrtTwoR * sqrtTwoR < twoR; sqrtTwoR *= 2 {}
        for ; twoR // sqrtTwoR > r // (2 * (log2(twoR // sqrtTwoR) + 1)); sqrtTwoR *= 2 {}
        this.blockLen = sqrtTwoR;
    }

    new method noBitsBLenCalc(twoR) {
        new int kLen = this.keyLen,
                kBuf = (kLen + (kLen & 1)) // 2,
                bLen = 1, target;

        if kBuf >= twoR // kBuf {
            this.bufLen = kBuf;
            this.bufPos = this.keyPos + this.keyLen - kBuf;
            target = kBuf;
        } else {
            this.bufLen = 0;
            target = twoR // kLen;
        }

        for ; bLen <= target; bLen *= 2 {}
        this.blockLen = bLen;
    }

    new method resetBuf() {
        this.bufPos   = this.keyPos;
        this.bufLen   = this.keyLen;
        this.blockLen = this.origBlockLen;
    }

    new method checkValidBitArray(array, a, b, size) {
        return array[a + size] < array[b - size];
    }

    new method firstMerge(array, a, m, b, strat3) {
        if b - m <= this.bufLen {
            this.mergeWithBufferBW(array, a, m, b, True);
            return;
        }

        new int m1 = a + (m - a) // 2,
                m2 = lrBinarySearch(array, m, b, array[m1], True),
                m3 = m1 + m2 - m;

        this.rotate(array, m1, m, m2);

        new int twoR = b - m3;
        if strat3 {
            this.strat3BLenCalc(twoR, m1 - a);
        }

        new int nW   = twoR // this.blockLen,
                w    = log2(nW) + 1,
                size = nW * w;

        if this.checkValidBitArray(array, a, m1, size) {
            m3 = m2 - ((m2 - m3) // this.blockLen) * this.blockLen;

            new BitArray bits = BitArray(array, a, m1 - size, nW, w);
            this.combine(array, m3, m2, b, bits);
            bits.free();
        } else {
            this.noBitsBLenCalc(twoR);
            m3 = m2 - ((m2 - m3) // this.blockLen) * this.blockLen;

            new bool dualBuf = this.dualBuf;
            this.dualBuf = False;
            this.combine(array, m3, m2, b, None);
            this.dualBuf = dualBuf;
            this.resetBuf();
        }

        twoR = m3 - a;
        if strat3 {
            this.strat3BLenCalc(twoR, b - m3);
        }

        nW   = twoR // this.blockLen;
        w    = log2(nW) + 1;
        size = nW * w;

        new bool frag;
        new int m4, m5;
        if this.checkValidBitArray(array, m3, b, size) {
            m4 = a + ((m1 - a) // this.blockLen) * this.blockLen;
            m5 = m3 - (m1 - m4);

            frag = m4 != m1;
            if frag {
                this.rotate(array, m4, m1, m3);
            }

            new BitArray bits = BitArray(array, m3, b - size, nW, w);
            this.combine(array, a, m4, m5, bits);
            bits.free();
        } else {
            this.noBitsBLenCalc(twoR);
            m4 = a + ((m1 - a) // this.blockLen) * this.blockLen;
            m5 = m3 - (m1 - m4);

            frag = m4 != m1;
            if frag {
                this.rotate(array, m4, m1, m3);
            }

            new bool dualBuf = this.dualBuf;
            this.dualBuf = False;
            this.combine(array, a, m4, m5, None);
            this.dualBuf = dualBuf;
            this.resetBuf();
        }

        if frag {
            this.mergeWithBufferBW(array, a, m3, m5, False);
        }
    }

    new method lithiumLoop(array, a, b) {
        new int r = LithiumSort.RUN_SIZE,
                e = b - this.keyLen;
        while r <= this.bufLen {
            new int twoR = r * 2;
            for i = a; i < e - twoR; i += twoR {}

            if i + r < e {
                BufMerge2.mergeWithScrollingBufferBW(array, i, i + r, e);
            } else {
                this.shift(array, i, e, e + r, True);
            }

            for i -= twoR; i >= a; i -= twoR {
                BufMerge2.mergeWithScrollingBufferBW(array, i, i + r, i + twoR);
            }

            new int oldR = r;
            r = twoR;
            twoR *= 2;

            for i = a + oldR; i + twoR < e + oldR; i += twoR {
                this.dualMergeFW(array, i, i + r, i + twoR, oldR);
            }

            if i + r < e + oldR {
                this.dualMergeFW(array, i, i + r, e + oldR, oldR);
            } else {
                this.shift(array, i - oldR, i, e + oldR, False);
            }

            r = twoR;
        }

        b = e;
        e += this.keyLen;

        new bool strat3 = this.blockLen == 0;

        new int twoR = r * 2;
        while twoR < b - a {
            new int i = a + twoR;
            this.firstMerge(array, a, a + r, i, strat3);

            if strat3 {
                this.strat3BLenCalc(twoR, r);
            }

            new int nW   = twoR // this.blockLen,
                    w    = log2(nW) + 1,
                    size = nW * w;

            new dynamic bits;
            new bool dualBuf = this.dualBuf;
            if this.checkValidBitArray(array, a, a + twoR, size) {
                bits = BitArray(array, a, a + twoR - size, nW, w);
            } else {
                bits = None;
                this.dualBuf = False;
                this.noBitsBLenCalc(twoR);
            }

            for ; i < b - twoR; i += twoR {
                this.combine(array, i, i + r, i + twoR, bits);
            }

            if i + r < b {
                this.combine(array, i, i + r, b, bits);
            }

            if bits is None {
                this.resetBuf();
                this.dualBuf = dualBuf;
            } else {
                bits.free();
            }

            r = twoR;
            twoR *= 2;
        }

        this.firstMerge(array, a, a + r, b, strat3);

        this.bufLen = 0;
        binaryInsertionSort(array, b, e);
        
        r = lrBinarySearch(array, a, b, array[e - 1], False);
        this.rotate(array, r, b, e);

        new int d = b - r;
        e -= d;
        b -= d;

        new int b0 = b + (e - b) // 2;
        r = lrBinarySearch(array, a, b, array[b0 - 1], False);
        this.rotate(array, r, b, b0);

        d   = b - r;
        b0 -= d;
        b  -= d;

        this.mergeInPlaceBW(array, b0, b0 + d, e, True);
        this.mergeInPlaceBW(array, a, b, b0, True);
    }

    new method inPlaceMergeSort(array, a, b) {
        this.sortRuns(array, a, b);

        new int r = LithiumSort.RUN_SIZE;
        while r < b - a {
            new int twoR = r * 2;
            for i = a; i < b - twoR; i += twoR {
                this.mergeInPlaceBW(array, i, i + r, i + twoR, True);
            }

            if i + r < b {
                this.mergeInPlaceBW(array, i, i + r, b, True);
            }

            r = twoR;
        }
    }

    new method sort(array, a, b, doDualBuf = True) {
        new int n = b - a;
        if n <= LithiumSort.SMALL_SORT {
            this.inPlaceMergeSort(array, a, b);
            return;
        }

        new int sqrtn = 1;
        for ; sqrtn * sqrtn < n; sqrtn *= 2 {}

        new int ideal = 2 * sqrtn if doDualBuf else sqrtn;
        new int keysFound = this.findKeys(array, a, b, ideal);

        if keysFound <= LithiumSort.MAX_STRAT4_UNIQUE {
            this.inPlaceMergeSort(array, a, b);
            return;
        }

        this.bufPos       = b - keysFound;
        this.bufLen       = keysFound;
        this.keyLen       = keysFound;
        this.keyPos       = this.bufPos;
        this.origBlockLen = sqrtn;

        if keysFound == ideal && doDualBuf {
            this.blockLen = sqrtn;
            this.dualBuf  = True;
        } elif keysFound >= sqrtn {
            this.blockLen = sqrtn;
            this.dualBuf  = False;
        } else {
            this.blockLen = 0;
            this.dualBuf  = False;
        }

        this.sortRuns(array, a, b - keysFound);
        this.lithiumLoop(array, a, b);
    }
}

@Sort(
    "Block Merge Sorts",
    "Lithium Sort",
    "Lithium Sort",
);
new function lithiumSortRun(array) {
    LithiumSort().sort(array, 0, len(array));
}