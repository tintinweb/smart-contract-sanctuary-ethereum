/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// File: Address.sol

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256(\'\')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    /**
     * @dev Replacement for Solidity\'s `transfer`: sends `amount` wei to
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: AggregatorInterface.sol

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);
  
  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
  }

// File: AggregatorV3Interface.sol

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  
  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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
      uint80 oundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
    
    }

// File: AssetRateAdapter.sol

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);
    
    function decimals() external view returns (uint8);
    
    function description() external view returns (string memory);
    
    function version() external view returns (uint256);
    
    function underlying() external view returns (address);
    
    function getExchangeRateStateful() external returns (int256);
    
    function getExchangeRateView() external view returns (int256);
    
    function getAnnualizedSupplyRate() external view returns (uint256);
    } 

// File: IERC20.sol

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
     * @dev Moves `amount` tokens from the caller\'s account to `recipient`.
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
     * @dev Sets `amount` as the allowance of `spender` over the caller\'s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender\'s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller\'s
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

// File: IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    }
// File: Math.sol

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
 library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
    }

// File: SafeMath.sol

/**
 * @dev Wrappers over Solidity\'s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it\'s recommended to use it always.
 */
 library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity\'s `+` operator.
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
     * Counterpart to Solidity\'s `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity\'s `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        
        return c;
    }
    
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity\'s `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring \'a\' not being zero, but the
        // benefit is lost if \'b\' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }
    
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity\'s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity\'s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn\'t hold
        
        return c;
    }
    
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity\'s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity\'s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    }

// File: nTokenERC20.sol

interface nTokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);
    
    function nTokenTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);
    
    function nTokenBalanceOf(uint16 currencyId, address account) external view returns (uint256);
    
    function nTokenTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);
    
    function nTokenTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
    function nTokenTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    
    function nTokenTransferApproveAll(address spender, uint256 amount) external returns (bool);
    
    function nTokenClaimIncentives() external returns (uint256);
    
    function nTokenPresentValueAssetDenominated(uint16 currencyId) external view returns (int256);
    
    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);
        } 

// File: AggregatorV2V3Interface.sol

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// File: SafeERC20.sol

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
        // \'safeIncreaseAllowance\' and \'safeDecreaseAllowance\'
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
        // We need to perform a low level call here, to bypass Solidity\'s return data size checking mechanism, since
        // we\'re implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.
        
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
    }

// File: BaseStrategy.sol

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
    }

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);
    
    function symbol() external view returns (string calldata);
    
    function decimals() external view returns (uint256);
    
    function apiVersion() external pure returns (string memory);
    
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);
    
    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);
    
    function deposit(uint256 amount) external returns (uint256);
    
    function deposit(uint256 amount, address recipient) external returns (uint256);
    
    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);
    
    function withdraw(uint256 maxShares) external returns (uint256);
    
    function withdraw(uint256 maxShares, address recipient) external returns (uint256);
    
    function token() external view returns (address);
    
    function strategies(address _strategy) external view returns (StrategyParams memory);
    
    function pricePerShare() external view returns (uint256);
    
    function totalAssets() external view returns (uint256);
    
    function depositLimit() external view returns (uint256);
    
    function maxAvailableShares() external view returns (uint256);
    
    /**
     * View how much the Vault would increase this Strategy\'s borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);
    
    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);
    
    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);
    
    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);
    
    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;
    
    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);
    
    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);
    
    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
    }

/**
 * This interface is here for the keeper bot to use.
 */
 interface StrategyAPI {
    function name() external view returns (string memory);
    
    function vault() external view returns (address);
    
    function want() external view returns (address);
    
    function apiVersion() external pure returns (string memory);
    
    function keeper() external view returns (address);
    
    function isActive() external view returns (bool);
    
    function delegatedAssets() external view returns (uint256);
    
    function estimatedTotalAssets() external view returns (uint256);
    
    function tendTrigger(uint256 callCost) external view returns (bool);
    
    function tend() external;
    
    function harvestTrigger(uint256 callCost) external view returns (bool);
    
    function harvest() external;
    
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
    }

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
    }

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()\'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy\'s performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */
 
 abstract contract BaseStrategy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    string public metadataURI;
    
    // health checks
    bool public doHealthCheck;
    address public healthCheck;
    
    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy\'s version must match the Vault\'s `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.3";
    }
    
    /**
     * @notice This Strategy\'s name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy\'s name.
     */
    function name() external view virtual returns (string memory);
    
    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn\'s TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn\'s ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn\'s Total Value
     *  Locked (TVL) calculation across it\'s ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }
    
    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;
    
    IERC20 public want;
    
    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
    
    event UpdatedStrategist(address newStrategist);
    
    event UpdatedKeeper(address newKeeper);
    
    event UpdatedRewards(address rewards);
    
    event UpdatedMinReportDelay(uint256 delay);
    
    event UpdatedMaxReportDelay(uint256 delay);
    
    event UpdatedProfitFactor(uint256 profitFactor);
    
    event UpdatedDebtThreshold(uint256 debtThreshold);
    
    event EmergencyExitEnabled();
    
    event UpdatedMetadataURI(string metadataURI);
    
    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;
    
    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;
    
    // The minimum multiple that `callCost` must be above the credit/profit to
    // be "justifiable". See `setProfitFactor()` for more details.
    uint256 public profitFactor;
    
    // Use this to adjust the threshold at which running a debt causes a
    // harvest trigger. See `setDebtThreshold()` for more details.
    uint256 public debtThreshold;
    
    // See note on `setEmergencyExit()`.
    bool public emergencyExit;
    
    // modifiers
    modifier onlyAuthorized() {
        require(msg.sender == strategist || msg.sender == governance(), "!authorized");
        _;
    }
    
    modifier onlyEmergencyAuthorized() {
        require(
            msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian() || msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }
    
    modifier onlyStrategist() {
        require(msg.sender == strategist, "!strategist");
        _;
    }
    
    modifier onlyGovernance() {
        require(msg.sender == governance(), "!authorized");
        _;
    }
    
    modifier onlyKeepers() {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management(),
            "!authorized"
        );
        _;
    }
    
    modifier onlyVaultManagers() {
        require(msg.sender == vault.management() || msg.sender == governance(), "!authorized");
        _;
    }
    
    constructor(address _vault) public {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }
    
    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");
        
        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, uint256(-1)); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;
        
        // initialize variables
        minReportDelay = 0;
        maxReportDelay = 86400;
        profitFactor = 100;
        debtThreshold = 0;
        
        vault.approve(rewards, uint256(-1)); // Allow rewards to be pulled
    }
    
    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        healthCheck = _healthCheck;
    }
    
    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        doHealthCheck = _doHealthCheck;
    }
    
    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }
    
    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }
    
    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyStrategist {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, uint256(-1));
        emit UpdatedRewards(_rewards);
    }
    
    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }
    
    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }
    
    /**
     * @notice
     *  Used to change `profitFactor`. `profitFactor` is used to determine
     *  if it\'s worthwhile to harvest, given gas costs. (See `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _profitFactor A ratio to multiply anticipated
     * `harvest()` gas cost against.
     */
    function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
        profitFactor = _profitFactor;
        emit UpdatedProfitFactor(_profitFactor);
    }
    
    /**
     * @notice
     *  Sets how far the Strategy can go into loss without a harvest and report
     *  being required.
     *
     *  By default this is 0, meaning any losses would cause a harvest which
     *  will subsequently report the loss to the Vault for tracking. (See
     *  `harvestTrigger()` for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _debtThreshold How big of a loss this Strategy may carry without
     * being required to report to the Vault.
     */
    function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
        debtThreshold = _debtThreshold;
        emit UpdatedDebtThreshold(_debtThreshold);
    }
    
    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }
    
    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }
    
    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);
    
    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);
    
    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }
    
    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault\'s accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy\'s debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );
        
    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;
    
    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy\'s positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);
    
    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy\'s positions back to the Vault.
     */
     
    function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);
    
    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper\'s estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // We usually don\'t need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        // If your implementation uses the cost of the call in want, you can
        // use uint256 callCost = ethToWant(callCostInWei);
        
        return false;
    }
    
    /**
     * @notice
     *  Adjust the Strategy\'s position. The purpose of tending isn\'t to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don\'t take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }
    
    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/main/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper\'s estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        uint256 callCost = ethToWant(callCostInWei);
        StrategyParams memory params = vault.strategies(address(this));
        
        // Should not trigger if Strategy is not activated
        if (params.activation == 0) return false;
        
        // Should not trigger if we haven\'t waited long enough since previous harvest
        if (block.timestamp.sub(params.lastReport) < minReportDelay) return false;
        
        // Should trigger if hasn\'t been called in a while
        if (block.timestamp.sub(params.lastReport) >= maxReportDelay) return true;
        
        // If some amount is owed, pay it back
        // NOTE: Since debt is based on deposits, it makes sense to guard against large
        //       changes to the value from triggering a harvest directly through user
        //       behavior. This should ensure reasonable resistance to manipulation
        //       from user-initiated withdrawals as the outstanding debt fluctuates.
        uint256 outstanding = vault.debtOutstanding();
        if (outstanding > debtThreshold) return true;
        
        // Check for profits and losses
        uint256 total = estimatedTotalAssets();
        // Trigger if we have a loss to report
        if (total.add(debtThreshold) < params.totalDebt) return true;
        
        uint256 profit = 0;
        if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We\'ve earned a profit!
        
        // Otherwise, only trigger if it "makes sense" economically (gas cost
        // is <N% of value moved)
        uint256 credit = vault.creditAvailable();
        return (profitFactor.mul(callCost) < credit.add(profit));
    }
    
    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy\'s position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy\'s position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy\'s position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding.sub(amountFreed);
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed.sub(debtOutstanding);
            }
            debtPayment = debtOutstanding.sub(loss);
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }
        
        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);
        
        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);
        
        // call healthCheck contract
        if (doHealthCheck && healthCheck != address(0)) {
            require(HealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt), "!healthcheck");
        } else {
            doHealthCheck = true;
        }
        
        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }
    
    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }
    
    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;
    
    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy\'s Vault must be the same as this Strategy\'s Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }
    
    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        vault.revokeStrategy();
        
        emit EmergencyExitEnabled();
    }
    
    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);
    
    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");
        
        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");
        
        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
    }

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);
    
    constructor(address _vault) public BaseStrategy(_vault) {}
    
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }
    
    function clone(address _vault) external returns (address) {
        require(isOriginal, "!clone");
        return this.clone(_vault, msg.sender, msg.sender, msg.sender);
    }
    
    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external returns (address newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }
        
        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);
        
        emit Cloned(newStrategy);
    }
    }

// File: Types.sol

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
enum TokenType {UnderlyingToken, cToken, cETH, Ether, NonMintable}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the frst big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 assetCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint33 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
    }

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
    }

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {NoChange, Update, Delete, RevertIfStored}

/****** Calldata objects ******/

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
    }

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
    }

