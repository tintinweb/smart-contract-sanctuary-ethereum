/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity ^0.8.0;

contract Logger {
    mapping(string => string) private logs;
    mapping(address => bool) public whitelist;
    address public owner;

    constructor() {
        owner = msg.sender;
        whitelist[owner] = true;
    }

    function addUser(address user) external returns(bool) {
        require(msg.sender == owner);
        whitelist[user] = true;
        return true;
    }

    function addLog(string calldata log, string memory hashValue) external returns(bool) {
        require(whitelist[msg.sender]);
        logs[log] = hashValue;
        return true;
    }

    function getLog(string calldata log) external view returns(string memory) {
        return logs[log];
    }
}