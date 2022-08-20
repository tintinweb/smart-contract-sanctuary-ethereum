/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IUniswapV2Factory {
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
}


interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}



contract PairInfoCollector {
    address owner;

    constructor(){
        // Set the owner to the account that deployes the contract
        owner = msg.sender;
    }

    function getPairLength(address factory) public view returns (uint) {
        return IUniswapV2Factory(factory).allPairsLength();
    }

    function get_tokens_per_pair(address[] memory _addresses) public view returns (address[] memory,address[] memory) {
        address[] memory token0;
        address[] memory token1;
        token0 = new address[](_addresses.length);
        token1 = new address[](_addresses.length);
        for (uint i=0; i<_addresses.length; i++) {
             address pair = _addresses[i];
             address _token0 = IUniswapV2Pair(pair).token0();
             address _token1 = IUniswapV2Pair(pair).token1();
             token0[i] = _token0;
             token1[i] = _token1;
        }
        return (token0,token1);
    }

    function getAllPairs(address factory,uint start,uint end) public view returns (address[] memory) {
         address[] memory all_pairs;
         all_pairs = new address[](end - start); 
         for (uint i=start; i<end; i++) {
             uint index = i - start ;
             address pair_address = IUniswapV2Factory(factory).allPairs(i);
             all_pairs[index] = pair_address;
        }
        return all_pairs;
    }
}