/****** In memory objects ******/
/// @notice Internal object that represents settled cash balances
struct SettleAmount {
    uint256 currencyId;
    int256 netCashChange;
    }

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 maxCollateralBalance;
    }

/// @notice Internal object that represents an nToken portfolio
struct nTokenPortfolio {
    CashGroupParameters cashGroup;
    PortfolioState portfolioState;
    int256 totalSupply;
    int256 cashBalance;
    uint256 lastInitializedTime;
    bytes6 parameters;
    address tokenAddress;
    }

/// @notice Internal object used during liquidation
struct LiquidationFactors {
    address account;
    // Aggregate free collateral of the account denominated in ETH underlying, 8 decimal precision
    int256 netETHValue;
    // Amount of net local currency asset cash before haircuts and buffers available
    int256 localAssetAvailable;
    // Amount of net collateral currency asset cash before haircuts and buffers available
    int256 collateralAssetAvailable;
    // Haircut value of nToken holdings denominated in asset cash, will be local or collateral nTokens based
    // on liquidation type
    int256 nTokenHaircutAssetValue;
    // nToken parameters for calculating liquidation amount
    bytes6 nTokenParameters;
    // ETH exchange rate from local currency to ETH
    ETHRate localETHRate;
    // ETH exchange rate from collateral currency to ETH
    ETHRate collateralETHRate;
    // Asset rate for the local currency, used in cross currency calculations to calculate local asset cash required
    AssetRateParameters localAssetRate;
    // Used during currency liquidations if the account has liquidity tokens
    CashGroupParameters collateralCashGroup;
    // Used during currency liquidations if it is only a calculation, defaults to false
    bool isCalculation;
    }

/// @notice Internal asset array portfolio state
struct PortfolioState {
    // Array of currently stored assets
    PortfolioAsset[] storedAssets;
    // Array of new assets to add
    PortfolioAsset[] newAssets;
    uint256 lastNewAssetIndex;
    // Holds the length of stored assets after accounting for deleted assets
    uint256 storedAssetLength;
    }

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
    }

/// @notice Internal object used to handle balance state during a transaction
struct BalanceState {
    uint16 currencyId;
    // Cash balance stored in balance state at the beginning of the transaction
    int256 storedCashBalance;
    // nToken balance stored at the beginning of the transaction
    int256 storedNTokenBalance;
    // The net cash change as a result of asset settlement or trading
    int256 netCashChange;
    // Net asset transfers into or out of the account
    int256 netAssetTransferInternalPrecision;
    // Net token transfers into or out of the account
    int256 netNTokenTransfer;
    // Net token supply change from minting or redeeming
    int256 netNTokenSupplyChange;
    // The last time incentives were claimed for this currency
    uint256 lastClaimTime;
    // The last integral supply amount when tokens were claimed
    uint256 lastClaimIntegralSupply;
    }

/// @dev Asset rate used to convert between underlying cash and asset cash
struct AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
    }

/// @dev Cash group when loaded into memory
struct CashGroupParameters {
    uint16 currencyId;
    uint256 maxMarketIndex;
    AssetRateParameters assetRate;
    bytes32 data;
    }

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint256 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
    }

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalAssetCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
    }

/****** Storage objects ******/

