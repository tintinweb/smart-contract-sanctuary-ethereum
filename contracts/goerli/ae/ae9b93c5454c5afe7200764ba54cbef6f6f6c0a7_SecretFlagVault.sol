/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract SecretFlagVault {

  string private flag;

  constructor(string memory newFlag) public {
    flag = newFlag;
  }
}