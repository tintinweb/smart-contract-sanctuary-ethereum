// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.18;

contract Remarker {

    event Remarked(address indexed sender, string message);

    function remark(string memory _message) external {}

    function remarkWithEvent(string memory message) external {
        emit Remarked(msg.sender, message);
    }

}