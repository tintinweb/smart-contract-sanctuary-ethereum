// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./GovernancePool.sol";
import "../interfaces/ILotteryToken.sol";
import "../interfaces/ILotteryGameToken.sol";
import "../interfaces/IRewardDistribution.sol";
import "../governance/interfaces/IGovernance.sol";
import "../lotteryGame/DateTime.sol";

/// @title Contract for lotto/game tokens reward distribution
/// @author Applicature
/// @notice Manage reward distribution based on the reward type -
/// whether it is COMMUNITY or GOVERNANCE reward
contract RewardDistribution is IRewardDistribution, Ownable, GovernancePool, KeeperCompatibleInterface  {
    using SafeERC20 for IERC20;

    uint256 private constant DECIMALS_18 = 1e18;
    uint256 private constant ONE_HUNDRED_PERCENT_WITH_PRECISIONS =
        100 * DECIMALS_18;

    // @notice info about community reward distributions
    CommunityReward[] public rewardDistributionInfo;
    // @notice info about governance reward distributions
    GovernanceReward[] public govRewardsInfo;
    // @notice count of community distributions
    uint256 public countOfCommunityDistribution;
    // @notice count of governance distributions
    uint256 public countOfGovernanceDistribution;
    // @notice total amount of lotto tokens for reward distribution
    uint256 public totalLottoSupply;
    // @notice total amount of game tokens for reward distribution
    uint256 public totalGameSupply;
    // @notice total amount of claimed lotto tokens
    uint256 public claimedLottoReward;
    // @notice total amount of claimed game tokens
    uint256 public claimedGameReward;
    // @notice number of max available top index in reward distributions array to claim reward at one tx
    uint256 public loopClaimLimit;

    // @notice governance contract
    IGovernance public immutable governance;
    // @notice lotto token
    IERC20 public immutable lottoToken;
    // @notice game token
    IERC20 public immutable gameToken;
    // @notice date time
    DateTime public dateTime;
    // @notice games factory
    address public immutable gameFactory;
    // @notice number day of the week
    uint8 public day = 3;
    // @notice interval e.g. 7 days
    uint256 public interval = 2 minutes;

    uint256 public test;


    /// @notice store number of last claimed distribution index by the user
    mapping(address => ClaimedIndexes) public lastClaimedDistribution;

    // @notice total voting power defined for the specific proposal
    // at the moment of the last check of existing governance rewards
    // in case if the one proposal will be valid for several reward distribution
    // the info for reward distribution user's portion will be diffrent,
    // like different total amount of token
    mapping(uint256 => VotingPowerInfo) private usedVotingPowerForProposal;

    // @notice voting power amount for the proposal
    // in the specific governance reward distribution id
    // id propos => id gov distribution => amount of votes need to be used for calcualtion
    mapping(uint256 => mapping(uint256 => VotingPowerInfo))
        private votingPowerForDistribution;

    // @notive last valid checked proposal index for the governance rewards distribution
    LastProposalIndexInfo private indexOfLastCheckedProposal;

    // @notive last time of the check whether there are valid governance rewards for distribution
    uint256 public lastTimeGovRewardCheck;

    bool private isNullIdPropActive = true;

    // @notice allowed for game factory contract and owner(governance)
    modifier onlyAllowed() {
        require(
            msg.sender == gameFactory || msg.sender == owner(),
            "Isn't allowed"
        );
        _;
    }

    /// @notice Set initial data
    /// @param lottoToken_ lotto token contract
    /// @param gameToken_ game token contract
    /// @param gameFactory_ game factory contract address
    /// @param mainGame_ main lottery game contract address
    constructor(
        address lottoToken_,
        address gameToken_,
        address gameFactory_,
        address mainGame_,
        address governance_
    ) {
        require(
            gameFactory_ != address(0) && mainGame_ != address(0),
            "ZERO_ADDRESS"
        );
        lottoToken = IERC20(lottoToken_);
        gameToken = IERC20(gameToken_);
        gameFactory = gameFactory_;
        governance = IGovernance(governance_);
        islotteryGame[mainGame_] = true;
        loopClaimLimit = 1000;
        lastTimeGovRewardCheck = block.timestamp;
        emit LotteryGameAdded(mainGame_);
    }

    /// @notice Set address of DateTime contract
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param dateTime_ address of DateTime contract
    function setDateTime(address dateTime_) external onlyAllowed {
        require(dateTime_ != address(0), "ZERO_ADDRESS");
        dateTime = DateTime(dateTime_);
    }

    function checkTest() external {
        test = dateTime.getWeekday(block.timestamp);
    }

    /// @notice Set new loop claim limit value
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param loopClaimLimit_ value of new loop claim limit
    function setLoopClaimLimit(uint256 loopClaimLimit_) external onlyAllowed {
        require(loopClaimLimit_ != 0, "ZERO_AMOUNT");
        loopClaimLimit = loopClaimLimit_;
    }

    /// @notice Set new number of the day to check chainlink upkeeper
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param day_ the number of the day of the week (1-7)
    function setWeekDays(uint8 day_) external onlyAllowed {
        require(day_ > 0 && day_ < 8, "INVALID_VALUE");
        day = day_;
    }

    /// @notice Set new interval to check chainlink upkeeper
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param interval_ value of interval for next check
    function setIntervalForCheck(uint256 interval_) external onlyAllowed {
        require(interval_ > 0, "INVALID_VALUE");
        interval = interval_;
    }

    /// @notice Add new game to the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of new game contract
    function addNewGame(address game_) external override onlyAllowed {
        require(game_ != address(0), "ZERO_ADDRESS");
        islotteryGame[game_] = true;
        emit LotteryGameAdded(game_);
    }

    /// @notice Add new game to the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of new game contract
    function removeGame(address game_) external override onlyAllowed {
        require(islotteryGame[game_], "DEACTIVATED");
        islotteryGame[game_] = false;
        emit LotteryGameRemoved(game_);
    }

    /// @notice Add new community reward distribution portion
    /// @dev Allowed to be called only by authorized game contracts
    /// @param distributionInfo structure of <CommunityReward> type
    function addDistribution(CommunityReward calldata distributionInfo)
        external
        override
        onlyLotteryGame
    {
        _addDistribution(distributionInfo);
    }

    /// @notice Claim available community reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimCommunityReward() external override {
        address user = msg.sender;
        require(lastClaimedDistribution[user].lastClaimedCommunityReward < rewardDistributionInfo.length, "NOTHING_TO_CLAIM");
        uint256 from = lastClaimedDistribution[user].lastClaimedCommunityReward;
        if (lastClaimedDistribution[user].isCommNullIndexUsed){
            from+=1;
        }
        uint256 to = from + loopClaimLimit - 1;
        if (to >= rewardDistributionInfo.length){
            to = rewardDistributionInfo.length -1;
        }
        (uint256 lottoRewards, uint256 gameRewards) = _availableCommunityReward(
            from,
            to,
            user
        );
        _claim(lottoRewards, gameRewards, user);

        lastClaimedDistribution[user].lastClaimedCommunityReward = to;

        if (to >= 0){
            if(!lastClaimedDistribution[user].isCommNullIndexUsed)
                lastClaimedDistribution[user].isCommNullIndexUsed = true;
        }        
    }

    /// @notice Return available community reward of user
    /// @param user address need check rewards for 
    function availableCommunityReward(address user)
        external
        view
        override
        returns (uint256 lottoRewards, uint256 gameRewards)
    {
        require(rewardDistributionInfo.length != 0, "INVALID_ITEMS");
        require(lastClaimedDistribution[user].lastClaimedCommunityReward < rewardDistributionInfo.length, "NOTHING_TO_CLAIM");
        uint256 from = lastClaimedDistribution[user].lastClaimedCommunityReward;
        if (lastClaimedDistribution[user].isCommNullIndexUsed){
            from+=1;
        }
        uint256 to = rewardDistributionInfo.length - 1;
        (lottoRewards, gameRewards) = _availableCommunityReward(
            from,
            to,
            user
        );
    }

    /// @notice Return available community reward of user
    /// @param user address need check rewards for 
    function availableGovernanceReward(address user)
        external
        view
        override
        returns (uint256 lottoRewards, uint256 gameRewards)
    {
        require(govRewardsInfo.length != 0, "INVALID_ITEMS");
        require(lastClaimedDistribution[user].lastClaimedGovernanceReward < govRewardsInfo.length, "NOTHING_TO_CLAIM");
        uint256 from = lastClaimedDistribution[user].lastClaimedGovernanceReward;
        if (lastClaimedDistribution[user].isGovNullIndexUsed){
            from+=1;
        }
        uint256 to = govRewardsInfo.length - 1;
        (lottoRewards, gameRewards) = _availableGovernanceReward(
            from,
            to,
            user
        );
    }

    /// @dev Called by Chainlink Keepers to check if work needs to be done
    /// @notice Runs off-chain at every block to determine if the performUpkeep function should be called on-chain
    function checkUpkeep(
        bytes calldata /*checkData */
    ) external override returns (bool upkeepNeeded, bytes memory /*performData*/ ) {
        upkeepNeeded = (block.timestamp >= interval + lastTimeGovRewardCheck) && (dateTime.getWeekday(block.timestamp) == day);
    }

    /// @dev Called by Chainlink Keepers to handle work
    /// @notice Contains the logic that should be executed on-chain when checkUpkeep returns true
    function performUpkeep(bytes calldata  /* performData */) external override {
        //revalidate the conditions from checkUpkeep()
        if((block.timestamp >= interval + lastTimeGovRewardCheck) && (dateTime.getWeekday(block.timestamp) == day)) {
            _checkGovernanceReward();
        }
    }

    /// @notice Check if there are any valid/new proposals in governance contract.
    /// Add new governance reward distribution portion if conditions allow
    function _checkGovernanceReward() internal {
        uint256 totalCountOfProposals = governance.getProposalsCount();

        // can be new valid proposals or proposals that didn't finish prev week
        // and should be valid for the current active week
        if (
            totalCountOfProposals != 0 &&
            (totalCountOfProposals >
                indexOfLastCheckedProposal.prevCountOfProposals ||
                (totalCountOfProposals - 1) !=
                indexOfLastCheckedProposal.index ||
                isNullIdPropActive)
        ) {
            // calculate count of new proposals
            bool condition = indexOfLastCheckedProposal.prevCountOfProposals != 0 && !isNullIdPropActive;
            uint256 proposalCount = totalCountOfProposals - indexOfLastCheckedProposal.index;

            uint256 countOfNewProposals = condition ? proposalCount - 1 :  proposalCount;

            uint256 from = indexOfLastCheckedProposal.index + 1;
            uint256 to = totalCountOfProposals - 1;

            // in case if already were the one proposition
            // so the last checked index will be 0
            // the first check
            if (
                (indexOfLastCheckedProposal.prevCountOfProposals == 0 &&
                    indexOfLastCheckedProposal.index == 0) || isNullIdPropActive
            ) {
                from = 0;
            }
            for (int256 i = int256(to); i >= int256(from); i--) {
                uint256 index = i > 0 ? uint256(i) : 0;
                // check if the voting on the proposal was finished
                // if no - the last checked index will be that one of the last not finished proposal
                if (
                    uint256(governance.getProposalState(index)) >
                    uint256(IGovernance.ProposalState.Active)
                ) {
                    indexOfLastCheckedProposal.index = index;
                    if (index == 0) {
                        isNullIdPropActive = false;
                    }
                    break;
                } else {
                    VotingPowerInfo storage info = usedVotingPowerForProposal[
                        index
                    ];
                    IGovernance.ProposalWithoutVotes
                        memory proposal = governance.getProposalById(index);

                    uint256 prevLottoVotes = info.lottoPower;
                    uint256 prevGameVotes = info.gamePower;
                    // new total amount
                    uint256 lottoVotes = proposal.lottoVotes;
                    uint256 gameVotes = proposal.gameVotes;
                    uint256 currentDistId = govRewardsInfo.length != 0
                        ? govRewardsInfo.length - 1
                        : 0;

                    VotingPowerInfo
                        storage votesInfoForCurrentDistributionId = votingPowerForDistribution[
                            index
                        ][currentDistId];

                    // set votes count for current distribution period
                    votesInfoForCurrentDistributionId.lottoPower =
                        lottoVotes -
                        prevLottoVotes;
                    votesInfoForCurrentDistributionId.gamePower =
                        gameVotes -
                        prevGameVotes;
                    votesInfoForCurrentDistributionId.isUpdated = true;
                    // update new total used voting power for the passed periods
                    info.lottoPower = lottoVotes;
                    info.gamePower = gameVotes;
                }
            }

            indexOfLastCheckedProposal
                .prevCountOfProposals = totalCountOfProposals;

            // get valid amount from the pool
            (
                uint256 lottoAmount,
                uint256 gameAmount
            ) = _updateGovernanceRewardPool();

            require(lottoAmount != 0 || gameAmount != 0, "EMPTY_POOL");

            uint256 lottoAmountForDistribution = lottoAmount /
                countOfNewProposals;
            uint256 gameAmountForDistribution = gameAmount /
                countOfNewProposals;

            // add distribution
            GovernanceReward memory govReward;
            govReward.totalLottoAmount = lottoAmount;
            govReward.totalGameAmount = gameAmount;
            govReward.lottoPerProposal = lottoAmountForDistribution;
            govReward.gamePerProposal = gameAmountForDistribution;
            govReward.countOfProposals = countOfNewProposals;
            govReward.validPropIndexes.from = from;
            govReward.validPropIndexes.to = to;
            govReward.startPeriod = lastTimeGovRewardCheck;
            govReward.endPeriod = block.timestamp;

            govRewardsInfo.push(govReward);
            countOfGovernanceDistribution++;

            totalGameSupply += gameAmount;
            totalLottoSupply += lottoAmount;

            // set pointer for week number at the beginning
            weekNumber = 0;
        } else {
            // increase pointer if there are no valid proposals for the current week
            weekNumber++;
        }

        lastTimeGovRewardCheck = block.timestamp;
    }

    /// @notice Claim available governance reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimGovernanceReward() external override {
        address user = msg.sender;
        require(lastClaimedDistribution[user].lastClaimedGovernanceReward < govRewardsInfo.length, "NOTHING_TO_CLAIM");
        uint256 from = lastClaimedDistribution[user].lastClaimedGovernanceReward;
        if (lastClaimedDistribution[user].isGovNullIndexUsed){
            from+=1;
        }
        uint256 to = from + loopClaimLimit - 1;
        if (to >= govRewardsInfo.length){
            to = govRewardsInfo.length - 1;
        }
        (
            uint256 lottoRewards,
            uint256 gameRewards
        ) = _availableGovernanceReward(from, to, user);
        _claim(lottoRewards, gameRewards, user);

        lastClaimedDistribution[user].lastClaimedGovernanceReward = to;
        
        if (to >= 0){
            if(!lastClaimedDistribution[user].isCommNullIndexUsed)
                lastClaimedDistribution[user].isCommNullIndexUsed = true;
        }   
    }

    function _addDistribution(CommunityReward calldata distributionInfo)
        internal
    {
        // tokens transfer will be encoded in the games/token contract not here???
        rewardDistributionInfo.push(distributionInfo);
        uint256 rewardAmount = distributionInfo.amountForDistribution;
        distributionInfo.isMainLottoToken
            ? totalLottoSupply += rewardAmount
            : totalGameSupply += rewardAmount;
        countOfCommunityDistribution++;
        emit RewardDistributionAdded(
            msg.sender,
            RewardTypes.COMMUNITY,
            rewardAmount
        );
    }

    /// @notice Distribute amount of `lottoRewards` and `gameRewards` to the `user`
    /// @param lottoRewards amount of lotto rewards
    /// @param gameRewards amount of game rewards
    /// @param user address of user to transfer rewards to
    function _claim(
        uint256 lottoRewards,
        uint256 gameRewards,
        address user
    ) internal {
        require(
            lottoRewards != 0 || gameRewards != 0,
            "There is no available reward"
        );
        if (lottoRewards > 0) {
            lottoToken.safeTransfer(user, lottoRewards);
            totalLottoSupply -= lottoRewards;
            claimedLottoReward += lottoRewards;
            emit RewardClaimed(user, address(lottoToken), lottoRewards);
        }

        if (gameRewards > 0) {
            gameToken.safeTransfer(user, gameRewards);
            totalGameSupply -= gameRewards;
            claimedGameReward += gameRewards;
            emit RewardClaimed(user, address(gameToken), gameRewards);
        }
    }

    /// @notice Calculate available community reward for the user
    /// @param from lower limit of reward distribution
    /// @param to upper limit of reward distribution
    /// @param user address of user to calculate reward for
    function _availableCommunityReward(
        uint256 from,
        uint256 to,
        address user
    ) internal view returns (uint256, uint256) {
        uint256 totalLottoRewars;
        uint256 totalGameRewards;
        for (uint256 i = from; i <= to; i++) {            
                CommunityReward memory gameInfo = rewardDistributionInfo[i];
                uint256 reward = _communityRewardCondition(gameInfo, user);
                gameInfo.isMainLottoToken
                    ? totalLottoRewars += reward
                    : totalGameRewards += reward;
        }
        return (totalLottoRewars, totalGameRewards);
    }

    /// @notice Calculate available governance reward for the user
    /// @param from lower limit of reward distribution
    /// @param to upper limit of reward distribution
    /// @param user address of user to calculate reward for
    function _availableGovernanceReward(
        uint256 from,
        uint256 to,
        address user
    ) internal view returns (uint256 lottoRewards, uint256 gameRewards) {
        for (uint256 i = from; i <= to; i++) {
            GovernanceReward memory govRewards = govRewardsInfo[i];
            GovRewardIndexes memory indexes = govRewards.validPropIndexes;
            for (
                uint256 propIndex = indexes.from;
                propIndex <= indexes.to;
                propIndex++
            ) {
                IGovernance.Vote memory userVotes = governance
                    .getVoteOnProposal(propIndex, user);

                if (
                    userVotes.votingPower != 0 &&
                    userVotes.submitTimestamp >= govRewards.startPeriod &&
                    userVotes.submitTimestamp < govRewards.endPeriod
                ) {
                    (
                        uint256 lotto,
                        uint256 game
                    ) = _governanceRewardCondition(
                            govRewards,
                            i,
                            user,
                            propIndex
                        );
                    lottoRewards += lotto;
                    gameRewards += game;
                }
            }
        }
    }

    /// @notice Calculate user balance of lotto or game token in a specific point of time
    /// @param user address of user
    /// @param timestamp time in seconds needed to check balance at
    /// @param isMainLotto whether check balance of lotto token or not
    function _getUserBalance(
        address user,
        uint256 timestamp,
        bool isMainLotto
    ) internal view returns (uint256) {
        address token = address(isMainLotto ? lottoToken : gameToken);
        return ILotteryToken(token).getVotingPowerAt(user, timestamp);
    }

    /// @notice Check conditions needed for COMMUNITY reward distribution
    /// @param gameInfo info about reward distribution
    /// @param user address of user
    function _communityRewardCondition(
        CommunityReward memory gameInfo,
        address user
    ) internal view returns (uint256) {
        uint256 userBalance = _getUserBalance(
            user,
            gameInfo.timeOfGameFinish,
            gameInfo.isMainLottoToken
        );

        uint256 totalRewardSupply = gameInfo.isMainLottoToken ? totalLottoSupply : totalGameSupply; 
        uint256 totalUsersHoldingsExludingRewardsAmount = gameInfo.totalUsersHoldings - totalRewardSupply;
        
        if (userBalance == 0) return 0;
        return
            _calculateReward(
                userBalance,
                totalUsersHoldingsExludingRewardsAmount,
                gameInfo.amountForDistribution
            );
    }

    /// @notice Check conditions needed for GOVERNANCE reward distribution
    /// @param govRewards info about gov reward distribution
    /// @param user address of user
    /// @param indexOfProposal index of proposal to check if conditinon is passed for
    function _governanceRewardCondition(
        GovernanceReward memory govRewards,
        uint256 indexOfDistribution,
        address user,
        uint256 indexOfProposal
    ) internal view returns (uint256 lottoRewards, uint256 gameRewards) {
        IGovernance.ProposalWithoutVotes memory proposal = governance
            .getProposalById(indexOfProposal);
        uint256 lottoVotes = proposal.lottoVotes;
        uint256 gameVotes = proposal.gameVotes;

        // get balance firstly
        uint256 lottoBalance = _getUserBalance(
            user,
            proposal.startTimestamp,
            true
        );
        uint256 gameBalance = _getUserBalance(
            user,
            proposal.startTimestamp,
            false
        );

        VotingPowerInfo memory votesInfo = votingPowerForDistribution[
            indexOfProposal
        ][indexOfDistribution];

        // get rewards based on the voting power (lotto and game tokens)
        if (lottoBalance != 0) {
            lottoRewards = _calculateReward(
                lottoBalance,
                lottoVotes,
                votesInfo.isUpdated
                    ? votesInfo.lottoPower
                    : govRewards.lottoPerProposal
            );
        }
        if (gameBalance != 0) {
            gameRewards = _calculateReward(
                gameBalance,
                gameVotes,
                votesInfo.isUpdated
                    ? votesInfo.gamePower
                    : govRewards.gamePerProposal
            );
        }
    }

    /// @notice Calculate portion of rewards based on the input parameters
    /// @param userBalance balance of user
    /// @param totalUsersHolding amount of total users holdings
    /// @param amountToDistribute amount need to be distribute
    function _calculateReward(
        uint256 userBalance,
        uint256 totalUsersHolding,
        uint256 amountToDistribute
    ) internal pure returns (uint256) {
        uint256 percentOfHolding = (userBalance *
            ONE_HUNDRED_PERCENT_WITH_PRECISIONS) / totalUsersHolding;

        return
            (amountToDistribute * percentOfHolding) /
            ONE_HUNDRED_PERCENT_WITH_PRECISIONS;
    }

    /// @notice Update Governance pool amount to zero, transfer all existed pool amount
    /// for the governance rewards distribution, take 10% from the Extra pool on top
    /// for the governance reward.
    /// @return lottoAmount amount of lotto tokens for reward distribution
    /// @return gameAmount amount of game tokens for reward distribution
    function _updateGovernanceRewardPool()
        private
        returns (uint256 lottoAmount, uint256 gameAmount)
    {
        lottoAmount = governancePool.lottoAmount;
        gameAmount = governancePool.gameAmount;

        // nullify governancePool
        governancePool.lottoAmount = 0;
        governancePool.gameAmount = 0;

        // will send 10% of lotto and 10% game tokens on top to reward amount
        PoolInfo memory extraPoolValues = extraPool;

        if (extraPoolValues.lottoAmount != 0) {
            uint256 extraLotto = (extraPoolValues.lottoAmount * 1_000) / ONE_HUNDRED_PERCENT_WITH_PRECISIONS; //check  %%
            extraPool.lottoAmount -= extraLotto;
            lottoAmount += extraLotto;
        }

        if (extraPoolValues.gameAmount != 0) {
            uint256 extraGame = (extraPoolValues.gameAmount * 1_000) / ONE_HUNDRED_PERCENT_WITH_PRECISIONS; //check  %%
            extraPool.gameAmount -= extraGame;
            gameAmount += extraGame;
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract GovernancePool {

    struct PoolInfo {
        uint256 lottoAmount;
        uint256 gameAmount;
    }

    PoolInfo public governancePool;
    PoolInfo public extraPool;

    /// @notice number of current week 
    uint256 public weekNumber;

    /// @notice point if the address is game contract
    mapping(address => bool) public islotteryGame;

    modifier onlyLotteryGame() {
        require(islotteryGame[msg.sender], "Isn't game contract");
        _;
    }

    /// @notice increase amount of tokens in the pool for governnace reward
    /// @dev Accumulate Governnace pool in case of week number accumulation limit is up to 5
    /// in another case will accumulate Extra pool 
    /// @param lottoAmount amount of lotto tokens to be added to the pool
    /// @param gameAmount amount of game tokens to be added to the pool
    function replenishPool(uint256 lottoAmount, uint256 gameAmount)
        external
        onlyLotteryGame
    {
        if (weekNumber < 5) {
            governancePool.lottoAmount += lottoAmount;
            governancePool.gameAmount += gameAmount;
        } else {
            extraPool.lottoAmount += lottoAmount;
            extraPool.gameAmount += gameAmount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Defined interface for LotteryToken contract
interface ILotteryToken {

    ///@notice struct to store detailed info about the lottery
    struct Lottery {
        uint256 id;
        uint256 participationFee;
        uint256 startedAt;
        uint256 finishedAt;
        uint256 participants;
        address[] winners;
        uint256 epochId;
        uint256[] winningPrize;
        uint256 governanceReward;
        uint256 communityReward;
        address rewardPool;
        bool isActive;
    }

    ///@notice struct to store info about fees and participants in each epoch
    struct Epoch {
        uint256 totalFees;
        uint256 minParticipationFee;
        uint256 firstLotteryId;
        uint256 lastLotteryId;
    }

    ///@notice struct to store info about user balance based on the last game id interaction
    struct UserBalance {
        uint256 lastGameId;
        uint256 balance;
        uint256 at;
    }

    /// @notice Emit when voting power of 'account' is changed to 'newVotes'
    /// @param account address of user whose voting power is changed
    /// @param newVotes new amount of voting power for 'account'
    event VotingPowerChanged(address account, uint256 newVotes);

    /// @notice Emit when reward pool is changed
    /// @param rewardPool address of new reward pool
    event RewardPoolChanged(address rewardPool);

    /// @notice A checkpoint for marking historical number of votes from a given block timestamp
    struct Snapshot {
        uint256 blockTimestamp;
        uint256 votes;
    }

    function rewardPool() external view returns(address);

    /// @dev disable transfers
    /// can be called by lottery game contract only
    function lockTransfer() external;

    /// @dev enable transfers
    /// can be called by lottery game contract only
    function unlockTransfer() external;

    /// @dev start new game
    /// @param _participationFee amount of tokens needed to participaint in the game
    function startLottery(uint256 _participationFee)
        external
        returns (Lottery memory startedLottery);

    /// @dev finish game
    /// @param _participants count of participants
    /// @param _winnerAddresses address of winner
    /// @param _marketingAddress marketing address
    /// @param _winningPrizeValues amount of winning prize in tokens
    /// @param _marketingFeeValue amount of marketing fee in tokens
    function finishLottery(
        uint256 _participants,
        address[] memory _winnerAddresses,
        address _marketingAddress,
        uint256[] memory _winningPrizeValues,
        uint256 _marketingFeeValue,
        uint256 _governanceReward,
        uint256 _communityReward
    ) external returns (Lottery memory finishedLotteryGame);

    /// @notice Set address of reward pool to accumulate governance and community rewards at
    /// @dev Can be called only by lottery game contract
    /// @param _rewardPool address of reward distribution contract
    function setRewardPool(address _rewardPool) external;

    /// @dev Returns last lottery
    function lastLottery() external view returns (Lottery memory lottery);

    /// @dev Returns last epoch
    function lastEpoch() external view returns (Epoch memory epoch);

    /// @dev Return voting power of the 'account' at the specific period of time 'blockTimestamp'
    /// @param account address to check voting power for
    /// @param blockTimestamp timestamp in second to check voting power at
    function getVotingPowerAt(address account, uint256 blockTimestamp)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ILotteryGameToken {
    /// @notice A checkpoint for marking historical number of votes from a given block timestamp
    struct Snapshot {
        uint256 blockTimestamp;
        uint256 votes;
    }

    /// @notice Emit when voting power of 'account' is changed to 'newVotes'
    /// @param account address of user whose voting power is changed
    /// @param newVotes new amount of voting power for 'account'
    event VotingPowerChanged(address indexed account, uint256 newVotes);

    /// @notice Mint 'amount' of tokens for the 'account'
    /// @param account address of the user to mint tokens for
    /// @param amount amount of minted tokens
    function mint(address account, uint256 amount) external;

    /// @notice Burn 'amount' of tokens for the 'account'
    /// @dev Can be burn only allowed address. User can't burn his tokens by hisself
    /// @param account address of the user to burn tokens for
    /// @param amount amount of burned tokens
    function burn(address account, uint256 amount) external;

    
    /// @dev Return voting power of the 'account' at the specific period of time 'blockTimestamp'
    /// @param account address to check voting power for
    /// @param blockTimestamp timestamp in second to check voting power at
    function getVotingPowerAt(address account, uint256 blockTimestamp)
        external
        view
        returns (uint256);

    
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

interface IRewardDistribution {

    /// @notice rewards types
    enum RewardTypes {
        COMMUNITY,
        GOVERNANCE
    }

    /// @notice Info needed to store community reward distribution
    struct CommunityReward {
        uint256 timeOfGameFinish;
        uint256 countOfHolders;
        uint256 totalUsersHoldings;
        uint256 amountForDistribution;
        bool isMainLottoToken;
    }

    /// @notice Voting power info
    struct VotingPowerInfo {
        uint256 lottoPower;
        uint256 gamePower;
        bool isUpdated;
    }

    /// @notice Info about last distribution index
    struct LastProposalIndexInfo {
        uint256 index;
        // need this to handle case when the prev index will be 0 and count of proposals will be 1
        uint256 prevCountOfProposals;
    }

    /// @notice Info about indexes of valid proposals for the governance reward distribution
    struct GovRewardIndexes {
        uint256 from;
        uint256 to;
    }

      /// @notice Info about indexes of valid proposals for the governance reward distribution
    struct ClaimedIndexes {
        uint256 lastClaimedCommunityReward;
        uint256 lastClaimedGovernanceReward;
        bool isCommNullIndexUsed;
        bool isGovNullIndexUsed;
    }

    /// @notice Info needed to store governance reward distribution
    struct GovernanceReward {
        uint256 startPeriod;
        uint256 endPeriod;
        uint256 totalLottoAmount;
        uint256 totalGameAmount;
        uint256 lottoPerProposal;
        uint256 gamePerProposal;
        uint256 totalUsersHoldings;
        uint256 countOfProposals;
        GovRewardIndexes validPropIndexes;
    }

    /// @notice Emit when new lottery game is added
    /// @param lotteryGame address of lotteryGame contract
    event LotteryGameAdded(address indexed lotteryGame);

    /// @notice Emit when new lottery game is removed
    /// @param lotteryGame address of lotteryGame contract
    event LotteryGameRemoved(address indexed lotteryGame);

    /// @notice Emit when new reward distribution is added
    /// @param fromGame address of lotteryGame contract who added a distribution
    /// @param rewardType type of reward 
    /// @param amountForDistribution amount of tokens for distribution
    event RewardDistributionAdded(
        address indexed fromGame,
        RewardTypes rewardType,
        uint256 amountForDistribution
    );

    /// @notice Emit when new reward distribution is added
    /// @param user address of user who claim the tokens
    /// @param distributedToken address of token what is claimed 
    /// @param amount amount of tokens are claimed
    event RewardClaimed(
        address indexed user,
        address indexed distributedToken,
        uint256 indexed amount
    );

    /// @notice Add new game to the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of new game contract
    function addNewGame(address game_) external;

    /// @notice Remove registrated game from the list
    /// @dev Allowed to be called only by gameFactory or governance
    /// @param game_ address of game to be removed
    function removeGame(address game_) external;

    /// @notice Add new community reward distribution portion
    /// @dev Allowed to be called only by authorized game contracts
    /// @param distributionInfo structure of <CommunityReward> type
    function addDistribution(CommunityReward calldata distributionInfo)
        external;

    /// @notice Claim available community reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimCommunityReward() external;

    /// @notice Claim available reward for the fucntion caller
    /// @dev Do not claim all available reward for the user.
    /// To avoid potential exceeding of block gas limit there is  some top limit of index.
    function claimGovernanceReward() external;

    /// @notice Return available community reward of user
   /// @param user address need check rewards for 
    function availableCommunityReward(address user)
        external
        view
        returns (uint256 lottoRewards, uint256 gameRewards);

    /// @notice Return available community reward of user
   /// @param user address need check rewards for 
    function availableGovernanceReward(address user)
        external
        view
        returns (uint256 lottoRewards, uint256 gameRewards);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IExecutor.sol";

interface IGovernance {
    /**
     * @dev List of available states of proposal
     * @param Pending When the proposal is creted and the votingDelay is not passed
     * @param Canceled When the proposal is calceled
     * @param   Active When the proposal is on voting
     * @param  Failed Whnen the proposal is not passes the quorum
     * @param  Succeeded When the proposal is passed
     * @param   Expired When the proposal is expired (the execution period passed)
     * @param  Executed When the proposal is executed
     **/
    enum ProposalState {
        Pending,
        Canceled,
        Active,
        Failed,
        Succeeded,
        Expired,
        Executed
    }

    /**
     * @dev Struct of a votes
     * @param support is the user suport proposal or not
     * @param votingPower amount of voting  power
     * @param submitTimestamp date when vote was submitted
     **/
    struct Vote {
        bool support;
        uint248 votingPower;
        uint256 submitTimestamp;
    }

    /**
     * @dev Struct of a proposal with votes
     * @param id Id of the proposal
     * @param creator Creator address
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block.timestamp when the proposal was started
     * @param endTimestamp block.timestamp when the proposal will ended
     * @param executionTime block.timestamp of the minimum time when the propsal can be execution, if set 0 it can't be executed yet
     * @param forVotes amount of For votes
     * @param againstVotes amount of Against votes
     * @param executed true is proposal is executes, false if proposal is not executed
     * @param canceled true is proposal is canceled, false if proposal is not canceled
     * @param strategy the address of governanceStrategy contract for current proposal voting power calculation
     * @param ipfsHash IPFS hash of the proposal
     * @param lottoVotes lotto tokens voting power portion
     * @param gameVotes game tokens voting power portion
     * @param votes the Vote struct where is hold mapping of users who voted for the proposal
     **/
    struct Proposal {
        uint256 id;
        address creator;
        IExecutor executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
        mapping(address => Vote) votes;
    }

    /**
     * @dev Struct of a proposal without votes
     * @param id Id of the proposal
     * @param creator Creator address
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block.timestamp when the proposal was started
     * @param endTimestamp block.timestamp when the proposal will ended
     * @param executionTime block.timestamp of the minimum time when the propsal can be execution, if set 0 it can't be executed yet
     * @param forVotes amount of For votes
     * @param againstVotes amount of Against votes
     * @param executed true is proposal is executes, false if proposal is not executed
     * @param canceled true is proposal is canceled, false if proposal is not canceled
     * @param strategy the address of governanceStrategy contract for current proposal voting power calculation
     * @param ipfsHash IPFS hash of the proposal
     * @param lottoVotes lotto tokens voting power portion
     * @param gameVotes game tokens voting power portion
     **/
    struct ProposalWithoutVotes {
        uint256 id;
        address creator;
        IExecutor executor;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 executionTime;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        bool canceled;
        address strategy;
        bytes32 ipfsHash;
        uint256 lottoVotes;
        uint256 gameVotes;
    }

    /**
     * @dev emitted when a new proposal is created
     * @param id Id of the proposal
     * @param creator address of the creator
     * @param executor The ExecutorWithTimelock contract that will execute the proposal
     * @param targets list of contracts called by proposal's associated transactions
     * @param values list of value in wei for each propoposal's associated transaction
     * @param signatures list of function signatures (can be empty) to be used when created the callData
     * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param startTimestamp block number when vote starts
     * @param endTimestamp block number when vote ends
     * @param strategy address of the governanceStrategy contract
     * @param ipfsHash IPFS hash of the proposal
     **/
    event ProposalCreated(
        uint256 id,
        address indexed creator,
        IExecutor indexed executor,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 executionTimestamp,
        address strategy,
        bytes32 ipfsHash
    );

    /**
     * @dev emitted when a proposal is canceled
     * @param id Id of the proposal
     **/
    event ProposalCanceled(uint256 id);

    /**
     * @dev emitted when a proposal is executed
     * @param id Id of the proposal
     * @param initiatorExecution address of the initiator of the execution transaction
     **/
    event ProposalExecuted(uint256 id, address indexed initiatorExecution);
    /**
     * @dev emitted when a vote is registered
     * @param id Id of the proposal
     * @param voter address of the voter
     * @param support boolean, true = vote for, false = vote against
     * @param votingPower Power of the voter/vote
     **/
    event VoteEmitted(
        uint256 id,
        address indexed voter,
        bool support,
        uint256 votingPower
    );

    /**
     * @dev emitted when a new governance strategy set
     * @param newStrategy address of new strategy
     * @param initiatorChange msg.sender address
     **/
    event GovernanceStrategyChanged(
        address indexed newStrategy,
        address indexed initiatorChange
    );

    /**
     * @dev emitted when a votingDelay is changed
     * @param newVotingDelay new voting delay in seconds
     * @param initiatorChange msg.sender address
     **/
    event VotingDelayChanged(
        uint256 newVotingDelay,
        address indexed initiatorChange
    );

    /**
     * @dev emitted when a executor is authorized
     * @param executor new address of executor
     **/
    event ExecutorAuthorized(address executor);
    /**
     * @dev emitted when a executor is unauthorized
     * @param executor  address of executor
     **/
    event ExecutorUnauthorized(address executor);

    /**
     * @dev emitted when a community reward percent is changed
     * @param communityReward  percent of community reward
     **/
    event CommunityRewardChanged(uint256 communityReward);

    /**
     * @dev emitted when a governance reward percent is changed
     * @param governanceReward  percent of governance reward
     **/
    event GovernanceRewardChanged(uint256 governanceReward);

    /**
     * @dev Creates a Proposal (needs Voting Power of creator > propositionThreshold)
     * @param executor - The Executor contract that will execute the proposal
     * @param targets - list of contracts called by proposal's associated transactions
     * @param values - list of value in wei for each propoposal's associated transaction
     * @param signatures - list of function signatures (can be empty) to be used when created the callData
     * @param calldatas - list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
     * @param ipfsHash - IPFS hash of the proposal
     **/
    function createProposal(
        IExecutor executor,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bytes32 ipfsHash
    ) external returns (uint256);

    /**
     * @dev Cancels a Proposal,
     * either at anytime by guardian
     * or when proposal is Pending/Active and threshold of creator no longer reached
     * @param proposalId id of the proposal
     **/
    function cancelProposal(uint256 proposalId) external;
    /**
     * @dev Execute the proposal (If Proposal Succeeded)
     * @param proposalId id of the proposal to execute
     **/
    function executeProposal(uint256 proposalId) external payable;

    /**
     * @dev Function allowing msg.sender to vote for/against a proposal
     * @param proposalId id of the proposal
     * @param support boolean, true = vote for, false = vote against
     **/
    function submitVote(uint256 proposalId, bool support) external;

    /**
     * @dev Set new GovernanceStrategy
     * @notice owner should be a  executor, so needs to make a proposal
     * @param governanceStrategy new Address of the GovernanceStrategy contract
     **/
    function setGovernanceStrategy(address governanceStrategy) external;

    /**
     * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
     * @notice owner should be a  executor, so needs to make a proposal
     * @param votingDelay new voting delay in seconds
     **/
    function setVotingDelay(uint256 votingDelay) external;

    /**
     * @dev Add new addresses to the list of authorized executors
     * @notice owner should be a  executor, so needs to make a proposal
     * @param executors list of new addresses to be authorized executors
     **/
    function authorizeExecutors(address[] calldata executors) external;

    /**
     * @dev Remove addresses from the list of authorized executors
     * @notice owner should be a  executor, so needs to make a proposal
     * @param executors list of addresses to be removed as authorized executors
     **/
    function unauthorizeExecutors(address[] calldata executors) external;

    /**
     * @dev Let the guardian abdicate from its priviledged rights.Set _guardian address as zero address
     * @notice can be called only by _guardian
     **/
    function abdicate() external;

    /**
     * @dev Getter of the current GovernanceStrategy address
     * @return The address of the current GovernanceStrategy contract
     **/
    function getGovernanceStrategy() external view returns (address);

    /**
     * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
     * Different from the voting duration
     * @return The voting delay in seconds
     **/
    function getVotingDelay() external view returns (uint256);

    /**
     * @dev Returns whether an address is an authorized executor
     * @param executor address to evaluate as authorized executor
     * @return true if authorized, false is not authorized
     **/
    function isExecutorAuthorized(address executor)
        external
        view
        returns (bool);

    /**
     * @dev Getter the address of the guardian, that can mainly cancel proposals
     * @return The address of the guardian
     **/
    function getGuardian() external view returns (address);

    /**
     * @dev Getter of the proposal count (the current number of proposals ever created)
     * @return the proposal count
     **/
    function getProposalsCount() external view returns (uint256);

    /**
     * @dev Getter of a proposal by id
     * @param proposalId id of the proposal to get
     * @return the proposal as ProposalWithoutVotes memory object
     **/
    function getProposalById(uint256 proposalId)
        external
        view
        returns (ProposalWithoutVotes memory);

    /**
     * @dev Getter of the Vote of a voter about a proposal
     * @notice Vote is a struct: ({bool support, uint248 votingPower})
     * @param proposalId id of the proposal
     * @param voter address of the voter
     * @return The associated Vote memory object
     **/
    function getVoteOnProposal(uint256 proposalId, address voter)
        external
        view
        returns (Vote memory);

    /**
     * @dev Get the current state of a proposal
     * @param proposalId id of the proposal
     * @return The current state if the proposal
     **/
    function getProposalState(uint256 proposalId)
        external
        view
        returns (ProposalState);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// day of week
/**
   1 - monday
   2 - tuesday
   3 - wednesday
   4 - thursday
   5 - friday
   6 - saturday
   7 - sunday

   hour should be in unix - so if you would need 20:00 EST you should set 15 (- 5 hours)

 */
contract DateTime {
    /*
     *  Date and Time utilities for ethereum contracts
     *
     */
    struct DateTimeStruct {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    struct TimelockForLotteryGame {
        uint8[] daysUnlocked;
        uint8[] hoursStartUnlock;
        uint256[] unlockDurations;
    }

    mapping(address => TimelockForLotteryGame) private timelocks;

    constructor(address lotteryGame, TimelockForLotteryGame memory timelock) {
        timelocks[lotteryGame] = timelock;
    }

    function getTimelock(address lotteryGame)
        external
        view
        returns (TimelockForLotteryGame memory)
    {
        return timelocks[lotteryGame];
    }

    function setTimelock(
        address lotteryGame,
        TimelockForLotteryGame memory timelock
    ) external {
        timelocks[lotteryGame] = timelock;
    }

    uint256 private constant DAY_IN_SECONDS = 86400;
    uint256 private constant YEAR_IN_SECONDS = 31536000;
    uint256 private constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 private constant HOUR_IN_SECONDS = 3600;
    uint256 private constant MINUTE_IN_SECONDS = 60;

    uint16 private constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year)
        public
        pure
        returns (uint8)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp)
        internal
        pure
        returns (DateTimeStruct memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor +=
            YEAR_IN_SECONDS *
            (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
pragma solidity 0.8.9;

import "./IGovernance.sol";

interface IExecutor {
    /**
     * @dev emitted when a new pending admin is set
     * @param newPendingAdmin address of the new pending admin
     **/
    event NewPendingAdmin(address newPendingAdmin);

    /**
     * @dev emitted when a new admin is set
     * @param newAdmin address of the new admin
     **/
    event NewAdmin(address newAdmin);

    /**
     * @dev emitted when an action is Cancelled
     * @param actionHash hash of the action
     * @param target address of the targeted contract
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     * @param resultData the actual callData used on the target
     **/
    event ExecutedAction(
        bytes32 actionHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 executionTime,
        bytes resultData
    );

    /**
     * @dev Getter of the current admin address (should be governance)
     * @return The address of the current admin
     **/
    function getAdmin() external view returns (address);

    /**
     * @dev Getter of the current pending admin address
     * @return The address of the pending admin
     **/
    function getPendingAdmin() external view returns (address);

    /**
     * @dev Checks whether a proposal is over its grace period
     * @param governance Governance contract
     * @param proposalId Id of the proposal against which to test
     * @return true of proposal is over grace period
     **/
    function isProposalOverExecutionPeriod(
        IGovernance governance,
        uint256 proposalId
    ) external view returns (bool);

    /**
     * @dev Getter of execution period constant
     * @return grace period in seconds
     **/
    function executionPeriod() external view returns (uint256);

    /**
     * @dev Function, called by Governance, that cancels a transaction, returns the callData executed
     * @param target smart contract target
     * @param value wei value of the transaction
     * @param signature function signature of the transaction
     * @param data function arguments of the transaction or callData if signature empty
     * @param executionTime time at which to execute the transaction
     **/
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 executionTime
    ) external payable returns (bytes memory);
}