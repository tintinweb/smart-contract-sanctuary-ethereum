// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

    error RPC__LowBet();
    error RPC_GameEnded();
    error RPC__NotPlayer();
    error RPC__ZeroAddress();
    error RPC__ZeroAmmount();
    error RPC__IncorrectBet();
    error RPC__TransactionFailed();


contract RPC {
    event GameCreated(address indexed player1,address indexed player2, Game indexed game);
    event GameComplete(address indexed player1,address indexed player2,Game indexed game);
    event GameMove(address indexed player1,address indexed player2,Game indexed game,uint move);

    uint private constant PERCISION=10000;
    uint private constant FEE = 4950;

    struct Game {
        address winner;
        uint startTime;
        uint bet;
        uint gameID;
        uint fBet;
        uint sBet;
    }

    mapping(address => mapping(address=>uint)) private count;
    mapping(address => mapping(address=>mapping(uint=>Game))) private  game;

    function createGame(address secondPlayer) external payable {
        if(msg.value == 0){revert RPC__LowBet();}
        _checkAddressAndAmmount(secondPlayer,msg.value);
      
        count[msg.sender][secondPlayer] +=1;
        uint conter = count[msg.sender][secondPlayer];

        Game storage newGame = game[msg.sender][secondPlayer][conter];

        newGame.bet = msg.value;
        newGame.gameID = conter;
        newGame.startTime = block.timestamp;
       
        emit GameCreated(msg.sender,secondPlayer, newGame);
    }

    function makeMove(address fBetter,address sBetter,uint move) external payable {
        _checkAddressAndAmmount(fBetter,1);
        _checkAddressAndAmmount(sBetter,msg.value);

        uint gameID = count[fBetter][msg.sender];
        Game storage currentGame = game[fBetter][msg.sender][gameID];

        if(currentGame.startTime == 0) {revert RPC_GameEnded();}
        if(msg.sender == fBetter){
            if(msg.value!=0){revert RPC__IncorrectBet();}
            game[msg.sender][sBetter][gameID].fBet = move;       
        }
        else if(msg.sender == sBetter){
            game[fBetter][msg.sender][gameID].sBet = move;
            _checkIfBetsMatch(currentGame, msg.value);
        }
        else{revert RPC__NotPlayer(); }

        
        if(currentGame.fBet != 0 && currentGame.sBet != 0){
          _checkWinner(currentGame,fBetter,sBetter);    
        }

    }
    
    function _checkWinner(Game storage _game,address _first,address _second) internal {
        uint firstBet = _game.fBet;
        uint secondBet = _game.sBet;
        uint betAmount = _game.bet;
        address winner;

        if(firstBet==secondBet){winner =address(0);}

        else if (firstBet == 1 && secondBet == 3) {winner = _first;} 
        else if (firstBet == 2 && secondBet == 1) {winner = _first;}
        else if (firstBet == 3 && secondBet == 2) {winner = _first;}

        else if (firstBet == 1 && secondBet == 2) {winner = _second;}  
        else if (firstBet == 2 && secondBet == 3) {winner = _second;}  
        else if (firstBet == 3 && secondBet == 1) {winner = _second;}

        _game.winner = winner;
        _game.startTime = 0;

        if (winner == address(0x0)) {
            (bool success1,) = _first.call{ value: (betAmount * PERCISION)/FEE }("");
            (bool success2,) = _second.call{ value: (betAmount * PERCISION)/FEE}("");
            if(!success1 && !success2){ revert RPC__TransactionFailed();}
            emit GameComplete(_first,_second,_game);
        }
        else{
            (bool success,) = winner.call{ value: betAmount }("");
            if(!success){revert RPC__TransactionFailed();}
            emit GameComplete(_first,_second,_game);
        } 

    }

    /////////////////////
    //Internal Function//
    /////////////////////
    function _checkAddressAndAmmount(address player,uint amount) internal pure {
        if(player == address(0)) revert RPC__ZeroAddress();
        if(amount == 0) revert RPC__ZeroAmmount();
    }
    function _checkIfBetsMatch(Game memory _game,uint amount) internal  {
        uint bet = _game.bet;
        if(bet > amount){    
            revert RPC__IncorrectBet();
        }
        
        else if(bet < amount){
            (bool success,) = msg.sender.call{ value: amount-bet }("");
            if(!success) {revert RPC__TransactionFailed();}
        }
    }
    ////////////////////
    //Getter Functions//
    ////////////////////
    function getGame(address player1,address player2,uint gameID) public view returns(Game memory){
        return game[player1][player2][gameID];
    }
    function getCounter(address player1,address player2) public view returns(uint){
        return count[player1][player2];
    }

    
}