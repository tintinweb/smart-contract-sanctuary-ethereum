pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./UniswapFlashSwapper.sol";
import "./Exponential.sol";

//0x0000000000000000000000000000000000000000
//0xc778417E063141139Fce010982780140Aa0cD5Ab
//0x5592ec0cfb4dbc12d3ab100b257153436a1f0fea
//0xB7bFbc2Cf0167Eb2945247C18dd7Caa28D9C39f0
contract FlashLiquidator is UniswapFlashSwapper, Exponential {

    event FlashSwap(address target, address tokenSeized, uint256 seizeAmount, uint repayAmount, uint256 profit);
    
    constructor(address _AlkemiWETH, address _WETH, IAlkemiEarnPublic _alkemiPublic) public UniswapFlashSwapper(_AlkemiWETH, _WETH, _alkemiPublic) {}

    // @notice Flash-borrows _amount of _tokenBorrow from a Uniswap V2 pair and repays using _tokenBorrow
    // @param _tokenBorrow The address of the token you want to flash-borrow, use 0x0 for ETH
    // @param _amount The amount of _tokenBorrow you will borrow
    // @param _tokenCollateral The address of the token you want to use to payback the flash-borrow, use 0x0 for ETH
    // @dev Need to add access control
    function flashSwap(address _tokenBorrow, uint256 _amount, address _tokenCollateral, address _targetAccount) external {
        // Start the flash swap
        // This will acuire _amount of the _tokenBorrow token for this contract and then
        // run the `execute` function below
        bytes memory data = abi.encode(
            _targetAccount
        );
        startSwap(_tokenBorrow, _amount, _tokenCollateral, data);
    }



    // @dev When this code executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds
    //     at least _amountToRepay of the _tokenPay token
    // @dev Paying back the flash-loan happens automatically 
    // @param _tokenBorrow The address of the token you flash-borrowed, address(0) indicates ETH
    // @param _amount The amount of the _tokenBorrow token you borrowed
    // @param _tokenPay The address of the token in which you'll repay the flash-borrow, address(0) indicates ETH
    // @param _amountToRepay The amount of the _tokenPay token that will be auto-removed from this contract to pay back
    //        the flash-borrow when this function finishes executing
    // @param _userData Holds the address of target User
    function execute(address _tokenBorrow, uint _amount, address _tokenPay, uint _amountToRepay, bytes memory _userData) internal {
    
        uint256 profit;
        if(_tokenBorrow == address(0)){
            _tokenBorrow = AlkemiWETH;
        } else if(_tokenPay == address(0)){
            _tokenPay = AlkemiWETH;
        }
        (
            address _target
        ) = abi.decode(_userData, (address));
        Exp memory underwaterAssetPrice = Exp({mantissa: (alkemiPublic.assetPrices(_tokenBorrow))});
        Exp memory collateralPrice = Exp({mantissa: (alkemiPublic.assetPrices(_tokenPay))});

        //calculate the seize amount the liquidator will receive after liquidation
        uint256 seizeAmount = calculateAmountSeize(underwaterAssetPrice, collateralPrice, _amount);

        //Make sure there is enough amount to repay
        //require(seizeAmount >= _amountToRepay, "Not enough amount to repay");
        alkemiPublic.liquidateBorrow(_target, _tokenBorrow, _tokenPay,_amount);
        alkemiPublic.withdraw(_tokenPay, seizeAmount);
        
        if(seizeAmount > _amountToRepay){
            profit = sub(seizeAmount, _amountToRepay);
            if(profit > 0)
            IERC20(_tokenPay).transfer(msg.sender,profit);
        }
        
        emit FlashSwap(_target, _tokenPay, seizeAmount, _amountToRepay, profit);
    }

    // @notice Simple getter for convenience while testing
    function getBalanceOf(address _input) external view returns (uint) {
        if (_input == address(0)) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }

      function calculateAmountSeize(
        Exp memory underwaterAssetPrice,
        Exp memory collateralPrice,
        uint256 closeBorrowAmount_TargetUnderwaterAsset
    ) public pure returns (uint256) {
    
        Exp memory liquidationDiscount = Exp({mantissa: (10**17)});
        // (1+liquidationDiscount)
        Exp memory liquidationMultiplier;

        // assetPrice-of-underwaterAsset * (1+liquidationDiscount)
        Exp memory priceUnderwaterAssetTimesLiquidationMultiplier;

        // priceUnderwaterAssetTimesLiquidationMultiplier * closeBorrowAmount_TargetUnderwaterAsset
        // or, expanded:
        // underwaterAssetPrice * (1+liquidationDiscount) * closeBorrowAmount_TargetUnderwaterAsset
        Exp memory finalNumerator;

        // finalNumerator / priceCollateral
        Exp memory rawResult;

        (liquidationMultiplier) = addExp(
            Exp({mantissa: mantissaOne}),
            liquidationDiscount
        );
        
        (priceUnderwaterAssetTimesLiquidationMultiplier) = mulExp(
            underwaterAssetPrice,
            liquidationMultiplier
        );
        
        (finalNumerator) = mulScalar(
            priceUnderwaterAssetTimesLiquidationMultiplier,
            closeBorrowAmount_TargetUnderwaterAsset
        );

        (rawResult) = divExp(finalNumerator, collateralPrice);

        return (truncate(rawResult));
    }
}