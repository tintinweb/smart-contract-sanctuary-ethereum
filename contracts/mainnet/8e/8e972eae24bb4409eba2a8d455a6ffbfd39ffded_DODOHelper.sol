/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

/*
    DODO query's helper.Power by TransitSwap.
    SPDX-License-Identifier: MIT
*/
pragma solidity >=0.8.0;

interface IDODOV2 {
    function querySellBase(
        address trader, 
        uint256 payBaseAmount
    ) external view  returns (uint256 receiveQuoteAmount,uint256 mtFee);

    function querySellQuote(
        address trader, 
        uint256 payQuoteAmount
    ) external view  returns (uint256 receiveBaseAmount,uint256 mtFee);
}

interface IDODOV2_1_1 {
    function querySellBase(
        address trader, 
        uint256 payBaseAmount
    ) external view  returns (uint256 receiveQuoteAmount, uint256 mtFee, uint8 newRState, uint256 newBaseTarget);

    function querySellQuote(
        address trader, 
        uint256 payQuoteAmount
    ) external view  returns (uint256 receiveBaseAmount, uint256 mtFee, uint8 newRState, uint256 newBaseTarget);
}

contract DODOHelper {

    function querySellBaseByHelper(address pool, address trader, uint256 amount) public view returns (uint256 receiveQuoteAmount) {
        (receiveQuoteAmount,) = IDODOV2(pool).querySellBase(trader, amount);
    }

    function querySellQuoteByHelper(address pool, address trader, uint256 amount) public view returns (uint256 receiveBaseAmount) {
        (receiveBaseAmount,) = IDODOV2(pool).querySellQuote(trader, amount);
    }
}