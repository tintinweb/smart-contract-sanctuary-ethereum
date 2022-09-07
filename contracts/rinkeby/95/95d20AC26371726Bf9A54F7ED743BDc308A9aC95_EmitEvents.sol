/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract EmitEvents {
    struct User {
        string name;
        uint age;
        address addr;
    }
    mapping (address => User) public users;
    event Log(string name, uint age, address addr);

    function register(string memory _name, uint _age, address _addr) public {
        users[_addr] = User(_name, _age, _addr);
        emit Log(_name, _age, _addr);
    }

}