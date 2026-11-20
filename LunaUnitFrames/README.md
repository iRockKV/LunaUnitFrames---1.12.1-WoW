# LunaUnitFrames (v2225 Fork)

iRock's customized fork of **LunaUnitFrames v2225** for WoW Vanilla (1.12.1), optimized for **Kronos V**.
<img width="2144" height="662" alt="LunaExample" src="https://github.com/user-attachments/assets/69d79065-b481-4b3d-9fa1-e1508e2a1d06" />
> **Important:** This fork strictly depends on **SuperWoW** and **UnitXP** (or **wow_Turbo**) to function properly.

## Requirements

* WoW Vanilla 1.12.1 client
* **SuperWoW** (required for 2D unit coordinates & extended APIs)
* **UnitXP** or **wow_Turbo** (required for C++ Line of Sight checks)

## Key Features & Changes

* **Precision Range & LoS System:**
  * Exact 2D range fade-out at > 39.5 yards or when out of Line of Sight (LoS).
  * LoS Frame Indicator: Displays a distinct frame border when a target is within casting range but LoS.
  *  Because Kronos V features enhanced LoS mechanics, where certain trees or objects may still allow spellcasting despite LoS flags, 
  *	this gives healers exact positional awareness.
  
* **Fixed HealComm:**
  * Resolved issues with incoming heal predictions for reliable raid healing.
  
* **Customized Aura Squares (squares.lua`):**
  * Tracks high-priority raid/PvP buffs (e.g., *Last Stand, Innervate, Arcane Power, WSG Flags*) and critical debuffs (e.g., *Mortal Strike, Weakened Soul, Conflagration, Veil of Shadow*).
  * Features **3 dedicated Buff/Debuff slots**: configure your class buffs (like *Power Word: Fortitude* or *Mark of the Wild*) ingame, while high-priority buffs and debuffs temporarily override them when active. You can customize the buffs and debuffs you want to track in squares.lua.
  
* **HoT Tracking:**
  * Visual icons tracking for active Hots spells (*Rejuvenation, Renew, Regrowth*).
  
* **Ticker**
  *Continuously displays the 2-second ticker for mana and energy regeneration and rage decay, as well as the indicator for the 5-second rule. Enables ‘Drink or Eat Walking’

All credits to:
  # LunaUnitFrames
Unit Frames for WoW 1.12.1
Feel free to fork this but give credit (at least author & link to this github)
DO NOT REUPLOAD! LINK HERE INSTEAD.
paypal.me/LunaUnitFrames
Donations are non-refundable / don't entitle you to anything
https://github.com/Aviana/LunaUnitFrames
https://github.com/gnwl/LunaUnitFrames