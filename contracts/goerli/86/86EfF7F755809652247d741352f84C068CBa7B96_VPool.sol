/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/token/Context.sol


pragma solidity 0.6.12;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/token/Pausable.sol


pragma solidity ^0.6.12;

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
    constructor () internal {
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
}


// File contracts/interfaces/IVPoolConfiguration.sol

pragma solidity 0.6.12;

interface IVPoolConfiguration {
    function hordToken() external view returns(address);
    function baseToken() external view returns(address);
    function hordChampion() external view returns(address);
    function minChampStake() external view returns(uint256);
    function minFollowerUSDStake() external view returns(uint256);
    function maxFollowerUSDStake() external view returns(uint256);
    function gasUtilizationRatio() external view returns(uint256);
    function percentPrecision() external view returns(uint256);
    function totalSupplyVPoolTokens() external view returns (uint256);
    function whitelistingDurationSecs() external view returns (uint256);
    function maxDurationValue() external view returns (uint256);
    function vPoolSubscriptionDurationSecs() external view returns (uint256);
    function platformStakeRatio() external view returns (uint256);
    function maxUserParticipation() external view returns (uint256);
    function minUserParticipation() external view returns (uint256);
    function timeToAcceptOpenOrders() external view returns (uint256);
    function maxOfProjectTokens() external view returns (uint256);
}


// File contracts/interfaces/IVPoolManager.sol

pragma solidity 0.6.12;

/**
 * IHPoolManager contract.
 * @author Nikola Madjarevic
 * Date created: 20.7.21.
 * Github: madjarevicn
 */
interface IVPoolManager {
    function setActivityForExactHPool(uint256 poolId, bool paused) external;
    function subscribeForVPool(bytes memory signature, uint256 poolId, uint256 amountUsd) external payable;
    function getUserSubscriptionForPool(uint256 poolId, address user) external view returns (uint256, bool);
}


// File contracts/interfaces/IMatchingMarket.sol

pragma solidity 0.6.12;

interface IMatchingMarket {
    function addTransferFee(uint256 amount, address hPoolToken) external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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


// File contracts/pools/VPoolToken.sol

pragma solidity 0.6.12;





/**
 * VPoolToken contract.
 * @author Srdjan Simonovic
 * Date created: 15.03.22.
 * Github: s2imonovic
 */
contract VPoolToken is Pausable, IERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _totalMintedSupply;

    address internal hordToken;

    IVPoolConfiguration internal vPoolConfiguration;
    IVPoolManager internal vPoolManager;
    IMatchingMarket internal matchingMarket;

    event TakenTradingFee(uint256 amount);
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function createToken(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address beneficiary,
        address vPoolConfiguration_,
        address matchingMarket_
    )
    internal
    {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        _totalMintedSupply = totalSupply_;
        _balances[beneficiary] = totalSupply_;
        vPoolConfiguration = IVPoolConfiguration(vPoolConfiguration_);
        matchingMarket = IMatchingMarket(matchingMarket_);

        hordToken = vPoolConfiguration.hordToken();

        emit Transfer(address(0x0), beneficiary, totalSupply_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name()
    public
    view
    virtual
    returns (string memory)
    {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol()
    public
    view
    virtual
    returns (string memory)
    {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals()
    public
    pure
    virtual
    returns (uint8)
    {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply()
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev Returns total supply minted ever
     */
    function totalMintedSupply()
    public
    view
    returns (uint256)
    {
        return _totalMintedSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    )
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address recipient,
        uint256 amount
    )
    external
    virtual
    override
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    )
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    )
    external
    virtual
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
    external
    virtual
    override
    returns (bool)
    {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function burn(
        uint amount
    )
    external
    virtual
    {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
    internal
    virtual
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            sender == address(this) || sender == address(matchingMarket) ||
            recipient == address(matchingMarket) || msg.sender == address(matchingMarket),
            "Only tradable on DEX."
        );

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 amount
    )
    internal
    virtual
    {
        require(account != address(0), "ERC20: burn from the zero address");


        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
    internal
    virtual
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.6.12;

/**
 * IMaintainersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/HordUpgradable.sol

pragma solidity 0.6.12;

/**
 * HordUpgradables contract.
 * @author Nikola Madjarevic
 * Date created: 8.5.21.
 * Github: madjarevicn
 */
contract HordUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    event MaintainersRegistrySet(address maintainersRegistry);
    event CongressAndMaintainersSet(address hordCongress, address maintainersRegistry);

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "Hord: Restricted only to Maintainer");
        _;
    }

    // Only chainport congress modifier
    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "Hord: Restricted only to HordCongress");
        _;
    }

    modifier onlyHordCongressOrMaintainer {
        require(msg.sender == hordCongress || maintainersRegistry.isMaintainer(msg.sender),
            "Hord: Only Congress or Maintainer."
        );
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        require(_hordCongress != address(0), "HordCongress can not be 0x0 address");
        require(_maintainersRegistry != address(0), "MaintainersRegistry can not be 0x0 address");

        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);

        emit CongressAndMaintainersSet(hordCongress, address(maintainersRegistry));
    }

}


