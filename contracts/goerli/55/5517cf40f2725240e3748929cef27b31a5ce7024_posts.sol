/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract posts {

    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
     }

    struct post {
        address poster;
        uint256 id;
        string postTitle;
        string postText;
        string image;
        uint256 date;
    }

    event postCreated (
        address poster,
        uint256 id,
        string postTitle,
        string postText,
        string image
    );

    mapping(uint256 => post) Posts;

    function addPost(string memory postTitle, string memory postText, string memory image) public payable {
            require(msg.value == (0 ether), "Please pay gas fees to get your post on the blockchain");
            post storage newPost = Posts[counter];
            newPost.postTitle = postTitle;
            newPost.postText = postText;
            newPost.poster = msg.sender;
            newPost.id = counter;
            newPost.image = image;
            newPost.date = block.timestamp;
            emit postCreated(
                msg.sender, 
                counter, 
                postTitle, 
                postText,
                image
            );
            counter++;

            payable(owner).transfer(msg.value);
    }

    function getPost(uint256 id) public view returns (string memory, string memory, string memory, address, uint256){
        require(id < counter, "No such Post");

        post storage t = Posts[id];
        return (t.postTitle, t.postText,  t.image, t.poster, t.date);
    }

    function getAllPosts() public view returns (post[] memory allPosts) {
        allPosts = new post[](counter);

        for (uint256 i = 0; i < counter; i++) {
            allPosts[i] = Posts[i];
        }
    }

}