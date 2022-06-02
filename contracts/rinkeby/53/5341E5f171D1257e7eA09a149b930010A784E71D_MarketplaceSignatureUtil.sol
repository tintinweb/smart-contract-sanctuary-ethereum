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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

// _________ .__                   .___
// \_   ___ \|  |   ______  _  ____| _/___________
// /    \  \/|  |  /  _ \ \/ \/ / __ |/ __ \_  __ \
// \     \___|  |_(  <_> )     / /_/ \  ___/|  | \/
//  \______  /____/\____/ \/\_/\____ |\___  >__|
//         \/                       \/    \/

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {BuyOrderV1, BuyOrderV1Functions} from "./libraries/passiveorders/BuyOrderV1.sol";
import {Execution} from "./libraries/execution/Execution.sol";
import {SafeERC20Transfer} from "./libraries/assettransfer/SafeERC20Transfer.sol";
import {SignatureUtil} from "./libraries/SignatureUtil.sol";
import {MarketplaceSignatureUtil, OpenSeaOwnableDelegateProxy} from "./libraries/MarketplaceSignatureUtil.sol";
import {NftCollectionFunctions} from "./libraries/NftCollection.sol";

contract ClowderMainOwnable is Ownable {
    address public protocolFeeReceiver;
    uint256 public protocolFeeFraction = 100; // out of 10_000
    uint256 public protocolFeeFractionFromSelling = 100; // out of 10_000
    uint256 public minConsensusForSellingOverOrEqualBuyPrice = 5_000; // out of 10_000
    uint256 public minConsensusForSellingUnderBuyPrice = 10_000; // out of 10_000

    /**
     * @notice [onlyOwner] Change the protocol fee receiver
     * @param _protocolFeeReceiver new receiver
     */
    function changeProtocolFeeReceiver(address _protocolFeeReceiver)
        external
        onlyOwner
    {
        protocolFeeReceiver = _protocolFeeReceiver;
    }

    /**
     * @notice [onlyOwner] Change the protocol fee fraction
     * @param _protocolFeeFraction new fee fraction (out of 10_000)
     */
    function changeProtocolFeeFraction(uint256 _protocolFeeFraction)
        external
        onlyOwner
    {
        protocolFeeFraction = _protocolFeeFraction;
    }

    /**
     * @notice [onlyOwner] Change the protocol fee fraction from selling
     * @param _protocolFeeFractionFromSelling new fee fraction (out of 10_000)
     */
    function changeProtocolFeeFractionFromSelling(
        uint256 _protocolFeeFractionFromSelling
    ) external onlyOwner {
        protocolFeeFractionFromSelling = _protocolFeeFractionFromSelling;
    }

    /**
     * @notice [onlyOwner] Change the min consensus for selling over or equal to buy price
     * @param _minConsensusForSellingOverOrEqualBuyPrice new min consensus (out of 10_000)
     */
    function changeMinConsensusForSellingOverOrEqualBuyPrice(
        uint256 _minConsensusForSellingOverOrEqualBuyPrice
    ) external onlyOwner {
        minConsensusForSellingOverOrEqualBuyPrice = _minConsensusForSellingOverOrEqualBuyPrice;
    }

    /**
     * @notice [onlyOwner] Change the min consensus for selling under buy price
     * @param _minConsensusForSellingUnderBuyPrice new min consensus (out of 10_000)
     */
    function changeMinConsensusForSellingUnderBuyPrice(
        uint256 _minConsensusForSellingUnderBuyPrice
    ) external onlyOwner {
        minConsensusForSellingUnderBuyPrice = _minConsensusForSellingUnderBuyPrice;
    }
}

