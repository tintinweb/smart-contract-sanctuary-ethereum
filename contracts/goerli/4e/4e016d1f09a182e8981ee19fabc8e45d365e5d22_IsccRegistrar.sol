/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0 <0.9.0;
/// @title ISCC-REGISTRAR v1.3

interface IsccHub {
  function announce (string calldata _iscc, string calldata _url, string calldata _message) external;
}

contract IsccRegistrar {

   address public hub;

   constructor(address _hub) {
      hub = _hub;
   }

   function declare(string calldata iscc, string calldata url, string calldata message) public {
      IsccHub(hub).announce(iscc, url, message);
   }
}