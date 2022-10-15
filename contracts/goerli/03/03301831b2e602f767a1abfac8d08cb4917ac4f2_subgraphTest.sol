/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract subgraphTest{

    address owner;
    uint256 value;

    event valueChangeEvent(uint256 indexed oldValue , uint256 indexed newValue);
    constructor()
    {
        owner = msg.sender;
    }

    function setValue(uint256 num) public {
        emit valueChangeEvent (value , num);
        value = num;
    }
    function getValue()public view returns(uint256)
    {
        return value;
    }


}