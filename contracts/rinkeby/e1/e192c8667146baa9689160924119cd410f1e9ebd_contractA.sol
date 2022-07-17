/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract contractA{
    uint public mydemocontract=5;

    function store(uint _num) public{
        mydemocontract=_num;
    }

    function retrieve() public view returns (uint256){
        return mydemocontract;
    }
}