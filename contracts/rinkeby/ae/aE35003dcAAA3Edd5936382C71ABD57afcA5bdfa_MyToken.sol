/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MyToken  {

    uint private age;

    function setAge(uint _age) public {
        age = _age;
    }

    function getAge() public view returns(uint){
        return age;
    }
     
}