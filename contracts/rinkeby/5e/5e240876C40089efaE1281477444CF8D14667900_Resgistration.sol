/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Resgistration{

    struct signUp{
        string first_Name;
        string last_Name;
        string email;
        uint password;
        uint confirmPassword;
        bool isActive;
    }


    mapping(address => signUp) public UserRegistration;
    address public Owner;
    uint public x;


   constructor(){
    Owner = msg.sender;
  }
modifier OnlyOwner {
      require(Owner == msg.sender,"Caller is not owner!");
      _;
  }

    function  setUser(address sender, string memory fname, string memory lname,string memory  _email, uint _password,uint _cpassword, bool isActive) public OnlyOwner {
        require(_password == _cpassword, "password and confirm password not match");
        UserRegistration[sender]=signUp(fname,lname,_email,_password,_cpassword, isActive);
  
    }

    function login(address sender) public view returns(bool){
      return UserRegistration[sender].isActive;

    }
 function updateUser(address sender, string memory fname, string memory lname,string memory  _email, uint _password,uint _cpassword) public{
     UserRegistration[sender].first_Name=fname;
     UserRegistration[sender].last_Name=lname;
    UserRegistration[sender].email=_email;
    UserRegistration[sender].password=_password;
    UserRegistration[sender].confirmPassword=_cpassword;
    require(_password == _cpassword, "password and confirm password not match");


 }

   
}