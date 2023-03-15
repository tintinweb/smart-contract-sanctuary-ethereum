// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//Errors
error deletePost__InvalidPostUid();
error deletePost__SenderNotPoster();

/**
 * @title Social Media Contract
 * @author Hari Krishna
 * @dev This contract is a social media application for web3 users
 */
contract SocialMedia {
    //type Declarations
    struct Post {
        address User;
        uint postUid;
        string text;
        string ipfsHash;
    }
    mapping(uint => Post) private posts;

    //State Variables
    uint private postUid;
    uint private numberofPost;

    //modifiers
    modifier isPostExist(uint _postId) {
        if (posts[_postId].User == address(0)) revert deletePost__InvalidPostUid();
        _;
    }

    modifier isSenderIsCreator(uint _postId) {
        if (posts[_postId].User != msg.sender) revert deletePost__SenderNotPoster();
        _;
    }

    //Events
    event NewPost(address indexed users, string ipfsHash, string text, uint postId);
    event DeletePost(address indexed users, uint postId);

    //Functions
    function createPost(string memory _text, string memory _ipfsHash) public {
        ++postUid;
        posts[postUid] = Post(msg.sender, postUid, _text, _ipfsHash);
        numberofPost++;
        emit NewPost(msg.sender, _ipfsHash, _text, postUid);
        
        
    }

    function deletePost(uint _postUid) public isPostExist(_postUid) isSenderIsCreator(_postUid) {
        delete posts[_postUid];
        numberofPost--;
        emit DeletePost(msg.sender, _postUid);
    }

    //view/ pure functions
    function getPoster(uint _postUid) public view isPostExist(_postUid) returns (address) {
        return posts[postUid].User;
    }

    function getNumberOfPosts() public view returns (uint) {
        return numberofPost;
    }

    function getTotalPost()public view returns (uint) {
        return postUid;
    }

    function getPost(uint _postUid) public view isPostExist(_postUid) returns (Post memory) {
        return posts[postUid];
    }

    function getIpfsHash(uint _postUid) public view isPostExist(_postUid) returns (string memory) {
        return posts[postUid].ipfsHash;
    }
}