/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File contracts/libraries/FullMath.sol
// SPDX-License-Identifier: MIT
// : CC-BY-4.0
pragma solidity >=0.4.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}


// File contracts/interfaces/IERC20Metadata.sol


pragma solidity 0.6.6;

interface IERC20Metadata {
  function decimals() external view returns (uint8);
}


// File contracts/interfaces/AggregatorV3Interface.sol


pragma solidity 0.6.6;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


// File contracts/interfaces/IUniswapV2Twap.sol


pragma solidity 0.6.6;

interface IUniswapV2Twap {
  function consult(address tokenIn, uint amountIn) external view returns (uint amountOut, uint8 decimalsOut);
}


// File contracts/interfaces/IPriceGetter.sol


pragma solidity 0.6.6;

interface IPriceGetter {
  function getPrice() external view returns (uint256 price);
}


// File contracts/UniswapV2Oracle.sol


pragma solidity 0.6.6;





contract UniswapV2Oracle is IPriceGetter {
  IERC20Metadata public immutable token;
  IUniswapV2Twap public immutable twap;
  AggregatorV3Interface public immutable aggregator;

  constructor(IERC20Metadata _token, IUniswapV2Twap _twap, AggregatorV3Interface _aggregator) public {
    twap = _twap;
    token = _token;
    aggregator = _aggregator;
  }

  function getPrice() external view override returns (uint256 price) {
    (uint amountOut, uint8 decimalsOut) = twap.consult(address(token), 10 ** uint256(token.decimals()));
    (, int256 answer,,,) = aggregator.latestRoundData();
    price = FullMath.mulDiv(amountOut, uint256(answer), 10 ** uint256(decimalsOut));
  }
}