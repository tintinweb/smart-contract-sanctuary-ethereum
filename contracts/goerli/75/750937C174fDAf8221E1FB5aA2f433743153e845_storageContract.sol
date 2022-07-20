pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract storageContract {

  event SetPurpose(address sender, string purpose);

  string public purpose = "Purposeful Action!";

  constructor() payable {
    // what should we do on deploy?
  }

  function setPurpose(string memory newPurpose) public {
      purpose = newPurpose;
      emit SetPurpose(msg.sender, purpose);
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}