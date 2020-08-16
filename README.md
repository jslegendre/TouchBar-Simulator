# TouchBar Simulator

The first (open source) touchbar simulator (that I've seen) to use the new "2nd Generation" touchbar display APIs. If the other ones out there aren't working for you, this one might.  Even if the others are, this one doesn't suffer the same [bugs the others do](https://github.com/sindresorhus/touch-bar-simulator/issues/61).   

This simulator is also built the same way Apple built theirs for Xcode. Using an XPC service to render the touchbar display stream instead of the main app with the (also undocumented) ViewBridge framework. I would expect this to be pretty sturdy for at least the rest of Big Surs run.

Not to worry though, I'm sure this will get ~~ripped off~~ *ahem* "implemented" into the other apps.

