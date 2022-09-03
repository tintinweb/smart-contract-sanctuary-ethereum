// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title RolaGame
 */

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./RolaGameInternalUpgradeable.sol";

contract RolaGameUpgradeable is RolaGameInternalUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%

    address public rolaAddress; // address of the ROLA token

    address public adminAddress; // address of the admin

    address public operatorAddress; // address of the operator

    uint256 public minBetAmount; // minimum betting amount 

    mapping(uint256 => mapping(address => BetInfo)) public ledger;
    
    mapping(uint256 => mapping(address => uint256[])) public userRounds;

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "RolaGame: Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(msg.sender == adminAddress || msg.sender == owner(), "RolaGame: Not admin or owner");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "RolaGame: Not operator");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "RolaGame: Contract not allowed");
        require(msg.sender == tx.origin, "RolaGame: Proxy contract not allowed");
        _;
    }

    /**
     * @notice Constructor 
     * @param _adminAddress: admin address
     * @param _operatorAddress: operator address
     * @param _rolaAddress: ROLA token address
     * @param _bufferSeconds: buffer of time for resolution of price
     * @param _minBetAmount: minimum bet amounts (in wei)
     * @param _treasuryFee: treasury fee (1000 = 10%)
     */
    function initialize(
        address _adminAddress,
        address _operatorAddress,
        address _rolaAddress,
        uint256 _bufferSeconds,
        uint256 _minBetAmount,
        uint256 _treasuryFee
    ) initializer external {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __DexPriceCalculationEnabled_init();
        require(_treasuryFee <= MAX_TREASURY_FEE, "RolaGame: Treasury fee too high");
        adminAddress = _adminAddress;
        operatorAddress = _operatorAddress;
        rolaAddress = _rolaAddress;
        bufferSeconds = _bufferSeconds;
        minBetAmount = _minBetAmount;
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Bet bear position
     * @param roundId: roundId
     */
    function betBear(uint256 roundId, uint256 amount) external override whenNotPaused nonReentrant notContract {
        IERC20Upgradeable rolaCoaster = IERC20Upgradeable(rolaAddress);
        
        require(amount <= rolaCoaster.balanceOf(_msgSender()), "RolaGame: Insufficient ROLA tokens");
        require(_bettable(roundId), "RolaGame: Round not bettable");
        require(amount >= minBetAmount, "RolaGame: Bet amount must be greater than minBetAmount");
        require(ledger[roundId][msg.sender].amount == 0, "RolaGame: Can only bet once per round");

        rolaCoaster.transferFrom(_msgSender(), address(this), amount);

        // Update round data
        Round storage round = roundData[roundId];
        round.totalAmount = round.totalAmount + amount;
        round.bearAmount = round.bearAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[roundId][msg.sender];
        betInfo.position = Position.Bear;
        betInfo.amount = amount;
        userRounds[roundId][msg.sender].push(roundId);

        emit BetBear(msg.sender, roundId, amount);
    }

    /**
     * @notice Bet bull position
     * @param roundId: roundId
     * @param amount: amount
     */

    function betBull(uint256 roundId, uint256 amount) external override whenNotPaused nonReentrant notContract {
        IERC20Upgradeable rolaCoaster = IERC20Upgradeable(rolaAddress);
        
        require(amount <= rolaCoaster.balanceOf(_msgSender()), "RolaGame: Insufficient ROLA tokens");
        require(_bettable(roundId), "RolaGame: Round not bettable");
        require(amount >= minBetAmount, "RolaGame: Bet amount must be greater than minBetAmount");
        require(ledger[roundId][msg.sender].amount == 0, "RolaGame: Can only bet once per round");

        rolaCoaster.transferFrom(_msgSender(), address(this), amount);

        // Update round data
        Round storage round = roundData[roundId];
        round.totalAmount = round.totalAmount + amount;
        round.bullAmount = round.bullAmount + amount;

        // Update user data
        BetInfo storage betInfo = ledger[roundId][msg.sender];
        betInfo.position = Position.Bull;
        betInfo.amount = amount;
        userRounds[roundId][msg.sender].push(roundId);

        emit BetBull(msg.sender, roundId, amount);
    }

    /**
     * @notice Claim reward for an array of epochs
     * @param epochs: array of epochs
     */
    function claim(uint256[] calldata epochs) external override nonReentrant notContract {
        uint256 reward; // Initializes reward

        for (uint256 i = 0; i < epochs.length; i++) {
            require(roundData[epochs[i]].startTimestamp != 0, "RolaGame: Round has not started");
            uint256 closeTimestamp = roundData[epochs[i]].startTimestamp + (2 * roundData[epochs[i]].roundExecutionTime);
            require(block.timestamp > closeTimestamp, "RolaGame: Round has not ended");

            uint256 addedReward = 0;

            // Round valid, claim rewards
            if (genesisRound[epochs[i]].DexCalled) {
                require(claimable(epochs[i], msg.sender), "Not eligible for claim");
                Round memory round = roundData[epochs[i]];
                addedReward = (ledger[epochs[i]][msg.sender].amount * round.rewardAmount) / round.rewardBaseCalAmount;
            }
            // Round invalid, refund bet amount
            else {
                require(refundable(epochs[i], msg.sender), "RolaGame: Not eligible for refund");
                addedReward = ledger[epochs[i]][msg.sender].amount;
            }

            ledger[epochs[i]][msg.sender].claimed = true;
            reward += addedReward;

            emit Claim(msg.sender, epochs[i], addedReward);
        }
        if (reward > 0) {
            IERC20Upgradeable(rolaAddress).safeTransfer(address(msg.sender), reward);
        }
    }

    /**
     * @notice Start the next round n, lock price for round n-1, end round n-2
     * @dev Callable by operator
     */
    function executeRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preroundId, uint256 endroundId) external override whenNotPaused onlyOperator {
        require(
            genesisRound[preroundId].genesisStartOnce && genesisRound[endroundId].genesisLockOnce,
            "RolaGame: Can only run after genesisStartRound and genesisLockRound is triggered"
        );

        Round memory round = roundData[preroundId];
        (int currentPrice) = _getPriceFromDex(round.baseAddress, round.dexAddress);
        _safeLockRound(preroundId, currentPrice);

        Round memory roundEnd = roundData[endroundId];
        (int currentPriceEndRound) = _getPriceFromDex(round.baseAddress, roundEnd.dexAddress);
        _safeEndRound(endroundId, currentPriceEndRound);
        _calculateRewards(endroundId);
        
        _safeStartRound(baseAddress, dexAddress, roundId, startRoundTime, roundExecutionTime, endroundId);
        
        genesisRound[preroundId].genesisLockOnce = true;
        genesisRound[roundId].genesisStartOnce = true;
    }

    /**
     * @notice Lock genesis round
     * @dev Callable by operator
     */
    function genesisLockRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preRoundId) external override whenNotPaused onlyOperator {
        require(genesisRound[preRoundId].genesisStartOnce, "Can only run after genesisStartRound is triggered");
        require(!genesisRound[preRoundId].genesisLockOnce, "Can only run genesisLockRound once");
        require(!genesisRound[roundId].genesisStartOnce, "Round ID already taken");

        Round memory round = roundData[preRoundId];
        (int currentPrice) = _getPriceFromDex(round.baseAddress, round.dexAddress);
        _safeLockRound(preRoundId, currentPrice);
        _startRound(baseAddress, dexAddress, roundId, startRoundTime, roundExecutionTime);
        genesisRound[preRoundId].genesisLockOnce = true;
        genesisRound[roundId].genesisStartOnce = true;
    }

    /**
     * @notice Start genesis round
     * @dev Callable by admin or operator
     */
    function genesisStartRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime) external override whenNotPaused onlyOperator {
        require(!genesisRound[roundId].genesisStartOnce, "Can only run genesisStartRound once");        
        _startRound(baseAddress, dexAddress, roundId, startRoundTime, roundExecutionTime);
        genesisRound[roundId].genesisStartOnce = true;
    }

    /**
     * @notice End Previous round (n-2)
     * @dev Callable by admin or operator
     */
    function endRound(uint256 roundId) external override whenNotPaused onlyOperator {
        require(
            genesisRound[roundId].genesisStartOnce && genesisRound[roundId].genesisLockOnce,
            "RolaGame: Can only run after genesisStartRound and genesisLockRound is triggered"
        );
        Round memory roundEnd = roundData[roundId];
        (int currentPriceEndRound) = _getPriceFromDex(roundEnd.baseAddress, roundEnd.dexAddress);
        _safeEndRound(roundId, currentPriceEndRound);
        _calculateRewards(roundId);
    }

    /**
     * @notice Lock Previous round (n-1)
     * @dev Callable by admin or operator
     */
    function lockRound(uint256 roundId) external override whenNotPaused onlyOperator {
        require(genesisRound[roundId].genesisStartOnce, "RolaGame: Can only run after genesisStartRound is triggered");
        require(!genesisRound[roundId].genesisLockOnce, "RolaGame: Can only run genesisLockRound once");

       Round memory round = roundData[roundId];
        (int currentPrice) = _getPriceFromDex(round.baseAddress, round.dexAddress);
        _safeLockRound(roundId, currentPrice);
        genesisRound[roundId].genesisLockOnce = true;
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by admin
     */
    function claimTreasury() external override nonReentrant onlyAdmin {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        recoverToken(rolaAddress, currentTreasuryAmount);

        emit TreasuryClaim(currentTreasuryAmount);
    }

    /**
     * @notice Set buffer (in seconds)
     * @dev Callable by admin
     */
    function setBufferTime(uint256 _bufferSeconds) external override whenPaused onlyAdmin {
        require(_bufferSeconds != 0, "RolaGame: bufferSeconds must be superior to 0");
        bufferSeconds = _bufferSeconds;

        emit NewBufferSeconds(_bufferSeconds);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by admin
     */
    function setMinBetAmount(uint256 _minBetAmount) external override whenPaused onlyAdmin {
        require(_minBetAmount != 0, "RolaGame: minBetAmount must be superior to 0");
        minBetAmount = _minBetAmount;

        emit NewMinBetAmount(minBetAmount);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external override whenPaused onlyAdmin {
        require(_treasuryFee <= MAX_TREASURY_FEE, "RolaGame: Treasury fee too high");
        treasuryFee = _treasuryFee;

        emit NewTreasuryFee(treasuryFee);
    }

    /**
     * @notice Set admin address
     * @dev Callable by owner
     */
    function setAdmin(address _adminAddress) external override onlyOwner {
        require(_adminAddress != address(0), "RolaGame: Cannot be zero address");
        adminAddress = _adminAddress;

        emit NewAdminAddress(_adminAddress);
    }

    /**
     * @notice Set operator address
     * @dev Callable by admin
     */
    function setOperator(address _operatorAddress) external override onlyAdmin {
        require(_operatorAddress != address(0), "RolaGame: Cannot be zero address");
        operatorAddress = _operatorAddress;

        emit NewOperatorAddress(_operatorAddress);
    }

    /**
     * @notice Get the claimable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function claimable(uint256 epoch, address user) internal view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = roundData[epoch];
        GenesisRoundBlock storage genesisRoundData = genesisRound[epoch];
        if (round.lockPrice == round.closePrice) {
            return false;
        }
        return
            genesisRoundData.DexCalled &&
            betInfo.amount != 0 &&
            !betInfo.claimed &&
            ((round.closePrice > round.lockPrice && betInfo.position == Position.Bull) ||
                (round.closePrice < round.lockPrice && betInfo.position == Position.Bear));
    }

    /**
     * @notice Get the refundable stats of specific epoch and user account
     * @param epoch: epoch
     * @param user: user address
     */
    function refundable(uint256 epoch, address user) internal view returns (bool) {
        BetInfo memory betInfo = ledger[epoch][user];
        Round memory round = roundData[epoch];
        GenesisRoundBlock storage genesisRoundData = genesisRound[epoch];
        uint256 closeTimestamp = round.startTimestamp + (2 * round.roundExecutionTime);
        return
            !genesisRoundData.DexCalled &&
            !betInfo.claimed &&
            block.timestamp > closeTimestamp + bufferSeconds &&
            betInfo.amount != 0;
    }

    /**
     * @notice It allows the owner to recover tokens sent to the contract by mistake
     * @param _token: token address
     * @param _amount: token amount
     * @dev Callable by owner
     */
    function recoverToken(address _token, uint256 _amount) public override onlyAdminOrOwner {
        IERC20Upgradeable(_token).safeTransfer(address(msg.sender), _amount);

        emit TokenRecovery(_token, _amount);
    }

    /**
     * @notice called by the admin to pause, triggers stopped state
     * @dev Callable by admin or operator
     */
    function pause() external override whenNotPaused onlyAdmin {
        _pause();
    }

    /**
     * @notice called by the admin to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external override whenPaused onlyAdmin {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DexPriceCalculationUpgradeable.sol";
import "./IRolaGameUpgradeable.sol";

abstract contract RolaGameInternalUpgradeable is DexPriceCalculationUpgradeable, IRolaGameUpgradeable {

    mapping(uint256 => Round) public roundData;

    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)

    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public bufferSeconds; // number of seconds for valid execution of a prediction round

    mapping(uint256 => GenesisRoundBlock) public genesisRound;

    enum Position {
        Bull,
        Bear
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 roundExecutionTime;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        int256 lockPrice;
        int256 closePrice;
        address dexAddress;
        address baseAddress;
    }

    // Structure for creating genesis block
    struct GenesisRoundBlock {
        bool genesisLockOnce;
        bool genesisStartOnce;
        bool DexCalled;
    }

    /**
     * @notice Calculating the rewards of round
     * @param roundId: Round Id
    */

    function _calculateRewards(uint256 roundId) internal {
        require(
            roundData[roundId].rewardBaseCalAmount == 0 &&
                roundData[roundId].rewardAmount == 0,
            "RolaGame: Rewards calculated"
        );
        Round storage round = roundData[roundId];
        uint256 rewardBaseCalAmount;
        uint256 calculateTreasuryAmount;
        uint256 calculateRewardAmount;

        // Bull wins
        if (round.closePrice > round.lockPrice) {
            rewardBaseCalAmount = round.bullAmount;
            calculateTreasuryAmount = (round.totalAmount * treasuryFee) / 10000;
            calculateRewardAmount = round.totalAmount - calculateTreasuryAmount;
        }
        // Bear wins
        else if (round.closePrice < round.lockPrice) {
            rewardBaseCalAmount = round.bearAmount;
            calculateTreasuryAmount = (round.totalAmount * treasuryFee) / 10000;
            calculateRewardAmount = round.totalAmount - calculateTreasuryAmount;
        }
        // House wins
        else {
            rewardBaseCalAmount = 0;
            calculateRewardAmount = 0;
            calculateTreasuryAmount = round.totalAmount;
        }
        round.rewardBaseCalAmount = rewardBaseCalAmount;
        round.rewardAmount = calculateRewardAmount;

        // Add to treasury
        treasuryAmount += calculateTreasuryAmount;

        emit RewardsCalculated(roundId, rewardBaseCalAmount, calculateRewardAmount, calculateTreasuryAmount);
    }

    /**
     * @notice safe end round by passing parameters.
     * @param roundId: Round Id.
     * @param price: Round Close Price.
    */

    function _safeEndRound(uint256 roundId, int256 price) internal {
        uint256 closeTimestamp = roundData[roundId].startTimestamp + (2 * roundData[roundId].roundExecutionTime);
        uint256 lockTimestamp = roundData[roundId].startTimestamp + roundData[roundId].roundExecutionTime;
        require(
            lockTimestamp != 0,
            "RolaGame: Can only end round after round has locked"
        );
        require(
            block.timestamp >= closeTimestamp,
            "RolaGame: Can only end round after closeTimestamp"
        );
        require(
            block.timestamp <=
                closeTimestamp + bufferSeconds,
            "RolaGame: Can only end round within bufferSeconds"
        );
        Round storage round = roundData[roundId];
        GenesisRoundBlock storage genesisRoundData = genesisRound[roundId];
        round.closePrice = price;
        genesisRoundData.DexCalled = true;

        emit EndRound(roundId, round.closePrice);
    }

    /**
     * @notice safe lock round by passing parameters
     * @param roundId: Round Id
     * @param price: Round Lock Price.
    */

    function _safeLockRound(uint256 roundId, int256 price) internal {
        uint256 lockTimestamp = roundData[roundId].startTimestamp + roundData[roundId].roundExecutionTime;
        require(
            roundData[roundId].startTimestamp != 0,
            "RolaGame: Can only lock round after round has started"
        );
        require(
            block.timestamp >= lockTimestamp,
            "RolaGame: Can only lock round after lockTimestamp"
        );
        require(
            block.timestamp <=
                lockTimestamp + bufferSeconds,
            "RolaGame: Can only lock round within bufferSeconds"
        );
        Round storage round = roundData[roundId];
        round.lockPrice = price;

        emit LockRound(roundId, round.lockPrice);
    }

    /**
     * @notice Start round by passing parameters
     * @param dexAddress: Dex address
     * @param roundId: Round Id
     * @param startRoundTime: Start Round Time
     * @param roundExecutionTime: Round execution time
     * @param endroundId: End round id
    */

    function _safeStartRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 endroundId) internal {
        uint256 closeTimestamp = roundData[endroundId].startTimestamp + (2 * roundData[endroundId].roundExecutionTime);
        require(
            genesisRound[endroundId].genesisStartOnce,
            "RolaGame: Can only run after genesisStartRound is triggered"
        );
        require(
            closeTimestamp != 0,
            "RolaGame: Can only start round after round has ended"
        );
        require(
            block.timestamp >= closeTimestamp,
            "RolaGame: Can only start new round after round n-2 closeTimestamp"
        );
        _startRound(baseAddress, dexAddress, roundId, startRoundTime, roundExecutionTime);
    }

    /**
     * @notice Start round by passing parameters
     * @param dexAddress: Dex address
     * @param roundId: Round Id
     * @param startRoundTime: Start Round Time
     * @param roundExecutionTime: Round execution time
    */

    function _startRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime) internal {
        Round storage round = roundData[roundId];
        round.dexAddress = dexAddress;
        round.baseAddress = baseAddress;
        round.roundExecutionTime = roundExecutionTime;
        round.startTimestamp = startRoundTime;
        round.epoch = roundId;
        round.totalAmount = 0;
        emit StartRound(roundId, round.dexAddress);
    }

    /**
     * @notice Checking the round is bettable
     * @dev Checking the the round id bettable or not
     * @param roundId: Round Id
     * @return bool: If timestamp and lock timestamp will retun bool
    */

    function _bettable(uint256 roundId) internal view returns (bool) {
        uint256 lockTimestamp = roundData[roundId].startTimestamp + roundData[roundId].roundExecutionTime;
        return
            roundData[roundId].startTimestamp != 0 &&
            lockTimestamp != 0 &&
            block.timestamp > roundData[roundId].startTimestamp &&
            block.timestamp < lockTimestamp;
    }

    /**
     * @notice Checking get price from the Dex
     * @param dexAddress: Dex Address
     * @return currentPrice: Get Current Price after passing Dex address
    */

    function _getPriceFromDex(address baseAddress, address dexAddress) internal view returns (int) {
        (int currentPrice) = getTokenPriceInBaseToken(baseAddress, dexAddress);
        return (currentPrice);
    }

    /**
     * @notice Checking the contract
     * @param account: Account address
     * @return size: check the size of contract
    */

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @dev Interface of the RolaGame implementation.
 * @author The Systango Team
 */

interface IRolaGameUpgradeable {

    /**
     * @dev Event generated when Bet will happen at BetBear
     */
    event BetBear(address indexed sender, uint256 indexed epoch, uint256 amount);

    /**
     * @dev Event generated when Bet will happen at BetBull
     */
    event BetBull(address indexed sender, uint256 indexed epoch, uint256 amount);

    /**
     * @dev Event generated when user will claim
     */
    event Claim(address indexed sender, uint256 indexed epoch, uint256 amount);

    /**
     * @dev Event generated when Round will lock
     */
    event LockRound(uint256 indexed roundId, int256 price);

    /**
     * @dev Event generated when Round will end
     */
    event EndRound(uint256 indexed roundId, int256 price);

    /**
     * @dev Event generated when a new Admin Address is set
     */
    event NewAdminAddress(address admin);

    /**
     * @dev Event generated when a new Buffer time is set
     */
    event NewBufferSeconds(uint256 bufferSeconds);

    /**
     * @dev Event generated when a new Mint Amount is set
     */
    event NewMinBetAmount(uint256 minBetAmount);

    /**
     * @dev Event generated when a new Tresury Fee is set
     */
    event NewTreasuryFee(uint256 treasuryFee);

    /**
     * @dev Event generated when a new Operator is set
     */
    event NewOperatorAddress(address operator);

    /**
     * @dev Event generated when Reward Calculation happen
     */
    event RewardsCalculated(uint256 indexed roundId, uint256 rewardBaseCalAmount, uint256 rewardAmount, uint256 treasuryAmount);

    /**
     * @dev Event generated when Round Start
     */
    event StartRound(uint256 indexed roundId, address dexAddress);

    /**
     * @dev Event generated when token is recovered
     */
    event TokenRecovery(address indexed token, uint256 amount);

    /**
     * @dev Event generated when Claimed treasury account
     */
    event TreasuryClaim(uint256 amount);

    function genesisStartRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime) external;

    function betBear(uint256 roundId, uint256 amount) external;

    function betBull(uint256 roundId, uint256 amount) external;

    function genesisLockRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preRoundId) external;

    function executeRound(address baseAddress, address dexAddress, uint256 roundId, uint256 startRoundTime, uint256 roundExecutionTime, uint256 preroundId, uint256 endroundId) external;

    function claim(uint256[] calldata epochs) external;

    function endRound(uint256 roundId) external;

    function lockRound(uint256 roundId) external;

    function claimTreasury() external;

    function setBufferTime(uint256 _bufferSeconds) external;

    function setMinBetAmount(uint256 _minBetAmount) external;

    function setTreasuryFee(uint256 _treasuryFee) external;

    function setAdmin(address _adminAddress) external;

    function setOperator(address _operatorAddress) external;

    function recoverToken(address _token, uint256 _amount) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DexPriceCalculationUpgradeable is Initializable {

    function __DexPriceCalculationEnabled_init() internal onlyInitializing {
        __DexPriceCalculationEnabled_init_unchained();
    }

    function __DexPriceCalculationEnabled_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Calculate price based on pair reserves
     * @param dexAddress: Dex Address
    */
    function getTokenPriceInBaseToken(address dexAddress, address baseAddress) public view returns(int res) {
        IUniswapV2Pair pair = IUniswapV2Pair(dexAddress);
        IUniswapV2ERC20 token1 = IUniswapV2ERC20(pair.token1());
        IUniswapV2ERC20 token0 = IUniswapV2ERC20(pair.token0());
        (uint Res0, uint Res1,) = pair.getReserves();
        uint res0 = Res0*(10**token1.decimals());
        uint res1 = Res1*(10**token0.decimals());
        if(pair.token0() == baseAddress){
            res = int(((res0*(10**18))/res1));
            return (res);
        }
        if(pair.token1() == baseAddress){
            res = int(((res1*(10**18))/res0));
            return (res);
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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