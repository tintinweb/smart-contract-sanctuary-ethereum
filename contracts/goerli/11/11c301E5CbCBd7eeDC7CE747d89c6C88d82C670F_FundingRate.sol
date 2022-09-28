pragma solidity 0.8.7;

import "./libraries/token/interfaces/IERC20.sol";
import "./libraries/token/interfaces/IWETH.sol";
import "./libraries/token/SafeERC20.sol";

// first step, store prices in this contract by hitting it
// we need to set up an interface later with what we want
// later, you hit a positionrouter that executes the increase and decrease positions

contract FundingRate {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address public FAKE_USDC = 0x80E10c893150d0FD0E754F9a8338697742D04D7b;


    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    
    uint256 public minBlockInterval = 0;
    uint256 public lastUpdatedBlock;
    uint256 public maxTimeDeviation = 3600;
    uint256 public lastUpdatedAt;
    uint256 public priceDataInterval = 300;
    uint256 public maxPriceUpdateDelay = 3600;
    uint256 public maxDeviationBasisPoints = 750;
    uint256 public constant CUMULATIVE_DELTA_PRECISION = 10 * 1000 * 1000;

    mapping(address => uint256) public poolAmounts;

    // array of tokens used in setCompactedPrices, saves L1 calldata gas costs
    address[] public tokens;
    string[] public asset;
    mapping (string => uint256) public prices;

    // array of tokenPrecisions used in setCompactedPrices, saves L1 calldata gas costs
    // if the token price will be sent with 3 decimals, then tokenPrecision for that token
    // should be 10 ** 3
    uint256[] public tokenPrecisions;
    // uint256(~0) is 256 bits of 1s
    // shift the 1s by (256 - 32) to get (256 - 32) 0s followed by 32 1s
    // so something like 0000 0000 0000 0000 0000 .... 1111 1111 1111 1111 1111 .... 
    uint256 constant public BITMASK_32 = type(uint256).max >> (256 - 32);

    /* Precision tracking */
    uint256 private DEFAULT_PRECISION = 10 ** 30;
    uint256 private FAKEUSDC_PRECISION = 10 ** 6;
    uint256 private USD_PRECISION = DEFAULT_PRECISION;
    uint256 private PRICE_PRECISION = DEFAULT_PRECISION;


    /* Funding Rate Variables */
    // for now, 1 hour funding interval
    // 1 hour .001% (this is 10 in the funding rate precision) is effective rate of 9.155%
    // so probably should be incrementing this around 

    // uint256 public fundingInterval = 8 hours;
    // uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public fundingInterval = 1 hours; // 8760 hours in a year
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 seconds;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000; // means "1" so each zero you take off goes to 10%, 1% ...
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1% is the ceiling on funding rate factor - I see in contract it is currently 100
    uint256 public fundingRateFactor = 100; // setting this manually for now
    // uint256 public stableFundingRateFactor;

    /* 
    uint a = 3 hours; //  10800 or 3*60*60
    uint b = 5 minutes // 300 or 5*60
    uint d = 2 weeks // 1209600 or 2*7*24*60*60
    */

    // cumulativeFundingRates tracks the funding rates based on utilization - changing address to string
    mapping (string => uint256) public cumulativeFundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token - changing address to string again
    mapping (string => uint256) public lastFundingTimes;

    // new shaan mappings
    mapping (string => uint256) public gross_exposure; // maps to USD val, not the token decimals - so these should all be in 10**30 with usd converted
    mapping (string => uint256) public net_exposure; // maps to USD val, not the token decimals - so these should all be in 10**30 with usd converted



    constructor() {
        asset.push("oil");
        asset.push("gas");
        asset.push("gold");
        asset.push("silver");
        asset.push("copper");
        asset.push("corn");
        asset.push("soy");
        asset.push("orange");
    }

    /* Temporary functions */
    function initializeStarterFundingRate(string memory _asset) public returns (uint256) {
        require(cumulativeFundingRates[_asset] == 0, "It has already been init");
        cumulativeFundingRates[_asset] = 1000; // we initialize at 1 * 10^3 - arbitrary because everything else is from there
        lastFundingTimes[_asset] = block.timestamp.div(fundingInterval).mul(fundingInterval);
        return cumulativeFundingRates[_asset];
    }

    function stepUpFunding(string memory _asset, uint256 _howMuch) public returns (uint256) {
        // fundingRateFactor is 100, so updating a 34% from the utilization becomes 34
        // if you did 100, this would cause this segment to jump by .01% per hour, which is 140% annualized increase in interest rate
        // for now this is fine, we just need to measure delta
        // this is just either not changing the cumulative funding rate or its incrementing by max .01% per hour
        require(_howMuch <= 100, "Cannot step up funding rate more than 0.01% per turn"); // funding rate is 6 zeroes, so 5 is 10%, 4, 1%, 3 .1%, and 2 is .01%. We are saying max change is .01%
        cumulativeFundingRates[_asset] = cumulativeFundingRates[_asset].add(_howMuch);
        lastFundingTimes[_asset] = block.timestamp.div(fundingInterval).mul(fundingInterval);
        return cumulativeFundingRates[_asset];
    }

    function stepDownFunding(string memory _asset, uint256 _howMuch) public returns (uint256) {
        // fundingRateFactor is 100, so updating a 34% from the utilization becomes 34
        require(_howMuch <= 100, "Cannot step up funding rate more than 0.01% per turn"); // funding rate is 6 zeroes, so 5 is 10%, 4, 1%, 3 .1%, and 2 is .01%. We are saying max change is .01%
        cumulativeFundingRates[_asset] = cumulativeFundingRates[_asset].sub(_howMuch);
        lastFundingTimes[_asset] = block.timestamp.div(fundingInterval).mul(fundingInterval);
        return cumulativeFundingRates[_asset];
    }



    // functions to do and to integrate with off chain vol index
    
    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor/*, uint256 _stableFundingRateFactor */) external {
        // _onlyGov();
        // _validate(_fundingInterval >= MIN_FUNDING_RATE_INTERVAL, 10);
        // _validate(_fundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 11);
        // _validate(_stableFundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 12);
        fundingInterval = _fundingInterval;
        fundingRateFactor = _fundingRateFactor;
        // stableFundingRateFactor = _stableFundingRateFactor;
    }

    function updateCumulativeFundingRate(string memory _asset) public {
        if (lastFundingTimes[_asset] == 0) {
            lastFundingTimes[_asset] = block.timestamp.div(fundingInterval).mul(fundingInterval);
            return;
        }

        if (lastFundingTimes[_asset].add(fundingInterval) > block.timestamp) {
            return;
        }

        uint256 fundingRate = getNextFundingRate(_asset);
        cumulativeFundingRates[_asset] = cumulativeFundingRates[_asset].add(fundingRate);
        // shaan: why multiply and divide? is that to just convert it into a uint256? I assume? Jackson?
        lastFundingTimes[_asset] = block.timestamp.div(fundingInterval).mul(fundingInterval);

        // emit UpdateFundingRate(_token, cumulativeFundingRates[_token]);
    }

    function getNextFundingRate(string memory _asset) public view returns (uint256) {
        if (lastFundingTimes[_asset].add(fundingInterval) > block.timestamp) { return 0; }

        // time stamp t + 1 minus time stamp t divided by the funding interval
        // so interval is 8 hours, that means that dividing gets you the time change divided by 8 hours
        // so if time delta is 8 hours, then the interval is one, if time delta 16 hours, interval is 2...
        uint256 intervals = block.timestamp.sub(lastFundingTimes[_asset]).div(fundingInterval);
        // this is not relevant anymore because now we have to track total size of bets
        // uint256 poolAmount = poolAmounts[_token];
        uint256 gross = gross_exposure[_asset];
        uint256 net = net_exposure[_asset];
        // if (poolAmount == 0) { return 0; }
        // this is probably wrong but leaving for now
        if (net == 0 || gross == 0) {return 0;}
        // this needs to be changed if we have more than one asset, because depositor assets wil be over many tokens
        uint256 usdval = poolAmounts[FAKE_USDC].mul(USD_PRECISION).div(FAKEUSDC_PRECISION);
        uint256 riskpercentage;
        if (gross.div(usdval) == 0){
            uint256 fakefifty = 50;
            riskpercentage = fundingRateFactor.mul(fakefifty).div(10**2); // fake 50%
        } else{
            // if this ticks up this means more risk, so more funding rate
            riskpercentage = fundingRateFactor.mul(gross).div(usdval);
        }
        // funding rate should NOT be in same decimals as the underlying token
        // btc has 8 decimals, and i am getting 243174 for cumulative
        // usdc has 6, and I am getting 195589 for cumulative
        // weth has 18, and I am getting 314542 for cumulative,
        // so basically, risk percentage needs to be figured out in terms of decimals?
        // it is figured out because you use the factor as a multiplication factor to avoid the decimals from fixed point

        // uint256 _fundingRateFactor = stableTokens[_token] ? stableFundingRateFactor : fundingRateFactor;
        // uint256 _fundingRateFactor = fundingRateFactor;
        // factor (100) times how much is reserved for open positions times intervals divided by pool amount
        // intervals make sense, you basically take the ratio of reserved to total pool amount and multiply it by 100
        // factor is how much it affects the % - so if reserved amount
        // return _fundingRateFactor.mul(reservedAmounts[_token]).mul(intervals).div(poolAmount);
        
        // btc has 8 decimals
        // btc reserved: 33 883 074 283
        // btc poolamount: 292 343 766 508
        // .1159014768
        // so this would be actually 11 590 147
        // bc btc 8 decimals this is 11%
        // then you would multiply by intervals which converts delta to 8 hour increments
        // Shaan Note: we basically have to finely tune this parameter and is going to be part of our special sauce
        // this interval thing basically saying to add 2 times if its been 2 hours, 3x if 3 hours etc

        return riskpercentage.mul(intervals);
    }
    

    function getFundingFee(string memory _asset, uint256 _size, uint256 _entryFundingRate) public view returns (uint256) {
        if (_size == 0) { return 0; }

        uint256 fundingRate = cumulativeFundingRates[_asset].sub(_entryFundingRate);
        if (fundingRate == 0) { return 0; }
        // the divide basically makes sure that the same decimals as the funding rate added with mult get netted out
        return _size.mul(fundingRate).div(FUNDING_RATE_PRECISION);
    }
    

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./interfaces/IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        // require(isContract(target), "Address: call to non-contract");
        require(isContract(target), toAsciiString(target));

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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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