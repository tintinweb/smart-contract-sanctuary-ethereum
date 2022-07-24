// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract FuturizeACL {
  mapping(bytes => address) public owners;
  mapping(bytes => mapping(address => bool)) public accessList;

  function createFile(bytes calldata ipfsCid) external {
    owners[ipfsCid] = msg.sender;
  }

  function giveAccess(bytes calldata ipfsCid, address userToReceiveAccess) external {
    require(owners[ipfsCid] == msg.sender, "Not owner of this file!");
    accessList[ipfsCid][userToReceiveAccess] = true;
  }

  function revokeAccess(bytes calldata ipfsCid, address userToRevokeAccess) external {
    require(owners[ipfsCid] == msg.sender, "Not owner of this file!");
    delete accessList[ipfsCid][userToRevokeAccess];
  }

  function hasAccess(bytes calldata ipfsCid, address userToCheck) public view returns (uint256) {
    if (accessList[ipfsCid][userToCheck] || owners[ipfsCid] == userToCheck) {
      return 1;
    } else {
      return 0;
    }
  }
}