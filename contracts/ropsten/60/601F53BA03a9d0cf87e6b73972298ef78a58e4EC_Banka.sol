/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Banka {
    address AUSD = 0x497FD7e287F1c46925db489197de1ECd1CEa2BA9;
    uint time;
    uint private highestBid;
    address private winner;
    uint private sum;
    struct Winnerss {
        address addr;
        uint SumWin;
        uint time;
    }
    Winnerss[] public Winners;
    struct Player {
        address addres;
        uint sumOfBet;
        uint timeOfBet;
    }
    Player[] public players;
    IERC20 token = IERC20(AUSD);
    
    function start(uint Sum) public  {
        require(time<block.timestamp, "Game already started");
        require(Sum>0, "Value need to be higher than 0");
        if (sum > 0) {
            Winners.push(Winnerss(winner, sum, block.timestamp));
            token.transfer(winner, sum);
            token.transferFrom(msg.sender, address(this), Sum);
            time = block.timestamp + 99;
            highestBid = Sum;
            sum = Sum;
            winner = msg.sender;
            delete players;
            players.push(Player(msg.sender, Sum, block.timestamp));
        }
        else {
            token.transferFrom(msg.sender, address(this), Sum);
            time = block.timestamp + 99;
            highestBid = Sum;
            sum = Sum;
            winner = msg.sender;
            delete players;
            players.push(Player(msg.sender, Sum, block.timestamp));
        }
    }
    function makeNewBet(uint Sum) public  {
        require(time>block.timestamp, "Game already ended, start new please");
        require(Sum>highestBid, "Value need to be higher than highestBid");
        token.transferFrom(msg.sender, address(this), Sum);
        highestBid = Sum;
        time = block.timestamp + 99;
        sum = sum + Sum;
        winner = msg.sender;
        players.push(Player(msg.sender, Sum, block.timestamp));
    }
    function timeLeft() public view returns(uint TimeLeft) {
        require(time>block.timestamp, "Game already ended");
        return TimeLeft = time - block.timestamp;
        
    }
    function withdraw() public {
    require(time<block.timestamp, "Game still going");
    require(msg.sender == winner, "You are not winner");
    Winners.push(Winnerss(winner, sum, block.timestamp));
    token.transfer(winner, sum);
    sum = 0;
    delete players;
    }
    function lastWiner() public view returns(address) {
        require(time<block.timestamp, "Game still going");
        return winner;
    }
    function HighestBid() public view returns(uint) {
        return highestBid/1000000000000000000;
    }
    function SumOf() public view returns(uint) {
        return sum/1000000000000000000;
    } 
}