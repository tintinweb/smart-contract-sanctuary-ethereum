// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Decentragram {
    struct Post {
        uint256 id;
        string content;
        string imageHash;
        uint256 earnings;
        address payable author;
    }

    struct Tip {
        uint256 id;
        uint256 postId;
        uint256 amount;
        address sender;
    }

    Post[] public posts;
    Tip[] public tips;

    event PostCreated(
        uint256 id,
        string content,
        string imageHash,
        uint256 earnings,
        address author
    );
    event TipCreated(
        uint256 id,
        uint256 postId,
        uint256 amount,
        address sender
    );

    function createPost(
        string memory _content,
        string memory _imageHash
    ) public {
        require(bytes(_content).length > 0, "Content should not be empty");

        uint256 postId = posts.length;
        posts.push(Post(postId, _content, _imageHash, 0, payable(msg.sender)));
        emit PostCreated(postId, _content, _imageHash, 0, msg.sender);
    }

    function tip(uint256 _postId, uint256 _amount) public payable {
        require(_postId < posts.length, "Post does not exist");
        require(_amount > 0, "Amount should be greater than 0");
        require(
            msg.value == _amount,
            "Amount should be equal to the amount sent"
        );
        require(
            posts[_postId].author != msg.sender,
            "You cannot tip your own post"
        );

        uint256 tipId = tips.length;
        posts[_postId].earnings += _amount;
        posts[_postId].author.transfer(_amount);
        tips.push(Tip(tipId, _postId, _amount, msg.sender));
        emit TipCreated(tipId, _postId, _amount, msg.sender);
    }
}