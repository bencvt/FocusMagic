# Focus Magic by bencvt

Automatically assign focus magic circles by typing `/fm`.

Any time there are more than a couple mages in a raid, it's a minor pain to assign who buffs their [Focus Magic](https://www.wowhead.com/wotlk/spell=54648/focus-magic) on whom.
The more mages, the more annoying it gets.

This small addon streamlines the process. Simply type `/fm` and assignments will be posted to party chat (when everyone's in the same group) or to raid chat (when the mages are in different groups).

## How assignments are made

Pretty simple:

1. Inspect every mage in the raid to verify that they spec into Focus Magic. (Frost and frostfire mages, shoo!)
2. Alphabetize the list of mages.
3. Go down the list and assign pairs of mages to FM each other.
4. If there is an odd number of mages, make the last group a circle of three.

## Examples

Two mages:  
`FM: Aegwynn<=>Antonidas`

Three mages:  
`FM alphabetically: Aegwynn=>Antonidas=>Jaina=>Aegwynn`

Four mages:  
`FM alphabetically: Aegwynn<=>Antonidas, Jaina<=>Khadgar`

Four mages but one of them doesn't spec into FM:  
`FM alphabetically: Aegwynn=>Jaina=>Khadgar=>Aegwynn (Antonidas does not have FM)`

Five mages:  
`FM alphabetically: Aegwynn<=>Antonidas, Jaina=>Khadgar=>Medivh=>Jaina`

And so on.

## Caveat

Alphabetic assignments are straightforward and work just fine for the vast majority of raid groups, but...

For highly organized raids with 4+ mages looking to min/max absolutely everything, you'll probably want to manually assign FMs instead, with your best mages paired up. This addon does not try to determine which mages are "best".