// File contracts/interfaces/IHPoolHelper.sol

pragma solidity 0.6.12;


interface IHPoolHelper {
    function useNonce(uint256 poolNonce, address hPool) view external;
    function isChampionAddress(address signer, address hPool) view external;
    function getBestBuyRoute(address token) view external returns(address[] memory);
    function getBestSellRoute(address token)  view external returns(address[] memory);
}


// File contracts/interfaces/IWrappedToken.sol

pragma solidity ^0.6.12;

interface IWrappedToken {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address account) external returns (uint256);
    function transfer(address dst, uint wad) external returns (bool);
}


// File contracts/interfaces/ISignatureValidator.sol

pragma solidity 0.6.12;

/**
 * ISignatureValidator contract.
 * @author Nikola Madjarevic
 * Date created: 30.9.21.
 * Github: madjarevicn
 */
interface ISignatureValidator {

    function recoverSignatureBuyOrderRatio(
        address dstToken,
        uint256 ratio,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureTradeOrder(
        address srcToken,
        address dstToken,
        uint256 amountSrc,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureSellLimit(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountSrc,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureBuyLimit(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountUSD,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureStopLoss(
        address srcToken,
        address dstToken,
        uint256 priceUSD,
        uint256 amountSrc,
        uint256 validUntil,
        uint256 poolNonce,
        uint256 poolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureEndPool(
        uint256 poolId,
        uint256 poolNonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureOpenOrder(
        uint256 poolId,
        uint256 tokenId,
        uint256 amountUSDToWithdraw,
        uint256 amountOfTokensToReturn,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureCloseOrder(
        uint256 tokenId,
        uint256 totalTokensToBeReceived,
        uint256 finalTokenPrice,
        uint256 amountOfTokensToReceiveNow,
        address tokenAddress,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

    function recoverSignatureClosePortion(
        uint256 tokenId,
        uint256 portionId,
        uint256 amountOfTokensToReceive,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    view
    returns (address);

}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File contracts/pools/VPool.sol

pragma solidity 0.6.12;







/**
 * VPool contract.
 * @author Srdjan Simonovic
 * Date created: 22.03.22.
 * Github: s2imonovic
 */
contract VPool is HordUpgradable, VPoolToken, Initializable{

    struct VPoolInfo {
        address vPoolImplementation;
        address baseAsset;
        uint256 vPoolId;
        uint256 totalDeposit;
        uint256 timeWhileOpenOrderAllowed;
        uint256 maxOfProjectTokens;
        bool isHPoolTokenMinted;
    }

    struct Portion {
        uint256 potionId;
        uint256 amountOfTokens;
        uint256 unlockingTime;
        bool isPortionReceived;
    }

    struct ChampionOrder {
        uint256 amountStableToWithdraw;
        uint256 totalTokensToBeReceived;
        uint256 amountTokensReceived;
        uint256 finalTokenPriceInUSD;
        uint256 usdWorthOfPositionInPurchasePrice;
        uint256 numberOfPortions;
        address tokenAddress;
        address tokenWithdrawn;
        bool isBuyingExecuted;
        bool isClosingFirstPortionReceived;
        bool isClosingFinalized;
    }

    // Represent instance of VPool struct
    VPoolInfo public vPool;
    // Storing all tokens (assets) which are present in the pool
    address[] private assets;
    // Storing all openOrders
    uint256[] private openOrders;
    // Champion address of this hPool
    address public championAddress;
    //Represent total base asset at launch
    uint256 public totalBaseAssetAtLaunch;
    // Represent BE poolId
    uint256 public bePoolId;
    // Represent is this pool ended
    bool public isPoolEnded;
    // Mapping token address to index
    mapping(address => uint256) public tokenToIndex;
    // Represent tokenId to ChampionOrder struct
    mapping(uint256 => ChampionOrder) public tokenIdToChampionSwap;
    // Represent tokenId to Portion struct
    mapping(uint256 => Portion[]) public tokenIdToPortions;
    // Represent beTokenId to vPool contract
    mapping(uint256 => address) public tokenIdToVPool;
    // Mapping that represent is user claim his vPoolTokens
    mapping(address => bool) public didUserClaimVPoolTokens;
    // Represent instance of HPoolHelper contract
    IHPoolHelper private hPoolHelper;
    // Represent instance of uniswapRouter contract
    IUniswapV2Router02 private uniswapRouter;
    // Represent instance of signatureValidator contract
    ISignatureValidator private signatureValidator;
    // Represent instance of wrappedToken
    IWrappedToken private wrappedToken;

    event TotalBudgetDepositInUSD(uint256 amount);
    event VPoolTokenMinted(string name, string symbol, uint256 totalSupply);
    event SwapExecuted(
        uint256 amountSource,
        uint256 amountTarget,
        address sourceToken,
        address targetToken
    );
    event OpenOrder(address champion, uint256 tokenId, uint256 usdAmount);
    event CloseOrderForFirstTime(
        address token,
        uint256 totalTokensToBeReceived,
        uint256 finalTokenPrice,
        uint256 amountOfTokensToReceiveNow
    );
    event ClosePortion(
        address token,
        uint256 amountOfTokensToReceiveNow
    );
    event OpenOrderTimeChanged(uint256 newTime);
    event OpenOrderClosedAndFinalized(uint256 poolId, uint256 tokenId, uint256 totalReceived);
    event TotalTokensAmountChanged(uint256 poolId, uint256 totalTokensAmount);
    event ClaimedVPoolTokens(address user, uint256 amountOfTokens);

    modifier onlyVPoolManager {
        require(msg.sender == address(vPoolManager), "only VPoolManager");
        _;
    }

    receive() external payable {

    }

    function initialize(
        uint256 _vPoolId,
        uint256 _bePoolId,
        address _hordCongress,
        address _hordMaintainersRegistry,
        address _vPoolManager,
        address _championAddress,
        address _signatureValidator,
        address _vPoolImplementation,
        address _hPoolHelper,
        address _uniswapRouter
    )
    external
    initializer
    {
        require(_championAddress != address(0), "0x0 address");
        require(_vPoolManager != address(0), "0x0 address");
        require(_hPoolHelper != address(0), "0x0 address");
        require(_uniswapRouter != address(0), "0x0 address");

        setCongressAndMaintainers(_hordCongress, _hordMaintainersRegistry);

        bePoolId = _bePoolId;
        vPool.vPoolId = _vPoolId;
        championAddress = _championAddress;
        vPool.vPoolImplementation = _vPoolImplementation;

        hPoolHelper = IHPoolHelper(_hPoolHelper);
        vPoolManager = IVPoolManager(_vPoolManager);
        signatureValidator = ISignatureValidator(_signatureValidator);
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        wrappedToken = IWrappedToken(uniswapRouter.WETH());
    }

    function setTimeWhileOpenOrderAllowed(
        uint256 timeToExpand
    )
    external
    onlyHordCongress
    {
        require(timeToExpand <= vPoolConfiguration.maxDurationValue(), "Duration time is not valid.");
        vPool.timeWhileOpenOrderAllowed = block.timestamp.add(timeToExpand);

        emit OpenOrderTimeChanged(vPool.timeWhileOpenOrderAllowed);
    }

    function setTotalTokensToBeReceived(
        uint256 tokenId,
        uint256 totalAmountOfTokensToBeReceived
    )
    external
    {
        require(msg.sender == tx.origin, "Only direct calls.");
        require(msg.sender == championAddress, "Restricted only to champion.");
        tokenIdToChampionSwap[tokenId].totalTokensToBeReceived = totalAmountOfTokensToBeReceived;

        emit TotalTokensAmountChanged(tokenId, totalAmountOfTokensToBeReceived);
    }

    /**
        * @notice  Function allowing congress to pause the smart-contract
        * @dev     Can be only called by HordCongress or maintainer
     */
    function pause()
    external
    onlyHordCongressOrMaintainer
    {
        vPoolManager.setActivityForExactHPool(vPool.vPoolId, true);
        _pause();
    }

    /**
        * @notice  Function allowing congress to unpause the smart-contract
        * @dev     Can be only called by HordCongress or maintainer
     */
    function unpause()
    external
    onlyHordCongressOrMaintainer
    {
        vPoolManager.setActivityForExactHPool(vPool.vPoolId, false);
        _unpause();
    }

    /**
        * @notice         Function to swap exact tokens for tokens.
        * @param          isWETHSource is check is weth source token.
        * @param          token is address of the token we want to convert to eth.
        * @param          amountSrc is amount of srcToken to send.
        * @param          minAmountOut is minimum amount of ETH that must be received for the transaction not to revert.
    */
    function swapExactTokensForTokens(
        address[] memory path,
        address token,
        bool isWETHSource,
        uint256 amountSrc,
        uint256 minAmountOut,
        bool isLiquidation
    )
    public
    returns (uint256)
    {

        IERC20 asset = IERC20(token);

        if(path.length == 0) {
            path = new address[](2);
            if(isWETHSource) {
                path[0] = address(wrappedToken);
                path[1] = token;
                wrappedToken.approve(address(uniswapRouter), amountSrc);
            } else {
                path[0] = token;
                path[1] = address(wrappedToken);
                asset.approve(address(uniswapRouter), amountSrc);
            }
        } else {
            IERC20(path[0]).approve(address(uniswapRouter), amountSrc);
        }

        uint256 deadline = block.timestamp.add(600);

        uint256[] memory actualAmountOutMin = uniswapRouter.getAmountsOut(amountSrc, path);
        uint256 targetTokenIdx = path.length - 1;
        require(actualAmountOutMin[targetTokenIdx] >= minAmountOut, "minAmountOut > actualAmountOutMin.");

        uint256[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountSrc,
            actualAmountOutMin[targetTokenIdx],
            path,
            address(this),
            deadline
        );

        if(tokenToIndex[token] == 0) {
            tokenToIndex[token] = assets.length;
            assets.push(token);
        }

        emit SwapExecuted(amounts[0], amounts[targetTokenIdx], path[0], path[targetTokenIdx]);

        // Return amount of tokens received
        return (amounts[targetTokenIdx]);

    }

    /**
        * @notice       Function to create HPoolToken.
        * @dev          Function is called during the initialization of hPool in the VPoolManager contract.
        * @param        name is the name of the HPoolToken.
        * @param        symbol is the symbol of the HPoolToken.
        * @param        totalSupply is the initial amount of hPoolTokens.
     */
    function mintHPoolToken(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address _vPoolManager,
        address _matchingMarket
    )
    external
    onlyVPoolManager
    {
        require(!vPool.isHPoolTokenMinted, "already minted");
        // Mark that token is minted.
        vPool.isHPoolTokenMinted = true;
        // Initially all HPool tokens are minted on the pool level
        createToken(name, symbol, totalSupply, address(this), _vPoolManager, _matchingMarket);
        // Set time for open orders
        vPool.timeWhileOpenOrderAllowed = block.timestamp.add(vPoolConfiguration.timeToAcceptOpenOrders());
        // Trigger even that hPool token is minted
        emit VPoolTokenMinted(name, symbol, totalSupply);
    }

    /**
         * @notice  Function to do initial budget deposit
         * @param   amountUSDAfterFees is the initial value representing pool worth during the launch.
     */
    function depositBudget(
        uint256 amountUSDAfterFees,
        uint256 totalDeposit
    )
    external
    onlyVPoolManager
    {
        require(amountUSDAfterFees > 0, "value = 0");
        // Deposit funds
        totalBaseAssetAtLaunch = amountUSDAfterFees;
        // Total deposit with fee for treasury
        vPool.totalDeposit = totalDeposit;

        vPool.maxOfProjectTokens = vPoolConfiguration.maxOfProjectTokens();
        vPool.baseAsset = vPoolConfiguration.baseToken();
        tokenToIndex[vPool.baseAsset] = assets.length;
        assets.push(vPool.baseAsset);

        emit TotalBudgetDepositInUSD(amountUSDAfterFees);
    }

    /**
        * @notice       Function to claim VPoolToken by user.
     */
    function claimVPoolTokens()
    external
    whenNotPaused
    {
        require(!didUserClaimVPoolTokens[msg.sender], "withdrawn.");
        require(msg.sender != championAddress, "can`t claim.");

        uint256 numberOfTokensToClaim = getNumberOfTokensUserCanClaim(msg.sender);
        _transfer(address(this), msg.sender, numberOfTokensToClaim);

        didUserClaimVPoolTokens[msg.sender] = true;

        emit ClaimedVPoolTokens(msg.sender, numberOfTokensToClaim);
    }

    /**
        * @notice          Function verifies signature and send funds to champion
        * @param           sigR is first 32 bytes of signature.
        * @param           sigS is second 32 bytes of signature.
        * @param           sigV is the last byte of signature.
     */
    function verifyAndExecuteOpenOrder (
        address stableToken,
        uint256 tokenId,
        uint256 amountStableToWithdraw,
        uint256 amountOfTokensToReturn,
        uint256 _bePoolId,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    {
        require(vPool.timeWhileOpenOrderAllowed >= block.timestamp, "Time for open order has elapsed.");
        require(!tokenIdToChampionSwap[tokenId].isBuyingExecuted, "Buying is already done.");
        require(bePoolId == _bePoolId, "Wrong bePoolId");

        address champion = signatureValidator.recoverSignatureOpenOrder(
            bePoolId,
            tokenId,
            amountStableToWithdraw,
            amountOfTokensToReturn,
            sigR,
            sigS,
            sigV
        );
        require(champion == championAddress, "Invalid signer address.");

        tokenIdToChampionSwap[tokenId].amountStableToWithdraw = amountStableToWithdraw;
        tokenIdToChampionSwap[tokenId].isBuyingExecuted = true;
        tokenIdToChampionSwap[tokenId].tokenWithdrawn = stableToken;

        openOrders.push(tokenId);

        IERC20(stableToken).safeTransfer(champion, amountStableToWithdraw);

        emit OpenOrder(champion, tokenId, amountStableToWithdraw);
    }

    /**
        * @notice          Function verifies signature and receive tokens from champion
        * @param           sigR is first 32 bytes of signature.
        * @param           sigS is second 32 bytes of signature.
        * @param           sigV is the last byte of signature.
     */
    function verifyAndExecuteInitCloseOrder(
        uint256 tokenId,
        uint256 totalTokensToBeReceived,
        uint256 finalTokenPriceInUSD,
        uint256 amountOfTokensToReceiveNow,
        uint256 numberOfPortions,
        uint256 unlockingTime,
        address tokenAddress,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    {
        require(!tokenIdToChampionSwap[tokenId].isClosingFirstPortionReceived, "Callable only once per token.");

        address champion = signatureValidator.recoverSignatureCloseOrder(
            tokenId,
            totalTokensToBeReceived,
            finalTokenPriceInUSD,
            amountOfTokensToReceiveNow,
            tokenAddress,
            sigR,
            sigS,
            sigV
        );

        require(champion == championAddress, "Invalid signer address.");

        tokenIdToChampionSwap[tokenId].totalTokensToBeReceived = totalTokensToBeReceived;
        tokenIdToChampionSwap[tokenId].tokenAddress = tokenAddress;
        tokenIdToChampionSwap[tokenId].numberOfPortions = numberOfPortions;
        tokenIdToChampionSwap[tokenId].finalTokenPriceInUSD = finalTokenPriceInUSD;
        tokenIdToChampionSwap[tokenId].isClosingFirstPortionReceived = true;
        tokenIdToChampionSwap[tokenId].usdWorthOfPositionInPurchasePrice = finalTokenPriceInUSD.mul(totalTokensToBeReceived);

        IERC20(tokenAddress).safeTransferFrom(champion, address(this), amountOfTokensToReceiveNow);

        tokenIdToChampionSwap[tokenId].amountTokensReceived = tokenIdToChampionSwap[tokenId].amountTokensReceived.add(amountOfTokensToReceiveNow);

        Portion memory portion;
        portion.potionId = tokenIdToPortions[tokenId].length.add(1);
        portion.amountOfTokens = amountOfTokensToReceiveNow;
        portion.unlockingTime = unlockingTime;
        portion.isPortionReceived = true;

        tokenIdToPortions[tokenId].push(portion);

        tokenIdToVPool[tokenId] = address(this);
        tokenToIndex[tokenAddress] = assets.length;
        assets.push(tokenAddress);

        isLastPortion(portion.potionId, tokenId);

        emit CloseOrderForFirstTime(tokenAddress, totalTokensToBeReceived, finalTokenPriceInUSD, amountOfTokensToReceiveNow);
    }

    /**
        * @notice          Function verifies signature and receive tokens from champion
        * @param           sigR is first 32 bytes of signature.
        * @param           sigS is second 32 bytes of signature.
        * @param           sigV is the last byte of signature.
     */
    function verifyAndExecuteClosePortion(
        uint256 tokenId,
        uint256 portionId,
        uint256 amountOfTokensToReceive,
        uint256 unlockingTime,
        address tokenAddress,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    )
    external
    onlyMaintainer
    {
        require(!tokenIdToChampionSwap[tokenId].isClosingFinalized, "All portions are received.");

        address champion = signatureValidator.recoverSignatureClosePortion(
            tokenId,
            portionId,
            amountOfTokensToReceive,
            sigR,
            sigS,
            sigV
        );

        require(champion == championAddress, "Invalid signer address.");

        Portion memory portion;
        portion.potionId = tokenIdToPortions[tokenId].length;
        portion.amountOfTokens = amountOfTokensToReceive;
        portion.unlockingTime = unlockingTime;
        portion.isPortionReceived = true;

        tokenIdToPortions[tokenId].push(portion);

        IERC20(tokenAddress).safeTransferFrom(championAddress, address(this), amountOfTokensToReceive);

        tokenIdToChampionSwap[tokenId].amountTokensReceived = tokenIdToChampionSwap[tokenId].amountTokensReceived.add(amountOfTokensToReceive);

        isLastPortion(portionId, tokenId);

        emit ClosePortion(tokenAddress, amountOfTokensToReceive);
    }

    /**
         * @notice          Function which check is that potion last one
         * @param           portionId id of portion which is checked
         * @param           tokenId id of token to which portion belongs
     */
    function isLastPortion(
        uint256 portionId,
        uint256 tokenId
    )
    public
    returns (bool)
    {
        if (portionId == tokenIdToChampionSwap[tokenId].numberOfPortions) {
            require(
                tokenIdToChampionSwap[tokenId].amountTokensReceived >= tokenIdToChampionSwap[tokenId].totalTokensToBeReceived,
                "Not all tokens were received."
            );
            tokenIdToChampionSwap[tokenId].isClosingFinalized = true;

            emit OpenOrderClosedAndFinalized(vPool.vPoolId, tokenId, tokenIdToChampionSwap[tokenId].amountTokensReceived);
        }
        return true;
    }

    /**
         * @notice          Function to return assets and their balances from the smart-contract
         * @param           start is the start index of the search
         * @param           end is the end index of the search
         * @dev             If 0,0 passed, it will return all assets.
     */
    function getAssetsAndBalances(
        uint256 start,
        uint256 end
    )
    external
    view
    returns (
        address [] memory,
        uint256 [] memory
    )
    {
        require(start <= end, "Wrong input.");
        require(end <= assets.length, "overflow");

        if(end == 0) {
            end = assets.length;
        }

        uint256 [] memory assetsBalances = new uint256[](end.sub(start));
        address [] memory assetsList = new address[](end.sub(start));

        uint256 counter = 0;

        for(uint256 i = start; i < end; i++) {
            IERC20 asset = IERC20(assets[counter]);

            if (address(asset) != address(0)) {
                assetsList[counter] = address(asset);
                assetsBalances[counter] = asset.balanceOf(address(this));
            }
            counter++;
        }

        return (assetsList, assetsBalances);
    }

    /**
        * @notice          Function to get how much tokens user can claim.
        * @param           follower is address of the user who wants to claim his vPoolTokens.
     */
    function getNumberOfTokensUserCanClaim(
        address follower
    )
    public
    view
    returns (uint256)
    {
        if(didUserClaimVPoolTokens[follower]) {
            // Check if user already claimed HPoolTokens
            return 0;
        }
        // Get how much ETH user subscribed for the pool
        (uint256 subscriptionUSDUser, ) = vPoolManager.getUserSubscriptionForPool(vPool.vPoolId, follower);
        // Amount user can claim is against total minted supply not total supply (total supply changes)
        return subscriptionUSDUser.mul(totalMintedSupply()).div(vPool.totalDeposit);
    }

}