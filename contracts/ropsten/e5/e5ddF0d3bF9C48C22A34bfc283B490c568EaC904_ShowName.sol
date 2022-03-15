/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ShowName{
    string MyName;

    function set(string memory x) public {
        MyName = x;
    }

    function get() public view returns(string memory){
        return MyName;
    }
}