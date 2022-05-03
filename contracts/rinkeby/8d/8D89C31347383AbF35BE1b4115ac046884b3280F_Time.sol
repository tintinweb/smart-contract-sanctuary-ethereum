pragma solidity ^0.8.4;

contract Time {
    uint256 public createTime;

    function getTime() external {
        createTime = block.timestamp;
    }
}