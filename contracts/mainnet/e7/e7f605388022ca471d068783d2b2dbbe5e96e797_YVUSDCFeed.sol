/**
 *Submitted for verification at Etherscan.io on 2022-05-19
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

interface ICToken {
    function underlying() external view returns (address);
}

contract YVUSDCFeed is IFeed {
    IYearnVault public constant vault = IYearnVault(0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE);
    IAggregator constant public USDC = IAggregator(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);

    function latestAnswer() public view returns (uint256) {
        return vault.pricePerShare() * uint256(USDC.latestAnswer()) * 1e4;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}