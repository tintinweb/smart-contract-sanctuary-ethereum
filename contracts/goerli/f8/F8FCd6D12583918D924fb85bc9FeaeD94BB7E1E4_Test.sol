// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Test {
 struct member {
    uint id;
    address addr;
    uint password;
    bool signIn;
 }
 mapping(address => member) members;

 function signUp(uint _password) public {
    members[msg.sender].password = _password;
 }

 function signIn(uint _password) public returns(bool) {
    require( members[msg.sender].password == _password, "wrong password");
    members[msg.sender].signIn = true;
    return members[msg.sender].signIn;
 }

 function search() public view returns(uint, bool){
    return (members[msg.sender].id,members[msg.sender].signIn);
 }
}