pragma solidity ^0.8.0;

import {IPriceOracleGetter} from "./IPriceOracleGetter.sol";
import {IPool} from "./IPool.sol";
import {IERC20Metadata} from "./IERC20Metadata.sol";
import {DataTypes} from "./DataTypes.sol";
import "./PRBMathSD59x18Typed.sol";

contract UberDex{
    using PRBMathSD59x18Typed for PRBMath.SD59x18;
    IPriceOracleGetter _priceOracleGetter;
    IPool _pool;
    address[] availableTokenAddresses;
    uint256 internal constant LTV_MASK = 0xFFFF;
    PRBMath.SD59x18 fee = PRBMath.SD59x18(3000000000000000);
    PRBMath.SD59x18 slippageCurvature = PRBMath.SD59x18(30000000000000000);
    PRBMath.SD59x18 minAllowedLtv = PRBMath.SD59x18(100000000000000000);

    constructor(
        address priceOracleGetterAddress,
        address poolAddress,
        address[] memory tokenAddresses
        )
    {
        _priceOracleGetter = IPriceOracleGetter(priceOracleGetterAddress);
        _pool = IPool(poolAddress);
        availableTokenAddresses = tokenAddresses;
    }

    function swap(address inputToken, uint inputQty, address outputToken) public
    {
        require(IERC20Metadata(inputToken).allowance(msg.sender, address(this)) >= inputQty);
        

        uint outputQty = howManyFor(inputToken, inputQty, outputToken);

    }

    function supply(address token, uint qty, address from) private 
    {
        
    }

    function applyFee(PRBMath.SD59x18 memory qty) private view returns (PRBMath.SD59x18 memory)
    {
        return qty.mul(PRBMath.SD59x18(1).sub(fee));
    }

    function howManyFor(address inputToken, uint inputQtyWeis, address outputToken) public view returns (uint)
    {
        PRBMath.SD59x18 memory inputQty = tokenQtyToFixedPoint(inputToken, inputQtyWeis);
        PRBMath.SD59x18 memory basicOutputQty = basicHowManyFor(inputToken, inputQty, outputToken);
        PRBMath.SD59x18 memory borrowingPowerAfterTrade = calculateAggregatedBorrowingPowerAfterTrade(inputToken, inputQty, outputToken, basicOutputQty);
        require(borrowingPowerAfterTrade.toInt() >= 0, "Insufficient pool size to execute swap");

        PRBMath.SD59x18 memory aggregatedBorrowingPower = getAggregatedBorrowingPower();
        PRBMath.SD59x18 memory borrowingPowerDelta = aggregatedBorrowingPower.sub(borrowingPowerAfterTrade);
        if(borrowingPowerDelta.toInt() == 0)
        {
            return uint(applyFee(inputQty).toInt());
        }

        PRBMath.SD59x18 memory currentAggregatedValuation = getAggregatedPositionsValuation();

        PRBMath.SD59x18 memory ltvAfter = borrowingPowerAfterTrade.div(currentAggregatedValuation);
        PRBMath.SD59x18 memory ltvBefore = aggregatedBorrowingPower.div(currentAggregatedValuation);

        PRBMath.SD59x18 memory relativeSlippage = calculateRelativeSlippage(ltvBefore, ltvAfter);
        PRBMath.SD59x18 memory bpDeltaDollars = borrowingPowerDelta.abs();
        PRBMath.SD59x18 memory slippageDollars = bpDeltaDollars.mul(relativeSlippage);
        PRBMath.SD59x18 memory slippageQty = slippageDollars.div(getAssetPrice(outputToken));
        PRBMath.SD59x18 memory outputQtyWithSlippageApplied = basicOutputQty.sub(slippageQty);
        PRBMath.SD59x18 memory outputQty = applyFee(outputQtyWithSlippageApplied);
        return uint(outputQty.toInt());
    }

    function basicHowManyFor(address inputToken, PRBMath.SD59x18 memory inputQty, address outputToken) private view returns (PRBMath.SD59x18 memory)
    {
        PRBMath.SD59x18 memory inputPrice = getAssetPrice(inputToken);
        PRBMath.SD59x18 memory outputPrice = getAssetPrice(outputToken);
        PRBMath.SD59x18 memory relationalPrice = PRBMathSD59x18Typed.div(inputPrice, outputPrice);
        PRBMath.SD59x18 memory result = PRBMathSD59x18Typed.mul(relationalPrice, inputQty);
        return result;
    }

    function getAssetPrice(address token) private view returns (PRBMath.SD59x18 memory)
    {
        uint tokenPriceWeis = _priceOracleGetter.getAssetPrice(token);
        return tokenQtyToFixedPoint(token, tokenPriceWeis);
    }

    function tokenQtyToFixedPoint(address tokenAddress, uint qty) private view returns (PRBMath.SD59x18 memory)
    {
        uint8 decimals = IERC20Metadata(tokenAddress).decimals();
        if(decimals == 18)
        {
            return PRBMath.SD59x18(int(qty));
        }

        if(decimals < 18)
        {
            for(uint8 i = 0; i < 18 - decimals; i++)
            {
                qty *= 10;
            }

            return PRBMath.SD59x18(int(qty)); 
        }
        else
        {
            for(uint8 i = 0; i < decimals - 18; i++)
            {
                qty /= 10;
            }

            return PRBMath.SD59x18(int(qty));
        }
    }

    function calculateAggregatedBorrowingPowerAfterTrade(address inputToken, PRBMath.SD59x18 memory inputQty, address outputToken, PRBMath.SD59x18 memory outputQty) private view returns (PRBMath.SD59x18 memory) {
        PRBMath.SD59x18 memory aggregatedBorrowingPower = PRBMath.SD59x18(0);
        for (uint8 i = 0; i < availableTokenAddresses.length; i++) {
            address token = availableTokenAddresses[i];
            DataTypes.ReserveData memory tokenData = _pool.getReserveData(token);
            PRBMath.SD59x18 memory ltv = extractLtv(tokenData.configuration.data);
            PRBMath.SD59x18 memory price = getAssetPrice(token);
            PRBMath.SD59x18 memory balance = getPositionQty(tokenData.aTokenAddress, tokenData.variableDebtTokenAddress);

            if (token == inputToken) 
            {
                aggregatedBorrowingPower.add(calculateBorrowingPower(balance.add(inputQty), price, ltv));
            }
            else if (token == outputToken)
            {
                aggregatedBorrowingPower.add(calculateBorrowingPower(balance.add(outputQty), price, ltv));
            }
            else
            {
                aggregatedBorrowingPower.add(calculateBorrowingPower(balance, price, ltv));
            }
        }

        return aggregatedBorrowingPower;
    }

    function getAggregatedBorrowingPower() private view returns (PRBMath.SD59x18 memory) {
        PRBMath.SD59x18 memory aggregatedBorrowingPower = PRBMath.SD59x18(0);
        for (uint8 i = 0; i < availableTokenAddresses.length; i++) {
            address token = availableTokenAddresses[i];
            DataTypes.ReserveData memory tokenData = _pool.getReserveData(token);
            PRBMath.SD59x18 memory ltv = extractLtv(tokenData.configuration.data);
            PRBMath.SD59x18 memory price = getAssetPrice(token);
            PRBMath.SD59x18 memory balance = getPositionQty(tokenData.aTokenAddress, tokenData.variableDebtTokenAddress);

            aggregatedBorrowingPower.add(calculateBorrowingPower(balance, price, ltv));
        }

        return aggregatedBorrowingPower;
    }

    function getAggregatedPositionsValuation() private view returns(PRBMath.SD59x18 memory)
    {
        PRBMath.SD59x18 memory aggregatedValuation = PRBMath.SD59x18(0);
        for(uint8 i = 0; i < availableTokenAddresses.length; i++)
        {
            address token = availableTokenAddresses[i];
            DataTypes.ReserveData memory tokenData = _pool.getReserveData(token);
            aggregatedValuation = aggregatedValuation.add(getPositionQty(tokenData.aTokenAddress, tokenData.variableDebtTokenAddress));
        }

        return aggregatedValuation;
    }

    function getPositionQty(address aTokenAddr, address vDebtToken) private view returns(PRBMath.SD59x18 memory) {
        uint tokenQty = IERC20Metadata(aTokenAddr).balanceOf(address(this));
        if (tokenQty > 0) 
        {
            return tokenQtyToFixedPoint(aTokenAddr, tokenQty);
        }
        tokenQty = IERC20Metadata(vDebtToken).balanceOf(address(this));
        return PRBMathSD59x18Typed.mul(tokenQtyToFixedPoint(vDebtToken, tokenQty), PRBMath.SD59x18(-1)); // if balance equals to 0 => returns 0 anyway
    }

    function extractLtv(uint cfgData) public pure returns(PRBMath.SD59x18 memory) {
        uint shiftedLtv = cfgData & LTV_MASK;
        return PRBMath.SD59x18(int(shiftedLtv)*(10**14));
    }

    function calculateBorrowingPower(PRBMath.SD59x18 memory qty, PRBMath.SD59x18 memory price, PRBMath.SD59x18 memory ltv) private pure returns (PRBMath.SD59x18 memory) {
        PRBMath.SD59x18 memory valuation = PRBMathSD59x18Typed.mul(price, qty);
        if(PRBMathSD59x18Typed.toInt(valuation) > 0)
        {
            return PRBMathSD59x18Typed.mul(valuation, ltv);
        }
        
        return valuation;
    }

    function calculateRelativeSlippage(PRBMath.SD59x18 memory ltvBefore, PRBMath.SD59x18 memory ltvAfter) private view returns(PRBMath.SD59x18 memory)
    {
        PRBMath.SD59x18 memory startingBoundValue = integralAtPoint(ltvBefore);
        PRBMath.SD59x18 memory endingBoundValue = integralAtPoint(ltvAfter);
        PRBMath.SD59x18 memory integralDelta = startingBoundValue.sub(endingBoundValue);
        PRBMath.SD59x18 memory segmentLength = ltvBefore.sub(ltvAfter).abs();
        return integralDelta.div(segmentLength);
    }

    function integralAtPoint(PRBMath.SD59x18 memory x) private view returns(PRBMath.SD59x18 memory)
    {
        PRBMath.SD59x18 memory xSubN = x.sub(minAllowedLtv);
        
        PRBMath.SD59x18 memory one = PRBMath.SD59x18(1000000000000000000);
        return xSubN.abs().div(minAllowedLtv.sub(one).abs()).ln().sub(one)
        .mul(xSubN)
        .mul(slippageCurvature)
        .div(one.add(one).ln())
        .mul(one.sub(one).sub(one));
    }
}