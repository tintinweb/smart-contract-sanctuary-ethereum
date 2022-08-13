// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title IPDB
 * Interplanetary Database
 */

contract IPDB {
    struct Db {
        string cid;
        uint256 timestamp;
    }
    mapping(address => mapping(string => mapping(uint256 => Db))) databases;
    mapping(address => mapping(string => uint256)) versions;

    // This function stores correct cid inside the mapping
    function store(string memory name, string memory cid) external {
        // Do a version update, if 0 will start from version 1
        versions[msg.sender][name]++;
        // Store inside databases the version
        databases[msg.sender][name][versions[msg.sender][name]].cid = cid;
        databases[msg.sender][name][versions[msg.sender][name]]
            .timestamp = block.timestamp;
    }

    // This function returns the latest database
    function get(address identifier, string memory name)
        external
        view
        returns (string memory, uint256)
    {
        return (
            databases[identifier][name][versions[identifier][name]].cid,
            versions[identifier][name]
        );
    }

    // This function searches for a specific version of database
    function search(
        address identifier,
        string memory name,
        uint256 version
    ) external view returns (string memory) {
        return databases[identifier][name][version].cid;
    }
}