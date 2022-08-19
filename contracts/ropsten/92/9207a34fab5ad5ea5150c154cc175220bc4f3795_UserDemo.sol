/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;
// import "@openzeppelin/contracts/access/Ownable.sol";

contract UserDemo  {
    /**
    *  创建model
    */

    struct user{
        address id;
        string name;
    }

    mapping(address => user) userList;

    user[] Users;//用户列表

    function addUser(address id,string memory name) public  {
        userList[id] = user(id,name);
        Users.push(user(id,name));
    } 

    function getUsetInfo(address id) public view returns(user memory userInfo){
        userInfo = userList[id];
    }

    function getUserList() public view returns (user[] memory){
       return Users;
    }

        

}