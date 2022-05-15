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

contract YVDAIFeed is IFeed {
    IYearnVault public constant vault = IYearnVault(0xdA816459F1AB5631232FE5e97a05BBBb94970c95);
    IAggregator constant public DAI = IAggregator(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);

    function latestAnswer() public view returns (uint256) {
        return vault.pricePerShare() * uint256(DAI.latestAnswer()) / 1e8;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}