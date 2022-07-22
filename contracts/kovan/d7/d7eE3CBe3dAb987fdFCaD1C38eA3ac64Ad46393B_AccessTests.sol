pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract AccessTests {
  mapping(address => string) public hasAccess;

  function giveAccess(
    string calldata encryptedMessage,
    // address[] calldata listOfAddress
    address accessAddress
  ) public {
    hasAccess[accessAddress] = encryptedMessage;
  }

  function hasAccessFunction(address accessAddress, string calldata encryptedMessage) public pure returns (uint256) {
    if (accessAddress == 0xED0262718A77e09C3C8F48696791747E878a5551) {
      return 1;
    } else {
      return 0;
    }
  }
}