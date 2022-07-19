// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ChildContract.sol";

contract Create2Contract {
    ChildContract public child;

    function deploy() public {
        child = new ChildContract{salt: 0}();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ChildContract {
    address public owner;
    uint public num;

    constructor() {
        owner = msg.sender;
    }

    function store(uint _num) public {
        num = _num;
    }

    function destruct() public {
        selfdestruct(payable(0x111E164336e0d0A2b9554f96A2cCa80680fBA449));
    }
}