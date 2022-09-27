pragma solidity 0.8.7;

import "./libraries/token/interfaces/IERC20.sol";
import "./libraries/token/interfaces/IWETH.sol";
import "./libraries/token/SafeERC20.sol";

// contract Vault is ReentrancyGuard, IVault {
contract Vault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* 
     * Everything inside of Position is in USD (10^30) for simplicity.
     * This means that returning collateral out means USD -> USDC precision conversion is needed.
     */
    struct Position {
        uint256 size; // in USD (10^30)
        uint256 collateral; // in USD (10^30)
        uint256 averagePrice; // in USD (10^30)
        // uint256 entryFundingRate; // in USD (10^30)
        // uint256 reserveAmount;
        int256 realisedPnl; // in USD (10^30)
        uint256 lastIncreasedTime; //
    }

    /* Position Tracking */
    mapping (bytes32 => Position) public positions;

    mapping (uint256 => string) public errors;

    /* Precision tracking */
    uint256 private DEFAULT_PRECISION = 10 ** 30;
    uint256 private FAKEUSDC_PRECISION = 10 ** 6;
    uint256 private USD_PRECISION = DEFAULT_PRECISION;
    uint256 private PRICE_PRECISION = DEFAULT_PRECISION;
    // funding rate is two more digits than bps, so 1% in funding rate is 10000, 10% is 100000, and 100% is FUNDING_RATE_PRECISION
    uint256 public constant FUNDING_RATE_PRECISION = 10 ** 6;

    /* env variables */
    uint256 public MAX_LEVERAGE = 50; // 50x
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public marginFeeBasisPoints = 10; // 0.1%
    address public FAKE_USDC = 0x80E10c893150d0FD0E754F9a8338697742D04D7b;

    /* Mappings for Bookkeeping */
    mapping (address => uint256) public feeReserves;

    // tokenBalances is used only to determine _transferIn values
    mapping (address => uint256) public tokenBalances;

    // poolAmounts tracks the number of received tokens that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    // shows 95m for WETH right now while front end shows 85m - the 85m is the redemption collateral
    // poolAmounts DOES NOT contain margin
    // REPEAT - see above = you add collateral and subtract out the reserved balances to get redemption val
    mapping(address => uint256) public poolAmounts;

    /* Mappings for gross and net exposure */
    mapping (string => uint256) public gross_exposure; // maps to USD val, not the token decimals - so these should all be in 10**30 with usd converted
    mapping (string => uint256) public net_exposure; // maps to USD val, not the token decimals - so these should all be in 10**30 with usd converted



    // To test for this event, follow this: https://ethereum.stackexchange.com/questions/93757/listening-to-events-using-ethers-js-on-a-hardhat-test-network
    event Liquidation(uint collateral, uint positionSize);
    event SendUSDC(address recipient, uint amount);

    constructor() {
        errors[1] = "Position size is unexpectedly 0";
        errors[2] = "USD out is unexpectedly 0";
        errors[3] = "Collateral is unexpectedly 0";
        errors[4] = "Leverage unexpected changed";
        errors[5] = "Cannot liquidate a healthy position";
        errors[6] = "Size delta is larger than position size";
        errors[7] = "Fee is greater than collateral";
    }

    function increasePosition(
        string memory asset, // the asset being purchased
        uint256 collateralUSDC, // USDC collateral being put up (10^6)
        uint256 sizeDelta, // USD size delta (10^30)
        uint256 price // price of the asset in USD (10^30)
    ) external {
        // Fetch or create new position
        bytes32 key = getPositionKey(msg.sender, asset);
        Position storage position = positions[key];

        // If position is new, set the price as the average price
        if (position.size == 0) {
            position.averagePrice = price;
        }
        // Otherwise Update the average purchase price of the user's position
        if (position.size > 0 && sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(price, position.size, position.averagePrice, sizeDelta);
        }
        // tried to set up collect margin fee properly - fee is in 30 decimals too but saves down the USDC as 6
        uint256 feeUSD = _collectMarginFees(sizeDelta);
        uint256 feeUSDC = feeUSD.mul(FAKEUSDC_PRECISION).div(USD_PRECISION);
        // fee comes out of collateral
        _validate(collateralUSDC > feeUSDC, 7);
        uint256 collateralAfterFeesUSDC = collateralUSDC.sub(feeUSDC);
        uint256 collateralAfterFeesUSD = collateralAfterFeesUSDC.mul(USD_PRECISION).div(FAKEUSDC_PRECISION);
        position.collateral = position.collateral.add(collateralAfterFeesUSD);

        // TODO: Validate leverage is within bounds bc of fee deduction (need to validate liquidation)
        position.size = position.size.add(sizeDelta);
        position.lastIncreasedTime = block.timestamp;

        // increase gross and net exposures, right now long only so net and short should equal each other
        gross_exposure[asset] = gross_exposure[asset].add(sizeDelta);
        // eventually you need to change this to if else for if its long or not you subtract vs add - also need to account for dealing with uint256? if it goes negative?
        // we need to figure out how this would be negative lol
        net_exposure[asset] = net_exposure[asset].add(sizeDelta);


        _validate(position.size > 0, 1);
        // increase the fee reserve amount, then increase the pool amount
        // _increasePoolAmount(FAKE_USDC, collateralUSDC);
        // shaan changed to collateralAfterFeesUSDC
        _increasePoolAmount(FAKE_USDC, collateralAfterFeesUSDC);
        // maybe set up a function for this later? but add token balance now
        tokenBalances[FAKE_USDC] = tokenBalances[FAKE_USDC].add(collateralUSDC);
        // if someone sends us tokens this will get out of whack, and thats why GMX has _transferIn
        // for now we do not transfer in
        // require(tokenBalances[FAKE_USDC] == IERC20(FAKE_USDC).balanceOf(address(this)));
        require(tokenBalances[FAKE_USDC] == poolAmounts[FAKE_USDC].add(feeReserves[FAKE_USDC]), "Token balance does not match pool and fees");

    }
    
    // Decrease the position, but keep the leverage constant; i.e decrease the collateral
    function decreasePosition(
        string memory asset, // the asset being purchased
        uint256 _collateralDeltaUSDC, // in USD (10^6), this is necessary bc calculating leverage is inaccurate
        uint256 _sizeDelta, // in USD (10^30)
        uint256 price // price of the asset in USD (10^30)
    ) public returns (uint256) {
        bytes32 key = getPositionKey(msg.sender, asset);
        Position storage position = positions[key];
        // Validate that the position exists and inputs
        _validate(position.size > 0, 1);
        _validate(_sizeDelta <= position.size, 6);

        // within reducecollateral, it
        (uint256 usdOut, uint256 usdOutAfterFee) = _reduceCollateral(asset, msg.sender, _collateralDeltaUSDC, _sizeDelta, price);
        if (_collateralDeltaUSDC > 0) {
            // If collateral is being reduced, then there should be USD out
            _validate(usdOut > 0, 2);
        }

        if (position.size != _sizeDelta) {
            position.size = position.size.sub(_sizeDelta);
            _validate(position.collateral > 0, 3);
        } else {
            delete positions[key];
        }
        // these will not balace each other because the size delta could have changed? But idk i think the 
        // decrease gross and net exposures, right now long only so net and short should equal each other
        gross_exposure[asset] = gross_exposure[asset].sub(_sizeDelta);
        // eventually you need to change this to if else for if its long or not you subtract vs add - also need to account for dealing with uint256? if it goes negative?
        // we need to figure out how this would be negative lol
        net_exposure[asset] = net_exposure[asset].sub(_sizeDelta);

        // uint256 decreaseUSDC = usdOut.mul(FAKEUSDC_PRECISION).div(USD_PRECISION);
        // we use this same thing to calculate the unrealized funding fees + another fee for changing position size
        // inside of reduce collateral, we already netted fee out, so nowe we net the rest out
        uint256 usdcOutAfterFee = usdOutAfterFee.mul(FAKEUSDC_PRECISION).div(USD_PRECISION);
        _decreasePoolAmount(FAKE_USDC, usdcOutAfterFee);
        // should balance with this
        tokenBalances[FAKE_USDC] = tokenBalances[FAKE_USDC].sub(usdcOutAfterFee);
        // require(tokenBalances[FAKE_USDC] == poolAmounts[FAKE_USDC].add(feeReserves[FAKE_USDC]), "Token balance does not match pool and fees");
        // For now, we don't actually transfer usdOut, only return it so tests can check against it

        emit SendUSDC(msg.sender, usdcOutAfterFee);
        return usdcOutAfterFee;
    }

    function liquidatePosition(
        string memory asset, // the asset being purchased
        uint256 price // in USD (10^30)
    ) external {
        bytes32 key = getPositionKey(msg.sender, asset);
        Position memory position = positions[key];
        _validate(position.size > 0, 1);

        (uint256 liquidationState, uint256 marginFees) = _validateLiquidation(asset, price);
        _validate(liquidationState != 0, 5);
        emit Liquidation(position.collateral, position.size);

        if (liquidationState == 2) {
            // Liquidate but return remaining collateral back to user
            decreasePosition(asset, 0, position.size, price);
            return;
        }

        uint256 marginFeesUSDC = marginFees.mul(FAKEUSDC_PRECISION).div(USD_PRECISION);
        feeReserves[FAKE_USDC] = feeReserves[FAKE_USDC].add(marginFeesUSDC);
        // The liquidated collateral STAYS in the pool, with fees deducted
        _decreasePoolAmount(FAKE_USDC, marginFeesUSDC);

        delete positions[key];
    }

    /* 
     * Validate Liquidation will return two values:
     * (1) Liquidation state
     *   - 0: No liquidation
     *   - 1: Liquidate because position is underwater
     *   - 2: Liquidate because position exceeds max leverage
     * 
     *   There is a distinction between 1 and 2 because for 2, we can still return
     *   collateral back to the user.
     * (2) Margin fees
     */
    function _validateLiquidation(
        string memory asset,
        uint256 price // in USD (10^30)
    ) private view returns (uint256, uint256)  {
        bytes32 key = getPositionKey(msg.sender, asset);
        Position memory position = positions[key];

        (bool hasProfit, uint256 delta) = getDelta(price, position.size, position.averagePrice);
        uint256 fees = _computeMarginFee(position.size);

        if (!hasProfit && position.collateral < delta) {
            return (1, fees);
        }
        uint256 remainingCollateral = position.collateral;
        if (!hasProfit) {
            remainingCollateral = position.collateral.sub(delta);
        }
        if (remainingCollateral < fees) {
            return (1, remainingCollateral);
        }
        if (remainingCollateral.mul(MAX_LEVERAGE) < position.size) {
            return (2, fees);
        }

        return (0, fees);
    }

    function _increasePoolAmount(address _token, uint256 _amount) private {
        poolAmounts[_token] = poolAmounts[_token].add(_amount);
        // uint256 balance = IERC20(_token).balanceOf(address(this));
        // _validate(poolAmounts[_token] <= balance, 49);
    }

    function _decreasePoolAmount(address _token, uint256 _amount) private {
        poolAmounts[_token] = poolAmounts[_token].sub(_amount, "Vault: poolAmount exceeded");
        // _validate(reservedAmounts[_token] <= poolAmounts[_token], 50);
        // emit DecreasePoolAmount(_token, _amount);
    }

    function _reduceCollateral(
        string memory asset,
        address _account,
        uint256 _collateralDeltaUSDC,
        uint256 _sizeDelta,
        uint256 currentPrice
    ) private returns (uint256, uint256) {
        bytes32 key = getPositionKey(_account, asset);
        Position storage position = positions[key];
        // increases fee, so need to account for this with decrease pool amount
        uint256 feeUSD = _collectMarginFees(_sizeDelta);

        bool hasProfit;
        uint256 adjustedDelta;
        // scope variables to avoid stack too deep errors
        {
        (bool _hasProfit, uint256 delta) = getDelta(currentPrice, position.size, position.averagePrice);
        hasProfit = _hasProfit;
        // get the proportional change in pnl
        adjustedDelta = _sizeDelta.mul(delta).div(position.size);
        }

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);
        }

        if (!hasProfit && adjustedDelta > 0) {
            position.collateral = position.collateral.sub(adjustedDelta);
            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
        }

        // reduce the position's collateral by _collateralDelta
        // transfer _collateralDelta out
        if (_collateralDeltaUSDC > 0) {
            uint256 _collateralDeltaUSD = _collateralDeltaUSDC.mul(USD_PRECISION).div(FAKEUSDC_PRECISION);
            usdOut = usdOut.add(_collateralDeltaUSD);
            position.collateral = position.collateral.sub(_collateralDeltaUSD);
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut = usdOut.add(position.collateral);
            position.collateral = 0;
        }

        // if the usdOut is more than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        uint256 usdOutAfterFee = usdOut;
        if (usdOut > feeUSD) {
            usdOutAfterFee = usdOut.sub(feeUSD);
        } else {
            position.collateral = position.collateral.sub(feeUSD);
        }
        // regardless, you are now netting out the fee from the pool because added before
        // so get the fee in terms of USDC and then decrease the pool
        uint256 feeUSDC = feeUSD.mul(FAKEUSDC_PRECISION).div(USD_PRECISION);
        _decreasePoolAmount(FAKE_USDC, feeUSDC);


        return (usdOut, usdOutAfterFee);
    }

    function getPositionKey(address _account, string memory asset) public pure returns (bytes32) {
        return keccak256(abi.encode(_account, asset));
    }

    function getNextAveragePrice(uint256 newPrice, uint256 _size, uint256 oldAveragePrice, uint256 _sizeDelta) public view returns (uint256) {
        // There is also an assumption that a spread exists for the token, that assumption
        // is removed for this initial MVP
        (bool hasProfit, uint256 delta) = getDelta(newPrice, _size, oldAveragePrice);
        uint256 nextSize = _size.add(_sizeDelta);
        uint256 divisor = hasProfit ? nextSize.add(delta) : nextSize.sub(delta);
        return newPrice.mul(nextSize).div(divisor);
    }

    // Delta here refers to profit or loss
    function getDelta(uint256 newPrice, uint256 _size, uint256 oldAveragePrice) public view returns (bool, uint256) {
        _validate(oldAveragePrice > 0, 38);
        uint256 priceDelta = oldAveragePrice > newPrice ? oldAveragePrice.sub(newPrice) : newPrice.sub(oldAveragePrice); // mu(i) - p(i+1)
        uint256 delta = _size.mul(priceDelta).div(oldAveragePrice);
        bool hasProfit = newPrice > oldAveragePrice;

        return (hasProfit, delta);
    }

    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, errors[_errorCode]);
    }


    /*               THIS IS THE FEE SECTION               */

    function _collectSwapFees(address _token, uint256 _amount, uint256 _feeBasisPoints) private returns (uint256) {
        // this is just converted to %
        uint256 afterFeeAmount = _amount.mul(BASIS_POINTS_DIVISOR.sub(_feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = _amount.sub(afterFeeAmount);
        feeReserves[_token] = feeReserves[_token].add(feeAmount);
        //emit CollectSwapFees(_token, feeAmount, tokenToUsdMin(_token, feeAmount));
        return afterFeeAmount;
    }

    function _computeMarginFee(
        uint256 _sizeDelta // in USD (10^30)
    ) private view returns (uint256)  {
        return _sizeDelta.mul(marginFeeBasisPoints).div(BASIS_POINTS_DIVISOR);
    }

    // Margin Fees have two components, size of position and then fee you pay to fund the position
    // whenever you increase position all the funding fees that have racked up until that time are realized
    // i have simplified this to assume fake usdc for now for margin fees
    function _collectMarginFees(
        uint256 _sizeDelta // in USD (10^30)
        // uint256 _size, // in USD (10^30)
        // uint256 _entryFundingRate // in USD (10^30)
    ) private returns (uint256) {
        uint256 feeUsd =_computeMarginFee(_sizeDelta);
        // TODO: Add in entryFundingRate logic so this fee can be incorporated
        // // entryfunding rate is cumulative at the time that position was opened
        // uint256 fundingRate = cumulativeFundingRates[FAKE_USDC].sub(_entryFundingRate);
        // uint256 fundingFee = _size.mul(fundingRate).div(FUNDING_RATE_PRECISION);
        
        // feeUsd = feeUsd.add(fundingFee);
        uint256 feeUSDC = feeUsd.mul(FAKEUSDC_PRECISION).div(DEFAULT_PRECISION);

        // we can assume for now that you are depositing in FAKE_USDC -- converted USD 30 decimal value to 6 decimal USDC
        feeReserves[FAKE_USDC] = feeReserves[FAKE_USDC].add(feeUSDC);
        //emit CollectMarginFees(_token, feeUsd, feeTokens);
        // returns in 30 decimals
        return feeUsd;
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