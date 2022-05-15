/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IYearnVault {
    function pricePerShare() external view returns (uint256 price);
}

contract YVUSDTFeed is IFeed {
    IYearnVault public constant vault = IYearnVault(0x7Da96a3891Add058AdA2E826306D812C638D87a7);
    IAggregator constant public USDT = IAggregator(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);

    function latestAnswer() public view returns (uint256) {
        return vault.pricePerShare() * uint256(USDT.latestAnswer()) * 1e4;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}