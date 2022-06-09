/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: contracts/FinalProject2.sol


pragma solidity ^0.8.0;

contract Lottery {
    address[] public players;
    address public recentWinner;
    address public charity;

    address private _owner;

    uint256 public entranceFee;

    uint256 public roundPlayed;
    uint256 public accumulatedStake;
    uint256 public totalPlayersCount;

    struct Record
    {
        address winner;
        address charity;
        uint256 winnerGot;
        uint256 charityGot;
        uint256 playerCnt;
    }

    Record[] public records;

    modifier onlyOwner()
    {
        require(msg.sender == _owner, "You are not permitted to use this function.");
        _;
    }//modifier onlyOwner

    enum LOTTERY_STATE { CLOSED, STARTED, PICKING }

    LOTTERY_STATE lotteryState;

    constructor()
    {
        lotteryState = LOTTERY_STATE.CLOSED;
        _owner = msg.sender;
    }//constructor

    function startLottery(uint256 _entranceFee, address _charity) public onlyOwner
    {
        require(lotteryState == LOTTERY_STATE.CLOSED, "The lottery is already started.");
        lotteryState = LOTTERY_STATE.STARTED;
        entranceFee = _entranceFee;
        charity = _charity;
    }//startLottery
    
    function endLottery() public onlyOwner
    {
        if (players.length == 0)
        {
            lotteryState = LOTTERY_STATE.CLOSED;
            return;
        }//if

        lotteryState = LOTTERY_STATE.PICKING;

        uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;
        recentWinner = players[indexOfWinner];

        records.push(Record(
        {
            winner: recentWinner,
            charity: charity,
            winnerGot: address(this).balance * 9 / 10,
            charityGot: address(this).balance / 10,
            playerCnt: players.length
        }));
        
        accumulatedStake += address(this).balance;
        totalPlayersCount += players.length;

        (bool sendSucc, ) = payable (charity).call{value: address(this).balance / 10}("");
        (sendSucc, ) = payable (recentWinner).call{value: address(this).balance}("");
        
        delete players;
        lotteryState = LOTTERY_STATE.CLOSED;
        roundPlayed++;
    }//endLottery

    function enter() public payable
    {
        require(lotteryState == LOTTERY_STATE.STARTED, "The lottery is not started yet. Please try again later.");
        require(msg.value >= entranceFee, "Not enough money for entry fee.");
        players.push(msg.sender);
    }
}