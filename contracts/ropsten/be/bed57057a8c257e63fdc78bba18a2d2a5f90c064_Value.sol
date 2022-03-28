/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0<0.9.0;

contract Value{
    uint value;
    address ownerAddress;

    constructor(){
        ownerAddress=msg.sender;
    }

    function getValue() public view returns(uint){
        return value;
    }

    function setValue(uint _value) public {
        require(msg.sender==ownerAddress,"Owner Required");
        value = _value;

    }
}