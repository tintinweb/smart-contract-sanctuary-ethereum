/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract PORN {

    struct Comment {
        bool like;
        string content;
    }

    struct Post {
        string content;
        uint pb_value;
    }

    struct Member {
        string name;
        uint256 p_value;
        uint build_time;
    }

    mapping(address => Member) public members;
    Post[] public posts;
    Comment[] public comments;
    mapping(address => uint[]) public account_to_post;
    mapping(uint => uint[]) public post_to_comment;
    mapping(uint => address) public comment_to_account;

    event NewPostAdded(uint post_id, uint comment_id, address owner);
    /// Create a new ballot to choose one of `proposalNames`.
    constructor(string memory name) {
        join(msg.sender, name);
    }

    function join(address addr, string memory name) public{
        members[addr].name = name;
        members[addr].p_value = 100;
        members[addr].build_time = block.timestamp;
    }

    function get_p_value(address addr) public view returns(uint256){
        return members[addr].p_value;
    }

    function new_post(string memory text) public{
        Post memory post = Post({content: text, pb_value: 0});
        posts.push(post);
        uint id = posts.length - 1;

        account_to_post[msg.sender].push(id);
        emit NewPostAdded(id, 0, msg.sender);
    }

    function new_comment(uint post_id, bool _like, string memory text) public{
        Comment memory comment = Comment({like: _like, content: text});
        comments.push(comment);
        uint comment_id = comments.length - 1;

        post_to_comment[post_id].push(comment_id);
        comment_to_account[comment_id] = msg.sender;
        emit NewPostAdded(post_id, comment_id, msg.sender);
    }
   
}