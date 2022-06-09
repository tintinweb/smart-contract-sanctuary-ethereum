/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// File: contracts/final.sol


pragma solidity ^0.8.10;

contract Lottery {
    address[] public player;
    address public winner;
    address private _owner;
    uint256 public wager;

    modifier isOwner{
        require(msg.sender == _owner, "You are not the owner of this contract!");
        _;
    }

    enum STATE{
      STOP,
      RUNNING,
      PENDING
    }

    STATE lotteryState;

    constructor(){
      lotteryState = STATE.STOP;
      _owner = msg.sender;
    }
     function getPlayerNum() public view returns (uint256) {
       return player.length;
     }

    function startLottery(uint256 fee) public {
      require(lotteryState == STATE.STOP, "The lottery is running!");
      lotteryState = STATE.RUNNING;
      require(fee > 0, "You should enter a positive number!");
      wager = fee;
    }

    function enter() payable public {
      require(lotteryState == STATE.RUNNING, "The lottery is not running!");
      require(msg.value >= wager, "Insufficient wager!");
      player.push(msg.sender);
    }

    function endLottery() public isOwner{
      require(lotteryState == STATE.RUNNING, "The lottery is not running!");
      require(getPlayerNum() > 0, "No player in the current pool!");
      lotteryState = STATE.PENDING;

      uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % player.length;
      winner = player[indexOfWinner];
      payable(winner).transfer(address(this).balance);
      delete player;

      lotteryState = STATE.STOP;
    }
}


// pragma solidity ^0.8.0;

// contract Lottery {
//     address[] public players;
//     address public recentWinner;

//     address private _owner;

//     uint256 public entranceFee;

//     modifier onlyOwner {
//       require(msg.sender == _owner, "Not contract owner");
//       _;
//     }

//     enum LOTTERY_STATE {
//       STOPPED,
//       STARTED,
//       CALCULATING
//     }

//     LOTTERY_STATE contractState;

//     constructor() {
//       contractState = LOTTERY_STATE.STOPPED;
//       _owner = msg.sender;
//     }
    
//     function getPlayerCount() public view returns (uint256) {
//       return players.length;
//     }

//     // 啟動投注 (startLottery) 由合約 owner 執行，同時設定投注金額。
//     function startLottery(uint256 fee) public {
//       require(contractState == LOTTERY_STATE.STOPPED, "Lottery is currently running, this require it to be stopped.");
//       contractState = LOTTERY_STATE.STARTED;

//       require(fee > 0, "You have to specify a positive number");

//       // 1.00000 ETH is 1 * 10 ** 18
//       // 0.00001 ETH is 1 * 10 ** (18 - 5)
//       entranceFee = fee;
//     }

//     function enter() payable public {
//       require(contractState == LOTTERY_STATE.STARTED, "Lottery is not running.");
//       require(msg.value >= entranceFee, "Insufficient funds.");
//       players.push(msg.sender);
//     }

//     function endLottery() public onlyOwner {
//       require(contractState == LOTTERY_STATE.STARTED, "Lottery is currently stopped or calculating winner.");
//       require(players.length > 0, "There is currently no player in the pool.");

//       contractState = LOTTERY_STATE.CALCULATING;

//       uint256 indexOfWinner = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))) % players.length;

//       recentWinner = players[indexOfWinner];

//       payable(recentWinner).transfer(address(this).balance);

//       delete players;

//       contractState = LOTTERY_STATE.STOPPED;
//     }
// }