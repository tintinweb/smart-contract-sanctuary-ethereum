/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    string[] str;


    function store(string calldata str_) public {
        str.push(str_);
    }


    function retrieve() public view returns (string[] memory){
        return str;
    }
}