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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity 0.8.17;

/**
 * @title INFTBuyer
 * @author pbnather
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INFTBuyer {
    /* ============ Events ============ */

    event CollectionAdded(
        IERC721 indexed _collection,
        IERC20 _token,
        uint256 _price,
        uint256[] _ids
    );

    event CollectionIdsSet(
        IERC721 indexed _collection,
        uint256[] _ids,
        bool[] _allows
    );

    event CollectionAllowAllChanged(
        IERC721 indexed _collection,
        bool _allowAll
    );

    event CollectionPriceAndTokenChanged(
        IERC721 indexed _collection,
        uint256 _price,
        IERC20 _token
    );

    event NFTReceiverChanged(
        address indexed _oldNftReceiver,
        address indexed _newNftReceiver
    );

    event WithdrewTokens(IERC20 indexed _token, uint256 amount);

    event Redeemed(
        IERC721 indexed _collection,
        uint256 indexed _id,
        address indexed _user
    );

    /* ============ External Owner Functions ============ */

    /**
     * @notice Adds collection with specific ids, or all ids allowlisted.
     *
     * @dev If @param _allowAll is set to true, @param _ids has to be empty.
     * If @param _allowAll is set to false, @param _ids cannot be empty.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of allowlisted ids.
     * @param _allowAll Bool if all ids are allowlisted.
     * @param _token ERC20 token address that is paid for NFTs in the collection.
     * @param _price Price of the NFT in @param _token.
     */
    function addCollection(
        IERC721 _collection,
        uint256[] memory _ids,
        bool _allowAll,
        IERC20 _token,
        uint256 _price
    ) external;

    /**
     * @notice Set collection ids' state.
     *
     * @dev Collection's `allowAll` has to be false.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of collection ids.
     * @param _allows List of ids' allowed states in same order as @param _ids.
     */
    function setCollectionIds(
        IERC721 _collection,
        uint256[] memory _ids,
        bool[] memory _allows
    ) external;

    /**
     * @notice Set collection's `allowAll` state, if all ids are allowed.
     *
     * @dev Setting `allowAll` to true will clear `allowedList` and `allowed`.
     *
     * @param _collection Address of ERC721 collection.
     * @param _allowAll New `allowAll` state.
     */
    function setCollectionAllowAll(IERC721 _collection, bool _allowAll)
        external;

    /**
     * @notice Set collection's price per NFT and ERC20 token to payout.
     *
     * @param _collection Address of ERC721 collection.
     * @param _price Price of the NFT in @param _token.
     * @param _token ERC20 token address that is paid for NFTs in the collection.
     */
    function setCollectionPriceAndToken(
        IERC721 _collection,
        uint256 _price,
        IERC20 _token
    ) external;

    /**
     * @notice Set address that gets all the NFTs.
     *
     * @param _nftReceiver Address that gets all the NFTs.
     */
    function setNftReceiver(address _nftReceiver) external;

    /**
     * @notice Withdraws ERC20 token to the owner address.
     *
     * @param _token ERC20 token address to withdraw.
     */
    function withdrawTokens(IERC20 _token) external;

    /* ============ External Functions ============ */

    /**
     * @notice Redeem NFTs for the corresponding ERC20 tokens.
     *
     * @dev Will revert if any NFT won't redeem succesfully.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of ids to redeem.
     */
    function redeem(IERC721 _collection, uint256[] memory _ids) external;

    /* ============ External View Functions ============ */

    /**
     * @notice Returns length of the `collections` list.
     *
     * @dev First Collection is dummy one.
     *
     * @return length_ Length of the `collections` list.
     */
    function getCollectionsLength() external view returns (uint256 length_);

    /**
     * @notice Returns list of all collection addresses.
     *
     * @dev First dummy collection is ommited from the returned list.
     *
     * @return collections_ List of collection addresses.
     */
    function getAllCollectionAddresses()
        external
        view
        returns (address[] memory collections_);

    /**
     * @notice Returns all allowed ids from the given collection.
     *
     * @dev If @return allIds_ is true, all ids are allowed, and @return ids_ is empty.
     *
     * @param _collection Address of ERC721 collection.
     *
     * @return allIds_ Bool if all ids are allowlisted.
     * @return ids_ List of allowed ids.
     */
    function getAllowedCollectionIds(IERC721 _collection)
        external
        view
        returns (bool allIds_, uint256[] memory ids_);

    /**
     * @notice Returns price in ERC20 token for each NFT in the collection.
     *
     * @param _collection Address of ERC721 collection.
     *
     * @return token_ ERC20 token address that is paid for NFTs in the collection.
     * @return price_ Price of the NFT in @param _token.
     */
    function getCollectionPriceAndToken(IERC721 _collection)
        external
        view
        returns (IERC20 token_, uint256 price_);

    /**
     * @notice Returns if the given NFT id is allowlisted to redeem.
     *
     * @param _collection Address of ERC721 collection.
     * @param _id Id of the NFT in the @param _collection.
     *
     * @return allowed_ Bool if NFT with id @param _id is allowed.
     */
    function isNftAllowed(IERC721 _collection, uint256 _id)
        external
        view
        returns (bool allowed_);

    /**
     * @notice Returns list of NFT collection id's that the user has and are able to redeem.
     *
     * @dev Collection has to support IERC721Enumerable for this to work, otherwise it will revert.
     *
     * @param _collection Address of ERC721 collection.
     * @param _account User account address to check.
     *
     * @return ids_ List of collection IDs that the user has and that are allowed to redeem.
     */
    function getUserAllowedNfts(IERC721 _collection, address _account)
        external
        view
        returns (uint256[] memory ids_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title NFTBuyer
 * @author pbnather
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./interfaces/INFTBuyer.sol";

contract NFTBuyer is INFTBuyer, Ownable {
    using SafeERC20 for IERC20;

    /* ============ Structures ============ */

    struct Collection {
        IERC721 collectionAddress;
        IERC20 payoutToken;
        uint256 price;
        bool allowAll;
        mapping(uint256 => bool) allowed;
        uint256[] allowedList;
    }

    /* ============ State ============ */

    Collection[] public collections;
    mapping(address => uint256) public collectionIndexes;
    address public nftReceiver;

    /* ============ Constructor ============ */

    constructor(address _nftReceiver) {
        require(_nftReceiver != address(0));
        nftReceiver = _nftReceiver;
        collections.push();
    }

    /* ============ External Owner Functions ============ */

    /**
     * @notice Adds collection with specific ids, or all ids allowlisted.
     *
     * @dev If @param _allowAll is set to true, @param _ids has to be empty.
     * If @param _allowAll is set to false, @param _ids cannot be empty.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of allowlisted ids.
     * @param _allowAll Bool if all ids are allowlisted.
     * @param _token ERC20 token address that is paid for NFTs in the collection.
     * @param _price Price of the NFT in @param _token.
     */
    function addCollection(
        IERC721 _collection,
        uint256[] memory _ids,
        bool _allowAll,
        IERC20 _token,
        uint256 _price
    ) external onlyOwner {
        uint256 length = _ids.length;
        if (_allowAll) require(length == 0, "_allowAll is true, don't add ids");
        else require(length > 0, "_allowAll is false, specify ids");
        require(address(_token) != address(0), "Token address zero");
        require(address(_collection) != address(0), "Collection address zero");
        require(
            collectionIndexes[address(_collection)] == 0,
            "Collection already exists"
        );
        require(_price > 0, "Price is zero");

        collections.push();
        uint256 index = collections.length - 1;
        collectionIndexes[address(_collection)] = index;
        Collection storage collection = collections[index];
        collection.collectionAddress = _collection;
        collection.payoutToken = _token;
        collection.price = _price;
        collection.allowAll = _allowAll;
        for (uint256 i = 0; i < length; i++) {
            collection.allowed[_ids[i]] = true;
            collection.allowedList.push(_ids[i]);
        }

        emit CollectionAdded(_collection, _token, _price, _ids);
    }

    /**
     * @notice Set collection ids' state.
     *
     * @dev Collection's `allowAll` has to be false.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of collection ids.
     * @param _allows List of ids' allowed states in same order as @param _ids.
     */
    function setCollectionIds(
        IERC721 _collection,
        uint256[] memory _ids,
        bool[] memory _allows
    ) external onlyOwner {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        require(collection.allowAll != true, "Collection is in allAllow mode");
        uint256 length = _ids.length;
        for (uint256 i = 0; i < length; i++) {
            if (collection.allowed[_ids[i]] == _allows[i]) continue;
            collection.allowed[_ids[i]] = _allows[i];
            if (_allows[i]) collection.allowedList.push(_ids[i]);
            else _deleteIdFromCollection(collection, _ids[i]);
        }

        emit CollectionIdsSet(_collection, _ids, _allows);
    }

    /**
     * @notice Set collection's `allowAll` state, if all ids are allowed.
     *
     * @dev Setting `allowAll` to true will clear `allowedList` and `allowed`.
     *
     * @param _collection Address of ERC721 collection.
     * @param _allowAll New `allowAll` state.
     */
    function setCollectionAllowAll(IERC721 _collection, bool _allowAll)
        external
        onlyOwner
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        require(collection.allowAll != _allowAll, "State is same");
        collection.allowAll = _allowAll;
        if (_allowAll) {
            uint256 length = collection.allowedList.length;
            for (uint256 i = 0; i < length; i++) {
                collection.allowed[collection.allowedList[i]] = false;
            }
            delete collection.allowedList;
        }
        emit CollectionAllowAllChanged(_collection, _allowAll);
    }

    /**
     * @notice Set collection's price per NFT and ERC20 token to payout.
     *
     * @param _collection Address of ERC721 collection.
     * @param _price Price of the NFT in @param _token.
     * @param _token ERC20 token address that is paid for NFTs in the collection.
     */
    function setCollectionPriceAndToken(
        IERC721 _collection,
        uint256 _price,
        IERC20 _token
    ) external onlyOwner {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        require(_price > 0, "Price is zero");
        require(address(_token) != address(0), "Token is address zero");
        collection.price = _price;
        collection.payoutToken = _token;
        emit CollectionPriceAndTokenChanged(_collection, _price, _token);
    }

    /**
     * @notice Set address that gets all the NFTs.
     *
     * @param _nftReceiver Address that gets all the NFTs.
     */
    function setNftReceiver(address _nftReceiver) external onlyOwner {
        require(_nftReceiver != address(0), "New address is address zero");
        require(_nftReceiver != nftReceiver, "Address is same");
        address oldNftReceiver = nftReceiver;
        nftReceiver = _nftReceiver;
        emit NFTReceiverChanged(oldNftReceiver, _nftReceiver);
    }

    /**
     * @notice Withdraws ERC20 token to the owner address.
     *
     * @param _token ERC20 token address to withdraw.
     */
    function withdrawTokens(IERC20 _token) external onlyOwner {
        require(address(_token) != address(0), "Token is address zero");
        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "Cannot withdraw zero tokens");
        _token.safeTransfer(owner(), amount);
        emit WithdrewTokens(_token, amount);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Redeem NFTs for the corresponding ERC20 tokens.
     *
     * @dev Will revert if any NFT won't redeem succesfully.
     *
     * @param _collection Address of ERC721 collection.
     * @param _ids List of ids to redeem.
     */
    function redeem(IERC721 _collection, uint256[] memory _ids) external {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        for (uint256 i = 0; i < _ids.length; i++) {
            if (collection.allowAll || collection.allowed[_ids[i]]) {
                _redeemNft(collection, _ids[i]);
            } else {
                revert("NFT is not allowed");
            }
        }
    }

    /* ============ External View Functions ============ */

    /**
     * @notice Returns length of the `collections` list.
     *
     * @dev First Collection is dummy one.
     *
     * @return length_ Length of the `collections` list.
     */
    function getCollectionsLength() external view returns (uint256 length_) {
        length_ = collections.length;
    }

    /**
     * @notice Returns list of all collection addresses.
     *
     * @dev First dummy collection is ommited from the returned list.
     *
     * @return collections_ List of collection addresses.
     */
    function getAllCollectionAddresses()
        external
        view
        returns (address[] memory collections_)
    {
        uint256 length = collections.length;
        collections_ = new address[](length - 1);
        for (uint256 i = 1; i < length; i++) {
            collections_[i - 1] = address(collections[i].collectionAddress);
        }
    }

    /**
     * @notice Returns all allowed ids from the given collection.
     *
     * @dev If @return allIds_ is true, all ids are allowed, and @return ids_ is empty.
     *
     * @param _collection Address of ERC721 collection.
     *
     * @return allIds_ Bool if all ids are allowlisted.
     * @return ids_ List of allowed ids.
     */
    function getAllowedCollectionIds(IERC721 _collection)
        external
        view
        returns (bool allIds_, uint256[] memory ids_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        if (collection.allowAll) allIds_ = true;
        else {
            allIds_ = false;
            uint256 length = collection.allowedList.length;
            ids_ = new uint256[](length);
            for (uint256 i = 0; i < length; i++) {
                ids_[i] = collection.allowedList[i];
            }
        }
    }

    /**
     * @notice Returns price in ERC20 token for each NFT in the collection.
     *
     * @param _collection Address of ERC721 collection.
     *
     * @return token_ ERC20 token address that is paid for NFTs in the collection.
     * @return price_ Price of the NFT in @param _token.
     */
    function getCollectionPriceAndToken(IERC721 _collection)
        external
        view
        returns (IERC20 token_, uint256 price_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        token_ = collection.payoutToken;
        price_ = collection.price;
    }

    /**
     * @notice Returns if the given NFT id is allowlisted to redeem.
     *
     * @param _collection Address of ERC721 collection.
     * @param _id Id of the NFT in the @param _collection.
     *
     * @return allowed_ Bool if NFT with id @param _id is allowed.
     */
    function isNftAllowed(IERC721 _collection, uint256 _id)
        external
        view
        returns (bool allowed_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collection = collections[index];
        if (collection.allowAll) {
            allowed_ = true;
        } else if (collection.allowed[_id]) {
            allowed_ = true;
        } else {
            allowed_ = false;
        }
    }

    /**
     * @notice Returns list of NFT collection id's that the user has and are able to redeem.
     *
     * @dev Collection has to support IERC721Enumerable for this to work, otherwise it will revert.
     *
     * @param _collection Address of ERC721 collection.
     * @param _account User account address to check.
     *
     * @return ids_ List of collection IDs that the user has and that are allowed to redeem.
     */
    function getUserAllowedNfts(IERC721 _collection, address _account)
        external
        view
        returns (uint256[] memory ids_)
    {
        uint256 index = collectionIndexes[address(_collection)];
        require(index > 0, "Collection doesn't exist");
        Collection storage collectionInfo = collections[index];

        // Return empty array if user doesn't have nfts.
        uint256 nftBalance = _collection.balanceOf(_account);
        if (nftBalance == 0) return new uint256[](0);

        // Check if collection supports IERC721Enumerable extension.
        require(
            _collection.supportsInterface(type(IERC721Enumerable).interfaceId),
            "Collection not IERC721Enumerable"
        );

        IERC721Enumerable collection = IERC721Enumerable(address(_collection));
        uint256[] memory userNfts = new uint256[](nftBalance);

        if (collectionInfo.allowAll) {
            // Return all user NFTs.
            for (uint256 i = 0; i < nftBalance; i++) {
                userNfts[i] = collection.tokenOfOwnerByIndex(_account, i);
            }
            return userNfts;
        } else {
            // Filter NFTs to return.
            uint256 noAllowedIds = 0;
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 id = collection.tokenOfOwnerByIndex(_account, i);
                if (collectionInfo.allowed[id]) {
                    userNfts[noAllowedIds] = id;
                    noAllowedIds += 1;
                }
            }
            uint256[] memory userAllowedNfts = new uint256[](noAllowedIds);
            for (uint256 i = 0; i < noAllowedIds; i++) {
                userAllowedNfts[i] = userNfts[i];
            }
            return userAllowedNfts;
        }
    }

    /* ============ Private Functions ============ */

    /**
     * @dev Transfer tokens and NFTs, clear collections data if needed.
     *
     * @param _collection Collection struct from `collections` list.
     * @param _id Id of the NFT in the @param _collection.
     */
    function _redeemNft(Collection storage _collection, uint256 _id) private {
        require(
            _collection.payoutToken.balanceOf(address(this)) >=
                _collection.price,
            "Not enough tokens in the contract"
        );
        if (!_collection.allowAll) {
            _collection.allowed[_id] = false;
            _deleteIdFromCollection(_collection, _id);
        }
        _collection.collectionAddress.transferFrom(
            msg.sender,
            nftReceiver,
            _id
        );
        _collection.payoutToken.safeTransfer(msg.sender, _collection.price);
        emit Redeemed(_collection.collectionAddress, _id, msg.sender);
    }

    /**
     * @dev Deletes id from collection metadata
     *
     * @param _collection Collection struct from `collections` list.
     * @param _id Id of the NFT in the @param _collection.
     */
    function _deleteIdFromCollection(
        Collection storage _collection,
        uint256 _id
    ) private {
        for (uint256 i = 0; i < _collection.allowedList.length; i++) {
            if (_collection.allowedList[i] == _id) {
                _collection.allowedList[i] = _collection.allowedList[
                    _collection.allowedList.length - 1
                ];
                _collection.allowedList.pop();
                break;
            }
        }
    }
}