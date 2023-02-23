// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IBuyback.sol";
import "./interfaces/IMnt.sol";
import "./libraries/PauseControl.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

contract Buyback is IBuyback, Initializable, AccessControl, PauseControl, InterconnectorLeaf {
    using SafeERC20Upgradeable for IMnt;
    using SafeCast for uint256;

    struct ParticipantInfo {
        bool participating; /// Flag that marks account as legally participating in Buyback
        uint32 lastStakeInBlock; /// Block when last stake was made
        uint32 loyaltyStart; /// Start timestamp of the loyalty rewards functionality
        uint256 weight; /// Last calculated buyback weight of the user
        uint256 lastIndex; /// Buyback index from the last buyback claim
        uint256 lastBalance; /// The last account's balance was locked in protocol contracts.
        uint256 coreBalance; /// Minimal amount of MNTs the participant should preserve to save current loyalty factor
    }

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Role that's allowed to initiate buyback
    /// @dev Value is the Keccak-256 hash of "DISTRIBUTOR"
    bytes32 public constant DISTRIBUTOR = bytes32(0x85faced7bde13e1a7dad704b895f006e704f207617d68166b31ba2d79624862d);

    uint256 internal constant INDEX_SCALE = 1e36;
    uint256 internal constant LOYALTY_SCALE = 1e18;
    uint32 internal constant STRATA_NUMBER = 24;
    uint32 internal constant STRATUM_DURATION = (60 * 60 * 24 * 365) / 24; // 1,314,000 seconds (half a month)

    IMnt public mnt;
    ISupervisor public supervisor;
    IRewardsHub public rewardsHub;

    mapping(address => ParticipantInfo) internal participants;

    // Buyback storage

    mapping(address => uint256) internal stakes;
    uint256 internal totalWeight;
    uint256 internal buybackIndex;

    // Loyalty factor storage

    uint256[STRATA_NUMBER] internal loyaltyStrata; /// Array of loyalty factors per stratum
    uint256[] internal loyaltyGroupThresholds; /// MNT tokens required to get into the loyalty group
    uint32[] internal loyaltyGroupStartStrata; /// Array of strata indexes each loyalty group begins with
    uint256 internal loyaltyCoreFactor; /// Portion of balance increase that goes to the core balance
    uint32 internal coreResetPenalty; /// Amount of groups account will lose in case of their core reset

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin_,
        IMnt mnt_,
        ISupervisor supervisor_,
        IRewardsHub rewardsHub_,
        uint256 loyaltyCoreFactor_,
        uint32 coreResetPenalty_,
        uint256[STRATA_NUMBER] memory loyaltyStrata_,
        uint256[] memory loyaltyGroupThresholds_,
        uint32[] memory loyaltyGroupStartStrata_
    ) external initializer {
        supervisor = supervisor_;
        mnt = mnt_;
        rewardsHub = rewardsHub_;

        require(loyaltyCoreFactor_ < LOYALTY_SCALE, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
        require(
            loyaltyGroupThresholds_.length == loyaltyGroupStartStrata_.length,
            ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL
        );
        require(loyaltyGroupStartStrata_[0] == 0, ErrorCodes.BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO);

        loyaltyCoreFactor = loyaltyCoreFactor_;
        coreResetPenalty = coreResetPenalty_;

        for (uint256 i = 0; i < STRATA_NUMBER; i++) {
            require(loyaltyStrata_[i] < LOYALTY_SCALE, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
            loyaltyStrata[i] = loyaltyStrata_[i];
        }

        loyaltyGroupThresholds = new uint256[](loyaltyGroupThresholds_.length);
        loyaltyGroupStartStrata = new uint32[](loyaltyGroupThresholds_.length);
        for (uint256 i = 0; i < loyaltyGroupThresholds_.length; i++) {
            require(loyaltyGroupStartStrata_[i] < STRATA_NUMBER);
            loyaltyGroupThresholds[i] = loyaltyGroupThresholds_[i];
            loyaltyGroupStartStrata[i] = loyaltyGroupStartStrata_[i];
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(DISTRIBUTOR, admin_);
    }

    /// @inheritdoc IBuyback
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 stakeAmount
        )
    {
        return (
            participants[account].participating,
            participants[account].weight,
            participants[account].lastIndex,
            stakes[account]
        );
    }

    /// @inheritdoc IBuyback
    function getLoyaltyInfo(address account)
        external
        view
        returns (
            uint32,
            uint256,
            uint256
        )
    {
        ParticipantInfo memory info = participants[account];
        return (info.loyaltyStart, info.coreBalance, info.lastBalance);
    }

    /// @inheritdoc IBuyback
    function isParticipating(address account) public view returns (bool) {
        return participants[account].participating;
    }

    /// @inheritdoc IBuyback
    function getStakedAmount(address account) external view returns (uint256) {
        return stakes[account];
    }

    /// @inheritdoc IBuyback
    function getWeight(address account) external view returns (uint256) {
        return participants[account].weight;
    }

    /// @inheritdoc IBuyback
    function getTotalWeight() external view returns (uint256) {
        return totalWeight;
    }

    /// @inheritdoc IBuyback
    function getBuybackIndex() external view returns (uint256) {
        return buybackIndex;
    }

    /// @inheritdoc IBuyback
    function getLoyaltyFactorForBalance(address account, uint256 balance) public view returns (uint256) {
        if (balance < loyaltyGroupThresholds[0]) return 0;

        uint32 loyaltyStart = participants[account].loyaltyStart;
        if (loyaltyStart == 0) return 0;

        uint32 deltaTime = getTimestamp() - loyaltyStart;
        if (deltaTime < STRATUM_DURATION) return 0;

        return loyaltyStrata[_findStratumIndex(deltaTime, balance)];
    }

    /// @inheritdoc IBuyback
    function getLoyaltyParameters()
        external
        view
        returns (
            uint256[STRATA_NUMBER] memory,
            uint256[] memory,
            uint32[] memory,
            uint256,
            uint32
        )
    {
        return (loyaltyStrata, loyaltyGroupThresholds, loyaltyGroupStartStrata, loyaltyCoreFactor, coreResetPenalty);
    }

    // // // // Buyback // // // //

    /// @inheritdoc IBuyback
    function stake(uint256 amount) external checkPaused(STAKE_OP) {
        require(whitelist().isWhitelisted(msg.sender), ErrorCodes.WHITELISTED_ONLY);
        require(isParticipating(msg.sender), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);
        require(supervisor.isNotBlacklisted(msg.sender), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        ParticipantInfo storage info = participants[msg.sender];

        // Accounts should not receive higher loyalty factors if they are entering new
        // loyalty group via stake after long period of inactivity. In that case their
        // new loyalty factor would be at the start of their new group.
        //
        // To achieve that we should update weights and loyalties before stake, then
        // check condition of entering new group and in that case reset accounts loyaltyStart.
        updateBuybackAndVotingWeights(msg.sender);

        uint256 lastBalance = info.lastBalance;
        uint32 prevGroup = _findGroupByBalance(lastBalance);
        uint32 newGroup = _findGroupByBalance(lastBalance + amount);
        if (newGroup > prevGroup) {
            uint32 newGroupStratum = loyaltyGroupStartStrata[newGroup];
            // May underflow if timestamp is less than a year from Unix epoch %).
            uint32 toGroupStart = getTimestamp() - (newGroupStratum + 1) * STRATUM_DURATION;
            // Use <highest start timestamp> that equals to <lowest delta time>
            // This part actually checks that account has enough delta time for the new group.
            if (toGroupStart > info.loyaltyStart) info.loyaltyStart = toGroupStart;
        }

        stakes[msg.sender] += amount;
        info.lastStakeInBlock = block.number.toUint32();

        emit Stake(msg.sender, amount);

        updateBuybackAndVotingWeightsRelaxed(msg.sender);
        mnt.safeTransferFrom(msg.sender, address(this), amount);
    }

    /// @inheritdoc IBuyback
    function unstake(uint256 amount) external checkPaused(UNSTAKE_OP) {
        require(amount > 0, ErrorCodes.INCORRECT_AMOUNT);

        require(block.number > participants[msg.sender].lastStakeInBlock, ErrorCodes.BB_UNSTAKE_TOO_EARLY);

        // Check if the sender is a member of the Buyback system
        bool isSenderParticipating = participants[msg.sender].participating;
        uint256 staked = stakes[msg.sender];

        if (amount == type(uint256).max || amount == staked) {
            amount = staked;
            delete stakes[msg.sender];
        } else {
            require(amount < staked, ErrorCodes.INSUFFICIENT_STAKE);
            stakes[msg.sender] = staked - amount;
        }

        emit Unstake(msg.sender, amount);

        // Update weights of the sender if he participates in the Buyback system
        if (isSenderParticipating) {
            updateBuybackAndVotingWeights(msg.sender);
        }

        mnt.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IBuyback
    function buyback(uint256 amount) external onlyRole(DISTRIBUTOR) {
        require(amount > 0, ErrorCodes.NOTHING_TO_DISTRIBUTE);
        require(totalWeight > 0, ErrorCodes.NOT_ENOUGH_PARTICIPATING_ACCOUNTS);
        require(address(rewardsHub) != address(0));

        uint256 shareMantissa = (amount * INDEX_SCALE) / totalWeight;
        buybackIndex += shareMantissa;

        emit NewBuyback(amount, shareMantissa);

        mnt.safeTransferFrom(msg.sender, address(rewardsHub), amount);
    }

    /// @inheritdoc IBuyback
    function participate() external {
        require(supervisor.isNotBlacklisted(msg.sender), ErrorCodes.ADDRESS_IS_BLACKLISTED);
        require(!isParticipating(msg.sender), ErrorCodes.ALREADY_PARTICIPATING_IN_BUYBACK);

        participants[msg.sender].participating = true;
        emit ParticipateBuyback(msg.sender);

        updateBuybackAndVotingWeights(msg.sender);
    }

    /// @inheritdoc IBuyback
    function leave() external {
        _leave(msg.sender);
    }

    /// @inheritdoc IBuyback
    function leaveByAmlDecision(address participant) external {
        require(!supervisor.isNotBlacklisted(participant), ErrorCodes.ADDRESS_IS_NOT_IN_AML_SYSTEM);
        _leave(participant);
    }

    function _leave(address participant) internal checkPaused(LEAVE_OP) {
        require(isParticipating(participant), ErrorCodes.NOT_PARTICIPATING_IN_BUYBACK);

        _claimReward(participant);

        totalWeight -= participants[participant].weight;

        // Deletes all weight and loyalty info
        delete participants[participant];

        // Do not delete stakes here!

        emit LeaveBuyback(participant, stakes[participant]);

        mnt.updateVotingWeight(participant);
    }

    /// @inheritdoc IBuyback
    function updateBuybackAndVotingWeights(address account) public {
        if (!isParticipating(account)) return;
        require(!isOperationPaused(UPDATE_OP, address(0)), ErrorCodes.OPERATION_PAUSED);
        _updateWeights(account);
    }

    /// @inheritdoc IBuyback
    function updateBuybackAndVotingWeightsRelaxed(address account) public {
        if (!isParticipating(account)) return;
        if (isOperationPaused(UPDATE_OP, address(0))) return;
        _updateWeights(account);
    }

    function _updateWeights(address account) internal {
        _claimReward(account);

        ParticipantInfo storage info = participants[account];
        uint256 oldWeight = info.weight;
        // slither-disable-next-line reentrancy-no-eth

        uint256 newBalance = weightAggregator().getAccountFunds(account);
        _updateLoyaltyFactor(account, newBalance);

        uint256 loyaltyFactor = getLoyaltyFactorForBalance(account, newBalance);
        uint256 newWeight = newBalance + (newBalance * loyaltyFactor) / LOYALTY_SCALE;

        if (newWeight != oldWeight) {
            uint256 newTotal = totalWeight + newWeight - oldWeight;
            info.weight = newWeight;
            totalWeight = newTotal;
            emit BuybackWeightChanged(account, newWeight, oldWeight, newTotal);
        }

        mnt.updateVotingWeight(account);
    }

    function _claimReward(address account) internal {
        ParticipantInfo storage info = participants[account];

        uint256 currentBuybackIndex = buybackIndex;
        uint256 accountIndex = info.lastIndex;
        if (accountIndex >= currentBuybackIndex) return;

        info.lastIndex = currentBuybackIndex; // We should update buyback index even if weight is zero

        uint256 deltaIndex = currentBuybackIndex - accountIndex;
        uint256 rewardMnt = (info.weight * deltaIndex) / INDEX_SCALE;

        // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
        rewardsHub.accrueBuybackReward(account, rewardMnt);
    }

    // // // // Loyalty factor // // // //

    function _updateLoyaltyFactor(address account, uint256 newBalance) internal {
        ParticipantInfo storage info = participants[account];

        uint256 lastBalance = info.lastBalance;
        if (newBalance == lastBalance) return;

        uint256 baseThreshold = loyaltyGroupThresholds[0];
        if (newBalance < baseThreshold) {
            if (lastBalance >= baseThreshold) _leaveLoyalty(account);
            return;
        }

        if (newBalance > lastBalance) _accrueLoyalty(account, lastBalance, newBalance);
        else _withdrawLoyalty(account, newBalance);

        info.lastBalance = newBalance;
    }

    function _accrueLoyalty(
        address account,
        uint256 lastBalance,
        uint256 newBalance
    ) internal {
        ParticipantInfo storage info = participants[account];

        if (lastBalance == 0) {
            // We update lastBalance only when balance > baseThreshold.
            // This way in the first time it reaches threshold delta
            // would be equal to (newBalance - 0).
            info.loyaltyStart = getTimestamp();
        }

        uint256 deltaBalance = newBalance - lastBalance;
        uint256 coreIncrease = (deltaBalance * loyaltyCoreFactor) / LOYALTY_SCALE;
        info.coreBalance += coreIncrease.toUint224();
    }

    function _withdrawLoyalty(address account, uint256 newBalance) internal {
        ParticipantInfo storage info = participants[account];

        if (newBalance > info.coreBalance) return;

        uint32 rightNow = getTimestamp();
        uint32 deltaTime = rightNow - info.loyaltyStart;
        uint32 newLoyaltyStart = rightNow;

        if (deltaTime >= STRATUM_DURATION) {
            uint32 currentStratum = _findStratumIndex(deltaTime, newBalance);
            uint32 groupAtStratum = _findGroupByStratum(currentStratum);
            uint32 resetToStratum = groupAtStratum >= coreResetPenalty
                ? loyaltyGroupStartStrata[groupAtStratum - coreResetPenalty]
                : 0;

            // Add 1 to stratum to counteract first month (0 stratum is on the 1st month)
            newLoyaltyStart -= (resetToStratum + 1) * STRATUM_DURATION;
        }
        info.loyaltyStart = newLoyaltyStart;

        uint256 newCoreBalance = (newBalance * loyaltyCoreFactor) / LOYALTY_SCALE;
        info.coreBalance = newCoreBalance.toUint224();
    }

    function _leaveLoyalty(address account) internal {
        ParticipantInfo storage info = participants[account];

        // Clear only loyalty related values
        info.loyaltyStart = 0;
        info.lastBalance = 0;
        info.coreBalance = 0;
    }

    /// @dev deltaTime should be >= STRATUM_DURATION
    function _findStratumIndex(uint32 deltaTime, uint256 balance) internal view returns (uint32) {
        // Stratum by time. Skips zero month
        uint32 stratumIndex = deltaTime / STRATUM_DURATION - 1;
        uint32 balanceGroup = _findGroupByBalance(balance);

        // Skip last group because it has no limit
        if (balanceGroup < loyaltyGroupThresholds.length - 1) {
            uint32 nextGroupStratum = loyaltyGroupStartStrata[balanceGroup + 1];
            if (stratumIndex >= nextGroupStratum) stratumIndex = nextGroupStratum - 1;
        }

        // Don't let to overflow if user in the last group for too long
        if (stratumIndex >= STRATA_NUMBER) return STRATA_NUMBER - 1;

        return stratumIndex;
    }

    /// @dev assuming that balance is greater that the base threshold
    function _findGroupByBalance(uint256 balance) internal view returns (uint32) {
        uint32 len = loyaltyGroupThresholds.length.toUint32();
        for (uint32 i = 1; i < len; i++) {
            if (balance < loyaltyGroupThresholds[i]) return i - 1;
        }
        return len - 1;
    }

    function _findGroupByStratum(uint32 stratum) internal view returns (uint32) {
        uint32 len = loyaltyGroupThresholds.length.toUint32();
        for (uint32 i = 1; i < len; i++) {
            if (stratum < loyaltyGroupStartStrata[i]) return i - 1;
        }
        return len - 1;
    }

    // // // // Admin zone // // // //

    /// @inheritdoc IBuyback
    function participateOnBehalf(address[] memory accounts) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(buybackIndex == 0, ErrorCodes.BUYBACK_DRIPS_ALREADY_HAPPENED);
        for (uint256 i = 0; i < accounts.length; i++) {
            require(supervisor.isNotBlacklisted(accounts[i]), ErrorCodes.ADDRESS_IS_BLACKLISTED);
            participants[accounts[i]].participating = true;
            emit ParticipateBuyback(accounts[i]);
        }
    }

    /// @inheritdoc IBuyback
    function leaveOnBehalf(address participant) external onlyRole(GATEKEEPER) {
        require(!mnt.isParticipantActive(participant), ErrorCodes.BB_ACCOUNT_RECENTLY_VOTED);

        _leave(participant);
    }

    /// @inheritdoc IBuyback
    function setLoyaltyParameters(uint256 coreFactor_, uint32 coreResetPenalty_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(coreFactor_ < LOYALTY_SCALE, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
        require(coreResetPenalty_ < STRATA_NUMBER, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
        loyaltyCoreFactor = coreFactor_;
        coreResetPenalty = coreResetPenalty_;

        emit LoyaltyParametersChanged(coreFactor_, coreResetPenalty_);
    }

    /// @inheritdoc IBuyback
    function setLoyaltyStrata(uint256[STRATA_NUMBER] memory loyaltyStrata_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < STRATA_NUMBER; i++) {
            require(loyaltyStrata_[i] < LOYALTY_SCALE);
            loyaltyStrata[i] = loyaltyStrata_[i];
        }
        emit LoyaltyStrataChanged();
    }

    /// @inheritdoc IBuyback
    function setLoyaltyGroups(uint256[] memory loyaltyGroupThresholds_, uint32[] memory loyaltyGroupStartStrata_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(loyaltyGroupThresholds_.length > 0, ErrorCodes.INPUT_ARRAY_IS_EMPTY);
        require(
            loyaltyGroupThresholds_.length == loyaltyGroupStartStrata_.length,
            ErrorCodes.INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL
        );
        require(loyaltyGroupStartStrata_[0] == 0, ErrorCodes.BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO);

        loyaltyGroupThresholds = new uint256[](loyaltyGroupThresholds_.length);
        loyaltyGroupStartStrata = new uint32[](loyaltyGroupThresholds_.length);
        for (uint256 i = 0; i < loyaltyGroupThresholds_.length; i++) {
            require(loyaltyGroupStartStrata_[i] < STRATA_NUMBER, ErrorCodes.NUMBER_IS_NOT_IN_SCALE);
            loyaltyGroupThresholds[i] = loyaltyGroupThresholds_[i];
            loyaltyGroupStartStrata[i] = loyaltyGroupStartStrata_[i];
        }

        emit LoyaltyGroupsChanged(loyaltyGroupThresholds_.length);
    }

    // // // // Pause control // // // //

    bytes32 internal constant STAKE_OP = "Stake";
    bytes32 internal constant UNSTAKE_OP = "Unstake";
    bytes32 internal constant UPDATE_OP = "Update";
    bytes32 internal constant LEAVE_OP = "Leave";

    function validatePause(address) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    function validateUnpause(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    // // // // Utils // // // //

    function getTimestamp() internal view virtual returns (uint32) {
        return block.timestamp.toUint32();
    }

    function weightAggregator() internal view returns (IWeightAggregator) {
        return getInterconnector().weightAggregator();
    }

    function whitelist() internal view returns (IWhitelist) {
        return getInterconnector().whitelist();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./libraries/ProtocolLinkage.sol";
import "./interfaces/IInterconnectorLeaf.sol";

abstract contract InterconnectorLeaf is IInterconnectorLeaf, LinkageLeaf {
    function getInterconnector() public view returns (IInterconnector) {
        return IInterconnector(getLinkageRootAddress());
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBuyback is IAccessControl, ILinkageLeaf {
    event Stake(address who, uint256 amount);
    event Unstake(address who, uint256 amount);
    event NewBuyback(uint256 amount, uint256 share);
    event ParticipateBuyback(address who);
    event LeaveBuyback(address who, uint256 currentStaked);
    event BuybackWeightChanged(address who, uint256 newWeight, uint256 oldWeight, uint256 newTotalWeight);
    event LoyaltyParametersChanged(uint256 newCoreFactor, uint32 newCoreResetPenalty);
    event LoyaltyStrataChanged();
    event LoyaltyGroupsChanged(uint256 newGroupCount);

    /**
     * @notice Gets info about account membership in Buyback
     */
    function getMemberInfo(address account)
        external
        view
        returns (
            bool participating,
            uint256 weight,
            uint256 lastIndex,
            uint256 stakeAmount
        );

    /**
     * @notice Gets info about accounts loyalty calculation
     */
    function getLoyaltyInfo(address account)
        external
        view
        returns (
            uint32 loyaltyStart,
            uint256 coreBalance,
            uint256 lastBalance
        );

    /**
     * @notice Gets if an account is participating in Buyback
     */
    function isParticipating(address account) external view returns (bool);

    /**
     * @notice Gets stake of the account
     */
    function getStakedAmount(address account) external view returns (uint256);

    /**
     * @notice Gets buyback weight of an account
     */
    function getWeight(address account) external view returns (uint256);

    /**
     * @notice Gets loyalty factor of an account with given balance.
     */
    function getLoyaltyFactorForBalance(address account, uint256 balance) external view returns (uint256);

    /**
     * @notice Gets total Buyback weight, which is the sum of weights of all accounts.
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Gets current Buyback index.
     * Its the accumulated sum of MNTs shares that are given for each weight of an account.
     */
    function getBuybackIndex() external view returns (uint256);

    /**
     * @notice Gets all global loyalty parameters.
     */
    function getLoyaltyParameters()
        external
        view
        returns (
            uint256[24] memory loyaltyStrata,
            uint256[] memory groupThresholds,
            uint32[] memory groupStartStrata,
            uint256 coreFactor,
            uint32 coreResetPenalty
        );

    /**
     * @notice Stakes the specified amount of MNT and transfers them to this contract.
     * @notice This contract should be approved to transfer MNT from sender account
     * @param amount The amount of MNT to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Unstakes the specified amount of MNT and transfers them back to sender if he participates
     *         in the Buyback system, otherwise just transfers MNT tokens to the sender.
     *         would not be greater than staked amount left. If `amount == MaxUint256` unstakes all staked tokens.
     * @param amount The amount of MNT to unstake
     */
    function unstake(uint256 amount) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating. Reverts if operation is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeights(address account) external;

    /**
     * @notice Claims buyback rewards, updates buyback weight and voting power.
     * Does nothing if account is not participating or update is paused.
     * @param account Address to update weights for
     */
    function updateBuybackAndVotingWeightsRelaxed(address account) external;

    /**
     * @notice Does a buyback using the specified amount of MNT from sender's account
     * @param amount The amount of MNT to take and distribute as buyback
     * @dev RESTRICTION: Distributor only
     */
    function buyback(uint256 amount) external;

    /**
     * @notice Make account participating in the buyback.
     */
    function participate() external;

    /**
     * @notice Make accounts participate in buyback before its start.
     * @param accounts Address to make participate in buyback.
     * @dev RESTRICTION: Admin only
     */
    function participateOnBehalf(address[] memory accounts) external;

    /**
     * @notice Leave buyback participation, claim any MNTs rewarded by the buyback.
     * Leaving does not withdraw staked MNTs but reduces weight of the account to zero
     */
    function leave() external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed
     * Can only be called if (timestamp > participantLastVoteTimestamp + maxNonVotingPeriod).
     * @param participant Address to leave for
     * @dev RESTRICTION: GATEKEEPER only
     */
    function leaveOnBehalf(address participant) external;

    /**
     * @notice Leave buyback participation on behalf, claim any MNTs rewarded by the buyback and
     * reduce the weight of account to zero. All staked MNTs remain on the buyback contract and available
     * for their owner to be claimed.
     * @dev Function to leave sanctioned accounts from Buyback system
     * Can only be called if the participant is sanctioned by the AML system.
     * @param participant Address to leave for
     */
    function leaveByAmlDecision(address participant) external;

    /**
     * @notice Changes loyalty core factor and core reset penalty parameters.
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyParameters(uint256 newCoreFactor, uint32 newCoreResetPenalty) external;

    /**
     * @notice Sets new loyalty factors for all strata.
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyStrata(uint256[24] memory newLoyaltyStrata) external;

    /**
     * @notice Sets new groups and their parameters
     * @param newGroupThresholds New list of groups and their balance thresholds.
     * @param newGroupStartStrata Indexes of starting stratum of each group. First index MUST be zero.
     *        Length of array must be equal to the newGroupThresholds
     * @dev RESTRICTION: Admin only
     */
    function setLoyaltyGroups(uint256[] memory newGroupThresholds, uint32[] memory newGroupStartStrata) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ErrorCodes.sol";

abstract contract PauseControl {
    event OperationPaused(bytes32 op, address subject);
    event OperationUnpaused(bytes32 op, address subject);

    mapping(address => mapping(bytes32 => bool)) internal pausedOps;

    function validatePause(address subject) internal view virtual;

    function validateUnpause(address subject) internal view virtual;

    function isOperationPaused(bytes32 op, address subject) public view returns (bool) {
        return pausedOps[subject][op];
    }

    function pauseOperation(bytes32 op, address subject) external virtual {
        validatePause(subject);
        require(!isOperationPaused(op, subject));
        pausedOps[subject][op] = true;
        emit OperationPaused(op, subject);
    }

    function unpauseOperation(bytes32 op, address subject) external virtual {
        validateUnpause(subject);
        require(isOperationPaused(op, subject));
        pausedOps[subject][op] = false;
        emit OperationUnpaused(op, subject);
    }

    modifier checkPausedSubject(bytes32 op, address subject) {
        require(!isOperationPaused(op, subject), ErrorCodes.OPERATION_PAUSED);
        _;
    }

    modifier checkPaused(bytes32 op) {
        require(!isOperationPaused(op, address(0)), ErrorCodes.OPERATION_PAUSED);
        _;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./ILinkageLeaf.sol";

interface IMnt is IERC20Upgradeable, IERC165, IAccessControlUpgradeable, ILinkageLeaf {
    event MaxNonVotingPeriodChanged(uint256 oldPeriod, uint256 newPeriod);
    event NewGovernor(address governor);
    event VotesUpdated(address account, uint256 oldVotingWeight, uint256 newVotingWeight);
    event TotalVotesUpdated(uint256 oldTotalVotes, uint256 newTotalVotes);

    /**
     * @notice get governor
     */
    function governor() external view returns (address);

    /**
     * @notice returns votingWeight for user
     */
    function votingWeight(address) external view returns (uint256);

    /**
     * @notice get total voting weight
     */
    function totalVotingWeight() external view returns (uint256);

    /**
     * @notice Updates voting power of the account
     */
    function updateVotingWeight(address account) external;

    /**
     * @notice Creates new total voting weight checkpoint
     * @dev RESTRICTION: Governor only.
     */
    function updateTotalWeightCheckpoint() external;

    /**
     * @notice Checks user activity for the last `maxNonVotingPeriod` blocks
     * @param account_ The address of the account
     * @return returns true if the user voted or his delegatee voted for the last maxNonVotingPeriod blocks,
     * otherwise returns false
     */
    function isParticipantActive(address account_) external view returns (bool);

    /**
     * @notice Updates last voting timestamp of the account
     * @dev RESTRICTION: Governor only.
     */
    function updateVoteTimestamp(address account) external;

    /**
     * @notice Gets the latest voting timestamp for account.
     * @dev If the user delegated his votes, then it also checks the timestamp of the last vote of the delegatee
     * @param account The address of the account
     * @return latest voting timestamp for account
     */
    function lastActivityTimestamp(address account) external view returns (uint256);

    /**
     * @notice set new governor
     * @dev RESTRICTION: Admin only.
     */
    function setGovernor(address newGovernor) external;

    /**
     * @notice Sets the maxNonVotingPeriod
     * @dev Admin function to set maxNonVotingPeriod
     * @param newPeriod_ The new maxNonVotingPeriod (in sec). Must be greater than 90 days and lower than 2 years.
     * @dev RESTRICTION: Admin only.
     */
    function setMaxNonVotingPeriod(uint256 newPeriod_) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

library ErrorCodes {
    // Common
    string internal constant ADMIN_ONLY = "E101";
    string internal constant UNAUTHORIZED = "E102";
    string internal constant OPERATION_PAUSED = "E103";
    string internal constant WHITELISTED_ONLY = "E104";
    string internal constant ADDRESS_IS_NOT_IN_AML_SYSTEM = "E105";
    string internal constant ADDRESS_IS_BLACKLISTED = "E106";

    // Invalid input
    string internal constant ADMIN_ADDRESS_CANNOT_BE_ZERO = "E201";
    string internal constant INVALID_REDEEM = "E202";
    string internal constant REDEEM_TOO_MUCH = "E203";
    string internal constant MARKET_NOT_LISTED = "E204";
    string internal constant INSUFFICIENT_LIQUIDITY = "E205";
    string internal constant INVALID_SENDER = "E206";
    string internal constant BORROW_CAP_REACHED = "E207";
    string internal constant BALANCE_OWED = "E208";
    string internal constant UNRELIABLE_LIQUIDATOR = "E209";
    string internal constant INVALID_DESTINATION = "E210";
    string internal constant INSUFFICIENT_STAKE = "E211";
    string internal constant INVALID_DURATION = "E212";
    string internal constant INVALID_PERIOD_RATE = "E213";
    string internal constant EB_TIER_LIMIT_REACHED = "E214";
    string internal constant INVALID_DEBT_REDEMPTION_RATE = "E215";
    string internal constant LQ_INVALID_SEIZE_DISTRIBUTION = "E216";
    string internal constant EB_TIER_DOES_NOT_EXIST = "E217";
    string internal constant EB_ZERO_TIER_CANNOT_BE_ENABLED = "E218";
    string internal constant EB_ALREADY_ACTIVATED_TIER = "E219";
    string internal constant EB_END_BLOCK_MUST_BE_LARGER_THAN_CURRENT = "E220";
    string internal constant EB_CANNOT_MINT_TOKEN_FOR_ACTIVATED_TIER = "E221";
    string internal constant EB_EMISSION_BOOST_IS_NOT_IN_RANGE = "E222";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E223";
    string internal constant INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT = "E224";
    string internal constant VESTING_SCHEDULE_ALREADY_EXISTS = "E225";
    string internal constant INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE = "E226";
    string internal constant NO_VESTING_SCHEDULE = "E227";
    string internal constant SCHEDULE_IS_IRREVOCABLE = "E228";
    string internal constant MNT_AMOUNT_IS_ZERO = "E230";
    string internal constant INCORRECT_AMOUNT = "E231";
    string internal constant MEMBERSHIP_LIMIT = "E232";
    string internal constant MEMBER_NOT_EXIST = "E233";
    string internal constant MEMBER_ALREADY_ADDED = "E234";
    string internal constant MEMBERSHIP_LIMIT_REACHED = "E235";
    string internal constant REPORTED_PRICE_SHOULD_BE_GREATER_THAN_ZERO = "E236";
    string internal constant MTOKEN_ADDRESS_CANNOT_BE_ZERO = "E237";
    string internal constant TOKEN_ADDRESS_CANNOT_BE_ZERO = "E238";
    string internal constant REDEEM_TOKENS_OR_REDEEM_AMOUNT_MUST_BE_ZERO = "E239";
    string internal constant FL_TOKEN_IS_NOT_UNDERLYING = "E240";
    string internal constant FL_AMOUNT_IS_TOO_LARGE = "E241";
    string internal constant FL_CALLBACK_FAILED = "E242";
    string internal constant DD_UNSUPPORTED_TOKEN = "E243";
    string internal constant DD_MARKET_ADDRESS_IS_ZERO = "E244";
    string internal constant DD_ROUTER_ADDRESS_IS_ZERO = "E245";
    string internal constant DD_RECEIVER_ADDRESS_IS_ZERO = "E246";
    string internal constant DD_BOT_ADDRESS_IS_ZERO = "E247";
    string internal constant DD_MARKET_NOT_FOUND = "E248";
    string internal constant DD_RECEIVER_NOT_FOUND = "E249";
    string internal constant DD_BOT_NOT_FOUND = "E250";
    string internal constant DD_ROUTER_ALREADY_SET = "E251";
    string internal constant DD_RECEIVER_ALREADY_SET = "E252";
    string internal constant DD_BOT_ALREADY_SET = "E253";
    string internal constant EB_MARKET_INDEX_IS_LESS_THAN_USER_INDEX = "E254";
    string internal constant LQ_INVALID_DRR_ARRAY = "E255";
    string internal constant LQ_INVALID_SEIZE_ARRAY = "E256";
    string internal constant LQ_INVALID_DEBT_REDEMPTION_RATE = "E257";
    string internal constant LQ_INVALID_SEIZE_INDEX = "E258";
    string internal constant LQ_DUPLICATE_SEIZE_INDEX = "E259";
    string internal constant DD_INVALID_TOKEN_IN_ADDRESS = "E260";
    string internal constant DD_INVALID_TOKEN_OUT_ADDRESS = "E261";
    string internal constant DD_INVALID_TOKEN_IN_AMOUNT = "E262";
    string internal constant DD_LIQUIDATION_ADDRESS_IS_ZERO = "E263";
    string internal constant DD_LIQUIDATION_ALREADY_SET = "E264";

    // Protocol errors
    string internal constant INVALID_PRICE = "E301";
    string internal constant MARKET_NOT_FRESH = "E302";
    string internal constant BORROW_RATE_TOO_HIGH = "E303";
    string internal constant INSUFFICIENT_TOKEN_CASH = "E304";
    string internal constant INSUFFICIENT_TOKENS_FOR_RELEASE = "E305";
    string internal constant INSUFFICIENT_MNT_FOR_GRANT = "E306";
    string internal constant TOKEN_TRANSFER_IN_UNDERFLOW = "E307";
    string internal constant NOT_PARTICIPATING_IN_BUYBACK = "E308";
    string internal constant NOT_ENOUGH_PARTICIPATING_ACCOUNTS = "E309";
    string internal constant NOTHING_TO_DISTRIBUTE = "E310";
    string internal constant ALREADY_PARTICIPATING_IN_BUYBACK = "E311";
    string internal constant MNT_APPROVE_FAILS = "E312";
    string internal constant TOO_EARLY_TO_DRIP = "E313";
    string internal constant BB_UNSTAKE_TOO_EARLY = "E314";
    string internal constant INSUFFICIENT_SHORTFALL = "E315";
    string internal constant HEALTHY_FACTOR_NOT_IN_RANGE = "E316";
    string internal constant BUYBACK_DRIPS_ALREADY_HAPPENED = "E317";
    string internal constant EB_INDEX_SHOULD_BE_GREATER_THAN_INITIAL = "E318";
    string internal constant NO_VESTING_SCHEDULES = "E319";
    string internal constant INSUFFICIENT_UNRELEASED_TOKENS = "E320";
    string internal constant ORACLE_PRICE_EXPIRED = "E321";
    string internal constant TOKEN_NOT_FOUND = "E322";
    string internal constant RECEIVED_PRICE_HAS_INVALID_ROUND = "E323";
    string internal constant FL_PULL_AMOUNT_IS_TOO_LOW = "E324";
    string internal constant INSUFFICIENT_TOTAL_PROTOCOL_INTEREST = "E325";
    string internal constant BB_ACCOUNT_RECENTLY_VOTED = "E326";
    string internal constant DD_SWAP_ROUTER_IS_ZERO = "E327";
    string internal constant DD_SWAP_CALL_FAILS = "E328";
    string internal constant LL_NEW_ROOT_CANNOT_BE_ZERO = "E329";
    string internal constant RH_PAYOUT_FROM_FUTURE = "E330";
    string internal constant RH_ACCRUE_WITHOUT_UNLOCK = "E331";
    string internal constant RH_LERP_DELTA_IS_GREATER_THAN_PERIOD = "E332";
    string internal constant PRECONDITIONS_NOT_MET = "E333";

    // Invalid input - Admin functions
    string internal constant ZERO_EXCHANGE_RATE = "E401";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant MARKET_ALREADY_LISTED = "E403";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant EC_INVALID_PROVIDER_REPRESENTATIVE = "E406";
    string internal constant EC_PROVIDER_CANT_BE_REPRESENTATIVE = "E407";
    string internal constant OR_ORACLE_ADDRESS_CANNOT_BE_ZERO = "E408";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_SHOULD_BE_GREATER_THAN_ZERO = "E409";
    string internal constant OR_REPORTER_MULTIPLIER_SHOULD_BE_GREATER_THAN_ZERO = "E410";
    string internal constant INVALID_TOKEN = "E411";
    string internal constant INVALID_PROTOCOL_INTEREST_FACTOR_MANTISSA = "E412";
    string internal constant INVALID_REDUCE_AMOUNT = "E413";
    string internal constant LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO = "E414";
    string internal constant INVALID_UTILISATION_FACTOR_MANTISSA = "E415";
    string internal constant INVALID_MTOKENS_OR_BORROW_CAPS = "E416";
    string internal constant FL_PARAM_IS_TOO_LARGE = "E417";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E418";
    string internal constant INPUT_ARRAY_LENGTHS_ARE_NOT_EQUAL = "E419";
    string internal constant EC_INVALID_BOOSTS = "E420";
    string internal constant EC_ACCOUNT_IS_ALREADY_LIQUIDITY_PROVIDER = "E421";
    string internal constant EC_ACCOUNT_HAS_NO_AGREEMENT = "E422";
    string internal constant OR_TIMESTAMP_THRESHOLD_SHOULD_BE_GREATER_THAN_ZERO = "E423";
    string internal constant OR_UNDERLYING_TOKENS_DECIMALS_TOO_BIG = "E424";
    string internal constant OR_REPORTER_MULTIPLIER_TOO_BIG = "E425";
    string internal constant SHOULD_HAVE_REVOCABLE_SCHEDULE = "E426";
    string internal constant MEMBER_NOT_IN_DELAY_LIST = "E427";
    string internal constant DELAY_LIST_LIMIT = "E428";
    string internal constant NUMBER_IS_NOT_IN_SCALE = "E429";
    string internal constant BB_STRATUM_OF_FIRST_LOYALTY_GROUP_IS_NOT_ZERO = "E430";
    string internal constant INPUT_ARRAY_IS_EMPTY = "E431";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../interfaces/ILinkageLeaf.sol";
import "../interfaces/ILinkageRoot.sol";
import "./ErrorCodes.sol";

abstract contract LinkageRoot is ILinkageRoot {
    /// @notice Store self address to prevent context changing while delegateCall
    ILinkageRoot internal immutable _self = this;
    /// @notice Owner address
    address public immutable _linkage_owner;

    constructor(address owner_) {
        require(owner_ != address(0), ErrorCodes.ADMIN_ADDRESS_CANNOT_BE_ZERO);
        _linkage_owner = owner_;
    }

    /// @inheritdoc ILinkageRoot
    function switchLinkageRoot(ILinkageRoot newRoot) external {
        require(msg.sender == _linkage_owner, ErrorCodes.UNAUTHORIZED);

        emit LinkageRootSwitch(newRoot);

        Address.functionDelegateCall(
            address(newRoot),
            abi.encodePacked(LinkageRoot.interconnect.selector),
            "LinkageRoot: low-level delegate call failed"
        );
    }

    /// @inheritdoc ILinkageRoot
    function interconnect() external {
        emit LinkageRootInterconnected();
        interconnectInternal();
    }

    function interconnectInternal() internal virtual;
}

abstract contract LinkageLeaf is ILinkageLeaf {
    /// @inheritdoc ILinkageLeaf
    function switchLinkageRoot(ILinkageRoot newRoot) public {
        require(address(newRoot) != address(0), ErrorCodes.LL_NEW_ROOT_CANNOT_BE_ZERO);

        StorageSlot.AddressSlot storage slot = getRootSlot();
        address oldRoot = slot.value;
        if (oldRoot == address(newRoot)) return;

        require(oldRoot == address(0) || oldRoot == msg.sender, ErrorCodes.UNAUTHORIZED);
        slot.value = address(newRoot);

        emit LinkageRootSwitched(newRoot, LinkageRoot(oldRoot));
    }

    /**
     * @dev Gets current root contract address
     */
    function getLinkageRootAddress() internal view returns (address) {
        return getRootSlot().value;
    }

    /**
     * @dev Gets current root contract storage slot
     */
    function getRootSlot() private pure returns (StorageSlot.AddressSlot storage) {
        // keccak256("minterest.slot.linkageRoot")
        return StorageSlot.getAddressSlot(0xc34f336ef21a27e6cdbefdb1e201a57e5e6cb9d267e34fc3134d22f9decc8bbf);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IInterconnector.sol";
import "./ILinkageLeaf.sol";

interface IInterconnectorLeaf is ILinkageLeaf {
    function getInterconnector() external view returns (IInterconnector);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILinkageRoot.sol";

interface ILinkageLeaf {
    /**
     * @notice Emitted when root contract address is changed
     */
    event LinkageRootSwitched(ILinkageRoot newRoot, ILinkageRoot oldRoot);

    /**
     * @notice Connects new root contract address
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface ILinkageRoot {
    /**
     * @notice Emitted when new root contract connected to all leafs
     */
    event LinkageRootSwitch(ILinkageRoot newRoot);

    /**
     * @notice Emitted when root interconnects its contracts
     */
    event LinkageRootInterconnected();

    /**
     * @notice Connects new root to all leafs contracts
     * @param newRoot New root contract address
     */
    function switchLinkageRoot(ILinkageRoot newRoot) external;

    /**
     * @notice Update root for all leaf contracts
     * @dev Should include only leaf contracts
     */
    function interconnect() external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ISupervisor.sol";
import "./IRewardsHub.sol";
import "./IMnt.sol";
import "./IBuyback.sol";
import "./IVesting.sol";
import "./IMinterestNFT.sol";
import "./IPriceOracle.sol";
import "./ILiquidation.sol";
import "./IBDSystem.sol";
import "./IWeightAggregator.sol";
import "./IEmissionBooster.sol";

interface IInterconnector {
    function supervisor() external view returns (ISupervisor);

    function buyback() external view returns (IBuyback);

    function emissionBooster() external view returns (IEmissionBooster);

    function bdSystem() external view returns (IBDSystem);

    function rewardsHub() external view returns (IRewardsHub);

    function mnt() external view returns (IMnt);

    function minterestNFT() external view returns (IMinterestNFT);

    function liquidation() external view returns (ILiquidation);

    function oracle() external view returns (IPriceOracle);

    function vesting() external view returns (IVesting);

    function whitelist() external view returns (IWhitelist);

    function weightAggregator() external view returns (IWeightAggregator);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IMToken.sol";
import "./IBuyback.sol";
import "./IRewardsHub.sol";
import "./ILinkageLeaf.sol";
import "./IWhitelist.sol";

/**
 * @title Minterest Supervisor Contract
 * @author Minterest
 */
interface ISupervisor is IAccessControl, ILinkageLeaf {
    /**
     * @notice Emitted when an admin supports a market
     */
    event MarketListed(IMToken mToken);

    /**
     * @notice Emitted when an account enable a market
     */
    event MarketEnabledAsCollateral(IMToken mToken, address account);

    /**
     * @notice Emitted when an account disable a market
     */
    event MarketDisabledAsCollateral(IMToken mToken, address account);

    /**
     * @notice Emitted when a utilisation factor is changed by admin
     */
    event NewUtilisationFactor(
        IMToken mToken,
        uint256 oldUtilisationFactorMantissa,
        uint256 newUtilisationFactorMantissa
    );

    /**
     * @notice Emitted when liquidation fee is changed by admin
     */
    event NewLiquidationFee(IMToken marketAddress, uint256 oldLiquidationFee, uint256 newLiquidationFee);

    /**
     * @notice Emitted when borrow cap for a mToken is changed
     */
    event NewBorrowCap(IMToken indexed mToken, uint256 newBorrowCap);

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    function accountAssets(address, uint256) external view returns (IMToken);

    /**
     * @notice Collection of states of supported markets
     * @dev Types containing (nested) mappings could not be parameters or return of external methods
     */
    function markets(IMToken)
        external
        view
        returns (
            bool isListed,
            uint256 utilisationFactorMantissa,
            uint256 liquidationFeeMantissa
        );

    /**
     * @notice get A list of all markets
     */
    function allMarkets(uint256) external view returns (IMToken);

    /**
     * @notice get Borrow caps enforced by beforeBorrow for each mToken address.
     */
    function borrowCaps(IMToken) external view returns (uint256);

    /**
     * @notice get keccak-256 hash of gatekeeper role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of timelock
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Returns the assets an account has enabled as collateral
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has enabled as collateral
     */
    function getAccountAssets(address account) external view returns (IMToken[] memory);

    /**
     * @notice Returns whether the given account is enabled as collateral in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, IMToken mToken) external view returns (bool);

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of addresses of the mToken markets to be enabled as collateral
     */
    function enableAsCollateral(IMToken[] memory mTokens) external;

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mTokenAddress The address of the asset to be removed
     */
    function disableAsCollateral(IMToken mTokenAddress) external;

    /**
     * @notice Makes checks if the account should be allowed to lend tokens in the given market
     * @param mToken The market to verify the lend against
     * @param lender The account which would get the lent tokens
     */
    function beforeLend(IMToken mToken, address lender) external;

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market and triggers emission system
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @param isAmlProcess Do we need to check the AML system or not
     */
    function beforeRedeem(
        IMToken mToken,
        address redeemer,
        uint256 redeemTokens,
        bool isAmlProcess
    ) external;

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     */
    function beforeBorrow(
        IMToken mToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param borrower The account which would borrowed the asset
     */
    function beforeRepayBorrow(IMToken mToken, address borrower) external;

    /**
     * @notice Checks if the seizing of assets should be allowed to occur (auto liquidation process)
     * @param mToken Asset which was used as collateral and will be seized
     * @param liquidator_ The address of liquidator contract
     * @param borrower The address of the borrower
     */
    function beforeAutoLiquidationSeize(
        IMToken mToken,
        address liquidator_,
        address borrower
    ) external;

    /**
     * @notice Checks if the sender should be allowed to repay borrow in the given market (auto liquidation process)
     * @param liquidator_ The address of liquidator contract
     * @param borrower_ The account which borrowed the asset
     * @param mToken_ The market to verify the repay against
     */
    function beforeAutoLiquidationRepay(
        address liquidator_,
        address borrower_,
        IMToken mToken_
    ) external;

    /**
     * @notice Checks if the address is the Liquidation contract
     * @dev Used in liquidation process
     * @param liquidator_ Prospective address of the Liquidation contract
     */
    function isLiquidator(address liquidator_) external view;

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of mTokens to transfer
     */
    function beforeTransfer(
        IMToken mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /**
     * @notice Makes checks before flash loan in MToken
     * @param mToken The address of the token
     * receiver - The address of the loan receiver
     * amount - How much tokens to flash loan
     * fee - Flash loan fee
     */
    function beforeFlashLoan(
        IMToken mToken,
        address, /* receiver */
        uint256, /* amount */
        uint256 /* fee */
    ) external view;

    /**
     * @notice Calculate account liquidity in USD related to utilisation factors of underlying assets
     * @return (USD value above total utilisation requirements of all assets,
     *           USD value below total utilisation requirements of all assets)
     */
    function getAccountLiquidity(address account) external view returns (uint256, uint256);

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param mTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        IMToken mTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external returns (uint256, uint256);

    /**
     * @notice Get liquidationFeeMantissa and utilisationFactorMantissa for market
     * @param market Market for which values are obtained
     * @return (liquidationFeeMantissa, utilisationFactorMantissa)
     */
    function getMarketData(IMToken market) external view returns (uint256, uint256);

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external view;

    /**
     * @notice Sets the utilisationFactor for a market
     * @dev Governance function to set per-market utilisationFactor
     * @param mToken The market to set the factor on
     * @param newUtilisationFactorMantissa The new utilisation factor, scaled by 1e18
     * @dev RESTRICTION: Timelock only.
     */
    function setUtilisationFactor(IMToken mToken, uint256 newUtilisationFactorMantissa) external;

    /**
     * @notice Sets the liquidationFee for a market
     * @dev Governance function to set per-market liquidationFee
     * @param mToken The market to set the fee on
     * @param newLiquidationFeeMantissa The new liquidation fee, scaled by 1e18
     * @dev RESTRICTION: Timelock only.
     */
    function setLiquidationFee(IMToken mToken, uint256 newLiquidationFeeMantissa) external;

    /**
     * @notice Add the market to the markets mapping and set it as listed, also initialize MNT market state.
     * @dev Admin function to set isListed and add support for the market
     * @param mToken The address of the market (token) to list
     * @dev RESTRICTION: Admin only.
     */
    function supportMarket(IMToken mToken) external;

    /**
     * @notice Set the given borrow caps for the given mToken markets.
     *         Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or gateKeeper function to set the borrow caps.
     *      A borrow cap of 0 corresponds to unlimited borrowing.
     * @param mTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set.
     *                      A value of 0 corresponds to unlimited borrowing.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function setMarketBorrowCaps(IMToken[] calldata mTokens, uint256[] calldata newBorrowCaps) external;

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (IMToken[] memory);

    /**
     * @notice Returns true if market is listed in Supervisor
     */
    function isMarketListed(IMToken) external view returns (bool);

    /**
     * @notice Check that account is not in the black list and protocol operations are available.
     * @param account The address of the account to check
     */
    function isNotBlacklisted(address account) external view returns (bool);

    /**
     * @notice Check if transfer of MNT is allowed for accounts.
     * @param from The source account address to check
     * @param to The destination account address to check
     */
    function isMntTransferAllowed(address from, address to) external view returns (bool);

    /**
     * @notice Returns block number
     */
    function getBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./IMToken.sol";
import "./ILinkageLeaf.sol";

interface IRewardsHub is ILinkageLeaf {
    event DistributedSupplierMnt(IMToken mToken, address supplier, uint256 mntDelta, uint256 mntSupplyIndex);
    event DistributedBorrowerMnt(IMToken mToken, address borrower, uint256 mntDelta, uint256 mntBorrowIndex);
    event EmissionRewardAccrued(address account, uint256 amount);
    event RepresentativeRewardAccrued(address account, address provider, uint256 amount);
    event BuybackRewardAccrued(address account, uint256 amount);

    event RewardUnlocked(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event MntGranted(address recipient, uint256 amount);

    event MntSupplyEmissionRateUpdated(IMToken mToken, uint256 newSupplyEmissionRate);
    event MntBorrowEmissionRateUpdated(IMToken mToken, uint256 newBorrowEmissionRate);

    /**
     * @notice get keccak-256 hash of gatekeeper
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of timelock
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Gets the rate at which MNT is distributed to the corresponding supply market (per block)
     */
    function mntSupplyEmissionRate(IMToken) external view returns (uint256);

    /**
     * @notice Gets the rate at which MNT is distributed to the corresponding borrow market (per block)
     */
    function mntBorrowEmissionRate(IMToken) external view returns (uint256);

    /**
     * @notice Gets the MNT market supply state for each market
     */
    function mntSupplyState(IMToken) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT market borrow state for each market
     */
    function mntBorrowState(IMToken) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT supply index and block number for each market
     */
    function mntSupplierState(IMToken, address) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets the MNT borrow index and block number for each market
     */
    function mntBorrowerState(IMToken, address) external view returns (uint224 index, uint32 blockN);

    /**
     * @notice Gets summary amount of available and delayed balances of an account.
     */
    function totalBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Gets amount of MNT that can be withdrawn from an account at this block.
     */
    function availableBalanceOf(address account) external view returns (uint256);

    /**
     * @notice Initializes market in RewardsHub. Should be called once from Supervisor.supportMarket
     * @dev RESTRICTION: Supervisor only
     */
    function initMarket(IMToken mToken) external;

    /**
     * @notice Accrues MNT to the market by updating the borrow and supply indexes
     * @dev This method doesn't update MNT index history in Minterest NFT.
     * @param market The market whose supply and borrow index to update
     * @return (MNT supply index, MNT borrow index)
     */
    function updateAndGetMntIndexes(IMToken market) external returns (uint224, uint224);

    /**
     * @notice Shorthand function to distribute MNT emissions from supplies of one market.
     */
    function distributeSupplierMnt(IMToken mToken, address account) external;

    /**
     * @notice Shorthand function to distribute MNT emissions from borrows of one market.
     */
    function distributeBorrowerMnt(IMToken mToken, address account) external;

    /**
     * @notice Updates market indexes and distributes tokens (if any) for holder
     * @dev Updates indexes and distributes only for those markets where the holder have a
     * non-zero supply or borrow balance.
     * @param account The address to distribute MNT for
     */
    function distributeAllMnt(address account) external;

    /**
     * @notice Distribute all MNT accrued by the accounts
     * @param accounts The addresses to distribute MNT for
     * @param mTokens The list of markets to distribute MNT in
     * @param borrowers Whether or not to distribute MNT earned by borrowing
     * @param suppliers Whether or not to distribute MNT earned by supplying
     */
    function distributeMnt(
        address[] memory accounts,
        IMToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) external;

    /**
     * @notice Accrues buyback reward
     * @dev RESTRICTION: Buyback only
     */
    function accrueBuybackReward(address account, uint256 amount) external;

    /**
     * @notice Gets part of delayed rewards that is unlocked and have become available.
     */
    function getUnlockableRewards(address account) external view returns (uint256);

    /**
     * @notice Transfers available part of MNT rewards to the sender.
     * This will decrease accounts buyback and voting weights.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Transfers
     * @dev RESTRICTION: Admin only
     */
    function grant(address recipient, uint256 amount) external;

    /**
     * @notice Set MNT borrow and supply emission rates for a single market
     * @param mToken The market whose MNT emission rate to update
     * @param newMntSupplyEmissionRate New supply MNT emission rate for market
     * @param newMntBorrowEmissionRate New borrow MNT emission rate for market
     * @dev RESTRICTION Timelock only
     */
    function setMntEmissionRates(
        IMToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBuyback.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 */
interface IVesting is IAccessControl {
    /**
     * @notice An event that's emitted when a new vesting schedule for a account is created.
     */
    event VestingScheduleAdded(address target, VestingSchedule schedule);

    /**
     * @notice An event that's emitted when a vesting schedule revoked.
     */
    event VestingScheduleRevoked(address target, uint256 unreleased, uint256 locked);

    /**
     * @notice An event that's emitted when the account Withdrawn the released tokens.
     */
    event Withdrawn(address target, uint256 withdrawn);

    /**
     * @notice Emitted when an account is added to the delay list
     */
    event AddedToDelayList(address account);

    /**
     * @notice Emitted when an account is removed from the delay list
     */
    event RemovedFromDelayList(address account);

    /**
     * @notice The structure is used in the contract constructor for create vesting schedules
     * during contract deploying.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param start offset in minutes at which vesting starts. Zero will vesting immediately.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * @param revocable whether the vesting is revocable or not.
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice Vesting schedules of an account.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * `released amount` of tokens to his address.
     * @param revocable whether the vesting is revocable or not.
     */
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint32 created;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /// @notice get keccak-256 hash of GATEKEEPER role
    function GATEKEEPER() external view returns (bytes32);

    /// @notice get keccak-256 hash of TOKEN_PROVIDER role
    function TOKEN_PROVIDER() external view returns (bytes32);

    /**
     * @notice get vesting schedule of an account.
     */
    function schedules(address)
        external
        view
        returns (
            uint256 totalAmount,
            uint256 released,
            uint32 created,
            uint32 start,
            uint32 duration,
            bool revocable
        );

    /**
     * @notice Gets the amount of MNT that was transferred to Vesting contract
     * and can be transferred to other accounts via vesting process.
     * Transferring rewards from Vesting via withdraw method will decrease this amount.
     */
    function allocation() external view returns (uint256);

    /**
     * @notice Gets the amount of allocated MNT tokens that are not used in any vesting schedule yet.
     * Creation of new vesting schedules will decrease this amount.
     */
    function freeAllocation() external view returns (uint256);

    /**
     * @notice get Whether or not the account is in the delay list
     */
    function delayList(address) external view returns (bool);

    /**
     * @notice Withdraw the specified number of tokens. For a successful transaction, the requirement
     * `amount_ > 0 && amount_ <= unreleased` must be met.
     * If `amount_ == MaxUint256` withdraw all unreleased tokens.
     * @param amount_ The number of tokens to withdraw.
     */
    function withdraw(uint256 amount_) external;

    /**
     * @notice Increases vesting schedule allocation and transfers MNT into Vesting.
     * @dev RESTRICTION: TOKEN_PROVIDER only
     */
    function refill(uint256 amount) external;

    /**
     * @notice Transfers MNT that were added to the contract without calling the refill and are unallocated.
     * @dev RESTRICTION: Admin only
     */
    function sweep(address recipient, uint256 amount) external;

    /**
     * @notice Allows the admin to create a new vesting schedules.
     * @param schedulesData an array of vesting schedules that will be created.
     * @dev RESTRICTION: Admin only.
     */
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external;

    /**
     * @notice Allows the admin to revoke the vesting schedule. Tokens already vested
     * transfer to the account, the rest are returned to the vesting contract.
     * Accounts that are in delay list have their withdraw blocked so they would not receive anything.
     * @param target_ the address from which the vesting schedule is revoked.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function revokeVestingSchedule(address target_) external;

    /**
     * @notice Calculates the end of the vesting.
     * @param who_ account address for which the parameter is returned.
     * @return the end of the vesting.
     */
    function endOfVesting(address who_) external view returns (uint256);

    /**
     * @notice Calculates locked amount for a given `time`.
     * @param who_ account address for which the parameter is returned.
     * @return locked amount for a given `time`.
     */
    function lockedAmount(address who_) external view returns (uint256);

    /**
     * @notice Calculates the amount that has already vested.
     * @param who_ account address for which the parameter is returned.
     * @return the amount that has already vested.
     */
    function vestedAmount(address who_) external view returns (uint256);

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param who_ account address for which the parameter is returned.
     * @return the amount that has already vested but hasn't been released yet.
     */
    function releasableAmount(address who_) external view returns (uint256);

    /**
     * @notice Gets the amount that has already vested but hasn't been released yet if account
     *      schedule had no starting delay (cliff).
     */
    function getReleasableWithoutCliff(address account) external view returns (uint256);

    /**
     * @notice Add an account with revocable schedule to the delay list
     * @param who_ The account that is being added to the delay list
     * @dev RESTRICTION: Gatekeeper only.
     */
    function addToDelayList(address who_) external;

    /**
     * @notice Remove an account from the delay list
     * @param who_ The account that is being removed from the delay list
     * @dev RESTRICTION: Gatekeeper only.
     */
    function removeFromDelayList(address who_) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

/**
 * @title MinterestNFT
 * @dev Contract module which provides functionality to mint new ERC1155 tokens
 *      Each token connected with image and metadata. The image and metadata saved
 *      on IPFS and this contract stores the CID of the folder where lying metadata.
 *      Also each token belongs one of the Minterest tiers, and give some emission
 *      boost for Minterest distribution system.
 */
interface IMinterestNFT is IAccessControl, IERC1155, ILinkageLeaf {
    /**
     * @notice Emitted when new base URI was installed
     */
    event NewBaseUri(string newBaseUri);

    /**
     * @notice get name for Minterst NFT Token
     */
    function name() external view returns (string memory);

    /**
     * @notice get symbool for Minterst NFT Token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get address of opensea proxy registry
     */
    function proxyRegistry() external view returns (ProxyRegistry);

    /**
     * @notice get keccak-256 hash of GATEKEEPER role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice Mint new 1155 standard token
     * @param account_ The address of the owner of minterestNFT
     * @param amount_ Instance count for minterestNFT
     * @param data_ The _data argument MAY be re-purposed for the new context.
     * @param tier_ tier
     */
    function mint(
        address account_,
        uint256 amount_,
        bytes memory data_,
        uint256 tier_
    ) external;

    /**
     * @notice Mint new ERC1155 standard tokens in one transaction
     * @param account_ The address of the owner of tokens
     * @param amounts_ Array of instance counts for tokens
     * @param data_ The _data argument MAY be re-purposed for the new context.
     * @param tiers_ Array of tiers
     * @dev RESTRICTION: Gatekeeper only
     */
    function mintBatch(
        address account_,
        uint256[] memory amounts_,
        bytes memory data_,
        uint256[] memory tiers_
    ) external;

    /**
     * @notice Transfer token to another account
     * @param to_ The address of the token receiver
     * @param id_ token id
     * @param amount_ Count of tokens
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeTransfer(
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external;

    /**
     * @notice Transfer tokens to another account
     * @param to_ The address of the tokens receiver
     * @param ids_ Array of token ids
     * @param amounts_ Array of tokens count
     * @param data_ The _data argument MAY be re-purposed for the new context.
     */
    function safeBatchTransfer(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        bytes memory data_
    ) external;

    /**
     * @notice Set new base URI
     * @param newBaseUri Base URI
     * @dev RESTRICTION: Admin only
     */
    function setURI(string memory newBaseUri) external;

    /**
     * @notice Override function to return image URL, opensea requirement
     * @param tokenId_ Id of token to get URL
     * @return IPFS URI for token id, opensea requirement
     */
    function uri(uint256 tokenId_) external view returns (string memory);

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     * @param _owner Owner of tokens
     * @param _operator Address to check if the `operator` is the operator for `owner` tokens
     * @return isOperator return true if `operator` is the operator for `owner` tokens otherwise true     *
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);

    /**
     * @dev Returns the next token ID to be minted
     * @return the next token ID to be minted
     */
    function nextIdToBeMinted() external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;
import "./IMToken.sol";

interface IPriceOracle {
    /**
     * @notice Get the underlying price of a mToken asset
     * @param mToken The mToken to get the underlying price of
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     *
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getUnderlyingPrice(IMToken mToken) external view returns (uint256);

    /**
     * @notice Return price for an asset
     * @param asset address of token
     * @return The underlying asset price mantissa (scaled by 1e18).
     *  Zero means the price is unavailable.
     * @dev Price should be scaled to 1e18 for tokens with tokenDecimals = 1e18
     *      and for 1e30 for tokens with tokenDecimals = 1e6.
     */
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./IMToken.sol";
import "./IDeadDrop.sol";
import "./ILinkageLeaf.sol";
import "./IPriceOracle.sol";

/**
 * This contract provides the liquidation functionality.
 */
interface ILiquidation is IAccessControl, ILinkageLeaf {
    event HealthyFactorLimitChanged(uint256 oldValue, uint256 newValue);
    event NewDeadDrop(address oldDeadDrop, address newDeadDrop);
    event NewInsignificantLoanThreshold(uint256 oldValue, uint256 newValue);
    event ReliableLiquidation(
        bool isManualLiquidation,
        bool isDebtHealthy,
        address liquidator,
        address borrower,
        IMToken[] marketAddresses,
        uint256[] seizeIndexes,
        uint256[] debtRates
    );
    event ProcessingStateUsageChanged(bool newValue);

    /**
     * @dev Local accountState for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct AccountLiquidationAmounts {
        uint256 accountTotalSupplyUsd;
        uint256 accountTotalCollateralUsd;
        uint256 accountPresumedTotalRepayUsd;
        uint256 accountTotalBorrowUsd;
        uint256[] repayAmounts;
        uint256[] seizeAmounts;
    }

    /**
     * @notice GET The maximum allowable value of a healthy factor after liquidation, scaled by 1e18
     */
    function healthyFactorLimit() external view returns (uint256);

    /**
     * @notice GET Maximum sum in USD for internal liquidation. Collateral for loans that are less
     * than this parameter will be counted as protocol interest, scaled by 1e18
     */
    function insignificantLoanThreshold() external view returns (uint256);

    /**
     * @notice get keccak-256 hash of TRUSTED_LIQUIDATOR role
     */
    function TRUSTED_LIQUIDATOR() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of MANUAL_LIQUIDATOR role
     */
    function MANUAL_LIQUIDATOR() external view returns (bytes32);

    /**
     * @notice get keccak-256 hash of TIMELOCK role
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Liquidate insolvent debt position
     * @param borrower_ Account which is being liquidated
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_  An array of debt redemption rates for each debt markets (scaled by 1e18).
     * @dev RESTRICTION: Trusted liquidator only
     */
    function liquidateUnsafeLoan(
        address borrower_,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external;

    /**
     * @notice Accrues interest for all required borrower's markets
     * @dev Accrue is required if market is used as borrow (debtRate > 0)
     *      or collateral (seizeIndex arr contains market index)
     *      The caller must ensure that the lengths of arrays 'accountAssets' and 'debtRates' are the same,
     *      array 'seizeIndexes' does not contain duplicates and none of the indexes exceeds the value
     *      (accountAssets.length - 1).
     * @param accountAssets An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     */
    function accrue(
        IMToken[] memory accountAssets,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external;

    /**
     * @notice For each market calculates the liquidation amounts based on borrower's state.
     * @param account_ The address of the borrower
     * @param marketAddresses An array with addresses of markets where the debtor is in
     * @param seizeIndexes_ An array with market indexes that will be used as collateral
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18)
     * @return accountState Struct that contains all balance parameters
     *         All arrays calculated in underlying assets, all total values calculated in USD.
     *         (the array indexes match each other)
     */
    function calculateLiquidationAmounts(
        address account_,
        IMToken[] memory marketAddresses,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external view returns (AccountLiquidationAmounts memory);

    /**
     * @notice Sets a new value for healthyFactorLimit
     * @dev RESTRICTION: Timelock only
     */
    function setHealthyFactorLimit(uint256 newValue_) external;

    /**
     * @notice Sets a new minterest deadDrop
     * @dev RESTRICTION: Admin only
     */
    function setDeadDrop(address newDeadDrop_) external;

    /**
     * @notice Sets a new insignificantLoanThreshold
     * @dev RESTRICTION: Timelock only
     */
    function setInsignificantLoanThreshold(uint256 newValue_) external;

    /**
     * @notice Sets a new state for useProcessingState
     * @dev RESTRICTION: Admin only
     */
    function setProcessingStateUsage(bool newValue_) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./ILinkageLeaf.sol";

interface IBDSystem is IAccessControl, ILinkageLeaf {
    event AgreementAdded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 startBlock,
        uint32 endBlock
    );
    event AgreementEnded(
        address indexed liquidityProvider,
        address indexed representative,
        uint256 representativeBonus,
        uint256 liquidityProviderBoost,
        uint32 endBlock
    );

    /**
     * @notice getter function to get liquidity provider agreement
     */
    function providerToAgreement(address)
        external
        view
        returns (
            uint256 liquidityProviderBoost,
            uint256 representativeBonus,
            uint32 endBlock,
            address representative
        );

    /**
     * @notice getter function to get counts
     *         of liquidity providers of the representative
     */
    function representativesProviderCounter(address) external view returns (uint256);

    /**
     * @notice Creates a new agreement between liquidity provider and representative
     * @dev Admin function to create a new agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the liquidity provider representative.
     * @param representativeBonus_ percentage of the emission boost for representative
     * @param liquidityProviderBoost_ percentage of the boost for liquidity provider
     * @param endBlock_ The number of the first block when agreement will not be in effect
     * @dev RESTRICTION: Admin only
     */
    function createAgreement(
        address liquidityProvider_,
        address representative_,
        uint256 representativeBonus_,
        uint256 liquidityProviderBoost_,
        uint32 endBlock_
    ) external;

    /**
     * @notice Removes a agreement between liquidity provider and representative
     * @dev Admin function to remove a agreement
     * @param liquidityProvider_ address of the liquidity provider
     * @param representative_ address of the representative.
     * @dev RESTRICTION: Admin only
     */
    function removeAgreement(address liquidityProvider_, address representative_) external;

    /**
     * @notice checks if `account_` is liquidity provider.
     * @dev account_ is liquidity provider if he has agreement.
     * @param account_ address to check
     * @return `true` if `account_` is liquidity provider, otherwise returns false
     */
    function isAccountLiquidityProvider(address account_) external view returns (bool);

    /**
     * @notice checks if `account_` is business development representative.
     * @dev account_ is business development representative if he has liquidity providers.
     * @param account_ address to check
     * @return `true` if `account_` is business development representative, otherwise returns false
     */
    function isAccountRepresentative(address account_) external view returns (bool);

    /**
     * @notice checks if agreement is expired
     * @dev reverts if the `account_` is not a valid liquidity provider
     * @param account_ address of the liquidity provider
     * @return `true` if agreement is expired, otherwise returns false
     */
    function isAgreementExpired(address account_) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

interface IWeightAggregator {
    /**
     * @notice Returns MNTs of the account that are used in buyback weight calculation.
     */
    function getAccountFunds(address account) external view returns (uint256);

    /**
     * @notice Returns loyalty factor of the specified account.
     */
    function getLoyaltyFactor(address account) external view returns (uint256);

    /**
     * @notice Returns Buyback weight for the user
     */
    function getBuybackWeight(address account) external view returns (uint256);

    /**
     * @notice Return voting weight for the user
     */
    function getVotingWeight(address account) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

import "./ISupervisor.sol";
import "./IRewardsHub.sol";
import "./IMToken.sol";
import "./ILinkageLeaf.sol";

interface IEmissionBooster is IAccessControl, ILinkageLeaf {
    /**
     * @notice Emitted when new Tier was created
     */
    event NewTierCreated(uint256 createdTier, uint32 endBoostBlock, uint256 emissionBoost);

    /**
     * @notice Emitted when Tier was enabled
     */
    event TierEnabled(
        IMToken market,
        uint256 enabledTier,
        uint32 startBoostBlock,
        uint224 mntSupplyIndex,
        uint224 mntBorrowIndex
    );

    /**
     * @notice Emitted when emission boost mode was enabled
     */
    event EmissionBoostEnabled(address caller);

    /**
     * @notice Emitted when MNT supply index of the tier ending on the market was saved to storage
     */
    event SupplyIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /**
     * @notice Emitted when MNT borrow index of the tier ending on the market was saved to storage
     */
    event BorrowIndexUpdated(address market, uint256 nextTier, uint224 newIndex, uint32 endBlock);

    /**
     * @notice get the Tier for each MinterestNFT token
     */
    function tokenTier(uint256) external view returns (uint256);

    /**
     * @notice get a list of all created Tiers
     */
    function tiers(uint256)
        external
        view
        returns (
            uint32,
            uint32,
            uint256
        );

    /**
     * @notice get status of emission boost mode.
     */
    function isEmissionBoostingEnabled() external view returns (bool);

    /**
     * @notice get Stored markets indexes per block.
     */
    function marketSupplyIndexes(IMToken, uint256) external view returns (uint256);

    /**
     * @notice get Stored markets indexes per block.
     */
    function marketBorrowIndexes(IMToken, uint256) external view returns (uint256);

    /**
     * @notice Mint token hook which is called from MinterestNFT.mint() and sets specific
     *      settings for this NFT
     * @param to_ NFT ovner
     * @param ids_ NFTs IDs
     * @param amounts_ Amounts of minted NFTs per tier
     * @param tiers_ NFT tiers
     * @dev RESTRICTION: MinterestNFT only
     */
    function onMintToken(
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_,
        uint256[] memory tiers_
    ) external;

    /**
     * @notice Transfer token hook which is called from MinterestNFT.transfer() and sets specific
     *      settings for this NFT
     * @param from_ Address of the tokens previous owner. Should not be zero (minter).
     * @param to_ Address of the tokens new owner.
     * @param ids_ NFTs IDs
     * @param amounts_ Amounts of minted NFTs per tier
     * @dev RESTRICTION: MinterestNFT only
     */
    function onTransferToken(
        address from_,
        address to_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    ) external;

    /**
     * @notice Enables emission boost mode.
     * @dev Admin function for enabling emission boosts.
     * @dev RESTRICTION: Whitelist only
     */
    function enableEmissionBoosting() external;

    /**
     * @notice Creates new Tiers for MinterestNFT tokens
     * @dev Admin function for creating Tiers
     * @param endBoostBlocks Emission boost end blocks for created Tiers
     * @param emissionBoosts Emission boosts for created Tiers, scaled by 1e18
     * Note: The arrays passed to the function must be of the same length and the order of the elements must match
     *      each other
     * @dev RESTRICTION: Admin only
     */
    function createTiers(uint32[] memory endBoostBlocks, uint256[] memory emissionBoosts) external;

    /**
     * @notice Enables emission boost in specified Tiers
     * @param tiersForEnabling Tier for enabling emission boost
     * @dev RESTRICTION: Admin only
     */
    function enableTiers(uint256[] memory tiersForEnabling) external;

    /**
     * @notice Return the number of created Tiers
     * @return The number of created Tiers
     */
    function getNumberOfTiers() external view returns (uint256);

    /**
     * @notice Checks if the specified Tier is active
     * @param tier_ The Tier that is being checked
     */
    function isTierActive(uint256 tier_) external view returns (bool);

    /**
     * @notice Checks if the specified Tier exists
     * @param tier_ The Tier that is being checked
     */
    function tierExists(uint256 tier_) external view returns (bool);

    /**
     * @param account_ The address of the account
     * @return Bitmap of all accounts tiers
     */
    function getAccountTiersBitmap(address account_) external view returns (uint256);

    /**
     * @param account_ The address of the account to check if they have any tokens with tier
     */
    function isAccountHaveTiers(address account_) external view returns (bool);

    /**
     * @param account_ Address of the account
     * @return tier Highest tier number
     * @return boost Highest boost amount
     */
    function getCurrentAccountBoost(address account_) external view returns (uint256 tier, uint256 boost);

    /**
     * @notice Calculates emission boost for the account.
     * @param market_ Market for which we are calculating emission boost
     * @param account_ The address of the account for which we are calculating emission boost
     * @param userLastIndex_ The account's last updated mntBorrowIndex or mntSupplyIndex
     * @param userLastBlock_ The block number in which the index for the account was last updated
     * @param marketIndex_ The market's current mntBorrowIndex or mntSupplyIndex
     * @param isSupply_ boolean value, if true, then return calculate emission boost for suppliers
     * @return boostedIndex Boost part of delta index
     */
    function calculateEmissionBoost(
        IMToken market_,
        address account_,
        uint256 userLastIndex_,
        uint256 userLastBlock_,
        uint256 marketIndex_,
        bool isSupply_
    ) external view returns (uint256 boostedIndex);

    /**
     * @notice Update MNT supply index for market for NFT tiers that are expired but not yet updated.
     * @dev This function checks if there are tiers to update and process them one by one:
     *      calculates the MNT supply index depending on the delta index and delta blocks between
     *      last MNT supply index update and the current state,
     *      emits SupplyIndexUpdated event and recalculates next tier to update.
     * @param market Address of the market to update
     * @param lastUpdatedBlock Last updated block number
     * @param lastUpdatedIndex Last updated index value
     * @param currentSupplyIndex Current MNT supply index value
     * @dev RESTRICTION: RewardsHub only
     */
    function updateSupplyIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentSupplyIndex
    ) external;

    /**
     * @notice Update MNT borrow index for market for NFT tiers that are expired but not yet updated.
     * @dev This function checks if there are tiers to update and process them one by one:
     *      calculates the MNT borrow index depending on the delta index and delta blocks between
     *      last MNT borrow index update and the current state,
     *      emits BorrowIndexUpdated event and recalculates next tier to update.
     * @param market Address of the market to update
     * @param lastUpdatedBlock Last updated block number
     * @param lastUpdatedIndex Last updated index value
     * @param currentBorrowIndex Current MNT borrow index value
     * @dev RESTRICTION: RewardsHub only
     */
    function updateBorrowIndexesHistory(
        IMToken market,
        uint256 lastUpdatedBlock,
        uint256 lastUpdatedIndex,
        uint256 currentBorrowIndex
    ) external;

    /**
     * @notice Get Id of NFT tier to update next on provided market MNT index, supply or borrow
     * @param market Market for which should the next Tier to update be updated
     * @param isSupply_ Flag that indicates whether MNT supply or borrow market should be updated
     * @return Id of tier to update
     */
    function getNextTierToBeUpdatedIndex(IMToken market, bool isSupply_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IInterestRateModel.sol";

interface IMToken is IAccessControl, IERC20, IERC3156FlashLender, IERC165 {
    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(
        uint256 cashPrior,
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalProtocolInterest
    );

    /**
     * @notice Event emitted when tokens are lended
     */
    event Lend(address lender, uint256 lendAmount, uint256 lendTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 newTotalTokenSupply);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are seized
     */
    event Seize(
        address borrower,
        address receiver,
        uint256 seizeTokens,
        uint256 accountsTokens,
        uint256 totalSupply,
        uint256 seizeUnderlyingAmount
    );

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is repaid during autoliquidation
     */
    event AutoLiquidationRepayBorrow(
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrowsNew,
        uint256 totalBorrowsNew,
        uint256 TotalProtocolInterestNew
    );

    /**
     * @notice Event emitted when flash loan is executed
     */
    event FlashLoanExecuted(address receiver, uint256 amount, uint256 fee);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(IInterestRateModel oldInterestRateModel, IInterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the protocol interest factor is changed
     */
    event NewProtocolInterestFactor(
        uint256 oldProtocolInterestFactorMantissa,
        uint256 newProtocolInterestFactorMantissa
    );

    /**
     * @notice Event emitted when the flash loan max share is changed
     */
    event NewFlashLoanMaxShare(uint256 oldMaxShare, uint256 newMaxShare);

    /**
     * @notice Event emitted when the flash loan fee is changed
     */
    event NewFlashLoanFee(uint256 oldFee, uint256 newFee);

    /**
     * @notice Event emitted when the protocol interest are added
     */
    event ProtocolInterestAdded(address benefactor, uint256 addAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Event emitted when the protocol interest reduced
     */
    event ProtocolInterestReduced(address admin, uint256 reduceAmount, uint256 newTotalProtocolInterest);

    /**
     * @notice Value is the Keccak-256 hash of "TIMELOCK"
     */
    function TIMELOCK() external view returns (bytes32);

    /**
     * @notice Underlying asset for this MToken
     */
    function underlying() external view returns (IERC20);

    /**
     * @notice EIP-20 token name for this token
     */
    function name() external view returns (string memory);

    /**
     * @notice EIP-20 token symbol for this token
     */
    function symbol() external view returns (string memory);

    /**
     * @notice EIP-20 token decimals for this token
     */
    function decimals() external view returns (uint8);

    /**
     * @notice Model which tells what the current interest rate should be
     */
    function interestRateModel() external view returns (IInterestRateModel);

    /**
     * @notice Initial exchange rate used when lending the first MTokens (used when totalTokenSupply = 0)
     */
    function initialExchangeRateMantissa() external view returns (uint256);

    /**
     * @notice Fraction of interest currently set aside for protocol interest
     */
    function protocolInterestFactorMantissa() external view returns (uint256);

    /**
     * @notice Block number that interest was last accrued at
     */
    function accrualBlockNumber() external view returns (uint256);

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    function borrowIndex() external view returns (uint256);

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    function totalBorrows() external view returns (uint256);

    /**
     * @notice Total amount of protocol interest of the underlying held in this market
     */
    function totalProtocolInterest() external view returns (uint256);

    /**
     * @notice Share of market's current underlying token balance that can be used as flash loan (scaled by 1e18).
     */
    function maxFlashLoanShare() external view returns (uint256);

    /**
     * @notice Share of flash loan amount that would be taken as fee (scaled by 1e18).
     */
    function flashLoanFeeShare() external view returns (uint256);

    /**
     * @notice Returns total token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external returns (uint256);

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by supervisor to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return (token balance, borrow balance, exchange rate mantissa)
     */
    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Returns the current per-block borrow interest rate for this mToken
     * @return The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current per-block supply interest rate for this mToken
     * @return The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view returns (uint256);

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return The total borrows with interest
     */
    function totalBorrowsCurrent() external returns (uint256);

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's
     *         borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return The calculated balance
     */
    function borrowBalanceCurrent(address account) external returns (uint256);

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return The calculated balance
     */
    function borrowBalanceStored(address account) external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() external returns (uint256);

    /**
     * @notice Calculates the exchange rate from the underlying to the MToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Get cash balance of this mToken in the underlying asset
     * @return The quantity of underlying asset owned by this contract
     */
    function getCash() external view returns (uint256);

    /**
     * @notice Applies accrued interest to total borrows and protocol interest
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     */
    function accrueInterest() external;

    /**
     * @notice Sender supplies assets into the market and receives mTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param lendAmount The amount of the underlying asset to supply
     */
    function lend(uint256 lendAmount) external;

    /**
     * @notice Sender redeems mTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of mTokens to redeem into underlying
     */
    function redeem(uint256 redeemTokens) external;

    /**
     * @notice Redeems all mTokens for account in exchange for the underlying asset.
     * Can only be called within the AML system!
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param account An account that is potentially sanctioned by the AML system
     */
    function redeemByAmlDecision(address account) external;

    /**
     * @notice Sender redeems mTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming mTokens
     */
    function redeemUnderlying(uint256 redeemAmount) external;

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function borrow(uint256 borrowAmount) external;

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     */
    function repayBorrow(uint256 repayAmount) external;

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external;

    /**
     * @notice Liquidator repays a borrow belonging to borrower
     * @param borrower_ the account with the debt being payed off
     * @param repayAmount_ the amount of underlying tokens being returned
     */
    function autoLiquidationRepayBorrow(address borrower_, uint256 repayAmount_) external;

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract.
     *         Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     * @dev RESTRICTION: Admin only.
     */
    function sweepToken(IERC20 token, address admin_) external;

    /**
     * @notice Burns collateral tokens at the borrower's address, transfer underlying assets
     to the DeadDrop or Liquidator address.
     * @dev Called only during an auto liquidation process, msg.sender must be the Liquidation contract.
     * @param borrower_ The account having collateral seized
     * @param seizeUnderlyingAmount_ The number of underlying assets to seize. The caller must ensure
     that the parameter is greater than zero.
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     protocolInterest
     * @param receiver_ Address that receives accounts collateral
     */
    function autoLiquidationSeize(
        address borrower_,
        uint256 seizeUnderlyingAmount_,
        bool isLoanInsignificant_,
        address receiver_
    ) external;

    /**
     * @notice The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @notice The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @notice Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice accrues interest and sets a new protocol interest factor for the protocol
     * @dev Admin function to accrue interest and set a new protocol interest factor
     * @dev RESTRICTION: Timelock only.
     */
    function setProtocolInterestFactor(uint256 newProtocolInterestFactorMantissa) external;

    /**
     * @notice Accrues interest and increase protocol interest by transferring from msg.sender
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterest(uint256 addAmount_) external;

    /**
     * @notice Can only be called by liquidation contract. Increase protocol interest by transferring from payer.
     * @dev Calling code should make sure that accrueInterest() was called before.
     * @param payer_ The address from which the protocol interest will be transferred
     * @param addAmount_ Amount of addition to protocol interest
     */
    function addProtocolInterestBehalf(address payer_, uint256 addAmount_) external;

    /**
     * @notice Accrues interest and reduces protocol interest by transferring to admin
     * @param reduceAmount Amount of reduction to protocol interest
     * @dev RESTRICTION: Admin only.
     */
    function reduceProtocolInterest(uint256 reduceAmount, address admin_) external;

    /**
     * @notice accrues interest and updates the interest rate model using setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @dev RESTRICTION: Timelock only.
     */
    function setInterestRateModel(IInterestRateModel newInterestRateModel) external;

    /**
     * @notice Updates share of markets cash that can be used as maximum amount of flash loan.
     * @param newMax New max amount share
     * @dev RESTRICTION: Timelock only.
     */
    function setFlashLoanMaxShare(uint256 newMax) external;

    /**
     * @notice Updates fee of flash loan.
     * @param newFee New fee share of flash loan
     * @dev RESTRICTION: Timelock only.
     */
    function setFlashLoanFeeShare(uint256 newFee) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IWhitelist is IAccessControl {
    /**
     * @notice The given member was added to the whitelist
     */
    event MemberAdded(address);

    /**
     * @notice The given member was removed from the whitelist
     */
    event MemberRemoved(address);

    /**
     * @notice Protocol operation mode switched
     */
    event WhitelistModeWasTurnedOff();

    /**
     * @notice Amount of maxMembers changed
     */
    event MaxMemberAmountChanged(uint256);

    /**
     * @notice get maximum number of members.
     *      When membership reaches this number, no new members may join.
     */
    function maxMembers() external view returns (uint256);

    /**
     * @notice get the total number of members stored in the map.
     */
    function memberCount() external view returns (uint256);

    /**
     * @notice get protocol operation mode.
     */
    function whitelistModeEnabled() external view returns (bool);

    /**
     * @notice get is account member of whitelist
     */
    function accountMembership(address) external view returns (bool);

    /**
     * @notice get keccak-256 hash of GATEKEEPER role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice Add a new member to the whitelist.
     * @param newAccount The account that is being added to the whitelist.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function addMember(address newAccount) external;

    /**
     * @notice Remove a member from the whitelist.
     * @param accountToRemove The account that is being removed from the whitelist.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function removeMember(address accountToRemove) external;

    /**
     * @notice Disables whitelist mode and enables emission boost mode.
     * @dev RESTRICTION: Admin only.
     */
    function turnOffWhitelistMode() external;

    /**
     * @notice Set a new threshold of participants.
     * @param newThreshold New number of participants.
     * @dev RESTRICTION: Gatekeeper only.
     */
    function setMaxMembers(uint256 newThreshold) external;

    /**
     * @notice Check protocol operation mode. In whitelist mode, only members from whitelist and who have
     *         EmissionBooster can work with protocol.
     * @param who The address of the account to check for participation.
     */
    function isWhitelisted(address who) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title Minterest InterestRateModel Interface
 * @author Minterest
 */
interface IInterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param protocolInterest The total amount of protocol interest the market has
     * @param protocolInterestFactorMantissa The current protocol interest factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 protocolInterest,
        uint256 protocolInterestFactorMantissa
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "./ILiquidation.sol";
import "./IMToken.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IDeadDrop is IAccessControl {
    event WithdrewToProtocolInterest(uint256 amount, IERC20 token, IMToken market);
    event Withdraw(address token, address to, uint256 amount);
    event NewLiquidation(ILiquidation liquidation);
    event NewSwapRouter(ISwapRouter router);
    event NewAllowedWithdrawReceiver(address receiver);
    event NewAllowedBot(address bot);
    event NewAllowedMarket(IERC20 token, IMToken market);
    event AllowedWithdrawReceiverRemoved(address receiver);
    event AllowedBotRemoved(address bot);
    event AllowedMarketRemoved(IERC20 token, IMToken market);
    event Swap(IERC20 tokenIn, IERC20 tokenOut, uint256 spentAmount, uint256 receivedAmount);
    event NewProcessingState(address target, uint256 hashValue, uint256 oldState, uint256 newState);
    event LiquidationFinalised(address target, uint256 hashValue);

    /**
     * @notice get Uniswap SwapRouter
     */
    function swapRouter() external view returns (ISwapRouter);

    /**
     * @notice get Whitelist for markets allowed as a withdrawal destination.
     */
    function allowedMarkets(IERC20) external view returns (IMToken);

    /**
     * @notice get whitelist for users who can be a withdrawal recipients
     */
    function allowedWithdrawReceivers(address) external view returns (bool);

    /**
     * @notice get keccak-256 hash of gatekeeper role
     */
    function GATEKEEPER() external view returns (bytes32);

    /**
     * @notice Perform swap on Uniswap DEX
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState operation code that should precede the current operation
     * @param targetState operation code that will be assigned after successful swap
     * @param tokenIn input token
     * @param tokenInAmount amount of input token
     * @param tokenOut output token
     * @param data Uniswap calldata
     * @dev RESTRICTION: Gatekeeper only
     */
    function performSwap(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        IERC20 tokenIn,
        uint256 tokenInAmount,
        IERC20 tokenOut,
        bytes calldata data
    ) external;

    /**
     * @notice Withdraw underlying asset to market's protocol interest
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState operation code that should precede the current operation
     * @param targetState operation code that will be assigned after successful withdrawal
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @dev RESTRICTION: Gatekeeper only
     */
    function withdrawToProtocolInterest(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState,
        uint256 targetState,
        uint256 amount,
        IERC20 underlying
    ) external;

    /**
     * @notice Set processing state of started liquidation
     * @param target Address of the account under liquidation
     * @param hashValue Liquidation identity hash
     * @dev RESTRICTION: Liquidator contract only
     */
    function initialiseLiquidation(address target, uint256 hashValue) external;

    /**
     * @notice Update processing state of ongoing liquidation
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param targetState New state value of the liquidation
     * @dev RESTRICTION: Gatekeeper only
     */
    function updateProcessingState(
        address validationKey,
        uint256 validationHash,
        uint256 targetState
    ) external;

    /**
     * @notice Finalise processing state of ongoing liquidation
     * @param validationKey first part of the key used for onchain validation
     * @param validationHash second part of the key used for onchain validation
     * @param requiredState State value required to complete finalization
     * @dev RESTRICTION: Gatekeeper only
     */
    function finaliseLiquidation(
        address validationKey,
        uint256 validationHash,
        uint256 requiredState
    ) external;

    /**
     * @notice Withdraw tokens to the wallet
     * @param amount Amount to withdraw
     * @param underlying Token to withdraw
     * @param to Receipient address
     * @dev RESTRICTION: Admin only
     */
    function withdraw(
        uint256 amount,
        IERC20 underlying,
        address to
    ) external;

    /**
     * @notice Add new market to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedMarket(IMToken market) external;

    /**
     * @notice Set new ILiquidation contract
     * @dev RESTRICTION: Admin only
     */
    function setLiquidationAddress(ILiquidation liquidationContract) external;

    /**
     * @notice Set new ISwapRouter router
     * @dev RESTRICTION: Admin only
     */
    function setRouterAddress(ISwapRouter router) external;

    /**
     * @notice Add new withdraw receiver address to the whitelist
     * @dev RESTRICTION: TIMELOCK only
     */
    function addAllowedReceiver(address receiver) external;

    /**
     * @notice Add new bot address to the whitelist
     * @dev RESTRICTION: Admin only
     */
    function addAllowedBot(address bot) external;

    /**
     * @notice Remove market from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedMarket(IERC20 underlying) external;

    /**
     * @notice Remove withdraw receiver address from the whitelist
     * @dev RESTRICTION: TIMELOCK only
     */
    function removeAllowedReceiver(address receiver) external;

    /**
     * @notice Remove withdraw bot address from the whitelist
     * @dev RESTRICTION: Admin only
     */
    function removeAllowedBot(address bot) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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