// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library CyborgTables {

    function getStyle(uint roll) external pure returns (string memory){

        string[] memory style = new string[](50);
        style[1] = "0Core";
        style[2] = "Acid panda";
        style[3] = "Beastie";
        style[4] = "Bitcrusher";
        style[5] = "Bloodsport";
        style[6] = "Cadavercore";
        style[7] = "Codefolk";
        style[8] = "Converter";
        style[9] = "Corpodrone";
        style[10] = "Cosmopunk";
        style[11] = "Cvit";
        style[12] = "Cybercrust";
        style[13] = "CyPop";
        style[14] = "Daemonista";
        style[15] = "Deathbloc";
        style[16] = "Doomtroop";
        style[17] = "Ghoul";
        style[18] = "Glitchmode";
        style[19] = "Goregrinder";
        style[20] = "Gutterscum";
        style[21] = "Hexcore";
        style[22] = "Hype street";
        style[23] = "Kill mode";
        style[24] = "Meta";
        style[25] = "Mimic";

        style[26] = "Minimal";
        style[27] = "Minotaur";
        style[28] = "Mobwave";
        style[29] = "Monsterwave";
        style[30] = "Murdercore";
        style[31] = "Necropop";
        style[32] = "Neurotripper";
        style[33] = "NuFlesh";
        style[34] = "NuGoth";
        style[35] = "NuPrep";
        style[36] = "Oceanwave";
        style[37] = "OG";
        style[38] = "Old-school cyberpunk";
        style[39] = "Orbital";
        style[40] = "Postlife";
        style[41] = "Pyrocore";
        style[42] = "Razormouth";
        style[43] = "Retro metal";
        style[44] = "Riot kid";
        style[45] = "Robomode";
        style[46] = "Roller bruiser";
        style[47] = "Technoir";
        style[48] = "Trad punk";
        style[49] = "Wallgoth";
        style[50] = "Waster";

        return style[roll];
    }

    function getFeature(uint roll) external pure returns (string memory){

        string[] memory feature = new string[](50);
        feature[1] = "Abundance of rings";
        feature[2] = "All monochrome";
        feature[3] = "Artificial skin";
        feature[4] = "Beastlike";
        feature[5] = "Broken nose";
        feature[6] = "Burn scars";
        feature[7] = "Complete hairless";
        feature[8] = "Cosmetic gills";
        feature[9] = "Covered in tattoos";
        feature[10] = "Customized voicebox";
        feature[11] = "Disheveled look";
        feature[12] = "Dollfaced";
        feature[13] = "Dueling scars";
        feature[14] = "Elaborate hairstyle";
        feature[15] = "Enhanced cheekbones";
        feature[16] = "Fluorescent veins";
        feature[17] = "Forehead display";
        feature[18] = "Giant RCD helmet rig";
        feature[19] = "Glitterskin";
        feature[20] = "Glowing respirator";
        feature[21] = "Golden grillz";
        feature[22] = "Headband";
        feature[23] = "Heavy on the makeup";
        feature[24] = "Holomorphed face";
        feature[25] = "Interesting perfume";

        feature[26] = "Lace trimmings";
        feature[27] = "Laser branded";
        feature[28] = "Lipless-just teeth";
        feature[29] = "Mirror eyes";
        feature[30] = "More plastic than skin";
        feature[31] = "Necrotic face";
        feature[32] = "Nonhuman ears";
        feature[33] = "Palms covered in notes";
        feature[34] = "Pattern overdose";
        feature[35] = "Plenty of piercings";
        feature[36] = "Radiant eyebrows";
        feature[37] = "Rainbow haircut";
        feature[38] = "Ritual scarifications";
        feature[39] = "Robotlike";
        feature[40] = "Shoulder pads";
        feature[41] = "Subdermal implants";
        feature[42] = "Tons of jewelery";
        feature[43] = "Traditional amulets";
        feature[44] = "Translucent skin";
        feature[45] = "Transparent wear";
        feature[46] = "Unkept hair";
        feature[47] = "Unnatural eyes";
        feature[48] = "UV-inked face";
        feature[49] = "VIP lookalike";
        feature[50] = "War paints";

        return feature[roll];
    }

    function getObsession(uint roll) external pure returns (string memory){

        string[] memory obsession = new string[](50);
        obsession[1] = "Adrenaline";
        obsession[2] = "AI Poetry";
        obsession[3] = "Ammonium Chloride Candy";
        obsession[4] = "Ancient Grimoires";
        obsession[5] = "Arachnids";
        obsession[6] = "Belts";
        obsession[7] = "Blades";
        obsession[8] = "Bones";
        obsession[9] = "Customized Cars";
        obsession[10] = "Dronespotting";
        obsession[11] = "Experimental Stimuli";
        obsession[12] = "Explosives";
        obsession[13] = "Extravagant Manicure";
        obsession[14] = "Gauze and Band-aids";
        obsession[15] = "Gin";
        obsession[16] = "Graffiti";
        obsession[17] = "Hand-Pressed Synthpresso";
        obsession[18] = "Handheld Games";
        obsession[19] = "Headphones";
        obsession[20] = "History Sims";
        obsession[21] = "Interactive Holo-ink";
        obsession[22] = "Journaling";
        obsession[23] = "Masks";
        obsession[24] = "Medieval Weaponry";
        obsession[25] = "Microbots";

        obsession[26] = "Mixing Stimulants";
        obsession[27] = "Model Mech Kits";
        obsession[28] = "Obsolete Tech";
        obsession[29] = "Porcelain figurines";
        obsession[30] = "Painted Shirts";
        obsession[31] = "Puppets";
        obsession[32] = "Records";
        obsession[33] = "Recursive Synthesizers";
        obsession[34] = "Shades";
        obsession[35] = "Slacklining";
        obsession[36] = "Sneakers";
        obsession[37] = "Stim Smokes";
        obsession[38] = "Style Hopping";
        obsession[39] = "Tarot";
        obsession[40] = "Taxidermy";
        obsession[41] = "Trendy Food";
        obsession[42] = "Urban Exploring";
        obsession[43] = "Vampires vs. Werewolves";
        obsession[44] = "Vintage Army Jackets";
        obsession[45] = "Vintage TV Shows";
        obsession[46] = "Virtuaflicks";
        obsession[47] = "Virtuapals";
        obsession[48] = "Voice Modulators";
        obsession[49] = "Watches";
        obsession[50] = "Wigs";

        return obsession[roll];
    }

    function getWants(uint roll) external pure returns (string memory){

        string[] memory wants = new string[](20);
        wants[1] = "Anarchy";
        wants[2] = "Burn It All Down";
        wants[3] = "Cash";
        wants[4] = "Drugs";
        wants[5] = "Enlightenment";
        wants[6] = "Fame";
        wants[7] = "Freedom";
        wants[8] = "Fun";
        wants[9] = "Justice";
        wants[10] = "Love";
        wants[11] = "Mayhem";
        wants[12] = "Power Over Others";
        wants[13] = "Revenge";
        wants[14] = "Safety for Loved Ones";
        wants[15] = "Save the World";
        wants[16] = "See Others Fail";
        wants[17] = "Self-Control";
        wants[18] = "Self-Actualization";
        wants[19] = "Success";
        wants[20] = "To Kill";

        return wants[roll];
    }

    function getQuirk(uint roll) external pure returns (string memory){

        string[] memory quirk = new string[](20);
        quirk[1] = "Chainsmoker";
        quirk[2] = "Chew on Hair";
        quirk[3] = "Compulsive Swearing";
        quirk[4] = "Constantly Watching Holos";
        quirk[5] = "Coughs";
        quirk[6] = "Fiddles with Jewelry";
        quirk[7] = "Flirty";
        quirk[8] = "Gestures a Lot";
        quirk[9] = "Giggles Inappropriately";
        quirk[10] = "Hat/Hood and Shades, Always";
        quirk[11] = "Itchy";
        quirk[12] = "Loudly Chews Gum";
        quirk[13] = "Must Tag Every Location";
        quirk[14] = "Never Looks Anyone in the Eye";
        quirk[15] = "Nosepicker";
        quirk[16] = "Rapid Blinking";
        quirk[17] = "Reeks of Lighter Fluid";
        quirk[18] = "Scratches Facial Scar";
        quirk[19] = "Twitchy";
        quirk[20] = "Wheezes";

        return quirk[roll];
    }

}