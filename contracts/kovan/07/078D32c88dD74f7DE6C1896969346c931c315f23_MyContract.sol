/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    string _name;

    constructor(string memory name){
        _name = name;
    }


    function Hello() public view returns(string memory){
        return _name;
    }
}