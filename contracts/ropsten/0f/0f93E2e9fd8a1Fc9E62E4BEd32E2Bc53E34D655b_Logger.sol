/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity ^0.8.0;

contract Logger {
    struct Snapshot {
        string hashValue;
        uint32 recordsCount;
        uint32 timestamp;
    }
    mapping(string => Snapshot[]) private snapshots;
    mapping(string => string[]) private logs;
    mapping(address => bool) public whitelist;
    address public owner;

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    constructor() {
        owner = msg.sender;
        whitelist[owner] = true;
    }

    function addUser(address user) external returns(bool) {
        require(msg.sender == owner);
        whitelist[user] = true;
        return true;
    }

    function addLog(string calldata organizationId, string memory logId) external returns(bool) {
        require(whitelist[msg.sender]);
        for (uint i = 0; i < logs[organizationId].length; i++) {
            require(!compareStrings(logs[organizationId][i], logId));
        }
        logs[organizationId].push(logId);
        return true;
    }

    function getLogs(string calldata organizationId) public view returns(string[] memory) {
        return logs[organizationId];
    }

    function compareSnapshots(Snapshot memory a, Snapshot memory b) private pure returns (bool) {
        if (!compareStrings(a.hashValue, b.hashValue)) {
            return false;
        }
        if (a.recordsCount != b.recordsCount) {
            return false;
        }
        if (a.timestamp != b.timestamp) {
            return false;
        }
        return true;
    }

    function addSnapshot(string calldata logId, Snapshot memory snapshot) external returns(bool) {
        require(whitelist[msg.sender]);
        for (uint i = 0; i < snapshots[logId].length; i++) {
            require(!compareSnapshots(snapshots[logId][i], snapshot));
        }
        snapshots[logId].push(snapshot);
        return true;
    }

    function getSnapshots(string calldata logId) public view returns(Snapshot[] memory) {
        return snapshots[logId];
    }
}