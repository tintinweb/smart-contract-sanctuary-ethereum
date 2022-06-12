/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract MyContract{
    string value;
    
    function get() public view returns(string memory){
        return value;
    }

    function set(string memory _value) public {
        value = _value;
    }

}