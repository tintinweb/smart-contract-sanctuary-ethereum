/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL
pragma solidity >=0.7.0 < 0.9.0;

contract TestChainlinkFeederMock /* is IChainlinkAggregator */ {
    int private currentPriceInWei;
    uint8 private decimal;

    constructor(uint8 _decimal) {
        decimal = _decimal;
    }

    function setPrice(int newPrice) public {
        currentPriceInWei = newPrice * int(10 ** decimal);
    }

    function setPriceInWei(int newPriceInWei) public {
        currentPriceInWei = newPriceInWei;
    }

    function latestRoundData() external view returns (uint80, int, uint, uint, uint80) {
        return (0, currentPriceInWei, 0, 0, 0);
    }

    function decimals() public view returns (uint8) {
        return decimal;
    }
}