// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "./Post.sol";

contract BlogFactory {
    Post[] public uploadedPosts;

    function createBlogPost(
        string memory _postTitle,
        string memory _tag,
        string memory _timestamp,
        string memory _content
    ) public {
        Post newPost = new Post(
            _postTitle,
            msg.sender,
            _tag,
            _timestamp,
            _content
        );

        uploadedPosts.push(newPost);
    }

    function getUploadedPosts() public view returns (Post[] memory) {
        return uploadedPosts;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Post {
    address public author;
    string public postTitle;
    uint256 public likeCount;
    string public tag;
    string public timestamp;
    string public content;

    mapping(address => bool) public didLike;

    address[] public likersAddresses;

    struct Likers {
        address creator;
        uint256 likeCount;
        bool isLiked;
        mapping(address => bool) likes;
    }

    Likers[] public likes;

    constructor(
        string memory _title,
        address _author,
        string memory _tag,
        string memory _timestamp,
        string memory _content
    ) {
        postTitle = _title;
        author = _author;
        tag = _tag;
        timestamp = _timestamp;
        likeCount = 0;
        content = _content;
    }

    function likePost() public {
        require(didLike[msg.sender] == false);

        didLike[msg.sender] = true;
        likeCount += 1;
        likersAddresses.push(msg.sender);
    }

    function getPostDetails()
        public
        view
        returns (
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            address[] memory
        )
    {
        return (
            author,
            postTitle,
            tag,
            timestamp,
            content,
            likeCount,
            likersAddresses
        );
    }
}