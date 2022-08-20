/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

//import "";


contract One{
    uint256 num;
    string message;
    
    event EmitValue(string, uint);

    constructor(){
        num = 100;
    }

    function setValue(uint256 _num) external returns (bool){
        num = _num;
        emit EmitValue("Emitted",num);
        return true;
    }

    function getValue() external returns (uint256){
        emit EmitValue("Emitted num value",num);
        return num;
    }

    function testFunction() internal view returns(uint){

    }
    
}