/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error Friend__AlreadyExists();

contract BenFriend {
    struct Friend {
        uint256 id;
        address friendAddress;
    }

    Friend[] private s_friendList;
    uint256 s_count;

    mapping(address => bool) private s_friendExists;

    event FriendBecome(uint256 indexed id, address indexed friend);

    constructor() {
        s_count = 0;
    }

    function becomeFriend() public {
        if (s_friendExists[msg.sender]) {
            revert Friend__AlreadyExists();
        }
        s_friendList.push(Friend(s_count, msg.sender));
        s_friendExists[msg.sender] = true;
        s_count++;

        emit FriendBecome(s_count, msg.sender);
    }

    function friendExists(address friendAddress) public view returns (bool) {
        return s_friendExists[friendAddress];
    }

    function getFriend(uint256 index) public view returns(Friend memory){
        return s_friendList[index];
    }

    function getCount() public view returns(uint256){
        return s_count;
    }
}