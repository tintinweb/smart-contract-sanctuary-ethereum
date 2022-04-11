// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Killable.sol";


contract Counter is Killable {
    uint256 constant NUM = 1234;
    uint256 public number;

    constructor() {
        number = 100;
    }

    function add() public {
        number = number + 1;
    }

    function put(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256){
        uint256 n = this.number();
        return n;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;


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