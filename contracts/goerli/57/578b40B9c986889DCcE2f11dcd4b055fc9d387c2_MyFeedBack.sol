// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract MyFeedBack {
    struct Feedback {
        address sender;
        string feedback;
        uint timestamp;
    }

    Feedback[] public userFeedback;

    function sendFeedBack(string calldata _userFeedback) external {
        Feedback memory feedback = Feedback({
            sender: msg.sender,
            feedback: _userFeedback,
            timestamp: block.timestamp
        });
        userFeedback.push(feedback);
    }

    function getFeedBack() public view returns (Feedback[] memory) {
        return userFeedback;
    }
}