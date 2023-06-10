// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Lottery.sol";

contract LotteryCreator {
    
    mapping(uint256 => Lottery) lotteries;
    uint256 private id;

    function createLottaryContract(uint256 minimunEntrence, uint256 endingDate) public {
        id++;
        Lottery lottery = new Lottery(id, minimunEntrence, endingDate);
        lotteries[id] = lottery;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lottery {

    uint256 id;
    uint256 public minimunEntrence;
    uint256 public endingDate;
    uint256 public winningAmount;
    address public owner;
    mapping(address => uint256) public participents;
    address[] public players;

    constructor(uint256 _id, uint256 _minimunEntrence, uint256 _endingDate) {
        require(_minimunEntrence >= 1, "Increase minimun entrence");
        require(_endingDate > block.timestamp, "Increase ending date");
        id = _id;
        minimunEntrence = _minimunEntrence;
        endingDate = _endingDate;
        winningAmount = 0;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyActive() {
        require(endingDate > block.timestamp, "Lottery not active");
        _;
    }

    function enter() public payable onlyActive{
        require(msg.value >= minimunEntrence, "Not enough to enter");
        participents[msg.sender] = msg.value;
        players.push(msg.sender);
        winningAmount += msg.value;
    }

    function pickWinner() public onlyOwner {
        // require(endingDate < block.timestamp, "Lottery should end");
        uint256 amount = winningAmount;
        uint256 randomNum = random(players.length);
        address winner = players[randomNum];
        winningAmount = 0;
        (bool success, ) = payable(winner).call{value: amount}("");
        require(success, "Not successful");
    }
    
    function random(uint number) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.prevrandao,  
        msg.sender))) % number;
    }
}