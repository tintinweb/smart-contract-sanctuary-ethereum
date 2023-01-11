// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Twitter {
    struct Post {
        string content;
        address creator;
        uint likes;
        uint id;
    }

    Post[] public postsArray;
    mapping(uint => Post) public posts;

    function createPost(string memory _content) public {
        Post memory newPost = Post({
            content: _content,
            creator: msg.sender,
            likes: 0,
            id: postsArray.length
        });
        posts[newPost.id] = newPost;
        postsArray.push(newPost);
    }

    function likePost(uint _id) public {
        Post storage post = posts[_id];
        Post storage postFromArray = postsArray[_id];

        post.likes++;
        postFromArray.likes++;
    }

    function deletePost(uint _id) public {
        require(
            msg.sender == posts[_id].creator &&
                msg.sender == postsArray[_id].creator,
            "You cannot delete somedy's post"
        );
        delete (posts[_id]);
        delete (postsArray[_id]);
    }

    function getPostsArray() public view returns (Post[] memory) {
        return postsArray;
    }
}