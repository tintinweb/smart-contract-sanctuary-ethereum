/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

//SPDX-License-Identifier: NO LICENSE
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Hacking_coinFlip {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you're not the owner");
        _;
    }

    function sendMultipleTransactions(address payable alice) public onlyOwner() {
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
        alice.transfer(1000000);
}
}