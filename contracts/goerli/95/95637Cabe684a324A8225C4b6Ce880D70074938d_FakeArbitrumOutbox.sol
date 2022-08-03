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

interface IBridge {
  function executeCall(
    address destAddr,
    uint256 amount,
    bytes calldata data
  ) external returns (bool success, bytes memory returnData);
}

contract FakeArbitrumOutbox {
  event OutBoxTransactionExecuted(
    address indexed destAddr,
    address indexed l2Sender,
    uint256 indexed outboxEntryIndex,
    uint256 transactionIndex
  );

  struct L2ToL1Context {
    uint128 l2Block;
    uint128 l1Block;
    uint128 timestamp;
    uint128 batchNum;
    bytes32 outputId;
    address sender;
  }

  IBridge public bridge;

  // Note, these variables are set and then wiped during a single transaction.
  // Therefore their values don't need to be maintained, and their slots will
  // be empty outside of transactions
  L2ToL1Context internal context;

  constructor(address _bridge) {
    bridge = IBridge(_bridge);
  }

  /// @notice When l2ToL1Sender returns a nonzero address, the message was originated by an L2 account
  /// When the return value is zero, that means this is a system message
  /// @dev the l2ToL1Sender behaves as the tx.origin, the msg.sender should be validated to protect against reentrancies
  function l2ToL1Sender() external view returns (address) {
    return context.sender;
  }

  /**
   * @notice Executes a L2>L1 message
   * @dev [ArbitrumFakeOutbox] Ignore the dispute period
   */

  function executeTransaction(
    uint256 batchNum,
    bytes32[] memory, /* proof */
    uint256 index,
    address l2Sender,
    address destAddr,
    uint256 l2Block,
    uint256 l1Block,
    uint256 l2Timestamp,
    uint256 amount,
    bytes memory calldataForL1
  ) external {
    // [ArbitrumFakeOutbox] Skipped: merkle proof check & spent output recording

    emit OutBoxTransactionExecuted(destAddr, l2Sender, batchNum, index);
    // we temporarily store the previous values so the outbox can naturally
    // unwind itself when there are nested calls to `executeTransaction`
    L2ToL1Context memory prevContext = context;
    context = L2ToL1Context({
      sender: l2Sender,
      l2Block: uint128(l2Block),
      l1Block: uint128(l1Block),
      timestamp: uint128(l2Timestamp),
      batchNum: uint128(batchNum),
      outputId: 0
    });
    // set and reset vars around execution so they remain valid during call
    executeBridgeCall(destAddr, amount, calldataForL1);
    context = prevContext;
  }

  function executeBridgeCall(
    address destAddr,
    uint256 amount,
    bytes memory data
  ) internal {
    (bool success, bytes memory returndata) = bridge.executeCall(destAddr, amount, data);
    if (!success) {
      if (returndata.length > 0) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert("FakeArbitrumOutbox/BRIDGE_CALL_FAILED");
      }
    }
  }
}