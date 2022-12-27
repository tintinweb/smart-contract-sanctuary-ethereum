/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract A {
    enum LoginState {
        logout,
        login
    }
    struct user {
        string id;
        string password;
        LoginState loginState;
    }

    mapping(address => user) Users;

    function setUser(address _addr, string memory _id, string memory _password) public {
        Users[_addr] = user(_id, _password, LoginState.login);
    }

    function logIn(address _addr, string memory _id, string memory _password) public {
        require(keccak256(abi.encodePacked(Users[_addr].id)) == keccak256(abi.encodePacked(_id)) 
        && 
        keccak256(abi.encodePacked(Users[_addr].password)) == keccak256(abi.encodePacked(_password)) , "Failed");
        require(Users[_addr].loginState == LoginState.logout);
        Users[_addr].loginState = LoginState.login;
    }

    function logOut(address _addr, string memory _id, string memory _password) public {
        require(keccak256(abi.encodePacked(Users[_addr].id)) == keccak256(abi.encodePacked(_id)) 
        && 
        keccak256(abi.encodePacked(Users[_addr].password)) == keccak256(abi.encodePacked(_password)) , "Failed");
        require(Users[_addr].loginState == LoginState.login);
        Users[_addr].loginState = LoginState.logout;
    }
    
    function getUser(address _addr) public view returns(string memory, string memory, LoginState){
        return (Users[_addr].id, Users[_addr].password, Users[_addr].loginState);
    }
}