// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract WebThreeSocial {
    address public owner;
    uint256 private counter;

    // Function runs once when the contract is deployed
    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    // Data structure of each post
    struct post {
        address sender;
        uint256 id;
        string postTxt;
        string postImg;
    }

    // Event to fire when a post is created and update frontend
    event postCreated (address sender, uint256 id, string postTxt, string postImg);

    // Mapping counter(postId) to each post
    mapping(uint256 => post) Posts;

    // Function to add a new post and write the information to the blockchain
    function addPost (string memory _postTxt, string memory _postImg) public payable {
        require(msg.value == (1 ether), "Please submit 1 ether"); // sender should send 1 ETH along with each post
        post storage newPost = Posts[counter];
        newPost.sender = msg.sender;
        newPost.id = counter;
        newPost.postTxt = _postTxt;
        newPost.postImg = _postImg;
        emit postCreated (msg.sender, counter, _postTxt, _postImg);
        counter++;

        payable(owner).transfer(msg.value);
    }

    // Function to get the post by the postId
    function getPost(uint256 _postId) public view returns (string memory, string memory, address) {
        require(_postId < counter, "Post does not exist"); // Check to make sure that the postId exists
        post storage p = Posts[_postId];
        return (p.postTxt, p.postImg, p.sender);
    }
}