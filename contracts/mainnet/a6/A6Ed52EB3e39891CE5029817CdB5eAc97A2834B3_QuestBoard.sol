//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
 

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./utils/Owner.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./MultiMerkleDistributor.sol";
import "./interfaces/IGaugeController.sol";
import "./utils/Errors.sol";

/** @title Warden Quest Board  */
/// @author Paladin
/*
    Main contract, holding all the Quests data & ressources
    Allowing users to add/update Quests
    And the managers to update Quests to the next period & trigger the rewards for closed periods 
*/

contract QuestBoard is Owner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /** @notice Address of the Curve Gauge Controller */
    address public immutable GAUGE_CONTROLLER;

    /** @notice Seconds in a Week */
    uint256 private constant WEEK = 604800;
    /** @notice 1e18 scale */
    uint256 private constant UNIT = 1e18;
    /** @notice Max BPS value (100%) */
    uint256 private constant MAX_BPS = 10000;


    /** @notice State of each Period for each Quest */
    enum PeriodState { ZERO, ACTIVE, CLOSED, DISTRIBUTED }
    // All Periods are ACTIVE at creation since they voters from past periods are also accounted for the future period


    /** @notice Struct for a Period of a Quest */
    struct QuestPeriod {
        // Total reward amount that can be distributed for that period
        uint256 rewardAmountPerPeriod;
        // Amount of reward for each vote (for 1 veCRV)
        uint256 rewardPerVote;
        // Tartget Bias for the Gauge
        uint256 objectiveVotes;
        // Amount of reward to distribute, at period closing
        uint256 rewardAmountDistributed;
        // Amount not distributed, for Quest creator to redeem
        uint256 withdrawableAmount;
        // Timestamp of the Period start
        uint48 periodStart;
        // Current state of the Period
        PeriodState currentState;
    }

    /** @notice Struct holding the parameters of the Quest common for all periods */
    struct Quest {
        // Address of the Quest creator (caller of createQuest() method)
        address creator;
        // Address of the ERC20 used for rewards
        address rewardToken;
        // Address of the target Gauge
        address gauge;
        // Total number of periods for the Quest
        uint48 duration;
        // Timestamp where the 1st QuestPeriod starts
        uint48 periodStart;
        // Total amount of rewards paid for this Quest
        // If changes were made to the parameters of this Quest, this will account
        // any added reward amounts
        uint256 totalRewardAmount;
    }

    /** @notice ID for the next Quest to be created */
    uint256 public nextID;

    /** @notice List of Quest (indexed by ID) */
    // ID => Quest
    mapping(uint256 => Quest) public quests;
    /** @notice List of timestamp periods the Quest is active in */
    // QuestID => Periods (timestamps)
    mapping(uint256 => uint48[]) public questPeriods;
    /** @notice Mapping of all QuestPeriod struct for each period of each Quest */
    // QuestID => period => QuestPeriod
    mapping(uint256 => mapping(uint256 => QuestPeriod)) public periodsByQuest;
    /** @notice All the Quests present in this period */
    // period => array of Quest
    mapping(uint256 => uint256[]) public questsByPeriod;
    /** @notice Mapping of Distributors used by each Quest to send rewards */
    // ID => Distributor
    mapping(uint256 => address) public questDistributors;


    /** @notice Platform fees ratio (in BPS) */
    uint256 public platformFee = 500;

    /** @notice Minimum Objective required */
    uint256 public minObjective;

    /** @notice Address of the Chest to receive platform fees */
    address public questChest;
    /** @notice Address of the reward Distributor contract */
    address public distributor;

    /** @notice Mapping of addresses allowed to call manager methods */
    mapping(address => bool) approvedManagers;
    /** @notice Whitelisted tokens that can be used as reward tokens */
    mapping(address => bool) public whitelistedTokens;
    /** @notice Min rewardPerVote per token (to avoid spam creation of useless Quest) */
    mapping(address => uint256) public minRewardPerVotePerToken;

    /** @notice Boolean, true if the cotnract was killed, stopping main user functions */
    bool public isKilled;
    /** @notice Timestam pwhen the contract was killed */
    uint256 public kill_ts;
    /** @notice Delay where contract can be unkilled */
    uint256 public constant KILL_DELAY = 2 * 604800; //2 weeks

    // Events

    /** @notice Event emitted when a new Quest is created */
    event NewQuest(
        uint256 indexed questID,
        address indexed creator,
        address indexed gauge,
        address rewardToken,
        uint48 duration,
        uint256 startPeriod,
        uint256 objectiveVotes,
        uint256 rewardPerVote
    );

    /** @notice Event emitted when rewards of a Quest are increased */
    event IncreasedQuestReward(uint256 indexed questID, uint256 indexed updatePeriod, uint256 newRewardPerVote, uint256 addedRewardAmount);
    /** @notice Event emitted when the Quest objective bias is increased */
    event IncreasedQuestObjective(uint256 indexed questID, uint256 indexed updatePeriod, uint256 newObjective, uint256 addedRewardAmount);
    /** @notice Event emitted when the Quest duration is extended */
    event IncreasedQuestDuration(uint256 indexed questID, uint256 addedDuration, uint256 addedRewardAmount);

    /** @notice Event emitted when Quest creator withdraw undistributed rewards */
    event WithdrawUnusedRewards(uint256 indexed questID, address recipient, uint256 amount);

    /** @notice Event emitted when a Period is Closed */
    event PeriodClosed(uint256 indexed questID, uint256 indexed period);

    /** @notice Event emitted when a new reward token is whitelisted */
    event WhitelistToken(address indexed token, uint256 minRewardPerVote);
    event UpdateRewardToken(address indexed token, uint256 newMinRewardPerVote);

    /** @notice Event emitted when the contract is killed */
    event Killed(uint256 killTime);
    /** @notice Event emitted when the contract is unkilled */
    event Unkilled(uint256 unkillTime);
    /** @notice Event emitted when the Quest creator withdraw all unused funds (if the contract was killed) */
    event EmergencyWithdraw(uint256 indexed questID, address recipient, uint256 amount);

    event InitDistributor(address distributor);
    event ApprovedManager(address indexed manager);
    event RemovedManager(address indexed manager);
    event ChestUpdated(address oldChest, address newChest);
    event DistributorUpdated(address oldDistributor, address newDistributor);
    event PlatformFeeUpdated(uint256 oldfee, uint256 newFee);
    event MinObjectiveUpdated(uint256 oldMinObjective, uint256 newMinObjective);

    // Modifiers

    /** @notice Check the caller is either the admin or an approved manager */
    modifier onlyAllowed(){
        if(!approvedManagers[msg.sender] && msg.sender != owner()) revert Errors.CallerNotAllowed();
        _;
    }

    /** @notice Check that contract was not killed */
    modifier isAlive(){
        if(isKilled) revert Errors.Killed();
        _;
    }


    // Constructor
    constructor(address _gaugeController, address _chest){
        if(_gaugeController == address(0)) revert Errors.ZeroAddress();
        if(_chest == address(0)) revert Errors.ZeroAddress();
        if(_gaugeController == _chest) revert Errors.SameAddress();


        GAUGE_CONTROLLER = _gaugeController;

        questChest = _chest;

        minObjective = 1000 * UNIT;
    }


    // View Functions
   
    /**
    * @notice Returns the current Period for the contract
    * @dev Returns the current Period for the contract
    */
    function getCurrentPeriod() public view returns(uint256) {
        return (block.timestamp / WEEK) * WEEK;
    }
   
    /**
    * @notice Returns the list of all Quest IDs active on a given period
    * @dev Returns the list of all Quest IDs active on a given period
    * @param period Timestamp of the period
    * @return uint256[] : Quest IDs for the period
    */
    function getQuestIdsForPeriod(uint256 period) external view returns(uint256[] memory) {
        period = (period / WEEK) * WEEK;
        return questsByPeriod[period];
    }
   
    /**
    * @notice Returns all periods for a Quest
    * @dev Returns all period timestamps for a Quest ID
    * @param questId ID of the Quest
    * @return uint256[] : List of period timestamps
    */
    function getAllPeriodsForQuestId(uint256 questId) external view returns(uint48[] memory) {
        return questPeriods[questId];
    }
   
    /**
    * @notice Returns all QuestPeriod of a given Quest
    * @dev Returns all QuestPeriod of a given Quest ID
    * @param questId ID of the Quest
    * @return QuestPeriod[] : list of QuestPeriods
    */
    function getAllQuestPeriodsForQuestId(uint256 questId) external view returns(QuestPeriod[] memory) {
        uint256 nbPeriods = questPeriods[questId].length;
        QuestPeriod[] memory periods = new QuestPeriod[](nbPeriods);
        for(uint256 i; i < nbPeriods;){
            periods[i] = periodsByQuest[questId][questPeriods[questId][i]];
            unchecked{ ++i; }
        }
        return periods;
    }
   
    /**
    * @dev Returns the number of periods to come for a given Quest
    * @param questID ID of the Quest
    * @return uint : remaining duration (non active periods)
    */
    function _getRemainingDuration(uint256 questID) internal view returns(uint256) {
        // Since we have the current period, the start period for the Quest, and each period is 1 WEEK
        // We can find the number of remaining periods in the Quest simply by dividing the remaining time between
        // currentPeriod and the last QuestPeriod start by a WEEK.
        // If the current period is the last period of the Quest, we want to return 0
        if(questPeriods[questID].length == 0) revert Errors.EmptyQuest();
        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];
        uint256 currentPeriod = getCurrentPeriod();
        return lastPeriod < currentPeriod ? 0: (lastPeriod - currentPeriod) / WEEK;
    }


    // Functions


    struct CreateVars {
        address creator;
        uint256 rewardPerPeriod;
        uint256 nextPeriod;
    }
   
    /**
    * @notice Creates a new Quest
    * @dev Creates a new Quest struct, and QuestPeriods for the Quest duration
    * @param gauge Address of the Gauge targeted by the Quest
    * @param rewardToken Address of the reward token
    * @param duration Duration (in number of periods) of the Quest
    * @param objective Target bias to reach (equivalent to amount of veCRV in wei to reach)
    * @param rewardPerVote Amount of reward per veCRV (in wei)
    * @param totalRewardAmount Total amount of rewards for the whole Quest (in wei)
    * @param feeAmount Platform fees amount (in wei)
    * @return uint256 : ID of the newly created Quest
    */
    function createQuest(
        address gauge,
        address rewardToken,
        uint48 duration,
        uint256 objective,
        uint256 rewardPerVote,
        uint256 totalRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant returns(uint256) {
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        // Local memory variables
        CreateVars memory vars;
        vars.creator = msg.sender;

        // Check all parameters
        if(gauge == address(0) || rewardToken == address(0)) revert Errors.ZeroAddress();
        if(IGaugeController(GAUGE_CONTROLLER).gauge_types(gauge) < 0) revert Errors.InvalidGauge();
        if(!whitelistedTokens[rewardToken]) revert Errors.TokenNotWhitelisted();
        if(duration == 0) revert Errors.IncorrectDuration();
        if(objective < minObjective) revert Errors.ObjectiveTooLow();
        if(rewardPerVote == 0 || totalRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
        if(rewardPerVote < minRewardPerVotePerToken[rewardToken]) revert Errors.RewardPerVoteTooLow();

        // Verifiy the given amounts of reward token are correct
        vars.rewardPerPeriod = (objective * rewardPerVote) / UNIT;

        if((vars.rewardPerPeriod * duration) != totalRewardAmount) revert Errors.IncorrectTotalRewardAmount();
        if((totalRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(vars.creator, address(this), totalRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(vars.creator, questChest, feeAmount);

        // Quest will start on next period
        vars.nextPeriod = getCurrentPeriod() + WEEK;

        // Get the ID for that new Quest and increment the nextID counter
        uint256 newQuestID = nextID;
        unchecked{ ++nextID; }

        // Fill the Quest struct data
        quests[newQuestID].creator = vars.creator;
        quests[newQuestID].rewardToken = rewardToken;
        quests[newQuestID].gauge = gauge;
        quests[newQuestID].duration = duration;
        quests[newQuestID].totalRewardAmount = totalRewardAmount;
        quests[newQuestID].periodStart = safe48(vars.nextPeriod);

        uint48[] memory _periods = new uint48[](duration);

        //Set the current Distributor as the one to receive the rewards for users for that Quest
        questDistributors[newQuestID] = distributor;

        // Iterate on periods based on Quest duration
        uint256 periodIterator = vars.nextPeriod;
        for(uint256 i; i < duration;){
            // Add the Quest on the list of Quests active on the period
            questsByPeriod[periodIterator].push(newQuestID);

            // And add the period in the list of periods of the Quest
            _periods[i] = safe48(periodIterator);

            periodsByQuest[newQuestID][periodIterator].periodStart = safe48(periodIterator);
            periodsByQuest[newQuestID][periodIterator].objectiveVotes = objective;
            periodsByQuest[newQuestID][periodIterator].rewardPerVote = rewardPerVote;
            periodsByQuest[newQuestID][periodIterator].rewardAmountPerPeriod = vars.rewardPerPeriod;
            periodsByQuest[newQuestID][periodIterator].currentState = PeriodState.ACTIVE;
            // Rest of the struct shoud laready have the correct base data:
            // rewardAmountDistributed => 0
            // withdrawableAmount => 0

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        // Write the array of period timestamp of that Quest in storage
        questPeriods[newQuestID] = _periods;

        // Add that Quest & the reward token in the Distributor
        if(!MultiMerkleDistributor(distributor).addQuest(newQuestID, rewardToken)) revert Errors.DisitributorFail();

        emit NewQuest(
            newQuestID,
            vars.creator,
            gauge,
            rewardToken,
            duration,
            vars.nextPeriod,
            objective,
            rewardPerVote
        );

        return newQuestID;
    }

   
    /**
    * @notice Increases the duration of a Quest
    * @dev Adds more QuestPeriods and extends the duration of a Quest
    * @param questID ID of the Quest
    * @param addedDuration Number of period to add
    * @param addedRewardAmount Amount of reward to add for the new periods (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function increaseQuestDuration(
        uint256 questID,
        uint48 addedDuration,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
        if(addedDuration == 0) revert Errors.IncorrectAddDuration();

        //We take data from the last period of the Quest to account for any other changes in the Quest parameters
        if(questPeriods[questID].length == 0) revert Errors.EmptyQuest();
        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        if(lastPeriod < getCurrentPeriod()) revert Errors.ExpiredQuest();

        // Check that the given amounts are correct
        uint rewardPerPeriod = periodsByQuest[questID][lastPeriod].rewardAmountPerPeriod;

        if((rewardPerPeriod * addedDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        address rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);

        uint256 periodIterator = ((lastPeriod + WEEK) / WEEK) * WEEK;

        // Update the Quest struct with added reward admounts & added duration
        quests[questID].totalRewardAmount += addedRewardAmount;
        quests[questID].duration += addedDuration;

        uint256 objective = periodsByQuest[questID][lastPeriod].objectiveVotes;
        uint256 rewardPerVote = periodsByQuest[questID][lastPeriod].rewardPerVote;

        // Add QuestPeriods for the new added duration
        for(uint256 i; i < addedDuration;){
            questsByPeriod[periodIterator].push(questID);

            questPeriods[questID].push(safe48(periodIterator));

            periodsByQuest[questID][periodIterator].periodStart = safe48(periodIterator);
            periodsByQuest[questID][periodIterator].objectiveVotes = objective;
            periodsByQuest[questID][periodIterator].rewardPerVote = rewardPerVote;
            periodsByQuest[questID][periodIterator].rewardAmountPerPeriod = rewardPerPeriod;
            periodsByQuest[questID][periodIterator].currentState = PeriodState.ACTIVE;
            // Rest of the struct shoud laready have the correct base data:
            // rewardAmountDistributed => 0
            // redeemableAmount => 0

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit IncreasedQuestDuration(questID, addedDuration, addedRewardAmount);

    }
   
    /**
    * @notice Increases the reward per votes for a Quest
    * @dev Increases the reward per votes for a Quest
    * @param questID ID of the Quest
    * @param newRewardPerVote New amount of reward per veCRV (in wei)
    * @param addedRewardAmount Amount of rewards to add (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function increaseQuestReward(
        uint256 questID,
        uint256 newRewardPerVote,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(newRewardPerVote == 0 || addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
    
        uint256 remainingDuration = _getRemainingDuration(questID); //Also handles the Empty Quest check
        if(remainingDuration == 0) revert Errors.ExpiredQuest();

        // The new reward amount must be higher 
        uint256 currentPeriod = getCurrentPeriod();
        if(newRewardPerVote <= periodsByQuest[questID][currentPeriod].rewardPerVote) revert Errors.LowerRewardPerVote();

        // For all non active QuestPeriods (non Closed, nor the current Active one)
        // Calculates the amount of reward token needed with the new rewardPerVote value
        // by calculating the new amount of reward per period, and the difference with the current amount of reward per period
        // to have the exact amount to add for each non-active period, and the exact total amount to add to the Quest
        // (because we don't want to pay for Periods that are Closed or the current period)
        uint256 newRewardPerPeriod = (periodsByQuest[questID][currentPeriod].objectiveVotes * newRewardPerVote) / UNIT;
        uint256 diffRewardPerPeriod = newRewardPerPeriod - periodsByQuest[questID][currentPeriod].rewardAmountPerPeriod;

        if((diffRewardPerPeriod * remainingDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        address rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);

        uint256 nextPeriod = currentPeriod + WEEK;
        uint256 periodIterator = nextPeriod;

        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        // Update the Quest struct with the added reward amount
        quests[questID].totalRewardAmount += addedRewardAmount;

        // Update all QuestPeriods, starting with the nextPeriod one
        for(uint256 i; i < remainingDuration;){

            if(periodIterator > lastPeriod) break; //Safety check, we never want to write on non-initialized QuestPeriods (that were not initialized)

            // And update each QuestPeriod with the new values
            periodsByQuest[questID][periodIterator].rewardPerVote = newRewardPerVote;
            periodsByQuest[questID][periodIterator].rewardAmountPerPeriod = newRewardPerPeriod;

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit IncreasedQuestReward(questID, nextPeriod, newRewardPerVote, addedRewardAmount);
    }
   
    /**
    * @notice Increases the target bias/veCRV amount to reach on the Gauge
    * @dev CIncreases the target bias/veCRV amount to reach on the Gauge
    * @param questID ID of the Quest
    * @param newObjective New target bias to reach (equivalent to amount of veCRV in wei to reach)
    * @param addedRewardAmount Amount of rewards to add (in wei)
    * @param feeAmount Platform fees amount (in wei)
    */
    function increaseQuestObjective(
        uint256 questID,
        uint256 newObjective,
        uint256 addedRewardAmount,
        uint256 feeAmount
    ) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(addedRewardAmount == 0 || feeAmount == 0) revert Errors.NullAmount();
    
        uint256 remainingDuration = _getRemainingDuration(questID); //Also handles the Empty Quest check
        if(remainingDuration == 0) revert Errors.ExpiredQuest();

        // No need to compare to minObjective : the new value must be higher than current Objective
        // and current objective needs to be >= minObjective
        uint256 currentPeriod = getCurrentPeriod();
        if(newObjective <= periodsByQuest[questID][currentPeriod].objectiveVotes) revert Errors.LowerObjective();

        // For all non active QuestPeriods (non Closed, nor the current Active one)
        // Calculates the amount of reward token needed with the new objective bias
        // by calculating the new amount of reward per period, and the difference with the current amount of reward per period
        // to have the exact amount to add for each non-active period, and the exact total amount to add to the Quest
        // (because we don't want to pay for Periods that are Closed or the current period)
        uint256 newRewardPerPeriod = (newObjective * periodsByQuest[questID][currentPeriod].rewardPerVote) / UNIT;
        uint256 diffRewardPerPeriod = newRewardPerPeriod - periodsByQuest[questID][currentPeriod].rewardAmountPerPeriod;

        if((diffRewardPerPeriod * remainingDuration) != addedRewardAmount) revert Errors.IncorrectAddedRewardAmount();
        if((addedRewardAmount * platformFee)/MAX_BPS != feeAmount) revert Errors.IncorrectFeeAmount();

        address rewardToken = quests[questID].rewardToken;
        // Pull all the rewards in this contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), addedRewardAmount);
        // And transfer the fees from the Quest creator to the Chest contract
        IERC20(rewardToken).safeTransferFrom(msg.sender, questChest, feeAmount);


        uint256 nextPeriod = currentPeriod + WEEK;
        uint256 periodIterator = nextPeriod;

        uint256 lastPeriod = questPeriods[questID][questPeriods[questID].length - 1];

        // Update the Quest struct with the added reward amount
        quests[questID].totalRewardAmount += addedRewardAmount;

        // Update all QuestPeriods, starting with the nextPeriod one
        for(uint256 i; i < remainingDuration;){

            if(periodIterator > lastPeriod) break; //Safety check, we never want to write on non-existing QuestPeriods (that were not initialized)

            // And update each QuestPeriod with the new values
            periodsByQuest[questID][periodIterator].objectiveVotes = newObjective;
            periodsByQuest[questID][periodIterator].rewardAmountPerPeriod = newRewardPerPeriod;

            periodIterator = ((periodIterator + WEEK) / WEEK) * WEEK;

            unchecked{ ++i; }
        }

        emit IncreasedQuestObjective(questID, nextPeriod, newObjective, addedRewardAmount);
    }
   
    /**
    * @notice Withdraw all undistributed rewards from Closed Quest Periods
    * @dev Withdraw all undistributed rewards from Closed Quest Periods
    * @param questID ID of the Quest
    * @param recipient Address to send the reward tokens to
    */
    function withdrawUnusedRewards(uint256 questID, address recipient) external isAlive nonReentrant {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(recipient == address(0)) revert Errors.ZeroAddress();

        // Total amount available to withdraw
        uint256 totalWithdraw;

        uint48[] memory _questPeriods = questPeriods[questID];

        uint256 length = _questPeriods.length;
        for(uint256 i; i < length;){
            QuestPeriod storage _questPeriod = periodsByQuest[questID][_questPeriods[i]];

            // We allow to withdraw unused rewards after the period was closed, or after it was distributed
            if(_questPeriod.currentState == PeriodState.ACTIVE) {
                unchecked{ ++i; }
                continue;
            }

            uint256 withdrawableForPeriod = _questPeriod.withdrawableAmount;

            // If there is token to withdraw for that period, add they to the total to withdraw,
            // and set the withdrawable amount to 0
            if(withdrawableForPeriod != 0){
                totalWithdraw += withdrawableForPeriod;
                _questPeriod.withdrawableAmount = 0;
            }

            unchecked{ ++i; }
        }

        // If there is a non null amount of token to withdraw, execute a transfer
        if(totalWithdraw != 0){
            address rewardToken = quests[questID].rewardToken;
            IERC20(rewardToken).safeTransfer(recipient, totalWithdraw);

            emit WithdrawUnusedRewards(questID, recipient, totalWithdraw);
        }
    }
   
    /**
    * @notice Emergency withdraws all undistributed rewards from Closed Quest Periods & all rewards for Active Periods
    * @dev Emergency withdraws all undistributed rewards from Closed Quest Periods & all rewards for Active Periods
    * @param questID ID of the Quest
    * @param recipient Address to send the reward tokens to
    */
    function emergencyWithdraw(uint256 questID, address recipient) external nonReentrant {
        if(!isKilled) revert Errors.NotKilled();
        if(block.timestamp < kill_ts + KILL_DELAY) revert Errors.KillDelayNotExpired();

        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(msg.sender != quests[questID].creator) revert Errors.CallerNotAllowed();
        if(recipient == address(0)) revert Errors.ZeroAddress();

        // Total amount to emergency withdraw
        uint256 totalWithdraw;

        uint48[] memory _questPeriods = questPeriods[questID];
        uint256 length = _questPeriods.length;
        for(uint256 i; i < length;){
            QuestPeriod storage _questPeriod = periodsByQuest[questID][_questPeriods[i]];

            // For CLOSED or DISTRIBUTED periods
            if(_questPeriod.currentState != PeriodState.ACTIVE){
                uint256 withdrawableForPeriod = _questPeriod.withdrawableAmount;

                // If there is a non_null withdrawable amount for the period,
                // add it to the total to withdraw, et set the withdrawable amount ot 0
                if(withdrawableForPeriod != 0){
                    totalWithdraw += withdrawableForPeriod;
                    _questPeriod.withdrawableAmount = 0;
                }
            } else {
                // And for the active period, and the next ones, withdraw the total reward amount
                totalWithdraw += _questPeriod.rewardAmountPerPeriod;
                _questPeriod.rewardAmountPerPeriod = 0;
            }

            unchecked{ ++i; }
        }

        // If the total amount to emergency withdraw is non_null, execute a transfer
        if(totalWithdraw != 0){
            address rewardToken = quests[questID].rewardToken;
            IERC20(rewardToken).safeTransfer(recipient, totalWithdraw);

            emit EmergencyWithdraw(questID, recipient, totalWithdraw);
        }

    }



    // Manager functions

    function _closeQuestPeriod(uint256 period, uint256 questID) internal returns(bool) {
        // We check that this period was not already closed
        if(periodsByQuest[questID][period].currentState != PeriodState.ACTIVE) return false;
            
        // We use the Gauge Point data from nextPeriod => the end of the period we are closing
        uint256 nextPeriod = period + WEEK;

        IGaugeController gaugeController = IGaugeController(GAUGE_CONTROLLER);

        Quest memory _quest = quests[questID];
        QuestPeriod memory _questPeriod = periodsByQuest[questID][period];
        _questPeriod.currentState = PeriodState.CLOSED;

        // Call a checkpoint on the Gauge, in case it was not written yet
        gaugeController.checkpoint_gauge(_quest.gauge);

        // Get the bias of the Gauge for the end of the period
        uint256 periodBias = gaugeController.points_weight(_quest.gauge, nextPeriod).bias;

        if(periodBias == 0) { 
            //Because we don't want to divide by 0
            // Here since the bias is 0, we consider 0% completion
            // => no rewards to be distributed
            // We do not change _questPeriod.rewardAmountDistributed since the default value is already 0
            _questPeriod.withdrawableAmount = _questPeriod.rewardAmountPerPeriod;
        }
        else{
            // For here, if the Gauge Bias is equal or greater than the objective, 
            // set all the period reward to be distributed.
            // If the bias is less, we take that bias, and calculate the amount of rewards based
            // on the rewardPerVote & the Gauge bias

            uint256 toDistributeAmount = periodBias >= _questPeriod.objectiveVotes ? _questPeriod.rewardAmountPerPeriod : (periodBias * _questPeriod.rewardPerVote) / UNIT;

            _questPeriod.rewardAmountDistributed = toDistributeAmount;
            // And the rest is set as withdrawable amount, that the Quest creator can retrieve
            _questPeriod.withdrawableAmount = _questPeriod.rewardAmountPerPeriod - toDistributeAmount;

            address questDistributor = questDistributors[questID];
            if(!MultiMerkleDistributor(questDistributor).addQuestPeriod(questID, period, toDistributeAmount)) revert Errors.DisitributorFail();
            IERC20(_quest.rewardToken).safeTransfer(questDistributor, toDistributeAmount);
        }

        periodsByQuest[questID][period] =  _questPeriod;

        emit PeriodClosed(questID, period);

        return true;
    }
 
    /**
    * @notice Closes the Period, and all QuestPeriods for this period
    * @dev Closes all QuestPeriod for the given period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    */
    function closeQuestPeriod(uint256 period) external isAlive onlyAllowed nonReentrant returns(uint256 closed, uint256 skipped) {
        period = (period / WEEK) * WEEK;
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        if(period == 0) revert Errors.InvalidPeriod();
        if(period >= getCurrentPeriod()) revert Errors.PeriodStillActive();
        if(questsByPeriod[period].length == 0) revert Errors.EmptyPeriod();
        // We use the 1st QuestPeriod of this period to check it was not Closed
        uint256[] memory questsForPeriod = questsByPeriod[period];

        // For each QuestPeriod
        uint256 length = questsForPeriod.length;
        for(uint256 i = 0; i < length;){
            bool result = _closeQuestPeriod(period, questsForPeriod[i]);

            if(result){
                closed++;
            } 
            else {
                skipped++;
            }

            unchecked{ ++i; }
        }
    }

    /**
    * @notice Closes the given QuestPeriods for the Period
    * @dev Closes the given QuestPeriods for the Period, calculating rewards to distribute & send them to distributor
    * @param period Timestamp of the period
    * @param questIDs List of the Quest IDs to close
    */
    function closePartOfQuestPeriod(uint256 period, uint256[] calldata questIDs) external isAlive onlyAllowed nonReentrant returns(uint256 closed, uint256 skipped) {
        period = (period / WEEK) * WEEK;
        uint256 questIDLength = questIDs.length;
        if(questIDLength == 0) revert Errors.EmptyArray();
        if(distributor == address(0)) revert Errors.NoDistributorSet();
        if(period == 0) revert Errors.InvalidPeriod();
        if(period >= getCurrentPeriod()) revert Errors.PeriodStillActive();
        if(questsByPeriod[period].length == 0) revert Errors.EmptyPeriod();

        // For each QuestPeriod
        for(uint256 i = 0; i < questIDLength;){
            bool result = _closeQuestPeriod(period, questIDs[i]);

            if(result){
                closed++;
            } 
            else {
                skipped++;
            }

            unchecked{ ++i; }
        }
    }
   
    /**
    * @dev Sets the QuestPeriod as disitrbuted, and adds the MerkleRoot to the Distributor contract
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param totalAmount sum of all rewards for the Merkle Tree
    * @param merkleRoot MerkleRoot to add
    */
    function _addMerkleRoot(uint256 questID, uint256 period, uint256 totalAmount, bytes32 merkleRoot) internal {
        if(questID >= nextID) revert Errors.InvalidQuestID();
        if(merkleRoot == 0) revert Errors.EmptyMerkleRoot();
        if(totalAmount == 0) revert Errors.NullAmount();

        // This also allows to check if the given period is correct => If not, the currentState is never set to CLOSED for the QuestPeriod
        if(periodsByQuest[questID][period].currentState != PeriodState.CLOSED) revert Errors.PeriodNotClosed();

        // Add the MerkleRoot to the Distributor & set the QuestPeriod as DISTRIBUTED
        if(!MultiMerkleDistributor(questDistributors[questID]).updateQuestPeriod(questID, period, totalAmount, merkleRoot)) revert Errors.DisitributorFail();

        periodsByQuest[questID][period].currentState = PeriodState.DISTRIBUTED;
    }
   
    /**
    * @notice Sets the QuestPeriod as disitrbuted, and adds the MerkleRoot to the Distributor contract
    * @dev internal call to _addMerkleRoot()
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param totalAmount sum of all rewards for the Merkle Tree
    * @param merkleRoot MerkleRoot to add
    */
    function addMerkleRoot(uint256 questID, uint256 period, uint256 totalAmount, bytes32 merkleRoot) external isAlive onlyAllowed nonReentrant {
        period = (period / WEEK) * WEEK;
        _addMerkleRoot(questID, period, totalAmount, merkleRoot);
    }

    /**
    * @notice Sets a list of QuestPeriods as disitrbuted, and adds the MerkleRoot to the Distributor contract for each
    * @dev Loop and internal call to _addMerkleRoot()
    * @param questIDs List of Quest IDs
    * @param period Timestamp of the period
    * @param totalAmounts List of sums of all rewards for the Merkle Tree
    * @param merkleRoots List of MerkleRoots to add
    */
    function addMultipleMerkleRoot(
        uint256[] calldata questIDs,
        uint256 period,
        uint256[] calldata totalAmounts,
        bytes32[] calldata merkleRoots
    ) external isAlive onlyAllowed nonReentrant {
        period = (period / WEEK) * WEEK;
        uint256 length = questIDs.length;

        if(length != merkleRoots.length) revert Errors.InequalArraySizes();
        if(length != totalAmounts.length) revert Errors.InequalArraySizes();

        for(uint256 i = 0; i < length;){
            _addMerkleRoot(questIDs[i], period, totalAmounts[i], merkleRoots[i]);

            unchecked{ ++i; }
        }
    }
   
    /**
    * @notice Whitelists a reward token
    * @dev Whitelists a reward token
    * @param newToken Address of the reward token
    */
    function whitelistToken(address newToken, uint256 minRewardPerVote) public onlyAllowed {
        if(newToken == address(0)) revert Errors.ZeroAddress();
        if(minRewardPerVote == 0) revert Errors.InvalidParameter();

        whitelistedTokens[newToken] = true;

        minRewardPerVotePerToken[newToken] = minRewardPerVote;

        emit WhitelistToken(newToken, minRewardPerVote);
    }
   
    /**
    * @notice Whitelists a list of reward tokens
    * @dev Whitelists a list of reward tokens
    * @param newTokens List of reward tokens addresses
    */
    function whitelistMultipleTokens(address[] calldata newTokens, uint256[] calldata minRewardPerVotes) external onlyAllowed {
        uint256 length = newTokens.length;

        if(length == 0) revert Errors.EmptyArray();
        if(length != minRewardPerVotes.length) revert Errors.InequalArraySizes();

        for(uint256 i = 0; i < length;){
            whitelistToken(newTokens[i], minRewardPerVotes[i]);

            unchecked{ ++i; }
        }
    }

    function updateRewardToken(address newToken, uint256 newMinRewardPerVote) external onlyAllowed {
        if(!whitelistedTokens[newToken]) revert Errors.TokenNotWhitelisted();
        if(newMinRewardPerVote == 0) revert Errors.InvalidParameter();

        minRewardPerVotePerToken[newToken] = newMinRewardPerVote;

        emit UpdateRewardToken(newToken, newMinRewardPerVote);
    }

    // Admin functions
   
    /**
    * @notice Sets an initial Distributor address
    * @dev Sets an initial Distributor address
    * @param newDistributor Address of the Distributor
    */
    function initiateDistributor(address newDistributor) external onlyOwner {
        if(distributor != address(0)) revert Errors.AlreadyInitialized();
        distributor = newDistributor;

        emit InitDistributor(newDistributor);
    }
   
    /**
    * @notice Approves a new address as manager 
    * @dev Approves a new address as manager
    * @param newManager Address to add
    */
    function approveManager(address newManager) external onlyOwner {
        if(newManager == address(0)) revert Errors.ZeroAddress();
        approvedManagers[newManager] = true;

        emit ApprovedManager(newManager);
    }
   
    /**
    * @notice Removes an address from the managers
    * @dev Removes an address from the managers
    * @param manager Address to remove
    */
    function removeManager(address manager) external onlyOwner {
        if(manager == address(0)) revert Errors.ZeroAddress();
        approvedManagers[manager] = false;

        emit RemovedManager(manager);
    }
   
    /**
    * @notice Updates the Chest address
    * @dev Updates the Chest address
    * @param chest Address of the new Chest
    */
    function updateChest(address chest) external onlyOwner {
        if(chest == address(0)) revert Errors.ZeroAddress();
        address oldChest = questChest;
        questChest = chest;

        emit ChestUpdated(oldChest, chest);
    }
   
    /**
    * @notice Updates the Distributor address
    * @dev Updates the Distributor address
    * @param newDistributor Address of the new Distributor
    */
    function updateDistributor(address newDistributor) external onlyOwner {
        if(newDistributor == address(0)) revert Errors.ZeroAddress();
        address oldDistributor = distributor;
        distributor = newDistributor;

        emit DistributorUpdated(oldDistributor, distributor);
    }
   
    /**
    * @notice Updates the Platfrom fees BPS ratio
    * @dev Updates the Platfrom fees BPS ratio
    * @param newFee New fee ratio
    */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        if(newFee > 500) revert Errors.InvalidParameter();
        uint256 oldfee = platformFee;
        platformFee = newFee;

        emit PlatformFeeUpdated(oldfee, newFee);
    }
   
    /**
    * @notice Updates the min objective value
    * @dev Updates the min objective value
    * @param newMinObjective New min objective
    */
    function updateMinObjective(uint256 newMinObjective) external onlyOwner {
        if(newMinObjective == 0) revert Errors.InvalidParameter();
        uint256 oldMinObjective = minObjective;
        minObjective = newMinObjective;

        emit MinObjectiveUpdated(oldMinObjective, newMinObjective);
    }
   
    /**
    * @notice Recovers ERC2O tokens sent by mistake to the contract
    * @dev Recovers ERC2O tokens sent by mistake to the contract
    * @param token Address tof the EC2O token
    * @return bool: success
    */
    function recoverERC20(address token) external onlyOwner returns(bool) {
        if(whitelistedTokens[token]) revert Errors.CannotRecoverToken();

        uint256 amount = IERC20(token).balanceOf(address(this));
        if(amount == 0) revert Errors.NullAmount();
        IERC20(token).safeTransfer(owner(), amount);

        return true;
    }
   
    /**
    * @notice Kills the contract
    * @dev Kills the contract
    */
    function killBoard() external onlyOwner {
        if(isKilled) revert Errors.AlreadyKilled();
        isKilled = true;
        kill_ts = block.timestamp;

        emit Killed(kill_ts);
    }
   
    /**
    * @notice Unkills the contract
    * @dev Unkills the contract
    */
    function unkillBoard() external onlyOwner {
        if(!isKilled) revert Errors.NotKilled();
        if(block.timestamp >= kill_ts + KILL_DELAY) revert Errors.KillDelayExpired();
        isKilled = false;

        emit Unkilled(block.timestamp);
    }



    // Utils 

    function safe48(uint n) internal pure returns (uint48) {
        if(n > type(uint48).max) revert Errors.NumberExceed48Bits();
        return uint48(n);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../utils/Address.sol";

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
pragma solidity ^0.8.10;

import "../oz/utils/Ownable.sol";

/** @title Extend OZ Ownable contract  */
/// @author Paladin

contract Owner is Ownable {

    address public pendingOwner;

    event NewPendingOwner(address indexed previousPendingOwner, address indexed newPendingOwner);

    error CannotBeOwner();
    error CallerNotPendingOwner();
    error ZeroAddress();

    function transferOwnership(address newOwner) public override virtual onlyOwner {
        if(newOwner == address(0)) revert ZeroAddress();
        if(newOwner == owner()) revert CannotBeOwner();
        address oldPendingOwner = pendingOwner;

        pendingOwner = newOwner;

        emit NewPendingOwner(oldPendingOwner, newOwner);
    }

    function acceptOwnership() public virtual {
        if(msg.sender != pendingOwner) revert CallerNotPendingOwner();
        address newOwner = pendingOwner;
        _transferOwnership(pendingOwner);
        pendingOwner = address(0);

        emit NewPendingOwner(newOwner, address(0));
    }

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

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
 

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./oz/interfaces/IERC20.sol";
import "./oz/libraries/SafeERC20.sol";
import "./oz/utils/MerkleProof.sol";
import "./utils/Owner.sol";
import "./oz/utils/ReentrancyGuard.sol";
import "./utils/Errors.sol";

/** @title Warden Quest Multi Merkle Distributor  */
/// @author Paladin
/*
    Contract holds ERC20 rewards from Quests
    Can handle multiple MerkleRoots
*/

contract MultiMerkleDistributor is Owner, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /** @notice Seconds in a Week */
    uint256 private constant WEEK = 604800;

    /** @notice Mapping listing the reward token associated to each Quest ID */
    // QuestID => reward token
    mapping(uint256 => address) public questRewardToken;

    /** @notice Mapping of tokens this contract is or was distributing */
    // token address => boolean
    mapping(address => bool) public rewardTokens;

    //Periods: timestamp => start of a week, used as a voting period 
    //in the Curve GaugeController though the timestamp / WEEK *  WEEK logic.
    //Handled through the QuestManager contract.
    //Those can be fetched through this contract when they are closed, or through the QuestManager contract.

    /** @notice List of Closed QuestPeriods by Quest ID */
    // QuestID => array of periods
    mapping(uint256 => uint256[]) public questClosedPeriods;

    /** @notice Merkle Root for each period of a Quest (indexed by Quest ID) */
    // QuestID => period => merkleRoot
    mapping(uint256 => mapping(uint256 => bytes32)) public questMerkleRootPerPeriod;

    /** @notice Amount of rewards for each period of a Quest (indexed by Quest ID) */
    // QuestID => period => totalRewardsAmount
    mapping(uint256 => mapping(uint256 => uint256)) public questRewardsPerPeriod;

    /** @notice BitMap of claims for each period of a Quest */
    // QuestID => period => claimedBitMap
    // This is a packed array of booleans.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) private questPeriodClaimedBitMap;

    /** @notice Address of the QuestBoard contract */
    address public immutable questBoard;


    // Events

    /** @notice Event emitted when an user Claims */
    event Claimed(
        uint256 indexed questID,
        uint256 indexed period,
        uint256 index,
        uint256 amount,
        address rewardToken,
        address indexed account
    );
    /** @notice Event emitted when a New Quest is added */
    event NewQuest(uint256 indexed questID, address rewardToken);
    /** @notice Event emitted when a Period of a Quest is updated (when the Merkle Root is added) */
    event QuestPeriodUpdated(uint256 indexed questID, uint256 indexed period, bytes32 merkleRoot);


    // Modifier

    /** @notice Check the caller is either the admin or the QuestBoard contract */
    modifier onlyAllowed(){
        if(msg.sender != questBoard && msg.sender != owner()) revert Errors.CallerNotAllowed();
        _;
    }


    // Constructor

    constructor(address _questBoard){
        if(_questBoard == address(0)) revert Errors.ZeroAddress();

        questBoard = _questBoard;
    }

    // Functions
   
    /**
    * @notice Checks if the rewards were claimed for an user on a given period
    * @dev Checks if the rewards were claimed for an user (based on the index) on a given period
    * @param questID ID of the Quest
    * @param period Amount of underlying to borrow
    * @param index Index of the claim
    * @return bool : true if already claimed
    */
    function isClaimed(uint256 questID, uint256 period, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 claimedWord = questPeriodClaimedBitMap[questID][period][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask != 0;
    }
   
    /**
    * @dev Sets the rewards as claimed for the index on the given period
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param index Index of the claim
    */
    function _setClaimed(uint256 questID, uint256 period, uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        questPeriodClaimedBitMap[questID][period][claimedWordIndex] |= (1 << claimedBitIndex);
    }

    //Basic Claim   
    /**
    * @notice Claims the reward for an user for a given period of a Quest
    * @dev Claims the reward for an user for a given period of a Quest if the correct proof was given
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param index Index in the Merkle Tree
    * @param account Address of the user claiming the rewards
    * @param amount Amount of rewards to claim
    * @param merkleProof Proof to claim the rewards
    */
    function claim(uint256 questID, uint256 period, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public nonReentrant {
        if(account == address(0)) revert Errors.ZeroAddress();
        if(questMerkleRootPerPeriod[questID][period] == 0) revert Errors.MerkleRootNotUpdated();
        if(isClaimed(questID, period, index)) revert Errors.AlreadyClaimed();

        // Check that the given parameters match the given Proof
        bytes32 node = keccak256(abi.encodePacked(questID, period, index, account, amount));
        if(!MerkleProof.verify(merkleProof, questMerkleRootPerPeriod[questID][period], node)) revert Errors.InvalidProof();

        // Set the rewards as claimed for that period
        // And transfer the rewards to the user
        address rewardToken = questRewardToken[questID];
        _setClaimed(questID, period, index);
        questRewardsPerPeriod[questID][period] -= amount;
        IERC20(rewardToken).safeTransfer(account, amount);

        emit Claimed(questID, period, index, amount, rewardToken, account);
    }


    //Struct ClaimParams
    struct ClaimParams {
        uint256 questID;
        uint256 period;
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }


    //Multi Claim   
    /**
    * @notice Claims multiple rewards for a given list
    * @dev Calls the claim() method for each entry in the claims array
    * @param account Address of the user claiming the rewards
    * @param claims List of ClaimParams struct data to claim
    */
    function multiClaim(address account, ClaimParams[] calldata claims) external {
        uint256 length = claims.length;
        
        if(length == 0) revert Errors.EmptyParameters();

        for(uint256 i; i < length;){
            claim(claims[i].questID, claims[i].period, claims[i].index, account, claims[i].amount, claims[i].merkleProof);

            unchecked{ ++i; }
        }
    }


    //FullQuest Claim (form of Multi Claim but for only one Quest => only one ERC20 transfer)
    //Only works for the given periods (in ClaimParams) for the Quest. Any omitted period will be skipped   
    /**
    * @notice Claims the reward for all the given periods of a Quest, and transfer all the rewards at once
    * @dev Sums up all the rewards for given periods of a Quest, and executes only one transfer
    * @param account Address of the user claiming the rewards
    * @param questID ID of the Quest
    * @param claims List of ClaimParams struct data to claim
    */
    function claimQuest(address account, uint256 questID, ClaimParams[] calldata claims) external nonReentrant {
        if(account == address(0)) revert Errors.ZeroAddress();
        uint256 length = claims.length;

        if(length == 0) revert Errors.EmptyParameters();

        // Total amount claimable, to transfer at once
        uint256 totalClaimAmount;
        address rewardToken = questRewardToken[questID];

        for(uint256 i; i < length;){
            if(claims[i].questID != questID) revert Errors.IncorrectQuestID();
            if(questMerkleRootPerPeriod[questID][claims[i].period] == 0) revert Errors.MerkleRootNotUpdated();
            if(isClaimed(questID, claims[i].period, claims[i].index)) revert Errors.AlreadyClaimed();

            // For each period given, if the proof matches the given parameters, 
            // set as claimed and add to the to total to transfer
            bytes32 node = keccak256(abi.encodePacked(questID, claims[i].period, claims[i].index, account, claims[i].amount));
            if(!MerkleProof.verify(claims[i].merkleProof, questMerkleRootPerPeriod[questID][claims[i].period], node)) revert Errors.InvalidProof();

            _setClaimed(questID, claims[i].period, claims[i].index);
            questRewardsPerPeriod[questID][claims[i].period] -= claims[i].amount;
            totalClaimAmount += claims[i].amount;

            emit Claimed(questID, claims[i].period, claims[i].index, claims[i].amount, rewardToken, account);

            unchecked{ ++i; }
        }

        // Transfer the total claimed amount
        IERC20(rewardToken).safeTransfer(account, totalClaimAmount);
    }

   
    /**
    * @notice Returns all current Closed periods for the given Quest ID
    * @dev Returns all current Closed periods for the given Quest ID
    * @param questID ID of the Quest
    * @return uint256[] : List of closed periods
    */
    function getClosedPeriodsByQuests(uint256 questID) external view returns (uint256[] memory) {
        return questClosedPeriods[questID];
    }



    // Manager functions
   
    /**
    * @notice Adds a new Quest to the listing
    * @dev Adds a new Quest ID and the associated reward token
    * @param questID ID of the Quest
    * @param token Address of the ERC20 reward token
    * @return bool : success
    */
    function addQuest(uint256 questID, address token) external returns(bool) {
        if(msg.sender != questBoard) revert Errors.CallerNotAllowed();
        if(questRewardToken[questID] != address(0)) revert Errors.QuestAlreadyListed();
        if(token == address(0)) revert Errors.TokenNotWhitelisted();

        // Add a new Quest using the QuestID, and list the reward token for that Quest
        questRewardToken[questID] = token;

        if(!rewardTokens[token]) rewardTokens[token] = true;

        emit NewQuest(questID, token);

        return true;
    }

    /**
    * @notice Adds a new period & the rewards of this period for a Quest
    * @dev Adds a new period & the rewards of this period for a Quest
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param totalRewardAmount Total amount of rewards to distribute for the period
    * @return bool : success
    */
    function addQuestPeriod(uint256 questID, uint256 period, uint256 totalRewardAmount) external returns(bool) {
        period = (period / WEEK) * WEEK;
        if(msg.sender != questBoard) revert Errors.CallerNotAllowed();
        if(questRewardToken[questID] == address(0)) revert Errors.QuestNotListed();
        if(questRewardsPerPeriod[questID][period] != 0) revert Errors.PeriodAlreadyUpdated();
        if(period == 0) revert Errors.IncorrectPeriod();
        if(totalRewardAmount == 0) revert Errors.NullAmount();

        questRewardsPerPeriod[questID][period] = totalRewardAmount;

        return true;
    }
   
    /**
    * @notice Updates the period of a Quest by adding the Merkle Root
    * @dev Add the Merkle Root for the eriod of the given Quest
    * @param questID ID of the Quest
    * @param period timestamp of the period
    * @param totalAmount sum of all rewards for the Merkle Tree
    * @param merkleRoot MerkleRoot to add
    * @return bool: success
    */
    function updateQuestPeriod(uint256 questID, uint256 period, uint256 totalAmount, bytes32 merkleRoot) external onlyAllowed returns(bool) {
        period = (period / WEEK) * WEEK;
        if(questRewardToken[questID] == address(0)) revert Errors.QuestNotListed();
        if(period == 0) revert Errors.IncorrectPeriod();
        if(questRewardsPerPeriod[questID][period] == 0) revert Errors.PeriodNotListed();
        if(questMerkleRootPerPeriod[questID][period] != 0) revert Errors.PeriodAlreadyUpdated();
        if(merkleRoot == 0) revert Errors.EmptyMerkleRoot();

        // Add a new Closed Period for the Quest
        questClosedPeriods[questID].push(period);

        if(totalAmount != questRewardsPerPeriod[questID][period]) revert Errors.IncorrectRewardAmount();

        // Add the new MerkleRoot for that Closed Period
        questMerkleRootPerPeriod[questID][period] = merkleRoot;

        emit QuestPeriodUpdated(questID, period, merkleRoot);

        return true;
    }


    //  Admin functions
   
    /**
    * @notice Recovers ERC2O tokens sent by mistake to the contract
    * @dev Recovers ERC2O tokens sent by mistake to the contract
    * @param token Address tof the EC2O token
    * @return bool: success
    */
    function recoverERC20(address token) external onlyOwner nonReentrant returns(bool) {
        if(rewardTokens[token]) revert Errors.CannotRecoverToken();
        uint256 amount = IERC20(token).balanceOf(address(this));
        if(amount == 0) revert Errors.NullAmount();
        IERC20(token).safeTransfer(owner(), amount);

        return true;
    }

    // 
    /**
    * @notice Allows to update the MerkleRoot for a given period of a Quest if the current Root is incorrect
    * @dev Updates the MerkleRoot for the period of the Quest
    * @param questID ID of the Quest
    * @param period Timestamp of the period
    * @param merkleRoot New MerkleRoot to add
    * @return bool : success
    */
    function emergencyUpdateQuestPeriod(uint256 questID, uint256 period, uint256 addedRewardAmount, bytes32 merkleRoot) external onlyOwner returns(bool) {
        // In case the given MerkleRoot was incorrect:
        // Process:
        // 1 - block claims for the Quest period by using this method to set an incorrect MerkleRoot, where no proof matches the root
        // 2 - prepare a new Merkle Tree, taking in account user previous claims on that period, and missing/overpaid rewards
        //      a - for all new claims to be added, set them after the last index of the previous Merkle Tree
        //      b - for users that did not claim, keep the same index, and adjust the amount to claim if needed
        //      c - for indexes that were claimed, place an empty node in the Merkle Tree (with an amount at 0 & the address 0xdead as the account)
        // 3 - update the Quest period with the correct MerkleRoot
        // (no need to change the Bitmap, as the new MerkleTree will account for the indexes already claimed)

        period = (period / WEEK) * WEEK;
        if(questRewardToken[questID] == address(0)) revert Errors.QuestNotListed();
        if(period == 0) revert Errors.IncorrectPeriod();
        if(questMerkleRootPerPeriod[questID][period] == 0) revert Errors.PeriodNotClosed();
        if(merkleRoot == 0) revert Errors.EmptyMerkleRoot();

        questMerkleRootPerPeriod[questID][period] = merkleRoot;

        questRewardsPerPeriod[questID][period] += addedRewardAmount;

        emit QuestPeriodUpdated(questID, period, merkleRoot);

        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface made for the Curve's GaugeController contract
 */
interface IGaugeController {

    struct VotedSlope {
        uint slope;
        uint power;
        uint end;
    }
    
    struct Point {
        uint bias;
        uint slope;
    }
    
    function vote_user_slopes(address, address) external view returns(VotedSlope memory);
    function last_user_vote(address, address) external view returns(uint);
    function points_weight(address, uint256) external view returns(Point memory);
    function checkpoint_gauge(address) external;
    function gauge_types(address _addr) external view returns(int128);
    
}

pragma solidity 0.8.10;
//SPDX-License-Identifier: MIT

library Errors {

    // Common Errors
    error ZeroAddress();
    error NullAmount();
    error CallerNotAllowed();
    error IncorrectRewardToken();
    error SameAddress();
    error InequalArraySizes();
    error EmptyArray();
    error EmptyParameters();
    error AlreadyInitialized();
    error InvalidParameter();
    error CannotRecoverToken();

    error Killed();
    error AlreadyKilled();
    error NotKilled();
    error KillDelayExpired();
    error KillDelayNotExpired();


    // Merkle Errors
    error MerkleRootNotUpdated();
    error AlreadyClaimed();
    error InvalidProof();
    error EmptyMerkleRoot();
    error IncorrectRewardAmount();


    // Quest Errors
    error CallerNotQuestBoard();
    error IncorrectQuestID();
    error IncorrectPeriod();
    error TokenNotWhitelisted();
    error QuestAlreadyListed();
    error QuestNotListed();
    error PeriodAlreadyUpdated();
    error PeriodNotClosed();
    error PeriodStillActive();
    error PeriodNotListed();
    error EmptyQuest();
    error EmptyPeriod();
    error ExpiredQuest();

    error NoDistributorSet();
    error DisitributorFail();
    error InvalidGauge();
    error InvalidQuestID();
    error InvalidPeriod();
    error ObjectiveTooLow();
    error RewardPerVoteTooLow();
    error IncorrectDuration();
    error IncorrectAddDuration();
    error IncorrectTotalRewardAmount();
    error IncorrectAddedRewardAmount();
    error IncorrectFeeAmount();
    error CalletNotQuestCreator();
    error LowerRewardPerVote();
    error LowerObjective();


    //Math
    error NumberExceed48Bits();

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}