/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// File: contracts/BetBasic.sol



pragma solidity ^0.8.0;

struct Game{
    uint256 idGame;
    uint256 totalOptionA;
    uint256 totalOptionB;
    uint256 total;
    uint256 limitTime;
    uint8 optionA;
    uint8 optionB;
    uint8 winner;
}

contract BetBasic {

    address public owner;
    Game[] public games;
    uint256 private counterId;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256 ))) public amountUser;  
    // idBet -> option -> user -> amountUser
  
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    function createGame(uint256 _hours, uint256 _minutes) public onlyOwner {
        Game memory game;
        game.limitTime = block.timestamp + _hours * 1 hours + _minutes * 1 minutes;
        game.idGame = counterId ++;
        games.push(game);
    }

    function setWinner(uint256 _idGame, uint8 _winner) public onlyOwner  {
        require(finishedBet(_idGame) == true);
        require(_winner == 1 || _winner == 2);
        Game storage game = games[_idGame];
        game.winner = _winner;
    }
    
    function bet(uint256 _idGame, uint8 _option) public payable {
        require(finishedBet(_idGame) == false);
        require(_option == 1 || _option == 2);
        Game storage game = games[_idGame];

        amountUser[_idGame][_option][msg.sender] += msg.value;

        if(_option == 1) 
            game.totalOptionA += msg.value;
        else 
            game.totalOptionB += msg.value;
    }

    function claimReward(uint256 _idGame) public {
        require(finishedBet(_idGame) == true);
        Game storage game = games[_idGame];

        game.total = game.totalOptionA + game.totalOptionB;
        uint8 _optionWinner = game.winner;
        uint256 totalWinner;

        if(game.winner == game.optionA) 
            totalWinner = game.totalOptionA;
        else 
            totalWinner = game.totalOptionB;

        uint256 bettedAmount = amountUser[_idGame][_optionWinner][msg.sender];
        uint256 owedAmount = (bettedAmount * game.total) / totalWinner;
       
        require(owedAmount > 0, "Nothing is owned to you");
        (bool successOwner, ) = owner.call{value: owedAmount / 10}("");
        (bool successUser, ) = msg.sender.call{value: (owedAmount * 9) / 10}("");
        require(successOwner == true && successUser == true, "Transaction failed");

        amountUser[_idGame][_optionWinner][msg.sender] = 0;
    }

    function finishedBet(uint256 _idGame) private view returns(bool){
        if(block.timestamp >= games[_idGame].limitTime)
            return true;
        return false;
    }

    receive() external payable {}
}