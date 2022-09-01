// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";

pragma solidity ^0.8.7;

contract Login{
    struct loginApp{
        string userName;
        string password;
        string email;
        uint16 loginStatus;
    }
    constructor(){
        
    }
  
    mapping (address => loginApp ) public loginMap;
 
    function signUp(string memory name, string memory psw, string memory userEmail) public{
        require(bytes(psw).length>0 && bytes(name).length>0 && bytes(userEmail).length>0,"Please Enter the value");
        require( bytes(loginMap[msg.sender].email).length <= 0 ,"User Already exist");
        loginMap[msg.sender].userName=name;
        loginMap[msg.sender].password=psw;
        loginMap[msg.sender].email=userEmail;

    }
    function SignIn(string memory _email, string memory psw)public{
        
       require(keccak256(abi.encodePacked(loginMap[msg.sender].email))== keccak256(abi.encodePacked(_email)) && keccak256(abi.encodePacked(loginMap[msg.sender].password))== keccak256(abi.encodePacked(psw)), "Email OR Password are invalid");
       loginMap[msg.sender].loginStatus = 1;
    }
    function signOut() public{
        loginMap[msg.sender].loginStatus = 0;
    }
    function changePassword(string memory psw, string memory oldPSW)public{
        require(bytes(psw).length > 0 && bytes(oldPSW).length > 0,"Please Enter the value");
        require(keccak256(abi.encodePacked(loginMap[msg.sender].password))!= keccak256(abi.encodePacked(psw)),"Enter New Password");
        require(keccak256(abi.encodePacked(loginMap[msg.sender].password))==keccak256(abi.encodePacked(oldPSW)),"Please enter correct password");
        loginMap[msg.sender].password=psw;
    }
}