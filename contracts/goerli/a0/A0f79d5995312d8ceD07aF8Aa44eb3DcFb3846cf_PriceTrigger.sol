// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../triggers/TriggerTypes.sol";
import "../utils/assets/TokenLib.sol";

struct ActionRuntimeParams {
    TriggerReturn[] triggerReturnArr;
    uint256[] collaterals;
}

struct Action {
    address callee; // eg. swapUni
    bytes data; // any custom param to send to the callee, encoded at compileTime
    Token[] inputTokens; // token to be used to initiate the action
    Token[] outputTokens; // token to be gotten as output
}

struct ActionConstraints {
    uint256 expiry; // this action will revert if used after this time
    uint256 activation; // this action will revert if used before this time
}

struct Position {
    // metadata that can optionally be used to indicate constraints that bound the actions
    // This can be be used by the smart contract to decide whether this position is acceptable
    // The constraints should match the index order of the nextActions
    ActionConstraints[] actionConstraints;
    // A list of actions that can be taken as next-steps to this action.
    // the next step in this action (which will typically be to close an open position).
    // Taking ANY of these actions will result in this position being closed.
    Action[] nextActions;
}

struct ActionResponse {
    //array of amounts with datatype.
    uint256[] tokenOutputs; // idx if ERC721, amount if erc20 or native
    // In future, we may have non-token outputs to be interpreted by the receiver
    // bytes otherOutputs;

    // The position should provide an exhaustive list of actions that can be used to close
    // the position for a given action. Otherwise, a position might end up being closed, but the
    // contract wouldnt know and will keep it marked pending.
    Position position;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TriggerTypes.sol";

interface ITrigger {
    // Returns true if Action needs to be called
    // Returns a uint to be fed to Actions call
    function check(Trigger calldata trigger) external view returns (bool, TriggerReturn memory);

    // Used during addition of a trigger.
    // Reverts if trigger.fields don't make sense.
    function validate(Trigger calldata trigger) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ITrigger.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../utils/Utils.sol";

contract PriceTrigger is ITrigger, Ownable {
    // keyword -> fn call to get data
    // if we know how to get the value, then it can be a trigger. so this serves as a list of allowed triggers

    // TODO We might need to have multiple feeds and reconcile them.
    mapping(address => address) priceFeeds;

    constructor() {}

    function addPriceFeed(address asset, address dataSource) external onlyOwner {
        priceFeeds[asset] = dataSource;
    }

    // This is always against USD
    // Assume decimals = 8 (i.e. 1 USD = 1e8), because this is true for all USD feeds as of this writing
    // Note, we're not using ASSET/ETH price even if they're available. We're always doing a ETH/USD separately and changing the denominator.
    function _getPrice(address asset) private view returns (uint256) {
        require(priceFeeds[asset] != address(0));
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeeds[asset]);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price >= 0, "price is negative!");
        return uint256(price); // WARNING: feels icky. Why did they not use uint?
    }

    function validate(Trigger calldata trigger) external view returns (bool) {
        require(trigger.triggerType == TriggerType.Price);
        (address asset1, , , ) = decodePriceTriggerCreateTimeParams(trigger.createTimeParams);
        require(priceFeeds[asset1] != address(0), "asset1 unauthorized");
        return true;
    }

