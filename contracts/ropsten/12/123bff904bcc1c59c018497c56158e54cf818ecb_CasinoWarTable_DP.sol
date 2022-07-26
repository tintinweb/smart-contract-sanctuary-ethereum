/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;

/* 
Developed By: Dhaval Patel ([email protected])
Version:v 1.1, July 26, 2022
Casino War Game overview --> 
    https://www.youtube.com/watch?v=uimPY3I1aw4&ab_channel=ResortsWorldManila 
    https://en.wikipedia.org/wiki/Casino_War
*/

/*
    ToDo - Pending items
    1) Implement "withdrawal pattern" - to avoid re-entrance attacks
            Instead of transferring money to players, let them withdraw
    2) Let the players withdraw the money, incase the game has ended and dealer has not picked a winner
    3) Let the joined player increase the bet - currently they can place the bet only once
    4) Implement the Casino War scenario in case of Tie
    5) User the oracle/chainlink to implement the random function
    6) Scalability - Contract deploying another contracts    
*/

/*
// This contract will act as a dealer and will deploy the main CasinoWar contract
contract CasinoWarTableCreator_DP{
    // declaring a dynamic array with address of deployed table contracts
    CasinoWarTable_DP[] public casinoWarTables;

    //declaring the function that will deploy the contract CasinoWarTable
    function createCassinoWarTable() public{
        // passing msg.sender to the constructor of CasionWarGame
        CasinoWarTable_DP newCWTable = new CasinoWarTable_DP(msg.sender);
        // adding the address of the instance to the dynamic array
        casinoWarTables.push(newCWTable);
    }
}
*/

