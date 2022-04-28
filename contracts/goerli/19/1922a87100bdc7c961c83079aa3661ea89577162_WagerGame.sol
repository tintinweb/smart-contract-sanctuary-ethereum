/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
* This smart contract handles the transaction for a wager game.
*/
contract WagerGame {

    event Log(string message, uint val);

    enum GameStatus {
        None,
    	NotStarted,
    	InProgress
    }
    
    enum GameResult {
    	None,
    	Won,
    	Lost,
    	Tied,
    	Aborted
    }
    
    /**
    * The billard game player. Each game has two players.
    */
    struct Player {
        string playerId;
        address addr;
    }

    /**
    * The billard game.
    */
    struct Game {
        Player initiator;
        Player opponent;
        uint amount;
        GameStatus status;
    }
 
    address private owner;
    address private server;

    mapping(string => Game) private games; // active wager games
    string[] private initiators; // array of the initiators of the games in progress
    uint private gamesNotStartedCount; // a count of the "not started" wager games
    uint private gamesInProgressCount; // a count of the "in progress" wager games 
    uint private tipCharge; // the amount charged for a wager game
    uint private totalTips; // the total amount of tips in the smart contract
    
    /**
    * Set the owner and admin of the smart contract when the contract is deployed.
    */ 
    constructor() {
        owner = msg.sender;
        server = msg.sender;
        tipCharge = 1000; // this is 10% of the winnings (1000 basis points)
    }

    /**
    * This modifies a function so that only the server can call it. 
    */
    modifier onlyServer() {
        require(msg.sender == server, "not allowed, only server allowed");
        _;
    }

    /**
    * This modifies a function so that only the contract owner can call it. 
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "not allowed, only owner allowed");
        _;
    }

    /**
    * This modifies a function so that only the server or the contract owner can call it. 
    */
    modifier onlyServerOrOwner() {
        require(msg.sender == server || msg.sender == owner, "not allowed, only server or owner allowed");
        _;
    }

    /**
    * This changes the "server" of the smart contract.
    * This can only be called by the contract owner address.
    */
    function setServer(address newServer) external onlyOwner {
        require(newServer != address(0), "invalid address for server");
        server = newServer;
    }

    /**
    * This changes the "owner" of the smart contract.
    * This can only be called by the contract owner address.
    */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "invalid address for owner");
        owner = newOwner;
    }

    /**
    * Get the total tips value.
    */
    function getTotalTips() external view returns(uint) {
        return totalTips;
    }

    /**
    * Widthdraw the tips from the smart contract.
    * This is needed otherwise the tips will be stuck in the smart contract forever.
    */
    function withdrawTips() external onlyOwner {
        payable(owner).transfer(totalTips);
        totalTips = 0;
    }

    /*
    * This allows the tip percentage to be updated.
    */
    function updateTipCharge(uint newTipCharge) external onlyOwner {
        tipCharge = newTipCharge;
    }

    /**
    * Get the tip charge.
    */
    function getTipCharge() external view returns(uint) {
        return tipCharge;
    }

    /**
    * Get the balance in the smart contract.
    **/
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
    
    /**
    * Get the amount of not started games.
    **/
    function getGamesNotStartedCount() external view returns(uint) {
        return gamesNotStartedCount;
    }

    /**
    * Get the amount of in progress games.
    **/
    function getGamesInProgressCount() external view returns(uint) {
        return gamesInProgressCount;
    }

    /**
    * Get the amount of in game initiators.
    **/
    function getInitiatorsCount() external view returns(uint) {
        return initiators.length;
    }

    /**
    * Abort the wager game by player ID.
    * @param playerId - the game initiator player ID
    **/
    function abortWagerGameByPlayerId(string calldata playerId) external onlyServerOrOwner returns(bool) {
        Game memory game = games[playerId];

        return abortExistingGame(game);
    }

    /**
    * This function is used to manually abort the wager game by address.
    * @param addr - the game initiator or opponent address
    */
    function abortWagerGameByAddress(address addr) external onlyOwner returns(bool) { 
        Game memory game;

        for (uint i = 0 ; i < gamesInProgressCount; i++) {   
            string memory gameInitiator = initiators[i];
            Game memory gameInProgress = games[gameInitiator];
            Player memory initiator = gameInProgress.initiator;
            Player memory opponent = gameInProgress.opponent;
            
            if (addr == initiator.addr || addr == opponent.addr) {
                game = gameInProgress;
                break;   
            }
        }

        require (game.initiator.addr == addr || game.opponent.addr == addr, "no wager game found for address");  

        return abortExistingGame(game);
    }

    /**
    * This recives the wager transaction from the game initiator.
    */
    function initiateWagerGame(string calldata initiatorId, 
                                string calldata opponentId) external payable {
        // Abort any existing games as a saftey measure. 
        // There should not be any existing wager games for either of the players.
        // If an existing wager game is found for either player the game is removed
        // and the wagers are returned to the players. No tip is deducted.
        // This shouldn't happen but might happen before an errored game is aborted.
        abortExistingGameByPlayerId(initiatorId);
        abortExistingGameByPlayerId(opponentId);

        Game memory game;
        game.initiator = Player(initiatorId, msg.sender);
        game.opponent = Player(opponentId, address(0));
        game.amount = msg.value;
        game.status = GameStatus.NotStarted;
        games[initiatorId] = game;
        gamesNotStartedCount++;     
    }

    /**
    * This recieves the wager transaction from the game opponent 
    * and change the game status because the game has started.
    */
    function acceptWagerGame(string calldata initiatorId,
                                    string calldata opponentId) external payable { 
        Game memory game = games[initiatorId];
        
        require(msg.value == game.amount, "wrong opponent wager amount for game");   
        require(compareStringsByBytes(opponentId, game.opponent.playerId), "invalid opponent for initiator game");                        
        
        game.opponent = Player(opponentId, msg.sender);
        game.status = GameStatus.InProgress;
        games[initiatorId] = game;
        initiators.push(initiatorId);
        gamesNotStartedCount--;  
        gamesInProgressCount++;   
    }

    /**
    * This returns the wager to the game initiator if the game is cancelled.
    * This can only be done before a game has started.
    */
    function cancelWagerGame(string calldata initiatorId) external onlyServer {
        Game memory game = games[initiatorId];
        
        require(game.status == GameStatus.NotStarted, "cannot cancel the wager game, the game has already started");    
        
        payable(game.initiator.addr).transfer(game.amount); 
        delete games[initiatorId];
        gamesNotStartedCount--; 
    }

    /**
    * This pays out the winnings.
    * This tranaction can only be called by the game server.
    * The result will usually be Won or Lost.
    * @param result - the game result
    * @param playerId - the initiator ID or the opponent ID
    */
    function payout(GameResult result, string memory playerId) external onlyServer {   
        // Get the game if the player ID is the initiator.
        Game memory game = games[playerId];

        if (game.status != GameStatus.InProgress) {
            // The player is not the initiator therefore find the game using the opponent ID.
            for (uint i = 0 ; i < gamesInProgressCount; i++) {   
                string memory initiator = initiators[i];
                Game memory gameInProgress = games[initiator];
                string memory opponentId =  gameInProgress.opponent.playerId;
                if (compareStringsByBytes(playerId, opponentId)) {
                    game = gameInProgress;
                    break;   
                }  
            }
        }
         
        require(game.status == GameStatus.InProgress, "cannot payout, the wager game has not yet started");    
        
        uint winnings = game.amount * 2;
        uint tip = calculateTip(winnings);

        if (result != GameResult.Aborted) {
            // add the tip to the total tips
            totalTips += tip;
        }

        if (result == GameResult.Won) {
            if (compareStringsByBytes(playerId, game.initiator.playerId)) {
                payable(game.initiator.addr).transfer(winnings - tip);
            } else if (compareStringsByBytes(playerId, game.opponent.playerId)) {
                payable(game.opponent.addr).transfer(winnings - tip);
            }    
        } else if (result == GameResult.Lost) {
            if (compareStringsByBytes(playerId, game.initiator.playerId)) {
                payable(game.opponent.addr).transfer(winnings - tip);
            } else if (compareStringsByBytes(playerId, game.opponent.playerId)) {
                payable(game.initiator.addr).transfer(winnings - tip);
            } 
        } else if (result == GameResult.Tied) {
            // split the winnings
            payable(game.initiator.addr).transfer(game.amount - calculateTip(game.amount));
            payable(game.opponent.addr).transfer(game.amount - calculateTip(game.amount));
        } else if (result == GameResult.Aborted) { 
            // this means the game has an error
            // return the wagers back to the players, no tip is deducted
            payable(game.initiator.addr).transfer(game.amount);
            payable(game.opponent.addr).transfer(game.amount);
        }

        delete games[game.initiator.playerId];
        deleteInitiatorArrayElement(game.initiator.playerId);
        gamesInProgressCount--;
    }

    /**
    * Calculate the table tip. 
    * The tip is the percentage deducted from the winnings.
    * This uses "basis points" calculation.
    */ 
    function calculateTip(uint winnings) private view returns(uint) {
        return (winnings * tipCharge) / 10000;
    }

    /**
    * Compare two strings.
    **/
    function compareStringsByBytes(string memory s1, string memory s2) private pure returns(bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    /**
    * Delete an element from the "initiator" array. 
    * This removes any spaces from the array and keeps the array order.
    */
    function deleteInitiatorArrayElement(string memory initiatorId) private {  
        uint index = 0;
        
        // find the index to be deleted
        for (uint i = 0; i < initiators.length; i++) {
            string memory playerId = initiators[i];
            if (compareStringsByBytes(playerId, initiatorId)) {
                index = i;
                break;
            }
        }

        // remove the game from the array
        remove(index); 
    }  


    /**
    * Remove an elememt from the "initiators" array.
    */
    function remove(uint index) private  {
        require(index < initiators.length, "the wager game initiator cannot be found for removal");   

        for (uint i = index; i < initiators.length - 1; i++){
            initiators[i] = initiators[i + 1];
        }

        initiators.pop();
    }

    /**
    * This is used to ensure there is no existing game for the player.
    * @param playerId - the game initiator player ID
    */
    function abortExistingGameByPlayerId(string memory playerId) private returns(bool) {   
        Game memory game = games[playerId];

        return abortExistingGame(game);
    }

    /**
    * Abort a existing game. 
    * This can be a game that has or has not yet started.
    */
    function abortExistingGame(Game memory game) private returns(bool) {
        bool hasAbortedGame = false;
        string memory playerId = game.initiator.playerId;

        if (game.status == GameStatus.InProgress || game.status == GameStatus.NotStarted) {
            // this means there is an existing wager game for the player
            // return the wagers back to the players and no tip is deducted
            if (game.status == GameStatus.NotStarted) {
                payable(game.initiator.addr).transfer(game.amount);
                gamesNotStartedCount--; 
            }
            else if (game.status == GameStatus.InProgress) {
                payable(game.initiator.addr).transfer(game.amount);
                payable(game.opponent.addr).transfer(game.amount);
                gamesInProgressCount--;       
            }

            delete games[playerId];
            deleteInitiatorArrayElement(playerId);
            hasAbortedGame = true;       
        }

        return hasAbortedGame;
    }
}