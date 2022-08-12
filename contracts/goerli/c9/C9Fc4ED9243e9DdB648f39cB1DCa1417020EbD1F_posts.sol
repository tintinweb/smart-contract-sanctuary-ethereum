/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract posts{

    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
     }

    struct post {
        address poster;
        uint256 id;
        string postTxt;
        string postImg;
    }

    event postCreated (
        address poster,
        uint256 id,
        string postTxt,
        string postImg
    );

    mapping(uint256 => post) Posts;

    function addPost(
        string memory postTxt,
        string memory postImg
        ) public payable {
            require(msg.value == (0 ether), "Please submit 0 matic");
            post storage newPost = Posts[counter];
            newPost.postTxt = postTxt;
            newPost.postImg = postImg;
            newPost.poster = msg.sender;
            newPost.id = counter;
            emit postCreated(
                msg.sender, 
                counter, 
                postTxt, 
                postImg
            );
            counter++;

            payable(owner).transfer(msg.value);
    }

    function getPost(uint256 id) public view returns (string memory, string memory, address){
        require(id < counter, "No such post");

        post storage p = Posts[id];
        return (p.postTxt, p.postImg, p.poster);
    }
}