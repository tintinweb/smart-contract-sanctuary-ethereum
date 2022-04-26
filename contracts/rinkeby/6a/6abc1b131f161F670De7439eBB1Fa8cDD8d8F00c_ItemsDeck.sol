// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract HeroesDeck {

    function getTraitsNames(uint256, uint256[6] calldata atts) public pure returns(string[6] memory names) {
        names[0] = level(atts[0]);
        names[1] = class(atts[1]);
        names[2] = rank(atts[2]);
        names[3] = rarity(atts[3]);
        names[4] = pet(atts[4]);
        names[5] = item(atts[5]);
    }

    function level(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 0) name = "None";
        if (id == 1) name = "I";
        if (id == 2) name = "II";
        if (id == 3) name = "III";
        if (id == 4) name = "IV";
        if (id == 5) name = "V";
        if (id == 6) name = "X"; 

        str = string(abi.encodePacked('{"trait_type": "Level", "value":"', name ,'"}'));
    }

    function class(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 0) name = "None";
        if (id == 1) name = "Warrior";
        if (id == 2) name = "Marksman";
        if (id == 3) name = "Assassin"; 
        if (id == 4) name = "Monk";
        if (id == 5) name = "Mage";
        if (id == 6) name = "Zombie";
        if (id == 7) name = "God";
        if (id == 8) name = "Oracle";

        str = string(abi.encodePacked('{"trait_type": "Class", "value":"', name ,'"}'));
    }

    function rank(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 0) name = "None";
        if (id == 1) name = "Novice";
        if (id == 2) name = "Beginner";
        if (id == 3) name = "Intermediate";
        if (id == 4) name = "Advanced";
        if (id == 5) name = "Expert";
        if (id == 6) name = "Master";

        str = string(abi.encodePacked('{"trait_type": "Rank", "value":"', name ,'"}'));
    }

    function rarity(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 0) name = "None";
        if (id == 1) name = "Common";
        if (id == 2) name = "Uncommon";
        if (id == 3) name = "Rare";
        if (id == 4) name = "Epic";
        if (id == 5) name = "Legendary";
        if (id == 6) name = "Mythic";

        str = string(abi.encodePacked('{"trait_type": "Rarity", "value":"', name ,'"}'));
    }

    function pet(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 0) name = "None";
        if (id == 1) name = "Fairy";
        if (id == 2) name = "Kitsune";
        if (id == 3) name = "Unicorn";
        if (id == 4) name = "Sphinx";
        if (id == 5) name = "Dragon";

        str = string(abi.encodePacked('{"trait_type": "Pet", "value":"', name ,'"}'));
    }

    function item(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 0) name = "None";
        if (id == 1)  name = "Dagger";
        if (id == 2)  name = "Sword";
        if (id == 3)  name = "Hammer";
        if (id == 4)  name = "Spear";
        if (id == 5)  name = "Mace";
        if (id == 6)  name = "Staff";
        if (id == 7)  name = "Force";
        if (id == 8)  name = "Implosion";
        if (id == 9)  name = "Explosion";
        if (id == 10) name = "Antimatter";
        if (id == 11) name = "Supernova";
        if (id == 12) name = "Ultimatum";
        if (id == 13) name = "Potion";
        if (id == 14) name = "Ether";
        if (id == 15) name = "Elixir";
        if (id == 16) name = "Nectar";
        if (id == 17) name = "Ambrosia";
        if (id == 18) name = "Cornucopia";

        str = string(abi.encodePacked('{"trait_type": "Item", "value":"', name ,'"}'));
    }
}

