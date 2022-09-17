/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IMintableERC20.sol



pragma solidity ^0.8.0;


interface IMintableERC20 is IERC20 {
    function mint(address destination, uint256 amount) external;
}
// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/libraries/Poolable.sol



pragma solidity ^0.8.0;
pragma abicoder v2;


/** @title Poolable.
@dev This contract manage configuration of pools
*/
abstract contract Poolable is Ownable {
    struct Pool {
        address collection; // nft collection
        uint256 lockDuration; // locked timespan
        uint256 minDuration; // min deposit timespan
        uint256 endRewardDate; // date to end the rewards
        uint256 rewardAmount; // amount rewarded when lockDuration is reached
    }

    // pools mapping
    uint256 public poolsLength;
    mapping(uint256 => Pool) private _pools;

    /**
     * @dev Emitted when a pool is created
     */
    event PoolAdded(uint256 poolIndex, Pool pool);

    /**
     * @dev Emitted when a pool is updated
     */
    event PoolUpdated(uint256 poolIndex, Pool pool);

    /**
     * @dev Modifier that checks that the pool at index `poolIndex` is open
     */
    modifier whenPoolOpened(uint256 poolIndex) {
        require(
            isPoolOpened(poolIndex),
            "Poolable: Pool is closed"
        );
        _;
    }

    /**
     * @dev Modifier that checks that the now() - `depositDate` is above or equal to the min lock duration for pool at index `poolIndex`
     */
    modifier whenUnlocked(uint256 poolIndex, uint256 depositDate) {
        require(isUnlocked(poolIndex, depositDate), "Poolable: Not unlocked");
        _;
    }

    function getPool(uint256 poolIndex) public view returns (Pool memory) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex];
    }

    function addPool(Pool calldata pool) external onlyOwner {
        uint256 poolIndex = poolsLength;

        _pools[poolIndex] = pool;
        poolsLength = poolsLength + 1;

        emit PoolAdded(poolIndex, _pools[poolIndex]);
    }

    function updatePool(uint256 poolIndex, Pool calldata pool) external onlyOwner {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        Pool storage editedPool = _pools[poolIndex];

        editedPool.lockDuration = pool.lockDuration;
        editedPool.minDuration = pool.minDuration;
        editedPool.endRewardDate = pool.endRewardDate;
        editedPool.rewardAmount = pool.rewardAmount;

        emit PoolUpdated(poolIndex, editedPool);
    }

    function closePool(uint256 poolIndex) external onlyOwner whenPoolOpened(poolIndex) {
        Pool storage editedPool = _pools[poolIndex];
        editedPool.endRewardDate = block.timestamp;

        emit PoolUpdated(poolIndex, editedPool);
    }

    function isUnlocked(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(depositDate < block.timestamp, "Poolable: Invalid deposit date");
        return block.timestamp - depositDate >= _pools[poolIndex].lockDuration;
    }

    function isUnlockable(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(depositDate < block.timestamp, "Poolable: Invalid deposit date");
        return block.timestamp - depositDate >= _pools[poolIndex].minDuration;
    }

    function isPoolOpened(uint256 poolIndex) public view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].endRewardDate == 0 || _pools[poolIndex].endRewardDate > block.timestamp;
    }

    function collectionForPool(uint256 poolIndex) public view returns (address) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].collection;
    }
}
// File: contracts/MetaObjectsStakingPool.sol



pragma solidity ^0.8.0;








/** @title MetaObjectsStakingPool
 */
