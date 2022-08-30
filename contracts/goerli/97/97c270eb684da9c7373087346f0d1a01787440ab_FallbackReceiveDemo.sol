/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16                ;

contract FallbackReceiveDemo {

    uint256 public POKE  ; 

    receive() external payable{
        POKE = 1                           ;
    }

    fallback() external payable{
        POKE = 2                            ;
    }

    function retrieve() public view returns(uint256){
        return POKE                          ;
    }

    function store(uint256 value) public{
        POKE = value                         ;
    }

}