/*
  Copyright 2019-2022 StarkWare Industries Ltd.

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

import "NamedStorage.sol";
import "IERC20.sol";
import "StarknetTokenBridge.sol";
import "Transfers.sol";

contract StarknetERC20Bridge is StarknetTokenBridge {
    function deposit(uint256 amount, uint256 l2Recipient) external {
        uint256 currentBalance = IERC20(bridgedToken()).balanceOf(address(this));
        require(currentBalance <= currentBalance + amount, "OVERFLOW");
        require(currentBalance + amount <= maxTotalBalance(), "MAX_BALANCE_EXCEEDED");
        Transfers.transferIn(bridgedToken(), msg.sender, amount);
        sendMessage(amount, l2Recipient);
    }

    function withdraw(uint256 amount, address recipient) public override {
        // The call to consumeMessage will succeed only if a matching L2->L1 message
        // exists and is ready for consumption.
        consumeMessage(amount, recipient);
        Transfers.transferOut(bridgedToken(), recipient, amount);
    }

    function transferOutFunds(uint256 amount, address recipient) internal override {
        Transfers.transferOut(bridgedToken(), recipient, amount);
    }
}