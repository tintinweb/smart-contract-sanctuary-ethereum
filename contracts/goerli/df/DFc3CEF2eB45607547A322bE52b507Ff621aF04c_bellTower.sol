/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

pragma solidity ^0.8.7;
contract TestContract{
    //some logic
}

contract bellTower{
    //计数器，记录敲了多少次钟
    uint public bellRung;

    //事件，记录谁敲了钟
    event BellRung(uint rangForTheNthTime, address whoRangIt);

    function ringTheBell() public{
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}