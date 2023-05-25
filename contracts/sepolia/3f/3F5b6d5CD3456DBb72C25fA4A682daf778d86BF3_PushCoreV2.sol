// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

pragma solidity >=0.6.0 <0.7.0;

contract EPNSCoreStorageV1_5 {
    /* ***************

  DEFINE ENUMS AND CONSTANTS

 *************** */

    // For Message Type
    enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual,
        TimeBound,
        TokenGaited
    }
    enum ChannelAction {
        ChannelRemoved,
        ChannelAdded,
        ChannelUpdated
    }

    /**
     * @notice Channel Struct that includes imperative details about a specific Channel.
     **/
    struct Channel {
        // @notice Denotes the Channel Type
        ChannelType channelType;
        /** @notice Symbolizes Channel's State:
         * 0 -> INACTIVE,
         * 1 -> ACTIVATED
         * 2 -> DeActivated By Channel Owner,
         * 3 -> BLOCKED by pushChannelAdmin/Governance
         **/
        uint8 channelState;
        // @notice denotes the address of the verifier of the Channel
        address verifiedBy;
        // @notice Total Amount of Dai deposited during Channel Creation
        uint256 poolContribution;
        // @notice Represents the Historical Constant
        uint256 channelHistoricalZ;
        // @notice Represents the FS Count
        uint256 channelFairShareCount;
        // @notice The last update block number, used to calculate fair share
        uint256 channelLastUpdate;
        // @notice Helps in defining when channel started for pool and profit calculation
        uint256 channelStartBlock;
        // @notice Helps in outlining when channel was updated
        uint256 channelUpdateBlock;
        // @notice The individual weight to be applied as per pool contribution
        uint256 channelWeight;
        // @notice The Expiry TimeStamp in case of TimeBound Channel Types
        uint256 expiryTime;
    }

    /* ***************
    MAPPINGS
 *************** */

    mapping(address => Channel) public channels;
    mapping(uint256 => address) public channelById;
    mapping(address => string) public channelNotifSettings;

    /* ***************
    STATE VARIABLES
 *************** */
    string public constant name = "EPNS_CORE_V2";
    bool oneTimeCheck;
    bool public isMigrationComplete;

    address public pushChannelAdmin;
    address public governance;
    address public daiAddress;
    address public aDaiAddress;
    address public WETH_ADDRESS;
    address public epnsCommunicator;
    address public UNISWAP_V2_ROUTER;
    address public PUSH_TOKEN_ADDRESS;
    address public lendingPoolProviderAddress;

    uint256 public REFERRAL_CODE;
    uint256 ADJUST_FOR_FLOAT;
    uint256 public channelsCount;

    //  @notice Helper Variables for FSRatio Calculation | GROUPS = CHANNELS
    uint256 public groupNormalizedWeight;
    uint256 public groupHistoricalZ;
    uint256 public groupLastUpdate;
    uint256 public groupFairShareCount;

    // @notice Necessary variables for Keeping track of Funds and Fees
    uint256 public CHANNEL_POOL_FUNDS;
    uint256 public PROTOCOL_POOL_FEES;
    uint256 public ADD_CHANNEL_MIN_FEES;
    uint256 public FEE_AMOUNT;
    uint256 public MIN_POOL_CONTRIBUTION;
}

pragma solidity >=0.6.0 <0.7.0;

contract EPNSCoreStorageV2 {
    /* *** V2 State variables *** */
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name, uint256 chainId, address verifyingContract)"
        );
    bytes32 public constant CREATE_CHANNEL_TYPEHASH =
        keccak256(
            "CreateChannel(ChannelType channelType, bytes identity, uint256 amount, uint256 channelExpiryTime, uint256 nonce, uint256 expiry)"
        );

    mapping(address => uint256) public nonces;
    mapping(address => uint256) public channelUpdateCounter;
    /** Staking V2 state variables **/
    mapping(address => uint256) public usersRewardsClaimed;

    //@notice: Stores all user's staking details
    struct UserFessInfo {
        uint256 stakedAmount;
        uint256 stakedWeight;
        uint256 lastStakedBlock;
        uint256 lastClaimedBlock;
        mapping(uint256 => uint256) epochToUserStakedWeight;
    }

    uint256 public genesisEpoch; // Block number at which Stakig starts
    uint256 lastEpochInitialized; // The last EPOCH ID initialized with the respective epoch rewards
    uint256 lastTotalStakeEpochInitialized; // The last EPOCH ID initialized with the respective total staked weight
    uint256 public totalStakedWeight; // Total token weight staked in Protocol at any given time
    uint256 public previouslySetEpochRewards; // Amount of rewards set in last initialized epoch
    uint256 public constant epochDuration = 21 * 7156; // 21 * number of blocks per day(7156) ~ 20 day approx

    // @notice: Stores all the individual epoch rewards
    mapping(uint256 => uint256) public epochRewards;
    // @notice: Stores User's Fees Details
    mapping(address => UserFessInfo) public userFeesInfo;
    // @notice: Stores the total staked weight at a specific epoch.
    mapping(uint256 => uint256) public epochToTotalStakedWeight;

    /** Handling bridged information **/
    address public bridgeAddress;
    address public relayerAddress;
    mapping(address => uint256) public celebUserFunds;
}

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

/**
 * EPNS Core is the main protocol that deals with the imperative
 * features and functionalities like Channel Creation, pushChannelAdmin etc.
 *
 * This protocol will be specifically deployed on Ethereum Blockchain while the Communicator
 * protocols can be deployed on Multiple Chains.
 * The EPNS Core is more inclined towards the storing and handling the Channel related
 * Functionalties.
 **/
