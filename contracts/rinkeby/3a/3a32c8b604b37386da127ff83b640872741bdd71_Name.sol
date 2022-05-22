/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT

contract Name{
    string public name ;

    constructor(string memory _name){
        name = _name;
    }

    function getName() public view returns(string memory){
        return name;
    }

    function setName(string memory _name)public{
        name = _name;
    }

}