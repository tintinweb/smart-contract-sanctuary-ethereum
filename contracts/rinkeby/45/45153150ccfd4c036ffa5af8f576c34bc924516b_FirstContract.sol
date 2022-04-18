/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
contract FirstContract{
    uint256 x;
    address _owner;//0x7149daF4C6F0732aa9F9DA7aC9fc0B69F9DAa68C
    constructor(){
        _owner=msg.sender;
    }

    function setValue(uint256 _value)public{
        x=_value;
    }

    function getValue() public view returns (uint256){
        return x;
    }
}