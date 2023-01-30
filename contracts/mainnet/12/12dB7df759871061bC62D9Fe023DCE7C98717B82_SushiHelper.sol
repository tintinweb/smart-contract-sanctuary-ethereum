// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract SushiHelper {

  /**
   * @notice Calculates the CREATE2 address for a sushi pair without making any
   * external calls.
   * 
   * @return pair Address of our token pair
   */

  function pairFor(address sushiRouterFactory, address tokenA, address tokenB) external view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint160(uint256(keccak256(abi.encodePacked(
      hex'ff',
      sushiRouterFactory,
      keccak256(abi.encodePacked(token0, token1)),
      hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
    )))));
  }


  /**
   * @notice Returns sorted token addresses, used to handle return values from pairs sorted in
   * this order.
   */

  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
      require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
      (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
      require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
  }

}