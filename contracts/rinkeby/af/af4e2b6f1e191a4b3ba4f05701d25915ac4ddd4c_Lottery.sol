/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// File: final_project1.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;

    address private _owner;

    uint256 public entranceFee; 
    
    uint256 public players_num; 

    modifier onlyOwner()
    {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

    enum STATUS {
        open,
        closed,
        compute
    }

    STATUS public status;

    constructor() {
        status = STATUS.closed;
        _owner = msg.sender;
    }

    function enter() public payable{
        require(status == STATUS.open, "Bets not started!");
        require(msg.value == entranceFee, "Insufficient bet amount");
        players.push(msg.sender);
        players_num++;
    }

    function startLottery(uint256 _entranceFee) public onlyOwner{
        require(status == STATUS.closed, "Betting has started!");
        status = STATUS.open;
        entranceFee = _entranceFee;
    }

    function endLottery() public onlyOwner{
        status =  STATUS.compute;
        uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
        recentWinner = players[indexOfWinner];
        payable(recentWinner).transfer(address(this).balance);
        delete players;
        status = STATUS.closed;
        players_num = 0;
    }
}