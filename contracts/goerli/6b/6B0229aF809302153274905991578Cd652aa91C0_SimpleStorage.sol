// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {
    mapping(address => Post[]) public postsByUser;

    struct Post {
        uint id;
        uint ipfsHash;
    }

    function addPost(uint256 hash) public {
        // Store the post on IPFS
        uint ipfsHash = hash;

        // Create a new post and add it to the user's array of posts
        Post memory newPost;
        newPost.id = postsByUser[msg.sender].length;
        newPost.ipfsHash = ipfsHash;
        postsByUser[msg.sender].push(newPost);
    }

    function getPosts(address user) public view returns (Post[] memory) {
        // Return the user's array of posts
        return postsByUser[user];
    }
}