contract ClowderMain is
    ClowderMainOwnable,
    ReentrancyGuard,
    ERC721Holder,
    ERC1155Holder,
    IERC1271
{
    address public immutable WETH;
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;

    // user => nonce => isUsedBuyNonce
    mapping(address => mapping(uint256 => bool)) public isUsedBuyNonce;
    // user => nonce => isUsedSellNonce
    mapping(address => mapping(uint256 => bool)) public isUsedSellNonce;
    // buyer => executionId => real contribution
    // Returns to zero when the owner is given their part of the
    // sale proceeds (claimProceeds).
    mapping(address => mapping(uint256 => uint256)) public realContributions;
    // executionId => Execution
    mapping(uint256 => Execution) public executions;


    /* Events */
    event OpenSeaOrderSet(
        MarketplaceSignatureUtil.OpenSeaOrder order
    );

    constructor(
        address _WETH,
        address _protocolFeeReceiver
    ) {
        WETH = _WETH;
        protocolFeeReceiver = _protocolFeeReceiver;

        EIP712_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ), // EIP712 domain typehash
                keccak256("Clowder"), // name
                keccak256(bytes("0.1")), // version
                block.chainid,
                address(this)
            )
        );
    }

    function cancelBuyOrders(uint256[] calldata buyOrderNonces) external {
        require(
            buyOrderNonces.length > 0,
            "Cancel: Must provide at least one nonce"
        );

        for (uint256 i = 0; i < buyOrderNonces.length; i++) {
            isUsedBuyNonce[msg.sender][buyOrderNonces[i]] = true; // used
        }
    }

    function cancelSellOrders(uint256[] calldata sellOrderNonces) external {
        require(
            sellOrderNonces.length > 0,
            "Cancel: Must provide at least one nonce"
        );

        for (uint256 i = 0; i < sellOrderNonces.length; i++) {
            isUsedSellNonce[msg.sender][sellOrderNonces[i]] = true; // cancelled
        }
    }

    /**
     * @notice Executes on an array of passive buy orders
     */
    function executeOnPassiveBuyOrders(
        BuyOrderV1[] calldata buyOrders,
        uint256 executorPrice,
        uint256 tokenId
    ) external nonReentrant {
        require(buyOrders.length > 0, "Execute: Must have at least one order");

        uint256 protocolFee = (protocolFeeFraction * executorPrice) / 10_000;
        uint256 price = executorPrice + protocolFee;
        address collection = buyOrders[0].collection;
        uint256 executionId = buyOrders[0].executionId;

        require(
            executions[executionId].collection == address(0),
            "Execute: Id already executed"
        );
        // creating the execution object immediately (extra measure to prevent reentrancy)
        executions[executionId] = Execution({
            collection: collection,
            buyPrice: price,
            tokenId: tokenId,
            sold: false,
            sellPrice: 0,
            listingEndTime: 0,
            openSeaOrderHash: bytes32(0),
            sellProtocolFee: 0
        });

        uint256 protocolFeeTransferred = 0;
        uint256 executorPriceTransferred = 0;

        // validate and process all the buy orders
        for (uint256 i = 0; i < buyOrders.length; i++) {
            BuyOrderV1 calldata order = buyOrders[i];
            // Validate order nonce usability
            require(
                !isUsedBuyNonce[order.signer][order.buyNonce],
                "Order nonce is unusable"
            );
            // Invalidating order nonce immediately (to avoid reentrancy
            // or even reusing the signature in this loop)
            // DO NOT separate from the above check, otherwise the order
            // nonce could be reused (you can check the
            // executeOnPassiveSellOrders for guidance). If you need separation
            // probably you can check the signer/nonces before "i".
            isUsedBuyNonce[order.signer][order.buyNonce] = true;
            // Validate order signature
            bytes32 orderHash = order.hash();
            require(
                SignatureUtil.verify(
                    orderHash,
                    order.signer,
                    order.v,
                    order.r,
                    order.s,
                    EIP712_DOMAIN_SEPARATOR
                ),
                "Signature: Invalid"
            );
            // Validate the order is not expired
            require(order.buyPriceEndTime >= block.timestamp, "Order expired");

            // Validate the order can accept the price
            require(order.canAcceptBuyPrice(price), "Order can't accept price");
            // Validate collection
            require(
                order.collection == collection,
                "Order collection mismatch"
            );
            // Validate executionId
            require(
                order.executionId == executionId,
                "Order executionId mismatch"
            );

            uint256 contribution = order.contribution;

            // transferring the protocol fee
            uint256 protocolWethAmount = Math.min(
                protocolFee - protocolFeeTransferred,
                contribution
            );
            protocolFeeTransferred += protocolWethAmount;
            _safeTransferWETH(
                order.signer,
                protocolFeeReceiver,
                protocolWethAmount
            );

            // transferring the protocol executor price
            uint256 executorPriceAmount = Math.min(
                executorPrice - executorPriceTransferred,
                contribution - protocolWethAmount
            );
            executorPriceTransferred += executorPriceAmount;
            _safeTransferWETH(order.signer, msg.sender, executorPriceAmount);

            // adding to the real contribution of the signer
            uint256 realContribution = protocolWethAmount + executorPriceAmount;
            realContributions[order.signer][executionId] += realContribution;
        } // ends the orders for loop

        // validating that we transferred the correct amounts of WETH
        require(
            protocolFeeTransferred == protocolFee,
            "Protocol fee not transferred correctly"
        );
        require(
            executorPriceTransferred == executorPrice,
            "Executor price not transferred correctly"
        );

        // transferring the NFT
        NftCollectionFunctions.transferNft(
            collection,
            msg.sender,
            address(this),
            tokenId
        );
    }

    function _invalidateNonces(BuyOrderV1[] calldata orders) internal {
        // Invalidating nonces
        for (uint256 i = 0; i < orders.length; i++) {
            BuyOrderV1 calldata order = orders[i];
            // Invalidating order nonce (to avoid reentrancy)
            isUsedSellNonce[order.signer][order.sellNonce] = true;
        }
    }

    function executeOnPassiveSellOrders(
        BuyOrderV1[] calldata orders,
        uint256 executorPrice
    ) external nonReentrant {
        require(orders.length > 0, "ExecuteSell: Must have at least one order");

        uint256 protocolFee = (protocolFeeFractionFromSelling * executorPrice) /
            10_000;
        uint256 price = executorPrice - protocolFee;
        uint256 executionId = orders[0].executionId;

        Execution storage execution = executions[executionId];

        /* Validations */

        require(execution.collection != address(0), "Execution doesn't exist");

        require(!execution.sold, "Execution already sold");

        BuyOrderV1Functions.validateSellOrdersParameters(
            isUsedSellNonce,
            realContributions,
            orders,
            executionId,
            execution,
            price,
            minConsensusForSellingOverOrEqualBuyPrice,
            minConsensusForSellingUnderBuyPrice
        );

        /* Invalidations */

        _invalidateNonces(orders);

        // marking as sold (to prevent reentrancy)
        execution.sold = true;

        // storing the price to be distributed among the owners
        execution.sellPrice = price;

        /* Giving away execution flow */

        // Validate signatures (includes interaction with
        // other contracts)
        BuyOrderV1Functions.validateSignatures(orders, EIP712_DOMAIN_SEPARATOR);

        // transferring the WETH from the caller to Clowder
        _safeTransferWETH(msg.sender, address(this), price);

        // transferring the protocol fee
        _safeTransferWETH(msg.sender, protocolFeeReceiver, protocolFee);

        // transferring the NFT
        NftCollectionFunctions.transferNft(
            execution.collection,
            address(this),
            msg.sender,
            execution.tokenId
        );
    }

    function listOnOpenSea(
        BuyOrderV1[] calldata orders,
        uint256 executorPrice,
        uint256 marketplaceFee // out of 10_000
    ) external nonReentrant {
        require(
            orders.length > 0,
            "ListOnMarketplace: Must have at least one order"
        );

        uint256 protocolFee = (protocolFeeFractionFromSelling * executorPrice) /
            10_000;
        uint256 price = executorPrice - protocolFee;
        uint256 executionId = orders[0].executionId;

        Execution storage execution = executions[executionId];

        /* Validations */

        require(execution.collection != address(0), "Execution doesn't exist");

        require(!execution.sold, "Execution already sold");

        uint256 minExpirationTime = BuyOrderV1Functions
            .validateSellOrdersParameters(
                isUsedSellNonce,
                realContributions,
                orders,
                executionId,
                execution,
                price,
                minConsensusForSellingOverOrEqualBuyPrice,
                minConsensusForSellingUnderBuyPrice
            );

        // Validate signatures (includes interaction with
        // other contracts)
        BuyOrderV1Functions.validateSignatures(orders, EIP712_DOMAIN_SEPARATOR);

        {
            // OpenSea stuff

            // Approving OpenSea to move the item (if not approved already) and WETH (yes, OpenSea requires this for the way it works)
            // initialize opensea proxy (check opensea-js)
            OpenSeaOwnableDelegateProxy myProxy = MarketplaceSignatureUtil
                .wyvernProxyRegistry
                .proxies(address(this));
                
            if (address(myProxy) == address(0)) {
                myProxy = MarketplaceSignatureUtil
                    .wyvernProxyRegistry
                    .registerProxy();
            }

            IERC721 erc721 = IERC721(execution.collection);
            if (!erc721.isApprovedForAll(address(this), address(myProxy))) {
                erc721.setApprovalForAll(address(myProxy), true);
            }

            IERC20 erc20 = IERC20(WETH);
            if (
                erc20.allowance(
                    address(this),
                    MarketplaceSignatureUtil.WyvernTokenTransferProxy
                ) < type(uint256).max
            ) {
                erc20.approve(
                    MarketplaceSignatureUtil.WyvernTokenTransferProxy,
                    type(uint256).max
                );
            }
        }

        // calculating list price
        uint256 listPrice = (10_000 * executorPrice) /
            (10_000 - marketplaceFee) +
            1;

        // creating the OpenSea sell order
        (bytes32 _hash, MarketplaceSignatureUtil.OpenSeaOrder memory openSeaOrder) 
            = MarketplaceSignatureUtil.buildAndGetOpenSeaOrderHash(
            address(this),
            execution.collection,
            execution.tokenId,
            listPrice,
            minExpirationTime,
            marketplaceFee,
            WETH
        );
        require(_hash != 0, "Hash must not be 0");

        // storing the hash by executionId (replacing the old one, so invalidating it)
        execution.openSeaOrderHash = _hash;
        // storing the last list price so we know how much to
        // to be awarded to each owner
        execution.sellPrice = price;
        // storing the protocol fee
        execution.sellProtocolFee = protocolFee;
        // storing the listing end time
        execution.listingEndTime = minExpirationTime;

        emit OpenSeaOrderSet(openSeaOrder);
    }

    function isValidSignature(bytes32 _hash, bytes calldata _signature)
        external
        view
        override
        returns (bytes4)
    {
        require(_hash != 0, "Hash must not be 0");
        uint256 executionId = uint256(bytes32(_signature[:32]));
        // Validate signatures
        if (executions[executionId].openSeaOrderHash == _hash) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    function claimNft(uint256 executionId, address to) external nonReentrant {
        Execution storage execution = executions[executionId];
        require(
            execution.collection != address(0),
            "ClaimNft: Execution doesn't exist"
        );
        require(!execution.sold, "ClaimNft: Execution already sold");
        /*
         * Invalidating immediately (extra measure to prevent reentrancy)
         * TODO: maybe we can zero the execution struct instead (?),
         * that way we save gas and also allow re-using the executionId
         */
        executions[executionId].sold = true;
        // validating real contribution
        uint256 realContribution = realContributions[msg.sender][executionId];
        require(
            execution.buyPrice == realContribution,
            "ClaimNft: wrong real contribution"
        );
        // just for claiming gas deductions
        realContributions[msg.sender][executionId] = 0;
        // transferring the NFT
        NftCollectionFunctions.transferNft(
            execution.collection,
            address(this),
            to,
            execution.tokenId
        );
    }

    function preClaim(uint256[] calldata executionIds) internal {
         // loop over the executions
        for (uint256 i = 0; i < executionIds.length; i++) {
            uint256 executionId = executionIds[i];
            Execution storage execution = executions[executionId];

            require(
                execution.collection != address(0),
                "PreClaim: Execution doesn't exist"
            );
            // Validating that we already sold the NFT
            // or that we don't have it anymore (if NFT was sold through a marketplace).
            // What about if nobody has claimed their proceeds from an old execution of the same NFT?
            // They wouldn't be allowed to claim proceeds until the current execution NFT is sold.
            // That's why the fee receiver should mark the execution as sold
            // as soon as the NFT is gone (sold), for now only
            // the fee receiver can receive the protocol sell fee. Do we need
            // to allow external arbitragers?
            // Another option is create a new contract per execution,
            // so this new contract holds the NFT, WETH and the execution struct,
            // would that be a bit more gas-expensive?
            bool clowderOwnsTheNft = IERC721(execution.collection).ownerOf(
                execution.tokenId
            ) == address(this);
            require(
                execution.sold || !clowderOwnsTheNft,
                "PreClaim: NFT has not been sold nor ask has been taken"
            );
            // Marking the execution as sold so future claimers don't need to
            // rely on checking whether Clowder owns the NFT or not
            if (!execution.sold) {
                execution.sold = true;
            }
        }
    }

    function claimProceeds(uint256[] calldata executionIds, address to)
        external
    {
        preClaim(executionIds);

        uint256 proceedsSum = 0;
        // loop over the executions
        for (uint256 i = 0; i < executionIds.length; i++) {
            uint256 executionId = executionIds[i];
            Execution storage execution = executions[executionId];

            // transferring the WETH to the signer
            uint256 realContribution = realContributions[msg.sender][
                executionId
            ];
            uint256 price = execution.sellPrice;
            // dust remains for the smart contract, that's ok
            uint256 proceeds = (realContribution * price) / execution.buyPrice;
            // to prevent double claiming:
            realContributions[msg.sender][executionId] = 0;
            proceedsSum += proceeds;
        }
        _safeTransferWETH(address(this), to, proceedsSum);
    }

    function claimProtocolFees(uint256[] calldata executionIds) external {
        preClaim(executionIds);

        uint256 feesSum = 0;
        // loop over the executions
        for (uint256 i = 0; i < executionIds.length; i++) {
            uint256 executionId = executionIds[i];
            Execution storage execution = executions[executionId];

            feesSum += execution.sellProtocolFee;
            // marking it zero so the protocol fee receiever can't receive it again
            execution.sellProtocolFee = 0;
        }
        _safeTransferWETH(address(this), protocolFeeReceiver, feesSum);
    }

    function _safeTransferWETH(
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeERC20Transfer.safeERC20Transfer(WETH, from, to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import {ClowderMain} from "../ClowderMain.sol";

interface OpenSea {
    // mapping(address => uint256) public nonces;
    function nonces(address user) external view returns (uint256);
}

interface OpenSeaOwnableDelegateProxy {}

interface OpenSeaProxyRegistry {
    // mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
    function proxies(address user)
        external
        view
        returns (OpenSeaOwnableDelegateProxy);

    function registerProxy() external returns (OpenSeaOwnableDelegateProxy);
}

library MarketplaceSignatureUtil {
    // mainnet
    // OpenSea public constant openSea =
    //     OpenSea(0x7f268357A8c2552623316e2562D90e642bB538E5);
    // address public constant WyvernTokenTransferProxy = 0xe5c783ee536cf5e63e792988335c4255169be4e1;
    // bytes32 internal constant OPENSEA_DOMAIN_SEPARATOR =
    //     0x72982d92449bfb3d338412ce4738761aff47fb975ceb17a1bc3712ec716a5a68;
    // bytes32 internal constant _OPENSEA_ORDER_TYPEHASH =
    //     0xdba08a88a748f356e8faf8578488343eab21b1741728779c9dcfdc782bc800f8;
    // address internal constant openSeaFeeRecipient =
    //     0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    // address internal constant openSeaMerkleValidator =
    //     0xbaf2127b49fc93cbca6269fade0f7f31df4c88a7;
    // address public constant WyvernProxyRegistry =
    // 0xa5409ec958c83c3f309868babaca7c86dcb077c1;

    // rinkeby
    OpenSea public constant openSea =
        OpenSea(0xdD54D660178B28f6033a953b0E55073cFA7e3744);
    OpenSeaProxyRegistry public constant wyvernProxyRegistry =
        OpenSeaProxyRegistry(0x1E525EEAF261cA41b809884CBDE9DD9E1619573A);
    address public constant WyvernTokenTransferProxy =
        0xCdC9188485316BF6FA416d02B4F680227c50b89e;
    bytes32 internal constant OPENSEA_DOMAIN_SEPARATOR =
        0xd38471a54d114ee69fbb07d1769a0bbecd4f429ddf5932c7098093908e24bd9d;
    bytes32 internal constant _OPENSEA_ORDER_TYPEHASH =
        0xdba08a88a748f356e8faf8578488343eab21b1741728779c9dcfdc782bc800f8;
    address internal constant openSeaFeeRecipient =
        0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
    address internal constant openSeaMerkleValidator =
        0x45B594792a5CDc008D0dE1C1d69FAA3D16B3DDc1;

    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

    /* An order on the exchange. */
    struct OpenSeaOrder {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint takerRelayerFee;
        /* Maker protocol fee of the order, unused for taker order. */
        uint makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint takerProtocolFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes calldata2; // changed 'calldata' name because of compilation error
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint extra;
        /* Listing timestamp. */
        uint listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint salt;
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    function hashOpenSeaOrder(OpenSeaOrder memory order, uint nonce)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint size = 800;
        bytes memory array = new bytes(size);
        uint index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes32(index, _OPENSEA_ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.target);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.calldata2)
        );
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.replacementPattern)
        );
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(
            index,
            keccak256(order.staticExtradata)
        );
        index = ArrayUtils.unsafeWriteAddressWord(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        index = ArrayUtils.unsafeWriteUint(index, nonce);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function getOpenSeaAskOrderHash(OpenSeaOrder memory order)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    OPENSEA_DOMAIN_SEPARATOR,
                    hashOpenSeaOrder(order, openSea.nonces(order.maker))
                )
            );
    }

    function buildAndGetOpenSeaOrderHash(
        address seller,
        address collection,
        uint256 tokenId,
        uint256 listPrice, // to be paid by buyer, the amount the seller receives is affected by feesFraction
        uint256 expiration,
        uint256 feesFraction, // (royalties + protocol fee fraction) out of 10_000
        address paymentToken
    ) public view returns (bytes32, OpenSeaOrder memory order) {
        order = MarketplaceSignatureUtil.OpenSeaOrder({
            exchange: address(openSea),
            maker: seller,
            taker: address(0),
            makerRelayerFee: feesFraction,
            takerRelayerFee: 0,
            makerProtocolFee: 0,
            takerProtocolFee: 0,
            feeMethod: FeeMethod.SplitFee,
            feeRecipient: openSeaFeeRecipient,
            side: SaleKindInterface.Side.Sell,
            saleKind: SaleKindInterface.SaleKind.FixedPrice,
            target: openSeaMerkleValidator,
            howToCall: AuthenticatedProxy.HowToCall.DelegateCall,
            staticTarget: address(0),
            staticExtradata: "",
            paymentToken: paymentToken,
            basePrice: listPrice,
            extra: 0,
            calldata2: bytes.concat(
                hex"fb16a595000000000000000000000000",
                abi.encodePacked(seller),
                hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                abi.encodePacked(collection),
                abi.encodePacked(tokenId),
                hex"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000"
            ),
            replacementPattern: hex"000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
            listingTime: block.timestamp,
            expirationTime: expiration,
            salt: block.timestamp
        });
        return (getOpenSeaAskOrderHash(order), order);
    }
}

