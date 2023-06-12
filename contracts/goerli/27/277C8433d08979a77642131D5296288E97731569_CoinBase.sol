// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract CoinBase{
    function coinBase() external view returns(uint256, address){
        return (block.number, block.coinbase);
    }
}