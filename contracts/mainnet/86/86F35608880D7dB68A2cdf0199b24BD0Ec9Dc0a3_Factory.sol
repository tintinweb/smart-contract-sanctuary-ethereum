// SPDX-License-Identifier: MIT

// Project: NERD Token
//
// Website: http://nerd.vip
// Twitter: @nerdoneth
//
// Note: The coin is completely useless and intended solely for entertainment and educational purposes. Please do not expect any financial returns.

pragma solidity ^0.8.20;

import "./Nerd.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract Factory {
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address public immutable nerd;

    constructor() payable {
        Nerd nerdToken = new Nerd(msg.sender);
        nerd = address(nerdToken);
        address srToken = nerdToken.SR();

        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

        address mainPool = factory.createPair(address(nerdToken), WETH);
        address srPool = factory.createPair(srToken, address(nerdToken));

        // add liquidity
        IWETH(WETH).deposit{value: 1 ether}();
        IERC20(WETH).transfer(mainPool, 1 ether);

        nerdToken.transfer(srPool, 6_400_000 ether);
        IERC20(srToken).transfer(srPool, 25_600_000 ether);

        // mint LP & lock it forever
        IUniswapV2Pair(mainPool).mint(nerd);
        IUniswapV2Pair(srPool).mint(nerd);
    }
}