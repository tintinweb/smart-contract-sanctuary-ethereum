/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract AtlasTest {
  event OracleRequest(
    bytes32 indexed requestId,
    address requestingContract,
    address requestInitiator,
    uint64 subscriptionId,
    address subscriptionOwner,
    bytes data
  );
  event OracleResponse(bytes32 indexed requestId);
  event UserCallbackError(bytes32 indexed requestId, string reason);
  event UserCallbackRawError(bytes32 indexed requestId, bytes lowLevelData);

  // 32: 0x010000000000000000000000000000000000000000000000
  // "sample error" => 0x73616d706c65206572726f72
  // "sample data" => 0x73616d706c652064617461

  function fireOracleRequest(
    bytes32 requestId,
    uint64 subscriptionId,
    bytes memory data
  ) public {
      emit OracleRequest(requestId, address(this), msg.sender, subscriptionId, msg.sender, data);
  }

  function fireOracleResponse(
    bytes32 requestId
  ) public {
    emit OracleResponse(requestId);
  }

  function fireUserCallbackError(
    bytes32 requestId, 
    string memory reason
  ) public {
    emit UserCallbackError(requestId, reason);
  }

  function fireUserCallbackRawError(
    bytes32 requestId, 
    bytes memory lowLevelData
  ) public {
    emit UserCallbackRawError(requestId, lowLevelData);
  }
}