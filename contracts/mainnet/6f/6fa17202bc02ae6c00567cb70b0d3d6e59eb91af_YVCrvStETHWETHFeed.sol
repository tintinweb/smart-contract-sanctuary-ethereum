/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
}

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IYearnVault {
    function pricePerShare() external view returns (uint256 price);
}

contract YVCrvStETHWETHFeed is IFeed {
    ICurvePool public constant CRVSTETH = ICurvePool(0x828b154032950C8ff7CF8085D841723Db2696056);
    IYearnVault public constant vault = IYearnVault(0x5faF6a2D186448Dfa667c51CB3D695c7A6E52d8E);
    IAggregator public constant ETH = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() public view returns (uint256) {
        return (CRVSTETH.get_virtual_price() * uint256(ETH.latestAnswer()) * vault.pricePerShare()) / 1e26;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}