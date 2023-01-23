// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract CallWinner {
    address winnerContract = 0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;

    function callWinner() external {
        (bool s, ) = winnerContract.call("attempt()");

        require(s);
    }
}