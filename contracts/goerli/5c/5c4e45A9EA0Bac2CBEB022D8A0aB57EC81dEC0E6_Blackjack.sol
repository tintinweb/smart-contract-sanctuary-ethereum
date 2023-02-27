// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./priceFeeds/PriceConsumerV3.sol";

contract Blackjack {
    PriceConsumerV3 price = new PriceConsumerV3();

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
    address public rewardToken;
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
    mapping(address => int) public rewards;

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

    // modifier betLimit(bool isEth, uint256 amount) {
    //     if(isEth) {
    //         require(msg.value >= minBet, 'Bet Value should be greater than minimum bet');
    //         require(msg.value <= maxBet, 'Bet Value should be lesser than maximum bet');
    //     } else {
    //         require(amount >= minBet, 'Bet Value should be greater than minimum bet');
    //         require(amount <= maxBet, 'Bet Value should be lesser than maximum bet');
    //     }
    //     _;
    // }

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
    function play(bool isEth, address tokenAddr, uint256 amount) public payable {
        ++currentBetId;
        Game storage bet = GameId[currentBetId];
        bet.startTime = block.timestamp;
        bet.bettor = msg.sender;

        if(isEth) {
            bet.player.betAmount = msg.value;
            isEther[currentBetId] = true;
            emit BetPlaced(currentBetId, bet.startTime, msg.sender, msg.value);
        }
        else{
            require(isWhitelistedToken[tokenAddr] == true, 'Token not allowed for placing bet');
            IERC20(tokenAddr).transferFrom(msg.sender, address(this), amount);
            tokenAddress[currentBetId] = tokenAddr;
            bet.player.betAmount = amount;
            emit BetPlaced(currentBetId, bet.startTime, msg.sender, amount);
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
            IERC20(tokenAddress[betId]).transferFrom(msg.sender, address(this), bet.player.betAmount);
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
            IERC20(tokenAddress[betId]).transferFrom(msg.sender, address(this), amount);
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
        rewardDistribution();  
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

    //Add the reward balance
    function rewardDistribution() internal {
        int ethPrice = price.getLatestPrice();
        int payableReward = ethPrice * 10 ** 8;
        rewards[msg.sender] += payableReward;
    }

    function claim() external  {
        require(IERC20(rewardToken).balanceOf(address(this)) >= uint(rewards[msg.sender]), "Contract does not have enough balance");
        uint256 amount = uint(rewards[msg.sender]);
        rewards[msg.sender] = 0;
        IERC20(rewardToken).transfer(msg.sender, amount);
    }

    function setTokenAddress(address _rewardToken) external onlyAuthorised {
        rewardToken = _rewardToken;
    }

    //Owner can set Seed Word
    function setSeedWord(uint256 seed) external onlyAuthorised {
        seedWord = seed;
    }

    //Maximum and minimum a player can bet
    // function setBetLimit(uint256 min, uint256 max) external onlyAuthorised {
    //     minBet = min;
    //     maxBet = max;
    // }

    //Add admins
    function addAdmins(address member) external onlyAuthorised {
        isAdmin[member] = true;
    }

    //Checks Ether balance of the contract
    function reserveInEther() public view returns (uint256) {
        return address(this).balance;
    }
    
    //Owner can whitelist allowed token for placing bets
    function addWhitelistTokens(address ERC20Address) external onlyAuthorised {
        // require(isWhitelistedToken[ERC20Address] == false, 'Token already whitelisted');
        isWhitelistedToken[ERC20Address] = true;
    }

    //Owner can remove whitelist tokens
    function removeWhitelistTokens(address ERC20Address) external onlyAuthorised {
        // require(isWhitelistedToken[ERC20Address], 'Token is not whitelisted');
        isWhitelistedToken[ERC20Address] = false;
    }

    //Allows users to withdraw their Ether winnings.
    function withdrawEtherWinnings(uint256 amount) external  {
        // require(winningsInEther[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
        // require(reserveInEther() >= amount,'Contract does not have enough balance');
        winningsInEther[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit EthWithdrawn(msg.sender, amount);
    }

    //Allows users to withdraw their ERC20 token winnings
    function withdrawTokenWinnings(address ERC20Address, uint256 amount) external  {
        // require(winningsInToken[msg.sender][ERC20Address] >= amount, "You do not have requested winning amount to withdraw");
        // require(IERC20(rewardToken).balanceOf(address(this)) >= amount,'Contract does not have enough balance');
        winningsInToken[msg.sender][ERC20Address] -= amount;
        IERC20(ERC20Address).transfer(msg.sender, amount);
        emit TokenWithdrawn(msg.sender, ERC20Address, amount);
    }

    //Owner is allowed to withdraw the contract's Ether balance.
    function withdrawEther(address _receiver, uint256 _amount) external  onlyAuthorised  {
        // require(reserveInEther() >= _amount,'Sorry, Contract does not have enough balance');
        payable(_receiver).transfer(_amount);
    }

    //Owner is allowed to withdraw the contract's token balance.
    function TokenWithdraw(address ERC20Address, address _receiver, uint256 _amount) external  onlyAuthorised {
        require(IERC20(rewardToken).balanceOf(address(this)) >= _amount, 'Sorry, Contract does not have enough token balance');
        bool sent = IERC20(ERC20Address).transfer(_receiver, _amount);
        require(sent, "Transaction inturrupted");
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
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Sepolia
     * Aggregator: BTC/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}