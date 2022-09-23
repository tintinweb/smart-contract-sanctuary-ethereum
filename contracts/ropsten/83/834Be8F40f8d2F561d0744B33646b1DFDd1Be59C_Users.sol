/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract Users {

  struct User {
        uint256 id;
        string firstName;
        string lastName;
        string phoneNo;
        string userAddress;
    }   

    User [] public users;

    uint public userCount = 0;

    function insert(string memory firstName, string memory lastName, string memory phoneNo, string memory userAddress) public {
        users.push(User(userCount, firstName, lastName, phoneNo, userAddress));
        userCount++;
    }

    function getAll() public view returns (User[] memory) {
        return users;
    }

    function remove(uint index) public {
        if (index >= users.length) return revert('User does not exist!');

        if (index == users[index].id) {
            delete users[index];
            userCount--;
        }
    }

    function getByID(uint index) public view returns(User memory){
        return(users[index]);
    }
}