/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

contract CrowdDemo{
    
    //创建接收人账户
    struct Admin{
        address payable addr;  //接收人账户
        uint amount;           //总收入
    }

    //用户存入
    struct User{
         address payable addr;
         uint amount;
    }

    mapping(address => User) users;

    //接收人信息
    Admin admin;

    constructor() public {
        admin = Admin({addr:0x8e5e45f04060bBf119d90043E0CEa0A6E63441F6,amount:0});
    }

    // 转入
    function income()public payable{
        admin.amount += msg.value;
        User storage u = users[msg.sender];
        u.amount += msg.value;
    }

    //转出
    function outcome()public payable{
      User storage cUser = users[msg.sender];
    if (cUser.amount>0){
            msg.sender.transfer(cUser.amount);
            cUser.amount= 0;
        }
    }

    //用户信息
   function userBanlanceInfo(address addr)  public view returns (uint){
        return users[addr].amount;
   }

    //fucking all
   function adminBanlanceInfo()  public view returns (uint){
        return admin.amount;
   }
}