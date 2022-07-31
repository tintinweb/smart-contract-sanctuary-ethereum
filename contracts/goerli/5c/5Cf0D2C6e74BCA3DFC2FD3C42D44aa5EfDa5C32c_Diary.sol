// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Diary {
    event DiaryLog(
        address indexed author,
        string diary,
        string date,
        string weather
    );

    function write(
        string calldata diary,
        string calldata date,
        string calldata weather
    ) external {
        emit DiaryLog(msg.sender, diary, date, weather);
    }

    fallback() external payable {}
    receive() external payable {}
}