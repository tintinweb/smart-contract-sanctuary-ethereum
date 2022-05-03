/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity >= 0.7;

contract Ping {

    receive() external payable {
        payable(msg.sender).send(address(this).balance);
    }

}