contract ItemsDeck {

    function getTraitsNames(uint256 id, uint256[6] calldata atts) public pure returns(string[6] memory names) {
        if (id > 10000) return getBossTraitsNames(id, atts);
        
        names[0] = level(atts[0]);
        names[1] = kind(id, atts[1]);
        names[2] = material(id, atts[2]);
        names[3] = rarity(atts[3]);
        names[4] = quality(atts[4]);
        names[5] = element(id, atts[5]);
    }

    function getBossTraitsNames(uint256 id, uint256[6] calldata atts) internal pure returns(string[6] memory names) {
        names[0] = level(atts[0]);
        names[1] = kind(id, atts[1]);
        names[2] = rarity(atts[2]);
        names[3] = quality(atts[3]);
        names[5] = element(id, atts[5]);
    }
    
    function level(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 1) name = "I";
        if (id == 2) name = "II";
        if (id == 3) name = "III";
        if (id == 4) name = "IV";
        if (id == 5) name = "V";
        if (id == 6) name = "X"; 

        str = string(abi.encodePacked('{"trait_type": "Level", "value":"', name ,'"}'));
    }

    function kind(uint256 tokenId, uint256 id) public pure returns (string memory str) {
        string memory name;
        uint256 class = tokenId % 4;

        if (tokenId > 10000) { 
            if (id == 11) name = "Dogemon's Tail";
            if (id == 12) name = "Lunar Rings";
            if (id == 13) name = "Lunar Rings";
            if (id == 14) name = "Axie Wings";
            if (id == 15) name = "Circulonimbus";
            if (id == 16) name = "Vitalik's Horn";
            if (id == 17) name = "Sand Scale";
            if (id == 18) name = "Lunar Crystal";
            if (id == 19) name = "Polybeast's Shards";
        }

        if (class == 0) {
            if (id == 1) name = "Dagger";
            if (id == 2) name = "Sword";
            if (id == 3) name = "Hammer";
            if (id == 4) name = "Spear";
            if (id == 5) name = "Mace";
            if (id == 6) name = "Staff"; 
        }

        if (class == 1) {
            if (id == 1) name = "Leather";
            if (id == 2) name = "Split Mail";
            if (id == 3) name = "Chain Mail";
            if (id == 4) name = "Scale Mail";
            if (id == 5) name = "Half Plate";
            if (id == 6) name = "Full Plate"; 
        }

        if (class == 2) {
            if (id == 1) name = "Force";
            if (id == 2) name = "Implosion";
            if (id == 3) name = "Explosion";
            if (id == 4) name = "Antimatter";
            if (id == 5) name = "Supernova";
            if (id == 6) name = "Ultimatum"; 
        }

        if (class == 3) {
            if (id == 1) name = "Potion";
            if (id == 2) name = "Ether";
            if (id == 3) name = "Elixir";
            if (id == 4) name = "Nectar";
            if (id == 5) name = "Ambrosia";
            if (id == 6) name = "Cornucopia"; 
        }

        str = string(abi.encodePacked('{"trait_type": "Type", "value":"', name ,'"}'));
    }

    function material(uint256 tokenId, uint256 id) public pure returns(string memory str) {
        string memory name;
        string memory trait;

        uint256 class = tokenId % 4;

        if (class < 2) {
            if (id == 1) name = "Wood";
            if (id == 2) name = "Iron";
            if (id == 3) name = "Bronze";
            if (id == 4) name = "Silver";
            if (id == 5) name = "Gold";
            if (id == 6) name = "Mythril";

            trait = "Material";
        }

        if (class == 2) {
            if (id == 1) name = "Kinetic";
            if (id == 2) name = "Potential";
            if (id == 3) name = "Electrical";
            if (id == 4) name = "Nuclear";
            if (id == 5) name = "Gravitational";
            if (id == 6) name = "Cosmic"; 

            trait = "Energy";
        }

        if (class == 3) {
            if (id == 1) name = "New";
            if (id == 2) name = "Annum";
            if (id == 3) name = "Decade";
            if (id == 4) name = "Century";
            if (id == 5) name = "Millennium";
            if (id == 6) name = "Beginning of Time"; 

            trait = "Vintage";
        }

        str = string(abi.encodePacked('{"trait_type": "',trait,'", "value":"', name ,'"}'));
    }

    function rarity(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 1) name = "Common";
        if (id == 2) name = "Uncommon";
        if (id == 3) name = "Rare";
        if (id == 4) name = "Epic";
        if (id == 5) name = "Legendary";
        if (id == 6) name = "Mythic";

        str = string(abi.encodePacked('{"trait_type": "Rarity", "value":"', name ,'"}'));
    }

    function quality(uint256 id) public pure returns (string memory str) {
        string memory name;
        if (id == 1) name = "Normal";
        if (id == 2) name = "Good";
        if (id == 3) name = "Very Good";
        if (id == 4) name = "Fine";
        if (id == 5) name = "Superfine";
        if (id == 6) name = "Excellent";

        str = string(abi.encodePacked('{"trait_type": "Quality", "value":"', name ,'"}'));
    }

    function element(uint256 tokenId, uint256 id) public pure returns (string memory str) {
        string memory name;
        string memory trait;

        uint256 class = tokenId % 4;
        
        if (tokenId > 10000 || class < 3) {
            if (id == 0) name = "None";
            if (id == 1) name = "Water";
            if (id == 2) name = "Fire";
            if (id == 3) name = "Air";
            if (id == 4) name = "Lightning";
            if (id == 5) name = "Earth";

            trait = "Element";
        }

        if (class == 3) {
            if (id == 1) name = "None";
            if (id == 2) name = "Weak";
            if (id == 3) name = "Mild";
            if (id == 4) name = "Regular";
            if (id == 5) name = "Strong";
            if (id == 6) name = "Potent"; 

            trait = "Potency";
        }

        str = string(abi.encodePacked('{"trait_type": "', trait ,'", "value":"', name ,'"}'));
    }
}