// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
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

pragma solidity ^0.8.15;

interface L2GovernanceRelayLike {
  function relay(address _target, bytes calldata _targetData) external;
}

interface IMailboxLike {
  function requestL2Transaction(
    address _contractL2,
    uint256 _l2Value,
    bytes calldata _calldata,
    uint256 _l2GasLimit,
    uint256 _l2GasPerPubdataByteLimit,
    bytes[] calldata _factoryDeps,
    address _refundRecipient
  ) external payable returns (bytes32 txHash);
}

contract L1GovernanceRelay {
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
    require(wards[msg.sender] == 1, "L1GovernanceRelay/not-authorized");
    _;
  }

  address public immutable l2GovernanceRelay; // the counterpart relay contract on L2
  IMailboxLike public immutable zkSyncMailbox; // zkSync main contract on L1

  event Rely(address indexed usr);
  event Deny(address indexed usr);

  constructor(address _l2GovernanceRelay, IMailboxLike _mailbox) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l2GovernanceRelay = _l2GovernanceRelay;
    zkSyncMailbox = _mailbox;
  }

  // Allow contract to receive ether
  receive() external payable {}

  // Allow governance to reclaim stored ether
  function reclaim(address _receiver, uint256 _amount) external auth {
    (bool sent, ) = _receiver.call{value: _amount}("");
    require(sent, "L1GovernanceRelay/failed-to-send-ether");
  }

  /**
   * @notice Forward a call to be repeated on L2. This is called by MakerDAO governance
   * to execute a previously deployed L2 spell via an L1 > L2 xdomain message.
   * @param _target The L2 contract to call
   * @param _targetData The calldata of the L2 call
   * @param _l1CallValue The amount of ether to send to zkSync Mailbox
   * @param _l2TxGasLimit The L2 gas limit to be used in the corresponding L2 transaction
   * @param _l2TxGasPerPubdataByte The gasPerPubdataByteLimit to be used in the corresponding L2 transaction
   * @param _factoryDeps array of L2 bytecodes that will be marked as known on L2. Empty for transactions not deploying contracts
   */
  function relay(
    address _target,
    bytes calldata _targetData,
    uint256 _l1CallValue,
    uint256 _l2TxGasLimit,
    uint256 _l2TxGasPerPubdataByte,
    bytes[] calldata _factoryDeps
  ) external payable auth returns (bytes32 txHash) {
    bytes memory l2TxCalldata = abi.encodeWithSelector(
      L2GovernanceRelayLike.relay.selector,
      _target,
      _targetData
    );

    txHash = zkSyncMailbox.requestL2Transaction{value: _l1CallValue}(
      l2GovernanceRelay,
      0, // l2Value is the amount of ETH sent to the L2 method. As the L2 method is non-payable, this is always 0
      l2TxCalldata,
      _l2TxGasLimit,
      _l2TxGasPerPubdataByte,
      _factoryDeps,
      l2GovernanceRelay
    );
  }
}