// Main contract - represents a Casino War Table
contract CasinoWarTable_DP{
    // declaring the state variables
    address payable public dealer;
    address payable[] public players; //dynamic array
    
    mapping(address => uint) public playerBets;
    mapping(address => uint) public playerCards;
    uint public dealerCard;

    enum State {Ended, Running, Canceled}
    State public gameState;

    uint startBlock; 
    uint endBlock;

    uint public minBetAmount;
    uint public maxBetAmount;
    uint totalTableBet;

    // To be used to generate a random number
    uint initialNumberSeed;

    //constructor(address eoa){     //Externally Owned Accounts (EOA) 
    constructor(){
        // initializing the dealer/owner as the address that deploys the contract
        dealer = payable(msg.sender);
        minBetAmount = 0.5 ether;
        maxBetAmount = 5 ether;
        initialNumberSeed = getRandomHash();
        startGame();
    }

    // Declaring the function modifiers
    modifier onlyDealer(){
        require(msg.sender == dealer, "You are not the dealer");
        _;
    }

    modifier notDealer(){
        require(msg.sender != dealer, "Dealer can't bet");
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock, "Can't play before start");
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock, "Can't play after end");
        _;
    }

    modifier runningState(){
        require(gameState == State.Running, "The game is not in running state");
        _;
    }

    // Defining the events to emit
    event BetPlacedEvent(address _player, uint _betAmount);
    event CardDealtEvent(address _player, uint _cardNumber, uint _cardType);
    event TransferEvent(address _sender, address _recipient, uint _value);
    event GameStateChanged(string _gameState);

    // Changing GameState
    //      - allows for emitting a GameStateChanged event from a central location
    function changeGameState(State _gameState) private {
        // Update the gameState with the new state
        gameState = _gameState;

        // emit the event as a string
        if (State.Running == _gameState) emit GameStateChanged("Running");
        if (State.Ended == _gameState) emit GameStateChanged("Ended");
        if (State.Canceled == _gameState) emit GameStateChanged("Canceled");
    }

    // Starting the game 
    //      - to be used in order to reset the table after the game has ended
    function startGame() public onlyDealer{
        require(gameState != State.Running, "The game is already in running state");

        changeGameState(State.Running);
        startBlock = block.number;  // This means the start is immidiate, it could be set to some future time as well
        // +6 means in 5 mins (5*60 = 300 sec / 50 sec) for etherum main net, for test net block creation is faster
        endBlock = startBlock + 6;  // +150 is roughly 30 mins for Ropsten net
        totalTableBet = 0;
    }
    
    // Letting the contract to receive money 
    //      - in case a player transfers money directly from wallet to join the game
   receive() external payable{
        joinTable();
    }
    
    // Letting players to join the table and place their bet
        // For testing removing the check on beforeEnd
    function joinTable() public payable notDealer runningState afterStart returns(bool){
        require(msg.value >= minBetAmount, "You can't bet less than the min betting amount");
        require(msg.value <= maxBetAmount, "You can't bet more than the max betting amount");
        require(playerBets[msg.sender] == 0, "You have already joined the table");

        // adding the player in the dynamic array
        players.push(payable(msg.sender));

        // updating the mapping variable
        playerBets[msg.sender] = msg.value;

        // updating total table bet amount
        totalTableBet = totalTableBet + msg.value;

        // emit the event
        emit BetPlacedEvent(msg.sender, msg.value);

        return true;
    }

    // Returning the contract's balance in wei 
    //      - represents total table value, i.e. bets from all players. It doesn't include dealer's contribution.
    function getTableValue() public view returns(uint){
        return address(this).balance;
    }

    // Get number of players on the table
    function getPlayerCount() public view returns(uint){
        return players.length;
    }

    // Deal the cards 
    //      - Assign a card to the dealer and to each of the players on the table
    function dealCards() internal{
        uint cardType;

        for (uint i=0; i<players.length; i++){
            playerCards[players[i]] = pickRandomCard(13); //to pick the actual card - from 1 to 13
            cardType = pickRandomCard(4); //to get the card type - from 1 to 4 - 1: clubs, 2: diamonds, 3: hearts, 4:spades
            // emit the event
            emit CardDealtEvent(players[i], playerCards[players[i]], cardType);
        }

        dealerCard = pickRandomCard(13); //to pick the actual card - from 1 to 13
        cardType = pickRandomCard(4); //to get the card type - from 1 to 4 - 1: clubs, 2: diamonds, 3: hearts, 4:spades
        // emit the event
        emit CardDealtEvent(dealer, dealerCard, cardType);
    }

    // Selecting the winner and transferring the money to the winner
    function pickWinner() public payable onlyDealer{
        // Dealer need to have the amount amount equivalant to table to give to all winners
        require(msg.value >= totalTableBet, "Dealer need to put amount more than or equal to the table value");
        // Need to have at least one player on the table
        require(players.length > 0, "Need to have at least one player on the table playing the game");

        // simulate dealer dealing the cards step, so that everybody has a card
        dealCards();

        // the recipient will get the value
        uint value;
        
        // Dealer plays against each plaer
        for (uint i=0; i<players.length; i++){
            // simple scenario - Not a Tie - dealer against each plaer; winner taks the betAmount
            if (dealerCard == playerCards[players[i]]){
            // Tie scenario - return half of the player's bet
            // Not implemented the Casino War scenario - where the player can double the bet and get bonus upon winning
                value = playerBets[players[i]] / 2; // other half will remain on table (in contract), will the dealr will take at the end
                transferMoney(players[i], value);
            }
            else if(dealerCard < playerCards[players[i]]){
                // get this money from the dealer
                value = playerBets[players[i]] * 2; // get equal amount from dealer and player's own bet back
                transferMoney(players[i], value);
            }
            /*
            // this else is not required, as in the final step the (outside the loop) remaining amount is transferred to the dealer
            else{
                value = playerBets[players[i]];
                dealer.transfer(value);
            }*/


        }

        // Transfer the remaining contract amount to the dealer
        transferMoney(dealer, getTableValue());

        // End the game
        changeGameState(State.Ended);

        // reset and get ready for next round
        resetGameParams();
    }

    // Cancel the game and return the bets 
    //      - to be used in extreme scenarios
    function cancelGame() public payable onlyDealer{
        
        //Change the state
        changeGameState(State.Canceled);

        // Return placed bids of every players
        for (uint i=0; i<players.length; i++){
            players[i].transfer(playerBets[players[i]]);
        }

        // Transfer the remaining contract amount to the dealer
        transferMoney(dealer, getTableValue());

        // Clear player and bid data
        resetGameParams();
    }

    // Clean up player data, betting data and delt card data
    function resetGameParams() internal onlyDealer{
        // delete playerBets; <-- This doesn't work, as you need to pass key to delete mapping
        for (uint i=0; i<players.length; i++){
            delete playerBets[players[i]];
            delete playerCards[players[i]];
        }
        
        players = new address payable[](0);   //alternative is -->      //delete players;
        dealerCard = 0;
        totalTableBet = 0;        
    }

    // Transfer the amount to the address
    function transferMoney(address payable _toAddress, uint _value) internal onlyDealer{
        // To save on Gas, transfer only if there is some value left on table
        if (_value > 0){
            _toAddress.transfer(_value);

            // emit the event
            emit TransferEvent(dealer, _toAddress, _value);
        }        
    }

    // Helper functions

    // Get a random hash based on block properties
    function getRandomHash() internal view returns(uint){
        /*
        This is not a true random number. Solidity contracts are deterministic. 
        Anyone who figures out how your contract produces randomness can anticipate 
        its results and use this information to exploit your application.
        */
        /*
        This is not giving multiple random numbers in a single call, 
        as they are likely to be in the same block
        */       
        //uint randomHash = uint(keccak256(toBytes(block.difficulty + block.timestamp)));
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
        return (randomHash % 13) + 1; //Get a random number between 1 and 13 (both incl.) - similar to 13 cards in a deck
    }

    // Get a random number between 1 to 13 
    function pickRandomCard(uint _modulus) internal returns(uint){
        uint randomNumber;
        randomNumber = uint(keccak256(abi.encodePacked(initialNumberSeed++)));
        return (randomNumber % _modulus) + 1 ; //_modulus = 13 to Get a random number between 1 and 13 (both incl.) - similar to 13 cards in a deck
    }
}