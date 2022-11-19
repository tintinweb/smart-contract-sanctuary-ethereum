/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    mapping(address => uint[]) personalArray;
    function addToPersonalArray(uint _number) public {
        personalArray[msg.sender].push(_number);
    }
    function getPersonalArray() public view returns(uint[] memory){
        return personalArray[msg.sender];
    }
}