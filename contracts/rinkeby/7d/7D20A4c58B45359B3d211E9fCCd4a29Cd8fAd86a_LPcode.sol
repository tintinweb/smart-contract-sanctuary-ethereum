pragma solidity 0.8.7;

import "./libraries/token/interfaces/IERC20.sol";
import "./libraries/token/interfaces/IWETH.sol";
import "./libraries/token/SafeERC20.sol";

// contract Vault is ReentrancyGuard, IVault {
// we need to set up an interface later with what we want
contract LPcode {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 leverage;
        uint256 averagePrice;
        // uint256 entryFundingRate;
        // uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }
    // positions tracks all open positions
    mapping(bytes32 => Position) public positions;
    mapping(uint256 => string) public errors;
    address public weth;
    address public usdc;
    address public fakeUSDC;
    IERC20 public fakeUSDC_erc;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDG_DECIMALS = 18;
    uint256 public constant USDC_DECIMALS = 6;
    uint256 public mintBurnFeeBasisPoints = 30; // 0.3%
    uint256 public taxBasisPoints = 50; // 0.5%
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;



    constructor(address _weth, address _usdc, address _fakeUSDC) {
        weth = _weth;
        usdc = _usdc;
        tokenDecimals[usdc] = 6;
        tokenDecimals[weth] = 18;
        fakeUSDC = _fakeUSDC;
        fakeUSDC_erc = IERC20(_fakeUSDC);
    }

    // manage GLP book keeping
    // max usdg amounts not important
    // pool amounts are a bit less than total amount in contract but more than total deposited

    // tokenBalances is used only to determine _transferIn values
    // 55537 964779483707560078 tokenbalance while
    // 55029 025353344015710458 is pool amount
    //
    mapping(address => uint256) public tokenBalances;

    // poolAmounts tracks the number of received tokens that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    // shows 95m for WETH right now while front end shows 85m - the 85m is the redemption collateral
    // poolAmounts DOES NOT contain margin
    // REPEAT - see above = you add collateral and subtract out the reserved balances to get redemption val
    mapping(address => uint256) public poolAmounts;

    // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions
    // this value is used to calculate the redemption values for selling of USDG
    // this is an estimated amount, it is possible for the actual guaranteed value to be lower
    // in the case of sudden price decreases, the guaranteed value should be corrected
    // after liquidations are carried out
    // if you increase position, you would DECREASE guarenteed USD by the amount of collateraldelta
    // if you are liquidating a position, you would decrease guarenteedUSD by position.size minus collateral
    // position size minus collateral is literally how much is owed ???
    mapping(address => uint256) public guaranteedUsd;

    // maxUsdgAmounts allows setting a max amount of USDG debt for a token
    // set at 120m for ETH right now seems to be manual
    mapping(address => uint256) public maxUsdgAmounts;

    // usdgAmounts tracks the amount of USDG debt for each whitelisted token
    mapping (address => uint256) public usdgAmounts;

    // reservedAmounts tracks the number of tokens reserved for open leverage positions
    // so if you take out 5 eth leveraged position, reserves the 5 eth
    mapping(address => uint256) public reservedAmounts;

    // feeReserves tracks the amount of fees per token
    mapping (address => uint256) public feeReserves;

    // track FAKE token balances
    mapping (address => uint256) public tempUSDGBalance;

    // token decimals
    mapping (address => uint256) public tokenDecimals;


    /*
    _token: address of the token
    _receiver: who gets the USDG
    _hardcodedprice: price of the _token with 10^30 zeroes
    _tempHowMuch: how many units in terms of the token to buy, times 10*tokendecimals
    */

    // need to set up proper transfer in - probs needs to make it like buying GLP
    // eventually will have to check for how much token deposited, if meets min value etc
    function buyUSDG(address _token, address _receiver, uint256 _hardcodedprice, uint256 _tempHowMuch)
        external
        returns (uint256)
    {
        // todo: transfer in the token itself and verify
        uint256 tokenAmount = _transferIn(_token, _tempHowMuch);
        // set the tokenbBalance in the native decimal places
        // tokenBalances[_token] = tokenBalances[_token].add(_tempHowMuch);
        //uint256 tokenAmount = _tempHowMuch;
        // 1767 000000 000000 000000 000000 000000
        // price is USD price, times 10^30
        uint256 price = _hardcodedprice;
        // token amount times its price divided by 10^30
        // uint256 tokendecimal = 
        uint256 usdgAmount = tokenAmount.mul(price).div(PRICE_PRECISION);
        usdgAmount = usdgAmount.mul(10 ** USDG_DECIMALS).div(10 ** USDC_DECIMALS);
        uint256 feeBasisPoints = mintBurnFeeBasisPoints;
        uint256 amountAfterFees = _collectSwapFees(_token, tokenAmount, feeBasisPoints);
        uint256 mintAmount = amountAfterFees.mul(price).div(PRICE_PRECISION);
        mintAmount = mintAmount.mul(10 ** USDG_DECIMALS).div(10 ** USDC_DECIMALS);
        // important part for bookkeeping - debt assigned to USDC bascially 
        usdgAmounts[_token] = usdgAmounts[_token].add(mintAmount);
        // here you increase pool amount too to account for new GLP deposit - function version checks that there's at least as much of asset as bookkeeping
        poolAmounts[_token] = poolAmounts[_token].add(amountAfterFees);
        // we should mint using the IERC20 contract eventually, but for now doing book keeping only

        // temporary tracking of balance
        tempUSDGBalance[_receiver] = tempUSDGBalance[_receiver].add(mintAmount);

        return mintAmount;
    }

    function sellUSDG(address _token, address _receiver, uint256 _hardcodedprice, uint256 _tempHowMuchUSDG)
        external
        returns (uint256)
    {
        // this checks how much USDG was sent with this contract and updates balances
        // usdgAmount I don't think is good to transferIn - bad code from GMX
        // uint256 usdgAmount = _transferIn(usdg);
        // temp version - assume USDC for now so USDC_Decimals and u dont need to account for it
        // need to require that you cannot exceed the amount that you already have

        uint256 usdgAmount = _tempHowMuchUSDG;

        // divided by price not multiplied
        uint256 redemptionAmount = usdgAmount.mul(PRICE_PRECISION).div(_hardcodedprice);
        redemptionAmount = redemptionAmount.mul(10 ** USDC_DECIMALS).div(10 ** USDG_DECIMALS);
        //uint256 redemptionAmount = getRedemptionAmount(_token, usdgAmount);
        // keeping this function because has valuable logic embedded in it
        // adjusts USDG associated with a given collateral value
        _decreaseUsdgAmount(_token, usdgAmount);


        //_decreasePoolAmount(_token, redemptionAmount);
        // burning bc you sent it to this address so now burn it
        // IUSDG(usdg).burn(address(this), usdgAmount);
        // temp instead of burning, change the temp mapping
        tempUSDGBalance[_receiver] = tempUSDGBalance[_receiver].sub(usdgAmount);



        // the _transferIn call increased the value of tokenBalances[usdg]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for usdg, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        //_updateTokenBalance(usdg);
        // shaan: can get rid of this for now, do not think tokenbalances should track USDG itself
        // tokenBalances[usdg] = IERC20(usdg).balanceOf(address(this));

        uint256 feeBasisPoints = mintBurnFeeBasisPoints;
        // this adds the swap fees to the fee reserves, but this is diff amount than what is adjusted on poolamounts
        uint256 amountOut = _collectSwapFees(_token, redemptionAmount, feeBasisPoints);
        // i moved this down here because i think before it was decreasing the total amount, not the total 
        poolAmounts[_token] = poolAmounts[_token].sub(amountOut, "Vault: poolAmount exceeded");

        // can just test by calling the tokenbalance or pool balance to check that it "moved out"
        // _transferOut(_token, amountOut, _receiver);

        return amountOut;
    }

    // THIS IS FORMULA that is the "pool value"
    // guarenteed USD is total collateral value
    // redemption collateral is in WETH terms, but this gets to the 86m if u convert
    // takes guarenteed usd converts to eth then adds pool amount then subtracts reserved
    // function getRedemptionCollateral(address _token) public view returns (uint256) {
    //     if (stableTokens[_token]) {
    //         return poolAmounts[_token];
    //     }
    //     uint256 collateral = usdToTokenMin(_token, guaranteedUsd[_token]);
    //     // collateral + pool amount - reserved amount
    //     return collateral.add(poolAmounts[_token]).sub(reservedAmounts[_token]);
    // }

    // guarenteed USD in USD terms (internal so 30 decimal points)
    // 50,827,562  533033 199093 573686 814009 704540
    // converted 29194 464101 100000 000000 in eth terms

    // reserved amount sample in WETH
    // 34609 012731 690494 498772

    // pool amount in WETH
    // 54956 692431 223715 810040

    // so 29k eth collateral plus the 54k pool amount eth minus the 34k reserve eth
    // logically, the utilization should be 34k / 54k - lets check

    // function getUtilisation(address _token) public view returns (uint256) {
    //     uint256 poolAmount = poolAmounts[_token];
    //     if (poolAmount == 0) {
    //         return 0;
    //     }

    //     return reservedAmounts[_token].mul(FUNDING_RATE_PRECISION).div(poolAmount);
    // }
    function _collectSwapFees(address _token, uint256 _amount, uint256 _feeBasisPoints) private returns (uint256) {
        // this is just converted to %
        uint256 afterFeeAmount = _amount.mul(BASIS_POINTS_DIVISOR.sub(_feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = _amount.sub(afterFeeAmount);
        feeReserves[_token] = feeReserves[_token].add(feeAmount);
        //emit CollectSwapFees(_token, feeAmount, tokenToUsdMin(_token, feeAmount));
        return afterFeeAmount;
    }
    function _decreaseUsdgAmount(address _token, uint256 _amount) private {
        uint256 value = usdgAmounts[_token];
        // since USDG can be minted using multiple assets
        // it is possible for the USDG debt for a single asset to be less than zero
        // the USDG debt is capped to zero for this case
        if (value <= _amount) {
            usdgAmounts[_token] = 0;
            return;
        }
        usdgAmounts[_token] = value.sub(_amount);
    }
    function _transferIn(address _token, uint256 _amount) private returns (uint256) {
        // for now, assume _token is fakeUSDC - will change later
        require(_token == fakeUSDC, "You can only deposit fakeUSDC");
        uint256 allowance = fakeUSDC_erc.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        fakeUSDC_erc.transferFrom(msg.sender, address(this), _amount);
        // this is how you would send eth back
        // we will eventually send back another GLP token back, for now its accounting
        // payable(msg.sender).transfer(_amount);
        // accounting after transfer is complete
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;

        return nextBalance.sub(prevBalance);
    }

    function _transferOut(address _token, uint256 _amount, address _receiver) private {
        //IERC20(_token).safeTransfer(_receiver, _amount);
        fakeUSDC_erc.safeTransfer(_receiver, _amount);
        // this may be duplicated
        tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
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