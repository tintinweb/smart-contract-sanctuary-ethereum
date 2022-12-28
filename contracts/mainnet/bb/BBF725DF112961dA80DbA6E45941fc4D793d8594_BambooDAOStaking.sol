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
pragma solidity ^0.8.0;

/**
 * @title Array
 * @author artpumpkin
 * @notice Adds utility functions to an array of integers
 */
library Array {
  /**
   * @notice Removes an array item by index
   * @dev This is a O(1) time-complexity algorithm without persiting the order
   * @param array_ A reference value to the array
   * @param index_ An item index to be removed
   */
  function remove(uint256[] storage array_, uint256 index_) internal {
    require(index_ < array_.length, "index out of bound");
    array_[index_] = array_[array_.length - 1];
    array_.pop();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Recoverable.sol";
import "./Generatable.sol";
import "./Array.sol";

struct Fee {
  uint128 numerator;
  uint128 denominator;
}

struct PendingPeriod {
  uint128 repeat;
  uint128 period;
}

struct PendingAmount {
  uint32 createdAt;
  uint112 fullAmount;
  uint112 claimedAmount;
  PendingPeriod pendingPeriod;
}

/**
 * @title Contract that adds auto-compounding staking functionalities with whitelist support
 * @author artpumpkin
 * @notice Stakes any ERC20 token in a auto-compounding way using this contract
 */
contract BambooDAOStaking is Ownable, Pausable, Generatable, Recoverable {
  using Array for uint256[];
  using SafeERC20 for IERC20;

  IERC20 private immutable _token;

  uint256 private constant YEAR = 365 days;

  uint152 public rewardRate;
  uint32 public rewardDuration = 12 weeks;
  uint32 private _rewardUpdatedAt = uint32(block.timestamp);
  uint32 public rewardFinishedAt;
  bool public whitelisted = false;
  mapping(address => bool) public isWhitelisted;

  uint256 private _totalStake;
  mapping(address => uint256) private _userStake;

  uint128 private _rewardPerToken;
  uint128 private _lastRewardPerTokenPaid;
  mapping(address => uint256) private _userRewardPerTokenPaid;

  Fee public fee = Fee(0, 1000);

  PendingPeriod public pendingPeriod = PendingPeriod({ repeat: 4, period: 7 days });
  mapping(address => uint256[]) private _userPendingIds;
  mapping(address => mapping(uint256 => PendingAmount)) private _userPending;

  /**
   * @param token_ The ERC20 token address to enable staking for
   */
  constructor(IERC20 token_) {
    _token = token_;
  }

  /**
   * @notice Computes the compounded total stake in real-time
   * @return totalStake The current compounded total stake
   */
  function totalStake() public view returns (uint256) {
    return _totalStake + _earned(_totalStake, _lastRewardPerTokenPaid);
  }

  /**
   * @notice Gets the current staking APY (4 decimals)
   * @return apy The current staking APY
   */
  function apy() external view returns (uint256) {
    if (block.timestamp > rewardFinishedAt || totalStake() == 0) {
      return 0;
    }

    return (rewardRate * YEAR * 100 * 100) / totalStake();
  }

  /**
   * @notice Converts targeted APY (4 decimals) to rewards to set
   * @param apy_ The targeted APY to convert
   * @return rewards The amount of rewards to set to match the targeted APY
   */
  function apyToAlphaRewards(uint256 apy_) external view returns (uint256) {
    return (totalStake() * rewardDuration * apy_) / (YEAR * 100 * 100);
  }

  /**
   * @notice Converts targeted APY (4 decimals) to rewards to increase/decrease
   * @dev This function can only be used if the reward duration isn't finished yet
   * @param apy_ The targeted APY to convert
   * @return rewards The amount of rewards to increase/decrease to match the targeted APY
   */
  function apyToDeltaRewards(uint256 apy_) external view returns (int256) {
    require(block.timestamp <= rewardFinishedAt, "reward duration finished");

    uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);

    int256 results = int256((totalStake() * rewardDuration * apy_) / (YEAR * 100 * 100)) - int256(remainingReward);

    return results >= 0 ? results : -results;
  }

  /**
   * @notice Gets the current rewards for a specific duration in seconds
   * @param duration_ The specific duration in seconds
   * @return rewards The rewards computed for the inputed duration
   */
  function rewardsForDuration(uint256 duration_) external view returns (uint256) {
    if (block.timestamp > rewardFinishedAt) {
      return 0;
    }

    return rewardRate * duration_;
  }

  /**
   * @notice Computes the compounded user stake in real-time
   * @param account_ The user address to use
   * @return userStake The current compounded user stake
   */
  function userStake(address account_) external view returns (uint256) {
    return _userStake[account_] + earned(account_);
  }

  /**
   * @notice Returns the user pending amount metadata
   * @param account_ The user address to use
   * @param index_ The user pending index to use
   * @return pendingAmount The user pending amount metadata
   */
  function userPending(address account_, uint256 index_) public view returns (PendingAmount memory) {
    uint256 id = _userPendingIds[account_][index_];
    return _userPending[account_][id];
  }

  /**
   * @notice Computes the user claimable pending percentage
   * @param account_ The user address to use
   * @param index_ The user pending index to use
   * @dev 18 decimals were used to not lose information
   * @return percentage The user claimable pending percentage
   */
  function userClaimablePendingPercentage(address account_, uint256 index_) external view returns (uint256) {
    PendingAmount memory pendingAmount = userPending(account_, index_);
    uint256 n = getClaimablePendingPortion(pendingAmount);
    return n >= pendingAmount.pendingPeriod.repeat ? 100 * 1e9 : (n * 100 * 1e9) / pendingAmount.pendingPeriod.repeat;
  }

  /**
   * @notice Returns the user pending ids
   * @param account_ The user address to use
   * @return ids The user pending ids
   */
  function userPendingIds(address account_) external view returns (uint256[] memory) {
    return _userPendingIds[account_];
  }

  /**
   * @notice Returns the last time rewards were updated
   * @return lastTimeRewardActiveAt A timestamp of the last time the update reward modifier was called
   */
  function lastTimeRewardActiveAt() public view returns (uint256) {
    return rewardFinishedAt > block.timestamp ? block.timestamp : rewardFinishedAt;
  }

  /**
   * @notice Returns the current reward per token value
   * @return rewardPerToken The accumulated reward per token value
   */
  function rewardPerToken() public view returns (uint256) {
    if (_totalStake == 0) {
      return _rewardPerToken;
    }

    return _rewardPerToken + ((lastTimeRewardActiveAt() - _rewardUpdatedAt) * rewardRate * 1e9) / _totalStake;
  }

  /**
   * @notice Returns the total rewards available
   * @return totalDurationReward The total expected rewards for the current reward duration
   */
  function totalDurationReward() external view returns (uint256) {
    return rewardRate * rewardDuration;
  }

  /**
   * @notice Returns the user earned rewards
   * @param account_ The user address to use
   * @return earned The user earned rewards
   */
  function earned(address account_) private view returns (uint256) {
    return _earned(_userStake[account_], _userRewardPerTokenPaid[account_]);
  }

  /**
   * @notice Returns the accumulated rewards for a given staking amount
   * @param stakeAmount_ The staked token amount
   * @param rewardPerTokenPaid_ The already paid reward per token
   * @return _earned The earned rewards based on a staking amount and the reward per token paid
   */
  function _earned(uint256 stakeAmount_, uint256 rewardPerTokenPaid_) internal view returns (uint256) {
    uint256 rewardPerTokenDiff = rewardPerToken() - rewardPerTokenPaid_;
    return (stakeAmount_ * rewardPerTokenDiff) / 1e9;
  }

  /**
   * @notice This modifier is used to update the rewards metadata for a specific account
   * @notice It is called for every user or owner interaction that changes the staking, the reward pool or the reward duration
   * @notice This is an extended modifier version of the Synthetix contract to support auto-compounding
   * @notice _rewardPerToken is accumulated every second
   * @notice _rewardUpdatedAt is updated for every interaction with this modifier
   * @param account_ The user address to use
   */
  modifier updateReward(address account_) {
    _rewardPerToken = uint128(rewardPerToken());
    _rewardUpdatedAt = uint32(lastTimeRewardActiveAt());

    // auto-compounding
    if (account_ != address(0)) {
      uint256 reward = earned(account_);

      _userRewardPerTokenPaid[account_] = _rewardPerToken;
      _lastRewardPerTokenPaid = _rewardPerToken;

      _userStake[account_] += reward;
      _totalStake += reward;
    }
    _;
  }

  /**
   * @notice This modifier is used to check whether the sender is whitelisted or not
   */
  modifier onlyWhitelist() {
    require(!whitelisted || isWhitelisted[msg.sender], "sender isn't whitelisted");
    _;
  }

  /**
   * @notice Sets the contract to support whitelisting or not
   * @param value_ Boolean value indicating whether to enable whitelisting or not
   */
  function setWhitelisted(bool value_) external onlyOwner {
    whitelisted = value_;

    emit WhitelistedSet(value_);
  }

  /**
   * @notice Sets an array of users to be whitelisted or not
   * @param users_ Users addresses
   * @param values_ Boolean values indicating whether the current user to be whitelisted or not
   */
  function setIsWhitelisted(address[] calldata users_, bool[] calldata values_) external onlyOwner {
    require(users_.length == values_.length, "users_ and values_ have different lengths");

    for (uint256 i = 0; i < users_.length; i++) {
      isWhitelisted[users_[i]] = values_[i];
    }

    emit IsWhitelistedSet(users_, values_);
  }

  /**
   * @notice Stakes an amount of the ERC20 token
   * @param amount_ The amount to stake
   */
  function stake(uint256 amount_) external whenNotPaused updateReward(msg.sender) onlyWhitelist {
    // checks
    require(amount_ > 0, "invalid input amount");

    // effects
    _totalStake += amount_;
    _userStake[msg.sender] += amount_;

    // interactions
    _token.safeTransferFrom(msg.sender, address(this), amount_);

    emit Staked(msg.sender, amount_);
  }

  /**
   * @notice Creates a new pending after withdrawal
   * @param amount_ The amount to create pending for
   */
  function createPending(uint256 amount_) internal {
    uint256 id = unique();
    _userPendingIds[msg.sender].push(id);
    _userPending[msg.sender][id] = PendingAmount({ createdAt: uint32(block.timestamp), fullAmount: uint112(amount_), claimedAmount: 0, pendingPeriod: pendingPeriod });

    emit PendingCreated(msg.sender, block.timestamp, amount_);
  }

  /**
   * @notice Cancels an existing pending
   * @param index_ The pending index to cancel
   */
  function cancelPending(uint256 index_) external whenNotPaused updateReward(msg.sender) {
    PendingAmount memory pendingAmount = userPending(msg.sender, index_);
    uint256 amount = pendingAmount.fullAmount - pendingAmount.claimedAmount;
    deletePending(index_);

    // effects
    _totalStake += amount;
    _userStake[msg.sender] += amount;

    emit PendingCanceled(msg.sender, pendingAmount.createdAt, pendingAmount.fullAmount);
  }

  /**
   * @notice Deletes an existing pending
   * @param index_ The pending index to delete
   */
  function deletePending(uint256 index_) internal {
    uint256[] storage ids = _userPendingIds[msg.sender];
    uint256 id = ids[index_];
    ids.remove(index_);
    delete _userPending[msg.sender][id];
  }

  /**
   * @notice Withdraws an amount of the ERC20 token
   * @notice When you withdraw a pending will be created for that amount
   * @notice You will be able to claim the pending for after an exact vesting period
   * @param amount_ The amount to withdraw
   */
  function _withdraw(uint256 amount_) internal {
    // effects
    _totalStake -= amount_;
    _userStake[msg.sender] -= amount_;

    createPending(amount_);

    emit Withdrawn(msg.sender, amount_);
  }

  /**
   * @notice Withdraws an amount of the ERC20 token
   * @param amount_ The amount to withdraw
   */
  function withdraw(uint256 amount_) external whenNotPaused updateReward(msg.sender) {
    // checks
    require(_userStake[msg.sender] > 0, "user has no active stake");
    require(amount_ > 0 && _userStake[msg.sender] >= amount_, "invalid input amount");

    // effects
    _withdraw(amount_);
  }

  /**
   * @notice Withdraws the full amount of the ERC20 token
   */
  function withdrawAll() external whenNotPaused updateReward(msg.sender) {
    // checks
    require(_userStake[msg.sender] > 0, "user has no active stake");

    // effects
    _withdraw(_userStake[msg.sender]);
  }

  /**
   * @notice Gets the user claimable pending portion
   * @param pendingAmount_ The pending amount metadata to use
   */
  function getClaimablePendingPortion(PendingAmount memory pendingAmount_) private view returns (uint256) {
    return (block.timestamp - pendingAmount_.createdAt) / pendingAmount_.pendingPeriod.period; // 0 1 2 3 4
  }

  /**
   * @notice Updates the claiming fee
   * @param numerator_ The fee numerator
   * @param denominator_ The fee denominator
   */
  function setFee(uint128 numerator_, uint128 denominator_) external onlyOwner {
    require(denominator_ != 0, "denominator must not equal 0");
    fee = Fee(numerator_, denominator_);
    emit FeeSet(numerator_, denominator_);
  }

  /**
   * @notice User can claim a specific pending by index
   * @param index_ The pending index to claim
   */
  function claim(uint256 index_) external whenNotPaused {
    // checks
    uint256 id = _userPendingIds[msg.sender][index_];
    PendingAmount storage pendingAmount = _userPending[msg.sender][id];

    uint256 n = getClaimablePendingPortion(pendingAmount);
    require(n != 0, "claim is still pending");

    uint256 amount;
    /**
     * @notice n is the user claimable pending portion
     * @notice Checking if user n and the user MAX n are greater than or equal
     * @notice That way we know if the user wants to claim the full amount or just part of it
     */
    if (n >= pendingAmount.pendingPeriod.repeat) {
      amount = pendingAmount.fullAmount - pendingAmount.claimedAmount;
    } else {
      uint256 percentage = (n * 1e9) / pendingAmount.pendingPeriod.repeat;
      amount = (pendingAmount.fullAmount * percentage) / 1e9 - pendingAmount.claimedAmount;
    }

    // effects
    /**
     * @notice Pending is completely done
     * @notice It will remove the pending item
     */
    if (n >= pendingAmount.pendingPeriod.repeat) {
      uint256 createdAt = pendingAmount.createdAt;
      uint256 fullAmount = pendingAmount.fullAmount;
      deletePending(index_);
      emit PendingFinished(msg.sender, createdAt, fullAmount);
    }
    /**
     * @notice Pending is partially done
     * @notice It will update the pending item
     */
    else {
      pendingAmount.claimedAmount += uint112(amount);
      emit PendingUpdated(msg.sender, pendingAmount.createdAt, pendingAmount.fullAmount);
    }

    // interactions
    uint256 feeAmount = (amount * fee.numerator) / fee.denominator;
    _token.safeTransfer(msg.sender, amount - feeAmount);

    emit Claimed(msg.sender, amount);
  }

  /**
   * @notice Owner can set staking rewards
   * @param reward_ The reward amount to set
   */
  function setReward(uint256 reward_) external onlyOwner updateReward(address(0)) {
    resetReward();

    // checks
    require(reward_ > 0, "invalid input amount");

    // effects
    rewardRate = uint152(reward_ / rewardDuration);
    _rewardUpdatedAt = uint32(block.timestamp);
    rewardFinishedAt = uint32(block.timestamp + rewardDuration);

    // interactions
    _token.safeTransferFrom(owner(), address(this), reward_);

    emit RewardSet(reward_);
  }

  /**
   * @notice Owner can increase staking rewards only if the duration isn't finished yet
   * @notice Increasing rewards doesn't alter the reward finish time
   * @param reward_ The reward amount to increase
   */
  function increaseReward(uint256 reward_) external onlyOwner updateReward(address(0)) {
    // checks
    require(reward_ > 0, "invalid input amount");
    require(block.timestamp <= rewardFinishedAt, "reward duration finished");

    // effects
    uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);
    rewardRate = uint152((remainingReward + reward_) / (rewardFinishedAt - block.timestamp));
    _rewardUpdatedAt = uint32(block.timestamp);

    // interactions
    _token.safeTransferFrom(owner(), address(this), reward_);

    emit RewardIncreased(reward_);
  }

  /**
   * @notice Owner can decrease staking rewards only if the duration isn't finished yet
   * @notice Decreasing rewards doesn't alter the reward finish time
   * @param reward_ The reward amount to decrease
   */
  function decreaseReward(uint256 reward_) external onlyOwner updateReward(address(0)) {
    // checks
    require(reward_ > 0, "invalid input amount");
    require(block.timestamp <= rewardFinishedAt, "reward duration finished");

    // effects
    uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);
    require(remainingReward > reward_, "invalid input amount");

    rewardRate = uint152((remainingReward - reward_) / (rewardFinishedAt - block.timestamp));
    _rewardUpdatedAt = uint32(block.timestamp);

    // interactions
    _token.safeTransfer(owner(), reward_);

    emit RewardDecreased(reward_);
  }

  /**
   * @notice Owner can rest all rewards and reward finish time back to 0
   */
  function resetReward() public onlyOwner updateReward(address(0)) {
    if (rewardFinishedAt <= block.timestamp) {
      rewardRate = 0;
      _rewardUpdatedAt = uint32(block.timestamp);
      rewardFinishedAt = uint32(block.timestamp);
    } else {
      // checks
      uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);

      // effects
      rewardRate = 0;
      _rewardUpdatedAt = uint32(block.timestamp);
      rewardFinishedAt = uint32(block.timestamp);

      // interactions
      _token.safeTransfer(owner(), remainingReward);
    }

    emit RewardReseted();
  }

  /**
   * @notice Owner can update the reward duration
   * @notice It can only be updated if the old reward duration is already finished
   * @param rewardDuration_ The reward rewardDuration_ to use
   */
  function setRewardDuration(uint32 rewardDuration_) external onlyOwner {
    require(block.timestamp > rewardFinishedAt, "reward duration must be finalized");

    rewardDuration = rewardDuration_;

    emit RewardDurationSet(rewardDuration_);
  }

  /**
   * @notice Owner can set the pending period
   * @notice If we want a vesting period of 7 days 4 times, we can have the repeat as 4 and the period as 7 days
   * @param repeat_ The number of times to keep a withdrawal pending
   * @param period_ The period between each repeat
   */
  function setPendingPeriod(uint128 repeat_, uint128 period_) external onlyOwner {
    pendingPeriod = PendingPeriod(repeat_, period_);
    emit PendingPeriodSet(repeat_, period_);
  }

  /**
   * @notice Owner can pause the staking contract
   */
  function pause() external whenNotPaused onlyOwner {
    _pause();
  }

  /**
   * @notice Owner can resume the staking contract
   */
  function unpause() external whenPaused onlyOwner {
    _unpause();
  }

  event Staked(address indexed account, uint256 amount);
  event PendingCreated(address indexed account, uint256 createdAt, uint256 amount);
  event PendingUpdated(address indexed account, uint256 createdAt, uint256 amount);
  event PendingFinished(address indexed account, uint256 createdAt, uint256 amount);
  event PendingCanceled(address indexed account, uint256 createdAt, uint256 amount);
  event Withdrawn(address indexed account, uint256 amount);
  event Claimed(address indexed account, uint256 amount);
  event RewardSet(uint256 amount);
  event RewardIncreased(uint256 amount);
  event RewardDecreased(uint256 amount);
  event RewardReseted();
  event RewardDurationSet(uint256 duration);
  event PendingPeriodSet(uint256 repeat, uint256 period);
  event FeeSet(uint256 numerator, uint256 denominator);
  event WhitelistedSet(bool value);
  event IsWhitelistedSet(address[] users, bool[] values);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Generatable
 * @author artpumpkin
 * @notice Generates a unique id
 */
contract Generatable {
  uint256 private _id;

  /**
   * @notice Generates a unique id
   * @return id The newly generated id
   */
  function unique() internal returns (uint256) {
    _id += 1;
    return _id;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Recoverable
 * @author artpumpkin
 * @notice Recovers stuck BNB or ERC20 tokens
 * @dev You can inhertit from this contract to support recovering stuck tokens or BNB
 */
contract Recoverable is Ownable {
  using SafeERC20 for IERC20;

  /**
   * @notice Recovers stuck ERC20 token in the contract
   * @param token_ An ERC20 token address
   * @param amount_ Amount to recover
   */
  function recoverERC20(address token_, uint256 amount_) external onlyOwner {
    IERC20 erc20 = IERC20(token_);
    require(erc20.balanceOf(address(this)) >= amount_, "invalid input amount");

    erc20.safeTransfer(owner(), amount_);
  }
}