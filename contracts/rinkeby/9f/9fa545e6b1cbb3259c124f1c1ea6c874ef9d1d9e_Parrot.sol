// SPDX-License-Identifier: MIT
import "./Counters.sol";
pragma solidity ^0.8.7;

contract Parrot{
    using Counters for Counters.Counter;
    Counters.Counter private _postIds;
    struct post {
        string posturi;
        address creator;
    }
    mapping(uint => post) public parrot_id;

    event postcreated(
        address creator,
        uint postid,
        string uri
    );
    function makepost(string memory posturi) public {
        uint256 postId = _postIds.current();
        parrot_id[postId] = post(
            posturi, 
            msg.sender
        );
        emit postcreated(msg.sender, postId, posturi);
        _postIds.increment();
    }

    function fetchPost() public view returns (post[] memory) {
    uint postCount = _postIds.current();

    post[] memory postsitem = new post[](postCount);
    for (uint i = 0; i < postCount; i++) {
        post storage currentpost = parrot_id[i];
        postsitem[i] = currentpost;
      }
    
    return postsitem;
    }

}