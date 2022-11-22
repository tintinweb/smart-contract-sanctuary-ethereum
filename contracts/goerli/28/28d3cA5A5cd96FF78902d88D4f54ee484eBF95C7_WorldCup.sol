// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract WorldCup {

    error NotEnoughBeer(bool allowed);
    
    uint256 score = 0;
    bool allowed = false;

    // update a new score

    function celebrateGoal(uint256 newScore) public {

        if (!allowed) {
            revert NotEnoughBeer(allowed);
        }

        score = newScore;
    }
}