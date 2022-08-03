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

interface IFakeArbitrumInbox {
  function bridge() external view returns (address);

  function setBridge(address _bridge) external;
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }
}

contract FakeArbitrumBridge {
  using Address for address;

  event OwnerUpdated(address newOwner);
  event OutboxToggle(address indexed outbox, bool enabled);
  event BridgeCallTriggered(
    address indexed outbox,
    address indexed destAddr,
    uint256 amount,
    bytes data
  );

  struct InOutInfo {
    uint256 index;
    bool allowed;
  }
  mapping(address => InOutInfo) private allowedOutboxesMap;
  address[] public allowedOutboxList;

  address public owner;
  IFakeArbitrumInbox public immutable fakeInbox;

  address public activeOutbox;

  constructor(address _fakeInbox) {
    owner = msg.sender;
    fakeInbox = IFakeArbitrumInbox(_fakeInbox);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "FakeArbitrumBridge/ONLY_OWNER");
    _;
  }

  function setOwner(address newOwner) external onlyOwner {
    owner = newOwner;
    emit OwnerUpdated(newOwner);
  }

  function executeCall(
    address destAddr,
    uint256 amount,
    bytes calldata data
  ) external returns (bool success, bytes memory returnData) {
    require(allowedOutboxesMap[msg.sender].allowed, "FakeArbitrumBridge/NOT_FROM_OUTBOX");
    if (data.length > 0) require(destAddr.isContract(), "FakeArbitrumBridge/NO_CODE_AT_DEST");

    address prevBridge = fakeInbox.bridge();
    if (prevBridge != address(this)) {
      fakeInbox.setBridge(address(this));
    }

    address currentOutbox = activeOutbox;
    activeOutbox = msg.sender;
    // We set and reset active outbox around external call so activeOutbox remains valid during call
    (success, returnData) = destAddr.call{value: amount}(data);
    activeOutbox = currentOutbox;

    if (prevBridge != address(this)) {
      fakeInbox.setBridge(prevBridge);
    }
    emit BridgeCallTriggered(msg.sender, destAddr, amount, data);
  }

  function setOutbox(address outbox, bool enabled) external onlyOwner {
    InOutInfo storage info = allowedOutboxesMap[outbox];
    bool alreadyEnabled = info.allowed;
    emit OutboxToggle(outbox, enabled);
    if ((alreadyEnabled && enabled) || (!alreadyEnabled && !enabled)) {
      return;
    }
    if (enabled) {
      allowedOutboxesMap[outbox] = InOutInfo(allowedOutboxList.length, true);
      allowedOutboxList.push(outbox);
    } else {
      allowedOutboxList[info.index] = allowedOutboxList[allowedOutboxList.length - 1];
      allowedOutboxesMap[allowedOutboxList[info.index]].index = info.index;
      allowedOutboxList.pop();
      delete allowedOutboxesMap[outbox];
    }
  }
}