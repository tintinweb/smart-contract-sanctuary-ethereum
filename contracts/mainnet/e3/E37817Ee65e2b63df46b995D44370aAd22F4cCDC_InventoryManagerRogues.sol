// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract InventoryManagerRogues {

    address impl_;
    address public manager;

    enum Part { body, face, armor, mainhand, offhand, boot, pant, shirt, hair }

    mapping(uint8 => address) public bodies;
    mapping(uint8 => address) public faces;
    mapping(uint8 => address) public boots;
    mapping(uint8 => address) public pants;
    mapping(uint8 => address) public shirts;
    mapping(uint8 => address) public hairs;
    mapping(uint8 => address) public armors;
    mapping(uint8 => address) public mainhands;
    mapping(uint8 => address) public offhands;

    string public constant header = '<svg id="orc" width="100%" height="100%" version="1.1" viewBox="0 0 60 60" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public constant footer = '<style>#orc{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>';

    function getSVG(bytes22 details_) public view returns(string memory) {
        return string(abi.encodePacked(
            header,
            getSVGLower(details_),
            getSVGUpper(details_),
            footer ));
    }

    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory) {
        return _buildRogueURI(_getUpper(id_), getSVG(details_), getAttributes(details_, level_, modF_, skillCredits_));
    }

    function _buildRogueURI(bytes memory upper, string memory svg, string memory attributes) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    BBase64.encode(
                        bytes(
                            abi.encodePacked(
                                upper,
                                BBase64.encode(bytes(svg)),
                                '",',
                                attributes,
                                '}'
                            )
                        )
                    )
                )
            );
    }


    function _getUpper(uint256 id_) internal pure returns (bytes memory) {
        return abi.encodePacked('{"name":"Rogue #',toString(id_),'", "description":"EtherOrcs Allies is a collection of 12,000 100% on-chain warriors that aid Genesis Orcs in their conquest of Valkala. Four classes of Allies (Shamans, Tanks, Mages, and Rogues) each produce their own unique consumables as their entry point to the broader EtherOrcs game economy. Each Ally can participate in all aspects of gameplay within the ecosystem and will strengthen the Horde and solidify its place as champions in the on-chain metaverse.", "image": "',
                                'data:image/svg+xml;base64,');
    } 
    
    /*///////////////////////////////////////////////////////////////
                    INVENTORY MANAGEMENT
    //////////////////////////////////////////////////////////////*/


    function setBodies(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            bodies[ids[index]] = source; 
        }
    }

    function setFaces(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            faces[ids[index]] = source; 
        }
    }

    function setBoots(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            boots[ids[index]] = source; 
        }
    }


    function setPants(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            pants[ids[index]] = source; 
        }
    }


    function setShirts(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            shirts[ids[index]] = source; 
        }
    }


    function setHairs(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            hairs[ids[index]] = source; 
        }
    }

    function setArmors(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            armors[ids[index]] = source; 
        }
    }

    function setMainhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            mainhands[ids[index]] = source; 
        }
    }

    function setOffhands(uint8[] calldata ids, address source) external {
        require(msg.sender == manager, "not manager");

        for (uint256 index = 0; index < ids.length; index++) {
            offhands[ids[index]] = source; 
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _rogueLower(bytes22 details) public pure returns(uint8 body_, uint8 shirt_, uint8 boot_, uint8 pant_) {
        body_  = uint8(bytes1(details));
        shirt_ = uint8(bytes1(details << 32));
        boot_  = uint8(bytes1(details << 16));
        pant_  = uint8(bytes1(details << 24));
    }

    function _rogueUpper(bytes22 details) public pure returns(uint8 face_, uint8 hair_, uint8 armor_, uint8 mainhand_, uint8 offhand_) {
        face_     = uint8(bytes1(details << 8));
        hair_     = uint8(bytes1(details << 40));
        armor_    = uint8(bytes1(details << 48));
        mainhand_ = uint8(bytes1(details << 56));
        offhand_  = uint8(bytes1(details << 64));
    }

    function getSVGLower(bytes22 details_) internal view returns(string memory) {
        (uint8 body_, uint8 shirt_, uint8 boot_, uint8 pant_) = _rogueLower(details_);

        return string(abi.encodePacked(
            get(Part.body,  body_), 
            get(Part.shirt, shirt_),
            get(Part.boot,  boot_),
            get(Part.pant,  pant_)
            ));
    }

    function getSVGUpper(bytes22 details_) internal view returns(string memory) {
        (uint8 face_, uint8 hair_, uint8 armor_, uint8 mainhand_, uint8 offhand_) = _rogueUpper(details_);

        return string(abi.encodePacked(
            get(Part.armor, armor_),
            get(Part.face, face_), 
            get(Part.hair,    hair_),
            get(Part.offhand, offhand_),
            get(Part.mainhand, mainhand_) 
            ));
    }
    
    function call(address source, bytes memory sig) internal view returns (string memory svg) {
        (bool succ, bytes memory ret)  = source.staticcall(sig);
        require(succ, "failed to get data");
        svg = abi.decode(ret, (string));
    }

    function get(Part part, uint8 id) internal view returns (string memory data_) {
        address source = 
            part == Part.body     ? bodies[id]    :
            part == Part.face     ? faces[id]     :
            part == Part.boot     ? boots[id]     :
            part == Part.pant     ? pants[id]     :
            part == Part.shirt    ? shirts[id]    :
            part == Part.hair     ? hairs[id]     :
            part == Part.armor    ? armors[id]    :
            part == Part.mainhand ? mainhands[id] : offhands[id];

        data_ = wrapTag(call(source, getData(part, id)));
    }
    
    function wrapTag(string memory uri) internal pure returns (string memory) {
        return string(abi.encodePacked('<image x="0" y="0" width="60" height="60" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,', uri, '"/>'));
    }

    function getData(Part part, uint8 id) internal pure returns (bytes memory data) {
        string memory s = string(abi.encodePacked(
            part == Part.body     ? "body"     :
            part == Part.face     ? "face"     :
            part == Part.boot     ? "boot"     :
            part == Part.pant     ? "pants"     :
            part == Part.shirt    ? "shirt"    :
            part == Part.hair     ? "hair"     :
            part == Part.armor    ? "armor"    :
            part == Part.mainhand ? "mainhand" : "offhand",
            toString(id),
            "()"
        ));
        
        return abi.encodeWithSignature(s, "");
    }

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

    function getAttributes(bytes22 details_, uint256 level_, uint256 modF_, uint256 sc_) internal pure returns (string memory) {
       return string(abi.encodePacked(_getLowerAtt(details_),_getUpperAtt(details_), _getBottomAtt(level_, sc_, modF_)));
    }

    function _getLowerAtt(bytes22 details_) internal pure returns (string memory) {
        (uint8 body_, , , ) = _rogueLower(details_);
       return string(abi.encodePacked(
           '"attributes": [',
            getBodyAttributes(body_),   ','));
    }

    function _getUpperAtt(bytes22 details_) internal pure returns (string memory) {
        (, , uint8 armor_, uint8 mainhand_, uint8 offhand_) = _rogueUpper(details_);
       return string(abi.encodePacked(
            getArmorAttributes(armor_),      ',',
            getMainhandAttributes(mainhand_), ',',
            getOffhandAttributes(offhand_)));
    }

    function _getBottomAtt(uint256 level_, uint256 sc_, uint256 modF_) internal pure returns (string memory) {
        return string(abi.encodePacked(',{"trait_type": "level", "value":', toString(level_),
            '},{"trait_type": "Type", "value":"Rogue"},{"trait_type": "skillCredits", "value":', toString(sc_),'},{"display_type": "boost_number","trait_type": "Runecraft", "value":', 
            toString(modF_),'}]'));
    }

    function getBodyAttributes(uint256 body_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Body","value":"',getBodyName(body_),'"}'));
    }

    function getArmorAttributes(uint256 armor_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Armor","value":"',getArmorName(armor_),'"},{"display_type":"number","trait_type":"ArmorTier","value":',toString(getTier(uint8(armor_))),'}'));
    }

    function getMainhandAttributes(uint256 mainhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Mainhand","value":"',getMainhandName(mainhand_),'"},{"display_type":"number","trait_type":"MainhandTier","value":',toString(getTier(uint8(mainhand_))),'}'));
    }

    function getOffhandAttributes(uint256 offhand_) internal pure returns(string memory) {
        return string(abi.encodePacked('{"trait_type":"Offhand","value":"',getOffhandName(offhand_),'"},{"display_type":"number","trait_type":"OffhandTier","value":',toString(getTier(uint8(offhand_))),'}'));
    }

    function getTier(uint8 item) internal pure returns (uint8 tier) {
        if (item <= 6) return 0;
        if (item <= 9) return 1;
        if (item <= 14) return 2;
        if (item <= 20) return 3;
        if (item <= 26) return 4;
        if (item <= 31) return 5;
        if (item <= 35) return 6;
        return 7;
    } 

    function getArmorName(uint256 id) public pure returns (string memory) {
        if (id == 0)  return "None";
        if (id == 1)  return "Leather Bracers +2";
        if (id == 2)  return "Leather Vambraces +2";
        if (id == 3)  return "Leather Gauntlets +2";
        if (id == 4)  return "Bronze Bracers +2";
        if (id == 5)  return "Elven Gauntlets +2";
        if (id == 6)  return "Lucky Gauntlets +3";
        if (id == 7)  return "Wanderers Gauntlets +3";
        if (id == 8)  return "Stealth Vambraces +3";
        if (id == 9)  return "Phantom Vambraces +3";
        if (id == 10)  return "Elders Gauntlets +3";
        if (id == 11)  return "Turtle Shell Vambraces +3";
        if (id == 12)  return "Golden Bracers +3";
        if (id == 13)  return "Last Gambit +3";
        if (id == 14)  return "Royal Vambraces +3";
        if (id == 15)  return "Hard Leather Vambraces +3";
        if (id == 16)  return "Thieves Spaulers +4";
        if (id == 17)  return "Spaulders of Unholy Fire +4";
        if (id == 18)  return "Armor of Remorse +4";
        if (id == 19)  return "Outlaws Protection +4";
        if (id == 20)  return "Snakes Carapace +4";
        if (id == 21)  return "Mantle of Malice +4";
        if (id == 22)  return "Assassins Cape +5";
        if (id == 23)  return "Cape of the Elders +5";
        if (id == 24)  return "Nightstalker Cape +5";
        if (id == 25)  return "Harbinger Cape +5";
        if (id == 26)  return "Shadowskin Cape +5";
        if (id == 27)  return "Serpent Cape +5";
        if (id == 28)  return "Cape of Thieves +5";
        if (id == 29)  return "Wraith Cloak +6";
        if (id == 30)  return "Gilded Shadow Cloak +6";
        if (id == 31)  return "Cloak of Undying +6";
        if (id == 32)  return "Enchanted Duelists Cloak +6";
        if (id == 33)  return "Oathbringer +6";
        if (id == 34)  return "Dawnbringer +6";
        if (id == 35)  return "Frost Cloak +6";
    }

    function getMainhandName(uint256 id) public pure returns (string memory) {
        if (id == 0)  return "None";
        if (id == 1)  return "Standard Blade +2";
        if (id == 2)  return "Soldier Sword +2";
        if (id == 3)  return "Curved Machete +2";
        if (id == 4)  return "Curved Blade +2";
        if (id == 5)  return "Blunt Sword +2";
        if (id == 6)  return "Sawtooth +3";
        if (id == 7)  return "Bladed Knuckles +3";
        if (id == 8)  return "Sharpened Sword +3";
        if (id == 9)  return "Butterfly Sword +3";
        if (id == 10)  return "Sai +3";
        if (id == 11)  return "Serrated Blade +3";
        if (id == 12)  return "Iron Claw +3";
        if (id == 13)  return "Whipper +3";
        if (id == 14)  return "Lightning Stunner +3";
        if (id == 15)  return "Mithril Cutter +3";
        if (id == 16)  return "Elf Flail +4";
        if (id == 17)  return "Shinobi Staff +4";
        if (id == 18)  return "Claw +4";
        if (id == 19)  return "Kujang +4";
        if (id == 20)  return "Miao Dao +4";
        if (id == 21)  return "Shinken +4";
        if (id == 22)  return "Double Bladed Reaper +5";
        if (id == 23)  return "Pirate Cutlass +5";
        if (id == 24)  return "Moon Blade +5";
        if (id == 25)  return "Laito +5";
        if (id == 26)  return "Flame Ash +5";
        if (id == 27)  return "Razer +5";
        if (id == 28)  return "Bloody Bokken +5";
        if (id == 29)  return "Fu Tao of Rina +6";
        if (id == 30)  return "Shotel of Amara +6";
        if (id == 31)  return "Kukri of Elora +6";
        if (id == 32)  return "Stiletto of Zestari +6";
        if (id == 33)  return "Blade of Iriel +6";
        if (id == 34)  return "Icebrink of Ilyana +6";
        if (id == 35)  return "Scythe of Andela +6";
    }

    function getOffhandName(uint256 id) public pure returns (string memory) {
        if (id == 0)  return "None";
        if (id == 1)  return "Iron Axe +2";
        if (id == 2)  return "Iron Grace +2";
        if (id == 3)  return "Broken Straight Sword +2";
        if (id == 4)  return "Broken Long Sword +2";
        if (id == 5)  return "Iron Chopper +2";
        if (id == 6)  return "Twin Tails +3";
        if (id == 7)  return "Ravager +3";
        if (id == 8)  return "Bone Short Sword +3";
        if (id == 9)  return "Coarse Ravager +3";
        if (id == 10)  return "Wide Axe +3";
        if (id == 11)  return "Spiked Flail +3";
        if (id == 12)  return "War Flail +3";
        if (id == 13)  return "Murakumo +3";
        if (id == 14)  return "Swordbreaker +3";
        if (id == 15)  return "Soldier Sword +3";
        if (id == 16)  return "Elders Blade +4";
        if (id == 17)  return "Flame Ash +4";
        if (id == 18)  return "Elf Bow +4";
        if (id == 19)  return "Double Sided Death +4";
        if (id == 20)  return "Elf Sai +4";
        if (id == 21)  return "Haladie +4";
        if (id == 22)  return "Shuriken of Fate +5";
        if (id == 23)  return "Broad Blades +5";
        if (id == 24)  return "Bloodquench +5";
        if (id == 25)  return "Assassins Blade +5";
        if (id == 26)  return "Coil of Redemption +5";
        if (id == 27)  return "Divine Blade +5";
        if (id == 28)  return "Bone Sword +5";
        if (id == 29)  return "Death Blade of Elyon +6";
        if (id == 30)  return "Shotel of Kali +6";
        if (id == 31)  return "Sharkbone of Tsarra +6";
        if (id == 32)  return "Soulreaper of Lyrei +6";
        if (id == 33)  return "God Bow of Aire +6";
        if (id == 34)  return "Swiftblade of Rania +6";
        if (id == 35)  return "Great Haladie of Kasula +6";
    }

    function getBodyName(uint256 id) public pure returns (string memory) {
        if (id == 1) return "Body 1";
        if (id == 2) return "Body 2";
    }
}

/// @title BBase64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in BBase64
/// @notice NOT BUILT BY ETHERORCS TEAM. Thanks Bretch Devos!
library BBase64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}