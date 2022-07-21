// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Inventory.sol";
import "./Base64.sol";

library Traits {

    function getTokenURI(Inventory.FallenInventory memory _inventory, uint256 soulScore, uint256 tokenId) external pure returns (string memory) {
        string[117] memory parts;
        string memory cast;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .e0 { fill: #52525b; font-family: "PT Mono", monospace; font-size: 12px; } .e1 { fill: #fafafa; font-family: "PT Mono", monospace; font-size: 12px; } .c1 { fill: #a1a1aa; font-family: "PT Mono"; font-size: 12px; } .c2 { fill: #fafafa; font-family: "PT Mono", monospace; font-size: 12px; } .c3 { fill: #4ade80; font-family: "PT Mono", monospace; font-size: 12px; } .c4 { fill: #16a34a; font-family: "PT Mono", monospace; font-size: 12px; } .c5 { fill: #60a5fa; font-family: "PT Mono", monospace; font-size: 12px; } .c6 { fill: #2563eb; font-family: "PT Mono", monospace; font-size: 12px; } .c7 { fill: #a78bfa; font-family: "PT Mono", monospace; font-size: 12px; } .c8 { fill: #7c3aed; font-family: "PT Mono", monospace; font-size: 12px; } .c9 { fill: #f97316; font-family: "PT Mono", monospace; font-size: 12px; }</style>';
        if(_inventory.base == 1){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#a1a1aa" stroke-width="5px"/>';
            cast = "Human";
        }  else if(_inventory.base == 2 ){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#4ade80" stroke-width="5px"/>';
            cast = "Dwarf";
        } else if(_inventory.base == 3){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#16a34a" stroke-width="5px"/>';
            cast = "Elf";
        } else if(_inventory.base == 5){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#60a5fa" stroke-width="5px"/>';
            cast = "Orc";
        } else if(_inventory.base == 8){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#2563eb" stroke-width="5px"/>';
            cast = "Troll";
        } else if(_inventory.base == 12){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#a78bfa" stroke-width="5px"/>';
            cast = "Demon";
        } else {
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#f97316" stroke-width="5px"/>';
            cast = "Undead";
        }
        parts[2] = '<line x1="85" y1="2.5" x2="85" y2="347.5" stroke="#3f3f46" stroke-width="2"/><line x1="275" y1="2.5" x2="275" y2="347.5" stroke="#3f3f46" stroke-width="2"/><line x1="2.5" y1="315" x2="347.5" y2="315" stroke="#3f3f46" stroke-width="2"/>';
        
        parts[3] = '<text x="10" y="23" class="e';
        parts[4] = Strings.toString(_inventory.head.status);
        parts[5] = '">Head</text>';
        
        parts[6] = '<text x="10" y="54" class="e';
        parts[7] = Strings.toString(_inventory.shoulders.status);
        parts[8] = '">Shoulders</text>';
        
        parts[9] = '<text x="10" y="85" class="e';
        parts[10] = Strings.toString(_inventory.chest.status);
        parts[11] = '">Chest</text>';
        
        parts[12] = '<text x="10" y="116" class="e';
        parts[13] = Strings.toString(_inventory.shirt.status);
        parts[14] = '">Shirt</text>';
        
        parts[15] = '<text x="10" y="147" class="e';
        parts[16] = Strings.toString(_inventory.pants.status);
        parts[17] = '">Pants</text>';

        parts[18] = '<text x="10" y="178" class="e';
        parts[19] = Strings.toString(_inventory.feet.status);
        parts[20] = '">Feet</text>';
        
        parts[21] = '<text x="10" y="209" class="e';
        parts[22] = Strings.toString(_inventory.ring.status);
        parts[23] = '">Ring</text>';

        parts[24] = '<text x="10" y="240" class="e';
        parts[25] = Strings.toString(_inventory.artifact.status);
        parts[26] = '">Artifact</text>';

        parts[27] = '<text x="10" y="271" class="e';
        parts[28] = Strings.toString(_inventory.mainhand.status);
        parts[29] = '">Mainhand</text>';

        parts[30] = '<text x="10" y="302" class="e';
        parts[31] = Strings.toString(_inventory.offhand.status);
        parts[32] = '">Offhand</text>';

        parts[33] = '<text x="10" y="335" class="e1">Overall</text>';
        
        parts[34] = '<text x="95" y="23" class="c';
        parts[35] = Strings.toString(_inventory.head.tier);
        parts[36] = '">';
        parts[37] = _inventory.head.name;
        parts[38] = '</text><text x="285" y="23" class="c';
        parts[39] = Strings.toString(_inventory.head.tier);
        parts[40] = '">';
        if(_inventory.head.soulScore != 0) { parts[41] = Strings.toString(_inventory.head.soulScore); }
        else { parts[41] = ""; }
        
        parts[42] = '</text><text x="95" y="54" class="c';
        parts[43] = Strings.toString(_inventory.shoulders.tier);
        parts[44] = '">';
        parts[45] = _inventory.shoulders.name;
        parts[46] = '</text><text x="285" y="54" class="c';
        parts[47] = Strings.toString(_inventory.shoulders.tier);
        parts[48] = '">';
        if(_inventory.shoulders.soulScore != 0) { parts[49] = Strings.toString(_inventory.shoulders.soulScore); }
        else { parts[49] = ""; }

        parts[50] = '</text><text x="95" y="85" class="c';
        parts[51] = Strings.toString(_inventory.chest.tier);
        parts[52] = '">';
        parts[53] = _inventory.chest.name;
        parts[54] = '</text><text x="285" y="85" class="c';
        parts[55] = Strings.toString(_inventory.chest.tier);
        parts[56] = '">';
        if(_inventory.chest.soulScore != 0) { parts[57] = Strings.toString(_inventory.chest.soulScore); }
        else { parts[57] = ""; }

        parts[58] = '</text><text x="95" y="116" class="c';
        parts[59] = Strings.toString(_inventory.shirt.tier);
        parts[60] = '">';
        parts[61] = _inventory.shirt.name;
        parts[62] = '</text><text x="285" y="116" class="c';
        parts[63] = Strings.toString(_inventory.shirt.tier);
        parts[64] = '">';
        if(_inventory.shirt.soulScore != 0) { parts[65] = Strings.toString(_inventory.shirt.soulScore); }
        else { parts[65] = ""; }

        parts[66] = '</text><text x="95" y="147" class="c';
        parts[67] = Strings.toString(_inventory.pants.tier);
        parts[68] = '">';
        parts[69] = _inventory.pants.name;
        parts[70] = '</text><text x="285" y="147" class="c';
        parts[71] = Strings.toString(_inventory.pants.tier);
        parts[72] = '">';
        if(_inventory.pants.soulScore != 0) { parts[73] = Strings.toString(_inventory.pants.soulScore); }
        else { parts[73] = ""; }

        parts[74] = '</text><text x="95" y="178" class="c';
        parts[75] = Strings.toString(_inventory.feet.tier);
        parts[76] = '">';
        parts[77] = _inventory.feet.name;
        parts[78] = '</text><text x="285" y="178" class="c';
        parts[79] = Strings.toString(_inventory.feet.tier);
        parts[80] = '">';
        if(_inventory.feet.soulScore != 0) { parts[81] = Strings.toString(_inventory.feet.soulScore); }
        else { parts[81] = ""; }

        parts[82] = '</text><text x="95" y="209" class="c';
        parts[83] = Strings.toString(_inventory.ring.tier);
        parts[84] = '">';
        parts[85] = _inventory.ring.name;
        parts[86] = '</text><text x="285" y="209" class="c';
        parts[87] = Strings.toString(_inventory.ring.tier);
        parts[88] = '">';
        if(_inventory.ring.soulScore != 0) { parts[89] = Strings.toString(_inventory.ring.soulScore); }
        else { parts[89] = ""; }
    
        parts[90] = '</text><text x="95" y="240" class="c';
        parts[91] = Strings.toString(_inventory.artifact.tier);
        parts[92] = '">';
        parts[93] = _inventory.artifact.name;
        parts[94] = '</text><text x="285" y="240" class="c';
        parts[95] = Strings.toString(_inventory.artifact.tier);
        parts[96] = '">';
        if(_inventory.artifact.soulScore != 0) { parts[97] = Strings.toString(_inventory.artifact.soulScore); }
        else { parts[97] = ""; }

        parts[98] = '</text><text x="95" y="271" class="c';
        parts[99] = Strings.toString(_inventory.mainhand.tier);
        parts[100] = '">';
        parts[101] = _inventory.mainhand.name;
        parts[102] = '</text><text x="285" y="271" class="c';
        parts[103] = Strings.toString(_inventory.mainhand.tier);
        parts[104] = '">';
        if(_inventory.mainhand.soulScore != 0) { parts[105] = Strings.toString(_inventory.mainhand.soulScore); }
        else { parts[105] = ""; }

        parts[106] = '</text><text x="95" y="302" class="c';
        parts[107] = Strings.toString(_inventory.offhand.tier);
        parts[108] = '">';
        parts[109] = _inventory.offhand.name;
        parts[110] = '</text><text x="285" y="302" class="c';
        parts[111] = Strings.toString(_inventory.offhand.tier);
        parts[112] = '">';
        if(_inventory.offhand.soulScore != 0) { parts[113] = Strings.toString(_inventory.offhand.soulScore); }
        else { parts[113] = ""; }
        
        if(soulScore < 10){ parts[114] = '</text><text x="285" y="335" class="c1">'; }
        else if(soulScore < 25){ parts[114] = '</text><text x="285" y="335" class="c2">'; }
        else if(soulScore < 50){ parts[114] = '</text><text x="285" y="335" class="c3">'; }
        else if(soulScore < 100){ parts[114] = '</text><text x="285" y="335" class="c4">'; }
        else if(soulScore < 200){ parts[114] = '</text><text x="285" y="335" class="c5">'; }
        else if(soulScore < 500){ parts[114] = '</text><text x="285" y="335" class="c6">'; }
        else{ parts[114] = '</text><text x="285" y="335" class="c7">'; }
        parts[115] = Strings.toString(soulScore);

        parts[116] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        output = string(abi.encodePacked(output, parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23], parts[24]));
        output = string(abi.encodePacked(output, parts[25], parts[26], parts[27], parts[28], parts[29], parts[30], parts[31], parts[32]));
        output = string(abi.encodePacked(output, parts[33], parts[34], parts[35], parts[36], parts[37], parts[38], parts[39], parts[40]));
        output = string(abi.encodePacked(output, parts[41], parts[42], parts[43], parts[44], parts[45], parts[46], parts[47], parts[48]));
        output = string(abi.encodePacked(output, parts[49], parts[50], parts[51], parts[52], parts[53], parts[54], parts[55], parts[56]));
        output = string(abi.encodePacked(output, parts[57], parts[58], parts[59], parts[60], parts[61], parts[62], parts[63], parts[64]));
        output = string(abi.encodePacked(output, parts[65], parts[66], parts[67], parts[68], parts[69], parts[70], parts[71], parts[72]));
        output = string(abi.encodePacked(output, parts[73], parts[74], parts[75], parts[76], parts[77], parts[78], parts[79], parts[80]));
        output = string(abi.encodePacked(output, parts[81], parts[82], parts[83], parts[84], parts[85], parts[86], parts[87], parts[88]));
        output = string(abi.encodePacked(output, parts[89], parts[90], parts[91], parts[92], parts[93], parts[94], parts[95], parts[96]));
        output = string(abi.encodePacked(output, parts[97], parts[98], parts[99], parts[100], parts[101], parts[102], parts[103], parts[104]));
        output = string(abi.encodePacked(output, parts[105], parts[106], parts[107], parts[108], parts[109], parts[110], parts[111], parts[112]));
        output = string(abi.encodePacked(output, parts[113], parts[114], parts[115], parts[116]));

        string memory json = string(abi.encodePacked('{"name": "Fallen #', toString(tokenId), '", "description": "Fallen is a fully onchain game.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","attributes": [{"trait_type": "Shirt", "value": "', _inventory.shirt.name, '"},{"trait_type": "Pants", "value": "', _inventory.pants.name, '"},{"trait_type": "Head", "value": "', _inventory.head.name, '"},{"trait_type": "Feet", "value": "', _inventory.feet.name, '"},{"trait_type": "Chest", "value": "', _inventory.chest.name, '"},{"trait_type": "Shoulders", "value": "', _inventory.shoulders.name));
        json = Base64.encode(bytes(string(abi.encodePacked(json, '"},{"trait_type": "Ring", "value": "', _inventory.ring.name, '"},{"trait_type": "Mainhand", "value": "', _inventory.mainhand.name, '"},{"trait_type": "Offhand", "value": "', _inventory.offhand.name, '"},{"trait_type": "Artifact", "value": "', _inventory.artifact.name, '"},{"trait_type": "Cast", "value": "', cast, '"},{"trait_type": "Soul Score", "value": "', Strings.toString(soulScore), '"}]}'))));
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