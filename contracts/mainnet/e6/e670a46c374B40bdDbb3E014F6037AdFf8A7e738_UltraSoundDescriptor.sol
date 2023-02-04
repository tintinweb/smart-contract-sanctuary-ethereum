// SPDX-License-Identifier: MIT

/// @title Ultra Sound Editions Descriptor
/// @author -wizard

// Inspired by - Nouns DAO and .merge by pak

pragma solidity ^0.8.6;

import {IUltraSoundParts} from "./interfaces/IUltraSoundParts.sol";
import {IUltraSoundGridRenderer} from "./interfaces/IUltraSoundGridRenderer.sol";
import {IUltraSoundDescriptor} from "./interfaces/IUltraSoundDescriptor.sol";
import {IUltraSoundEditions} from "./interfaces/IUltraSoundEditions.sol";
import {Base64} from "./libs/Base64.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract UltraSoundDescriptor is IUltraSoundDescriptor, Ownable {
    using Strings for *;

    struct MetadataStructure {
        string name;
        string description;
        string createdBy;
        string image;
        MetadataAttribute[] attributes;
    }

    struct MetadataAttribute {
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }

    IUltraSoundParts public parts;
    IUltraSoundGridRenderer public renderer;

    IUltraSoundGridRenderer.Override[] private overrides;
    IUltraSoundGridRenderer.Override[] private ultraSoundEdition;

    bool public isDataURIEnabled = true;
    string public baseURI;

    constructor(IUltraSoundParts _parts, IUltraSoundGridRenderer _renderer) {
        parts = _parts;
        renderer = _renderer;
        overrides.push(
            IUltraSoundGridRenderer.Override({
                symbols: 2,
                positions: 78,
                colors: "#B5BDDB",
                size: 0
            })
        );
        overrides.push(
            IUltraSoundGridRenderer.Override({
                symbols: 3,
                positions: 79,
                colors: "#B5BDDB",
                size: 0
            })
        );

        ultraSoundEdition.push(
            IUltraSoundGridRenderer.Override({
                symbols: 4,
                positions: 35,
                colors: "",
                size: 1
            })
        );
        ultraSoundEdition.push(
            IUltraSoundGridRenderer.Override({
                symbols: 5,
                positions: 51,
                colors: "url(#lg1)",
                size: 0
            })
        );
        ultraSoundEdition.push(
            IUltraSoundGridRenderer.Override({
                symbols: 6,
                positions: 52,
                colors: "url(#lg1)",
                size: 0
            })
        );
    }

    function toggleDataURIEnabled() external onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    function setParts(IUltraSoundParts _parts) external override onlyOwner {
        parts = _parts;
        emit PartsUpdated(_parts);
    }

    function setRenderer(IUltraSoundGridRenderer _renderer) external onlyOwner {
        renderer = _renderer;
        emit RendererUpdated(_renderer);
    }

    function palettesCount() external view override returns (uint256) {
        return parts.palettesCount();
    }

    function symbolsCount() external view override returns (uint256) {
        return parts.symbolsCount();
    }

    function gradientsCount() external view override returns (uint256) {
        return parts.gradientsCount();
    }

    function quantitiesCount() external view override returns (uint256) {
        return parts.quantityCount();
    }

    function tokenURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) external view returns (string memory) {
        if (isDataURIEnabled) return dataURI(tokenId, edition);
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function _formatData(IUltraSoundEditions.Edition memory edition, uint8 size)
        internal
        pure
        returns (IUltraSoundGridRenderer.Symbol memory)
    {
        return
            IUltraSoundGridRenderer.Symbol({
                id: edition.burned ? 7 : 1,
                gridPalette: 0,
                gridSize: size,
                seed: edition.seed,
                level: edition.level,
                palette: edition.palette,
                opaque: edition.ultraSound || edition.level < 5 ? true : false
            });
    }

    function tokenSVG(IUltraSoundEditions.Edition memory edition, uint8 size)
        external
        view
        returns (string memory)
    {
        return
            renderer.generateGrid(
                _formatData(edition, size),
                _getOverrides(edition.ultraSound, edition.level),
                _getGradients(edition.level, edition.seed),
                edition.ultraEdition
            );
    }

    function dataURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) public view returns (string memory) {
        bytes memory name = abi.encodePacked(
            "proof of stake #",
            tokenId.toString()
        );

        if (edition.level == 7) {
            name = abi.encodePacked(
                "ultra sound edition #",
                edition.ultraEdition.toString()
            );
        } else if (edition.burned) {
            name = abi.encodePacked("proof of burn #", tokenId.toString());
        }
        MetadataStructure memory metadata = MetadataStructure({
            name: string(name),
            description: string(
                abi.encodePacked(
                    "may or may not be ultra sound\\n\\nby -wizard\\n\\n",
                    "[inventory](https://ultrasoundeditions.com/inventory) | ",
                    "[swap](https://ultrasoundeditions.com/inventory/",
                    tokenId.toString(),
                    "/swap) | [merge](https://ultrasoundeditions.com/inventory/",
                    tokenId.toString(),
                    "/merge)"
                )
            ),
            createdBy: "-wizard",
            image: renderer.generateGrid(
                _formatData(edition, 1),
                _getOverrides(edition.ultraSound, edition.level),
                _getGradients(edition.level, edition.seed),
                edition.ultraEdition
            ),
            attributes: _getJsonAttributes(edition)
        });

        // prettier-ignore
        string memory base64Json = Base64.encode(bytes(string(_generateMetadata(metadata))));
        // prettier-ignore
        return string(abi.encodePacked("data:application/json;base64,", base64Json));
    }

    function _getOverrides(bool ultraSound, uint256 level)
        private
        view
        returns (IUltraSoundGridRenderer.Override[] memory o)
    {
        if (ultraSound && level != 7) o = overrides;
        else if (ultraSound && level == 7) o = ultraSoundEdition;
        else o = new IUltraSoundGridRenderer.Override[](0);
    }

    function _getGradients(uint256 level, uint256 seed)
        private
        view
        returns (uint256)
    {
        if (level != 7) return 0;
        else return ((seed % (parts.gradientsCount() - 1)) + 1);
    }

    function _generateMetadata(MetadataStructure memory metadata)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true)
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "description",
                metadata.description,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "created_by",
                metadata.createdBy,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "image_data",
                metadata.image,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute(
                "attributes",
                _getAttributes(metadata.attributes),
                false
            )
        );

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(MetadataAttribute[] memory attributes)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonArray());

        for (uint256 i = 0; i < attributes.length; i++) {
            MetadataAttribute memory attribute = attributes[i];

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(
                    _getAttribute(attribute),
                    i < (attributes.length - 1)
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(MetadataAttribute memory attribute)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "display_type",
                attribute.displayType,
                true
            )
        );

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute(
                "trait_type",
                attribute.traitType,
                true
            )
        );

        if (attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute(
                    "value",
                    attribute.value,
                    false
                )
            );
        }

        byteString = abi.encodePacked(byteString, _closeJsonObject());

        return string(byteString);
    }

    function _getJsonAttributes(IUltraSoundEditions.Edition memory edition)
        private
        pure
        returns (MetadataAttribute[] memory)
    {
        // prettier-ignore
        MetadataAttribute[] memory metadataAttributes = new MetadataAttribute[](6);

        metadataAttributes[0] = _getMetadataAttribute(
            false,
            "number",
            "Block Number",
            edition.blockNumber.toString()
        );
        metadataAttributes[1] = _getMetadataAttribute(
            false,
            "date",
            "Block Time",
            edition.blockTime.toString()
        );
        metadataAttributes[2] = _getMetadataAttribute(
            false,
            "number",
            "Base Fee",
            edition.baseFee.toString()
        );
        metadataAttributes[3] = _getMetadataAttribute(
            false,
            "number",
            "Merge Count",
            edition.mergeCount.toString()
        );
        metadataAttributes[4] = _getMetadataAttribute(
            true,
            "string",
            "Ultra Sound",
            edition.ultraSound ? "True" : "False"
        );
        metadataAttributes[5] = _getMetadataAttribute(
            false,
            "number",
            "Level",
            edition.level.toString()
        );

        return metadataAttributes;
    }

    function _getMetadataAttribute(
        bool isValueAString,
        string memory displayType,
        string memory traitType,
        string memory value
    ) private pure returns (MetadataAttribute memory) {
        MetadataAttribute memory attribute = MetadataAttribute({
            isValueAString: isValueAString,
            displayType: displayType,
            traitType: traitType,
            value: value
        });

        return attribute;
    }

    function _openJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"',
                    key,
                    '": "',
                    value,
                    '"',
                    insertComma ? "," : ""
                )
            );
    }

    function _pushJsonComplexAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonPrimitiveNonStringAttribute(
        string memory key,
        string memory value,
        bool insertComma
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked('"', key, '": ', value, insertComma ? "," : "")
            );
    }

    function _pushJsonArrayElement(string memory value, bool insertComma)
        private
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(value, insertComma ? "," : ""));
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Parts
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundParts {
    error SenderIsNotDescriptor();
    error PartNotFound();

    event SymbolAdded();
    event PaletteAdded();
    event GradientAdded();

    function addSymbol(bytes calldata data) external;

    function addSymbols(bytes[] calldata data) external;

    function addPalette(bytes calldata data) external;

    function addPalettes(bytes[] calldata data) external;

    function addGradient(bytes calldata data) external;

    function addGradients(bytes[] calldata data) external;

    function symbols(uint256 index) external view returns (bytes memory);

    function palettes(uint256 index) external view returns (bytes memory);

    function gradients(uint256 index) external view returns (bytes memory);

    function quantities(uint256 index) external view returns (uint16);

    function symbolsCount() external view returns (uint256);

    function palettesCount() external view returns (uint256);

    function gradientsCount() external view returns (uint256);

    function quantityCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Grid Renderer
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundGridRenderer {
    struct Symbol {
        uint32 seed;
        uint8 gridPalette;
        uint8 gridSize;
        uint8 id;
        uint8 level;
        uint8 palette;
        bool opaque;
    }

    struct Override {
        uint16 symbols;
        uint16 positions;
        string colors;
        uint16 size;
    }

    function generateGrid(
        Symbol memory symbol,
        Override[] memory overides,
        uint256 gradient,
        uint256 edition
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Editions Descriptor
/// @author -wizard

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./IUltraSoundGridRenderer.sol";
import {IUltraSoundEditions} from "./IUltraSoundEditions.sol";
import {IUltraSoundParts} from "./IUltraSoundParts.sol";

interface IUltraSoundDescriptor {
    event PartsUpdated(IUltraSoundParts icon);
    event RendererUpdated(IUltraSoundGridRenderer renderer);
    event DataURIToggled(bool enabled);
    event BaseURIUpdated(string baseURI);

    error EmptyPalette();
    error BadPaletteLength();
    error IndexNotFound();

    function setParts(IUltraSoundParts _parts) external;

    function setRenderer(IUltraSoundGridRenderer _renderer) external;

    function palettesCount() external view returns (uint256);

    function symbolsCount() external view returns (uint256);

    function gradientsCount() external view returns (uint256);

    function quantitiesCount() external view returns (uint256);

    function tokenURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) external view returns (string memory);

    function dataURI(
        uint256 tokenId,
        IUltraSoundEditions.Edition memory edition
    ) external view returns (string memory);

    function tokenSVG(IUltraSoundEditions.Edition memory edition, uint8 size)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Editions
/// @author -wizard

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./IUltraSoundGridRenderer.sol";
import {IUltraSoundDescriptor} from "./IUltraSoundDescriptor.sol";

interface IUltraSoundEditions {
    error LevelsMustMatch(uint256 tokenOneLevel, uint256 tokenTwoLevel);
    error ExceedsMaxLevel(uint16 level, uint256 maxLevel);
    error MustBeUltraSound(uint256 tokenId);
    error MustBeTokenOwner(address token, uint256 tokenId);
    error ContractNotOperator();
    error OnReceivedRequestFailure();
    error CannotRestore();
    error TooMany();

    event Redeemed(uint256 tokenId);
    event RedeemedMultiple(uint256[] tokenId);
    event Merged(uint256 tokenId, uint256 tokenIdBurned);
    event Swapped(uint256 tokenId, uint256 swappedTokenId);
    event Restored(uint256 tokenId, address by);
    event MetadataUpdate(uint256 _tokenId);
    event DescriptorUpdated(address orignal, address replaced);
    event ProofOfWorkUpdated(address orignal, address replaced);
    event UltraSoundBaseFeeUpdated(uint256 orignal, uint256 replaced);

    struct Edition {
        bool ultraSound;
        bool burned;
        uint32 seed;
        uint8 level;
        uint8 palette;
        uint32 blockNumber;
        uint64 baseFee;
        uint64 blockTime;
        uint16 mergeCount;
        uint16 ultraEdition;
    }

    function pause() external;

    function unpause() external;

    function setDescriptor(IUltraSoundDescriptor _descriptor) external;

    function setUltraSoundBaseFee(uint256 _baseFee) external;

    function toggleDegenMode() external;

    function restored() external view returns (uint256);

    function isUltraSound(uint256 tokenId)
        external
        view
        returns (bool ultraSound);

    function levelOf(uint256 tokenId) external view returns (uint256 level);

    function levelsOf(uint256[] calldata tokenIds)
        external
        view
        returns (uint256[] memory);

    function mergeCountOf(uint256 tokenId)
        external
        view
        returns (uint256 mergeCount);

    function edition(uint256 tokenId)
        external
        view
        returns (
            bool ultraSound,
            bool burned,
            uint32 seed,
            uint8 level,
            uint8 palette,
            uint32 blockNumber,
            uint64 baseFee,
            uint64 blockTime,
            uint16 mergeCount,
            uint16 ultraEdition
        );

    function mint(uint256 tokenId) external;

    function mintBulk(uint256[] calldata tokenId) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokenSVG(uint256 tokenId, uint8 size)
        external
        view
        returns (string memory);
}

interface IERC721Burn {
    function burn(uint256 tokenId) external;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}