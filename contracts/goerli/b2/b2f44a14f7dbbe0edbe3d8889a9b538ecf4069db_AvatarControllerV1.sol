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

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/StringUtils.sol";
import "../nft/IBaseNFT.sol";
import "../resolver/IResolver.sol";
import "../registry/ICRS.sol";
import "../resolver/profile/IProxyConfigResolver.sol";

/**
 * @dev A registrar controller for registering and renewing names at fixed cost in gas coin.
 */
contract Controller is Ownable {
    using StringUtils for *;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    uint256 constant public MIN_REGISTRATION_DURATION = 28 days;
    uint256 constant public MIN_COMMITMENT_AGE = 60;
    uint256 constant public MAX_COMMITMENT_AGE = 86400;

    bytes4 constant public TOKEN_URI_SELECTOR = bytes4(keccak256("tokenURI(string)"));
    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string,uint256)") ^
        keccak256("available(string)") ^
        keccak256("makeCommitment(string,address,bytes32)") ^
        keccak256("commit(bytes32)") ^
        keccak256("register(string,address,uint256,bytes32)") ^
        keccak256("renew(string,uint256)")
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") ^
        keccak256("makeCommitmentWithConfig(string,address,bytes32,address,address)")
    );

    IBaseNFT public immutable base;
    ICRS public immutable crs;
    bytes32 public immutable baseNode;

    mapping(bytes32=>uint) public commitments;
    uint256 public maxLeasePeriod;

    event NameRegistered(string name, bytes32 indexed label, address indexed owner, address indexed token, uint cost, uint expires);
    event NameRenewed(string name, bytes32 indexed label, address indexed token, uint cost, uint expires);
    event PaymentReceived(address indexed payer, uint256 amount);
    event MaxLeaseChanged(address indexed owner, uint256 duration);

    /**
     * @dev Set NFT smart contract, price oracle and default settings.
     * @param _base Address of NFT smart contract.
     */
    constructor(IBaseNFT _base) Ownable() {
        base = _base;
        crs = _base.crs();
        baseNode = _base.baseNode();
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param _duration How long the name is being registered or extended for, in seconds.
     * @return The ERC20 token address (0 for gas token) and the price of this renewal.
     */
    function rentPrice(string memory _name, uint _duration) public view returns(address, uint) {
        bytes32 _baseNode = baseNode;
        (, uint256 _amount, address _token) = IResolver(crs.resolver(_baseNode)).royalty(_baseNode, address(this));
        
        uint256 _len = _name.strlen();
        if (_len == 4) {
            return (_token, _amount * _duration * 5);
        } else if (_len == 3) {
            return (_token, _amount * _duration * 10);
        } else if (_len == 2) {
            return (_token, _amount * _duration * 50);
        } else if (_len == 1) {
            return (_token, _amount * _duration * 250);
        }
        return (_token, _amount * _duration);
    }

    /**
     * @dev Check if name is longer than 1 symbol.
     * @param _name The name being registered or renewed.
     * @return true if valid.
     */
    function valid(string memory _name) public pure returns(bool) {
        return _name.strlen() >= 1;
    }

    /**
     * @dev Check if name is not registered already.
     * @param _name The name being registered or renewed.
     * @return true if available.
     */
    function available(string memory _name) public view returns(bool) {
        bytes32 _label = keccak256(bytes(_name));
        return valid(_name) && base.available(uint256(_label));
    }

    /**
     * @dev Ticket to reserve registration spot.
     * @param _name The name being registered.
     * @param _owner Address which will own the name.
     * @param _secret Secret to confirm commitment.
     * @return node hash of a new record.
     */
    function makeCommitment(string memory _name, address _owner, bytes32 _secret) public pure returns(bytes32) {
        return makeCommitmentWithConfig(_name, _owner, _secret, address(0), address(0));
    }

    /**
     * @dev Ticket to reserve registration spot with default resolver and address.
     * @param _name The name being registered.
     * @param _owner Address which will own the name.
     * @param _secret Secret to confirm ownership.
     * @param _resolver Resolver smart contract to store record data.
     * @param _addr Reverse record for an address.
     * @return node hash of a new record.
     */
    function makeCommitmentWithConfig(
        string memory _name,
        address _owner,
        bytes32 _secret,
        address _resolver,
        address _addr
    ) public pure returns(bytes32) {
        bytes32 _label = keccak256(bytes(_name));
        if (_resolver == address(0) && _addr == address(0)) {
            return keccak256(abi.encodePacked(_label, _owner, _secret));
        }
        require(_resolver != address(0), "resolver forbidden");
        return keccak256(abi.encodePacked(_label, _owner, _resolver, _addr, _secret));
    }

    /**
     * @dev Start registration process.
     * @param _commitment Reservation ticket.
     */
    function commit(bytes32 _commitment) public virtual {
        // solhint-disable not-rely-on-time
        require(commitments[_commitment] + MAX_COMMITMENT_AGE < block.timestamp, "expired commitment");
        // solhint-disable not-rely-on-time
        commitments[_commitment] = block.timestamp;
    }

    /**
     * @dev Finish registration process.
     * @param _name The name being registered.
     * @param _owner Address which will own the name.
     * @param _duration Seconds lease duration.
     * @param _secret Secret to confirm commitment.
     */
    function register(string calldata _name, address _owner, uint _duration, bytes32 _secret) external payable {
        registerWithConfig(_name, _owner, _duration, _secret, address(0), address(0));
    }

    /**
     * @dev Finish registration process, setting the resolver and address.
     * @param _name The name being registered.
     * @param _owner Address which will own the name.
     * @param _duration Lease duration in seconds.
     * @param _secret Secret to confirm commitment.
     * @param _resolver Resolver smart contract to store record data.
     * @param _addr Reverse record for an address.
     */
    function registerWithConfig(
        string memory _name,
        address _owner,
        uint _duration,
        bytes32 _secret,
        address _resolver,
        address _addr
    ) public payable {
        (address _paymentToken, uint _cost, uint _gasValue) = _consumeCommitment(
            _name,
            _duration,
            makeCommitmentWithConfig(_name, _owner, _secret, _resolver, _addr)
        );

        bytes32 _label = keccak256(bytes(_name));
        uint256 _tokenId = uint256(_label);

        // Store name on-chain to generate metadata.
        base.saveName(_name);

        uint _expires;
        if(_resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            _expires = _doRegistration(_tokenId, _duration, address(this), _gasValue);

            // The nodehash of this label
            bytes32 _nodehash = keccak256(abi.encodePacked(base.baseNode(), _label));

            // Set the resolver
            crs.setResolver(_nodehash, _resolver);

            // Configure the resolver
            if (_addr != address(0)) {
                IResolver(_resolver).setAddr(_nodehash, _addr);
            }

            // Now transfer full ownership to the expected owner
            base.reclaim(_tokenId, _owner);
            base.transferFrom(address(this), _owner, _tokenId);
        } else {
            require(_addr == address(0), "no reverse addr allowed");
            _expires = _doRegistration(_tokenId, _duration, _owner, _gasValue);
        }

        emit NameRegistered(_name, _label, _owner, _paymentToken, _cost, _expires);
    }

    /**
     * @dev Extend the lease of previously registered name.
     * @param _name The name being registered.
     * @param _duration Lease duration in seconds.
     */
    function renew(string calldata _name, uint _duration) external payable {
        bytes32 _label = keccak256(bytes(_name));
        uint256 _maxLeasePeriod = maxLeasePeriod;
        // solhint-disable not-rely-on-time
        require(_maxLeasePeriod == 0 || base.nameExpires(uint256(_label)) + _duration <= block.timestamp + maxLeasePeriod, "too long lease");
        
        (address _paymentToken, uint _cost) = rentPrice(_name, _duration);
        uint256 _gasValue = msg.value;
        if (_cost > 0) {
            if (_paymentToken == address(0)) {
                require(msg.value >= _cost, "payment failed");
                _gasValue -= _cost;
            } else {
                IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _cost);
            }
        }

        uint _expires;
        if (_gasValue == 0) {
            _expires = base.renew(uint256(_label), _duration);
        } else {
            (_expires) = abi.decode(address(base).functionCallWithValue(
                abi.encodeWithSignature("renew(uint256,uint256)", uint256(_label), _duration),
                _gasValue
            ), (uint256));
        }

        emit NameRenewed(_name, _label, _paymentToken, _cost, _expires);
    }

    /**
     * @dev Withdraw the fees in ERC20 or gas token.
     * @param _paymentToken ERC20 token address for withdrawal, address(0) for gas coin
     */
    function withdraw(address _paymentToken) external onlyOwner {
        if (_paymentToken == address(0)) {
            payable(msg.sender).sendValue(address(this).balance);     
        } else {
            address _me = address(this);
            uint256 _balance = IERC20(_paymentToken).balanceOf(_me);
            IERC20(_paymentToken).safeTransfer(msg.sender, _balance);
        }  
    }

    /**
     * @dev Can recieve gas token payments.
     */
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allow limitation of maximum lease period for early projects.
     * @param _maxLeasePeriod Maximum lease period in seconds, pass 0 to disable.
     */
    function adminMaxLeasePeriod(uint256 _maxLeasePeriod) external onlyOwner {
        maxLeasePeriod = _maxLeasePeriod;
        emit MaxLeaseChanged(msg.sender, _maxLeasePeriod);
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param _interfaceID Keccak of matched interface.
     * @return true if interface is implemented.
     */
    function supportsInterface(bytes4 _interfaceID) public virtual pure returns (bool) {
        return _interfaceID == INTERFACE_META_ID ||
               _interfaceID == COMMITMENT_CONTROLLER_ID ||
               _interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    /**
     * @dev Use commitment to register commited name.
     * @param _name The name being registered.
     * @param _duration Lease duration in seconds.
     * @param _commitment Commitment hash.
     * @return registration cost in wei or ERC20 token, remaining gas coin.
     */
    function _consumeCommitment(
        string memory _name,
        uint _duration,
        bytes32 _commitment
    ) internal returns (address, uint256, uint256) {
        // Require a valid commitment, if the commitment is too old, or the name is registered, stop
        uint256 _ts = commitments[_commitment];
        // solhint-disable not-rely-on-time
        uint256 _bts = block.timestamp;
        require(_ts + MIN_COMMITMENT_AGE <= _bts, "await maturation");
        require(_ts + MAX_COMMITMENT_AGE > _bts, "expired commitment");
        require(available(_name), "not available");

        delete commitments[_commitment];

        require(_duration >= MIN_REGISTRATION_DURATION, "min 1 month");
        uint256 _maxLeasePeriod = maxLeasePeriod;
        require(_maxLeasePeriod == 0 || _duration <= _maxLeasePeriod, "too long lease");

        (address _tokenAddr, uint _cost) = rentPrice(_name, _duration);
        if (_cost > 0) {
            if (_tokenAddr == address(0)) {
                require(msg.value >= _cost, "payment failed");
                return (_tokenAddr, _cost, msg.value - _cost);
            } else if (_cost > 0) {
                IERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _cost);
            }
        }
        return (_tokenAddr, _cost, msg.value);
    }

    /**
     * @dev Processed with registration.
     * @param _tokenId NFT id of CRS.
     * @param _duration Lease duration in seconds.
     * @param _owner Address to own NFT.
     * @param _gasValue Amount of gas coin to be paid.
     * @return expiration ts in seconds.
     */
    function _doRegistration(uint256 _tokenId, uint256 _duration, address _owner, uint256 _gasValue) internal returns(uint256) {
        if (_gasValue > 0) {
            (uint256 _expires) = abi.decode(payable(address(base)).functionCallWithValue(
                abi.encodeWithSignature("register(uint256,address,uint256)", _tokenId, _owner, _duration),
                _gasValue
            ), (uint256));
            return _expires;
        }
        return base.register(_tokenId, _owner, _duration);
    }
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

import "./Controller.sol";

/**
 * @dev Controller with whitelisting feature to protect namespace.
 */
contract GatedController is Controller {
    bytes4 constant private COMMITMENT_WITH_WHITELIST = bytes4(
        keccak256("commit(string,bytes32,bytes)") ^
        keccak256("isAllowed(address,string,bytes)") ^
        keccak256("getDomainSeparator()")
    );

    /// @dev Value returned by a call to `isAllowed` if the check
    /// was successful. The value is defined as:
    /// bytes4(keccak256("isAllowed(address,string,bytes)"))
    bytes4 internal constant MAGICVALUE = 0xe3500b28;

    /// @dev The EIP-712 domain type hash used for computing the domain
    /// separator.
    bytes32 internal constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 internal constant DOMAIN_NAME = keccak256("IdentityWhitelist");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 internal constant DOMAIN_VERSION = keccak256("v1");

    /// @dev The domain separator used for signing orders that gets mixed in
    /// making signatures for different domains incompatible. This domain
    /// separator is computed following the EIP-712 standard and has replay
    /// protection mixed in so that signed orders are only valid for specific
    /// contracts.
    bytes32 public immutable DOMAIN_SEPARATOR;

    bool public whitelistDisabled;
    mapping(address => bool) public validators;

    event ValidatorAdded(address indexed validator);
    event ValidatorRemoved(address indexed validator);
    event WhitelistStatusChanged(address owner, bool indexed status);

    constructor(IBaseNFT _base) Controller(_base) {
        // NOTE: Currently, the only way to get the chain ID in solidity is
        // using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPE_HASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                chainId,
                address(this)
            )
        );
    }

    /**
     * @dev Unpermissioned commitment is blocked while whitelist is active.
     *
     * @param _commitment Reservation ticket.
     */
    function commit(bytes32 _commitment) public override {
        require(whitelistDisabled, "use with whitelisting params");
        super.commit(_commitment);
    }

    /**
     * @dev Start registration process.
     *
     * @param _name Name for registration.
     * @param _commitment Reservation ticket.
     * @param _pass Whitelisting ticket.
     */
    function commit(string memory _name, bytes32 _commitment, bytes calldata _pass) public {
        require(isAllowed(msg.sender, _name, _pass) == MAGICVALUE, "not whitelisted");
        super.commit(_commitment);
    }

    /**
     * @dev Checks if user is whitelisted wallet.
     *
     * @param _user Address to check for whitelisting.
     * @param _name Whitelisted identity name.
     * @param _pass Digest of signed wallets.
     * @return 0xe3500b28 for success 0x00000000 for failure.
     */
    function isAllowed(
        address _user,
        string memory _name,
        bytes calldata _pass
    ) public view returns (bytes4) {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
        (_v, _r, _s) = abi.decode(_pass, (uint8, bytes32, bytes32));
        bytes32 _hash = keccak256(abi.encode(getDomainSeparator(), _user, _name));
        address _signer =
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                _v,
                _r,
                _s
            );

        if (validators[_signer]) return MAGICVALUE;
        return bytes4(0);
    }

    /**
     * @dev Get domain separator in scope of EIP-712.
     *
     * @return EIP-712 domain.
     */
    function getDomainSeparator() public virtual view returns(bytes32) {
        return DOMAIN_SEPARATOR;
    }

    /**
     * @dev Enable / disable whitelist protection.
     *
     * @param _status True to disable whitelist, false ot enable.
     */
    function toggleWhitelist(bool _status) external onlyOwner {
        whitelistDisabled = _status;
        emit WhitelistStatusChanged(msg.sender, _status);
    }

    /**
     * @dev Updated validator status.
     *
     * @param _validator Address of validator.
     */
    function addValidator(address _validator) external onlyOwner {
        validators[_validator] = true;
        emit ValidatorAdded(_validator);
    }

    /**
     * @dev Updated validator status.
     *
     * @param _validator Address of validator.
     */
    function removeValidator(address _validator) external onlyOwner {
        validators[_validator] = false;
        emit ValidatorRemoved(_validator);
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param _interfaceID Keccak of matched interface.
     * @return true if interface is implemented.
     */
    function supportsInterface(bytes4 _interfaceID) public override pure returns (bool) {
        return _interfaceID == COMMITMENT_WITH_WHITELIST || super.supportsInterface(_interfaceID);
    }
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

import "../registry/ICRS.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IBaseNFT is Ownable, IERC721 {
    uint constant public GRACE_PERIOD = 90 days;

    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
    event NameRenewed(uint256 indexed id, uint expires);

    /// The CRS registry
    ICRS public crs;

    /// The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    /// A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    /**
     * @dev Authorises a controller, who can register and renew domains.
     */
    function addController(address controller) virtual external;

    /**
     * @dev Revoke controller permission for an address.
     */
    function removeController(address controller) virtual external;

    /**
     * @dev Set the resolver for the TLD this registrar manages.
     */
    function setResolver(address resolver) virtual external;

    /**
     * @dev Returns the expiration timestamp of the specified label hash.
     */
    function nameExpires(uint256 id) virtual external view returns(uint);

    /**
     * @dev Returns true if the specified name is available for registration.
     */
    function available(uint256 id) virtual public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner, uint duration) virtual external payable returns(uint);

    /**
     * @dev Extend the lease.
     */
    function renew(uint256 id, uint duration) virtual external payable returns(uint);

    /**
     * @dev Reclaim ownership of a name in CRS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) virtual external;

    /**
     * @dev Change baseNode settings on the related resolver.
     */
    function setBasenodeResolverSettings(bytes calldata callData) virtual external returns (bool, bytes memory);

    /**
     * @dev Save name on-chain for metadata storage.
     */
    function saveName(string memory name) virtual external;
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

