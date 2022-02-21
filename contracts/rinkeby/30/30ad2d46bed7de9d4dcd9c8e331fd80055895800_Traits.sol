// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Dungeon.sol";
import "./Base64.sol";

library Traits {
    
    function getTokenURI(Dungeon.RaidInventory memory _inventory, uint256 tokenId) external pure returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .empty { fill: grey; font-family: helvetica; font-size: 12px; } .full { fill: white; font-family: helvetica; font-size: 12px; } .base { fill: white; font-family: helvetica; font-size: 12px; } .two { fill: lime; font-family: helvetica; font-size: 12px; }.three { fill: darkblue; font-family: helvetica; font-size: 12px; } .four { fill: darkviolet; font-family: helvetica; font-size: 12px; } .five { fill: orangered; font-family: helvetica; font-size: 12px; } .six { fill: orange; font-family: helvetica; font-size: 12px; } </style>';
        parts[1] = '<rect width="100%" height="100%" fill="black" />';
        /*if(Raids.tier[tokenId] < 600){
            parts[1] = '<rect width="100%" height="100%" fill="black" />';
        } else if(Raids.tier[tokenId] < 800){
            parts[1] = '<rect width="100%" height="100%" fill="black" stroke="lime" stroke-width="10"/>';
        } else if(Raids.tier[tokenId] < 950){
            parts[1] = '<rect width="100%" height="100%" fill="black" stroke="darkblue" stroke-width="10"/>';
        } else if(Raids.tier[tokenId]  < 990){
            parts[1] = '<rect width="100%" height="100%" fill="black" stroke="darkviolet" stroke-width="10"/>';
        } else if(Raids.tier[tokenId] < 999){
            parts[1] = '<rect width="100%" height="100%" fill="black" stroke="orangered" stroke-width="10"/>';
        } else {
            parts[1] = '<rect width="100%" height="100%" fill="black" stroke="orange" stroke-width="10"/>';
        }*/
        parts[2] = '<line x1="75" y1="3" x2="75" y2="347" stroke="grey" /><line x1="275" y1="3" x2="275" y2="347" stroke="grey" /><line x1="3" y1="315" x2="347" y2="315" stroke="grey" />';
        parts[3] = '<text x="10" y="30" class="full">Shirt</text>';
        parts[4] = '<text x="10" y="60" class="empty">Pants</text>';
        parts[5] = '<text x="10" y="90" class="empty">Head</text>';
        parts[6] = '<text x="10" y="120" class="empty">Feet</text>';
        parts[7] = '<text x="10" y="150" class="empty">Chest</text>';
        parts[8] = '<text x="10" y="180" class="empty">Shoulders</text>';
        parts[9] = '<text x="10" y="210" class="empty">Ring</text>';
        parts[10] = '<text x="10" y="240" class="empty">Mainhand</text>';
        parts[11] = '<text x="10" y="270" class="empty">Offhand</text>';
        parts[12] = '<text x="10" y="300" class="empty">Artifact</text>';
        parts[13] = '<text x="10" y="335" class="empty">Overall</text>';
        parts[14] = '<text x="85" y="30" class="two">';
        parts[15] = _inventory.shirt.name;
        /*
        parts[16] = '</text><text x="285" y="30" class=_inventory.shirt.tier>';
        parts[17] = Strings.toString(_inventory.shirt.value);

        parts[18] = '</text><text x="85" y="60" class=_inventory.pants.tier>';
        parts[19] = _inventory.pants.name;
        parts[20] = '</text><text x="285" y="60" class=_inventory.pants.tier>';
        parts[21] = Strings.toString(_inventory.pants.value);

        parts[22] = '</text><text x="85" y="90" class=_inventory.head.tier">';
        parts[23] = _inventory.head.name;
        parts[24] = '</text><text x="285" y="90" class=_inventory.head.tier>';
        parts[25] = Strings.toString(_inventory.head.value);

        parts[26] = '</text><text x="85" y="120" class=_inventory.feet.tier>';
        parts[27] = _inventory.feet.name;
        parts[28] = '</text><text x="285" y="120" class=_inventory.feet.tier>';
        parts[29] = Strings.toString(_inventory.feet.value);

        parts[30] = '</text><text x="85" y="150" class=_inventory.chest.tier>';
        parts[31] = _inventory.chest.name;
        parts[32] = '</text><text x="285" y="150" class=_inventory.chest.tier>';
        parts[33] = Strings.toString(_inventory.chest.value);

        parts[34] = '</text><text x="85" y="180" class=_inventory.shoulders.tier>';
        parts[35] = _inventory.shoulders.name;
        parts[36] = '</text><text x="285" y="180" class=_inventory.shoulders.tier>';
        parts[37] = Strings.toString(_inventory.shoulders.value);

        parts[38] = '</text><text x="85" y="210" class=_inventory.ring.tier>';
        parts[39] = _inventory.ring.name;
        parts[40] = '</text><text x="285" y="210" class=_inventory.ring.tier>';
        parts[41] = Strings.toString(_inventory.ring.value);
    
        parts[42] = '</text><text x="85" y="240" class=_inventory.mainhand.tier>';
        parts[43] = _inventory.mainhand.name;
        parts[44] = '</text><text x="285" y="240" class=_inventory.mainhand.tier>';
        parts[45] = Strings.toString(_inventory.mainhand.value);

        parts[46] = '</text><text x="85" y="270" class=_inventory.offhand.tier>';
        parts[47] = _inventory.offhand.name;
        parts[48] = '</text><text x="285" y="270" class=_inventory.offhand.tier>';
        parts[49] = Strings.toString(_inventory.offhand.value);

        parts[50] = '</text><text x="85" y="300" class=_inventory.artifact.tier>';
        parts[51] = _inventory.artifact.name;
        parts[52] = '</text><text x="285" y="300" class=_inventory.artifact.tier>';
        parts[53] = Strings.toString(_inventory.artifact.value);

        parts[54] = '</text><text x="285" y="335" class=_inventory.artifact.tier>';
        parts[55] = Strings.toString(_inventory.pants.value);*/

        parts[16] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));/*
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        output = string(abi.encodePacked(output, parts[25], parts[26], parts[27], parts[28], parts[29], parts[30], parts[31], parts[32]));
        output = string(abi.encodePacked(output, parts[33], parts[34], parts[35], parts[36], parts[37], parts[38], parts[39], parts[40]));
        output = string(abi.encodePacked(output, parts[41], parts[42], parts[43], parts[44], parts[45], parts[46], parts[47], parts[48]));
        output = string(abi.encodePacked(output, parts[49], parts[50], parts[51], parts[52], parts[53], parts[54], parts[55], parts[56]));
*/
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bag #', toString(tokenId), '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}