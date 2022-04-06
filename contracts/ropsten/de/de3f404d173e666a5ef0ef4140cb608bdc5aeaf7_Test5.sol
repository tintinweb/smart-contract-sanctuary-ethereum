/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test5 {
    uint age = 10;

    function setAge(uint _age) public {
        age = _age;
    }

    function getAge() public view returns(uint) {
        return age;
    }
}