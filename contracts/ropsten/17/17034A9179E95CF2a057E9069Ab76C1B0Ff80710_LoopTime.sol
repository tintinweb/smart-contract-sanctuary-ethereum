/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract LoopTime{
    uint public start;
    uint public end;
    uint[] arr;
    constructor(){
        start = block.timestamp;
        end = start + 2 minutes;
    }
    function counter() public returns(uint[] memory){
        uint i;
        //uint j;
        for(i=start; i<=end; i++)
            arr.push(i);
        return arr;
    }
}