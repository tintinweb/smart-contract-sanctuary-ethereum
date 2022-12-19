/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SexyLotto {
    address public manager;
    mapping(address => uint256) public playersPrize;
    bool entry = false;
    address[] public winners;
    uint256[] public prize;
    address[] public tickets;
    uint256 public prizePool;
    uint256 public managerFee = 1;
    uint256 public managerPool;

    // uint public ticketLimit = 1;
    uint256 public ticketCost = 0.0001 ether;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager{
        require(msg.sender == manager,"Not Authorized");
        _;
    }

    function ticketsCount() public view returns (uint256) {
        return uint256(tickets.length);
    }

    function winnersCount() public view returns (uint256) {
        return uint256(winners.length);
    }

    function getTicket() public payable {
        require(msg.value >= ticketCost, "error");
        prizePool += (msg.value - ((msg.value * managerFee) / 100));
        managerPool += ((msg.value * managerFee) / 100);
        tickets.push(msg.sender);
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, tickets)
                )
            );
    }

    function pickWinner() public onlyManager {
        require(
            tickets.length >= 5,
            "tickets must be more than 5"
        );
        uint256 index = random() % tickets.length;
        playersPrize[tickets[index]] += prizePool;
        winners.push(tickets[index]);
        prize.push(prizePool);
        delete tickets;
        prizePool = 0;
    }

    function claim(uint256 amount) public {
        require(!entry);
        entry = true;

        require(
            amount <= playersPrize[msg.sender],
            "The prize balance must be more than the amount for claim"
        );
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);

        playersPrize[msg.sender] -= amount;

        entry = false;
    }

    function managerClaim(uint256 amount) public onlyManager {
        require(
            amount <= managerPool,
            "The Manager balance must be more than the amount for claim"
        );
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
        managerPool -= amount;
    }

    /// only manager
    function setNewManager(address newManager) public onlyManager {
        manager = newManager;
    }

    function setCost(uint256 newCost) public onlyManager {
        ticketCost = newCost;
    }

    function setFee(uint256 newFee) public onlyManager {
        managerFee = newFee;
    }

    /// for test

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint256 amount) public onlyManager {
        require(
            amount <= address(this).balance,
            "The balance must be more than the amount for withdraw"
        );
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

}