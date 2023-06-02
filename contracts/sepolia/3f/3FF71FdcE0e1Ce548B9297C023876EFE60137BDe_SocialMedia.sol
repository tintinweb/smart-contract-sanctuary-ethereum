/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract SocialMedia{
    mapping (address => string) posts;
    event PostCreated(
        address addr,
        string post
    );
    function createPost(string memory post) public{
        posts[msg.sender] = post;
        emit PostCreated(msg.sender,post);

    }
    function getPost() public view  returns (string memory){
        return posts[msg.sender];
    }
}