/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract knowhere {
    struct Person {
        string name;
        uint age;
    }
    function set(Person memory person) public pure  returns(Person[] memory) {
        Person[] memory ps = new Person[](1);
        ps[0] = person;
        return ps;
    }

    function getTest (string memory test) public pure returns(bytes32){
	    return keccak256(abi.encode(test));
    }

    function setByte(bytes32 add) public pure returns(bytes32) {
        return add;
    }
}