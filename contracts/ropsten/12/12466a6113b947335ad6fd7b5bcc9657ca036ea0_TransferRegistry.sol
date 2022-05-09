/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

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


contract TransferRegistry {
    event LogRegisteredTransfer(bytes32 transferFact);

    function transferERC20(
        address recipient,
        address erc20,
        uint256 amount,
        uint256 salt
    ) external {
        bytes32 transferFact = keccak256(abi.encodePacked(recipient, amount, erc20, salt));
        emit LogRegisteredTransfer(transferFact);
    }
}