// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../IFeedStrategy.sol";

interface ICurvePool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

contract CurvePoolReferenceFeedStrategy is IFeedStrategy {
    IFeedStrategy public immutable referenceFeed;
    ICurvePool public immutable curvePool;
    int8 public immutable referenceCoinIndex;
    int8 public immutable outputCoinIndex;
    uint8 public immutable inputCoinDecimals;
    uint256 public immutable oneToken;

    constructor(
        address referenceFeedAddress, // price feed to use
        address curvePoolAddress, // curve pool to use
        int8 coinIndex, // token index which feed (referenceFeedAddress) we already have
        int8 outIndex, // index of coin in pool we are outputing
        uint8 inDecimals, // decimals of coin in pool we are outputing
        uint256 oneTokenAmount // 1.0 of output coin token with decimals
    ) {
        curvePool = ICurvePool(curvePoolAddress);
        referenceCoinIndex = coinIndex;
        outputCoinIndex = outIndex;
        oneToken = oneTokenAmount;
        referenceFeed = IFeedStrategy(referenceFeedAddress);
        inputCoinDecimals = inDecimals;
    }

    function getPrice() external view returns (int256 value, uint8 decimals) {
        uint256 l1price = curvePool.get_dy(
            outputCoinIndex,
            referenceCoinIndex,
            oneToken
        );

        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");

        return (int256(l1price) * usdPrice, usdDecimals + inputCoinDecimals);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IFeedStrategy {
    function getPrice() external view returns (int256 value, uint8 decimals);
}