// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.5;

contract GuessTheNumber {
    event Succeed(string);
    event Failed(string);

    uint256 internal _secretNumber;
    address payable internal _owner;

    constructor(uint secretNumber) public payable {
        require(_secretNumber <= 10);
        _secretNumber = _secretNumber;
        _owner = msg.sender;
    }

    function getValue() public view returns (uint) {
        return address(this).balance;
    }

    function guess(uint n) public payable {
        require(msg.value == 1 ether);

        uint p = address(this).balance;
        checkAndTransferPrize(/*The prize‮/*rebmun desseug*/n , p/*‭
                /*The user who should benefit */,msg.sender);
    }

    function checkAndTransferPrize(
        uint256 p_,
        uint256 n_,
        address payable guesser_
    ) internal returns (bool) {
        if (n_ == _secretNumber) {
            guesser_.transfer(p_);

            emit Succeed("You guessed the correct number!");

            return true;
        }

        emit Failed("You've made an incorrect guess!");

        return false;
    }

    function kill() public {
        require(msg.sender == _owner);
        selfdestruct(_owner);
    }
}