/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.8.7;

contract KingOfFools {
    address public prevDepositor;
    uint public prevAmount;

    uint constant DIVISION = 10 ** 10;
    
    receive() external payable {
        if (prevDepositor != address(0x0) && msg.value >= prevAmount * 15 * DIVISION / 10 / DIVISION) {
            (bool sent,) = prevDepositor.call{value: msg.value}("");
            require(sent, "Failed to send error");
        }

        prevDepositor = msg.sender;
        prevAmount = msg.value;
    }
}