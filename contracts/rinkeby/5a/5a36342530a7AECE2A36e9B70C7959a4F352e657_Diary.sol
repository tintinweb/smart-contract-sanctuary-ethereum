// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Diary {
    event DiaryLog(address author, string diary);

    function write(string calldata diary) external {
        emit DiaryLog(msg.sender, diary);
    }
}