/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/IFingerprints.sol";
import "./interfaces/IFingerprints.sol";
import "./libraries/Metadata.sol";

contract FingerprintsV1 is IFingerprints, Ownable, IERC165 {
    using Counters for Counters.Counter;
    Counters.Counter private _idCounter;

    /// @dev "MODA-<ChainID>-<FingerprintVersion>-"
    string private constant MODA_ID_PREFACE = "MODA-1-1-";

    ///@dev ArtistReleases => is a list of NFTs that are registered for Fingerprints
    mapping(address => bool) private _authorizedReleases;

    /// @dev MODA ID => Metadata
    mapping(string => Metadata.Meta) internal _metadata;

    /// @dev MODA ID => x values in an array to iterate over
    mapping(string => uint32[]) public x_array;

    /// @dev MODA ID => x => array of y
    mapping(string => mapping(uint32 => uint32[])) public y_map;

    event FingerprintCreated(address indexed creator, string indexed modaId, string indexed song);
    event ArtistReleasesRegistered(address indexed artist, address indexed artistReleases, bool isRegistered);

    function createFingerprint(
        address creator,
        string memory creatorName,
        address artist,
        string memory artistName,
        string memory uri,
        string memory title,
        bytes32 hash,
        uint8 x_shape,
        uint8 y_shape
    ) public onlyOwner {
        _idCounter.increment();
        string memory modaId = string(abi.encodePacked(MODA_ID_PREFACE, Strings.toString(_idCounter.current())));
        require(_metadata[modaId].creator == address(0), "Fingerprint already exists");
        require(address(0) != creator, "creator cannot be 0x0");
        require(address(0) != artist, "artist cannot be 0x0");
        require(bytes(creatorName).length > 0, "creatorName cannot be blank");
        require(bytes(uri).length > 0, "uri cannot be blank");
        require(bytes32(0) != hash, "hash cannot be 0x0");
        require(x_shape > 0 && y_shape > 0, "x and y shapes cannot be 0");

        _metadata[modaId].created = block.timestamp;
        _metadata[modaId].hash = hash;
        _metadata[modaId].creator = creator;
        _metadata[modaId].creatorName = creatorName;
        _metadata[modaId].artist = artist;
        _metadata[modaId].artistName = artistName;
        _metadata[modaId].title = title;
        _metadata[modaId].x_shape = x_shape;
        _metadata[modaId].y_shape = y_shape;
        _metadata[modaId].uri = uri;

        emit FingerprintCreated(creator, modaId, title);
    }

    function setURI(string memory modaId, string memory uri) public onlyOwner {
        _metadata[modaId].uri = uri;
    }

    /// @dev Registration for official ArtistReleases that are recognized by MODA. The event emitted serves as a way for client applications to find all contracts and filter by creator
    /// @param artistReleases The address of the NFT contract deployed by MODA
    /// @param artist The address of the artist for a given ArtistReleases contract
    /// @param isRegistered The state of registration
    function registerArtistReleases(
        address artistReleases,
        address artist,
        bool isRegistered
    ) public onlyOwner {
        _authorizedReleases[artistReleases] = isRegistered;
        emit ArtistReleasesRegistered(artistReleases, artist, isRegistered);
    }

    /// @dev Function to check if a ArtistReleases contract is registered
    /// @param artistReleases Address of a ArtistReleases contract
    /// @return bool
    function isAuthorizedArtistRelease(address artistReleases) public view returns (bool) {
        return _authorizedReleases[artistReleases];
    }

    function setData(
        string memory modaId,
        uint32[] memory x,
        uint32[][] memory y
    ) public onlyOwner {
        _setData(modaId, x, y);
    }

    function _setData(
        string memory modaId,
        uint32[] memory x,
        uint32[][] memory y
    ) internal virtual {
        require(x.length == y.length, "x and y must have the same length");

        for (uint256 i = 0; i < x.length; i++) {
            uint32 _x_value = x[i];
            x_array[modaId].push(_x_value);
            y_map[modaId][_x_value] = y[i];

            _metadata[modaId].pointCount += y[i].length;
        }
    }

    /// @inheritdoc	IFingerprints
    function getPoint(string memory modaId, uint32 index) external view override returns (uint32 x, uint32 y) {
        uint256 count = 0;
        for (uint32 i = 0; i < x_array[modaId].length; i++) {
            uint32[] memory _y = y_map[modaId][x_array[modaId][i]];

            for (uint32 j = 0; j < _y.length; j++) {
                if (count == index) {
                    return (x_array[modaId][i], _y[j]);
                }
                count++;
            }
        }

        return (0, 0);
    }

    /// @inheritdoc	IFingerprints
    function metadata(string memory modaId) external view override returns (Metadata.Meta memory) {
        return _metadata[modaId];
    }

    function uniqueX(string memory modaId) public view returns (uint256) {
        return x_array[modaId].length;
    }

    /// @inheritdoc	IERC165
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(IFingerprints).interfaceId;
    }

    /// @inheritdoc	IFingerprints
    function hasMatchingArtist(
        string memory modaId,
        address artist,
        address artistReleases
    ) external view override returns (bool) {
        return _metadata[modaId].artist == artist && isAuthorizedArtistRelease(artistReleases);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/Metadata.sol";

interface IFingerprints {
    /**
     * @return Metadata.Meta
     * @param modaId MODA ID in the form of MODA-<ChainID>-<FingerprintVersion>-<FingerprintID>
     */
    function metadata(string memory modaId) external view returns (Metadata.Meta memory);

    /**
     * @return x and y coordinates for a given point in fingerprint data
     * @param modaId MODA ID in the form of MODA-<ChainID>-<FingerprintVersion>-<FingerprintID>
     */
    function getPoint(string memory modaId, uint32 index) external view returns (uint32 x, uint32 y);

    /**
     * @dev Convenience function used to verify an artist wallet address matches the one in the metadata for a given hash
     * @return bool
     * @param modaId MODA ID in the form of MODA-<ChainID>-<FingerprintVersion>-<FingerprintID>
     * @param artist Artist wallet address or a contract address used on behalf of the artist
     */
    function hasMatchingArtist(
        string memory modaId,
        address artist,
        address artistReleases
    ) external view returns (bool);
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Metadata {
    struct Meta {
        bytes32 hash;
        uint256 created;
        address creator;
        string creatorName;
        address artist;
        string artistName;
        string title;
        uint8 x_shape;
        uint8 y_shape;
        uint256 pointCount;
        string uri;
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