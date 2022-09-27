// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./RandomNumber.sol";

contract DiceGame is Initializable, RandomNumber {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    AggregatorV3Interface internal s_priceFeed;
    uint256 private constant BP = 1e18;
    uint16 public s_houseEdge; // Minimum winning percentage for the casino
    address payable public s_feeRecipient;
    uint256 public s_linkPremium;
    uint256 public s_maxBetAmount;
    mapping(address => bool) public s_isTokenAllowed;
    address[] public s_allowedTokens;

    event RequestId(uint256 requestId);

    function initialize(
        uint64 subscriptionId,
        address vrfCoordinator_,
        bytes32 keyHash_,
        address linkToken_,
        address payable feeRecepient,
        uint16 houseEdge,
        uint256 linkPremium_,
        uint256 maxBetAmount,
        address priceFeed
    ) public virtual initializer {
        __RandomNumber_init(
            subscriptionId,
            vrfCoordinator_,
            keyHash_,
            linkToken_
        );
        require(
            houseEdge >= 100 && houseEdge < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        require(feeRecepient != address(0), "DiceGame: Invalid fee recipient");
        s_feeRecipient = feeRecepient;
        s_houseEdge = houseEdge;
        s_linkPremium = linkPremium_;
        s_maxBetAmount = maxBetAmount;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /// @notice Allows to replenish the contract with the native token ETH, BNB, MATIC, etc...
    receive() external payable {}

    /// @notice Allows the users to bet for a guess random number sending a range of numbers in which they think the random number will be generated
    /// @dev the user has to send in the value of the transaction the native token of the bet + the chainlink fees after calculating it with the function estimateChainlinkFee
    /// @dev the user could also bet in allowed erc20 tokens but still need to send in the value of the transaction the chainlinkn fee
    /// @param lowerNumber Lower number of the range
    /// @param upperNumber Higher number of the range
    /// @param betAmount The amount to bet
    /// @param token Token address to use for the bet, use address zero 0x0000000000000000000000000000000000000000 for native token
    function playGame(
        uint16 lowerNumber,
        uint16 upperNumber,
        uint256 betAmount,
        IERC20Upgradeable token
    ) external payable {
        uint256 contractBalance;
        uint256 paidFee;
        if (token == IERC20Upgradeable(address(0))) {
            paidFee = msg.value - betAmount;
            contractBalance = getAvailablePrize(token) - paidFee;
        } else {
            require(s_isTokenAllowed[address(token)], "Token is not allowed");

            token.safeTransferFrom(msg.sender, address(this), betAmount);
            paidFee = msg.value;
            contractBalance = getAvailablePrize(token);
        }

        (, uint256 multiplier, uint256 prizeAmount) = calculateBet(
            lowerNumber,
            upperNumber,
            betAmount
        );

        require(
            prizeAmount <= contractBalance,
            "DiceGame: Insufficient balance to accept bet"
        );
        require(
            prizeAmount > betAmount,
            "DiceGame: Estimated prize is equal to or less than the bet amount"
        );

        uint256 chainlinkFeeNativeToken = estimateChainlinkFee(tx.gasprice);

        require(
            paidFee >= chainlinkFeeNativeToken,
            "DiceGame: Insufficient payment for chainlink fee"
        );
        (bool success, ) = s_feeRecipient.call{value: paidFee}("");

        require(success, "DiceGame: Error while paying feeRecepient");
        uint256 requestId = requestRandomWords(
            lowerNumber,
            upperNumber,
            prizeAmount,
            betAmount,
            multiplier,
            token
        );
        emit RequestId(requestId);
    }

    /// @notice Returns the current number of tokens allowed for bets
    /// @dev It can be used combined with the function s_allowedTokens(index) to bring the token addresses
    /// @return Returns the length of the allowed tokens
    function getAllowedTokensLength() external view returns (uint256) {
        return s_allowedTokens.length;
    }

    /// @notice Allows the owner to edit the house edge which is the amount of numbers that cannot be used
    /// @dev The minimum house edge is 1% or 1.00 or 100, so at least 100 of 10001 numbers cannot be used by the user
    /// @param houseEdge new house edge to be used in the contract
    function editHouseEdge(uint16 houseEdge) external onlyOwner {
        require(
            houseEdge >= 100 && houseEdge < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        s_houseEdge = houseEdge;
    }

    /// @notice Allows the owner to withdraw any tokens from the contract
    /// @dev The owner can call this function to get the native token or erc20 tokens from the contract balance
    /// @param _token is the token address to withdraw
    /// @param _amount is the amount in wei of tokens to withdraw
    function withdraw(IERC20Upgradeable _token, uint256 _amount)
        external
        onlyOwner
    {
        if (_token == IERC20Upgradeable(address(0))) {
            // allow to rescue ether
            payable(owner()).transfer(_amount);
        } else {
            _token.safeTransfer(owner(), _amount);
        }
    }

    // The function will adjust the multiplier to the closest possible multiplier
    function getBiggestMultiplierFromBet(
        uint256 betAmount,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier) {
        require(
            betAmount <= s_maxBetAmount,
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        // Formula: multiplier = (getAvailablePrize() + Bet) / Bet
        // This gives us the maximum multiplier possible
        multiplier = ((getAvailablePrize(token) + betAmount) * BP) / betAmount;
        if (multiplier > getMaxMultiplier()) multiplier = getMaxMultiplier();
        // Calculates the closest multiplier
        uint256 upperNum = getWinningChanceFromMultiplier(multiplier);
        (, multiplier, ) = calculateBet(uint16(1), uint16(upperNum), 1);
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
    }

    /// @notice Show the numbers produced by chainlink using the randomness
    /// @dev The randomness comes from the chainlink event
    //  @dev RandomWordsFulfilled(requestId, randomness, payment, success)
    /// @param randomness source of randomness used to generate the numbers
    /// @return chainlinkRawNumber big number produced by chanlink
    /// @return parsedNumber raw number formated to be in the range from 0 to 1000
    function getNumberFromRandomness(uint256 randomness)
        external
        pure
        returns (uint256 chainlinkRawNumber, uint256 parsedNumber)
    {
        chainlinkRawNumber = uint256(keccak256(abi.encode(randomness, 0)));
        parsedNumber = chainlinkRawNumber % (MAX_NUMBER + 1);
    }

    /// @notice Allows to estimate the winning chance, multiplier, and prize amount
    /// @dev To choose a single number send the same number in lower and upper inputs
    /// @param lowerNumber Lower number of the range
    /// @param upperNumber Higher number of the range
    /// @param betAmount The amount to bet
    /// @return winningChance The winning chance percentage = (winningChance/10001 * 100)
    /// @return multiplier Multiplier: multiplier/1e18 or multiplier/1000000000000000000
    /// @return prizeAmount Prize amount = prizeAmount/1e18  or prizeAmount/1000000000000000000
    function calculateBet(
        uint16 lowerNumber,
        uint16 upperNumber,
        uint256 betAmount
    )
        public
        view
        returns (
            uint256 winningChance,
            uint256 multiplier,
            uint256 prizeAmount
        )
    {
        require(
            betAmount > 0 && betAmount <= s_maxBetAmount,
            "DiceGame: Invalid bet amount"
        );
        require(
            lowerNumber <= MAX_NUMBER &&
                upperNumber <= MAX_NUMBER &&
                lowerNumber <= upperNumber,
            "DiceGame: Invalid range"
        );

        // Checks if there is enough room in the range for the house edge.
        uint16 leftOver = lowerNumber == upperNumber
            ? (MAX_NUMBER + 1) - 1
            : lowerNumber + MAX_NUMBER - upperNumber;
        require(leftOver >= s_houseEdge, "DiceGame: Invalid boundaries");

        winningChance = (MAX_NUMBER + 1) - leftOver;
        multiplier = (((MAX_NUMBER + 1) - s_houseEdge) * BP) / winningChance;
        prizeAmount = (betAmount * multiplier) / BP;
    }

    // It produces the closest possible multipler based to the bet and profit
    function getMultiplierFromBetAndProfit(
        uint256 betAmount,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        require(
            betAmount <= s_maxBetAmount,
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        require(
            profit <= getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
        require(profit > 0, "DiceGame: profit has to be greater than 0");
        // Formula: multiplier = (bet+profit) / bet
        multiplier = ((betAmount + profit) * BP) / betAmount;

        uint256 upperNum = getWinningChanceFromMultiplier(multiplier);
        (, multiplier, ) = calculateBet(uint16(1), uint16(upperNum), 1);
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
    }

    // Expects the multiplier to be in wei format 2x equals 2e18
    // Returns the quantity of numbers that can be used.
    // It chooses the closest winning chance to the provided multiplier
    // Example output: winningChance = 10 means 10 different numbers.
    function getWinningChanceFromMultiplier(uint256 multiplier)
        public
        view
        returns (uint256 winningChance)
    {
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        uint256 winningChanceBeforeRounding = ((((MAX_NUMBER + 1) -
            s_houseEdge) * BP) * BP) / multiplier;

        // Before rounding up it uses the current winning chance without decimals to see
        // If it is more than the desired multiplier else add 1 to the winning chance
        (, uint256 multiplierNoRounding, ) = calculateBet(
            uint16(1),
            uint16(winningChanceBeforeRounding / BP),
            1
        );
        if (multiplierNoRounding > multiplier)
            winningChance = (winningChanceBeforeRounding + BP) / BP;
        else {
            winningChance = winningChanceBeforeRounding / BP;
        }
    }

    // The function will adjust the provided multiplier to the closest possible multiplier
    // And then calculate the profit based on that multiplier
    // The upperNum can be used to get the multiplier used for the obtained profit
    function getProfitFromBetAndMultiplier(
        uint256 betAmount,
        uint256 multiplier,
        IERC20Upgradeable token
    ) public view returns (uint256 profit, uint256 upperNum) {
        require(
            betAmount <= s_maxBetAmount,
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        upperNum = getWinningChanceFromMultiplier(multiplier);
        (, , uint256 prizeAmount) = calculateBet(
            uint16(1),
            uint16(upperNum),
            betAmount
        );
        profit = prizeAmount - betAmount;
        require(
            profit <= getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
    }

    function getMultiplierFromBetAndChance(
        uint256 betAmount,
        uint256 winningChance,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        require(
            betAmount <= s_maxBetAmount,
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
        require(
            winningChance <= getMaxWinningChance(),
            "DiceGame: winning chance is greater than the max winning chance"
        );

        require(winningChance > 0, "DiceGame: winning chance cannot be 0");

        (, multiplier, ) = calculateBet(uint16(1), uint16(winningChance), 1);
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        require(
            (((multiplier * betAmount) / BP) - betAmount) <=
                getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
    }

    // The upperNum can be used to calculate the exact multiplier used for the calculation of the bet amount
    function getBetFromMultiplierAndProfit(
        uint256 multiplier,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 betAmount, uint256 upperNum) {
        require(
            multiplier >= getMinMultiplier(),
            "DiceGame: expected multiplier cannot be lower than min multiplier"
        );
        require(
            multiplier <= getMaxMultiplier(),
            "DiceGame: expected multiplier is greater than the max multiplier"
        );
        require(
            profit <= getAvailablePrize(token),
            "DiceGame: current balance cannot pay expected profit"
        );
        // Moves the multiplier to the closest possible multiplier
        upperNum = getWinningChanceFromMultiplier(multiplier);
        (, multiplier, ) = calculateBet(uint16(1), uint16(upperNum), 1);
        // formula = Bet =  profit / multiplier - 1
        betAmount = (profit * BP) / (multiplier - BP);
        require(
            betAmount <= s_maxBetAmount,
            "DiceGame: bet amount cannot be greater than the max bet amount"
        );
    }

    // The max multiplier comes when a user chooses only one number between 0-10001
    function getMaxMultiplier() public view returns (uint256 maxMultiplier) {
        maxMultiplier = ((MAX_NUMBER + 1) - s_houseEdge) * BP;
    }

    // if (multiplier, winning chance) are 0 then send profit and bet
    // if (multiplier,profit and bet) are 0 then send winning chance
    function getPreviewNumbers(
        uint256 desiredMultiplier,
        uint256 desiredWinningChance,
        uint256 desiredProfit,
        uint256 desiredBetAmount,
        IERC20Upgradeable token
    )
        public
        view
        returns (
            uint256 resultBetAmount,
            uint256 resultProfit,
            uint256 resultPrize,
            uint256 resultWinningChance,
            uint256 resultMultiplier
        )
    {
        uint256 multiplier = desiredMultiplier;
        uint256 betAmount;

        // Calculates the bet using multiplier and profit
        if (
            desiredBetAmount == 0 && desiredMultiplier > 0 && desiredProfit > 0
        ) {
            (betAmount, ) = getBetFromMultiplierAndProfit(
                desiredMultiplier,
                desiredProfit,
                token
            );
        } else {
            // Assign a low bet if no bet was passed
            betAmount = desiredBetAmount > 0 ? desiredBetAmount : 1000000000;
        }

        if (multiplier == 0) {
            // Gets the multiplier from the win chance
            if (desiredWinningChance > 0) {
                multiplier = getMultiplierFromBetAndChance(
                    betAmount,
                    desiredWinningChance,
                    token
                );
            } else {
                // Gets the multiplier from the profit and bet
                require(desiredProfit > 0, "DiceGame: fill profit and bet");
                multiplier = getMultiplierFromBetAndProfit(
                    betAmount,
                    desiredProfit,
                    token
                );
            }
            require(multiplier > 0, "DiceGame: fill winning chance");
        }

        uint256 winChance = getWinningChanceFromMultiplier(multiplier);
        uint256 prizeAmount;
        (winChance, multiplier, prizeAmount) = calculateBet(
            uint16(1),
            uint16(winChance),
            betAmount
        );
        // Generating profit
        (uint256 profit, ) = getProfitFromBetAndMultiplier(
            betAmount,
            multiplier,
            token
        );
        // Filling results
        resultBetAmount = betAmount;
        resultProfit = profit;
        resultPrize = prizeAmount;
        resultWinningChance = winChance;
        resultMultiplier = multiplier;
    }

    // The min multiplier comes when a user chooses all numbers except for house edge + 1
    function getMinMultiplier() public view returns (uint256 minMultiplier) {
        minMultiplier =
            (((MAX_NUMBER + 1) - s_houseEdge) * BP) /
            ((MAX_NUMBER + 1) - (s_houseEdge + 1));
    }

    // It estimates the winning chance to cover all the possible numbers except for the  house edge + 1, so that it can get more than 1x
    function getMaxWinningChance()
        public
        view
        returns (uint256 maxWinningChance)
    {
        // Need the leftOver to be greater than the houseEdge
        uint256 leftOver = s_houseEdge + 1;
        maxWinningChance = (MAX_NUMBER + 1) - leftOver;
    }

    /// @notice Allows the owner to enable or disable the allowed tokens to be used in the bets
    /// @dev The owner send an array of tokens and array of statuses make sure both are sorted in the same positions
    /// @param tokens Array of token addresses to modify the status
    /// @param statuses Array of booleans where true means enable and false means disable
    function editAllowedTokens(address[] memory tokens, bool[] memory statuses)
        public
        onlyOwner
    {
        require(
            tokens.length == statuses.length,
            "DiceGame: Invalid input lengths in allowed tokens"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            // Only continues if there is a change
            if (s_isTokenAllowed[tokens[i]] != statuses[i]) {
                s_isTokenAllowed[tokens[i]] = statuses[i];
                // Pushes the new token to the allowed list
                if (statuses[i]) s_allowedTokens.push(tokens[i]);
                else {
                    // Deletes the token from the allowed list
                    for (uint256 j = 0; j < s_allowedTokens.length; j++) {
                        if (s_allowedTokens[j] == tokens[i]) {
                            s_allowedTokens[j] = s_allowedTokens[
                                s_allowedTokens.length - 1
                            ];
                            s_allowedTokens.pop();
                        }
                    }
                }
            }
        }
    }

    /// @notice Allows the owner to edit the address that receives the chainlink fees
    /// @dev Do not use a contract that can not accept native tokens receive or fallback functions
    /// @param feeRecepient Address that receives the chainlink fees
    function editFeeRecipient(address payable feeRecepient) public onlyOwner {
        require(feeRecepient != address(0), "DiceGame: Invalid fee recipient");
        s_feeRecipient = feeRecepient;
    }

    /// @notice Allows the owner to edit the maximum bet that users can make
    /// @dev Numbers in wei (1 equals 1 wei), but (1e18 equals 1 token)
    /// @param maxBetAmount Maximum bet that users can make
    function editMaxBetAmount(uint256 maxBetAmount) public onlyOwner {
        s_maxBetAmount = maxBetAmount;
    }

    /// @notice Calculates the chainlink fee using the current tx gas price
    /// @dev Explain to a developer any extra details
    /// @param currentGasPrice gas price to be used in the tx
    /// @return fee amount in native token - wei format
    function estimateChainlinkFee(uint256 currentGasPrice)
        public
        view
        returns (uint256)
    {
        require(currentGasPrice < 200e9, "DiceGame: Gas price is too high");
        (, int256 price, , , ) = s_priceFeed.latestRoundData(); // price in Eth for 1 LINK
        if (price < 0) price = 0; // Prevents error with overflow below
        uint256 priceParsed = (uint256(price) * s_linkPremium) / BP;
        currentGasPrice = currentGasPrice + ((currentGasPrice * 5) / 100); // Adds 5% to the current gas price
        return
            (currentGasPrice * (MAX_VERIFICATION_GAS + CALLBACK_GAS_LIMIT)) +
            priceParsed;
    }

    /// @notice Shows the amount of tokens that are available to pay prizes
    /// @dev This function separates the tokens locked waiting for an result from the current balance of the contract
    /// @param token Token address to be requested
    /// @return balance of the token specified that is available to pay prizes
    function getAvailablePrize(IERC20Upgradeable token)
        public
        view
        returns (uint256)
    {
        uint256 lockedInBets = s_totalInBetsPerToken[address(token)];
        if (token == IERC20Upgradeable(address(0))) {
            return address(this).balance - (lockedInBets);
        } else {
            return token.balanceOf(address(this)) - lockedInBets;
        }
    }
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./chainlink/VRFConsumerBaseV2Upgradeable.sol"; // Custom implementation
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract RandomNumber is OwnableUpgradeable, VRFConsumerBaseV2Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint16 public constant MAX_NUMBER = 10000;
    uint16 public constant MIN_NUMBER = 0;
    // This callback gas limit will change if the logic of the fulfillRandomWords function changes
    uint32 internal constant CALLBACK_GAS_LIMIT = 130000;
    uint32 internal constant MAX_VERIFICATION_GAS = 200000;
    uint16 private constant REQUESTS_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private s_coordinator;
    LinkTokenInterface private s_linkToken;

    // Your subscription ID.
    uint64 public s_subscriptionId;
    bytes32 private s_keyHash;
    mapping(uint256 => uint256) public responseBlockByRequestId;
    mapping(address => uint256) public s_totalInBetsPerToken;
    mapping(uint256 => UserGuess) public guessByRequestId;

    // Read about gaps before adding new variables below:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[100] internal __gap;

    struct UserGuess {
        address payable user;
        uint16 lowerNumber;
        uint16 upperNumber;
        uint256 prizeAmount;
        uint256 betAmount;
        uint256 multiplier;
        IERC20Upgradeable token;
    }

    event BetResult(
        uint256 indexed requestId,
        address payable indexed user,
        uint256 winningNumber,
        UserGuess userGuess,
        bool didUserWin,
        bool success,
        bool isPrize
    );

    function __RandomNumber_init(
        uint64 subscriptionId,
        address vrfCoordinator_,
        bytes32 keyHash,
        address linkToken
    ) internal {
        __Ownable_init();
        __VRFConsumerBaseV2_init(vrfCoordinator_);
        s_coordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_linkToken = LinkTokenInterface(linkToken);
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(
        uint16 lowerNumber,
        uint16 upperNumber,
        uint256 prizeAmount,
        uint256 betAmount,
        uint256 multiplier,
        IERC20Upgradeable token
    ) internal virtual returns (uint256) {
        // Will revert if subscription is not set and funded.
        uint256 requestId = s_coordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUESTS_CONFIRMATION,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        s_totalInBetsPerToken[address(token)] += betAmount;
        guessByRequestId[requestId] = UserGuess(
            payable(msg.sender),
            lowerNumber,
            upperNumber,
            prizeAmount,
            betAmount,
            multiplier,
            token
        );
        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // Valid numbers must be from 0 to 10000 or 0.00 to 100.00
        uint16 winningNumber = uint16(randomWords[0] % (MAX_NUMBER + 1));

        // It will be used to facilitate event filtering later.
        responseBlockByRequestId[requestId] = block.number;

        UserGuess memory userGuess = guessByRequestId[requestId];
        uint256 totalInBets = s_totalInBetsPerToken[address(userGuess.token)];
        s_totalInBetsPerToken[address(userGuess.token)] -= userGuess.betAmount;
        // If the user guessed incorrectly then stop
        if (
            userGuess.lowerNumber > winningNumber ||
            userGuess.upperNumber < winningNumber
        ) {
            emit BetResult(
                requestId,
                userGuess.user,
                winningNumber,
                userGuess,
                false,
                true,
                false
            );
            return;
        }

        bool success;

        if (userGuess.token == IERC20Upgradeable(address(0))) {
            uint256 available = address(this).balance -
                (totalInBets - userGuess.betAmount);
            if (available >= userGuess.prizeAmount) {
                // Pay the prize amount (native token)
                (success, ) = userGuess.user.call{value: userGuess.prizeAmount}(
                    ""
                );
                emit BetResult(
                    requestId,
                    userGuess.user,
                    winningNumber,
                    userGuess,
                    true,
                    success,
                    true
                );
            } else {
                // Return the bet amount (native token)
                (success, ) = userGuess.user.call{value: userGuess.betAmount}(
                    ""
                );
                emit BetResult(
                    requestId,
                    userGuess.user,
                    winningNumber,
                    userGuess,
                    true,
                    success,
                    false
                );
            }
        } else {
            uint256 available = userGuess.token.balanceOf(address(this)) -
                (totalInBets - userGuess.betAmount);
            if (available >= userGuess.prizeAmount) {
                // Pay the prize amount (ERC20 token)
                success = userGuess.token.transfer(
                    userGuess.user,
                    userGuess.prizeAmount
                );
                emit BetResult(
                    requestId,
                    userGuess.user,
                    winningNumber,
                    userGuess,
                    true,
                    success,
                    true
                );
            } else {
                // Return the bet amount (ERC20 token)
                success = userGuess.token.transfer(
                    userGuess.user,
                    userGuess.betAmount
                );
                emit BetResult(
                    requestId,
                    userGuess.user,
                    winningNumber,
                    userGuess,
                    true,
                    success,
                    false
                );
            }
        }
    }

    /// @notice Allows the admin to set a new subscription id for the chainlink service
    /// @dev The susbscription id should not change so often, and only the owner can do it
    /// @param subscriptionId new subscription id from the chainlink service
    function editSubscriptionId(uint64 subscriptionId) external onlyOwner {
        s_subscriptionId = subscriptionId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
    error OnlyCoordinatorCanFulfill(address have, address want);
    address private vrfCoordinator;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     */
    function __VRFConsumerBaseV2_init(address _vrfCoordinator)
        internal
        initializer
    {
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual;

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC20PermitUpgradeable {
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