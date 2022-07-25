/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

contract hd {

    string private name;
    uint private age;

    function setName(string memory newName) public {
        name = newName;
    }

    function getName() view public returns(string memory) {
        return name;
    }

    function setAge(uint newAge) public {
        age = newAge;
    }

    function getAge() view public returns(uint) {
        return age;
    }

}