/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// File: contracts/finalproject/final_project1.sol


pragma solidity ^0.8.0;

contract Lottery {

    address [] public players;
    address payable public recentWinner;
    address public owner;

    uint256 public entranceFee;

    enum state{
        ongoing,
        drawing,
        pause
    }
    state lotterystate;

    constructor() {
        owner = msg.sender;
        lotterystate = state.pause;
    }

    // onlyOwner Modifier
    modifier onlyOwner {
        require(owner == msg.sender, "This function can only be used by owner");
        _;
    }

    // enter function
        // 1. Check if there is ongoing lottery
        // 2. Check if entrance fee is valid
        // 3. Add sender to players array

    function enter() public payable {
        require(lotterystate == state.ongoing, "No ongoing lottery");
        require(msg.value == entranceFee, "Invalid entrance fee");
        players.push(msg.sender);
    }

    // startLottery function (Only owner can execute)
        // 1. Check if no lottery is ongoing
        // 2. Set entraceFee
        // 3. Set state to ONGOING

    function startLottery(uint256 fee) public onlyOwner{
        require(lotterystate == state.pause, "Lottery ongoing");
        entranceFee = fee;
        lotterystate = state.ongoing;
    }

    // endlottery function (Only owner can execute)
        // 1. Set state to DRAWING
        // 2. Check if any player entered
        // 3. Generate random winner
        // 4. Send prize to winner
        // 5. Clear out player array
        // 6. Set state to PAUSE 

    function endLottery() public onlyOwner {
        lotterystate = state.drawing;
        require(players.length != 0, "No player entered");
        uint256 indexOfWinner = 
            uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;

        recentWinner = payable(players[indexOfWinner]);
        (bool sent, ) = recentWinner.call{value: address(this).balance}("");
        require(sent, "send failed");
        delete players;
        lotterystate = state.pause;
    }
}