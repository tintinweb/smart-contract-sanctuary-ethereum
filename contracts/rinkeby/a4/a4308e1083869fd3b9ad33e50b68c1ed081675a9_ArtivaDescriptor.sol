// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { IArtivaDescriptor } from "./interfaces/IArtivaDescriptor.sol";
import {ISVGGenerator} from "./interfaces/ISVGGenerator.sol";
import {ISeeder} from "./interfaces/ISeeder.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { Base64 } from 'base64/base64.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

contract ArtivaDescriptor is IArtivaDescriptor, Ownable {
    using Strings for uint256;

    // SVG Generator
    ISVGGenerator svgGenerator;

    // Whether the descriptor can be updated
    bool public isSVGGeneratorLocked;

    // Wether or not new props / pallets can be added
    bool public isDataLocked;

    // Color pallets (Index => Hex colors as Bytes)
    mapping(uint8 => bytes[]) public palettes;

    // Holds the configurations for generation types that can be cretaed with the SVG renderer
    Configuration[] public configurations;

    // Background props (Bytes string)
    bytes[] public backgroundProps;

    // Circle props (Bytes string)
    bytes[] public circleProps;

     // Path props (Bytes string)
    bytes[] public pathProps;

     // Gradient static props (Bytes string)
    bytes[] public gradientStaticProps;

    // Amount of color pallets 
    uint256 private _paletteCount = 0;

    /**
     * @notice Require that the svg generator has not been locked.
     */
    modifier whenSVGGeneratorNotLocked() {
        require(!isSVGGeneratorLocked, 'SVG generator is locked');
        _;
    }

    /**
     * @notice Require that the data have not been locked.
     */
    modifier whenDataNotLocked() {
        require(!isDataLocked, 'Data is locked');
        _;
    }


    constructor(ISVGGenerator _svgGenerator) {
        svgGenerator = _svgGenerator;
    }

    /**
     * @notice Get the number of available palettes.
     */
    function paletteCount() external view returns (uint256) {
        return _paletteCount;
    }

    /**
     * @notice Get the number of available palettes.
     */
    function colorsInPalletCount(uint8 paletteIndex) external view returns (uint256) {
        return getPalette(paletteIndex).length;
    }

    /**
     * @notice Get the number of available configurations.
     */
    function configurationsCount() external view returns (uint256) {
        return configurations.length;
    }

    /**
     * @notice Get the number of background props.
     */
    function backgroundPropsCount() external view returns (uint256) {
        return backgroundProps.length;
    }

    /**
     * @notice Get the number of available circle props.
     */
    function circlePropsCount() external view returns (uint256) {
        return circleProps.length;
    }

    /**
     * @notice Get the number of available path props.
     */
    function pathPropsCount() external view returns (uint256) {
        return pathProps.length;
    }

    /**
     * @notice Get the number of available gradient static props.
     */
    function gradientStaticPropsCount() external view returns (uint256) {
        return gradientStaticProps.length;
    }

     /**
     * @notice Gets a pallete by index.
     */
    function getPalette(uint8 paletteIndex) public view returns (bytes[] memory) {
        return palettes[paletteIndex];
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, bytes[] calldata newColors) external onlyOwner whenDataNotLocked {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        if(palettes[paletteIndex].length == 0) _paletteCount += 1;
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add configurations.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyConfigurations(Configuration[] calldata _configurations) external onlyOwner whenDataNotLocked {
        for (uint256 i = 0; i < _configurations.length; i++) {
            _addConfiguration(_configurations[i]);
        }
    }

    /**
     * @notice Batch add background props.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgroundProps(bytes[] calldata _backgroundProps) external onlyOwner whenDataNotLocked {
        for (uint256 i = 0; i < _backgroundProps.length; i++) {
            _addBackgroundProp(_backgroundProps[i]);
        }
    }

    /**
     * @notice Batch add circle props.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCircleProps(bytes[] calldata _circleProps) external onlyOwner whenDataNotLocked {
        for (uint256 i = 0; i < _circleProps.length; i++) {
            _addCircleProp(_circleProps[i]);
        }
    }

    /**
     * @notice Batch add path props.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyPathProps(bytes[] calldata _pathProps) external onlyOwner whenDataNotLocked {
        for (uint256 i = 0; i < _pathProps.length; i++) {
            _addPathProp(_pathProps[i]);
        }
    }

    /* @notice Batch add gradient static props.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyGradientStaticProps(bytes[] calldata _gradientStaticProps) external onlyOwner whenDataNotLocked {
        for (uint256 i = 0; i < _gradientStaticProps.length; i++) {
            _addGradientStaticProps(_gradientStaticProps[i]);
        }
    }

        /**
     * @notice Set svg generator.
     * @dev Only callable by the owner when not locked.
     */
    function setSVGGenerator(ISVGGenerator _svgGenerator) external onlyOwner whenSVGGeneratorNotLocked {
        svgGenerator = _svgGenerator;

        emit SVGGeneratorUpdated(_svgGenerator);
    }

    /**
     * @notice Lock the svg generator.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSVGGenerator() external onlyOwner whenSVGGeneratorNotLocked {
        isSVGGeneratorLocked = true;

        emit SVGGeneratorLocked();
    }

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory) {
        return dataURI(tokenId, seed);
    }
    

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) public view returns (string memory) {
        string memory tokenId = tokenId.toString();
        string memory name = string(abi.encodePacked('Artiva ', tokenId));
        string memory description = string(abi.encodePacked('Artiva ', tokenId, ' is a member of the Artiva DAO'));

        return genericDataURI(name, description, seed);
    }

    function genericDataURI(
        string memory name,
        string memory description,
        ISeeder.Seed memory seed
    ) public view returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            image: generateSVGImage(seed)
        });
        return NFTDescriptor.constructTokenURI(params);
    }

    function generateSVGImage(ISeeder.Seed memory seed) public view returns (string memory) {
        ISVGGenerator.SVGParams memory params = getSVGParamsFromSeed(seed);
        return svgGenerator.generateSVGImage(params);
    }

    function getSVGParamsFromSeed(ISeeder.Seed memory seed) internal view returns (ISVGGenerator.SVGParams memory) {
        uint256 paletteLength = seed.colorIndexes.length;
        bytes[] memory basePalette = getPalette(seed.paletteIndex);
        bytes[] memory palette = new bytes[](paletteLength);

        for(uint256 i = 0; i < paletteLength; i++) {
            uint8 colorIndex = seed.colorIndexes[i];
            palette[i] = basePalette[colorIndex];
            _removeFromArray(basePalette, colorIndex);
        }

        Configuration storage config = configurations[seed.configurationIndex];
        return ISVGGenerator.SVGParams({
            backgroundProps: backgroundProps[config.background],
            circleProps: circleProps[config.circle],
            pathProps: pathProps[config.path],
            gradientType: config.gradientType,
            gradientStaticProps: gradientStaticProps[config.gradientStatic],
            gradientDynamicProps: config.gradientDynamic,
            palette: palette
        });
    }

    function _removeFromArray(bytes[] memory array, uint256 idx) internal pure {
        array[idx] = array[array.length - 1];
        assembly { mstore(array, sub(mload(array), 1)) }
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, bytes calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a background prop.
     */
    function _addConfiguration(Configuration calldata _configuration) internal {
        configurations.push(_configuration);
    }

    /**
     * @notice Add a background prop.
     */
    function _addBackgroundProp(bytes calldata _backgroundProp) internal {
        backgroundProps.push(_backgroundProp);
    }

    /**
     * @notice Add a circle prop.
     */
    function _addCircleProp(bytes calldata _circleProp) internal {
        circleProps.push(_circleProp);
    }

    /**
     * @notice Add a path props=.
     */
    function _addPathProp(bytes calldata _pathProp) internal {
        pathProps.push(_pathProp);
    }

    /**
     * @notice Add a gradient static prop.
     */
    function _addGradientStaticProps(bytes calldata _gradientStaticProp) internal {
        gradientStaticProps.push(_gradientStaticProp);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { ISVGGenerator } from './ISVGGenerator.sol';
import { ISeeder } from './ISeeder.sol';

interface IArtivaDescriptor {
    struct Configuration {
        uint48 background;
        uint48 circle;
        uint48 path;
        uint48 gradientType;
        uint48 gradientStatic;
        bytes[] gradientDynamic;
    }

    event SVGGeneratorUpdated(ISVGGenerator svgGenerator);

    event SVGGeneratorLocked();

    function tokenURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ISeeder.Seed memory seed) external view returns (string memory);

    function paletteCount() external view returns (uint256);

    function getPalette(uint8 paletteIndex) external view returns (bytes[] memory);
    
    function colorsInPalletCount(uint8 paletteIndex) external view returns (uint256);

    function configurationsCount() external view returns (uint256);

    function backgroundPropsCount() external view returns (uint256);

    function circlePropsCount() external view returns (uint256);

    function pathPropsCount() external view returns (uint256);

    function gradientStaticPropsCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface ISVGGenerator {
    struct SVGParams {
        bytes backgroundProps;
        bytes circleProps;
        bytes pathProps;
        bytes gradientStaticProps;
        uint48 gradientType;
        bytes[] gradientDynamicProps;
        bytes[] palette;
    }

    function generateSVGImage(SVGParams memory params) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IArtivaDescriptor} from "./IArtivaDescriptor.sol";

interface ISeeder {
    struct Seed {
        uint8[] colorIndexes;
        uint8 paletteIndex;
        uint24 configurationIndex;
    }

    function generateSeed(uint256 tokenId, IArtivaDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { Base64 } from 'base64/base64.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string image;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params)
        public
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', Base64.encode(bytes(abi.encodePacked(params.image))), '"}')
                    )
                )
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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