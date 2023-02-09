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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITradingMaster {
    struct Team {
        uint256 id;
        /// @dev Team volume amount. If one of members leave the team, it will not be reduced.
        mapping(uint256 => uint256) volumeByRound;
        /// @dev Actual Team volume amount. If one of memebers leave the team, it will be reduced.
        mapping(uint256 => uint256) actualVolumeByRound;
        address creator;
        address[] requesters;
        string name;
        bool live;
    }

    struct User {
        mapping(uint256 => uint256) volumeByRound;
        uint256 teamId;
        uint256[] receivedInvIds;
    }

    struct Request {
        bool invited;
        bool requested;
    }

    struct Round {
        uint256 createdTimestamp;
        uint256 endTimestamp;
        uint256 rewardsAmount;
        uint256[] winTeams;
        uint16 roundFee;
        uint16[] rewardsPercents;
        bool finished;
    }

    /// @notice Token that used for rewards and stored as fee.
    function baseToken() external view returns (address baseToken);

    /// @notice Check now is round duration or not.
    function inRoundDuration() external view returns (bool);

    /// @notice Get round information.
    function getRoundInfo() external view returns (Round memory);

    /// @notice Get Round fee rate.
    /// @dev If it's not round duration or trader doesn't belong to a team, returns 0.
    /// @param _trader The address of trader.
    function getRoundFee(address _trader) external view returns (uint16);

    /// @notice Set platform master contract address.
    /// @dev Only owner can call this function.
    /// @param _platformMaster The address of platform master contract.
    function setPlatformMaster(address _platformMaster) external;

    /// @notice Update user&team volume with volumeAmount.
    /// @notice Update current round rewards.
    /// @dev This is applied when now is in round duration.
    /// @dev _roundFee should be deposited first before call updateVolumeAndRewards function.
    /// @dev Only platformMaster can call this function.
    /// @param _account The address of account.
    /// @param _volumeAmount The amount of volume to update(add).
    /// @param _roundFee Roundfee to add roundRewards.
    function updateVolumeAndRewards(address _account, uint256 _volumeAmount, uint256 _roundFee) external;

    /// @notice Create new round.
    /// @dev Only platform master can call this function.
    /// @param _createTimestamp Start timestamp for new round.
    /// @param _durationDays    The new round duration as day.
    /// @param _roundFee        Round fee percent. 
    /// @param _rewardsPercents Rewards percent for winners.
    function createRound(
        uint256 _createTimestamp, 
        uint16 _durationDays, 
        uint16 _roundFee,
        uint16[] memory _rewardsPercents
    ) external;

    /// @notice Finish round.
    /// @dev Only platform master can call this function.
    /// @dev Divide rewards to winners.
    function finishRound() external;

    /// @notice Create team.
    /// @dev The user should be apart from any teams to create a team.
    /// @dev Only platform master can call this function.
    /// @param _creator The address of `msg.sender` - creator
    /// @param _name The team name.
    function createTeam(address _creator, string memory _name) external;

    /// @notice Disband the team with team id.
    /// @dev Only team creator can do this.
    /// @dev Only platform master can call this function.
    /// @param _account The address of origin caller.
    /// @param _teamId The team id to disband.
    function disbandTeam(address _account, uint256 _teamId) external;

    /// @notice Send invitation to users.
    /// @dev Invitor should be team member.
    /// @dev Only platform master can call this function.
    /// @param _account The address of origin caller.
    /// @param _recipients The list of invitation recipients.
    function sendInvitation(address _account, address[] memory _recipients) external;

    /// @notice Accept invitation.
    /// @dev Acceptor should be apart from any team.
    /// @dev Only platform master can call this function.
    /// @param _account the address of acceptor.
    /// @param _teamId The team id to accept.
    function acceptInvitation(address _account, uint256 _teamId) external;

    /// @notice Send request to join to a team.
    /// @dev Requester should be not belongs to any teams.
    /// @dev Only platform master can call this function.
    /// @param _account The address of sender.
    /// @param _teamIds The list of team id to send reqest.
    function sendRequestToTeam(address _account, uint256[] memory _teamIds) external;

    /// @notice Accept request.
    /// @dev Caller should be owner of a team.
    /// @dev Only platform master can call this function.
    /// @param _acceptor The address of acceptor.
    /// @param _user The addres of user for accepting.
    function acceptRequest(address _acceptor, address _user) external;

    /// @notice Leave team.
    /// @dev Only platform master can call this function.
    /// @param _creator The address of team creator.
    function leaveTeam(address _creator) external;

    /// @notice Get all invitations.
    /// @param _user The address of a user.
    /// @return _invitationIds The team ids that received invitation.
    function checkInvitation(address _user) external view returns (uint256[] memory _invitationIds);

    /// @notice Get all requests.
    /// @dev Caller should be owner of a team.
    /// @param _account, The address of user who wanna check requeest.
    /// @return _requesters The list of requester addresses .
    function checkRequest(address _account) external view returns (address[] memory _requesters);

    /// @notice Get information of a team.
    /// @param _teamId The team id to get info.
    /// @return volume  Amount of trading volume.
    /// @return creator The address of team creator.
    /// @return members The addresses of team member.
    /// @return name    Team name
    function getTeamInfo(uint256 _teamId) external view returns (
        uint256 volume,
        address creator,
        address[] memory members,
        string memory name
    );

    /// @notice Get amount of trade volume for a team.
    /// @param _teamId Team id.
    /// @return Return trading volume amount.
    function getTeamVolume(uint256 _teamId) external view returns (uint256);

    /// @notice Get rewards amount of prize.
    /// @param _teamId Team id.
    /// @return Rewards amount of prize.
    function getPrizeAmount(uint256 _teamId) external view returns (uint256);

    /// @notice Get team info user belongs to.
    function getUserTeamInfo(address _user) external view returns (
        bool teamMember, 
        bool teamCreator, 
        uint256 teamId,
        uint256 userTeamVolume
    );

    event RoundCreated(uint256 roundId);

    event RoundFinished(uint256 roundId);

    event TeamCreated(address indexed creator, uint256 teamId);

    event TeamDisbanded(uint256 teamId);

    event UserTeamLeft(address indexed user, uint256 teamId);

    event PlatformFeeSet(uint16 newFee);

    event InvitationAcceped(uint256 teamId);

    event RequestAccepted(address indexed requester, uint256 teamId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITradingMaster.sol";

/// @title TeamMaster - Team and Round master.
/// @author 5thWeb
contract TradingMaster is Ownable2Step, ITradingMaster {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => User) public userInfos;
    mapping(uint256 => Team) private teamInfos;
    mapping(uint256 => Round) private roundInfos;
    mapping(uint256 => EnumerableSet.AddressSet) private teamMembers;

    /// @dev Show inviation already received or not by user and team id.
    mapping(address => mapping(uint256 => Request)) private requestInfos;

    // roundId and teamId are started from 1.
    Counters.Counter private roundId;
    Counters.Counter private teamId;

    /// @inheritdoc ITradingMaster
    address public baseToken;

    /// @notice The PlatformMaster contract address.
    address public platformMaster;

    uint16 public BASE_POINT = 1000;

    modifier onlyPlatformMaster {
        require (msg.sender == platformMaster, "only PlatformMaster");
        _;
    }

    constructor (
        address _baseToken
    ) {
        teamId.increment();

        require (_baseToken != address(0), "zero token address");
        baseToken = _baseToken;
    }

    /// @inheritdoc ITradingMaster
    function inRoundDuration() public view returns (bool) {
        return roundId.current() != 0 && !_checkRoundTimeOver();
    }

    /// @inheritdoc ITradingMaster
    function getRoundInfo() external view returns (Round memory) {
        uint256 curRoundId = roundId.current();
        return roundInfos[curRoundId];
    }

    /// @inheritdoc ITradingMaster
    function getRoundFee(address _trader) external view returns (uint16) {
        uint256 curRoundId = roundId.current();
        if (
            userInfos[_trader].teamId == 0 || 
            !inRoundDuration()
        ) {
            return 0;
        }
        
        return roundInfos[curRoundId].roundFee;
    }

    /// @inheritdoc ITradingMaster
    function setPlatformMaster(address _platformMaster) external override onlyOwner {
        require (_platformMaster != address(0), "zero platform master contract address");
        platformMaster = _platformMaster;
    }

    /// @inheritdoc ITradingMaster
    function createRound(
        uint256 _createTimestamp, 
        uint16 _durationDays, 
        uint16 _roundFee,
        uint16[] memory _rewardsPercents
    ) external override onlyPlatformMaster {
        uint256 curRoundId = roundId.current();
        require (_durationDays > 0, "invalid duration");
        require (_createTimestamp >= block.timestamp, "before current time");
        require (curRoundId == 0 || roundInfos[curRoundId].finished, "round not finished");
        roundId.increment();
        curRoundId = roundId.current();
        roundInfos[curRoundId] = Round(
            _createTimestamp, 
            _createTimestamp + _durationDays * 1 days,
            0, 
            new uint256[](3),
            _roundFee,
            _rewardsPercents,
            false
        );

        emit RoundCreated(curRoundId);
    }

    /// @inheritdoc ITradingMaster
    function finishRound() external override onlyPlatformMaster {
        uint256 curRoundId = roundId.current();
        Round storage round = roundInfos[curRoundId];
        require (curRoundId > 0 && !round.finished, "already finished");
        require (round.endTimestamp < block.timestamp, "in round duration");

        require (IERC20(baseToken).balanceOf(address(this)) >= round.rewardsAmount, "not enough balance for prize rewards");
        round.finished = true;
        _takePrizeAmount();

        emit RoundFinished(curRoundId);
    }

    /// @inheritdoc ITradingMaster
    function createTeam(
        address _creator,
        string memory _name
    ) external override onlyPlatformMaster {
        require (_creator != address(0), "zero address caller");
        require (userInfos[_creator].teamId == 0, "user already blongs to a team");

        uint256 curTeamId = teamId.current();
        Team storage team = teamInfos[curTeamId];
        team.id = curTeamId;
        team.creator = _creator;
        team.name = _name;
        team.live = true;
        userInfos[_creator].teamId = curTeamId;
        teamId.increment();
        teamMembers[curTeamId].add(_creator);

        emit TeamCreated(_creator, curTeamId);
    }

    /// @inheritdoc ITradingMaster
    function disbandTeam(
        address _account,
        uint256 _teamId
    ) external override onlyPlatformMaster {
        Team storage teamInfo = teamInfos[_teamId];
        require (teamInfo.live, "not exists");
        require (teamInfo.creator == _account, "not team creator");

        uint256 lastRoundId = roundId.current();
        require (lastRoundId == 0 || roundInfos[lastRoundId].finished, "can not disband team before round finished");

        address[] memory members = teamMembers[_teamId].values();
        for (uint256 i = 0; i < members.length; i ++) {
            _leaveTeam(members[i], _teamId);
        }

        teamInfo.live = false;
        teamInfo.creator = address(0);
        teamInfo.name = "";

        emit TeamDisbanded(_teamId);
    }

    /// @inheritdoc ITradingMaster
    function sendInvitation(
        address _account,
        address[] memory _recipients
    ) external override onlyPlatformMaster {
        uint256 _teamId = userInfos[_account].teamId;
        uint256 length = _recipients.length;
        require (_teamId > 0, "not belongs to any team");
        require (length > 0, "invalid recipients list");

        for (uint256 i = 0; i < length; i ++) {
            address recipient = _recipients[i];
            Request storage request = requestInfos[recipient][_teamId];
            if (!request.requested && !request.invited) {
                request.invited = true;
                userInfos[recipient].receivedInvIds.push(_teamId);
            }
        }
    }

    /// @inheritdoc ITradingMaster
    function acceptInvitation(
        address _account,
        uint256 _teamId
    ) external override onlyPlatformMaster {
        Team storage teamInfo = teamInfos[_teamId];
        User storage userInfo = userInfos[_account];

        require (teamInfo.live, "invalid team id");
        require (userInfo.teamId == 0, "already blongs to a team");
        require (requestInfos[_account][_teamId].invited, "not invited");

        delete userInfo.receivedInvIds;
        userInfo.teamId = _teamId;
        requestInfos[_account][_teamId].invited = false;
        teamMembers[_teamId].add(_account);

        emit InvitationAcceped(_teamId);
    }

    /// @inheritdoc ITradingMaster
    function checkInvitation(
        address _user
    ) external view override returns (uint256[] memory _invitationIds) {
        return userInfos[_user].receivedInvIds;
    }

    /// @inheritdoc ITradingMaster
    function sendRequestToTeam(
        address _account,
        uint256[] memory _teamIds
    ) external override onlyPlatformMaster {
        uint256 length = _teamIds.length;
        require (userInfos[_account].teamId == 0, "already belongs to a team");
        require (length > 0, "invalid team list");

        for (uint256 i = 0; i < length; i ++) {
            uint256 id = _teamIds[i];
            require (teamInfos[id].live, "not exist team");
            Request storage request = requestInfos[_account][id];
            if (!request.requested && !request.requested) {
                request.requested = true;
                teamInfos[id].requesters.push(_account);
            }
        }
    }

    /// @inheritdoc ITradingMaster
    function acceptRequest(
        address _acceptor,
        address _user
    ) external override onlyPlatformMaster {
        uint256 id = 0;
        require (userInfos[_user].teamId == 0, "already belongs to a team");
        id = userInfos[_acceptor].teamId;
        require (id > 0 && teamInfos[id].creator == _acceptor, "not team creator");
        require (requestInfos[_user][id].requested, "not requested user");

        User storage userInfo = userInfos[_user];

        teamMembers[id].add(_user);
        userInfo.teamId = id;
        requestInfos[_user][id].requested = false;

        emit RequestAccepted(_user, id);
    }

    /// @inheritdoc ITradingMaster
    function checkRequest(address _account) external view override returns (address[] memory _requesters) {
        uint256 id = userInfos[_account].teamId;
        if (teamInfos[id].creator != _account) { return new address[](0); }
        address[] memory requesters = teamInfos[id].requesters;
        uint256 length = requesters.length;
        uint256 cnt = 0;
        for (uint256 i = 0; i < length; i ++) {
            if (userInfos[requesters[i]].teamId == 0) { cnt ++; }
        }
        
        _requesters = new address[](cnt);
        uint256 index = 0;
        for (uint256 i = 0; i < length; i ++) {
            if (userInfos[requesters[i]].teamId == 0) { _requesters[index ++] = requesters[i]; }
        }
    }

    /// @inheritdoc ITradingMaster
    function leaveTeam(address _member) external override {
        uint256 _teamId = userInfos[_member].teamId;
        require (_teamId > 0, "no team");
        require (teamInfos[_teamId].creator != _member, "creator can not leave team");
        _leaveTeam(_member, _teamId);

        emit UserTeamLeft(_member, _teamId);
    }

    /// @inheritdoc ITradingMaster
    function getTeamInfo(uint256 _teamId) external view override returns (
        uint256 volume,
        address creator,
        address[] memory members,
        string memory name
    ) {
        Team storage team = teamInfos[_teamId];
        uint256 _roundId = roundId.current();
        require (team.live, "not exist team");
        return (
            roundInfos[_roundId].finished ? 0 : team.volumeByRound[_roundId],
            team.creator,
            teamMembers[team.id].values(),
            team.name
        );
    }

    /// @inheritdoc ITradingMaster
    function getTeamVolume(uint256 _teamId) external view override returns (uint256) {
        Team storage team = teamInfos[_teamId];
        uint256 _roundId = roundId.current();
        return team.live && !roundInfos[_roundId].finished ? team.volumeByRound[_roundId] : 0;
    }

    /// @inheritdoc ITradingMaster
    function getUserTeamInfo(address _user) external view override returns (
        bool teamMember_, 
        bool teamCreator_, 
        uint256 teamId_,
        uint256 userTeamVolume_
    ) {
        require (_user != address(0), "invalid user address");
        uint256 curRoundId = roundId.current();
        Round memory round = roundInfos[curRoundId];
        teamId_ = userInfos[_user].teamId;
        teamMember_ = teamId_ > 0;
        teamCreator_ = teamMember_ ? teamInfos[teamId_].creator == _user : false;
        userTeamVolume_ = round.finished ? 0 : userInfos[_user].volumeByRound[curRoundId];
    }

    /// @inheritdoc ITradingMaster
    function getPrizeAmount(uint256 _teamId) public view override returns (uint256) {
        Round memory round = roundInfos[roundId.current()];
        uint256 prizePercent = 0;
        
        for (uint256 i = 0; i < 3; i ++) {
            if (round.winTeams[i] == _teamId) {
                prizePercent = round.rewardsPercents[i];
                break;
            }
        }

        return round.rewardsAmount * prizePercent / BASE_POINT;
    }

    /// @inheritdoc ITradingMaster
    function updateVolumeAndRewards(address _account, uint256 _volumeAmount, uint256 _roundFee) external onlyPlatformMaster {
        uint256 curRound = roundId.current();
        uint256 userTeamId = userInfos[_account].teamId;
        if (userTeamId > 0 && !_checkRoundTimeOver()) {
            userInfos[_account].volumeByRound[curRound] += _volumeAmount;
            teamInfos[userTeamId].volumeByRound[curRound] += _volumeAmount;
            teamInfos[userTeamId].actualVolumeByRound[curRound] += _volumeAmount;
            roundInfos[curRound].rewardsAmount += _roundFee;
            _updateSortTeam(userTeamId);
        }
    }

    function actualTeamVolume(uint256 _teamId) external view returns (uint256) {
        uint256 curRound = roundId.current();
        if (curRound != 0 && !roundInfos[curRound].finished) {
            return teamInfos[_teamId].actualVolumeByRound[curRound];
        }
        return 0;
    }

    function _updateSortTeam(uint256 _compareTeamId) internal {
        Team storage compareTeamInfo = teamInfos[_compareTeamId];
        uint256 curRound = roundId.current();
        Round storage round = roundInfos[curRound];

        for (uint256 i = 0; i < 3; i ++) {
            uint256 winTeamId = round.winTeams[i];
            if (winTeamId == 0 || winTeamId == _compareTeamId) {
                round.winTeams[i] = _compareTeamId;
                return;
            }
            
            if (teamInfos[winTeamId].volumeByRound[curRound] < compareTeamInfo.volumeByRound[curRound]) {
                for (uint256 j = 2; j > i; j --) {
                    round.winTeams[j] = round.winTeams[j - 1];
                }
                round.winTeams[i] = _compareTeamId;
                return;
            }
        }
    }

    /// @notice Take prize.
    /// @dev Divide prize to team members based on trading weight.
    function _takePrizeAmount() internal {
        Round memory round = roundInfos[roundId.current()];
        if (round.rewardsAmount == 0) return;
        for (uint256 i = 0; i < 3; i ++) {
            if (round.rewardsPercents[i] == 0) return;
            _giveRewardsToWinner(round.winTeams[i], round.rewardsPercents[i]);
        }
    }

    /// @notice Give rewards to team.
    /// @dev Divided team rewards to team members based on volume weight.
    /// @param _teamId Win team id.
    /// @param _rewardPercent Percent of total rewards for win team.
    function _giveRewardsToWinner(uint256 _teamId, uint256 _rewardPercent) internal {
        if (!teamInfos[_teamId].live) return;

        uint256 roundRewards = roundInfos[roundId.current()].rewardsAmount;
        uint256 teamRewards = roundRewards * _rewardPercent / BASE_POINT;
        if (teamRewards == 0) return;

        // divide rewards to users based on volume weight.
        {
            uint256 _roundId = roundId.current();
            uint256 teamVolume = teamInfos[_teamId].actualVolumeByRound[_roundId];
            address[] memory members = teamMembers[_teamId].values();
            uint256 memberLength = members.length;
            if (teamVolume == 0 || memberLength == 1) {
                IERC20(baseToken).safeTransfer(members[0], teamRewards);
                return;
            }
            
            for (uint256 i = 0; i < memberLength; i ++) {
                address member = members[i];
                uint256 memberVolume = userInfos[member].volumeByRound[_roundId];
                uint256 memberRewards = teamRewards * memberVolume / teamVolume;
                IERC20(baseToken).safeTransfer(member, memberRewards);
            }
        }
    }

    /// @notice Let a user leave a team.
    /// @param _user The address of a user.
    /// @param _teamId Team id to leave.
    function _leaveTeam(address _user, uint256 _teamId) internal {
        userInfos[_user].teamId = 0;
        uint256 _roundId = roundId.current();
        if (_roundId != 0 && !roundInfos[_roundId].finished) {
            teamInfos[_teamId].actualVolumeByRound[_roundId] -= userInfos[_user].volumeByRound[_roundId];
            userInfos[_user].volumeByRound[_roundId] = 0;
        }
        teamMembers[_teamId].remove(_user);
    }

    /// @notice Check round time is over or not.
    /// @return true/false.
    function _checkRoundTimeOver() internal view returns (bool) {
        uint256 id = roundId.current();
        Round memory round = roundInfos[id];
        if (id > 0 && round.endTimestamp > block.timestamp) return false;
        return true;
    }
}