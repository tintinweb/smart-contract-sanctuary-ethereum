/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SocialMedia{
    mapping (address => user) public users;
    post[] public posts;
    uint public postNum = 0;
    uint public userid = 0;
    
    event PostCreated(
        address addr,
        string post
    );

    event Success(
        bool success,
        string text
    );

    struct user {
        uint id;
        string name;
        uint[] posts;
        bool account;
    }

    struct post {
        uint id;
        string title;
        string body;
        uint date;
        uint likes;
    }

    function createPost(string memory title, string memory p) public{
        user storage currentUser = users[msg.sender];
        currentUser.posts.push(postNum);
        users[msg.sender] = currentUser;
        post memory newPost = post({id: users[msg.sender].id, title: title, body: p, date: block.timestamp, likes: 0});
        posts.push(newPost);
        postNum++;
        emit PostCreated(msg.sender,"New post was created");
    }

    function signin(string memory username) public {
        if(users[msg.sender].account == false){
            users[msg.sender] = user({id: userid, name: username, posts: new uint[](0), account: true});
            userid++;
            emit Success(true,"account was created successfully");

        }else{
            emit Success(true,"account already exists");
        }
    }

    function getPost(address addr) public view  returns (uint[] memory){
        return users[addr].posts;
    }
}