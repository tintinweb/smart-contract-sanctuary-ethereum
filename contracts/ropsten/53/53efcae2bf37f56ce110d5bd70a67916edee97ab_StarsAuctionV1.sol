/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// Dependency file: @openzeppelin/contracts/utils/Counters.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

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


// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// Dependency file: @openzeppelin/contracts/token/ERC1155/IERC1155.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/interfaces/IERC2981.sol

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

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


// Root file: contracts/StarsAuction.sol

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title An Auction Contract for bidding and selling NFTs
/// @author STARS.ART
/// @notice This contract can be used for auctioning NFTs (supports ERC721 and ERC1155) and accepts any ERC20 token as payment
contract StarsAuctionV1 is Ownable, ReentrancyGuard {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    using Address for address;
    using Counters for Counters.Counter;
    Counters.Counter private _auctionIds;

    address public feeAddress; // = 0xDa209d5B20CE12e6E37AED4374290668FDc68C85
    uint256 public feePercentage; // = 75; // default fee percentage : 0.75%, can move setting the value to constructor
    mapping(address => bool) public supportedERC20;

    enum TokenType {
        ERC721,
        ERC1155
    }
    enum AuctionStatus {
        CLOSED,
        OPEN
    }

    mapping(uint256 => Auction) private _auctions;

    struct Auction {
        uint256 auctionId;
        address nftContract;
        uint256 tokenId;
        uint256 quantity;
        // uint256 bidIncreasePercentage;
        // uint256 auctionBidPeriod; // Increments the length of time the auction is open in which a new bid can be made after each bid.
        uint256 startDate;
        uint256 duration;
        uint256 minPrice;
        uint256 buyNowPrice;
        uint256 highestBid;
        address highestBidder;
        address seller;
        address ERC20Token; // The seller can specify if ERC20 token that can be used to bid or purchase the NFT.
        TokenType tokenType;
        AuctionStatus status;
    }

    uint256 public minAuctionDuration;
    uint256 public minBidIncreasePercentage;

    /*
     * Default values that are used if not specified by the NFT seller.
     */
    uint256 public defaultBidIncreasePercentage;
    uint32 public minimumSettableIncreasePercentage;
    uint32 public maximumMinPricePercentage;
    uint32 public defaultAuctionBidPeriod;

    event AuctionCreated(uint256 auctionId, uint256 timestamp);

    event AuctionClosed(uint256 auctionId);

    event BidMade(uint256 auctionId, uint256 bid, address bidder);

    event Withdrawn(uint256 auctionId, address seller, uint256 funds);

    event FundsWithdrawn(uint256 auctionId, address seller, uint256 funds);

    event TokenWithdrawn(uint256 auctionId, address highestBidder);

    constructor(
        address feeAddress_,
        uint256 feePercentage_,
        address usdtAddress,
        address usdcAddress,
        uint256 minAuctionDuration_
    ) {
        setFeeAddress(feeAddress_);
        setFeePercentage(feePercentage_);
        setSupportedERC20(usdtAddress, true);
        setSupportedERC20(usdcAddress, true);
        setMinAuctionDuration(minAuctionDuration_); // 86400 = 1 day
        minBidIncreasePercentage = 500; // 5% --> 500

        defaultBidIncreasePercentage = 100;
        defaultAuctionBidPeriod = 86400; // 1 day
        minimumSettableIncreasePercentage = 100;
        maximumMinPricePercentage = 8000;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "StarsAuction: Invalid Address");
        feeAddress = _feeAddress;
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 1000, "StarsAuction: Fee percentage can't be more than 10%");
        feePercentage = _feePercentage;
    }

    function setSupportedERC20(address _ERC20Token, bool _isSupported) public onlyOwner {
        require(_ERC20Token.isContract(), "StarsAuction: Not a contract");
        supportedERC20[_ERC20Token] = _isSupported;
    }

    function setMinAuctionDuration(uint256 _duration) public onlyOwner {
        require(_duration > 0, "StarsAuction: Invalid duration");
        minAuctionDuration = _duration;
    }

    function _calculateFee(uint256 price) private view returns (uint256) {
        return (price * feePercentage) / 10000;
    }

    function getAuction(uint256 id) public view returns (Auction memory) {
        return _auctions[id];
    }

    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _minPrice,
        uint256 _duration,
        address _ERC20Token,
        uint256 _buyNowPrice
    ) external {
        require(_nftContract.isContract(), "StarsAuction: Not a contract");
        require(
            _duration >= minAuctionDuration,
            "StarsAuction: Auction duration must be more than 1 day"
        );
        require(
            _buyNowPrice > _minPrice,
            "StarsAuction: BuyNowPrice can't be less than min price"
        );

        if (_supportsRoyalties(_nftContract)) {
            (, uint256 royaltyAmount) = IERC2981(_nftContract).royaltyInfo(_tokenId, 10000); // price --> 100000
            require(
                royaltyAmount <= 5000, // (10000 * 5000) / 10000,
                "StarsAuction: Too high royalty percentage"
            );
        }

        if (_ERC20Token == address(0)) {
            require(
                _minPrice >= 0.00000000001 ether,
                "StarsAuction: Price must be at least 0.00000000001 ether"
            );
        } else {
            require(supportedERC20[_ERC20Token], "StarsAuction: ERC20 token isn't supported");
            require(_minPrice >= 1e7, "StarsAuction: Price must be at least 10 ERC20Tokens");
        }

        TokenType tokenType;
        bool supportsIERC721 = IERC721(_nftContract).supportsInterface(_INTERFACE_ID_ERC721);
        bool supportsIERC1155 = IERC1155(_nftContract).supportsInterface(_INTERFACE_ID_ERC1155);
        require(
            supportsIERC721 || supportsIERC1155,
            "StarsMarket: Contract doesn't support IERC721 or IERC1155"
        );

        if (supportsIERC721) {
            require(_quantity == 1, "StarsAuction: ERC721 quantity must be 1");
            require(
                IERC721(_nftContract).ownerOf(_tokenId) == msg.sender,
                "StarsAuction: Not an owner of nft"
            );
            require(
                IERC721(_nftContract).isApprovedForAll(msg.sender, address(this)),
                "StarsAuction: Need to approve auction contract"
            );

            tokenType = TokenType.ERC721;
            IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
        } else {
            require(
                IERC1155(_nftContract).supportsInterface(_INTERFACE_ID_ERC1155),
                "StarsAuction: Contract doesn't support IERC721"
            );
            require(
                IERC1155(_nftContract).balanceOf(msg.sender, _tokenId) >= _quantity,
                "StarsAuction: Not enough copies"
            );
            require(
                IERC1155(_nftContract).isApprovedForAll(msg.sender, address(this)),
                "StarsAuction: Need to approve auction contract"
            );

            tokenType = TokenType.ERC1155;
            IERC1155(_nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _quantity,
                ""
            );
        }

        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();
        _auctions[auctionId] = Auction(
            auctionId,
            _nftContract,
            _tokenId,
            _quantity,
            block.timestamp,
            _duration,
            _minPrice,
            _buyNowPrice,
            0,
            address(0),
            msg.sender,
            _ERC20Token,
            tokenType,
            AuctionStatus.OPEN
        );

        emit AuctionCreated(auctionId, block.timestamp);
    }

    function bid(uint256 _auctionId, uint256 _value) external payable nonReentrant {
        address ERC20Token = _auctions[_auctionId].ERC20Token;
        uint256 highestBid = _auctions[_auctionId].highestBid;
        address highestBidder = _auctions[_auctionId].highestBidder;
        address seller = _auctions[_auctionId].seller;

        require(
            _auctions[_auctionId].status == AuctionStatus.OPEN,
            "StarsAuction: Auction must be opened"
        );
        require(
            _auctions[_auctionId].startDate + _auctions[_auctionId].duration > block.timestamp,
            "StarsAuction: Auction time ended"
        );
        require(msg.sender != seller, "StarsAuction: Seller can't make bids");
        require(msg.sender != highestBidder, "StarsAuction: Highest bidder can't make a bid");

        // if (_auctions[_auctionId].highestBid == 0) {
        //     require(
        //         _auctions[_auctionId].minPrice <= _value,
        //         "StarsAuction: The first bid must be more or equal than minPrice"
        //     );
        // } else {
        //     require( // TODO: check if _value is more than highestBid at least on 5%
        //         _auctions[_auctionId].highestBid <= _value,
        //         "StarsAuction: The bid must be more or equal than highestBid"
        //     );
        // }

        if (highestBidder != address(0)) {
            _transferPreviousBid(ERC20Token, highestBidder, highestBid);
        }

        if (_auctions[_auctionId].buyNowPrice <= _value) {
            if (ERC20Token == address(0)) {
                require(msg.value == _value, "StarsAuction: Incorrect amount of wei was sent");
            } else {
                require(
                    IERC20(ERC20Token).allowance(msg.sender, address(this)) >= _value,
                    "StarsAuction: Not enough ERC20 tokens approved"
                );
            }
            address nftContract = _auctions[_auctionId].nftContract;
            uint256 fee = _calculateFee(_value);

            if (_supportsRoyalties(nftContract)) {
                (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(nftContract)
                    .royaltyInfo(_auctions[_auctionId].tokenId, _value);
                if (ERC20Token == address(0)) {
                    (bool statusRoyalty, ) = payable(royaltyReceiver).call{value: royaltyAmount}(
                        ""
                    );
                    require(statusRoyalty, "StarsAuction: Failed to send Ether");
                } else {
                    IERC20(ERC20Token).transferFrom(msg.sender, royaltyReceiver, royaltyAmount);
                }
                _value -= royaltyAmount;
            }

            if (ERC20Token == address(0)) {
                (bool statusAmount, ) = payable(seller).call{value: _value - fee}("");
                (bool statusFee, ) = payable(feeAddress).call{value: fee}("");
                require(statusAmount && statusFee, "StarsAuction: Failed to send Ether");
            } else {
                IERC20(ERC20Token).transferFrom(msg.sender, seller, _value - fee);
                IERC20(ERC20Token).transferFrom(msg.sender, feeAddress, fee);
            }

            // _payFeesAndSeller(_auctionId, ERC20Token, msg.sender, seller, _value);
            _transferToken(
                _auctionId,
                nftContract,
                _auctions[_auctionId].tokenId,
                _auctions[_auctionId].quantity,
                address(this),
                msg.sender
            );
            _auctions[_auctionId].status = AuctionStatus.CLOSED;

            emit AuctionClosed(_auctionId);
        } else {
            if (highestBidder == address(0)) {
                require(
                    _value >= _auctions[_auctionId].minPrice,
                    "StarsAuction: The first bid must be higher than minPrice"
                );
            } else {
                // TODO: try to set minPrice when starting auction as highestBid with zero address???
                require(
                    _value >= (highestBid * (10000 + minBidIncreasePercentage)) / 10000, // + 100%
                    "StarsAuction: Bid must be at least 5% higher than previous"
                );
            }

            _auctions[_auctionId].highestBid = _value;
            _auctions[_auctionId].highestBidder = msg.sender;

            if (ERC20Token == address(0)) {
                require(msg.value == _value, "StarsAuction: Incorrect amount of wei was sent");
            } else {
                require(
                    IERC20(ERC20Token).allowance(msg.sender, address(this)) >= _value,
                    "StarsAuction: Not enough ERC20 tokens approved"
                );

                IERC20(ERC20Token).transferFrom(msg.sender, address(this), _value);
            }

            emit BidMade(_auctionId, _value, msg.sender);
        }
    }

    function closeAuction(uint256 _auctionId) external nonReentrant {
        require(
            _auctions[_auctionId].status == AuctionStatus.OPEN,
            "StarsAuction: Auction is already closed"
        );
        require(
            _auctions[_auctionId].seller == msg.sender,
            "StarsAuction: Only seller can close auction"
        );
        require(
            _auctions[_auctionId].highestBidder == address(0),
            "StarsAuction: Can't close auction when bids are made"
        );

        _transferToken(
            _auctionId,
            _auctions[_auctionId].nftContract,
            _auctions[_auctionId].tokenId,
            _auctions[_auctionId].quantity,
            address(this),
            msg.sender
        );
        _auctions[_auctionId].status = AuctionStatus.CLOSED;

        emit AuctionClosed(_auctionId);
    }

    // withdrawFundsOrTokens()
    // function withdraw(uint256 _auctionId) external nonReentrant {
    //     address seller = _auctions[_auctionId].seller;
    //     uint256 highestBid = _auctions[_auctionId].highestBid;
    //     address highestBidder = _auctions[_auctionId].highestBidder;

    //     require(
    //         _auctions[_auctionId].status == AuctionStatus.OPEN,
    //         "StarsAuction: Auction is already closed"
    //     );
    //     require(
    //         _auctions[_auctionId].startDate + _auctions[_auctionId].duration < block.timestamp,
    //         "StarsAuction: Auction time must be ended"
    //     );
    //     require(
    //         msg.sender == seller || msg.sender == highestBidder,
    //         "StarsAuction: Only seller and highestBidder can withdraw auction funds"
    //     );

    //     if (highestBidder == address(0)) {
    //         _transferToken(
    //             _auctionId,
    //             _auctions[_auctionId].nftContract,
    //             _auctions[_auctionId].tokenId,
    //             _auctions[_auctionId].quantity,
    //             address(this),
    //             seller
    //         );
    //     } else {
    //         _payFeesAndSeller(
    //             _auctionId,
    //             _auctions[_auctionId].ERC20Token,
    //             address(this),
    //             seller,
    //             highestBid
    //         );
    //         _transferToken(
    //             _auctionId,
    //             _auctions[_auctionId].nftContract,
    //             _auctions[_auctionId].tokenId,
    //             _auctions[_auctionId].quantity,
    //             address(this),
    //             highestBidder
    //         );

    //         emit Withdrawn(_auctionId, seller, highestBid);
    //     }

    //     _auctions[_auctionId].status = AuctionStatus.CLOSED;

    //     emit AuctionClosed(_auctionId);
    // }

    function withdrawFunds(uint256 _auctionId) external nonReentrant {
        address seller = _auctions[_auctionId].seller;
        uint256 highestBid = _auctions[_auctionId].highestBid;
        address highestBidder = _auctions[_auctionId].highestBidder;

        require(
            _auctions[_auctionId].status == AuctionStatus.OPEN,
            "StarsAuction: Auction is already closed"
        );
        require(
            _auctions[_auctionId].startDate + _auctions[_auctionId].duration < block.timestamp,
            "StarsAuction: Auction time must be ended"
        );
        require(msg.sender == seller, "StarsAuction: Only seller can withdraw auction funds");

        if (highestBidder == address(0)) {
            _transferToken(
                _auctionId,
                _auctions[_auctionId].nftContract,
                _auctions[_auctionId].tokenId,
                _auctions[_auctionId].quantity,
                address(this),
                seller
            );

            emit TokenWithdrawn(_auctionId, seller);
        } else {
            _payFeesAndSeller(_auctionId, _auctions[_auctionId].ERC20Token, seller, highestBid);

            emit FundsWithdrawn(_auctionId, seller, highestBid);
        }

        _auctions[_auctionId].status = AuctionStatus.CLOSED;
    }

    function withdrawToken(uint256 _auctionId) external nonReentrant {
        address highestBidder = _auctions[_auctionId].highestBidder;

        require(
            _auctions[_auctionId].status == AuctionStatus.OPEN,
            "StarsAuction: Auction is already closed"
        );
        require(
            _auctions[_auctionId].startDate + _auctions[_auctionId].duration < block.timestamp,
            "StarsAuction: Auction time must be ended"
        );
        require(
            msg.sender == highestBidder,
            "StarsAuction: Only highestBidder can withdraw auction token"
        );

        _transferToken(
            _auctionId,
            _auctions[_auctionId].nftContract,
            _auctions[_auctionId].tokenId,
            _auctions[_auctionId].quantity,
            address(this),
            highestBidder
        );

        _auctions[_auctionId].status = AuctionStatus.CLOSED;

        emit TokenWithdrawn(_auctionId, highestBidder);
    }

    function _transferPreviousBid(
        address _ERC20Token,
        address _to,
        uint256 _amount
    ) private {
        if (_ERC20Token == address(0)) {
            (bool status, ) = payable(_to).call{value: _amount}("");
            require(status, "StarsAuction: Failed to send Ether");
        } else {
            IERC20(_ERC20Token).transfer(_to, _amount);
        }
    }

    function _payFeesAndSeller(
        uint256 _auctionId,
        address _ERC20Token,
        address _to,
        uint256 _amount
    ) private {
        address nftContract = _auctions[_auctionId].nftContract;
        uint256 fee = _calculateFee(_amount);

        if (_supportsRoyalties(nftContract)) {
            (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(nftContract).royaltyInfo(
                _auctions[_auctionId].tokenId,
                _amount
            );
            if (_ERC20Token == address(0)) {
                (bool statusRoyalty, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
                require(statusRoyalty, "StarsAuction: Failed to send Ether");
            } else {
                IERC20(_ERC20Token).transfer(royaltyReceiver, royaltyAmount);
            }
            _amount -= royaltyAmount;
        }

        if (_ERC20Token == address(0)) {
            (bool statusAmount, ) = payable(_to).call{value: _amount - fee}("");
            (bool statusFee, ) = payable(feeAddress).call{value: fee}("");
            require(statusAmount && statusFee, "StarsAuction: Failed to send Ether");
        } else {
            IERC20(_ERC20Token).transfer(_to, _amount - fee);
            IERC20(_ERC20Token).transfer(feeAddress, fee);
        }
    }

    function _transferToken(
        uint256 _auctionId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _quantity,
        address _from,
        address _to
    ) private {
        if (_auctions[_auctionId].tokenType == TokenType.ERC721) {
            IERC721(_nftContract).safeTransferFrom(_from, _to, _tokenId);
        } else {
            IERC1155(_nftContract).safeTransferFrom(_from, _to, _tokenId, _quantity, "");
        }
    }

    // function getUserAuctions(address walletAddress) public view returns (Auction[] memory) {
    //     uint256 totalAuctionCount = _auctionIds.current();
    //     // uint256 auctionCount = 0;
    //     uint256 currentIndex = 0;

    //     // for (uint256 i = 0; i < totalItemCount; i++) {
    //     //     if (
    //     //         (idToMarketItem[i + 1].seller == walletAddress) &&
    //     //         (idToMarketItem[i + 1].status == MarketStatus.OPEN)
    //     //     ) {
    //     //         itemCount += 1;
    //     //     }
    //     // }

    //     Auction[] memory auctions = new Auction[](totalAuctionCount);
    //     for (uint256 i = 0; i < totalAuctionCount; i++) {
    //         if (
    //             (_auctions[i + 1].seller == walletAddress) &&
    //             (_auctions[i + 1].status == AuctionStatus.OPEN)
    //         ) {
    //             Auction storage currentAuction = _auctions[i + 1];
    //             auctions[currentIndex] = currentAuction;
    //             currentIndex += 1;
    //         }
    //     }

    //     return auctions;
    // }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /* Uncomment when mintBatchNFT will be added
	function onERC1155BatchReceived(address, 
        address, uint256[] memory, 
        uint256[] memory, 
        bytes memory
    ) public virtual returns (bytes4) {
		return this.onERC1155BatchReceived.selector;
	}
	*/

    function _supportsRoyalties(address _nftContract) internal view returns (bool) {
        return IERC165(_nftContract).supportsInterface(_INTERFACE_ID_ERC2981);
    }
}