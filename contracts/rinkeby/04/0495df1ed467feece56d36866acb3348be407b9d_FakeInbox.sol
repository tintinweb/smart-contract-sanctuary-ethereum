/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.6.11;

contract FakeInbox  {
  event InboxMessageDelivered(uint256 indexed messageNum, bytes data);
  event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);

  address public immutable bridge;
  FakeInbox public constant inbox = FakeInbox(0x578BAde599406A8fE3d24Fd7f7211c0911F5B29e);

  constructor(address _bridge) public {
      bridge = _bridge;
  }
  
  function createRetryableTicket(
    address destAddr,
    uint256 arbTxCallValue,
    uint256 maxSubmissionCost,
    address submissionRefundAddress,
    address valueRefundAddress,
    uint256 maxGas,
    uint256 gasPriceBid,
    bytes calldata data
  ) external payable returns (uint256) {
        inbox.createRetryableTicket(destAddr, arbTxCallValue, maxSubmissionCost, submissionRefundAddress, valueRefundAddress, maxGas, gasPriceBid, data);
  }

  function createRetryableTicketNoRefundAliasRewrite(
    address destAddr,
    uint256 arbTxCallValue,
    uint256 maxSubmissionCost,
    address submissionRefundAddress,
    address valueRefundAddress,
    uint256 maxGas,
    uint256 gasPriceBid,
    bytes calldata data
  ) external payable returns (uint256) {
       inbox.createRetryableTicketNoRefundAliasRewrite(destAddr, arbTxCallValue, maxSubmissionCost, submissionRefundAddress, valueRefundAddress, maxGas, gasPriceBid, data);
  }
}