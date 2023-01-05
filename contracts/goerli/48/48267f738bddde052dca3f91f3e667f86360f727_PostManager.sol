// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./post.sol";

contract PostManager {
    uint256 postIDCounter;
    Post[] public posts;
    mapping(address => uint256) public postIDs;
    string public CID; //Content Identifier

    function createPost(string memory _CID) external returns (bool) {
        uint256 postID = postIDCounter;
        postIDCounter++;
        Post post = new Post(msg.sender);
        posts.push(post);
        postIDs[address(post)] = postID;
        _CID = CID;
        return true;
    }

    function addComment(string memory _CID, address _postAddress)
        external
        returns (bool)
    {
        uint256 postID = postIDs[_postAddress];
        posts[postID].postComment(msg.sender, block.timestamp);
        _CID = CID;
        return true;
    }

    function getPosts() external view returns (address[] memory _posts) {
        _posts = new address[](postIDCounter);
        for (uint256 i = 0; i < postIDCounter; i++) {
            _posts[i] = address(posts[i]);
        }
        return _posts;
    }

    function getPostsData(address[] calldata _postList)
        external
        view
        returns (
            address[] memory posterAddress,
            uint256[] memory numberOfLikes,
            uint256[] memory numberOfComments,
            string memory postCID
        )
    {
        posterAddress = new address[](_postList.length);
        numberOfLikes = new uint256[](_postList.length);
        numberOfComments = new uint256[](_postList.length);
        postCID = CID;
        for (uint256 i = 0; i < _postList.length; i++) {
            uint256 postID = postIDs[_postList[i]];
            posterAddress[i] = posts[postID].poster();
            numberOfLikes[i] = posts[postID].likeListLength();
            numberOfComments[i] = posts[postID].commentListLength();
        }
        return (posterAddress, numberOfLikes, numberOfComments, postCID);
    }
}