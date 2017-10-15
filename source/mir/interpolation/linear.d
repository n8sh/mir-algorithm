/++
$(H2 Linear Interpolation)

See_also: $(REF_ALTTEXT $(TT interp1), interp1, mir, interpolation)

License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
Copyright: Copyright © 2017, Kaleidic Associates Advisory Limited
Authors:   Ilya Yaroshenko

Macros:
SUBREF = $(REF_ALTTEXT $(TT $2), $2, mir, interpolation, $1)$(NBSP)
T2=$(TR $(TDNW $(LREF $1)) $(TD $+))
+/
module mir.interpolation.linear;

import std.traits;
import mir.array.primitives;
import mir.ndslice.slice;
import mir.utility: fastmath;

@fastmath:

/++
Unbounded linear interpolation.
+/
struct LinearInterpolation(IG, IV)
{
    ///
    size_t _length;
    ///
    IG _grid;
    ///
    IV _values;

    private alias G = Unqual!(typeof(IG.init[0]));
    private alias V = Unqual!(typeof(IV.init[0]));

@trusted @fastmath:

    this()(Slice!(Contiguous, [1], IG) grid, Slice!(Contiguous, [1], IV) values) @system
    {
        assert (grid.length >= 2);
        assert (grid.length == values.length);
        this._length = grid.length;
        this._grid   = grid._iterator;
        this._values = values._iterator;
    }

    /++
    Interval index for x.
    +/
    size_t interval(T)(in T x)
    {
        import std.range: assumeSorted;
        return _grid.sliced(_length)[1 .. $ - 1]
            .assumeSorted
            .lowerBound(x)
            .length;
    }

    /++
    `(x)` and `[x]` operators.
    Complexity:
        `O(log(_grid.length))`
    +/
    auto opCall(uint derivative = 0, T)(T x)
    {
        return opCall(x, interval(x));
    }

    /++
    `(x, interval)` and `[x, interval]` operators.
    Complexity:
        `O(1)`
    +/
    auto opCall(uint derivative = 0, T)(in T x, size_t interval) @system
    {
        assert(interval + 1 < _length);

        auto x0 = _grid  [interval + 0];
        auto x1 = _grid  [interval + 1];
        auto y0 = _values[interval + 0];
        auto y1 = _values[interval + 1];

        return opCall(x0, x1, y0, y1, x);
    }

    ///
    static auto opCall(uint derivative = 0, T)(G x0, G x1, V y0, V y1, in T x)
        if (derivative <= 6)
    {
        immutable step = x1 - x0;
        immutable c0 = x - x0;
        immutable c1 = x1 - x;
        immutable w0 = c0 / step;
        immutable w1 = c1 / step;
        immutable r0 = y0 * w1;
        immutable r1 = y1 * w0;
        immutable y = r0 + r1;
        static if (derivative == 0)
        {
            return y;
        }
        else
        {
            typeof(y)[derivative + 1] ret = 0;
            ret[0] = y;
            return ret;
        }
    }

    /// ditto
    alias opIndex = opCall;
}

/++
Linear interpolation.

Params:
    grid = `x` values for interpolation
    values = `f(x)` values for interpolation

Constraints:
    `grid`, `values` must have the same length >= 3

Returns: $(LREF LinearInterpolation)
+/
LinearInterpolation!(IG, IV) linearInterpolation(IG, IV)(Slice!(Contiguous, [1], IG) grid, Slice!(Contiguous, [1], IV) values) @trusted
{
    if (grid.length < 2)
        assert(0);
    if (grid.length != values.length)
        assert(0);
    return typeof(return)(grid, values);
}

///
version(mir_test)
@safe unittest
{
    import mir.ndslice;
    import std.math: approxEqual;

    auto x = [0, 1, 2, 3, 5.00274, 7.00274, 10.0055, 20.0137, 30.0192];
    auto y = [0.0011, 0.0011, 0.0030, 0.0064, 0.0144, 0.0207, 0.0261, 0.0329, 0.0356,];
    auto xs = [1, 2, 3, 4.00274, 5.00274, 6.00274, 7.00274, 8.00548, 9.00548, 10.0055, 11.0055, 12.0082, 13.0082, 14.0082, 15.0082, 16.011, 17.011, 18.011, 19.011, 20.0137, 21.0137, 22.0137, 23.0137, 24.0164, 25.0164, 26.0164, 27.0164, 28.0192, 29.0192, 30.0192];

    auto interpolation = linearInterpolation(x.sliced, y.sliced);

    auto data = [0.0011, 0.0030, 0.0064, 0.0104, 0.0144, 0.0176, 0.0207, 0.0225, 0.0243, 0.0261, 0.0268, 0.0274, 0.0281, 0.0288, 0.0295, 0.0302, 0.0309, 0.0316, 0.0322, 0.0329, 0.0332, 0.0335, 0.0337, 0.0340, 0.0342, 0.0345, 0.0348, 0.0350, 0.0353, 0.0356];

    assert(approxEqual(xs.sliced.map!interpolation, data, 1e-4, 1e-4));
}
