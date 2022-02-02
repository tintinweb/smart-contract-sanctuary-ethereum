// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract MockSimplePresale {
    mapping(address => uint256) public purchased;

    constructor() {}

    function setPurchased(uint256 _purchased) external {
        purchased[msg.sender] = _purchased;
    }
}