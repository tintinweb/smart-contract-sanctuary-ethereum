/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

pragma solidity ^0.8.18;

contract BellRinger {
    uint public bellRung;

    event BellRung(uint rang, address whoRang);

    function ringTheBell() public {
        bellRung++;

        emit BellRung(bellRung, msg.sender);
    }
}