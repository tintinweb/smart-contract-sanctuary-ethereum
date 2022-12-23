// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// a16z Contracts v0.0.1 (CantBeEvil.sol)
pragma solidity 0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/ICantBeEvil.sol";

enum LicenseVersion {
    PUBLIC,
    EXCLUSIVE,
    COMMERCIAL,
    COMMERCIAL_NO_HATE,
    PERSONAL,
    PERSONAL_NO_HATE
}

contract CantBeEvil is ERC165, ICantBeEvil {
    using Strings for uint256;
    string internal constant _BASE_LICENSE_URI =
        "ar://zmc1WTspIhFyVY82bwfAIcIExLFH5lUcHHUN0wXg4W8/";
    LicenseVersion internal licenseVersion;

    constructor(LicenseVersion _licenseVersion) {
        licenseVersion = _licenseVersion;
    }

    function getLicenseURI() public view returns (string memory) {
        return
            string.concat(
                _BASE_LICENSE_URI,
                uint256(licenseVersion).toString()
            );
    }

    function getLicenseName() public view returns (string memory) {
        return _getLicenseVersionKeyByValue(licenseVersion);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICantBeEvil).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getLicenseVersionKeyByValue(LicenseVersion _licenseVersion)
        internal
        pure
        returns (string memory)
    {
        require(uint8(_licenseVersion) <= 6);
        if (LicenseVersion.PUBLIC == _licenseVersion) return "PUBLIC";
        if (LicenseVersion.EXCLUSIVE == _licenseVersion) return "EXCLUSIVE";
        if (LicenseVersion.COMMERCIAL == _licenseVersion) return "COMMERCIAL";
        if (LicenseVersion.COMMERCIAL_NO_HATE == _licenseVersion)
            return "COMMERCIAL_NO_HATE";
        if (LicenseVersion.PERSONAL == _licenseVersion) return "PERSONAL";
        else return "PERSONAL_NO_HATE";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {EquipmentRarity, EquipmentType} from "./interfaces/IAnomuraEquipment.sol";
import {LicenseVersion, CantBeEvil} from "./CantBeEvil.sol";

interface IEquipmentData {
    function pluckType(uint256) external view returns (EquipmentType);

    function pluckBody(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckClaws(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckLegs(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckShell(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckHeadpieces(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckHabitat(uint256)
        external
        view
        returns (string memory, EquipmentRarity);
}

contract EquipmentData is IEquipmentData, CantBeEvil {
  
    string[] public BODY_PARTS = [
        "Premier Body",
        "Unhinged Body",
        "Mesmerizing Body",
        "Rave Body",
        "Combustion Body",
        "Radiating Eye",
        "Charring Body",
        "Inferno Body",
        "Siberian Body",
        "Antarctic Body",
        "Glacial Body",
        "Amethyst Body",
        "Beast",
        "Panga Panga",
        "Ceylon Ebony",
        "Katalox",
        "Diamond",
        "Golden"
    ];
    string[] public CLAW_PARTS = [
        "Natural Claw",
        "Coral Claw",
        "Titian Claw",
        "Pliers",
        "Scissorhands",
        "Laser Gun",
        "Snow Claw",
        "Sky Claw",
        "Icicle Claw",
        "Pincers",
        "Hammer Logs",
        "Carnivora Claw"
    ];
    string[] public LEGS_PARTS = [
        "Argent Leg",
        "Sunlit Leg",
        "Auroral Leg",
        "Steel Leg",
        "Tungsten Leg",
        "Titanium Leg",
        "Crystal Leg",
        "Empyrean Leg",
        "Azure Leg",
        "Bamboo Leg",
        "Walmara Leg",
        "Pintobortri Leg"
    ];
    string[] public SHELL_PARTS = [
        "Auger Shell",
        "Seasnail Shell",
        "Miter Shell",
        "Alembic",
        "Chimney",
        "Starship",
        "Ice Cube",
        "Ice Shell",
        "Frosty",
        "Mora",
        "Carnivora",
        "Pure Runes",
        "Architect",
        "Bee Hive",
        "Coral",
        "Crystal",
        "Diamond",
        "Ethereum",
        "Golden Skull",
        "Japan Temple",
        "Planter",
        "Snail",
        "Tentacles",
        "Tesla Coil",
        "Cherry Blossom",
        "Maple Green",
        "Volcano",
        "Gates of Hell",
        "Holy Temple",
        "ZED Skull"
    ];
    string[] public HEADPIECES_PARTS = [
        "Morning Sun Starfish",
        "Granulated Starfish",
        "Royal Starfish",
        "Sapphire",
        "Emerald",
        "Kunzite",
        "Rhodonite",
        "Aventurine",
        "Peridot",
        "Moldavite",
        "Jasper",
        "Alexandrite",
        "Copper Fire",
        "Chemical Fire",
        "Carmine Fire",
        "Charon",
        "Deimos",
        "Ganymede",
        "Sol",
        "Sirius",
        "Lyra",
        "Aconite Skull",
        "Titan Arum Skull",
        "Nerium Oleander Skull"
    ];
    string[] public HABITAT_PARTS = [
        "Crystal Cave",
        "Crystal Cave Rainbow",
        "Emerald Forest",
        "Garden of Eden",
        "Golden Glade",
        "Beach",
        "Magical Deep Sea",
        "Natural Sea",
        "Bioluminescent Abyss",
        "Blazing Furnace",
        "Steam Apparatus",
        "Science Lab",
        "Starship Throne",
        "Happy Snowfield",
        "Midnight Mountain",
        "Cosmic Star",
        "Sunset Cliffs",
        "Space Nebula",
        "Plains of Vietnam",
        "ZED Run",
        "African Savannah"
    ];
    string[] public PREFIX_ATTRS = [
        "Briny",
        "Tempestuous",
        "Limpid",
        "Pacific",
        "Atlantic",
        "Abysmal",
        "Profound",
        "Misty",
        "Solar",
        "Empyrean",
        "Sideral",
        "Astral",
        "Ethereal",
        "Crystal",
        "Quantum",
        "Empiric",
        "Alchemic",
        "Crash Test",
        "Nuclear",
        "Syntethic",
        "Tempered",
        "Fossil",
        "Craggy",
        "Gemmed",
        "Verdant",
        "Lymphatic",
        "Gnarled",
        "Lithic"
    ];
    string[] public SUFFIX_ATTRS = [
        "of the Coast",
        "of Maelstrom",
        "of Depths",
        "of Eternity",
        "of Peace",
        "of Equilibrium",
        "of the Universe",
        "of the Galaxy",
        "of Absolute Zero",
        "of Constellations",
        "of the Moon",
        "of Lightspeed",
        "of Evidence",
        "of Relativity",
        "of Evolution",
        "of Consumption",
        "of Progress",
        "of Damascus",
        "of Gaia",
        "of The Wild",
        "of Overgrowth",
        "of Rebirth",
        "of World Roots",
        "of Stability"
    ];
    string[] public UNIQUE_ATTRS = [
        "The Leviathan",
        "Will of Oceanus",
        "Suijin's Touch",
        "Tiamat Kiss",
        "Poseidon Vow",
        "Long bao",
        "Uranus Wish",
        "Aim of Indra",
        "Cry of Yuki Onna",
        "Sirius",
        "Vega",
        "Altair",
        "Ephestos Skill",
        "Gift of Prometheus",
        "Pandora's",
        "Wit of Lu Dongbin",
        "Thoth's Trick",
        "Cyclopes Plan",
        "Root of Dimu",
        "Bhumi's Throne",
        "Rive of Daphne",
        "The Minotaur",
        "Call of Cernunnos",
        "Graze of Terra"
    ];
    string[] public BACKGROUND_PREFIX_ATTRS = [
        "Bountiful",
        "Isolated",
        "Mechanical",
        "Reborn"
    ];

    constructor() 
    CantBeEvil(LicenseVersion.PUBLIC)
    {}

    /* 
    1 / 25 = 4% headpieces => 96% rest, for 5 other parts
    0       -     191 = BODY
    192     -     383 = CLAWS
    384     -     575 = LEGS
    576     -     767 = SHELL
    768     -     959 = HABITAT
    960     -     999 - HEADPIECES
    */
    function pluckType(uint256 prob)
        external
        pure
        returns (EquipmentType typeOf)
    {
        uint256 rand = prob % 1000;

        if (rand < 192) typeOf = EquipmentType.BODY;
        else if (rand < 192 * 2) typeOf = EquipmentType.CLAWS;
        else if (rand < 192 * 3) typeOf = EquipmentType.LEGS;
        else if (rand < 192 * 4) typeOf = EquipmentType.SHELL;
        else if (rand < 192 * 5) typeOf = EquipmentType.HABITAT;
        else typeOf = EquipmentType.HEADPIECES;
    }

    function pluckBody(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.BODY);
    }

    function pluckClaws(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.CLAWS);
    }

    function pluckLegs(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.LEGS);
    }

    function pluckShell(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.SHELL);
    }

    function pluckHeadpieces(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(
            prob,
            EquipmentType.HEADPIECES
        );
    }

    function pluckHabitat(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluckBackground(prob);
    }

    function pluckBackground(uint256 _seed)
        internal
        view
        returns (string memory output, EquipmentRarity)
    {
        uint256 randomCount = 0;
        uint256 greatness = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        ) % 51;
        uint256 randNameSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );
        uint256 randPartSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );

        output = HABITAT_PARTS[randNameSeed % HABITAT_PARTS.length];

        if (greatness > 45) {
            output = string(
                abi.encodePacked(
                    BACKGROUND_PREFIX_ATTRS[
                        randPartSeed % BACKGROUND_PREFIX_ATTRS.length
                    ],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.RARE);
        }
        return (output, EquipmentRarity.NORMAL); // does not have any special attributes
    }

    function pluck(uint256 _seed, EquipmentType typeOf)
        internal
        view
        returns (string memory output, EquipmentRarity)
    {
        uint256 randomCount = 0;
        uint256 greatness = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        ) % 94;
        uint256 randNameSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );
        uint256 randPartSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );

        if (typeOf == EquipmentType.BODY) {
            output = BODY_PARTS[randNameSeed % BODY_PARTS.length];
        } else if (typeOf == EquipmentType.CLAWS) {
            output = CLAW_PARTS[randNameSeed % CLAW_PARTS.length];
        } else if (typeOf == EquipmentType.LEGS) {
            output = LEGS_PARTS[randNameSeed % LEGS_PARTS.length];
        } else if (typeOf == EquipmentType.SHELL) {
            output = SHELL_PARTS[randNameSeed % SHELL_PARTS.length];
        } else if (typeOf == EquipmentType.HEADPIECES) {
            output = HEADPIECES_PARTS[randNameSeed % HEADPIECES_PARTS.length];
        } else if (typeOf == EquipmentType.HABITAT) {
            output = HABITAT_PARTS[randNameSeed % HABITAT_PARTS.length];
        }

        if (greatness > 92) {
            output = string(
                abi.encodePacked(
                    UNIQUE_ATTRS[randPartSeed % UNIQUE_ATTRS.length],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.LEGENDARY);
        }

        if (greatness > 83) {
            output = string(
                abi.encodePacked(
                    PREFIX_ATTRS[randPartSeed % PREFIX_ATTRS.length],
                    " ",
                    output,
                    " ",
                    SUFFIX_ATTRS[randPartSeed % SUFFIX_ATTRS.length]
                )
            );
            return (output, EquipmentRarity.RARE);
        }

        if (greatness > 74) {
            output = string(
                abi.encodePacked(
                    output,
                    " ",
                    SUFFIX_ATTRS[randPartSeed % SUFFIX_ATTRS.length]
                )
            );
            return (output, EquipmentRarity.MAGIC);
        }

        if (greatness > 65) {
            output = string(
                abi.encodePacked(
                    PREFIX_ATTRS[randPartSeed % PREFIX_ATTRS.length],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.MAGIC);
        }
        return (output, EquipmentRarity.NORMAL); // does not have any special attributes
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {IERC721AUpgradeable} from "./IERC721AUpgradeable.sol";

interface IAnomuraEquipment is IERC721AUpgradeable { 
    function isTokenExists(uint256 _tokenId) external view returns(bool); 
    function isMetadataReveal(uint256 _tokenId) external view returns(bool);
    function revealMetadataForToken(bytes calldata performData) external; 
}

// This will likely change in the future, this should not be used to store state, or can only use inside a mapping
struct EquipmentMetadata {
    string name;
    EquipmentType equipmentType;
    EquipmentRarity equipmentRarity;
}

/// @notice equipment information
enum EquipmentType {
    BODY,
    CLAWS,
    LEGS,
    SHELL,
    HEADPIECES,
    HABITAT
}

/// @notice rarity information
enum EquipmentRarity {
    NORMAL,
    MAGIC,
    RARE,
    LEGENDARY 
}

// SPDX-License-Identifier: MIT
// a16z Contracts v0.0.1 (ICantBeEvil.sol)
pragma solidity 0.8.13;

interface ICantBeEvil {
    function getLicenseURI() external view returns (string memory);
    function getLicenseName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721AUpgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}