library ArrayUtils {
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] =
                    ((mask[i] ^ 0xff) & array[i]) |
                    (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(a) == keccak256(b);
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal
        pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteAddressWord(uint index, address source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint8Word(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write bytes32 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteBytes32(uint index, bytes32 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
}

//// starts more OPENSEA stuff

library SaleKindInterface {
    /**
     * Side: buy or sell.
     */
    enum Side {
        Buy,
        Sell
    }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind {
        FixedPrice,
        DutchAuction
    }
}

library AuthenticatedProxy {
    enum HowToCall {
        Call,
        DelegateCall
    }
}

//// ends OPENSEA stuff

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library NftCollectionFunctions {

    // interface IDs
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    function transferNft(
        address collection,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            IERC721(collection).safeTransferFrom(from, to, tokenId);
        } else {
            revert("Collection does not support ERC721");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

library SignatureUtil {
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        require(signer != address(0), "SignatureUtil: Invalid signer");
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes32 digest = ECDSA.toTypedDataHash(domainSeparator, hash);
        return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library SafeERC20Transfer {
    using SafeERC20 for IERC20;

    function safeERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount != 0) {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

struct Execution {
    address collection; // zero to evaluate as non-existant
    uint256 buyPrice;
    uint256 tokenId;
    bool sold;
    /* Marketplace listing parameters */
    uint256 sellPrice; // if not sold yet, this is the amount we will recieve
    // from a marketplace in case it is listed for sale
    uint256 listingEndTime; // expiration time of the listing
    bytes32 openSeaOrderHash;
    uint256 sellProtocolFee; // only has value when a marketplace listing happens
    // otherwise it is zero because the protocol fee is transferred immediately
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import {SignatureUtil} from "./../SignatureUtil.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Execution} from "./../execution/Execution.sol";

using BuyOrderV1Functions for BuyOrderV1 global;

// DO NOT CHANGE the struct, create a new order file instead.
// If chaging the struct is extremely necessary, don't forget to 
// update the hash constant and hash function below.
struct BuyOrderV1 {
    
    address signer; // order signer

    // general order parameters
    address collection; // collection address
    uint256 executionId; // buy order execution id
    uint256 contribution; // WETH contribution

    // buy order parameters
    uint256 buyPrice; // buy WETH price
    uint256 buyPriceEndTime; // order expiration time (set 0 for omitting)
    uint256 buyNonce; // for differentiating orders (it is not possible to re-use the nonce)

    // sell order parameters
    uint256 sellPrice; // sell WETH price 
    uint256 sellPriceEndTime; // sell order expiration time (set 0 for omitting)
    uint256 sellNonce;

    // signature parameters
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @title PassiveTradeOrders
 * @notice
 */
library BuyOrderV1Functions {
    bytes32 internal constant PASSIVE_BUY_ORDER_HASH = 0x72e794cb40f2ebfd460c7e8f21afeacac61a902963a831638aeff99e28bc690f;

    function hash(BuyOrderV1 memory passiveOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PASSIVE_BUY_ORDER_HASH,
                    passiveOrder.signer,
                    passiveOrder.collection,
                    passiveOrder.executionId,
                    passiveOrder.contribution,
                    passiveOrder.buyPrice,
                    passiveOrder.buyPriceEndTime,
                    passiveOrder.buyNonce,
                    passiveOrder.sellPrice,
                    passiveOrder.sellPriceEndTime,
                    passiveOrder.sellNonce
                )
            );
    }

    function canAcceptBuyPrice(BuyOrderV1 memory passiveOrder, uint256 price) internal pure returns (bool) {
        return passiveOrder.buyPrice >= price;
    }
    
    function canAcceptSellPrice(BuyOrderV1 memory passiveOrder, uint256 price) internal pure returns (bool) {
        return passiveOrder.sellPrice <= price;
    }

    
    // Validate signatures (includes interaction with
    // other contracts)
    // Remember that we give away execution flow
    // in case the signer is a contract (isValidSignature)
    function validateSignatures(
        BuyOrderV1[] calldata orders,
        bytes32 domainSeparator
    ) public view {
        for (uint256 i = 0; i < orders.length; i++) {
            BuyOrderV1 calldata order = orders[i];
            // Validate order signature
            bytes32 orderHash = hash(order);
            require(
                SignatureUtil.verify(
                    orderHash,
                    order.signer,
                    order.v,
                    order.r,
                    order.s,
                    domainSeparator
                ),
                "Signature: Invalid"
            );
        }
    }

    function validateSellOrdersParameters(
        mapping(address => mapping(uint256 => bool)) storage _isUsedSellNonce,
        mapping(address => mapping(uint256 => uint256)) storage _realContributions,
        BuyOrderV1[] calldata orders,
        uint256 executionId,
        Execution storage execution,
        uint256 price,
        uint256 minConsensusForSellingOverOrEqualBuyPrice,
        uint256 minConsensusForSellingUnderBuyPrice
    ) public view returns (uint256) {
        // mapping(address => mapping(uint256 => bool))
        //     storage _isUsedSellNonce = isUsedSellNonce;
        // mapping(address => mapping(uint256 => uint256))
        //     storage _realContributions = realContributions;
        // Execution storage execution = executions[executionId];

        uint256 minExpirationTime = type(uint256).max;
        uint256 realContributionOnBoard = 0;
        // Validate orders parameters, no need to access state
        for (uint256 i = 0; i < orders.length; i++) {
            BuyOrderV1 calldata order = orders[i];

            // Validate the order is not expired
            require(order.sellPriceEndTime >= block.timestamp, "Order expired");
            // Validate collection
            require(
                order.collection == execution.collection,
                "Order collection mismatch"
            );
            // Validate executionId
            require(
                order.executionId == executionId,
                "Order executionId mismatch"
            );
            // Validating that the signer has not voted yet
            for (uint256 j = 0; j < i; j++) {
                if (orders[j].signer == order.signer) {
                    require(false, "Signer already voted");
                }
            }
            // Validating price acceptance
            require(
                canAcceptSellPrice(order, price),
                "Order can't accept price"
            );
            // updating the min expiration time
            minExpirationTime = Math.min(
                minExpirationTime,
                order.sellPriceEndTime
            );

            /* State required for tne following lines */

            // Validate order nonce usability
            require(
                !_isUsedSellNonce[order.signer][order.sellNonce],
                "Order nonce is unusable"
            );
            // counting the "votes" in favor of this price
            realContributionOnBoard += _realContributions[order.signer][
                executionId
            ];
        } // ends the voters for loop

        // Validating price consensus
        if (price >= execution.buyPrice) {
            // we need at least N out of 10_000 consensus
            require(
                realContributionOnBoard * 10_000 >=
                    execution.buyPrice *
                        minConsensusForSellingOverOrEqualBuyPrice,
                "Selling over or equal buyPrice: consensus not reached"
            );
        } else {
            // we need a different consensus ratio
            require(
                realContributionOnBoard * 10_000 >=
                    execution.buyPrice * minConsensusForSellingUnderBuyPrice,
                "Selling under buyPrice: consensus not reached"
            );
        }

        return minExpirationTime;
    }
}