/// @dev Token object in storage:
///  20 bytes for token address
///  1 byte for hasTransferFee
///  1 byte for tokenType
///  1 byte for tokenDecimals
///  9 bytes for maxCollateralBalance (may not always be set)
struct TokenStorage {
    // Address of the token
    address tokenAddress;
    // Transfer fees will change token deposit behavior
    bool hasTransferFee;
    TokenType tokenType;
    uint8 decimalPlaces;
    // Upper limit on how much of this token the contract can hold at any time
    uint72 maxCollateralBalance;
    }

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
    }

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
    }

/// @dev Governance parameters for a cash group, total storage is 9 bytes + 7 bytes for liquidity token haircuts
/// and 7 bytes for rate scalars, total of 23 bytes. Note that this is stored packed in the storage slot so there
/// are no indexes stored for liquidityTokenHaircuts or rateScalars, maxMarketIndex is used instead to determine the
/// length.
struct CashGroupSettings {
    // Index of the AMMs on chain that will be made available. Idiosyncratic fCash
    // that is dated less than the longest AMM will be tradable.
    uint8 maxMarketIndex;
    // Time window in 5 minute increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // Total fees per trade, specified in BPS
    uint8 totalFeeBPS;
    // Share of the fees given to the protocol, denominated in percentage
    uint8 reserveFeeShare;
    // Debt buffer specified in 5 BPS increments
    uint8 debtBuffer5BPS;
    // fCash haircut specified in 5 BPS increments
    uint8 fCashHaircut5BPS;
    // If an account has a negative cash balance, it can be settled by incurring debt at the 3 month market. This
    // is the basis points for the penalty rate that will be added the current 3 month oracle rate.
    uint8 settlementPenaltyRate5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationfCashHaircut5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationDebtBuffer5BPS;
    // Liquidity token haircut applied to cash claims, specified as a percentage between 0 and 100
    uint8[] liquidityTokenHaircuts;
    // Rate scalar used to determine the slippage of the market
    uint8[] rateScalars;
    }

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account\'s asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
    }

/// @dev Holds nToken context information mapped via the nToken address, total storage is
/// 16 bytes
struct nTokenContext {
    // Currency id that the nToken represents
    uint16 currencyId;
    // Annual incentive emission rate denominated in WHOLE TOKENS (multiply by 
    // INTERNAL_TOKEN_PRECISION to get the actual rate)
    uint32 incentiveAnnualEmissionRate;
    // The last block time at utc0 that the nToken was initialized at, zero if it
    // has never been initialized
    uint32 lastInitializedTime;
    // Length of the asset array, refers to the number of liquidity tokens an nToken
    // currently holds
    uint8 assetArrayLength;
    // Each byte is a specific nToken parameter
    bytes5 nTokenParameters;
    }

/// @dev Holds account balance information, total storage 32 bytes
struct BalanceStorage {
    // Number of nTokens held by the account
    uint80 nTokenBalance;
    // Last time the account claimed their nTokens
    uint32 lastClaimTime;
    // The total integral supply of the nToken at the last claim time packed into
    // 56 bits. There is some loss of precision here but it is acceptable
    uint56 packedLastClaimIntegralSupply;
    // Cash balance of the account
    int88 cashBalance;
    }

/// @dev Holds information about a settlement rate, total storage 25 bytes
struct SettlementRateStorage {
    uint40 blockTime;
    uint128 settlementRate;
    uint8 underlyingDecimalPlaces;
    }

/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalAssetCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
    }

struct ifCashStorage {
    // Notional amount of fCash at the slot, limited to int128 to allow for
    // future expansion
    int128 notional;
    }

/// @dev A single portfolio asset in storage, total storage of 19 bytes
struct PortfolioAssetStorage {
    // Currency Id for the asset
    uint16 currencyId;
    // Maturity of the asset
    uint40 maturity;
    // Asset type (fCash or Liquidity Token marker)
    uint8 assetType;
    // Notional
    int88 notional;
    }

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes
struct nTokenTotalSupplyStorage {
    // Total supply of the nToken
    uint96 totalSupply;
    // Integral of the total supply used for calculating the average total supply
    uint128 integralTotalSupply;
    // Last timestamp the supply value changed, used for calculating the integralTotalSupply
    uint32 lastSupplyChangeTime;
    }

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 lastClaimIntegralSupply;
    }

// File: NotionalGovernance.sol

interface NotionalGovernance {
    event ListCurrency(uint16 newCurrencyId);
    event UpdateETHRate(uint16 currencyId);
    event UpdateAssetRate(uint16 currencyId);
    event UpdateCashGroup(uint16 currencyId);
    event DeployNToken(uint16 currencyId, address nTokenAddress);
    event UpdateDepositParameters(uint16 currencyId);
    event UpdateInitializationParameters(uint16 currencyId);
    event UpdateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate);
    event UpdateTokenCollateralParameters(uint16 currencyId);
    event UpdateGlobalTransferOperator(address operator, bool approved);
    event UpdateAuthorizedCallbackContract(address operator, bool approved);
    event UpdateMaxCollateralBalance(uint16 currencyId, uint72 maxCollateralBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseRouterAndGuardianUpdated(address indexed pauseRouter, address indexed pauseGuardian);
    
    function transferOwnership(address newOwner) external;
    
    function setPauseRouterAndGuardian(address pauseRouter_, address pauseGuardian_) external;
    
    function listCurrency(
        TokenStorage calldata assetToken,
        TokenStorage calldata underlyingToken,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external returns (uint16 currencyId);
    
    function updateMaxCollateralBalance(
        uint16 currencyId,
        uint72 maxCollateralBalanceInternalPrecision
    ) external;
    
    function enableCashGroup(
        uint16 currencyId,
        AssetRateAdapter assetRateOracle,
        CashGroupSettings calldata cashGroup,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external;
    
    function updateDepositParameters(
        uint16 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) external;
    
    function updateInitializationParameters(
        uint16 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) external;
    
    function updateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate) external;
    
    function updateTokenCollateralParameters(
        uint16 currencyId,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) external;
    
    function updateCashGroup(uint16 currencyId, CashGroupSettings calldata cashGroup) external;
    
    function updateAssetRate(uint16 currencyId, AssetRateAdapter rateOracle) external;
    
    function updateETHRate(
        uint16 currencyId,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external;
    
    function updateGlobalTransferOperator(address operator, bool approved) external;
    
    function updateAuthorizedCallbackContract(address operator, bool approved) external;
    }

// File: NotionalViews.sol

interface NotionalViews {
    function getMaxCurrencyId() external view returns (uint16);
    
    function getCurrencyId(address tokenAddress) external view returns (uint16 currencyId);
    
    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);
        
    function getRateStorage(uint16 currencyId)
        external
        view
        returns (ETHRateStorage memory ethRate, AssetRateStorage memory assetRate);
        
    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
           Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        );
        
    function getCashGroup(uint16 currencyId) external view returns (CashGroupSettings memory);
    
    function getCashGroupAndAssetRate(uint16 currencyId)
        external
        view
        returns (CashGroupSettings memory cashGroup, AssetRateParameters memory assetRate);
        
    function getInitializationParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory annualizedAnchorRates, int256[] memory proportions);
        
    function getDepositParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds);
        
    function nTokenAddress(uint16 currencyId) external view returns (address);
    
    function getNoteToken() external view returns (address);
    
    function getSettlementRate(uint16 currencyId, uint40 maturity)
        external
        view
        returns (AssetRateParameters memory);
        
    function getMarket(uint16 currencyId, uint256 maturity, uint256 settlementDate)
        external view returns (MarketParameters memory);
        
    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);
    
    function getActiveMarketsAtBlockTime(uint16 currencyId, uint32 blockTime)
        external
        view
        returns (MarketParameters[] memory);
        
    function getReserveBalance(uint16 currencyId) external view returns (int256 reserveBalance);
    
    function getNTokenPortfolio(address tokenAddress)
        external
        view
        returns (PortfolioAsset[] memory liquidityTokens, PortfolioAsset[] memory netfCashAssets);
        
    function getNTokenAccount(address tokenAddress)
        external
        view
        returns (
            uint16 currencyId,
            uint256 totalSupply,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            bytes5 nTokenParameters,
            int256 cashBalance,
            uint256 integralTotalSupply,
            uint256 lastSupplyChangeTime
        );
        
    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );
        
    function getAccountContext(address account) external view returns (AccountContext memory);
    
    function getAccountBalance(uint16 currencyId, address account)
        external
        view
        returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime
        );
        
    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);
    
    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);
    
    function getAssetsBitmap(address account, uint16 currencyId) external view returns (bytes32);
    
    function getFreeCollateral(address account) external view returns (int256, int256[] memory);
    
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);
        
    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);
    
    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);
    
    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        returns (uint256);
        
        } 

