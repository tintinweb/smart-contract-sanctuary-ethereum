/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract PublicRelay {
function relay(address payable _dest, bytes calldata _packet) external payable {
  _dest.call{value: msg.value}(_packet);
  }
}