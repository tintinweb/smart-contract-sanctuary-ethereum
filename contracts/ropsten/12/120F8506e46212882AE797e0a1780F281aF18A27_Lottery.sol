// SPDX-License-Identifier: MIT
// gabl22 @ github.com

// Lottery 0x03 03.08.2022

pragma solidity >=0.8.0 <0.9.0;

import "./TimeRandom.sol";
import "./CashFlow.sol";

contract Lottery is CashFlow
(
    CashFlow.Config({
        publicDonations: true,
        publicCharging: true
    })
)
{

    using TimeRandom for TimeRandom.Random;

    TimeRandom.Random private generator = TimeRandom.Random({
        _last: 557940830126698960967415390
    });

   function betOn(uint min, uint bet, uint max) external payable cashFlow returns(uint) {
        require(min <= bet && bet <= max, "Error: Number out of range");
        require(min != max, "Error: Range can't be empty");
        uint _payout = prize(msg.value, min, max);
        require(_payout < balance(), "Error: Insufficient funds, consider charging!");
        if(TimeRandom.random(generator.nextSeed(), min, max) == bet) {
            address winner = tx.origin;
            payable(winner).transfer(_payout);
            return _payout;
        }
        return 0;
    }

    function prize(uint amountBet, uint min, uint max) public pure returns(uint) {
        uint range = max - min;
        return range * amountBet;
    }
    
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}