/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Scumbugs Data Values
 */
contract ScumbugsValues {

    mapping(uint8 => bytes32) public handMap;
    mapping(uint8 => bytes32) public bodyMap;
    mapping(uint8 => bytes32) public eyesMap;
    mapping(uint8 => bytes32) public headMap;
    mapping(uint8 => bytes32) public mouthMap;
    mapping(uint8 => bytes32) public backgroundMap;
    mapping(uint8 => bytes32) public bugTypeMap;


    constructor() {
        // Initialize hand map
        handMap[0] = bytes32("No traits");
        handMap[1] = bytes32("Bug You");
        handMap[2] = bytes32("Smoke");
        handMap[3] = bytes32("Money Talk");
        handMap[4] = bytes32("Bug Spray");
        handMap[5] = bytes32("Camcorder");
        handMap[6] = bytes32("Golf Club");
        handMap[7] = bytes32("Spicey");
        handMap[8] = bytes32("Genius");
        handMap[9] = bytes32("All In");
        handMap[10] = bytes32("Fishing Rod");
        handMap[11] = bytes32("Lactose Intolerant");
        handMap[12] = bytes32("Pizza");
        handMap[13] = bytes32("Scum Drink");
        handMap[14] = bytes32("Selfie Stick");
        handMap[15] = bytes32("Fake Watch");
        handMap[16] = bytes32("Rings");
        handMap[17] = bytes32("Boujee");
        handMap[18] = bytes32("Scissorhands");
        handMap[19] = bytes32("Artist");
        handMap[20] = bytes32("Graffiti");
        handMap[21] = bytes32("Lasso");
        handMap[22] = bytes32("Mic");
        handMap[23] = bytes32("Wood");
        handMap[24] = bytes32("Spy");
        handMap[25] = bytes32("Lettuce Finger");
        handMap[26] = bytes32("Baller");
        handMap[27] = bytes32("Katana");
        handMap[28] = bytes32("Scary Puppet");
        handMap[29] = bytes32("Sippin");
        handMap[30] = bytes32("Shroom");
        handMap[31] = bytes32("Banana Gun");
        handMap[32] = bytes32("Flask");
        handMap[33] = bytes32("Boombox");
        handMap[34] = bytes32("Larry SB");
        handMap[35] = bytes32("Wonderful gm");
        handMap[36] = bytes32("Slingshot");
        handMap[37] = bytes32("Skateboard");
        handMap[38] = bytes32("Glow Stick");
        handMap[39] = bytes32("Sadomaso");
        handMap[40] = bytes32("Demi God");
        handMap[41] = bytes32("I Can Point This");

        // Initialize body map
        bodyMap[0] = bytes32("No traits");
        bodyMap[1] = bytes32("Logo T");
        bodyMap[2] = bytes32("System B");
        bodyMap[3] = bytes32("Daddy's Rich");
        bodyMap[4] = bytes32("McScumin");
        bodyMap[5] = bytes32("Stunt Bug");
        bodyMap[6] = bytes32("Bug Squad");
        bodyMap[7] = bytes32("Track Jacket");
        bodyMap[8] = bytes32("Polo");
        bodyMap[9] = bytes32("Boomer");
        bodyMap[10] = bytes32("Turtleneck");
        bodyMap[11] = bytes32("Coconut Bra");
        bodyMap[12] = bytes32("Tie-dye");
        bodyMap[13] = bytes32("Life Jacket");
        bodyMap[14] = bytes32("Down Jacket");
        bodyMap[15] = bytes32("Perfecto");
        bodyMap[16] = bytes32("Thunder Fleece");
        bodyMap[17] = bytes32("Spandex");
        bodyMap[18] = bytes32("Bugs Racing");
        bodyMap[19] = bytes32("Scum Bag");
        bodyMap[20] = bytes32("Trailer Park Bugs");
        bodyMap[21] = bytes32("Disco Shirt");
        bodyMap[22] = bytes32("Knit");
        bodyMap[23] = bytes32("Gloves Jacket");
        bodyMap[24] = bytes32("Sherpa Fleece");
        bodyMap[25] = bytes32("Velvet Hoodie");
        bodyMap[26] = bytes32("Hoodie Up");
        bodyMap[27] = bytes32("Denim Jacket");
        bodyMap[28] = bytes32("Biker Vest");
        bodyMap[29] = bytes32("Sherling Jacket");
        bodyMap[30] = bytes32("V God");
        bodyMap[31] = bytes32("Trench Coat");
        bodyMap[32] = bytes32("Tuxedo");
        bodyMap[33] = bytes32("Dragon Shirt");
        bodyMap[34] = bytes32("Scammer");
        bodyMap[35] = bytes32("B.W.A.");
        bodyMap[36] = bytes32("Punk Jacket");
        bodyMap[37] = bytes32("Loose Knit");
        bodyMap[38] = bytes32("Red Puffer");
        bodyMap[39] = bytes32("Wolf");
        bodyMap[40] = bytes32("King Robe");
        bodyMap[41] = bytes32("Notorious B.U.G.");
        bodyMap[42] = bytes32("Scum God Jacket");
        bodyMap[43] = bytes32("Fast Lane");
        bodyMap[44] = bytes32("Iced Out Chain");
        bodyMap[45] = bytes32("Flower Costume");
        bodyMap[46] = bytes32("Cold Chain");
        bodyMap[47] = bytes32("Straight Jacket");
        bodyMap[48] = bytes32("Predator Costume");
        bodyMap[49] = bytes32("White & Gold Dress");
        bodyMap[50] = bytes32("Spike Jacket");
        bodyMap[51] = bytes32("Invisibility Cloak");
        bodyMap[52] = bytes32("GOAT Jacket");
        bodyMap[53] = bytes32("Black & Blue Dress");

        // Initialize eyes map
        eyesMap[0] = bytes32("No traits");
        eyesMap[1] = bytes32("Clear Eyes");
        eyesMap[2] = bytes32("Sus");
        eyesMap[3] = bytes32("Scum");
        eyesMap[4] = bytes32("Shroomed");
        eyesMap[5] = bytes32("Shark");
        eyesMap[6] = bytes32("Cleo");
        eyesMap[7] = bytes32("Soft Glam");
        eyesMap[8] = bytes32("Goat");
        eyesMap[9] = bytes32("Cat");
        eyesMap[10] = bytes32("Clown");
        eyesMap[11] = bytes32("Tearful");
        eyesMap[12] = bytes32("Mesmerized");
        eyesMap[13] = bytes32("Scum Clown");
        eyesMap[14] = bytes32("Blind");
        eyesMap[15] = bytes32("Black Eye");
        eyesMap[16] = bytes32("Black Eye Scum");

        // Initialize head map
        headMap[0] = bytes32("No traits");
        headMap[1] = bytes32("Logo Cap");
        headMap[2] = bytes32("Beanie");
        headMap[3] = bytes32("Mullet");
        headMap[4] = bytes32("Dreadlocks");
        headMap[5] = bytes32("V-cut");
        headMap[6] = bytes32("Sleek");
        headMap[7] = bytes32("Trucker Hat");
        headMap[8] = bytes32("Preppy");
        headMap[9] = bytes32("Bun");
        headMap[10] = bytes32("Black Bucket Hat");
        headMap[11] = bytes32("Fade");
        headMap[12] = bytes32("Ushanka");
        headMap[13] = bytes32("Red Spikes");
        headMap[14] = bytes32("Beach");
        headMap[15] = bytes32("Afro");
        headMap[16] = bytes32("Lover Bug");
        headMap[17] = bytes32("New Jack City");
        headMap[18] = bytes32("Blume");
        headMap[19] = bytes32("Mohawk");
        headMap[20] = bytes32("Fitted Cap");
        headMap[21] = bytes32("Karen");
        headMap[22] = bytes32("Blond Bowlcut");
        headMap[23] = bytes32("The King");
        headMap[24] = bytes32("Durag");
        headMap[25] = bytes32("Bucket Hat");
        headMap[26] = bytes32("Bus Driver");
        headMap[27] = bytes32("Black Bowlcut");
        headMap[28] = bytes32("Rawr xd");
        headMap[29] = bytes32("Cowboy");
        headMap[30] = bytes32("Aerobics");
        headMap[31] = bytes32("Rattail");
        headMap[32] = bytes32("Clown");
        headMap[33] = bytes32("Hair Metal");
        headMap[34] = bytes32("Unibruh");
        headMap[35] = bytes32("Biker");
        headMap[36] = bytes32("Piercing");
        headMap[37] = bytes32("/");
        headMap[38] = bytes32("Knot Head");
        headMap[39] = bytes32("Say No More");
        headMap[40] = bytes32("Mixologist");
        headMap[41] = bytes32("Sahara Cap");
        headMap[42] = bytes32("Cheetah Fur Hat");
        headMap[43] = bytes32("Pharaoh");
        headMap[44] = bytes32("Giga Brain");
        headMap[45] = bytes32("Flower Costume");
        headMap[46] = bytes32("Rockstar");
        headMap[47] = bytes32("Dryden");
        headMap[48] = bytes32("Trash's King");
        headMap[49] = bytes32("Tin Foil Hat");
        headMap[50] = bytes32("Umbrella");
        headMap[51] = bytes32("Archive Cap");
        headMap[52] = bytes32("Rug Legend");
        headMap[53] = bytes32("Compost God");
        headMap[54] = bytes32("Balaclava");
        headMap[55] = bytes32("Predator Costume");

        // Initialize mouth map
        mouthMap[0] = bytes32("Smiley");
        mouthMap[1] = bytes32("Duck Face");
        mouthMap[2] = bytes32("Vortex");
        mouthMap[3] = bytes32("Pornstache");
        mouthMap[4] = bytes32("Ron");
        mouthMap[5] = bytes32("Bandana");
        mouthMap[6] = bytes32("Kiss");
        mouthMap[7] = bytes32("Glossy Lips");
        mouthMap[8] = bytes32("Hogan");
        mouthMap[9] = bytes32("Buckteeth");
        mouthMap[10] = bytes32("Lumbersexual");
        mouthMap[11] = bytes32("Grrr");
        mouthMap[12] = bytes32("Toothbrush");
        mouthMap[13] = bytes32("Rotten");
        mouthMap[14] = bytes32("Zoidbug");
        mouthMap[15] = bytes32("Reptilian");
        mouthMap[16] = bytes32("Goth");
        mouthMap[17] = bytes32("Tooth Cap");
        mouthMap[18] = bytes32("Lemmy");
        mouthMap[19] = bytes32("Gold Grillz");
        mouthMap[20] = bytes32("Overjet");
        mouthMap[21] = bytes32("Duke In Vegas");
        mouthMap[22] = bytes32("Hannibal");
        mouthMap[23] = bytes32("Iced Out");
        mouthMap[24] = bytes32("Braces");

        // Initialize background map
        backgroundMap[0] = bytes32("blue");
        backgroundMap[1] = bytes32("green");
        backgroundMap[2] = bytes32("orange");
        backgroundMap[3] = bytes32("pink");
        backgroundMap[4] = bytes32("red");
        backgroundMap[5] = bytes32("yellow");

        // Initialize bug type map
        bugTypeMap[0] = bytes32("mantis");
        bugTypeMap[1] = bytes32("caterpillar");
        bugTypeMap[2] = bytes32("fly");
        bugTypeMap[3] = bytes32("mosquito");
        bugTypeMap[4] = bytes32("moth");
        bugTypeMap[5] = bytes32("snail");

    }

}