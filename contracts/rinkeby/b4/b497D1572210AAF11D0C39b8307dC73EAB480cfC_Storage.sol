/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

/* 
This is the smart contract to simple save data in storage
*/
// SPDX-License-Identifier: MIT
// dappsar: 2022
pragma solidity >=0.6.0 <0.9.0;

contract Storage{

  address payable internal owner;
  string private data;

  event DataSetted();
 
 
  constructor () public
  {
    owner = payable(msg.sender);
  }

  // This modifier is used to check if the sender of the function call is the owner.
  modifier onlyOwner()
  {
    require(msg.sender==owner);
    _;
  }

  function set(string memory newData) public {
    data = newData;
    emit DataSetted();
  }

  function get() public view returns (string memory _data) {
    return data;
  }

  function getVersion() public pure returns (string memory _version) {
    return "1.0";
  }

  function destroySmartContract() public onlyOwner {
    selfdestruct(owner);
  }

}