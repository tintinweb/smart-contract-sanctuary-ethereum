// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Fortress Arena Tank Base Gene Contract
 * @author Atomrigs Lab 
 */

contract TankBaseGene is Ownable {

    address public _tankNft;

    string[] private races = [
        "carrot",       //0
        "cannon",       //1
        "poseidon",     //2
        "crossbow",     //3
        "catapult",     //4
        "ionattacker",  //5
        "multi",        //6
        "missile",      //7
        "minelander",   //8
        "secwind",      //9
        "laser",        //10
        "duke",         //11
        "ironhammer",   //12
        "walkietalkie", //13
        "rainbowshell", //14
        "windblow",     //15
        "dragoncannon", //16
        "solartank",    //17
        "blazer",       //18
        "overcharger"   //19
    ];

    string[] private colors = [
        "blue",     //0
        "red",      //1
        "green",    //2
        "brown",    //3
        "yellow",   //4
        "purple"    //5
    ];

    string[] private materials = [
        "steel", //0
        "wood",  //1
        "radios" //2
    ];

    string[] private classes = [
        "normal",   //0
        "superior", //1
        "rare",     //2
        "epic",     //3
        "legendary"    //4
    ];

    string[] private elements = [
        "fire",     //0
        "wind",     //1
        "earth",    //2
        "water",    //3
        "light",    //4
        "dark"      //5
    ];

    string[] private generations = [
        "generation-0",
        "generation-1"
    ];

    string[] private founderTanks = [
        "founder-tank",
        "regular-tank"
    ];

    modifier onlyNftOrOwner() {
        require(_msgSender() == _tankNft || _msgSender() == owner(), "TankGene: caller is not the NFT tank contract address");
        _;
    }

    constructor(address _tankNftAddr) {
        _tankNft = _tankNftAddr;
    }    

    function tankNft() external view returns (address) {
        return _tankNft;
    }

    function setTankNft(address _nftAddr) external onlyOwner {
        _tankNft = _nftAddr;
    }

    function getSeed(uint _tokenId) public view onlyNftOrOwner returns (uint) {
        return uint256(keccak256(abi.encodePacked(_tokenId, uint(2021))));
    }

    function getBaseGenes(uint _tokenId) public view onlyNftOrOwner returns (uint[] memory) {
        uint[] memory genes = new uint[](7);
        if (_tokenId > 0 && _tokenId <= 120) {
            genes[0] = (_tokenId-1) % 20;
            genes[1] = colors.length - 1; 
            genes[2] = materials.length - 1;
            genes[3] = classes.length - 1;
            genes[4] = (_tokenId-1) / 20;
            genes[5] = uint(0);
            genes[6] = uint(0);
        } else {
            uint seed = getSeed(_tokenId);
            genes[0] = getRaceIdx(seed);
            genes[1] = getColorIdx(seed);
            genes[2] = getMaterialIdx(seed);
            genes[3] = getClassIdx(seed);
            genes[4] = getElementIdx(seed);
            genes[5] = getGeneration();
            genes[6] = getFounderTank(_tokenId);
        }
        return genes;
    }

    function getBaseGeneNames(uint _tokenId) public view onlyNftOrOwner returns (string[] memory) {

        uint[] memory genes = getBaseGenes(_tokenId);
        string[] memory geneNames = new string[](7);
        geneNames[0] = races[genes[0]];
        geneNames[1] = colors[genes[1]];
        geneNames[2] = materials[genes[2]];
        geneNames[3] = classes[genes[3]];
        geneNames[4] = elements[genes[4]];
        geneNames[5] = generations[genes[5]];
        geneNames[6] = founderTanks[genes[6]];
        return geneNames;
    }    

    function getImgIdx(uint _tokenId) public view onlyNftOrOwner returns (string memory) {

        uint[] memory genes = getBaseGenes(_tokenId);
        string memory race = toString(genes[0] + uint(101));
        string memory color;
        if(genes[1] <= 8) {
            color = string(abi.encodePacked("0", toString(genes[1] + uint(1))));
        } else {
            color = toString(genes[1] + uint(1));
        }
        string memory material = toString(genes[2] + uint(1));
        string memory class = toString(genes[3] + uint(1));
        string memory element = toString(genes[4] + uint(1));
        return string(abi.encodePacked(race, color, material, class, element));
    }

    function getRaceIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10) % 100;
        if (v < 10) {
            return uint(0);
        } else if (v < 19) {
            return uint(1);
        } else if (v < 28) {
            return uint(2);
        } else if (v < 36) {
            return uint(3);
        } else if (v < 43) {
            return uint(4);
        } else if (v < 49) {
            return uint(5);
        } else if (v < 54) {
            return uint(6);
        } else if (v < 59) {
            return uint(7);
        } else if (v < 64) {
            return uint(8);
        } else if (v < 69) {
            return uint(9);
        } else if (v < 73) {
            return uint(10);
        } else if (v < 77) {
            return uint(11);
        } else if (v < 81) {
            return uint(12);
        } else if (v < 85) {
            return uint(13);
        } else if (v < 88) {
            return uint(14);
        } else if (v < 91) {
            return uint(15);
        } else if (v < 94) {
            return uint(16);
        } else if (v < 96) {
            return uint(17);
        } else if (v < 98) {
            return uint(18);
        } else {
            return uint(19);
        }
    }

    function getColorIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/1000) % 100;
        if (v < 30) {
            return uint(0);
        } else if (v < 50) {
            return uint(1);
        } else if (v < 70) {
            return uint(2);
        } else if (v < 85) {
            return uint(3);
        } else if (v < 95) {
            return uint(4);
        } else {
            return uint(5);
        }
    }

    function getMaterialIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/100000) % 100;
        if (v < 50) {
            return uint(0);
        } else if (v < 80) {
            return uint(1);
        } else {
            return uint(2);
        }
    }       

    function getClassIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/10000000) % 100;
        if (v < 40) {
            return uint(0);
        } else if (v < 70) {
            return uint(1);
        } else if (v < 90) {
            return uint(2);
        } else if (v < 98) {
            return uint(3);
        } else {
            return uint(4);
        }
    }       

    function getElementIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed/1000000000) % 100;
        if (v < 20) {
            return uint(0);
        } else if (v < 40) {
            return uint(1);
        } else if (v < 60) {
            return uint(2);
        } else if (v < 80) {
            return uint(3);
        } else if (v < 94) {
            return uint(4);
        } else {
            return uint(5);
        }
    }

    function getGeneration() private pure returns (uint) {
        return uint(0); //this contract owns all genration 0 tanks only
    }

    function getFounderTank(uint _tokenId) private pure returns (uint) {
        if (_tokenId > 0 && _tokenId <= 120) {
            return uint(0);
        } else {
            return uint(1);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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