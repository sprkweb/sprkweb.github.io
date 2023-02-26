---
title: "Maybe what you need is not floating-point numbers"
date: 2023-02-26
lastmod: 2023-02-26
tags: [Golang]
---

There are many features in programming languages that are prone to problems and should be used with caution. One of the most famous examples is the goto operator. Floating-point numbers should also be considered as such features.
<!--more-->

## Why?

I will not enumerate all possible problems of floating point numbers: most likely, you are already familiar with many of them, and if not, I recommend to read the following articles:

- [Examples of floating point problems](https://jvns.ca/blog/2023/01/13/examples-of-floating-point-problems/)
- [Ordering Numbers, How Hard Can It Be?](https://orlp.net/blog/ordering-numbers/)

Such behavior creates an additional cognitive load on the developer and room for errors. How many programmers can, without thinking much, say the minimum step for changing a specific floating-point number?

Don't get me wrong: the message of the article is not that floating point numbers should not be used. They are a tool with its own use cases. This article is about **when it is better to use other tools**.

## So what do we do?

If you want to use floating point numbers somewhere, you can consider the following possibilities instead:

### 1. Integers

Identifiers, counters, ordinal numbers are the most obvious examples of values that are better represented as integers. But there are many other cases in which, if you think twice, integers turn out to be the best solution. 

For example, if you want to store a fractional number of kilometers, then it may be worth presenting them not as kilometers, but as meters / centimeters / millimeters:

```go
// ❌ it is not exactly 17.529 kilometers
distanceKilometers := 17.529

// 👍 that's better!
distanceMeters := 17529
```

You can do the same with other physical quantities.

### 2. Decimal

In cases where the needed precision is not known beforehand, but it is very important that the representation in decimal format exactly matches the stored one (eg, for money amounts), you can use special libraries for decimal numbers.

In Python, for example, there is a module `decimal` in the standard library:

```python
>>> my_salary = 10.1
>>> print("{:.16f}".format(my_salary))
10.0999999999999996

>>> from decimal import *
>>> my_salary = Decimal('10.1')
>>> print("{:.16f}".format(my_salary))
10.1000000000000000
```

### 3. Rational numbers

Sometimes the numbers are divided by some known number, which may not be a multiple of ten:

```go
import "fmt"

func main() {
    fullPageWidth := 1000
    blocksAmount := 3
    blockWidth := fullPageWidth / blocksAmount

    if (blockWidth * blocksAmount) != fullPageWidth {
        fmt.Println("We need a perfect fit!") 
    } else {
        fmt.Println("Perfect!")
    }
}

//=> We need a perfect fit!
```

In such cases you can use rational numbers:

```go
import (
    "fmt"
    "math/big"
)

func main() {
    fullPageWidth := new(big.Rat).SetInt64(1000)
    blocksAmount := new(big.Rat).SetInt64(3)
    blockWidth := new(big.Rat).Quo(fullPageWidth, blocksAmount)

    if new(big.Rat).Mul(blockWidth, blocksAmount).Cmp(fullPageWidth) != 0 {
        fmt.Println("We need a perfect fit!")
    } else {
        fmt.Println("Perfect!")
    }
}

//=> Perfect!
```

### 4. Specialized types

Many databases and some languages already have predefined types for units such as time and money. It is worth learning about their availability and features: such types have already thought out the storage method and all the necessary operations.

## Conclusion

If you want to use fractional numbers, floating point numbers may not be what you need.

Floating point numbers should be used when precision is not important and approximate values are fine.

In other cases, you might use integers, decimals, rational numbers, and specialized types for values such as money and time instead.
