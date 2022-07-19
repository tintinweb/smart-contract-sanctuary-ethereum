/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract Box {  
    uint public val;
    function initialize(uint _val) external {
        val=_val;
    }

    function add() public returns(uint aa){
        return 777;
    }
}