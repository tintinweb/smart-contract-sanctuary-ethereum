// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Lottery {

    address internal manager;
    address payable[] internal participants;
    uint private minParticipants;
    address payable internal winner;
    bool locked;
    // uint private lotteryTime;

    event BuyLottery(address buyer, uint _time);
    event DrawLottery(address winner, uint rewardAmount, uint _time);

    // modifier clearWinner() {
    //     _;
    //     winner = payable(address(0x0));
    // }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        manager = msg.sender;
        minParticipants = 2;
        locked = false;
        // lotteryTime = block.timestamp + drawTime;
    }

    receive() external payable {

    }

    function buyLottery() payable public noReentrant {
        require(msg.value == 1 ether, "The amount for lottery ticket is invalid!");
        participants.push(payable(msg.sender));
        emit BuyLottery(msg.sender, block.timestamp);
    }

    function getTotalBalance() public view returns (uint totalAmount) {
        assert(msg.sender == manager);
        return address(this).balance;
    }

    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, participants.length)));
    }

    function selectWinner() public noReentrant returns (address) {
        require(msg.sender == manager, "Not the right to call lottery end!");
        uint len = participants.length;
        require(minParticipants <= len, "Not the desired number of participants!");
        uint index = (random() % len);
        winner = participants[index];
        uint amount = getTotalBalance();
        (bool sent, ) = winner.call{value: amount}("");
        require(sent, "Unable to transfer reward to winner!");
        participants = new address payable[] (0);
        emit DrawLottery(winner, amount, block.timestamp);
        return address(winner);
    }

    function setMinParticipants(uint _number) external {
        assert(msg.sender == manager);
        minParticipants = _number;
    }

    function getTotalParticipants() external view returns (uint) {
        return participants.length;
    }

    function getParticipants() external view returns (address payable[] memory) {
        return participants;
    }

    function getMinParticipants() external view returns (uint) {
        return minParticipants;
    }

    function getWinner() external view returns (address) {
        return winner;
    }

}