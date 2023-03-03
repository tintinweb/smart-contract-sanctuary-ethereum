// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

error Post__AlreadyLiked();
error Post__RewardTransferFailed();

contract PostFactory {
    struct Post {
        address author;
        string postTitle;
        string content;
        uint256 createdOn;
        uint rewardEarned;
        address[] likers;
    }

    uint private postCount;
    mapping(uint => Post) private postMapping;
    mapping(address => mapping(uint => bool)) private likedPosts;

    event Post__Created(uint indexed postId, address indexed author);

    constructor() {
        postCount = 0;
    }

    function createPost(string memory _postTitle, string memory _content) public {
        postMapping[postCount] = Post(
            msg.sender,
            _postTitle,
            _content,
            block.timestamp,
            0,
            new address[](0)
        );
        emit Post__Created(postCount, msg.sender);
        postCount++;
    }

    function likePost(uint _postId) public {
        Post storage post = postMapping[_postId];
        if (likedPosts[msg.sender][_postId]) {
            revert Post__AlreadyLiked();
        }
        post.likers.push(msg.sender);
        likedPosts[msg.sender][_postId] = true;
    }

    function rewardPost(uint _postId) external payable {
        Post storage post = postMapping[_postId];
        (bool success, ) = payable(post.author).call{value: msg.value}("");
        if (!success) {
            revert Post__RewardTransferFailed();
        }
        post.rewardEarned = post.rewardEarned + msg.value;
    }

    function getPostDetails(
        uint _postId
    ) public view returns (address, string memory, string memory, uint256, uint, uint) {
        Post storage post = postMapping[_postId];
        uint likes = post.likers.length;
        return (
            post.author,
            post.postTitle,
            post.content,
            post.createdOn,
            post.rewardEarned,
            likes
        );
    }

    function getTotalPostCount() public view returns (uint) {
        return postCount;
    }
}