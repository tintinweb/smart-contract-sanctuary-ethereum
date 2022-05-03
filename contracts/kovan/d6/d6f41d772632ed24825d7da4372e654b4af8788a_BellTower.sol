/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract TestContract {

}

contract BellTower{
    uint public bellRung;

    event BellRung(uint rangForTheTime, address whoRangIt);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}