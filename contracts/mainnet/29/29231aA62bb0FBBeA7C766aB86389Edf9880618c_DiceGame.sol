// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./RandomNumber.sol";
import "./Interfaces/ICalculations.sol";

contract DiceGame is Initializable, RandomNumber {
    address internal linkToNativeTokenPriceFeed;
    uint256 private constant BP = 1e18;
    uint16 public houseEdge; // Minimum winning percentage for the casino
    address payable public feeRecipient;
    uint256 public linkPremium;
    uint256 public maxBetAmount;
    ICalculations public calculations;

    event RequestId(
        uint256 requestId,
        address indexed user,
        uint256 dateTime,
        uint256 amountOfPlays
    );

    function initialize(
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        address linkToken_,
        address payable feeRecepient_,
        uint16 houseEdge_,
        uint256 linkPremium_,
        uint256 maxBetAmount_,
        address linkToNativeTokenPriceFeed_,
        address nativeToUsdPriceFeed,
        uint256 withdrawalWaitingPeriod_,
        address calculations_
    ) public virtual initializer {
        __RandomNumber_init(
            withdrawalWaitingPeriod_,
            subscriptionId_,
            vrfCoordinator_,
            keyHash_,
            linkToken_
        );
        require(
            houseEdge_ >= 100 && houseEdge_ < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        require(feeRecepient_ != address(0), "DiceGame: Invalid fee recipient");
        feeRecipient = feeRecepient_;
        houseEdge = houseEdge_;
        linkPremium = linkPremium_;
        maxBetAmount = maxBetAmount_;
        linkToNativeTokenPriceFeed = linkToNativeTokenPriceFeed_;
        // Adding the usd price feed of the native token
        tokenToUsdPriceFeed[address(0)] = nativeToUsdPriceFeed;
        addedTokens.push(address(0));
        require(
            calculations_ != address(0),
            "DiceGame: invalid input calculations"
        );
        calculations = ICalculations(calculations_);
    }

    /// @notice Allows to replenish the contract with the native token ETH, BNB, MATIC, etc...
    receive() external payable {}

    /// @notice Allows the users to bet for a guess random number sending a range of numbers in which they think the random number will be generated
    /// @dev the user has to send in the value of the transaction the native token of the bet + the chainlink fees after calculating it with the function estimateChainlinkFee
    /// @dev the user could also bet in allowed erc20 tokens but still need to send in the value of the transaction the chainlinkn fee
    /// @param lowerNumbers Array of Lower number of the range
    /// @param upperNumbers Array of  Higher number of the range
    /// @param betAmounts Array of The amount to bet
    /// @param tokens Array of Token address to use for the bet, use address zero 0x0000000000000000000000000000000000000000 for native token
    /// @param influencer address of the influencer who referred this player
    function playGame(
        uint16[] calldata lowerNumbers,
        uint16[] calldata upperNumbers,
        uint256[] calldata betAmounts,
        IERC20Upgradeable[] calldata tokens,
        address influencer
    ) external payable {
        require(
            lowerNumbers.length == upperNumbers.length &&
                lowerNumbers.length == betAmounts.length &&
                lowerNumbers.length == tokens.length,
            "DiceGame: different inputs size"
        );

        require(betAmounts.length <= 10, "DiceGame: send less than 10 bets");

        uint256 remainingValueForFee = msg.value;
        uint256[] memory prizeAmounts = new uint256[](betAmounts.length);
        uint256[] memory multipliers = new uint256[](betAmounts.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            processInfluencerReferral(
                influencer,
                betAmounts[i],
                address(tokens[i])
            );

            if (tokens[i] == IERC20Upgradeable(address(0))) {
                remainingValueForFee -= betAmounts[i];
            } else {
                require(
                    tokenToUsdPriceFeed[address(tokens[i])] != address(0),
                    "DiceGame: Token is not allowed"
                );

                bool successTransfer = tokens[i].transferFrom(
                    msg.sender,
                    address(this),
                    betAmounts[i]
                );
                require(successTransfer, "DiceGame: error with transferFrom");
            }
            (, multipliers[i], prizeAmounts[i]) = calculateBet(
                lowerNumbers[i],
                upperNumbers[i],
                betAmounts[i]
            );
            require(
                prizeAmounts[i] <= getAvailablePrize(tokens[i]),
                "DiceGame: Insufficient balance to accept bet"
            );
            require(
                prizeAmounts[i] > betAmounts[i],
                "DiceGame: prize is too low"
            );
            totalInBetsPerToken[address(tokens[i])] += betAmounts[i];
        }

        uint256 chainlinkFeeNativeToken = estimateChainlinkFee(
            tx.gasprice,
            tokens.length
        );

        require(
            remainingValueForFee >= chainlinkFeeNativeToken,
            "DiceGame: chainlink fee too low"
        );
        (bool success, ) = feeRecipient.call{value: remainingValueForFee}("");

        require(success, "DiceGame: Error while paying feeRecepient");
        uint256 requestId = requestRandomWords(
            lowerNumbers,
            upperNumbers,
            prizeAmounts,
            betAmounts,
            multipliers,
            tokens
        );
        emit RequestId(requestId, msg.sender, block.timestamp, tokens.length);
    }

    function changeCalculations(address calculations_) external onlyOwner {
        calculations = ICalculations(calculations_);
    }

    function getAddedTokens() external view returns (address[] memory) {
        return addedTokens;
    }

    /// @notice Allows the owner to edit the house edge which is the amount of numbers that cannot be used
    /// @dev The minimum house edge is 1% or 1.00 or 100, so at least 100 of 10000 numbers cannot be used by the user
    /// @param houseEdge_ new house edge to be used in the contract
    function editHouseEdge(uint16 houseEdge_) external onlyOwner {
        require(
            houseEdge_ >= 100 && houseEdge_ < MAX_NUMBER,
            "DiceGame: Invalid house edge"
        );
        houseEdge = houseEdge_;
    }

    function withdraw(IERC20Upgradeable _token, uint256 _amount)
        external
        onlyOwner
    {
        require(
            getAvailablePrize(_token) -
                totalUnpaidToInfluencersByToken[address(_token)] >=
                _amount,
            "DiceGame: amount is more than allowed"
        );
        if (_token == IERC20Upgradeable(address(0))) {
            payable(owner()).transfer(_amount);
        } else {
            bool success = _token.transfer(owner(), _amount);
            require(success, "DiceGame: error in transfer");
        }
    }

    /// @notice Returns the biggest multiplier that a user can use based on the bet amount
    /// @param betAmount bet amount to sent in the bet
    /// @param token address of the token to use in the bet
    /// @return multiplier number in the wei units representing the biggest multiplier
    function getBiggestMultiplierFromBet(
        uint256 betAmount,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier) {
        multiplier = calculations.getBiggestMultiplierFromBet(betAmount, token);
    }

    /// @notice Show the numbers produced by chainlink using the randomness
    /// @dev The randomness comes from the chainlink event
    //  @dev RandomWordsFulfilled(requestId, randomness, payment, success)
    /// @param randomness source of randomness used to generate the numbers
    /// @param amountOfNumbers how many numbers were generated
    /// @return chainlinkRawNumbers array of big numbers produced by chanlink
    /// @return parsedNumbers array of raw number formated to be in the range from 1 to 10000
    function getNumberFromRandomness(
        uint256 randomness,
        uint256 amountOfNumbers
    )
        external
        view
        returns (
            uint256[] memory chainlinkRawNumbers,
            uint256[] memory parsedNumbers
        )
    {
        (chainlinkRawNumbers, parsedNumbers) = calculations
            .getNumberFromRandomness(randomness, amountOfNumbers);
    }

    /// @notice Allows to estimate the winning chance, multiplier, and prize amount
    /// @dev To choose a single number send the same number in lower and upper inputs
    /// @param lowerNumber Lower number of the range
    /// @param upperNumber Higher number of the range
    /// @param betAmount The amount to bet
    /// @return winningChance The winning chance percentage = (winningChance/10000 * 100)
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
            betAmount > 0 && betAmount <= maxBetAmount,
            "DiceGame: Invalid bet amount"
        );
        require(
            lowerNumber <= MAX_NUMBER &&
                upperNumber <= MAX_NUMBER &&
                lowerNumber <= upperNumber &&
                lowerNumber > 0,
            "DiceGame: Invalid range"
        );

        // Checks if there is enough room in the range for the house edge.
        uint16 leftOver = lowerNumber == upperNumber
            ? MAX_NUMBER - 1
            : lowerNumber - MIN_NUMBER + MAX_NUMBER - upperNumber;
        require(leftOver >= houseEdge, "DiceGame: Invalid boundaries");

        winningChance = MAX_NUMBER - leftOver;
        multiplier = ((MAX_NUMBER - houseEdge) * BP) / winningChance;
        prizeAmount = (betAmount * multiplier) / BP;
    }

    /// @notice It produces the closest possible multipler based to the bet and profit
    function getMultiplierFromBetAndProfit(
        uint256 betAmount,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        multiplier = calculations.getMultiplierFromBetAndProfit(
            betAmount,
            profit,
            token
        );
    }

    /// @notice Expects the multiplier to be in wei format 2x equals 2e18
    /// @notice Returns the quantity of numbers that can be used in the bet.
    /// @notice It chooses the closest winning chance to the provided multiplier
    /// @notice Example output: winningChance = 10 means 10 different numbers.
    function getWinningChanceFromMultiplier(uint256 multiplier)
        public
        view
        returns (uint256 winningChance)
    {
        winningChance = calculations.getWinningChanceFromMultiplier(multiplier);
    }

    /// @notice The function will adjust the provided multiplier to the closest possible multiplier
    /// @notice And then calculate the profit based on that multiplier
    /// @notice The upperNum can be used to get the multiplier used for the obtained profit
    function getProfitFromBetAndMultiplier(
        uint256 betAmount,
        uint256 multiplier,
        IERC20Upgradeable token
    ) public view returns (uint256 profit, uint256 upperNum) {
        (profit, upperNum) = calculations.getProfitFromBetAndMultiplier(
            betAmount,
            multiplier,
            token
        );
    }

    /// @notice Returns the closest possible multiplier generated by the bet amount and win chance
    function getMultiplierFromBetAndChance(
        uint256 betAmount,
        uint256 winningChance,
        IERC20Upgradeable token
    ) public view returns (uint256 multiplier) {
        multiplier = calculations.getMultiplierFromBetAndChance(
            betAmount,
            winningChance,
            token
        );
    }

    /// @notice Returns bet amount to be used for the multiplier and profit
    /// @notice The upperNum can be used to calculate the exact multiplier used for the calculation of the bet amount
    function getBetFromMultiplierAndProfit(
        uint256 multiplier,
        uint256 profit,
        IERC20Upgradeable token
    ) public view returns (uint256 betAmount, uint256 upperNum) {
        (betAmount, upperNum) = calculations.getBetFromMultiplierAndProfit(
            multiplier,
            profit,
            token
        );
    }

    /// @notice The max multiplier comes when a user chooses only one number between 1-10000
    function getMaxMultiplier() public view returns (uint256 maxMultiplier) {
        maxMultiplier = calculations.getMaxMultiplier();
    }

    /// @notice Calculates the values that help to visualize the bet with the most accurate numbers
    /// @notice The function will correct values ​​that are not precise, but will throw an error if the values ​​are out of bounds.
    /// @param desiredMultiplier Desired multiplier in wei units
    /// @param desiredWinningChance Win chance the user would like to have numbers from 1 to 10000
    /// @param desiredProfit Amount of profit the user expects to have
    /// @param desiredBetAmount Bet to be used when playing
    /// @param token Address of the token to be used in the bet
    /// @return resultBetAmount Bet amount to be used in the preview of the bet
    /// @return resultProfit Profit to be used in the preview of the bet
    /// @return resultPrize Prize to be used in the preview of the bet
    /// @return resultWinningChance Win chance to be used in the preview of the bet
    /// @return resultMultiplier Multiplier to be used in the preview of the bet
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
        (
            resultBetAmount,
            resultProfit,
            resultPrize,
            resultWinningChance,
            resultMultiplier
        ) = calculations.getPreviewNumbers(
            desiredMultiplier,
            desiredWinningChance,
            desiredProfit,
            desiredBetAmount,
            token
        );
    }

    /// @notice The min multiplier comes when a user chooses all numbers except for house edge + 1
    function getMinMultiplier() public view returns (uint256 minMultiplier) {
        minMultiplier = calculations.getMinMultiplier();
    }

    /// @notice It estimates the winning chance to cover all the possible numbers except for the  house edge + 1, so that it can get more than 1x
    function getMaxWinningChance()
        public
        view
        returns (uint256 maxWinningChance)
    {
        // Need the leftOver to be greater than the houseEdge
        maxWinningChance = calculations.getMaxWinningChance();
    }

    /// @notice Allows the owner to edit the address that receives the chainlink fees
    /// @dev Do not use a contract that can not accept native tokens receive or fallback functions
    /// @param feeRecepient_ Address that receives the chainlink fees
    function editFeeRecipient(address payable feeRecepient_) public onlyOwner {
        require(feeRecepient_ != address(0), "DiceGame: Invalid fee recipient");
        feeRecipient = feeRecepient_;
    }

    /// @notice Allows the owner to edit the maximum bet that users can make
    /// @dev Numbers in wei (1 equals 1 wei), but (1e18 equals 1 token)
    /// @param maxBetAmount_ Maximum bet that users can make
    function editMaxBetAmount(uint256 maxBetAmount_) public onlyOwner {
        maxBetAmount = maxBetAmount_;
    }

    /// @notice Calculates the chainlink fee using the current tx gas price
    /// @dev Explain to a developer any extra details
    /// @param currentGasPrice gas price to be used in the tx
    /// @param amountOfBets how many numbers will be requested
    /// @return fee amount in native token - wei format
    function estimateChainlinkFee(uint256 currentGasPrice, uint256 amountOfBets)
        public
        view
        returns (uint256)
    {
        return
            calculations.estimateChainlinkFee(
                currentGasPrice,
                amountOfBets,
                linkPremium,
                MAX_VERIFICATION_GAS,
                CALLBACK_GAS_LIMIT,
                linkToNativeTokenPriceFeed
            );
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
        uint256 lockedInBets = totalInBetsPerToken[address(token)];
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
import "./ReferralSystem.sol";

contract RandomNumber is ReferralSystem, VRFConsumerBaseV2Upgradeable {
    uint16 public constant MAX_NUMBER = 10000;
    uint16 public constant MIN_NUMBER = 1;
    // This callback gas limit will change if the logic of the fulfillRandomWords function changes
    uint32 internal constant CALLBACK_GAS_LIMIT = 200000;
    uint32 internal constant MAX_VERIFICATION_GAS = 200000;
    uint16 private constant REQUESTS_CONFIRMATION = 3;

    VRFCoordinatorV2Interface public coordinator;
    LinkTokenInterface private linkToken;

    // Your subscription ID.
    uint64 public subscriptionId;
    bytes32 public keyHash;
    mapping(uint256 => uint256) public responseBlockByRequestId;
    mapping(address => uint256) public totalInBetsPerToken;
    mapping(uint256 => UserGuess[]) public guessByRequestId;

    // Read about gaps before adding new variables below:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[50] private __gap;

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
        uint256 betIndex,
        address payable indexed user,
        address influencer,
        uint256 winningNumber,
        UserGuess userGuess,
        bool didUserWin,
        bool success,
        bool isPrize
    );

    function __RandomNumber_init(
        uint256 withdrawalWaitingPeriod_,
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        address linkToken_
    ) internal {
        __ReferralSystem_init(withdrawalWaitingPeriod_);
        __VRFConsumerBaseV2_init(vrfCoordinator_);
        coordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        linkToken = LinkTokenInterface(linkToken_);
        subscriptionId = subscriptionId_;
        keyHash = keyHash_;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords(
        uint16[] memory lowerNumbers,
        uint16[] memory upperNumbers,
        uint256[] memory prizeAmounts,
        uint256[] memory betAmounts,
        uint256[] memory multipliers,
        IERC20Upgradeable[] memory tokens
    ) internal virtual returns (uint256) {
        // Will revert if subscription is not set and funded.
        uint256 requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUESTS_CONFIRMATION,
            CALLBACK_GAS_LIMIT * uint32(tokens.length),
            uint32(tokens.length)
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            guessByRequestId[requestId].push(
                UserGuess(
                    payable(msg.sender),
                    lowerNumbers[i],
                    upperNumbers[i],
                    prizeAmounts[i],
                    betAmounts[i],
                    multipliers[i],
                    tokens[i]
                )
            );
        }

        return requestId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        // It will be used to facilitate event filtering later.
        responseBlockByRequestId[requestId] = block.number;

        for (uint256 i = 0; i < randomWords.length; i++) {
            // Valid numbers must be from 1 to 10000 or 0.01 to 100.00
            uint16 winningNumber = uint16(randomWords[i] % MAX_NUMBER) + 1;
            UserGuess memory userGuess = guessByRequestId[requestId][i];
            uint256 totalInBets = totalInBetsPerToken[address(userGuess.token)];
            totalInBetsPerToken[address(userGuess.token)] -= userGuess
                .betAmount;

            (address influencer, bool isEnabled) = getUserReferredBy(
                userGuess.user
            );
            if (!isEnabled) influencer = address(0);

            // If the user guessed incorrectly then stop
            if (
                userGuess.lowerNumber > winningNumber ||
                userGuess.upperNumber < winningNumber
            ) {
                updateTotalUserLosses(
                    userGuess.betAmount,
                    address(userGuess.token),
                    influencer
                );

                emit BetResult(
                    requestId,
                    i,
                    userGuess.user,
                    influencer,
                    winningNumber,
                    userGuess,
                    false,
                    true,
                    false
                );
                continue;
            }

            bool success;
            bool isRefund;
            if (userGuess.token == IERC20Upgradeable(address(0))) {
                uint256 available = address(this).balance -
                    (totalInBets - userGuess.betAmount);
                if (available >= userGuess.prizeAmount) {
                    // Pay the prize amount (native token)
                    (success, ) = userGuess.user.call{
                        value: userGuess.prizeAmount
                    }("");
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        true
                    );
                } else {
                    isRefund = true;
                    // Refund the bet amount (native token)
                    (success, ) = userGuess.user.call{
                        value: userGuess.betAmount
                    }("");
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
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
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        true
                    );
                } else {
                    isRefund = true;
                    // Refund the bet amount (ERC20 token)
                    success = userGuess.token.transfer(
                        userGuess.user,
                        userGuess.betAmount
                    );
                    emit BetResult(
                        requestId,
                        i,
                        userGuess.user,
                        influencer,
                        winningNumber,
                        userGuess,
                        true,
                        success,
                        false
                    );
                }
            }
            if (influencer == address(0)) continue;
            if (!success) {
                updateTotalUserLosses(
                    userGuess.betAmount,
                    address(userGuess.token),
                    influencer
                );
                continue;
            }
            if (isRefund) {
                updateTotalUserRefunds(
                    userGuess.betAmount,
                    address(userGuess.token),
                    influencer
                );
                continue;
            }
            updateTotalUserWins(
                userGuess.prizeAmount,
                userGuess.betAmount,
                address(userGuess.token),
                influencer
            );
        }
    }

    /// @notice Allows the admin to set a new subscription id for the chainlink service
    /// @dev The susbscription id should not change so often, and only the owner can do it
    /// @param subscriptionId_ new subscription id from the chainlink service
    function editSubscriptionId(uint64 subscriptionId_) external onlyOwner {
        subscriptionId = subscriptionId_;
    }

    function editKeyHash(bytes32 keyHash_) external onlyOwner {
        keyHash = keyHash_;
    }

    /// @notice Overrides the renounceOwnership function, it won't be possible to renounce the ownership
    function renounceOwnership() public pure override {
        require(false, "DiceGame: renounceOwnership has been disabled");
    }

    function getGuessesByRequestId(uint256 requestId)
        external
        view
        returns (UserGuess[] memory)
    {
        return guessByRequestId[requestId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICalculations {
    /// @notice Returns the biggest multiplier that a user can use based on the bet amount
    /// @param betAmount bet amount to sent in the bet
    /// @param token address of the token to use in the bet
    /// @return multiplier number in the wei units representing the biggest multiplier
    function getBiggestMultiplierFromBet(
        uint256 betAmount,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier);

    /// @notice Show the numbers produced by chainlink using the randomness
    /// @dev The randomness comes from the chainlink event
    //  @dev RandomWordsFulfilled(requestId, randomness, payment, success)
    /// @param randomness source of randomness used to generate the numbers
    /// @param amountOfNumbers how many numbers were generated
    /// @return chainlinkRawNumbers array of big numbers produced by chanlink
    /// @return parsedNumbers array of raw number formated to be in the range from 1 to 10000
    function getNumberFromRandomness(
        uint256 randomness,
        uint256 amountOfNumbers
    )
        external
        view
        returns (
            uint256[] memory chainlinkRawNumbers,
            uint256[] memory parsedNumbers
        );

    /// @notice It produces the closest possible multipler based to the bet and profit
    function getMultiplierFromBetAndProfit(
        uint256 betAmount,
        uint256 profit,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier);

    /// @notice Expects the multiplier to be in wei format 2x equals 2e18
    /// @notice Returns the quantity of numbers that can be used in the bet.
    /// @notice It chooses the closest winning chance to the provided multiplier
    /// @notice Example output: winningChance = 10 means 10 different numbers.
    function getWinningChanceFromMultiplier(uint256 multiplier)
        external
        view
        returns (uint256 winningChance);

    /// @notice The function will adjust the provided multiplier to the closest possible multiplier
    /// @notice And then calculate the profit based on that multiplier
    /// @notice The upperNum can be used to get the multiplier used for the obtained profit
    function getProfitFromBetAndMultiplier(
        uint256 betAmount,
        uint256 multiplier,
        IERC20Upgradeable token
    ) external view returns (uint256 profit, uint256 upperNum);

    /// @notice Returns the closest possible multiplier generated by the bet amount and win chance
    function getMultiplierFromBetAndChance(
        uint256 betAmount,
        uint256 winningChance,
        IERC20Upgradeable token
    ) external view returns (uint256 multiplier);

    /// @notice Returns bet amount to be used for the multiplier and profit
    /// @notice The upperNum can be used to calculate the exact multiplier used for the calculation of the bet amount
    function getBetFromMultiplierAndProfit(
        uint256 multiplier,
        uint256 profit,
        IERC20Upgradeable token
    ) external view returns (uint256 betAmount, uint256 upperNum);

    /// @notice The max multiplier comes when a user chooses only one number between 1-10000
    function getMaxMultiplier() external view returns (uint256 maxMultiplier);

    /// @notice Calculates the values that help to visualize the bet with the most accurate numbers
    /// @notice The function will correct values ​​that are not precise, but will throw an error if the values ​​are out of bounds.
    /// @param desiredMultiplier Desired multiplier in wei units
    /// @param desiredWinningChance Win chance the user would like to have numbers from 1 to 10000
    /// @param desiredProfit Amount of profit the user expects to have
    /// @param desiredBetAmount Bet to be used when playing
    /// @param token Address of the token to be used in the bet
    /// @return resultBetAmount Bet amount to be used in the preview of the bet
    /// @return resultProfit Profit to be used in the preview of the bet
    /// @return resultPrize Prize to be used in the preview of the bet
    /// @return resultWinningChance Win chance to be used in the preview of the bet
    /// @return resultMultiplier Multiplier to be used in the preview of the bet
    function getPreviewNumbers(
        uint256 desiredMultiplier,
        uint256 desiredWinningChance,
        uint256 desiredProfit,
        uint256 desiredBetAmount,
        IERC20Upgradeable token
    )
        external
        view
        returns (
            uint256 resultBetAmount,
            uint256 resultProfit,
            uint256 resultPrize,
            uint256 resultWinningChance,
            uint256 resultMultiplier
        );

    /// @notice The min multiplier comes when a user chooses all numbers except for house edge + 1
    function getMinMultiplier() external view returns (uint256 minMultiplier);

    /// @notice It estimates the winning chance to cover all the possible numbers except for the  house edge + 1, so that it can get more than 1x
    function getMaxWinningChance()
        external
        view
        returns (uint256 maxWinningChance);

    /// @notice Calculates the chainlink fee using the current tx gas price
    /// @dev Explain to a developer any extra details
    /// @param currentGasPrice gas price to be used in the tx
    /// @param amountOfBets how many numbers will be requested
    /// @return fee amount in native token - wei format
    function estimateChainlinkFee(
        uint256 currentGasPrice,
        uint256 amountOfBets,
        uint256 linkPremium,
        uint256 maxVerificationGas,
        uint256 callbackGasLimit,
        address linkToNativeTokenPriceFeed
    ) external view returns (uint256);
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

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ReferralSystem is OwnableUpgradeable {
    uint16 public constant MAX_TOKENS_AMOUNT = 130;

    address[] public influencerWallets;
    mapping(address => InfluencerData) public influencerData;
    mapping(address => Payout[]) public historicalPayoutsByInfluencer;
    mapping(address => address) private userReferredBy; // What influencer referred this user
    mapping(address => uint256) public totalPaidToInfluencersByToken; // All the influencers
    mapping(address => uint256) public totalUnpaidToInfluencersByToken; // All the influencers
    mapping(address => address) public tokenToUsdPriceFeed;
    address[] public addedTokens;
    uint256 public withdrawalWaitingPeriod;

    // Read about gaps before adding new variables below:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#storage-gaps
    uint256[50] private __gap;

    struct InfluencerData {
        address wallet;
        bool isEnabled;
        uint256 percentage;
        address[] referrals;
        uint256 nextWithdrawalDate;
        mapping(address => uint256) totalBetsByToken;
        mapping(address => uint256) totalUserWinsByToken;
        mapping(address => uint256) totalUserLossesByToken;
        mapping(address => uint256) totalUserRefundsByToken;
        mapping(address => int256) totalInfluencerProfit; // can be negative, calculated with amount * %
        mapping(address => int256) totalCasinoProfit; // can be negative, calculated with amount * %
        mapping(address => uint256) totalPayouts;
    }

    struct Payout {
        address influencer;
        address token;
        uint256 paymentAmount;
        uint256 datetime;
        uint256 totalPayouts;
    }

    struct InfluencerProfitCalculationData {
        uint256 tokensLength;
        int256 total;
        uint256 counter;
        address usdPriceFeed;
        address currentToken;
        uint8 decimals;
        int256 tokenAmount;
        uint256 paymentTotal;
    }

    function __ReferralSystem_init(uint256 withdrawalWaitingPeriod_) internal {
        __Ownable_init();
        withdrawalWaitingPeriod = withdrawalWaitingPeriod_;
    }

    function updateTotalUserLosses(
        uint256 betAmount,
        address token,
        address influencer
    ) internal {
        // The user lost the game, increase user losses of influencer
        // Increase profit of influencer and casino

        influencerData[influencer].totalUserLossesByToken[token] += betAmount;

        // ====== Updating influencer profits ======
        uint256 influencerAmount = calculateInfluencerProfit(
            betAmount,
            influencer
        );
        int256 influencerProfitBefore = influencerData[influencer]
            .totalInfluencerProfit[token];
        influencerData[influencer].totalInfluencerProfit[token] += int256(
            influencerAmount
        );
        int256 influencerProfitAfter = influencerProfitBefore +
            int256(influencerAmount);
        updateTotalUnpaidInfluencers(
            influencerProfitBefore,
            influencerProfitAfter,
            token
        );
        // ====== Updating casino profits ======
        uint256 casinoAmount = betAmount - influencerAmount;
        influencerData[influencer].totalCasinoProfit[token] += int256(
            casinoAmount
        );
    }

    function updateTotalUserRefunds(
        uint256 betAmount,
        address token,
        address influencer
    ) internal {
        // if (influencer == address(0)) return;
        // A refund ocurred, store it as refund if there is an influencer
        influencerData[influencer].totalUserRefundsByToken[token] += betAmount;
    }

    function updateTotalUserWins(
        uint256 prizeAmount,
        uint256 betAmount,
        address token,
        address influencer
    ) internal {
        // Sucessful win payment, increase user wins of influencer
        // Decrease profit of influencer and casino
        uint256 playProfit = prizeAmount - betAmount;
        influencerData[influencer].totalUserWinsByToken[token] += playProfit;

        // ====== Updating influencer profits ======
        uint256 influencerAmount = calculateInfluencerProfit(
            playProfit,
            influencer
        );
        int256 influencerProfitBefore = influencerData[influencer]
            .totalInfluencerProfit[token];
        influencerData[influencer].totalInfluencerProfit[token] -= int256(
            influencerAmount
        );
        int256 influencerProfitAfter = influencerProfitBefore -
            int256(influencerAmount);
        updateTotalUnpaidInfluencers(
            influencerProfitBefore,
            influencerProfitAfter,
            token
        );
        // ====== Updating casino profits ======
        uint256 casinoAmount = playProfit - influencerAmount;
        influencerData[influencer].totalCasinoProfit[token] -= int256(
            casinoAmount
        );
    }

    // percentage is any number <= 100 multiplied by 1e18
    function addInfluencers(
        address[] calldata influencers,
        uint256[] calldata percentages
    ) external onlyOwner {
        require(
            percentages.length == influencers.length,
            "ReferralSystem: different inputs size"
        );

        for (uint256 i = 0; i < influencers.length; i++) {
            require(
                percentages[i] <= 100 ether,
                "ReferralSystem: percentage is greater than 100%"
            );
            require(
                influencerData[influencers[i]].wallet == address(0),
                "ReferralSystem: influencer previously added"
            );

            // Adding the influencer
            influencerWallets.push(influencers[i]);
            influencerData[influencers[i]].wallet = influencers[i];
            influencerData[influencers[i]].isEnabled = true;
            influencerData[influencers[i]].percentage = percentages[i];
            influencerData[influencers[i]].nextWithdrawalDate =
                block.timestamp +
                withdrawalWaitingPeriod;
        }
    }

    function disableInfluencers(address[] calldata influencers)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < influencers.length; i++) {
            require(
                influencerData[influencers[i]].wallet == influencers[i],
                "ReferralSystem: influencer does not exist"
            );
            require(
                influencerData[influencers[i]].isEnabled == true,
                "ReferralSystem: influencer already disabled"
            );
            influencerData[influencers[i]].isEnabled = false;
        }
    }

    // Time in seconds 1 = 1 second
    function editWithdrawalWaitingPeriod(uint256 newWaitingPeriod)
        external
        onlyOwner
    {
        withdrawalWaitingPeriod = newWaitingPeriod;
    }

    function withdrawInfluencerProfit() external {
        require(
            influencerData[msg.sender].wallet == msg.sender,
            "ReferralSystem: caller is not an influencer"
        );
        bool paymentOccurred;
        require(
            influencerData[msg.sender].nextWithdrawalDate <= block.timestamp,
            "ReferralSystem: waiting period has not finished"
        );

        (
            address[] memory tokens,
            uint256[] memory amounts
        ) = getInfluencerWithdrawableBalances(msg.sender);
        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] == 0) continue;
            // ========= Updating total paid and unpaid =========
            influencerData[msg.sender].totalInfluencerProfit[
                tokens[i]
            ] -= int256(amounts[i]);
            totalPaidToInfluencersByToken[tokens[i]] += amounts[i];
            totalUnpaidToInfluencersByToken[tokens[i]] -= amounts[i];
            influencerData[msg.sender].totalPayouts[tokens[i]] += amounts[i];
            paymentOccurred = true;
            // ========= Transferring of tokens =========
            if (tokens[i] == address(0)) {
                // Payment in native token
                (bool success, ) = payable(msg.sender).call{value: amounts[i]}(
                    ""
                );
                require(success, "ReferralSystem: Error paying influencer");
            } else {
                // Payment in ERC20 token
                bool success = IERC20Upgradeable(tokens[i]).transfer(
                    influencerData[msg.sender].wallet,
                    amounts[i]
                );
                require(success, "ReferralSystem: Error paying influencer");
            }
            Payout memory payout = Payout(
                msg.sender,
                tokens[i],
                uint256(amounts[i]),
                block.timestamp,
                influencerData[msg.sender].totalPayouts[tokens[i]]
            );
            historicalPayoutsByInfluencer[msg.sender].push(payout);
        }
        // Throw error if the total profit is negative
        require(
            paymentOccurred,
            "ReferralSystem: influencer total profit is negative"
        );

        influencerData[msg.sender].nextWithdrawalDate =
            block.timestamp +
            withdrawalWaitingPeriod;
    }

    // This function calculates the total profit of the influencer in all the tokens converted to USD,
    // If the sum of losses and and wins is positive it will create a list of instructions of tokens and amounts
    // That can be used to pay the equivalent amount to the excess of positive profit in USD.
    // If the total profit in USD is negative the function returns two empty lists
    function getInfluencerWithdrawableBalances(address influencer)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        InfluencerProfitCalculationData memory data;
        data.tokensLength = addedTokens.length;
        address[] memory tokenAddresses = new address[](data.tokensLength);
        int256[] memory tokenAmounts = new int256[](data.tokensLength);
        int256[] memory usdPrices = new int256[](data.tokensLength);

        for (uint256 i = 0; i < data.tokensLength; i++) {
            data.currentToken = addedTokens[i];
            data.usdPriceFeed = tokenToUsdPriceFeed[data.currentToken];
            data.decimals = AggregatorV3Interface(data.usdPriceFeed).decimals();
            (, int256 answer, , , ) = AggregatorV3Interface(data.usdPriceFeed)
                .latestRoundData();

            data.tokenAmount = influencerData[influencer].totalInfluencerProfit[
                data.currentToken
            ];

            int256 usdPrice = (data.tokenAmount * answer) /
                int256(10**data.decimals);

            // Adds to the total
            data.total += usdPrice;
            if (usdPrice > 0) {
                tokenAddresses[data.counter] = data.currentToken;
                tokenAmounts[data.counter] = data.tokenAmount;
                usdPrices[data.counter] = usdPrice;
                data.counter++;
            }
        }
        if (data.total < 0) {
            // The total in USD is less negative
            address[] memory tokensEmpty;
            uint256[] memory amountsEmpty;
            return (tokensEmpty, amountsEmpty);
        }

        address[] memory tokens = new address[](usdPrices.length);
        uint256[] memory amounts = new uint256[](usdPrices.length);
        data.counter = 0; // Resets the counter
        // The total in USD is positive, create transfer intructions
        for (uint256 i = 0; i < usdPrices.length; i++) {
            if (usdPrices[i] <= 0) continue; // Skips the empty ones
            tokens[data.counter] = tokenAddresses[i];

            if (
                uint256(data.total) >=
                (data.paymentTotal + uint256(usdPrices[i]))
            ) {
                amounts[data.counter] = uint256(tokenAmounts[i]);
                if (
                    uint256(data.total) ==
                    (data.paymentTotal + uint256(usdPrices[i]))
                ) {
                    return (tokens, amounts);
                }
                data.paymentTotal += uint256(usdPrices[i]);
            } else {
                uint256 missingAmountUSD = (uint256(data.total) -
                    data.paymentTotal);
                amounts[data.counter] =
                    (((uint256(tokenAmounts[i]) * 1e18) /
                        uint256(usdPrices[i])) * missingAmountUSD) /
                    1e18;
                return (tokens, amounts);
            }
            data.counter++;
        }
        return (tokens, amounts);
    }

    function updateTotalUnpaidInfluencers(
        int256 profitBefore,
        int256 profitAfter,
        address token
    ) internal {
        if (profitBefore > 0)
            totalUnpaidToInfluencersByToken[token] -= uint256(profitBefore);
        if (profitAfter > 0)
            totalUnpaidToInfluencersByToken[token] += uint256(profitAfter);
    }

    function processInfluencerReferral(
        address influencer,
        uint256 betAmount,
        address token
    ) internal {
        (address referredBy, bool isEnabled) = getUserReferredBy(msg.sender);
        if (referredBy == address(0)) {
            // Player without influencer
            if (influencer != address(0)) {
                require(
                    influencerData[influencer].isEnabled,
                    "ReferralSystem: influencer is disabled"
                );
                // Setting the influencer for the first time
                userReferredBy[msg.sender] = influencer;
                influencerData[influencer].referrals.push(msg.sender);
                influencerData[influencer].totalBetsByToken[token] += betAmount;
            }
        } else {
            require(
                referredBy == influencer,
                "ReferralSystem: influencer cannot change"
            );
            if (isEnabled) {
                influencerData[influencer].totalBetsByToken[token] += betAmount;
            }
        }
    }

    /// @notice Allows the owner to enable or disable the allowed tokens to be used in the bets
    /// @dev The owner send an array of tokens and array of statuses make sure both are sorted in the same positions
    /// @param tokens Array of token addresses to modify the status
    /// @param usdPriceFeeds Array of token addresses of the chainlink price feed contract used to get the usd price
    function addAllowedTokens(
        address[] memory tokens,
        address[] memory usdPriceFeeds
    ) external onlyOwner {
        require(
            tokens.length == usdPriceFeeds.length,
            "DiceGame: Different inputs size"
        );

        uint32 addedTokensLength = uint32(addedTokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            addedTokensLength++;
            require(
                addedTokensLength <= MAX_TOKENS_AMOUNT,
                "DiceGame: maximum tokens length exceeded"
            );
            require(
                tokenToUsdPriceFeed[tokens[i]] == address(0),
                "DiceGame: Token already added"
            );
            require(
                usdPriceFeeds[i] != address(0),
                "ReferralSystem: invalid usd price feed"
            );
            // Pushes the new token to the list of added tokens
            // Sets the usdPriceFeed address for the token
            tokenToUsdPriceFeed[tokens[i]] = usdPriceFeeds[i];
            addedTokens.push(tokens[i]);
        }
    }

    function editUsdPriceFeed(
        address[] memory tokens,
        address[] memory usdPriceFeeds
    ) external onlyOwner {
        require(
            tokens.length == usdPriceFeeds.length,
            "DiceGame: Different inputs size"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            require(
                tokenToUsdPriceFeed[tokens[i]] != address(0),
                "DiceGame: Token has not been added"
            );
            require(
                usdPriceFeeds[i] != address(0),
                "ReferralSystem: invalid usd price feed"
            );
            tokenToUsdPriceFeed[tokens[i]] = usdPriceFeeds[i];
        }
    }

    function getInfluencers() external view returns (address[] memory) {
        return influencerWallets;
    }

    function getInfluencersLength() external view returns (uint256) {
        return influencerWallets.length;
    }

    function getReferralList(address influencer)
        external
        view
        returns (address[] memory)
    {
        return influencerData[influencer].referrals;
    }

    function getReferralLength(address influencer)
        external
        view
        returns (uint256)
    {
        return influencerData[influencer].referrals.length;
    }

    function getHistoricalPayouts(address influencer)
        external
        view
        returns (Payout[] memory)
    {
        return historicalPayoutsByInfluencer[influencer];
    }

    function getTotalNumbersByInfluencer(address influencer, address token)
        external
        view
        returns (
            uint256 totalBets,
            uint256 totalWins,
            uint256 totalLosses,
            uint256 totalRefunds,
            int256 totalInfluencerProfit,
            int256 totalCasinoProfit,
            uint256 totalPayouts
        )
    {
        totalBets = influencerData[influencer].totalBetsByToken[token];
        totalWins = influencerData[influencer].totalUserWinsByToken[token];
        totalLosses = influencerData[influencer].totalUserLossesByToken[token];
        totalRefunds = influencerData[influencer].totalUserRefundsByToken[
            token
        ];
        totalInfluencerProfit = influencerData[influencer]
            .totalInfluencerProfit[token];
        totalCasinoProfit = influencerData[influencer].totalCasinoProfit[token];
        totalPayouts = influencerData[influencer].totalPayouts[token];
    }

    function calculateInfluencerProfit(uint256 amount, address influencer)
        private
        view
        returns (uint256)
    {
        return (influencerData[influencer].percentage * amount) / 100 ether;
    }

    function getUserReferredBy(address user)
        public
        view
        returns (address influencer, bool isEnabled)
    {
        influencer = userReferredBy[user];
        isEnabled = influencerData[influencer].isEnabled;
    }
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