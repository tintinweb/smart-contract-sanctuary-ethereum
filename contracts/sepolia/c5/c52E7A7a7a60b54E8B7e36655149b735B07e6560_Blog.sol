// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Blog {

    struct Post {
        string cid;
        address author;
    }

    mapping(uint256 => Post) public posts;

    uint256 postId = 0;

    function createPost(string memory _cid) public {
        posts[postId] = Post (_cid, msg.sender);
        postId += 1;
    }

    function getCurrentPostId() public view returns(uint256) {
        return postId;
    }

    function getPost(uint256 _postId) public view returns(Post memory) {
        return posts[_postId];
    }

}