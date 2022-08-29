// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IDelegationRegistry} from "./IDelegationRegistry.sol";

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev New project launches can read previous cold wallet -> hot wallet delegations from here and integrate those permissions into their flow
 * contributors: foobar (0xfoobar), punk6529 (open metaverse), loopify (loopiverse), andy8052 (fractional), purplehat (artblocks), emiliano (nftrentals),
 *               arran (proof), james (collabland), john (gnosis safe), wwhchung (manifoldxyz) tally labs and many more
 */

contract DelegationRegistry is IDelegationRegistry, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice The global mapping and single source of truth for delegations
    mapping(bytes32 => bool) private delegations;

    /// @notice A mapping of wallets to versions (for cheap revocation)
    mapping(address => uint256) private vaultVersion;

    /// @notice A mapping of wallets to delegates to versions (for cheap revocation)
    mapping(address => mapping(address => uint256)) private delegateVersion;

    /// @notice A secondary mapping to return onchain enumerability of wallet-level delegations
    /// @notice vault -> vaultVersion -> delegates
    mapping(address => mapping(uint256 => EnumerableSet.AddressSet))
        private delegationsForAll;

    /// @notice A secondary mapping to return onchain enumerability of contract-level delegations
    /// @notice vault -> vaultVersion -> contract -> delegates
    mapping(address => mapping(uint256 => mapping(address => EnumerableSet.AddressSet)))
        private delegationsForContract;

    /// @notice A secondary mapping to return onchain enumerability of token-level delegations
    /// @notice vault -> vaultVersion -> contract -> tokenId -> delegates
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => EnumerableSet.AddressSet))))
        internal delegationsForToken;

    /**
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IDelegationRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** -----------  WRITE ----------- */

    /**
     * See {IDelegationRegistry-delegateForAll}.
     */
    function delegateForAll(address delegate, bool value) external override {
        bytes32 delegateHash = keccak256(
            abi.encode(
                delegate,
                msg.sender,
                vaultVersion[msg.sender],
                delegateVersion[msg.sender][delegate]
            )
        );
        delegations[delegateHash] = value;
        _setDelegationEnumeration(
            delegationsForAll[msg.sender][vaultVersion[msg.sender]],
            delegate,
            value
        );
        emit IDelegationRegistry.DelegateForAll(msg.sender, delegate, value);
    }

    /**
     * See {IDelegationRegistry-delegateForContract}.
     */
    function delegateForContract(
        address delegate,
        address contract_,
        bool value
    ) external override {
        bytes32 delegateHash = keccak256(
            abi.encode(
                delegate,
                msg.sender,
                contract_,
                vaultVersion[msg.sender],
                delegateVersion[msg.sender][delegate]
            )
        );
        delegations[delegateHash] = value;
        _setDelegationEnumeration(
            delegationsForContract[msg.sender][vaultVersion[msg.sender]][
                contract_
            ],
            delegate,
            value
        );
        emit IDelegationRegistry.DelegateForContract(
            msg.sender,
            delegate,
            contract_,
            value
        );
    }

    /**
     * See {IDelegationRegistry-delegateForToken}.
     */
    function delegateForToken(
        address delegate,
        address contract_,
        uint256 tokenId,
        bool value
    ) external override {
        bytes32 delegateHash = keccak256(
            abi.encode(
                delegate,
                msg.sender,
                contract_,
                tokenId,
                vaultVersion[msg.sender],
                delegateVersion[msg.sender][delegate]
            )
        );
        delegations[delegateHash] = value;
        _setDelegationEnumeration(
            delegationsForToken[msg.sender][vaultVersion[msg.sender]][
                contract_
            ][tokenId],
            delegate,
            value
        );
        emit IDelegationRegistry.DelegateForToken(
            msg.sender,
            delegate,
            contract_,
            tokenId,
            value
        );
    }

    function _setDelegationEnumeration(
        EnumerableSet.AddressSet storage set,
        address key,
        bool value
    ) internal {
        if (value) {
            set.add(key);
        } else {
            set.remove(key);
        }
    }

    /**
     * See {IDelegationRegistry-revokeAllDelegates}.
     */
    function revokeAllDelegates() external override {
        vaultVersion[msg.sender]++;
        emit IDelegationRegistry.RevokeAllDelegates(msg.sender);
    }

    /**
     * See {IDelegationRegistry-revokeDelegate}.
     */
    function revokeDelegate(address delegate) external override {
        _revokeDelegate(delegate, msg.sender);
    }

    /**
     * See {IDelegationRegistry-revokeSelf}.
     */
    function revokeSelf(address vault) external override {
        _revokeDelegate(msg.sender, vault);
    }

    function _revokeDelegate(address delegate, address vault) internal {
        delegateVersion[vault][delegate]++;
        // Remove delegate from enumerations
        delegationsForAll[vault][vaultVersion[vault]].remove(delegate);
        // For delegationsForContract and delegationsForToken, filter in the view
        // functions
        emit IDelegationRegistry.RevokeDelegate(vault, msg.sender);
    }

    /** -----------  READ ----------- */

    /**
     * See {IDelegationRegistry-getDelegationsForAll}.
     */
    function getDelegationsForAll(address vault)
        external
        view
        returns (address[] memory)
    {
        return delegationsForAll[vault][vaultVersion[vault]].values();
    }

    /**
     * See {IDelegationRegistry-getDelegationsForContract}.
     */
    function getDelegationsForContract(address vault, address contract_)
        external
        view
        override
        returns (address[] memory delegates)
    {
        EnumerableSet.AddressSet
            storage potentialDelegates = delegationsForContract[vault][
                vaultVersion[vault]
            ][contract_];
        uint256 potentialDelegatesLength = potentialDelegates.length();
        uint256 delegateCount = 0;
        delegates = new address[](potentialDelegatesLength);
        for (uint256 i = 0; i < potentialDelegatesLength; ) {
            if (
                checkDelegateForContract(
                    potentialDelegates.at(i),
                    vault,
                    contract_
                )
            ) {
                delegates[delegateCount] = potentialDelegates.at(i);
                delegateCount++;
            }
            unchecked {
                ++i;
            }
        }
        if (potentialDelegatesLength > delegateCount) {
            assembly {
                let decrease := sub(potentialDelegatesLength, delegateCount)
                mstore(delegates, sub(mload(delegates), decrease))
            }
        }
    }

    /**
     * See {IDelegationRegistry-getDelegationsForToken}.
     */
    function getDelegationsForToken(
        address vault,
        address contract_,
        uint256 tokenId
    ) external view override returns (address[] memory delegates) {
        // Since we cannot easily invalidate delegates on the enumeration (see revokeDelegates)
        // we will need to filter out invalid entries
        EnumerableSet.AddressSet
            storage potentialDelegates = delegationsForToken[vault][
                vaultVersion[vault]
            ][contract_][tokenId];
        uint256 potentialDelegatesLength = potentialDelegates.length();
        uint256 delegateCount = 0;
        delegates = new address[](potentialDelegatesLength);
        for (uint256 i = 0; i < potentialDelegatesLength; ) {
            if (
                checkDelegateForToken(
                    potentialDelegates.at(i),
                    vault,
                    contract_,
                    tokenId
                )
            ) {
                delegates[delegateCount] = potentialDelegates.at(i);
                delegateCount++;
            }
            unchecked {
                ++i;
            }
        }
        if (potentialDelegatesLength > delegateCount) {
            assembly {
                let decrease := sub(potentialDelegatesLength, delegateCount)
                mstore(delegates, sub(mload(delegates), decrease))
            }
        }
    }

    /**
     * See {IDelegationRegistry-checkDelegateForAll}.
     */
    function checkDelegateForAll(address delegate, address vault)
        public
        view
        override
        returns (bool)
    {
        bytes32 delegateHash = keccak256(
            abi.encode(
                delegate,
                vault,
                vaultVersion[vault],
                delegateVersion[vault][delegate]
            )
        );
        return delegations[delegateHash];
    }

    /**
     * See {IDelegationRegistry-checkDelegateForAll}.
     */
    function checkDelegateForContract(
        address delegate,
        address vault,
        address contract_
    ) public view override returns (bool) {
        bytes32 delegateHash = keccak256(
            abi.encode(
                delegate,
                vault,
                contract_,
                vaultVersion[vault],
                delegateVersion[vault][delegate]
            )
        );
        return
            delegations[delegateHash]
                ? true
                : checkDelegateForAll(delegate, vault);
    }

    /**
     * See {IDelegationRegistry-checkDelegateForToken}.
     */
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) public view override returns (bool) {
        bytes32 delegateHash = keccak256(
            abi.encode(
                delegate,
                vault,
                contract_,
                tokenId,
                vaultVersion[vault],
                delegateVersion[vault][delegate]
            )
        );
        return
            delegations[delegateHash]
                ? true
                : checkDelegateForContract(delegate, vault, contract_);
    }
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

