// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.14;

contract FakeArbitrumInbox {
  // --- Auth ---
  mapping(address => uint256) public wards;

  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier auth() {
    require(wards[msg.sender] == 1, "FakeArbitrumInbox/not-authorized");
    _;
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event BridgeSet(address indexed bridge);

  address public bridge;

  constructor(address _bridge) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    bridge = _bridge;
  }

  /** @dev setBridge can be used to flip between using the real Bridge
   * (controlled by the Outbox, which enforces a 7 days security window)
   * and the FakeArbitrumBridge (which ignores the security window)
   */
  function setBridge(address _bridge) external auth {
    bridge = _bridge;
    emit BridgeSet(_bridge);
  }

  function createRetryableTicket(
    address, /* destAddr */
    uint256, /* arbTxCallValue */
    uint256, /* maxSubmissionCost */
    address, /* submissionRefundAddress */
    address, /* valueRefundAddress */
    uint256, /* maxGas */
    uint256, /* gasPriceBid */
    bytes calldata /* data */
  ) external payable returns (uint256) {
    // This fake inbox cannot be used to pass messages from L1 to L2
    revert("FakeArbitrumInbox/createRetryableTicket-not-supported");
  }

  function createRetryableTicketNoRefundAliasRewrite(
    address, /* destAddr */
    uint256, /* arbTxCallValue */
    uint256, /* maxSubmissionCost */
    address, /* submissionRefundAddress */
    address, /* valueRefundAddress */
    uint256, /* maxGas */
    uint256, /* gasPriceBid */
    bytes calldata /* data */
  ) external payable returns (uint256) {
    // This fake inbox cannot be used to pass messages from L1 to L2
    revert("FakeArbitrumInbox/createRetryableTicketNoRefundAliasRewrite-not-supported");
  }
}