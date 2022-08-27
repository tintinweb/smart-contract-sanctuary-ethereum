/* --------------------------------- ******* ----------------------------------- 
                                       THE

                            ███████╗██╗   ██╗███████╗
                            ██╔════╝╚██╗ ██╔╝██╔════╝
                            █████╗   ╚████╔╝ █████╗  
                            ██╔══╝    ╚██╔╝  ██╔══╝  
                            ███████╗   ██║   ███████╗
                            ╚══════╝   ╚═╝   ╚══════╝
                                 FOR ADVENTURERS
                                                                                   
                             .-=++=-.........-=++=-                  
                        .:..:++++++=---------=++++++:.:::            
                     .=++++----=++-------------===----++++=.         
                    .+++++=---------------------------=+++++.
                 .:-----==------------------------------------:.     
                =+++=---------------------------------------=+++=    
               +++++=---------------------------------------=++++=   
               ====-------------=================-------------===-   
              -=-------------=======================-------------=-. 
            :+++=----------============ A ============----------=+++:
            ++++++--------======= MAGICAL DEVICE =======---------++++=
            -++=----------============ THAT ============----------=++:
             ------------=========== CONTAINS ==========------------ 
            :++=---------============== AN =============----------=++-
            ++++++--------========== ON-CHAIN =========--------++++++
            :+++=----------========== WORLD ==========----------=+++:
              .==-------------=======================-------------=-  
                -=====----------===================----------======   
               =+++++---------------------------------------++++++   
                =+++-----------------------------------------+++=    
                  .-=----===---------------------------===-----:.     
                      .+++++=---------------------------=+++++.        
                       .=++++----=++-------------++=----++++=:         
                         :::.:++++++=----------++++++:.:::            
                                -=+++-.........-=++=-.                 

                            HTTPS://EYEFORADVENTURERS.COM
   ----------------------------------- ******* ---------------------------------- */

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

