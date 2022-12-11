/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

/*
 * 区块链微博程序
 */
contract MicroBlog {
    string app_name; // 应用程序的名称

    uint256 blog_id; // 当前微博ID

    mapping(uint256 => Blog) blogs;

    struct Blog {
        uint256 time;
        address owner;
        string content;
    }

    event Log(string _log);

    constructor(string memory _name) {
        app_name = _name;
    }

    function publish(string memory content) public {
        blogs[blog_id] = Blog(block.timestamp, msg.sender, content);
        blog_id++;
    }

    function getBlogCount() public view returns (uint256) {
        return blog_id;
    }

    function getBlogById(uint256 id) public view returns (Blog memory) {
        return blogs[id];
    }
}