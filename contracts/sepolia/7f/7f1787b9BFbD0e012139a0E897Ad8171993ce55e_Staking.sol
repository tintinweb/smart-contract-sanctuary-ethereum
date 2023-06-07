// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IHelix.sol";
import "./interfaces/IKondux.sol";
import "./interfaces/IKonduxERC20.sol";
import "./types/AccessControlled.sol";

contract Staking is AccessControlled {
    using Counters for Counters.Counter;

    Counters.Counter private _depositIds;

    /**
     * @dev Struct representing a staker's information.
     */
    struct Staker {
        // The address of the staked token
        address token;
        // The address of the staker
        address staker;
        // The total amount of tokens deposited by the staker
        uint256 deposited;
        // The total amount of tokens redeemed by the staker
        uint256 redeemed;
        // The timestamp of the last update for this staker's deposit
        uint256 timeOfLastUpdate;
        // The timestamp of the staker's last deposit
        uint256 lastDepositTime;
        // The accumulated, but unclaimed rewards for the staker. These are calculated
        // each time a user writes to the contract
        uint256 unclaimedRewards;
        // The duration of the timelock applied to the staker's deposit
        uint256 timelock;
        // The category of the timelock applied to the staker's deposit
        uint8 timelockCategory;
        // ERC20 Ratio at the time of staking
        uint256 ratioERC20;
    } 

    enum LockingTimes {        
        OneMonth, // 0
        ThreeMonths, // 1
        SixMonths, // 2
        OneYear, // 3
        Test, // 4
        Test24h, // 5
        Test48h // 6
    }

    // The deposit IDs associated with a user's address
    mapping(address => uint[]) public userDepositsIds;

    // The Staker struct information associated with a deposit ID
    mapping(uint => Staker) public userDeposits;

    // Indicates whether a specific ERC20 token is authorized for staking
    mapping (address => bool) public authorizedERC20;

    // The minimum amount required to stake for a specific ERC20 token
    mapping (address => uint256) public minStakeERC20;

    // The compound frequency for a specific ERC20 token
    mapping (address => uint256) public compoundFreqERC20;

    // The rewards per hour for a specific ERC20 token
    mapping (address => uint256) public aprERC20;

    // The withdrawal fee for a specific ERC20 token
    mapping (address => uint256) public withdrawalFeeERC20;

    // The founders reward boost for a specific ERC20 token
    mapping (address => uint256) public foundersRewardBoostERC20;

    // The kNFT reward boost for a specific ERC20 token
    mapping (address => uint256) public kNFTRewardBoostERC20;

    // The ratio for a specific ERC20 token
    mapping (address => uint256) public ratioERC20;

    // The decimals of a specific ERC20 token
    mapping (address => uint8) public decimalsERC20;

    // The total amount staked for a specific ERC20 token
    mapping (address => uint256) public totalStaked;

    // The total amount staked by a user for a specific ERC20 token
    mapping (address => mapping (address => uint256)) public userTotalStakedByCoin;

    // The total amount rewarded for a specific ERC20 token
    mapping (address => uint256) public totalRewarded;

    // The total amount rewarded by a user for a specific ERC20 token
    mapping (address => mapping (address => uint256)) public userTotalRewardedByCoin;

    // The total amount paid as a withdrawal fee for a specific ERC20 token
    mapping (address => uint256) public totalWithdrawalFees;

    // The penalty for withdrawing early for a specific ERC20 token
    mapping (address => uint256) public earlyWithdrawalPenalty;

    // The boost for a specific timelock category
    mapping(uint => uint256) public timelockCategoryBoost;

    // The divisor for a specific token
    mapping (address => uint256) public divisorERC20;

    // The allowed dnaVersion for reward boost
    mapping (uint256 => bool) public allowedDnaVersions;

    // Map of timelock durartions
    mapping(uint8 => uint256) public timelockDurations;

    IHelix public helixERC20; // Helix ERC20 Token
    IERC721 public konduxERC721Founders; // Kondux ERC721 Founders Token
    address public konduxERC721kNFT; // Kondux ERC721 kNFT Token
    ITreasury public treasury; // Treasury Contract

    // Events
    // Emitted when a staker withdraws their rewards
    event Withdraw(address indexed user, uint256 liquidAmount, uint256 fees);

    // Emitted when a staker withdraws all their rewards
    event WithdrawAll(address indexed staker, uint256 amount);

    // Emitted when a staker compounds their rewards
    event Compound(address indexed staker, uint256 amount);

    // Emitted when a staker stakes their tokens
    event Stake(uint indexed id, address indexed staker, address token, uint256 amount);

    // Emitted when a staker unstakes their tokens
    event Unstake(address indexed staker, uint256 amount);

    // Emitted when a staker receives a reward
    event Reward(address indexed user, uint256 netRewards, uint256 fees);

    // Emitted when the rewards per hour is updated for a token
    event NewAPR(uint256 indexed amount, address indexed token);

    // Emitted when the minimum stake is updated for a token
    event NewMinStake(uint256 indexed amount, address indexed token);

    // Emitted when the compound frequency is updated for a token
    event NewCompoundFreq(uint256 indexed amount, address indexed token);

    // Emitted when the Helix ERC20 token is updated
    event NewHelixERC20(address indexed helixERC20);

    // Emitted when the Kondux ERC721 Founders token is updated
    event NewKonduxERC721Founders(address indexed konduxERC721Founders);

    // Emitted when the Kondux ERC721 kNFT token is updated
    event NewKonduxERC721kNFT(address indexed konduxERC721kNFT);

    // Emitted when the treasury address is updated
    event NewTreasury(address indexed treasury);

    // Emitted when the withdrawal fee is updated for a token
    event NewWithdrawalFee(uint256 indexed amount, address indexed token);

    // Emitted when the founders reward boost is updated for a token
    event NewFoundersRewardBoost(uint256 indexed amount, address indexed token);

    // Emitted when the kNFT reward boost is updated for a token
    event NewKNFTRewardBoost(uint256 indexed amount, address indexed token);

    // Emitted when a token is authorized or deauthorized for staking
    event NewAuthorizedERC20(address indexed token, bool indexed authorized);

    // Emitted when the ratio is updated for a token
    event NewRatio(uint256 indexed amount, address indexed token);

    // Emitted when a new divisor is set for a token
    event NewDivisorERC20(uint256 indexed amount, address indexed token);
 

    /**
     * @dev Initializes the staking contract with the provided parameters.
     *
     * @param _authority The address of the authority contract.
     * @param _konduxERC20 The address of the Kondux ERC20 token contract.
     * @param _treasury The address of the treasury contract.
     * @param _konduxERC721Founders The address of the Kondux ERC721 Founders token contract.
     * @param _konduxERC721kNFT The address of the Kondux ERC721 kNFT token contract.
     * @param _helixERC20 The address of the Helix ERC20 token contract.
     *
     * The constructor sets up the initial state of the staking contract by initializing contract variables,
     * setting up default staking token parameters, and authorizing the Kondux ERC20 token for staking.
     */
    constructor(
        address _authority,
        address _konduxERC20,
        address _treasury,
        address _konduxERC721Founders,
        address _konduxERC721kNFT,
        address _helixERC20
    ) AccessControlled(IAuthority(_authority)) {
        // Ensure the provided addresses are valid
        require(_konduxERC20 != address(0), "Kondux ERC20 address is not set");
        require(_treasury != address(0), "Treasury address is not set");
        require(_konduxERC721Founders != address(0), "Kondux ERC721 Founders address is not set");
        require(_konduxERC721kNFT != address(0), "Kondux ERC721 kNFT address is not set");
        require(_helixERC20 != address(0), "Helix ERC20 address is not set");

        // Initialize contract variables
        konduxERC721Founders = IERC721(_konduxERC721Founders);
        konduxERC721kNFT = _konduxERC721kNFT;
        helixERC20 = IHelix(_helixERC20);
        treasury = ITreasury(_treasury);

        timelockDurations[0] = 30 days;         // 1 month
        timelockDurations[1] = 90 days;         // 3 months
        timelockDurations[2] = 180 days;        // 6 months
        timelockDurations[3] = 365 days;        // 1 year

        // Set up default staking token parameters
        setDivisorERC20(10_000, _konduxERC20); // 10,000 basis points
        setWithdrawalFee(100, _konduxERC20); // 1% fee on withdrawal or 100 / 10_000
        setFoundersRewardBoost(1_000, _konduxERC20); // 10% boost (=110%) on rewards or 1,000,000/10,000,000
        setkNFTRewardBoost(500, _konduxERC20); // 5% boost on rewards or 500 / 
        setMinStake(10_000_000, _konduxERC20); // 10,000,000 wei
        setAPR(25, _konduxERC20); // 0.00285%/h or 25% APR
        setCompoundFreq(60 * 60 * 24, _konduxERC20); // 24 hours
        setRatio(10_000, _konduxERC20); // 10,000:1 ratio, adjusted for kondux ERC20 decimals
        setEarlyWithdrawalPenalty(_konduxERC20, 10); // 10% penalty
        setTimelockCategoryBoost(1, 100); // 1% boost for 90 days timelock
        setTimelockCategoryBoost(2, 300); // 3% boost for 180 days timelock 
        setTimelockCategoryBoost(3, 900); // 9% boost for 365 days timelock
        setAllowedDnaVersion(1, true); // allow DNA version 1
        setDecimalsERC20(helixERC20.decimals(), _helixERC20); // set decimals for Helix ERC20 token 
        setDecimalsERC20(IKonduxERC20(_konduxERC20).decimals(), _konduxERC20); // set decimals for Kondux ERC20 token

        _setAuthorizedERC20(_konduxERC20, true);
    }

    /**
     * @dev This function allows a user to deposit a specified amount of an authorized token with a selected timelock period.
     *      The function checks the user's token balance, allowance, and the timelock value before proceeding.
     *      It then creates a new deposit record, sets the timelock based on the selected category, and updates the user's
     *      deposit list and total staked amount. The specified amount of tokens is transferred from the user to the vault,
     *      and an equivalent amount of reward tokens is minted for the user.
     * @param _amount The amount of tokens to deposit.
     * @param _timelock The timelock category, represented as an integer (0-4).
     * @param _token The address of the token contract.
     * @return _id The deposit ID assigned to this deposit.
     */
    function deposit(uint256 _amount, uint8 _timelock, address _token) public returns (uint) {
        // Check if the token address is set
        require(_token != address(0), "Token address is not set");
        // Check if the token is authorized for staking
        require(authorizedERC20[_token], "Token not authorized");
        // Check if the deposit amount is greater than or equal to the minimum required stake
        require(_amount >= minStakeERC20[_token], "Amount smaller than minimimum deposit");
        IERC20 konduxERC20 = IERC20(_token);
        // Check if the user has enough balance to stake the specified amount
        require(konduxERC20.balanceOf(msg.sender) >= _amount, "Can't stake more than you own");
        // Check if the user has approved the staking contract to spend the specified amount
        require(konduxERC20.allowance(msg.sender, address(this)) >= _amount, "Allowance not set");
        // Check if the selected timelock category is valid (between 0 and 3)
        require(_timelock <= 3, "Invalid timelock");

        // Get the current deposit ID
        uint _id = _depositIds.current();

        // Create a new deposit record for the user
        userDeposits[_id] = Staker({
            token: _token,
            staker: msg.sender,
            deposited: _amount,
            unclaimedRewards: 0,
            timelock: block.timestamp + timelockDurations[_timelock], // Set the timelock period based on the selected category
            timelockCategory: _timelock,
            timeOfLastUpdate: block.timestamp,
            lastDepositTime: block.timestamp,
            redeemed: 0,
            ratioERC20: ratioERC20[_token]
        });

        // Add the deposit ID to the user's deposit list
        userDepositsIds[msg.sender].push(_id);

        // Update the user's total staked amount
        _addTotalStakedAmount(_amount, _token, msg.sender);
        
        // Mint an equivalent amount of reward tokens for the user
        // Get the decimals of the original staked token and Helix
        uint8 originalTokenDecimals = decimalsERC20[_token];
        uint8 helixDecimals = decimalsERC20[address(helixERC20)];

        // Calculate the decimal difference
        uint decimalDifference;
        if (helixDecimals > originalTokenDecimals) {
            decimalDifference = helixDecimals - originalTokenDecimals;
        } else {
            decimalDifference = 0;
        }

        // Transfer the deposited tokens from the user to the vault
        konduxERC20.transferFrom(msg.sender, authority.vault(), _amount);

        // Mint an equivalent amount of reward tokens for the user, adjusted based on the decimal difference
        helixERC20.mint(msg.sender, _amount * ratioERC20[_token] * (10 ** decimalDifference));

        // Increment the deposit ID counter
        _depositIds.increment();

        // Emit a Stake event
        emit Stake(_id, msg.sender, _token, _amount);

        return _id;
    }

    /**
     * @dev This function allows the owner of a deposit to stake their earned rewards.
     *      It verifies that the caller is the deposit owner and that the compounding is not happening too soon.
     *      The function calculates the rewards, resets the unclaimed rewards to zero, and updates the deposit record.
     *      The total staked amount is updated, and an equivalent amount of reward tokens is minted for the user.
     * @param _depositId The ID of the deposit whose rewards are to be staked.
     */
    function stakeRewards(uint _depositId) public {
        // Verify that the caller is the owner of the deposit
        require(msg.sender == userDeposits[_depositId].staker, "You are not the owner of this deposit");
        // Verify that the user is not trying to compound rewards too soon
        // require(compoundRewardsTimer(_depositId) == 0, "Tried to compound rewards too soon");

        // Calculate the rewards and add any unclaimed rewards
        uint256 rewards = calculateRewards(msg.sender, _depositId) + userDeposits[_depositId].unclaimedRewards;

        // Check if the rewards are non-zero
        require(rewards > 0, "No rewards available");

        // Reset the unclaimed rewards to zero
        userDeposits[_depositId].unclaimedRewards = 0;
        // Update the deposited amount with the compounded rewards
        userDeposits[_depositId].deposited += rewards;
        // Update the time of the last update
        userDeposits[_depositId].timeOfLastUpdate = block.timestamp;

        // Update the user's total staked amount
        _addTotalStakedAmount(rewards, userDeposits[_depositId].token, userDeposits[_depositId].staker);

        // Mint an equivalent amount of reward tokens for the user
        // Get the decimals of the original staked token and Helix
        uint8 originalTokenDecimals = decimalsERC20[userDeposits[_depositId].token];
        uint8 helixDecimals = decimalsERC20[address(helixERC20)];

        // Calculate the decimal difference
        uint decimalDifference;
        if (helixDecimals > originalTokenDecimals) {
            decimalDifference = helixDecimals - originalTokenDecimals;
        } else {
            decimalDifference = 0;
        }

        // Mint the calculated rewards for the user, adjusted based on the decimal difference
        helixERC20.mint(msg.sender, rewards * userDeposits[_depositId].ratioERC20 * (10 ** decimalDifference));

        // Emit a Compound event
        emit Compound(msg.sender, rewards);
    }

    /**
     * @dev This function allows the owner of a deposit to claim their earned rewards.
     *      It verifies that the caller is the deposit owner and that the timelock has passed.
     *      The function calculates the rewards, resets the unclaimed rewards to zero, and updates the deposit record.
     *      The reward tokens are burned, and the earned rewards are transferred to the user from the vault.
     *      The function emits a Reward event upon successful execution.
     * @param _depositId The ID of the deposit whose rewards are to be claimed.
     */
    function claimRewards(uint _depositId) public {
        require(msg.sender == userDeposits[_depositId].staker, "You are not the owner of this deposit");
        require(block.timestamp >= userDeposits[_depositId].timelock, "Timelock not passed");

        uint256 rewards = calculateRewards(msg.sender, _depositId) + userDeposits[_depositId].unclaimedRewards;

        require(rewards > 0, "You have no rewards");

        userDeposits[_depositId].unclaimedRewards = 0;
        userDeposits[_depositId].timeOfLastUpdate = block.timestamp;

        IERC20 konduxERC20 = IERC20(userDeposits[_depositId].token);

        uint256 netRewards = (rewards * (10_000 - withdrawalFeeERC20[userDeposits[_depositId].token])) / divisorERC20[userDeposits[_depositId].token];
        uint256 fees = rewards - netRewards;

        konduxERC20.transferFrom(authority.vault(), msg.sender, netRewards); 

        _addTotalRewardedAmount(netRewards, userDeposits[_depositId].token, userDeposits[_depositId].staker);
        _addTotalWithdrawalFees(rewards - netRewards, userDeposits[_depositId].token);

        emit Reward(msg.sender, netRewards, fees);
    }

    /**
     * @dev This function allows the owner of a deposit to withdraw a specified amount of their deposited tokens.
     *      It verifies that the timelock has passed, the caller is the deposit owner, and the withdrawal amount
     *      is within the available limits. The function calculates the rewards, updates the deposit record, and
     *      transfers the liquid amount to the user after applying the withdrawal fee. The collateral tokens are burned.
     *      The function emits a Withdraw event upon successful execution.
     * @param _amount The amount of tokens to withdraw.
     * @param _depositId The ID of the deposit from which to withdraw the tokens.
     */
    function withdraw(uint256 _amount, uint _depositId) public {
        // Verify that the timelock has passed
        require(block.timestamp >= userDeposits[_depositId].timelock, "Timelock not passed");
        // Verify that the caller is the owner of the deposit
        require(msg.sender == userDeposits[_depositId].staker, "You are not the owner of this deposit");
        // Verify that the withdrawal amount is within the available limits
        require(userDeposits[_depositId].deposited >= _amount, "Can't withdraw more than you have");
        // Verify that the withdrawal amount is less than or equal to the collateral tokens the user has
        require(_amount * userDeposits[_depositId].ratioERC20 <= helixERC20.balanceOf(msg.sender), "Can't withdraw more tokens than the collateral you have");

        // Calculate the rewards
        uint256 _rewards = calculateRewards(msg.sender, _depositId);
        // Update the deposit record
        userDeposits[_depositId].deposited -= _amount;
        userDeposits[_depositId].timeOfLastUpdate = block.timestamp;
        userDeposits[_depositId].unclaimedRewards += _rewards;

        // Calculate the liquid amount to transfer after applying the withdrawal fee
        uint256 _liquid = (_amount * (divisorERC20[userDeposits[_depositId].token] - withdrawalFeeERC20[userDeposits[_depositId].token])) / divisorERC20[userDeposits[_depositId].token];
        uint256 fees = _amount - _liquid;

        // Get the token contract
        IERC20 konduxERC20 = IERC20(userDeposits[_depositId].token);

        // Check if the treasury contract has approved the staking contract to withdraw the tokens
        require(konduxERC20.allowance(authority.vault(), address(this)) >= _liquid, "Treasury Contract need to approve Staking Contract to withdraw your tokens -- please call an Admin");

        // Subtract the staked amount
        _subtractStakedAmount(_amount, userDeposits[_depositId].token, userDeposits[_depositId].staker);

        // Get the decimals of the original staked token and Helix
        uint8 originalTokenDecimals = decimalsERC20[userDeposits[_depositId].token];
        uint8 helixDecimals = decimalsERC20[address(helixERC20)];

        // Calculate the decimal difference
        uint decimalDifference;
        if (originalTokenDecimals < helixDecimals) {
            decimalDifference = helixDecimals - originalTokenDecimals;
        } else {
            decimalDifference = 0;
        }

        // Burn the equivalent amount of collateral tokens, adjusted based on the decimal difference
        helixERC20.burn(msg.sender, _amount * userDeposits[_depositId].ratioERC20 * (10 ** decimalDifference));

        
        // Transfer the liquid amount to the user
        konduxERC20.transferFrom(authority.vault(), msg.sender, _liquid);

        // Update the user's total rewarded amount + total rewarded amount for the token
        _addTotalRewardedAmount(_liquid, userDeposits[_depositId].token, userDeposits[_depositId].staker); 
        _addTotalWithdrawalFees(_amount - _liquid, userDeposits[_depositId].token); 

        // Emit a Withdraw event
        emit Withdraw(msg.sender, _liquid, fees);
    }

    /**
     * @dev This function allows the owner of a deposit to withdraw a specified amount of their deposited tokens
     *      before the timelock has passed. The user is punished by not receiving any reward boosts and paying an extra
     *      fee proportional to the time left until the lock (the closer to the end of the locking time, the smaller the fee,
     *      starting at 10%).
     *      It verifies that the caller is the deposit owner, and the withdrawal amount is within the available limits.
     *      The function calculates the rewards, updates the deposit record, and transfers the liquid amount to the user
     *      after applying the extra fee and withdrawal fee. The collateral tokens are burned.
     *      The function emits a Withdraw event upon successful execution.
     * @param _amount The amount of tokens to withdraw.
     * @param _depositId The ID of the deposit from which to withdraw the tokens.
     */
    function earlyUnstake(uint256 _amount, uint _depositId) public {
        // Verify that the caller is the owner of the deposit
        require(msg.sender == userDeposits[_depositId].staker, "You are not the owner of this deposit");
        // Verify that the withdrawal amount is within the available limits
        require(userDeposits[_depositId].deposited >= _amount, "Can't withdraw more than you have");
        // Verify that the withdrawal amount is less than or equal to the collateral tokens the user has
        require(_amount * userDeposits[_depositId].ratioERC20 <= helixERC20.balanceOf(msg.sender), "Can't withdraw more tokens than the collateral you have");
        // Verify if the timelock has passed
        require(block.timestamp < userDeposits[_depositId].timelock, "Timelock has passed");

        // Calculate the extra fee proportional to the time left until the lock (the closer to the end of the locking time, the smaller the fee)
        uint256 timeLeft = userDeposits[_depositId].timelock - block.timestamp;
        uint256 lockDuration = userDeposits[_depositId].timelock - userDeposits[_depositId].lastDepositTime;
        uint256 extraFee = (_amount * earlyWithdrawalPenalty[userDeposits[_depositId].token] * timeLeft) / (lockDuration * 100);

        // If extra fee is more than the amount, set it to the amount
        if (extraFee > _amount) {
            extraFee = _amount;
        }

        // If extra fee is zero, apply 1% fee
        if (extraFee == 0) {
            extraFee = (_amount * 1) / 100;
        }

        // Calculate the total fee percentage
        uint256 totalFeePercentage = extraFee + withdrawalFeeERC20[userDeposits[_depositId].token];

        // Calculate the liquid amount to transfer after applying the total fee
        uint256 _liquid = (_amount - totalFeePercentage);
        uint256 fees = _amount - _liquid;

        // Update the deposit record
        userDeposits[_depositId].deposited -= _amount;
        userDeposits[_depositId].timeOfLastUpdate = block.timestamp;

        // Get the token contract
        IERC20 konduxERC20 = IERC20(userDeposits[_depositId].token);

        // Check if the treasury contract has approved the staking contract to withdraw the tokens
        require(konduxERC20.allowance(authority.vault(), address(this)) >= _liquid, "Treasury Contract need to approve Staking Contract to withdraw your tokens -- please call an Admin");

        // Subtract the staked amount
        _subtractStakedAmount(_amount, userDeposits[_depositId].token, userDeposits[_depositId].staker);

        // Calculate the decimal difference
        uint decimalDifference;
        if (decimalsERC20[userDeposits[_depositId].token] < decimalsERC20[address(helixERC20)]) {
            decimalDifference = decimalsERC20[address(helixERC20)] - decimalsERC20[userDeposits[_depositId].token];
        } else {
            decimalDifference = 0;
        }

        // Burn the equivalent amount of collateral tokens, adjusted based on the decimal difference
        helixERC20.burn(msg.sender, _amount * userDeposits[_depositId].ratioERC20 * (10 ** decimalDifference));
        
        // Transfer the liquid amount to the user
        konduxERC20.transferFrom(authority.vault(), msg.sender, _liquid);

        // Update the user's total rewarded amount + total rewarded amount for the token
        _addTotalRewardedAmount(_liquid, userDeposits[_depositId].token, userDeposits[_depositId].staker); 
        _addTotalWithdrawalFees(_amount - _liquid, userDeposits[_depositId].token); 

        // Emit a Withdraw event
        emit Withdraw(msg.sender, _liquid, fees);
    }

    /**
     * @dev This function allows the owner of a deposit to withdraw a specified amount of their deposited tokens
     *      and claim their earned rewards in a single transaction. It calls the withdraw and claimRewards functions.
     * @param _amount The amount of tokens to withdraw.
     * @param _depositId The ID of the deposit from which to withdraw the tokens and claim the rewards.
     */
    function withdrawAndClaim(uint256 _amount, uint _depositId) public {
        withdraw(_amount, _depositId);
        claimRewards(_depositId);
    }

    /**
     * @dev This function returns the remaining time until the next allowed compounding action for a given deposit ID.
     *      It calculates the remaining time based on the compound frequency for the deposited token.
     *      If the timer has already passed, it returns 0.
     * @param _depositId The ID of the deposit for which to return the compound timer.
     * @return remainingTime The remaining time until the next allowed compounding action in seconds.
     */
    function compoundRewardsTimer(uint _depositId) public view returns (uint256 remainingTime) {
        uint256 lastUpdateTime = userDeposits[_depositId].timeOfLastUpdate;
        uint256 compoundFrequency = compoundFreqERC20[userDeposits[_depositId].token];

        if (block.timestamp >= lastUpdateTime + compoundFrequency) {
            return 0;
        }

        remainingTime = (lastUpdateTime + compoundFrequency) - block.timestamp;
        return remainingTime;
    }

    /**
     * @dev This function calculates the rewards for a specified staker and deposit ID. The rewards calculation
     *      considers the deposit's elapsed time, staked amount, and a 25% APY compounded hourly.
     *      If the provided staker is not the owner of the deposit, the function returns 0.
     * @param _staker The address of the staker for which to calculate the rewards.
     * @param _depositId The ID of the deposit for which to calculate the rewards.
     * @return rewards The calculated rewards for the specified staker and deposit ID.
     */
    function calculateRewards(address _staker, uint _depositId) public view returns (uint256 rewards) {
        // Retrieve deposit details by _depositId
        Staker memory deposit_ = userDeposits[_depositId];

        // Check if the staker is the owner of the deposit; if not, return 0
        if (deposit_.staker != _staker) {
            return 0;
        }

        // Calculate the elapsed time since the last update
        uint256 elapsedTime = block.timestamp - deposit_.timeOfLastUpdate;
        // Get the deposited amount
        uint256 depositedAmount = deposit_.deposited;

        // Calculate the base reward per second using the token's APR
        uint256 tokenApr = aprERC20[deposit_.token];

        /**
         * @dev This line calculates the reward earned per second by a staker for their deposit, considering the deposit's APR (annual percentage rate).
         *
         * The formula breakdown:
         * 1. depositedAmount: The amount of tokens the staker deposited.
         * 2. tokenApr: The annual percentage rate for the token in question (e.g. 25% APR).
         * 3. 1e18: A scaling factor used to maintain precision in the calculations (10^18 or 1 followed by 18 zeros).
         * 4. 365 * 24 * 3600: The total number of seconds in a year, used to convert the APR to a per-second rate.
         * 5. 100: Used to convert the APR percentage to a decimal (e.g. 25% becomes 0.25).
         *
         * The formula calculates the per-second reward by multiplying the deposited amount and the token's APR, and then scaling it up by 1e18.
         * After that, it divides the result by the total number of seconds in a year and by 100 to adjust for the percentage.
         *
         * Using 1e18 maintains precision in the calculation, avoiding truncation errors due to integer division in Solidity.
         * By scaling up the result and performing the divisions afterward, the calculation maintains precision without truncating intermediate results to zero.
         */
        uint256 rewardPerSecond = (depositedAmount * tokenApr * 1e18) / (365 * 24 * 3600 * 100);
        
        // Calculate the base reward based on elapsed time
        uint256 _reward = elapsedTime * rewardPerSecond / 1e18;

        // Calculate the boost percentage
        uint256 boostPercentage = calculateBoostPercentage(_staker, _depositId);

        // Calculate the final reward by applying the boost percentage
        _reward = (_reward * boostPercentage) / divisorERC20[deposit_.token];

        // Return the calculated reward
        return _reward;
    }      

    // Internal functions:

    /**
     * @dev This internal function calculates the compounded rewards for a given deposited amount and number of elapsed periods.
     *      The function assumes a fixed 25% APR and 8760 periods per year (hourly compounding). It uses exponentiation to calculate
     *      the compounded rewards using the formula A = P * (1 + r/n)^(nt), where:
     *          A: final amount after compounding
     *          P: initial deposited amount
     *          r: annual interest rate (25%)
     *          n: number of periods in a year (8760)
     *          t: number of elapsed periods
     * @param _depositedAmount The initial deposited amount.
     * @param _periodsElapsed The number of elapsed periods (hours) since the deposit.
     * @return compound The calculated compounded rewards for the given deposited amount and elapsed periods.
     */
    function _calculateCompound(uint256 _depositedAmount, uint256 _periodsElapsed) internal pure returns (uint256 compound) {
        uint256 periodsInYear = 8760; // 24 hours * 365 days
        uint256 compoundFactor = 1 + (25 * 1e1 / periodsInYear);

        //Calculate compounded rewards using exponentiation (A = P * (1 + r/n)^(nt))
        compound = _depositedAmount * (compoundFactor ** _periodsElapsed) / (1e1 ** _periodsElapsed);

        return compound;        
    }
        
        
    // Functions for modifying  staking mechanism variables:
    /**
     * @dev This internal function is used to update the total rewarded amount and the total rewarded amount
     *      for a specific user and token. It is called when rewards are distributed or staked.
     * @param _amount The amount of tokens to add to the total rewarded and user's total rewarded.
     * @param _token The address of the token contract.
     * @param _user The address of the user receiving the rewards.
     */
    function _addTotalRewardedAmount(uint256 _amount, address _token, address _user) internal {
        totalRewarded[_token] += _amount;
        userTotalRewardedByCoin[_token][_user] += _amount;
    }


    /**
     * @dev This internal function adds the given amount to the total staked amount for a specified token
     *      and increases the staked amount for the user by the same amount.
     * @param _amount The amount to add to the total staked amount and user's staked amount.
     * @param _token The address of the token for which to update the staked amount.
     * @param _user The address of the user whose staked amount should be increased.
     */
    function _addTotalStakedAmount(uint256 _amount, address _token, address _user) internal {
        totalStaked[_token] += _amount;
        userTotalStakedByCoin[_token][_user] += _amount;
    }

    /**
     * @dev This internal function subtracts the given amount from the total staked amount for a specified token
     *      and decreases the staked amount for the user by the same amount.
     * @param _amount The amount to subtract from the total staked amount and user's staked amount.
     * @param _token The address of the token for which to update the staked amount.
     * @param _user The address of the user whose staked amount should be decreased.
     */
    function _subtractStakedAmount(uint256 _amount,  address _token, address _user) internal {
        // do a underflow check
        require(totalStaked[_token] >= _amount, "Staking: Not enough staked (Contract)");
        require(userTotalStakedByCoin[_token][_user] >= _amount, "Staking: Not enough staked (User)");
        totalStaked[_token] -= _amount;
        userTotalStakedByCoin[_token][_user] -= _amount;
    }

    /**
     * @dev This internal function adds the given amount to the total withdrawal fees for a specified token.
     * @param _amount The amount to add to the total withdrawal fees.
     * @param _token The address of the token for which to update the withdrawal fees.
     */
    function _addTotalWithdrawalFees(uint256 _amount, address _token) internal {
        totalWithdrawalFees[_token] += _amount;
    }
    
    /**
     * @dev This function sets the APR for a specified token.
     * @param _apr The rewards per hour value to be set, as x% APR. (e.g. 25 = 25%)
     * @param _tokenId The address of the token for which to set the rewards per hour.
     */
    function setAPR(uint256 _apr, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        aprERC20[_tokenId] = _apr; 
        emit NewAPR(_apr, _tokenId);
    }

    /**
     * @dev This function sets the minimum staking amount for a specified token.
     * @param _minStake The minimum staking amount to be set, in wei.
     * @param _tokenId The address of the token for which to set the minimum staking amount.
     */
    function setMinStake(uint256 _minStake, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        minStakeERC20[_tokenId] = _minStake;
        emit NewMinStake(_minStake, _tokenId);
    }

    /**
     * @dev This function sets the ratio for a specified ERC20 token.
     * @param _ratio The ratio value to be set.
     * @param _tokenId The address of the token for which to set the ratio.
     */
    function setRatio(uint256 _ratio, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        ratioERC20[_tokenId] = _ratio;
        emit NewRatio(_ratio, _tokenId);
    }

    /**
     * @dev This function sets the address of the Helix ERC20 contract.
     * @param _helix The address of the Helix ERC20 contract.
     */
    function setHelixERC20(address _helix) public onlyGovernor {
        require(_helix != address(0), "Helix address cannot be 0x0");
        helixERC20 = IHelix(_helix);
        emit NewHelixERC20(_helix);
    }

    /**
     * @dev This function sets the address of the konduxERC721Founders contract.
     * @param _konduxERC721Founders The address of the konduxERC721Founders contract.
     */
    function setKonduxERC721Founders(address _konduxERC721Founders) public onlyGovernor {
        require(_konduxERC721Founders != address(0), "Founders address cannot be 0x0");
        konduxERC721Founders = IERC721(_konduxERC721Founders);
        emit NewKonduxERC721Founders(_konduxERC721Founders);
    }

    /**
     * @dev This function sets the address of the konduxERC721kNFT contract.
     * @param _konduxERC721kNFT The address of the konduxERC721kNFT contract.
     */
    function setKonduxERC721kNFT(address _konduxERC721kNFT) public onlyGovernor {
        require(_konduxERC721kNFT != address(0), "kNFT address cannot be 0x0");
        konduxERC721kNFT = _konduxERC721kNFT;
        emit NewKonduxERC721kNFT(_konduxERC721kNFT);
    }

    /**
     * @dev This function sets the address of the Treasury contract.
     * @param _treasury The address of the Treasury contract.
     */
    function setTreasury(address _treasury) public onlyGovernor {
        require(_treasury != address(0), "Treasury address cannot be 0x0");
        treasury = ITreasury(_treasury);
        emit NewTreasury(_treasury);
    }

    /**
     * @dev This function sets the withdrawal fee for a specified token.
     * @param _withdrawalFee The withdrawal fee value to be set.
     * @param _tokenId The address of the token for which to set the withdrawal fee.
     */
    function setWithdrawalFee(uint256 _withdrawalFee, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        require(_withdrawalFee <= divisorERC20[_tokenId], "Withdrawal fee cannot be more than 100%");
        withdrawalFeeERC20[_tokenId] = _withdrawalFee;
        emit NewWithdrawalFee(_withdrawalFee, _tokenId); 
    }

    /**
     * @dev This function sets the founders reward boost for a specified token.
     * @param _foundersRewardBoost The founders reward boost value to be set.
     * @param _tokenId The address of the token for which to set the founders reward boost.
     */
    function setFoundersRewardBoost(uint256 _foundersRewardBoost, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        foundersRewardBoostERC20[_tokenId] = _foundersRewardBoost;
        emit NewFoundersRewardBoost(_foundersRewardBoost, _tokenId);
    }

    /**
     * @dev This function sets the kNFT reward boost for a specified token.
     * @param _kNFTRewardBoost The kNFT reward boost value to be set.
     * @param _tokenId The address of the token for which to set the kNFT reward boost.
     */
    function setkNFTRewardBoost(uint256 _kNFTRewardBoost, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        kNFTRewardBoostERC20[_tokenId] = _kNFTRewardBoost;
        emit NewKNFTRewardBoost(_kNFTRewardBoost, _tokenId); 
    }

    /**
    * @dev This function sets the compound frequency for a specified token.
    * @param _compoundFreq The compound frequency value to be set.
    * @param _tokenId The address of the token for which to set the compound frequency.
    */
    function setCompoundFreq(uint256 _compoundFreq, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        compoundFreqERC20[_tokenId] = _compoundFreq;
        emit NewCompoundFreq(_compoundFreq, _tokenId);
    }

    /**
     * @dev This function sets the penalty percentage for early withdrawal of a specified token.
     * @param _token The address of the token for which to set the penalty percentage.
     * @param penaltyPercentage The penalty percentage value to be set. Must be between 0 and 100. 
     */
    function setEarlyWithdrawalPenalty(address _token, uint256 penaltyPercentage) public onlyGovernor {
        // Check if the token address is set
        require(_token != address(0), "Token address is not set"); 
        require(penaltyPercentage <= 100, "Penalty percentage must be between 0 and 100");
        earlyWithdrawalPenalty[_token] = penaltyPercentage;
    }  

    /**
     * @dev This function sets the timelock category boost for a specified category.
     * @param _category The category for which to set the boost.
     * @param _boost The boost value to be set.
     */
    function setTimelockCategoryBoost(uint _category, uint256 _boost) public onlyGovernor {
        timelockCategoryBoost[_category] = _boost;
    }

    /**
     * @dev This function sets the divisor for a specified token.
     * @param _divisor The divisor value to be set.
     * @param _tokenId The address of the token for which to set the divisor.
     */
    function setDivisorERC20(uint256 _divisor, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        divisorERC20[_tokenId] = _divisor;
        emit NewDivisorERC20(_divisor, _tokenId);
    }

    /**
     * @dev This internal function sets whether an ERC20 token is authorized as a staking currency.
     * Emits a {NewAuthorizedERC20} event.
     * @param _token The address of the token to be authorized or deauthorized.
     * @param _authorized True to authorize the token, false to deauthorize.
     */
    function _setAuthorizedERC20(address _token, bool _authorized) internal {
        require(_token != address(0), "Token address cannot be 0x0");
        if (_authorized == true) {
            require(aprERC20[_token] > 0, "Rewards per hour must be greater than 0");
            require(compoundFreqERC20[_token] > 0, "Compound frequency must be greater than 0");
            require(withdrawalFeeERC20[_token] > 0, "Withdrawal fee must be greater than 0");
            require(foundersRewardBoostERC20[_token] > 0, "Founders reward boost must be greater than 0");
            require(kNFTRewardBoostERC20[_token] > 0, "kNFT reward boost must be greater than 0");
            require(ratioERC20[_token] > 0, "Ratio must be greater than 0");
            require(minStakeERC20[_token] > 0, "Minimum stake must be greater than 0");
            require(divisorERC20[_token] > 0, "Divisor must be greater than 0");
            require(IERC20(_token).totalSupply() > 0, "Token total supply must be greater than 0");
        }
        authorizedERC20[_token] = _authorized;
        emit NewAuthorizedERC20(_token, _authorized);
    }

    /**
     * @dev This function sets whether an ERC20 token is authorized as a staking currency.
     * Emits a {NewAuthorizedERC20} event.
     * @param _token The address of the token to be authorized or deauthorized.
     * @param _authorized True to authorize the token, false to deauthorize.
     */
    function setAuthorizedERC20(address _token, bool _authorized) public onlyGovernor {
        // Check if the token address is set
        require(_token != address(0), "Token address is not set"); 
        _setAuthorizedERC20(_token, _authorized);
    }

    /**
     * @dev This function sets the version of dna that is allowed to be used for reward bonus
     * @param _dnaVersion The dna version to be set.
     * @param _allowed True to allow the dna version, false to disallow.
     */
    function setAllowedDnaVersion(uint256 _dnaVersion, bool _allowed) public onlyGovernor {
        allowedDnaVersions[_dnaVersion] = _allowed;
    }

    /**
     * @dev This function sets the decimals of a specified token.
     * @param _decimals The decimals value to be set.
     * @param _tokenId The address of the token for which to set the decimals.
     */
    function setDecimalsERC20(uint8 _decimals, address _tokenId) public onlyGovernor {
        // Check if the token address is set
        require(_tokenId != address(0), "Token address is not set"); 
        decimalsERC20[_tokenId] = _decimals;
    }

    /**
     * @dev This function adds a new staking token with its parameters.
     * Emits various events based on the setter functions called during token addition.
     * Emits a {NewAuthorizedERC20} event at the end.
     * @param _token The address of the new staking token.
     * @param _apr The rewards per hour for the new staking token.
     * @param _compoundFreq The compound frequency for the new staking token.
     * @param _withdrawalFee The withdrawal fee for the new staking token.
     * @param _foundersRewardBoost The founders reward boost for the new staking token.
     * @param _kNFTRewardBoost The kNFT reward boost for the new staking token.
     * @param _ratio The ratio for the new staking token.
     * @param _minStake The minimum stake for the new staking token.
     */ 
    function addNewStakingToken(address _token, uint256 _apr, uint256 _compoundFreq, uint256 _withdrawalFee, uint256 _foundersRewardBoost, uint256 _kNFTRewardBoost, uint256 _ratio, uint256 _minStake) public onlyGovernor {
        require(_token != address(0), "Token address cannot be 0x0");
        require(_apr > 0, "Rewards per hour must be greater than 0"); 
        require(_compoundFreq > 0, "Compound frequency must be greater than 0");
        require(_withdrawalFee > 0, "Withdrawal fee must be greater than 0");
        require(_foundersRewardBoost > 0, "Founders reward boost must be greater than 0");
        require(_kNFTRewardBoost > 0, "kNFT reward boost must be greater than 0");
        require(_ratio > 0, "Ratio must be greater than 0");
        require(_minStake > 0, "Minimum stake must be greater than 0");
        require(IERC20(_token).totalSupply() > 0, "Token total supply must be greater than 0");

        setDivisorERC20(10_000, _token);
        setFoundersRewardBoost(_foundersRewardBoost, _token);
        setkNFTRewardBoost(_kNFTRewardBoost, _token);
        setAPR(_apr, _token); 
        setRatio(_ratio, _token);
        setWithdrawalFee(_withdrawalFee, _token);
        setCompoundFreq(_compoundFreq, _token);
        setMinStake(_minStake, _token);
        setDecimalsERC20(IERC20Metadata(_token).decimals(), _token);

        _setAuthorizedERC20(_token, true); 
    }


    // Functions for getting staking mechanism variables:

    /**
     * @dev This function returns the time of the last update for the specified deposit ID.
     * @param _depositId The ID of the deposit for which the time of the last update is requested.
     * @return _timeOfLastUpdate The time of the last update for the specified deposit ID.
     */
    function getTimeOfLastUpdate(uint _depositId) public view returns (uint256 _timeOfLastUpdate) {
        return userDeposits[_depositId].timeOfLastUpdate;
    }

    /**
     * @dev This function returns the staked amount for the specified deposit ID.
     * @param _depositId The ID of the deposit for which the staked amount is requested.
     * @return _deposited The staked amount for the specified deposit ID.
     */
    function getStakedAmount(uint _depositId) public view returns (uint256 _deposited) {
        return userDeposits[_depositId].deposited;
    }

    /**
     * @dev This function returns the APR for the specified token.
     * @param _tokenId The address of the token for which the rewards per hour are requested.
     * @return _rewardsPerHour The rewards per hour for the specified token.
     */
    function getAPR(address _tokenId) public view returns (uint256 _rewardsPerHour) {
        return aprERC20[_tokenId];
    }

    /**
     * @dev This function returns the Founder's reward boost for the specified token.
     * @param _tokenId The address of the token for which the Founder's reward boost is requested.
     * @return _foundersRewardBoost The Founder's reward boost for the specified token.
     */
    function getFoundersRewardBoost(address _tokenId) public view returns (uint256 _foundersRewardBoost) {
        return foundersRewardBoostERC20[_tokenId];
    }

    /**
     * @dev This function returns the kNFT reward boost for the specified token.
     * @param _tokenId The address of the token for which the kNFT reward boost is requested.
     * @return _kNFTRewardBoost The kNFT reward boost for the specified token.
     */
    function getkNFTRewardBoost(address _tokenId) public view returns (uint256 _kNFTRewardBoost) {
        return kNFTRewardBoostERC20[_tokenId];
    }

    /**
     * @dev This function returns the minimum stake for the specified token.
     * @param _tokenId The address of the token for which the minimum stake is requested.
     * @return _minStake The minimum stake for the specified token.
     */
    function getMinStake(address _tokenId) public view returns (uint256 _minStake) {
        return minStakeERC20[_tokenId];
    }

    /**
     * @dev This function returns the timelock category for the specified deposit ID.
     * @param _depositId The ID of the deposit for which the timelock category is requested.
     * @return _timelockCategory The timelock category for the specified deposit ID.
     */
    function getTimelockCategory(uint _depositId) public view returns (uint8 _timelockCategory) {
        return userDeposits[_depositId].timelockCategory;
    }

    /**
     * @dev This function returns the timelock for the specified deposit ID.
     * @param _depositId The ID of the deposit for which the timelock is requested.
     * @return _timelock The timelock for the specified deposit ID.
     */
    function getTimelock(uint _depositId) public view returns (uint256 _timelock) {
        return userDeposits[_depositId].timelock;
    }

    /**
     * @dev This function returns the deposit IDs for the specified user.
     * @param _user The address of the user for which the deposit IDs are requested.
     * @return An array of deposit IDs for the specified user.
     */
    function getDepositIds(address _user) public view returns (uint256[] memory) {
        return userDepositsIds[_user];
    }

    /**
     * @dev This function returns the withdrawal fee for the specified token.
     * @param _tokenId The address of the token for which the withdrawal fee is requested.
     * @return _withdrawalFee The withdrawal fee for the specified token.
     */
    function getWithdrawalFee(address _tokenId) public view returns (uint256 _withdrawalFee) {
        return withdrawalFeeERC20[_tokenId]; 
    }

    /**
     * @dev This function returns the total amount staked for a specific token.
     * @param _token The address of the token contract.
     * @return _totalStaked The total amount staked for the given token.
     */
    function getTotalStaked(address _token) public view returns (uint256 _totalStaked) {
        return totalStaked[_token];
    }

    /**
     * @dev This function returns the total amount staked by a specific user for a specific token.
     * @param _user The address of the user.
     * @param _token The address of the token contract.
     * @return _totalStaked The total amount staked by the user for the given token.
     */
    function getUserTotalStakedByCoin(address _user, address _token) public view returns (uint256 _totalStaked) {
        return userTotalStakedByCoin[_token][_user];
    }

    /**
     * @dev This function returns the total rewards earned for a specific token.
     * @param _token The address of the token contract.
     * @return _totalRewards The total rewards earned for the given token.
     */
    function getTotalRewards(address _token) public view returns (uint256 _totalRewards) {
        return totalRewarded[_token];
    }

    /**
     * @dev This function returns the total rewards earned by a specific user for a specific token.
     * @param _user The address of the user.
     * @param _token The address of the token contract.
     * @return _totalRewards The total rewards earned by the user for the given token.
     */
    function getUserTotalRewardsByCoin(address _user, address _token) public view returns (uint256 _totalRewards) {
        return userTotalRewardedByCoin[_token][_user]; 
    }

    /**
     * @dev This function returns the total withdrawal fees for a specific token.
     * @param _token The address of the token contract.
     * @return _totalWithdrawalFees The total withdrawal fees for the given token.
     */
    function getTotalWithdrawalFees(address _token) public view returns (uint256 _totalWithdrawalFees) {
        return totalWithdrawalFees[_token];
    }

    /**
     * @dev This function returns the timestamp of the deposit with the specified ID.
     * @param _depositId The id of the deposit for which the timestamp is requested.
     * @return _depositTimestamp The timestamp of the deposit
     */
    function getDepositTimestamp(uint _depositId) public view returns (uint256 _depositTimestamp) {
        return userDeposits[_depositId].lastDepositTime; 
    }

    /**
     * @dev This function returns the penalty for early withdrawal for the specified token in basis points. (X% = X * 100)
     * @param token The address of the token for which the penalty is requested.
     * @return The penalty for early withdrawal for the specified token in basis points.
     */
    function getEarlyWithdrawalPenalty(address token) public view returns (uint256) {
        return earlyWithdrawalPenalty[token];
    }

    /**
     * @dev This function returns the timelock category boost for the specified category.
     * @param _category The category for which the timelock category boost is requested.
     * @return The timelock category boost for the specified category.
     */
    function getTimelockCategoryBoost(uint _category) public view returns (uint256) {
        return timelockCategoryBoost[_category];
    }

    /**
     * @dev This function returns the divisor for the specified token.
     * @param _token The address of the token for which the divisor is requested.
     * @return The divisor for the specified token.
     */
    function getDivisorERC20(address _token) public view returns (uint256) {
        return divisorERC20[_token];
    }

    /**
     * @dev This function returns the permission of usage of a dna version as boost.
     * @param _dnaVersion The dna version for which the permission is requested.
     * @return The permission of usage of a dna version as boost
     */
    function getAllowedDnaVersion(uint256 _dnaVersion) public view returns (bool) {
        return allowedDnaVersions[_dnaVersion];
    }

    /**
     * @dev This function retrieves the deposit information for a given deposit ID. It returns the staked amount
     *      and the earned rewards (including unclaimed rewards) for the specified deposit.
     * @param _depositId The ID of the deposit for which to retrieve the information.
     * @return _stake The staked amount for the specified deposit.
     * @return _unclaimedRewards The earned rewards (including unclaimed rewards) for the specified deposit.
     */
    function getDepositInfo(uint _depositId) public view returns (uint256 _stake, uint256 _unclaimedRewards) {
        _stake = userDeposits[_depositId].deposited;  
        _unclaimedRewards = calculateRewards(msg.sender, _depositId) + userDeposits[_depositId].unclaimedRewards;
        return (_stake, _unclaimedRewards);  
    }

    /**
     * @dev This function returns the decimals for the specified token.
     * @param _token The address of the token for which the decimals are requested.
     * @return The decimals for the specified token.
     */
    function getDecimalsERC20(address _token) public view returns (uint8) {
        return decimalsERC20[_token];
    }

    /**
     * @dev This function returns the ratio for the specified token.
     * @param _token The address of the token for which the ratio is requested.
     * @return The ratio for the specified token.
     */
    function getRatioERC20(address _token) public view returns (uint256) {
        return ratioERC20[_token];
    }

    /**
     * @dev This function returns the ratio for the specified deposit.
     * @param _depositId The ID of the deposit for which to retrieve the information.
     * @return The ratio for the specified deposit.
     */
    function getDepositRatioERC20(uint256 _depositId) public view returns (uint256) {
        return userDeposits[_depositId].ratioERC20;
    }   

    /**
     * @dev This function returns the top 5 bonuses and their corresponding kNFT IDs.
     * @param _staker The address of the staker.
     * @param _stakeId The ID of the deposit for which to calculate the boost percentage.
     * @return top5Bonuses An array of the top 5 bonuses.
     * @return top5Ids An array of the corresponding kNFT IDs.
     */
    function getTop5BonusesAndIds(address _staker, uint256 _stakeId) public view returns (uint256[] memory top5Bonuses, uint256[] memory top5Ids) {
        uint256 kNFTBalance = IERC721(konduxERC721kNFT).balanceOf(_staker);

        // Initialize arrays to store the top 5 bonuses and their corresponding kNFT IDs
        top5Bonuses = new uint256[](5);
        top5Ids = new uint256[](5);

        // Iterate through the staker's kNFTs
        for (uint256 i = 0; i < kNFTBalance; i++) {
            uint256 tokenId = IERC721Enumerable(konduxERC721kNFT).tokenOfOwnerByIndex(_staker, i);

            // if the user's kNFT was received after the deposit date, continue
            if (IKondux(konduxERC721kNFT).getTransferDate(tokenId) > userDeposits[_stakeId].lastDepositTime) {
                continue;
            }

            // Get the kNFT's DNA version and check if it's allowed
            int256 dnaVersion = IKondux(konduxERC721kNFT).readGen(tokenId, 0, 1);
            if (!allowedDnaVersions[uint256(dnaVersion)]) { 
                continue;
            }

            // Get the kNFT's boost value and multiply it by 100 to get a percentage
            int256 dnaBoost = IKondux(konduxERC721kNFT).readGen(tokenId, 1, 2) * 100;

            // Clamp the boost value to 0 if it's negative
            if (dnaBoost < 0) {
                dnaBoost = 0;
            }

            // Update the top 5 bonuses array with the current kNFT boost
            for (uint256 j = 0; j < 5; j++) {
                if (uint256(dnaBoost) > top5Bonuses[j]) {
                    uint256 temp = top5Bonuses[j];
                    top5Bonuses[j] = uint256(dnaBoost);
                    dnaBoost = int256(temp);

                    uint256 tempId = top5Ids[j];
                    top5Ids[j] = tokenId;
                    tokenId = tempId;
                }
            }
        }

        return (top5Bonuses, top5Ids);
    }

    /**
     * @dev This function returns the top 5 bonuses and their corresponding kNFT IDs.
     * @param _staker The address of the staker.
     * @return top5Bonuses An array of the top 5 bonuses.
     * @return top5Ids An array of the corresponding kNFT IDs.
     */
    function getMaxTop5BonusesAndIds(address _staker) public view returns (uint256[] memory top5Bonuses, uint256[] memory top5Ids) {
        uint256 kNFTBalance = IERC721(konduxERC721kNFT).balanceOf(_staker);

        // Initialize arrays to store the top 5 bonuses and their corresponding kNFT IDs
        top5Bonuses = new uint256[](5);
        top5Ids = new uint256[](5);

        // Iterate through the staker's kNFTs
        for (uint256 i = 0; i < kNFTBalance; i++) {
            uint256 tokenId = IERC721Enumerable(konduxERC721kNFT).tokenOfOwnerByIndex(_staker, i);

            // Get the kNFT's DNA version and check if it's allowed
            int256 dnaVersion = IKondux(konduxERC721kNFT).readGen(tokenId, 0, 1);
            if (!allowedDnaVersions[uint256(dnaVersion)]) { 
                continue;
            }

            // Get the kNFT's boost value and multiply it by 100 to get a percentage
            int256 dnaBoost = IKondux(konduxERC721kNFT).readGen(tokenId, 1, 2) * 100;

            // Clamp the boost value to 0 if it's negative
            if (dnaBoost < 0) {
                dnaBoost = 0;
            }

            // Update the top 5 bonuses array with the current kNFT boost
            for (uint256 j = 0; j < 5; j++) {
                if (uint256(dnaBoost) > top5Bonuses[j]) {
                    uint256 temp = top5Bonuses[j];
                    top5Bonuses[j] = uint256(dnaBoost);
                    dnaBoost = int256(temp);

                    uint256 tempId = top5Ids[j];
                    top5Ids[j] = tokenId;
                    tokenId = tempId;
                }
            }
        }

        return (top5Bonuses, top5Ids);
    }

    /**
     * @dev This function calculates the boost percentage for a staker's deposit.
     * @param _staker The address of the staker.
     * @param _stakeId The ID of the deposit for which to calculate the boost percentage.
     * @return boostPercentage The boost percentage for the staker's deposit.
     */
    function calculateKNFTBoostPercentage(address _staker, uint256 _stakeId) public view returns (uint256 boostPercentage) {
        // Get the top 5 bonuses and their corresponding kNFT IDs
        (uint256[] memory top5Bonuses, ) = getTop5BonusesAndIds(_staker, _stakeId);

        // Add the top 5 bonuses to the boost percentage
        for (uint256 i = 0; i < 5; i++) {
            boostPercentage += top5Bonuses[i];
        }

        return boostPercentage;
    }

    /**
     * @dev This function calculates the boost percentage for a staker.
     * @param _staker The address of the staker.
     * @return boostPercentage The boost percentage for the staker's deposit.
     */
    function calculateMaxKNFTBoostPercentage(address _staker) public view returns (uint256 boostPercentage) {
        // Get the top 5 bonuses and their corresponding kNFT IDs
        (uint256[] memory top5Bonuses, ) = getMaxTop5BonusesAndIds(_staker);

        // Add the top 5 bonuses to the boost percentage
        for (uint256 i = 0; i < 5; i++) {
            boostPercentage += top5Bonuses[i];
        }

        return boostPercentage;
    }

    /**
     * @dev This function calculates the boost percentage for a specified staker and deposit ID.
     * @param _staker The address of the staker for which to calculate the boost.
     * @param _stakeId The ID of the stake for which to calculate the boost.
     * @return boostPercentage The calculated boost percentage for the specified staker and deposit ID.
     */
    function calculateBoostPercentage(address _staker, uint _stakeId) public view returns (uint256 boostPercentage) {
        // Retrieve deposit details by _depositId
        Staker memory deposit_ = userDeposits[_stakeId];

        // Initialize the boost percentage with the base boost percentage for the token
        boostPercentage = divisorERC20[deposit_.token];

        // Check if the staker has Founder's NFTs and add the boost percentage
        if (IERC721(konduxERC721Founders).balanceOf(_staker) > 0) {
            boostPercentage += foundersRewardBoostERC20[deposit_.token];
        }

        // Check if the staker has any kNFTs and calculate the top 5 boosts
        if (IERC721(konduxERC721kNFT).balanceOf(_staker) > 0) {
            boostPercentage += calculateKNFTBoostPercentage(_staker, _stakeId); 
        }

        // If the deposit has a timelock category, add the corresponding boost
        if (deposit_.timelockCategory > 0) {
            boostPercentage += timelockCategoryBoost[deposit_.timelockCategory];
        }

        return boostPercentage;
    }

    /**
     * @dev A function that agreggates the returned values of getTimelock, getDepositTimestamp, getTimelockCategory, getDepositInfo and calculateKNFTBoostPercentage
     * @param _staker The address of the staker for which to calculate the boost.
     * @param _stakeId The ID of the stake for which to calculate the boost.
     * @return _timelock The timelock for the specified deposit ID.
     * @return _depositTimestamp The timestamp of the deposit
     * @return _timelockCategory The timelock category for the specified deposit ID.
     * @return _stake The staked amount for the specified deposit.
     * @return _unclaimedRewards The earned rewards (including unclaimed rewards) for the specified deposit.
     * @return _boostPercentage The calculated boost percentage for the specified staker and deposit ID.
     */
    function getDepositDetails(address _staker, uint _stakeId) public view returns (uint256 _timelock, uint256 _depositTimestamp, uint8 _timelockCategory, uint256 _stake, uint256 _unclaimedRewards, uint256 _boostPercentage) {
        _timelock = getTimelock(_stakeId);
        _depositTimestamp = getDepositTimestamp(_stakeId);
        _timelockCategory = getTimelockCategory(_stakeId);
        (_stake, _unclaimedRewards) = getDepositInfo(_stakeId);
        _boostPercentage = calculateBoostPercentage(_staker, _stakeId);
    }
 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.9;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event RolePushed(address indexed account, bytes32 _role);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);

    function roles(address _addr) external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IHelix is IERC20, IERC20Metadata {
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function burn(address _to, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external; 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IKondux {
    function changeDenominator(uint96 _denominator) external returns (uint96);
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external;
    function setBaseURI(string memory _newURI) external returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function pause() external;
    function unpause() external;
    function safeMint(address to, uint256 dna) external returns (uint256);
    function setDna(uint256 _tokenID, uint256 _dna) external;
    function getDna(uint256 _tokenID) external view returns (uint256);
    function readGen(uint256 _tokenID, uint8 startIndex, uint8 endIndex) external view returns (int256);
    function writeGen(uint256 _tokenID, uint256 inputValue, uint8 startIndex, uint8 endIndex) external;
    function getTransferDate(uint256 _tokenID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IKonduxERC20 is IERC20 {
    function excludedFromFees(address) external view returns (bool);
    function tradingOpen() external view returns (bool);
    function taxSwapMin() external view returns (uint256);
    function taxSwapMax() external view returns (uint256);
    function _isLiqPool(address) external view returns (bool);
    function taxRateBuy() external view returns (uint8);
    function taxRateSell() external view returns (uint8);
    function antiBotEnabled() external view returns (bool);
    function excludedFromAntiBot(address) external view returns (bool);
    function _lastSwapBlock(address) external view returns (uint256);
    function taxWallet() external view returns (address);

    event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);
    event TokensBurned(address indexed burnedByWallet, uint256 tokenAmount);
    event TaxWalletChanged(address newTaxWallet);
    event TaxRateChanged(uint8 newBuyTax, uint8 newSellTax);

    function initLP() external;
    function enableTrading() external;
    function burnTokens(uint256 amount) external;
    function enableAntiBot(bool isEnabled) external;
    function excludeFromAntiBot(address wallet, bool isExcluded) external;
    function excludeFromFees(address wallet, bool isExcluded) external;
    function adjustTaxRate(uint8 newBuyTax, uint8 newSellTax) external;
    function setTaxWallet(address newTaxWallet) external;
    function taxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external;

    function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token
    ) external;

    function depositEther() external payable;

    function withdraw(
        uint256 _amount,
        address _token
    ) external;

    function withdrawTo(
        uint256 _amount,
        address _token,
        address _to
    ) external;

    function withdrawEther(
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IAuthority.sol";

/// @dev Reasoning for this contract = modifiers literaly copy code
/// instead of pointing towards the logic to execute. Over many
/// functions this bloats contract size unnecessarily.
/// imho modifiers are a meme.
abstract contract AccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IAuthority authority);

    /* ========== STATE VARIABLES ========== */

    IAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IAuthority _authority) {
        require(address(_authority) != address(0), "Authority cannot be zero address");
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor {
        _onlyGovernor();
        _;
    }

    modifier onlyGuardian {
        _onlyGuardian();
        _;
    }

    modifier onlyPolicy {
        _onlyPolicy();
        _;
    }

    modifier onlyVault {
        _onlyVault();
        _;
    }

    modifier onlyGlobalRole(bytes32 _role){
        _onlyRole(_role);
        _;
    }

    /* ========== GOV ONLY ========== */

    function initializeAuthority(IAuthority _newAuthority) internal {
        require(authority == IAuthority(address(0)), "AUTHORITY_INITIALIZED");
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    function setAuthority(IAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        require(msg.sender == authority.governor(), "UNAUTHORIZED");
    }

    function _onlyGuardian() internal view {
        require(msg.sender == authority.guardian(), "UNAUTHORIZED");
    }

    function _onlyPolicy() internal view {
        require(msg.sender == authority.policy(), "UNAUTHORIZED");        
    }

    function _onlyVault() internal view {
        require(msg.sender == authority.vault(), "UNAUTHORIZED");                
    }

    function _onlyRole(bytes32 _role) internal view {
        require(authority.roles(msg.sender) == _role, "UNAUTHORIZED");
    }
  
}