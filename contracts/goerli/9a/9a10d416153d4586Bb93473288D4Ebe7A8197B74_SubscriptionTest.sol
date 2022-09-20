pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "../interfaces/ISubscriptionManager.sol";

// echo subscrption code to subscription request
// this is used for testing

contract SubscriptionTest is ISubscriptionManager {
   function subscriptionStatus(address,
      string calldata,
      string calldata,
      uint256 echoCode,
      address,
      bytes calldata) external pure returns
      (uint256 errorCode) {
      return echoCode;
  }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

// interface for subscription information
// this is intended to be a general interface to query a contract
// with arbitrary data
//
// the interface will return 0 if successful, otherwise it will
// return a user defined error code
//
// the function is declared view is looking at the status of the
// subscription should not change anything within the contract

interface ISubscriptionManager {
   function subscriptionStatus(address sender,
      string calldata dataString1,
      string calldata dataString2,
      uint256 dataInt,
      address dataAddress,
      bytes calldata dataBytes) external view returns
      (uint256 errorCode);
}