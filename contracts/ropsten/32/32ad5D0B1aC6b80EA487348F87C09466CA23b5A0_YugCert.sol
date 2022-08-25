/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAdmin {
    function isValidAdmin(address adminAddress) external view returns (bool);
}

contract YugCert {
    mapping(string => mapping(string => uint256)) public _checksum_mapping;
    address _admin;

    constructor(address admin) {
        _admin = admin;
    }

    function addChecksum(string memory checksum, string memory session_id, uint256 expiry) public {
        require(IAdmin(_admin).isValidAdmin(msg.sender), "Unauthorized");
        require(expiry > block.timestamp, "Expiry cant be past time");
        _checksum_mapping[checksum][session_id] = expiry;
    }
}