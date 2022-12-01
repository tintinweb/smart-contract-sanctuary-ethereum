// SPDX-License-Identifier: GPL-3.0
//@authors: JamalForbes_
/*@note: This is a work in progress version with the game using
 the following OSFD contract to make 'secure' commits and reveal changes 
*/

pragma solidity ^0.8.17;

import "../node_modules/@OpenZeppelin/contracts/security/ReentrancyGuard.sol";

contract RPSv2 is ReentrancyGuard {

    address public owner;

    event GetGameOutcome(GameOutcome);

    enum GameStatus {
        nonExistent,
        started,
        participated,
        ended
    }

    enum GameOutcome {
        draw,
        playerOne,
        playerTwo
    }

    struct Game {
        address playerOne;
        address playerTwo;
        uint stake;
        uint  playerOneChoice;
        uint  playerTwoChoice;
        bytes32 playerOneHash;
        bytes32 playerTwoHash;
        GameStatus  status;
        GameOutcome outcome;
    }

    mapping (address => Game) public games;
    mapping (address => uint) public playerBalances;

	//Start
    function startGame(bytes32 gameHash, address opponent, uint gameStake) external { //@audit: why does this function cost so much gas?
        require(gameHash != "", "gameHash not provided");
        require(opponent != address(0x0) && opponent != msg.sender, "Problem with other player...");
        require(games[msg.sender].status == GameStatus.nonExistent, "Old game/No game");
        require(gameStake <= playerBalances[msg.sender], "Players funds are insufficient");

        playerBalances[msg.sender] = playerBalances[msg.sender]-(gameStake);
        
        games[msg.sender].playerOneHash = gameHash;
        games[msg.sender].playerOne = msg.sender;
        games[msg.sender].playerTwo = opponent;
        games[msg.sender].stake = gameStake;
        games[msg.sender].status = GameStatus.started;
    }

    //player 2 enters game
    function participateGame(bytes32 gameHash, address opponent) external {
        require(gameHash != "", "gameHash not provided");
        require(opponent != address(0x0), "Problem with other player...");
        require(games[opponent].playerTwo == msg.sender, "You are not Player 2 for this game");
        require(games[opponent].status == GameStatus.started, "Game not started or has already been participated in");

        uint gameStake = games[opponent].stake;
        require(gameStake <= playerBalances[msg.sender], "Player funds are insufficient");

        playerBalances[msg.sender] = playerBalances[msg.sender]-(gameStake);

        games[opponent].playerTwoHash = gameHash;
        games[opponent].status = GameStatus.participated;
    }

    //After hashes are sent in and both players have played - each player sends their salt with their choice
    function revealChoice(uint choice, bytes32 salt, address playerOne) external {        
        require(games[playerOne].status == GameStatus.participated, "Game does not exist or player Two has not placed a bet yet");                
       
        if(games[playerOne].playerOne == msg.sender) {
            require(games[playerOne].playerOneHash == getSaltedHash(choice, salt), "problem with salt");
            games[playerOne].playerOneChoice = choice;
        } else if(games[playerOne].playerTwo == msg.sender) {//@audit: why is player 2 gas cost greater?
            require(games[playerOne].playerTwoHash == getSaltedHash(choice, salt), "problem with salt");
            games[playerOne].playerTwoChoice = choice;
        } else {
            revert("Problem with addresses");
        }
    }
    
    function endGame(address playerOne) external returns(GameOutcome gameResult) {
        require(
          games[playerOne].playerOneChoice > 0 &&
          games[playerOne].playerTwoChoice > 0 ,
          "Both players need to reveal their choice before game can be completed"
        );

        address playerTwo = games[playerOne].playerTwo;
        uint playerOneChoice = games[playerOne].playerOneChoice;
        uint playerTwoChoice = games[playerOne].playerTwoChoice;
        uint stake = games[playerOne].stake;

        gameResult = GameOutcome((uint(3)+(uint(playerOneChoice))-(uint(playerTwoChoice)))%(3));

        if(gameResult == GameOutcome.draw){
            playerBalances[playerOne] = playerBalances[playerOne]+(stake);
            playerBalances[playerTwo] = playerBalances[playerTwo]+(stake);
        }
        else if(gameResult == GameOutcome.playerOne){
            playerBalances[playerOne] = playerBalances[playerOne]+(stake*(2));
        }
        else if(gameResult == GameOutcome.playerTwo){
            playerBalances[playerTwo] = playerBalances[playerTwo]+(stake*(2));
        }
        else{
            revert("Invalid Game Outcome");
        }

        //@dev: Use these lines and comment out deleteGame() to view a completed game in console
        games[playerOne].outcome = gameResult;
        games[playerOne].status = GameStatus.ended;
        deleteGame(playerOne);

        emit GetGameOutcome(gameResult);
        return gameResult;
    }
    
    function getSaltedHash(uint answer, bytes32 salt) internal pure returns (bytes32) {
       return keccak256(abi.encodePacked(answer, salt));
    }
   
    function deleteGame(address playerOne) internal {
        delete games[playerOne];
        //the game disappears after being played, so if you want to leave data behind for testing, you can just delete certain pieces of data
    }

    //deposit a player's funds
    function deposit() external payable {
        playerBalances[msg.sender] = playerBalances[msg.sender]+(msg.value);
    }
    
    //withdraw a player's funds
    function withdraw() external nonReentrant {
        uint playerBalance = playerBalances[msg.sender];
        require(playerBalance > 0, "No balance");
        
        playerBalances[msg.sender] = 0;
        (bool success, ) = address(msg.sender).call{ value: playerBalance }("");
        require(success, "withdraw failed to send");
    }
    
    function getContractBalance() external view returns(uint contractBalance) {
        return address(this).balance;
    }

    function getPlayerBalance(address playerAddress) external view returns(uint playerBalance) {
        return playerBalances[playerAddress];
    }

    function getMsgSender() external view returns(address msgsender) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}