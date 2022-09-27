/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
// Copyright 2022 Jack Kingsman
pragma solidity >=0.8.12;

contract ShoutBoard {
    uint64 internal constant halfLifeBlockCount = 7000; // recommended: 7000, or about 1 day
    uint256 internal constant topCost = 1 ether;

    address private adminAccount;
    string internal boardTitle;
    uint256 internal lastPost = 0;
    string[5] internal posts;
    uint8 internal constant maxPostCount = 5;

    modifier onlyAdmin {
        require(msg.sender == adminAccount, "Permission denied.");
        _;
    }

    constructor(string memory title) {
        adminAccount = msg.sender;
        boardTitle = title;
        for (uint8 i = 0; i < maxPostCount; i++) {
            posts[i] = "<not claimed>";
        }
    }

    function _setTitle(string calldata title) public onlyAdmin {
        boardTitle = title;
    }

    function _getPostCostWei() public view returns (uint) {
        if (lastPost == 0) {
            return 0;
        }

        uint blocksSincePost = block.number - lastPost;
        uint halvings = blocksSincePost / halfLifeBlockCount;
        uint currentCost = topCost;
        while (halvings > 0) {
            currentCost /= 2;
            halvings--;
        }

        return currentCost;
    }

    function post(string calldata postText) public payable {
        require(msg.value >= _getPostCostWei(), "Insufficient funds; please utilize _getPostCostWei() to see current cost in wei");

        // if we're at the maximum, shift the posts down and delete the last one
        for (uint8 i = maxPostCount - 1; i > 0; i--) {
            posts[i] = posts[i - 1];
        }

        lastPost = block.number;
        posts[0] = postText;
    }

    function _payout() public onlyAdmin {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function read() public view returns(string memory, string memory, string memory, string memory, string memory, string memory, string memory) {
        return (
            boardTitle,
            posts[0],
            posts[1],
            posts[2],
            posts[3],
            posts[4],
            "// Powered by \xF0\x9F\x93\xA3 Shoutboard"
        );
    }
}