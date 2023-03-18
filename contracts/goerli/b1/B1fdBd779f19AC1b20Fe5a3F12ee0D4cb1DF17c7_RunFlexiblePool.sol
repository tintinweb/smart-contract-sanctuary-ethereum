// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity ^0.8.18;

import "../INTERFACES/ITwoStepOwnable.sol";

/**
 * @title   TwoStepOwnable
 * @author  Unseen | decapinator.eth
 * @notice  TwoStepOwnable is a module which provides access control
 *          where the ownership of a contract can be exchanged via a
 *          two step process. A potential owner is set by the current
 *          owner using transferOwnership, then accepted by the new
 *          potential owner using acceptOwnership.
 */
contract TwoStepOwnable is ITwoStepOwnable {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Continue with function execution.
        _;
    }

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(
        address newPotentialOwner
    ) external override onlyOwner {
        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress();
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override onlyOwner {
        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
        emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
        _owner = msg.sender;
    }

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice A public view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @notice Internal function that sets the inital owner of the
     *         base contract. The initial owner must not be set
     *         previously.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure the initial owner is not an invalid address.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Emit an event indicating ownership has been set.
        emit OwnershipTransferred(address(0), initialOwner);

        // Set the initial owner.
        _owner = initialOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 *  @title IRunPool
 *  @notice Interface for RunPool.
 */
interface IRunPool {
    struct UserInfo {
        /* User Shares */
        uint256 shares;
        /* keep track of deposited time for potential penalty */
        uint256 lastDepositedTime;
        /* keep track of run deposited at the last user action. */
        uint256 runAtLastUserAction;
        /* keep track of the last user action time. */
        uint256 lastUserActionTime;
        /* lock start time. */
        uint256 lockStartTime;
        /* lock end time. */
        uint256 lockEndTime;
        /* lock status. */
        bool locked;
        /* amount deposited during lock period. */
        uint256 lockedAmount;
        /*boost share, in order to give the user
        higher reward.The user only enjoys the reward,
        so the principal needs to be recorded as a debt.*/
        uint256 userBoostedShare;
    }

    /**
     * @notice Returns the user info.
     */
    function userInfo(
        address _user
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    ///@notice Returns the price per full share.
    function getPricePerFullShare() external view returns (uint256);

    ///@notice Returns the total amount.
    function deposit(uint256 _amount, uint256 _lockDuration) external;

    ///@notice Withdraws the specified amount.
    function withdrawByAmount(uint256 _amount) external;

    ///@notice Withdraws all in case of emergency.
    function withdrawAll() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title   TwoStepOwnableInterface
 * @author  Unseen | decapinator.eth
 * @notice  TwoStepOwnableInterface contains all external function INTERFACES,
 *          events and errors for the two step ownable access control module.
 */
interface ITwoStepOwnable {
    /**
     * @dev Emit an event whenever the contract owner registers a
     *      new potential owner.
     *
     * @param newPotentialOwner The new potential owner of the contract.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever contract ownership is transferred.
     *
     * @param previousOwner The previous owner of the contract.
     * @param newOwner      The new owner of the contract.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Revert with an error when attempting to set an owner
     *      that is already set.
     */
    error OwnerAlreadySet(address currentOwner);

    /**
     * @dev Revert with an error when attempting to set the initial
     *      owner and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to claim ownership of the
     *      contract with a caller that is not the current potential owner.
     */
    error CallerIsNotNewPotentialOwner();

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../EXTENSIONS/TwoStepOwnable.sol";
import "../INTERFACES/IRunPool.sol";

/**
 *  @title PoolManager
 *  @notice Contract to manage RUN pool
 *  @author Unseen | decapinator.eth
 **/
contract FlexiblePoolManager is TwoStepOwnable, Pausable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        /* User Shares */
        uint256 shares;
        /* keep track of deposited time for potential penalty */
        uint256 lastDepositedTime;
        /* keep track of run deposited at the last user action. */
        uint256 runAtLastUserAction;
        /* keep track of the last user action time. */
        uint256 lastUserActionTime;
    }

    ///@notice Run token contract
    IERC20 public RUN;
    ///@notice RunPool contract
    IRunPool public runPool;

    ///@notice mapping address to userInfo
    mapping(address => UserInfo) public userInfo;

    uint256 public totalShares;
    address public treasury;
    bool public staking = true;

    uint256 public constant MAX_PERFORMANCE_FEE = 2000; // 20%
    uint256 public constant MAX_WITHDRAW_FEE = 500; // 5%
    uint256 public constant MAX_WITHDRAW_FEE_PERIOD = 1 weeks; // 1 week
    uint256 public constant MAX_WITHDRAW_AMOUNT_BOOSTER = 10010; // 1.001
    uint256 public constant MIN_DEPOSIT_AMOUNT = 0.00001 ether;
    uint256 public constant MIN_WITHDRAW_AMOUNT = 0.00001 ether;
    uint256 public constant MIN_WITHDRAW_AMOUNT_BOOSTER = 10000; // 1

    ///@notice When call runpool.withdrawByAmount function,there will be a loss of precision, so need to withdraw more.
    uint256 public withdrawAmountBooster = 10001; // 1.0001
    ///@notice performance fee
    uint256 public performanceFee = 200; // 2%
    ///@notice withdraw fee
    uint256 public withdrawFee = 10; // 0.1%
    ///@notice withdraw fee period
    uint256 public withdrawFeePeriod = 72 hours; // 3 days

    ///@notice emmited when deposit
    event DepositRun(
        address indexed sender,
        uint256 amount,
        uint256 shares,
        uint256 lastDepositedTime
    );
    ///@notice emmited when withdraw
    event WithdrawShares(
        address indexed sender,
        uint256 amount,
        uint256 shares
    );
    ///@notice emmited when performance fee is charged
    event ChargePerformanceFee(
        address indexed sender,
        uint256 amount,
        uint256 shares
    );
    ///@notice emmited when withdraw fee is charged
    event ChargeWithdrawFee(address indexed sender, uint256 amount);
    event Pause(); // when contract is paused
    event Unpause(); // when contract is unpaused
    event NewTreasury(address treasury); // when treasury is changed
    event NewPerformanceFee(uint256 performanceFee); // when performance fee is changed
    event NewWithdrawFee(uint256 withdrawFee); // when withdraw fee is changed
    event NewWithdrawFeePeriod(uint256 withdrawFeePeriod); // when withdraw fee period is changed
    event NewWithdrawAmountBooster(uint256 withdrawAmountBooster); // when withdraw amount booster is changed

    /**
     * @notice Withdraw unexpected tokens sent to the Run Flexible Pool
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(RUN), "USN: Token mismatch");
        require(_token != address(0), "USN: Token mismatch");
        uint256 amount = IERC20(_token).balanceOf(address(this));
        require(amount > 0, "USN: No tokens to withdraw");
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Withdraws from Run Pool without caring about rewards.
     * @dev EMERGENCY ONLY. Only callable by the contract owner.
     */
    function emergencyWithdraw() external onlyOwner {
        require(staking, "USN: No staking run");
        staking = false;
        runPool.withdrawAll();
    }

    /**
     * @notice Sets treasury address
     * @dev Only callable by the contract owner.
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "USN: Cannot be zero address");
        require(_treasury != treasury, "USN: Same as current treasury");
        treasury = _treasury;
        emit NewTreasury(treasury);
    }

    /**
     * @notice Sets performance fee
     * @dev Only callable by the contract owner.
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyOwner {
        require(
            _performanceFee <= MAX_PERFORMANCE_FEE,
            "performanceFee cannot be more than MAX_PERFORMANCE_FEE"
        );
        require(
            _performanceFee != performanceFee,
            "USN: Same as current performanceFee"
        );
        performanceFee = _performanceFee;
        emit NewPerformanceFee(performanceFee);
    }

    /**
     * @notice Sets withdraw fee
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFee(uint256 _withdrawFee) external onlyOwner {
        require(
            _withdrawFee <= MAX_WITHDRAW_FEE,
            "withdrawFee cannot be more than MAX_WITHDRAW_FEE"
        );
        require(
            _withdrawFee != withdrawFee,
            "USN: Same as current withdrawFee"
        );
        withdrawFee = _withdrawFee;
        emit NewWithdrawFee(withdrawFee);
    }

    /**
     * @notice Sets withdraw fee period
     * @dev Only callable by the contract owner.
     */
    function setWithdrawFeePeriod(
        uint256 _withdrawFeePeriod
    ) external onlyOwner {
        require(
            _withdrawFeePeriod <= MAX_WITHDRAW_FEE_PERIOD,
            "withdrawFeePeriod cannot be more than MAX_WITHDRAW_FEE_PERIOD"
        );
        require(
            _withdrawFeePeriod != withdrawFeePeriod,
            "USN: Same as current withdrawFeePeriod"
        );
        withdrawFeePeriod = _withdrawFeePeriod;
        emit NewWithdrawFeePeriod(withdrawFeePeriod);
    }

    /**
     * @notice Sets withdraw amount booster
     * @dev Only callable by the contract owner.
     */
    function setWithdrawAmountBooster(
        uint256 _withdrawAmountBooster
    ) external onlyOwner {
        require(
            _withdrawAmountBooster >= MIN_WITHDRAW_AMOUNT_BOOSTER,
            "withdrawAmountBooster cannot be less than MIN_WITHDRAW_AMOUNT_BOOSTER"
        );
        require(
            _withdrawAmountBooster <= MAX_WITHDRAW_AMOUNT_BOOSTER,
            "withdrawAmountBooster cannot be more than MAX_WITHDRAW_AMOUNT_BOOSTER"
        );
        require(
            _withdrawAmountBooster != withdrawAmountBooster,
            "USN: Same as current withdrawAmountBooster"
        );
        withdrawAmountBooster = _withdrawAmountBooster;
        emit NewWithdrawAmountBooster(withdrawAmountBooster);
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./FlexiblePoolManager.sol";

/**
 *  @title Flexible Run Pool
 *  @notice Contract to manage flexible RUN staking pool
 *  @author Unseen | decapinator.eth
 **/
contract RunFlexiblePool is FlexiblePoolManager {
    using SafeERC20 for IERC20;

    /**
     * @notice Constructor
     * @param _RUN: RUN contract
     * @param _runPool: RunPool contract
     * @param _owner: address of the owner
     * @param _treasury: address of the treasury (collects fees)
     */
    constructor(
        IERC20 _RUN,
        IRunPool _runPool,
        address _owner,
        address _treasury
    ) {
        require(_owner != address(0), "USN: _owner cannot be 0");
        require(_treasury != address(0), "USN: _treasury cannot be 0");
        require(address(_RUN) != address(0), "USN: _RUN cannot be 0");
        require(address(_runPool) != address(0), "USN: _runPool cannot be 0");
        RUN = _RUN;
        runPool = _runPool;
        treasury = _treasury;
        _setInitialOwner(_owner);
        IERC20(RUN).safeApprove(address(_runPool), type(uint256).max);
    }

    /**
     * @notice Deposits funds into the Run Flexible Pool.
     * @dev Only possible when contract not paused.
     * @param _amount: number of tokens to deposit (in RUN)
     */
    function deposit(uint256 _amount) external whenNotPaused {
        require(staking, "Not allowed to stake");
        require(
            _amount > MIN_DEPOSIT_AMOUNT,
            "Deposit amount must be greater than MIN_DEPOSIT_AMOUNT"
        );
        UserInfo storage user = userInfo[msg.sender];
        //charge performanceFee
        bool chargeFeeFromDeposit;
        uint256 currentPerformanceFee;
        uint256 performanceFeeShares;
        if (user.shares > 0) {
            uint256 totalAmount = (user.shares * balanceOf()) / totalShares;
            uint256 earnAmount = totalAmount - user.runAtLastUserAction;
            currentPerformanceFee = (earnAmount * performanceFee) / 10000;
            if (currentPerformanceFee > 0) {
                performanceFeeShares =
                    (currentPerformanceFee * totalShares) /
                    balanceOf();
                user.shares -= performanceFeeShares;
                totalShares -= performanceFeeShares;
                if (_amount >= currentPerformanceFee) {
                    chargeFeeFromDeposit = true;
                } else {
                    // withdrawByAmount have a MIN_WITHDRAW_AMOUNT limit ,so need to withdraw more than MIN_WITHDRAW_AMOUNT.
                    uint256 withdrawAmount = currentPerformanceFee <
                        MIN_WITHDRAW_AMOUNT
                        ? MIN_WITHDRAW_AMOUNT
                        : currentPerformanceFee;
                    //There will be a loss of precision when call withdrawByAmount, so need to withdraw more.
                    withdrawAmount =
                        (withdrawAmount * withdrawAmountBooster) /
                        10000;
                    runPool.withdrawByAmount(withdrawAmount);

                    currentPerformanceFee = available() >= currentPerformanceFee
                        ? currentPerformanceFee
                        : available();
                    RUN.safeTransfer(treasury, currentPerformanceFee);
                    emit ChargePerformanceFee(
                        msg.sender,
                        currentPerformanceFee,
                        performanceFeeShares
                    );
                }
            }
        }
        uint256 pool = balanceOf();
        RUN.safeTransferFrom(msg.sender, address(this), _amount);
        if (chargeFeeFromDeposit) {
            RUN.safeTransfer(treasury, currentPerformanceFee);
            emit ChargePerformanceFee(
                msg.sender,
                currentPerformanceFee,
                performanceFeeShares
            );
            pool -= currentPerformanceFee;
        }
        uint256 currentShares;
        if (totalShares != 0) {
            currentShares = (_amount * totalShares) / pool;
        } else {
            currentShares = _amount;
        }

        user.shares += currentShares;
        user.lastDepositedTime = block.timestamp;

        totalShares += currentShares;

        _earn();

        user.runAtLastUserAction = (user.shares * balanceOf()) / totalShares;
        user.lastUserActionTime = block.timestamp;

        emit DepositRun(msg.sender, _amount, currentShares, block.timestamp);
    }

    /**
     * @notice Withdraws funds from the Run Flexible Pool
     * @param _shares: Number of shares to withdraw
     */
    function withdraw(uint256 _shares) public {
        UserInfo storage user = userInfo[msg.sender];
        require(_shares > 0, "USN: Nothing to withdraw");
        require(_shares <= user.shares, "USN: Withdraw amount exceeds balance");
        //charge performanceFee
        uint256 totalAmount = (user.shares * balanceOf()) / totalShares;
        uint256 earnAmount = totalAmount - user.runAtLastUserAction;
        uint256 currentPerformanceFee;
        uint256 performanceFeeShares;
        if (earnAmount > 0) {
            currentPerformanceFee = (earnAmount * performanceFee) / 10000;
            performanceFeeShares =
                (currentPerformanceFee * totalShares) /
                balanceOf();
            user.shares -= performanceFeeShares;
            totalShares -= performanceFeeShares;
        }
        //Update withdraw shares
        if (_shares > user.shares) {
            _shares = user.shares;
        }
        //The current pool balance should not include currentPerformanceFee.
        uint256 currentAmount = (_shares *
            (balanceOf() - currentPerformanceFee)) / totalShares;
        user.shares -= _shares;
        totalShares -= _shares;
        uint256 withdrawAmount = currentAmount + currentPerformanceFee;
        if (staking) {
            // withdrawByAmount have a MIN_WITHDRAW_AMOUNT limit ,so need to withdraw more than MIN_WITHDRAW_AMOUNT.
            withdrawAmount = withdrawAmount < MIN_WITHDRAW_AMOUNT
                ? MIN_WITHDRAW_AMOUNT
                : withdrawAmount;
            //There will be a loss of precision when call withdrawByAmount, so need to withdraw more.
            withdrawAmount = (withdrawAmount * withdrawAmountBooster) / 10000;
            runPool.withdrawByAmount(withdrawAmount);
        }

        uint256 currentWithdrawFee;
        if (block.timestamp < user.lastDepositedTime + withdrawFeePeriod) {
            currentWithdrawFee = (currentAmount * withdrawFee) / 10000;
            currentAmount -= currentWithdrawFee;
        }
        //Combine two fees to reduce gas
        uint256 totalFee = currentPerformanceFee + currentWithdrawFee;
        if (totalFee > 0) {
            totalFee = available() >= totalFee ? totalFee : available();
            RUN.safeTransfer(treasury, totalFee);
            if (currentPerformanceFee > 0) {
                emit ChargePerformanceFee(
                    msg.sender,
                    currentPerformanceFee,
                    performanceFeeShares
                );
            }
            if (currentWithdrawFee > 0) {
                emit ChargeWithdrawFee(msg.sender, currentWithdrawFee);
            }
        }

        currentAmount = available() >= currentAmount
            ? currentAmount
            : available();
        RUN.safeTransfer(msg.sender, currentAmount);

        if (user.shares > 0) {
            user.runAtLastUserAction =
                (user.shares * balanceOf()) /
                totalShares;
        } else {
            user.runAtLastUserAction = 0;
        }

        user.lastUserActionTime = block.timestamp;

        emit WithdrawShares(msg.sender, currentAmount, _shares);
    }

    /**
     * @notice Withdraws all funds for a user
     */
    function withdrawAll() external {
        withdraw(userInfo[msg.sender].shares);
    }

    /**
     * @notice Calculates the price per share
     */
    function getPricePerFullShare() external view returns (uint256) {
        return totalShares == 0 ? 1e18 : (balanceOf() * 1e18) / totalShares;
    }

    /**
     * @notice Custom logic for how much the pool to be borrowed
     * @dev The contract puts 100% of the tokens to work.
     */
    function available() public view returns (uint256) {
        return RUN.balanceOf(address(this));
    }

    /**
     * @notice Calculates the total underlying tokens
     * @dev It includes tokens held by the contract and held in RunPool
     */
    function balanceOf() public view returns (uint256) {
        (uint256 shares, , , , , , , , ) = runPool.userInfo(address(this));
        uint256 pricePerFullShare = runPool.getPricePerFullShare();

        return
            RUN.balanceOf(address(this)) + (shares * pricePerFullShare) / 1e18;
    }

    /**
     * @notice Deposits tokens into RunPool to earn staking rewards
     */
    function _earn() internal {
        uint256 bal = available();
        if (bal > 0) {
            runPool.deposit(bal, 0);
        }
    }
}