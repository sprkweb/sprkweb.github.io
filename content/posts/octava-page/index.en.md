---
title: "Development history: Octava Page"
date: 2021-05-31
lastmod: 2023-01-07
tags: ["Development history", "Case"]
---

Octava Page is a web application for novice musicians
that helps to understand the notes.
<!--more-->

{{< table-of-contents >}}

## How it looks now

[View →](https://sprkweb.github.io/octava-page/)

[GitHub repo →](https://github.com/sprkweb/octava-page)

The interface is a schematic guitar fretboard with the notes marked on it.

You can change the number of strings with the "+" and "-" buttons at the bottom, 
and you can adjust the scale of the guitar 
by entering notes on the open strings 
(the default is the standard 6-string EBGDAE scale).

You can also use the interface on the top to select a chord or scale and 
enter a root note, then the app will highlight the notes of 
that chord or scale on the fretboard.

Since the application is serverless and contains only static files, 
it can be installed as a Progressive Web Application (_PWA_) and 
it will work without the Internet. 
You do that by opening it in a separate tab and 
clicking on the "Add to home screen" link at the bottom of the page 
(if your browser supports PWA).

I used React, Snowpack, SASS, Bootstrap, and JavaScript for development.

## History

{{< img "first-version.jpg" "Screenshot of the first version" >}}

Initially, the application was not intended specifically for guitarists, 
but for any musicians (primarily me and my friends; 
I, for example, did not play guitar), despite the interface 
(and still can be used not only by them): 
the idea of the first version was based on displaying the octave of notes 
from a certain root note (as on the screenshot -- 
the root note is always numbered 0).

The supposed way to use it was like this:

1. The user knows the "structure" of some type of chord, e.g. major chords, 
but is still having difficulty "calculating" their notes in his mind
2. The root note is entered
3. The app builds an octave from it
4. The user, knowing that the notes of a major chord are 
4 and 3 semitones apart, respectively, looks up the notes with 
the numbers 0-4-7 -- these will be the notes that make up the chord.
5. Then he finds the corresponding notes on his own instrument -- 
not necessarily a guitar.

In other words, user was supposed to 
_abstract away from the specific arrangement of the fingers on the fretboard_ 
and look at the interface from the perspective of pure musical theory.

Similarly, the application could be used for many other purposes, 
including "calculating" the notes of scales (tone-tone-semitone, etc.), 
intervals, and finding the notes on the fretboard. This way the application is
simple, flexible and versatile, depending on how you look at its function.

The experience of using it with friends showed that it was 
not the most successful and intuitively understandable idea. 
So I added the ability to highlight chords and scales and 
the ability to use multiple "strings".

{{< img "second-version.png" "Screenshot of the second version" >}}

On the one hand, the application has become more functional and convenient 
(everything that could be done with it before can still be done 
in exactly the same way), but on the other hand, 
from the user's point of view it has become much more narrowly specialized:
a guitar fretboard with notes.
