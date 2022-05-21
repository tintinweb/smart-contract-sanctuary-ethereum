/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract GhostIdentifier
{
    function instructionsIdentify() public pure returns(string memory)
    {
        return "Input ghost signs in ascending order. 1 - EMF, 2 - Orb, 3 - Spirit Box, 4 - Freezing, 5 - Fingerprints, 6 - Writing, 7 - D.O.T.S";
    }
    function identifyGhost(int32 features) public pure returns(string memory)
    {
        if (features == 257) return "Banshee";
        if (features == 456) return "Demon";
        if (features == 157) return "Goryo";
        if (features == 245) return "Hantu";
        if (features == 145) return "Jinn";
        if (features == 236) return "Mare";
        if (features == 156) return "Myling";
        if (features == 125) return "Obake";
        if (features == 147) return "Oni";
        if (features == 234) return "Onryo";
        if (features == 357) return "Phantom";
        if (features == 356) return "Poltergeist";
        if (features == 127) return "Raiju";
        if (features == 246) return "Revenant";
        if (features == 146) return "Shade";
        if (features == 136) return "Spirit";
        if (features == 345) return "Mimic";
        if (features == 134) return "Twins";
        if (features == 137) return "Wraith";
        if (features == 237) return "Yokai";
        if (features == 247) return "Yurei";
        return "Wrong input. Please read the instructions and try again.";
    }
    function compareStrings(string memory s1, string memory s2) public pure returns(bool)
    {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
    function instructionsInfo() public pure returns(string memory)
    {
        return "Input the name of the ghost and what kind of information you need. 0 - signs, 1 - unique traits";
    }
    function ghostInfo(string memory name,  uint8 choice) public pure returns(string memory)
    {
        if (choice == 0)
        {
            if (compareStrings(name, "Banshee")) return "Orb, Fingerprints, D.O.T.S";
            if (compareStrings(name, "Demon")) return "Freezing, Fingerprints, Writing";
            if (compareStrings(name, "Goryo")) return "EMF, Fingerprints, D.O.T.S";
            if (compareStrings(name, "Hantu")) return "Orb, Freezing, Fingerprints";
            if (compareStrings(name, "Jinn")) return "EMF, Freezing, Fingerprints";
            if (compareStrings(name, "Mare")) return "Orb, Spirit Box, Writing";
            if (compareStrings(name, "Myling")) return "EMF, Fingerprints, Writing";
            if (compareStrings(name, "Obake")) return "EMF, Orb, Fingerprints";
            if (compareStrings(name, "Oni")) return "EMF, Freezing, D.O.T.S";
            if (compareStrings(name, "Onryo")) return "Orb, Spirit Box, Freezing";
            if (compareStrings(name, "Phantom")) return "Spirit Box, Fingerprints, D.O.T.S";
            if (compareStrings(name, "Poltergeist")) return "Spirit Box, Fingerprints, Writing";
            if (compareStrings(name, "Raiju")) return "EMF, Orb, D.O.T.S";
            if (compareStrings(name, "Revenant")) return "Orb, Freezing, Writing";
            if (compareStrings(name, "Shade")) return "EMF, Freezing, Writing";
            if (compareStrings(name, "Spirit")) return "EMF, Spirit Box, Writing";
            if (compareStrings(name, "Mimic")) return "Spirit Box, Freezing, Fingerprints";
            if (compareStrings(name, "Twins")) return "EMF, Spirit Box, Freezing";
            if (compareStrings(name, "Wraith")) return "EMF, Spirit Box, D.O.T.S";
            if (compareStrings(name, "Yokai")) return "Orb, Spirit Box, D.O.T.S";
            if (compareStrings(name, "Yurei")) return "Orb, Freezing, D.O.T.S";
            return "Wrong ghost name.";
        }
        if (choice == 1)
        {
            if (compareStrings(name, "Banshee"))  return "Tends to focus on a single player until they are killed or have left the game. Makes unique sounds on a parabolic microphone";
            if (compareStrings(name, "Demon")) return "Hunts extremely frequently if your sanity is below 70%. Fears the crucifix, the item has increased effective range against a Demon";
            if (compareStrings(name, "Goryo")) return "Can only be seen passing through a D.O.T.S on video camera. Rarely leaves its ghost room.";
            if (compareStrings(name, "Hantu")) return "Moves much quicker in colder areas. Emits frosty breath in freezing rooms.";
            if (compareStrings(name, "Jinn")) return "Travels at faster speeds as long as the distance between the Jinn and the target is greater than 2 metres. Has a unique ability, upon using which each player within a 3 meter radius loses 25% of their sanity.";
            if (compareStrings(name, "Mare")) return "Can hunt at higher sanity levels, will try to turn off the lights more often. When performing a ghost event, it is most likely to choose the one where lightbulbs would explode. However, turning lights on will lower its sanity hunt threshold to 40%.";
            if (compareStrings(name, "Myling")) return "Has quieter footsteps during hunts. Produces paranormal sounds more frequently.";
            if (compareStrings(name, "Obake")) return "Can leave fingerprints that disappear quickly. May leave behind six-fingered fingerprints.";
            if (compareStrings(name, "Oni")) return "More active when people are nearby, throws objects at great speeds. Easy to identify due to its high activity.";
            if (compareStrings(name, "Onryo")) return "Chance to hunt at any sanity by blowing off a candle. Blows candles more often, presence of flames prevent the ghost from hunting.";
            if (compareStrings(name, "Phantom")) return "Drains sanity from those who look at it. Temporarily disappears when photographed.";
            if (compareStrings(name, "Poltergeist")) return "Can throw multiple objects at once, decreases sanity by throwing objects. Ineffective in rooms with no throwable objects.";
            if (compareStrings(name, "Raiju")) return "A Raiju can siphon power from nearby electrical sources, thus making it move faster. They are easy to identify due to this disruptive trait.";
            if (compareStrings(name, "Revenant")) return "Travels at very high speed while chasing its target. Travels slowly when line of sight is broken.";
            if (compareStrings(name, "Shade")) return "Rarely performs actions when multiple people are nearby. Doesn't hunt as long as you stay in group.";
            if (compareStrings(name, "Spirit")) return "Using Smudge Sticks will prevent Spirits from hunting for a long time (180 seconds comparing to 90 for other ghosts).";
            if (compareStrings(name, "Mimic")) return "Can mimic actions of other ghosts. Induces ghost orbs as fourth evidence.";
            if (compareStrings(name, "Twins")) return "Either twin acts as a separate ghost, so multiple hunts could take place at the same time. The Twins will usually often interact with the environment at the same time.";
            if (compareStrings(name, "Wraith")) return "Never touches the ground, doesn't leave footprints. Has a toxic reaction to salt.";
            if (compareStrings(name, "Yokai")) return "Talking near it will increase its chance of hunting. Can only hear and detect electronics within 2 metres of it.";
            if (compareStrings(name, "Yurei")) return "Has a greater impact on the player's sanity.";
            return "Wrong ghost name";
        }
        return "Incorrect input. Please read the instructions and try again.";
    }
}