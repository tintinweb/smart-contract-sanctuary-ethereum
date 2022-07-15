/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

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

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: contracts/scBeneficiary.sol


pragma solidity ^0.8.8;



 

abstract contract ScotchBeneficiary is Ownable {
  using SafeERC20 for IERC20;

   // Beneficiary (commission recipient) Mode
  enum BeneficiaryMode{
    // 0: No Beneficiary Specified
    None,
    // 1: Beneficiary - simple the recipient address
    Beneficiary,
    // 2: Distributor - the service to distribute money
    Distributor
  }

  // Beneficiary Model
  struct Beneficiary {
    BeneficiaryMode mode;       // mode of the beneficiary send funds
    address payable recipient;  // beneficiary recipient address
  }

  // beneficiary - receiver of the funds - the address where the funds will be sent
  Beneficiary internal _beneficiary;


  // ===========================================
  // ======= Secondary public functions ========
  // ===========================================

  // get current beneficiary info
  function getBeneficiary() public view returns (Beneficiary memory) {
    return _beneficiary;
  }


  // ===========================================
  // =========== Owner's functions =============
  // ===========================================

  // change beneficiary of the Scotch Marketplace
  function changeBeneficiary(BeneficiaryMode mode, address payable recipient) public virtual onlyOwner {
    if (mode == BeneficiaryMode.None)
      require(recipient == address(0), "Beneficiar mode None requires zero address for recipient!");
    else
      require(recipient != address(0), "Beneficiary recipient address should be specified!");

    _beneficiary.mode = mode;
    _beneficiary.recipient = recipient;
  }

  // send accumulated funds to recipient (native-token = zero tokenContract)
  function sendFunds(uint256 amount, address tokenContract) public virtual onlyOwner {
    require(_isBeneficiaryExists(), "Beneficiary should be specified!");
    require(amount > 0, "Send Amount should be positive!");

    // address of the current contract
    address current = address(this);

    if (tokenContract == address(0)) {
      // get Scotch Marketplace balance in native token
      uint256 balance = current.balance;
      require(balance >= amount, "Send Amount exceeds Smart Contract's native token balance!");

      // send native token amount to _beneficiar
      _beneficiary.recipient.transfer(amount);
    }
    else {
      // get ERC-20 Token Contract
      IERC20 hostTokenContract = IERC20(tokenContract);
      // get Scotch Marketplace balance in ERC-20 Token
      uint256 balance = hostTokenContract.balanceOf(current);
      require(balance >= amount, "Send Amount exceeds Smart Contract's ERC-20 token balance!");
      // send ERC-20 token amount to recipient
      hostTokenContract.transfer(_beneficiary.recipient, amount);
    }
  }

  // ===========================================
  // ======= Internal helper functions =========
  // ===========================================

  // check if beneficiary is specified to send funds
  function _isBeneficiaryExists() internal view virtual returns (bool){
    return _beneficiary.mode != BeneficiaryMode.None && _beneficiary.recipient != address(0);
  }

   // charge funds from caller in native tokens
  function _chargeFunds(uint256 amount, string memory message) internal virtual {
    if (amount > 0) {
      // check payment for appropriate funds amount
      require(msg.value >= amount, message);

      // send funds to _beneficiary
      if (_isBeneficiaryExists())
        _beneficiary.recipient.transfer(msg.value);
    }
  }
}

// File: contracts/iDistributor.sol


pragma solidity ^0.8.8;

interface IDistributor {
    function distribute(uint256 marketItemId) external payable;
}
// File: contracts/scMarketplace.sol


pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;






