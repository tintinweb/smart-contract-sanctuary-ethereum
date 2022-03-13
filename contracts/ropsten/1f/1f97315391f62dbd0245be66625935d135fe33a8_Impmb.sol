/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Impmb {

    struct Prediction {
        string title;
        string content;
        address owner;
        uint ts;
    }

    Prediction[] public topics;

    function postPrediction(string memory title, string memory content) public {
        topics.push(Prediction(title, content, msg.sender, block.timestamp));
    }

    function getCount() public view returns(uint) {
        return topics.length;
    }
}