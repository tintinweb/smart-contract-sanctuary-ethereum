/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

contract ContractPub {
 uint256 public num;
 string public name;
    constructor(uint256 _num, string memory _name){
        num = _num;
        name = _name;
    }
    function doWork() external
    {
        selfdestruct(payable(0));
    }
    function getNum() public view returns(uint){
        return num;
    }
    function getName() public view returns(string memory){
        return name;
    }
}