// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract EasterEggClaimer {
    event Claimed(address indexed receiver, uint256 amount, string message);

    address public immutable claimer;

    constructor() payable {
        claimer = msg.sender;
    }

    /// @notice Claims `amount` of the easter egg to `receiver`
    /// @param receiver the address to which the amount will be sent
    /// @param amount can be anything up to the full balance, up to
    ///               the claimer to decide if he wants to leave some to others!
    /// @param message some nice message :)
    function claim(
        address receiver,
        uint256 amount,
        string memory message
    ) external {
        require(amount <= address(this).balance, "not enough funds");
        require(msg.sender == claimer, "not claimer");
        payable(receiver).transfer(amount);
        emit Claimed(receiver, amount, message);
    }
}