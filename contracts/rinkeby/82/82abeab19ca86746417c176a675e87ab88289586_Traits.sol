// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Inventory.sol";
import "./Base64.sol";

library Traits {

    function getTokenURI(Inventory.FallenInventory memory _inventory, uint256 soulScore, uint256 tokenId) external pure returns (string memory) {
        string[122] memory parts;
        string memory race;
        string memory class;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style> .e0 { fill: #52525b; font-family: "PT Mono", monospace; font-size: 12px; } .e1 { fill: #fafafa; font-family: "PT Mono", monospace; font-size: 12px; } .c1 { fill: #a1a1aa; font-family: "PT Mono"; font-size: 12px; } .c2 { fill: #fafafa; font-family: "PT Mono", monospace; font-size: 12px; } .c3 { fill: #4ade80; font-family: "PT Mono", monospace; font-size: 12px; } .c4 { fill: #16a34a; font-family: "PT Mono", monospace; font-size: 12px; } .c5 { fill: #60a5fa; font-family: "PT Mono", monospace; font-size: 12px; } .c6 { fill: #2563eb; font-family: "PT Mono", monospace; font-size: 12px; } .c7 { fill: #a78bfa; font-family: "PT Mono", monospace; font-size: 12px; } .c8 { fill: #7c3aed; font-family: "PT Mono", monospace; font-size: 12px; } .c9 { fill: #f97316; font-family: "PT Mono", monospace; font-size: 12px; }</style>';
        if(_inventory.base == 1){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#a1a1aa" stroke-width="10px"/>';
            race = "Human";
            class = "1";
        }  else if(_inventory.base == 2 ){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#4ade80" stroke-width="10px"/>';
            race = "Dwarf";
            class = "3";
        } else if(_inventory.base == 3){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#16a34a" stroke-width="10px"/>';
            race = "Elf";
            class = "4";
        } else if(_inventory.base == 5){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#60a5fa" stroke-width="10px"/>';
            race = "Orc";
            class = "5";
        } else if(_inventory.base == 8){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#2563eb" stroke-width="10px"/>';
            race = "Troll";
            class = "6";
        } else if(_inventory.base == 12){
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#a78bfa" stroke-width="10px"/>';
            race = "Demon";
            class = "7";
        } else {
            parts[1] = '<rect width="100%" height="100%" rx="1" fill="#18181b" stroke="#f97316" stroke-width="10px"/>';
            race = "Undead";
            class = "9";
        }
        parts[2] = '<line x1="5" y1="39.5" x2="345" y2="39.5" stroke="#3f3f46" stroke-width="2"/><line x1="85" y1="5" x2="85" y2="345" stroke="#3f3f46" stroke-width="2"/><line x1="275" y1="5" x2="275" y2="345" stroke="#3f3f46" stroke-width="2"/><line x1="5" y1="312.5" x2="345" y2="312.5" stroke="#3f3f46" stroke-width="2"/>';
        
        parts[3] = '<text x="15" y="27.25" class="e1">Class</text>';
        parts[4] = '<text x="15" y="64" class="e';
        parts[5] = Strings.toString(_inventory.head.status);
        parts[6] = '">Head</text>';
        
        parts[7] = '<text x="15" y="90" class="e';
        parts[8] = Strings.toString(_inventory.shoulders.status);
        parts[9] = '">Shoulders</text>';
        
        parts[10] = '<text x="15" y="116" class="e';
        parts[11] = Strings.toString(_inventory.chest.status);
        parts[12] = '">Chest</text>';
        
        parts[13] = '<text x="15" y="142" class="e';
        parts[14] = Strings.toString(_inventory.shirt.status);
        parts[15] = '">Shirt</text>';
        
        parts[16] = '<text x="15" y="166" class="e';
        parts[17] = Strings.toString(_inventory.pants.status);
        parts[18] = '">Pants</text>';

        parts[19] = '<text x="15" y="194" class="e';
        parts[20] = Strings.toString(_inventory.feet.status);
        parts[21] = '">Feet</text>';
        
        parts[22] = '<text x="15" y="220" class="e';
        parts[23] = Strings.toString(_inventory.ring.status);
        parts[24] = '">Ring</text>';

        parts[25] = '<text x="15" y="246" class="e';
        parts[26] = Strings.toString(_inventory.artifact.status);
        parts[27] = '">Artifact</text>';

        parts[28] = '<text x="15" y="272" class="e';
        parts[29] = Strings.toString(_inventory.mainhand.status);
        parts[30] = '">Mainhand</text>';

        parts[31] = '<text x="15" y="298" class="e';
        parts[32] = Strings.toString(_inventory.offhand.status);
        parts[33] = '">Offhand</text>';

        parts[34] = '<text x="15" y="334.25" class="e1">Overall</text>';
        
        parts[35] = '<text x="97" y="27" class="c';
        parts[36] = class;
        parts[37] = '">';
        parts[38] = race;

        parts[39] = '</text><text x="97" y="64" class="c';
        parts[40] = Strings.toString(_inventory.head.tier);
        parts[41] = '">';
        parts[42] = _inventory.head.name;
        parts[43] = '</text><text x="287" y="64" class="c';
        parts[44] = Strings.toString(_inventory.head.tier);
        parts[45] = '">';
        if(_inventory.head.soulScore != 0) { parts[46] = Strings.toString(_inventory.head.soulScore); }
        else { parts[46] = ""; }
        
        parts[47] = '</text><text x="97" y="90" class="c';
        parts[48] = Strings.toString(_inventory.shoulders.tier);
        parts[49] = '">';
        parts[50] = _inventory.shoulders.name;
        parts[51] = '</text><text x="287" y="90" class="c';
        parts[52] = Strings.toString(_inventory.shoulders.tier);
        parts[53] = '">';
        if(_inventory.shoulders.soulScore != 0) { parts[54] = Strings.toString(_inventory.shoulders.soulScore); }
        else { parts[54] = ""; }

        parts[55] = '</text><text x="97" y="116" class="c';
        parts[56] = Strings.toString(_inventory.chest.tier);
        parts[57] = '">';
        parts[58] = _inventory.chest.name;
        parts[59] = '</text><text x="287" y="116" class="c';
        parts[60] = Strings.toString(_inventory.chest.tier);
        parts[61] = '">';
        if(_inventory.chest.soulScore != 0) { parts[62] = Strings.toString(_inventory.chest.soulScore); }
        else { parts[62] = ""; }

        parts[63] = '</text><text x="97" y="142" class="c';
        parts[64] = Strings.toString(_inventory.shirt.tier);
        parts[65] = '">';
        parts[66] = _inventory.shirt.name;
        parts[67] = '</text><text x="287" y="142" class="c';
        parts[68] = Strings.toString(_inventory.shirt.tier);
        parts[69] = '">';
        if(_inventory.shirt.soulScore != 0) { parts[70] = Strings.toString(_inventory.shirt.soulScore); }
        else { parts[70] = ""; }

        parts[71] = '</text><text x="97" y="166" class="c';
        parts[72] = Strings.toString(_inventory.pants.tier);
        parts[73] = '">';
        parts[74] = _inventory.pants.name;
        parts[75] = '</text><text x="287" y="166" class="c';
        parts[76] = Strings.toString(_inventory.pants.tier);
        parts[77] = '">';
        if(_inventory.pants.soulScore != 0) { parts[78] = Strings.toString(_inventory.pants.soulScore); }
        else { parts[78] = ""; }

        parts[79] = '</text><text x="97" y="194" class="c';
        parts[80] = Strings.toString(_inventory.feet.tier);
        parts[81] = '">';
        parts[82] = _inventory.feet.name;
        parts[83] = '</text><text x="287" y="194" class="c';
        parts[84] = Strings.toString(_inventory.feet.tier);
        parts[85] = '">';
        if(_inventory.feet.soulScore != 0) { parts[86] = Strings.toString(_inventory.feet.soulScore); }
        else { parts[86] = ""; }

        parts[87] = '</text><text x="97" y="220" class="c';
        parts[88] = Strings.toString(_inventory.ring.tier);
        parts[89] = '">';
        parts[90] = _inventory.ring.name;
        parts[91] = '</text><text x="287" y="220" class="c';
        parts[92] = Strings.toString(_inventory.ring.tier);
        parts[93] = '">';
        if(_inventory.ring.soulScore != 0) { parts[94] = Strings.toString(_inventory.ring.soulScore); }
        else { parts[94] = ""; }
    
        parts[95] = '</text><text x="97" y="246" class="c';
        parts[96] = Strings.toString(_inventory.artifact.tier);
        parts[97] = '">';
        parts[98] = _inventory.artifact.name;
        parts[99] = '</text><text x="287" y="246" class="c';
        parts[100] = Strings.toString(_inventory.artifact.tier);
        parts[101] = '">';
        if(_inventory.artifact.soulScore != 0) { parts[102] = Strings.toString(_inventory.artifact.soulScore); }
        else { parts[102] = ""; }

        parts[103] = '</text><text x="97" y="272" class="c';
        parts[104] = Strings.toString(_inventory.mainhand.tier);
        parts[105] = '">';
        parts[106] = _inventory.mainhand.name;
        parts[107] = '</text><text x="287" y="272" class="c';
        parts[108] = Strings.toString(_inventory.mainhand.tier);
        parts[109] = '">';
        if(_inventory.mainhand.soulScore != 0) { parts[110] = Strings.toString(_inventory.mainhand.soulScore); }
        else { parts[110] = ""; }

        parts[111] = '</text><text x="97" y="298" class="c';
        parts[112] = Strings.toString(_inventory.offhand.tier);
        parts[113] = '">';
        parts[114] = _inventory.offhand.name;
        parts[115] = '</text><text x="287" y="298" class="c';
        parts[116] = Strings.toString(_inventory.offhand.tier);
        parts[117] = '">';
        if(_inventory.offhand.soulScore != 0) { parts[118] = Strings.toString(_inventory.offhand.soulScore); }
        else { parts[118] = ""; }
        
        if(soulScore < 10){ parts[119] = '</text><text x="287" y="334.25" class="c1">'; }
        else if(soulScore < 25){ parts[119] = '</text><text x="287" y="334.25" class="c2">'; }
        else if(soulScore < 50){ parts[119] = '</text><text x="287" y="334.25" class="c3">'; }
        else if(soulScore < 100){ parts[119] = '</text><text x="287" y="334.25" class="c4">'; }
        else if(soulScore < 200){ parts[119] = '</text><text x="287" y="334.25" class="c5">'; }
        else if(soulScore < 500){ parts[119] = '</text><text x="287" y="334.25" class="c6">'; }
        else{ parts[119] = '</text><text x="287" y="334.25" class="c7">'; }
        parts[120] = Strings.toString(soulScore);

        parts[121] = '</text></svg>';

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
        output = string(abi.encodePacked(output, parts[113], parts[114], parts[115], parts[116], parts[117], parts[118], parts[119], parts[120]));
        output = string(abi.encodePacked(output, parts[121]));

        string memory json = string(abi.encodePacked('{"name": "Fallen #', toString(tokenId), '", "description": "Fallen is a fully onchain game.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '","attributes": [{"trait_type": "Shirt", "value": "', _inventory.shirt.name, '"},{"trait_type": "Pants", "value": "', _inventory.pants.name, '"},{"trait_type": "Head", "value": "', _inventory.head.name, '"},{"trait_type": "Feet", "value": "', _inventory.feet.name, '"},{"trait_type": "Chest", "value": "', _inventory.chest.name, '"},{"trait_type": "Shoulders", "value": "', _inventory.shoulders.name));
        json = Base64.encode(bytes(string(abi.encodePacked(json, '"},{"trait_type": "Ring", "value": "', _inventory.ring.name, '"},{"trait_type": "Mainhand", "value": "', _inventory.mainhand.name, '"},{"trait_type": "Offhand", "value": "', _inventory.offhand.name, '"},{"trait_type": "Artifact", "value": "', _inventory.artifact.name, '"},{"trait_type": "Race", "value": "', race, '"},{"trait_type": "Soul Score", "value": "', Strings.toString(soulScore), '"}]}'))));
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