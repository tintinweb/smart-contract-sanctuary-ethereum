/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

pragma solidity ^0.8.6;

contract BellTower {

    uint public rungCounter;

    event BellRung(uint rangForTheNthTime, address whoRangIt);

    function ringTheBell() public {
        rungCounter++;

        emit BellRung(rungCounter, msg.sender);
    }

}