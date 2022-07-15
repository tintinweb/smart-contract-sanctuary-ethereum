// SPDX-License-Identifier: MIT

/// @title Outsiders DNA
/// @author patrick piemonte

// ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓
// ▓ ▒                           ▓ ▒
// ▒          ████  ████           ▓
// ▓        ██  ████  ████         ▒
// ▒      ███    ███████████       ▓
// ▓      ████  ████████ ███       ▒
// ▒        ██████████ ███         ▓
// ▓          ██████ ███           ▒
// ▒            ███ ██             ▓
// ▓              ██               ▒
// ▒ ▓                           ▒ ▓
// ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒

pragma solidity >=0.8.10 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOutsidersDNA} from "./interfaces/IOutsidersDNA.sol";

contract OutsidersDNA is IOutsidersDNA, Ownable {
    uint256[10000] public outsidersDna;
    string[600] public traitMap = [
        "", // NOOP
        unicode"♈️ Aries",
        unicode"♉️ Taurus",
        unicode"♊️ Gemini",
        unicode"♋️ Cancer",
        unicode"♌️ Leo",
        unicode"♍️ Virgo",
        unicode"♎️ Libra",
        unicode"♏️ Scorpio",
        unicode"♐️ Sagittarius",
        unicode"♑️ Capricorn",
        unicode"♒️ Aquarius",
        unicode"♓️ Pisces"
        unicode"🌊 Wreck",
        unicode"🍌 Troop",
        unicode"🐾 Pack",
        unicode"💥 Mob"
    ];

    // Bitwise constants
    uint256 private constant OUTSIDER_ORDER_DNA_POSITION = 0;
    uint256 private constant OUTSIDER_SPECIES_DNA_POSITION = 5;
    uint256 private constant OUTSIDER_PERSONALITY_DNA_POSITION = 10;
    uint256 private constant OUTSIDER_FIT_DNA_POSITION = 15;
    uint256 private constant OUTSIDER_LID_DNA_POSITION = 20;
    uint256 private constant OUTSIDER_FACE_DNA_POSITION = 25;
    uint256 private constant OUTSIDER_BACKGROUND_DNA_POSITION = 30;
    uint256 private constant OUTSIDER_TYPE_DNA_POSITION = 35;
    uint256 private constant OUTSIDER_PHENOMENA_DNA_POSITION = 40;
    uint256 private constant OUTSIDER_SPY_DNA_POSITION = 45;
    uint256 private constant OUTSIDER_INIMITABLE_DNA_POSITION = 50;
    uint256 private constant OUTSIDER_ZODIAC_DNA_POSITION = 55;
    uint256 private constant OUTSIDER_AIRDROP_DNA_POSITION = 60;
    uint256 private constant OUTSIDER_LAYER_COUNT_DNA_POSITION = 65;
    uint256 private constant OUTSIDER_LAYERS_DNA_POSITION = 70;

    uint256 private constant OUTSIDER_LAYERS_DNA_SIZE = 12;

    uint256 private constant OUTSIDER_ORDER_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_SPECIES_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_PERSONALITY_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_FIT_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_LID_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_FACE_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_BACKGROUND_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_TYPE_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_PHENOMENA_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_SPY_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_INIMITABLE_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_ZODIAC_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_AIRDROP_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_LAYER_COUNT_DNA_BITMASK = uint256(0x1F);
    uint256 private constant OUTSIDER_LAYERS_DNA_BITMASK = uint256(0x0FFF);

    /**
     * @notice Specify a trait value to be referenced by all Outsider DNAs.
     * @dev Example: "💥 Mob" at index 3.
     */
    function setTraits(uint256[] memory indexes, string[] memory values)
        external
        onlyOwner
    {
        require(
            indexes.length == values.length,
            "Number of indexes must match values."
        );

        for (uint256 idx; idx < indexes.length; idx++) {
            uint256 index = indexes[idx];
            // Note: we reserve trait at index 0 as a NOOP
            if (index == 0) {
                continue;
            }
            traitMap[index] = values[idx];
        }
    }

    struct OutsiderCharacterTraitInput {
        // Base character traits
        uint16 order;
        uint16 species;
        uint16 personality;
        uint16 fit;
        uint16 lid;
        uint16 face;
        uint16 background;
        uint16 outsiderType;
        uint16 phenomena;
        uint16 zodiac;
        // Enhanced traits
        uint16 spy;
        uint16 inimitable;
        uint16 airdrop;
    }

    /**
     * @notice Specify the traits that compose the DNA.
     * @dev Only callable by the owner.
     * @param tokenIds – token ids of which to update
     * @param traits – traits to assign to the corresponding token id
     * @param layers – layer keys to assign to the corresponding token id
     */
    function setOutsiderTraits(
        uint256[] memory tokenIds,
        OutsiderCharacterTraitInput[] memory traits,
        uint16[][] memory layers
    ) external onlyOwner {
        require(
            tokenIds.length == traits.length &&
                tokenIds.length == layers.length,
            "Number of indexes must match all fields"
        );
        for (uint8 idx; idx < tokenIds.length; idx++) {
            // setup base traits
            uint256 dna = ((uint256(traits[idx].order) <<
                OUTSIDER_ORDER_DNA_POSITION) +
                (uint256(traits[idx].species) <<
                    OUTSIDER_SPECIES_DNA_POSITION) +
                (uint256(traits[idx].personality) <<
                    OUTSIDER_PERSONALITY_DNA_POSITION) +
                (uint256(traits[idx].fit) << OUTSIDER_FIT_DNA_POSITION) +
                (uint256(traits[idx].lid) << OUTSIDER_LID_DNA_POSITION) +
                (uint256(traits[idx].face) << OUTSIDER_FACE_DNA_POSITION) +
                (uint256(traits[idx].background) <<
                    OUTSIDER_BACKGROUND_DNA_POSITION) +
                (uint256(traits[idx].outsiderType) <<
                    OUTSIDER_TYPE_DNA_POSITION) +
                (uint256(traits[idx].phenomena) <<
                    OUTSIDER_ORDER_DNA_POSITION) +
                (uint256(traits[idx].zodiac) << OUTSIDER_ZODIAC_DNA_POSITION));
            // setup enhanced traits
            dna +=
                (uint256(traits[idx].spy) << OUTSIDER_SPY_DNA_POSITION) +
                (uint256(traits[idx].inimitable) <<
                    OUTSIDER_INIMITABLE_DNA_POSITION) +
                (uint256(traits[idx].airdrop) << OUTSIDER_AIRDROP_DNA_POSITION);

            // setup layers
            dna += (uint256(layers[idx].length) <<
                OUTSIDER_LAYER_COUNT_DNA_POSITION);
            for (
                uint16 layerIdx = 0;
                layerIdx < layers[idx].length;
                layerIdx++
            ) {
                dna +=
                    uint256(layers[idx][layerIdx]) <<
                    (OUTSIDER_LAYERS_DNA_SIZE *
                        layerIdx +
                        OUTSIDER_LAYERS_DNA_POSITION);
            }

            // write dna
            uint256 index = tokenIds[idx];
            outsidersDna[index] = dna;
        }
    }

    /**
     * @notice Get the trait values for an Outsider.
     */
    function getOutsiderTraits(uint256 tokenId)
        external
        view
        override
        returns (OutsiderTraits memory)
    {
        require(tokenId < 10000, "Invalid tokenId");

        uint256 dna = outsidersDna[tokenId];
        require(dna > 0, "Outsider DNA missing for token");

        OutsiderTraits memory traits = OutsiderTraits(
            traitMap[
                (dna >> OUTSIDER_ORDER_DNA_POSITION) &
                    OUTSIDER_ORDER_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_SPECIES_DNA_POSITION) &
                    OUTSIDER_SPECIES_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_TYPE_DNA_POSITION) & OUTSIDER_TYPE_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_PERSONALITY_DNA_POSITION) &
                    OUTSIDER_PERSONALITY_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_FIT_DNA_POSITION) & OUTSIDER_FIT_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_LID_DNA_POSITION) & OUTSIDER_LID_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_FACE_DNA_POSITION) & OUTSIDER_FACE_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_BACKGROUND_DNA_POSITION) &
                    OUTSIDER_BACKGROUND_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_PHENOMENA_DNA_POSITION) &
                    OUTSIDER_PHENOMENA_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_SPY_DNA_POSITION) & OUTSIDER_SPY_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_ZODIAC_DNA_POSITION) &
                    OUTSIDER_ZODIAC_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_INIMITABLE_DNA_POSITION) &
                    OUTSIDER_INIMITABLE_DNA_BITMASK
            ],
            traitMap[
                (dna >> OUTSIDER_AIRDROP_DNA_POSITION) &
                    OUTSIDER_AIRDROP_DNA_BITMASK
            ]
        );

        return traits;
    }

    /**
     * @notice Get the renderable layer indexes for an Outsider.
     */
    function getOutsiderLayers(uint256 tokenId)
        external
        view
        override
        returns (uint16[] memory layers)
    {
        require(tokenId < 10000, "Invalid tokenId");

        uint256 dna = outsidersDna[tokenId];
        require(dna > 0, "Outsider DNA missing for token");

        uint256 layerCount = (dna >> OUTSIDER_LAYER_COUNT_DNA_POSITION) &
            OUTSIDER_LAYER_COUNT_DNA_BITMASK;
        uint16[] memory layersToReturn = new uint16[](layerCount);
        for (uint256 layerIdx; layerIdx < layerCount; layerIdx++) {
            layersToReturn[layerIdx] = uint16(
                (dna >>
                    (OUTSIDER_LAYERS_DNA_SIZE *
                        layerIdx +
                        OUTSIDER_LAYERS_DNA_POSITION)) &
                    OUTSIDER_LAYERS_DNA_BITMASK
            );
        }
        return layersToReturn;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

/// @title Outsiders DNA interface
/// @author patrick piemonte

// ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓ ░ ▒ ▓
// ▓ ▒                           ▓ ▒
// ▒          ████  ████           ▓
// ▓        ██  ████  ████         ▒
// ▒      ███    ███████████       ▓
// ▓      ████  ████████ ███       ▒
// ▒        ██████████ ███         ▓
// ▓          ██████ ███           ▒
// ▒            ███ ██             ▓
// ▓              ██               ▒
// ▒ ▓                           ▒ ▓
// ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒ ░ ▓ ▒

pragma solidity >=0.8.10 <0.9.0;

interface IOutsidersDNA {
    struct OutsiderTraits {
        string order;
        string species;
        string personality;
        string fit;
        string lid;
        string face;
        string background;
        string outsiderType;
        string phenomena;
        string spy;
        string inimitable;
        string zodiac;
        string airdrop;
    }

    function getOutsiderTraits(uint256 tokenId)
        external
        view
        returns (OutsiderTraits memory);

    function getOutsiderLayers(uint256 tokenId)
        external
        view
        returns (uint16[] memory layers);
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