interface ICRS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./profile/IAddressResolver.sol";
import "./profile/INameResolver.sol";
import "./profile/ITextResolver.sol";
import "./profile/IContentHashResolver.sol";
import "./profile/IABIResolver.sol";
import "./profile/IInterfaceResolver.sol";
import "./profile/IPubkeyResolver.sol";
import "./profile/IRoyaltiesResolver.sol";
import "./profile/IProxyConfigResolver.sol";
import "./profile/IManagedResolver.sol";
import "./profile/IKeyHashResolver.sol";
import "./ISupportsInterface.sol";

/**
 * @dev A generic resolver interface which includes all the functions including the ones deprecated.
 */
interface IResolver is
    ISupportsInterface,
    IAddressResolver,
    INameResolver,
    ITextResolver,
    IContentHashResolver,
    IABIResolver,
    IInterfaceResolver,
    IPubkeyResolver,
    IRoyaltiesResolver,
    IProxyConfigResolver,
    IManagedResolver,
    IKeyHashResolver
{
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address a) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setName(bytes32 node, string calldata _name) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function setRoyalties(bytes32 node, address beneficiary, uint256 amount) external;
    function setProxyConfig(bytes32 node, address controller, bytes4 selector, address proxy) external;
    function setRole(bytes32 node, bytes4 roleSig, address manager, bool active) external;
    function setKeyHash(bytes32 node, bytes4 key, bytes32 keyhash) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupportsInterface {
    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    
    /**
     * @dev Returns the ABI associated with an ENS node.
     *      Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Interface for addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    /**
     * @dev Returns the address associated with a CRS node.
     * @param node The CRS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * @dev Returns the contenthash associated with a CRS node.
     * @param node The CRS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * @dev Returns the address of a contract that implements the specified interface for this name.
     *      If an implementer has not been set for this interfaceID and name, the resolver will query
     *      the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     *      contract implements EIP165 and returns `true` for the specified interfaceID, its address
     *      will be returned.
     * @param node The CRS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeyHashResolver {
    event KeyHashChanged(bytes32 indexed node, bytes4 indexed key, bytes32 keyhash);

    /**
     * @dev Returns the hash associated with a CRS node for a key.
     * @param node The CRS node to query.
     * @param key bytes4 signature of a key generated like bytes4(keccak256("KEY")).
     * @return The associated hash.
     */
    function keyHash(bytes32 node, bytes4 key) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IManagedResolver {
    event RoleChanged(
        bytes32 indexed node,
        bytes4 indexed roleSig,
        address indexed manager,
        bool active
    );

    /**
     * @dev Check if manager address has some role.
     * @param _node the node to update.
     * @param _roleSig bytes4 signature of a role generated like bytes4(keccak256("ROLE_NAME")).
     * @param _manager address which will get the role.
     * @return true if manager address has role.
     */
    function hasRole(bytes32 _node, bytes4 _roleSig, address _manager) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * @dev Returns the name associated with a CRS node, for reverse records.
     *      Defined in EIP181.
     * @param node The CRS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyConfigResolver {
    event ProxyConfigChanged(bytes32 indexed node, address indexed controller, bytes4 indexed selector, address proxy);

    /**
     * @dev Returns proxy contract address which resolves into some content.
     * @param node The CRS node to query.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @return Address which implements proxy interface.
     */
    function proxyConfig(bytes32 node, address controller, bytes4 selector) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * @dev Returns the SECP256k1 public key associated with a CRS node.
     *      Defined in EIP 619.
     * @param node The CRS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltiesResolver {
    event RoyaltiesChanged(
        bytes32 indexed node,
        address indexed beneficiary,
        uint256 amount,
        address token,
        address indexed forAddress
    );

    /**
     * @dev Returns the royalties associated with a CRS node.
     * @param node The CRS node to query
     * @param addr Specific address for which royalties apply, address(0) for any address.
     * @return beneficiary address for royalties.
     * @return amount of roylties.
     * @return token, address(0) for gas coin
     */
    function royalty(bytes32 node, address addr) external view returns (address, uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string value);

    /**
     * Returns the text data associated with a CRS node and key.
     * @param node The CRS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@le7el/web3_crs/contracts/controller/GatedController.sol";

contract AvatarControllerV1 is GatedController {
    constructor (IBaseNFT _base) GatedController(_base) {}
}