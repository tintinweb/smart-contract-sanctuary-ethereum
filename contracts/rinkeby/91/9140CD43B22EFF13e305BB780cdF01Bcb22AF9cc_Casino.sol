// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "./Killable.sol";

contract Casino is Killable {
    event Play(address payable indexed player, uint256 betSize, uint8 betNumber, uint8 winningNumber);
    event Payout(address payable winner, uint256 payout);

    function fund() external payable {}

    function bet(uint8 number) external payable {
        require(msg.value <= getMaxBet(), "Bet amount can not exceed max bet size");
        require(msg.value > 0, "A bet should be placed");

        uint8 winningNumber = generateWinningNumber();
        emit Play(payable (msg.sender), msg.value, number, winningNumber);

        if (number == winningNumber) {
            payout(payable (msg.sender), msg.value * 10);
        }
    }

    function getMaxBet() public view returns (uint256) {
        return address(this).balance / 100;
    }

    function generateWinningNumber() internal view returns (uint8) {
        return uint8(block.number % 10 + 1); // Don't do this in production
    }

    function payout(address payable winner, uint256 amount) internal {
        assert(amount > 0);
        assert(amount <= address(this).balance);

        winner.transfer(amount);
        emit Payout(winner, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

contract Killable {
    address payable public owner;

    constructor() {
        owner = payable (msg.sender);
    }

    function kill() external {
        require(msg.sender == owner, "Only the owner can kill this contract");
        selfdestruct(owner);
    }
}