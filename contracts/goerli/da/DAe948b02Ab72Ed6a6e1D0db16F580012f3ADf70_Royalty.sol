// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * Simple EIP2981 reference override implementation
 */
interface IEIP2981RoyaltyOverride is IERC165 {

    event TokenRoyaltyRemoved(uint256 tokenId);
    event TokenRoyaltySet(uint256 tokenId, address recipient, uint16 bps);
    event DefaultRoyaltySet(address recipient, uint16 bps);

    struct TokenRoyalty {
        address recipient;
        uint16 bps;
    }

    struct TokenRoyaltyConfig {
        uint256 tokenId;
        address recipient;
        uint16 bps;
    }

    /**
     * @dev Set per token royalties.  Passing a recipient of address(0) will delete any existing configuration
     */
    function setTokenRoyalties(TokenRoyaltyConfig[] calldata royalties) external;

    /**
     * @dev Get the number of token specific overrides.  Used to enumerate over all configurations
     */
    function getTokenRoyaltiesCount() external view returns(uint256);

    /**
     * @dev Get a token royalty configuration by index.  Use in conjunction with getTokenRoyaltiesCount to get all per token configurations
     */
    function getTokenRoyaltyByIndex(uint256 index) external view returns(TokenRoyaltyConfig memory);

    /**
     * @dev Set a default royalty configuration.  Will be used if no token specific configuration is set
     */
    function setDefaultRoyalty(TokenRoyalty calldata royalty) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * EIP-2981
 */
interface IEIP2981 {
    /**
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     *
     * => 0x2a55205a = 0x2a55205a
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFoundation {
    /*
     *  bytes4(keccak256('getFees(uint256)')) == 0xd5a06d4c
     *
     *  => 0xd5a06d4c = 0xd5a06d4c
     */
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

interface IFoundationTreasuryNode {
    function getFoundationTreasury() external view returns (address payable);
}

interface IFoundationTreasury {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRaribleV1 {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    function getFeeBps(uint256 id) external view returns (uint[] memory);
    function getFeeRecipients(uint256 id) external view returns (address payable[] memory);
}


interface IRaribleV2 {
    /*
     *  bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    struct Part {
        address payable account;
        uint96 value;
    }
    function getRaribleV2Royalties(uint256 id) external view returns (Part[] memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IRarible.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IFoundation.sol";

import "./IRoyaltyInternal.sol";

interface IRoyalty is IEIP2981, IRaribleV1, IRaribleV2, IFoundation, IRoyaltyInternal {
    /**
     * @dev Default royalty for all tokens without a specific royalty.
     */
    function defaultRoyalty() external view returns (TokenRoyalty memory);

    /**
     * @dev Get the number of token specific overrides.  Used to enumerate over all configurations
     */
    function getTokenRoyaltiesCount() external view returns (uint256);

