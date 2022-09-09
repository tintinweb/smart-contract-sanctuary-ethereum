// SPDX-License-Identifier: CC0-1.0

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G?77777J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GJP&&&&&&&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@B..7G&@@&G:^775P [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@G  ~&::[email protected] [email protected]@J  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@B..! :[email protected]@B^^775G [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:~&J7J&@@@@@@@& [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@& [email protected]@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:~&&&&&&&P#@B&& !GGG#@@@BYY&^^@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@@@@@.J&.Y&.!5YYJ7?JP##[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@:[email protected]@@@@@[email protected]~J#&@@?7!:[email protected]~ [email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@[email protected]^:@@@@@@@BYJJJJ&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G:[email protected]@@&G:^!.?#@@@@@@@@# J&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^[email protected]@@@@&&&@@@@@@@@@#5!#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5 B? B&&&J^@Y^#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5~.&Y &@&Y^[email protected][email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7Y55#Y^&B7Y5P#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@&YJJJ#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

pragma solidity ^0.8.13;

contract CryptoDickbuttsStrings {

    mapping(uint8 => string) strings;

    function getString(uint8 key) external view returns (string memory) {
        if(key >= 194 && key <= 203) return strings[255]; // None
        return strings[key];
    }

    constructor() {
        // Background (8)
        strings[2] = "Grassy Knoll";
        strings[4] = "Picnic Day";
        strings[3] = "Ocean Mist";
        strings[6] = "Stone Grey";
        strings[7] = "Sunset";
        strings[0] = "Buds";
        strings[5] = "Puls";
        strings[1] = "Denza";

        // Skin (11)
        strings[186] = "Mid";
        strings[191] = "Zombie";
        strings[182] = "Ape";
        strings[183] = "Dark";
        strings[185] = "Light";
        strings[181] = "Alien";
        strings[190] = "Vampire";
        strings[189] = "Skeleton";
        strings[184] = "Ghost";
        strings[188] = "Robot";
        strings[187] = "Rainbow";

        // Body (19)
        strings[16] = "Overalls";
        strings[8] = "Backpack";
        strings[9] = "Ballerina";
        strings[15] = "Mankini";
        strings[25] = "Vampire Cape";
        strings[11] = "Bikini";
        strings[13] = "Chest Hair";
        strings[12] = "Boxers";
        strings[21] = "Sash";
        strings[22] = "Tracksuit";
        strings[23] = "Trenchcoat";
        strings[18] = "Peed Pants";
        strings[10] = "Bee Wings";
        strings[24] = "Tuxedo";
        strings[20] = "Ruffles";
        strings[17] = "Pasties";
        strings[14] = "Jumpsuit";
        strings[19] = "Pox";

        // Hat (53)
        strings[134] = "Sanchez";
        strings[96] = "Afro";
        strings[143] = "Trucker";
        strings[114] = "Fez";
        strings[104] = "Bunny";
        strings[101] = "Birthday Hat";
        strings[117] = "Hero";
        strings[126] = "Mullet";
        strings[119] = "Jester";
        strings[115] = "Franky";
        strings[103] = "Bowl Cut";
        strings[110] = "Cute Ears";
        strings[147] = "Your Future";
        strings[140] = "Swimming Cap";
        strings[138] = "Straw Hat";
        strings[98] = "Army";
        strings[125] = "Mohawk";
        strings[135] = "Santa";
        strings[123] = "Marge";
        strings[100] = "Beret";
        strings[124] = "Miner";
        strings[113] = "Exposed Brain";
        strings[122] = "Long Hair";
        strings[142] = "Toque";
        strings[118] = "Horns";
        strings[105] = "Buns";
        strings[107] = "Captain";
        strings[121] = "Leeloo";
        strings[120] = "Karen";
        strings[133] = "Robinhood";
        strings[146] = "Witch";
        strings[137] = "Sombrero";
        strings[132] = "Poop";
        strings[106] = "Candle";
        strings[136] = "Siren";
        strings[99] = "Balaclava";
        strings[116] = "Fur Hat";
        strings[141] = "Tinfoil";
        strings[127] = "Ogre";
        strings[109] = "Cowboy";
        strings[131] = "Plant";
        strings[128] = "Party Hat";
        strings[111] = "Detective";
        strings[102] = "Bonnet";
        strings[108] = "Cat";
        strings[145] = "Visor";
        strings[97] = "Antennae";
        strings[130] = "Pirate";
        strings[112] = "Dino";
        strings[144] = "Unicorn";
        strings[129] = "Pharaoh";
        strings[139] = "Strawberry";

        // Eyes (26)
        strings[65] = "Ski Goggles";
        strings[58] = "Heart";
        strings[61] = "Masquerade";
        strings[59] = "Hippie";
        strings[64] = "Single Lens";
        strings[48] = "Alien";
        strings[63] = "Potter";
        strings[53] = "Designer";
        strings[51] = "Clout";
        strings[70] = "Welding Mask";
        strings[68] = "Swimming Goggles";
        strings[49] = "Blindfold";
        strings[60] = "Mascara";
        strings[57] = "Green";
        strings[54] = "Eyelashes";
        strings[62] = "Nerd";
        strings[72] = "White";
        strings[56] = "Googly";
        strings[67] = "Steampunk";
        strings[50] = "Blue";
        strings[52] = "Cyborg";
        strings[71] = "White Mask";
        strings[66] = "Skull Mask";
        strings[55] = "Gas Mask";
        strings[69] = "Third Eye";

        // Mouth (5)
        strings[164] = "Drool";
        strings[165] = "Pierced";
        strings[163] = "Clown";
        strings[162] = "Cigar";

        // Nose (4)
        strings[166] = "Pierced";
        strings[167] = "Piggy";
        strings[168] = "Squid";

        // Hand (24)
        strings[74] = "Boxing Glove";
        strings[91] = "Spiked Club";
        strings[79] = "Flowers";
        strings[84] = "Lollipop";
        strings[86] = "Megaphone";
        strings[92] = "Torch";
        strings[75] = "Camera";
        strings[94] = "Wine";
        strings[87] = "Pencil";
        strings[89] = "Scythe";
        strings[83] = "Lifesaver";
        strings[85] = "Luggage";
        strings[80] = "Gavel";
        strings[90] = "Skateboard";
        strings[82] = "Keyboard";
        strings[78] = "Flamethrower";
        strings[77] = "Flag";
        strings[88] = "Pickle";
        strings[81] = "Hero's Sword";
        strings[76] = "Cardboard Sign";
        strings[93] = "Trident";
        strings[95] = "Wizard's Staff";
        strings[73] = "Baggie";

        // Shoes (13)
        strings[178] = "Roman Sandals";
        strings[174] = "Knight";
        strings[180] = "Trainers";
        strings[169] = "Basketball";
        strings[172] = "Chucks";
        strings[173] = "Gym Socks";
        strings[179] = "Socks & Sandals";
        strings[175] = "Pegleg";
        strings[171] = "Carpet";
        strings[177] = "Rollerskates";
        strings[176] = "Rocket";
        strings[170] = "Bunny Slippers";

        // Butt (4)
        strings[28] = "Wounded";
        strings[26] = "Gassy";
        strings[27] = "Reddish";

        // Dick (20)
        strings[38] = "Mushroom";
        strings[31] = "Chicken";
        strings[33] = "Elephant Trunk";
        strings[40] = "Old Sock";
        strings[37] = "Fuse";
        strings[46] = "Tentacle";
        strings[29] = "Cannon";
        strings[35] = "Flower";
        strings[42] = "Purpy";
        strings[36] = "Fox";
        strings[47] = "Umbrella";
        strings[41] = "Pierced";
        strings[30] = "Carrot";
        strings[43] = "Rocket";
        strings[34] = "Flame";
        strings[32] = "Dynamite";
        strings[39] = "Oh Canada";
        strings[44] = "Scorpion";
        strings[45] = "Spidey";

        // Special (3)
        strings[192] = "Buddy";
        strings[193] = "Shiba";

        // Legendary (14)
        strings[148] = "Bananabutt";
        strings[155] = "Dixty Nine";
        strings[153] = "Dickfits";
        strings[150] = "Cryptoad Dickbutt";
        strings[158] = "Paris";
        strings[159] = "Prototype";
        strings[149] = "Butt De Kooning";
        strings[160] = "Spider-butt";
        strings[151] = "Dicka Lisa";
        strings[157] = "Lady Libutty";
        strings[156] = "Dotbutt";
        strings[161] = "Telebutty";
        strings[152] = "Dickasus";
        strings[154] = "Dickpet";

        // None
        strings[255] = "None";
    }
}