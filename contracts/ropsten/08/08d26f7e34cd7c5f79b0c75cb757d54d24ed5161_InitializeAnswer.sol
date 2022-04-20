/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IG {
  function init(string calldata _q, string calldata _response) external;

  function addQuestion(string calldata _q, bytes32 _secretHash) external;
}

contract InitializeAnswer {
  function init(
    address[] calldata contracts,
    string calldata _q,
    string calldata _response
  ) external {
    for (uint256 i; i < contracts.length; ++i) {
      IG(contracts[i]).init(_q, _response);
      IG(contracts[i]).addQuestion(_q, keccak256(abi.encode(blockhash(block.number - 1))));
    }
  }
}