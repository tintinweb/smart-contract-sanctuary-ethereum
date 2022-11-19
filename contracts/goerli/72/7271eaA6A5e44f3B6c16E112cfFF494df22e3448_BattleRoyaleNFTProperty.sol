pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
import "./IBattleRoyaleNFT.sol";
import "./IBattleRoyaleNFTRenderer.sol";
import "./libraries/Property.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

//import "../lib/forge-std/src/console.sol";

contract BattleRoyaleNFTProperty is IBattleRoyaleNFTRenderer {

    using Strings for uint;

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    bytes private constant _gunData = hex"20160000000c0c0d2e30344f4f5964647100000000000000000000120000000000000000004000a6492492492492492492c805a6d24db6e372391b6db6d005a6d24db6dc6e46e36db6d005a6d24db6dc8dc6e46db6d004929225249249249249249000929249244924924924924800125248905100a20000000000125248904900100000000000125248a00800100000000000129244924924900000000000929244924924900000000000929224000000000000000000929224000000000000000004949224000000000000000024a49224000000000000000024a49120000000000000000025249120000000000000000004a491000000000000000000009291000000000000000000009249000000000000000000000248000000000000000000";

    bytes private constant _bombData = hex"1818000000e6a8a0dd452afbbf03885e4305050718161bf6efef0000000000000000000000000000000000000000000000000080000000000000000520000000000000004924080000000000004db4400000000000248db680000000b6db0dcdb28000016ddadd2f28a400000bb5d6ddb6201000005bb6daddb7e0000002dbb6db6b6ea00000035bb6db6ff6d4000016ddb5db6ffeb40000175bb6db6df6b4000016dbb6d76db6b4000016dbb5db6df6a00000035b76db6db6a0000002eb6edb6db5000000005b6edb6db5000000000b6dbaed6800000000016db6eb40000000000005b6d000000000000000000000000000";

    bytes private constant _armorData = hex"181800000000000082796cb8b8b81718185d5f5f403c389c9c9c0000000000000000000002492492492490000014dcb97ef697420000b7d47b6daf9ea84000bf676f499ff15a40067a7fedf7dbf4aa4805c33f6fffdb7e494806293b6fb7db7e4448064d2bfff7fffe6848064dafedb6ff5b48480092676db6fff2124000004a6db6dba4800000004dffb7fda4800000004eabffd5a4800000004ed6ff6dc4800000000cdb25b4840000000009d36da4240000000063724922c4800000005bfbb7f7b8800000005fbdfeff50800000007bd21322d0800000004b9ad574c48000000009249249240000000000000000000000";

    bytes private constant _ringData = hex"1818000000010100744912d8a841e3cd8d6b8acb402908264da100000000000000000000000124924000000000000a71d7892000000000739248f62000000002a491b7ffe48000001ce48dafedbc900000e71b6d7f6cb7900000e6f249ff6db5e2400725b649ffedbebc40052589c97ffdfebc4007244029b7fff237880524402936e48dc6c80524402738db8dc88807258800e59252490800e488001c9b6e48c800e48800139a724908009cb10000726dc88800039624000e6db4400002725892766dbc4000004e4925b16da240000001d96d92691000000001276c564b1000000000009249248000000000000000000000";

    bytes private constant _foodData = hex"181800000008010199772ae0701c8f200eeebc4d1b843f00000000000000000000000000000124924920000000000949c69a840000000255adb6dda8900000155d75baebaea20000a76badb76b6ed44000db6d76daebb6ba40055b5db5db6db5da8806db6db6daed76db48055b6db6db6db6d68805576db6db6db5bd8800abb576b6db6b2a4000c996cb6daedb584004c9325adb75b93908063726d76db6da37080648dd923ae46ec8c806c694b6d92491b90806d32496a8a3721ac8065b524925124ad70800ab6db6db6dadb8400012adb6b75b6e1200000049b6badb848000000001249249200000000000000000000000";

    bytes private constant _bootsData = hex"1818000000010101251f1d3f3a3671756f56545096a49c00000000000000000000000000000000920000000000000000944004800000004904b84125100000005329488a31220000000dcdd692d9a440000001d6b494d1a44000000172d68cd1264000000032d48bd5324000000032b441d5a2000000003634419122000000002eb44175320000000171b442b5220000000a92a44171320000004c92b44259b4000012f44db493b9a20000b934a9244bb1344005591a2492415ab2400092490000015746400000000000017b4a880000000000012f4648000000000000051200000000000000049000000000000000000000";

    function _getColorString(uint red, uint green, uint blue) private pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        buffer[1] = _HEX_SYMBOLS[red & 0xf];
        buffer[0] = _HEX_SYMBOLS[(red >> 4) & 0xf];

        buffer[3] = _HEX_SYMBOLS[green & 0xf];
        buffer[2] = _HEX_SYMBOLS[(green >> 4) & 0xf];

        buffer[5] = _HEX_SYMBOLS[blue & 0xf];
        buffer[4] = _HEX_SYMBOLS[(blue >> 4) & 0xf];
        return string(buffer);
    }


    function _renderImage(bytes memory data) private pure returns (string memory r) {
        uint width = uint8(data[0]);
        uint height = uint8(data[1]);

        require(width * height % 8 == 0, "invalid size");
        
        string[8] memory colors;
        for(uint i = 1; i < 8; i++) {
            colors[i] = _getColorString(uint(uint8(data[2 + i * 3])), uint(uint8(data[2 + i * 3 + 1])), uint(uint8(data[2 + i * 3 + 2])));
        }
        uint index = 0;
        r = "";
        uint offsetX = (32 - width) / 2;
        uint offsetY = 36 - height;

        for (uint i = 26; i < data.length; i += 3) {
            uint24 tempUint;
            assembly {
                tempUint := mload(add(add(data, 3), i))
            }
            uint pixels = tempUint;
            for (uint j = 0; j < 8; j++) {
                uint x = index % width;
                uint y = index / width;
                uint d = (pixels >> (3 * (7 - j))) & 7;
                index += 1;
                if (d > 0) {
                    r = string(abi.encodePacked(r, '<rect fill="#', colors[d], '" x="', (x + offsetX).toString(), '" y="', (y + offsetY).toString(), '" width="1" height="1" />'));
                }
            }
        }
    }

    function _characterTextProperties(uint property) private pure returns (string[] memory r) {
        (uint hp, uint maxHP, uint bagCapacity) = Property.decodeCharacterProperty(property);
        r = new string[](6);
        r[0] = "HP";
        r[1] = hp.toString();

        r[2] = "Max HP";
        r[3] = maxHP.toString();

        r[4] = "Bag Capacity";
        r[5] = bagCapacity.toString();

    }

    function _gunTextProperties(uint property) private pure returns (string[] memory r) {
        (uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) = Property.decodeGunProperty(property);
        r = new string[](8);
        r[0] = "Bullet Count";
        r[1] = bulletCount.toString();

        r[2] = "Shoot Range";
        r[3] = shootRange.toString();

        r[4] = "Bullet Damage";
        r[5] = bulletDamage.toString();

        r[6] = "Triple Damage Chance";
        r[7] = string(abi.encodePacked(tripleDamageChance.toString(), "%"));

    }

    function _bombTextProperties(uint property) private pure returns (string[] memory r) {
        (uint throwRange, uint explosionRange, uint damage) = Property.decodeBombProperty(property);
        r = new string[](6);
        r[0] = "Throw Range";
        r[1] = throwRange.toString();

        r[2] = "Explosion Range";
        r[3] = explosionRange.toString();

        r[4] = "Bomb Damage";
        r[5] = damage.toString();
    }

    function _armorTextProperties(uint property) private pure returns (string[] memory r) {
        (uint defense) = Property.decodeArmorProperty(property);
        r = new string[](2);
        r[0] = "Defense";
        r[1] = defense.toString();
    }

    function _ringTextProperties(uint property) private pure returns (string[] memory r) {
        (uint dodgeCount, uint dodgeChance) = Property.decodeRingProperty(property);
        r = new string[](4);
        r[0] = "Dodge Count";
        r[1] = dodgeCount.toString();

        r[2] = "Dodge Chance";
        r[3] = string(abi.encodePacked(dodgeChance.toString(), "%"));
    }

    function _foodTextProperties(uint property) private pure returns (string[] memory r) {
        (uint heal) = Property.decodeFoodProperty(property);
        r = new string[](2);
        r[0] = "Heal HP";
        r[1] = heal.toString();
    }

    function _bootsTextProperties(uint property) private pure returns (string[] memory r) {
        (uint usageCount, uint moveMaxSteps) = Property.decodeBootsProperty(property);
        r = new string[](4);
        r[0] = "Usage Count";
        r[1] = usageCount.toString();

        r[2] = "Max Move Distance";
        r[3] = moveMaxSteps.toString();
    }

    function _renderTextProperties(string[] memory properties, string memory name) private pure returns (bytes memory r) {
        r = abi.encodePacked('<text x="31" y="6" class="title">', name, '</text>');
        for (uint i = 0; i < properties.length; i += 2) {
            uint strlen = bytes(properties[i]).length + bytes(properties[i+1]).length + 1;
            strlen = strlen * 85;
            strlen = strlen % 100 == 0 ? strlen / 100 : strlen / 100 + 1;
            strlen += 2;
            r = abi.encodePacked(r, '<g style="transform:translate(1px, ', ((i / 2) * 3 + 1).toString(), 'px)"><rect width="', strlen.toString(), '" class="text-back" /><text x="1" y="1.4" class="base">', properties[i], ':',  '<tspan class="value">', properties[i+1], '</tspan></text></g>');
        }
    }

    struct MetaDataParams {
        string name;
        uint tokenId;
        string description;
        string[] textProperties;
        bytes renderData;
        string color1;
        string color2;
    }
    function _genMetadata(MetaDataParams memory p) private pure returns (string memory) {
        bytes memory svg = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 36"><style>.base { fill: rgba(255,255,255,0.6); font-family: "Courier New", monospace; font-size: 1.4px; font-weight: 600;  } .title{ fill: black; font-family: "Courier New", monospace; font-size: 2.5px; text-anchor: end;font-weight: 700 } .hint { fill: black; font-family: "Courier New", monospace; font-size: 1px; font-weight: 600; text-anchor: end; }.value{fill: white;} .text-back{ height: 2px; rx: 1px; ry:1 px; fill: rgba(0,0,0,0.6);} </style><defs><radialGradient id="RadialGradient1"><stop offset="5%" stop-color="', p.color1, '"/><stop offset="75%" stop-color="',p.color2, '" /></radialGradient></defs><circle r="32" cx="16" cy="16" fill="url(#RadialGradient1)"/><text x="31" y="2" class="hint">play on battle-royale.xyz</text>');

        svg = abi.encodePacked(svg, _renderTextProperties(p.textProperties, p.name), _renderImage(p.renderData), '</svg>');

        //console.log("svg", string(svg));
        
        bytes memory attributes = "[";
        for (uint i = 0; i < p.textProperties.length; i += 2) {
            attributes = abi.encodePacked(attributes, i == 0 ? '' : ',', '{"trait_type":"', p.textProperties[i], '","value":"', p.textProperties[i+1], '"}');
        }
        attributes = abi.encodePacked(attributes, ']');

        bytes memory d = abi.encodePacked('{"name":"', p.name, ' #', p.tokenId.toString(), '","description":"', p.description, '","image": "data:image/svg+xml;base64,', Base64.encode(svg), '","attributes":', attributes, '}');
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(d)));
    }

    function _getCharacterData(uint tokenId) private pure returns (bytes memory) {
        uint d = uint(keccak256(abi.encodePacked(tokenId))) % 10;
        if (d == 0) {
            return hex"18180000000000005b3532a33733a47979e8cfbf29377900000000000004924000000000000129248800000000000a4db4910000000000535238da20000000029249b71a44000000029249291a44000000029249a4924400000002926ab515440000000056d6ed6520000000000db6db6a20000000000cb6db5100000000000196db31240000000009ca38db68900000005a49b6db6db20000131a6db6db6db24000d92249b6db72db0800c92249b6db965b610019264db6b4b24b48001b32d96dacd65b48001b66db6da556db48001936db6da4d6c948001573db6db6d24a88001d6edb6dadb6db8800196ecaedadb2da88";
        } else if (d == 1) {
            return hex"1818000000000000442e2a7e2f2bae2f2bae8981ded1ca432e810000000000000000000000000000000000000000000000480000000000000092912400000000000524db6880000000002929258c800000000149b6ebad10000000014934a34922000000014936db49220000000149bad2c922000000014adbadaaa2000000014b6db6cd24400000014aedb6c92640000000295db5b52640000000297faead28400000014924e469b64000000d4926db6db8c800006d4948dc923fc800026d55c92491f791001b6cdb6b6da9dac8009dacdb6db6aedd8806ddafbb5db7eaed8836bb92bb5db7eaed992eed92fb5db7eaed61";
        } else if (d == 2) {
            return hex"181800000000000032422d8a4745b5875ee7be87426f3f00000000000004920000000000000129a64000000000000b6dc68800000000005b6db6d90000000002db8dc6d90000000002db8db6da2000000002db72571b2000000002edb6d8db2000000002edb6db1b20000000005cb62b6220000000000db6db5920000000000d96db6484800000004db6daddb512000002a556c96cdb2440001cb54e3b6edb6c40009cb66dcb36c9444006469672d9b24a4b4806c79696b496925b6132c9968da894adcb6932c69672adb391b96932c4b692e92652492136acb3b5a93672376936bdb36d2db24ec96936bdb272a7b6d2c969";
        } else if (d == 3) {
            return hex"18180000000000002a23286246492a2843966752c39972e6c29b00000004924900000000000029b6e22000000000016dbb6b44000000000b76dd6d68800000005375db76b080000000636e376eb0800000005d6dbaed70800000005d6ddbed708000000053af6d9bd0800000000cbfffdbc9100000000cbbffeb91900000000c9bffe4b1100000000d73feeb70800000000b92dba470820000025392db6470944000956b91c724723d48057d6491c724936ff92adb64734b25936ff92b5ae5934d24965bb9075b6c934d2475ddb9075b5c92cf247ebd7105d92c91cf257749a929d93491cd26d24b2135c72c924d2691c9d9";
        } else if (d == 4) {
            return hex"181800000000000056678571a3bf383a56d3c6bd8f848e35415900000000924800000000000025269120000000000149b6db44000000000a51b75b6400000000538db6da4400000000534da75a440000000053d364da4c800000000a4ad49a48800000000adada9a68800000000abadb5648800000000bd6db6490800000000aeadbb484000000004a9369968480000003a4924aa48712000016a49249a492ea4800eca4924da4d55b69072524922d34d15b69052522b6db64935b693248a5b6dba49a2da90649145ae524ca45290649224b28a4924921062b124928a48a24a132dd249265b4d669a906db25dadd2296dbb1";
        } else if (d == 5) {
            return hex"1818000000000000613f4197604acb9a71dec6a6565f754f3c3d00000000000000000000000000000000000000000000124000000000000024a48900000000000149a6da20000000000a69b69b20000000000a69b6db44000000000b71b4d364000000000b6db49a48800000000a92c69468800000000a4a472448800000000a92d96b49100000000a725b5bb6d24000005a764923b5a308000062514ae3b5354800005b4a252daab9080002dc69272d4e59080016dc49c9526e495900c8e396495a4a4b6100c6dcb6496d51cb690526e4aecb6db1b929076cddc9256dadc969376d955b6d2da934a92a5dd45b6d2c492d69";
        } else if (d == 6) {
            return hex"18180000000000008d79553d583fcdaf8df8dbc622393500000000000025264800000000000149249900000000000a49249220000000000a8a452464000000005249451484000000005a522922440000000052892a9244000000005bcd555444000000000a725b6464000000000a92db6a20000000000196db5b20000000000036db1b2400000000017925aa6c800000004b6b671b7892400002f6db64db6db788001db6cf6cdecf6d8800edb66db6db7b36f100edb6d9bcdbdb36f1076db6db36dbdb66f1076db67b3cdedb36f13b6db6cf37b6db66d9076db6cdbd9b59ecd9076db67b6cd2cb3d993b6db6db679edb2db1";
        } else if (d == 7) {
            return hex"18180000000000004736493e3437673c53a36669d2ad7a6555680000000092480000000000002524d920000000000949249264000000005a4924944c800000000a56e59248800800000b5b6b94488059000001972da2488051000001cb6dadc88069000001db6db5ad92e9000001bb6db656ede1000001fb6db2765cb90000017b6db66e5bb100024df36d76d14b61001724b64bb592cb5100bca5d6db6c96db6905c8a4b6db2db55b693e2924b6a96d52db69322914924b62494961322924925b12525db131452452d924492fb93249229248a2497ff92924a5922892497ff92924b6da4894fffff13b6576dfdfecbd7ff9";
        } else if (d == 8) {
            return hex"1818000000000000323136978e8ebbbdc0ecd7cc6f5b5d2b283000000124924800000000000a6dc8d10000000000536e4b6220000000005e72cb6b20000000007372c963200000000074b2496320000000005db1c75b440000000057af3d34440000000055b6dd1b440000000055b6d9bfe8800000005bb6d6ffe880000000576edd77e4000000007fd6eadfe400000003ffedd927e400000015fff9c8dfe4920000afb76f48fbfffe48001ef779d9b3ffffd1001ff68e4cfffbfff9001ffc9a47fffdfdf9001ffc8ecdffff6db9001da572ccffffffb100ffbe8e5cdffffff9057efffbe6e7dffff9057fb6df6cffdffff9";
        } else {
            return hex"181800000000000041323e94323e42323eb68870ca323eccba9c00000000000000000000000004924900000000000129b6da20000000000a92edb664000000000dbedb6ed0800000000dfedb6ecc800000006df7db6ed9100000006df6fb6ed9a200000065b7fb6dadb20000006596db6d6f3200000063bffb6d6f3200000065fffffe8d90000002a5bffb7c6c800000006493db24840000000064923ae48400000000648dfb2490900000036c95f723b5a20000032476b964b6d20000035cfecb2496d20000035cfe46dc92c20000031daf36e579e200000334db6ce36dc200000333db6d248ea20000031cdb6724b69000";
        }
    }

    function tokenURI(uint tokenId, uint property) external pure returns (string memory) {
        uint nftType = Property.decodeType(property);
        if (nftType == Property.NFT_TYPE_CHARACTER) {
            return _genMetadata(MetaDataParams({
                name: "Character",
                tokenId: tokenId,
                description: "Must have one Character NFT to play game",
                textProperties: _characterTextProperties(property),
                renderData: _getCharacterData(tokenId),
                color1: "#48f5ff",
                color2: "#17aabb"
            }));
        } else if (nftType == Property.NFT_TYPE_GUN) {
            return _genMetadata(MetaDataParams({
                name: "Gun",
                tokenId: tokenId,
                description: "Shoot others with the gun",
                textProperties: _gunTextProperties(property),
                renderData: _gunData,
                color1: "#f25680",
                color2: "#a43957"
            }));
        } else if (nftType == Property.NFT_TYPE_BOMB) {
            return _genMetadata(MetaDataParams({
                name: "Bomb",
                tokenId: tokenId,
                description: "Throw the bomb to kill more people",
                textProperties: _bombTextProperties(property),
                renderData: _bombData,
                color1: "#ffe557",
                color2: "#ccb745"
            }));
        } else if (nftType == Property.NFT_TYPE_ARMOR) {
            return _genMetadata(MetaDataParams({
                name: "Armor",
                tokenId: tokenId,
                description: "Wear the armor to defend",
                textProperties: _armorTextProperties(property),
                renderData: _armorData,
                color1: "#bffada",
                color2: "#98c6ad"
            }));
        } else if (nftType == Property.NFT_TYPE_RING) {
            return _genMetadata(MetaDataParams({
                name: "Ring",
                tokenId: tokenId,
                description: "Wear the ring to dodge bullets",
                textProperties: _ringTextProperties(property),
                renderData: _ringData,
                color1: "#0ec2ff",
                color2: "#087499"
            }));
        } else if (nftType == Property.NFT_TYPE_FOOD) {
            return _genMetadata(MetaDataParams({
                name: "Food",
                tokenId: tokenId,
                description: "Eat food to heal (+HP)",
                textProperties: _foodTextProperties(property),
                renderData: _foodData,
                color1: "#14b598",
                color2: "#0e826d"
            }));
        } else if (nftType == Property.NFT_TYPE_BOOTS) {
            return _genMetadata(MetaDataParams({
                name: "Boots",
                tokenId: tokenId,
                description: "Wear the boots to move further",
                textProperties: _bootsTextProperties(property),
                renderData: _bootsData,
                color1: "#f77825",
                color2: "#ab531a"
            }));
        } else {
            revert("Unknown nft type");
        }
    }

    function characterProperty(uint property) public pure returns(uint hp, uint maxHP, uint bagCapacity) {
        return Property.decodeCharacterProperty(property);
    }

    function gunProperty(uint property) public pure returns(uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) {
        return Property.decodeGunProperty(property);
    }

    function bombProperty(uint property) public pure returns(uint throwRange, uint explosionRange, uint damage) {
        return Property.decodeBombProperty(property);
    }

    function armorProperty(uint property) public pure returns(uint defense) {
        return Property.decodeArmorProperty(property);
    }

    function ringProperty(uint property) public pure returns(uint dodgeCount, uint dodgeChance) {
        return Property.decodeRingProperty(property);
    }

    function foodProperty(uint property) public pure returns(uint heal) {
        return Property.decodeFoodProperty(property);
    }

    function bootsProperty(uint property) public pure returns(uint usageCount, uint moveMaxSteps) {
        return Property.decodeBootsProperty(property);
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "../lib/forge-std/src/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBattleRoyaleNFT is IERC721Enumerable {
    function tokenType(uint tokenId) external view returns (uint);
    function tokenProperty(uint tokenId) external view returns (uint);
    function nextTokenId() external view returns (uint);

    function burn(uint256 tokenId) external;

    function setProperty(uint tokenId, uint newProperty) external;
    function mintByGame(address to, uint property) external returns (uint);

    function games() external view returns (address[] memory);
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
import "./IBattleRoyaleNFT.sol";
//import "../lib/forge-std/src/console.sol";

interface IBattleRoyaleNFTRenderer {
    function tokenURI(uint tokenId, uint property) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Property {

    uint public constant NFT_TYPE_CHARACTER = 1;
    uint public constant NFT_TYPE_GUN = 2;
    uint public constant NFT_TYPE_BOMB = 3;
    uint public constant NFT_TYPE_ARMOR = 4;
    uint public constant NFT_TYPE_RING = 5;
    uint public constant NFT_TYPE_FOOD = 6;
    uint public constant NFT_TYPE_BOOTS = 7;

    function decodeType(uint encodeData) internal pure returns (uint) {
        uint t = encodeData >> 248;
        require(t > 0);
        return t;
    }

    function propertyCount(uint encodeData) internal pure returns (uint) {
        return encodeData & 0xffff;
    }

    // function encodeProperty(uint nftType, uint[] memory properties) internal pure returns (uint encodeData) {
    //     encodeData = (nftType << 248) | (properties.length);
    //     for(uint i = 0; i < properties.length; i++) {
    //         encodeData |= (properties[i] << (i * 16 + 16));
    //     }
    // }

    function encodeProperty1(uint nftType, uint property1) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 1;
        encodeData |= property1 << 16;
    }

    function encodeProperty2(uint nftType, uint property1, uint property2) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 2;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
    }

    function encodeProperty3(uint nftType, uint property1, uint property2, uint property3) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 3;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
        encodeData |= property3 << 48;
    }

    function encodeProperty4(uint nftType, uint property1, uint property2, uint property3, uint property4) internal pure returns (uint encodeData) {
        encodeData = (nftType << 248) | 4;
        encodeData |= property1 << 16;
        encodeData |= property2 << 32;
        encodeData |= property3 << 48;
        encodeData |= property4 << 64;
    }

    function decodeProperty1(uint encodeData) internal pure returns (uint) {
        return (encodeData >> 16) & 0xffff;
    }

    function decodeProperty2(uint encodeData) internal pure returns (uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff);
    }

    function decodeProperty3(uint encodeData) internal pure returns (uint, uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff, (encodeData >> 48) & 0xffff);
    }

    function decodeProperty4(uint encodeData) internal pure returns (uint, uint, uint, uint) {
        return ((encodeData >> 16) & 0xffff, (encodeData >> 32) & 0xffff, (encodeData >> 48) & 0xffff, (encodeData >> 64) & 0xffff);
    }

    /**
     * 0-16: hp
     * 16-32: max hp
     * 32-48: bag capacity
     */
    function decodeCharacterProperty(uint encodeData) internal pure returns (uint hp, uint maxHP, uint bagCapacity) {
        require(decodeType(encodeData) == NFT_TYPE_CHARACTER && propertyCount(encodeData) == 3, "not character");
        return decodeProperty3(encodeData);
    }

    function encodeCharacterProperty(uint hp, uint maxHP, uint bagCapacity) internal pure returns (uint) {
        return encodeProperty3(NFT_TYPE_CHARACTER, hp, maxHP, bagCapacity);
    }

    /**
     * 0-16: bullet count
     * 16-32: shoot range
     * 32-48: bullet damage
     * 48-64: triple damage chance
     */
    function decodeGunProperty(uint encodeData) internal pure returns (uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) {
        require(decodeType(encodeData) == NFT_TYPE_GUN && propertyCount(encodeData) == 4, "not gun");
        return decodeProperty4(encodeData);
    }

    function encodeGunProperty(uint bulletCount, uint shootRange, uint bulletDamage, uint tripleDamageChance) internal pure returns (uint) {
        return encodeProperty4(NFT_TYPE_GUN, bulletCount, shootRange, bulletDamage, tripleDamageChance);
    }

    /**
     * 0-16: throwing range
     * 16-32: explosion range
     * 32-48: damage
     */
    function decodeBombProperty(uint encodeData) internal pure returns (uint throwRange, uint explosionRange, uint damage) {
        require(decodeType(encodeData) == NFT_TYPE_BOMB && propertyCount(encodeData) == 3, "not bomb");
        return decodeProperty3(encodeData);
    }

    function encodeBombProperty(uint throwRange, uint explosionRange, uint damage) internal pure returns (uint) {
        return encodeProperty3(NFT_TYPE_BOMB, throwRange, explosionRange, damage);
    }

    /**
     * 
     * 0-16: defense
     */
    function decodeArmorProperty(uint encodeData) internal pure returns (uint defense) {
        require(decodeType(encodeData) == NFT_TYPE_ARMOR && propertyCount(encodeData) == 1, "not armor");
        return decodeProperty1(encodeData);
    }


    function encodeArmorProperty(uint defense) internal pure returns(uint) {
        return encodeProperty1(NFT_TYPE_ARMOR, defense);
    }

    /**
     * 
     * 0-16: dodgeCount
     * 16-32: dodgeChance
     */
    function decodeRingProperty(uint encodeData) internal pure returns (uint dodgeCount, uint dodgeChance) {
        require(decodeType(encodeData) == NFT_TYPE_RING && propertyCount(encodeData) == 2, "not ring");
        return decodeProperty2(encodeData);
    }

    function encodeRingProperty(uint dodgeCount, uint dodgeChance) internal pure returns(uint) {
        return encodeProperty2(NFT_TYPE_RING, dodgeCount, dodgeChance);
    }

    function decodeFoodProperty(uint encodeData) internal pure returns (uint heal) {
        require(decodeType(encodeData) == NFT_TYPE_FOOD && propertyCount(encodeData) == 1, "not food");
        return decodeProperty1(encodeData);
    }

    function encodeFoodProperty(uint heal) internal pure returns(uint) {
        return encodeProperty1(NFT_TYPE_FOOD, heal);
    }
    
    function decodeBootsProperty(uint encodeData) internal pure returns(uint usageCount, uint moveMaxSteps) {
        require(decodeType(encodeData) == NFT_TYPE_BOOTS && propertyCount(encodeData) == 2, "not boots");
        return decodeProperty2(encodeData);
    }

    function encodeBootsProperty(uint usageCount, uint moveMaxSteps) internal pure returns(uint) {
        return encodeProperty2(NFT_TYPE_BOOTS, usageCount, moveMaxSteps);
    }


    function newProperty(uint seed, uint probability) internal pure returns(uint property) {
        uint t = (probability >> (4 * (seed % 20))) & 0xf;
        seed = seed >> 8;
        property = 0;
        if (t == Property.NFT_TYPE_CHARACTER) {
            property = newCharacterProperty(seed);
        } else if (t == Property.NFT_TYPE_GUN) {
            property = newGunProperty(seed);
        } else if (t == Property.NFT_TYPE_BOMB) {
            property = newBombProperty(seed);
        } else if (t == Property.NFT_TYPE_ARMOR) {
            property = newArmorProperty(seed);
        } else if (t == Property.NFT_TYPE_RING) {
            property = newRingProperty(seed);
        } else if (t == Property.NFT_TYPE_FOOD) {
            property = newFoodProperty(seed);
        } else if (t == Property.NFT_TYPE_BOOTS) {
            property = newBootsProperty(seed);
        } else {
            revert("Unknown Type");
        }
    }

    /**
     * maxHp: 16-100(possible: 16, 20, 25, 33, 50, 100)
     * bagCapacity: 1-6(possible: 1-6)
     * maxHP * bagCapacity = 100 (volatility 30%)
     */
    function newCharacterProperty(uint seed) private pure returns (uint) {
        uint bagCapacity = seed % 6 + 1;
        uint hp = 100 * ((seed >> 4) % 60 + 70) / bagCapacity / 100;
        return encodeCharacterProperty(hp, hp, bagCapacity);
    }

    /**
     * bulletCount: 1-10: 1-10
     * shootRange: 1-16: 1-16
     * bulletDamage: 3-30: 3,7,10,15,30
     * criticalStrikeProbability: 10%-100%
     * 
     * bulletCount * (1 - 1/(shootRange/4+1)) * bulletDamage = 30 (volatility 30%)
     * bulletCount * criticalStrikeProbability = 100%
     */
    function newGunProperty(uint seed) private pure returns (uint) {
        uint bulletCount = seed % 10 + 1;
        uint shootRange = (seed >> 4) % 16 + 1;
        uint bulletDamage = 30 * ((seed >> 8) % 60 + 70) / bulletCount / (100 - 100/(shootRange/4+2));
        uint tripleDamageChance = 100 / bulletCount;
        return encodeGunProperty(bulletCount, shootRange, bulletDamage, tripleDamageChance);
    }

    /**
     * throwRange: 5-16
     * explosionRange: 1-10
     * damage: 10-100: 10, 11, 12, 14, 16, 20, 25, 33, 50, 100
     * 
     * explosionRange * damage = 100 (volatility 30%)
     */
    function newBombProperty(uint seed) private pure returns (uint) {
        uint throwRange = seed % 12 + 5;
        uint explosionRange = (seed >> 4) % 10 + 1;
        uint damage = 100 * ((seed >> 8) % 60 + 70) / explosionRange / 100;
        return encodeBombProperty(throwRange, explosionRange, damage);
    }

    /**
     * defense: 20-100
     */
    function newArmorProperty(uint seed) private pure returns (uint) {
        uint defense = seed % 80 + 20;
        return encodeArmorProperty(defense);
    }

    /**
     * dodgeCount: 3-6
     * dodgeChance: 50-100
     * 
     * dodgeChance * dodgeCount = 300 (volatility 30%)
     */
    function newRingProperty(uint seed) private pure returns (uint) {
        uint dodgeCount = seed % 4 + 3;
        uint dodgeChance = 300 * ((seed >> 8) % 60 + 70) / dodgeCount / 100;
        dodgeChance = dodgeChance > 100 ? 100 : dodgeChance;
        return encodeRingProperty(dodgeCount, dodgeChance);
    }

    /**
     * heal: 20-100
     */
    function newFoodProperty(uint seed) private pure returns (uint) {
        uint heal = seed % 80 + 20;
        return encodeFoodProperty(heal);
    }

    /**
     * usageCount: 1-3
     * moveMaxSteps: 5-15: 5, 10, 15
     * 
     * usageCount * moveMaxSteps = 15 (volatility 30%)
     */
    function newBootsProperty(uint seed) private pure returns (uint) {
        uint usageCount = seed % 3 + 1;
        uint moveMaxSteps = 15 * ((seed >> 8) % 60 + 70) / usageCount / 100;
        return encodeBootsProperty(usageCount, moveMaxSteps);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}