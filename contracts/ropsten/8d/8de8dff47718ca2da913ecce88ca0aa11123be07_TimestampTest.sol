/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.8.7;

contract TimestampTest {
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}