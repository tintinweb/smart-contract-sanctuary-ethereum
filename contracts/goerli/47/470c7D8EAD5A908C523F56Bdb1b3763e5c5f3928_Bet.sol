// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Bet {

    address payable public owner;
    uint public randomNumber;
    uint256 public betId;
    mapping(uint256 => Result) public results;

    struct Result {
        uint256 id;
        uint256 bet;
        uint256 amount;
        address payable player;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    event Win(uint256 id, uint256 bet, uint256 randomNumber, uint256 amount, address player, uint256 time);
    event Lose(uint256 id, uint256 bet, uint256 randomNumber, uint256 amount, address player, uint256 time);
    event Received(address indexed _from, uint256 _amount);
    event Withdraw(address indexed _from, address _to, uint256 _amount);
    //function that generates random number;
    function randomNumberGenerator() internal returns (uint){
        randomNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100);
        resultBet(randomNumber);
        return randomNumber;
    }

    function roll(uint bettorNumber) external betRole(bettorNumber) payable returns (uint) {

        require(msg.sender.balance > 0, "Error, msg.value must be greater than 0");
        results[betId] = Result(betId, bettorNumber, msg.value, payable(msg.sender));
        randomNumber = randomNumberGenerator();
        betId += 1;
        return randomNumber;
    }


    function resultBet(uint random) internal returns (bool) {
        uint winAmount = 0;
        if (random < results[betId].bet) {
            // winAmount that calculates how much money the user will earn;
            winAmount = ((981000 / results[betId].bet) * msg.value) / 10000;
            results[betId].player.transfer(winAmount);
            emit Win(results[betId].id, results[betId].bet, randomNumber, winAmount, results[betId].player, block.timestamp);
            return true;
        }
        emit Lose(results[betId].id, results[betId].bet, randomNumber, winAmount, results[betId].player, block.timestamp);

        return true;
    }

    function withdraw(uint amount) public onlyOwner returns (bool){
        require(address(this).balance >= amount, "your amount must be equal contract balance or greater than contract balance");
        payable(msg.sender).transfer(amount);
        emit Withdraw(address(this), msg.sender, amount);
        return true;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner");
        _;
    }

    modifier betRole(uint bettorNumber) {
        require(bettorNumber > 0, "your number must be greater than 0");
        require(bettorNumber < 97, "your number must be smaller than 97");
        _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}