// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// This contract allows the user to make transactions that can be copied by a generalized-searcher bot
// Do not use in mainnet unless you want to be rekt
// This is only for testing your own mev  bots
contract Victim {
    // Payable constructor, allows us to send some eth to this contract upon deployment
    address owner;

    constructor() payable {
        owner = msg.sender;
    }

    // Withdraw. Allows anyone to withdraw any amount to their own address
    function blablafunction123(uint256 amount) external {
        payable(msg.sender).transfer(amount);
    }

    // Withdraw. Allows anyone to withdraw any amount to any address
    function some1Random1Function1(uint256 amount, address payable recipient) external {
        recipient.transfer(amount);
    }

    //Withdraw but with guard
    function withdrawWithGuard(uint256 amount) external {
        require(msg.sender == owner);
        payable(msg.sender).transfer(amount);
    }

    //Withdraw but with guard
    function withdrawWithGuardForAccount(uint256 amount, address payable recipient) external {
        require(msg.sender == owner);
        recipient.transfer(amount);
    }

    receive() external payable {}
}