contract MetaObjectsStakingPool is Ownable, Poolable , ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct PoolDeposit {
        address owner;
        uint64 pool;
        uint256 depositDate;
        uint256 claimed;
    }

    struct MultiStakeParam {
        uint256[] tokenIds;
        uint256 poolId;
    }

    IERC20 public rewardToken;

    // poolDeposit per collection and tokenId
    mapping(uint256 => mapping(address => mapping(uint256 => PoolDeposit))) private _deposits;
    // owners per collection and tokenId 
    mapping (address => mapping(address => mapping(uint256 => bool))) private _owners;

    // user rewards mapping
    mapping(address => uint256) private _userRewards;

    event Stake(address indexed account, uint256 poolId, address indexed collection, uint256 tokenId);
    event Unstake(address indexed account, address indexed collection, uint256 tokenId);

    event BatchStake(address indexed account, uint256 poolId, address indexed collection, uint256[] tokenIds);
    event BatchUnstake(address indexed account, address indexed collection, uint256[] tokenIds);

    event Claimed(address indexed account, address indexed collection, uint256 tokenId, uint256 rewards, uint256 pool);
    event ClaimedMulti(address indexed account, MultiStakeParam[] groups, uint256 rewards);

    constructor(IMintableERC20 _rewardToken) {
        rewardToken = _rewardToken;
    }

    function _sendRewards(address destination, uint256 amount) internal virtual {
        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance >= amount * 10**18) rewardToken.safeTransfer(destination, amount *10**18);
        else IMintableERC20(address(rewardToken)).mint(destination, amount * 10**18);
    }

    function _sendAndUpdateRewards(address account, uint256 amount) internal {
        if (amount > 0) {
            _userRewards[account] = _userRewards[account] + amount;
            _sendRewards(account, amount);
        }
    }

    function _getPendingRewardAmounts(PoolDeposit memory deposit, Pool memory pool) internal view returns (uint256) {
        uint256 reward = 0;
        uint256 dt = deposit.depositDate;

        while (dt != 0 && pool.lockDuration != 0) {
            dt += pool.lockDuration;
            if (dt > block.timestamp) break;
            reward += pool.rewardAmount;
            if (pool.endRewardDate != 0 && dt > pool.endRewardDate) break;
        }

        if (reward <= deposit.claimed) {
            return 0;
        }

        return reward - deposit.claimed;
    }

    function _stake(
        address account,
        address collection,
        uint256 tokenId,
        uint256 poolId
    ) internal {
        require(_deposits[poolId][collection][tokenId].owner == address(0), "Stake: Token already staked");
        require( IERC721(collection).ownerOf(tokenId) == account ," not owner of the Token");

        // add deposit
        _deposits[poolId][collection][tokenId] = PoolDeposit({
            owner: account,
            pool: uint64(poolId),
            depositDate: block.timestamp,
            claimed: 0
        });
    }


    /**
     * @notice Stake a token from the collection
     */
    function stake(uint256 poolId, uint256 tokenId) external nonReentrant whenPoolOpened(poolId) {
        address account = _msgSender();
        Pool memory pool = getPool(poolId);
        _stake(account, pool.collection, tokenId, poolId);
        emit Stake(account, poolId, pool.collection, tokenId);
    }

    function _unstake(
        address account,
        uint256 poolId,
        address collection,
        uint256 tokenId
    ) internal returns (uint256) {
        PoolDeposit storage deposit = _deposits[poolId][collection][tokenId];
        require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");
        require(IERC721(collection).ownerOf(tokenId) == account ," not owner of the Token");

        Pool memory pool = getPool(deposit.pool);
        uint256 rewards = _getPendingRewardAmounts(deposit, pool);
        if (rewards > 0) {
            deposit.claimed += rewards;
        }

        // update deposit
        delete _deposits[poolId][collection][tokenId];

        // transfer token
        //IERC721(collection).safeTransferFrom(address(this), account, tokenId);

        return rewards;
    }

    /**
     * @notice Unstake a token
     */
    function unstake(uint256 poolId,address collection, uint256 tokenId) external nonReentrant {
        require(_deposits[poolId][collection][tokenId].owner == _msgSender(), "Stake: Not owner of token");

        address account = _msgSender();
        uint256 rewards = _unstake(account,poolId, collection, tokenId);
        _sendAndUpdateRewards(account, rewards);

        emit Unstake(account, collection, tokenId);
    }

    function _restake(
        uint256 newPoolId,
        uint256 currPoolId,
        address collection,
        uint256 tokenId
    ) internal returns (uint256) {
        require(isPoolOpened(newPoolId), "Stake: Pool is closed");
        require(collectionForPool(newPoolId) == collection, "Stake: Invalid collection");
        require(newPoolId != currPoolId , "Stake: cannot stake - same pools selected");

        PoolDeposit storage deposit = _deposits[currPoolId][collection][tokenId];
        Pool memory oldPool = getPool(deposit.pool);

        require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");
        uint256 rewards = _getPendingRewardAmounts(deposit, oldPool);

        // update deposit
        deposit.pool = uint64(newPoolId);
        deposit.depositDate = block.timestamp;
        deposit.claimed = 0;

        return rewards;
    }

    /**
     * @notice Allow a user to [re]stake a token in a new pool without unstaking it first.
     */
    function restake(
        uint256 newPoolId,
        uint256 currPoolId,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        require(_deposits[currPoolId][collection][tokenId].owner != address(0), "Stake: Token not staked");
        require(_deposits[currPoolId][collection][tokenId].owner == _msgSender(), "Stake: Not owner of token");

        address account = _msgSender();
        uint256 rewards = _restake(newPoolId,currPoolId, collection, tokenId);
        _sendAndUpdateRewards(account, rewards);

        emit Unstake(account, collection, tokenId);
        emit Stake(account, newPoolId, collection, tokenId);
    }

    function _batchStake(
        address account,
        uint256 poolId,
        uint256[] memory tokenIds
    ) internal whenPoolOpened(poolId) {
        Pool memory pool = getPool(poolId);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(account,pool.collection, tokenIds[i], poolId);
        }

        emit BatchStake(account, poolId, pool.collection, tokenIds);
    }

    function _batchUnstake(
        address account,
        uint256 poolId,
        address collection,
        uint256[] memory tokenIds
    ) internal {
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[poolId][collection][tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards = rewards + _unstake(account,poolId, collection, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, collection, tokenIds);
    }

    function _batchRestake(
        address account,
        uint256 poolId,
        uint256 currPoolId,
        address collection,
        uint256[] memory tokenIds
    ) internal {
        uint256 rewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_deposits[currPoolId][collection][tokenIds[i]].owner == account, "Stake: Not owner of token");
            rewards += _restake(poolId,currPoolId, collection, tokenIds[i]);
        }
        _sendAndUpdateRewards(account, rewards);

        emit BatchUnstake(account, collection, tokenIds);
        emit BatchStake(account, poolId, collection, tokenIds);
    }

    /**
     * @notice Batch stake a list of tokens from the collection
     */
    function batchStake(uint256 poolId, uint256[] calldata tokenIds) external nonReentrant {
        _batchStake(_msgSender(), poolId, tokenIds);
    }

    /**
     * @notice Batch unstake tokens
     */
    function batchUnstake(address collection,uint256 poolId, uint256[] calldata tokenIds) external nonReentrant {
        _batchUnstake(_msgSender(),poolId, collection, tokenIds);
    }

    /**
     * @notice Batch restake tokens
     */
    function batchRestake(
        uint256 poolId,
        uint256 currPoolId,
        address collection,
        uint256[] calldata tokenIds
    ) external nonReentrant {
        _batchRestake(_msgSender(), poolId,currPoolId, collection, tokenIds);
    }

    function claim(uint256 poolId,address collection, uint256 tokenId) external nonReentrant {
        address account = _msgSender();
        PoolDeposit storage deposit = _deposits[poolId][collection][tokenId];
        require(deposit.owner == account, "Stake: Not owner of token");
        require(isUnlockable(deposit.pool, deposit.depositDate), "Stake: Not yet unstakable");

        Pool memory pool = getPool(deposit.pool);
        uint256 rewards = _getPendingRewardAmounts(deposit, pool);
        if (rewards > 0) {
            deposit.claimed += rewards;
        }

        _sendAndUpdateRewards(account, rewards);
        emit Claimed(account, collection, tokenId, rewards, deposit.pool);
    }

    
    /**
     * @notice Checks if a token has been deposited for enough time to get rewards
     */
    function isTokenUnlocked(uint256 poolId,address collection, uint256 tokenId) public view returns (bool) {
        require(_deposits[poolId][collection][tokenId].owner != address(0), "Stake: Token not staked");
        return isUnlocked(_deposits[poolId][collection][tokenId].pool, _deposits[poolId][collection][tokenId].depositDate);
    }

    /**
     * @notice Get the stake detail for a token (owner, poolId, min unstakable date, reward unlock date)
     */
    function getStakeInfo(uint256 inpoolId,address collection, uint256 tokenId)
        external
        view
        returns (
            address owner, // owner
            uint256 poolId, // poolId
            uint256 depositDate, // deposit date
            uint256 unlockDate, // unlock date
            uint256 rewardDate, // reward date
            uint256 totalClaimed // total claimed
        )
    {
        if (_deposits[inpoolId][collection][tokenId].owner == address(0)) {
            return (address(0), 0, 0, 0, 0, 0);
        }
        PoolDeposit memory deposit = _deposits[inpoolId][collection][tokenId];
        Pool memory pool = getPool(deposit.pool);
        return (
            deposit.owner,
            deposit.pool,
            deposit.depositDate,
            deposit.depositDate + pool.minDuration,
            deposit.depositDate + pool.lockDuration,
            deposit.claimed
        );
    }

    /**
     * @notice Returns the total reward for a user
     */
    function getUserTotalRewards(address account) external view returns (uint256) {
        return _userRewards[account];
    }

}