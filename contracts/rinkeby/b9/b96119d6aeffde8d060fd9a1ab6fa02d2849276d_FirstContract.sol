/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FirstContract {
    uint256 x;
    uint256 y;
    address _owner;//0xa4b3F2e7550279F706fd9f2f0e9111948BE93583

    constructor() {
        _owner = msg.sender;
    }

    //public, external, internal, private
    function setValue(uint256 _value) public {
        x = _value;
        y = _value;
    }

    function getValue() public view returns (uint256) {
        return x;
    }
}