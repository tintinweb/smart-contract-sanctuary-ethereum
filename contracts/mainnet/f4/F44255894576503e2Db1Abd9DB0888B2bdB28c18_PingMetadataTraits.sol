// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IPingMetadataTraits.sol";
import "./PingAtts.sol";
import "../IExtendedColors.sol";

contract PingMetadataTraits is IPingMetadataTraits, Ownable {
    using Strings for uint8;
    using Strings for uint;

    string[] public _wiggleSpeeds = ['Fast', 'Medium', 'Slow'];
    string[] public _wiggleExtents = ['Rigid', 'Subtle', 'Moderate', 'Jelly'];

    IExtendedColors public colors;

    function setExtColorsAddr(address addr) external onlyOwner {
        colors = IExtendedColors(addr);
    }

    function setWiggleExtentName(uint idx, string memory name) external virtual onlyOwner {
        require (idx < _wiggleExtents.length, "ioob");
        _wiggleExtents[idx] = name;
    }

    function getTraits(PingAtts memory atts) external virtual override view returns (string memory)
    {
        return string.concat(
            getTraits_1(atts),
            getTraits_2(atts),
            getTraits_3(atts)
        );

    }
    function getTraits_1(PingAtts memory atts) internal view returns (string memory)
    {
        return string.concat(
            "[",
            composeAttributeString_Start('Paint Color', colors.getColorName(atts.paletteIndex, atts.paintIdx)),
            composeNumberAttributeString('Columns', atts.numX ),
            composeNumberAttributeString('Rows', atts.numY),
            composeAttributeString('Palette', colors.getPaletteName(atts.paletteIndex)),
            composeAttributeString('Textured', atts.hasTexture ? "Yes" : "No"),
            composeAttributeString('Contour', atts.openShape ? 'Bulk' : 'Sharp'),
            composeAttributeString('Wire Color', colors.getColorName(atts.paletteIndex, atts.lineColorIdx)),
            composeAttributeString('Shape Color', colors.getColorName(atts.paletteIndex, atts.shapeColorIdx))
        );
    }
    function getTraits_2(PingAtts memory atts) internal view returns (string memory)
    {
        return string.concat(
            composeAttributeString('Emit Color', colors.getColorName(atts.paletteIndex, atts.emitColorIdx)),
            composeAttributeString('Shadow Color', colors.getColorName(atts.paletteIndex, atts.shadowColorIdx)),
            composeAttributeString('Noise Shadow Color', colors.getColorName(atts.paletteIndex, atts.nShadColIdx)),
            composeNumberAttributeString('System Density', atts.shapeSizesDensity),
            composeAttributeString('Wire Thickness', atts.lineThickness <= 2 ? 'Web' : atts.lineThickness <= 4 ? 'String' : 'Cord'), //1, 3, 5
            composeAttributeString('Emit Rate', atts.emitRate <= 2 ? 'Stable' : atts.emitRate <= 5 ? 'Medium' : atts.emitRate <= 7 ? 'Unstable' : 'Rapid')
        );
    }
    function getTraits_3(PingAtts memory atts) internal view returns (string memory)
    {
        return string.concat(
            composeAttributeString('Wobble Speed', _wiggleSpeeds[atts.wiggleSpeedIdx]),    //fast medium slow
            composeAttributeString('Wobble Amount', _wiggleExtents[atts.wiggleStrengthIdx]),    //none, slim, medium, wide
            composeAttributeString('Paint Fade Color', colors.getColorName(atts.paletteIndex, atts.paint2Idx)),
            ']'
        );
    }

    function composeAttributeString(string memory trait, string memory value) internal pure returns (string memory) {
        return string.concat(
            ', { "trait_type": "', trait,
            '", "value": "', value,
            '" }'
        );
    }
    function composeAttributeString_Start(string memory trait, string memory value) internal pure returns (string memory) {
        return string.concat(
            '{ "trait_type": "', trait,
            '", "value": "', value,
            '" }'
        );
    }
    function composeNumberAttributeString(string memory trait, uint value) internal pure returns (string memory) {
        return string.concat(
            ', { "trait_type": "', trait,
            '", "value": ', value.toString(),
            ' }'
        );
    }

    function validateContract() external view returns (string memory) {
        if (address(colors) == address(0)) {
            return "No col addr";
        }
        return colors.validateContract();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


struct PingAtts {
    uint8 numX;
    uint8 numY;
    uint8 paletteIndex;
    bool hasTexture;
    bool openShape;
    uint8 lineColorIdx;
    uint8 paintIdx;
    uint8 shapeColorIdx;
    uint8 emitColorIdx;
    uint8 shadowColorIdx;
    uint8 nShadColIdx;
    uint8 shapeSizesDensity;
    uint8 lineThickness;
    uint8 emitRate;
    uint8 wiggleSpeedIdx;
    uint8 wiggleStrengthIdx;
    uint8 paint2Idx;

    uint8[] extraParams;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IValidatable {
    function validateContract() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PingAtts.sol";
import "./IValidatable.sol";

interface IPingMetadataTraits is IValidatable {

    function getTraits(PingAtts memory atts) external view returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IColors.sol";
import "./pings/IValidatable.sol";

interface IExtendedColors is IColors, IValidatable {
    function getColorName(uint paletteIdx, uint colorIndex) external view returns (string calldata name);
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