pragma solidity ^0.8.16;

/** 
* @title An immutable registry contract to be deployed as a standalone primitive
* @dev New project launches can read previous cold wallet -> hot wallet delegations from here and integrate those permissions into their flow
* contributors: foobar (0xfoobar), punk6529 (open metaverse), loopify (loopiverse), andy8052 (fractional), purplehat (artblocks), emiliano (nftrentals),
*               arran (proof), james (collabland), john (gnosis safe), wwhchung (manifoldxyz) tally labs and many more
*/

interface IDelegationRegistry {

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);
    
    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /** -----------  WRITE ----------- */

    /** 
    * @notice Allow the delegate to act on your behalf for all contracts
    * @param delegate The hotwallet to act on your behalf
    * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
    */
    function delegateForAll(address delegate, bool value) external;

    /** 
    * @notice Allow the delegate to act on your behalf for a specific contract
    * @param delegate The hotwallet to act on your behalf
    * @param contract_ The address for the contract you're delegating
    * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
    */
    function delegateForContract(address delegate, address contract_, bool value) external;
    /** 
    * @notice Allow the delegate to act on your behalf for a specific token, supports 721 and 1155
    * @param delegate The hotwallet to act on your behalf
    * @param contract_ The address for the contract you're delegating
    * @param tokenId The token id for the token you're delegating
    * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
    */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Revoke delegation for a specific vault, for all permissions
     */
    function revokeSelf(address vault) external;

    /** -----------  READ ----------- */

    /**
    * @notice Returns an array of wallet-level delegations for a given vault
    * @param vault The cold wallet who issued the delegation
    * @return addresses Array of wallet-level delegations for a given vault
    */
    function getDelegationsForAll(address vault) external view returns (address[] memory);

    /**
    * @notice Returns an array of contract-level delegations for a given vault and contract
    * @param vault The cold wallet who issued the delegation
    * @param contract_ The address for the contract you're delegating
    * @return addresses Array of contract-level delegations for a given vault and contract
    */
    function getDelegationsForContract(address vault, address contract_) external view returns (address[] memory);

    /**
    * @notice Returns an array of contract-level delegations for a given vault's token
    * @param vault The cold wallet who issued the delegation
    * @param contract_ The address for the contract holding the token
    * @param tokenId The token id for the token you're delegating
    * @return addresses Array of contract-level delegations for a given vault's token
    */
    function getDelegationsForToken(address vault, address contract_, uint256 tokenId) external view returns (address[] memory);

    /** 
    * @notice Returns true if the address is delegated to act on your behalf for all NFTs
    * @param delegate The hotwallet to act on your behalf
    * @param vault The cold wallet who issued the delegation
    */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /** 
    * @notice Returns true if the address is delegated to act on your behalf for an NFT contract
    * @param delegate The hotwallet to act on your behalf
    * @param contract_ The address for the contract you're delegating
    * @param vault The cold wallet who issued the delegation
    */ 
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);
    
    /** 
    * @notice Returns true if the address is delegated to act on your behalf for an specific NFT
    * @param delegate The hotwallet to act on your behalf
    * @param contract_ The address for the contract you're delegating
    * @param tokenId The token id for the token you're delegating
    * @param vault The cold wallet who issued the delegation
    */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId) external view returns (bool);
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