/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

struct user {
    uint age;
    string father;
}

contract School {

    string public class;
    mapping(address => user) public users;

    constructor(string memory _class){
        class = _class;
    }

    function setUser(address _address, uint _age, string memory _father) public{
        users[_address].age = _age;
        users[_address].father = _father;
    }
}