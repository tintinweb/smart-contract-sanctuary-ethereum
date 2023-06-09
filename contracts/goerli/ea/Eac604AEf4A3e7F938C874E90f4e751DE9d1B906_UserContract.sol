// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract UserContract {

    mapping (address=>bool) users;
    

    function signin(address _user) public {
        users[_user] = true;
    }

    function login() public view returns (bool){
        return users[msg.sender];
    }
}