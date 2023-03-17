/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract FamilyAgreement {

uint public minAmount = 1 ether;
address[] public funders;
mapping(address => uint) public amounts;
uint public countOfFunders;
uint public currentlyFunded;
address public immutable addressOfAReceiver;

constructor() {
    addressOfAReceiver = msg.sender;
}

function setNumberOfFunders(uint number) public
{
    countOfFunders = number;
}

function setMinAmount(uint minimum) public
{
    minAmount = minimum;
}

function fund() public payable {
    require(msg.value >= minAmount, "You need to send more ETH!");

    amounts[msg.sender] = msg.value;
    funders.push(msg.sender);
    currentlyFunded++;
}

function withdraw() public {
    require(amounts[msg.sender] > 0, "There are no funds!");
    require(countOfFunders > currentlyFunded, "All of the participants sent the money!");

    uint valueToWithdraw = amounts[msg.sender];

    currentlyFunded--;
    amounts[msg.sender] = 0;

    (bool sent,) = msg.sender.call{value: valueToWithdraw}("");
    require(sent, "Failed to withdraw");
}

function receiverWithdraw() public {
    require(msg.sender == addressOfAReceiver, "Not a receiver");
    require(countOfFunders == currentlyFunded, "Not all of the participants paid!");

    for (uint i=0; i<funders.length; i++) {
        amounts[funders[i]] = 0;
    }
    delete funders;
    currentlyFunded = 0;

    (bool sent,) = addressOfAReceiver.call{value: address(this).balance}("");
    require(sent, "Failed to withdraw");
}
}