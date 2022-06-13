/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test{

    uint public asd;

    event ThrowEvent(uint _asd);
    
    function aaa() public {

       emit ThrowEvent(20);
       
    }
}