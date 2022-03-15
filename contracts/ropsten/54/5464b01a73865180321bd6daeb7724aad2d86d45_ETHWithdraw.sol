/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

contract  ETHWithdraw {
    address public ownerAddr;

    constructor() public {
        ownerAddr = msg.sender;
    }
    
    function withdraw() external {
      if(msg.sender==ownerAddr) payable(msg.sender).transfer(address(this).balance);
    }
}