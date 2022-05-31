/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: Address

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

// Part: Context

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: IERC20

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
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

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

// Part: ReentrancyGuard

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// Part: SafeMath

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
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}

// Part: Initializable

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
        return !Address.isContract(address(this));
    }
}

// Part: SafeERC20

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

// File: LuckyMoney.sol

contract LuckyMoney is Context, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Record {
        address collector;
        bytes32 seed;
    }

    struct LuckyMoneyData {
        address creator;
        uint256 expireTime;
        // 0 for random, 1 for fixed
        uint8 mode;
        address tokenAddr;
        uint256 tokenAmount;
        uint256 collectorCount;
        uint256 nonce;
        uint256 refundAmount;
        mapping (address => bool) collectStatus;
        mapping (uint256 => Record) records;
    }

    mapping (bytes32 => LuckyMoneyData) public luckyMoneys;

    struct RewardConfig {
        uint256 forSender;
        uint256 forReceiver;
    }

    address[] public rewards;
    mapping (address => RewardConfig) public rewardConfigs;
    mapping (address => uint256) public rewardBalances;

    event Disperse(
        address indexed _sender,
        address _tokenAddr,
        uint256 _tokenAmount,
        uint256 _fee
    );
    event Create(
        bytes32 indexed _id,
        address _tokenAddr,
        uint256 _tokenAmount,
        uint256 _expireTime,
        uint256 _collectorCount,
        uint256 _fee,
        uint256 _gasRefund
    );
    event Collect(
        address indexed _collector,
        address indexed _tokenAddress,
        // 0 for disperse, 1 for luckyMoney
        uint8 _mode,
        uint256 _tokenAmount,
        bytes32 _id
    );
    event Distribute(
        bytes32 indexed _id,
        address indexed _caller,
        uint256 _remainCollector,
        uint256 _remainTokenAmount
    );
    event RewardCollect(
        address indexed _collector,
        address indexed _tokenAddr,
        // 0 for send, 1 for receive
        uint8 _mode,
        uint256 amount);
    event FeeRateUpdate(uint16 feeRate);
    event FeeReceiverUpdate(address receiver);
    event OwnershipUpdate(address oldOwner, address newOwner);

    address public owner;
    uint256 public refundAmount = 1e15; // 0.001

    // Fee = total * feeRate / feeBase
    // For example, feeRate as 100 means 1% fee.
    uint16 public feeRate = 10;
    uint16 public feeBase = 10000;
    address public feeReceiver;

    constructor() public {}

    function initialize(address _owner, address _feeReceiver) external initializer {
        owner = _owner;
        feeReceiver = _feeReceiver;

        feeRate = 10;
        feeBase = 10000;
        refundAmount = 1e15;

    }

    // ========= Normal disperse =========

    function disperseEther(address payable[] memory recipients, uint256[] memory values) external payable {
        address sender = msg.sender;
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }
        uint256 fee = takeFeeAndValidate(sender, msg.value, address(0), total);
        giveReward(sender, 0);
        emit Disperse(sender, address(0), total, fee);

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(values[i]);
            emit Collect(recipients[i], address(0), 1, values[i], 0);
            giveReward(recipients[i], 1);
        }
    }

    function disperseToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        address sender = msg.sender;
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }
        uint256 fee = takeFeeAndValidate(sender, 0, address(token), total);
        giveReward(sender, 0);
        emit Disperse(sender, address(token), total, fee);

        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransfer(recipients[i], values[i]);
            emit Collect(recipients[i], address(token), 1, values[i], 0);
            giveReward(recipients[i], 1);
        }
    }

    // ========= LuckyMoney which need signature to collect =========
    function create(
        uint256 expireTime,
        uint8 mode,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 collectorCount)
        external payable returns (bytes32) {

        address sender = msg.sender;
        uint256 value = msg.value;

        require(value >= refundAmount, "not enough to refund later");
        uint256 fee = takeFeeAndValidate(sender, msg.value - refundAmount, tokenAddr, tokenAmount);

        bytes32 luckyMoneyId = getLuckyMoneyId(sender, block.timestamp, tokenAddr, tokenAmount, collectorCount);
        LuckyMoneyData storage l = luckyMoneys[luckyMoneyId];
        l.creator = sender;
        l.expireTime = expireTime;
        l.mode = mode;
        l.tokenAddr = tokenAddr;
        l.tokenAmount = tokenAmount;
        l.collectorCount = collectorCount;
        l.refundAmount = refundAmount;
        emit Create(luckyMoneyId, tokenAddr, tokenAmount, expireTime, collectorCount, fee, refundAmount);
        giveReward(sender, 0);

        return luckyMoneyId;
    }

    function submit(bytes32 luckyMoneyId, bytes memory signature) external {
        address sender = msg.sender;
        LuckyMoneyData storage l = luckyMoneys[luckyMoneyId];
        require(!hasCollected(luckyMoneyId, sender), "collected before");
        require(l.nonce < l.collectorCount, "collector count exceed");

        // Verify signature
        bytes32 hash = getEthSignedMessageHash(luckyMoneyId, sender);
        require(recoverSigner(hash, signature) == l.creator, "signature not signed by creator");
        l.records[l.nonce] = Record(sender, getBlockAsSeed(sender));
        l.nonce += 1;
        l.collectStatus[sender] = true;
    }

    function distribute(bytes32 luckyMoneyId) external {
        LuckyMoneyData storage l = luckyMoneys[luckyMoneyId];
        require(l.nonce == l.collectorCount || block.timestamp > l.expireTime, "luckyMoney not fully collected or expired");
        // generate amounts
        address payable[] memory recipients = new address payable[](l.nonce);
        uint256[] memory values = new uint256[](l.nonce);
        uint256 remainCollectorCount = l.collectorCount;
        uint256 remainTokenAmount = l.tokenAmount;

        if (l.mode == 1) {
            // - Fix mode
            uint256 avgAmount = l.tokenAmount / l.collectorCount;
            remainCollectorCount = l.collectorCount - l.nonce;
            remainTokenAmount = l.tokenAmount - avgAmount * l.nonce;
            for (uint256 i = 0; i < l.nonce; i++) {
                recipients[i] = payable(l.records[i].collector);
                values[i] = avgAmount;
            }
        } else if (l.mode == 0) {

            // - Random mode
            bytes32 seed;
            for (uint256 i = 0; i < l.nonce; i++) {
                seed = seed ^ l.records[i].seed;
            }

            for (uint256 i = 0; i < l.nonce; i++) {
                recipients[i] = payable(l.records[i].collector);
                values[i] = calculateRandomAmount(seed, l.records[i].seed, remainTokenAmount, remainCollectorCount);
                remainCollectorCount -= 1;
                remainTokenAmount -= values[i];
            }
        }

        address tokenAddr = l.tokenAddr;
        address creator = l.creator;
        uint256 _refundAmount = l.refundAmount;
        // prevent reentrency attack, delete state before calling external transfer
        delete luckyMoneys[luckyMoneyId];

        // distribute
        if (tokenAddr == address(0)) {
            // - ETH
            for (uint256 i = 0; i < recipients.length; i++) {
                recipients[i].transfer(values[i]);
                emit Collect(recipients[i], tokenAddr, 2, values[i], luckyMoneyId);
                giveReward(recipients[i], 1);
            }
            // return exceed ethers to creator
            payable(creator).transfer(remainTokenAmount);
        } else {

            // - Token
            IERC20 token = IERC20(tokenAddr);
            for (uint256 i = 0; i < recipients.length; i++) {
                token.safeTransfer(recipients[i], values[i]);
                emit Collect(recipients[i], tokenAddr, 2, values[i], luckyMoneyId);
                giveReward(recipients[i], 1);
            }
            // return exceed tokens to creator
            token.transfer(creator, remainTokenAmount);
        }

        address sender = msg.sender;
        // refund caller
        payable(sender).transfer(_refundAmount);
        emit Distribute(luckyMoneyId, sender, remainCollectorCount, remainTokenAmount);
    }

    // ========= Admin functions =========

    function setOwner(address _owner) external {
        require(msg.sender == owner, "priviledged action");

        emit OwnershipUpdate(owner, _owner);
        owner = _owner;
    }

    function setRefundAmount(uint256 _amount) external {
        require(msg.sender == owner, "priviledged action");

        refundAmount = _amount;
    }

    function setFeeRate(uint16 _feeRate) external {
        require(msg.sender == owner, "priviledged action");
        require(_feeRate <= 10000, "fee rate greater than 100%");

        feeRate = _feeRate;
        emit FeeRateUpdate(_feeRate);
    }

    function setFeeReceiver(address _receiver) external {
        require(msg.sender == owner, "priviledged action");
        require(_receiver != address(0), "fee receiver can't be zero address");

        feeReceiver = _receiver;
        emit FeeReceiverUpdate(_receiver);
    }

    function setRewardTokens(address[] calldata rewardTokens) external {
        require(msg.sender == owner, "priviledged action");

        rewards = rewardTokens;
    }

    function configRewardRate(address rewardToken, uint256 forSender, uint256 forReceiver) external {
        require(msg.sender == owner, "priviledged action");

        rewardConfigs[rewardToken] = RewardConfig(forSender, forReceiver);
    }

    function addReward(address tokenAddr, uint256 amount) external {
        IERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
        rewardBalances[tokenAddr] += amount;
    }

    function withdrawReward(address tokenAddr, uint256 amount) external {
        require(msg.sender == owner, "priviledged action");
        require(rewardBalances[tokenAddr] >= amount, "remain reward not enough to withdraw");

        IERC20(tokenAddr).safeTransfer(owner, amount);
        rewardBalances[tokenAddr] -= amount;
    }

    // ========= View functions =========

    function hasCollected(bytes32 luckyMoneyId, address collector) public view returns (bool) {
        return luckyMoneys[luckyMoneyId].collectStatus[collector];
    }

    function expireTime(bytes32 luckyMoneyId) public view returns (uint256) {
        return luckyMoneys[luckyMoneyId].expireTime;
    }

    function feeOf(uint256 amount) public view returns (uint256) {
        return amount * feeRate / feeBase;
    }

    // ========= Util functions =========

    function takeFeeAndValidate(address sender, uint256 value, address tokenAddr, uint256 tokenAmount) internal returns (uint256 fee) {
        fee = feeOf(tokenAmount);
        if (tokenAddr == address(0)) {
            require(value == tokenAmount + fee, "incorrect amount of eth transferred");
            payable(feeReceiver).transfer(fee);
        } else {
            require(IERC20(tokenAddr).balanceOf(msg.sender) >= tokenAmount + fee, "incorrect amount of token transferred");
            IERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), tokenAmount);
            IERC20(tokenAddr).safeTransferFrom(msg.sender, address(feeReceiver), fee);
        }
    }

    function giveReward(address target, uint8 mode) internal {
        for (uint256 i = 0; i < rewards.length; i++) {
            address token = rewards[i];
            RewardConfig storage config = rewardConfigs[token];
            uint256 amount = mode == 0 ? config.forSender : config.forReceiver;
            if (amount > 0 && rewardBalances[token] > amount) {
                rewardBalances[token] -= amount;
                IERC20(token).safeTransfer(target, amount);
                emit RewardCollect(target, token, mode, amount);
            }
        }
    }

    // TODO will chainId matters? for security?
    function getLuckyMoneyId(
        address _creator,
        uint256 _startTime,
        address _tokenAddr,
        uint256 _tokenAmount,
        uint256 _collectorCount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_creator, _startTime, _tokenAddr, _tokenAmount, _collectorCount));
    }

    function getBlockAsSeed(address addr) public view returns (bytes32) {
        return keccak256(abi.encode(addr, block.timestamp, block.difficulty, block.number));
    }

    function calculateRandomAmount(bytes32 rootSeed, bytes32 seed, uint256 remainAmount, uint remainCount) public pure returns (uint256) {
        uint256 amount = 0;
        if (remainCount == 1) {
            amount = remainAmount;
        } else if (remainCount == remainAmount) {
            amount = 1;
        } else if (remainCount < remainAmount) {
            amount = uint256(keccak256(abi.encode(rootSeed, seed))) % (remainAmount / remainCount * 2) + 1;
        }
        return amount;
    }

    function getMessageHash(
        bytes32 _luckyMoneyId,
        address _collector
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_luckyMoneyId, _collector));
    }

  function getEthSignedMessageHash(
        bytes32 _luckyMoneyId,
        address _collector
  )
        public
        pure
        returns (bytes32)
    {
        bytes32 _messageHash = getMessageHash(_luckyMoneyId, _collector);
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        // implicitly return (r, s, v)
    }

    function GetInitializeData(address _owner, address _feeReceiver) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address)", _owner,_feeReceiver);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}