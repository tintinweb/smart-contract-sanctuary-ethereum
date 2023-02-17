// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Roulette.sol";

contract Blackjack is ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Game {
        address bettor;
        uint256 startTime;
        Player player;
        Player dealer;
        Player splitPlayer;
        bool completed;
    }

    struct Player {
        uint256 betAmount;
        uint256[] cards;
        uint8[] hand;
        uint8 score;
        uint256 winningAmount;
    }

    address public owner;
    uint256 public maxBet;
    uint256 public minBet;
    uint256 public currentBetId;
    uint256 public currentRoomId;
    uint256 private seedWord;
    uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];

    /*
    Cards value is calculated using index of this array
    ["AH","2H","3H","4H","5H","6H","7H","8H","9H","10H","JH","QH","KH","AC","2C","3C","4C","5C","6C","7C","8C","9C","10C","JC","QC","KC","AD","2D","3D","4D","5D","6D","7D","8D","9D","10D","JD","QD","KD","AS","2S","3S","4S","5S","6S","7S","8S","9S","10S","JS","QS","KS",] 
    */

    mapping(uint256 => Game) public GameId;
    mapping(uint256 => bool) public isEther;
    mapping(uint256 => address) public tokenAddress;
    mapping(address => bool) public isWhitelistedToken;
    mapping(address => uint256) public winningsInEther;
    mapping(address => mapping(address => uint256)) public winningsInToken;
    mapping(address => bool) public isAdmin; 

    event BetPlaced(uint256 betId, uint256 time, address player, uint256 betAmount);
    event CardsDistribution(uint256 betId, uint256 card1, uint256 card2, uint256 dCard);
    event SplitPlayer(uint256 betId, uint256 pCard2, uint256 spCard2);
    event DoubleDown(uint256 betId, uint256 pCard3);
    event PlayerHit(uint256 betId, uint256 pCard3);
    event DealerSecondCard(uint256 betId, uint256 dCard2);
    event DealerHit(uint256 betId, uint256 dNewCard);
    event BetCompleted(uint256 betId, uint256 winAmount);
    event EthWithdrawn(address indexed player, uint256 indexed amount);
    event TokenWithdrawn(address indexed player, address indexed tokenAddress, uint256 indexed amount);

    constructor() {
    owner = msg.sender;
    }

    modifier onlyAuthorised {
      require(isAdmin[msg.sender] || msg.sender == owner, 'not allowed to call this function');
    _;
    }

    modifier betLimit(bool isEth, uint256 amount) {
        uint256 betValue;
        if(isEth) {
            betValue = msg.value;
        } else {
            betValue = amount;
        }
        require(betValue >= minBet, 'Bet Value should be greater than minimum bet');
        require(betValue <= maxBet, 'Bet Value should be lesser than maximum bet');
        _;
    }

    modifier playerChecks(uint256 betId) {
        Game memory bet = GameId[betId];
        require(bet.player.hand.length > 0, "Card distribution for this bet id is not completed");
        require(msg.sender == bet.bettor, "Caller is not player");
        require(!bet.completed, 'Game is completed');
        _;
    }

    /**
     * @dev For placing the bet.
     * @param isEth to check whether the selected payment is in Ether or token.
     * @param tokenAddr to know which token is chosen if the the payment is not in Ether.
     * @notice Only whitelisted tokens are allowed for payments.
     * @param amount amount of token user wants to bet. Should approve the contract to use it first.
    */
    function play(bool isEth, address tokenAddr, uint256 amount) public payable betLimit(isEth, amount) {
        currentBetId = _inc(currentBetId);
        Game storage bet = GameId[currentBetId];
        bet.startTime = block.timestamp;
        bet.bettor = msg.sender;

        uint256 betValue;
        if(isEth) {
            betValue = msg.value;
            isEther[currentBetId] = true;
        }
        else{
            require(isWhitelistedToken[tokenAddr] == true, 'Token not allowed for placing bet');
            IERC20(tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            tokenAddress[currentBetId] = tokenAddr;
            betValue = amount;
        }

        uint256[] memory cards = drawCard(currentBetId, 3);

        bet.player.cards.push(cards[0]);
        bet.player.cards.push(cards[1]);
        bet.dealer.cards.push(cards[2]);

        uint256 pCard1 = (cards[0]) % 13;
        uint256 pCard2 = (cards[1]) % 13;
        uint256 dCard1 = (cards[2]) % 13;

        bet.player.hand.push(cardValues[pCard1]);
        bet.player.hand.push(cardValues[pCard2]);
        bet.dealer.hand.push(cardValues[dCard1]);

        calculate(bet.player);
        if(bet.player.score == 21) {
            revealDealerCard(currentBetId);
        }
        emit BetPlaced(currentBetId, bet.startTime, msg.sender, betValue);
        emit CardsDistribution(currentBetId, cards[0], cards[1], cards[2]);       
    }

    //Internal function used for generating multiple random card values.
    function drawCard(uint256 betId, uint8 numberOfCards) internal view returns(uint256[] memory) {
        uint256[] memory cards = new uint256[](numberOfCards);

        for (uint256 i = 0; i < numberOfCards; i++) {
            cards[i] = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,block.number,betId,seedWord, i))) % 52 ; 
        }
        return cards;
    }

    /**
     * @param betId Game id 
     * @notice Player can split only when there are 2 cards and when the value of both the cards are same.
     * @notice Player has to match the original bet to split
     * @notice We will split both the cards in each hand and provide one card to each hand and conclude the game.
     */
    function split(uint256 betId) public payable playerChecks(betId) {
        Game storage bet = GameId[betId];
        require(bet.player.hand.length == 2, 'can only split with two cards');
        require(bet.player.hand[0] == bet.player.hand[1], 'First two cards must be same');
        if(isEther[betId]) {
            require(msg.value == bet.player.betAmount, 'Must match original bet');
        }else {
            IERC20(tokenAddress[betId]).safeTransferFrom(msg.sender, address(this), bet.player.betAmount);
        }
        bet.splitPlayer.betAmount = bet.player.betAmount;
        bet.splitPlayer.hand.push(bet.player.hand[1]);
        bet.splitPlayer.cards.push(bet.player.cards[1]);
        bet.player.hand.pop();
        bet.player.cards.pop();

        uint256[] memory cards = drawCard(currentBetId, 2);

        bet.player.cards.push(cards[0]);
        bet.splitPlayer.cards.push(cards[1]);

        uint256 pCard2 = (cards[0]) % 13;
        uint256 spCard2 = (cards[1]) % 13;
        
        bet.player.hand.push(cardValues[pCard2]);
        bet.splitPlayer.hand.push(cardValues[spCard2]);

        calculate(bet.player);
        calculate(bet.splitPlayer);
        revealDealerCard(betId);

        emit SplitPlayer(betId, cards[0], cards[1]);
    }

    /**
     * @param betId Game id 
     * @notice Player can increase bet using this function
     * @notice Player can only double down when there are 2 cards.
     * @param amount if the bet is placed using any ERC20 token, player should specify how much amount he wants to increase.
     * @notice amount should not be more than original bet.
     * @notice We will provide one more card to the player and conclude the game.
     * @notice If the total score of the player goes above 21, player busts and loses bet.
     */
    function doubleDown(uint256 betId, uint256 amount) public payable playerChecks(betId) {
        Game storage bet = GameId[betId];
        require(bet.player.hand.length == 2, 'can only double down with two cards');
        if(isEther[betId]) {
            require(msg.value <= bet.player.betAmount, 'Amount should not be more than original bet');
            bet.player.betAmount += msg.value;
        }
        else{
            require(amount <= bet.player.betAmount && amount >= minBet, 'Amount should not be more than original bet');
            IERC20(tokenAddress[betId]).safeTransferFrom(msg.sender, address(this), amount);
            bet.player.betAmount += amount;
        }
       
        uint256[] memory cards = drawCard(currentBetId, 1);
        bet.player.cards.push(cards[0]); 
        uint256 pCard3 = cards[0] % 13;      

        bet.player.hand.push(cardValues[pCard3]);
        calculate(bet.player);
        if(bet.player.score > 21) {
            bet.completed = true;
            emit BetCompleted(betId, 0);
        } else {
        revealDealerCard(betId);
        }
        emit DoubleDown(betId, cards[0]);
    }

    /**
     * @param betId Game id 
     * @notice We provide a pard to the player and calculates his score.
     * @notice If the total score of the player goes above 21, player busts and loses bet.
     * @notice If the total score of the player is equal to 21, we reveal dealer's next card.
     */
    function hit(uint256 betId) public playerChecks(betId){
        uint256[] memory cards = drawCard(currentBetId, 1);

        Game storage bet = GameId[betId];
        bet.player.cards.push(cards[0]); 
        uint256 pCard3 = cards[0] % 13;
        bet.player.hand.push(cardValues[pCard3]);
        calculate(bet.player);
        if(bet.player.score > 21) {
            bet.completed = true;
            emit BetCompleted(betId, 0);
        }else if(bet.player.score == 21) {
            revealDealerCard(betId);
        }
        emit PlayerHit(betId, cards[0]);
    }

    /**
     * @param betId Game id 
     * @notice If the player choses to stand, we reveal dealer's next card and conclude game.
     */
    function stand(uint256 betId) public playerChecks(betId) {
        revealDealerCard(betId);
    }

    //Internal function used to calculate a hand score.
    function calculate(Player storage player) internal {
        uint8 numOfAces;
        uint8 playerScore;
        for(uint8 i = 0; i < player.hand.length; i++ ) {
            playerScore += player.hand[i];
            if(player.hand[i] == 11) {
                numOfAces++;
            }
            while(numOfAces > 0 && playerScore > 21) {
                playerScore -= 10;
                numOfAces--;
            }
            player.score = playerScore;
        }
    }

    /**
     * Internal function used for revealing dealer's second card.
     * @param betId Game id
     * @notice Randomness of the card is based on the cards length of the hand.
     * @notice While the dealer score is less than 17, we provide another card to the dealer.
     * @notice After the dealer's score goes above 16, we will calculate the pay outs.
     */
    function revealDealerCard(uint256 betId) internal {
        Game storage bet = GameId[betId];
        uint256[] memory card = drawCard(betId, 1);

        uint8 length = uint8(bet.dealer.hand.length + 1);
        uint256 dealerCard2 = card[0] * length;
        uint256 cardValue = dealerCard2;
        while(cardValue > 52) {
            cardValue -= 52;
        }
        bet.dealer.cards.push(cardValue);
        uint256 dCard2 = dealerCard2 % 13;
        bet.dealer.hand.push(cardValues[dCard2]);
        calculate(bet.dealer);
        while(bet.dealer.score < 17) {
            dealerHit(betId);
        }
        checkWinner(betId);
        emit DealerSecondCard(betId, cardValue);
    } 

    /**
     * Internal function called, while the dealer's score is below 17
     * @notice Randomness of the card is based on the cards length of the hand.
     */
    function dealerHit(uint256 betId) internal {
        Game storage bet = GameId[betId];
        
        uint256[] memory card = drawCard(betId, 1);
        uint8 length = uint8(bet.dealer.hand.length + 1);
        uint256 newCard = card[0] * length;
        uint256 cardValue = newCard;
        while(cardValue > 52) {
            cardValue -= 52;
        }
        bet.dealer.cards.push(cardValue);
        uint256 newCardForDealer = newCard % 13;
        bet.dealer.hand.push(cardValues[newCardForDealer]);
        calculate(bet.dealer);
        emit DealerHit(betId, cardValue);
    }

    /**
     * Internal function called when dealer's score goes above 16
     * @notice internally calls calculatePayOut function.
     * @notice update total winnings of the player.
     */
    function checkWinner(uint256 betId) internal {
        Game storage bet = GameId[betId];
        bet.completed = true;
        calculatePayOut(betId, bet.player);
        uint256 winAmount;
        if(bet.splitPlayer.hand.length > 0){
           calculatePayOut(betId, bet.splitPlayer); 
           winAmount = bet.player.winningAmount + bet.splitPlayer.winningAmount;
        }else {
          winAmount = bet.player.winningAmount;  
        }
        if(isEther[betId]){
            winningsInEther[bet.bettor] += winAmount;
        }else{
            winningsInToken[bet.bettor][tokenAddress[betId]] += winAmount;
        }
        emit BetCompleted(betId, winAmount);
    }

    // Internal function used for calculating and updating the winning amount of the player.
    function calculatePayOut(uint256 betId, Player storage player) internal {
        Game storage bet = GameId[betId];
        if(bet.player.hand.length == 2 && bet.player.score == 21 && bet.dealer.score != 21) {
            player.winningAmount = (25 * bet.player.betAmount)/10;
        }else if(player.score > bet.dealer.score || bet.dealer.score > 21) {
            player.winningAmount = 2 * player.betAmount;
        }else if(player.score == bet.dealer.score) {
            player.winningAmount = player.betAmount;
        }       
    }

    //Owner can set Seed Word
    function setSeedWord(uint256 seed) external onlyAuthorised {
        seedWord = seed;
    }

    //Maximum and minimum a player can bet
    function setBetLimit(uint256 min, uint256 max) external onlyAuthorised {
        minBet = min;
        maxBet = max;
    }

    //Add admins
    function addAdmins(address member) external onlyAuthorised {
        isAdmin[member] = true;
    }

    //Checks Ether balance of the contract
    function reserveInEther() public view returns (uint256) {
        return address(this).balance;
    }

    //Checks ERC20 Token balance.
    function reserveInToken(address ERC20Address) public view returns(uint) {
        return IERC20(ERC20Address).balanceOf(address(this));
    }
    
    //Owner can whitelist allowed token for placing bets
    function addWhitelistTokens(address ERC20Address) external onlyAuthorised {
        require(isWhitelistedToken[ERC20Address] == false, 'Token already whitelisted');
        isWhitelistedToken[ERC20Address] = true;
    }

    //Owner can remove whitelist tokens
    function removeWhitelistTokens(address ERC20Address) external onlyAuthorised {
        require(isWhitelistedToken[ERC20Address], 'Token is not whitelisted');
        isWhitelistedToken[ERC20Address] = false;
    }

    //Allows users to withdraw their Ether winnings.
    function withdrawEtherWinnings(uint256 amount) external nonReentrant {
        require(winningsInEther[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
        require(reserveInEther() >= amount,'Contract does not have enough balance');
        winningsInEther[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit EthWithdrawn(msg.sender, amount);
    }

    //Allows users to withdraw their ERC20 token winnings
    function withdrawTokenWinnings(address ERC20Address, uint256 amount) external nonReentrant {
        require(winningsInToken[msg.sender][ERC20Address] >= amount, "You do not have requested winning amount to withdraw");
        require(reserveInToken(ERC20Address) >= amount,'Contract does not have enough balance');
        winningsInToken[msg.sender][ERC20Address] -= amount;
        IERC20(ERC20Address).safeTransfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, ERC20Address, amount);
    }

    //Owner is allowed to withdraw the contract's Ether balance.
    function withdrawEther(address _receiver, uint256 _amount) external nonReentrant onlyAuthorised  {
        require(reserveInEther() >= _amount,'Sorry, Contract does not have enough balance');
        payable(_receiver).transfer(_amount);
    }

    //Owner is allowed to withdraw the contract's token balance.
    function TokenWithdraw(address ERC20Address, address _receiver, uint256 _amount) external nonReentrant onlyAuthorised {
        require(reserveInToken(ERC20Address) >= _amount, 'Sorry, Contract does not have enough token balance');
        bool sent = IERC20(ERC20Address).transfer(_receiver, _amount);
        require(sent, "Transaction inturrupted");
    }

    function _inc(uint256 index) private pure returns (uint256) {
    unchecked {
      return index + 1;
        }
    }

    receive() external payable {

    } 

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Roulette is ReentrancyGuard {
  using SafeERC20 for IERC20;
  uint256 public BetId;
  uint32 private deadlineOfGame = 90;                
  uint256 private maxBet;
  uint256 private minBet;
  uint8[] payouts = [2,3,3,2,2,36];
  uint8[] numberRange = [1,2,2,1,1,36];
  uint256 private seedWord;
  address private owner;

  enum BetTypes {
    colour,
    column,
    dozen,
    eighteen,
    modulus,
    number
  }

  /*
      Depending on the BetType, number will be:
      color: 0 for black, 1 for red
      column: 0 for left, 1 for middle, 2 for right
      dozen: 0 for first, 1 for second, 2 for third
      eighteen: 0 for low, 1 for high
      modulus: 0 for even, 1 for odd
      number: number
  */

  struct SinglePlayerBet {
    address bettorAddress;
    BetTypes[] betType;
    uint8[] number;
    uint256[] betAmount;
    uint256 winningAmount; 
    uint256 randomNumber;  
  }

  struct Room {
    bool gameStarted;
    uint256 time;
    uint256 randomNumber;
    bool betCompleted;
  }

  struct UserBet {
    address bettorAddress;
    BetTypes[] betType;
    uint8[] number;
    uint256[] betAmount;
    uint256 winningAmount;
    address tokenAddress;
    bool isEther;
  }

  event BetPlacedInEther(
    uint256 _betId,
    address _playerAddress,
    uint256[] _betAmount,
    BetTypes[] _betType,
    uint8[] _number
  );

  event BetPlacedInToken(
    uint256 _betId,
    address _playerAddress,
    address _tokenAddress,
    uint256[] _betAmount,
    BetTypes[] _betType,
    uint8[] _number
  );

  event RouletteStarted(uint256 indexed betId, uint indexed time);
  event SingleBetCompleted(uint256 indexed _betId, address indexed _player, uint256 _randomNumber, uint256 indexed _winningAmount);
  event BetCompleted(uint256 indexed _betId, uint256 indexed _randomNumber);
  event EthWithdrawn(address indexed player, uint256 indexed amount);
  event TokenWithdrawn(address indexed player, address indexed tokenAddress, uint256 indexed amount);

  mapping(address => bool) public isWhitelistedToken;                   //To check the allowed ERC20 tokens for placing bets
  mapping(uint256 => SinglePlayerBet) private betIdToBets;              // Mapping single player bets to an Id
  mapping(uint256 => Room) public RoomIdToBets;                         //Mapping multi player rooms with id
  mapping(uint256 => mapping(address => UserBet)) private players;      //Details of a player in a room
  mapping(uint256 => mapping(address => bool)) public participated;     //To check whether a player has participated in a room
  mapping(uint256 => address[]) private participants;                   //For checking players in a room
  mapping(address => uint256) public winningsInEther;                  //Player Winnings in Ether
  mapping(address => mapping(address => uint256)) public winningsInToken;   //Player ERC20 token winnings
  mapping(address => bool) public isAdmin;                              //returns if an address is admin
  mapping(uint256 => bool) public betIdExists;                          //Returns if bet with Id exists

 constructor() {
  owner = msg.sender;
}

 modifier onlyAdmins() {
  require(isAdmin[msg.sender] || msg.sender == owner, 'not allowed to call this function');
_;
 }

 modifier checkDeadline(uint256 roomId) {
  require(betIdExists[roomId] == true, "Room with the provided id does not exist");
  Room storage b = RoomIdToBets[roomId];
  if(participants[roomId].length == 0){
    b.time = block.timestamp;
    emit RouletteStarted(roomId, block.timestamp);
  }
  else {
    require(block.timestamp < b.time + deadlineOfGame, 'deadline for this bet is passed');
  }
    _;
  }
 
  /** 
   * @dev For placing the bet.
   * @param _betType to choose the bet type. 
   * @param number based on the bet type, a number should be chosen.
   * @param _isEther to check whether is selected network is Ether or ERC20 token.
   * @param ERC20Address to know which token is chosen if the the network connected is not Ether.
   * @notice Only whitelisted tokens are allowed for payments.
   * @param amount amount of token user wants to bet. Should approve the contract to use it first.
   */
  function singlePlayerBet(BetTypes[] memory _betType, uint8[] memory number, bool _isEther, address ERC20Address, uint256[] memory amount) external payable {
    require(_betType.length == number.length && number.length == amount.length); 
      BetId = _inc(BetId); 
      uint256 betValue ;  
      for(uint i = 0; i < _betType.length; i++) {
        uint8 temp = uint8(_betType[i]);
        require(number[i] <= numberRange[temp], "Number should be within range");
        require(amount[i] >= minBet, 'Bet Value should be greater than minimum bet');
        betValue += amount[i];
      }
      require(betValue <= maxBet, 'Bet Value should be lesser than maximum bet');

        SinglePlayerBet storage u = betIdToBets[BetId];
        u.bettorAddress = msg.sender;
        u.betType = _betType;
        u.number = number;
        u.betAmount = amount;

      if(_isEther){ 
        require(msg.value == betValue, 'Bet value should be same as the sum of bet amounts');            
        emit BetPlacedInEther(BetId, msg.sender, amount, _betType, number );
        }
    else {     
        require(isWhitelistedToken[ERC20Address] == true, 'Token not allowed for placing bet');
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this), betValue);
        emit BetPlacedInToken(BetId, msg.sender, ERC20Address, amount, _betType, number );
        }
        spinWheel( BetId, _isEther, ERC20Address);     
    }

  //Internal function called by SinglePlayerBet function to update random number and winning value.
  function spinWheel(uint256 _betId, bool isEther, address ERC20Address) internal  {
    SinglePlayerBet storage bet = betIdToBets[_betId];
    bet.randomNumber = randomNumber(_betId, bet.betType.length); 
    for(uint i = 0; i < bet.betType.length; i++){
      bool won = false;
      won = checkWinner(uint(bet.betType[i]), bet.randomNumber, bet.number[i]);
      uint256 typeOfBet = uint256(bet.betType[i]);
      /* if winning bet, add to player winnings balance */
      if (won && isEther) {
        winningsInEther[bet.bettorAddress] += bet.betAmount[i] * payouts[typeOfBet];
        bet.winningAmount += bet.betAmount[i] * payouts[typeOfBet];
      }
      else if (won && isEther == false) {
        winningsInToken[bet.bettorAddress][ERC20Address] += bet.betAmount[i] * payouts[typeOfBet];
        bet.winningAmount += bet.betAmount[i] * payouts[typeOfBet];
      }
    }
    emit SingleBetCompleted(_betId, bet.bettorAddress, bet.randomNumber, bet.winningAmount);
  }

  // Internal function to check if the bet type has won.
   function checkWinner(uint256 betType, uint256 num, uint256 number) internal pure returns(bool){
    bool won = false;
       if (num == 0) {
        won = (betType == uint256(BetTypes.number) && number == 0);                   /* bet on 0 */
      } else {
        if (betType == uint256(BetTypes.number)) { 
          won = (number == num);                              /* bet on number */
        } else if (betType == uint256(BetTypes.modulus)) {
          if (number == 0) won = (num % 2 == 0);              /* bet on even */
          if (number == 1) won = (num % 2 == 1);              /* bet on odd */
        } else if (betType == uint256(BetTypes.eighteen)) {            
          if (number == 0) won = (num <= 18);                 /* bet on low 18s */
          if (number == 1) won = (num >= 19);                 /* bet on high 18s */
        } else if (betType == uint256(BetTypes.dozen)) {                               
          if (number == 0) won = (num <= 12);                 /* bet on 1st dozen */
          if (number == 1) won = (num > 12 && num <= 24);     /* bet on 2nd dozen */
          if (number == 2) won = (num > 24);                  /* bet on 3rd dozen */
        } else if (betType == uint256(BetTypes.column)) {               
          if (number == 0) won = (num % 3 == 1);              /* bet on left column */
          if (number == 1) won = (num % 3 == 2);              /* bet on middle column */
          if (number == 2) won = (num % 3 == 0);              /* bet on right column */
        } else if (betType == uint256(BetTypes.colour)) {
          if (number == 0) {                                     /* bet on black */
            if (num <= 10 || (num >= 19 && num <= 28)) {
              won = (num % 2 == 0);
            } else {
              won = (num % 2 == 1);
            }
          } else {                                                 /* bet on red */
            if (num <= 10 || (num >= 19 && num <= 28)) {
              won = (num % 2 == 1);
            } else {
              won = (num % 2 == 0);
            }
          }
        }
      }
      return(won);
    }

    //Internal function used for generating random number
  function randomNumber(uint256 betId, uint256 betLength) internal view returns(uint256) {
    uint256 num = (uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,block.number, betId, betLength, seedWord))) + 1) % 37; 
    return num;
  }

  //returns struct details for the betId
  function checkBet(uint256 betId) external view returns(SinglePlayerBet memory) {
    return betIdToBets[betId];
  }

  /*
  Roulette game to be started by the owner. 
  Users are allowed to bet after the game is started until the deadline.
  */
  function startGame(uint256 betId) external onlyAdmins {
    require(!betIdExists[betId], "betId with this number already exists");
      Room storage b = RoomIdToBets[betId];
      b.gameStarted = true;
      betIdExists[betId] = true;
    }

   /** 
   * @dev For placing the bet.
   * @param _betType to choose the bet type. 
   * @param number based on the bet type, a number should be chosen.
   * Check the comments above for the available betTypes.
   * @param _isEther to check whether is selected network is Ether or ERC20 token.
   * @param ERC20Address to know which token is chosen if the the network connected is not Ether.
   * Only whitelisted tokens are allowed for payments.
   * @param amount amount of token user wants to bet. Should approve the contract to use it first.
   */
  function multiPlayerBet(uint256 roomId, BetTypes[] memory _betType, uint8[] memory number, bool _isEther, address ERC20Address, uint256[] memory amount) external payable checkDeadline(roomId) nonReentrant {
    require(participants[roomId].length < 6, "Maxium spots filled");
    Room storage b = RoomIdToBets[roomId];
    require(b.betCompleted == false, "Spinning of wheel is completed"); 
    require(participated[roomId][msg.sender] == false, "Already participated");
    require(_betType.length == number.length && number.length == amount.length);
    uint256 betValue;
      for(uint i = 0; i < _betType.length; i++) {
        uint8 temp = uint8(_betType[i]);
        require(number[i] <= numberRange[temp], "Number should be within range");
        require(amount[i] > 0, 'Bet Value should be greater than minimum bet');
        betValue += amount[i];
      }
        require(betValue <= maxBet, 'Bet Value should be lesser than maximum bet');
        participants[roomId].push(msg.sender);
        participated[roomId][msg.sender] = true;

        UserBet storage bet =  players[roomId][msg.sender];
        bet.bettorAddress = msg.sender;
        bet.betType = _betType;
        bet.number = number;
        bet.betAmount = amount;

      if(_isEther){ 
        require(msg.value == betValue, 'Bet value should be same as the bet amount');       
        bet.isEther = true;
        emit BetPlacedInEther(roomId, msg.sender, amount, _betType, number );
        }
      else {
        require(isWhitelistedToken[ERC20Address], 'Token not allowed for placing bet');
        bet.tokenAddress = ERC20Address;
        bet.isEther = false;  
        IERC20(ERC20Address).safeTransferFrom(msg.sender, address(this), betValue);  
        emit BetPlacedInToken(roomId, msg.sender, ERC20Address, amount, _betType, number );
      }
    }

  /*
  Checks if the player has won the bet.
  Calculate the payouts for the winners of all bet types.
  Adds the winning amount to the user winnings.
  */
  function spinWheelForRoom(uint256 roomId) external onlyAdmins {
    Room storage room = RoomIdToBets[roomId];
    require(room.betCompleted == false, "Spinning of wheel is completed");
    require(participants[roomId].length > 0, "No player joined");
    room.randomNumber = randomNumber(roomId, participants[roomId].length);
    for(uint j = 0; j < participants[roomId].length; j++) {
      address playerAddress = participants[roomId][j];   
      UserBet storage b = players[roomId][playerAddress];
      for(uint i = 0; i < b.betType.length; i++){
        bool won = false;
      won = checkWinner( uint(b.betType[i]), room.randomNumber, b.number[i]);
      uint256 typeOfBet = uint256(b.betType[i]);
      /* if winning bet, add to player winnings balance */
      if (won && b.isEther) {
        winningsInEther[b.bettorAddress] += b.betAmount[i] * payouts[typeOfBet];
        b.winningAmount += b.betAmount[i] * payouts[typeOfBet];
      }
      else if (won && b.isEther == false) {
        winningsInToken[b.bettorAddress][b.tokenAddress] += b.betAmount[i] * payouts[typeOfBet];
        b.winningAmount += b.betAmount[i] * payouts[typeOfBet];
      }   
     } 
     room.betCompleted = true;
    emit BetCompleted(roomId, room.randomNumber);
    }  
  }

  //Owner can set Seed Word
  function setSeedWord(uint256 seed) external onlyAdmins {
    seedWord = seed;
  }

  //Maximum and minimum a player can bet
  function betLimit(uint256 min, uint256 max) external onlyAdmins {
    minBet = min;
    maxBet = max;
  }

  //To set the waiting time in a room.
  function setDeadline(uint32 sec) external onlyAdmins {
    deadlineOfGame = sec;
  }

  //returns player details in a room
  function playerBetInRoom(uint256 roomId, address player) external view returns(UserBet memory) {
    return players[roomId][player];
  }

  function addAdmins(address member) external onlyAdmins {
    isAdmin[member] = true;
  }
  
  //Owner can whitelist allowed token for placing bets
  function addWhitelistTokens(address ERC20Address) external onlyAdmins {
    require(isWhitelistedToken[ERC20Address] == false, 'Token already whitelisted');
    isWhitelistedToken[ERC20Address] = true;
  }

  //Owner can remove whitelist tokens
  function removeWhitelistTokens(address ERC20Address) external onlyAdmins {
    require(isWhitelistedToken[ERC20Address] == true, 'Token is not whitelisted');
    isWhitelistedToken[ERC20Address] = false;
  }

  //Allows users to withdraw their Ether winnings.
  function withdrawEtherWinnings(uint256 amount) external nonReentrant {
    require(winningsInEther[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInEther() >= amount,'Contract does not have enough balance');
    winningsInEther[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
    emit EthWithdrawn(msg.sender, amount);
  }

  //Allows users to withdraw their ERC20 token winnings
  function withdrawTokenWinnings(address ERC20Address, uint256 amount) external nonReentrant {
    require(winningsInToken[msg.sender][ERC20Address] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInToken(ERC20Address) >= amount,'Contract does not have enough balance');
    winningsInToken[msg.sender][ERC20Address] -= amount;
    IERC20(ERC20Address).safeTransfer(msg.sender, amount);
    emit TokenWithdrawn(msg.sender, ERC20Address, amount);
  }

  //Get participants of a room
  function getPlayers(uint roomId) public view returns(address[] memory) {
    return participants[roomId];
  } 

  //Checks Ether balance of the contract
  function ReserveInEther() public view returns (uint256) {
    return address(this).balance;
  }

  //Checks ERC20 Token balance.
  function ReserveInToken(address ERC20Address) public view returns(uint) {
    return IERC20(ERC20Address).balanceOf(address(this));
  }

  //Owner is allowed to withdraw the contract's Ether balance.
  function withdrawEther(address _receiver, uint256 _amount) external nonReentrant onlyAdmins  {
    require(ReserveInEther() >= _amount,'Sorry, Contract does not have enough balance');
    payable(_receiver).transfer(_amount);
  }

  //Owner is allowed to withdraw the contract's token balance.
  function TokenWithdraw(address ERC20Address, address _receiver, uint256 _amount) external nonReentrant onlyAdmins {
    require(ReserveInToken(ERC20Address) >= _amount, 'Sorry, Contract does not have enough token balance');
    bool sent = IERC20(ERC20Address).transfer(_receiver, _amount);
    require(sent, "Transaction inturrupted");
  }

  function _inc(uint256 index) private pure returns (uint256) {
    unchecked {
      return index + 1;
    }
  }

  receive() external payable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}