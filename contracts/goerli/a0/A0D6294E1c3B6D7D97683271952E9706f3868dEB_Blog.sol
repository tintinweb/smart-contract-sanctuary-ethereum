/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Post {
    string title;
    uint32 timestamp;
    string content;
}

contract Blog {
    address public owner;
    string public name;

    Post[] public post;

    constructor(string memory _name) {
        owner = msg.sender;
        name = _name;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function setName(string memory _name) onlyOwner public {
        name = _name;
    }

    function count() public view returns (uint) {
        return post.length;
    }

    function create(string memory _title, string memory _content) onlyOwner public {
        Post memory newPost;
        newPost.title = _title;
        newPost.content = _content;
        newPost.timestamp = uint32(block.timestamp);

        post.push(newPost);
    }

    function page(uint offset, uint limit) public view returns (Post[] memory posts) {
        if (post.length == 0) {
            posts = new Post[](0);
            return posts;
        }

        require(offset < post.length, "OFFSET");
        require(limit > 0, "LIMIT");

        uint to = offset + limit;
        if (to > post.length) {
            to = post.length;
        }

        uint _count = to - offset;

        posts = new Post[](_count);

        uint i = 0;
        for (uint pos = offset; pos < to; pos++) {
            posts[i] = post[pos];
            i++;
        }
    }
}