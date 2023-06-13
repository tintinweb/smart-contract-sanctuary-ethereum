/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.19;

contract Target {
    uint256 public value;
    address public owner;

    constructor (address _owner) {
        owner = _owner;
    }
    
    function setValue(uint256 _value) public {
        require(msg.sender == owner, "You are not owner!");
        value = _value;
    }
}