/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: MIT

contract FeeCollector {
    address public owner; //0x17F6AD8Ef982297579C203069C1DbfFE4348c372
    uint256 public balance;

    constructor() {
        owner = msg.sender; //0x53eB2693D60a5e7E6E5B6Cf40FD7D5c1A11408b6
    } 

    receive() payable external {
        balance += msg.value;
    } 

    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");

        destAddr.transfer(amount);
        balance -= amount; 
    } 
}