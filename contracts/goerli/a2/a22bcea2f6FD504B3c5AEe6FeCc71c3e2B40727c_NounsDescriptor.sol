// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns NFT descriptor

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

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { Base64 } from 'base64-sol/base64.sol';


contract NounsDescriptor is INounsDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Noun parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // MATH Hat Art Styles
    string[] public override artstyles;

    // MATH Hat Backgrounds
    bytes[] public override backgrounds;

    // MATH Hat Base Colors
    bytes[] public override basecolors;
    
    // MATH Hat Visors (PNG Bytes)
    bytes[] public override visors;

    // MATH Hat Letters (PNG Bytes)
    bytes[] public override mathletters;

    // MATH Hat Accessories (PNG Bytes)
    bytes[] public override accessories;

    // MATH Hat Flair (PNG Bytes)
    bytes[] public override flair;


    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available MATH Hat Art Styles
     */

     function artStyleCount() external view override returns (uint256) {
        return artstyles.length;
     }
    /**
     * @notice Get the number of available MATH Hat `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available MATH Hat `basecolors`.
     */
    function baseColorCount() external view override returns (uint256) {
        return basecolors.length;
    }

    /**
     * @notice Get the number of available MATH Hat `visors`.
     */
    function visorCount() external view override returns (uint256) {
        return visors.length;
    }

    /**
     * @notice Get the number of available MATH Hat `mathletters`.
     */
    function mathlettersCount() external view override returns (uint256) {
        return mathletters.length;
    }

    /**
     * @notice Get the number of available MATH Hat `accessories`.
     */
    function accessoriesCount() external view override returns (uint256) {
        return accessories.length;
    }

    /**
     * @notice Get the number of available MATH Hat `flair`.
     */
    function flairCount() external view override returns (uint256) {
        return flair.length;
    }


    /**
     * @notice Batch add MATH Hat backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(bytes[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add MATH Hat basecolors.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBaseColors(bytes[] calldata _basecolors) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _basecolors.length; i++) {
            _addBaseColor(_basecolors[i]);
        }
    }

    /**
     * @notice Batch add MATH Hat visors.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyVisors(bytes[] calldata _visors) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _visors.length; i++) {
            _addVisor(_visors[i]);
        }
    }

    /**
     * @notice Batch add MATH Hat mathletters.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMATHletters(bytes[] calldata _mathletters) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _mathletters.length; i++) {
            _addmathletters(_mathletters[i]);
        }
    }

    /**
     * @notice Batch add MATH Hat accessories.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyAccessories(bytes[] calldata _accessories) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addAccessory(_accessories[i]);
        }
    }

    /**
     * @notice Batch add MATH Hat flair.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyFlair(bytes[] calldata _flair) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _flair.length; i++) {
            _addFlair(_flair[i]);
        }
    }    

    /**
     * @notice Add an art style
     */
    function addArtStyle(string calldata _artstyle) external override onlyOwner {
        _addArtStyle(_artstyle);
    }

    /**
     * @notice Add a Noun background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(bytes calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a MATH Hat Base Color
     * @dev This function can only be called by the owner when not locked.
     */
    function addBaseColor(bytes calldata _basecolor) external override onlyOwner whenPartsNotLocked {
        _addBaseColor(_basecolor);
    }

    /**
     * @notice Add a MATH Hat Visor.
     * @dev This function can only be called by the owner when not locked.
     */
    function addVisor(bytes calldata _visor) external override onlyOwner whenPartsNotLocked {
        _addVisor(_visor);
    }


    /**
     * @notice Add MATH Hat mathletters.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMATHletters(bytes calldata _mathletters) external override onlyOwner whenPartsNotLocked {
        _addmathletters(_mathletters);
    }

    /**
     * @notice Add a MATH Hat accessory.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessory(bytes calldata _accessory) external override onlyOwner whenPartsNotLocked {
        _addAccessory(_accessory);
    }


    /**
     * @notice Add MATH Hat mathletters.
     * @dev This function can only be called by the owner when not locked.
     */
    function addFlair(bytes calldata _flair) external override onlyOwner whenPartsNotLocked {
        _addFlair(_flair);
    }

    /**
     * @notice Lock all MATH Hat parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Nouns DAO noun.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Nouns DAO noun.
     */
    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) public view override returns (string memory) {
        string memory nounId = tokenId.toString();
        string memory name = string(abi.encodePacked('MATH Hat ', nounId));
        string memory description = string(abi.encodePacked('MATH Hat ', nounId, ' is a member of the FWD_DAO'));

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        INounsSeeder.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            artstyle: artstyles[seed.artstyle]
        });
        return constructTokenURI(params, seed);
    }

    /**
     * @notice Add a MATH Hat art style
     */
    function _addArtStyle(string calldata _artstyle) internal {
        artstyles.push(_artstyle);
    }
    
    /**
     * @notice Add a MATH Hat background.
     */
    function _addBackground(bytes calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a MATH Hat body.
     */
    function _addBaseColor(bytes calldata _basecolor) internal {
        basecolors.push(_basecolor);
    }

    /**
     * @notice Add a MATH Hat head.
     */
    function _addVisor(bytes calldata _visor) internal {
        visors.push(_visor);
    }

    /**
     * @notice Add MATH Hat mathletters.
     */
    function _addmathletters(bytes calldata _mathletters) internal {
        mathletters.push(_mathletters);
    }

    /**
     * @notice Add a MATH Hat accessory.
     */
    function _addAccessory(bytes calldata _accessory) internal {
        accessories.push(_accessory);
    }

    /**
     * @notice Add MATH Hat Flair
     */
     function _addFlair(bytes calldata _flair) internal {
        flair.push(_flair);
     }

    /**
     * @notice Get all Noun parts for the passed `seed`.
     */
    function _getPartsForSeed(INounsSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](6);
        _parts[0] = backgrounds[seed.background];
        _parts[1] = basecolors[seed.basecolor];
        _parts[2] = visors[seed.visor];
        _parts[3] = mathletters[seed.mathletters];
        _parts[4] = accessories[seed.accessory];
        _parts[5] = flair[seed.flair];
        return _parts;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(NFTDescriptor.TokenURIParams memory params, INounsSeeder.Seed memory seed)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(seed);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    } 

   /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(INounsSeeder.Seed memory seed) public view override returns (string memory svg) {

        bytes[] memory parts = _getPartsForSeed(seed);


        svg = Base64.encode(
            bytes(
                abi.encodePacked(
                    NFTDescriptor.HEADER,
                    NFTDescriptor.wrapTag(Base64.encode(parts[0])),
                    NFTDescriptor.wrapTag(Base64.encode(parts[1])),
                    NFTDescriptor.wrapTag(Base64.encode(parts[2])),
                    NFTDescriptor.wrapTag(Base64.encode(parts[3])),
                    NFTDescriptor.wrapTag(Base64.encode(parts[4])),
                    NFTDescriptor.wrapTag(Base64.encode(parts[5])),
                    NFTDescriptor.FOOTER
                )
            )
        );
        return svg;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

/// @title Interface for NounsDescriptor

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

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function artstyles(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (bytes memory);

    function basecolors(uint256 index) external view returns (bytes memory);

    function visors(uint256 index) external view returns (bytes memory);

    function mathletters(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function flair(uint256 index) external view returns (bytes memory);

    function artStyleCount() external view returns (uint256);

    function backgroundCount() external view returns (uint256);

    function baseColorCount() external view returns (uint256);

    function visorCount() external view returns (uint256);

    function mathlettersCount() external view returns (uint256);

    function accessoriesCount() external view returns (uint256);

    function flairCount() external view returns (uint256);

    function addManyBackgrounds(bytes[] calldata backgrounds) external;

    function addManyBaseColors(bytes[] calldata bodies) external;

    function addManyVisors(bytes[] calldata heads) external;

    function addManyMATHletters(bytes[] calldata glasses) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyFlair(bytes[] calldata flair) external;

    function addArtStyle(string calldata artstyle) external;

    function addBackground(bytes calldata background) external;

    function addBaseColor(bytes calldata basecolor) external;

    function addVisor(bytes calldata visor) external;

    function addMATHletters(bytes calldata mathletters) external;

    function addAccessory(bytes calldata accessory) external;

    function addFlair(bytes calldata flair) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

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

import { INounsDescriptor } from './INounsDescriptor.sol';

interface INounsSeeder {
    struct Seed {
        uint48 artstyle;
        uint48 background;
        uint48 basecolor;
        uint48 visor;
        uint48 mathletters;
        uint48 accessory;
        uint48 flair;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

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

import { INounsSeeder } from '../interfaces/INounsSeeder.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string artstyle;
    }

        struct SVGParams {
        bytes[] parts;
        string artstyle;
    }

    string internal constant HEADER =
        '<svg id="hat" width="100%" height="100%" version="1.1" viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string internal constant FOOTER =
        "<style>#hat{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>";
   
    function wrapTag(string memory uri) internal pure returns (string memory) {
    return
        string(
            abi.encodePacked(
                '<image x="1" y="1" width="500" height="500" image-rendering="crisp-edges" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                uri,
                '"/>'
            )
        );
    }   
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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