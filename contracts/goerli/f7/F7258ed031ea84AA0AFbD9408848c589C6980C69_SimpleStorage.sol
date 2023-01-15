// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    event UpdatedMessages(wrappedPost newPosts);

    mapping(address => wrappedPost) public postsByUser;
    address[] authorAddress;
    Post[] allPosts;
    wrappedPost[] allPosts2;
    uint256 userCount = 0;

    struct wrappedPost {
        address user;
        bool set;
        uint index;
        Post[] post;
    }

    struct Post {
        address user;
        uint id;
        string ipfsHash;
    }

    function addPost(string memory hash) public {
        // Create a new post and add it to the user's array of posts
        Post memory newPost;
        newPost.id = postsByUser[msg.sender].post.length;
        newPost.user = msg.sender;
        newPost.ipfsHash = hash;
        allPosts.push(newPost); //add the post to allpost array

        if (postsByUser[msg.sender].set != true) {
            authorAddress.push(msg.sender);
            postsByUser[msg.sender].index = userCount; //tells the location of the author in the array
            postsByUser[msg.sender].set = true;
            postsByUser[msg.sender].user = msg.sender;
            postsByUser[msg.sender].post.push(newPost); //add the post to the mapping
            allPosts2.push(postsByUser[msg.sender]);
            userCount += 1;
            emit UpdatedMessages(postsByUser[msg.sender]);
        } else {
            authorAddress.push(msg.sender);
            postsByUser[msg.sender].post.push(newPost); //add the post to the mapping
            allPosts2[postsByUser[msg.sender].index] = postsByUser[msg.sender];
            emit UpdatedMessages(postsByUser[msg.sender]);
        }
    }

    function getPosts(address user) public view returns (Post[] memory) {
        // Return the user's array of posts
        return postsByUser[user].post;
    }

    function getAllPostsByUser() public view returns (Post[] memory) {
        return allPosts;
    }

    function getAllPostsByUser2() public view returns (wrappedPost[] memory) {
        return allPosts2;
    }
}