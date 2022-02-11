/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

struct User {
    string name;
    address wallet;
    string publicKey; 
    bool isActive;
}
contract WalletAuthentication{

    mapping(address => User) private UserMap;
    uint8 public countUserArray=0;
    User [] public UserArray;

    function createUser(string memory _name,string memory _publicKey)public{
    require(UserMap[msg.sender].isActive==false,"Your wallet address is registered.");
    UserArray.push(User(_name,msg.sender,_publicKey,true));
    UserMap[msg.sender]=UserArray[countUserArray];
    countUserArray++;
    }

    function createUserByAddress(string memory _name,address _wallet,string memory _publicKey)public{
    require(UserMap[_wallet].isActive==false,"Your wallet address is registered.");
    UserArray.push(User(_name,_wallet,_publicKey,true));
    UserMap[_wallet]=UserArray[countUserArray];
    countUserArray++;
    }

    function userInfo(address _wallet)public view returns(string memory,string memory){
        User storage thisUser= UserMap[_wallet];
        if (thisUser.isActive) return (thisUser.name,thisUser.publicKey);
        else return ("null","null");
    }
}