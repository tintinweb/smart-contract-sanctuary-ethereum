/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Post {
    struct PostData {
        string title;
        string metaUrl;
        string description;
    }

    mapping(uint => PostData) public postStore;  // public 是對ㄉ嗎
    uint public postCount;

    function addPost(string memory _title, string memory _metaUrl, string memory _description) public {  // 讓外面的人可以呼叫所以是 public
        postStore[postCount] = PostData(_title, _metaUrl, _description);
        postCount++;
    }

    function getAllPost() public view returns (PostData[] memory) {
        PostData[] memory result = new PostData[](postCount);  // new 出 array
        for(uint i = 0; i < postCount; i++) {
            result[i] = postStore[i];
        }
        return result;
    }
}