// File: nERC1155Interface.sol

interface nERC1155Interface {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
    
    function balanceOf(address account, uint256 id) external view returns (uint256);
    
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
        
    function signedBalanceOf(address account, uint256 id) external view returns (int256);
    
    function signedBalanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (int256[] memory);
        
    function setApprovalForAll(address operator, bool approved) external;
    
    function isApprovedForAll(address account, address operator) external view returns (bool);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable;
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable;
    
    function decodeToAssets(uint256[] calldata ids, uint256[] calldata amounts)
        external
        view
        returns (PortfolioAsset[] memory);
        
    function encodeToId(
        uint16 currencyId,
        uint40 maturity,
        uint8 assetType
    ) external pure returns (uint256 id);
    }

// File: NotionalProxy.sol

interface NotionalProxy is nTokenERC20, nERC1155Interface, NotionalGovernance, NotionalViews {
    /** User trading events */
    event CashBalanceChange(address indexed account, uint16 indexed currencyId, int256 netCashChange);
    event nTokenSupplyChange(address indexed account, uint16 indexed currencyId, int256 tokenSupplyChange);
    event MarketsInitialized(uint16 currencyId);
    event SweepCashIntoMarkets(uint16 currencyId, int256 cashIntoMarkets);
    event SettledCashDebt(
        address indexed settledAccount,
        uint16 indexed currencyId,
        address indexed settler,
        int256 amountToSettleAsset,
        int256 fCashAmount
    );
    event nTokenResidualPurchase(
        uint16 indexed currencyId,
        uint40 indexed maturity,
        address indexed purchaser,
        int256 fCashAmountToPurchase,
        int256 netAssetCashNToken
    );
    event LendBorrowTrade(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash
    );
    event AddRemoveLiquidity(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash,
        int256 netLiquidityTokens
    );
    
    /// @notice Emitted when reserve fees are accrued
    event ReserveFeeAccrued(uint16 indexed currencyId, int256 fee);
    /// @notice Emitted whenever an account context has updated
    event AccountContextUpdate(address indexed account);
    /// @notice Emitted when an account has assets that are settled
    event AccountSettled(address indexed account);
    /// @notice Emitted when an asset rate is settled
    event SetSettlementRate(uint256 indexed currencyId, uint256 indexed maturity, uint128 rate);
    
    /* Liquidation Events */
    event LiquidateLocalCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        int256 netLocalFromLiquidator
    );
    
    event LiquidateCollateralCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 collateralCurrencyId,
        int256 netLocalFromLiquidator,
        int256 netCollateralTransfer,
        int256 netNTokenTransfer
    );
    
    event LiquidatefCashEvent(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 fCashCurrency,
        int256 netLocalFromLiquidator,
        uint256[] fCashMaturities,
        int256[] fCashNotionalTransfer
    );
    
    /** UUPS Upgradeable contract calls */
    function upgradeTo(address newImplementation) external;
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
    function getImplementation() external view returns (address);
    function owner() external view returns (address);
    function pauseRouter() external view returns (address);
    function pauseGuardian() external view returns (address);
    
    /** Initialize Markets Action */
    function initializeMarkets(uint16 currencyId, bool isFirstInit) external;
    
    function sweepCashIntoMarkets(uint16 currencyId) external;
    
    /** Redeem nToken Action */
    function nTokenRedeem(
        address redeemer,
        uint16 currencyId,
        uint96 tokensToRedeem_,
        bool sellTokenAssets
    ) external returns (int256);
    
    /** Account Action */
    function enableBitmapCurrency(uint16 currencyId) external;
    
    function settleAccount(address account) external;
    
    function depositUnderlyingToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external payable returns (uint256);
    
    function depositAssetToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external returns (uint256);
    
    function withdraw(
        uint16 currencyId,
        uint88 amountInternalPrecision,
        bool redeemToUnderlying
    ) external returns (uint256);
    
    /** Batch Action */
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;
    
    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions)
        external
        payable;
        
    function batchBalanceAndTradeActionWithCallback(
        address account,
        BalanceActionWithTrades[] calldata actions,
        bytes calldata callbackData
    ) external payable;
    
    /** Liquidation Action */
    function calculateLocalCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);
    
    function liquidateLocalCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);
    
    function calculateCollateralCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation
    )
        external
        returns (
            int256,
            int256,
            int256
        );
        
    function liquidateCollateralCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation,
        bool withdrawCollateral,
        bool redeemToUnderlying
    )
        external
        returns (
            int256,
            int256,
            int256
        );
        
    function calculatefCashLocalLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
    
    function liquidatefCashLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
    
    function calculatefCashCrossCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
    
    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
    }

// File: Strategy.sol

// Necessary interfaces to:
// 1) interact with the Notional protocol

// 2) Transact between WETH (Vault) and ETH (Notional)

// These are the core Yearn libraries

// Import the necessary structs to send/ receive data from Notional

/*
     * @notice
     *  Yearn Strategy allocating vault\'s funds to a fixed rate lending market within the Notional protocol
     */
contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    
    // NotionalContract: proxy that points to a router with different implementations depending on function 
    NotionalProxy public nProxy;
    // ID of the asset being lent in Notional
    uint16 public currencyID; 
    // Difference of decimals between Notional system (8) and want
    uint256 public DECIMALS_DIFFERENCE;
    // Scaling factor for entering positions as the fcash estimations have rounding errors
    uint256 internal constant FCASH_SCALING = 9_995;
    // minimum maturity for the market to enter
    uint256 private minTimeToMaturity;
    // minimum amount of want to act on
    uint16 public minAmountWant;
    // Initialize WETH interface
    IWETH public constant weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // Constant necessary to accept ERC1155 fcash tokens (for migration purposes) 
    bytes4 internal constant ERC1155_ACCEPTED = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    // To control when positions should be liquidated before maturity or not (and thus incur in losses)
    bool internal toggleRealizeLosses;
    // Base for percentage calculations. BPS (10000 = 100%, 100 = 1%)
    uint256 private constant MAX_BPS = 10_000;
    // Current maturity invested
    uint256 private maturity;
    
    // EVENTS
    event Cloned(address indexed clone);
    
    /*
     * @notice constructor for the contract, called at deployment, calls the initializer function used for 
     * cloning strategies
     * @param _vault Address of the corresponding vault the contract reports to
     * @param _nProxy Notional proxy used to interact with the protocol
     * @param _currencyID Notional identifier of the currency (token) the strategy interacts with:
     * 1 - ETH
     * 2 - DAI
     * 3 - USDC
     * 4 - WBTC
     */
    constructor(
        address _vault,
        NotionalProxy _nProxy,
        uint16 _currencyID    
    ) public BaseStrategy (_vault) {
        _initializeNotionalStrategy(_nProxy, _currencyID);
    }
    
    /*
     * @notice Initializer function to initialize both the BaseSrategy and the Notional strategy 
     * @param _vault Address of the corresponding vault the contract reports to
     * @param _strategist Strategist managing the strategy
     * @param _rewards Rewards address
     * @param _keeper Keeper address
     * @param _nProxy Notional proxy used to interact with the protocol
     * @param _currencyID Notional identifier of the currency (token) the strategy interacts with:
     * 1 - ETH
     * 2 - DAI
     * 3 - USDC
     * 4 - WBTC
     */
    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        NotionalProxy _nProxy,
        uint16 _currencyID
    ) external {
        _initialize(_vault, _strategist, _rewards, _keeper);
        _initializeNotionalStrategy(_nProxy, _currencyID);
    }
    
    /*
     * @notice Internal initializer for the Notional Strategy contract
     * @param _nProxy Notional proxy used to interact with the protocol
     * @param _currencyID Notional identifier of the currency (token) the strategy interacts with:
     * 1 - ETH
     * 2 - DAI
     * 3 - USDC
     * 4 - WBTC
     */
    function _initializeNotionalStrategy (
        NotionalProxy _nProxy,
        uint16 _currencyID
    ) internal {
        currencyID = _currencyID;
        nProxy = _nProxy;
        
        (Token memory assetToken, Token memory underlying) = _nProxy.getCurrency(_currencyID);
        DECIMALS_DIFFERENCE = uint256(underlying.decimals).mul(MAX_BPS).div(uint256(assetToken.decimals));
        
        // By default do not realize losses
        toggleRealizeLosses = false;
        
        // Check whether the currency is set up right
        if (_currencyID == 1) {
            require(address(0) == underlying.tokenAddress); 
        } else {
            require(address(want) == underlying.tokenAddress);
        }
    }
    
    /*
     * @notice Cloning function to re-use the strategy code and deploy the same strategy with other key parameters,
     * notably currencyID or yVault
     * @param _vault Address of the corresponding vault the contract reports to
     * @param _strategist Strategist managing the strategy
     * @param _rewards Rewards address
     * @param _keeper Keeper address
     * @param _nProxy Notional proxy used to interact with the protocol
     * @param _currencyID Notional identifier of the currency (token) the strategy interacts with:
     * 1 - ETH
     * 2 - DAI
     * 3 - USDC
     * 4 - WBTC
     */
    function cloneStrategy(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        NotionalProxy _nProxy,
        uint16 _currencyID
    ) external returns (address payable newStrategy) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));
        
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }
        
        Strategy(newStrategy).initialize(_vault, _strategist, _rewards, _keeper, _nProxy, _currencyID);
        
        emit Cloned(newStrategy);
    }
    
    // For ETH based strategies
    receive() external payable {}
    
    /*
     * @notice
     *  Sweep function only callable by governance to be able to sweep any ETH assigned to the strategy\'s balance
     */
    function sendETHToGovernance() external onlyGovernance {
        (bool sent, bytes memory data) = governance().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }
    
    /*
     * @notice
     *  Getter function for the name of the strategy
     * @return string, the name of the strategy
     */
    function name() external view override returns (string memory) {
        // Add your own name here, suggestion e.g. "StrategyCreamYFI"
        return "StrategyNotionalLending";
    }
    
    /*
     * @notice
     *  Getter function for the current invested maturity
     * @return uint256, current maturity we are invested in
     */
    function getMaturity() external view returns(uint256) {
        return maturity;
    }
    
    /*
     * @notice
     *  Getter function for the toggle defining whether to realize losses or not
     * @return bool, current toggleRealizeLosses state variable
     */
    function getToggleRealizeLosses() external view returns(bool) {
        return toggleRealizeLosses;
    }
    
    /*
     * @notice
     *  Setter function for the toggle defining whether to realize losses or not
     * only accessible to strategist, governance, guardian and management
     * @param _newToggle, new booelan value for the toggle
     */
    function setToggleRealizeLosses(bool _newToggle) external onlyEmergencyAuthorized {
        toggleRealizeLosses = _newToggle;
    }
    
    /*
     * @notice
     *  Getter function for the minimum time to maturity to invest into
     * @return uint256, current minTimeToMaturity state variable
     */
    function getMinTimeToMaturity() external view returns(uint256) {
        return minTimeToMaturity;
    }
    
    /*
     * @notice
     *  Setter function for the minimum time to maturity to invest into, accesible only to strategist, governance, guardian and management
     * @param _newTime, new minimum time to maturity to invest into
     */
    function setMinTimeToMaturity(uint256 _newTime) external onlyEmergencyAuthorized {
        minTimeToMaturity = _newTime;
    }
    
    /*
     * @notice
     *  Setter function for the minimum amount of want to invest, accesible only to strategist, governance, guardian and management
     * @param _newMinAmount, new minimum amount of want to invest
     */
    function setMinAmountWant(uint16 _newMinAmount) external onlyEmergencyAuthorized {
        minAmountWant = _newMinAmount;
    }
    
    /*
     * @notice
     *  Function estimating the total assets under management of the strategy, whether realized (token balances
     * of the contract) or unrealized (as Notional lending positions)
     * @return uint256, value containing the total AUM valuation
     */
    function estimatedTotalAssets() public view override returns (uint256) {
        // To estimate the assets under management of the strategy we add the want balance already 
        // in the contract and the current valuation of the matured and non-matured positions (including the cost of)
        // closing the position early
        
        return balanceOfWant()
            .add(_getTotalValueFromPortfolio())
        ;
    }
    
    /*
     * @notice
     *  Accounting function preparing the reporting to the vault taking into acccount the standing debt
     * @param _debtOutstanding, Debt still left to pay to the vault
     * @return _profit, the amount of profits the strategy may have produced until now
     * @return _loss, the amount of losses the strategy may have produced until now
     * @return _debtPayment, the amount the strategy has been able to pay back to the vault
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // Withdraw from terms that already matured
        _checkPositionsAndWithdraw();
        
        // We only need profit for decision making
        (_profit, ) = getUnrealisedPL();
        // free funds to repay debt + profit to the strategy
        uint256 wantBalance = balanceOfWant();
        
        // If we cannot realize the profit using want balance, don\'t report a profit to avoid
        // closing active positions before maturity
        if (_profit > wantBalance) {
            _profit = 0;
        }
        uint256 amountRequired = _debtOutstanding.add(_profit);
        if(amountRequired > wantBalance) {
            // we need to free funds
            // NOTE: liquidatePosition will try to use balanceOfWant first
            // liquidatePosition will realise Losses if required !! (which cannot be equal to unrealised losses if
            // we are not withdrawing 100% of position)
            uint256 amountAvailable = wantBalance;
            uint256 realisedLoss = 0;
            
            // If the toggle to realize losses is off, do not close any position
            if(toggleRealizeLosses) {
                (amountAvailable, realisedLoss) = liquidatePosition(amountRequired);
            }
            _loss = realisedLoss;
            
            if(amountAvailable >= amountRequired) {
                // There are no realisedLosses, debt is paid entirely and 
                // profit is defined in line 299 and 306
                _debtPayment = _debtOutstanding;
            } else {
                // We were not able to free enough funds
                if(amountAvailable < _debtOutstanding) {
                    // available funds are lower than the repayment that we need to do
                    _profit = 0;
                    _debtPayment = amountAvailable;
                    // we dont report losses here as the strategy might not be able to return in this harvest
                    // but it will still be there for the next harvest
                } else {
                    // NOTE: amountRequired is always equal or greater than _debtOutstanding
                    // important to use amountRequired just in case amountAvailable is > amountAvailable
                    // We will not report and losses but pay the entire debtOutstanding and report the rest of
                    // amountAvailable as profit (therefore losses are 0 because we were able to pay debtPayment)
                    _debtPayment = _debtOutstanding;
                    _profit = amountAvailable.sub(_debtPayment);
                    _loss = 0;
                }
            }
        } else {
            _debtPayment = _debtOutstanding;
        }
    }
    
    /*
     * @notice
     * Function re-allocating the available funds (present in the strategy\'s balance in the \'want\' token)
     * into new positions in Notional
     * @param _debtOutstanding, Debt still left to pay to the vault
     */
    function adjustPosition(uint256 _debtOutstanding) internal override {
        uint256 availableWantBalance = balanceOfWant();
        
        if(availableWantBalance <= _debtOutstanding) {
            return;
        }
        availableWantBalance = availableWantBalance.sub(_debtOutstanding);
        if(availableWantBalance < minAmountWant) {
            return;
        }
        
        // gas savings
        uint16 _currencyID = currencyID;
        uint256 _maturity = maturity;
        
        // Use the market index with the shortest maturity
        (uint256 minMarketIndex, uint256 minMarketMaturity) = _getMinimumMarketIndex();
        // If the new position enters a different market than the current maturity, roll the current position into
        // the next maturity market
        if(minMarketMaturity > _maturity && _maturity > 0) {
            availableWantBalance += _rollOverTrade(_maturity);
        }
        
        if (_currencyID == 1) {
            // Only necessary for wETH/ ETH pair
            weth.withdraw(availableWantBalance);
        } else {
            want.approve(address(nProxy), availableWantBalance);
        }
        // Amount to trade is the available want balance, changed to 8 decimals and
        // scaled down by FCASH_SCALING to ensure it does not revert
        int88 amountTrade = int88(
                availableWantBalance.mul(MAX_BPS).div(DECIMALS_DIFFERENCE).mul(FCASH_SCALING).div(MAX_BPS)
            );
        // NOTE: May revert if the availableWantBalance is too high and interest rates get to < 0
        int256 fCashAmountToTrade = nProxy.getfCashAmountGivenCashAmount(
            _currencyID, 
            -amountTrade, 
            minMarketIndex, 
            block.timestamp
            );
            
        if (fCashAmountToTrade <= 0) {
            return;
        }
        
        // Trade the shortest maturity market with at least minAmountToMaturity time left
        bytes32[] memory trades = new bytes32[](1);
        trades[0] = getTradeFrom(
            0, 
            minMarketIndex, 
            uint256(fCashAmountToTrade)
            );
            
        executeBalanceActionWithTrades(
            DepositActionType.DepositUnderlying,
            availableWantBalance,
            0, 
            true,
            true,
            trades
        );
        
        maturity = minMarketMaturity;
    }
    
    /*
     * @notice
     *  Internal function encoding a trade parameter into a bytes32 variable needed for Notional
     * @param _tradeType, Identification of the trade to perform, following the Notional classification in enum \'TradeActionType\'
     * @param _marketIndex, Market index in which to trade into
     * @param _amount, fCash amount to trade
     * @return bytes32 result, the encoded trade ready to be used in Notional\'s \'BatchTradeAction\'
     */
    function getTradeFrom(uint8 _tradeType, uint256 _marketIndex, uint256 _amount) internal returns (bytes32 result) {
        uint8 tradeType = uint8(_tradeType);
        uint8 marketIndex = uint8(_marketIndex);
        uint88 fCashAmount = uint88(_amount);
        uint32 minSlippage = uint32(0);
        uint120 padding = uint120(0);
        
        // We create result of trade in a bitmap packed encoded bytes32
        result = bytes32(uint(tradeType)) << 248;
        result |= bytes32(uint(marketIndex) << 240);
        result |= bytes32(uint(fCashAmount) << 152);
        result |= bytes32(uint(minSlippage) << 120);
        
        return result;
    }
    
    /*
     * @notice
     *  Internal function to assess the unrealised P&L of the Notional\'s positions
     * @return uint256 result, the encoded trade ready to be used in Notional\'s \'BatchTradeAction\'
     */
    function getUnrealisedPL() internal view returns (uint256 _unrealisedProfit, uint256 _unrealisedLoss) {
        // Calculate assets. This includes profit and cost of closing current position. 
        // Due to cost of closing position, If called just after opening the position, assets < invested want
        uint256 totalAssets = estimatedTotalAssets();
        // Get total debt from vault
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        // Calculate current P&L
        if(totalDebt > totalAssets) {
            // we have losses
            // Losses are unrealised until we close the position so we should not report them until realised
            _unrealisedLoss = totalDebt.sub(totalAssets);
        } else {
            // we have profit
            _unrealisedProfit = totalAssets.sub(totalDebt);
        }
        
    }
    
    /*
     * @notice
     *  Internal function liquidating enough Notional positions to liberate _amountNeeded \'want\' tokens
     * @param _amountNeeded, The total amount of tokens needed to pay the vault back
     * @return uint256 _liquidatedAmount, Amount freed
     * @return uint256 _loss, Losses incurred due to early closing of positions
     */
    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        _checkPositionsAndWithdraw();
        
        uint256 wantBalance = balanceOfWant();
        if (wantBalance >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        
        // Get current position\'s P&L
        (, uint256 unrealisedLosses) = getUnrealisedPL();
        // We only need to withdraw what we don\'t currently have
        uint256 amountToLiquidate = _amountNeeded.sub(wantBalance);
        
        // Losses are realised IFF we withdraw from the position, as they will come from breaking our "promise"
        // of lending at a certain %
        // The strategy will only realise losses proportional to the amount we are liquidating
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        uint256 lossesToBeRealised = unrealisedLosses.mul(amountToLiquidate).div(totalDebt.sub(wantBalance));
        
        // Due to how Notional works, we need to substract losses from the amount to liquidate
        // If we don\'t do this and withdraw a small enough % of position, we will not incur in losses,
        // leaving them for the future withdrawals (which is bad! those who withdraw should take the losses)
        amountToLiquidate = amountToLiquidate.sub(lossesToBeRealised);
        
        // Retrieve info of portfolio (summary of our position/s)
        PortfolioAsset[] memory _accountPortfolio = nProxy.getAccountPortfolio(address(this));
        // The maximum amount of trades we are doing is the number of terms (aka markets) we are in
        bytes32[] memory trades = new bytes32[](_accountPortfolio.length);
        
        // To liquidate the full required amount we may need to liquidate several differents terms
        // This shouldn\'t happen in the basic strategy (as we will only lend to the shortest term)
        uint256 remainingAmount = amountToLiquidate;
        // The following for-loop creates the list of required trades to get the amountRequired
        uint256 tradesToExecute = 0;
        for(uint256 i; i < _accountPortfolio.length; i++) {
            if (remainingAmount > 0) {
                uint256 _marketIndex = _getMarketIndexForMaturity(
                    _accountPortfolio[i].maturity
                );
                // Retrieve size of position in this market (underlyingInternalNotation)
                (, int256 underlyingInternalNotation) = nProxy.getCashAmountGivenfCashAmount(
                    currencyID,
                    int88(-_accountPortfolio[i].notional),
                    _marketIndex,
                    block.timestamp
                );
                // Adjust for decimals (Notional uses 8 decimals regardless of underlying)
                uint256 underlyingPosition = uint256(underlyingInternalNotation).mul(DECIMALS_DIFFERENCE).div(MAX_BPS);
                // If we can withdraw what we need from this market, we do and stop iterating over markets
                // If we can\'t, we create the trade to withdraw maximum amount and try in the next market / term
                if(underlyingPosition > remainingAmount) {
                    
                    int256 fCashAmountToTrade = -nProxy.getfCashAmountGivenCashAmount(
                        currencyID, 
                        int88(remainingAmount.mul(MAX_BPS).div(DECIMALS_DIFFERENCE)) + 1, 
                        _marketIndex, 
                        block.timestamp
                        );
                    trades[i] = getTradeFrom(1, _marketIndex, 
                                            uint256(fCashAmountToTrade)
                                            );
                    tradesToExecute++;
                    remainingAmount = 0;
                    break;
                } else {
                    trades[i] = getTradeFrom(1, _marketIndex, uint256(_accountPortfolio[i].notional));
                    tradesToExecute++;
                    remainingAmount -= underlyingPosition;
                    maturity = 0;
                }
            }
        }
        // NOTE: if for some reason we reach this with remainingAmount > 0, we will report losses !
        // this makes sense because means we have iterated over all markets and haven\'t been able to withdraw
        
        // As we did not know the number of trades we needed to make, we adjust the array to only include
        // non-empty trades (reverts otherwise)
        bytes32[] memory final_trades = new bytes32[](tradesToExecute);
        for (uint256 j=0; j<tradesToExecute; j++) {
            final_trades[j] = trades[j];
        }
        
        // Execute previously calculated trades
        // We won\'t deposit anything (we are withdrawing) and we signal that we want the underlying to hit the strategy (instead of remaining in our Notional account)
        executeBalanceActionWithTrades(
            DepositActionType.None, 
            0,
            0, 
            true,
            true,
            final_trades
        );
        
        // Assess result 
        uint256 totalAssets = balanceOfWant();
        if (_amountNeeded > totalAssets) {
            _liquidatedAmount = totalAssets;
            // _loss should be equal to lossesToBeRealised ! 
            _loss = _amountNeeded.sub(totalAssets);
            
        } else {
            _liquidatedAmount = _amountNeeded;
        }
        
        // Re-set the toggle to false
        toggleRealizeLosses = false;
    }
    
    /*
     * @notice
     *  Internal function used in emergency to close all active positions and liberate all assets
     * @return uint256 amountLiquidated, the total amount liquidated
     */
    function liquidateAllPositions() internal override returns (uint256) {
        
        (uint256 amountLiquidated, ) = liquidatePosition(estimatedTotalAssets());
        
        return amountLiquidated;
    }
    
    /*
     * @notice
     *  Internal function used to migrate all \'want\' tokens and active Notional positions to a new strategy
     * @param _newStrategy address where the contract of the new strategy is located
     */
    function prepareMigration(address _newStrategy) internal override {
        _checkPositionsAndWithdraw();
        PortfolioAsset[] memory _accountPortfolio = nProxy.getAccountPortfolio(address(this));
        
        uint256 _id = 0;
        for(uint256 i = 0; i < _accountPortfolio.length; i++) {
            _id = nProxy.encodeToId(
                currencyID, 
                uint40(_accountPortfolio[i].maturity), 
                uint8(_accountPortfolio[i].assetType)
                );
            nProxy.safeTransferFrom(
                address(this), 
                _newStrategy,
                _id, 
                uint256(_accountPortfolio[i].notional),
                ""
                );
        }
        
    }
    
    /*
     * @notice
     *  Callback function needed to receive ERC1155 (fcash), not needed for the first startegy contract but 
     * relevant for all the next ones
     * @param _sender, address of the msg.sender
     * @param _from, address of the contract sending the erc1155
     * @_id, encoded id of the asset (fcash or liquidity token)
     * @_amount, amount of assets tor receive
     * _data, bytes calldata to perform extra actions after receiving the erc1155
     * @return bytes4, constant accepting the erc1155
     */
    function onERC1155Received(address _sender, address _from, uint256 _id, uint256 _amount, bytes calldata _data) public returns(bytes4){
        return ERC1155_ACCEPTED;
    }
    
    /*
     * @notice
     *  Define protected tokens for the strategy to manage persistently that will not get converted back
     * to \'want\'
     * @return address result, the address of the tokens to protect
     */
    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}
    
    /*
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     */
    function ethToWant(uint256 _amtInWei)
        public
        view
        override
        returns (uint256)
    {
        return _fromETH(_amtInWei, address(want));
    }
    
    /*
     * @notice
     *  Internal function exchanging between ETH to \'want\'
     * @param _amount, Amount to exchange
     * @param asset, \'want\' asset to exchange to
     * @return uint256 result, the equivalent ETH amount in \'want\' tokens
     */
    function _fromETH(uint256 _amount, address asset)
        internal
        view
        returns (uint256)
    {
        if (
            _amount == 0 ||
            _amount == type(uint256).max ||
            address(asset) == address(weth) // 1:1 change
        ) {
            return _amount;
        }
        
        (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            AssetRateParameters memory assetRate
        ) = nProxy.getCurrencyAndRates(currencyID);
            
        return _amount.mul(uint256(underlyingToken.decimals)).div(uint256(ethRate.rate));
    }
    
    /*
     * @notice
     *  Public function used by the keeper to assess whether a harvest is necessary or not, 
     * returns true only if there is a position to settle
     * @param callCostInWei, call cost estimation performed by the keeper
     * @return bool, true when the strategy has a mature positionÂº
     */
    function harvestTrigger(uint256 callCostInWei) public view override returns (bool) {
        // We check if there is anything to settle in the account\'s portfolio by checking the account\'s
        // nextSettleTime in the account context
        AccountContext memory _accountContext = nProxy.getAccountContext(address(this));
        // If there is something to settle, do it and withdraw to the strategy\'s balance
        if (uint256(_accountContext.nextSettleTime) < block.timestamp) {
            return true;
        }
        return false;
    }
    
    // INTERNAL FUNCTIONS
    
    /*
     * @notice
     *  Internal function used to check whether there are positions that have reached maturity and if so, 
     * settle and withdraw them realizing the profits in the strategy\'s \'want\' balance
     */
    function _checkPositionsAndWithdraw() internal {
        // We check if there is anything to settle in the account\'s portfolio by checking the account\'s
        // nextSettleTime in the account context
        AccountContext memory _accountContext = nProxy.getAccountContext(address(this));
        
        // If there is something to settle, do it and withdraw to the strategy\'s balance
        if (uint256(_accountContext.nextSettleTime) < block.timestamp) {
            nProxy.settleAccount(address(this));
            
            (int256 cashBalance, 
            int256 nTokenBalance,
            uint256 lastClaimTime) = nProxy.getAccountBalance(currencyID, address(this));
            
            if(cashBalance > 0) {
                nProxy.withdraw(currencyID, uint88(cashBalance), true);
                if (currencyID == 1) {
                    // Only necessary for wETH/ ETH pair
                    weth.deposit{value: address(this).balance}();
                }
                maturity = 0;
            }
        }
        
    }
    
    /*
     * @notice
     *  Loop through the strategy\'s positions and convert the fcash to current valuation in \'want\', including the
     * fees incurred by leaving the position early. Represents the NPV of the position today.
     * @return uint256 _totalWantValue, the total amount of \'want\' tokens of the strategy\'s positions
     */
    function _getTotalValueFromPortfolio() internal view returns(uint256 _totalWantValue) {
        PortfolioAsset[] memory _accountPortfolio = nProxy.getAccountPortfolio(address(this));
        MarketParameters[] memory _activeMarkets = nProxy.getActiveMarkets(currencyID);
        // Iterate over all active markets and sum value of each position 
        for(uint256 i = 0; i < _accountPortfolio.length; i++) {
            for(uint256 j = 0; j < _activeMarkets.length; j++){
                if(_accountPortfolio[i].maturity < block.timestamp) {
                    // Convert the fcash amount of the position to underlying assuming a 1:1 conversion rate
                    // (taking into account decimals difference)
                    _totalWantValue += uint256(_accountPortfolio[i].notional).mul(DECIMALS_DIFFERENCE).div(MAX_BPS);
                    break;
                }
                if(_accountPortfolio[i].maturity == _activeMarkets[j].maturity) {
                    (, int256 underlyingPosition) = nProxy.getCashAmountGivenfCashAmount(
                        currencyID,
                        int88(-_accountPortfolio[i].notional),
                        j+1,
                        block.timestamp
                    );
                    _totalWantValue += uint256(underlyingPosition).mul(DECIMALS_DIFFERENCE).div(MAX_BPS);
                    break;
                }
            }
        }
    }
    
    // CALCS
    /*
     * @notice
     *  Internal function getting the current \'want\' balance of the strategy
     * @return uint256 result, strategy\'s \'want\' balance
     */
    function balanceOfWant() internal view returns (uint256) {
        return want.balanceOf(address(this));
    }
    
    /*
     * @notice
     *  Get the market index of a current position to calculate the real cash valuation
     * @param _maturity, Maturity of the position to value
     * @param _activeMarkets, All current active markets for the currencyID
     * @return uint256 result, market index of the position to value
     */
    function _getMarketIndexForMaturity(
        uint256 _maturity
    ) internal view returns(uint256) {
        MarketParameters[] memory _activeMarkets = nProxy.getActiveMarkets(currencyID);
        bool success = false;
        for(uint256 j=0; j<_activeMarkets.length; j++){
            if(_maturity == _activeMarkets[j].maturity) {
                return j+1;
            }
        }
        
        if (success == false) {
            return 0;
        }
    }
    
    /*
     * @notice
     *  Internal function calculating the market index with the shortest maturity that was at 
     * least minAmountToMaturity seconds still 
     * @return uint256 result, the minimum market index the strategy should be entering positions into
     * @return uint256 maturity, the minimum market index\'s maturity the strategy should be entering positions into
     */
    function _getMinimumMarketIndex() internal view returns(uint256, uint256) {
        MarketParameters[] memory _activeMarkets = nProxy.getActiveMarkets(currencyID);
        for(uint256 i = 0; i<_activeMarkets.length; i++) {
            if (_activeMarkets[i].maturity - block.timestamp >= minTimeToMaturity) {
                return (i+1, uint256(_activeMarkets[i].maturity));
            }
        }
    } 
    
    // NOTIONAL FUNCTIONS
    /*
     * @notice
     *  Internal function executing a \'batchBalanceAndTradeAction\' within Notional to either Lend or Borrow
     * @param actionType, Identification of the action to perform, following the Notional classification 
     * in enum \'DepositActionType\'
     * @param withdrawAmountInternalPrecision, withdraw an amount of asset cash specified in Notional 
     *  internal 8 decimal precision
     * @param withdrawEntireCashBalance, whether to withdraw entire cash balance. Useful if there may be
     * an unknown amount of asset cash residual left from trading
     * @param redeemToUnderlying, whether to redeem asset cash to the underlying token on withdraw
     * @param trades, array of bytes32 trades to perform
     */
    function executeBalanceActionWithTrades(
        DepositActionType actionType,
        uint256 depositActionAmount,
        uint256 withdrawAmountInternalPrecision,
        bool withdrawEntireCashBalance,
        bool redeemToUnderlying,
        bytes32[] memory trades) internal {
        BalanceActionWithTrades[] memory actions = new BalanceActionWithTrades[](1);
        // gas savings
        uint16 _currencyID = currencyID;
        actions[0] = BalanceActionWithTrades(
            actionType,
            _currencyID,
            depositActionAmount,
            withdrawAmountInternalPrecision, 
            withdrawEntireCashBalance,
            redeemToUnderlying,
            trades
        );
        
        if (_currencyID == 1) {
            nProxy.batchBalanceAndTradeAction{value: depositActionAmount}(address(this), actions);
            weth.deposit{value: address(this).balance}();
        } else {
            nProxy.batchBalanceAndTradeAction(address(this), actions);
        }
    }
    
    /*
     * @notice
     *  Internal function Closing a current non-mature position to re-invest the amount into a new 
     * higher maturity market
     * @param _currentMaturity, current maturity the strategy is invested in
     * @return uint256, liberated amount, now existing in want balance to add up to the availableWantBalance
     * to trade into in adjustPosition()
     */
    function _rollOverTrade(uint256 _currentMaturity) internal returns(uint256) {
        uint256 prevBalance = balanceOfWant();
        PortfolioAsset[] memory _accountPortfolio = nProxy.getAccountPortfolio(address(this));
        uint256 _currentIndex = _getMarketIndexForMaturity(_currentMaturity);
        
        bytes32[] memory rollTrade = new bytes32[](1);
        rollTrade[0] = getTradeFrom(1, _currentIndex, uint256(_accountPortfolio[0].notional));
        executeBalanceActionWithTrades(
            DepositActionType.None, 
            0,
            0, 
            true,
            true,
            rollTrade
        );
        
        return (balanceOfWant() - prevBalance);
    }
    
    }