contract EyeConstants {
    uint16 public constant NAME_PREFIX_COUNT = 69;
    uint16 public constant NAME_SUFFIX_COUNT = 18;
    uint16 public constant ORDER_COUNT = 16;
    uint16 public constant VISION_COUNT = 64;
    uint16 public constant CONDITION_COUNT = 4;

    function getConditionCount() external pure returns (uint16) {
        return CONDITION_COUNT;
    }

    function getVisionCount() external pure returns (uint16) {
        return VISION_COUNT;
    }

    function getNamePrefixCount() external pure returns (uint16) {
        return NAME_PREFIX_COUNT;
    }

    function getNameSuffixCount() external pure returns (uint16) {
        return NAME_SUFFIX_COUNT;
    }

    function getOrderCount() external pure returns (uint16) {
        return ORDER_COUNT;
    }

    function getVisionName(uint256 index)
        external
        pure
        returns (string memory visionName)
    {
        if (index == 0) {
            return "Catacombs";
        } else if (index == 1) {
            return "Lost Realm";
        } else if (index == 2) {
            return "The Mist";
        } else if (index == 3) {
            return "Riverlands";
        } else if (index == 4) {
            return "Star Field";
        } else if (index == 5) {
            return "Interface";
        } else if (index == 6) {
            return "Pure Stone";
        } else if (index == 7) {
            return "Watcher";
        } else if (index == 8) {
            return "Grotto";
        } else if (index == 9) {
            return "Shrine";
        } else if (index == 10) {
            return "Eve";
        } else if (index == 11) {
            return "Prison";
        } else if (index == 12) {
            return "The Eternal Flame";
        } else if (index == 13) {
            return "Dream";
        } else if (index == 14) {
            return "Dragonskin";
        } else if (index == 15) {
            return "Labyrinth";
        } else if (index == 16) {
            return "The Rift";
        } else if (index == 17) {
            return "Mana Spirit";
        } else if (index == 18) {
            return "The Depths";
        } else if (index == 19) {
            return "The Soulless Well";
        } else if (index == 20) {
            return "The Mother Grove";
        } else if (index == 21) {
            return "Wheel";
        } else if (index == 22) {
            return "Willows";
        } else if (index == 23) {
            return "True Ice";
        } else if (index == 24) {
            return "Deeptides";
        } else if (index == 25) {
            return "Holy Mirror";
        } else if (index == 26) {
            return "Night Moon";
        } else if (index == 27) {
            return "The Origin Oasis";
        } else if (index == 28) {
            return "Eternal Orchard";
        } else if (index == 29) {
            return "Brightsilk";
        } else if (index == 30) {
            return "Endless Landscape";
        } else if (index == 31) {
            return "Spectre";
        } else if (index == 32) {
            return "Mythic Trees";
        } else if (index == 33) {
            return "Vale";
        } else if (index == 34) {
            return "Hideout";
        } else if (index == 35) {
            return "Graveyard";
        } else if (index == 36) {
            return "Altar of the Void";
        } else if (index == 37) {
            return "Canvas";
        } else if (index == 38) {
            return "Mountain";
        } else if (index == 39) {
            return "Ring of Fire";
        } else if (index == 40) {
            return "Lair";
        } else if (index == 41) {
            return "Demonhide";
        } else if (index == 42) {
            return "Maze";
        } else if (index == 43) {
            return "Watchtower";
        } else if (index == 44) {
            return "Divine Light";
        } else if (index == 45) {
            return "Longship";
        } else if (index == 46) {
            return "Lagoona";
        } else if (index == 47) {
            return "Healtreey";
        } else if (index == 48) {
            return "Ancient Cross";
        } else if (index == 49) {
            return "Shield";
        } else if (index == 50) {
            return "Noctii";
        } else if (index == 51) {
            return "Day Star";
        } else if (index == 52) {
            return "The Celestial Vertex";
        } else if (index == 53) {
            return "Reflection";
        } else if (index == 54) {
            return "Fog";
        } else if (index == 55) {
            return "Sanctum";
        } else if (index == 56) {
            return "A voice whispers through the Mist";
        } else if (index == 57) {
            return "All that stands will burn";
        } else if (index == 58) {
            return "The forbidden magick of Deriving";
        } else if (index == 59) {
            return "An invitation to build";
        } else if (index == 60) {
            return "An infinitely-expansive Librarium";
        } else if (index == 61) {
            return "XXXXXX";
        } else if (index == 62) {
            return "??????";
        } else if (index == 63) {
            return "!!!!!!";
        } else {
            return "";
        }
    }

    function getNameSuffix(uint256 index)
        external
        pure
        returns (string memory namePrefix)
    {
        if (index == 0) {
            return "Bane";
        } else if (index == 1) {
            return "Root";
        } else if (index == 2) {
            return "Bite";
        } else if (index == 3) {
            return "Song";
        } else if (index == 4) {
            return "Roar";
        } else if (index == 5) {
            return "Grasp";
        } else if (index == 6) {
            return "Instrument";
        } else if (index == 7) {
            return "Glow";
        } else if (index == 8) {
            return "Bender";
        } else if (index == 9) {
            return "Shadow";
        } else if (index == 10) {
            return "Whisper";
        } else if (index == 11) {
            return "Shout";
        } else if (index == 12) {
            return "Growl";
        } else if (index == 13) {
            return "Tear";
        } else if (index == 14) {
            return "Peak";
        } else if (index == 15) {
            return "Form";
        } else if (index == 16) {
            return "Sun";
        } else if (index == 17) {
            return "Moon";
        } else {
            return "";
        }
    }

    function getNamePrefix(uint256 index)
        external
        pure
        returns (string memory namePrefix)
    {
        if (index == 0) {
            return "Agony";
        } else if (index == 1) {
            return "Apocalypse";
        } else if (index == 2) {
            return "Armageddon";
        } else if (index == 3) {
            return "Beast";
        } else if (index == 4) {
            return "Behemoth";
        } else if (index == 5) {
            return "Blight";
        } else if (index == 6) {
            return "Blood";
        } else if (index == 7) {
            return "Bramble";
        } else if (index == 8) {
            return "Brimstone";
        } else if (index == 9) {
            return "Brood";
        } else if (index == 10) {
            return "Carrion";
        } else if (index == 11) {
            return "Cataclysm";
        } else if (index == 12) {
            return "Chimeric";
        } else if (index == 13) {
            return "Corpse";
        } else if (index == 14) {
            return "Corruption";
        } else if (index == 15) {
            return "Damnation";
        } else if (index == 16) {
            return "Death";
        } else if (index == 17) {
            return "Demon";
        } else if (index == 18) {
            return "Dire";
        } else if (index == 19) {
            return "Dragon";
        } else if (index == 20) {
            return "Dread";
        } else if (index == 21) {
            return "Doom";
        } else if (index == 22) {
            return "Dusk";
        } else if (index == 23) {
            return "Eagle";
        } else if (index == 24) {
            return "Empyrean";
        } else if (index == 25) {
            return "Fate";
        } else if (index == 26) {
            return "Foe";
        } else if (index == 27) {
            return "Gale";
        } else if (index == 28) {
            return "Ghoul";
        } else if (index == 29) {
            return "Gloom";
        } else if (index == 30) {
            return "Glyph";
        } else if (index == 31) {
            return "Golem";
        } else if (index == 32) {
            return "Grim";
        } else if (index == 33) {
            return "Hate";
        } else if (index == 34) {
            return "Havoc";
        } else if (index == 35) {
            return "Honour";
        } else if (index == 36) {
            return "Horror";
        } else if (index == 37) {
            return "Hypnotic";
        } else if (index == 38) {
            return "Kraken";
        } else if (index == 39) {
            return "Loath";
        } else if (index == 40) {
            return "Maelstrom";
        } else if (index == 41) {
            return "Mind";
        } else if (index == 42) {
            return "Miracle";
        } else if (index == 43) {
            return "Morbid";
        } else if (index == 44) {
            return "Oblivion";
        } else if (index == 45) {
            return "Onslaught";
        } else if (index == 46) {
            return "Pain";
        } else if (index == 47) {
            return "Pandemonium";
        } else if (index == 48) {
            return "Phoenix";
        } else if (index == 49) {
            return "Plague";
        } else if (index == 50) {
            return "Rage";
        } else if (index == 51) {
            return "Rapture";
        } else if (index == 52) {
            return "Rune";
        } else if (index == 53) {
            return "Skull";
        } else if (index == 54) {
            return "Sol";
        } else if (index == 55) {
            return "Soul";
        } else if (index == 56) {
            return "Sorrow";
        } else if (index == 57) {
            return "Spirit";
        } else if (index == 58) {
            return "Storm";
        } else if (index == 59) {
            return "Tempest";
        } else if (index == 60) {
            return "Torment";
        } else if (index == 61) {
            return "Vengeance";
        } else if (index == 62) {
            return "Victory";
        } else if (index == 63) {
            return "Viper";
        } else if (index == 64) {
            return "Vortex";
        } else if (index == 65) {
            return "Woe";
        } else if (index == 66) {
            return "Wrath";
        } else if (index == 67) {
            return "Light's";
        } else if (index == 68) {
            return "Shimmering";
        } else {
            return "";
        }
    }

    function getOrderName(uint256 order)
        external
        pure
        returns (string memory orderName)
    {
        if (order == 0) {
            orderName = "Power";
        } else if (order == 1) {
            orderName = "Giants";
        } else if (order == 2) {
            orderName = "Titans";
        } else if (order == 3) {
            orderName = "Skill";
        } else if (order == 4) {
            orderName = "Perfection";
        } else if (order == 5) {
            orderName = "Brilliance";
        } else if (order == 6) {
            orderName = "Enlightenment";
        } else if (order == 7) {
            orderName = "Protection";
        } else if (order == 8) {
            orderName = "Anger";
        } else if (order == 9) {
            orderName = "Rage";
        } else if (order == 10) {
            orderName = "Fury";
        } else if (order == 11) {
            orderName = "Vitriol";
        } else if (order == 12) {
            orderName = "the Fox";
        } else if (order == 13) {
            orderName = "Detection";
        } else if (order == 14) {
            orderName = "Reflection";
        } else if (order == 15) {
            orderName = "the Twins";
        }
    }
}