// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    TCG 
*/
/**
 * @author Team3d.R&D
 */
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IInventory.sol";



 contract Game is ReentrancyGuard{

    using SafeERC20 for IERC20;

    IERC20 immutable public token;
    IInventory immutable public cards;

    struct Card{
        uint256 tokenID;
        uint8[4] powers; // 0 top, 1 left, 2 bottom, 3 right,
        address owner;
        uint256 userIndex;
        uint256 currentGameIndex; //index 0 means not in game
    }

    mapping(address => uint256[]) public playersDeck; //tokenId instorage on contract
    mapping(uint256 => Card) public tokenIdToCard;

    mapping(address=> uint256[]) public playerGames;

    struct GamePlay{
        Card[9] board;
        address player1;
        address player2;
        mapping(address=>uint256[]) playerHand;
        mapping(address=> uint8) points;
        bool isTurn; //false player1 turn, true player2 turn
        bool gameFinished;
        uint256 wager;
        uint8 tradeRule; //0 = one card, 1 = Difference, 2 = Direct, 3 = All
    }

    mapping(uint256 => GamePlay) public gamesPlayed;
    uint256[] public gamesWaitingPlayer;
    uint256 public gamesCreated;
                        //top, left, bottom, right
                        //0,1,2
                        //3,4,5
                        //6,7,8
   uint8[4][9] spots = [[9,9,3,1],[9,0,4,2],[9,1,5,9],
                        [0,9,6,4],[1,3,7,5],[2,4,8,9],
                        [3,9,9,7],[4,6,9,8],[5,7,9,9]]; //used for the board, 9 is out of bounds

    constructor(){
        token = IERC20(address(0xFFE93E63E94da7A44739b6aBFA25B81CEd979a6b));
        cards =  IInventory(address(0x7b9de58bD2F3795420a3C4c97bE5B0C00e539F6F));
    }

    /**
     * @dev function user calls to start a game
     * @param tokenIdOfCardsToPlay array of the tokenIds in the players deck
     * @param wager the amount of token they wish to wage if any
     * @param tradeRule what the winner gets when the game ends
     */
    function initializeGame(uint256[5] memory tokenIdOfCardsToPlay, uint256 wager, uint8 tradeRule)external nonReentrant{
        require(tradeRule <5, "tradeRule out of bounds");
        uint256 i = gamesCreated+1;

        GamePlay storage gp = gamesPlayed[i];
        address user = msg.sender;
        if(wager >= 1 ether){
            token.safeTransferFrom(user, address(this), wager);
            gp.wager = wager;
        }
        _buildHand(tokenIdOfCardsToPlay, user, i);

        gp.player1 = user;
        gp.tradeRule = tradeRule;
        gamesCreated++;
        gamesWaitingPlayer.push(i);

    }

    /**
     * @dev function to build the hand for the new game
     */
    function _buildHand(uint256[5] memory tokenIdOfCardsToPlay, address user, uint256 index)internal{
        GamePlay storage gp = gamesPlayed[index];
        for(uint256 x = 0; x < 5;){
            //NFT tokenId ownership == address(this) put it in a require statement...
            require(cards.ownerOf(tokenIdOfCardsToPlay[x]) == address(this), "Transfer Card First");
            Card storage c = tokenIdToCard[tokenIdOfCardsToPlay[x]];
            require(c.owner == user, "Not Card Owner");
            require(c.currentGameIndex == 0, "Card in game already");
            c.currentGameIndex = index; //stops card from being transferred
            gp.playerHand[user].push(tokenIdOfCardsToPlay[x]);
            gp.points[user]++;
            unchecked{x++;}
        }
        playerGames[user].push(index);

    }

    /**
     * @dev function to allow users to join games that need a player
     * @param gameWaitingIndex the location in the array of the game they want to play
     * @param creator a secondary check to ensure that the gameWaitingIndex selected matches what the caller wants
     */
    function joinGame(uint256[5] memory tokenIdOfCardsToPlay, uint256 gameWaitingIndex, address creator) external nonReentrant{
        uint256 gameIndex = gamesWaitingPlayer[gameWaitingIndex];
        GamePlay storage gp = gamesPlayed[gameIndex];
        address user = msg.sender;
        require(user != creator, "Other Player cannot be sender");
        require(gp.player1 == creator, "Creator not matching");
        require(gp.player2 == address(0), "Game already taken");
        
        if(gp.wager >= 1 ether){
            token.safeTransferFrom(user, address(this), gp.wager);
        }
        gp.player2 = user;
        _buildHand(tokenIdOfCardsToPlay, user, gameIndex);

        _removeFromWaiting(gameWaitingIndex,gameIndex);
    }

    /**
     * @dev function to remove game from waiting List
     */

    function _removeFromWaiting(uint256 gameWaitingIndex, uint256 gameIndex)internal {
        uint256 lastOne = gamesWaitingPlayer.length-1;
        require(gamesWaitingPlayer[gameWaitingIndex]==gameIndex, "Game Index does not match waiting list");
        gamesWaitingPlayer[gameWaitingIndex] = gamesWaitingPlayer[lastOne];
        gamesWaitingPlayer.pop();
    }

    /**
     * @dev allows a game creator to cancel the current game in waiting if noone has joined
     */
    function cancelGameWaiting(uint256 gameWaitingIndex) external{
        require(gameWaitingIndex < gamesWaitingPlayer.length, "Out of bounds");
        GamePlay storage gp = gamesPlayed[gamesWaitingPlayer[gameWaitingIndex]];
        address user = msg.sender;
        require(gp.player1 == user, "Must be creator");
        require(gp.player2 == address(0), "Must be in waiting");
        if(gp.wager>0){
            token.safeTransfer(user, gp.wager);
            gp.wager = 0;
        }
        for(uint256 x = 0; x <5; ){
            tokenIdToCard[gp.playerHand[user][x]].currentGameIndex =0; //Makes card tradeable
            unchecked {x++;}
        }
        _removeFromWaiting(gameWaitingIndex, gamesWaitingPlayer[gameWaitingIndex]);

    }

    /**
     * @dev transfer Cards from user into contract and into the deck of the user
     */

    function transferToDeck(uint256[] memory tokenIds) external nonReentrant{
        uint256 l = tokenIds.length;
        address user = msg.sender;
        for(uint256 x = 0; x < l;){
            uint256 id = tokenIds[x];
            require(cards.ownerOf(id) == user, "Sender must be owner");
            cards.safeTransferFrom(user, address(this), id);
            _addToDeck(user, tokenIds[x]);
            unchecked {x++;}
        }
    }
    /**
     * @dev function adds card to players deck
     * @param user deck to add to
     * @param tokenId nft ID
     */

    function _addToDeck(address user, uint256 tokenId) internal{
            Card memory c;
            c.tokenID = tokenId;
            // top,         left          bottom          right
            (,c.powers[0], c.powers[1],  c.powers[3],  c.powers[2],,)=cards.dataReturn(tokenId);
            c.owner = user;
            c.userIndex = playersDeck[user].length;
            playersDeck[user].push(tokenId);
            tokenIdToCard[tokenId] = c;
    }

    /**
     * @dev internal function to remove cards from a players deck
     * @param user the current owner
     * @param tokenId card to remove
     */
    function _removeFromDeck(address user, uint256 tokenId)internal {
        Card storage c = tokenIdToCard[tokenId];
        uint256 y = playersDeck[user].length-1;
        uint256 c1I = c.userIndex;
        c.currentGameIndex =0;
        c.userIndex = 0;
        c.owner = address(0);

        playersDeck[user][c1I] = playersDeck[user][y];
        tokenIdToCard[playersDeck[user][y]].userIndex = c1I;
        playersDeck[user].pop();
    }

    /**
     * @dev function to transfer cards from deck to owners wallet
     * @param tokenIds cards to transfer
     */

    function transferFromDeck(uint256[] memory tokenIds)external{

        address user = msg.sender;
        uint256 l = tokenIds.length;
        require(l <= playersDeck[user].length, "Out of bounds");

        for(uint256 x =0; x < l;){
            require(tokenIdToCard[tokenIds[x]].owner == user, "Not owner");
            require(tokenIdToCard[tokenIds[x]].currentGameIndex == 0, "Card in Game Currently");
            _removeFromDeck(user, tokenIds[x]);
            cards.safeTransferFrom(address(this), user, tokenIds[x]);
            unchecked{x++;}
        }
    }

    /**
     * @dev function to play acard
     * @param indexInHand refers to the card index in the players hand for the game
     * @param gameIndex refers to the game being played
     * @param boardPosition refers to where the card is to be placed
     */

    function placeCardOnBoard(uint256 indexInHand, uint256 gameIndex, uint8 boardPosition) external nonReentrant{

        GamePlay storage game = gamesPlayed[gameIndex];
        address user =msg.sender;
        require(game.player2 != address(0), "No second Player Yet");
        bool canPlay = (game.player1 == user && !game.isTurn)||(game.player2 == user && game.isTurn); //is a users turn
        require(canPlay, "Not a player, or turn yet");
        require(boardPosition <9, "Position out of bounds");
        require(game.board[boardPosition].owner == address(0), "Position Already taken");
        require(game.playerHand[user].length > indexInHand, "Hand out of Bounds");
        
        uint256 tokenId = game.playerHand[user][indexInHand];
        game.playerHand[user][indexInHand]= game.playerHand[user][game.playerHand[user].length-1];
        game.playerHand[user].pop();
        game.board[boardPosition] = tokenIdToCard[tokenId];
        
        uint8[4] memory otherPos = spots[boardPosition];
        uint8[4] memory sum;
        bool[4] memory same;
        bool[4] memory indexToChange;
        uint8 sameCount;

        //there's a lot here need to explain it for cube's barney style, FML

        for(uint8 i =0; i <4;){
            uint8 pos = otherPos[i];
            if(pos < 9 ){//pos is on the board
                if(game.board[pos].owner != address(0)){//there is a card placed on the board at pos
                    uint8 a = game.board[boardPosition].powers[i];
                    uint8 b = game.board[pos].powers[(i+2)%4];
                    sum[i] = a + b;
                    same[i] = a==b;
                    if(a==b){sameCount++;}
                    if(a > b){indexToChange[i] = true;}
                }
            }
            unchecked{i++;}
        }

        (uint8[4] memory ar, bool truth) = putma.sumFind(sum);

        if(truth || sameCount >1){
            bool sT = sameCount >1;
            for(uint8 i = 0; i<4;){
                //Found Sum Match at index
                if(ar[i] >0){
                    indexToChange[ar[i]] = true;
                    indexToChange[i] = true;
                }
                //if true
                if(same[i] && sT){indexToChange[i] = true;}
                unchecked{i++;}
            }
        }

        address other = game.player1;
        if(other == user){other = game.player2;}
        for(uint8 i = 0; i < 4;){
            if(indexToChange[i] && game.board[otherPos[i]].owner == other){
                game.board[otherPos[i]].owner = user;
                game.points[other] -=1;
                game.points[user] +1;
            }
            unchecked{i++;}
        }

        //Game is finished if a players hand  == 0
        game.gameFinished = game.playerHand[user].length == 0;
    }


    /**
     * @dev function for end of game state where the winner can claim, if draw either can claim
     * @param gameIndex refers to game
     * @param cardsToClaimTokenIds used to claim cards if not draw or direct 
     */
    function collectWinnings(uint256 gameIndex, uint256[] memory cardsToClaimTokenIds)external nonReentrant{
        address user = msg.sender;
        address other = gamesPlayed[gameIndex].player1;
        if(other == user){
            other = gamesPlayed[gameIndex].player2;
        }
        require(gamesPlayed[gameIndex].gameFinished, "Game still playing");
        require(gamesPlayed[gameIndex].points[user] >= gamesPlayed[gameIndex].points[other], "Winner must collect");
        returnCards(gameIndex, other, user, cardsToClaimTokenIds);
        if(gamesPlayed[gameIndex].points[user] == gamesPlayed[gameIndex].points[other]){ //if draw
            drawReturnCardsFromBoard(gameIndex, other, user);
        }else if(gamesPlayed[gameIndex].tradeRule != 2){ //if not direct tradeRule
            returnCards(gameIndex, other, user, cardsToClaimTokenIds);
        }else{// direct trade rule
            directReturnCards(gameIndex, other, user);
        }
        if(gamesPlayed[gameIndex].playerHand[user].length > 0){
            tokenIdToCard[gamesPlayed[gameIndex].playerHand[user][0]].currentGameIndex = 0;
        }else{
            tokenIdToCard[gamesPlayed[gameIndex].playerHand[other][0]].currentGameIndex = 0;
        }

    }

    /**
     * @dev function to return cards in case of draw
     * @param gameIndex game instance
     * @param other non-msg.sender
     * @param user msg.sender
     */

    function drawReturnCardsFromBoard(uint256 gameIndex, address other, address user)internal{
        GamePlay storage g = gamesPlayed[gameIndex];
        for(uint i =0; i < 9;){
            updateCards(0, g.board[i].tokenID);
            unchecked{i++;}
        }
        if(g.wager > 0){
            token.safeTransfer(user, gamesPlayed[gameIndex].wager);
            token.safeTransfer(other, gamesPlayed[gameIndex].wager);
        }
    }

    /**
     * @dev function to return cards in case of direct trade rule
     * @param gameIndex game instance
     * @param other non-msg.sender
     * @param user msg.sender and winner
     */ 
    function directReturnCards(uint256 gameIndex, address other, address user)internal{
        GamePlay storage g = gamesPlayed[gameIndex];
        for(uint i =0; i < 9;){

            uint256 tokenId = g.board[i].tokenID;
            uint256 win;
            if(g.board[i].owner == user){
                if(g.board[i].owner != tokenIdToCard[tokenId].owner){ // if card on board is controlled by winner but not owned
                    _transferCard(tokenId, gameIndex, user, other);
                }
                win =1;
            }
            updateCards(win, tokenId);
            unchecked{i++;}
            }
        
        if(g.wager > 0){
            token.safeTransfer(user, gamesPlayed[gameIndex].wager*2);
        }

    }

    /**
     * @dev function to transfer card in deck from one owner to another
     * @param tokenId card to transfer
     * @param gameIndex game associated with the transfer
     * @param newOwner new owner of card
     * @param currentOwner current owner of card 
    */
    function _transferCard(uint256 tokenId, uint256 gameIndex, address newOwner, address currentOwner)internal{
        require(tokenIdToCard[tokenId].owner == currentOwner && tokenIdToCard[tokenId].currentGameIndex == gameIndex, "Card does not meet requirements");
        _removeFromDeck(currentOwner, tokenId);
        _addToDeck(newOwner, tokenId);
    }

    /**
     * @dev function to update cards from game and to make them active in deck again
     * @param win 0 if loss or 1 if card won
     * @param tokenId card to update
     */

    function updateCards(uint256 win, uint256 tokenId) internal {
        cards.updateCardGameInformation(win, 1, tokenId);
        tokenIdToCard[tokenId].currentGameIndex = 0;
    }
    /**
     * @dev function to return cards 
     * @param gameIndex game instance
     * @param other non-msg.sender
     * @param user msg.sender and winner
     * @param cardsToClaimTokenIds winner card claim
     */ 
    function returnCards(uint256 gameIndex, address other, address user, uint256[] memory cardsToClaimTokenIds)internal{
        GamePlay storage g = gamesPlayed[gameIndex];
        uint256 cardsToCollect = putma.cardsToCollect(g.tradeRule, g.points[user], g.points[other]);
        if(cardsToCollect >0){
            require(cardsToClaimTokenIds.length == cardsToCollect, "length does not match winnings to claim");
            if(g.tradeRule !=2){
                for(uint i = 0; i < cardsToCollect;){
                    _transferCard(cardsToClaimTokenIds[i], gameIndex, user, other);
                    unchecked{i++;}
                }
            }
        }
        for(uint i =0; i < 9;){
            uint256 tokenId = g.board[i].tokenID;
            uint256 win;
            if(g.board[i].owner == user){
                win =1;
            }
            updateCards(win, tokenId);
            unchecked{i++;}
        }
    }

    /**
     * @dev function to view deck
     * @param player check players deck
     * @return size the number of cards in deck
     * @return deck the tokenIds of cards in deck
     */
    function deckInfo(address player)external view returns(uint256 size, uint256[] memory deck){
        size = playersDeck[player].length;
        deck = playersDeck[player];
    }

    /**
     * @dev returns gameIndexes that player is current involved in and finished
     * @param player address to check  
     * @return gamesIndexes a list of indexes
     */

    function playerGamesPlayed(address player) external view returns(uint256[] memory gamesIndexes){
        gamesIndexes = playerGames[player];
    }

    /**
     * @dev returns the game current status
     * @param gameIndex refers to game instance
     */

    function gameStats(uint256 gameIndex)external view returns(bool finished, address player1, uint8 player1Points, address player2, uint8 player2Points, uint256 player1HandSize, uint256 player2HandSize){
        finished = gamesPlayed[gameIndex].gameFinished;
        player1 = gamesPlayed[gameIndex].player1;
        player1Points = gamesPlayed[gameIndex].points[player1];
        player1HandSize = gamesPlayed[gameIndex].playerHand[player1].length;
        player2 = gamesPlayed[gameIndex].player2;
        player2Points = gamesPlayed[gameIndex].points[player2];
        player2HandSize = gamesPlayed[gameIndex].playerHand[player2].length;
    }
    
    /**
     * @dev function to return current board state of a game
     * @param gameIndex refers to current game
     * @return cardsOnBoard returns tokenIds if 0 no card
     * @return ownerOfCards returns owner of the position if null noone owns
     */
    function boardTokens(uint256 gameIndex)external view returns(uint256[9] memory cardsOnBoard, address[9] memory ownerOfCards){

        for(uint8 i = 0; i<0;){
            cardsOnBoard[i] = gamesPlayed[gameIndex].board[i].tokenID;
            ownerOfCards[i] = gamesPlayed[gameIndex].board[i].owner;
            unchecked{i++;}
        }
    }

 }

 library putma{

    function sumFind(uint8[4] memory sum)internal pure returns(uint8[4] memory a, bool truth){
            
            if(sum[0]>0){
                if(sum[0] == sum[1]){ 
                    a[0] = 1;
                    truth = true;
                }
                if(sum[0] == sum[2]){
                    a[0] = 2;
                    truth = true;
                }
                if(sum[0] == sum[3]){
                    a[0] = 3;
                    truth = true;
                }
            }
            if(sum[1] > 0){
                if(sum[1] == sum[2]){
                    a[1] = 2;
                    truth = true;
                }
                if(sum[1] == sum[3]){
                    a[1] = 3;
                    truth = true;
                }                
            }
            if(sum[2] > 0){
                if(sum[2] == sum[3]){
                    a[2] = 3;
                    truth = true;
                } 
            }
    }

    function cardsToCollect(uint256 tradeRule, uint8 winnerPoints, uint8 otherPoints)internal pure returns(uint8){
        if(winnerPoints==otherPoints){return 0;}
        if(tradeRule == 0){return 1;}
        if(tradeRule == 1){
            uint8 a = winnerPoints - otherPoints;
            if(a>5){
                a = 5;
            }
            return a;}
        if(tradeRule == 3){return 5;}
        return 0;
    }


 }

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.7 < 0.9.0;

/*
  _______                   ____  _____  
 |__   __|                 |___ \|  __ \ 
    | | ___  __ _ _ __ ___   __) | |  | |
    | |/ _ \/ _` | '_ ` _ \ |__ <| |  | |
    | |  __/ (_| | | | | | |___) | |__| |
    |_|\___|\__,_|_| |_| |_|____/|_____/ 

    https://team3d.io
    https://discord.gg/team3d
    NFT Triad contract
*/
/**
 * @author Team3d.R&D
 */

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IInventory is IERC721{

    function dataReturn(uint256 tokenId) external view returns(uint8 level, uint8 top, uint8 left, uint8 right, uint8 bottom, uint256 winCount, uint256 playedCount);
    function updateCardGameInformation(uint256 addWin, uint256 addPlayed, uint256 tokenId)external;
    function updateCardData(uint256 tokenId, uint8 top, uint8 left, uint8 right, uint8 bottom)external;
    function mint(uint256 templateId, address to)external returns(uint256);
    function templateExists(uint256 templateId)external returns(bool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}