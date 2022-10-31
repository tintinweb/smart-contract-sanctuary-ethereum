/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISvgData {
    function getStrokeByTag(uint tag, uint pos) external view returns(string memory);
    function getBackground(string memory color) external pure returns(string memory);
    function getTagLength(uint tag) external view returns(uint);
}

contract Generate is Ownable {
    using Strings for uint256;

    string[5] private _backColor = ["C7C8CF", "DCC4BE", "4E7187", "8C5851", "8972B1"];
    uint8[] private _interMap = [
        0,1,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,
        36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67
        // 68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,
        // 100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,
        // 124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,
        // 148,149,150,151,152,153,154,155,156,157,158,159,160
    ];
    mapping(uint256 => bytes) public _generedMap;  //已生成的图,格式13213
    mapping(uint256 => uint256) public _powerMap;
    mapping(uint256 => uint256) public _energyMap;
    mapping(uint256 => uint256) public _healthMap;
    mapping(uint256 => uint256) public _defenseMap;
    mapping(uint256 => uint256) public _treasureMap;
    mapping(uint256 => uint256) public _attackMap;

    address public _svgDataAddr = 0x33A95166F27a93E34e86eBa7Cc30FA2b599AeA7e;

    function setSvgStorage(address svgContract) public onlyOwner {
        _svgDataAddr = svgContract;
    }

    function setSeed(uint256 _tokenId) public returns(bytes memory) {
        uint256 power = 100;
        uint256 energy = 100;
        uint256 health = 100;
        uint256 defense = 100;
        uint256 treasure = 100;
        uint256 attack = 100;
        bytes memory imSeed;
        uint8 background = _interMap[random(5)];
        imSeed = abi.encodePacked(background);
        uint8 sex = _interMap[random(15)];
        uint8 max = 255;
        imSeed = abi.encodePacked(imSeed, sex);
        if (sex < 9) { //男
            uint tmp = random(100000);
            uint8 skin = 0;
            if (99999 == tmp) {
                skin = 5;
            }else if (tmp >= 99988) {
                skin = 7;
            }else if (tmp >= 99978) {
                skin = 8;
            }else if (tmp >= 99878) {
                skin = 4;
            }else if (tmp < 1000) {
                skin = 6;
            }else {
                skin = _interMap[uint256(tmp % 4)];
            }
            imSeed = abi.encodePacked(imSeed, skin);

            uint8 cloth = _interMap[random(ISvgData(_svgDataAddr).getTagLength(9))];
            imSeed = abi.encodePacked(imSeed, cloth);

            uint pro = random(100);
            if (pro < 30) {
                uint8 beard = _interMap[random(ISvgData(_svgDataAddr).getTagLength(15))];
                imSeed = abi.encodePacked(imSeed, beard);
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            pro = random(100);
            if (pro > 10 && pro <= 20) {
                uint8 ear = _interMap[random(ISvgData(_svgDataAddr).getTagLength(14))];
                imSeed = abi.encodePacked(imSeed, ear);
                if (3 == ear) {
                    treasure = 105;
                }else if (2 == ear) {
                    treasure = 103;
                }else if (1 == ear) {
                    treasure = 102;
                }else if (0 == ear) {
                    treasure = 101;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            if (24 == cloth) {
                imSeed = abi.encodePacked(imSeed, max);
            }else {
                uint8 hair = _interMap[random(ISvgData(_svgDataAddr).getTagLength(11))];
                imSeed = abi.encodePacked(imSeed, hair);
                if (0 == hair) {
                    defense = 121;
                }
            }
            
            if (cloth < 14) {
                tmp = random(100);
                if (tmp >= 70) {
                    uint8 element = _interMap[random(ISvgData(_svgDataAddr).getTagLength(16))];
                    imSeed = abi.encodePacked(imSeed, element);
                    power = getPower(element);
                    energy = getEnergy(element);
                    health = getHealth(element);
                }else {
                    imSeed = abi.encodePacked(imSeed, max);
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }
            pro = random(100);
            if (pro > 20 && pro <= 30) {
                uint8 neck = _interMap[random(ISvgData(_svgDataAddr).getTagLength(12))];
                imSeed = abi.encodePacked(imSeed, neck);
                if (5 == neck) {
                    treasure = 189;
                }else if (4 == neck) {
                    treasure = 155;
                }else if (3 == neck) {
                    treasure = 134;
                }else if (2 == neck) {
                    treasure = 121;
                }else if (1 == neck) {
                    treasure = 113;
                }else if (0 == neck) {
                    treasure = 108;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            pro = random(100);
            if (pro < 10) {
                uint8 glass = _interMap[random(ISvgData(_svgDataAddr).getTagLength(10))];
                imSeed = abi.encodePacked(imSeed, glass);
                if (5 == glass) {
                    defense = 113;
                }else if (4 == glass) {
                    defense = 108;
                }else if (3 == glass) {
                    defense = 105;
                }else if (2 == glass) {
                    defense = 103;
                }else if (1 == glass) {
                    defense = 102;
                }else if (0 == glass) {
                    defense = 101;
                }else if (7 == glass) {
                    defense = 134;
                }else if (8 == glass) {
                    defense = 189;
                }else if (6 == glass) {
                    defense = 155;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            pro = random(100);
            if (pro >= 95) {    //smoke
                uint8 eye = _interMap[random(ISvgData(_svgDataAddr).getTagLength(13))];
                imSeed = abi.encodePacked(imSeed, eye);
                if (7 == eye) {
                    attack = 134;
                }else if (6 == eye) {
                    attack = 121;
                }else if (5 == eye) {
                    attack = 113;
                }else if (4 == eye) {
                    attack = 108;
                }else if (3 == eye) {
                    attack = 105;
                }else if (2 == eye) {
                    attack = 103;
                }else if (1 == eye) {
                    attack = 102;
                }else if (0 == eye) {
                    attack = 101;
                }else if (16 == eye) {
                    attack = 189;
                }else if (12 == eye) {
                    defense = 189;
                }else if (11 == eye) {
                    defense = 155;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }
        }else { //女
            uint tmp = random(100000);
            uint8 skin = 0;
            if (99999 == tmp) {
                skin = 5;
            }else if (tmp < 100) {
                skin = 4;
            }else {
                skin = _interMap[uint256(tmp % 4)];
            }
            imSeed = abi.encodePacked(imSeed, skin);

            uint8 cloth = _interMap[random(ISvgData(_svgDataAddr).getTagLength(2))];
            imSeed = abi.encodePacked(imSeed, cloth);
            imSeed = abi.encodePacked(imSeed, max);
            
            uint pro = random(100);
            if (pro > 10 && pro <= 20) {
                uint8 ear = _interMap[random(ISvgData(_svgDataAddr).getTagLength(3))];
                imSeed = abi.encodePacked(imSeed, ear);
                if (3 == ear) {
                    treasure = 105;
                }else if (2 == ear) {
                    treasure = 103;
                }else if (1 == ear) {
                    treasure = 102;
                }else if (0 == ear) {
                    treasure = 101;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }
            
            if (32 == cloth) {
                imSeed = abi.encodePacked(imSeed, max);
            }else {
                uint8 hair = _interMap[random(ISvgData(_svgDataAddr).getTagLength(5))];
                imSeed = abi.encodePacked(imSeed, hair);
                if (0 == hair) {
                    defense = 121;
                }
            }

            if (cloth < 14) {
                tmp = random(100);
                if (tmp < 30) {
                    uint8 element = _interMap[random(ISvgData(_svgDataAddr).getTagLength(16))];
                    imSeed = abi.encodePacked(imSeed, element);
                    power = getPower(element);
                    energy = getEnergy(element);
                    health = getHealth(element);
                }else {
                    imSeed = abi.encodePacked(imSeed, max);
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            pro = random(100);
            if (pro > 20 && pro <= 30) {
                uint8 neck = _interMap[random(ISvgData(_svgDataAddr).getTagLength(6))];
                imSeed = abi.encodePacked(imSeed, neck);
                if (5 == neck) {
                    treasure = 189;
                }else if (4 == neck) {
                    treasure = 155;
                }else if (3 == neck) {
                    treasure = 134;
                }else if (2 == neck) {
                    treasure = 121;
                }else if (1 == neck) {
                    treasure = 113;
                }else if (0 == neck) {
                    treasure = 108;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            pro = random(100);
            if (pro < 10) {
                uint8 glass = _interMap[random(ISvgData(_svgDataAddr).getTagLength(4))];
                imSeed = abi.encodePacked(imSeed, glass);
                if (5 == glass) {
                    defense = 113;
                }else if (4 == glass) {
                    defense = 108;
                }else if (3 == glass) {
                    defense = 105;
                }else if (2 == glass) {
                    defense = 103;
                }else if (1 == glass) {
                    defense = 102;
                }else if (0 == glass) {
                    defense = 101;
                }else if (7 == glass) {
                    defense = 134;
                }else if (8 == glass) {
                    defense = 189;
                }else if (6 == glass) {
                    defense = 155;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }

            pro = random(100);
            if (pro >= 95) {  //smoke
                uint8 eye = _interMap[random(ISvgData(_svgDataAddr).getTagLength(7))];
                imSeed = abi.encodePacked(imSeed, eye);
                if (7 == eye) {
                    attack = 134;
                }else if (6 == eye) {
                    attack = 121;
                }else if (5 == eye) {
                    attack = 113;
                }else if (4 == eye) {
                    attack = 108;
                }else if (3 == eye) {
                    attack = 105;
                }else if (2 == eye) {
                    attack = 103;
                }else if (1 == eye) {
                    attack = 102;
                }else if (0 == eye) {
                    attack = 101;
                }else if (18 == eye) {
                    attack = 189;
                }else if (12 == eye) {
                    defense = 189;
                }else if (11 == eye) {
                    defense = 155;
                }
            }else {
                imSeed = abi.encodePacked(imSeed, max);
            }
        }

        _powerMap[_tokenId] = power;
        _energyMap[_tokenId] = energy;
        _healthMap[_tokenId] = health;
        _defenseMap[_tokenId] = defense;
        _treasureMap[_tokenId] = treasure;
        _attackMap[_tokenId] = attack;
        _generedMap[_tokenId] = imSeed;
        return imSeed;
    }

    //域名加.0x后缀
    function tokenURI(uint256 _tokenId, string memory tokenName) public view returns (string memory)
    {
        string[13] memory parts;
        parts[0] = '<svg width="330" height="330" xmlns="http://www.w3.org/2000/svg">';
        
        bytes memory seed = _generedMap[_tokenId];
        parts[1] = ISvgData(_svgDataAddr).getBackground(_backColor[uint8(seed[0])]);    //背景
        uint8 sex = uint8(seed[1]);

        if (sex < 9) { //男
           parts[2] = ISvgData(_svgDataAddr).getStrokeByTag(8, uint8(seed[2]));

            parts[3] = ISvgData(_svgDataAddr).getStrokeByTag(9, uint8(seed[3]));

            if (uint8(seed[4]) < 250) {
                parts[4] = ISvgData(_svgDataAddr).getStrokeByTag(15, uint8(seed[4]));
            }

            uint8 ear = uint8(seed[5]);
            if (ear < 250) {
                parts[5] = ISvgData(_svgDataAddr).getStrokeByTag(14, ear);
            }

            uint8 hair = uint8(seed[6]);
            if (hair < 250) {
                parts[6] = ISvgData(_svgDataAddr).getStrokeByTag(11, hair);
            }

            uint8 element = uint8(seed[7]);
            if (element < 250) {
                parts[7] = ISvgData(_svgDataAddr).getStrokeByTag(16, element);
            }

            uint8 neck = uint8(seed[8]);
            if (neck < 250) {
                parts[8] = ISvgData(_svgDataAddr).getStrokeByTag(12, neck);
            }

            uint8 glass = uint8(seed[9]);
            if (glass < 250) {
                parts[9] = ISvgData(_svgDataAddr).getStrokeByTag(10, glass);
            }
            
            uint8 eye = uint8(seed[10]);
            if (eye < 250) {    //smoke
                parts[10] = ISvgData(_svgDataAddr).getStrokeByTag(13, eye);
            }
        }else { //女
            parts[2] = ISvgData(_svgDataAddr).getStrokeByTag(1, uint8(seed[2]));

            parts[3] = ISvgData(_svgDataAddr).getStrokeByTag(2, uint8(seed[3]));
            parts[4] = '';

            if (uint8(seed[5]) < 250) {
                parts[5] = ISvgData(_svgDataAddr).getStrokeByTag(3, uint8(seed[5]));
            }

            if (uint8(seed[6]) < 250) {
                parts[6] = ISvgData(_svgDataAddr).getStrokeByTag(5, uint8(seed[6]));
            }
            
            uint8 element = uint8(seed[7]);
            if (element < 255) {
                parts[7] = ISvgData(_svgDataAddr).getStrokeByTag(16, element);
            }
           

            uint8 neck = uint8(seed[8]);
            if (neck < 250) {
                parts[8] = ISvgData(_svgDataAddr).getStrokeByTag(6, neck);
            }

            uint8 glass = uint8(seed[9]);
            if (glass < 250) {
                parts[9] = ISvgData(_svgDataAddr).getStrokeByTag(4, glass);
            }

            uint8 eye = uint8(seed[10]);
            if (eye < 250) {    //smoke
                parts[10] = ISvgData(_svgDataAddr).getStrokeByTag(7, eye);
            }
        }

        parts[11] = '<text font-family="PingFangSC-Regular, PingFang SC" font-size="34" font-weight="normal" line-spacing="34" fill="#FFFFFF"><tspan x="23" y="291">';
        parts[12] = '</tspan></text><rect fill="#FFFFFF" x="23.5" y="28.5" width="4.5" height="21" /><rect fill="#FFFFFF" x="46" y="28.5" width="4.5" height="21" /><rect fill="#FFFFFF" x="52" y="24" width="4.5" height="25.5" /><rect fill="#FFFFFF" x="70" y="24" width="4.5" height="25.5" /><rect fill="#FFFFFF" x="56.5" y="30" width="4.5" height="4.5" /><rect fill="#FFFFFF" x="61" y="34.5" width="4.5" height="4.5" /><rect fill="#FFFFFF" x="76" y="28.5" width="4.5" height="9.5" /><rect fill="#FFFFFF" x="89.5" y="38" width="4.5" height="7" /><rect fill="#FFFFFF" x="80.5" y="24" width="13.5" height="4.5" /><rect fill="#FFFFFF" x="80.5" y="33.5" width="9" height="4.5" /><rect fill="#FFFFFF" x="76" y="45" width="18" height="4.5" /><rect fill="#FFFFFF" x="65.5" y="39" width="4.5" height="4.5" /><rect fill="#FFFFFF" x="37" y="33" width="4.5" height="16.5" /><rect fill="#FFFFFF" x="28" y="24" width="4.5" height="4.5" /><rect fill="#FFFFFF" x="32.5" y="28.5" width="4.5" height="4.5" /><rect fill="#FFFFFF" x="37" y="24" width="9" height="4.5" /></svg>';
        uint256 length = bytes(tokenName).length-3;

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3]));
        output = string(abi.encodePacked(output, parts[4], parts[5],parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9],parts[10]));
        output = string(abi.encodePacked(output,parts[11],tokenName,parts[12]));

        string memory befInfo = string(abi.encodePacked('{"name": "', tokenName, '","attributes": [{"trait_type": "Name", "value": "', tokenName,'"},{"trait_type": "Length", "value": "', length.toString()));
        befInfo = string(abi.encodePacked(befInfo, '"},{"trait_type": "Power", "value": "', _powerMap[_tokenId].toString(), '"},{"trait_type": "Energy", "value": "', _energyMap[_tokenId].toString(), '"},{"trait_type": "Health", "value": "', _healthMap[_tokenId].toString()));
        befInfo = string(abi.encodePacked(befInfo, '"},{"trait_type": "Defense", "value": "', _defenseMap[_tokenId].toString(), '"},{"trait_type": "Treasure", "value": "', _treasureMap[_tokenId].toString(), '"},{"trait_type": "Attack", "value": "', _attackMap[_tokenId].toString()));
        string memory json = Base64.encode(bytes(string(abi.encodePacked(befInfo,'"}], "description": "", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function getHealth(uint256 element) private pure returns(uint256) {
        uint256 power;
        if (10 == element) {
            power = 189;
        }else if (11 == element) {
            power = 155;
        }else if (12 == element) {
            power = 134;
        }else if (13 == element) {
            power = 121;
        }else if (14 == element) {
            power = 113;
        }else if (15 == element) {
            power = 108;
        }else if (16 == element) {
            power = 105;
        }else if (17 == element) {
            power = 103;
        }else if (18 == element) {
            power = 102;
        }else if (19 == element) {
            power = 101;
        }else {
            power = 100;
        }
        return power;
    }

    function getEnergy(uint256 element) private pure returns(uint256) {
        uint256 power;
        if (20 == element) {
            power = 189;
        }else if (21 == element) {
            power = 155;
        }else if (22 == element) {
            power = 134;
        }else if (23 == element) {
            power = 121;
        }else if (24 == element) {
            power = 113;
        }else if (25 == element) {
            power = 108;
        }else if (26 == element) {
            power = 105;
        }else if (27 == element) {
            power = 103;
        }else if (28 == element) {
            power = 102;
        }else if (29 == element) {
            power = 101;
        }else {
            power = 100;
        }
        return power;
    }

    function getPower(uint element) private pure returns(uint256) {
        uint256 power;
        if (0 == element) {
            power = 189;
        }else if (1 == element) {
            power = 155;
        }else if (2 == element) {
            power = 134;
        }else if (3 == element) {
            power = 121;
        }else if (4 == element) {
            power = 113;
        }else if (5 == element) {
            power = 108;
        }else if (6 == element) {
            power = 105;
        }else if (7 == element) {
            power = 103;
        }else if (8 == element) {
            power = 102;
        }else if (9 == element) {
            power = 101;
        }else {
            power = 100;
        }
        return power;
    }

    function random(uint number) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % number;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}