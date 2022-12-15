/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract MOTD {

    string public message;

    constructor(){
        message = "First message!";
    }

    function updateMessage(string memory _updateMsg) public{
        message = _updateMsg;
    }

}