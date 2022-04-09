// SPDX-License-Identifier: GPL-3.0

/// @title The Beans NFT descriptor

/*********************************                                         
,-----.  ,------.  ,---.  ,--.  ,--. ,---.   
|  |) /_ |  .---' /  O  \ |  ,'.|  |'   .-'  
|  .-.  \|  `--, |  .-.  ||  |' '  |`.  `-.  
|  '--' /|  `---.|  | |  ||  | `   |.-'    | 
`------' `------'`--' `--'`--'  `--'`-----'                                                       
*********************************/

pragma solidity ^0.8.6;

import { Ownable } from "Ownable.sol";
import { Strings } from "Strings.sol";
import { IBeansDescriptor } from "IBeansDescriptor.sol";
import { IBeansSeeder } from "IBeansSeeder.sol";
import { IBaseBean } from "IBaseBean.sol";
import { IBeanVibe } from "IBeanVibe.sol";
import { IHelmet } from "IHelmet.sol";
import { IGear } from "IGear.sol";
import "Base64.sol";

contract BeansDescriptor is IBeansDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Base URI
    string public baseURI;

    // Base URI
    address public baseBeanAddy;


    // Base URI
    address public beanVibeAddy;


    // Bean Class One
    string[] public classOne;

    // Bean Class Two
    string[] public classTwo;

    uint256[] public beanSize;

    // Small Helmet Libraries
    address[] public smallHelmetLibraries;

     // Big Helmet Libraries
    address[] public bigHelmetLibraries;


    // Small Helmet Libraries
    address[] public gearLibraries;

    // Noun Color Palettes (Index => Hex Colors)
    mapping(address => uint256) public gearCount;


    uint256[] public beanVibes;


    // Noun Color Palettes (Index => Hex Colors)
    mapping(address => uint256) public smallHelmetCounts;

    // Noun Color Palettes (Index => Hex Colors)
    mapping(address => uint256) public bigHelmetCounts;


    /**
     * @notice Set the nounders DAO.
     * @dev Only callable by the nounders DAO when not locked.
     */
    function setBaseBean(address _basebean) external onlyOwner {
        baseBeanAddy = _basebean;

    }

    /**
     * @notice Set the nounders DAO.
     * @dev Only callable by the nounders DAO when not locked.
     */
    function setBeanVibe(address _beanvibe) external onlyOwner {
        beanVibeAddy = _beanvibe;

    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classOneCount() external view override returns (uint256) {
        return classOne.length;
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addClassOne(string memory _color) external {
        classOne.push(_color);
    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classTwoCount() external view override returns (uint256) {
        return classTwo.length;
    }


     /**
     * @notice Add a single color to a color palette.
     */
    function _addClassTwo(string memory _color) external {
        classTwo.push(_color);
    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classSizeCount() external view override returns (uint256) {
        return beanSize.length;
    }


    /**
     * @notice Add a single color to a color palette.
     */
    function _addClassSize(uint256 _size) external {
        beanSize.push(_size);
    }


    /**
     * @notice Add a single color to a color palette.
     */
    function _addClassVibe(uint256 _size) external {
        beanVibes.push(_size);
    }



    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classHelmetCount(uint256 sizeCount, uint256 helmetLibraryId) external view override returns (uint256) {
        if (sizeCount > 0 ){
            address helmetAddress = smallHelmetLibraries[helmetLibraryId];
            return(smallHelmetCounts[helmetAddress]);
        } else {
            address helmetAddress = bigHelmetLibraries[helmetLibraryId];
            return(bigHelmetCounts[helmetAddress]);
        }

    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classGearLibraryCount() external view override returns (uint256) {
        return gearLibraries.length;

    }

    


    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classHelmetLibraryCount(uint256 sizeCount) external view override returns (uint256) {
        if (sizeCount > 0 ){
            return(bigHelmetLibraries.length);
        } else {
            return(smallHelmetLibraries.length);
        }

    }



    /**
     * @notice Add a single color to a color palette.
     */
    function _addSmallHelmet(address smallHelmetAddress, uint8 smallHelmetCount) external {
        smallHelmetLibraries.push(smallHelmetAddress);
        smallHelmetCounts[smallHelmetAddress] = smallHelmetCount;
    }


    /**
     * @notice Add a single color to a color palette.
     */
    function _addBigHelmet(address bigHelmetAddress, uint8 bigHelmetCount) external {
        bigHelmetLibraries.push(bigHelmetAddress);
        bigHelmetCounts[bigHelmetAddress] = bigHelmetCount;
    }


    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classGearCount(uint256 gearLibraryId) external view override returns (uint256) {

            address gearAddress = gearLibraries[gearLibraryId];
            return(gearCount[gearAddress]);
    }


    /**
     * @notice Add a single color to a color palette.
     */
    function _addGear(address gearAddress, uint256 gearC) external {
        gearLibraries.push(gearAddress);
        gearCount[gearAddress] = (gearC);
    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function classVibeCount() external view override returns (uint256) {
        return beanVibes.length;
    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function pullHelmetSvg(string memory clsOne, string memory clsTwo, uint256 sizeId, uint256 helmetLibraryId, uint256 itemId) public view returns (string memory, string memory) {
        if (sizeId > 0 ) {
            address helmetAddress = bigHelmetLibraries[helmetLibraryId];
            return IHelmet(helmetAddress).getHelmetSvg(clsOne, clsTwo, itemId);
        } else {
            address helmetAddress = smallHelmetLibraries[helmetLibraryId];
            return IHelmet(helmetAddress).getHelmetSvg(clsOne, clsTwo, itemId);
        }


        
    }


    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function pullGearSvg(string memory clsOne, string memory clsTwo, uint256 gearLibraryId, uint256 itemId) public view returns (string memory, string memory) {

            address gearAddress = gearLibraries[gearLibraryId];
            return IGear(gearAddress).getGearSvg(clsOne, clsTwo, itemId);

    }


    /**
     * @notice Given a token ID and seed, construct a token URI for an official Beans DAO noun.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IBeansSeeder.Seed memory seed) external override view returns (string memory) {
        return dataURI(tokenId, seed);

    }


    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Beans DAO noun.
     */
    function dataURI(uint256 tokenId, IBeansSeeder.Seed memory seed) public view override returns (string memory) {
        string memory beanId = tokenId.toString();
        string memory clsOne = classOne[seed.classOne];
        string memory clsTwo = classTwo[seed.classTwo];
        string memory current_date = block.timestamp.toString();


        (string memory helmetTitle, string memory helemtSvg) = pullHelmetSvg(clsOne, clsTwo, seed.size, seed.helmetLib, seed.helmet);
        (string memory gearTitle, string memory gearSvg) = pullGearSvg(clsOne, clsTwo, seed.gearLib, seed.gear);
        string memory baseSvg = IBaseBean(baseBeanAddy).getBaseSvg(clsOne, clsTwo, seed.size);
        string memory vibeSvg = IBeanVibe(beanVibeAddy).getVibe(clsOne, clsTwo, seed.vibe);
        string memory finalSvg = string(abi.encodePacked(baseSvg, gearSvg, helemtSvg, vibeSvg));
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bean ', 
                        beanId,
                        '", "description": "Bean ',
                        beanId,
                        ' is a member of the Beans DAO", "attributes": [{"display_type": "date", "trait_type": "Birthday", "value": "',
                        current_date,
                        '"}, {"trait_type": "Helmet", "value": "',
                        helmetTitle,
                        '"}, {"trait_type": "Gear", "value": "',
                        gearTitle,
                        '"}], "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        
        return (finalTokenUri);
    }

    }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeansDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IBeansSeeder } from "IBeansSeeder.sol";

interface IBeansDescriptor {
    
    // gets the libray for the item and the item count of the specific library 
    
    function classOneCount() external view returns (uint256); //yes

    function classTwoCount() external view returns (uint256); //yes

    function classSizeCount() external view returns (uint256);

    function classHelmetLibraryCount(uint256 libIndex) external view returns (uint256);

    function classHelmetCount(uint256 sizeIndex, uint256 libraryIndex) external view returns (uint256);

    function classGearLibraryCount() external view returns (uint256);

    function classGearCount(uint256 libraryIndex) external view returns (uint256);

    function classVibeCount() external view returns (uint256);

    function tokenURI(uint256 tokenId, IBeansSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IBeansSeeder.Seed memory seed) external view returns (string memory);


}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeansSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IBeansDescriptor } from "IBeansDescriptor.sol";

interface IBeansSeeder {
    struct Seed {
        uint256 classOne;
        uint256 classTwo;
        uint256 size;
        uint256 helmetLib;
        uint256 helmet;
        uint256 gearLib;
        uint256 gear;
        uint256 vibe;

    }

    function generateSeed(uint256 beanId, IBeansDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeansDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;


interface IBaseBean {
    
     function getBaseSvg(string memory classOne, string memory classTwo, uint256 sizeId) external view returns (string memory );
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeansDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;


interface IBeanVibe {
    
     function getVibe(string memory classOne, string memory classTwo, uint256 vibeId) external view returns (string memory );
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeansDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;


interface IHelmet {
    


     function getHelmetSvg(string memory classOne, string memory classTwo, uint256 itemId) external view returns (string memory, string memory);

     function getLibraryCount() external view returns (uint256);


}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BeansDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;


interface IGear {
    

     function getGearSvg(string memory classOne, string memory classTwo, uint256 rand) external pure returns (string memory, string memory);

     function getLibraryCount() external view returns (uint256);


}

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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