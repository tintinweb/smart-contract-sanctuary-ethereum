/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IG {
  function initAnswer(string calldata _q, string calldata _response) external;

  function addQuestion(string calldata _q, bytes32 _secretHash) external;
}

contract InitializeAnswer {
  uint256 private constant _version = 1;
  address private immutable _admin_deployer;

  constructor() public payable {
    _admin_deployer = msg.sender;
  }

  function initAnswer(
    address[] calldata contracts,
    string calldata _q,
    string calldata _response
  ) external {
    for (uint256 i; i < contracts.length; ++i) {
      IG(contracts[i]).initAnswer(_q, _response);
      IG(contracts[i]).addQuestion(_q, keccak256(abi.encode(12345)));
    }
  }
}