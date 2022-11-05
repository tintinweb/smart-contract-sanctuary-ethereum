//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "./IArtData.sol";
import "./IColors.sol";
import "./IRenderer.sol";
import "./Structs.sol";

contract Previewer is IRenderer, ReentrancyGuard, Ownable
{
    using Strings for uint256;

    address public colorsAddr;
    uint8 spacingY = 40;
    uint8 spacingX = 100;

    function setColorsAddr(address addr) external virtual onlyOwner {
        colorsAddr = addr;
    }

    function setSpacing(uint8 spacingX_, uint8 spacingY_) external virtual onlyOwner {
        spacingX = spacingX_;
        spacingY = spacingY_;
    }

    function render(
        string calldata,
        uint256,
        BaseAttributes calldata art,
        bool,
        IArtData.ArtProps memory artProps
    )
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(address(colorsAddr) != address(0), "colors address does not exist");
        IColors colors = IColors(colorsAddr);

        string[] memory skyVals = colors.getSkyPalette(art.skyCol);
        string[] memory trailVals = colors.getPalette(art.palette);

        string memory svgStr = string(abi.encodePacked(
                svgStartStr,
                '<defs>',
                plane_def,
                sky_def[0],
                skyVals[0],
                sky_def[1],
                skyVals[1],
                sky_def[2],
                smoke_def,
                '</defs>',
                sky_draw
        ));

        for (uint256 i; i < art.planeAttributes.length; i++) {
            uint x = i / 5;
            uint y = i % 5;

            PlaneAttributes calldata plane = art.planeAttributes[i];
            uint256 angle_deg = 180 + 360 * plane.angle / artProps.numAngles;
            svgStr = string.concat( svgStr,
                    plane_draw[0],
                    (x* spacingX).toString(),
                    ' ',
                    (y* spacingY).toString(),
                    plane_draw[1],
                    trailVals[plane.trailCol % trailVals.length],
                    plane_draw[2],
                    angle_deg.toString(),
                    plane_draw[3]
            );
        }

        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(abi.encodePacked( svgStr, svgEndStr)))));
    }

    string svgStartStr = '<svg width="100%" height="100%" viewBox="0 0 200 200" \n\
version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" \n\
style="fill-rule:evenodd;clip-rule:evenodd;stroke-linejoin:round;stroke-miterlimit:2;"> \n\
';
    string svgEndStr = '</svg>';

    string plane_def = '\n\
<path id="plane" \n\
d="M37,58l39,0l0,-32.5c0,0 0.417,-11.417 12.5,-11.5c12.083,-0.083 12.481,11.489 12.5,11.5c0.019,0.011 0,32.5 0,32.5l39,0c0,0 17.667,1.167 17.5,19c-0.167,17.833 -17.5,19 -17.5,19l-39,0l0,44c0,0 12.75,-0.25 12.5,12.5c-0.25,12.75 -11.5,12.5 -11.5,12.5l-27,0c0,0 -11.333,0.167 -11.5,-12.5c-0.167,-12.667 12.5,-12.5 12.5,-12.5l0,-44l-39,0c0,0 -17.667,-0.25 -17.5,-19c0.167,-18.75 17.5,-19 17.5,-19Z" \n\
style="fill:#fff;"/>';

    string[] sky_def = [
'<linearGradient id="sky" gradientTransform="rotate(90)"> \n\
<stop offset="5%" stop-color="#',
//'B2FBFF',
'"/> <stop offset="95%" stop-color="#',
//'4FA9F2',
'"/> </linearGradient>'];

    string smoke_def = '<line id="smoke" x1="10" y1="18" x2="40" y2="18" stroke-width="5%"/>';

    string sky_draw = '<rect x="0" y="0" width="100%" height="100%" fill="url(#sky)"/>';

    string[] plane_draw = [
'<g transform="translate(',
//0 ',
//'0',
')"> <use xlink:href="#smoke" stroke="#',
//'c8823c',
'" /> <use xlink:href="#plane" fill="none" stroke="black" transform="translate(50 0) scale(0.2 0.2) rotate(',
//'30
' 88 89)"/> </g>'];

}

// File: contracts/Structs.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

struct PlaneAttributes {
    uint8 locX;
    uint8 locY;
    uint8 angle;
    uint8 trailCol;
    uint8 level;
    uint8 speed;
    uint8 planeType;
    uint8[] extraParams;
}

struct BaseAttributes {
    uint8 proximity;
    uint8 skyCol;
    uint8 numPlanes;
    uint8 palette;
    PlaneAttributes[] planeAttributes;
    uint8[] extraParams;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Structs.sol";
import "./IArtData.sol";

interface IRenderer {

    function render(
        string calldata tokenSeed,
        uint256 tokenId,
        BaseAttributes memory atts,
        bool isSample,
        IArtData.ArtProps memory artProps
    )
        external
        view
        returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IColors
{

    function getPalette(uint idx) external view returns (string[] calldata colors);
    function getPaletteSize(uint idx) external view returns (uint numColors) ;
    function getSkyPalette(uint idx) external view returns (string[] calldata colors);

    function getNumSkys() external view returns (uint numSkys);
    function getNumPalettes() external view returns (uint numPalettes);

    function getSkyName(uint idx) external view returns (string calldata name);
    function getPaletteName(uint idx) external view returns (string calldata name);

    function getSkyRarities() external view returns (uint8[] memory);
    function geColorPaletteRarities() external view returns (uint8[] memory);

}

// File: contracts/IArtData.sol


// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IArtData.sol";

interface IArtData{

    struct ArtProps {
        uint256 numOfX;
        uint256 numOfY;
        uint256 numAngles;
        uint256 numTypes;
        uint256[] extraParams;
    }

    function getProps() external view returns(ArtProps memory);


    function getNumOfX() external view returns (uint) ;

    function getNumOfY() external view returns (uint);

    function getNumAngles() external view returns (uint);

    function getNumTypes() external view returns (uint);

    function getNumSpeeds() external view returns (uint);

    function getSkyName(uint index) external view returns (string calldata);

    function getNumSkyCols() external view returns (uint);

    function getColorPaletteName(uint paletteIdx) external view returns (string calldata) ;

    function getNumColorPalettes() external view returns (uint) ;

    function getPaletteSize(uint paletteIdx) external view returns (uint);

    function getProximityName(uint index) external view returns (string calldata);

    function getNumProximities() external view returns (uint);

    function getMaxNumPlanes() external view returns (uint);


    function getLevelRarities() external view returns (uint8[] calldata);

    function getSpeedRarities() external view returns (uint8[] calldata);

    function getPlaneTypeRarities() external view returns (uint8[] calldata);

    function getProximityRarities() external view returns (uint8[] calldata);

    function getSkyRarities() external view returns (uint8[] calldata) ;

    function getColorPaletteRarities() external view returns (uint8[] calldata) ;

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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