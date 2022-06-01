/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

//increase minimum to 10 for ksx compatibility/////
//make so everybody must input same amount for fairness////
//also maybe switch to sherpuppy, switch to token
//allow way for users to pick numbers-----in future, not now
///can get as many entrants as you want///
//create way to view balance of lottery contract////////
///way for jackpot to build up and build up, not always have a winner
///way for users to call pickWinner function, but only at a certain time, makes it more decentralized////
///now make so new lottery starts, and time starts over

///start lottery function////
///restart///
///add view lottery start time////
////add fee for dev///

///done just need front end///



pragma solidity ^0.4.17;

contract Lottery {
    address public manager;
    address[] public players;
    uint public lotteryTime;
    bool lotteryActive;
    address public devAdd = msg.sender;
    
    
    
    function Lottery() public {
        manager = msg.sender;
    }

    function lotteryStart() public {
        lotteryActive = true;
        lotteryTime = now;
    }
    
    function enter() public payable  {
        require (lotteryActive == true, "lottery inactive");
        require(msg.value == 10 ether);
        uint256 fee = (msg.value / 100);
        devAdd.transfer(fee);
        players.push(msg.sender);
    }
    
    function checkActive() public view returns (bool) {
        return lotteryActive;
    }

    function random() private view returns (uint) {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyAfter(lotteryTime) {
        uint index = random() % players.length;
         uint256 fee = (this.balance / 100);
        devAdd.transfer(fee);
        players[index].transfer(this.balance);
        players = new address[](0);
        lotteryActive = false;
        
    }
       modifier onlyAfter(uint _time) {
      require(
         now >= _time,
         "Function called too early."
      );
      _;
    
       }
    
    function getPlayers() public view returns (address[]) {
        return players;
    }
    
    function getLotteryValue() public view returns(uint256) {
        return address(this).balance;
    }


}