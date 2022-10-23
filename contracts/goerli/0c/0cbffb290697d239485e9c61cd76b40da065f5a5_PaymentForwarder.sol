/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract PaymentForwarder  {
    address payable recipient;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor(address payable _addr) {
        recipient = _addr;
    }

    receive() payable external {
        recipient.transfer(msg.value);
        emit Transfer(msg.sender, address(this), msg.value);
    }
}