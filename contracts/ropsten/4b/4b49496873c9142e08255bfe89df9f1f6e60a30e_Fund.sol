/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Fund {

    function sendEther(address payable receiver) public payable{
        receiver.transfer(msg.value);
    }
}