// V1.8
contract ScotchMarketplace is ScotchBeneficiary, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Market-Item Status
  enum MarketItemStatus {
    // 0: market-item is active and can be sold
    Active,
    // 1: market-item is already sold
    Sold,
    // 2: market-item is cancelled by NFT owner
    Cancelled,
    // 3: market-item is deleted by Scotch owner
    Deleted
  }

  // input for market-item placement
  struct MarketItemInput {
    address tokenContract;
    uint256 tokenId;
    address priceContract;
    uint256 priceAmount;
    address[] whiteList;
  }

  // Market-Rate structure
  struct MarketRate {
    bool isActive;         // is market-rate active (is valid for specific address)
    uint256 listingPrice;  // listing price of a new market-item (for seller to create market-item)
    uint256 cancelPrice;   // the price for cancelling market-item on the market (by NFT owner)
    uint feePercent;       // fee % to charge from market-item price (seller will receive (100-feePercent)/100 * price)
  }

  // Market-Item structure
  struct MarketItem {
    uint256 itemId;           // id of the market-item
    address tokenContract;    // original (sellable) NFT token contract address
    uint256 tokenId;          // original (sellable) NFT token Id
    address payable seller;   // seller of the original NFT
    address payable buyer;    // buyer of the market-item - new owner of the sellable NFT
    address priceContract;    // ERC-20 price token address (Zero address => native token)
    uint256 price;            // price = amount of ERC-20 (or native token) price tokens to buy market-item
    MarketItemStatus status;  // status of the market-item
    uint256 fee;              // amount of fee (in ERC-20 price tokens) that were charged during the sale
    uint256 position;         // positive position in active market-items array (1..N)
    uint partnerId;           // Id of the partner, from which the sale was made
    address[] whiteList;      // white list of addresses that could buy market-item
  }

  // Events of Marketplace
  event MarketItemPlaced(uint256 indexed marketItemId, address indexed tokenContract, uint256 tokenId, address indexed seller, address priceContract, uint256 price);
  event MarketItemSold(uint256 indexed marketItemId, address indexed buyer);
  event MarketItemRemoved(uint256 indexed marketItemId, MarketItemStatus status);


  // counter for market items Id
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;

  // collection of market-items
  mapping(uint256 => MarketItem) private _items;

  // active-market-items collection - collection of active market-items ids only
  uint256[] private _activeItems;

  // mapping of (Token Contract, TokenID) => Active Position
  mapping(address => mapping(uint256 => uint256))  private _activeTokens;

  // collection of market-rates
  mapping(address => MarketRate) private _rates;

  // mapping of (marketItemID, buyer address) => allowed to buy flag
  mapping(uint256 => mapping(address => bool))  private _allowedToBuy;

  // maximal amount of items, that could be sold in one transaction
  uint public _maxItemsForSale;



  constructor() {
    _beneficiary = Beneficiary(BeneficiaryMode.None, payable(address(0)));
    _activeItems = new uint256[](0);
    _rates[address(0)] = MarketRate(true, 0, 0, 3);
    _maxItemsForSale = 100;
  }

  // ===========================================
  // ======= Scotch Marketplace modifiers ======
  // ===========================================

  modifier idExists(uint256 marketItemId) {
    require(marketItemId > 0 && marketItemId <= _itemIds.current(), "Invalid Market Item ID!");
    _;
  }

  modifier isActive(uint256 marketItemId) {
    require(_items[marketItemId].status == MarketItemStatus.Active, "Market Item is not Active");
    _;
  }

  // ===========================================
  // ==== MAIN Scotch Marketplace functions ====
  // ===========================================

  // create new market-item - listing of original NFT on Marketplace
  function placeMarketItem(address tokenContract, uint256 tokenId, address priceContract, uint256 price, address[] memory whiteList) public payable {
    require(price > 0, "Price must be positive (at least 1 wei)");

    // check if token is already placed in the market
    uint256 existingMarketItemId = findActiveMarketItem(tokenContract, tokenId);
    require(existingMarketItemId == 0, "That token is already placed on the market");

    // seller of the Token
    address seller = _msgSender();

    // token validation
    int validation = _checkTokenValidity(seller, tokenContract, tokenId);
    require(validation != - 1, "Only owner of the NFT can place it to the Marketplace");
    require(validation != - 2, "NFT should be approved to the Marketplace");
    require(validation == 0, "NFT is not valid to be sold on the Marketplace");

    // market-rate for seller
    uint256 listingPrice = _getValidRate(seller).listingPrice;

    // charge listing-price from seller
    _chargeFunds(listingPrice, "Listing Price should be sent to place NFT on the Marketplace");

    // build market-item input
    MarketItemInput memory input = MarketItemInput(tokenContract, tokenId, priceContract, price, whiteList);

    // create market-item
    _createMarketItem(seller, input);
  }

  function placeMarketItems(MarketItemInput[] memory input) public payable {
    require(input.length > 0, "At least one item input should be specified");
    require(input.length <= _maxItemsForSale, "Amount of specified items exceeds Maximum Allowed Amount");

    // seller of the Token
    address seller = _msgSender();

    // market-rate for seller
    uint256 listingPrice = _getValidRate(seller).listingPrice;

    // charge listing-price from seller
    _chargeFunds(listingPrice * input.length, "Listing Price should be sent to place NFT on the Marketplace");

    for (uint i = 0; i < input.length; i++)
    {
      require(input[i].priceAmount > 0, "Price must be positive (at least 1 wei)");

      // check if token is already placed in the market
      uint256 existingMarketItemId = findActiveMarketItem(input[i].tokenContract, input[i].tokenId);
      require(existingMarketItemId == 0, "That token is already placed on the market");

      // token validation
      int validation = _checkTokenValidity(seller, input[i].tokenContract, input[i].tokenId);
      require(validation != - 1, "Only owner of the NFT can place it to the Marketplace");
      require(validation != - 2, "NFT should be approved to the Marketplace");
      require(validation == 0, "NFT is not valid to be sold on the Marketplace");

      // create market-item
      _createMarketItem(seller, input[i]);
    }
  }

  // make deal on sell market-item, receive payment and transfer original NFT
  function makeMarketSale(uint256 marketItemId, uint partnerId) public payable idExists(marketItemId) isActive(marketItemId) nonReentrant {
    // address of the buyer for nft
    address buyer = _msgSender();
    // address of the market-item seller
    address payable seller = _items[marketItemId].seller;
    // original nft tokenId
    uint256 tokenId = _items[marketItemId].tokenId;

    // nft token contract && approval for nft
    IERC721 hostTokenContract = IERC721(_items[marketItemId].tokenContract);
    bool allApproved = hostTokenContract.isApprovedForAll(seller, address(this));
    if (!allApproved) {
      address approvedAddress = hostTokenContract.getApproved(tokenId);
      require(approvedAddress == address(this), "Market Item (NFT) should be approved to the Marketplace");
    }

    // check white-list if it was set up
    if (_items[marketItemId].whiteList.length > 0)
      require(_allowedToBuy[marketItemId][buyer] == true, "Your address is not specified in White-List for current Market Item");

    // charge price from seller & send to buyer & beneficiary
    uint256 feeAmount = _chargePrice(marketItemId, buyer);

    // update market-item info
    _items[marketItemId].buyer = payable(buyer);
    _items[marketItemId].fee = feeAmount;
    _items[marketItemId].partnerId = partnerId;

    // transfer original nft from seller to buyer
    hostTokenContract.safeTransferFrom(seller, buyer, tokenId);

    // remove market-item with Sold status
    _removeMarketItem(marketItemId, MarketItemStatus.Sold);

    // if beneficiary 'Distributor' mode specified => call distribute method for current marketItemId
    if (_beneficiary.mode == BeneficiaryMode.Distributor && _beneficiary.recipient != address(0))
    {
      // build distributor Host Contract
      IDistributor distributorHost = IDistributor(_beneficiary.recipient);
      distributorHost.distribute(marketItemId);
    }

    emit MarketItemSold(marketItemId, buyer);
  }

  // cancel market-item placement on Scotch Marketplace
  function cancelMarketItem(uint256 marketItemId) public payable idExists(marketItemId) isActive(marketItemId) nonReentrant {
    // address of the market-item seller
    address payable seller = _items[marketItemId].seller;
    // check market-item Seller is cancelling the market-item
    require(_msgSender() == seller, "Only Seller can cancel Market Item");
    // market-rate for seller
    uint256 cancelPrice = _getValidRate(seller).cancelPrice;

    // charge cancel-price from seller
    _chargeFunds(cancelPrice, "Cancel Price should be sent to cancel NFT placement on the Marketplace");

    // remove market-item with Cancelled status
    _removeMarketItem(marketItemId, MarketItemStatus.Cancelled);
  }


  // ===========================================
  // ======= Secondary public functions ========
  // ===========================================

  // get Rate for sender address
  function getRate() public view returns (MarketRate memory) {
    return _getValidRate(_msgSender());
  }

  // get market-item info by id
  function getMarketItem(uint256 marketItemId) public view idExists(marketItemId) returns (MarketItem memory) {
    return _items[marketItemId];
  }

  // get count of all market-items
  function getAllMarketItemsCount() public view returns (uint256) {
    return _itemIds.current();
  }

  // get count of active (not sold and not removed) market-items
  function getActiveMarketItemsCount() public view returns (uint256) {
    return _activeItems.length;
  }

  // get active active market-item by index (1 based)
  function getActiveMarketItem(uint256 position) public view returns (MarketItem memory) {
    require(_activeItems.length > 0, "There are no any Active Market Items yet!");
    require(position >= 1 && position <= _activeItems.length, "Position should be positive number in Active Market Items Count range (1..N)");
    return _items[_activeItems[position - 1]];
  }

  // find existing active market-item by tokenContract & tokenId
  function findActiveMarketItem(address tokenContract, uint256 tokenId) public view returns (uint256) {
    return _activeTokens[tokenContract][tokenId];
  }


  // ===========================================
  // =========== Owner's functions =============
  // ===========================================

  // set maximum amount of items that could be sold
  function setMaxItemsForSale(uint maxItemsForSale) public onlyOwner {
    _maxItemsForSale = maxItemsForSale;
  }

  // get Rate for specific address
  function getCustomRate(address adr) public view onlyOwner returns (MarketRate memory){
    return _getCustomRate(adr);
  }

  // set market-rate for specific address
  function setCustomRate(address adr, uint256 newListingPrice, uint256 newCancelPrice, uint newFeePercent) public onlyOwner {
    _rates[adr] = MarketRate(true, newListingPrice, newCancelPrice, newFeePercent);
  }

  // remove market-rate for specific address
  function removeCustomRate(address adr) public onlyOwner {
    if (adr == address(0))
      return;

    delete _rates[adr];
  }

  // remove market-item placement on Scotch Marketplace
  function deleteMarketItem(uint256 marketItemId) public onlyOwner idExists(marketItemId) isActive(marketItemId) nonReentrant {
    // remove market-item with Deleted status
    _removeMarketItem(marketItemId, MarketItemStatus.Deleted);
  }


  // ===========================================
  // ======= Internal helper functions =========
  // ===========================================
  // get Rate for specific address
  function _getCustomRate(address adr) private view returns (MarketRate memory) {
    return _rates[adr];
  }

  // get Rate for specific address
  function _getValidRate(address adr) private view returns (MarketRate memory) {
    // get active market-rate for specific address
    if (_rates[adr].isActive)
      return _rates[adr];

    // return default market-rate
    return _rates[address(0)];
  }

  // check if original NFT is valid to be placed on Marketplace
  function _checkTokenValidity(address seller, address tokenContract, uint256 tokenId) private view returns (int) {
    IERC721 hostTokenContract = IERC721(tokenContract);

    // get owner of the NFT (seller should be the owner of the NFT)
    address tokenOwner = hostTokenContract.ownerOf(tokenId);
    if (tokenOwner != seller)
      return - 1;

    // check approval for all
    bool allApproved = hostTokenContract.isApprovedForAll(seller, address(this));
    if (!allApproved)
    {
      // get approved address of the NFT (NFT should be approved to Marketplace)
      address tokenApproved = hostTokenContract.getApproved(tokenId);
      if (tokenApproved != address(this))
        return - 2;
    }

    return 0;
  }

  // add new MaketItem to Marketplace
  function _createMarketItem(address seller, MarketItemInput memory input) private {
    // new market-item ID
    _itemIds.increment();
    uint256 marketItemId = _itemIds.current();

    // push active market-item in array
    _activeItems.push(marketItemId);
    // position in active market-item array
    uint256 position = _activeItems.length;

    // create new market-item
    _items[marketItemId] = MarketItem(
      marketItemId, // ID of the market item
      input.tokenContract, // token Contract
      input.tokenId, // token ID
      payable(seller), // seller
      payable(address(0)), // buyer
      input.priceContract, // price Contract
      input.priceAmount, // price value
      MarketItemStatus.Active, // status
      0, // fee value
      position, // position
      0, // partnerId
      input.whiteList           // white list
    );

    // update token position to active market-item position
    _activeTokens[input.tokenContract][input.tokenId] = position;

    // setup white list for market item
    if (input.whiteList.length > 0)
    {
      for (uint i; i < input.whiteList.length; i++)
        _allowedToBuy[marketItemId][input.whiteList[i]] = true;
    }

    emit MarketItemPlaced(marketItemId, input.tokenContract, input.tokenId, seller, input.priceContract, input.priceAmount);
  }

  // remove market-item from marketplace
  function _removeMarketItem(uint256 marketItemId, MarketItemStatus status) private idExists(marketItemId) isActive(marketItemId) {
    // define index of market-item in active array
    uint index = _items[marketItemId].position - 1;
    // check market-item has position in active-market-item array
    require(index >= 0 && index < _activeItems.length, "Market Item has no position in Active Items array");
    // check market-item position in active-market-items array
    require(_activeItems[index] == marketItemId, "Market Item is not on the position in Active Items array!");
    // check that new status should NOT be Active
    require(status != MarketItemStatus.Active, "Specify correct status to remove Market Item!");

    // update market-item status & position
    _items[marketItemId].status = status;
    _items[marketItemId].position = 0;

    // replacing current active-market-item with last element
    if (index < _activeItems.length - 1) {
      // define last active-market-item ID
      uint256 lastItemId = _activeItems[_activeItems.length - 1];
      // replacing with last element
      _activeItems[index] = lastItemId;
      // update last active-market-item position
      _items[lastItemId].position = index + 1;
      _activeTokens[_items[lastItemId].tokenContract][_items[lastItemId].tokenId] = index + 1;
    }

    // remove last element from array = deleting item in array
    _activeItems.pop();

    // remove token position for current market-item
    delete _activeTokens[_items[marketItemId].tokenContract][_items[marketItemId].tokenId];

    emit MarketItemRemoved(marketItemId, status);
  }


  // charge price and fees during the deal
  function _chargePrice(
    uint256 marketItemId,
    address buyer)
  private returns (uint256) {
    // address of the market-item seller
    address payable seller = _items[marketItemId].seller;
    // price amount
    uint256 priceAmount = _items[marketItemId].price;
    // price contract
    address priceContract = _items[marketItemId].priceContract;


    // market-rate for seller
    uint feePercent = _getValidRate(seller).feePercent;
    // commission fee amount
    uint256 feeAmount = feePercent * priceAmount / 100;

    // amount that should be send to Seller
    uint256 sellerAmount = priceAmount - feeAmount;
    require(sellerAmount > 0, "Invalid Seller Amount calculated!");


    // charge price and fees in Native Token
    if (priceContract == address(0))
    {
      require(msg.value >= priceAmount, "Please submit the Price amount in order to complete the purchase");

      // transfer seller-amount to seller
      seller.transfer(sellerAmount);

      // send fee funds to _beneficiary
      if (_isBeneficiaryExists() && feeAmount > 0)
        _beneficiary.recipient.transfer(feeAmount);
    }
    // charge price and fees in ERC20 Token
    else
    {
      // address of the Scotch Marketplace
      address marketplace = address(this);

      // check price amount allowance to marketplace
      IERC20 hostPriceContract = IERC20(priceContract);
      uint256 priceAllowance = hostPriceContract.allowance(buyer, marketplace);
      require(priceAllowance >= priceAmount, "Please allow Price amount of ERC-20 Token in order to complete purchase");

      // transfer price amount to marketplace
      hostPriceContract.safeTransferFrom(buyer, marketplace, priceAmount);

      // transfer seller-amount to seller
      hostPriceContract.transfer(seller, sellerAmount);

      // send fee funds to _beneficiary
      if (_isBeneficiaryExists() && feeAmount > 0)
        hostPriceContract.transfer(_beneficiary.recipient, feeAmount);
    }

    return feeAmount;
  }
}