/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract TestSafeProxy {
  function execTransactionFromModule(
    address payable to,
    uint256 value,
    bytes calldata data,
    uint8 operation
  ) external returns (bool success) {
    if (operation == 1) (success, ) = to.delegatecall(data);
    else (success, ) = to.call{value: value}(data);
  }
}