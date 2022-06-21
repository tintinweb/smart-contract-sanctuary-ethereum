/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;
 
contract Test
{
    function sortTokens(address tokenA, address tokenB)
		internal
		pure
		returns (address token0, address token1)
	{
		require(tokenA != tokenB, "UniswapV2Library: same token");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "UniswapV2Library: address(0)");
	}

    function pairFor(address factory, address tokenA, address tokenB) public pure returns (address pair)
	{
		(address token0, address token1) = sortTokens(tokenA, tokenB);
		pair = address(
			uint256(
				keccak256(
					abi.encodePacked(
						hex"ff",
						factory,
						keccak256(abi.encodePacked(token0, token1)),
						hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
					)
				)
			)
		);
	}


    function pairFor2(address factory, address tokenA, address tokenB) public pure returns (address pair)
	{
		(address token0, address token1) = sortTokens(tokenA, tokenB);
		return address(
            uint160(bytes20(bytes32(
			uint256(
				keccak256(
					abi.encodePacked(
						hex"ff",
						factory,
						keccak256(abi.encodePacked(token0, token1)),
						hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
					)
				)
			))))
		);
	}

    function pairFor3(address factory, address tokenA, address tokenB) public pure returns (address pair)
	{
		(address token0, address token1) = sortTokens(tokenA, tokenB);
		return address(
            uint160(
			uint256(
				keccak256(
					abi.encodePacked(
						hex"ff",
						factory,
						keccak256(abi.encodePacked(token0, token1)),
						hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
					)
				)
			))
		);
	}
}