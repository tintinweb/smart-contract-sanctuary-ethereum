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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";

interface ConfigStoreInterface {
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    function getImplementationAddress(bytes32 interfaceName) external view returns (address);
}

error ImplementationNotFound();

contract ConfigStore is ConfigStoreInterface, Ownable, Multicall {
    mapping(bytes32 => address) public interfacesImplemented;

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    /**
     * @notice Updates the address of the contract that implements `interfaceName`.
     * @param interfaceName bytes32 of the interface name that is either changed or registered.
     * @param implementationAddress address of the implementation contract.
     */
    function changeImplementationAddress(
        bytes32 interfaceName,
        address implementationAddress
    )
        external
        override
        onlyOwner
    {
        interfacesImplemented[interfaceName] = implementationAddress;

        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }

    /**
     * @notice Gets the address of the contract that implements the given `interfaceName`.
     * @param interfaceName queried interface.
     * @return implementationAddress address of the defined interface.
     */
    function getImplementationAddress(bytes32 interfaceName) external view override returns (address) {
        address implementationAddress = interfacesImplemented[interfaceName];
        if (implementationAddress == address(0x0)) revert ImplementationNotFound();
        return implementationAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout Spire contracts by registration in the ConfigStore.
 */
library ConfigStoreInterfaces {
    // Receives staked treasure from Contest winners and ETH from minting losing entries.
    bytes32 internal constant BENEFICIARY = "BENEFICIARY";
    // Creates new Contests
    bytes32 internal constant CONTEST_FACTORY = "CONTEST_FACTORY";
}

/**
 * @title Global constants used throughout Spire contracts.
 *
 */
library GlobalConstants {
    uint256 internal constant GENESIS_TEXT_COUNT = 8;
    uint256 internal constant CONTEST_REWARD_AMOUNT = 100;
    uint256 internal constant INITIAL_ECHO_COUNT = 5;
    uint256 internal constant DEFAULT_CONTEST_MINIMUM_TIME = 7 days;
    uint256 internal constant DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES = 8;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Address } from "openzeppelin-contracts/contracts/utils/Address.sol";
import { IContestStaker } from "./ContestStaker.sol";
import { GlobalConstants } from "./Constants.sol";
import { IContest } from "./IContest.sol";
import "./HasConfigStore.sol";

// Contest Errors
error EntryExists(address entrant);
error HasWinner();
error NoWinner();
error DoesNotHaveWinner();
error Closed();
error NotClosed();
error EntryNotExists();
error NoStake();
error EntryApproved();
error NotEntrant();
error CannotReclaimWinner();
error InvalidMinimumContestTime();
error InvalidApprovedEntryThreshold();

/**
 * @title Contest
 * @notice A Contest lasts for a minimum of 7 days, during which time users can submit entries. The owner can
 * select a winning entry after the 7 days are passed and at least 8 entries have been submitted. The winning entry
 * is minted ERC1155's unique to their entry ID. After 7 days and at least 8 entries have been submitted the contest
 * is closed to new entries.
 * @dev How entries work: In order to submit an entry, a user must stake a designated ERC1155 `stakedToken` in the
 * contest staker contract. By submitting an entry, the user allows this contract to freeze their staked balance
 * in the staker contract until they cancel their entry (or reclaim their losing one). The owner can then approve
 * approve the entry in order for it to be considered for a winning entry and to count towards the
 * "approved entry threshold".
 * @dev What happens to losing entries: Losing entrants can "reclaim" their staked token which instructs this contract
 * to unfreeze their balance in the staker contract. Any user can also can cancel their entry submission if it
 * hasn't been approved as a valid entry yet.
 * @dev What happens to winning entries: The winning entry's staked token is transferred to the beneficiary. The winner
 * is minted a an ERC1155 token with an ID unique to their entry ID.
 */
contract Contest is IContest, HasConfigStore, Ownable, ReentrancyGuard, Multicall {
    using Address for address;

    // Count of approved entries.
    uint256 public approvedEntries;

    // Timestamp when contest was constructed.
    uint256 public contestStartTime;

    // Conditions that must pass for submission phase to be closed.
    uint256 public immutable minimumContestTime;
    uint256 public immutable approvedEntryThreshold;

    struct Winner {
        uint256 winningId;
        address winner;
    }

    Winner public winner;

    struct Entry {
        bool isApproved;
        string entryURI;
        address entrant;
        uint256 stakedTokenId;
    }

    mapping(uint256 => Entry) public entries;

    modifier noWinner() {
        if (hasWinner()) {
            revert HasWinner();
        }
        _;
    }

    event SubmittedEntry(uint256 indexed stakedTokenId, uint256 indexed entryId, address indexed entrant, string uri);
    event AcceptedEntry(uint256 indexed entryId, address indexed entrant);
    event SetWinningEntry(uint256 indexed entryId, address indexed winner, uint256 indexed stakedTokenId);
    event CancelledEntry(uint256 indexed entryId, address indexed entrant, uint256 indexed stakedTokenId);
    event ReclaimedLosingEntry(uint256 indexed entryId, address indexed entrant, uint256 indexed stakedTokenId);

    constructor(
        uint256 _minimumContestTime,
        uint256 _approvedEntryThreshold,
        ConfigStore _configStore
    )
        HasConfigStore(_configStore)
    {
        contestStartTime = block.timestamp;

        if (_minimumContestTime < 600) revert InvalidMinimumContestTime();
        if (_approvedEntryThreshold == 0) revert InvalidApprovedEntryThreshold();
        minimumContestTime = _minimumContestTime;
        approvedEntryThreshold = _approvedEntryThreshold;
    }

    /**
     *
     * Admin functions
     *
     */

    // Once an entry is approved, it cannot be rejected. Skips already approved entries. Entries can't be accepted
    // once a contest is closed but they can be accepted before the contest admin has set a winner.
    function acceptEntries(uint256[] memory entryIds) external override onlyOwner noWinner nonReentrant {
        for (uint32 i = 0; i < entryIds.length; i++) {
            if (entries[entryIds[i]].isApproved) continue;
            if (entries[entryIds[i]].entrant == address(0)) revert EntryNotExists();
            entries[entryIds[i]].isApproved = true;
            approvedEntries++;
            emit AcceptedEntry(entryIds[i], entries[entryIds[i]].entrant);
        }
    }

    function setWinningEntry(uint256 entryId) external override onlyOwner noWinner nonReentrant {
        if (!isClosed()) revert NotClosed();
        if (entries[entryId].entrant == address(0)) revert EntryNotExists();
        if (winner.winner != address(0)) revert HasWinner();
        winner = Winner(entryId, entries[entryId].entrant);

        // Send staked token to beneficiary
        IContestStaker(address(_getContestFactory())).transferFrozenStake(
            entries[entryId].stakedTokenId, entries[entryId].entrant, _getBeneficiary(), 1
        );
        emit SetWinningEntry(entryId, entries[entryId].entrant, entries[entryId].stakedTokenId);
    }

    /**
     *
     * User functions
     *
     */

    // User can choose which Treasure ID `stakedTokenId` to use as their stake provided it os registered in the
    // ContestStaker. The caller must have staked in the contestStaker contract and this function will freeze
    // their balance from being withdrawn in that contract, until the user has either cancelled their
    // unapproved entry or reclaimed their losing entry.
    function submitEntry(uint256 stakedTokenId, uint256 entryId, string memory entryURI) external nonReentrant {
        if (isClosed()) revert Closed();
        if (entries[entryId].entrant != address(0)) revert EntryExists({entrant: entries[entryId].entrant});
        if (!IContestStaker(address(_getContestFactory())).canUseStake(stakedTokenId, msg.sender)) revert NoStake();
        entries[entryId] = Entry(false, entryURI, msg.sender, stakedTokenId);
        IContestStaker(address(_getContestFactory())).freezeStake(stakedTokenId, msg.sender, 1);
        emit SubmittedEntry(stakedTokenId, entryId, msg.sender, entryURI);
    }

    // Can be called as long as an entry is not approved. Unfreezes their stake in contestStaker so user can
    // withdraw. Caller must be entrant.
    function cancelEntry(uint256 entryId) public nonReentrant {
        if (entries[entryId].entrant != msg.sender) revert NotEntrant();
        if (entries[entryId].isApproved) revert EntryApproved();
        IContestStaker(address(_getContestFactory())).unfreezeStake(entries[entryId].stakedTokenId, msg.sender, 1);
        emit CancelledEntry(entryId, msg.sender, entries[entryId].stakedTokenId);
        delete entries[entryId];
    }

    // If entry was approved but not a winner, entrant can use this function to reclaim their stake. If an entry
    // was not approved before a winner was selected, they can use this function or cancelEntry to reclaim their stake.
    function reclaimEntry(uint256 entryId) external nonReentrant {
        if (!hasWinner()) revert NoWinner();
        if (entryId == winner.winningId) revert CannotReclaimWinner();
        if (entries[entryId].entrant != msg.sender) revert NotEntrant();
        IContestStaker(address(_getContestFactory())).unfreezeStake(entries[entryId].stakedTokenId, msg.sender, 1);
        emit ReclaimedLosingEntry(entryId, msg.sender, entries[entryId].stakedTokenId);

        // Don't delete entry as it might be able to be minted again as a losing entry.
    }

    function hasWinner() public view override returns (bool) {
        return winner.winner != address(0);
    }

    function getWinner() public view override returns (address) {
        return winner.winner;
    }

    function getWinningId() public view override returns (uint256) {
        return winner.winningId;
    }

    function getEntrant(uint256 entryId) public view override returns (address) {
        return entries[entryId].entrant;
    }

    // No more entries can be submitted after this threshold is reached. Since approvedEntryThreshold and
    // contest time elapsed are only increasing, once this is true it can reset to false (i.e. this should return
    // false until its true and then always true).
    function isClosed() public view override returns (bool) {
        return approvedEntries >= approvedEntryThreshold && block.timestamp - contestStartTime >= minimumContestTime;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import { Contest } from "./Contest.sol";
import { ContestStaker } from "./ContestStaker.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { ConfigStore } from "./ConfigStore.sol";

// Deploys new Contests and transfers ownership of them to the deployer. Also registers the contract with a
// contest staker contract so that the contests can freeze and unfreeze user stakes. This contract deploys the
// contest staker upon construction so this contract owns the staker contract.

interface IContestFactory {
    function deployNewContest(
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold,
        ConfigStore _configStore
    )
        external
        returns (address);
}

contract ContestFactory is IContestFactory, ContestStaker, Ownable {
    constructor(
        IERC1155 stakedTreasure,
        uint256[] memory stakeableTokenIds
    )
        ContestStaker(stakedTreasure, stakeableTokenIds) // solhint-disable-next-line no-empty-blocks
    { }

    function addStakeableTokenId(uint256 tokenId) public onlyOwner nonReentrant {
        _addStakeableTokenId(tokenId);
    }

    // Anyone can call this function to deploy a new Contest that sets the caller as the owner of the new Contest.
    // This should be called by the Spire contract but there is no harm if anyone calls it.
    function deployNewContest(
        uint256 minimumContestTime,
        uint256 approvedEntryThreshold,
        ConfigStore _configStore
    )
        public
        override
        nonReentrant
        returns (address)
    {
        address contest = address(
            new Contest(
            minimumContestTime,
            approvedEntryThreshold,
            _configStore
            )
        );
        _registerContest(address(contest));
        Ownable(contest).transferOwnership(msg.sender);
        return address(contest);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";
import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";
import { EnumerableSet } from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

// Anyone can stake a designated ERC1155 token into this contract, and they can choose which token ID to stake
// provided the ID is whitelisted (see the private stakeableTokenIds set). This contract provides internal methods that
// another contract can use to append to the stakeable token ID set and register contests, which can freeze and
// unfreeze user's stakes. The idea is that the contests can freeze a user's stake if they submit an entry,
// and unfreeze it if they withdraw their entry. The contests can also transfer a user's frozen stake,
// which could be used to take a winner's stake for example. The advantage of this design is that a user's stake
// can be re-used for multiple contests and they only need to interface with this staking contract, instead of
// approving and staking per contest entered.

error UnregisteredContest();
error AddToSetFailed();
error RemoveFromSetFailed();
error InvalidTokenId();
error InvalidInputAmount();
error InsufficientStake(uint256 usableStake, uint256 requestedStake);
error InsufficientFrozenStake(uint256 frozenStake, uint256 requestedStake);

interface IContestStaker {
    function freezeStake(uint256 tokenId, address staker, uint256 amount) external;
    function unfreezeStake(uint256 tokenId, address staker, uint256 amount) external;
    function transferFrozenStake(uint256 tokenId, address staker, address recipient, uint256 amount) external;
    function canUseStake(uint256 tokenId, address staker) external view returns (bool);
}

contract ContestStaker is IContestStaker, ERC1155Holder, ReentrancyGuard, Multicall {
    using EnumerableSet for EnumerableSet.UintSet;

    // Whitelisted token IDs that can be staked. This set is append-only to eliminate situation where a user has
    // staked a token ID that is no longer whitelisted.
    EnumerableSet.UintSet private stakeableTokenIds;

    IERC1155 public stakedToken;

    // tokenId => staker => stake amount.
    mapping(uint256 => mapping(address => uint256)) public stakes;
    mapping(uint256 => mapping(address => uint256)) public frozenStakes;

    // Contests can put a hold on a user's stake.
    mapping(address => bool) public contests;

    modifier onlyContest() {
        if (!contests[msg.sender]) revert UnregisteredContest();
        _;
    }

    event Staked(uint256 indexed tokenId, uint256 amount, address indexed staker);
    event Unstaked(uint256 indexed tokenId, uint256 amount, address indexed staker);
    event AddedTokenId(uint256 indexed tokenId);
    event FreezeStake(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event UnfreezeStake(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event TransferFrozenStake(
        uint256 indexed tokenId, address indexed staker, address recipient, uint256 indexed amount
    );

    constructor(IERC1155 _stakedToken, uint256[] memory _stakeableTokenIds) {
        stakedToken = _stakedToken;
        for (uint256 i = 0; i < _stakeableTokenIds.length; i++) {
            stakeableTokenIds.add(_stakeableTokenIds[i]);
            emit AddedTokenId(_stakeableTokenIds[i]);
        }
    }

    /**
     *
     * Contest functions: Can only be called by whitelisted contest contract.
     *
     */

    // Invariant: stake amount should always be >= frozen stake amount.
    /**
     * @notice Freeze 1 stake of user
     */
    function freezeStake(uint256 tokenId, address staker, uint256 amount) public override onlyContest nonReentrant {
        if (!stakeableTokenIds.contains(tokenId)) revert InvalidTokenId();
        if (getUsableStake(tokenId, staker) < amount) revert InsufficientStake(getUsableStake(tokenId, staker), amount);
        frozenStakes[tokenId][staker] += 1;
        emit FreezeStake(tokenId, staker, amount);
    }

    function unfreezeStake(uint256 tokenId, address staker, uint256 amount) public override onlyContest nonReentrant {
        if (frozenStakes[tokenId][staker] < amount) {
            revert InsufficientFrozenStake(frozenStakes[tokenId][staker], amount);
        }
        frozenStakes[tokenId][staker] -= amount;
        emit UnfreezeStake(tokenId, staker, amount);
    }

    // Only stake frozen by contest can be transferred away to recipient. Decrements both stakes
    // and frozen stakes amount of user.
    function transferFrozenStake(
        uint256 tokenId,
        address staker,
        address recipient,
        uint256 amount
    )
        public
        override
        onlyContest
        nonReentrant
    {
        if (frozenStakes[tokenId][staker] < amount) {
            revert InsufficientFrozenStake(frozenStakes[tokenId][staker], amount);
        }
        stakes[tokenId][staker] -= amount;
        frozenStakes[tokenId][staker] -= amount;
        stakedToken.safeTransferFrom(address(this), recipient, tokenId, amount, "");
        emit TransferFrozenStake(tokenId, staker, recipient, amount);
    }

    /**
     *
     * Public functions.
     *
     */

    /**
     * @notice Increase stake amount. Cannot send any staked amount that was frozen by a contest.
     * @dev Caller must approve this contract to transfer the token ID.
     */
    function stake(uint256 tokenId, uint256 amount) public nonReentrant {
        if (!stakeableTokenIds.contains(tokenId)) revert InvalidTokenId();
        if (amount == 0) revert InvalidInputAmount();
        stakes[tokenId][msg.sender] += amount;
        stakedToken.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Staked(tokenId, amount, msg.sender);
    }

    /**
     * @notice Send stake back to user. Cannot send any staked amount that was frozen by a contest.
     */
    function unstake(uint256 tokenId, uint256 amount) public nonReentrant {
        if (getUsableStake(tokenId, msg.sender) < amount) {
            revert InsufficientStake(getUsableStake(tokenId, msg.sender), amount);
        }
        if (amount == 0) revert InvalidInputAmount();
        stakes[tokenId][msg.sender] -= amount;
        // If stake is now 0, delete the entries to give caller gas refund.
        if (stakes[tokenId][msg.sender] == 0) {
            delete stakes[tokenId][msg.sender];
            delete frozenStakes[tokenId][msg.sender];
        }
        stakedToken.safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        emit Unstaked(tokenId, amount, msg.sender);
    }

    /**
     *
     * View functions
     *
     */

    function getStakeableTokenIds() public view returns (uint256[] memory) {
        return stakeableTokenIds.values();
    }

    // This could theoretically run out of gas if token ID count is very high.
    // Returns stake amount for user for each token ID returned by `getStakeableTokenIds`. Returns in same order
    // as `getStakeableTokenIds` so caller should be sure to merge on indices.
    function getStakeAmountsForUser(address user) public view returns (uint256[] memory tokenIds) {
        uint256[] memory allTokenIds = getStakeableTokenIds();
        tokenIds = new uint256[](allTokenIds.length);
        for (uint256 i = 0; i < allTokenIds.length; i++) {
            tokenIds[i] = getUsableStake(allTokenIds[i], user);
        }
    }

    function getUsableStake(uint256 tokenId, address staker) public view returns (uint256) {
        return stakes[tokenId][staker] - frozenStakes[tokenId][staker];
    }

    function canUseStake(uint256 tokenId, address staker) public view override returns (bool) {
        return getUsableStake(tokenId, staker) > 0;
    }
    /**
     *
     * Internal functions
     *
     */

    // Register a contest that can freeze and unfreeze stakes.
    function _registerContest(address contest) internal {
        contests[contest] = true;
    }

    // Add a token ID that can be staked.
    function _addStakeableTokenId(uint256 tokenId) internal {
        bool success = stakeableTokenIds.add(tokenId);
        if (!success) revert AddToSetFailed();
        emit AddedTokenId(tokenId);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./ConfigStore.sol";
import { ConfigStoreInterfaces } from "./Constants.sol";
import { IContestFactory } from "./ContestFactory.sol";
import { ToggleGovernanceFactory } from "./ToggleGovernanceFactory.sol";

contract HasConfigStore {
    ConfigStore public configStore;

    constructor(ConfigStore _configStore) {
        configStore = _configStore;
    }

    function _getContestFactory() internal view returns (IContestFactory) {
        return IContestFactory(configStore.getImplementationAddress(ConfigStoreInterfaces.CONTEST_FACTORY));
    }

    function _getBeneficiary() internal view returns (address) {
        return configStore.getImplementationAddress(ConfigStoreInterfaces.BENEFICIARY);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IContest {
    function acceptEntries(uint256[] memory entryIds) external;
    function setWinningEntry(uint256 entryId) external;
    function isClosed() external view returns (bool);
    function hasWinner() external view returns (bool);
    function getWinner() external view returns (address);
    function getWinningId() external view returns (uint256);
    function getEntrant(uint256 entryId) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";

interface IERC1155Supply is IERC1155 {
    function totalSupply(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ERC1155Holder } from "openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import { IERC1155 } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import { IERC1155Supply } from "./IERC1155Supply.sol";
import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { Multicall } from "openzeppelin-contracts/contracts/utils/Multicall.sol";

interface IToggleGovernance {
    function hasEnoughStake(uint256 requiredStake) external view returns (bool);
}

error InsufficientStakeAmount();

contract ToggleGovernance is ERC1155Holder, IToggleGovernance, ReentrancyGuard, Multicall {
    IERC1155Supply public governanceToken;
    uint256 public governanceTokenId;

    mapping(address => uint256) public stakers;
    uint256 public stakedAmount;

    event Stake(address indexed staker, uint256 amount);
    event Unstake(address indexed staker, uint256 amount);

    constructor(IERC1155Supply _governanceToken, uint256 _governanceTokenId) {
        governanceToken = _governanceToken;
        governanceTokenId = _governanceTokenId;
    }

    function stake(uint256 amount) public nonReentrant {
        stakers[msg.sender] += amount;
        stakedAmount += amount;
        governanceToken.safeTransferFrom(msg.sender, address(this), governanceTokenId, amount, "");
        emit Stake(msg.sender, amount);
    }

    function unstake(uint256 amount) public nonReentrant {
        if (stakers[msg.sender] < amount) revert InsufficientStakeAmount();
        stakers[msg.sender] -= amount;
        stakedAmount -= amount;
        governanceToken.safeTransferFrom(address(this), msg.sender, governanceTokenId, amount, "");
        emit Unstake(msg.sender, amount);
    }

    function hasEnoughStake(uint256 requiredStake) public view override returns (bool) {
        // Threshold for staked amount is minimum of total supply and required stake.
        uint256 threshold = requiredStake > governanceToken.totalSupply(governanceTokenId)
            ? governanceToken.totalSupply(governanceTokenId)
            : requiredStake;
        return stakedAmount >= threshold;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { ReentrancyGuard } from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import { ToggleGovernance } from "./ToggleGovernance.sol";
import { IERC1155Supply } from "./IERC1155Supply.sol";

library ToggleGovernanceFactory {
    function deployNewToggleGovernor(
        IERC1155Supply governanceToken,
        uint256 governanceTokenId
    )
        internal
        returns (address)
    {
        return address(new ToggleGovernance(governanceToken, governanceTokenId));
    }
}