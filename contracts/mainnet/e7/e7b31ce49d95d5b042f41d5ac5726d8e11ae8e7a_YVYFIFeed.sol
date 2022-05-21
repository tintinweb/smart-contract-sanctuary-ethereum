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
}

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface IYearnVault {
    function pricePerShare() external view returns (uint256 price);
}

contract YVYFIFeed is IFeed {
    IYearnVault public constant vault = IYearnVault(0xdb25cA703181E7484a155DD612b06f57E12Be5F0);
    IAggregator public constant YFI = IAggregator(0xA027702dbb89fbd58938e4324ac03B58d812b0E1);

    function latestAnswer() public view returns (uint256) {
        uint256 yvYfiPrice = uint256(YFI.latestAnswer()) * vault.pricePerShare();

        return yvYfiPrice / 1e8;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}