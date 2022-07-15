// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ChildContract.sol";

contract ParentContract {
    ChildContract public child;
    uint public num;

    constructor() {
        child = new ChildContract();
    }

    function store(uint _num) public {
        num = _num;
    }

    function getChildOwner() public view returns (address) {
        return child.owner();
    }

    function childStore(uint _num) public {
        child.store(_num);
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
}