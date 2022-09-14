/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: unlicensed ;
pragma solidity 0.8.7;

contract GetterSetter {
    string private name;
    uint256 private age;

    function getName() public view returns (string memory) {
        return name;
    }

    function getAge() public view returns (uint256) {
        return age;
    }

    function setName (string memory _name) public {
        name = _name;
    }

    function setAge (uint256 _age) public {
        age = _age;
    }
}