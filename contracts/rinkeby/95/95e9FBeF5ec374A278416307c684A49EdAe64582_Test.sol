/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract Test {
    uint256 private value;


    function setValue(uint256 _value) public {
        value = _value;
    }

    function getValue() public view returns(uint256){
        return value;
    }
    
}