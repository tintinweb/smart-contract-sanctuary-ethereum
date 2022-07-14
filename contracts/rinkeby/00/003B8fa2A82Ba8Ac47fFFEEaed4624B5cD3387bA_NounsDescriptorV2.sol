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
import { INounsDescriptorV2 } from './interfaces/INounsDescriptorV2.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { NFTDescriptorV2 } from './libs/NFTDescriptorV2.sol';
import { ISVGRenderer } from './interfaces/ISVGRenderer.sol';
import { INounsArt } from './interfaces/INounsArt.sol';
import { IInflator } from './interfaces/IInflator.sol';

contract NounsDescriptorV2 is INounsDescriptorV2, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    /// @notice The contract responsible for holding compressed Noun art
    INounsArt public art;

    /// @notice The contract responsible for constructing SVGs
    ISVGRenderer public renderer;

    /// @notice Whether or not new Noun parts can be added
    bool public override arePartsLocked;

    /// @notice Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    /// @notice Base URI, used when isDataURIEnabled is false
    string public override baseURI;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    constructor(INounsArt _art, ISVGRenderer _renderer) {
        art = _art;
        renderer = _renderer;
    }

    /**
     * @notice Set the Noun's art contract.
     * @dev Only callable by the owner when not locked.
     */
    function setArt(INounsArt _art) external onlyOwner whenPartsNotLocked {
        art = _art;

        emit ArtUpdated(_art);
    }

    /**
     * @notice Set the SVG renderer.
     * @dev Only callable by the owner.
     */
    function setRenderer(ISVGRenderer _renderer) external onlyOwner {
        renderer = _renderer;

        emit RendererUpdated(_renderer);
    }

    /**
     * @notice Set the art contract's `descriptor`.
     * @param descriptor the address to set.
     * @dev Only callable by the owner.
     */
    function setArtDescriptor(address descriptor) external onlyOwner {
        art.setDescriptor(descriptor);
    }

    /**
     * @notice Set the art contract's `inflator`.
     * @param inflator the address to set.
     * @dev Only callable by the owner.
     */
    function setArtInflator(IInflator inflator) external onlyOwner {
        art.setInflator(inflator);
    }

    /**
     * @notice Get the number of available Noun `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return art.backgroundsCount();
    }

    /**
     * @notice Get the number of available Noun `bodies`.
     */
    function bodyCount() external view override returns (uint256) {
        return art.getBodiesTrait().storedImagesCount;
    }

    /**
     * @notice Get the number of available Noun `accessories`.
     */
    function accessoryCount() external view override returns (uint256) {
        return art.getAccessoriesTrait().storedImagesCount;
    }

    /**
     * @notice Get the number of available Noun `heads`.
     */
    function headCount() external view override returns (uint256) {
        return art.getHeadsTrait().storedImagesCount;
    }

    /**
     * @notice Get the number of available Noun `glasses`.
     */
    function glassesCount() external view override returns (uint256) {
        return art.getGlassesTrait().storedImagesCount;
    }

    /**
     * @notice Batch add Noun backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        art.addManyBackgrounds(_backgrounds);
    }

    /**
     * @notice Add a Noun background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        art.addBackground(_background);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette.
     * @param paletteIndex the identifier of this palette
     * @param palette byte array of colors. every 3 bytes represent an RGB color. max length: 256 * 3 = 768
     * @dev This function can only be called by the owner when not locked.
     */
    function setPalette(uint8 paletteIndex, bytes calldata palette) external override onlyOwner whenPartsNotLocked {
        art.setPalette(paletteIndex, palette);
    }

    /**
     * @notice Add a batch of body images.
     * @param encodedCompressed bytes created by taking a string array of RLE-encoded images, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBodies(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addBodies(encodedCompressed, decompressedLength, imageCount);
    }

    /**
     * @notice Add a batch of accessory images.
     * @param encodedCompressed bytes created by taking a string array of RLE-encoded images, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessories(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addAccessories(encodedCompressed, decompressedLength, imageCount);
    }

    /**
     * @notice Add a batch of head images.
     * @param encodedCompressed bytes created by taking a string array of RLE-encoded images, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHeads(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addHeads(encodedCompressed, decompressedLength, imageCount);
    }

    /**
     * @notice Add a batch of glasses images.
     * @param encodedCompressed bytes created by taking a string array of RLE-encoded images, abi encoding it as a bytes array,
     * and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addGlasses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addGlasses(encodedCompressed, decompressedLength, imageCount);
    }

    /**
     * @notice Update a single color palette. This function can be used to
     * add a new color palette or update an existing palette. This function does not check for data length validity
     * (len <= 768, len % 3 == 0).
     * @param paletteIndex the identifier of this palette
     * @param pointer the address of the contract holding the palette bytes. every 3 bytes represent an RGB color.
     * max length: 256 * 3 = 768.
     * @dev This function can only be called by the owner when not locked.
     */
    function setPalettePointer(uint8 paletteIndex, address pointer) external override onlyOwner whenPartsNotLocked {
        art.setPalettePointer(paletteIndex, pointer);
    }

    /**
     * @notice Add a batch of body images from an existing storage contract.
     * @param pointer the address of a contract where the image batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded images, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBodiesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addBodiesFromPointer(pointer, decompressedLength, imageCount);
    }

    /**
     * @notice Add a batch of accessory images from an existing storage contract.
     * @param pointer the address of a contract where the image batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded images, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addAccessoriesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addAccessoriesFromPointer(pointer, decompressedLength, imageCount);
    }

    /**
     * @notice Add a batch of head images from an existing storage contract.
     * @param pointer the address of a contract where the image batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded images, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHeadsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addHeadsFromPointer(pointer, decompressedLength, imageCount);
    }

    /**
     * @notice Add a batch of glasses images from an existing storage contract.
     * @param pointer the address of a contract where the image batch was stored using SSTORE2. The data
     * format is expected to be like {encodedCompressed}: bytes created by taking a string array of
     * RLE-encoded images, abi encoding it as a bytes array, and finally compressing it using deflate.
     * @param decompressedLength the size in bytes the images bytes were prior to compression; required input for Inflate.
     * @param imageCount the number of images in this batch; used when searching for images among batches.
     * @dev This function can only be called by the owner when not locked.
     */
    function addGlassesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external override onlyOwner whenPartsNotLocked {
        art.addGlassesFromPointer(pointer, decompressedLength, imageCount);
    }

    /**
     * @notice Get a background color by ID.
     * @param index the index of the background.
     * @return string the RGB hex value of the background.
     */
    function backgrounds(uint256 index) public view override returns (string memory) {
        return art.backgrounds(index);
    }

    /**
     * @notice Get a head image by ID.
     * @param index the index of the head.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function heads(uint256 index) public view override returns (bytes memory) {
        return art.heads(index);
    }

    /**
     * @notice Get a body image by ID.
     * @param index the index of the body.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function bodies(uint256 index) public view override returns (bytes memory) {
        return art.bodies(index);
    }

    /**
     * @notice Get an accessory image by ID.
     * @param index the index of the accessory.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function accessories(uint256 index) public view override returns (bytes memory) {
        return art.accessories(index);
    }

    /**
     * @notice Get a glasses image by ID.
     * @param index the index of the glasses.
     * @return bytes the RLE-encoded bytes of the image.
     */
    function glasses(uint256 index) public view override returns (bytes memory) {
        return art.glasses(index);
    }

    /**
     * @notice Get a color palette by ID.
     * @param index the index of the palette.
     * @return bytes the palette bytes, where every 3 consecutive bytes represent a color in RGB format.
     */
    function palettes(uint8 index) public view override returns (bytes memory) {
        return art.palettes(index);
    }

    /**
     * @notice Lock all Noun parts.
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
        string memory name = string(abi.encodePacked('Noun ', nounId));
        string memory description = string(abi.encodePacked('Noun ', nounId, ' is a member of the Nouns DAO'));

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
        NFTDescriptorV2.TokenURIParams memory params = NFTDescriptorV2.TokenURIParams({
            name: name,
            description: description,
            parts: getPartsForSeed(seed),
            background: art.backgrounds(seed.background)
        });
        return NFTDescriptorV2.constructTokenURI(renderer, params);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(INounsSeeder.Seed memory seed) external view override returns (string memory) {
        ISVGRenderer.SVGParams memory params = ISVGRenderer.SVGParams({
            parts: getPartsForSeed(seed),
            background: art.backgrounds(seed.background)
        });
        return NFTDescriptorV2.generateSVGImage(renderer, params);
    }

    /**
     * @notice Get all Noun parts for the passed `seed`.
     */
    function getPartsForSeed(INounsSeeder.Seed memory seed) public view returns (ISVGRenderer.Part[] memory) {
        bytes memory body = art.bodies(seed.body);
        bytes memory accessory = art.accessories(seed.accessory);
        bytes memory head = art.heads(seed.head);
        bytes memory glasses_ = art.glasses(seed.glasses);

        ISVGRenderer.Part[] memory parts = new ISVGRenderer.Part[](4);
        parts[0] = ISVGRenderer.Part({ image: body, palette: _getPalette(body) });
        parts[1] = ISVGRenderer.Part({ image: accessory, palette: _getPalette(accessory) });
        parts[2] = ISVGRenderer.Part({ image: head, palette: _getPalette(head) });
        parts[3] = ISVGRenderer.Part({ image: glasses_, palette: _getPalette(glasses_) });
        return parts;
    }

    /**
     * @notice Get the color palette pointer for the passed part.
     */
    function _getPalette(bytes memory part) private view returns (bytes memory) {
        return art.palettes(uint8(part[0]));
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

/// @title Interface for NounsDescriptorV2

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
import { ISVGRenderer } from './ISVGRenderer.sol';
import { INounsArt } from './INounsArt.sol';
import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsDescriptorV2 is INounsDescriptorMinimal {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    event ArtUpdated(INounsArt art);

    event RendererUpdated(ISVGRenderer renderer);

    error EmptyPalette();
    error BadPaletteLength();
    error IndexNotFound();

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view override returns (uint256);

    function bodyCount() external view override returns (uint256);

    function accessoryCount() external view override returns (uint256);

    function headCount() external view override returns (uint256);

    function glassesCount() external view override returns (uint256);

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addBackground(string calldata background) external;

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function addBodies(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addAccessories(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addHeads(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addGlasses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addBodiesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addAccessoriesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addHeadsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addGlassesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory);

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

import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptorMinimal descriptor) external view returns (Seed memory);
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

import { Base64 } from 'base64-sol/base64.sol';
import { ISVGRenderer } from '../interfaces/ISVGRenderer.sol';

library NFTDescriptorV2 {
    struct TokenURIParams {
        string name;
        string description;
        string background;
        ISVGRenderer.Part[] parts;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(ISVGRenderer renderer, TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            renderer,
            ISVGRenderer.SVGParams({ parts: params.parts, background: params.background })
        );

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
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(ISVGRenderer renderer, ISVGRenderer.SVGParams memory params)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(renderer.generateSVG(params)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for SVGRenderer

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

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
        string background;
    }

    function generateSVG(SVGParams memory params) external view returns (string memory svg);

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);

    function generateSVGParts(Part[] memory parts) external view returns (string memory partialSVG);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsArt

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

import { Inflate } from '../libs/Inflate.sol';
import { IInflator } from './IInflator.sol';

interface INounsArt {
    error SenderIsNotDescriptor();

    error EmptyPalette();

    error BadPaletteLength();

    error EmptyBytes();

    error BadDecompressedLength();

    error BadImageCount();

    error ImageNotFound();

    error PaletteNotFound();

    event DescriptorUpdated(address oldDescriptor, address newDescriptor);

    event InflatorUpdated(address oldInflator, address newInflator);

    event BackgroundsAdded(uint256 count);

    event PaletteSet(uint8 paletteIndex);

    event BodiesAdded(uint16 count);

    event AccessoriesAdded(uint16 count);

    event HeadsAdded(uint16 count);

    event GlassesAdded(uint16 count);

    struct NounArtStoragePage {
        uint16 imageCount;
        uint80 decompressedLength;
        address pointer;
    }

    struct Trait {
        NounArtStoragePage[] storagePages;
        uint256 storedImagesCount;
    }

    function descriptor() external view returns (address);

    function inflator() external view returns (IInflator);

    function setDescriptor(address descriptor) external;

    function setInflator(IInflator inflator) external;

    function addManyBackgrounds(string[] calldata _backgrounds) external;

    function addBackground(string calldata _background) external;

    function palettes(uint8 paletteIndex) external view returns (bytes memory);

    function setPalette(uint8 paletteIndex, bytes calldata palette) external;

    function addBodies(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addAccessories(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addHeads(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addGlasses(
        bytes calldata encodedCompressed,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addBodiesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function setPalettePointer(uint8 paletteIndex, address pointer) external;

    function addAccessoriesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addHeadsFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function addGlassesFromPointer(
        address pointer,
        uint80 decompressedLength,
        uint16 imageCount
    ) external;

    function backgroundsCount() external view returns (uint256);

    function backgrounds(uint256 index) external view returns (string memory);

    function heads(uint256 index) external view returns (bytes memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function getBodiesTrait() external view returns (Trait memory);

    function getAccessoriesTrait() external view returns (Trait memory);

    function getHeadsTrait() external view returns (Trait memory);

    function getGlassesTrait() external view returns (Trait memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Inflator

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

import { Inflate } from '../libs/Inflate.sol';

interface IInflator {
    function puff(bytes memory source, uint256 destlen) external pure returns (Inflate.ErrorCode, bytes memory);
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

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

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

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0 <0.9.0;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
/// @dev Modified the original code for gas optimizations
/// 1. Disable overflow/underflow checks
/// 2. Chunk some loop iterations
library Inflate {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need) private pure returns (ErrorCode, uint256) {
        unchecked {
            // Bit accumulator (can use up to 20 bits)
            uint256 val;

            // Load at least need bits into val
            val = s.bitbuf;
            while (s.bitcnt < need) {
                if (s.incnt == s.input.length) {
                    // Out of input
                    return (ErrorCode.ERR_NOT_TERMINATED, 0);
                }

                // Load eight bits
                val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
                s.bitcnt += 8;
            }

            // Drop need bits and update buffer, always zero to seven bits left
            s.bitbuf = val >> need;
            s.bitcnt -= need;

            // Return need bits, zeroing the bits above that
            uint256 ret = (val & ((1 << need) - 1));
            return (ErrorCode.ERR_NONE, ret);
        }
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Length of stored block
            uint256 len;

            // Discard leftover bits from current byte (assumes s.bitcnt < 8)
            s.bitbuf = 0;
            s.bitcnt = 0;

            // Get length and check against its one's complement
            if (s.incnt + 4 > s.input.length) {
                // Not enough input
                return ErrorCode.ERR_NOT_TERMINATED;
            }
            len = uint256(uint8(s.input[s.incnt++]));
            len |= uint256(uint8(s.input[s.incnt++])) << 8;

            if (uint8(s.input[s.incnt++]) != (~len & 0xFF) || uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)) {
                // Didn't match complement!
                return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
            }

            // Copy len bytes from in to out
            if (s.incnt + len > s.input.length) {
                // Not enough input
                return ErrorCode.ERR_NOT_TERMINATED;
            }
            if (s.outcnt + len > s.output.length) {
                // Not enough output space
                return ErrorCode.ERR_OUTPUT_EXHAUSTED;
            }
            while (len != 0) {
                // Note: Solidity reverts on underflow, so we decrement here
                len -= 1;
                s.output[s.outcnt++] = s.input[s.incnt++];
            }

            // Done with a valid stored block
            return ErrorCode.ERR_NONE;
        }
    }

    function _decode(State memory s, Huffman memory h) private pure returns (ErrorCode, uint256) {
        unchecked {
            // Current number of bits in code
            uint256 len;
            // Len bits being decoded
            uint256 code = 0;
            // First code of length len
            uint256 first = 0;
            // Number of codes of length len
            uint256 count;
            // Index of first code of length len in symbol table
            uint256 index = 0;
            // Error code
            ErrorCode err;

            uint256 tempCode;
            for (len = 1; len <= MAXBITS; len += 5) {
                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 1];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 2];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 3];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;

                // Get next bit
                (err, tempCode) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, 0);
                }
                code |= tempCode;
                count = h.counts[len + 4];

                // If length len, return symbol
                if (code < first + count) {
                    return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
                }
                // Else update for next length
                index += count;
                first += count;
                first <<= 1;
                code <<= 1;
            }

            // Ran out of codes
            return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
        }
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        unchecked {
            // Current symbol when stepping through lengths[]
            uint256 symbol;
            // Current length when stepping through h.counts[]
            uint256 len;
            // Number of possible codes left of current length
            uint256 left;
            // Offsets in symbol table for each length
            uint256[MAXBITS + 1] memory offs;

            // Count number of codes of each length
            for (len = 0; len <= MAXBITS; ++len) {
                h.counts[len] = 0;
            }
            for (symbol = 0; symbol < n; ++symbol) {
                // Assumes lengths are within bounds
                ++h.counts[lengths[start + symbol]];
            }
            // No codes!
            if (h.counts[0] == n) {
                // Complete, but decode() will fail
                return (ErrorCode.ERR_NONE);
            }

            // Check for an over-subscribed or incomplete set of lengths

            // One possible code of zero length
            left = 1;

            for (len = 1; len <= MAXBITS; len += 5) {
                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 1]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 1];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 2]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 2];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 3]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 3];

                // One more bit, double codes left
                left <<= 1;
                if (left < h.counts[len + 4]) {
                    // Over-subscribed--return error
                    return ErrorCode.ERR_CONSTRUCT;
                }
                // Deduct count from possible codes
                left -= h.counts[len + 4];
            }

            // Generate offsets into symbol table for each length for sorting
            offs[1] = 0;
            for (len = 1; len < MAXBITS; ++len) {
                offs[len + 1] = offs[len] + h.counts[len];
            }

            // Put symbols in table sorted by length, by symbol order within each length
            for (symbol = 0; symbol < n; ++symbol) {
                if (lengths[start + symbol] != 0) {
                    h.symbols[offs[lengths[start + symbol]]++] = symbol;
                }
            }

            // Left > 0 means incomplete
            return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
        }
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        unchecked {
            // Decoded symbol
            uint256 symbol;
            // Length for copy
            uint256 len;
            // Distance for copy
            uint256 dist;
            // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
            // Size base for length codes 257..285
            uint16[29] memory lens = [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
            // Extra bits for length codes 257..285
            uint8[29] memory lext = [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
            // Offset base for distance codes 0..29
            uint16[30] memory dists = [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
            // Extra bits for distance codes 0..29
            uint8[30] memory dext = [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
            // Error code
            ErrorCode err;

            // Decode literals and length/distance pairs
            while (symbol != 256) {
                (err, symbol) = _decode(s, lencode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }

                if (symbol < 256) {
                    // Literal: symbol is the byte
                    // Write out the literal
                    if (s.outcnt == s.output.length) {
                        return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                    }
                    s.output[s.outcnt] = bytes1(uint8(symbol));
                    ++s.outcnt;
                } else if (symbol > 256) {
                    uint256 tempBits;
                    // Length
                    // Get and compute length
                    symbol -= 257;
                    if (symbol >= 29) {
                        // Invalid fixed code
                        return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                    }

                    (err, tempBits) = bits(s, lext[symbol]);
                    if (err != ErrorCode.ERR_NONE) {
                        return err;
                    }
                    len = lens[symbol] + tempBits;

                    // Get and check distance
                    (err, symbol) = _decode(s, distcode);
                    if (err != ErrorCode.ERR_NONE) {
                        // Invalid symbol
                        return err;
                    }
                    (err, tempBits) = bits(s, dext[symbol]);
                    if (err != ErrorCode.ERR_NONE) {
                        return err;
                    }
                    dist = dists[symbol] + tempBits;
                    if (dist > s.outcnt) {
                        // Distance too far back
                        return ErrorCode.ERR_DISTANCE_TOO_FAR;
                    }

                    // Copy length bytes from distance bytes back
                    if (s.outcnt + len > s.output.length) {
                        return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                    }
                    while (len != 0) {
                        // Note: Solidity reverts on underflow, so we decrement here
                        len -= 1;
                        s.output[s.outcnt] = s.output[s.outcnt - dist];
                        ++s.outcnt;
                    }
                } else {
                    s.outcnt += len;
                }
            }

            // Done with a valid fixed or dynamic block
            return ErrorCode.ERR_NONE;
        }
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Build fixed Huffman tables
            // TODO this is all a compile-time constant
            uint256 symbol;
            uint256[] memory lengths = new uint256[](FIXLCODES);

            // Literal/length table
            for (symbol = 0; symbol < 144; ++symbol) {
                lengths[symbol] = 8;
            }
            for (; symbol < 256; ++symbol) {
                lengths[symbol] = 9;
            }
            for (; symbol < 280; ++symbol) {
                lengths[symbol] = 7;
            }
            for (; symbol < FIXLCODES; ++symbol) {
                lengths[symbol] = 8;
            }

            _construct(s.lencode, lengths, FIXLCODES, 0);

            // Distance table
            for (symbol = 0; symbol < MAXDCODES; ++symbol) {
                lengths[symbol] = 5;
            }

            _construct(s.distcode, lengths, MAXDCODES, 0);

            return ErrorCode.ERR_NONE;
        }
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Decode data until end-of-block code
            return _codes(s, s.lencode, s.distcode);
        }
    }

    function _build_dynamic_lengths(State memory s) private pure returns (ErrorCode, uint256[] memory) {
        unchecked {
            uint256 ncode;
            // Index of lengths[]
            uint256 index;
            // Descriptor code lengths
            uint256[] memory lengths = new uint256[](MAXCODES);
            // Error code
            ErrorCode err;
            // Permutation of code length codes
            uint8[19] memory order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

            (err, ncode) = bits(s, 4);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
            ncode += 4;

            // Read code length code lengths (really), missing lengths are zero
            for (index = 0; index < ncode; ++index) {
                (err, lengths[order[index]]) = bits(s, 3);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, lengths);
                }
            }
            for (; index < 19; ++index) {
                lengths[order[index]] = 0;
            }

            return (ErrorCode.ERR_NONE, lengths);
        }
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        unchecked {
            // Number of lengths in descriptor
            uint256 nlen;
            uint256 ndist;
            // Index of lengths[]
            uint256 index;
            // Error code
            ErrorCode err;
            // Descriptor code lengths
            uint256[] memory lengths = new uint256[](MAXCODES);
            // Length and distance codes
            Huffman memory lencode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
            Huffman memory distcode = Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
            uint256 tempBits;

            // Get number of lengths in each table, check lengths
            (err, nlen) = bits(s, 5);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }
            nlen += 257;
            (err, ndist) = bits(s, 5);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }
            ndist += 1;

            if (nlen > MAXLCODES || ndist > MAXDCODES) {
                // Bad counts
                return (ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, lencode, distcode);
            }

            (err, lengths) = _build_dynamic_lengths(s);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lencode, distcode);
            }

            // Build huffman table for code lengths codes (use lencode temporarily)
            err = _construct(lencode, lengths, 19, 0);
            if (err != ErrorCode.ERR_NONE) {
                // Require complete code set here
                return (ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE, lencode, distcode);
            }

            // Read length/literal and distance code length tables
            index = 0;
            while (index < nlen + ndist) {
                // Decoded value
                uint256 symbol;
                // Last length to repeat
                uint256 len;

                (err, symbol) = _decode(s, lencode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return (err, lencode, distcode);
                }

                if (symbol < 16) {
                    // Length in 0..15
                    lengths[index++] = symbol;
                } else {
                    // Repeat instruction
                    // Assume repeating zeros
                    len = 0;
                    if (symbol == 16) {
                        // Repeat last length 3..6 times
                        if (index == 0) {
                            // No last length!
                            return (ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH, lencode, distcode);
                        }
                        // Last length
                        len = lengths[index - 1];
                        (err, tempBits) = bits(s, 2);
                        if (err != ErrorCode.ERR_NONE) {
                            return (err, lencode, distcode);
                        }
                        symbol = 3 + tempBits;
                    } else if (symbol == 17) {
                        // Repeat zero 3..10 times
                        (err, tempBits) = bits(s, 3);
                        if (err != ErrorCode.ERR_NONE) {
                            return (err, lencode, distcode);
                        }
                        symbol = 3 + tempBits;
                    } else {
                        // == 18, repeat zero 11..138 times
                        (err, tempBits) = bits(s, 7);
                        if (err != ErrorCode.ERR_NONE) {
                            return (err, lencode, distcode);
                        }
                        symbol = 11 + tempBits;
                    }

                    if (index + symbol > nlen + ndist) {
                        // Too many lengths!
                        return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                    }
                    while (symbol != 0) {
                        // Note: Solidity reverts on underflow, so we decrement here
                        symbol -= 1;

                        // Repeat last or zero symbol times
                        lengths[index++] = len;
                    }
                }
            }

            // Check for end-of-block code -- there better be one!
            if (lengths[256] == 0) {
                return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
            }

            // Build huffman table for literal/length codes
            err = _construct(lencode, lengths, nlen, 0);
            if (
                err != ErrorCode.ERR_NONE &&
                (err == ErrorCode.ERR_NOT_TERMINATED ||
                    err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                    nlen != lencode.counts[0] + lencode.counts[1])
            ) {
                // Incomplete code ok only for single length 1 code
                return (ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, lencode, distcode);
            }

            // Build huffman table for distance codes
            err = _construct(distcode, lengths, ndist, nlen);
            if (
                err != ErrorCode.ERR_NONE &&
                (err == ErrorCode.ERR_NOT_TERMINATED ||
                    err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                    ndist != distcode.counts[0] + distcode.counts[1])
            ) {
                // Incomplete code ok only for single length 1 code
                return (ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS, lencode, distcode);
            }

            return (ErrorCode.ERR_NONE, lencode, distcode);
        }
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        unchecked {
            // Length and distance codes
            Huffman memory lencode;
            Huffman memory distcode;
            // Error code
            ErrorCode err;

            (err, lencode, distcode) = _build_dynamic(s);
            if (err != ErrorCode.ERR_NONE) {
                return err;
            }

            // Decode data until end-of-block code
            return _codes(s, lencode, distcode);
        }
    }

    function puff(bytes memory source, uint256 destlen) internal pure returns (ErrorCode, bytes memory) {
        unchecked {
            // Input/output state
            State memory s = State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
            // Temp: last bit
            uint256 last;
            // Temp: block type bit
            uint256 t;
            // Error code
            ErrorCode err;

            // Build fixed Huffman tables
            err = _build_fixed(s);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Process blocks until last block or error
            while (last == 0) {
                // One if last block
                (err, last) = bits(s, 1);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, s.output);
                }

                // Block type 0..3
                (err, t) = bits(s, 2);
                if (err != ErrorCode.ERR_NONE) {
                    return (err, s.output);
                }

                err = (
                    t == 0
                        ? _stored(s)
                        : (t == 1 ? _fixed(s) : (t == 2 ? _dynamic(s) : ErrorCode.ERR_INVALID_BLOCK_TYPE))
                );
                // type == 3, invalid

                if (err != ErrorCode.ERR_NONE) {
                    // Return with error
                    break;
                }
            }

            return (err, s.output);
        }
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