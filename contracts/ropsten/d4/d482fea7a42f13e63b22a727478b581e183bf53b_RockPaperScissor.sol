/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity ^0.4.26;

contract RockPaperScissor {
    struct Games{
        address maker;
        string betType;
        uint betAmount;
        bool gameMatched;
    }
    uint maxBet = 5000000000000000;
    uint minBet = 1000000000000000;
    uint fee    = 50000000000000;
    address manager;

    Games[] public games;

    constructor() public {
        manager = msg.sender;
    } 

    function createGame(string memory betType) public payable {
        require(msg.value >= minBet && msg.value <= maxBet, "Bet amount allow only between 0.001 and 0.005");
        string memory paper = "P";
        string memory rock  = "R";
        string memory scissor = "S";
        require(keccak256(bytes(betType)) == keccak256(bytes(paper)) || keccak256(bytes(betType)) == keccak256(bytes(rock)) || keccak256(bytes(betType)) == keccak256(bytes(scissor)));
        Games memory new_game = Games(msg.sender, betType, msg.value, false);
        games.push(new_game);
    }

    function countGame() public view returns (uint) {
        return games.length;
    }

    function getGames(uint gameId) public view returns (address , string memory, uint, bool){
        return (games[gameId].maker , games[gameId].betType, games[gameId].betAmount, games[gameId].gameMatched);
    }

    function matchGame(uint gameId, string memory betType) public payable returns (string memory) {
        require(msg.value == games[gameId].betAmount, "Bet amount must be equal to maker");
        require(games[gameId].gameMatched == false, "This game already matched");
        uint winnerAmount = (msg.value * 2) - (fee*2);
        uint drawAmount   = msg.value - fee;

        // draw
        if(keccak256(bytes(betType)) == keccak256(bytes(games[gameId].betType))){
            
            games[gameId].maker.transfer(drawAmount);
            msg.sender.transfer(drawAmount);
            games[gameId].gameMatched = true;
            return 'draw';
        }

        // win
        string memory paper = "P";
        string memory rock  = "R";
        string memory scissor = "S";
        if(keccak256(bytes(betType)) == keccak256(bytes(paper)) && keccak256(bytes(games[gameId].betType)) == keccak256(bytes(rock))){
            msg.sender.transfer(winnerAmount);
            return 'You win by Paper over Rock';
        }
        if(keccak256(bytes(betType)) == keccak256(bytes(rock)) && keccak256(bytes(games[gameId].betType)) == keccak256(bytes(scissor))){
            msg.sender.transfer(winnerAmount);
            return 'You win by Rock over Scissor';
        }
        if(keccak256(bytes(betType)) == keccak256(bytes(scissor)) && keccak256(bytes(games[gameId].betType)) == keccak256(bytes(paper))){
            msg.sender.transfer(winnerAmount);
            return 'You win by Scissor over Paper';
        }

        // loose
        if(keccak256(bytes(betType)) == keccak256(bytes(rock)) && keccak256(bytes(games[gameId].betType)) == keccak256(bytes(paper))){
             games[gameId].maker.transfer(winnerAmount);
            return 'You loose by Rock with paper';
        }
        if(keccak256(bytes(betType)) == keccak256(bytes(scissor)) && keccak256(bytes(games[gameId].betType)) == keccak256(bytes(rock))){
             games[gameId].maker.transfer(winnerAmount);
            return 'You loose by Scissor with Rock';
        }
        if(keccak256(bytes(betType)) == keccak256(bytes(paper)) && keccak256(bytes(games[gameId].betType)) == keccak256(bytes(scissor))){
             games[gameId].maker.transfer(winnerAmount);
            return 'You loose by Paper with Scissor';
        }
    }

    function getSmartContractAmount() public view returns (uint) {
        return address(this).balance;
    }

    function transferFeeToOwner() public returns (uint) {
        require(msg.sender == manager,'You are not manager');
        manager.transfer(address(this).balance);
    }

}