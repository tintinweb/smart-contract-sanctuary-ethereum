// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./Killable.sol";


contract Counter is Killable {
    uint256 number;

    constructor() public {
        number = 100;
    }

    function add() public {
        number = number + 1;
    }

    function put(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256){
        return number;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;


abstract contract Killable {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function kill() external {
        require(msg.sender == owner, "Only the owner can kill this contract");
        selfdestruct(owner);
    }
}