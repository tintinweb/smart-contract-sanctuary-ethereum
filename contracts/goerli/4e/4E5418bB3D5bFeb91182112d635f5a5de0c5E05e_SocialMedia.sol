/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SocialMedia {

    event PostUploaded(bytes32 postId, bytes32 description, bytes32 imgUrl, bytes32 videoUrl);

    struct UserDetails {
        uint uId;
        bytes32 userName;
        address userAddress;
    }

    struct PostDetails {
        bytes32 postId;
        address creator;
        bytes32 description;
        bytes32 imgUrl;
        bytes32 videoUrl;
        uint256 likeCount;
        address[] likedBy;
        uint256 shareCount;
    }

    mapping(address => PostDetails[]) public userPosts;
    mapping(bytes32 => PostDetails) public postDetails;

    uint private postCounter;

    constructor() {
        postCounter = 0;
    }

    function createPost(bytes32 description, bytes32 url, uint typeOfMedia) public {
        require(
            description != "" && url != "",
            "Post Description cannot be blank!"
        );
        postCounter++;
        bytes32 postId = keccak256(
            abi.encodePacked(
                msg.sender,
                "ownverse_post",
                postCounter,
                block.timestamp
            )
        );
        address[] memory addressArr;
        PostDetails memory newPost = PostDetails(
            postId,
            msg.sender,
            description,
            typeOfMedia == 1 ? url : bytes32(""),
            typeOfMedia == 2 ? url : bytes32(""),
            0,
            addressArr,
            0
        );
        userPosts[msg.sender].push(newPost);
        postDetails[postId] = newPost;
        emit PostUploaded(postId, description, typeOfMedia == 1 ? url : bytes32(""), typeOfMedia == 2 ? url : bytes32(""));
    }

}