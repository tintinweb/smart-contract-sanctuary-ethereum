/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity >= 0.7.0 < 0.9.0;

contract MyContract {
    
    uint value;
    
    function getValue() external view returns(uint){
        return value;
    }
    
    function getNewValue() external pure returns(uint){
        return 3 + 3;
    }
    
    function setValue(uint _value) external {
        value = _value;
    }
    
    function multiply () external pure returns(uint){
        return 3 * 7;
    }
    
    function valuePlusThree() external view returns(uint){
        return value + 3;
    }
}