/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
}

interface IYearnVault {
    function pricePerShare() external view returns (uint256 price);
}

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

//
contract YVCrvDolaFeed is IFeed {
    ICurvePool public constant DOLA3CRV = ICurvePool(0xAA5A67c256e27A5d80712c51971408db3370927D);
    IYearnVault public constant vault = IYearnVault(0xd88dBBA3f9c4391Ee46f5FF548f289054db6E51C);
    IAggregator constant public DAI = IAggregator(0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9);
    IAggregator constant public USDC = IAggregator(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
    IAggregator constant public USDT = IAggregator(0x3E7d1eAB13ad0104d2750B8863b489D65364e32D);
    
    /**
     * @dev Returns the smallest of two numbers.
     */
    // FROM: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6d97f0919547df11be9443b54af2d90631eaa733/contracts/utils/math/Math.sol
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Calculates the latest price of yvCrvDOLA tokens
    function _get() internal view returns (uint) {
        uint256 minStable = min(
            uint256(DAI.latestAnswer()),
            min(uint256(USDC.latestAnswer()), min(uint256(USDT.latestAnswer()), uint256(1e8)))
        );

        uint yVCurvePrice = DOLA3CRV.get_virtual_price() * minStable * vault.pricePerShare();

        return yVCurvePrice / 1e26;
    }

    function latestAnswer() public view returns (uint) {
        return _get();
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}