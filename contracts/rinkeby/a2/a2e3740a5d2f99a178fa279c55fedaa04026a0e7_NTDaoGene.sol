// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title National Treasure DAO (NTDAO) Gene Contract
 * @author Atomrigs Lab 
 */

interface INFT {
    function refundState(uint256 tokenId_) external view returns (bool);
}


contract NTDaoGene is Ownable {

    address public _nftAddr;

    string[] private classes = [
        "Common",           //0
        "Rare",             //1
        "Super Rare",       //2
        "Treasure",         //3
        "National Treasure" //4
    ];

    string[] private elements = [
        "Water",   //0
        "Wood",    //1
        "Fire",    //2
        "Earth",   //3
        "Metal"    //4
    ];

    string[] private branches = [
        "Rat",     //0
        "Ox",      //1
        "Tiger",   //2
        "Rabbit",  //3
        "Dragon",  //4        
        "Snake",   //5
        "Horse",   //6
        "Goat",    //7
        "Monkey",  //8
        "Rooster", //9
        "Dog",     //10
        "Pig"      //11        
    ];

    string[] private divisions = [
        "Geumgang",  //0
        "Seorak",    //1
        "Jiri",      //2
        "Halla",     //3
        "Baekdu"     //4
    ];    

    string[] private countries = [
        "Joseon",     //0
        "Goryeo",     //1
        "Balhae",     //2
        "Silla",      //3
        "Gaya",       //4        
        "Baekje",     //5
        "Goguryeo",    //6
        "Gojoseon"    //7
    ];

    modifier onlyNftOrOwner() {
        require(_msgSender() == _nftAddr || _msgSender() == owner(), "TankGene: caller is not the NFT tank contract address");
        _;
    }

    constructor(address nftAddr_) {
        _nftAddr = nftAddr_;
    }    

    function getNftAddr() external view returns (address) {
        return _nftAddr;
    }

    function setNftAddr(address nftAddr_) external onlyOwner {
        _nftAddr = nftAddr_;
    }

    function getSeed(uint _tokenId) public view onlyNftOrOwner returns (uint) {
        return uint256(keccak256(abi.encodePacked(_tokenId, uint(2022))));
    }

    function getBaseGenes(uint _tokenId) public view onlyNftOrOwner returns (uint[] memory) {
        uint[] memory genes = new uint[](5);
        uint seed = getSeed(_tokenId);
        genes[0] = getClassIdx(seed);
        genes[1] = getElementIdx(seed);
        genes[2] = getBranchIdx(seed);
        genes[3] = getDivisionIdx(seed);
        genes[4] = getCountryIdx(seed);
        return genes;
    }

    function getBaseGeneNames(uint _tokenId) public view onlyNftOrOwner returns (string[] memory) {

        uint[] memory genes = getBaseGenes(_tokenId);
        string[] memory geneNames = new string[](5);
        geneNames[0] = classes[genes[0]];
        geneNames[1] = elements[genes[1]];
        geneNames[2] = branches[genes[2]];
        geneNames[3] = divisions[genes[3]];
        geneNames[4] = countries[genes[4]];        
        return geneNames;
    }    

    function getClassIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10) % 1000;
        if (v < 450) {
            return uint(0);
        } else if (v < 800) {
            return uint(1);
        } else if (v < 970) {
            return uint(2);
        } else if (v < 998) {
            return uint(3);
        } else {
            return uint(4);
        }
    }      

    function getElementIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10000) % 100;
        if (v < 40) {
            return uint(0);
        } else if (v < 70) {
            return uint(1);
        } else if (v < 85) {
            return uint(2);
        } else if (v < 95) {
            return uint(3);
        } else {
            return uint(4);
        }
    }

    function getBranchIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/1000000) % 100;
        if (v < 18) {
            return uint(0);
        } else if (v < 31) {
            return uint(1);
        } else if (v < 43) {
            return uint(2);
        } else if (v < 53) {
            return uint(3);
        } else if (v < 62) {
            return uint(4);
        } else if (v < 70) {
            return uint(5);
        } else if (v < 78) {
            return uint(6);
        } else if (v < 86) {
            return uint(7);
        } else if (v < 91) {
            return uint(8);
        } else if (v < 95) {
            return uint(9);
        } else if (v < 98) {
            return uint(10);
        } else {
            return uint(11);
        }
    }

    function getDivisionIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/100000000) % 100;
        if (v < 40) {
            return uint(0);
        } else if (v < 70) {
            return uint(1);
        } else if (v < 90) {
            return uint(2);
        } else if (v < 99) {
            return uint(3);
        } else {
            return uint(4);
        }
    }

    function getCountryIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10000000000) % 100;
        if (v < 50) {
            return uint(0);
        } else if (v < 75) {
            return uint(1);
        } else if (v < 83) {
            return uint(2);
        } else if (v < 91) {
            return uint(3);
        } else if (v < 94) {
            return uint(4);
        } else if (v < 97) {
            return uint(5);
        } else if (v < 99) {
            return uint(6);
        } else {
            return uint(7);
        }
    }

    function getDescription() external pure returns (string memory) {
        string memory desc = "The National Treasure DAO (NTDAO) is a project designed to protect the cultural heritage of Korea as a shared property of citizens and spread its meaning to the public. The name DAO (Decentralized Autonomous Organization) was given, because this project is not for the benefit of a particular company or individual, but to express the voluntary participation of many citizens and communities to achieve the goal of the organization through decentralized decision-making. The process of carrying out this project itself is also the goal of contemplating, sharing, and working together on the true meaning of cultural heritage protection.";
        return desc;
    }

    function getAttrs(uint _tokenId) external view returns (string memory) {

        INFT nft = INFT(_nftAddr);
        string memory isRefunded;
        if(nft.refundState(_tokenId)) {
            isRefunded = 'Y';
        } else {
            isRefunded = 'N';
        }

        string[] memory genes  = getBaseGeneNames(_tokenId);
        string[13] memory parts;

        parts[0] = '[{"trait_type": "class", "value": "';
        parts[1] = genes[0];
        parts[2] = '"}, {"trait_type": "element", "value": "';
        parts[3] = genes[1];
        parts[4] = '"}, {"trait_type": "branch", "value": "';        
        parts[5] = genes[2];
        parts[6] = '"}, {"trait_type": "division", "value": "';        
        parts[7] = genes[3];
        parts[8] = '"}, {"trait_type": "country", "value": "';        
        parts[9] = genes[4];
        parts[10] = '"}, {"trait_type": "isRefunded", "value": "';  
        parts[11] = isRefunded;      
        parts[12] = '"}, {"trait_type": "generation", "value": "Generation-0"}]';        

        string memory attrs = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        attrs = string(abi.encodePacked(attrs, parts[9], parts[10], parts[11], parts[12]));
        return attrs;
    }

    function getLogo() internal pure returns (string memory) {
        string memory gtag = '<g><path class="st1" d="M355.81,130.43c-2.8,1.28-7.2,1.89-10.38,0.44c-6.49-2.95-5.66-12.49-4.94-18.22c0.22-1.77-2.29-3.2-3.69-2.11 c-4.82,3.69-11.04,5.9-16.87,7.33c-15.91,3.91-32.51,0.98-47.31-5.53c-1.35-0.59-3.27-0.25-3.61,1.48 c-0.89,4.28-2.66,8.53-5.02,12.2c-4.8,7.48-12.12,10.16-20.58,7.25c-2.66-0.91-3.96,2.68-2.16,4.23c-0.15,0.69,0,1.4,0.74,2.02 c5.14,4.33,11.19,7.87,17.51,10.13c4.94,1.77,9.74,2.21,14.93,1.65c4.08-0.44,8.39-0.84,12.39,0.27c2.68,0.74,5.16,1.94,8.02,2.07 c5.04,0.25,10.06-1.87,14.95-2.75c9.32-1.7,18.32,2.83,27.61,0.12c7.77-2.26,14.95-8.02,20.39-13.89c0.71-0.76,0.76-1.65,0.52-2.41 h0.02C361.18,133.36,358.67,129.13,355.81,130.43z M338.43,145.41c-4.35,1.84-9.32,2.02-13.94,1.23c-3.79-0.64-7.38-1.5-11.26-1.18 c-5.14,0.42-9.96,2.09-15,2.98c-3.22,0.57-5.73-0.22-8.73-1.2c-2.8-0.91-5.66-1.3-8.61-1.28c-5.09,0-10.08,1.33-15.15,0.32 c-5.56-1.11-11.07-3.69-15.91-6.96c6.74,0.02,12.84-3.15,17.26-9.17c2.66-3.61,4.67-7.94,5.93-12.34 c14.9,6.05,31.08,8.66,46.97,5.11c5.07-1.13,10.5-2.85,15.2-5.48c-0.22,6.89,1.18,14.43,7.75,17.7c2.63,1.3,5.56,1.67,8.48,1.4 C347.6,140.14,343.2,143.39,338.43,145.41z"/><path class="st1" d="M280.91,123.23c-1.28,0.05-2.51,1.08-2.46,2.46c0,0.3,0,0.59-0.02,0.89c0,0.15-0.02,0.3-0.02,0.42 c0,0.05,0,0.1-0.02,0.15c-0.07,0.39-0.12,0.79-0.22,1.18c-0.1,0.49-0.25,0.98-0.39,1.45c-0.1,0.27-0.17,0.54-0.27,0.81 c-0.05,0.12-0.1,0.22-0.15,0.34c0,0.02,0,0-0.02,0.02c-0.27,0.59-0.57,1.18-0.91,1.72c-0.17,0.3-0.37,0.59-0.57,0.86 c-0.02,0.02-0.05,0.05-0.05,0.1c-0.1,0.15-0.22,0.27-0.32,0.39c-0.57,0.66-1.18,1.28-1.84,1.82c-0.05,0.05-0.12,0.1-0.17,0.15 c-0.2,0.12-0.37,0.27-0.57,0.39c-0.47,0.32-0.93,0.59-1.4,0.86c-1.13,0.61-1.6,2.26-0.89,3.37c0.74,1.16,2.16,1.55,3.37,0.89 c5.46-3,8.8-8.46,9.37-14.58c0.05-0.42,0.07-0.84,0.05-1.23C283.32,124.41,282.27,123.18,280.91,123.23z M278.36,127.28 C278.33,127.53,278.33,127.43,278.36,127.28L278.36,127.28z"/><path class="st1" d="M293.5,125.51c-1.38,0.44-1.92,1.65-1.72,3c-0.02-0.2-0.07-0.64-0.07-0.47c0,0.1,0.02,0.22,0.05,0.32 c0.05,0.39,0.07,0.79,0.1,1.18c0.07,1.23,0.05,2.46-0.05,3.66c-0.02,0.17-0.05,0.37-0.05,0.54c0,0.02,0,0.05,0,0.07 c-0.05,0.37-0.12,0.74-0.2,1.11c-0.15,0.76-0.37,1.52-0.64,2.24c-0.05,0.1-0.07,0.22-0.12,0.32c-0.05,0.12-0.07,0.17-0.07,0.15 c-0.05,0.07-0.07,0.15-0.1,0.2c-0.17,0.34-0.37,0.69-0.59,1.03c-0.1,0.15-0.22,0.42-0.37,0.54c-0.02,0.02-0.05,0.05-0.05,0.05 c-0.3,0.34-0.64,0.66-0.98,0.96c-0.98,0.84-0.93,2.63,0,3.47c1.06,0.96,2.43,0.89,3.47,0c3.02-2.58,4.2-6.57,4.57-10.38 c0.22-2.09,0.15-4.2-0.17-6.3C296.33,125.93,294.66,125.12,293.5,125.51z M290.72,137.64c0-0.02,0.05-0.12,0.12-0.27 C290.85,137.41,290.77,137.51,290.72,137.64z"/><path class="st1" d="M312.9,137.61c0.07,0.1,0.1,0.2-0.1-0.1l-0.02-0.02c0,0,0.02,0,0.02,0.02c-0.2-0.3-0.37-0.59-0.54-0.91 c-0.05-0.12-0.12-0.22-0.17-0.34c0,0,0,0,0-0.02c-0.1-0.32-0.22-0.64-0.32-0.98c-0.07-0.3-0.15-0.61-0.2-0.93 c-0.02-0.17-0.05-0.34-0.07-0.49c0,0.02,0,0.05,0.02,0.07c-0.07-0.61-0.1-1.23-0.07-1.84c0-0.57,0.02-1.13,0.07-1.67 c0.02-0.2,0.05-0.37,0.05-0.57c0-0.07,0.02-0.12,0.02-0.2c0.07-0.42,0.15-0.81,0.25-1.23c0.32-1.25-0.39-2.73-1.72-3.02 c-1.28-0.3-2.68,0.39-3.02,1.72c-1.2,4.72-0.89,10.65,2.63,14.34c0.89,0.93,2.58,0.96,3.47,0c0.91-1.01,0.96-2.48,0-3.47 C313.15,137.91,313,137.73,312.9,137.61z"/><path class="st1" d="M311.5,133.9L311.5,133.9C311.53,134.1,311.63,134.44,311.5,133.9z"/><path class="st1" d="M312.81,137.51c0.02,0.02,0.05,0.05,0.1,0.1C312.86,137.56,312.83,137.51,312.81,137.51L312.81,137.51 L312.81,137.51z"/><path class="st1" d="M330.81,137.29c-0.3-0.15-0.59-0.32-0.89-0.52c-0.17-0.1-0.32-0.22-0.49-0.32c0,0-0.02-0.02-0.05-0.02 s0,0-0.02-0.02c-0.49-0.42-0.96-0.86-1.38-1.38c-0.02-0.02-0.05-0.07-0.07-0.1c-0.05-0.1-0.17-0.22-0.22-0.3 c-0.17-0.27-0.34-0.52-0.52-0.81c-0.15-0.25-0.27-0.49-0.42-0.76c-0.07-0.15-0.15-0.3-0.22-0.44c0-0.02-0.02-0.05-0.05-0.07 c-0.02-0.05-0.1-0.22-0.12-0.27c-0.05-0.12-0.1-0.25-0.15-0.37c-0.1-0.27-0.17-0.54-0.27-0.81c-0.15-0.52-0.27-1.01-0.39-1.52 c-0.05-0.22-0.07-0.44-0.12-0.66c-0.02-0.07-0.02-0.15-0.05-0.25c-0.02-0.32-0.07-0.64-0.1-0.96c-0.02-0.39-0.05-0.76-0.02-1.16 c0.05-1.28-1.16-2.51-2.46-2.46c-1.38,0.05-2.41,1.08-2.46,2.46c-0.05,1.35,0.15,2.73,0.39,4.03c0.52,2.73,1.65,5.31,3.37,7.5 c1.11,1.43,2.56,2.61,4.16,3.44c1.13,0.59,2.73,0.32,3.37-0.89C332.28,139.51,332.01,137.91,330.81,137.29z M327.78,134.81 C327.71,134.71,327.73,134.73,327.78,134.81L327.78,134.81z"/></g>';
        return gtag;
    }
    
    function getImg(uint _tokenId) external view returns (string memory) {
        string[] memory genes  = getBaseGeneNames(_tokenId);
        string[14] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 600 600" style="background-color: #f8f3ef;"><style> .base {font-family: cursive, fantasy; fill: #3D2818; font-size:200%; letter-spacing: 0em;} .img{text-aline:center;} </style>';
        parts[1] = getLogo();
        parts[2] = '<text x="50%" y="220" dominant-baseline="middle" text-anchor="middle" class="base" style="fill: #3D2818; font-size:350%;"> &#xAD6D;&#xBCF4;  DAO</text>';
        parts[3] = '<text x="50%" y="300" dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[4] = genes[0];
        parts[5] = '</text><text x="50%" y="350" dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[6] = genes[1];
        parts[7] = '</text><text x="50%" y="400" dominant-baseline="middle" text-anchor="middle" class="base">';
        parts[8] = genes[2];
        parts[9] = '</text><text x="50%" y="450" dominant-baseline="middle" text-anchor="middle" class="base">';        
        parts[10] = genes[3];
        parts[11] = '</text><text x="50%" y="500" dominant-baseline="middle" text-anchor="middle" class="base">';        
        parts[12] = genes[4];
        parts[13] = '</text></svg>';
        string memory attrs = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        attrs = string(abi.encodePacked(attrs, parts[9], parts[10], parts[11], parts[12], parts[13]));

        string memory img = string(abi.encodePacked('data:image/svg+xml;base64,',Base64.encode(bytes(attrs))));
        return img;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}