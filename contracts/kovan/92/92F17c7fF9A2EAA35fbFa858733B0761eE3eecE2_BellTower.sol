/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.8.4;

contract BellTower{
    uint public bellRung = 0;

    event BellRung(uint rangForTheNthTime, address whoRungIt);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}