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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This implements access control for owner and admins
 */
abstract contract GenArtAccess is Ownable {
    mapping(address => bool) public admins;
    address public genartAdmin;

    constructor() Ownable() {
        genartAdmin = _msgSender();
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdmin() {
        address sender = _msgSender();
        require(
            owner() == sender || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the GEN.ART admin.
     */
    modifier onlyGenArtAdmin() {
        address sender = _msgSender();
        require(
            genartAdmin == sender,
            "GenArtAccess: caller is not genart admin"
        );
        _;
    }

    function setGenArtAdmin(address admin) public onlyGenArtAdmin {
        genartAdmin = admin;
    }

    function setAdminAccess(address admin, bool access) public onlyGenArtAdmin {
        admins[admin] = access;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGenArt {
    function isGoldToken(uint256 _membershipId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtInterfaceV4 {
    function isGoldToken(uint256 _membershipId) external view returns (bool);

    function getMembershipsOf(address account)
        external
        view
        returns (uint256[] memory);

    function ownerOfMembership(uint256 _membershipId)
        external
        view
        returns (address, bool);

    function isVaulted(uint256 _membershipId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArt.sol";
import "../access/GenArtAccess.sol";

/**
 * @title GenArtValut
 * @notice It handles the distribution of ETH loyalties
 * @notice forked from https://etherscan.io/address/0xbcd7254a1d759efa08ec7c3291b2e85c5dcc12ce#code
 */
contract GenArtLoyaltyVault is ReentrancyGuard, GenArtAccess {
    using SafeERC20 for IERC20;
    struct UserInfo {
        uint256 tokens; // shares of token staked
        uint256[] membershipIds;
        uint256 userRewardPerTokenPaid; // user reward per token paid
        uint256 rewards; // pending rewards
    }

    // Precision factor for calculating rewards and exchange rate
    uint256 public constant PRECISION_FACTOR = 10**18;

    // Reward rate (block)
    uint256 public currentRewardPerBlock;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Reward per token stored
    uint256 public rewardPerTokenStored;

    // Total existing shares
    uint256 public totalTokenShares;
    uint256 public totalMembershipShares;

    uint256 public minimumTokenAmount = 4_000;
    uint256 public minimumMembershipAmount = 1;

    mapping(address => UserInfo) public userInfo;

    IERC20 public immutable genartToken;
    address public immutable genartMembership;

    mapping(address => uint256) public lockedWithdraw;

    uint256 public weightFactorTokens = 2;
    uint256 public weightFactorMemberships = 1;

    mapping(uint256 => address) public membershipOwners;

    bool public emergencyWithdrawDisabled;

    event Deposit(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 harvestedAmount);
    event NewRewardPeriod(
        uint256 numberBlocks,
        uint256 rewardPerBlock,
        uint256 reward
    );
    event Withdraw(address indexed user, uint256 amount, uint256[] memberships);

    /**
     * @notice Constructor
     * @param _genartToken address of the token staked (GRNART)
     */
    constructor(address _genartMembership, address _genartToken) {
        genartToken = IERC20(_genartToken);
        genartMembership = _genartMembership;
    }

    modifier requireNotLocked(address user) {
        require(block.timestamp > lockedWithdraw[user], "assets locked");
        _;
    }

    /**
     * @notice Deposit staked tokens (and collect reward tokens if requested)
     * @param amount amount to deposit (in GENART)
     */
    function deposit(uint256[] memory membershipIds, uint256 amount)
        external
        nonReentrant
    {
        address sender = _msgSender();
        _checkDeposit(sender, membershipIds, amount);
        _deposit(sender, membershipIds, amount);
    }

    function harvest() external nonReentrant {
        address sender = _msgSender();
        uint256 pendingRewards = _harvest(sender);
        require(pendingRewards > 0, "zero rewards to harvest");
        // transfer reward token to sender
        payable(sender).transfer(pendingRewards);
    }

    /**
     * @notice Withdraw all staked tokens (and collect reward tokens if requested)
     */
    function withdraw() external requireNotLocked(msg.sender) nonReentrant {
        address sender = _msgSender();
        require(userInfo[sender].tokens > 0, "zero shares");
        _withdraw(sender);
    }

    /**
     * @notice Withdraw staked tokens and memberships
     */
    function withdrawPartial(
        uint256 amount,
        uint256[] memory membershipsToWithdraw
    ) external requireNotLocked(msg.sender) nonReentrant {
        _withdrawPartial(msg.sender, amount, membershipsToWithdraw);
    }

    /**
     * @notice Update the reward per block (in rewardToken)
     * @dev Only callable by owner. Owner is meant to be another smart contract.
     */
    function updateRewards(uint256 rewardDurationInBlocks)
        external
        payable
        onlyAdmin
    {
        // adjust the current reward per block
        if (block.number >= periodEndBlock) {
            currentRewardPerBlock = msg.value / rewardDurationInBlocks;
        } else {
            currentRewardPerBlock =
                (msg.value +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                rewardDurationInBlocks;
        }

        lastUpdateBlock = block.number;
        periodEndBlock = block.number + rewardDurationInBlocks;

        emit NewRewardPeriod(
            rewardDurationInBlocks,
            currentRewardPerBlock,
            msg.value
        );
    }

    function lockUserWithdraw(address user, uint256 toTimestamp)
        external
        onlyAdmin
    {
        if (lockedWithdraw[user] >= toTimestamp) return;
        lockedWithdraw[user] = toTimestamp;
    }

    function setWeightFactors(
        uint256 newWeightFactorTokens,
        uint256 newWeightFactorMemberships
    ) external onlyAdmin {
        weightFactorTokens = newWeightFactorTokens;
        weightFactorMemberships = newWeightFactorMemberships;
    }

    function setMinTokenAndMembershipAmount(
        uint256 minimumTokenAmount_,
        uint256 minimumMembershipAmount_
    ) external onlyAdmin {
        minimumTokenAmount = minimumTokenAmount_;
        minimumMembershipAmount = minimumMembershipAmount_;
    }

    /**
     * @dev Disable emergency withdraw
     */
    function disableEmergencyWithdraw() public onlyAdmin {
        emergencyWithdrawDisabled = true;
    }

    /**
     * @dev Withdraw funds on contract to owner in case of emergency
     */
    function emergencyWithdraw() public onlyAdmin {
        require(!emergencyWithdrawDisabled, "emergency withdraw disabled");
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Checks requirements for depositing a stake
     */
    function _checkDeposit(
        address user,
        uint256[] memory membershipIds,
        uint256 amount
    ) internal view {
        // check required amount of tokens
        require(
            amount >=
                (
                    userInfo[user].membershipIds.length == 0
                        ? minimumTokenAmount * PRECISION_FACTOR
                        : 0
                ),
            "not enough tokens"
        );
        if (userInfo[user].membershipIds.length == 0) {
            require(
                membershipIds.length >= minimumMembershipAmount,
                "not enough memberships"
            );
        }
    }

    /**
     * @notice Return share value of a membership based on tier
     */
    function _getMembershipShareValue(uint256 membershipId)
        internal
        view
        returns (uint256)
    {
        // 5 shares per gold membership. 1 share for standard memberships
        return
            (IGenArt(genartMembership).isGoldToken(membershipId) ? 5 : 1) *
            PRECISION_FACTOR;
    }

    function _deposit(
        address user,
        uint256[] memory membershipIds,
        uint256 amount
    ) internal {
        // update reward for user
        _updateReward(user);
        // send memberships to this contract
        for (uint256 i; i < membershipIds.length; i++) {
            IERC721(genartMembership).transferFrom(
                user,
                address(this),
                membershipIds[i]
            );
            // save the membership token Ids
            userInfo[user].membershipIds.push(membershipIds[i]);
            membershipOwners[membershipIds[i]] = user;
            // adjust internal membership shares
            totalMembershipShares += _getMembershipShareValue(membershipIds[i]);
        }

        // transfer GENART tokens to this address
        genartToken.transferFrom(user, address(this), amount);

        // adjust internal token shares
        userInfo[user].tokens += amount;
        totalTokenShares += amount;

        emit Deposit(user, amount);
    }

    /**
     * @notice Update reward for a user account
     * @param _user address of the user
     */
    function _updateReward(address _user) internal {
        if (block.number != lastUpdateBlock) {
            rewardPerTokenStored = _rewardPerShare();
            lastUpdateBlock = _lastRewardBlock();
        }

        userInfo[_user].rewards = _calculatePendingRewards(_user);
        userInfo[_user].userRewardPerTokenPaid = rewardPerTokenStored;
    }

    /**
     * @notice Withdraw staked tokens and memberships and collect rewards
     */
    function _withdraw(address user) internal {
        // harvest rewards
        uint256 pendingRewards = _harvest(user);
        uint256 tokens = userInfo[user].tokens;
        uint256[] memory memberships = userInfo[user].membershipIds;

        // adjust internal token shares
        userInfo[user].tokens = 0;
        totalTokenShares -= tokens;

        // transfer GENART tokens to user
        genartToken.safeTransfer(user, tokens);
        for (uint256 i = memberships.length; i >= 1; i--) {
            // remove membership token id from user info object
            userInfo[user].membershipIds.pop();
            membershipOwners[memberships[i - 1]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                memberships[i - 1]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                user,
                memberships[i - 1]
            );
        }
        // transfer reward token to user
        payable(user).transfer(pendingRewards);
        emit Withdraw(user, tokens, memberships);
    }

    /**
     * @notice Withdraw staked tokens and memberships
     */
    function _withdrawPartial(
        address user,
        uint256 amount,
        uint256[] memory membershipsToWithdraw
    ) internal {
        // harvest rewards
        uint256 pendingRewards = _harvest(user);
        uint256 tokens = userInfo[user].tokens;

        uint256 remainingTokens;
        uint256 remainingMemberships;
        unchecked {
            remainingTokens = tokens - amount;
            remainingMemberships =
                userInfo[user].membershipIds.length -
                membershipsToWithdraw.length;
        }
        require(
            remainingTokens >= minimumTokenAmount,
            "remaining tokens less then minimumTokenAmount"
        );
        require(
            remainingMemberships >= minimumMembershipAmount,
            "remaining memberships less then minimumMembershipAmount"
        );

        // adjust internal token shares
        userInfo[user].tokens = remainingTokens;
        totalTokenShares -= amount;

        // transfer GENART tokens to user
        genartToken.safeTransfer(user, amount);
        for (uint256 i; i < membershipsToWithdraw.length; i++) {
            // remove membership token id from user info object
            uint256 vaultedMembershipIndex = findArrayIndex(
                userInfo[user].membershipIds,
                membershipsToWithdraw[i]
            );
            userInfo[user].membershipIds[vaultedMembershipIndex] = userInfo[
                user
            ].membershipIds[userInfo[user].membershipIds.length - 1];

            userInfo[user].membershipIds.pop();

            membershipOwners[membershipsToWithdraw[i]] = address(0);
            // adjust internal membership shares
            totalMembershipShares -= _getMembershipShareValue(
                membershipsToWithdraw[i]
            );
            IERC721(genartMembership).transferFrom(
                address(this),
                user,
                membershipsToWithdraw[i]
            );
        }
        // transfer reward token to user
        payable(user).transfer(pendingRewards);
        emit Withdraw(user, tokens, membershipsToWithdraw);
    }

    function findArrayIndex(uint256[] memory array, uint256 value)
        internal
        pure
        returns (uint256 index)
    {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) return i;
        }
        revert("value not found in array");
    }

    /**
     * @notice Harvest reward tokens that are pending
     */
    function _harvest(address user) internal returns (uint256) {
        // update reward for user
        _updateReward(user);

        // retrieve pending rewards
        uint256 pendingRewards = userInfo[user].rewards;

        if (pendingRewards == 0) return 0;
        // adjust user rewards and transfer
        userInfo[user].rewards = 0;

        emit Harvest(user, pendingRewards);

        return pendingRewards;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() internal view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Return reward per share
     */
    function _rewardPerShare() internal view returns (uint256) {
        if (totalTokenShares == 0) {
            return rewardPerTokenStored;
        }

        return
            rewardPerTokenStored +
            ((_lastRewardBlock() - lastUpdateBlock) * (currentRewardPerBlock));
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param user address of the user
     */
    function _calculatePendingRewards(address user)
        internal
        view
        returns (uint256)
    {
        return
            (((getUserShares(user)) *
                (_rewardPerShare() - (userInfo[user].userRewardPerTokenPaid))) /
                PRECISION_FACTOR) + userInfo[user].rewards;
    }

    /**
     * @notice Calculate pending rewards (WETH) for a user
     * @param user address of the user
     */
    function calculatePendingRewards(address user)
        external
        view
        returns (uint256)
    {
        return _calculatePendingRewards(user);
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Return rewards per share
     */
    function rewardPerShare() external view returns (uint256) {
        return _rewardPerShare();
    }

    /**
     * @notice Return weighted shares of user
     */
    function getUserShares(address user) public view returns (uint256) {
        uint256 userMembershipShares;
        for (uint256 i = 0; i < userInfo[user].membershipIds.length; i++) {
            userMembershipShares += _getMembershipShareValue(
                userInfo[user].membershipIds[i]
            );
        }
        unchecked {
            uint256 tokenShares = totalTokenShares == 0
                ? 0
                : (weightFactorTokens *
                    userInfo[user].tokens *
                    PRECISION_FACTOR) / totalTokenShares;

            uint256 membershipShares = totalMembershipShares == 0
                ? 0
                : (weightFactorMemberships *
                    userMembershipShares *
                    PRECISION_FACTOR) / totalMembershipShares;
            return
                (tokenShares + membershipShares) /
                (weightFactorMemberships + weightFactorTokens);
        }
    }

    function getStake(address user)
        external
        view
        returns (
            uint256,
            uint256[] memory,
            uint256,
            uint256
        )
    {
        return (
            userInfo[user].tokens,
            userInfo[user].membershipIds,
            totalTokenShares == 0 ? 0 : getUserShares(user),
            _calculatePendingRewards(user)
        );
    }

    function getMembershipsOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[user].membershipIds;
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}