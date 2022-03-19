// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import {Integers} from "../lib/Integers.sol";
import "../interfaces/ICoBotsRenderer.sol";

/*  @title CoBots Renderer
    @author Clement Walter
    @dev Encode each traits as a "sum" of `rect`, each rect being stored using 4 bytes
*/
contract CoBotsRenderer is Ownable, ReentrancyGuard, ICoBotsRenderer {
    using Integers for uint8;
    using Strings for uint256;

    // We have a total of 4 * 6 = 24 bits = 3 bytes for coordinates + 1 byte for the color
    // Hence each rect is 4 bytes
    uint8 public constant BITS_PER_COORDINATES = 6;
    uint8 public constant BITS_PER_FILL_INDEX = 8;

    string public constant RECT_TAG_START = "%3crect%20x=%27";
    string public constant Y_TAG = "%27%20y=%27";
    string public constant WIDTH_TAG = "%27%20width=%27";
    string public constant HEIGHT_TAG = "%27%20height=%27";
    string public constant FILL_TAG = "%27%20fill=%27%23";
    string public constant RECT_TAG_END = "%27/%3e";
    string public constant SVG_TAG_START =
        "%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20viewBox=%270%200%2045%2045%27%20width=%27450px%27%20height=%27450px%27%3e";
    string public constant SVG_TAG_END =
        "%3cstyle%3erect{shape-rendering:crispEdges}%3c/style%3e%3c/svg%3e";

    address public fillPalette;
    address public traitPalette;
    address public traitPaletteIndexes; // where each trait begins in the traits' palette
    bytes public layerIndexes; // the index of the first item of each layer, uint8/bytes1 for each layer

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Colors are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    function setFillPalette(bytes calldata _fillPalette) external onlyOwner {
        fillPalette = SSTORE2.write(_fillPalette);
    }

    /// @dev All the rects are concatenated together to save gas.
    ///      The traitPaletteIndexes is used to retrieve the rect from the traitPalette.
    function setTraitPalette(bytes calldata _traitPalette) external onlyOwner {
        traitPalette = SSTORE2.write(_traitPalette);
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    function setTraitPaletteIndexes(bytes calldata _traitPaletteIndexes)
        external
        onlyOwner
    {
        traitPaletteIndexes = SSTORE2.write(_traitPaletteIndexes);
    }

    /// @dev Traits are stored as a plain list while the rendering works with layer and items within each layer.
    ///      Since each layer has a variable number of items, we store the index of the first trait of each layer.
    function setLayerIndexes(bytes calldata _layerIndexes) external onlyOwner {
        layerIndexes = _layerIndexes;
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(uint256 _index) public view returns (string memory) {
        bytes memory palette = SSTORE2.read(fillPalette);
        return
            string.concat(
                uint8(palette[3 * _index]).toString(16, 2),
                uint8(palette[3 * _index + 1]).toString(16, 2),
                uint8(palette[3 * _index + 2]).toString(16, 2)
            );
    }

    /// @dev This function lets map from layerIndex and itemIndex to traitIndex.
    function getTraitIndex(uint256 _layerIndex, uint256 _itemIndex)
        public
        view
        returns (uint256)
    {
        uint8 traitIndex = uint8(layerIndexes[_layerIndex]);
        uint8 nextTraitIndex = uint8(layerIndexes[_layerIndex + 1]);
        if (traitIndex + _itemIndex > nextTraitIndex - 1) {
            return type(uint8).max;
        }

        return _itemIndex + traitIndex;
    }

    /// @dev Retrieve the bytes for the given trait from the traitPalette storage.
    function getTraitBytes(uint256 _index) public view returns (bytes memory) {
        bytes memory _indexes = SSTORE2.read(traitPaletteIndexes);
        uint32 start = uint32(BytesLib.toUint16(_indexes, _index * 2));
        uint32 next = uint32(BytesLib.toUint16(_indexes, _index * 2 + 2));
        bytes memory _traitPalette = SSTORE2.read(traitPalette);
        return BytesLib.slice(_traitPalette, start, next - start);
    }

    function decodeRect(bytes memory rectBytes)
        public
        view
        returns (string memory)
    {
        return decodeRect(rectBytes, 0, 0);
    }

    function decodeRect(
        bytes memory rectBytes,
        uint8 offsetX,
        uint8 offsetY
    ) public view returns (string memory) {
        require(rectBytes.length == 4, "Rect bytes must be 4 bytes long");
        string memory fill = getFill(uint8(rectBytes[3]));
        return
            string.concat(
                RECT_TAG_START,
                (uint8(rectBytes[0] >> 2) + offsetX).toString(),
                Y_TAG,
                (uint8(((rectBytes[0] << 4) | (rectBytes[1] >> 4)) & 0x3f) +
                    offsetY).toString(),
                WIDTH_TAG,
                uint8(((rectBytes[1] << 2) & 0x3f) | (rectBytes[2] >> 6))
                    .toString(),
                HEIGHT_TAG,
                uint8(rectBytes[2] & 0x3f).toString(),
                FILL_TAG,
                fill,
                RECT_TAG_END
            );
    }

    function decode8Rects(bytes32 rectsBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                decodeRect(
                    bytes.concat(
                        rectsBytes[0],
                        rectsBytes[1],
                        rectsBytes[2],
                        rectsBytes[3]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[4],
                        rectsBytes[5],
                        rectsBytes[6],
                        rectsBytes[7]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[8],
                        rectsBytes[9],
                        rectsBytes[10],
                        rectsBytes[11]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[12],
                        rectsBytes[13],
                        rectsBytes[14],
                        rectsBytes[15]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[16],
                        rectsBytes[17],
                        rectsBytes[18],
                        rectsBytes[19]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[20],
                        rectsBytes[21],
                        rectsBytes[22],
                        rectsBytes[23]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[24],
                        rectsBytes[25],
                        rectsBytes[26],
                        rectsBytes[27]
                    )
                ),
                decodeRect(
                    bytes.concat(
                        rectsBytes[28],
                        rectsBytes[29],
                        rectsBytes[30],
                        rectsBytes[31]
                    )
                )
            );
    }

    function decode32Rects(bytes memory rectsBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat(
                decode8Rects(BytesLib.toBytes32(rectsBytes, 0)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 32)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 64)),
                decode8Rects(BytesLib.toBytes32(rectsBytes, 96))
            );
    }

    /// @dev Decode the rect and returns it as a plain string to be used in the svg rect attribute.
    ///      One rect is 4 bytes so 8 rects is a bytes32.
    ///      With 20 bytes32, we have up to 160 rects per trait / co-bots actually if we concat the bytes first.
    ///      This magic number comes from a small data analysis of the traits. We use the fact that an empty
    ///      bytes32 will lead to an empty rect (width and height 0).
    function getTrait(bytes memory traitEncodedBytes)
        public
        view
        returns (string memory)
    {
        // buffer is 20 * 32 bytes = up to 160 rects
        bytes memory buffer = bytes.concat(
            traitEncodedBytes,
            new bytes(640 - traitEncodedBytes.length)
        );
        return
            string.concat(
                SVG_TAG_START,
                decode32Rects(BytesLib.slice(buffer, 0, 128)),
                decode32Rects(BytesLib.slice(buffer, 128, 128)),
                decode32Rects(BytesLib.slice(buffer, 256, 128)),
                decode32Rects(BytesLib.slice(buffer, 384, 128)),
                decode32Rects(BytesLib.slice(buffer, 512, 128)),
                SVG_TAG_END
            );
    }

    function getImageURI(bytes memory traitEncodedBytes)
        public
        view
        returns (string memory)
    {
        return
            string.concat("data:image/svg+xml,", getTrait(traitEncodedBytes));
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Co-bots  ////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    function getRandomItems(uint256 tokenId, uint8 seed)
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        uint256 randomBotMemory = uint256(
            keccak256(abi.encodePacked(tokenId, seed))
        );

        // Eyes
        uint256 randomEyes = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        eyesIndex = randomEyes < 25
            ? 11
            : (randomEyes < 75 ? 10 : randomEyes % 10);

        // Mouth
        uint256 randomMouth = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        mouthIndex = randomMouth < 50 ? 10 : randomMouth % 10;

        // Antenna
        uint256 randomAntenna = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        antennaIndex = randomAntenna < 50
            ? 10
            : (randomAntenna < 75 ? 11 : randomAntenna % 10);

        // Feet
        uint256 randomFeet = randomBotMemory % 10_000;
        randomBotMemory >>= 14;
        feetIndex = randomFeet < 50 ? 10 : randomFeet % 10;
    }

    function getToadItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 12, 6);
    }

    function getNounishItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 13, 0);
    }

    function getWizardItems()
        public
        pure
        returns (
            uint256 eyesIndex,
            uint256 mouthIndex,
            uint256 antennaIndex,
            uint256 feetIndex
        )
    {
        return (0, 0, 14, 9);
    }

    function getCoBotItems(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) public pure returns (uint256[10] memory) {
        uint256 eyesIndex;
        uint256 mouthIndex;
        uint256 antennaIndex;
        uint256 feetIndex;
        if (tokenId == 0) {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getToadItems();
        } else if (tokenId == 1) {
            (
                eyesIndex,
                mouthIndex,
                antennaIndex,
                feetIndex
            ) = getNounishItems();
        } else if (tokenId == 2) {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getWizardItems();
        } else {
            (eyesIndex, mouthIndex, antennaIndex, feetIndex) = getRandomItems(
                tokenId,
                seed
            );
        }

        uint256[10] memory items;
        // 0. Colour
        items[0] = color ? 0 : 1;
        // 1. Digit 1
        items[1] = tokenId / 1000;
        // 2. Digit 2
        items[2] = (tokenId / 100) % 10;
        // 3. Digit 3
        items[3] = (tokenId / 10) % 10;
        // 4. Digit 4
        items[4] = tokenId % 10;
        // 5. Eyes
        items[5] = eyesIndex;
        // 6. Mouth
        items[6] = mouthIndex;
        // 7. Antenna
        items[7] = antennaIndex;
        // 8. Status
        items[8] = status ? 1 : 0;
        // 9. Feet
        items[9] = feetIndex;
        return items;
    }

    function getCoBotBytes(uint256[10] memory items)
        public
        view
        returns (bytes memory)
    {
        return
            bytes.concat(
                getTraitBytes(getTraitIndex(0, items[0])),
                getTraitBytes(getTraitIndex(1, items[1])),
                getTraitBytes(getTraitIndex(2, items[2])),
                getTraitBytes(getTraitIndex(3, items[3])),
                getTraitBytes(getTraitIndex(4, items[4])),
                getTraitBytes(getTraitIndex(5, items[5])),
                getTraitBytes(getTraitIndex(6, items[6])),
                getTraitBytes(getTraitIndex(7, items[7])),
                items[8] == 1
                    ? new bytes(4)
                    : getTraitBytes(getTraitIndex(8, items[8])),
                getTraitBytes(getTraitIndex(9, items[9]))
            );
    }

    function getCoBotImageURI(uint256[10] memory items)
        public
        view
        returns (string memory)
    {
        return getImageURI(getCoBotBytes(items));
    }

    function getCoBotAttributes(
        uint256[10] memory items,
        bool status,
        bool color
    ) public pure returns (string memory) {
        string[12] memory eyes = [
            "Classic", // 0
            "Cyclops", // 1
            "Awoken", // 2
            "Flirty", // 3
            "Zen", // 4
            "Sadhappy", // 5
            "Unaligned", // 6
            "Smitten", // 7
            "Optimistic", // 8
            "Hacky", // 9
            "Super", // 50 times
            "Nounish" // 25 times
        ];
        string[11] memory mouths = [
            "Classic", // 0
            "Worried", // 1
            "Knightly", // 2
            "Shy", // 3
            "Happy", // 4
            "Bigsad", // 5
            "Smug", // 6
            "Wowed", // 7
            "Thirsty", // 8
            "Villainous", // 9
            "Shady" // 50 times
        ];
        string[15] memory antennas = [
            "Classic", // 0
            "Serious", // 1
            "Jumpy", // 2
            "Buzzed", // 3
            "Buggy", // 4
            "Punk", // 5
            "Angelic", // 6
            "Impish", // 7
            "Humbled", // 8
            "Western", // 9
            "Royal", // 50 times
            "Hacky", // 25 times
            "!croak", // 1 time
            "Nounish", // 1 time
            "Wizard" // 1 time
        ];
        string[11] memory feet = [
            "Classic", // 0
            "Heavy Duty", // 1
            "Firey", // 2
            "Little Firey", // 3
            "Roller", // 4
            "Little Roller", // 5
            "Energetic", // 6
            "Little Energetic", // 7
            "Hobbled", // 8
            "Ghostly", // 9
            "Pushy" // 50 times
        ];
        return
            string.concat(
                "[",
                items[7] > 11 ? "" : '{"trait_type": "Eyes", "value": "',
                items[7] > 11 ? "" : eyes[items[5]],
                items[7] > 11 ? "" : '"},',
                items[7] > 11 ? "" : '{"trait_type": "Mouth", "value": "',
                items[7] > 11 ? "" : mouths[items[6]],
                items[7] > 11 ? "" : '"},',
                '{"trait_type": "Antenna", "value": "',
                antennas[items[7]],
                '"},',
                '{"trait_type": "Feet", "value": "',
                feet[items[9]],
                '"},',
                '{"trait_type": "Status", "value": "',
                status ? "Online" : "Offline",
                '"},',
                '{"trait_type": "Color", "value": "',
                color ? "Blue" : "Red",
                '"}',
                "]"
            );
    }

    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) public view returns (string memory) {
        uint256[10] memory items = getCoBotItems(tokenId, seed, status, color);
        return
            string.concat(
                "data:application/json,",
                '{"image_data": "',
                getCoBotImageURI(items),
                '"',
                ',"description": "Co-Bots are cooperation robots | CC0 & 100% On-Chain | co-bots.com."',
                ',"name": "Co-Bot #',
                tokenId.toString(),
                '"',
                ',"attributes": ',
                getCoBotAttributes(items, status, color),
                "}"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
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

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < count; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }

    /**
     * Load 16
     *
     * Converts two bytes to a 16 bit unsigned integer
     *
     * @param _leadingBytes the first byte of the unsigned integer in [256, 65536]
     * @param _endingBytes the second byte of the unsigned integer in [0, 255]
     * @return uint16 The resulting integer value
     */
    function load16(bytes1 _leadingBytes, bytes1 _endingBytes)
        public
        pure
        returns (uint16)
    {
        return
            (uint16(uint8(_leadingBytes)) << 8) + uint16(uint8(_endingBytes));
    }

    /**
     * Load 12
     *
     * Converts three bytes into two uint12 integers
     *
     * @return (uint16, uint16) The two uint16 values up to 2^12 each
     */
    function load12x2(
        bytes1 first,
        bytes1 second,
        bytes1 third
    ) public pure returns (uint16, uint16) {
        return (
            (uint16(uint8(first)) << 4) + (uint16(uint8(second)) >> 4),
            (uint16(uint8(second & hex"0f")) << 8) + uint16(uint8(third))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ICoBotsRenderer {
    function tokenURI(
        uint256 tokenId,
        uint8 seed,
        bool status,
        bool color
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
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