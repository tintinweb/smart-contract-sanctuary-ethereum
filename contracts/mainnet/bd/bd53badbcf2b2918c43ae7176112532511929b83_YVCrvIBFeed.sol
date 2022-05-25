/**
 *Submitted for verification at Etherscan.io on 2022-05-24
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

contract YVCrvIBFeed is IFeed {
    ICurvePool public constant IronBank = ICurvePool(0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF);
    IYearnVault public constant vault = IYearnVault(0x27b7b1ad7288079A66d12350c828D3C00A6F07d7);
    IAggregator public constant DAI = IAggregator(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    IAggregator public constant USDC = IAggregator(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    IAggregator public constant USDT = IAggregator(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);

    /**
     * @dev Returns the smallest of two numbers.
     */
    // FROM: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6d97f0919547df11be9443b54af2d90631eaa733/contracts/utils/math/Math.sol
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function latestAnswer() public view returns (uint256) {
        uint256 minStable = min(uint256(DAI.latestAnswer()), min(uint256(USDC.latestAnswer()), uint256(USDT.latestAnswer())));

        uint256 yvIBPrice = IronBank.get_virtual_price() * minStable * vault.pricePerShare();

        return yvIBPrice / 1e26;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}