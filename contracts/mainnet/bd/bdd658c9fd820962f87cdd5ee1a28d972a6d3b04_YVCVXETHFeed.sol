/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
    function lp_price() external view returns (uint256 price);
}

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IYearnVault {
    function pricePerShare() external view returns (uint256 price);
}

contract YVCVXETHFeed is IFeed {
    ICurvePool public constant CVXETH = ICurvePool(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    IYearnVault public constant vault = IYearnVault(0x1635b506a88fBF428465Ad65d00e8d6B6E5846C3);
    IAggregator public constant ETH = IAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() public view override returns (uint256) {
        uint256 yvCvxEthPrice = CVXETH.lp_price() * uint256(ETH.latestAnswer()) * vault.pricePerShare();

        return yvCvxEthPrice / 1e26;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}