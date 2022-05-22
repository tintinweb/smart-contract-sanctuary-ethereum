/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity 0.8.10;
// SPDX-License-Identifier: MIT

contract name{
    string public name ;
    constructor(string memory _name){
        name = _name;
    }
    function get_Name()public view returns(string memory){
        return name ;
    }
    function set_Name(string memory _name)public{
        name = _name ;
    }
}