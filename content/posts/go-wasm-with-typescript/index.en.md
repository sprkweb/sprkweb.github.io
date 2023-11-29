---
title: "How to make Go, WebAssembly and TypeScript work together"
date: 2023-11-29
lastmod: 2023-11-29
tags: [Golang, "Development history", "Case"]
---

Recently in one [of my pet projects](https://github.com/sprkweb/finaplan-web/tree/fab272594212a8c390a57f4ff5aede30489c9f05) I added Go code compiled in WebAssembly (*WASM*) for client-side execution. The interface is made with Svelte with TypeScript, and the logic is implemented in Golang. As a result, I got an interesting experience that I want to share: how to make Go, WebAssembly and TypeScript work together.
<!--more-->

{{< table-of-contents >}}

## How to export Go function to JavaScript

Create a separate directory for Go module with `go.mod` and `main.go` files.

You cannot directly import functions from Go into JavaScript. Instead, your Go code running in a browser can create global functions or any other global variables for JavaScript.

You can register a global function for JavaScript like this:

```go
package main

import "syscall/js"

func myFunc(this js.Value, args []js.Value) any {
    return "hello"
}

func main() {
    // create a global variable MyFunc in JavaScript 
    // and assign a function to it
	js.Global().Set("MyFunc", js.FuncOf(myFunc))

    // wait indefinitely so that Go does not terminate execution 
    // and the function remains available
	<-make(chan struct{}) 
}
```

[`syscall/js`](https://pkg.go.dev/syscall/js) is a package from the Go standard library. The Go compiler and your IDE may complain that they don't know it. To avoid this, you should add a directive to the beginning of `main.go` that the file can be compiled only to WebAssembly:

```go
//go:build wasm
// +build wasm
package main

import (
	"syscall/js"
...
```

## Compiling Go code into WebAssembly

Compile with environment variables `GOOS=js` and `GOARCH=wasm`. You can make a `Makefile` for convenience:

```Makefile
build: copy-wasm-exec
	GOOS=js GOARCH=wasm go build -o main.wasm

copy-wasm-exec:
	cp $(shell go env GOROOT)/misc/wasm/wasm_exec.js .
```

The `make build` command does the compilation. The `make copy-wasm-exec` command copies the `wasm_exec.js` library from your version of Go. We'll need this library when running WebAssembly from JavaScript.

## Running Go code in JavaScript

In order to execute Go code compiled into WebAssembly, you need to import `wasm_exec.js`:

```typescript
// $go is an alias for path to our Go module
import '$go/wasm_exec' 
```

This file creates the `Go` class. Its TypeScript type:

```typescript
declare global {
    export interface Window {
        Go: {
            new (): {
                run: (inst: WebAssembly.Instance) => Promise<void>
                importObject: WebAssembly.Imports
            }
        }
	}
}
```

Running the WebAssembly binary in the browser is done using the [`WebAssembly.instantiateStreaming`](https://developer.mozilla.org/en-US/docs/WebAssembly/Loading_and_running), `fetch` and the imported `Go` class:

```typescript
// `wasm` variable contains URL
// of our WASM binary
import wasm from '$go/main.wasm?url' 

// load and run our Go code
export async function load() {
    if (!WebAssembly) {
        throw new Error('WebAssembly is not supported in your browser')
    }

    const go = new window.Go()
    const result = await WebAssembly.instantiateStreaming(
		// load the binary
        fetch(wasm), 
        go.importObject
    )

	// run it
    go.run(result.instance)

    // wait until it creates the function we need
    await until(() => window.MyFunc != undefined)
	// return the function
    return window.MyFunc
}

// helper Promise which waits until `f` is true
const until = (f: () => boolean): Promise<void> => {
    return new Promise(resolve => {
        const intervalCode = setInterval(() => {
            if (f()) {
                resolve()
                clearInterval(intervalCode)
            }
        }, 10)
    })
}
```

## How to create a JavaScript class via WebAssembly

In JavaScript, a class is a function that creates an object. In order to create such a class from Go, we need to create functions for its constructor and methods. In each function we need to convert the types: at the beginning we convert `js.Value` to the type we need and vice versa at the end.

```go
type wrapper struct {
	obj *mypkg.myObj
}

// Constructor of a JavaScript object
func NewObj(this js.Value, args []js.Value) any {
	// Convert `js.Value` arguments to the types we need
	name := args[0].String()
	number := args[1].Int()

	// Create an object
	wrap := &wrapper{
		obj: mypkg.NewObj(name, number)
	}
	
	// Convert our wrapper to
	// JavaScript object with two methods
	return js.ValueOf(map[string]any{
		"set": js.FuncOf(wrap.Set),
		"get": js.FuncOf(wrap.Get),
	})
}

// The object's method
func (w *wrapper) Set(this js.Value, args []js.Value) any {
	name := args[0].String()
	number := args[1].Int()

    res, err := w.obj.Set(name, number)
    if err != nil {
        return js.ValueOf(map[string]any{
            "error":  err.Error(),
        })
    }

	return js.ValueOf(map[string]any{
		"result": res,
	})
}
...
```

## Error handling

In Go code, you *can't* throw a JavaScript exception. If you throw a panic in Go code, it will terminate and you will no longer be able to call its functions.

If your function can fail, you can return an object that contains either a `result` or `error` field. In TypeScript notation, the interface looks like this:

```typescript
interface Result<T>{
    result?: T
    error?: string
}
```

Then error checking can be like this:

```typescript
const { result, error } = myobj.get()
if (error != undefined) {
    // handle error
} else {
    // handle result
}
```

## Create types for TypeScript

You should create TypeScript types for everything imported from Go:

```typescript
declare global {
    export interface Window {
        NewObj: (name: string, num: number) => MyObj
    }
}

export interface MyObj {
	get() => Result<number>
	set(name: string, num: number) => Result<number>
}
```

## All together

You can see an example of how it all fits together on GitHub:
- [Go module compiled to WebAssembly](https://github.com/sprkweb/finaplan-web/tree/fab272594212a8c390a57f4ff5aede30489c9f05/src/lib/go)
- [Running a WebAssembly binary and declaring TypeScript types](https://github.com/sprkweb/finaplan-web/blob/fab272594212a8c390a57f4ff5aede30489c9f05/src/routes/finaplan.ts)
