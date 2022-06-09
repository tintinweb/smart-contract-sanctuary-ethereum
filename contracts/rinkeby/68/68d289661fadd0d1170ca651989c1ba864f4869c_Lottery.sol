/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: finalproject1.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;

    address private _owner;

    uint256 public entranceFee;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    enum STATE {
        START,
        CALCULATING,
        CLOSED
    }

    STATE public LOTTERY_STATE;

    constructor() {
        LOTTERY_STATE = STATE.CLOSED;
        _owner = msg.sender;
    }

    function enter() public payable {
        require(LOTTERY_STATE == STATE.START, "Lottery is closed now.");
        require(msg.value >= entranceFee, "Your entrance fee isn't enough.");
        players.push(msg.sender);
    }

    function startLottery(uint256 _fee) public onlyOwner {
        require(LOTTERY_STATE == STATE.CLOSED, "Lottery already started.");
        LOTTERY_STATE = STATE.START;
        entranceFee = _fee;
    }

    function endLottery() public onlyOwner {
        LOTTERY_STATE = STATE.CALCULATING;
        uint256 indexOfWinner = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.difficulty, block.timestamp) 
            )
        ) % players.length;
        recentWinner = players[indexOfWinner];
        payable(recentWinner).transfer(address(this).balance);
        delete players;
        LOTTERY_STATE = STATE.CLOSED;
    }
}