/*
  Copyright 2019-2021 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "Common.sol";
import "StarknetTokenBridge.sol";

contract StarknetEthBridge is StarknetTokenBridge {
    using Addresses for address;

    function deposit(uint256 l2Recipient) external payable {
        // The msg.value in this transaction was already credited to the contract.
        require(address(this).balance <= maxTotalBalance(), "MAX_BALANCE_EXCEEDED");
        sendMessage(msg.value, l2Recipient);
    }

    function withdraw(uint256 amount, address recipient) public override {
        // Make sure we don't accidentally burn funds.
        require(recipient != address(0x0), "INVALID_RECIPIENT");

        // The call to consumeMessage will succeed only if a matching L2->L1 message
        // exists and is ready for consumption.
        consumeMessage(amount, recipient);
        recipient.performEthTransfer(amount);
    }

    function transferOutFunds(uint256 amount, address recipient) internal override {
        recipient.performEthTransfer(amount);
    }
}