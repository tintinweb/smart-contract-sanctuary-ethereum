/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File operator-filter-registry/src/[email protected]


pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}


// File operator-filter-registry/src/[email protected]


pragma solidity ^0.8.13;

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}


// File operator-filter-registry/src/[email protected]


pragma solidity ^0.8.13;

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File @openzeppelin/contracts/interfaces/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}


// File @openzeppelin/contracts/token/common/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}


// File contracts/kzfmfinal.sol


pragma solidity ^0.8.0;





contract ZoomanFreemint is ERC721Royalty, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721('Zoo-manFreemint', 'ZMN') {
        _setDefaultRoyalty(owner(), 1000);
        freeMintAmountMapping[0x002841301d1AB971D8acB3509Aa2891e3ef9D7E1] = 3;
        freeMintAmountMapping[0xFE4bE01Da4fBfD47650EB2c7bd37d09607d1337F] = 1;
        freeMintAmountMapping[0xfE2cd171379139bc0D895dA75464AEF8460B3400] = 1;
        freeMintAmountMapping[0xFdAb2E988Cf8242AfbDf208f9368868d050CC253] = 1;
        freeMintAmountMapping[0xFD52c7f77C60dD0aDB11C2E631A9C9a7efEBF8dc] = 1;
        freeMintAmountMapping[0xfc5F6FfA7007900654fA9E974Be837b26abf0cA2] = 1;
        freeMintAmountMapping[0xfB29409dD2c76157a6F8f7F06Fd51630AdAa1be9] = 1;
        freeMintAmountMapping[0xF6e512563eE2c8Fc3aE713dc41CA9175FeFE2503] = 1;
        freeMintAmountMapping[0xF661c19c314292E24564F8EAec220Da9607873Ba] = 1;
        freeMintAmountMapping[0xf58808BCA3c49BAe910C693155f3427cE539DF2a] = 1;
        freeMintAmountMapping[0xF522cE5819CA0a9B922C1262E7b8542d14F0001a] = 1;
        freeMintAmountMapping[0xf514A75f48364fff1276cdcF23171A8F0fb5998d] = 1;
        freeMintAmountMapping[0xf4E54339403CF8201B55AA97b3B3baD8221B239C] = 1;
        freeMintAmountMapping[0xF4548503Dd51De15e8D0E6fB559f6062d38667e7] = 1;
        freeMintAmountMapping[0xf406aed3369614123eB6c8ea6afB12995D49dBdB] = 1;
        freeMintAmountMapping[0xF33621a6612D789f31cb39130e8e1239213ef2aa] = 1;
        freeMintAmountMapping[0xf2F3f58E80340918F85a11E090311e1a96c10156] = 1;
        freeMintAmountMapping[0xf2F39F813ebA0B580887199632c91308fb54cF9b] = 1;
        freeMintAmountMapping[0xF1C78c04EB0f2dB43cF499CDe23bE74230D43b1A] = 1;
        freeMintAmountMapping[0xf15b2D971B9b320d931B5264Df47af3B4DB82981] = 1;
        freeMintAmountMapping[0xf08a26090d1CDf2958299A6479dB4d9F34616110] = 1;
        freeMintAmountMapping[0xF05b026855C8FbC0a2682cbb1b610BafCF54a047] = 1;
        freeMintAmountMapping[0xef7Ce9855AEfBCd56dF4E54BC63fA09a1cFc5F8f] = 1;
        freeMintAmountMapping[0xeF1DAd2b5345A25DDF0eC504532ad21aB9EFd24a] = 1;
        freeMintAmountMapping[0xee38E54DE56a9d3878267fB26697AdB990947330] = 1;
        freeMintAmountMapping[0xEdAf3aF3220d9bf6083FBf03f52e9b1807f9ca56] = 1;
        freeMintAmountMapping[0xed937a015c832b3C067e28c68fD980100175e6E9] = 1;
        freeMintAmountMapping[0xECEbbbe3E40175C2b5a441149F855f0e215acbcd] = 1;
        freeMintAmountMapping[0xec79f29C30Bae7F31cF0462e0658F9f0C368f454] = 1;
        freeMintAmountMapping[0xEc2ef0657495611906bcb32dd98f6b41f50186E5] = 1;
        freeMintAmountMapping[0xeC20527c933DE96c37822384828Ed6bE1D8Cd807] = 1;
        freeMintAmountMapping[0xEAbB8945bf334c05144A13DF75eB76d047a7eebD] = 1;
        freeMintAmountMapping[0xE8f2754fbF84DB99d1b94fe3507809469e01d6A3] = 1;
        freeMintAmountMapping[0xE87cD0136d604B34410F8CB3E2DC7dFc04cB9Bc6] = 1;
        freeMintAmountMapping[0xE69e744949Dc0A6Af1a3381b41333C9b91302eC4] = 1;
        freeMintAmountMapping[0xE5D8F6D0Bc8E5bd9751F611AeaA6BABcd08C7d83] = 1;
        freeMintAmountMapping[0xE51Dc2090F49e01857Bb08A7B6ADA93A0BD43a1a] = 1;
        freeMintAmountMapping[0xE49f7b329621e4e8dda916e02C0D9e0651b58775] = 1;
        freeMintAmountMapping[0xe49d5BE6C9f8Ff32bBa6Fa0ec26C8b9BbB23b0A8] = 1;
        freeMintAmountMapping[0xE440964985D8005A5f44Ed830Fb3acfceF15dd04] = 1;
        freeMintAmountMapping[0xe34a3dDA68988076F1Ac02B7B62e9a264525615E] = 1;
        freeMintAmountMapping[0xE2Ad9b510407Cdc4E383C020C2962EcB0a4f5Bea] = 1;
        freeMintAmountMapping[0xE27A311ab12dF25e2885e7BF51Cd494a6488b380] = 1;
        freeMintAmountMapping[0xE0BC83041bda542408edAd51263F5d41955D1f17] = 1;
        freeMintAmountMapping[0xdf6e1e8945bcB7f1B17f4D83e36Ab79a5d724607] = 1;
        freeMintAmountMapping[0xDF1424D814C223769def829278a54f9562Ae10aB] = 1;
        freeMintAmountMapping[0xddF21318ca81F9dcB3f143b40B95C72328c46892] = 1;
        freeMintAmountMapping[0xdd2Cb738E8f987579776c6d25b4F769Bf6529792] = 1;
        freeMintAmountMapping[0xDD12A0c04BE3fF962E7321f11Bc08DbE227c25aC] = 1;
        freeMintAmountMapping[0xdAcdB79016cB5e155Ea960e7615b3A7796420E61] = 1;
        freeMintAmountMapping[0xda69fb774131cdCE04E8f8EcE3c67b20815Bd71e] = 1;
        freeMintAmountMapping[0xda5bcb02b4EF1850F9781153CAF1b7e7C268aE3b] = 1;
        freeMintAmountMapping[0xdA32D3EE3b60EbE8f9D296A34bc628149A5D320c] = 1;
        freeMintAmountMapping[0xD75c07B56CB3E1E47Adc22944b5E78efBc242b8f] = 1;
        freeMintAmountMapping[0xd63520F915bB5E13cC07CD053de320dFa661227d] = 1;
        freeMintAmountMapping[0xd4B1623E464e8Bc0260A88E09d933f895cbf33BE] = 1;
        freeMintAmountMapping[0xD46486757b7d7a3f45E7364a5defE30247e93a9a] = 1;
        freeMintAmountMapping[0xd4076fff8B52e3590486Dc772f9AB10fe8dD8A29] = 1;
        freeMintAmountMapping[0xd1d2262D1fEA768fe0dc3c26C5b0D91748727000] = 1;
        freeMintAmountMapping[0xd073974fF18df18b56F70E69dFA0893B8c385764] = 1;
        freeMintAmountMapping[0xd06AA2838Fdd54d12Fe366DBad6bb7EC86d17C5E] = 1;
        freeMintAmountMapping[0xCFcb18A76DAF95633ca762C5E46DdB5E04ADE31F] = 1;
        freeMintAmountMapping[0xCf3223ca96C4a3cbb50E40eE376b0a5d86E829E2] = 1;
        freeMintAmountMapping[0xCe0233903111Adc2D90bde8AEEdDf6C77F731A20] = 1;
        freeMintAmountMapping[0xCd10c01d455a5b50737d2b734196766FD0b4b7eE] = 1;
        freeMintAmountMapping[0xCAc61AAD8b8AAae87D1BA2f680871A95Ddd0f8b1] = 1;
        freeMintAmountMapping[0xc9F2fE88250098838e8A36210E9311015Ef62b48] = 1;
        freeMintAmountMapping[0xc8331Db1414bdF20a88f0192351d3eCFaD11aAC1] = 1;
        freeMintAmountMapping[0xc67C21D1fdfF7AFB241C8C829E40cd289f8eb001] = 1;
        freeMintAmountMapping[0xc5eda85d9c9F62f34D807D9A1adA3A1c59f3AD2b] = 1;
        freeMintAmountMapping[0xc34b1b511A14BFf1D54e557c0e37F7937509Ea97] = 1;
        freeMintAmountMapping[0xc2E7D8C328F156D99C4cde1ac6D6B03D2d41a9cA] = 1;
        freeMintAmountMapping[0xC1B4Bb6260e68E339CF54cC2733aeecC0F8295aF] = 1;
        freeMintAmountMapping[0xc0658AF26F21c5b8b31951B38c69cc465116Ad5C] = 1;
        freeMintAmountMapping[0xBEbf53131E47dB582f6453a7CfA8827D59F7A6af] = 1;
        freeMintAmountMapping[0xbDC674b2C585dA3C80E50e48f6b73690dFcAFeBD] = 1;
        freeMintAmountMapping[0xbd0DE205C5AB42257e63a5f9cc7fa3b0e2f9A3CA] = 1;
        freeMintAmountMapping[0xBBc8Bd583430Abb3aF7b24A29bfeeC44D2D9e97C] = 1;
        freeMintAmountMapping[0xBACb4dB3dCC49c9493163eF9EB3E7Fb0254a0D00] = 1;
        freeMintAmountMapping[0xB9b503c8C6AAf2Ff16E16F069053DA2155A03c61] = 1;
        freeMintAmountMapping[0xb92AA8895BDDf37B1F3BC315aCA6B74f17E973cd] = 1;
        freeMintAmountMapping[0xB9165f97E0A28485c4d54d29206b25627B44be53] = 1;
        freeMintAmountMapping[0xb6f9ECEa3Beb098981110C55223135C94F92c679] = 1;
        freeMintAmountMapping[0xB658ee7c91c927D5CBb5251eAd780d7b9C6C455b] = 1;
        freeMintAmountMapping[0xB4D9a40712fed064e90dc3552d0CEAcA6c888551] = 1;
        freeMintAmountMapping[0xB4ac8a8e9c61Ac35D00469842C65Dc0cd9bca130] = 1;
        freeMintAmountMapping[0xB31853FA4dF39dffe598f835D0B26174430e285B] = 1;
        freeMintAmountMapping[0xB237d44B7C9F5C0b175Cb7d205b97a19E958C514] = 1;
        freeMintAmountMapping[0xB0dcACCC43cfeE786acAD6E250cC8Cff6045B194] = 1;
        freeMintAmountMapping[0xafc3B89f14893f5BfA33B858B6C318394EfA2ade] = 1;
        freeMintAmountMapping[0xAea31abFAdfb9c8B885c54e751C0d99CB0662137] = 1;
        freeMintAmountMapping[0xAe85D36BC312288B3444E81f6502CD238c137E32] = 1;
        freeMintAmountMapping[0xaD29F6dD5a03105813Ad0d879383f818c6B5FB99] = 1;
        freeMintAmountMapping[0xace93d27680d27d8C2181ECC6AFBda93Cd678aC3] = 1;
        freeMintAmountMapping[0xAc9F69978AE542b4bcE62314fAcb4a790d2102f1] = 1;
        freeMintAmountMapping[0xab4753de403D0861590680c6FFc8329572D54D31] = 1;
        freeMintAmountMapping[0xaA2F9Ddc1d5981eB715168Ae09121F08228C483e] = 1;
        freeMintAmountMapping[0xAA196af22025958430D5ef504a27b4e7b05bBD68] = 1;
        freeMintAmountMapping[0xa98c8FC9e02069F8Cc305238eB001CcF647E8105] = 1;
        freeMintAmountMapping[0xA73757C41995E93A0af5AAe7828AE3369752d09E] = 1;
        freeMintAmountMapping[0xa70c08AA66365CeFD9B4C8af0c4e8A366E595d6C] = 1;
        freeMintAmountMapping[0xA546Ee534805f9968e5a84A9Cb48860779E45E13] = 1;
        freeMintAmountMapping[0xA4c3C659dCbf3021D32e378e164B0D1c339843De] = 1;
        freeMintAmountMapping[0xa49dfD905EfB545019EACbE25a4024A7C70866C8] = 1;
        freeMintAmountMapping[0xa45E81919BF7563F39b99Cf0603A28175276B60a] = 1;
        freeMintAmountMapping[0xA1AC9882c1f2fa810EEBad1ADeE4B71eE2454A19] = 1;
        freeMintAmountMapping[0xa0751827DA7a5cE235D85694164382Ee8920648D] = 1;
        freeMintAmountMapping[0x9F61B0aC23747AF2734Bcf3A8EEF0BbB82932cEa] = 1;
        freeMintAmountMapping[0x9Ee987F7D547C036901AD3DAD30671Cf54cCCc92] = 1;
        freeMintAmountMapping[0x9cAfE57302Db8334DE78FdB0244eA536911908c5] = 1;
        freeMintAmountMapping[0x9B2e6dfcB85237EEAAc4a95968B616485EE53D8E] = 1;
        freeMintAmountMapping[0x9aa7cF645442097F134902B0cBb595CaDff24960] = 1;
        freeMintAmountMapping[0x99F277d2a41113Fccd60d3Bd874FdDd67f0204Be] = 1;
        freeMintAmountMapping[0x97F5E4dcEf753df248479d5150Df177355453d00] = 1;
        freeMintAmountMapping[0x97c544BB08BD793eB56cc9452D15e77F067a66bb] = 1;
        freeMintAmountMapping[0x95d78bA3b80D76740732bA4b02Bb3887C880A562] = 1;
        freeMintAmountMapping[0x95576B44757263150E1224dA24d6A6a0EDC81CD6] = 1;
        freeMintAmountMapping[0x94B4D1a7cF4D46e5F52C7f5B6E7e63926fBE6d73] = 1;
        freeMintAmountMapping[0x945475aF27f187506A896ccdD2CbAe103d6490AA] = 1;
        freeMintAmountMapping[0x939BF69c9D3376290922E45466D96e5200D33B63] = 1;
        freeMintAmountMapping[0x934b19E396566d3aa45ebeb611325f899951adA5] = 1;
        freeMintAmountMapping[0x91aDb5B476418D7f70a112bE8a5166020769919A] = 1;
        freeMintAmountMapping[0x8D8e99BFD8D31A9812329824635e3eA7800b6406] = 1;
        freeMintAmountMapping[0x8d82fC0E884E4509D01884263Da76f10bdF75F9c] = 1;
        freeMintAmountMapping[0x8CACb17F18dDf34Ea35BE228f30A2c41E8A11d75] = 1;
        freeMintAmountMapping[0x8c1584666c98257A5872E6205b6dE631B3301829] = 1;
        freeMintAmountMapping[0x8b9A364581eDd2520d355002D7049568AC64b71C] = 1;
        freeMintAmountMapping[0x8A04De446D1bBFA3F8f6C41442AA62C719157ef8] = 1;
        freeMintAmountMapping[0x89ea3681FA7A838084b28C1bEe1e0de1c2ce1C11] = 1;
        freeMintAmountMapping[0x8871d265a0C8dF287Cf9A76Dd8F6ba513DFdA3B9] = 1;
        freeMintAmountMapping[0x87F06a9bE97AE026220B24389095AFC2277AF93e] = 1;
        freeMintAmountMapping[0x870BA521b5830Ce144DD0e824DA837269491C8FA] = 1;
        freeMintAmountMapping[0x86573536Ab37E0dea5b2D37247aD68fb3C668803] = 1;
        freeMintAmountMapping[0x8427b5AE23291F2c5D1D85ABf6AFAe48426F357c] = 1;
        freeMintAmountMapping[0x829B2dE9c1b1E18a94f3c71aA9fb3832D4C61Df5] = 1;
        freeMintAmountMapping[0x81f5B2538a5762467f256B0E5A07c0AC812Fde67] = 1;
        freeMintAmountMapping[0x819fCccdeeAC99405348Df192601dd07EF1d77e9] = 1;
        freeMintAmountMapping[0x7Ec1B412Ce73254b2a965F1251837f52e30B9217] = 1;
        freeMintAmountMapping[0x7e5D1ec3cd82F73Bca98727194c70b67D27F42f1] = 1;
        freeMintAmountMapping[0x7E01CCb7a89dc5417C3F87cc738ae4db2c219173] = 1;
        freeMintAmountMapping[0x7DFd472eE9fE7cA9AFc81C1BBB155F0bD635B968] = 1;
        freeMintAmountMapping[0x7Be0614BF06Cb9B6f72518CCbE550053c36127c7] = 1;
        freeMintAmountMapping[0x7BA721159C92ee766fcD578E06D488f1916DF17d] = 1;
        freeMintAmountMapping[0x7aD304E9596881f175B76b856FC2ef761927C61a] = 1;
        freeMintAmountMapping[0x7A2234DB7EE77589Da07d593F1563Ad83F0A1253] = 1;
        freeMintAmountMapping[0x79F910f11a2B3DAb380b0B6C1E75EdfABce8423c] = 1;
        freeMintAmountMapping[0x79e7Cf2c7f085a39a0F0d40E30dE9b759862B9F7] = 1;
        freeMintAmountMapping[0x797C81efE7a4EE6B517Eae06CaB4eB866b5d33F8] = 1;
        freeMintAmountMapping[0x7962F5959633405FcA783928E41fE933DCEb9AaD] = 1;
        freeMintAmountMapping[0x790D7FF1555b9b951aeF8c59728AeFe2A326DEa0] = 1;
        freeMintAmountMapping[0x77C219F85B6d20Ba6139003C5D13Ff985924504f] = 1;
        freeMintAmountMapping[0x761e4dE49B3Cbb53972f8372c4CEc44E4d8b36ec] = 1;
        freeMintAmountMapping[0x7413A533d57223C222BA0aA37A09A2E733878013] = 1;
        freeMintAmountMapping[0x73F55d0FaE1A4A95769E4b9F0Cc18B6106a32D89] = 1;
        freeMintAmountMapping[0x7371262598d7936fB0B5b6D46f12611821F36895] = 1;
        freeMintAmountMapping[0x72E22DEAbeaEaBDd559EA7B741EF2BD77D08439e] = 1;
        freeMintAmountMapping[0x72A4D7A1E496104185C558d13230A2c075ecbDCf] = 1;
        freeMintAmountMapping[0x729dA52EE3a8f9a2053fdFE877E5c281ce8785Df] = 1;
        freeMintAmountMapping[0x721e02FBe66c1eDE165ac3ABb335419FC3F374Ef] = 1;
        freeMintAmountMapping[0x71c0dD41A4B35596399D647df6420C6e847D23b4] = 1;
        freeMintAmountMapping[0x71a5a3aa039fB63DBa8ce2E3C3a3e2DaB81a5939] = 1;
        freeMintAmountMapping[0x70A5751cE33dE4436B1e5935772aFA007382a78b] = 1;
        freeMintAmountMapping[0x6ebe842F91D4f0a2d28Cf273BCEc8E34247B2595] = 1;
        freeMintAmountMapping[0x6e448Ac7C20e3011BB15a9F83cce71aC00303805] = 1;
        freeMintAmountMapping[0x6E1324676F515bcAb14c26C5F1d70ca6172Ca455] = 1;
        freeMintAmountMapping[0x6aB8eA1b7852589CcCDc80Ac5f6c21afAD74ce38] = 1;
        freeMintAmountMapping[0x6a780C771281322c8E0bbAb55b935C1bb70F66ec] = 1;
        freeMintAmountMapping[0x6909FE2c20FEa0e84077E2C26709A42FD482fAB2] = 1;
        freeMintAmountMapping[0x68174da16A168122bddDD93456F97B089068d46d] = 1;
        freeMintAmountMapping[0x67a1Ee75aA95C5C1E7341Ac81e0cA30D3EAafbc5] = 1;
        freeMintAmountMapping[0x67155a71Ec459C595F3A6Eb13520a78f8bB90B7C] = 1;
        freeMintAmountMapping[0x6609eC70BF04f20DDd720470B2fEDA600427fC3A] = 1;
        freeMintAmountMapping[0x6571C1643F76945926Fa93ca07aB6104DF2b6DD2] = 1;
        freeMintAmountMapping[0x64ff8A32bd2b2746ed2A42Ce46eb1Bd74C59f70C] = 1;
        freeMintAmountMapping[0x647a36F2f04f5b54Cb4c8022b9026f7fbDAd7F1b] = 1;
        freeMintAmountMapping[0x63a71B19b70F05cf6b5a79Da0d717eF46de97552] = 1;
        freeMintAmountMapping[0x6321F49B3a9182Be7cB57De40bbf8117E37668d2] = 1;
        freeMintAmountMapping[0x61EC94F740707F8cE243b80F765A2b95196f1c5A] = 1;
        freeMintAmountMapping[0x60b2972658a600e2d0a39DB4aF1f9Fb11097b8a5] = 1;
        freeMintAmountMapping[0x607e6697233D045EE6A586B303630298Dd80515d] = 1;
        freeMintAmountMapping[0x603Bddc4d7FE9681dcfbbDBD99c0B152d684bA45] = 1;
        freeMintAmountMapping[0x5e85c03Ad8B2C86018D0eDDfaEBdd55EfdCFfB0D] = 1;
        freeMintAmountMapping[0x5cD935Bd72eBfBf4B0141568Bc89cC896d9f0b1D] = 1;
        freeMintAmountMapping[0x5bf6dBEe2798ca0674e5703DFc2fC32855245e55] = 1;
        freeMintAmountMapping[0x5aE2d4dab5881fbF2a5dCD3ccDCf5190Cf69293b] = 1;
        freeMintAmountMapping[0x5acd55138528f9e8BF4a2855ecF2777E6a1909F9] = 1;
        freeMintAmountMapping[0x5a8D322920B5e3D9670B3ED80a0d9e4e37C0470C] = 1;
        freeMintAmountMapping[0x59a1C0Ab93b5C0853ECa16ff594568dB4D481182] = 1;
        freeMintAmountMapping[0x5770B226AD3497EB7F02637f65615CDD620D5e79] = 1;
        freeMintAmountMapping[0x55F555CcF956802A42596c708C08cB8bD99214fA] = 1;
        freeMintAmountMapping[0x555b9d685Af3f8003F3D3df3D4b8338e78aA8184] = 1;
        freeMintAmountMapping[0x55215b8E731276EAfCfC9a8bf7d325cdf9E1c0d7] = 1;
        freeMintAmountMapping[0x537A4046755e610D9b97CA4203A4f836974e0d11] = 1;
        freeMintAmountMapping[0x5357E4671EAa4a7367921EfC8EB60D56d3650ad5] = 1;
        freeMintAmountMapping[0x5253043DF7a50970398dd1037eeCf6B384FD4672] = 1;
        freeMintAmountMapping[0x522FA1709cBdE1cd54652639B93403b7367B4A3e] = 1;
        freeMintAmountMapping[0x52008d2a42a15915509D4c7fE6694B0Ed11beB5B] = 1;
        freeMintAmountMapping[0x5154c1F3959b7c5B2F1956947BC77Eee0C1039e0] = 1;
        freeMintAmountMapping[0x50F0f41E527Bc7DDb9d4192937281773b1a47c99] = 1;
        freeMintAmountMapping[0x50eC189497A2A93ae670e8193DE41b389c45b300] = 1;
        freeMintAmountMapping[0x50252dDeC36De574734FE0CB4A475c7e6F1C2eb2] = 1;
        freeMintAmountMapping[0x50063D335B85898AE7Aa0b28B86Db96507A5c25F] = 1;
        freeMintAmountMapping[0x4FDB49033C916b9b09BCd0850F2240d610afF726] = 1;
        freeMintAmountMapping[0x4E3b3680BbaF5b6eE805E4606a772C5A112723c3] = 1;
        freeMintAmountMapping[0x4D3B23Cf47440C709d9B37Ae37366d3BC8B5889f] = 1;
        freeMintAmountMapping[0x4D3122eA24d779CF7741f1d6A5829905B235c48c] = 1;
        freeMintAmountMapping[0x4CaE8F1F7A5CFcc82b5123872ef3B9fAc395c210] = 1;
        freeMintAmountMapping[0x4C8e07E0DF30120dFa2bd20BB84D68108928569F] = 1;
        freeMintAmountMapping[0x4c87e557C2878257d689849820dc4c2edb229f27] = 1;
        freeMintAmountMapping[0x4a02e5FD33E84aa36549890A2eBd21d275080966] = 1;
        freeMintAmountMapping[0x493Da0cDe8cbe456d096D296B88550a703939354] = 1;
        freeMintAmountMapping[0x48eF11011DeD807F3246bB8c2F4CE9426e09Be88] = 1;
        freeMintAmountMapping[0x47d317653695aa0c57557519AFf9f7A186141510] = 1;
        freeMintAmountMapping[0x47a991819ab1e4Fb3A884b54F12bAeb346f9dc69] = 1;
        freeMintAmountMapping[0x47659CAf77A8822F477887657Dfb34EC2F448852] = 1;
        freeMintAmountMapping[0x474f057fFd4184cE80236d39C88E8ECFe8589931] = 1;
        freeMintAmountMapping[0x465951a661084386bc46306C2eb3A2Fe921F0c7d] = 1;
        freeMintAmountMapping[0x46570358D6202Cb2c74c02e5722a65863787DDf0] = 1;
        freeMintAmountMapping[0x461B854BA646F97aE209FFDe8ce383b49e4522E8] = 1;
        freeMintAmountMapping[0x45B526788E9AC6DE32fC9364484241677aa03B58] = 1;
        freeMintAmountMapping[0x44A756D6E0B9B01B79e2709b53d1f5D6f54830d2] = 1;
        freeMintAmountMapping[0x434f7C4a1470a03494dFf3530037082d086738a5] = 1;
        freeMintAmountMapping[0x4269417EeFa4e8F515b67C63974474993062cE85] = 1;
        freeMintAmountMapping[0x423A65Cd9F3AbC065d1fCfCD64780903E2842d10] = 1;
        freeMintAmountMapping[0x40cB3AB5930FF6cE0375c37E17941C65eE6323fC] = 1;
        freeMintAmountMapping[0x40c54783FeADE03d09C49ba76598efB1B43F9C44] = 1;
        freeMintAmountMapping[0x403Ca284c16795263c704F3411360A5A11cE91DC] = 1;
        freeMintAmountMapping[0x3E1dc89ab1E3BB8A64bB0f65b65b404f1BF708c3] = 1;
        freeMintAmountMapping[0x3D0fC6E351FaEeD03aa179308fF4a7960b808bC5] = 1;
        freeMintAmountMapping[0x343126bbDE06A8BCBBD71eB966705f5a8a12EB8d] = 1;
        freeMintAmountMapping[0x33fe4A6B3E79615067E75bDa042F8820D7666d82] = 1;
        freeMintAmountMapping[0x3340DE8618888ba23DD1CE5AF43C020cF2605023] = 1;
        freeMintAmountMapping[0x330E705D7c1340BE603bCde12CED193868De7739] = 1;
        freeMintAmountMapping[0x2fd87ACfee01B5311fDD33a10866fFd14c4aE36B] = 1;
        freeMintAmountMapping[0x2F9087D8A9701DD7adEE061823BAb529877a1043] = 1;
        freeMintAmountMapping[0x2d5a1190b6c1bf13b256210A65F625681b488110] = 1;
        freeMintAmountMapping[0x2D1AEa14Ca5A10d1D7532e909F94DD0d5E16295f] = 1;
        freeMintAmountMapping[0x2bdDC6B3eb3aBed4A6C362763e5CF8E9f9037DbA] = 1;
        freeMintAmountMapping[0x2B8b0C7E42Cd82C92d4Be78e2dD1F1Af4ddE7Cce] = 1;
        freeMintAmountMapping[0x2aC651150309ad369d5b7278bBe11FF7e76B5EAd] = 1;
        freeMintAmountMapping[0x2a8482a8e89C1D4aCdDA32FD232EA425eeb87e60] = 1;
        freeMintAmountMapping[0x29C07AA7105d2869a17dD3821bCf1E3Ad6a3f682] = 1;
        freeMintAmountMapping[0x27e7610DC12a2aB5E219043FB41AbC313Cb11b5F] = 1;
        freeMintAmountMapping[0x27a2AdC97246eC7580388bF20d19f889d56388e9] = 1;
        freeMintAmountMapping[0x25dE611cea5cA7Ba0668f2D8Eb3068ba72F0C30d] = 1;
        freeMintAmountMapping[0x25885B2f3d6521022523213e208920A9F3C17Db1] = 1;
        freeMintAmountMapping[0x243119dbef6Acffe4420C2b49F7a3EC2f8f870F5] = 1;
        freeMintAmountMapping[0x24169E61432CeaC043CbeA388BD5b51AAf8B2B1c] = 1;
        freeMintAmountMapping[0x222c52726f0D1d4D452F69C87f38429a09229f1f] = 1;
        freeMintAmountMapping[0x21116c1eE3D766be50377c190056b2419946Fc3e] = 1;
        freeMintAmountMapping[0x2099296f14173b27bbe49F9232d3eF95dfD1a259] = 1;
        freeMintAmountMapping[0x20827652c6dc88015C66448A6eC5cf74daeECC4D] = 1;
        freeMintAmountMapping[0x2076A87D5968fB96d24f56315cA9014897973772] = 1;
        freeMintAmountMapping[0x2072C081C77A476c28d4B2e0F86ED8A789BD8078] = 1;
        freeMintAmountMapping[0x2065685879367ff787F19bC0a2BBAE2e284dFCe4] = 1;
        freeMintAmountMapping[0x1FDA16d5111f639D20ac78b31742b152729b421F] = 1;
        freeMintAmountMapping[0x1f5066F3a87c117075F57eb3E9839F3999977FDD] = 1;
        freeMintAmountMapping[0x1E6416545d3d520Dd0A512CBE8787cA61E8491bE] = 1;
        freeMintAmountMapping[0x1DC952E7232A25340Ecdf9Ef722D3ceee0f4beD4] = 1;
        freeMintAmountMapping[0x1DA399FEBc4d2aC3841f3dBBf1201078Bb10520E] = 1;
        freeMintAmountMapping[0x1D028D6fFEFbc9ec660aA30385733415F20f78fd] = 1;
        freeMintAmountMapping[0x1C23FA52c7e4B1eD0aa70611d918F5FD20E2b039] = 1;
        freeMintAmountMapping[0x1b42eaF5FA6cBe192FF7C43615dfFbc20541aAb3] = 1;
        freeMintAmountMapping[0x1b3b107FBb9A4530bA8b0F764F63f62a53788e4a] = 1;
        freeMintAmountMapping[0x1aa42256135E53Ebd86f19699A62702B57265869] = 1;
        freeMintAmountMapping[0x1A3326bf12589eE53b3f796c9D376EA3df60d459] = 1;
        freeMintAmountMapping[0x19D89263CaBC26030178955fF5bABc2641379f8C] = 1;
        freeMintAmountMapping[0x19206CC9eb256F611b0985d18867d1Cc6ef80EE1] = 1;
        freeMintAmountMapping[0x16dEaa7aDEe82463ea617dfb931a6bf2B41bf428] = 1;
        freeMintAmountMapping[0x16414387406dE17f3eCB0e2CAd263C9D04553f4e] = 1;
        freeMintAmountMapping[0x14e083f433308170ECB3a2758D51332a0B833e10] = 1;
        freeMintAmountMapping[0x14ad8F58d7EbA4B50689c9165af9cfbceF706398] = 1;
        freeMintAmountMapping[0x149435d8E44B7f0bd12EC849678Ae55c4951027E] = 1;
        freeMintAmountMapping[0x1479B108407e7a9DE802D14B3e55B2962a0f26bc] = 1;
        freeMintAmountMapping[0x145dBea397f71512Ab97cbbF080d74D3bcC29176] = 1;
        freeMintAmountMapping[0x130f994E85B9c81Aa8AA63e25fc05fF27f16Ef20] = 1;
        freeMintAmountMapping[0x112CfD399062161dDaEA99bC30c97013d61927c5] = 1;
        freeMintAmountMapping[0x108BE80b8f2E44034171723AC720A7177b002FAE] = 1;
        freeMintAmountMapping[0x0Feb8c649fbE79e576BCc0857e2aEa7e4359561a] = 1;
        freeMintAmountMapping[0x0f138831Aa4a28E298CD120D6338dc815d93481d] = 1;
        freeMintAmountMapping[0x0Ed35594FDb513f955cddE0B0B54a12d619d109c] = 1;
        freeMintAmountMapping[0x0cD6139A8cc6Cba0a9067e9E5fF13FEeBF95Ad47] = 1;
        freeMintAmountMapping[0x0b386696fEb58e5d30f8036AE0ee663857c9C150] = 1;
        freeMintAmountMapping[0x0b1F309FBd3D038576Df6d205bc6c6c13ebBE3B6] = 1;
        freeMintAmountMapping[0x0B15d768985d35039CfaBFCE8680AfD535fD1556] = 1;
        freeMintAmountMapping[0x0b122c9d7B1E0dc305feb4CBfE97646d02a10bc6] = 1;
        freeMintAmountMapping[0x0aa22bdc1F0A6850928750306f697E7394C6aB38] = 1;
        freeMintAmountMapping[0x0A11605280c54F62F4968DBd7078981006716355] = 1;
        freeMintAmountMapping[0x098Ca151fc2E112459DF0f5F88f85AafE605F0fB] = 1;
        freeMintAmountMapping[0x08113b0e3f4D02b6ACB9073B4acA8FFaBcc740A3] = 1;
        freeMintAmountMapping[0x079754F9A459716B36ECa1EFb72b3ceADDd8E0E7] = 1;
        freeMintAmountMapping[0x060AE6eb0AE0C2A1aA37fe6Aa43711D46EE19B31] = 1;
        freeMintAmountMapping[0x05bE7B75Cc3D3Bf89cb548F74D37d4367dd5544b] = 1;
        freeMintAmountMapping[0x0591763c6fc03C991643be4CAe8BC42e785896de] = 1;
        freeMintAmountMapping[0x04e45DC9785ceCd1a2CcFb40ad70ad70B3f10D45] = 1;
        freeMintAmountMapping[0x03a965fA0283F5E5A5E02e6e859e97710D2b50c3] = 1;
        freeMintAmountMapping[0x0290d2853585c35550F7d1E82Ca9b9BE497cBBfD] = 1;
        freeMintAmountMapping[0x019D239a36a4fd4828253E8EcCaDD1dD2D0dd147] = 1;
        freeMintAmountMapping[0x004fb342F4B36e504f667a4fe6932E0a1e20E529] = 1;
        freeMintAmountMapping[0xFd55D2558Fa1a8D6321336E681d4bE2048AF4117] = 2;
        freeMintAmountMapping[0xf6B56fBb88Ebc36F16835559E5aea990855Bb693] = 2;
        freeMintAmountMapping[0xf23B45a630724Ccba2AEA077B743F9e43465852E] = 2;
        freeMintAmountMapping[0xE8AbFe0685d7596c78438eD0B68c709b83486052] = 2;
        freeMintAmountMapping[0xE745cB3c5152750C63e2eD81510E3Edc89C3bcfa] = 2;
        freeMintAmountMapping[0xe1b38E2c33acfd66283334CfFbe1dA1a69e02F87] = 2;
        freeMintAmountMapping[0xE19216644ae5E188DAAbe8C9FC515Ec4783D52cC] = 2;
        freeMintAmountMapping[0xCE75584C49c4b5A3d232c16230a384497f91019E] = 2;
        freeMintAmountMapping[0xC74D61485be0647E388ff351ABFBAEEBc8977C12] = 2;
        freeMintAmountMapping[0xC264b4a5fb07202721eAaF13E756a91A34C409C5] = 2;
        freeMintAmountMapping[0xBEA72d78Bfe1d9c7F10Adbfd13f0476101CD00Df] = 2;
        freeMintAmountMapping[0xAf41939181902e68865186ae1f61e42338ddD754] = 2;
        freeMintAmountMapping[0xaa77d1a289F45F494edE8D2C93022b5E88baed2E] = 2;
        freeMintAmountMapping[0xa8E035f1D0Ef3f9EeA02688D1D64e7FDaA91970A] = 2;
        freeMintAmountMapping[0x98F202FD845AC175AD2d62bBe2d8684aff8AEcbE] = 2;
        freeMintAmountMapping[0x9854153589d671742d9B70b079984178db5436C0] = 2;
        freeMintAmountMapping[0x971DC6BB8122F51375e1b8c17212f987Fb6Db306] = 2;
        freeMintAmountMapping[0x8F31dd09226c5f82EdC414b3382AD9C404dE27Dc] = 2;
        freeMintAmountMapping[0x8dB5824Dab9848Ea740Bc06133E59AE679DE857f] = 2;
        freeMintAmountMapping[0x8aFe8F0b3486bbf3A0b6c785D87D9B972bD22F1D] = 2;
        freeMintAmountMapping[0x847A643AD8d71569329E8B133a68291696D9ac4B] = 2;
        freeMintAmountMapping[0x83e958aa52023ec40dE1dC30276adDEea6de4028] = 2;
        freeMintAmountMapping[0x6ce0DB14A58c81aaa13Cf0764199D206BD25312F] = 2;
        freeMintAmountMapping[0x5Edb7A2a7067Cc95c58C073d0c9a8B999dCa3b29] = 2;
        freeMintAmountMapping[0x5eC0f7103c93cbAd1A5Ce240D691f47566233134] = 2;
        freeMintAmountMapping[0x5cd796f22119bFb027b8ef25853923E59E950524] = 2;
        freeMintAmountMapping[0x5b6e4330ad93B8082d646f1684dcB32EC975289E] = 2;
        freeMintAmountMapping[0x58CEde4254a9d04464f11e7237a6f5872B84f364] = 2;
        freeMintAmountMapping[0x5632F9275B385eF8c51AD9956dB681776a26Be28] = 2;
        freeMintAmountMapping[0x561D4C86576C9E1675F1f77318ECfc18EC85D9Dc] = 2;
        freeMintAmountMapping[0x55fA6481A31f1963d5d6ab16d16E72d7225c3E8b] = 2;
        freeMintAmountMapping[0x5411Cf794c9cE7d956F47074A85411d597C83CD9] = 2;
        freeMintAmountMapping[0x52e030bCc69161e1A1f420485F6AEa6Eb0D97733] = 2;
        freeMintAmountMapping[0x4fedb138A7D7f1427768EF5747Bb8556b352e764] = 2;
        freeMintAmountMapping[0x4F6c919A4dc3D5870c51A05762A7088f5943Cb45] = 2;
        freeMintAmountMapping[0x498699432B19Bb8718c7f5BA61f1B2a116583803] = 2;
        freeMintAmountMapping[0x484aBbaA00Fc5A703dA1Eb747315660C11cd7103] = 2;
        freeMintAmountMapping[0x40B7Bea71f83a94c912E4C0a58564459D4Dd4cb8] = 2;
        freeMintAmountMapping[0x3d9fd60AEC344C20Fc0ef161f59225181730f47B] = 2;
        freeMintAmountMapping[0x35cCEd5CdF2483848EFc48Dbf6c5C4fdE225522D] = 2;
        freeMintAmountMapping[0x30C71b427b1822cbd95939851E61cF896d03f2e4] = 2;
        freeMintAmountMapping[0x2EE6B129a671cD805b1FB1e5ff70587E8F551c42] = 2;
        freeMintAmountMapping[0x2e40eF7526B1c86A19005346127d3C0FC2EC9019] = 2;
        freeMintAmountMapping[0x2A84c441f6002b2310D4925232676E6Dc8E78A40] = 2;
        freeMintAmountMapping[0x24379F6561726956fF440f72713cc31Bf5F6d34a] = 2;
        freeMintAmountMapping[0x2126d8d321fc638E1fcC58BF74c9D00156397524] = 2;
        freeMintAmountMapping[0x1Fb2DF535d1c7969a2964F49E25cE3a05bf45A91] = 2;
        freeMintAmountMapping[0x1F5705e882b7B190538508bF83485564fF9a0e6a] = 2;
        freeMintAmountMapping[0x1d6e4d039A259390Bc71BD2a1E60861BD6D7d50a] = 2;
        freeMintAmountMapping[0x17982d4224d781187617e01A4b7f4Df7CbcF317b] = 2;
        freeMintAmountMapping[0x0E644De3505B7b024f4d4C37B093a62CCF82af16] = 2;
        freeMintAmountMapping[0x0Dc1949E3a7282c293A491b1b66756aa65DE7e55] = 2;
        freeMintAmountMapping[0xee610163862968E5bC6d4d55493DE6a64222C07c] = 3;
        freeMintAmountMapping[0xEd44CA68bA2375A29492A860DDd5d41B4Db46e56] = 3;
        freeMintAmountMapping[0xeC1d11D899A8Ed5fcC1a03Ca9ce14Bbd06B24d97] = 3;
        freeMintAmountMapping[0xdFc85e3409Ea08ee0AD05A9D9Bd6f1B352308392] = 3;
        freeMintAmountMapping[0xc6bD569dBf8abcf20aBBbaB6F58AAEef2a22040e] = 3;
        freeMintAmountMapping[0xA79CaAbAf320A8Fe645C1C7290f14276c2a477d2] = 3;
        freeMintAmountMapping[0x85ab567d13086cd03976765a2c9a49e8E1DA9187] = 3;
        freeMintAmountMapping[0x82d2f81F61556f80bcDA77491B3CCBa4cfaE1142] = 3;
        freeMintAmountMapping[0x7B0f3E1eA31A731Da7E35628f1D6D1a772B8F8f3] = 3;
        freeMintAmountMapping[0x5e93303aEadccf996bd77EB91A9FaB241880334f] = 3;
        freeMintAmountMapping[0x4f556D724b1f7EFF4a6efAb5Af3a647f3dEbE48C] = 3;
        freeMintAmountMapping[0x4ADe4038736Ed186bee80f3fA8a7Bf931126F72C] = 3;
        freeMintAmountMapping[0x221995e6B982a5a9023df2fc4E4e00EdDC54010b] = 3;
        freeMintAmountMapping[0x1d7A3E7366d84F78E616dD805B305AC402cc5a6b] = 3;
        freeMintAmountMapping[0x002841301d1AB971D8acB3509Aa2891e3ef9D7E1] = 3;
        freeMintAmountMapping[0xE794cE89b1bb16780be977fe7a246bb6E6b256e0] = 4;
        freeMintAmountMapping[0xd99694fD205Cc2c9d5EBFFc5fD5ca5cb5416Ed03] = 4;
        freeMintAmountMapping[0xd239815bfCC6C70358927437429789Bcf0ac810D] = 4;
        freeMintAmountMapping[0xc8Ba8bBd50D10E3078BDf8f475516C5b02175D2C] = 4;
        freeMintAmountMapping[0xC8B51A47b7eDD0681276444770Bff117957A180a] = 4;
        freeMintAmountMapping[0xB4a4b42081Ca39F07c62F0A3f4bee9687559d7A9] = 4;
        freeMintAmountMapping[0xA672273865810234fAe493C944fC3a000f303f60] = 4;
        freeMintAmountMapping[0x9f819b76f00DA9dF29b4D2760cC888b74F17006C] = 4;
        freeMintAmountMapping[0x64541D14fC2ba37bFfCd209b5173479D41d1513D] = 4;
        freeMintAmountMapping[0x0f01eb10c9AfdC4A8094088793C59d04FC6dD2a0] = 4;
        freeMintAmountMapping[0xbD57dE27Eb6b422350c262f0e451d31a65e3EFe5] = 5;
        freeMintAmountMapping[0xa961a6375dBE7B14Df4f0cD426552C5a7709eFb9] = 5;
        freeMintAmountMapping[0xA8eb2ea3A233bC7Af4043DF453191a0939Bcb286] = 5;
        freeMintAmountMapping[0x9139Cd9146aB97162334205563662412a5D62CB2] = 5;
        freeMintAmountMapping[0x5f2952fF0E30f272554CC1f74884261D561ae979] = 5;
        freeMintAmountMapping[0x501790C6890dFA43c264AeE4Ed9aA5E116d0A0d4] = 5;
        freeMintAmountMapping[0x2aa92Eb0024e3F54c35dF1b1d6879631241222f2] = 5;
        freeMintAmountMapping[0x2664d2b96bd52b0E3eB08DE99C726D694f23D34F] = 5;
        freeMintAmountMapping[0x221a11F813e30CEf5399F3D584c4f3E00f5C0486] = 5;
        freeMintAmountMapping[0x115CB6Dc6223EAe44a8ce4F4CB8407f24F6Fd70f] = 5;
        freeMintAmountMapping[0xfDE0E287b589Ee479bD188F717bd566903da2C87] = 6;
        freeMintAmountMapping[0xFb2520759E6Dbc4696111a8Ef18bE569fe6b0E3E] = 6;
        freeMintAmountMapping[0xc1b853f9B2f3aa1e0f853901aC3e340f8bEa33B3] = 6;
        freeMintAmountMapping[0x9Ee6B94b4Fd48A75178D57bF5eb263DA709b8dbb] = 6;
        freeMintAmountMapping[0x2494062FeBddc66a073C00ac958d5132547eC449] = 6;
        freeMintAmountMapping[0x97eC8b90856649a0B61d09E2151b869635012724] = 7;
        freeMintAmountMapping[0x50871234728bF8d881d0f4e4B718080f71044185] = 7;
        freeMintAmountMapping[0xd18c458D756b8F6eD3742cc6a594D3A2B576Fa8F] = 8;
        freeMintAmountMapping[0x5F1A688C94971e2b7Da2b1a030947DeF4D7172e7] = 9;
        freeMintAmountMapping[0x2C7f5C7cD4b7bFeE9d4216B29e1A61D2A0a398F1] = 9;
        freeMintAmountMapping[0x57B27fC6EfF1c5DbDeC4a615cC88D43A583772d8] =     13;
        freeMintAmountMapping[0x4e9A80Ce5E4B0dF0d324aCaFebbbB2332Cb38Ff8] =     13;
        freeMintAmountMapping[0x44FaA42Da632DEcbdC7D40231Eb115DE6CB60f06] =     13;
        freeMintAmountMapping[0x5687e44feb0401d6FA56a26D01b253cec63276De] =     15;
        freeMintAmountMapping[0x4AA41136AD53FfB0f028dcA371D7B3c87305423D] =     15;
        freeMintAmountMapping[0x4E98dc956DE2B19Df8363c6Fb1af283a5600d80F] =     17;
        freeMintAmountMapping[0xEe50ab320e99c3a291A16E52EBF5409f122CBD67] =     20;
        freeMintAmountMapping[0x13c9b8215E03f4554fD066468700bf6a496912Bf] =     25;
        freeMintAmountMapping[0xDD178e387006425eC15CFF07F7e38A37BcC92a8D] =     28;
        freeMintAmountMapping[0x5ED0Cb5F507cF82F5A1b84E715b040fA361c433B] =     34;
    }

    mapping(address => uint256) freeMintAmountMapping;

    uint256 freeMintStartTime = 1671973200;
    
    uint256 freeMintEndTime = 1672225200;
    uint16 freeMintMaxAmount = 800;
    uint16 freeMintCount;

    bool revealStatus = false;
    string baseURIbeforeReveal = 'https://freemint.zoo-man.com/br/br.json';
    string baseURIafterReveal;

    function setBeforeRevealURI(string memory uri) public onlyOwner {
        baseURIbeforeReveal = uri;
    }

    function setAfterRevealURI(string memory uri) public onlyOwner {
        baseURIafterReveal = uri;
    }

    function setRevealOn() public onlyOwner {
        revealStatus = true;
    }

    function setFreeMint(address to, uint16 amount) public onlyOwner {
        freeMintAmountMapping[to] = amount;
    }

    function freeMint() public {
        require(freeMintAmountMapping[msg.sender] - balanceOf(msg.sender) >= 1);
        require(freeMintCount + 1 <= freeMintMaxAmount);
        require(block.timestamp >= freeMintStartTime);
        require(block.timestamp < freeMintEndTime);

        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, tokenId, '');
        _tokenIdCounter.increment();
        freeMintCount ++;
    }

    function freeBatchMint() public {
        uint256 freeMintLeftAmount = freeMintAmountMapping[msg.sender] - balanceOf(msg.sender);
        require(freeMintLeftAmount >= 1);
        require((freeMintLeftAmount + freeMintCount) <= freeMintMaxAmount);
        require(block.timestamp >= freeMintStartTime);
        require(block.timestamp < freeMintEndTime);

        for (uint256 i = 0; i < freeMintLeftAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId, '');
            _tokenIdCounter.increment();
            freeMintCount ++;
        }
    }

    function ownerMint() public onlyOwner {
        require(freeMintCount <= freeMintMaxAmount);
        require(block.timestamp >= freeMintEndTime);

        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, tokenId, '');
        freeMintCount ++;
    }

    function ownerBatchMint() public onlyOwner {
        require(freeMintCount <= freeMintMaxAmount);
        require(block.timestamp >= freeMintEndTime);

        for(uint256 i = freeMintCount; i <= freeMintMaxAmount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId, '');
            _tokenIdCounter.increment();
            freeMintCount ++;
        }
    }

     function tokenURI(uint256 tokenId)
        public
        view
        override
        returns(string memory)
    {
        return getURI(tokenId);
    }
    
    function getURI(uint256 tokenId)
        public
        view
        returns(string memory)
    {
        if(revealStatus == true) {
            return string(abi.encodePacked(baseURIafterReveal, tokenId.toString(), ".json"));
        } else {
            return baseURIbeforeReveal;
        }
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}