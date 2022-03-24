// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract Dice{

    address s_owner;

    constructor(){
        s_owner = msg.sender;
    }

    struct Bet {
        uint8 currentBet;
        bool isBetSet;
        uint256 destiny;
        uint256 amount;
    }

    mapping(address => Bet) private bets;

    event NewBetIsSet(address bidder, uint8 currentBet, uint256 amount);
    event GameResult(address bidder, uint8 currentBet , uint256 destiny);

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }

    function roll() public {
        require(bets[msg.sender].isBetSet == true);
        bets[msg.sender].isBetSet = false;
        bets[msg.sender].destiny = random();
        if(bets[msg.sender].destiny == bets[msg.sender].currentBet){
            payable(msg.sender).transfer(bets[msg.sender].amount * 5);
        }
        emit GameResult(msg.sender, bets[msg.sender].currentBet, bets[msg.sender].destiny);
    }

    function random() internal view returns(uint256){
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));

        return (seed % 6) + 1;
    }

    function getNewBet(uint8 betNumber) public payable returns(uint256) {
        require(bets[msg.sender].isBetSet == false);
        require(msg.value > 1 wei);
        bets[msg.sender].isBetSet = true;
        bets[msg.sender].currentBet = betNumber;
        bets[msg.sender].amount = msg.value;
        emit NewBetIsSet(msg.sender, betNumber, msg.value);
        return bets[msg.sender].currentBet;
    }

    function isBetSet() public view returns(bool) {
        return bets[msg.sender].isBetSet;
    }

    function betOf(address owner) external view returns(uint256) {
        require(bets[owner].isBetSet == true);
        return bets[owner].currentBet;
    }

    function withdraw(uint256 amount) onlyOwner public {
        payable(s_owner).transfer(address(this).balance);
    }

    receive() external payable {

    }

    fallback() external payable {

    }
}