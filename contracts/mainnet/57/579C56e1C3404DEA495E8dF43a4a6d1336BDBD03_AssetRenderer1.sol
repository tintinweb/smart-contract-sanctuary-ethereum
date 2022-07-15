// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "../Structs/Miner.sol";

library AssetRenderer1 {
    using Strings for *;

    /**
    * @notice generate CSS color variables
    * @param colorId color id of skintone
    * @return string of css
    */
    function cssSkinVar(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[16] memory COLORS = [
            'var(--dm59)',  // 0  | porcelain
            'var(--dm58)',  // 1  | creme
            'var(--dm57)',  // 2  | sienna
            'var(--dm56)',  // 3  | sand
            'var(--dm55)',  // 4  | beige
            'var(--dm54)',  // 5  | honey
            'var(--dm53)',  // 6  | almond
            'var(--dm52)',  // 7  | bronze
            'var(--dm51)',  // 8  | espresso
            'var(--dm50)',  // 9  | ebony
            'var(--dm5)',   // 10 | demon
            'var(--dm17)',  // 11 | orc
            'var(--dm26)',  // 12 | djinn
            'var(--dm39)',  // 13 | spectre
            'var(--dm2)',   // 14 | mystic
            'var(--dm34)'   // 15 | golem
        ];
        return string(abi.encodePacked(
            '%253Cstyle%253E:root{--dms:',
            COLORS[colorId],
            ';'
        ));
    }

    /**
    * @notice generate CSS color variables
    * @param colorId color id of hair color
    * @return string of css
    */
    function cssHairVar(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[8] memory COLORS = [
            'var(--dm48)',  // 0 | light brown
            'var(--dm46)',  // 1 | dark brown
            'var(--dm41)',  // 2 | dirty blonde
            'var(--dm13)',  // 3 | blonde
            'var(--dm36)',  // 4 | gray
            'var(--dm43)',  // 5 | dark brownish/gray
            'var(--dm24)',  // 6 | black
            'var(--dm11)'   // 7 | orange/red

        ];
        return string(abi.encodePacked(
            '--dmh:',
            COLORS[colorId],
            ';'
        ));
    }

    /**
    * @notice generate CSS color variables
    * @param colorId color id of eye color
    * @return string of css
    */
    function cssEyeVar(uint256 colorId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[13] memory COLORS = [
            'black',        // 0  | black
            'var(--dm29)',  // 1  | gray
            'var(--dm20)',  // 2  | light green
            'var(--dm17)',  // 3  | green
            'var(--dm41)',  // 4  | amber
            'var(--dm45)',  // 5  | light brown
            'var(--dm47)',  // 6  | brown
            'var(--dm28)',  // 7  | light blue
            'var(--dm26)',  // 8  | blue
            'var(--dm11)',  // 9  | orange
            'var(--dm2)',   // 10 | purple
            'var(--dm5)',   // 11 | red
            'transparent'   // 12 | none
        ];
        return string(abi.encodePacked(
            '--dmi:',
            COLORS[colorId],
            '}%253C/style%253E'
        ));
    }

    /**
    * @notice generate CSS color variables for gear items
    * @param gearId gear id of gear item
    * @return string of css
    */
    function cssVar(uint256 gearId)
        external
        pure
        returns (string memory)
    {
        // Array of potential color values
        string[46] memory COLORS = [
            'var(--dm14)',      // 0  | BRIGHT YELLOW
            'var(--dm42)',      // 1  | LIGHT DULL YELLOW
            'var(--dm44)',      // 2  | DULL BROWN
            'var(--dm48)',      // 3  | BRIGHT BROWN
            'var(--dm43)',      // 4  | DARK DULL BROWN
            'var(--dm37)',      // 5  | GRAY
            'var(--dm36)',      // 6  | DARK GRAY
            'var(--dm38)',      // 7  | LIGHT GRAY
            'var(--dm41)',      // 8  | DARK ORANGE
            'var(--dm11)',      // 9  | ORANGE
            'var(--dm12)',      // 10 | BRIGHT YELLOW
            'var(--dm2)',       // 11 | BRIGHT PURPLE & skintone 14
            'var(--dm17)',      // 12 | GREEN && skintone 12
            'var(--dm46)',      // 13 | DARK BROWN
            'var(--dm49)',      // 14 | MID BRIGHT BROWN
            'var(--dm32)',      // 15 | LIGHT BLUE
            'var(--dm10)',      // 16 | LIGHT PINK
            'white',            // 17 | WHITE
            'var(--dm15)',      // 18 | LIGHT YELLOW
            'var(--dm35)',      // 19 | DARK GRAY
            'var(--dm37)',      // 20 | MID GRAY
            'var(--dm1)',       // 21 | DARK PURPLE
            'var(--dm25)',      // 22 | DARK BLUE
            'var(--dm26)',      // 23 | LIGHT BLUE
            'var(--dm19)',      // 24 | LIGHT GREEN
            'var(--dm52)',      // 25 | DARK BROWN & skintone 8
            'var(--dm21)',      // 26 | SLIME GREEN
            'var(--dm20)',      // 27 | LIGHT GREEN
            'var(--dm59)',      // 28 | skintone 1
            'var(--dm58)',      // 29 | skintone 2
            'var(--dm57)',      // 30 | skintone 3
            'var(--dm56)',      // 31 | skintone 4
            'var(--dm55)',      // 32 | skintone 5
            'var(--dm54)',      // 33 | skintone 6
            'var(--dm53)',      // 34 | skintone 7
            'var(--dm51)',      // 35 | skintone 9
            'var(--dm50)',      // 36 | skintone 10
            'var(--dm5)',       // 37 | skintone 11
            'var(--dm26)',      // 38 | skintone 13
            'var(--dm39)',      // 39 | skintone 14
            'var(--dm2)',       // 40 | skintone 15
            'url(%2523ch)',     // 41 | chain
            'url(%2523ch2)',    // 42 | chain2
            'url(%2523ch3)',    // 43 | chain3
            'var(--dms)',       // 44 | skintone
            'transparent'       // 45 | transparent
        ];
        if(gearId < 17){
            return '';
        } else if(gearId < 34){
            uint8[4] memory gear = [
                [0,1,0,45],
                [2,1,0,45],
                [3,1,0,45],
                [8,1,0,43],
                [2,4,2,45],
                [7,5,7,42],
                [8,5,7,9],
                [9,5,10,10],
                [5,5,7,7],
                [7,7,17,6],
                [3,3,3,11],
                [3,3,3,12],
                [6,7,17,9],
                [8,5,9,9],
                [3,3,8,8],
                [3,3,13,14],
                [15,15,16,16]
            ][gearId - 17];
            return string(abi.encodePacked(
                '--dmpa1:',
                COLORS[gear[0]],
                ';--dmpa2:',
                COLORS[gear[1]],
                ';--dmpa3:',
                COLORS[gear[2]],
                ';--dmpa4:',
                COLORS[gear[3]],
                ';'
            ));
        } else if(gearId < 51){
            uint8[3] memory gear = [
                [0,18,45],
                [4,2,45],
                [2,3,45],
                [3,3,41],
                [19,20,45],
                [2,18,45],
                [2,8,9],
                [21,11,45],
                [2,5,7],
                [2,17,45],
                [22,23,45],
                [2,24,45],
                [20,19,45],
                [8,9,45],
                [2,8,3],
                [35,14,45],
                [15,16,45]
            ][gearId - 34];
            return string(abi.encodePacked(
                '--dmpp1:',
                COLORS[gear[0]],
                ';--dmpp2:',
                COLORS[gear[1]],
                ';--dmpp3:',
                COLORS[gear[2]],
                ';'
            ));
        } else if(gearId < 68){
            uint8[3] memory gear = [
                [44,45,45],
                [2,45,45],
                [3,45,45],
                [3,8,45],
                [7,5,45],
                [19,20,45],
                [8,9,45],
                [45,45,45],
                [5,7,45],
                [7,17,45],
                [21,11,45],
                [45,45,45],
                [45,45,45],
                [45,45,45],
                [3,8,45],
                [35,45,14],
                [15,16,45]
            ][gearId - 51];
            return string(abi.encodePacked(
                '--dmpf1:',
                COLORS[gear[0]],
                ';--dmpf2:',
                COLORS[gear[1]],
                ';--dmpf3:',
                COLORS[gear[2]],
                ';'
            ));
        } else {
            uint8[4] memory gear = [
                [44,45,45,45],
                [7,5,45,45],
                [3,8,45,45],
                [3,8,7,45],
                [5,7,45,45],
                [7,3,8,45],
                [9,8,45,45],
                [3,8,27,26],
                [7,8,3,45],
                [9,8,45,45],
                [8,9,3,45],
                [9,8,45,45],
                [9,8,45,45],
                [5,7,45,45],
                [7,5,45,45],
                [7,8,3,45],
                [7,5,45,45],
                [10,9,45,45],
                [9,10,9,45],
                [10,9,10,45],
                [10,9,45,45],
                [15,16,45,45],
                [19,20,19,45],
                [20,19,20,45],
                [20,19,45,45],
                [8,9,45,45],
                [8,3,45,45],
                [26,14,27,45],
                [16,15,45,45]
            ][gearId - 68];
            return string(abi.encodePacked(
                '--dmpw1:',
                COLORS[gear[0]],
                ';--dmpw2:',
                COLORS[gear[1]],
                ';--dmpw3:',
                COLORS[gear[2]],
                ';--dmpw4:',
                COLORS[gear[3]],
                ';%253C/style%253E%253Cg class=\'h\' transform=\'translate(4,88)\'%253E'
            ));
        }
    }

    /**
    * @notice render a weapon asset
    * @param smAssetId the small asset id of the gear item
    * @return string of svg
    */
    function weapon(uint256 smAssetId)
        external
        pure
        returns (string memory)
    {
        string[20] memory GEAR = [
            // START WEAPONS
            // 0 empty
            '%253Cg%253E%253C/g%253E',
            // 1 sword
            '%253Cg%253E%253Cpath d=\'M17,9h2v2h-1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-2v-3h2v-1h2v-1h2v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M18,10h1v1h-1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h2v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M17,9h2v2h-1v1h-1v1h-1v-1h1v-1h1v-1h-1v1h-2v-1h2zM13,11h1v1h-1zM11,12h1v1h-1v1h-1v1h1v1h-2v1h-1v-3h1v-1h2zM12,14h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 2 daggers
            '%253Cg%253E%253Cpath d=\'M15,10h2v1h1v1h1v2h-3v-2h-1zM8,14h2v-1h2v2h-1v1h-1v1h-2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M16,10h1v1h1v1h1v2h1v1h-5v-1h3v-2h-1v-1h-1zM7,13h1v3h2v-1h1v-1h1v1h-1v1h-1v1h-2v1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M15,11h1v1h1v3h-2v-1h1v-2h-1zM10,13h2v1h-2v1h-2v1h2v-1h1v-1h1v1h-1v1h-1v1h-2v1h-1v-3h1v-1h2zM18,13h1v1h1v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 3 bow
            '%253Cg%253E%253Cpath d=\'M11,9h1v1h-1v1h-2v1h-1v1h-2v1h-2v1h-1v-1h1v-1h2v-1h2v-1h1v-1h2zM7,15h1v1h1v1h1v1h1v1h-1v-1h-1v-1h-1v-1h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M13,8h1v1h-1v1h-1v-1h1zM2,14h1v1h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M14,7h1v3h-1v2h-1v1h-1v1h-1v1h-1v1h-2v1h-1v-1h1v-1h2v-1h1v-1h1v-1h1v-2h1zM1,15h1v1h2v1h-2v-1h-1zM11,18h1v2h-2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M14,7h1v2h-2v1h1v-1h1v1h-1v2h-1v1h-1v-1h1v-2h-1v-1h1v-1h1zM2,14h1v1h-1v1h2v1h-2v-1h-1v-1h1zM7,15h1v1h1v1h-2zM11,18h1v1h-1v1h-1v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 4 staff
            '%253Cg%253E%253Cpath d=\'M6,5h1v1h1v4h-1v2h-1v-2h-1v-4h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M6,6h1v2h1v1h-1v2h-1v-2h-1v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M6,12h1v2h-1zM5,17h1v5h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M5,8h1v1h1v-1h1v2h-1v2h-1v-2h-1zM6,13h1v1h-1zM5,17h1v3h-1zM5,21h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 5 scepter
            '%253Cg%253E%253Cpath d=\'M15,10h3v2h-1v1h-4v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h1v-1h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M18,9h1v1h-1zM15,11h1v1h1v-1h1v1h-1v1h-1v-1h-1v1h-1v-1h1zM12,13h1v1h-1zM7,15h1v1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M18,9h1v1h-1v2h-1v1h-3v-1h2v-1h1v-1h1zM9,14h1v1h-1v1h-2v-1h2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 6 knuckles
            '%253Cg%253E%253Cpath d=\'M5,14h3v3h-1v1h-2v-1h1v-2h-1zM17,14h3v3h-1v1h-2v-1h1v-2h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M5,13h2v1h1v2h-1v-1h-1v-1h-1zM17,13h2v1h1v2h-1v-1h-1v-1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M6,13h1v1h-1zM5,15h1v1h1v2h-2zM17,15h1v1h1v2h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 7 pickaxe
            '%253Cg%253E%253Cpath d=\'M9,13h4v1h-2v1h-2v1h-2v-2h2zM3,16h1v1h1v1h-2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M11,12h2v1h-2v1h-2v1h-1v-1h1v-1h2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M11,7h2v1h1v1h1v2h1v4h-1v2h-1v1h-1v1h-1v-1h1v-8h-1v-2h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M11,7h2v1h1v1h1v1h-1v-1h-1v1h1v5h1v-4h1v4h-1v2h-1v1h-1v1h-1v-2h1v-3h-2v1h-2v1h-2v-2h3v-1h2v-1h1v-2h-1v-2h-1zM3,17h2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 8 club
            '%253Cg%253E%253Cpath d=\'M13,9h3v1h1v3h-1v1h-2v1h-3v1h-4v-2h1v-1h1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M13,10h3v1h-1v1h-2v1h-1v1h-2v1h-2v-1h1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M13,9h1v1h-1zM10,11h1v1h-1v1h-1v1h-1v2h-1v-2h1v-1h1v-1h1zM16,11h1v2h-1v1h-2v1h-3v1h-2v-1h2v-1h2v-1h2v-1h1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 9 shadowblades
            '%253Cg%253E%253Cpath d=\'M17,9h2v1h1v1h1v5h-3v-5h-1zM11,15h1v2h-1v1h-1v1h-5v-3h6z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M18,9h1v1h1v1h1v1h-1v-1h-1v-1h-1v1h-1v-1h1zM18,12h1v2h-1v1h1v1h1v-2h1v2h-1v1h-1v1h-2v-1h1v-2h-1v-1h1zM3,15h1v1h2v-1h1v1h2v1h-2v-1h-1v1h-1v1h2v1h-2v-1h-1v-1h-1zM10,15h1v1h1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M18,13h1v1h-1zM3,15h1v1h2v-1h1v1h-1v1h1v1h1v1h-3v-1h-1v-1h-1zM19,15h2v1h-1v1h-1v1h-2v-1h1v-1h1zM8,16h2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 10 shortswords
            '%253Cg%253E%253Cpath d=\'M14,8h2v1h1v1h1v4h-2v-2h-1v-2h-1zM11,12h2v2h-1v1h-1v1h-4v-2h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M15,8h1v1h1v1h1v2h1v2h-1v-2h-1v-2h-1v-1h-1zM12,13h1v1h-1v1h-1v1h-2v1h-2v-1h2v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M14,8h2v1h-1v1h1v-1h1v1h1v1h-1v-1h-1v2h-1v-2h-1zM11,12h2v1h-2v1h1v-1h1v1h-1v1h-1v1h-1v-1h1v-1h-2v-1h2zM16,13h1v1h-1zM7,14h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 11 kusarigama
            '%253Cg%253E%253Cpath d=\'M14,9h3v1h2v1h1v1h1v1h-1v-1h-2v-1h-2v1h-2v-1h-1v-1h1zM3,17h1v1h1v2h-1v1h-1v-1h-1v-2h1zM7,17h1v1h1v1h6v-1h1v-1h1v1h-1v1h-1v1h-6v-1h-1v-1h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M15,12h2v2h1v2h-2v-2h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M16,12h1v2h1v2h-1v-2h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M16,9h1v1h-1zM13,10h1v1h2v1h1v2h1v2h-2v-2h-1v-1h1v-1h-2v-1h-1zM18,11h1v1h-1zM20,12h1v1h-1zM3,17h1v1h-1zM7,17h1v1h1v1h1v1h-1v-1h-1v-1h-1zM16,17h1v1h-1v1h-1v1h-1v-1h1v-1h1zM2,19h1v1h1v-1h1v1h-1v1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 12 handaxes
            '%253Cg%253E%253Cpath d=\'M16,8h3v1h1v1h1v2h-1v1h-1v-1h-3v-2h1v-1h-1zM9,14h2v1h1v-1h1v3h-1v1h-1v1h-2v-1h-1v-1h1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M14,10h2v2h1v4h-1v-2h-1v-2h-1zM9,12h2v2h-2v1h-3v-1h1v-1h2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M14,10h2v2h1v2h1v2h-1v-2h-1v-2h-1v-1h-1zM10,12h1v2h-2v1h-2v1h-1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M17,9h1v1h1v-1h1v1h1v1h-1v-1h-1v2h1v1h-1v-1h-2v2h1v2h-2v-2h-1v-1h1v-3h1zM7,13h1v2h-1v1h-1v-2h1zM10,13h1v2h1v-1h1v3h-1v1h-1v1h-2v-1h-1v-1h1v1h2v-1h1v-1h-1v-1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 13 shortsword
            '%253Cg%253E%253Cpath d=\'M13,11h2v2h-1v1h-1v1h-2v1h-4v-2h2v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M14,12h1v1h-1v1h-1v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M13,11h2v1h-2v1h1v-1h1v1h-1v1h-1v1h-1v-1h1v-1h-2v-1h2zM9,13h1v1h-1zM7,14h1v1h-1zM8,16h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 14 poison spear
            '%253Cg%253E%253Cpath d=\'M5,5h1v9h-1zM5,17h1v5h-1z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M4,3h2v3h-1v-1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M5,1h1v2h1v3h-1v-1h-1zM6,7h1v1h-1z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M5,3h1v1h1v1h-1v-1h-1z\' fill=\'var(--dmpw4)\'/%253E%253Cpath d=\'M5,1h1v1h-1zM5,6h1v1h-1zM5,8h1v4h-1zM5,17h1v2h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 15 wand
            '%253Cg%253E%253Cpath d=\'M13,11h2v1h-2v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M15,10h2v1h-2v1h-1v-1h1zM7,14h1v1h-1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M16,10h1v1h-1zM9,13h1v1h-1v1h-2v-1h2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 16 phoenix
            '%253Cg%253E%253Cpath d=\'M5,11h5v1h2v1h1v1h1v1h1v2h-2v1h-3v-1h1v-1h-4v-2h1v-1h-1v-1h-2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M6,11h3v1h2v1h1v1h1v1h1v1h1v1h-2v-1h-1v-1h-1v-1h-2v1h1v1h-1v-1h-1v-1h1v-1h-1v-1h-2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M5,11h2v1h2v1h1v1h1v1h2v-1h1v1h-1v1h1v-1h1v2h-4v1h-1v-1h1v-1h-4v-2h1v-1h-1v-1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 17 cutter
            '%253Cg%253E%253Cpath d=\'M20,3h1v3h-1v2h-1v3h-1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-2v-3h2v-1h2v-1h2v-1h2v-1h-3v-1h1v-1h1v-1h1v-1h1v-1h2v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M19,4h1v3h-1v1h-1v2h-1v1h-1v1h-1v1h-2v-1h1v-1h1v-1h1v-1h1v-1h1v-1h1v-1h-1v1h-1v1h-1v1h-2v-1h1v-1h1v-1h2v-1h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M16,5h1v1h-1zM20,5h1v1h-1zM17,7h1v1h-1v2h-1v1h-1v1h-2v1h-2v1h-2v1h-1v1h1v-1h2v-1h2v1h-2v1h-2v1h-2v-3h2v-1h2v-1h2v-1h2v-1h-1v-1h-1v1h-1v-1h1v-1h1v1h1v-1h2zM18,10,h1v1h-1v1h-1v1h-1v-1h1v-1h1zM14,13h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 18 scmitar
            '%253Cg%253E%253Cpath d=\'M16,8h3v3h-1v1h-1v1h-1v1h-2v1h-3v1h-2v1h-2v-2h2v-1h2v-1h1v-1h1v-1h1v-1h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M17,5h1v1h1v2h-1v2h-1v1h-1v1h-1v1h-2v1h-2v1h-2v1h-2v-1h2v-1h2v-1h2v-1h1v-1h1v-2h1v-2h1z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M17,5h1v2h-1v2h-1v1h-1v1h-1v1h-1v1h-1v1h-1v2h-2v1h-2v-2h2v-1h2v-1h1v-1h1v-1h1v-1h1v-1h1v-2h1zM18,9h1v2h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h1zM13,14h1v1h-1z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E',
            // 19 greataxe
            '%253Cg%253E%253Cpath d=\'M17,11h2v1h1v-1h1v3h-1v1h-2v1h-4v-1h1v-3h2z\' fill=\'var(--dmpw1)\'/%253E%253Cpath d=\'M17,9h2v2h-2v1h-2v1h-2v1h-2v1h-2v1h-2v-2h2v-1h2v-1h2v-1h2v-1h2zM3,16h1v1h1v1h-2v1h-2v-2h2z\' fill=\'var(--dmpw2)\'/%253E%253Cpath d=\'M17,9h1v1h-1v1h-2v1h-2v1h-2v1h-2v1h-1v-1h1v-1h2v-1h2v-1h2v-1h2z\' fill=\'var(--dmpw3)\'/%253E%253Cpath d=\'M18,10h1v2h1v-1h1v3h-1v1h-1v-1h1v-1h-1v-1h-1zM15,12h1v2h1v1h1v1h-4v-1h1zM7,14h3v1h-1v1h-2zM1,17h1v1h1v-1h2v1h-2v1h-2z\' fill=\'var(--dmb25)\'/%253E%253C/g%253E'
            // END WEAPONS
        ];
        return GEAR[smAssetId];
    }

    /**
    * @notice render a chamber with an encounter
    * @param ct chamber type
    * @param et encounter type
    * @param index chamber index
    * @return string of svg
    */
    function smChamber(string memory ut, string memory ct, string memory et, uint256 index)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '%253Cg transform=\'translate(',
            // Calculate the starting x position of the chamber
            (((index % 8) * 14) + 2).toString(),
            ',',
            // Calculate the starting y position of the chamber
            (((index / 8) * 14) + 2).toString(),
            ')\'%253E%253Cuse href=\'%2523',
            ut,
            '\' class=\'c',
            ct,
            '\'/%253E%253Cuse href=\'%2523e',
            et,
            '\'/%253E%253C/g%253E'
        ));
    }

    /**
    * @notice render the next upcoming chamber
    * @param index next chamber index
    * @return string of svg
    */
    function smNext(uint256 index)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            '%253Cg transform=\'translate(',
            // Calculate the starting x position of the chamber
            (((index % 8) * 14) + 2).toString(),
            ',',
            // Calculate the starting y position of the chamber
            (((index / 8) * 14) + 2).toString(),
            ')\'%253E%253Cuse href=\'%2523u\' class=\'n\'/%253E%253C/g%253E'
        ));
    }

    /**
    * @notice render the exit chamber
    * @return string of svg
    */
    function smExit()
        external
        pure
        returns (string memory)
    {
        return '%253Cg transform=\'translate(100,72)\'%253E%253Cimage href=\'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAMAAABhq6zVAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF2dnZ/NYXG4YtIJ41YDEU////HcDtgEIb7MtdQwAAADdJREFUeNpcysERACAIA0FQif13bBxRkPvtJDJTUgAYANUDMwl4AY5+k7JcdNbYwyYxUh+WAAMAA0sDCBfICVcAAAAASUVORK5CYII=\'/%253E%253C/g%253E';
    }

    /**
    * @notice render portions of the bottom stats block
    * @param index index to render
    * @param miner current miner instance
    * @return string of svg
    */
    function smMinerStat(uint256 index, Miner memory miner)
        external
        pure
        returns (string memory)
    {
        if(index == 0){ // health
            return string(abi.encodePacked(
                '%253Ctext x=\'39\' y=\'90.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.health < 0 ? 0 : uint16(miner.health)).toString(),
                '%253C/text%253E'
            ));

        } else if(index == 1){ // attack
            return string(abi.encodePacked(
                '%253Ctext x=\'67\' y=\'90.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.attack < 0 ? 0 : uint16(miner.attack)).toString(),
                '%253C/text%253E'
            ));
        } else if(index == 2){ // gold
            return string(abi.encodePacked(
                '%253Ctext x=\'95\' y=\'90.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                miner.gold.toString(),
                '%253C/text%253E'
            ));
        } else if(index == 3){ // armor
            return string(abi.encodePacked(
                '%253Ctext x=\'39\' y=\'101.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.armor < 0 ? 0 : uint16(miner.armor)).toString(),
                '%253C/text%253E'
            ));
        } else if(index == 4){ // speed
            return string(abi.encodePacked(
                '%253Ctext x=\'67\' y=\'101.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                (miner.speed < 0 ? 0 : uint16(miner.speed)).toString(),
                '%253C/text%253E'
            ));
        } else { // chamber count
            return string(abi.encodePacked(
                '%253Ctext x=\'95\' y=\'101.75\' font-family=\'txt\' font-size=\'10\' dominant-baseline=\'hanging\' fill=\'white\'%253E',
                miner.currentChamber.toString(),
                '%253C/text%253E'
            ));
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Miner {
    int16 baseHealth;
    int16 baseArmor;
    int16 health;
    int16 armor;
    int16 attack;
    int16 speed;
    uint16 gold;
    uint8 genderId;
    uint8 classId;
    uint8 skintoneId;
    uint8 hairColorId;
    uint8 hairTypeId;
    uint8 eyeColorId;
    uint8 eyeTypeId;
    uint8 mouthId;
    uint8 headgearId;
    uint8 armorId;
    uint8 pantsId;
    uint8 footwearId;
    uint8 weaponId;
    uint8 curseTurns;
    uint8 buffTurns;
    uint8 debuffTurns;
    uint8 revives;
    uint8 currentChamber;
}