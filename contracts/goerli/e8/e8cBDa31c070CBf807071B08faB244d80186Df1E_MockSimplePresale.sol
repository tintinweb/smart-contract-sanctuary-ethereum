// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


contract MockSimplePresale{
    mapping(address=>uint) public purchased;

    constructor(){}

    function setPurchased(uint _purchased) external{
        purchased[msg.sender] = _purchased;
    }
}