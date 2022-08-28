// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title IPDB
 * Interplanetary Database
 */

contract IPDB {
    mapping(address => mapping(string => mapping(uint256 => string))) databases;
    mapping(address => mapping(string => uint256)) versions;

    event Stored(address _database, string _name, uint256 version, string _cid);

    // This function stores correct cid inside the mapping
    function store(string memory name, string memory cid) external {
        // Do a version update, if 0 will start from version 1
        versions[msg.sender][name]++;
        // Store inside databases the version
        databases[msg.sender][name][versions[msg.sender][name]] = cid;
        emit Stored(msg.sender, name, versions[msg.sender][name], cid);
    }

    // This function returns the latest database
    function get(address identifier, string memory name)
        external
        view
        returns (string memory, uint256)
    {
        return (
            databases[identifier][name][versions[identifier][name]],
            versions[identifier][name]
        );
    }

    // This function searches for a specific version of database
    function search(
        address identifier,
        string memory name,
        uint256 version
    ) external view returns (string memory) {
        return databases[identifier][name][version];
    }
}