import "./EPNSCoreStorageV1_5.sol";
import "./EPNSCoreStorageV2.sol";
import "../interfaces/IPUSH.sol";
import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IEPNSCommV1.sol";
import "../interfaces/ITokenBridge.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract PushCoreV2 is
    Initializable,
    EPNSCoreStorageV1_5,
    PausableUpgradeable,
    EPNSCoreStorageV2
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ***************
        EVENTS
     *************** */
    event UpdateChannel(address indexed channel, bytes identity);
    event RewardsClaimed(address indexed user, uint256 rewardAmount);
    event ChannelVerified(address indexed channel, address indexed verifier);
    event ChannelVerificationRevoked(
        address indexed channel,
        address indexed revoker
    );

    event DeactivateChannel(
        address indexed channel,
        uint256 indexed amountRefunded
    );
    event ReactivateChannel(
        address indexed channel,
        uint256 indexed amountDeposited
    );
    event ChannelBlocked(address indexed channel);
    event AddChannel(
        address indexed channel,
        ChannelType indexed channelType,
        bytes identity
    );
    event ChannelNotifcationSettingsAdded(
        address _channel,
        uint256 totalNotifOptions,
        string _notifSettings,
        string _notifDescription
    );
    event AddSubGraph(address indexed channel, bytes _subGraphData);
    event TimeBoundChannelDestroyed(
        address indexed channel,
        uint256 indexed amountRefunded
    );
    event ChannelOwnershipTransfer(
        address indexed channel,
        address indexed newOwner
    );
    event Staked(address indexed user, uint256 indexed amountStaked);
    event UnStaked(address indexed user, uint256 indexed amountUnstaked);
    event RewardsHarvested(
        address indexed user,
        uint256 indexed rewardAmount,
        uint256 fromEpoch,
        uint256 tillEpoch
    );
    event RelayerAddressUpdated(
        address indexed oldRelayer,
        address indexed newRelayer
    );
    event BridgeAddressUpdated(
        address indexed oldBridge,
        address indexed newBridge
    );
    event IncentivizeChatReqReceived(
        address requestSender,
        address requestReceiver,
        uint256 amountForReqReceiver,
        uint256 feePoolAmount,
        uint256 timestamp
    );
    event ChatIncentiveClaimed(
        address indexed user,
        uint256 indexed amountClaimed
    );

    /* ***************
        INITIALIZER
    *************** */

    function initialize(
        address _pushChannelAdmin,
        address _pushTokenAddress,
        address _wethAddress,
        address _uniswapRouterAddress,
        address _lendingPoolProviderAddress,
        address _daiAddress,
        address _aDaiAddress,
        uint256 _referralCode
    ) public initializer returns (bool success) {
        // setup addresses
        pushChannelAdmin = _pushChannelAdmin;
        governance = _pushChannelAdmin; // Will be changed on-Chain governance Address later
        daiAddress = _daiAddress;
        aDaiAddress = _aDaiAddress;
        WETH_ADDRESS = _wethAddress;
        REFERRAL_CODE = _referralCode;
        PUSH_TOKEN_ADDRESS = _pushTokenAddress;
        UNISWAP_V2_ROUTER = _uniswapRouterAddress;
        lendingPoolProviderAddress = _lendingPoolProviderAddress;

        FEE_AMOUNT = 10 ether; // PUSH Amount that will be charged as Protocol Pool Fees
        MIN_POOL_CONTRIBUTION = 50 ether; // Channel's poolContribution should never go below MIN_POOL_CONTRIBUTION
        ADD_CHANNEL_MIN_FEES = 50 ether; // can never be below MIN_POOL_CONTRIBUTION

        ADJUST_FOR_FLOAT = 10**7;
        groupLastUpdate = block.number;
        groupNormalizedWeight = ADJUST_FOR_FLOAT; // Always Starts with 1 * ADJUST FOR FLOAT

        // Create Channel
        success = true;
    }

    /* ***************

    SETTER & HELPER FUNCTIONS

    *************** */
    function onlyPushChannelAdmin() private {
        require(
            msg.sender == pushChannelAdmin,
            "PushCoreV2::onlyPushChannelAdmin: Invalid Caller"
        );
    }

    function onlyGovernance() private {
        require(
            msg.sender == governance,
            "PushCoreV2::onlyGovernance: Invalid Caller"
        );
    }

    function onlyActivatedChannels(address _channel) private {
        require(
            channels[_channel].channelState == 1,
            "PushCoreV2::onlyActivatedChannels: Invalid Channel"
        );
    }

    function onlyChannelOwner(address _channel) private {
        require(
            ((channels[_channel].channelState == 1 && msg.sender == _channel) ||
                (msg.sender == pushChannelAdmin && _channel == address(0x0))),
            "PushCoreV2::onlyChannelOwner: Invalid Channel Owner"
        );
    }

    function addSubGraph(bytes calldata _subGraphData) external {
        onlyActivatedChannels(msg.sender);
        emit AddSubGraph(msg.sender, _subGraphData);
    }

    function setEpnsCommunicatorAddress(address _commAddress) external {
        onlyPushChannelAdmin();
        epnsCommunicator = _commAddress;
    }

    function setGovernanceAddress(address _governanceAddress) external {
        onlyPushChannelAdmin();
        governance = _governanceAddress;
    }

    function setFeeAmount(uint256 _newFees) external {
        onlyGovernance();
        require(
            _newFees > 0 && _newFees < ADD_CHANNEL_MIN_FEES,
            "PushCoreV2::setFeeAmount: Invalid Fee"
        );
        FEE_AMOUNT = _newFees;
    }

    function setMinPoolContribution(uint256 _newAmount) external {
        onlyGovernance();
        require(
            _newAmount > 0,
            "PushCoreV2::setMinPoolContribution: Invalid Amount"
        );
        MIN_POOL_CONTRIBUTION = _newAmount;
    }

    function pauseContract() external {
        onlyGovernance();
        _pause();
    }

    function unPauseContract() external {
        onlyGovernance();
        _unpause();
    }

    /**
     * @notice Allows to set the Minimum amount threshold for Creating Channels
     *
     * @dev    Minimum required amount can never be below MIN_POOL_CONTRIBUTION
     *
     * @param _newFees new minimum fees required for Channel Creation
     **/
    function setMinChannelCreationFees(uint256 _newFees) external {
        onlyGovernance();
        require(
            _newFees >= MIN_POOL_CONTRIBUTION,
            "PushCoreV2::setMinChannelCreationFees: Invalid Fees"
        );
        ADD_CHANNEL_MIN_FEES = _newFees;
    }

    function transferPushChannelAdminControl(address _newAdmin) external {
        onlyPushChannelAdmin();
        require(
            _newAdmin != address(0),
            "PushCoreV2::transferPushChannelAdminControl: Invalid Address"
        );
        require(
            _newAdmin != pushChannelAdmin,
            "PushCoreV2::transferPushChannelAdminControl: Similar Admnin Address"
        );
        pushChannelAdmin = _newAdmin;
    }

    /* ***********************************

        CHANNEL RELATED FUNCTIONALTIES

    **************************************/
    /**
     * @notice Allows Channel Owner to update their Channel's Details like Description, Name, Logo, etc by passing in a new identity bytes hash
     *
     * @dev  Only accessible when contract is NOT Paused
     *       Only accessible when Caller is the Channel Owner itself
     *       If Channel Owner is updating the Channel Meta for the first time:
     *       Required Fees => 50 PUSH tokens
     *
     *       If Channel Owner is updating the Channel Meta for the N time:
     *       Required Fees => (50 * N) PUSH Tokens
     *
     *       Total fees goes to PROTOCOL_POOL_FEES
     *       Updates the channelUpdateCounter
     *       Updates the channelUpdateBlock
     *       Records the Block Number of the Block at which the Channel is being updated
     *       Emits an event with the new identity for the respective Channel Address
     *
     * @param _channel     address of the Channel
     * @param _newIdentity bytes Value for the New Identity of the Channel
     * @param _amount amount of PUSH Token required for updating channel details.
     **/
    function updateChannelMeta(
        address _channel,
        bytes calldata _newIdentity,
        uint256 _amount
    ) external whenNotPaused {
        onlyChannelOwner(_channel);
        uint256 updateCounter = channelUpdateCounter[_channel].add(1);
        uint256 requiredFees = ADD_CHANNEL_MIN_FEES.mul(updateCounter);

        require(
            _amount >= requiredFees,
            "PushCoreV2::updateChannelMeta: Insufficient Deposit Amount"
        );
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(_amount);
        channelUpdateCounter[_channel] = updateCounter;
        channels[_channel].channelUpdateBlock = block.number;

        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            _channel,
            address(this),
            _amount
        );
        emit UpdateChannel(_channel, _newIdentity);
    }

    /**
     * @notice An external function that allows users to Create their Own Channels by depositing a valid amount of PUSH
     * @dev    Only allows users to Create One Channel for a specific address.
     *         Only allows a Valid Channel Type to be assigned for the Channel Being created.
     *         Validates and Transfers the amount of PUSH  from the Channel Creator to the EPNS Core Contract
     *
     * @param  _channelType the type of the Channel Being created
     * @param  _identity the bytes value of the identity of the Channel
     * @param  _amount Amount of PUSH  to be deposited before Creating the Channel
     * @param  _channelExpiryTime the expiry time for time bound channels
     **/
    function createChannelWithPUSH(
        ChannelType _channelType,
        bytes calldata _identity,
        uint256 _amount,
        uint256 _channelExpiryTime
    ) external whenNotPaused {
        require(
            _amount >= ADD_CHANNEL_MIN_FEES,
            "PushCoreV2::_createChannelWithPUSH: Insufficient Deposit Amount"
        );
        require(
            channels[msg.sender].channelState == 0,
            "PushCoreV2::onlyInactiveChannels: Channel already Activated"
        );
        require(
            (_channelType == ChannelType.InterestBearingOpen ||
                _channelType == ChannelType.InterestBearingMutual ||
                _channelType == ChannelType.TimeBound ||
                _channelType == ChannelType.TokenGaited),
            "PushCoreV2::onlyUserAllowedChannelType: Invalid Channel Type"
        );

        emit AddChannel(msg.sender, _channelType, _identity);

        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _createChannel(msg.sender, _channelType, _amount, _channelExpiryTime);
    }

    /**
     * @notice Base Channel Creation Function that allows users to Create Their own Channels and Stores crucial details about the Channel being created
     * @dev    -Initializes the Channel Struct
     *         -Subscribes the Channel's Owner to Imperative EPNS Channels as well as their Own Channels
     *         - Updates the CHANNEL_POOL_FUNDS and PROTOCOL_POOL_FEES in the contract.
     *
     * @param _channel         address of the channel being Created
     * @param _channelType     The type of the Channel
     * @param _amountDeposited The total amount being deposited while Channel Creation
     * @param _channelExpiryTime the expiry time for time bound channels
     **/
    function _createChannel(
        address _channel,
        ChannelType _channelType,
        uint256 _amountDeposited,
        uint256 _channelExpiryTime
    ) private {
        uint256 poolFeeAmount = FEE_AMOUNT;
        uint256 poolFundAmount = _amountDeposited.sub(poolFeeAmount);
        //store funds in pool_funds & pool_fees
        CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.add(poolFundAmount);
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(poolFeeAmount);

        // Calculate channel weight
        uint256 _channelWeight = poolFundAmount.mul(ADJUST_FOR_FLOAT).div(
            MIN_POOL_CONTRIBUTION
        );
        // Next create the channel and mark user as channellized
        channels[_channel].channelState = 1;
        channels[_channel].poolContribution = poolFundAmount;
        channels[_channel].channelType = _channelType;
        channels[_channel].channelStartBlock = block.number;
        channels[_channel].channelUpdateBlock = block.number;
        channels[_channel].channelWeight = _channelWeight;
        // Add to map of addresses and increment channel count
        uint256 _channelsCount = channelsCount;
        channelById[_channelsCount] = _channel;
        channelsCount = _channelsCount.add(1);

        if (_channelType == ChannelType.TimeBound) {
            require(
                _channelExpiryTime > block.timestamp,
                "PushCoreV2::createChannel: Invalid channelExpiryTime"
            );
            channels[_channel].expiryTime = _channelExpiryTime;
        }

        // Subscribe them to their own channel as well
        address _epnsCommunicator = epnsCommunicator;
        if (_channel != pushChannelAdmin) {
            IEPNSCommV1(_epnsCommunicator).subscribeViaCore(_channel, _channel);
        }

        // All Channels are subscribed to EPNS Alerter as well, unless it's the EPNS Alerter channel iteself
        if (_channel != address(0x0)) {
            IEPNSCommV1(_epnsCommunicator).subscribeViaCore(
                address(0x0),
                _channel
            );
            IEPNSCommV1(_epnsCommunicator).subscribeViaCore(
                _channel,
                pushChannelAdmin
            );
        }
    }

    /**
     * @notice Function that allows Channel Owners to Destroy their Time-Bound Channels
     * @dev    - Can only be called the owner of the Channel or by the EPNS Governance/Admin.
     *         - EPNS Governance/Admin can only destory a channel after 14 Days of its expriation timestamp.
     *         - Can only be called if the Channel is of type - TimeBound
     *         - Can only be called after the Channel Expiry time is up.
     *         - If Channel Owner destroys the channel after expiration, he/she recieves back refundable amount & CHANNEL_POOL_FUNDS decreases.
     *         - If Channel is destroyed by EPNS Governance/Admin, No refunds for channel owner. Refundable Push tokens are added to PROTOCOL_POOL_FEES.
     *         - Deletes the Channel completely
     *         - It transfers back refundable tokenAmount back to the USER.
     **/

    function destroyTimeBoundChannel(address _channelAddress)
        external
        whenNotPaused
    {
        onlyActivatedChannels(_channelAddress);
        Channel memory channelData = channels[_channelAddress];

        require(
            channelData.channelType == ChannelType.TimeBound,
            "PushCoreV2::destroyTimeBoundChannel: Channel not TIME BOUND"
        );
        require(
            (msg.sender == _channelAddress &&
                channelData.expiryTime < block.timestamp) ||
                (msg.sender == pushChannelAdmin &&
                    channelData.expiryTime.add(14 days) < block.timestamp),
            "PushCoreV2::destroyTimeBoundChannel: Invalid Caller or Channel Not Expired"
        );
        uint256 totalRefundableAmount = channelData.poolContribution;

        if (msg.sender != pushChannelAdmin) {
            CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.sub(totalRefundableAmount);
            IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(
                msg.sender,
                totalRefundableAmount
            );
        } else {
            CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.sub(totalRefundableAmount);
            PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(totalRefundableAmount);
        }
        // Unsubscribing from imperative Channels
        address _epnsCommunicator = epnsCommunicator;
        IEPNSCommV1(_epnsCommunicator).unSubscribeViaCore(
            address(0x0),
            _channelAddress
        );
        IEPNSCommV1(_epnsCommunicator).unSubscribeViaCore(
            _channelAddress,
            _channelAddress
        );
        IEPNSCommV1(_epnsCommunicator).unSubscribeViaCore(
            _channelAddress,
            pushChannelAdmin
        );
        // Decrement Channel Count and Delete Channel Completely
        channelsCount = channelsCount.sub(1);
        delete channels[_channelAddress];

        emit TimeBoundChannelDestroyed(msg.sender, totalRefundableAmount);
    }

    /** @notice - Deliminated Notification Settings string contains -> Total Notif Options + Notification Settings
     * For instance: 5+1-0+2-50-20-100+1-1+2-78-10-150
     *  5 -> Total Notification Options provided by a Channel owner
     *
     *  For Boolean Type Notif Options
     *  1-0 -> 1 stands for BOOLEAN type - 0 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case FALSE.
     *  1-1 stands for BOOLEAN type - 1 stands for Default Boolean Type for that Notifcation(set by Channel Owner), In this case TRUE.
     *
     *  For SLIDER TYPE Notif Options
     *   2-50-20-100 -> 2 stands for SLIDER TYPE - 50 stands for Default Value for that Option - 20 is the Start Range of that SLIDER - 100 is the END Range of that SLIDER Option
     *  2-78-10-150 -> 2 stands for SLIDER TYPE - 78 stands for Default Value for that Option - 10 is the Start Range of that SLIDER - 150 is the END Range of that SLIDER Option
     *
     *  @param _notifOptions - Total Notification options provided by the Channel Owner
     *  @param _notifSettings- Deliminated String of Notification Settings
     *  @param _notifDescription - Description of each Notification that depicts the Purpose of that Notification
     *  @param _amountDeposited - Fees required for setting up channel notification settings
     **/
    function createChannelSettings(
        uint256 _notifOptions,
        string calldata _notifSettings,
        string calldata _notifDescription,
        uint256 _amountDeposited
    ) external {
        onlyActivatedChannels(msg.sender);
        require(
            _amountDeposited >= ADD_CHANNEL_MIN_FEES,
            "PushCoreV2::createChannelSettings: Insufficient Funds Passed"
        );

        string memory notifSetting = string(
            abi.encodePacked(
                Strings.toString(_notifOptions),
                "+",
                _notifSettings
            )
        );
        channelNotifSettings[msg.sender] = notifSetting;

        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(_amountDeposited);
        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            _amountDeposited
        );
        emit ChannelNotifcationSettingsAdded(
            msg.sender,
            _notifOptions,
            notifSetting,
            _notifDescription
        );
    }

    /**
     * @notice Allows Channel Owner to Deactivate his/her Channel for any period of Time. Channels Deactivated can be Activated again.
     * @dev    - Function can only be Called by Already Activated Channels
     *         - Calculates the totalRefundableAmount for the Channel Owner.
     *         - The function deducts MIN_POOL_CONTRIBUTION from refundAble amount to ensure that channel's weight & poolContribution never becomes ZERO.
     *         - Updates the State of the Channel(channelState) and the New Channel Weight in the Channel's Struct
     *         - In case, the Channel Owner wishes to reactivate his/her channel, they need to Deposit at least the Minimum required PUSH  while reactivating.
     **/

    function deactivateChannel() external whenNotPaused {
        onlyActivatedChannels(msg.sender);
        Channel storage channelData = channels[msg.sender];

        uint256 minPoolContribution = MIN_POOL_CONTRIBUTION;
        uint256 totalRefundableAmount = channelData.poolContribution.sub(
            minPoolContribution
        );

        uint256 _newChannelWeight = minPoolContribution
            .mul(ADJUST_FOR_FLOAT)
            .div(minPoolContribution);

        channelData.channelState = 2;
        CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.sub(totalRefundableAmount);
        channelData.channelWeight = _newChannelWeight;
        channelData.poolContribution = minPoolContribution;

        IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(
            msg.sender,
            totalRefundableAmount
        );

        emit DeactivateChannel(msg.sender, totalRefundableAmount);
    }

    /**
     * @notice Allows Channel Owner to Reactivate his/her Channel again.
     * @dev    - Function can only be called by previously Deactivated Channels
     *         - Channel Owner must Depost at least minimum amount of PUSH  to reactivate his/her channel.
     *         - Deposited PUSH amount is distributed between CHANNEL_POOL_FUNDS and PROTOCOL_POOL_FEES
     *         - Calculation of the new Channel Weight and poolContribution is performed and stored
     *         - Updates the State of the Channel(channelState) in the Channel's Struct.
     * @param _amount Amount of PUSH to be deposited
     **/

    function reactivateChannel(uint256 _amount) external whenNotPaused {
        require(
            _amount >= ADD_CHANNEL_MIN_FEES,
            "PushCoreV2::reactivateChannel: Insufficient Funds"
        );
        require(
            channels[msg.sender].channelState == 2,
            "PushCoreV2::onlyDeactivatedChannels: Channel is Active"
        );

        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        uint256 poolFeeAmount = FEE_AMOUNT;
        uint256 poolFundAmount = _amount.sub(poolFeeAmount);
        //store funds in pool_funds & pool_fees
        CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.add(poolFundAmount);
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(poolFeeAmount);

        Channel storage channelData = channels[msg.sender];

        uint256 _newPoolContribution = channelData.poolContribution.add(
            poolFundAmount
        );
        uint256 _newChannelWeight = _newPoolContribution
            .mul(ADJUST_FOR_FLOAT)
            .div(MIN_POOL_CONTRIBUTION);

        channelData.channelState = 1;
        channelData.poolContribution = _newPoolContribution;
        channelData.channelWeight = _newChannelWeight;

        emit ReactivateChannel(msg.sender, _amount);
    }

    /**
     * @notice ALlows the pushChannelAdmin to Block any particular channel Completely.
     *
     * @dev    - Can only be called by pushChannelAdmin
     *         - Can only be Called for Activated Channels
     *         - Can only Be Called for NON-BLOCKED Channels
     *
     *         - Updates channel's state to BLOCKED ('3')
     *         - Decreases the Channel Count
     *         - Since there is no refund, the channel's poolContribution is added to PROTOCOL_POOL_FEES and Removed from CHANNEL_POOL_FUNDS
     *         - Emit 'ChannelBlocked' Event
     * @param _channelAddress Address of the Channel to be blocked
     **/

    function blockChannel(address _channelAddress) external whenNotPaused {
        onlyPushChannelAdmin();
        require(
            ((channels[_channelAddress].channelState != 3) &&
                (channels[_channelAddress].channelState != 0)),
            "PushCoreV2::onlyUnblockedChannels: Invalid Channel"
        );
        uint256 minPoolContribution = MIN_POOL_CONTRIBUTION;
        Channel storage channelData = channels[_channelAddress];
        // add channel's currentPoolContribution to PoolFees - (no refunds if Channel is blocked)
        // Decrease CHANNEL_POOL_FUNDS by currentPoolContribution
        uint256 currentPoolContribution = channelData.poolContribution.sub(
            minPoolContribution
        );
        CHANNEL_POOL_FUNDS = CHANNEL_POOL_FUNDS.sub(currentPoolContribution);
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(currentPoolContribution);

        uint256 _newChannelWeight = minPoolContribution
            .mul(ADJUST_FOR_FLOAT)
            .div(minPoolContribution);

        channelsCount = channelsCount.sub(1);
        channelData.channelState = 3;
        channelData.channelWeight = _newChannelWeight;
        channelData.channelUpdateBlock = block.number;
        channelData.poolContribution = minPoolContribution;

        emit ChannelBlocked(_channelAddress);
    }

    /* **************
    => CHANNEL VERIFICATION FUNCTIONALTIES <=
    *************** */

    /**
     * @notice    Function is designed to tell if a channel is verified or not
     * @dev       Get if channel is verified or not
     * @param    _channel Address of the channel to be Verified
     * @return   verificationStatus  Returns 0 for not verified, 1 for primary verification, 2 for secondary verification
     **/
    function getChannelVerfication(address _channel)
        public
        view
        returns (uint8 verificationStatus)
    {
        address verifiedBy = channels[_channel].verifiedBy;
        bool logicComplete = false;

        // Check if it's primary verification
        if (
            verifiedBy == pushChannelAdmin ||
            _channel == address(0x0) ||
            _channel == pushChannelAdmin
        ) {
            // primary verification, mark and exit
            verificationStatus = 1;
        } else {
            // can be secondary verification or not verified, dig deeper
            while (!logicComplete) {
                if (verifiedBy == address(0x0)) {
                    verificationStatus = 0;
                    logicComplete = true;
                } else if (verifiedBy == pushChannelAdmin) {
                    verificationStatus = 2;
                    logicComplete = true;
                } else {
                    // Upper drill exists, go up
                    verifiedBy = channels[verifiedBy].verifiedBy;
                }
            }
        }
    }

    function batchVerification(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] calldata _channelList
    ) external returns (bool) {
        onlyPushChannelAdmin();
        for (uint256 i = _startIndex; i < _endIndex; i++) {
            verifyChannel(_channelList[i]);
        }
        return true;
    }

    /**
     * @notice    Function is designed to verify a channel
     * @dev       Channel will be verified by primary or secondary verification, will fail or upgrade if already verified
     * @param    _channel Address of the channel to be Verified
     **/
    function verifyChannel(address _channel) public {
        onlyActivatedChannels(_channel);
        // Check if caller is verified first
        uint8 callerVerified = getChannelVerfication(msg.sender);
        require(
            callerVerified > 0,
            "PushCoreV2::verifyChannel: Caller is not verified"
        );

        // Check if channel is verified
        uint8 channelVerified = getChannelVerfication(_channel);
        require(
            channelVerified == 0 || msg.sender == pushChannelAdmin,
            "PushCoreV2::verifyChannel: Channel already verified"
        );

        // Verify channel
        channels[_channel].verifiedBy = msg.sender;

        // Emit event
        emit ChannelVerified(_channel, msg.sender);
    }

    /**
     * @notice    Function is designed to unverify a channel
     * @dev       Channel who verified this channel or Push Channel Admin can only revoke
     * @param    _channel Address of the channel to be unverified
     **/
    function unverifyChannel(address _channel) public {
        require(
            channels[_channel].verifiedBy == msg.sender ||
                msg.sender == pushChannelAdmin,
            "PushCoreV2::unverifyChannel: Invalid Caller"
        );

        // Unverify channel
        channels[_channel].verifiedBy = address(0x0);

        // Emit Event
        emit ChannelVerificationRevoked(_channel, msg.sender);
    }

    /*** Core-V2: Stake and Claim Functions ***/

    /**
     * Allows caller to add pool_fees at any given epoch
     **/
    function addPoolFees(uint256 _rewardAmount) external {
        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            _rewardAmount
        );
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(_rewardAmount);
    }

    /**
     * @notice Function to return User's Push Holder weight based on amount being staked & current block number
     **/
    function _returnPushTokenWeight(
        address _account,
        uint256 _amount,
        uint256 _atBlock
    ) internal view returns (uint256) {
        return
            _amount.mul(
                _atBlock.sub(IPUSH(PUSH_TOKEN_ADDRESS).holderWeight(_account))
            );
    }

    /**
     * @notice Returns the epoch ID based on the start and end block numbers passed as input
     **/
    function lastEpochRelative(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        require(
            _to >= _from,
            "PushCoreV2:lastEpochRelative:: Relative Block Number Overflow"
        );
        return uint256((_to - _from) / epochDuration + 1);
    }

    /**
     * @notice Calculates and returns the claimable reward amount for a user at a given EPOCH ID.
     * @dev    Formulae for reward calculation:
     *         rewards = ( userStakedWeight at Epoch(n) * avalailable rewards at EPOCH(n) ) / totalStakedWeight at EPOCH(n)
     **/
    function calculateEpochRewards(address _user, uint256 _epochId)
        public
        view
        returns (uint256 rewards)
    {
        rewards = userFeesInfo[_user]
            .epochToUserStakedWeight[_epochId]
            .mul(epochRewards[_epochId])
            .div(epochToTotalStakedWeight[_epochId]);
    }

    /**
     * @notice Function to initialize the staking procedure in Core contract
     * @dev    Requires caller to deposit/stake 1 PUSH token to ensure staking pool is never zero.
     **/
    function initializeStake() external {
        require(
            genesisEpoch == 0,
            "PushCoreV2::initializeStake: Already Initialized"
        );
        genesisEpoch = block.number;
        lastEpochInitialized = genesisEpoch;

        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            1e18
        );
        _stake(address(this), 1e18);
    }

    /**
     * @notice Function to allow users to stake in the protocol
     * @dev    Records total Amount staked so far by a particular user
     *         Triggers weight adjustents functions
     * @param  _amount represents amount of tokens to be staked
     **/
    function stake(uint256 _amount) external {
        _stake(msg.sender, _amount);
    }

    function _stake(address _staker, uint256 _amount) private {
        uint256 currentEpoch = lastEpochRelative(genesisEpoch, block.number);
        uint256 blockNumberToConsider = genesisEpoch.add(
            epochDuration.mul(currentEpoch)
        );
        uint256 userWeight = _returnPushTokenWeight(
            _staker,
            _amount,
            blockNumberToConsider
        );

        IERC20(PUSH_TOKEN_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        userFeesInfo[_staker].stakedAmount =
            userFeesInfo[_staker].stakedAmount +
            _amount;
        userFeesInfo[_staker].lastClaimedBlock = userFeesInfo[_staker]
            .lastClaimedBlock == 0
            ? genesisEpoch
            : userFeesInfo[_staker].lastClaimedBlock;

        // Adjust user and total rewards, piggyback method
        _adjustUserAndTotalStake(_staker, userWeight);
    }

    /**
     * @notice Function to allow users to Unstake from the protocol
     * @dev    Allows stakers to claim rewards before unstaking their tokens
     *         Triggers weight adjustents functions
     *         Allows users to unstake all amount at once
     **/
    function unstake() external {
        require(
            block.number >
                userFeesInfo[msg.sender].lastStakedBlock + epochDuration,
            "PushCoreV2::unstake: Can't Unstake before 1 complete EPOCH"
        );
        require(
            userFeesInfo[msg.sender].stakedAmount > 0,
            "PushCoreV2::unstake: Invalid Caller"
        );
        harvestAll();

        IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(
            msg.sender,
            userFeesInfo[msg.sender].stakedAmount
        );

        // Adjust user and total rewards, piggyback method
        _adjustUserAndTotalStake(
            msg.sender,
            -userFeesInfo[msg.sender].stakedWeight
        );

        userFeesInfo[msg.sender].stakedAmount = 0;
        userFeesInfo[msg.sender].stakedWeight = 0;
    }

    /**
     * @notice Allows users to harvest/claim their earned rewards from the protocol
     * @dev    Computes nextFromEpoch and currentEpoch and uses them as startEPoch and endEpoch respectively.
     *         Rewards are claculated from start epoch till endEpoch(currentEpoch - 1).
     *         Once calculated, user's total claimed rewards and nextFromEpoch details is updated.
     **/
    function harvestAll() public {
        uint256 currentEpoch = lastEpochRelative(genesisEpoch, block.number);

        uint256 rewards = harvest(msg.sender, currentEpoch - 1);
        IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(msg.sender, rewards);
    }

    /**
     * @notice Allows paginated harvests for users between a particular number of epochs.
     * @param  _tillEpoch   - the end epoch number till which rewards shall be counted.
     * @dev    _tillEpoch should never be equal to currentEpoch.
     *         Transfers rewards to caller and updates user's details.
     **/
    function harvestPaginated(uint256 _tillEpoch) external {
        uint256 rewards = harvest(msg.sender, _tillEpoch);
        IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(msg.sender, rewards);
    }

    /**
     * @notice Allows Push Governance to harvest/claim the earned rewards for its stake in the protocol
     * @param  _tillEpoch   - the end epoch number till which rewards shall be counted.
     * @dev    only accessible by Push Admin
     *         Unlike other harvest functions, this is designed to transfer rewards to Push Governance.
     **/
    function daoHarvestPaginated(uint256 _tillEpoch) external {
        onlyGovernance();
        uint256 rewards = harvest(address(this), _tillEpoch);
        IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(governance, rewards);
    }

    /**
     * @notice Internal harvest function that is called for all types of harvest procedure.
     * @param  _user       - The user address for which the rewards will be calculated.
     * @param  _tillEpoch   - the end epoch number till which rewards shall be counted.
     * @dev    _tillEpoch should never be equal to currentEpoch.
     *         Transfers rewards to caller and updates user's details.
     **/
    function harvest(address _user, uint256 _tillEpoch)
        internal
        returns (uint256 rewards)
    {
        IPUSH(PUSH_TOKEN_ADDRESS).resetHolderWeight(_user);
        _adjustUserAndTotalStake(_user, 0);

        uint256 currentEpoch = lastEpochRelative(genesisEpoch, block.number);
        uint256 nextFromEpoch = lastEpochRelative(
            genesisEpoch,
            userFeesInfo[_user].lastClaimedBlock
        );

        require(
            currentEpoch > _tillEpoch,
            "PushCoreV2::harvestPaginated::Invalid _tillEpoch w.r.t currentEpoch"
        );
        require(
            _tillEpoch >= nextFromEpoch,
            "PushCoreV2::harvestPaginated::Invalid _tillEpoch w.r.t nextFromEpoch"
        );
        for (uint256 i = nextFromEpoch; i <= _tillEpoch; i++) {
            uint256 claimableReward = calculateEpochRewards(_user, i);
            rewards = rewards.add(claimableReward);
        }

        usersRewardsClaimed[_user] = usersRewardsClaimed[_user].add(rewards);
        // set the lastClaimedBlock to blocknumer at the end of `_tillEpoch`
        uint256 _epoch_to_block_number = genesisEpoch +
            _tillEpoch *
            epochDuration;
        userFeesInfo[_user].lastClaimedBlock = _epoch_to_block_number;

        emit RewardsHarvested(_user, rewards, nextFromEpoch, _tillEpoch);
    }

    /**
     * @notice  This functions helps in adjustment of user's as well as totalWeigts, both of which are imperative for reward calculation at a particular epoch.
     * @dev     Enables adjustments of user's stakedWeight, totalStakedWeight, epochToTotalStakedWeight as well as epochToTotalStakedWeight.
     *          triggers _setupEpochsReward() to adjust rewards for every epoch till the current epoch
     *
     *          Includes 2 main cases of weight adjustments
     *          1st Case: User stakes for the very first time:
     *              - Simply update userFeesInfo, totalStakedWeight and epochToTotalStakedWeight of currentEpoch
     *
     *          2nd Case: User is NOT staking for first time - 2 Subcases
     *              2.1 Case: User stakes again but in Same Epoch
     *                  - Increase user's stake and totalStakedWeight
     *                  - Record the epochToUserStakedWeight for that epoch
     *                  - Record the epochToTotalStakedWeight of that epoch
     *
     *              2.2 Case: - User stakes again but in different Epoch
     *                  - Update the epochs between lastStakedEpoch & (currentEpoch - 1) with the old staked weight amounts
     *                  - While updating epochs between lastStaked & current Epochs, if any epoch has zero value for totalStakedWeight, update it with current totalStakedWeight value of the protocol
     *                  - For currentEpoch, initialize the epoch id with updated weight values for epochToUserStakedWeight & epochToTotalStakedWeight
     */
    function _adjustUserAndTotalStake(address _user, uint256 _userWeight)
        internal
    {
        uint256 currentEpoch = lastEpochRelative(genesisEpoch, block.number);
        _setupEpochsRewardAndWeights(_userWeight, currentEpoch);
        uint256 userStakedWeight = userFeesInfo[_user].stakedWeight;

        // Initiating 1st Case: User stakes for first time
        if (userStakedWeight == 0) {
            userFeesInfo[_user].stakedWeight = _userWeight;
        } else {
            // Initiating 2.1 Case: User stakes again but in Same Epoch
            uint256 lastStakedEpoch = lastEpochRelative(
                genesisEpoch,
                userFeesInfo[_user].lastStakedBlock
            );
            if (currentEpoch == lastStakedEpoch) {
                userFeesInfo[_user].stakedWeight =
                    userStakedWeight +
                    _userWeight;
            } else {
                // Initiating 2.2 Case: User stakes again but in Different Epoch
                for (uint256 i = lastStakedEpoch; i <= currentEpoch; i++) {
                    if (i != currentEpoch) {
                        userFeesInfo[_user].epochToUserStakedWeight[
                                i
                            ] = userStakedWeight;
                    } else {
                        userFeesInfo[_user].stakedWeight =
                            userStakedWeight +
                            _userWeight;
                        userFeesInfo[_user].epochToUserStakedWeight[
                                i
                            ] = userFeesInfo[_user].stakedWeight;
                    }
                }
            }
        }

        if (_userWeight != 0) {
            userFeesInfo[_user].lastStakedBlock = block.number;
        }
    }

    /**
     * @notice Internal function that allows setting up the rewards for specific EPOCH IDs
     * @dev    Initializes (sets reward) for every epoch ID that falls between the lastEpochInitialized and currentEpoch
     *         Reward amount for specific EPOCH Ids depends on newly available Protocol_Pool_Fees. 
                - If no new fees was accumulated, rewards for particular epoch ids can be zero
                - Records the Pool_Fees value used as rewards.
                - Records the last epoch id whose rewards were set.
     */
    function _setupEpochsRewardAndWeights(
        uint256 _userWeight,
        uint256 _currentEpoch
    ) private {
        uint256 _lastEpochInitiliazed = lastEpochRelative(
            genesisEpoch,
            lastEpochInitialized
        );
        // Setting up Epoch Based Rewards
        if (_currentEpoch > _lastEpochInitiliazed || _currentEpoch == 1) {
            uint256 availableRewardsPerEpoch = (PROTOCOL_POOL_FEES -
                previouslySetEpochRewards);
            uint256 _epochGap = _currentEpoch.sub(_lastEpochInitiliazed);

            if (_epochGap > 1) {
                epochRewards[_currentEpoch - 1] += availableRewardsPerEpoch;
            } else {
                epochRewards[_currentEpoch] += availableRewardsPerEpoch;
            }

            lastEpochInitialized = block.number;
            previouslySetEpochRewards = PROTOCOL_POOL_FEES;
        }
        // Setting up Epoch Based TotalWeight
        if (
            lastTotalStakeEpochInitialized == 0 ||
            lastTotalStakeEpochInitialized == _currentEpoch
        ) {
            epochToTotalStakedWeight[_currentEpoch] += _userWeight;
        } else {
            for (
                uint256 i = lastTotalStakeEpochInitialized + 1;
                i <= _currentEpoch - 1;
                i++
            ) {
                if (epochToTotalStakedWeight[i] == 0) {
                    epochToTotalStakedWeight[i] = epochToTotalStakedWeight[
                        lastTotalStakeEpochInitialized
                    ];
                }
            }
            epochToTotalStakedWeight[_currentEpoch] =
                epochToTotalStakedWeight[lastTotalStakeEpochInitialized] +
                _userWeight;
        }
        lastTotalStakeEpochInitialized = _currentEpoch;
    }

    function setRelayerAddress(address _relayer) external {
        onlyPushChannelAdmin();
        emit RelayerAddressUpdated(relayerAddress, _relayer);
        relayerAddress = _relayer;
    }

    function setBridgeAddress(address _bridge) external {
        onlyPushChannelAdmin();
        emit BridgeAddressUpdated(bridgeAddress, _bridge);
        bridgeAddress = _bridge;
    }

    function handleChatRequestData(
        address requestSender,
        address requestReceiver,
        uint256 amount,
        bytes calldata vaa
    ) external {
        require(
            msg.sender == relayerAddress,
            "PushCoreV2:handleChatRequestData::Unauthorized caller"
        );
        uint256 poolFeeAmount = FEE_AMOUNT;
        uint256 requestReceiverAmount = amount.sub(poolFeeAmount);

        celebUserFunds[requestReceiver] += requestReceiverAmount;
        PROTOCOL_POOL_FEES = PROTOCOL_POOL_FEES.add(poolFeeAmount);

        ITokenBridge(bridgeAddress).completeTransferWithPayload(vaa);
        emit IncentivizeChatReqReceived(
            requestSender,
            requestReceiver,
            requestReceiverAmount,
            poolFeeAmount,
            block.timestamp
        );
    }

    function claimChatIncentives(uint256 _amount) external {
        require(
            celebUserFunds[msg.sender] >= _amount,
            "PushCoreV2:claimChatIncentives::Invalid Amount"
        );

        celebUserFunds[msg.sender] -= _amount;
        IERC20(PUSH_TOKEN_ADDRESS).safeTransfer(msg.sender, _amount);

        emit ChatIncentiveClaimed(msg.sender, _amount);
    }
}

pragma solidity >=0.6.0 <0.7.0;

interface IEPNSCommV1 {
 	function subscribeViaCore(address _channel, address _user) external returns(bool);
  function unSubscribeViaCore(address _channel, address _user) external returns (bool);
}

pragma solidity >=0.6.0 <0.7.0;

interface IPUSH {
  function born() external view returns(uint);
  function totalSupply() external view returns(uint);
  function resetHolderWeight(address holder) external;
  function holderWeight(address) external view returns (uint);
  function returnHolderUnits(address account, uint atBlock) external view returns (uint);
}

interface ITokenBridge {

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

}

pragma solidity >=0.6.0 <0.7.0;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
    ) external returns (uint[] memory amounts); 
}