/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Events{
    //state variable to store 
    uint public a =0;
    event Addition (address user, uint number);

    function addNumber() public {
        ++a;
        emit Addition(msg.sender, a);
    }

}