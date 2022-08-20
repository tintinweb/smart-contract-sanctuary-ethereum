pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract YourContract {

  event SetPurpose(address sender, string purpose);

  string public purpose = "Building Unstoppable Apps!!";

  constructor() payable {
  }

  function setPurpose(string memory newPurpose1) public {
      purpose = newPurpose1;
      emit SetPurpose(msg.sender, purpose);
  }

  // to support receiving ETH by default
  receive() external payable {}
  fallback() external payable {}
}