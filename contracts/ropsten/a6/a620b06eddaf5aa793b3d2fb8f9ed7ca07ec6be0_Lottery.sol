// SPDX-License-Identifier: MIT
// gabl22 @ github.com

pragma solidity >=0.8.0 <0.9.0;

import "./TimeRandom.sol";
import "./Ownable.sol";

contract Lottery is Ownable {

    using TimeRandom for TimeRandom.Random;

    TimeRandom.Random private generator = TimeRandom.Random({
        _last: 2*3*5*7*11*13*17*19*23*29*31*37*41*43*47*53*59*61*67*71 + 1
    });

    function betOn(uint min, uint bet, uint max) external payable returns(bool) {
        require(min <= bet && bet <= max, "Number out of range");
        require(min != max, "Range can't be empty");
        if(TimeRandom.random(generator.nextSeed(), min, max) == bet) {
            uint prize = (max - (min + 1)) * msg.value;
            address winner = tx.origin;
            if(balance() < prize) {
                prize = balance();
            }
            payable(winner).transfer(prize);
            return true;
        }
        return false;
    }
    
    function balance() public view returns(uint) {
        return address(this).balance;
    }
}