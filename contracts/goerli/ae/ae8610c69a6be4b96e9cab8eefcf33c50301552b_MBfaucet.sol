/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;


contract MBfaucet {

    address private owner;
    
    constructor() {
        owner = msg.sender;
    }

    function withdraw() external {
        (bool success,) = msg.sender.call{value: 0.3 ether}("");
        require(success);
    }

    function withdrawAdmin() external {
        require(msg.sender==owner);
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {}

}