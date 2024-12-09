---
title: "Как подружить Go, WebAssembly и TypeScript"
date: 2023-11-29
lastmod: 2023-11-29
tags: [Golang, "История разработки", "Кейс"]
---

Недавно в [одном из пет-проектов](https://github.com/sprkweb/finaplan-web/tree/fab272594212a8c390a57f4ff5aede30489c9f05) добавил код на Go, скомпилированный в WebAssembly (*WASM*) для выполнения на стороне клиента. Интерфейс выполнен на Svelte с TypeScript, а на Golang реализуется логика. В результате я получил интересный опыт, которым хочу поделиться: как гармонично подружить между собой Go, WebAssembly и TypeScript.
<!--more-->

{{< table-of-contents >}}

## Как экспортировать Go функцию в JavaScript

Создайте отдельную директорию для Go модуля -- с файлами `go.mod` и `main.go`.

Напрямую импортировать функции из Go в JavaScript нельзя. Вместо этого ваш Go код, запущенный в браузере, может создать для JavaScript глобальные функции или любые другие глобальные переменные. 

Зарегистрировать для JavaScript глобальную функцию можно так:

```go
package main

import "syscall/js"

func myFunc(this js.Value, args []js.Value) any {
    return "hello"
}

func main() {
    // создаём в JavaScript глобальную переменную MyFunc
    // и присваиваем ей функцию
	js.Global().Set("MyFunc", js.FuncOf(myFunc))

    // ждём бесконечно, чтобы Go не завершил выполнение и 
    // функция были доступна
	<-make(chan struct{}) 
}
```

[`syscall/js`](https://pkg.go.dev/syscall/js) -- пакет из стандартной библиотеки Go. Компилятор Go и среда разработки могут ругаться, что они его не знают. Чтобы этого избежать, в начало `main.go` нужно добавить директиву о том, что файл должен компилироваться только в WebAssembly:

```go
//go:build wasm
// +build wasm
package main

import (
	"syscall/js"
...
```

## Компиляция Go кода в WebAssembly

Компилировать нужно с переменными окружения `GOOS=js` и `GOARCH=wasm`. Для удобства можно сделать `Makefile`:

```Makefile
build: copy-wasm-exec
	GOOS=js GOARCH=wasm go build -o main.wasm

copy-wasm-exec:
	cp $(shell go env GOROOT)/misc/wasm/wasm_exec.js .
```

Команда `make build` выполняет компиляцию, а `make copy-wasm-exec` -- копирует библиотеку `wasm_exec.js` из вашей версии Go -- она нам понадобится при запуске WebAssembly из JavaScript.

## Запуск Go кода в JavaScript

Для выполнения Go кода, скомпилированного в WebAssembly, нужно импортировать `wasm_exec.js`:

```typescript
// $go - алиас для пути к нашей директории с кодом на Go
import '$go/wasm_exec' 
```

Этот файл создаёт класс `Go`. Его TypeScript тип:

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

Запуск WebAssembly бинарника в браузере производится с помощью связки [`WebAssembly.instantiateStreaming`](https://developer.mozilla.org/en-US/docs/WebAssembly/Loading_and_running), `fetch` и импортированного класса `Go`:

```typescript
// переменная wasm будет содержать URL
// нашего скомпилированного WASM бинарника
import wasm from '$go/main.wasm?url' 

// функция, загружающая и запускающая наш Go код
export async function load() {
    if (!WebAssembly) {
        throw new Error('WebAssembly is not supported in your browser')
    }

    const go = new window.Go()
    const result = await WebAssembly.instantiateStreaming(
		// загружаем бинарник
        fetch(wasm), 
        go.importObject
    )

	// запускаем
    go.run(result.instance)

    // ждём, пока он создаст нужную нам функцию
    await until(() => window.MyFunc != undefined)
	// возвращаем эту функцию
    return window.MyFunc
}

// вспомогательный промис, который ждёт, пока условие f станет true
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

## Как создать JavaScript класс через WebAssembly

В JavaScript класс -- это функция, которая создаёт объект. Чтобы создать такой класс из Go, нужно создать функции для его конструктора и методов. В каждой функции нужно конвертировать типы: в начале -- из типа `js.Value` в нужный нам, в конце -- обратно.

```go
// Обёртка вокруг объекта myObj
type wrapper struct {
	obj *mypkg.myObj
}

// Конструктор JavaScript объекта
func NewObj(this js.Value, args []js.Value) any {
	// Конвертируем аргументы из типа js.Value в нужные нам
	name := args[0].String()
	number := args[1].Int()

	// Создаём объект
	wrap := &wrapper{
		obj: mypkg.NewObj(name, number)
	}
	
	// Конвертируем наш объект wrapper в
	// JavaScript объект, содержащий два метода
	return js.ValueOf(map[string]any{
		"set": js.FuncOf(wrap.Set),
		"get": js.FuncOf(wrap.Get),
	})
}

// Метод объекта
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

## Обработка ошибок

В Go коде вы *не можете* вызвать исключение (throw exception) JavaScript. Если вызвать панику в Go коде, то он завершит свою работу и вы больше не сможете вызвать его функции.

Если ваша функция может завершиться с ошибкой, то можно возвращать объект, который содержит либо поле `result`, либо `error`. В нотации TypeScript интерфейс выглядит так:

```typescript
interface Result<T>{
    result?: T
    error?: string
}
```

Тогда проверять ошибки можно так же, как это обычно делается в Go:

```typescript
const { result, error } = myobj.get()
if (error != undefined) {
    // обработать ошибку
} else {
    // обработать результат
}
```

## Создаём типы для TypeScript

Под всё, что импортируется из Go, стоит создать типы TypeScript:

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

## Всё вместе

Посмотреть пример того, как это всё сочетается, можно на GitHub:
- [Go модуль, компилируемый в WebAssembly](https://github.com/sprkweb/finaplan-web/tree/fab272594212a8c390a57f4ff5aede30489c9f05/src/lib/go)
- [Запуск WebAssembly бинарника и объявление типов TypeScript](https://github.com/sprkweb/finaplan-web/blob/fab272594212a8c390a57f4ff5aede30489c9f05/src/routes/finaplan.ts)
