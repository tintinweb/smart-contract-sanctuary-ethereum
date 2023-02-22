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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IAdminACLV0 {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     * @param previousSuperAdmin The previous superAdmin address.
     * @param newSuperAdmin The new superAdmin address.
     * @param genArt721CoreAddressesToUpdate Array of genArt721Core
     * addresses to update to the new superAdmin, for indexing purposes only.
     */
    event SuperAdminTransferred(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin,
        address[] genArt721CoreAddressesToUpdate
    );

    /// Type of the Admin ACL contract, e.g. "AdminACLV0"
    function AdminACLType() external view returns (string memory);

    /// super admin address
    function superAdmin() external view returns (address);

    /**
     * @notice Calls transferOwnership on other contract from this contract.
     * This is useful for updating to a new AdminACL contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function transferOwnershipOn(
        address _contract,
        address _newAdminACL
    ) external;

    /**
     * @notice Calls renounceOwnership on other contract from this contract.
     * @dev this function should be gated to only superAdmin-like addresses.
     */
    function renounceOwnershipOn(address _contract) external;

    /**
     * @notice Checks if sender `_sender` is allowed to call function with selector
     * `_selector` on contract `_contract`.
     */
    function allowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/// @dev Source: https://github.com/0xfoobar/delegation-registry/blob/main/src/IDelegationRegistry.sol

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(
        address vault,
        address delegate,
        address contract_,
        bool value
    );

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(
        address vault,
        address delegate,
        address contract_,
        uint256 tokenId,
        bool value
    );

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

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
    function delegateForContract(
        address delegate,
        address contract_,
        bool value
    ) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(
        address delegate,
        address contract_,
        uint256 tokenId,
        bool value
    ) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(
        address delegate
    ) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(
        address vault
    ) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(
        address vault,
        address contract_
    ) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(
        address vault
    ) external view returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(
        address vault
    ) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(
        address delegate,
        address vault
    ) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(
        address delegate,
        address vault,
        address contract_
    ) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for including owned NFT token address and token ID information.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterHolderV0 is IFilteredMinterV0 {
    /**
     * @notice Registered holders of NFTs at address `_NFTAddress` to be
     * considered for minting.
     */
    event RegisteredNFTAddress(address indexed _NFTAddress);

    /**
     * @notice Unregistered holders of NFTs at address `_NFTAddress` to be
     * considered for minting.
     */
    event UnregisteredNFTAddress(address indexed _NFTAddress);

    /**
     * @notice Allow holders of NFTs at addresses `_ownedNFTAddresses`, project
     * IDs `_ownedNFTProjectIds` to mint on project `_projectId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTProjectIds`.
     * e.g. Allows holders of project `_ownedNFTProjectIds[0]` on token
     * contract `_ownedNFTAddresses[0]` to mint.
     */
    event AllowedHoldersOfProjects(
        uint256 indexed _projectId,
        address[] _ownedNFTAddresses,
        uint256[] _ownedNFTProjectIds
    );

    /**
     * @notice Remove holders of NFTs at addresses `_ownedNFTAddresses`,
     * project IDs `_ownedNFTProjectIds` to mint on project `_projectId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTProjectIds`.
     * e.g. Removes holders of project `_ownedNFTProjectIds[0]` on token
     * contract `_ownedNFTAddresses[0]` from mint allowlist.
     */
    event RemovedHoldersOfProjects(
        uint256 indexed _projectId,
        address[] _ownedNFTAddresses,
        uint256[] _ownedNFTProjectIds
    );

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address, using owned ERC-721 NFT to claim right to purchase.
    function purchase(
        uint256 _projectId,
        address _ownedNftAddress,
        uint256 _ownedNftTokenId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address, using owned ERC-721 NFT to claim right to purchase.
    function purchaseTo(
        address _to,
        uint256 _projectId,
        address _ownedNftAddress,
        uint256 _ownedNftTokenId
    ) external payable returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterHolderV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterHolderV0 interface in order
 * to add support for configuring and indexing the delegation registry address.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterHolderV1 is IFilteredMinterHolderV0 {
    /**
     * @notice Notifies of the contract's configured delegation registry
     * address.
     */
    event DelegationRegistryUpdated(address delegationRegistryAddress);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterHolderV1.sol";
import "./IFilteredMinterV2.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterHolderV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterHolderV2 is
    IFilteredMinterHolderV1,
    IFilteredMinterV2
{

}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IFilteredMinterV0 {
    /**
     * @notice Price per token in wei updated for project `_projectId` to
     * `_pricePerTokenInWei`.
     */
    event PricePerTokenInWeiUpdated(
        uint256 indexed _projectId,
        uint256 indexed _pricePerTokenInWei
    );

    /**
     * @notice Currency updated for project `_projectId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event ProjectCurrencyInfoUpdated(
        uint256 indexed _projectId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /// togglePurchaseToDisabled updated
    event PurchaseToDisabledUpdated(
        uint256 indexed _projectId,
        bool _purchaseToDisabled
    );

    // getter function of public variable
    function minterType() external view returns (string memory);

    function genArt721CoreAddress() external returns (address);

    function minterFilterAddress() external returns (address);

    // Triggers a purchase of a token from the desired project, to the
    // TX-sending address.
    function purchase(
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Triggers a purchase of a token from the desired project, to the specified
    // receiving address.
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) external payable returns (uint256 tokenId);

    // Toggles the ability for `purchaseTo` to be called directly with a
    // specified receiving address that differs from the TX-sending address.
    function togglePurchaseToDisabled(uint256 _projectId) external;

    // Called to make the minter contract aware of the max invocations for a
    // given project.
    function setProjectMaxInvocations(uint256 _projectId) external;

    // Gets if token price is configured, token price in wei, currency symbol,
    // and currency address, assuming this is project's minter.
    // Supersedes any defined core price.
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV0.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV0 interface in order to
 * add support for generic project minter configuration updates.
 * @dev keys represent strings of finite length encoded in bytes32 to minimize
 * gas.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV1 is IFilteredMinterV0 {
    /// ANY
    /**
     * @notice Generic project minter configuration event. Removes key `_key`
     * for project `_projectId`.
     */
    event ConfigKeyRemoved(uint256 indexed _projectId, bytes32 _key);

    /// BOOL
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(uint256 indexed _projectId, bytes32 _key, bool _value);

    /// UINT256
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of uint256 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        uint256 _value
    );

    /// ADDRESS
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of addresses at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        address _value
    );

    /// BYTES32
    /**
     * @notice Generic project minter configuration event. Sets value of key
     * `_key` to `_value` for project `_projectId`.
     */
    event ConfigValueSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Adds value `_value`
     * to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueAddedToSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @notice Generic project minter configuration event. Removes value
     * `_value` to the set of bytes32 at key `_key` for project `_projectId`.
     */
    event ConfigValueRemovedFromSet(
        uint256 indexed _projectId,
        bytes32 _key,
        bytes32 _value
    );

    /**
     * @dev Strings not supported. Recommend conversion of (short) strings to
     * bytes32 to remain gas-efficient.
     */
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV1.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface extends the IFilteredMinterV1 interface in order to
 * add support for manually setting project max invocations.
 * @author Art Blocks Inc.
 */
interface IFilteredMinterV2 is IFilteredMinterV1 {
    /**
     * @notice Local max invocations for project `_projectId`, tied to core contract `_coreContractAddress`,
     * updated to `_maxInvocations`.
     */
    event ProjectMaxInvocationsLimitUpdated(
        uint256 indexed _projectId,
        uint256 _maxInvocations
    );

    // Sets the local max invocations for a given project, checking that the provided max invocations is
    // less than or equal to the global max invocations for the project set on the core contract.
    // This does not impact the max invocations value defined on the core contract.
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";

/**
 * @title This interface is intended to house interface items that are common
 * across all GenArt721CoreContractV3 flagship and derivative implementations.
 * This interface extends the IManifold royalty interface in order to
 * add support the Royalty Registry by default.
 * @author Art Blocks Inc.
 */
interface IGenArt721CoreContractV3_Base is IManifold {
    /**
     * @notice Token ID `_tokenId` minted to `_to`.
     */
    event Mint(address indexed _to, uint256 indexed _tokenId);

    /**
     * @notice currentMinter updated to `_currentMinter`.
     * @dev Implemented starting with V3 core
     */
    event MinterUpdated(address indexed _currentMinter);

    /**
     * @notice Platform updated on bytes32-encoded field `_field`.
     */
    event PlatformUpdated(bytes32 indexed _field);

    /**
     * @notice Project ID `_projectId` updated on bytes32-encoded field
     * `_update`.
     */
    event ProjectUpdated(uint256 indexed _projectId, bytes32 indexed _update);

    event ProposedArtistAddressesAndSplits(
        uint256 indexed _projectId,
        address _artistAddress,
        address _additionalPayeePrimarySales,
        uint256 _additionalPayeePrimarySalesPercentage,
        address _additionalPayeeSecondarySales,
        uint256 _additionalPayeeSecondarySalesPercentage
    );

    event AcceptedArtistAddressesAndSplits(uint256 indexed _projectId);

    // version and type of the core contract
    // coreVersion is a string of the form "0.x.y"
    function coreVersion() external view returns (string memory);

    // coreType is a string of the form "GenArt721CoreV3"
    function coreType() external view returns (string memory);

    // owner (pre-V3 was named admin) of contract
    // this is expected to be an Admin ACL contract for V3
    function owner() external view returns (address);

    // Admin ACL contract for V3, will be at the address owner()
    function adminACLContract() external returns (IAdminACLV0);

    // backwards-compatible (pre-V3) admin - equal to owner()
    function admin() external view returns (address);

    /**
     * Function determining if _sender is allowed to call function with
     * selector _selector on contract `_contract`. Intended to be used with
     * peripheral contracts such as minters, as well as internally by the
     * core contract itself.
     */
    function adminACLAllowed(
        address _sender,
        address _contract,
        bytes4 _selector
    ) external returns (bool);

    // getter function of public variable
    function nextProjectId() external view returns (uint256);

    // getter function of public mapping
    function tokenIdToProjectId(
        uint256 tokenId
    ) external view returns (uint256 projectId);

    // @dev this is not available in V0
    function isMintWhitelisted(address minter) external view returns (bool);

    function projectIdToArtistAddress(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySales(
        uint256 _projectId
    ) external view returns (address payable);

    function projectIdToAdditionalPayeePrimarySalesPercentage(
        uint256 _projectId
    ) external view returns (uint256);

    // @dev new function in V3
    function projectStateData(
        uint256 _projectId
    )
        external
        view
        returns (
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            bool paused,
            uint256 completedTimestamp,
            bool locked
        );

    // function to set a token's hash (must be guarded)
    function setTokenHash_8PT(uint256 _tokenId, bytes32 _hash) external;

    // @dev gas-optimized signature in V3 for `mint`
    function mint_Ecf(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

interface IGenArt721CoreContractV3_Engine is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 renderProviderRevenue_,
            address payable renderProviderAddress_,
            uint256 platformProviderRevenue_,
            address payable platformProviderAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev The render provider primary sales payment address
    function renderProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider primary sales payment address
    function platformProviderPrimarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Percentage of primary sales allocated to the render provider
    function renderProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev Percentage of primary sales allocated to the platform provider
    function platformProviderPrimarySalesPercentage()
        external
        view
        returns (uint256);

    // @dev The render provider secondary sales royalties payment address
    function renderProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev The platform provider secondary sales royalties payment address
    function platformProviderSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to the render provider
    function renderProviderSecondarySalesBPS() external view returns (uint256);

    // @dev Basis points of secondary sales allocated to the platform provider
    function platformProviderSecondarySalesBPS()
        external
        view
        returns (uint256);

    // function to read the hash for a given tokenId
    function tokenIdToHash(uint256 _tokenId) external view returns (bytes32);

    // function to read the hash-seed for a given tokenId
    function tokenIdToHashSeed(
        uint256 _tokenId
    ) external view returns (bytes12);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IAdminACLV0.sol";
import "./IGenArt721CoreContractV3_Base.sol";

/**
 * @title This interface extends IGenArt721CoreContractV3_Base with functions
 * that are part of the Art Blocks Flagship core contract.
 * @author Art Blocks Inc.
 */
// This interface extends IGenArt721CoreContractV3_Base with functions that are
// in part of the Art Blocks Flagship core contract.
interface IGenArt721CoreContractV3 is IGenArt721CoreContractV3_Base {
    // @dev new function in V3
    function getPrimaryRevenueSplits(
        uint256 _projectId,
        uint256 _price
    )
        external
        view
        returns (
            uint256 artblocksRevenue_,
            address payable artblocksAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_,
            uint256 additionalPayeePrimaryRevenue_,
            address payable additionalPayeePrimaryAddress_
        );

    // @dev Art Blocks primary sales payment address
    function artblocksPrimarySalesAddress()
        external
        view
        returns (address payable);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales payment address (now called artblocksPrimarySalesAddress).
     */
    function artblocksAddress() external view returns (address payable);

    // @dev Percentage of primary sales allocated to Art Blocks
    function artblocksPrimarySalesPercentage() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function returning Art Blocks
     * primary sales percentage (now called artblocksPrimarySalesPercentage).
     */
    function artblocksPercentage() external view returns (uint256);

    // @dev Art Blocks secondary sales royalties payment address
    function artblocksSecondarySalesAddress()
        external
        view
        returns (address payable);

    // @dev Basis points of secondary sales allocated to Art Blocks
    function artblocksSecondarySalesBPS() external view returns (uint256);

    /**
     * @notice Backwards-compatible (pre-V3) function  that gets artist +
     * artist's additional payee royalty data for token ID `_tokenId`.
     * WARNING: Does not include Art Blocks portion of royalties.
     */
    function getRoyaltyData(
        uint256 _tokenId
    )
        external
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev Royalty Registry interface, used to support the Royalty Registry.
/// @dev Source: https://github.com/manifoldxyz/royalty-registry-solidity/blob/main/contracts/specs/IManifold.sol

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(
        uint256 tokenId
    ) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "./IFilteredMinterV2.sol";

pragma solidity ^0.8.0;

/**
 * @title This interface defines any events or functions required for a minter
 * to conform to the MinterBase contract.
 * @dev The MinterBase contract was not implemented from the beginning of the
 * MinterSuite contract suite, therefore early versions of some minters may not
 * conform to this interface.
 * @author Art Blocks Inc.
 */
interface IMinterBaseV0 {
    // Function that returns if a minter is configured to integrate with a V3 flagship or V3 engine contract.
    // Returns true only if the minter is configured to integrate with an engine contract.
    function isEngine() external returns (bool isEngine);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

interface IMinterFilterV0 {
    /**
     * @notice Emitted when contract is deployed to notify indexing services
     * of the new contract deployment.
     */
    event Deployed();

    /**
     * @notice Approved minter `_minterAddress`.
     */
    event MinterApproved(address indexed _minterAddress, string _minterType);

    /**
     * @notice Revoked approval for minter `_minterAddress`
     */
    event MinterRevoked(address indexed _minterAddress);

    /**
     * @notice Minter `_minterAddress` of type `_minterType`
     * registered for project `_projectId`.
     */
    event ProjectMinterRegistered(
        uint256 indexed _projectId,
        address indexed _minterAddress,
        string _minterType
    );

    /**
     * @notice Any active minter removed for project `_projectId`.
     */
    event ProjectMinterRemoved(uint256 indexed _projectId);

    function genArt721CoreAddress() external returns (address);

    function setMinterForProject(uint256, address) external;

    function removeMinterForProject(uint256) external;

    function mint(
        address _to,
        uint256 _projectId,
        address sender
    ) external returns (uint256);

    function getMinterForProject(uint256) external view returns (address);

    function projectHasMinter(uint256) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity 0.8.17;

import "./IRandomizerV2.sol";

interface IRandomizerPolyptychV0 is IRandomizerV2 {
    /**
     * @notice Minter contract at `_contractAddress` allowed to assign token hash seeds.
     */
    event HashSeedSetterUpdated(address indexed _contractAddress);

    /**
     * @notice Project with ID `_projectId` is enabled/disabled for polyptych minting.
     */
    event ProjectIsPolyptychUpdated(uint256 _projectId, bool _isPolyptych);

    /**
     * @notice When a core contract calls this, it can be assured that the randomizer
     * will set a bytes32 hash for tokenId `_tokenId` on the core contract. This function
     * may only be called by the contract configured as the `hashSeedSetterContract` via
     * the `setHashSeedSetterContract` available to the core contract admin.
     */
    function assignTokenHash(uint256 _tokenId) external;

    /**
     * @notice Store the token hash seed for an existing token to be re-used in a polyptych panel.
     */
    function setPolyptychHashSeed(uint256 _tokenId, bytes12 _hashSeed) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

import "./IGenArt721CoreContractV3_Base.sol";

interface IRandomizerV2 {
    // The core contract that may interact with this randomizer contract.
    function genArt721Core()
        external
        view
        returns (IGenArt721CoreContractV3_Base);

    // When a core contract calls this, it can be assured that the randomizer
    // will set a bytes32 hash for tokenId `_tokenId` on the core contract.
    function assignTokenHash(uint256 _tokenId) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IMinterBaseV0.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Base.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3.sol";
import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Engine.sol";

import "@openzeppelin-4.7/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Minter Base Class
 * @notice A base class for Art Blocks minter contracts that provides common
 * functionality used across minter contracts.
 * This contract is not intended to be deployed directly, but rather to be
 * inherited by other minter contracts.
 * From a design perspective, this contract is intended to remain simple and
 * easy to understand. It is not intended to cause a complex inheritance tree,
 * and instead should keep minter contracts as readable as possible for
 * collectors and developers.
 * @dev Semantic versioning is used in the solidity file name, and is therefore
 * controlled by contracts importing the appropriate filename version.
 * @author Art Blocks Inc.
 */
abstract contract MinterBase is IMinterBaseV0 {
    /// state variable that tracks whether this contract's associated core
    /// contract is an Engine contract, where Engine contracts have an
    /// additional revenue split for the platform provider
    bool public immutable isEngine;

    // @dev we do not track an initialization state, as the only state variable
    // is immutable, which the compiler enforces to be assigned during
    // construction.

    /**
     * @notice Initializes contract to ensure state variable `isEngine` is set
     * appropriately based on the minter's associated core contract address.
     * @param genArt721Address Art Blocks core contract address for
     * which this contract will be a minter.
     */
    constructor(address genArt721Address) {
        // set state variable isEngine
        isEngine = _getV3CoreIsEngine(genArt721Address);
    }

    /**
     * @notice splits ETH funds between sender (if refund), providers,
     * artist, and artist's additional payee for a token purchased on
     * project `_projectId`.
     * WARNING: This function uses msg.value and msg.sender to determine
     * refund amounts, and therefore may not be applicable to all use cases
     * (e.g. do not use with Dutch Auctions with on-chain settlement).
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param pricePerTokenInWei Current price of token, in Wei.
     */
    function splitFundsETH(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address genArt721CoreAddress
    ) internal {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - pricePerTokenInWei;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split revenues
            splitRevenuesETH(
                projectId,
                pricePerTokenInWei,
                genArt721CoreAddress
            );
        }
    }

    /**
     * @notice splits ETH revenues between providers, artist, and artist's
     * additional payee for revenue generated by project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     * @param projectId Project ID for which funds shall be split.
     * @param valueInWei Value to be split, in Wei.
     */
    function splitRevenuesETH(
        uint256 projectId,
        uint256 valueInWei,
        address genArtCoreContract
    ) internal {
        if (valueInWei <= 0) {
            return; // return early
        }
        bool success;
        // split funds between platforms, artist, and artist's
        // additional payee
        uint256 renderProviderRevenue_;
        address payable renderProviderAddress_;
        uint256 artistRevenue_;
        address payable artistAddress_;
        uint256 additionalPayeePrimaryRevenue_;
        address payable additionalPayeePrimaryAddress_;
        if (isEngine) {
            // get engine splits
            uint256 platformProviderRevenue_;
            address payable platformProviderAddress_;
            (
                renderProviderRevenue_,
                renderProviderAddress_,
                platformProviderRevenue_,
                platformProviderAddress_,
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3_Engine(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, valueInWei);
            // Platform Provider payment (only possible if engine)
            if (platformProviderRevenue_ > 0) {
                (success, ) = platformProviderAddress_.call{
                    value: platformProviderRevenue_
                }("");
                require(success, "Platform Provider payment failed");
            }
        } else {
            // get flagship splits
            (
                renderProviderRevenue_, // artblocks revenue
                renderProviderAddress_, // artblocks address
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, valueInWei);
        }
        // Render Provider / Art Blocks payment
        if (renderProviderRevenue_ > 0) {
            (success, ) = renderProviderAddress_.call{
                value: renderProviderRevenue_
            }("");
            require(success, "Render Provider payment failed");
        }
        // artist payment
        if (artistRevenue_ > 0) {
            (success, ) = artistAddress_.call{value: artistRevenue_}("");
            require(success, "Artist payment failed");
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue_ > 0) {
            (success, ) = additionalPayeePrimaryAddress_.call{
                value: additionalPayeePrimaryRevenue_
            }("");
            require(success, "Additional Payee payment failed");
        }
    }

    /**
     * @notice splits ERC-20 funds between providers, artist, and artist's
     * additional payee, for a token purchased on project `_projectId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * business practices, including end-to-end testing on mainnet, and
     * admin-accepted artist payment addresses.
     */
    function splitFundsERC20(
        uint256 projectId,
        uint256 pricePerTokenInWei,
        address currencyAddress,
        address genArtCoreContract
    ) internal {
        IERC20 _projectCurrency = IERC20(currencyAddress);
        // split remaining funds between foundation, artist, and artist's
        // additional payee
        uint256 renderProviderRevenue_;
        address payable renderProviderAddress_;
        uint256 artistRevenue_;
        address payable artistAddress_;
        uint256 additionalPayeePrimaryRevenue_;
        address payable additionalPayeePrimaryAddress_;
        if (isEngine) {
            // get engine splits
            uint256 platformProviderRevenue_;
            address payable platformProviderAddress_;
            (
                renderProviderRevenue_,
                renderProviderAddress_,
                platformProviderRevenue_,
                platformProviderAddress_,
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3_Engine(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, pricePerTokenInWei);
            // Platform Provider payment (only possible if engine)
            if (platformProviderRevenue_ > 0) {
                _projectCurrency.transferFrom(
                    msg.sender,
                    platformProviderAddress_,
                    platformProviderRevenue_
                );
            }
        } else {
            // get flagship splits
            (
                renderProviderRevenue_, // artblocks revenue
                renderProviderAddress_, // artblocks address
                artistRevenue_,
                artistAddress_,
                additionalPayeePrimaryRevenue_,
                additionalPayeePrimaryAddress_
            ) = IGenArt721CoreContractV3(genArtCoreContract)
                .getPrimaryRevenueSplits(projectId, pricePerTokenInWei);
        }
        // Art Blocks payment
        if (renderProviderRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                renderProviderAddress_,
                renderProviderRevenue_
            );
        }
        // artist payment
        if (artistRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                artistAddress_,
                artistRevenue_
            );
        }
        // additional payee payment
        if (additionalPayeePrimaryRevenue_ > 0) {
            _projectCurrency.transferFrom(
                msg.sender,
                additionalPayeePrimaryAddress_,
                additionalPayeePrimaryRevenue_
            );
        }
    }

    /**
     * @notice Returns whether a V3 core contract is an Art Blocks Engine
     * contract or not. Return value of false indicates that the core is a
     * flagship contract.
     * @dev this function reverts if a core contract does not return the
     * expected number of return values from getPrimaryRevenueSplits() for
     * either a flagship or engine core contract.
     * @dev this function uses the length of the return data (in bytes) to
     * determine whether the core is an engine or not.
     * @param genArt721CoreV3 The address of the deployed core contract.
     */
    function _getV3CoreIsEngine(
        address genArt721CoreV3
    ) private returns (bool) {
        // call getPrimaryRevenueSplits() on core contract
        bytes memory payload = abi.encodeWithSignature(
            "getPrimaryRevenueSplits(uint256,uint256)",
            0,
            0
        );
        (bool success, bytes memory returnData) = genArt721CoreV3.call(payload);
        require(success, "getPrimaryRevenueSplits() call failed");
        // determine whether core is engine or not, based on return data length
        uint256 returnDataLength = returnData.length;
        if (returnDataLength == 6 * 32) {
            // 6 32-byte words returned if flagship (not engine)
            // @dev 6 32-byte words are expected because the non-engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, and artist's additional payee, and Art Blocks.
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return false;
        } else if (returnDataLength == 8 * 32) {
            // 8 32-byte words returned if engine
            // @dev 8 32-byte words are expected because the engine core
            // contracts return a payout address and uint256 payment value for
            // the artist, artist's additional payee, render provider
            // typically Art Blocks, and platform provider (partner).
            // also note that per Solidity ABI encoding, the address return
            // values are padded to 32 bytes.
            return true;
        } else {
            // unexpected return value length
            revert("Unexpected revenue split bytes");
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../../interfaces/0.8.x/IGenArt721CoreContractV3_Engine.sol";
import "../../interfaces/0.8.x/IMinterFilterV0.sol";
import "../../interfaces/0.8.x/IFilteredMinterHolderV2.sol";
import "../../interfaces/0.8.x/IRandomizerPolyptychV0.sol";
import "../../interfaces/0.8.x/IDelegationRegistry.sol";
import "./MinterBase_v0_1_1.sol";

import "@openzeppelin-4.5/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin-4.5/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin-4.5/contracts/utils/structs/EnumerableSet.sol";

pragma solidity 0.8.17;

/**
 * @title Core contract interface for accessing the randomizer from the minter
 * @notice This interface provides the minter with access to the randomizer, allowing the
 * token hash seed for a newly-minted token to be assigned by the minter if the artist
 * has enabled the project as a polyptych. Polytptych projects must use the V3 engine
 * core contract, polyptych minter, and polyptych randomizer - this interface allows the
 * minter to access the randomizer.
 */
interface IGenArt721CoreContractV3WithRandomizer is
    IGenArt721CoreContractV3_Engine
{
    /// current randomizer contract
    function randomizerContract() external returns (IRandomizerPolyptychV0);
}

/**
 * @title Filtered Minter contract that allows tokens to be minted with ETH or ERC20 tokens
 * when purchaser owns an allowlisted ERC-721 NFT. This contract must be used with
 * an accompanying randomizer contract that is configured to copy the token hash seed
 * from the allowlisted token to a corresponding newly-minted token.
 * The source token may only be used to mint one additional polyptych "panel" if the token
 * has not yet been used to mint a panel with the currently configured panel ID. To add
 * an additional panel to a project, the panel ID may be incremented for the project
 * using the `incrementPolyptychProjectPanelId` function. Panel IDs for a project may only
 * be incremented such that panels must be minted in the order of their panel ID. Tokens
 * of the same project and panel ID may be minted in any order.
 * This is designed to be used with IGenArt721CoreContractV3_Engine contracts with an
 * active IPolyptychRandomizerV0 randomizer available for this minter to use.
 * This minter requires both a properly configured engine core contract and polyptych
 * randomizer in order to mint polyptych tokens.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract is designed to be managed, with limited powers.
 * Privileged roles and abilities are controlled by the core contract's Admin
 * ACL contract and a project's artist. Both of these roles hold extensive
 * power and can modify minter details.
 * Care must be taken to ensure that the admin ACL contract and artist
 * addresses are secure behind a multi-sig or other access control mechanism.
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the core contract's Admin ACL
 * contract:
 * - registerNFTAddress
 * - unregisterNFTAddress
 * ----------------------------------------------------------------------------
 * The following functions are restricted to a project's artist:
 * - allowHoldersOfProjects
 * - removeHoldersOfProjects
 * - allowRemoveHoldersOfProjects
 * - updatePricePerTokenInWei
 * - updateProjectCurrencyInfo
 * - setProjectMaxInvocations
 * - manuallyLimitProjectMaxInvocations
 * ----------------------------------------------------------------------------
 * Additional admin and artist privileged roles may be described on other
 * contracts that this minter integrates with.
 * ----------------------------------------------------------------------------
 * This contract allows gated minting with support for vaults to delegate minting
 * privileges via an external delegation registry. This means a vault holding an
 * allowed token can delegate minting privileges to a wallet that is not holding an
 * allowed token, enabling the vault to remain air-gapped while still allowing minting.
 * The delegation registry contract is responsible for managing these delegations,
 * and is available at the address returned by the public immutable
 * `delegationRegistryAddress`. At the time of writing, the delegation
 * registry enables easy delegation configuring at https://delegate.cash/.
 * Art Blocks does not guarentee the security of the delegation registry, and
 * users should take care to ensure that the delegation registry is secure.
 * Delegations must be configured by the vault owner prior to purchase. Supported
 * delegation types include token-level, contract-level (via genArt721CoreAddress), or
 * wallet-level delegation. Contract-level delegations must be configured for the core
 * token contract as returned by the owned token's core contract address.
 */
contract MinterPolyptychV0 is
    ReentrancyGuard,
    MinterBase,
    IFilteredMinterHolderV2
{
    // add Enumerable Set methods
    using EnumerableSet for EnumerableSet.AddressSet;

    /// Delegation registry address
    address public immutable delegationRegistryAddress;

    /// Delegation registry address
    IDelegationRegistry private immutable delegationRegistryContract;

    /// Core contract address this minter interacts with
    address public immutable genArt721CoreAddress;

    /// This contract handles cores with interface IV3
    IGenArt721CoreContractV3WithRandomizer private immutable genArtCoreContract;

    /// Minter filter address this minter interacts with
    address public immutable minterFilterAddress;

    /// Minter filter this minter may interact with.
    IMinterFilterV0 private immutable minterFilter;

    // Stores whether a panel with an ID has been minted for a given token hash seed
    // panelId => hashSeed => panelIsMinted
    mapping(uint256 => mapping(bytes12 => bool))
        public polyptychPanelHashSeedIsMinted;

    /// minterType for this minter
    string public constant minterType = "MinterPolyptychV0";

    /// minter version for this minter
    string public constant minterVersion = "v0.1.0";

    uint256 constant ONE_MILLION = 1_000_000;

    struct ProjectConfig {
        bool maxHasBeenInvoked;
        bool priceIsConfigured;
        uint24 maxInvocations;
        uint24 polyptychPanelId;
        address currencyAddress;
        uint256 pricePerTokenInWei;
        string currencySymbol;
    }

    mapping(uint256 => ProjectConfig) public projectConfig;

    /// Set of core contracts allowed to be queried for token holders
    EnumerableSet.AddressSet private _registeredNFTAddresses;

    /**
     * projectId => ownedNFTAddress => ownedNFTProjectIds => bool
     * projects whose holders are allowed to purchase a token on `projectId`
     */
    mapping(uint256 => mapping(address => mapping(uint256 => bool)))
        public allowedProjectHolders;

    // modifier to restrict access to only AdminACL allowed calls
    // @dev defers which ACL contract is used to the core contract
    modifier onlyCoreAdminACL(bytes4 _selector) {
        require(
            genArtCoreContract.adminACLAllowed(
                msg.sender,
                address(this),
                _selector
            ),
            "Only Core AdminACL allowed"
        );
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "Only Artist"
        );
        _;
    }

    /**
     * @notice Initializes contract to be a Filtered Minter for
     * `_minterFilter`, integrated with Art Blocks core contract
     * at address `_genArt721Address`.
     * @param _genArt721Address Art Blocks core contract for which this
     * contract will be a minter.
     * @param _minterFilter Minter filter for which
     * this will a filtered minter.
     * @param _delegationRegistryAddress Delegation registry contract address.
     */
    constructor(
        address _genArt721Address,
        address _minterFilter,
        address _delegationRegistryAddress
    ) ReentrancyGuard() MinterBase(_genArt721Address) {
        genArt721CoreAddress = _genArt721Address;
        genArtCoreContract = IGenArt721CoreContractV3WithRandomizer(
            _genArt721Address
        );
        delegationRegistryAddress = _delegationRegistryAddress;
        emit DelegationRegistryUpdated(_delegationRegistryAddress);
        delegationRegistryContract = IDelegationRegistry(
            _delegationRegistryAddress
        );
        minterFilterAddress = _minterFilter;
        minterFilter = IMinterFilterV0(_minterFilter);
        require(
            minterFilter.genArt721CoreAddress() == _genArt721Address,
            "Illegal contract pairing"
        );
        // currently, this minter only supports Engine V3 core contracts
        require(MinterBase.isEngine, "Only supports V3 Engine core");
    }

    /**
     * @notice Return whether or not a token has been used to mint a polyptych panel with the given ID
     * @param _panelId The ID of the polyptych panel being checked
     * @param _ownedNFTAddress ERC-721 NFT address holding the project token
     * owned by msg.sender being used to prove right to purchase
     * @param _ownedNFTTokenId ERC-721 NFT token ID owned by msg.sender being used
     * to prove right to purchase
     */
    function polyptychPanelMintedWithToken(
        uint24 _panelId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId
    ) external view returns (bool panelMinted) {
        bytes12 _tokenHash = IGenArt721CoreContractV3_Engine(_ownedNFTAddress)
            .tokenIdToHashSeed(_ownedNFTTokenId);
        require(_tokenHash != bytes32(0), "Invalid token hash seed");
        return polyptychPanelHashSeedIsMinted[_panelId][_tokenHash];
    }

    /**
     *
     * @notice Registers holders of NFTs at address `_NFTAddress` to be
     * considered for minting. New core address is assumed to follow syntax of:
     * `projectId = tokenId / 1_000_000`
     * @param _NFTAddress NFT core address to be registered.
     */
    function registerNFTAddress(
        address _NFTAddress
    ) external onlyCoreAdminACL(this.registerNFTAddress.selector) {
        // check that core contract implements the `tokenIdToHashSeed` function
        IGenArt721CoreContractV3WithRandomizer(_NFTAddress).tokenIdToHashSeed(
            0
        );
        _registeredNFTAddresses.add(_NFTAddress);
        emit RegisteredNFTAddress(_NFTAddress);
    }

    /**
     *
     * @notice Unregisters holders of NFTs at address `_NFTAddress` to be
     * considered for adding to future allowlists.
     * @param _NFTAddress NFT core address to be unregistered.
     */
    function unregisterNFTAddress(
        address _NFTAddress
    ) external onlyCoreAdminACL(this.unregisterNFTAddress.selector) {
        _registeredNFTAddresses.remove(_NFTAddress);
        emit UnregisteredNFTAddress(_NFTAddress);
    }

    /**
     * @notice Allows holders of NFTs at addresses `_ownedNFTAddressesAdd`,
     * project IDs `_ownedNFTProjectIdsAdd` to mint on project `_projectId`.
     * Also removes holders of NFTs at addresses `_ownedNFTAddressesRemove`,
     * project IDs `_ownedNFTProjectIdsRemove` from minting on project
     * `_projectId`.
     * `_ownedNFTAddressesAdd` assumed to be aligned with
     * `_ownedNFTProjectIdsAdd`.
     * e.g. Allows holders of project `_ownedNFTProjectIdsAdd[0]` on token
     * contract `_ownedNFTAddressesAdd[0]` to mint `_projectId`.
     * `_ownedNFTAddressesRemove` also assumed to be aligned with
     * `_ownedNFTProjectIdsRemove`.
     * @param _projectId Project ID to enable minting on.
     * @param _ownedNFTAddressesAdd NFT core addresses of projects to be
     * allowlisted. Indexes must align with `_ownedNFTProjectIdsAdd`.
     * @param _ownedNFTProjectIdsAdd Project IDs on `_ownedNFTAddressesAdd`
     * whose holders shall be allowlisted to mint project `_projectId`. Indexes
     * must align with `_ownedNFTAddressesAdd`.
     * @param _ownedNFTAddressesRemove NFT core addresses of projects to be
     * removed from allowlist. Indexes must align with
     * `_ownedNFTProjectIdsRemove`.
     * @param _ownedNFTProjectIdsRemove Project IDs on
     * `_ownedNFTAddressesRemove` whose holders will be removed from allowlist
     * to mint project `_projectId`. Indexes must align with
     * `_ownedNFTAddressesRemove`.
     * @dev if a project is included in both add and remove arrays, it will be
     * removed.
     */
    function allowRemoveHoldersOfProjects(
        uint256 _projectId,
        address[] memory _ownedNFTAddressesAdd,
        uint256[] memory _ownedNFTProjectIdsAdd,
        address[] memory _ownedNFTAddressesRemove,
        uint256[] memory _ownedNFTProjectIdsRemove
    ) external onlyArtist(_projectId) {
        allowHoldersOfProjects(
            _projectId,
            _ownedNFTAddressesAdd,
            _ownedNFTProjectIdsAdd
        );
        removeHoldersOfProjects(
            _projectId,
            _ownedNFTAddressesRemove,
            _ownedNFTProjectIdsRemove
        );
    }

    /**
     * @notice Syncs local maximum invocations of project `_projectId` based on
     * the value currently defined in the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev this enables gas reduction after maxInvocations have been reached -
     * core contracts shall still enforce a maxInvocation check during mint.
     */
    function setProjectMaxInvocations(uint256 _projectId) public {
        uint256 maxInvocations;
        uint256 invocations;
        (invocations, maxInvocations, , , , ) = genArtCoreContract
            .projectStateData(_projectId);
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(maxInvocations);

        // We need to ensure maxHasBeenInvoked is correctly set after manually syncing the
        // local maxInvocations value with the core contract's maxInvocations value.
        // This synced value of maxInvocations from the core contract will always be greater
        // than or equal to the previous value of maxInvocations stored locally.
        projectConfig[_projectId].maxHasBeenInvoked =
            invocations == maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, maxInvocations);
    }

    /**
     * @notice Manually sets the local maximum invocations of project `_projectId`
     * with the provided `_maxInvocations`, checking that `_maxInvocations` is less
     * than or equal to the value of project `_project_id`'s maximum invocations that is
     * set on the core contract.
     * @dev Note that a `_maxInvocations` of 0 can only be set if the current `invocations`
     * value is also 0 and this would also set `maxHasBeenInvoked` to true, correctly short-circuiting
     * this minter's purchase function, avoiding extra gas costs from the core contract's maxInvocations check.
     * @param _projectId Project ID to set the maximum invocations for.
     * @param _maxInvocations Maximum invocations to set for the project.
     */
    function manuallyLimitProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) external onlyArtist(_projectId) {
        // CHECKS
        // ensure that the manually set maxInvocations is not greater than what is set on the core contract
        uint256 maxInvocations;
        uint256 invocations;
        (invocations, maxInvocations, , , , ) = genArtCoreContract
            .projectStateData(_projectId);
        require(
            _maxInvocations <= maxInvocations,
            "Cannot increase project max invocations above core contract set project max invocations"
        );
        require(
            _maxInvocations >= invocations,
            "Cannot set project max invocations to less than current invocations"
        );

        // EFFECTS
        // update storage with results
        projectConfig[_projectId].maxInvocations = uint24(_maxInvocations);
        // We need to ensure maxHasBeenInvoked is correctly set after manually setting the
        // local maxInvocations value.
        projectConfig[_projectId].maxHasBeenInvoked =
            invocations == _maxInvocations;

        emit ProjectMaxInvocationsLimitUpdated(_projectId, _maxInvocations);
    }

    /**
     * @notice Updates this minter's price per token of project `_projectId`
     * to be '_pricePerTokenInWei`, in Wei.
     * This price supersedes any legacy core contract price per token value.
     * @dev Note that it is intentionally supported here that the configured
     * price may be explicitly set to `0`.
     */
    function updatePricePerTokenInWei(
        uint256 _projectId,
        uint256 _pricePerTokenInWei
    ) external onlyArtist(_projectId) {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        _projectConfig.pricePerTokenInWei = _pricePerTokenInWei;
        _projectConfig.priceIsConfigured = true;
        emit PricePerTokenInWeiUpdated(_projectId, _pricePerTokenInWei);

        // sync local max invocations if not initially populated
        // @dev if local max invocations and maxHasBeenInvoked are both
        // initial values, we know they have not been populated.
        if (
            _projectConfig.maxInvocations == 0 &&
            _projectConfig.maxHasBeenInvoked == false
        ) {
            setProjectMaxInvocations(_projectId);
        }
    }

    /**
     * @notice Updates payment currency of project `_projectId` to be
     * `_currencySymbol` at address `_currencyAddress`.
     * @param _projectId Project ID to update.
     * @param _currencySymbol Currency symbol.
     * @param _currencyAddress Currency address.
     */
    function updateProjectCurrencyInfo(
        uint256 _projectId,
        string memory _currencySymbol,
        address _currencyAddress
    ) external onlyArtist(_projectId) {
        // require null address if symbol is "ETH"
        require(
            (keccak256(abi.encodePacked(_currencySymbol)) ==
                keccak256(abi.encodePacked("ETH"))) ==
                (_currencyAddress == address(0)),
            "ETH is only null address"
        );
        projectConfig[_projectId].currencySymbol = _currencySymbol;
        projectConfig[_projectId].currencyAddress = _currencyAddress;
        emit ProjectCurrencyInfoUpdated(
            _projectId,
            _currencyAddress,
            _currencySymbol
        );
    }

    /**
     * @notice Purchases a token from project `_projectId`.
     * @param _projectId Project ID to mint a token on.
     * @param _ownedNFTAddress ERC-721 NFT address holding the project token
     * owned by msg.sender being used to prove right to purchase.
     * @param _ownedNFTTokenId ERC-721 NFT token ID owned by msg.sender being used
     * to prove right to purchase.
     * @return tokenId Token ID of minted token
     */
    function purchase(
        uint256 _projectId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_dlc(
            msg.sender,
            _projectId,
            _ownedNFTAddress,
            _ownedNFTTokenId,
            address(0)
        );
        return tokenId;
    }

    /**
     * @notice gas-optimized version of purchase(uint256,address,uint256).
     */
    function purchase_nnf(
        uint256 _projectId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId
    ) external payable returns (uint256 tokenId) {
        tokenId = purchaseTo_dlc(
            msg.sender,
            _projectId,
            _ownedNFTAddress,
            _ownedNFTTokenId,
            address(0)
        );
        return tokenId;
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @param _ownedNFTAddress ERC-721 NFT holding the project token owned by
     * msg.sender being used to claim right to purchase.
     * @param _ownedNFTTokenId ERC-721 NFT token ID owned by msg.sender being used
     * to claim right to purchase.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo(
        address _to,
        uint256 _projectId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId
    ) external payable returns (uint256 tokenId) {
        return
            purchaseTo_dlc(
                _to,
                _projectId,
                _ownedNFTAddress,
                _ownedNFTTokenId,
                address(0)
            );
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     *         the token's owner to `_to`, as a delegate, (the `msg.sender`)
     *         on behalf of an explicitly defined vault.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @param _ownedNFTAddress ERC-721 NFT address holding the project token owned by
     *         _vault (or msg.sender if no _vault is provided) being used to claim right to purchase.
     * @param _ownedNFTTokenId ERC-721 NFT token ID owned by _vault (or msg.sender if
     *         no _vault is provided) being used to claim right to purchase.
     * @param _vault Vault being purchased on behalf of.  Acceptable to be `address(0)` if no vault.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo(
        address _to,
        uint256 _projectId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId,
        address _vault
    ) external payable returns (uint256 tokenId) {
        return
            purchaseTo_dlc(
                _to,
                _projectId,
                _ownedNFTAddress,
                _ownedNFTTokenId,
                _vault
            );
    }

    /**
     * @notice Inactive function - requires NFT ownership to purchase.
     */
    function purchase(uint256) external payable returns (uint256) {
        revert("Must claim NFT ownership");
    }

    /**
     * @notice Warning: Disabling purchaseTo is not supported on this minter.
     * This method exists purely for interface-conformance purposes.
     */
    function togglePurchaseToDisabled(
        uint256 _projectId
    ) external view onlyArtist(_projectId) {
        revert("Action not supported");
    }

    /**
     * @notice projectId => has project reached its maximum number of
     * invocations? Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached. A false negative will
     * only result in a gas cost increase, since the core contract will still
     * enforce a maxInvocation check during minting. A false positive is not
     * possible because the V3 core contract only allows maximum invocations
     * to be reduced, not increased. Based on this rationale, we intentionally
     * do not do input validation in this method as to whether or not the input
     * `_projectId` is an existing project ID.
     */
    function projectMaxHasBeenInvoked(
        uint256 _projectId
    ) external view returns (bool) {
        return projectConfig[_projectId].maxHasBeenInvoked;
    }

    /**
     * @notice projectId => project's maximum number of invocations.
     * Optionally synced with core contract value, for gas optimization.
     * Note that this returns a local cache of the core contract's
     * state, and may be out of sync with the core contract. This is
     * intentional, as it only enables gas optimization of mints after a
     * project's maximum invocations has been reached.
     * @dev A number greater than the core contract's project max invocations
     * will only result in a gas cost increase, since the core contract will
     * still enforce a maxInvocation check during minting. A number less than
     * the core contract's project max invocations is only possible when the
     * project's max invocations have not been synced on this minter, since the
     * V3 core contract only allows maximum invocations to be reduced, not
     * increased. When this happens, the minter will enable minting, allowing
     * the core contract to enforce the max invocations check. Based on this
     * rationale, we intentionally do not do input validation in this method as
     * to whether or not the input `_projectId` is an existing project ID.
     */
    function projectMaxInvocations(
        uint256 _projectId
    ) external view returns (uint256) {
        return uint256(projectConfig[_projectId].maxInvocations);
    }

    /**
     * @notice Gets your balance of the ERC-20 token currently set
     * as the payment currency for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return balance Balance of ERC-20
     */
    function getYourBalanceOfProjectERC20(
        uint256 _projectId
    ) external view returns (uint256 balance) {
        balance = IERC20(projectConfig[_projectId].currencyAddress).balanceOf(
            msg.sender
        );
        return balance;
    }

    /**
     * @notice Gets your allowance for this minter of the ERC-20
     * token currently set as the payment currency for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function checkYourAllowanceOfProjectERC20(
        uint256 _projectId
    ) external view returns (uint256 remaining) {
        remaining = IERC20(projectConfig[_projectId].currencyAddress).allowance(
            msg.sender,
            address(this)
        );
        return remaining;
    }

    /**
     * @notice Gets quantity of NFT addresses registered on this minter.
     * @return uint256 quantity of NFT addresses registered
     */
    function getNumRegisteredNFTAddresses() external view returns (uint256) {
        return _registeredNFTAddresses.length();
    }

    /**
     * @notice Get registered NFT core contract address at index `_index` of
     * enumerable set.
     * @param _index enumerable set index to query.
     * @return NFTAddress NFT core contract address at index `_index`
     * @dev index must be < quantity of registered NFT addresses
     */
    function getRegisteredNFTAddressAt(
        uint256 _index
    ) external view returns (address NFTAddress) {
        return _registeredNFTAddresses.at(_index);
    }

    /**
     * @notice Gets if price of token is configured, price of minting a
     * token on project `_projectId`, and currency symbol and address to be
     * used as payment. Supersedes any core contract price information.
     * @param _projectId Project ID to get price information for.
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of project on this
     * minter. This minter always returns "ETH"
     * @return currencyAddress currency address for purchases of project on
     * this minter. This minter always returns null address, reserved for ether
     */
    function getPriceInfo(
        uint256 _projectId
    )
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        ProjectConfig storage _projectConfig = projectConfig[_projectId];
        isConfigured = _projectConfig.priceIsConfigured;
        tokenPriceInWei = _projectConfig.pricePerTokenInWei;
        currencyAddress = _projectConfig.currencyAddress;
        if (currencyAddress == address(0)) {
            // defaults to ETH
            currencySymbol = "ETH";
        } else {
            currencySymbol = _projectConfig.currencySymbol;
        }
    }

    /**
     * @notice Inactive function - requires NFT ownership to purchase.
     */
    function purchaseTo(address, uint256) public payable returns (uint256) {
        revert("Must claim NFT ownership");
    }

    /**
     * @notice gas-optimized version of purchaseTo(address,uint256,address,uint256,address).
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @param _ownedNFTAddress ERC-721 NFT address holding the project token owned by _vault
     *         (or msg.sender if no _vault is provided) being used to claim right to purchase.
     * @param _ownedNFTTokenId ERC-721 NFT token ID owned by _vault (or msg.sender if
     *         no _vault is provided) being used to claim right to purchase.
     * @param _vault Vault being purchased on behalf of. Acceptable to be `address(0)` if no vault.
     * @return tokenId Token ID of minted token
     */
    function purchaseTo_dlc(
        address _to,
        uint256 _projectId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId,
        address _vault
    ) public payable nonReentrant returns (uint256 tokenId) {
        // CHECKS
        ProjectConfig storage _projectConfig = projectConfig[_projectId];

        // Note that `maxHasBeenInvoked` is only checked here to reduce gas
        // consumption after a project has been fully minted.
        // `_projectConfig.maxHasBeenInvoked` is locally cached to reduce
        // gas consumption, but if not in sync with the core contract's value,
        // the core contract also enforces its own max invocation check during
        // minting.
        require(
            !_projectConfig.maxHasBeenInvoked,
            "Maximum number of invocations reached"
        );

        // require artist to have configured price of token on this minter
        require(_projectConfig.priceIsConfigured, "Price not configured");

        // require token used to claim to be in set of allowlisted NFTs
        require(
            isAllowlistedNFT(_projectId, _ownedNFTAddress, _ownedNFTTokenId),
            "Only allowlisted NFTs"
        );

        // NOTE: delegate-vault handling **begins here**.

        // handle that the vault may be either the `msg.sender` in the case
        // that there is not a true vault, or may be `_vault` if one is
        // provided explicitly (and it is valid).
        address vault = msg.sender;
        if (_vault != address(0)) {
            // If a vault is provided, it must be valid, otherwise throw rather
            // than optimistically-minting with original `msg.sender`.
            // Note, we do not check `checkDelegateForAll` or `checkDelegateForContract` as well,
            // as they are known to be implicitly checked by calling `checkDelegateForToken`.
            bool isValidVault = delegationRegistryContract
                .checkDelegateForToken(
                    msg.sender, // delegate
                    _vault, // vault
                    _ownedNFTAddress, // contract
                    _ownedNFTTokenId // tokenId
                );
            require(isValidVault, "Invalid delegate-vault pairing");
            vault = _vault;
        }

        // we need the new token ID in advance of the randomizer setting a token hash
        (uint256 _invocations, , , , , ) = genArtCoreContract.projectStateData(
            _projectId
        );

        address _artist = genArtCoreContract.projectIdToArtistAddress(
            _projectId
        );

        uint256 _newTokenId = (_projectId * ONE_MILLION) + _invocations;

        // EFFECTS

        // we need to store the new token ID before it is minted so the randomizer can query it
        IGenArt721CoreContractV3WithRandomizer _ownedNFTCoreContract = IGenArt721CoreContractV3WithRandomizer(
                _ownedNFTAddress
            );
        bytes12 _targetHashSeed = _ownedNFTCoreContract.tokenIdToHashSeed(
            _ownedNFTTokenId
        );

        _requireCurrentPanelIsMintedOnce(_projectId, _targetHashSeed);

        genArtCoreContract.randomizerContract().setPolyptychHashSeed(
            _newTokenId,
            _targetHashSeed
        );

        // once mint() is called, the polyptych randomizer will either:
        // 1) assign a random token hash
        // 2) if configured, obtain the token hash from the `polyptychSeedHashes` mapping
        tokenId = minterFilter.mint(_to, _projectId, vault);

        // NOTE: delegate-vault handling **ends here**.

        // redundant check against reentrancy
        bytes12 _assignedHashSeed = genArtCoreContract.tokenIdToHashSeed(
            tokenId
        );
        require(
            _assignedHashSeed == _targetHashSeed,
            "Unexpected token hash seed"
        );

        // invocation is token number plus one, and will never overflow due to
        // limit of 1e6 invocations per project. block scope for gas efficiency
        // (i.e. avoid an unnecessary var initialization to 0).
        unchecked {
            uint256 tokenInvocation = (tokenId % ONE_MILLION) + 1;
            uint256 localMaxInvocations = _projectConfig.maxInvocations;
            // handle the case where the token invocation == minter local max
            // invocations occurred on a different minter, and we have a stale
            // local maxHasBeenInvoked value returning a false negative.
            // @dev this is a CHECK after EFFECTS, so security was considered
            // in detail here.
            require(
                tokenInvocation <= localMaxInvocations,
                "Maximum invocations reached"
            );
            // in typical case, update the local maxHasBeenInvoked value
            // to true if the token invocation == minter local max invocations
            // (enables gas efficient reverts after sellout)
            if (tokenInvocation == localMaxInvocations) {
                _projectConfig.maxHasBeenInvoked = true;
            }
        }

        // INTERACTIONS
        // require sender to own NFT used to redeem
        /**
         * @dev Considered an interaction because calling ownerOf on an NFT
         * contract. Plan is to only register AB/PBAB NFTs on the minter, but
         * in case other NFTs are registered, better to check here. Also,
         * function is non-reentrant, so being extra cautious.
         */
        if (msg.sender == _artist) {
            require(
                IERC721(_ownedNFTAddress).ownerOf(_ownedNFTTokenId) == _to,
                "Only owner of NFT"
            );
        } else {
            require(
                IERC721(_ownedNFTAddress).ownerOf(_ownedNFTTokenId) == vault,
                "Only owner of NFT"
            );
        }

        // split funds
        uint256 pricePerTokenInWei = _projectConfig.pricePerTokenInWei;
        address currencyAddress = _projectConfig.currencyAddress;
        if (currencyAddress != address(0)) {
            require(
                msg.value == 0,
                "this project accepts a different currency and cannot accept ETH"
            );
            require(
                IERC20(currencyAddress).allowance(msg.sender, address(this)) >=
                    pricePerTokenInWei,
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(currencyAddress).balanceOf(msg.sender) >=
                    pricePerTokenInWei,
                "Insufficient balance."
            );
            splitFundsERC20(
                _projectId,
                pricePerTokenInWei,
                currencyAddress,
                genArt721CoreAddress
            );
        } else {
            require(
                msg.value >= pricePerTokenInWei,
                "Must send minimum value to mint!"
            );
            splitFundsETH(_projectId, pricePerTokenInWei, genArt721CoreAddress);
        }

        return tokenId;
    }

    /**
     * @notice Allows holders of NFTs at addresses `_ownedNFTAddresses`,
     * project IDs `_ownedNFTProjectIds` to mint on project `_projectId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTProjectIds`.
     * e.g. Allows holders of project `_ownedNFTProjectIds[0]` on token
     * contract `_ownedNFTAddresses[0]` to mint `_projectId`.
     * @param _projectId Project ID to enable minting on.
     * @param _ownedNFTAddresses NFT core addresses of projects to be
     * allowlisted. Indexes must align with `_ownedNFTProjectIds`.
     * @param _ownedNFTProjectIds Project IDs on `_ownedNFTAddresses` whose
     * holders shall be allowlisted to mint project `_projectId`. Indexes must
     * align with `_ownedNFTAddresses`.
     */
    function allowHoldersOfProjects(
        uint256 _projectId,
        address[] memory _ownedNFTAddresses,
        uint256[] memory _ownedNFTProjectIds
    ) public onlyArtist(_projectId) {
        // require same length arrays
        require(
            _ownedNFTAddresses.length == _ownedNFTProjectIds.length,
            "Length of add arrays must match"
        );
        // for each approved project
        for (uint256 i = 0; i < _ownedNFTAddresses.length; i++) {
            // ensure registered address
            require(
                _registeredNFTAddresses.contains(_ownedNFTAddresses[i]),
                "Only Registered NFT Addresses"
            );
            // approve
            allowedProjectHolders[_projectId][_ownedNFTAddresses[i]][
                _ownedNFTProjectIds[i]
            ] = true;
        }
        // emit approve event
        emit AllowedHoldersOfProjects(
            _projectId,
            _ownedNFTAddresses,
            _ownedNFTProjectIds
        );
    }

    /**
     * @notice Removes holders of NFTs at addresses `_ownedNFTAddresses`,
     * project IDs `_ownedNFTProjectIds` to mint on project `_projectId`. If
     * other projects owned by a holder are still allowed to mint, holder will
     * maintain ability to purchase.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTProjectIds`.
     * e.g. Removes holders of project `_ownedNFTProjectIds[0]` on token
     * contract `_ownedNFTAddresses[0]` from mint allowlist of `_projectId`.
     * @param _projectId Project ID to enable minting on.
     * @param _ownedNFTAddresses NFT core addresses of projects to be removed
     * from allowlist. Indexes must align with `_ownedNFTProjectIds`.
     * @param _ownedNFTProjectIds Project IDs on `_ownedNFTAddresses` whose
     * holders will be removed from allowlist to mint project `_projectId`.
     * Indexes must align with `_ownedNFTAddresses`.
     */
    function removeHoldersOfProjects(
        uint256 _projectId,
        address[] memory _ownedNFTAddresses,
        uint256[] memory _ownedNFTProjectIds
    ) public onlyArtist(_projectId) {
        // require same length arrays
        require(
            _ownedNFTAddresses.length == _ownedNFTProjectIds.length,
            "Length of remove arrays must match"
        );
        // for each removed project
        for (uint256 i = 0; i < _ownedNFTAddresses.length; i++) {
            // revoke
            allowedProjectHolders[_projectId][_ownedNFTAddresses[i]][
                _ownedNFTProjectIds[i]
            ] = false;
        }
        // emit removed event
        emit RemovedHoldersOfProjects(
            _projectId,
            _ownedNFTAddresses,
            _ownedNFTProjectIds
        );
    }

    /**
     * @notice Allows the artist to increment the minter to the next polyptych panel
     * @param _projectId Project ID to increment to its next polyptych panel
     */
    function incrementPolyptychProjectPanelId(
        uint256 _projectId
    ) public onlyArtist(_projectId) {
        projectConfig[_projectId].polyptychPanelId++;
    }

    /**
     * @notice Returns if token is an allowlisted NFT for project `_projectId`.
     * @param _projectId Project ID to be checked.
     * @param _ownedNFTAddress ERC-721 NFT token address to be checked.
     * @param _ownedNFTTokenId ERC-721 NFT token ID to be checked.
     * @return bool Token is allowlisted
     * @dev does not check if token has been used to purchase
     * @dev assumes project ID can be derived from tokenId / 1_000_000
     */
    function isAllowlistedNFT(
        uint256 _projectId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId
    ) public view returns (bool) {
        uint256 ownedNFTProjectId = _ownedNFTTokenId / ONE_MILLION;
        return
            allowedProjectHolders[_projectId][_ownedNFTAddress][
                ownedNFTProjectId
            ];
    }

    function _requireCurrentPanelIsMintedOnce(
        uint256 _projectId,
        bytes12 _tokenHashSeed
    ) private {
        // mark the polyptych panel as minted so the same panel cannot be minted twice
        uint256 _panelId = projectConfig[_projectId].polyptychPanelId;

        require(
            _tokenHashSeed != bytes12(0),
            "Cannot have an empty hash seed to copy."
        );

        require(
            !polyptychPanelHashSeedIsMinted[_panelId][_tokenHashSeed],
            "Panel already minted"
        );
        polyptychPanelHashSeedIsMinted[_panelId][_tokenHashSeed] = true;
    }
}