    /**
     * @dev Get a token royalty configuration by index.  Use in conjunction with getTokenRoyaltiesCount to get all per token configurations
     */
    function getTokenRoyaltyByIndex(uint256 index) external view returns (TokenRoyaltyConfig memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IRoyaltyInternal {
    event TokenRoyaltyRemoved(uint256 tokenId);
    event TokenRoyaltySet(uint256 tokenId, address recipient, uint16 bps);
    event DefaultRoyaltySet(address recipient, uint16 bps);

    struct TokenRoyalty {
        address recipient;
        uint16 bps;
    }

    struct TokenRoyaltyConfig {
        uint256 tokenId;
        address recipient;
        uint16 bps;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "./RoyaltyInternal.sol";
import "./RoyaltyStorage.sol";
import "./IRoyalty.sol";

/**
 * @title ERC2981 - Royalty
 * @notice Provide standard on-chain EIP-2981 royalty support for ERC721 or ERC1155 tokens, and additional functions for Rarible and Foundation.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:provides-interfaces IEIP2981 IRoyalty IRaribleV1 IRaribleV2 IFoundation IEIP2981RoyaltyOverride
 */
contract Royalty is IRoyalty, RoyaltyInternal {
    using RoyaltyStorage for RoyaltyStorage.Layout;

    function defaultRoyalty() external view virtual returns (TokenRoyalty memory) {
        return RoyaltyStorage.layout().defaultRoyalty;
    }

    /**
     * @dev EIP-2981
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual returns (address, uint256) {
        return _royaltyInfo(tokenId, value);
    }

    /**
     * @dev IEIP2981RoyaltyOverride (Manifold)
     */
    function getTokenRoyaltiesCount() external view virtual override returns (uint256) {
        return _getTokenRoyaltiesCount();
    }

    function getTokenRoyaltyByIndex(uint256 index) external view virtual override returns (TokenRoyaltyConfig memory) {
        return _getTokenRoyaltyByIndex(index);
    }

    /**
     * @dev IFoundation
     */
    function getFees(uint256 tokenId) external view virtual returns (address payable[] memory, uint256[] memory) {
        address payable[] memory receivers = new address payable[](1);
        uint256[] memory bps = new uint256[](1);

        (address receiver, uint256 value) = _royaltyInfo(tokenId, 10000);

        receivers[0] = payable(receiver);
        bps[0] = value;

        return (receivers, bps);
    }

    /**
     * @dev IRaribleV1
     */
    function getFeeRecipients(uint256 tokenId) external view virtual returns (address payable[] memory) {
        address payable[] memory receivers = new address payable[](1);

        (address receiver, ) = _royaltyInfo(tokenId, 10000);
        receivers[0] = payable(receiver);

        return receivers;
    }

    function getFeeBps(uint256 tokenId) external view virtual returns (uint256[] memory) {
        uint256[] memory bps = new uint256[](1);

        (, uint256 value) = _royaltyInfo(tokenId, 10000);

        bps[0] = value;

        return bps;
    }

    /**
     * @dev IRaribleV2
     */
    function getRaribleV2Royalties(uint256 tokenId) external view override returns (IRaribleV2.Part[] memory result) {
        result = new IRaribleV2.Part[](1);

        // Passing 10,000 as value will give us the bps (basis points, out of 10,000) of the royalty.
        (address account, uint256 value) = _royaltyInfo(tokenId, 10000);

        result[0].account = payable(account);
        result[0].value = uint96(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@manifoldxyz/royalty-registry-solidity/contracts/overrides/IRoyaltyOverride.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRoyaltyInternal.sol";
import "./RoyaltyStorage.sol";

/**
 * @title Royalty standard functionality base on EIP-2981 (derived from Manifold.xyz contracts to adopt Diamond architecture)
 */
abstract contract RoyaltyInternal is IRoyaltyInternal {
    using RoyaltyStorage for RoyaltyStorage.Layout;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @dev Sets token royalties. When you override this in the implementation contract
     * ensure that you access restrict it to the contract owner or admin
     */
    function _setTokenRoyalties(TokenRoyaltyConfig[] memory royaltyConfigs) internal virtual {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();

        for (uint256 i = 0; i < royaltyConfigs.length; i++) {
            TokenRoyaltyConfig memory royaltyConfig = royaltyConfigs[i];

            require(royaltyConfig.bps < 10000, "Invalid bps");

            if (royaltyConfig.recipient == address(0)) {
                delete l.tokenRoyalties[royaltyConfig.tokenId];
                l.tokensWithRoyalties.remove(royaltyConfig.tokenId);

                emit TokenRoyaltyRemoved(royaltyConfig.tokenId);
            } else {
                l.tokenRoyalties[royaltyConfig.tokenId] = TokenRoyalty(royaltyConfig.recipient, royaltyConfig.bps);
                l.tokensWithRoyalties.add(royaltyConfig.tokenId);

                emit TokenRoyaltySet(royaltyConfig.tokenId, royaltyConfig.recipient, royaltyConfig.bps);
            }
        }
    }

    /**
     * @dev Sets default royalty. When you override this in the implementation contract
     * ensure that you access restrict it to the contract owner or admin
     */
    function _setDefaultRoyalty(TokenRoyalty memory royalty) internal virtual {
        require(royalty.bps < 10000, "Invalid bps");

        RoyaltyStorage.layout().defaultRoyalty = TokenRoyalty(royalty.recipient, royalty.bps);

        emit DefaultRoyaltySet(royalty.recipient, royalty.bps);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-getTokenRoyaltiesCount}.
     */
    function _getTokenRoyaltiesCount() internal view virtual returns (uint256) {
        return RoyaltyStorage.layout().tokensWithRoyalties.length();
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-getTokenRoyaltyByIndex}.
     */
    function _getTokenRoyaltyByIndex(uint256 index) internal view virtual returns (TokenRoyaltyConfig memory) {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();

        uint256 tokenId = l.tokensWithRoyalties.at(index);
        TokenRoyalty memory royalty = l.tokenRoyalties[tokenId];

        return TokenRoyaltyConfig(tokenId, royalty.recipient, royalty.bps);
    }

    /**
     * @dev See {IEIP2981RoyaltyOverride-royaltyInfo}.
     */
    function _royaltyInfo(uint256 tokenId, uint256 value) internal view virtual returns (address, uint256) {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();

        if (l.tokenRoyalties[tokenId].recipient != address(0)) {
            return (l.tokenRoyalties[tokenId].recipient, (value * l.tokenRoyalties[tokenId].bps) / 10000);
        }

        if (l.defaultRoyalty.recipient != address(0) && l.defaultRoyalty.bps != 0) {
            return (l.defaultRoyalty.recipient, (value * l.defaultRoyalty.bps) / 10000);
        }

        return (address(0), 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IRoyaltyInternal.sol";
import "./IRoyalty.sol";

library RoyaltyStorage {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Layout {
        IRoyaltyInternal.TokenRoyalty defaultRoyalty;
        mapping(uint256 => IRoyaltyInternal.TokenRoyalty) tokenRoyalties;
        EnumerableSet.UintSet tokensWithRoyalties;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.Royalty");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}