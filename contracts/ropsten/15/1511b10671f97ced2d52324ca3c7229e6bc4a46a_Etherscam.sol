/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Etherscam{
    
    function SendToAddress(address receiver) public payable{
        (bool success, ) = receiver.call{value: msg.value}("");
        require(success);
    }
}