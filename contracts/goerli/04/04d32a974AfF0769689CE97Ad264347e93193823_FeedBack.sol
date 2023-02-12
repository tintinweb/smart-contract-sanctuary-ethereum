// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract FeedBack {
    string[] public userFeedback; // array of feedbacks

    function sendFeedBack(string calldata _userFeedback) external {
        userFeedback.push(_userFeedback);
    }

    function getFeedBack() public view returns (string[] memory) {
        string[] memory feedbacks = new string[](userFeedback.length);
        for (uint i = 0; i < userFeedback.length; i++) {
            feedbacks[i] = userFeedback[i];
        }
        return feedbacks;
    }
}