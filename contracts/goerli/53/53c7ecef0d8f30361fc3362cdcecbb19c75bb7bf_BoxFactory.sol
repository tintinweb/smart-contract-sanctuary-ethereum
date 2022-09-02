/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Box {
    uint private value;

    function getValue() public view returns(uint) {
        return value;
    }

    function setValue(uint newValue) public {
        value = newValue;
    }
}

contract BoxFactory {
    event MsgSender(address boxAddr);
    event BoxCreated(address boxAddr);

    function createBox() public returns(address)  {
        Box box = new Box();
        emit BoxCreated(address(box));
        emit MsgSender(address(msg.sender));
        return address(box);
    }
}