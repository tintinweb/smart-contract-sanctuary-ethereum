/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.8.0;

contract Logger {
    mapping(string => string) private logs;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addLog(string calldata log, string memory hashValue) external returns(bool) {
        logs[log] = hashValue;
        return true;
    }

    function getLog(string calldata log) external view returns(string memory) {
        return logs[log];
    }

}