/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Store {

    address admin = msg.sender;
    mapping (address => uint)  ownerRegisterCount;

    constructor (){
        ownerRegisterCount[admin] = 2 ;
    }

    event NewUser(string username);
    struct User{
        string username;
        address direction;
    }

    function sendMeMoneyContract() public payable{

    }

    function sendAdminMoneyContract () public  {

    }

    function refundMoneyUser() private{

    }


    User[] users;

    function register (string memory _username) public {
        users.push(User(_username, msg.sender));
        require (ownerRegisterCount[msg.sender]==0,"Register failed");
        ownerRegisterCount[msg.sender]++;
        emit NewUser(_username);
    }

    function list() public view returns (User[] memory){
        require (ownerRegisterCount[msg.sender] == 2);
        return users;
    }

    function unsubscribe() public{
        require (ownerRegisterCount[msg.sender] == 1,"Unsubscribe failed");
        for (uint i = 0; i < users.length-1; i++){
            users[i] = users[i+1];
        }
        users.pop();
    }
}