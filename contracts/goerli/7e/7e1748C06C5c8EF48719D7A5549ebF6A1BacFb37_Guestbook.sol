/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Guestbook
 * @dev Store & retrieve a list of guest names
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Guestbook {
  event AddedGuest(string message, string guestName);
  string[] guests;
  function signBook(string memory guestName) public {
    guests.push(guestName);
    emit AddedGuest("New guest!", guestName);
  }
  function getNames() public view returns (string[] memory) {
    return guests;
  }
}