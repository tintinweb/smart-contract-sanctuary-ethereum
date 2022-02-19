/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

contract ages {

    uint private age;
    function getAge() external view returns(uint) {
        return age;
    }

    function setAge(uint _age) external {
        age = _age;
    }
}