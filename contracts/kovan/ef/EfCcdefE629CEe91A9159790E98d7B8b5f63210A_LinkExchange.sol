// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IExchange.sol";

contract LinkExchange is IExchange {
  mapping(address => mapping(address => uint256)) public liquidity;

  function setLiquidity(
    address token0,
    address token1,
    uint256 liquidity0,
    uint256 liquidity1
  ) external {
    liquidity[token0][token1] = liquidity0;
    liquidity[token1][token0] = liquidity1;
  }

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    override
    returns (uint256[] memory amounts)
  {
    amounts = new uint256[](2);
    amounts[0] = amountIn;
    amounts[1] =
      (amountIn * liquidity[path[1]][path[0]]) /
      liquidity[path[0]][path[1]];
  }

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    override
    returns (uint256[] memory amounts)
  {
    amounts = new uint256[](2);
    amounts[0] =
      (amountOut * liquidity[path[0]][path[1]]) /
      liquidity[path[1]][path[0]];
    amounts[1] = amountOut;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IExchange {
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}