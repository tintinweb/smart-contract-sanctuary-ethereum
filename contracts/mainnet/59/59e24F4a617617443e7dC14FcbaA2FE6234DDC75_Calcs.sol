// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "../Structs/PackedVars.sol";
import "../Structs/Monster.sol";
import "../Structs/Miner.sol";

library Calcs {
    using Strings for *;

    /**
    * @notice return a headgear stats array
    * @param gearId the gear id of the headgear item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function headgearStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,3],       // 0  | C | none

            // uncommon = 8 total
            // Health & Attack
            [int16(3),0,5,0,    1,7],       // 1  | U | bandana
            [int16(6),0,2,0,    2,10],      // 2  | U | leather hat
            [int16(2),0,6,0,    3,11],      // 3  | U | rusty helm
            [int16(4),0,4,0,    4,8],       // 4  | U | feathered cap

            // rare = 14 total
            // Health & Armor & Attack
            [int16(7),5,2,0,    5,4],       // 5  | R | enchanted crown
            [int16(5),5,4,0,    6,12],      // 6  | R | bronze helm
            [int16(2),4,8,0,    7,0],       // 7  | R | assassin's mask

            // epic = 24 total
            // Health & Armor & Attack
            [int16(6),12,6,0,    8,13],     // 8  | E | iron helm
            [int16(9),6,9,0,    15,16],     // 9  | E | skull helm
            [int16(9),6,9,0,    14,6],      // 10 | E | charmed headband
            [int16(9),6,9,0,    12,9],      // 11 | E | ranger cap
            [int16(9),6,9,0,    10,1],      // 12 | E | misty hood

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(13),10,13,6,    16,17],  // 13 | L | phoenix helm
            [int16(13),10,13,6,    13,5],   // 14 | L | ancient mask
            [int16(13),10,13,6,    11,15],  // 15 | L | genesis helm
            [int16(13),10,13,6,    9,14]    // 16 | L | soul shroud
        ];
        return GEAR[gearId];
    }

    /**
    * @notice return an armor stats array
    * @param gearId the gear id of the armor item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function armorStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,0],       // 17 | C | cotton shirt

            // uncommon = 8 total
            // Health & Armor
            [int16(3),5,0,0,    0,1],       // 18 | U | thick vest
            [int16(4),4,0,0,    0,2],       // 19 | U | leather chestplate
            [int16(2),6,0,0,    3,3],       // 20 | U | rusty chainmail
            [int16(6),2,0,0,    0,4],       // 21 | U | longcoat

            // rare = 14 total
            // Health & Armor & Attack
            [int16(6),4,4,0,    3,5],       // 22 | R | chainmail
            [int16(5),6,3,0,    0,6],       // 23 | R | bronze chestplate
            [int16(6),6,2,0,    0,7],       // 24 | R | blessed armor

            // epic = 24 total
            // Health & Armor & Attack
            [int16(6),7,11,0,    0,8],      // 25 | E | iron chestplate
            [int16(9),9,6,0,    2,9],       // 26 | E | skull armor
            [int16(9),9,6,0,    1,10],      // 27 | E | cape of deception
            [int16(9),9,6,0,    1,11],      // 28 | E | mystic cloak
            [int16(9),9,6,0,    4,12],      // 29 | E | shimmering cloak

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(13),13,10,6,    0,13],   // 30 | L | phoenix chestplate
            [int16(13),13,10,6,    0,14],   // 31 | L | ancient robe
            [int16(13),13,10,6,    1,15],   // 32 | L | genesis cloak
            [int16(13),13,10,6,    1,16]    // 33 | L | soul cloak
        ];
        return GEAR[gearId - 17];
    }

    /**
    * @notice return a pants stats array
    * @param gearId the gear id of the pants item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function pantsStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,0],       // 34 | C | cotton pants

            // uncommon = 8 total
            // Armor & Speed
            [int16(0),6,0,2,    0,0],       // 35 | U | thick pants
            [int16(0),4,0,4,    0,0],       // 36 | U | leather greaves
            [int16(0),3,0,5,    3,0],       // 37 | U | rusty chainmail pants
            [int16(0),2,0,6,    0,0],       // 38 | U | reliable leggings

            // rare = 14 total
            // Health & Armor & Speed
            [int16(2),4,0,8,    0,0],       // 39 | R | padding leggings
            [int16(3),5,0,6,    1,0],       // 40 | R | bronze greaves
            [int16(5),5,0,4,    0,0],       // 41 | R | enchanted pants

            // epic = 24 total
            // Health & Armor & Speed
            [int16(8),9,0,7,    1,0],       // 42 | E | iron greaves
            [int16(6),9,0,9,    0,0],       // 43 | E | skull greaves
            [int16(6),9,0,9,    0,0],       // 44 | E | swift leggings
            [int16(6),9,0,9,    0,0],       // 45 | E | forest greaves
            [int16(6),9,0,9,    0,0],       // 46 | E | silent leggings

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(10),13,6,13,    0,0],    // 47 | L | phoenix greaves
            [int16(10),13,6,13,    2,0],    // 48 | L | ancient greaves
            [int16(10),13,6,13,    0,0],    // 49 | L | genesis greaves
            [int16(10),13,6,13,    0,0]     // 50 | L | soul greaves
        ];
        return GEAR[gearId - 34];
    }

    /**
    * @notice return a footwear stats array
    * @param gearId the gear id of the footwear item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function footwearStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][17] memory GEAR = [
            [int16(0),0,0,0,    0,0],       // 51 | C | none

            // uncommon = 8 total
            // Health & Speed
            [int16(3),0,0,5,    1,0],       // 52 | U | sturdy cleats
            [int16(4),0,0,4,    1,0],       // 53 | U | leather boots
            [int16(6),0,0,2,    2,0],       // 54 | U | rusty boots
            [int16(2),0,0,6,    0,0],       // 55 | U | lightweight shoes

            // rare = 14 total
            // Health & Attack & Speed
            [int16(2),0,3,9,    2,0],       // 56 | R | bandit's shoes
            [int16(5),0,4,5,    2,0],       // 57 | R | bronze boots
            [int16(6),0,5,3,    6,0],       // 58 | R | heavy boots

            // epic = 24 total
            // Health & Attack & Speed
            [int16(9),0,10,5,    2,0],      // 59 | E | iron boots
            [int16(9),0,6,9,    1,0],       // 60 | E | skull boots
            [int16(9),0,6,9,    1,0],       // 61 | E | enchanted boots
            [int16(9),0,6,9,    4,0],       // 62 | E | jaguarpaw boots
            [int16(9),0,6,9,    3,0],       // 63 | E | lightfoot boots

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(13),6,10,13,    5,0],    // 64 | L | phoenix boots
            [int16(13),6,10,13,    1,0],    // 65 | L | ancient boots
            [int16(13),6,10,13,    1,0],    // 66 | L | genesis boots
            [int16(13),6,10,13,    2,0]     // 67 | L | soul boots
        ];
        return GEAR[gearId - 51];
    }

    /**
    * @notice return a weapon stats array
    * @param gearId the gear id of the weapon item
    * @return array of int16 values representing the HP buff, AP buff, ATK buff, SPD buff, small asset id and large asset id of the item
    */
    function weaponStats(uint256 gearId)
        public
        pure
        returns (int16[6] memory)
    {
        int16[6][29] memory GEAR = [
            [int16(0),0,0,0,    0,5],       // 68 | C | fists

            // uncommon = 8 total
            // Attack & Speed
            [int16(0),0,4,4,    1,6],       // 69 | U | rusty sword
            [int16(0),0,6,2,    8,20],      // 70 | U | wooden club
            [int16(0),0,5,3,    7,1],       // 71 | U | pickaxe
            [int16(0),0,2,6,    6,0],       // 72 | U | brass knuckles

            // rare = 14 total
            // Armor & Attack & Speed
            [int16(0),2,6,6,    19,28],     // 73 | R | weathered greataxe
            [int16(0),2,6,6,    5,18],      // 74 | R | polished scepter
            [int16(0),2,6,6,    14,24],     // 75 | R | poisoned spear
            [int16(0),2,6,6,    11,3],      // 76 | R | kusarigama
            [int16(0),4,4,6,    1,7],       // 77 | R | bronze sword
            [int16(0),4,4,6,    4,15],      // 78 | R | bronze staff
            [int16(0),4,4,6,    13,23],     // 79 | R | bronze shortsword
            [int16(0),4,4,6,    2,9],       // 80 | R | bronze daggers
            [int16(0),2,4,8,    18,27],     // 81 | R | dusty scmitar
            [int16(0),2,4,8,    15,25],     // 82 | R | silver wand
            [int16(0),2,4,8,    12,22],     // 83 | R | dual handaxes
            [int16(0),2,4,8,    10,21],     // 84 | R | dual shortswords

            // epic = 24 total
            // Armor & Attack & Speed
            [int16(0),7,9,8,    1,8],       // 85 | E | holy sword
            [int16(0),7,9,8,    4,16],      // 86 | E | holy staff
            [int16(0),7,9,8,    3,12],      // 87 | E | holy bow
            [int16(0),7,9,8,    2,10],      // 88 | E | holy daggers
            [int16(0),5,9,10,    17,26],    // 89 | E | soulcutter
            [int16(0),5,9,10,    4,17],     // 90 | E | shadow staff
            [int16(0),5,9,10,    3,13],     // 91 | E | shadow bow
            [int16(0),5,9,10,    9,2],      // 92 | E | shadowblades

            // legendary = 42 total
            // Health & Armor & Attack & Speed
            [int16(6),10,13,13,    16,4],   // 93 | L | phoenix blade
            [int16(6),10,13,13,    5,19],   // 94 | L | ancient scepter
            [int16(6),10,13,13,    3,14],   // 95 | L | genesis bow
            [int16(6),10,13,13,    2,11]    // 96 | L | soul daggers
        ];

        return GEAR[gearId - 68];
    }

    /**
    * @notice return a uint16 value from a bytes32 hash, given an offset
    * @param hash the bytes32 hash to retrieve a uint16 from
    * @param offset the offset from 0 to grab the data from
    * @return uint16 value cast to a uint256
    */
    function _hashToUint16(bytes32 hash, uint256 offset)
        internal
        pure
        returns (uint256)
    {
        require(30 >= offset, "oob");
        return uint256((hash << (offset * 8)) >> 240);
    }

    /**
    * @notice calculate a gear type
    * @param typeVal a uint value between 0-255
    * @return uint8 value of gear type for an item
    */
    function gType(uint8 typeVal)
        public
        pure
        returns (uint8)
    {
        /*
        0  | common     | 0-127   | 1/2   | 128 | 50%    | 0%
        1  | uncommon 1 | 128-151 | 3/32  | 24  | 9.375% | 18.75%
        2  | uncommon 2 | 152-175 | 3/32  | 24  | 9.375% | 18.75%
        3  | uncommon 3 | 176-199 | 3/32  | 24  | 9.375% | 18.75%
        4  | uncommon 4 | 200-223 | 3/32  | 24  | 9.375% | 18.75%
        5  | rare 1     | 224-232 | 9/256 | 9   | 3.516% | 7.031%
        6  | rare 2     | 233-241 | 9/256 | 9   | 3.516% | 7.031%
        7  | rare 3     | 242-250 | 9/256 | 9   | 3.516% | 7.031%
        8  | epic 1     | 251-252 | 1/32  | 2   | 0.781% | 1.563%
        9  | epic 2     | 253-254 | 1/32  | 2   | 0.781% | 1.563%
        10 | legendary  | 255     | 1/256 | 1   | 0.391% | 0.781%
        */

        // Sorting from middle-out (reduce gas by probability)
        if(typeVal < 128){
            return 0;
        } else {
            if(typeVal < 224) {
                if(typeVal < 176){
                    return typeVal < 152 ? 1 : 2;
                } else {
                    return typeVal < 200 ? 3 : 4;
                }
            } else {
                if(typeVal < 251){
                    if(typeVal < 233){
                        return 5;
                    } else {
                        return typeVal < 242 ? 6 : 7;
                    }
                } else {
                    if(typeVal < 253){
                        return 8;
                    } else {
                        return typeVal < 255 ? 9 : 10;
                    }
                }
            }
        }
    }

    /**
    * @notice calculate a chamber type
    * @param hash the bytes32 hash value of a chamber
    * @return uint256 value of chamber type
    */
    function _cType(bytes32 hash)
        internal
        pure
        returns (uint256)
    {
        return (uint256(uint8(hash[4])) / 32);
    }

    /**
    * @notice calculate a chamber type and return as a string
    * @param hash the bytes32 hash value of a chamber
    * @return string of chamber type
    */
    function ctString(bytes32 hash)
        external
        pure
        returns (string memory)
    {
        return _cType(hash).toString();
    }

    /**
    * @notice calculate an encounter type
    * @param hash the bytes32 hash value of a chamber
    * @return uint8 value of the encounter type
    */
    function _eType(bytes32 hash)
        internal
        pure
        returns (uint8)
    {
        uint256 typeVal = uint256(_hashToUint16(hash,14));

        /*

        #  | type       | value range | size | probability
        ---+------------+-------------+------+-------------------
        0  | slime      | 0-6143      | 6144 | 9.375%
        1  | crawler    | 6144-12287  | 6144 | 9.375%
        2  | poison bat | 12288-18431 | 6144 | 9.375%
        3  | skeleton   | 18432-24575 | 6144 | 9.375%
        4  | trap       | 24576-28475 | 3900 | 5.950927734375%
        5  | curse      | 28476-32375 | 3900 | 5.950927734375%
        6  | buff       | 32376-36275 | 3900 | 5.950927734375%
        7  | debuff     | 36276-40175 | 3900 | 5.950927734375%
        8  | gold       | 40176-44075 | 3900 | 5.950927734375%
        9  | thief      | 44076-47975 | 3900 | 5.950927734375%
        10 | empty      | 47976-51875 | 3900 | 5.950927734375%
        11 | rest       | 51876-55775 | 3900 | 5.950927734375%
        12 | gear       | 55776-58780 | 3005 | 4.58526611328125%
        13 | merchant   | 58781-61785 | 3005 | 4.58526611328125%
        14 | treasure   | 61786-63600 | 1815 | 2.76947021484375%
        15 | heal       | 63601-65415 | 1815 | 2.76947021484375%
        16 | revive     | 65416-65495 | 80   | 0.1220703125%
        17 | armory     | 65496-65535 | 40   | 0.06103515625%

        */

        // Sorting from middle-out (reduce gas by probability)
        if(typeVal < 32376){
            if(typeVal < 18432){
                if(typeVal < 12288){
                    return typeVal < 6144 ? 0 : 1;
                } else {
                    return 2;
                }
            } else {
                if(typeVal < 24576){
                    return 3;
                } else {
                    return typeVal < 28476 ? 4 : 5;
                }
            }
        } else {
            if(typeVal < 47976){
                if(typeVal < 40176){
                    return typeVal < 36276 ? 6 : 7;
                } else {
                    return typeVal < 44076 ? 8 : 9;
                }
            } else {
                if(typeVal < 55776){
                    return typeVal < 51876 ? 10 : 11;
                } else {
                    if(typeVal < 61786){
                        return typeVal < 58781 ? 12 : 13;
                    } else {
                        if(typeVal < 63601){
                            return 14;
                        } else {
                            if(typeVal < 65416){
                                return 15;
                            } else {
                                return typeVal < 65496 ? 16 : 17;
                            }
                        }
                    }
                }
            }
        }

    }

    /**
    * @notice calculate an encounter type and return as a string
    * @param hash the bytes32 hash value of a chamber
    * @return string of the encounter type
    */
    function etString(bytes32 hash)
        external
        pure
        returns (string memory)
    {
        return _eType(hash).toString();
    }

    /**
    * @notice calculate an encounter outcome
    * @param hash chamber hash
    * @param miner the current Miner instance
    * @return array representing the post-encounter miner struct
    */
    function chamberStats(bytes32 hash, Miner memory miner)
        external
        pure
        returns (Miner memory)
    {
        // Define chamberData
        PackedVars memory chamberData;

        // Define encounter type for this chamber
        chamberData.var_uint8_1 = _eType(hash);

        // Pre-encounter calcuations

        // Check Miner's class
        if(miner.classId == 0){
            // Miner is a warrior! Restore 2 armor
            miner.armor = miner.armor + 2;
            // Check if armor is greater than baseArmor
            if(miner.armor > miner.baseArmor){
                // Set armor to baseArmor
                miner.armor = miner.baseArmor;
            }
        } else if(miner.classId == 2){
            // Miner is a ranger! Restore 3 health and add 2 to baseHealth
            // Restore health
            miner.health = miner.health + 3;
            // Check if health is greater than baseHealth
            if(miner.health > miner.baseHealth){
                // Set health to baseHealth
                miner.health = miner.baseHealth;
            }
            // Add 2 to baseHealth
            miner.baseHealth = miner.baseHealth + 2;
        }

        // Check if Miner is cursed and make sure this isn't a curse chamber to avoid doing double damage
        if(miner.curseTurns > 0 && chamberData.var_uint8_1 != 5){
            // Miner is cursed!
            // Calculate curse damage taken (10 percent of current health or 5 if Miner has less than 50 health)
            chamberData.var_int16_1 = miner.health < 50 ? int16(5) : (miner.health / 10);
            // Set Miner health
            miner.health = miner.health - chamberData.var_int16_1;
            // Check if Miner is dead but has a revive
            if(miner.health < 1 && miner.revives > 0){
                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                miner.health = miner.baseHealth / 4;
                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                // Remove revive from inventory
                miner.revives--;
            }
            // Remove curse turn
            miner.curseTurns--;
        }

        // Encounter calculations

        // Check if Miner is still alive after potential curse damage has been calculated
        if(miner.health > 0){
            // Miner is alive! Loop through potential encounter types to calculate results
            if(chamberData.var_uint8_1 < 4){ // MONSTER
                // Define monster
                Monster memory monster;
                // Check what kind of monster we've encountered and adjust stats
                if(chamberData.var_uint8_1 == 0){ // SLIME
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 70 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 15 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 35;
                    monster.mtype = chamberData.var_uint8_1;
                } else if(chamberData.var_uint8_1 == 1){ // CRAWLER
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 65 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 25 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 50;
                    monster.mtype = chamberData.var_uint8_1;
                } else if(chamberData.var_uint8_1 == 2){ // POISON BAT
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 60 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 15 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 55;
                    monster.mtype = chamberData.var_uint8_1;
                } else { // SKELETON
                    monster.health = int16(int8(uint8(hash[0]) % 48)) + 80 + (10 * int16(uint16(miner.currentChamber / 8)));
                    monster.attack = int16(int8(uint8(hash[2]) % 24)) + 30 + (5 * int16(uint16(miner.currentChamber / 8)));
                    monster.speed = int16(int8(uint8(hash[3]) % 24)) + 40;
                    monster.mtype = chamberData.var_uint8_1;
                }

                // Define turn counter
                chamberData.var_uint8_2 = 0;

                // Loop through battle turns until someone dies
                while(miner.health > 0 && monster.health > 0){
                    // Check variable monster turn speed vs. variable Miner turn speed
                    if((monster.speed + int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[7]) % 24))) > (miner.speed + int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[6]) % 24)))){
                        // Monster goes first

                        // Get random offset from monster's base attack for this turn
                        chamberData.var_int16_4 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[14]) % 8));
                        // Adjust monster's attack modifier to be a range of -4 to 4, no zero (positive numbers will be a buff, negative will be debuff)
                        chamberData.var_int16_4 = chamberData.var_int16_4 - (chamberData.var_int16_4 < 4 ? int16(4) : int16(3));

                        // Calculate total damage taken
                        chamberData.var_int16_2 = monster.attack + chamberData.var_int16_4;

                        // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                        // Value is 1/2 instead of 1/3 for Warriors
                        chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                        // Sub armor damage from armor
                        miner.armor = miner.armor - chamberData.var_int16_3;
                        // Sub health damage from health
                        miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                        // If armor has been broken, pass excess damage to health and set armor to zero
                        if(miner.armor < 0){
                            miner.health = miner.health + miner.armor;
                            miner.armor = 0;
                        }

                        // Check if Miner is dead
                        if(miner.health < 1){
                            // Check if Miner has a revive
                            if(miner.revives > 0){
                                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                                miner.health = miner.baseHealth / 4;
                                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                                // Remove revive from inventory
                                miner.revives--;
                            } else {
                                // He/she dead, bro
                                break;
                            }
                        }

                        // Get random offset from Miner's base attack for this turn
                        chamberData.var_int16_1 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[13]) % 8));
                        // Adjust Miner's attack modifier to be a range of -4 to 4, no zero (negative numbers will be a buff, positive will be debuff)
                        chamberData.var_int16_1 = chamberData.var_int16_1 - (chamberData.var_int16_1 < 4 ? int16(4) : int16(3));

                        // Attack monster
                        monster.health = monster.health - miner.attack - chamberData.var_int16_1 - (miner.buffTurns > 0 ? int16(4) : int16(0)) + (miner.debuffTurns > 0 ? int16(4) : int16(0));

                    } else {
                        // Miner goes first

                        // Get random offset from Miner's base attack for this turn
                        chamberData.var_int16_1 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[13]) % 8));
                        // Adjust Miner's attack modifier to be a range of -4 to 4, no zero (negative numbers will be a buff, positive will be debuff)
                        chamberData.var_int16_1 = chamberData.var_int16_1 - (chamberData.var_int16_1 < 4 ? int16(4) : int16(3));

                        // Attack monster
                        monster.health = monster.health - miner.attack - chamberData.var_int16_1 - (miner.buffTurns > 0 ? int16(4) : int16(0)) + (miner.debuffTurns > 0 ? int16(4) : int16(0));

                        // Check if monster is dead
                        if(monster.health < 1){
                            // It dead, bro
                            break;
                        } else {

                            // Get random offset from monster's base attack for this turn
                            chamberData.var_int16_4 = int16(int8(uint8(keccak256(abi.encodePacked(hash,chamberData.var_uint8_2))[14]) % 8));
                            // Adjust monster's attack modifier to be a range of -4 to 4, no zero (positive numbers will be a buff, negative will be debuff)
                            chamberData.var_int16_4 = chamberData.var_int16_4 - (chamberData.var_int16_4 < 4 ? int16(4) : int16(3));

                            // Calculate total damage taken
                            chamberData.var_int16_2 = monster.attack + chamberData.var_int16_4;

                            // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                            // Value is 1/2 instead of 1/3 for Warriors
                            chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                            // Sub armor damage from armor
                            miner.armor = miner.armor - chamberData.var_int16_3;
                            // Sub health damage from health
                            miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                            // If armor has been broken, pass excess damage to health and set armor to zero
                            if(miner.armor < 0){
                                miner.health = miner.health + miner.armor;
                                miner.armor = 0;
                            }

                            // Check if Miner is dead but has a revive
                            if(miner.health < 1 && miner.revives > 0){
                                // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                                miner.health = miner.baseHealth / 4;
                                miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                                // Remove revive from inventory
                                miner.revives--;
                            }
                        }
                    }
                    // Add one to loop/turn count
                    chamberData.var_uint8_2++;
                }
            } else if(chamberData.var_uint8_1 == 4){ // TRAP

                // Calculate trap damage
                chamberData.var_int16_2 = int16(int8(uint8(hash[2]) % 16) + 32);

                // Check if Miner is an assassin
                if(miner.classId == 3){
                    // // Miner is an assassin! Cut trap damage in half
                    chamberData.var_int16_2 = (chamberData.var_int16_2 / 2);
                }

                // Sub 1/3 of total damage from total damage for armor damage (do this instead of dmg / 3 * 2 because of integer floor rounding - would favor health damage instead of armor)
                // Value is 1/2 instead of 1/3 for Warriors
                chamberData.var_int16_3 = chamberData.var_int16_2 - (chamberData.var_int16_2 / (miner.classId == 0 ? int16(2) : int16(3)));

                // Sub armor damage from armor
                miner.armor = miner.armor - chamberData.var_int16_3;
                // Sub health damage from health
                miner.health = miner.health - (chamberData.var_int16_2 - chamberData.var_int16_3);
                // If armor has been broken, pass excess damage to health and set armor to zero
                if(miner.armor < 0){
                    miner.health = miner.health + miner.armor;
                    miner.armor = 0;
                }

                // Check if Miner is dead but has a revive
                if(miner.health < 1 && miner.revives > 0){
                    // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                    miner.health = miner.baseHealth / 4;
                    miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                    // Remove revive from inventory
                    miner.revives--;
                }
            } else if(chamberData.var_uint8_1 == 5){ // CURSE

                // Check if the Miner IS NOT a mage
                if(miner.classId != 1){
                    // Miner is not a mage! Curse this mf
                    // Calculate curse damage taken (10 percent of current health or 5 if Miner has less than 50 health)
                    chamberData.var_int16_1 = miner.health < 50 ? int16(5) : (miner.health / 10);

                    // Sub curse damage from health
                    miner.health = miner.health - chamberData.var_int16_1;

                    // Check if Miner is dead but has a revive
                    if(miner.health < 1 && miner.revives > 0){
                        // Revive with 1/4 health and 1/4 armor IF current armor is less than current armor
                        miner.health = miner.baseHealth / 4;
                        miner.armor = miner.armor < (miner.baseArmor / 4) ? (miner.baseArmor / 4) : miner.armor;
                        // Remove revive from inventory
                        miner.revives--;
                    }

                    // Add curse for 4 more chambers
                    miner.curseTurns = 4;
                }

            } else if(chamberData.var_uint8_1 == 6){ // BUFF
                // Add buff for 3 chambers (adding one extra because it will be removed at the end of loop)
                miner.buffTurns = miner.buffTurns + 4;
            } else if(chamberData.var_uint8_1 == 7){ // DEBUFF
                // Add debuff for 3 chambers (adding one extra because it will be removed at the end of loop)
                miner.debuffTurns = miner.debuffTurns + 4;
            } else if(chamberData.var_uint8_1 == 8){ // GOLD
                // Add gold to inventory
                miner.gold = miner.gold + uint16(uint8(hash[8]) % 24) + 2;

            } else if(chamberData.var_uint8_1 == 9){ // THIEF
                // Check if the Miner is an assassin
                if(miner.classId == 3){
                    // Miner is an assassin! Give a low-tier item (uncommon or rare)

                    // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                    chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                    // Gear rarity
                    // Add 128 to modulo 123 to get item from uncommon or rare rarity tiers
                    chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) % 123) + 128);

                    // Gear ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? chamberData.var_uint8_3 : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 8) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear health buff to health
                    miner.health = miner.health + gearItem[0];
                    // Add gear armor buff to baseArmor
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear armor buff to armor
                    miner.armor = miner.armor + gearItem[1];
                    // Add gear attack buff to attack
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed
                    miner.speed = miner.speed + gearItem[3];

                } else {
                    // Miner IS NOT an assassin, let's steal some gold
                    // uint16 goldStolen
                    chamberData.var_uint16_1 = uint16(uint8(hash[8]) % 16) + 1;

                    // Remove stolen gold from Miner
                    miner.gold = miner.gold > chamberData.var_uint16_1 ? (miner.gold - chamberData.var_uint16_1) : 0;
                }
            // } else if(chamberData.var_uint8_1 == 10){ // EMPTY
                // Nothing happens here
            } else if(chamberData.var_uint8_1 == 11){ // REST
                // Restore health
                miner.health = miner.health + int16(int8(uint8(hash[9]) % 24)) + 7;

                // Check if health is greater than baseHealth
                if(miner.health > miner.baseHealth){
                    // Miner is way too healthy, set health to baseHealth
                    miner.health = miner.baseHealth;
                }

            } else if(chamberData.var_uint8_1 == 12){ // GEAR
                // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                // Gear rarity
                // If less than 128, add 128 to the hash val (rarity tiers start at uncommon and double chance for each tier)
                chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) < 128 ? uint8(hash[16 + chamberData.var_uint8_2]) + 128 : uint8(hash[16 + chamberData.var_uint8_2])));

                // Gear ID
                chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                // Define array for gearItem stats
                int16[6] memory gearItem;

                // Check which gear type and add values appropriately
                if(chamberData.var_uint8_2 == 0){
                    // Get headgear stats
                    gearItem = headgearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.headgearId){
                        miner.headgearId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 1){
                    // Get armor stats
                    gearItem = armorStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.armorId){
                        miner.armorId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 2){
                    // Get pants stats
                    gearItem = pantsStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.pantsId){
                        miner.pantsId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 3){
                    // Get footwear stats
                    gearItem = footwearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.footwearId){
                        miner.footwearId = chamberData.var_uint8_4;
                    }
                } else {
                    // Get weapon stats
                    gearItem = weaponStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.weaponId){
                        miner.weaponId = chamberData.var_uint8_4;
                    }
                }
                // Add gear health buff to baseHealth
                miner.baseHealth = miner.baseHealth + gearItem[0];
                // Add gear health buff to health
                miner.health = miner.health + gearItem[0];
                // Add gear armor buff to baseArmor
                miner.baseArmor = miner.baseArmor + gearItem[1];
                // Add gear armor buff to armor
                miner.armor = miner.armor + gearItem[1];
                // Add gear attack buff to attack
                miner.attack = miner.attack + gearItem[2];
                // Add gear speed buff to speed
                miner.speed = miner.speed + gearItem[3];

            } else if(chamberData.var_uint8_1 == 13){ // MERCHANT

                // Check if Miner has enough gold for item (min 25)
                if(miner.gold > 24){
                    // Miner can afford to purchase some gear, assign gear type
                    // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                    chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                    // Check what the Miner can afford
                    if(miner.gold < 50){
                        // Buy uncommon item

                        // Gear rarity - assign 1-4 for uncommon
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 4) + 1;
                        // Pay the merchant
                        miner.gold = miner.gold - 25;
                    } else if (miner.gold < 75){
                        // Buy rare item

                        // Gear rarity - assign 5-7 for rare
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 3) + 5;
                        // Pay the merchant
                        miner.gold = miner.gold - 50;
                    }
                    else if (miner.gold < 100){
                        // Buy epic item

                        // Gear rarity - assign 8-9 for epic
                        chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 2) + 8;
                        // Pay the merchant
                        miner.gold = miner.gold - 75;
                    } else {
                        // Buy legendary item

                        // Gear rarity - assign 10 for legendary
                        chamberData.var_uint8_3 = 10;
                        // Pay the merchant
                        miner.gold = miner.gold - 100;
                    }

                    // Determine Gear ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (chamberData.var_uint8_3 > 4 ? (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId) : chamberData.var_uint8_3)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear health buff to health
                    miner.health = miner.health + gearItem[0];
                    // Add gear armor buff to baseArmor
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear armor buff to armor
                    miner.armor = miner.armor + gearItem[1];
                    // Add gear attack buff to attack
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed
                    miner.speed = miner.speed + gearItem[3];
                }

            } else if(chamberData.var_uint8_1 == 14){ // TREASURE

                // Add found gold to gold
                miner.gold = miner.gold + uint16(uint8(hash[8]) % 48) + 28;

                // Gear type (0 == headgear, 1 == armor, 2 == pants, 3 == footwear, 4 == weapon)
                chamberData.var_uint8_2 = uint8(hash[13]) % 5;

                // Gear rarity
                // Modulo of 32, add 224 to the hash val to get a value between 224-255 (rarity tiers start at rare)
                chamberData.var_uint8_3 = gType((uint8(hash[16 + chamberData.var_uint8_2]) % 32) + 224);

                // Determine Gear ID
                chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (chamberData.var_uint8_3 > 8 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : chamberData.var_uint8_3) : (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId)) + (17 * chamberData.var_uint8_2);

                // Define array for gearItem stats
                int16[6] memory gearItem;

                // Check which gear type and add values appropriately
                if(chamberData.var_uint8_2 == 0){
                    // Get headgear stats
                    gearItem = headgearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.headgearId){
                        miner.headgearId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 1){
                    // Get armor stats
                    gearItem = armorStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.armorId){
                        miner.armorId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 2){
                    // Get pants stats
                    gearItem = pantsStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.pantsId){
                        miner.pantsId = chamberData.var_uint8_4;
                    }
                } else if(chamberData.var_uint8_2 == 3){
                    // Get footwear stats
                    gearItem = footwearStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.footwearId){
                        miner.footwearId = chamberData.var_uint8_4;
                    }
                } else {
                    // Get weapon stats
                    gearItem = weaponStats(chamberData.var_uint8_4);
                    // If gearId is higher than Miner's current gearId, reassign visible gear
                    if(chamberData.var_uint8_4 > miner.weaponId){
                        miner.weaponId = chamberData.var_uint8_4;
                    }
                }
                // Add gear health buff to baseHealth
                miner.baseHealth = miner.baseHealth + gearItem[0];
                // Add gear health buff to health
                miner.health = miner.health + gearItem[0];
                // Add gear armor buff to baseArmor
                miner.baseArmor = miner.baseArmor + gearItem[1];
                // Add gear armor buff to armor
                miner.armor = miner.armor + gearItem[1];
                // Add gear attack buff to attack
                miner.attack = miner.attack + gearItem[2];
                // Add gear speed buff to speed
                miner.speed = miner.speed + gearItem[3];
            } else if(chamberData.var_uint8_1 == 15){ // HEAL

                // Restore health by 1/2 baseHealth
                miner.health = miner.health + (miner.baseHealth / 2);
                // Check if health is greater than baseHealth
                if(miner.health > miner.baseHealth){
                    // Miner is way too healthy, set health to baseHealth
                    miner.health = miner.baseHealth;
                }

                // Restore armor by 1/2 baseArmor
                miner.armor = miner.armor + (miner.baseArmor / 2);

                // Check if armor is greater than baseArmor
                if(miner.armor > miner.baseArmor){
                    // Miner is way too tanky, set armor to baseArmor
                    miner.armor = miner.baseArmor;
                }
            } else if(chamberData.var_uint8_1 == 16){ // REVIVE
                // Add revive to inventory
                miner.revives++;

            } else if(chamberData.var_uint8_1 == 17){ // ARMORY
                // Oh baby, this Miner is about to get BROLIC

                // Loop through gear types to add all to gear stats
                for(chamberData.var_uint8_2 = 0; chamberData.var_uint8_2 < 5; chamberData.var_uint8_2++){

                    // Gear rarity
                    // 3/4 chance of epic, 1/4 chance of legendary
                    chamberData.var_uint8_3 = (uint8(hash[16 + chamberData.var_uint8_2]) % 4) < 3 ? 9 : 10;

                    // Determine Gear ID
                    chamberData.var_uint8_4 = (chamberData.var_uint8_2 < 4 ? (((chamberData.var_uint8_3 - 9) * 4) + 9 + miner.classId) : (((chamberData.var_uint8_3 - 5) * 4) + 5 + miner.classId)) + (17 * chamberData.var_uint8_2);

                    // Define array for gearItem stats
                    int16[6] memory gearItem;

                    // Check which gear type and add values appropriately
                    if(chamberData.var_uint8_2 == 0){
                        // Get headgear stats
                        gearItem = headgearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.headgearId){
                            miner.headgearId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 1){
                        // Get armor stats
                        gearItem = armorStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.armorId){
                            miner.armorId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 2){
                        // Get pants stats
                        gearItem = pantsStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.pantsId){
                            miner.pantsId = chamberData.var_uint8_4;
                        }
                    } else if(chamberData.var_uint8_2 == 3){
                        // Get footwear stats
                        gearItem = footwearStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.footwearId){
                            miner.footwearId = chamberData.var_uint8_4;
                        }
                    } else {
                        // Get weapon stats
                        gearItem = weaponStats(chamberData.var_uint8_4);
                        // If gearId is higher than Miner's current gearId, reassign visible gear
                        if(chamberData.var_uint8_4 > miner.weaponId){
                            miner.weaponId = chamberData.var_uint8_4;
                        }
                    }
                    // Add gear health buff to baseHealth
                    miner.baseHealth = miner.baseHealth + gearItem[0];
                    // Add gear armor buff to baseArmor
                    miner.baseArmor = miner.baseArmor + gearItem[1];
                    // Add gear attack buff to attack
                    miner.attack = miner.attack + gearItem[2];
                    // Add gear speed buff to speed
                    miner.speed = miner.speed + gearItem[3];
                }
                // Set current Miner health to base health
                miner.health = miner.baseHealth;
                // Set current Miner armor to base armor
                miner.armor = miner.baseArmor;
            }
        }

        // Post-encounter calculations

        // If the Miner has at least one buff turn remaining, remove a buff turn
        if(miner.buffTurns > 0){
            miner.buffTurns--;
        }
        // If the Miner has at least one debuff turn remaining, remove a debuff turn
        if(miner.debuffTurns > 0){
            miner.debuffTurns--;
        }
        // Return the Miner
        return miner;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct Monster {
    int16 health;
    int16 attack;
    int16 speed;
    uint8 mtype;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

struct PackedVars {
    int8 var_int8_1;
    int8 var_int8_2;
    int8 var_int8_3;
    int8 var_int8_4;
    int8 var_int8_5;
    int8 var_int8_6;
    uint8 var_uint8_1;
    uint8 var_uint8_2;
    uint8 var_uint8_3;
    uint8 var_uint8_4;
    uint8 var_uint8_5;
    uint8 var_uint8_6;
    int16 var_int16_1;
    int16 var_int16_2;
    int16 var_int16_3;
    int16 var_int16_4;
    uint16 var_uint16_1;
    uint16 var_uint16_2;
    uint16 var_uint16_3;
    uint16 var_uint16_4;
    uint32 var_uint32_1;
}