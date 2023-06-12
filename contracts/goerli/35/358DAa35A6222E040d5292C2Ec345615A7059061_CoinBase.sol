// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract CoinBase{
    function coinBase() external view returns(address){
        return block.coinbase;
    }

    function number() external view returns(uint256){
        return block.number;
    }
}