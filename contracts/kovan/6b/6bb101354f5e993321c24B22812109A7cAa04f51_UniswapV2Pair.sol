/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// File: contracts/tool/pancake.sol

// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract UniswapV2Pair {


    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    function setReserves(uint112 _reserve0, uint112 _reserve1) public {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

}