    // See note on _getPrice to see why we don't need a _scale function as seen in
    // https://docs.chain.link/docs/get-the-latest-price/#getting-a-different-price-denomination
    function check(Trigger calldata trigger) external view returns (bool, TriggerReturn memory) {
        // get the val of var, so we can check if it matches trigger
        (address asset1, address asset2, Ops op, uint256 val) = decodePriceTriggerCreateTimeParams(
            trigger.createTimeParams
        );

        uint256 asset1price = _getPrice(asset1);
        uint256 res;

        if (asset2 == Constants.USD) {
            res = asset1price; // decimals is 10**8
        } else {
            uint256 asset2price = _getPrice(asset2);
            res = (asset1price * 10**8) / asset2price; // Keeping the decimals at 10**8
        }

        TriggerReturn memory runtimeData = TriggerReturn({
            triggerType: trigger.triggerType,
            runtimeData: abi.encode(asset1, asset2, res)
        });

        if (op == Ops.GT) {
            return (res > val, runtimeData);
        } else if (op == Ops.LT) {
            return (res < val, runtimeData);
        } else {
            revert("Ops not handled!");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Ops {
    GT,
    LT
}

enum TriggerType {
    NULL,
    Price,
    Timestamp
}

struct Trigger {
    address callee;
    TriggerType triggerType;
    bytes createTimeParams; // any custom param to send to the callee, encoded at compileTime
}

struct TriggerReturn {
    TriggerType triggerType;
    bytes runtimeData;
}

function decodePriceTriggerCreateTimeParams(bytes memory createTimeParams)
    pure
    returns (
        address,
        address,
        Ops,
        uint256
    )
{
    return abi.decode(createTimeParams, (address, address, Ops, uint256));
}

function decodeTimestampTriggerCreateTimeParams(bytes memory createTimeParams) pure returns (Ops, uint256) {
    return abi.decode(createTimeParams, (Ops, uint256));
}

function decodePriceTriggerReturn(bytes memory runtimeData)
    pure
    returns (
        address,
        address,
        uint256
    )
{
    return abi.decode(runtimeData, (address, address, uint256));
}

function decodeTimestampTriggerReturn(bytes memory runtimeData) pure returns (uint256) {
    return abi.decode(runtimeData, (uint256));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Constants {
    address constant ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address constant USD = address(0);
    string constant TOKEN_TYPE_NOT_RECOGNIZED = "Token type not recognized";
    string constant UNREACHABLE_STATE = "This state should never be reached";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Constants.sol";
import "../actions/ActionTypes.sol";
import "./subscriptions/Subscriptions.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./assets/TokenLib.sol";

library Utils {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    function _delegatePerformAction(Action memory action, ActionRuntimeParams memory runtimeParams)
        internal
        returns (ActionResponse memory)
    {
        (bool success, bytes memory returndata) = action.callee.delegatecall(
            abi.encodeWithSignature(
                "perform((address,bytes,(uint8,address,uint256)[],(uint8,address,uint256)[]),((uint8,bytes)[],uint256[]))",
                action,
                runtimeParams
            )
        );

        // Taken from: https://eip2535diamonds.substack.com/p/understanding-delegatecall-and-how
        if (success == false) {
            // if there is a return reason string
            if (returndata.length > 0) {
                // bubble up any reason for revert
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Function call reverted");
            }
        } else {
            return abi.decode(returndata, (ActionResponse));
        }
    }

    function _getPositionHash(bytes32[] memory actionHashes) internal view returns (bytes32) {
        return keccak256(abi.encode(actionHashes, address(this)));
    }

    function _getPositionHash(Action[] calldata actions) internal view returns (bytes32) {
        bytes32[] memory actionHashes = new bytes32[](actions.length);
        for (uint32 i = 0; i < actions.length; i++) {
            actionHashes[i] = keccak256(abi.encode(actions[i]));
        }

        return _getPositionHash(actionHashes);
    }

    function _createPosition(
        Action memory precursorAction,
        Action[] memory nextActions,
        EnumerableSet.Bytes32Set storage _pendingPositions,
        mapping(bytes32 => bytes32[]) storage _actionPositionsMap
    ) internal returns (bool, bytes32 positionHash) {
        if (nextActions.length == 0) {
            return (false, positionHash);
        } else {
            bytes32[] memory actionHashes = new bytes32[](nextActions.length);
            for (uint32 i = 0; i < nextActions.length; i++) {
                actionHashes[i] = keccak256(abi.encode(nextActions[i]));
            }

            positionHash = _getPositionHash(actionHashes);
            _pendingPositions.add(positionHash);

            for (uint32 i = 0; i < actionHashes.length; i++) {
                _actionPositionsMap[actionHashes[i]].push(positionHash);
            }

            return (true, positionHash);
        }
    }

    function _closePosition(
        Action memory action,
        EnumerableSet.Bytes32Set storage _pendingPositions,
        mapping(bytes32 => bytes32[]) storage _actionPositionsMap
    ) internal returns (bool, bytes32[] memory deletedPositionHashes) {
        bytes32 actionHash = keccak256(abi.encode(action));
        bytes32[] memory deletedPositionHashes = _actionPositionsMap[actionHash];
        if (deletedPositionHashes.length > 0) {
            // this action is part of a position, so before using it, we need to discard the position
            for (uint32 i = 0; i < deletedPositionHashes.length; i++) {
                _pendingPositions.remove(deletedPositionHashes[i]);
            }
            delete _actionPositionsMap[actionHash];
            return (true, deletedPositionHashes);
        } else {
            return (false, deletedPositionHashes);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./TokenLib.sol";

library AssetTracker {
    using TokenLib for Token;

    struct Assets {
        Token[] tokens; // tracking all the assets this fund has atm
        mapping(bytes32 => uint256) balances; // tracking balances of ERC20 and ETH, ids for NFT
    }

    function increaseAsset(
        Assets storage assets,
        Token memory token,
        uint256 amount
    ) public {
        bytes32 tokenHash = keccak256(abi.encode(token));
        if (token.isERC721()) {
            assets.balances[tokenHash] = amount;
            assets.tokens.push(token);
        } else if (token.isERC20() || token.isETH()) {
            if (assets.balances[tokenHash] == 0) {
                assets.tokens.push(token);
            }
            assets.balances[tokenHash] += amount;
        } else {
            revert(Constants.TOKEN_TYPE_NOT_RECOGNIZED);
        }
    }

    function decreaseAsset(
        Assets storage assets,
        Token memory token,
        uint256 amount
    ) public {
        bytes32 tokenHash = keccak256(abi.encode(token));
        if (token.isERC721()) {
            delete assets.balances[tokenHash];
            removeFromAssets(assets, token);
        } else if (token.isERC20() || token.isETH()) {
            require(assets.balances[tokenHash] >= amount);
            assets.balances[tokenHash] -= amount;
            // TODO: could be made more efficient if we kept token => idx in storage
            if (assets.balances[tokenHash] == 0) {
                removeFromAssets(assets, token);
            }
        } else {
            revert(Constants.TOKEN_TYPE_NOT_RECOGNIZED);
        }
    }

    function removeFromAssets(Assets storage assets, Token memory token) public {
        for (uint256 i = 0; i < assets.tokens.length; i++) {
            if (assets.tokens[i].equals(token)) {
                assets.tokens[i] = assets.tokens[assets.tokens.length - 1];
                assets.tokens.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../Constants.sol";
import "./TokenTypes.sol";

library TokenLib {
    using SafeERC20 for IERC20;

    function equals(Token memory t1, Token memory t2) public pure returns (bool) {
        return (t1.t == t2.t && t1.addr == t2.addr && t1.id == t2.id);
    }

    function approve(
        Token memory token,
        address to,
        uint256 collateral
    ) public returns (uint256 ethCollateral) {
        if (isERC20(token)) {
            IERC20(token.addr).safeApprove(to, collateral);
        } else if (isETH(token)) {
            ethCollateral = collateral;
        } else if (isERC721(token)) {
            require(token.id == collateral);
            IERC721(token.addr).approve(to, collateral);
        } else {
            revert(Constants.TOKEN_TYPE_NOT_RECOGNIZED);
        }
    }

    function send(
        Token memory token,
        address receiver,
        uint256 amount
    ) public {
        if (isERC20(token)) {
            IERC20(token.addr).safeTransfer(receiver, amount);
        } else if (isETH(token)) {
            payable(receiver).transfer(amount);
        } else if (isERC721(token)) {
            require(token.id == amount);
            IERC721(token.addr).safeTransferFrom(address(this), receiver, amount);
        } else {
            revert("Wrong token type!");
        }
    }

    function balance(Token memory token) public view returns (uint256) {
        if (isERC20(token)) {
            return IERC20(token.addr).balanceOf(address(this));
        } else if (isETH(token)) {
            return address(this).balance;
        } else {
            revert("Wrong token type!");
        }
    }

    function take(
        Token memory token,
        address sender,
        uint256 collateral
    ) public {
        if (isERC20(token)) {
            IERC20(token.addr).safeTransferFrom(sender, address(this), collateral);
        } else if (isERC721(token)) {
            require(token.id == collateral);
            IERC721(token.addr).safeTransferFrom(sender, address(this), collateral);
        } else if (!isETH(token)) {
            revert("Wrong token type!");
        }
    }

    function isETH(Token memory token) public view returns (bool) {
        return equals(token, Token({t: TokenType.NATIVE, addr: Constants.ETH, id: 0}));
    }

    function isERC20(Token memory token) public view returns (bool) {
        return token.t == TokenType.ERC20;
    }

    function isERC721(Token memory token) public view returns (bool) {
        return token.t == TokenType.ERC721;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum TokenType {
    NATIVE,
    ERC721,
    ERC20
}

struct Token {
    TokenType t;
    address addr;
    uint256 id; // only used for ERC721, else set to 0
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../assets/TokenLib.sol";
import "../Utils.sol";
import "../assets/AssetTracker.sol";

library Subscriptions {
    using AssetTracker for AssetTracker.Assets;
    using TokenLib for Token;

    enum Status {
        ACTIVE,
        WITHDRAWN
    }

    struct Subscription {
        uint256 collateralAmount;
        Status status;
    }

    struct Constraints {
        uint256 minCollateralPerSub; // minimum amount needed as collateral to deposit
        uint256 maxCollateralPerSub; // max ...
        uint256 minCollateralTotal;
        uint256 maxCollateralTotal; // limit on subscription to protect from slippage DOS attacks
        uint256 deadline; // a block.timestamp, after which no one can deposit to this
        uint256 lockin; // a block.timestamp, until which no one can redeem (given trade/fund has been activated)
        Token allowedDepositToken;
        bool onlyWhitelistedInvestors; // if set to true, will create an investor whitelist
    }

    struct SubStuff {
        Constraints constraints;
        mapping(address => Subscription) subscriptions;
        uint256 totalCollateral; // tracking total ETH received from subscriptions
        uint256 subscriberToManagerFeePercentage; // 1% = 100;
        uint256 subscriberToPlatformFeePercentage; // 1% = 100;
        address platformFeeWallet;
    }

    function deposit(
        SubStuff storage subStuff,
        AssetTracker.Assets storage assets,
        Token memory collateralToken,
        uint256 collateralAmount
    ) public {
        // Take the platform fee
        uint256 platformFee = (collateralAmount * subStuff.subscriberToPlatformFeePercentage) / 100_00;
        collateralToken.send(subStuff.platformFeeWallet, platformFee);

        uint256 remainingCollateralAmount = collateralAmount - platformFee;
        validateCollateral(subStuff, msg.sender, collateralToken, remainingCollateralAmount);

        Subscriptions.Subscription storage sub = subStuff.subscriptions[msg.sender];
        sub.status = Subscriptions.Status.ACTIVE;
        sub.collateralAmount += remainingCollateralAmount;

        subStuff.totalCollateral += remainingCollateralAmount;
        assets.increaseAsset(collateralToken, remainingCollateralAmount);
    }

    function setConstraints(SubStuff storage subStuff, Constraints memory constraints) public {
        validateSubscriptionConstraintsBasic(constraints);
        subStuff.constraints = constraints;
    }

    function setSubscriptionFeeParams(
        SubStuff storage subStuff,
        uint256 subscriberToManagerFeePercentage,
        uint256 subscriberToPlatformFeePercentage,
        address platformFeeWallet
    ) public {
        require(subscriberToManagerFeePercentage <= 100 * 100, "managementFee > 100%");
        require(subscriberToPlatformFeePercentage <= 100 * 100, "managementFee > 100%");

        subStuff.subscriberToManagerFeePercentage = subscriberToManagerFeePercentage;
        subStuff.subscriberToPlatformFeePercentage = subscriberToPlatformFeePercentage;
        subStuff.platformFeeWallet = platformFeeWallet;
    }

    function validateSubscriptionConstraintsBasic(Subscriptions.Constraints memory constraints) public view {
        require(
            constraints.minCollateralPerSub <= constraints.maxCollateralPerSub,
            "minCollateralPerSub > maxCollateralPerSub"
        );
        require(
            constraints.minCollateralTotal <= constraints.maxCollateralTotal,
            "minTotalCollaterl > maxTotalCollateral"
        );
        require(constraints.minCollateralTotal >= constraints.minCollateralPerSub, "mininmums don't make sense");
        require(constraints.maxCollateralTotal >= constraints.maxCollateralPerSub, "maximums don't make sense");
        require(constraints.deadline >= block.timestamp, "deadline is in the past");
        require(constraints.lockin >= block.timestamp, "lockin is in the past");
        require(constraints.lockin > constraints.deadline, "lockin <= deadline");
    }

    function validateCollateral(
        SubStuff storage subStuff,
        address subscriber,
        Token memory collateralToken,
        uint256 collateralAmount
    ) public view returns (bool) {
        require(collateralToken.equals(subStuff.constraints.allowedDepositToken));

        uint256 prevCollateralAmount = subStuff.subscriptions[subscriber].collateralAmount;

        if ((collateralToken.isETH())) {
            require(collateralAmount == msg.value);
        }

        require(subStuff.constraints.minCollateralPerSub <= collateralAmount, "< minCollateralPerSub");
        require(
            subStuff.constraints.maxCollateralPerSub >= collateralAmount + prevCollateralAmount,
            "> maxCollateralPerSub"
        );
        require(
            subStuff.constraints.maxCollateralTotal >= (subStuff.totalCollateral + collateralAmount),
            "> maxColalteralTotal"
        );
        require(block.timestamp < subStuff.constraints.deadline);

        return true;
    }

    function withdrawCollateral(SubStuff storage subStuff, AssetTracker.Assets storage assets)
        public
        returns (Token[] memory, uint256[] memory)
    {
        Subscriptions.Subscription storage subscription = subStuff.subscriptions[msg.sender];
        subscription.status = Subscriptions.Status.WITHDRAWN;
        uint256 amountToSendBack = subscription.collateralAmount;
        subscription.collateralAmount = 0;

        subStuff.totalCollateral -= amountToSendBack;
        assets.decreaseAsset(subStuff.constraints.allowedDepositToken, amountToSendBack);

        subStuff.constraints.allowedDepositToken.send(msg.sender, amountToSendBack);

        Token[] memory tokens = new Token[](1);
        tokens[0] = subStuff.constraints.allowedDepositToken;
        uint256[] memory balances = new uint256[](1);
        balances[0] = amountToSendBack;

        return (tokens, balances);
    }

    function withdrawAssets(SubStuff storage subStuff, AssetTracker.Assets storage assets)
        public
        returns (Token[] memory, uint256[] memory)
    {
        Subscriptions.Subscription storage subscription = subStuff.subscriptions[msg.sender];
        subscription.status = Subscriptions.Status.WITHDRAWN;

        Token[] memory tokens = new Token[](assets.tokens.length);
        uint256[] memory balances = new uint256[](assets.tokens.length);

        // TODO: potentially won't need the loop anymore if closing == swap back to 1 asset
        for (uint256 i = 0; i < assets.tokens.length; i++) {
            tokens[i] = assets.tokens[i];
            balances[i] =
                getShares(subStuff, assets, msg.sender, assets.tokens[i]) -
                getManagementFeeShare(subStuff, assets, tokens[i]);
            tokens[i].send(msg.sender, balances[i]);
        }
        return (tokens, balances);
    }

    function getManagementFeeShare(
        SubStuff storage subStuff,
        AssetTracker.Assets storage assets,
        Token memory token
    ) public view returns (uint256) {
        return (assets.balances[keccak256(abi.encode(token))] * subStuff.subscriberToManagerFeePercentage) / 100_00;
    }

    function getShares(
        SubStuff storage subStuff,
        AssetTracker.Assets storage assets,
        address subscriber,
        Token memory token
    ) public view returns (uint256) {
        if (token.isERC20() || token.isETH()) {
            return
                (subStuff.subscriptions[subscriber].collateralAmount * assets.balances[keccak256(abi.encode(token))]) /
                subStuff.totalCollateral;
        } else {
            revert(Constants.TOKEN_TYPE_NOT_RECOGNIZED);
        }
    }
}