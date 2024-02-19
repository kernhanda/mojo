# ===----------------------------------------------------------------------=== #
#
# This file is Modular Inc proprietary.
#
# ===----------------------------------------------------------------------=== #
"""Implements slice.

These are Mojo built-ins, so you don't need to import them.
"""

from math import limit
from sys.intrinsics import _mlirtype_is_eq


@always_inline("nodebug")
fn _int_max_value() -> Int:
    # FIXME: The `slice` type should have the concept of `None` indices, but the
    # effect of a `None` end index is the same as a very large end index.
    return int(limit.max_finite[DType.index]())


@always_inline("nodebug")
fn _default_or[T: AnyRegType](value: T, default: Int) -> Int:
    # TODO: Handle `__index__` for other types when we have traits!
    @parameter
    if _mlirtype_is_eq[T, Int]():
        return __mlir_op.`kgen.rebind`[_type=Int](value)
    else:
        __mlir_op.`kgen.param.assert`[
            cond = (_mlirtype_is_eq[T, NoneType]()).__mlir_i1__(),
            message = "expected Int or NoneType".value,
        ]()
        return default


@register_passable("trivial")
struct Slice(Sized):
    """Represents a slice expression.

    Objects of this type are generated when slice syntax is used within square
    brackets, e.g.:

    ```mojo
    var msg: String = "Hello Mojo"

    # Both are equivalent and print "Mojo".
    print(msg[6:])
    print(msg.__getitem__(Slice(6, len(msg))))
    ```
    """

    var start: Int
    """The starting index of the slice."""
    var end: Int
    """The end index of the slice."""
    var step: Int
    """The step increment value of the slice."""

    @always_inline("nodebug")
    fn __init__(end: Int) -> Self:
        """Construct slice given the end value.

        Args:
            end: The end value.

        Returns:
            The constructed slice.
        """
        return Self {start: 0, end: end, step: 1}

    @always_inline("nodebug")
    fn __init__(start: Int, end: Int) -> Self:
        """Construct slice given the start and end values.

        Args:
            start: The start value.
            end: The end value.

        Returns:
            The constructed slice.
        """
        return Self {start: start, end: end, step: 1}

    @always_inline("nodebug")
    fn __init__[
        T0: AnyRegType, T1: AnyRegType, T2: AnyRegType
    ](start: T0, end: T1, step: T2) -> Self:
        """Construct slice given the start, end and step values.

        Parameters:
            T0: Type of the start value.
            T1: Type of the end value.
            T2: Type of the step value.

        Args:
            start: The start value.
            end: The end value.
            step: The step value.

        Returns:
            The constructed slice.
        """
        return Self {
            start: _default_or(start, 0),
            end: _default_or(end, _int_max_value()),
            step: _default_or(step, 1),
        }

    @always_inline("nodebug")
    fn __eq__(self, other: Self) -> Bool:
        """Compare this slice to the other.

        Args:
            other: The slice to compare to.

        Returns:
            True if start, end, and step values of this slice match the
            corresponding values of the other slice and False otherwise.
        """
        return (
            self.start == other.start
            and self.end == other.end
            and self.step == other.step
        )

    @always_inline("nodebug")
    fn __ne__(self, other: Self) -> Bool:
        """Compare this slice to the other.

        Args:
            other: The slice to compare to.

        Returns:
            False if start, end, and step values of this slice match the
            corresponding values of the other slice and True otherwise.
        """
        return not (self == other)

    @always_inline("nodebug")
    fn __len__(self) -> Int:
        """Return the length of the slice.

        Returns:
            The length of the slice.
        """

        @always_inline("nodebug")
        fn div_ceil(numerator: Int, denominator: Int) -> Int:
            return (numerator + denominator - 1) // denominator

        if self.step > 0:
            return div_ceil(self.end - self.start, self.step)
        else:
            return div_ceil(self.start - self.end, -self.step)

    @always_inline
    fn __getitem__(self, idx: Int) -> Int:
        """Get the slice index.

        Args:
            idx: The index.

        Returns:
            The slice index.
        """
        return self.start + idx * self.step

    @always_inline("nodebug")
    fn _has_end(self) -> Bool:
        return self.end != _int_max_value()


@always_inline("nodebug")
fn slice(end: Int) -> Slice:
    """Construct slice given the end value.

    Args:
        end: The end value.

    Returns:
        The constructed slice.
    """
    return Slice(end)


@always_inline("nodebug")
fn slice(start: Int, end: Int) -> Slice:
    """Construct slice given the start and end values.

    Args:
        start: The start value.
        end: The end value.

    Returns:
        The constructed slice.
    """
    return Slice(start, end)


# TODO(30496): Modernize the slice type
@always_inline("nodebug")
fn slice[
    T0: AnyRegType, T1: AnyRegType, T2: AnyRegType
](start: T0, end: T1, step: T2) -> Slice:
    """Construct a Slice given the start, end and step values.

    Parameters:
        T0: Type of the start value.
        T1: Type of the end value.
        T2: Type of the step value.

    Args:
        start: The start value.
        end: The end value.
        step: The step value.

    Returns:
        The constructed slice.
    """
    return Slice(start, end, step)
