// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./Exponential.sol";
import "./SafeMath.sol";

interface IJToken {
    function balanceOf(address owner) external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);
}

interface IJoetroller {
    function isMarketListed(address jTokenAddress) external view returns (bool);

    function getAllMarkets() external view returns (IJToken[] memory);

    function rewardDistributor() external view returns (address);
}

contract RewardDistributorStorageV2 {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Active brains of Unitroller
    IJoetroller public joetroller;

    struct RewardMarketState {
        /// @notice The market's last updated joeBorrowIndex or joeSupplyIndex
        uint208 index;
        /// @notice The timestamp number the index was last updated at
        uint48 timestamp;
    }

    /// @notice The portion of supply reward rate that each market currently receives
    mapping(uint8 => mapping(address => uint256)) public rewardSupplySpeeds;

    /// @notice The portion of borrow reward rate that each market currently receives
    mapping(uint8 => mapping(address => uint256)) public rewardBorrowSpeeds;

    /// @notice The JOE/AVAX market supply state for each market
    mapping(uint8 => mapping(address => RewardMarketState)) public rewardSupplyState;

    /// @notice The JOE/AVAX market borrow state for each market
    mapping(uint8 => mapping(address => RewardMarketState)) public rewardBorrowState;

    /// @notice The JOE/AVAX borrow index for each market for each supplier as of the last time they accrued reward
    mapping(uint8 => mapping(address => mapping(address => uint256))) public rewardSupplierIndex;

    /// @notice The JOE/AVAX borrow index for each market for each borrower as of the last time they accrued reward
    mapping(uint8 => mapping(address => mapping(address => uint256))) public rewardBorrowerIndex;

    /// @notice The JOE/AVAX accrued but not yet transferred to each user
    mapping(uint8 => mapping(address => uint256)) public rewardAccrued;

    /// @notice JOE token contract address
    EIP20Interface public joe;

    /// @notice If initializeRewardAccrued is locked
    bool public isInitializeRewardAccruedLocked;
}

contract RewardDistributorV2 is RewardDistributorStorageV2, Exponential {
    using SafeMath for uint256;

    /// @notice Emitted when a new reward supply speed is calculated for a market
    event RewardSupplySpeedUpdated(uint8 rewardType, IJToken indexed jToken, uint256 newSpeed);

    /// @notice Emitted when a new reward borrow speed is calculated for a market
    event RewardBorrowSpeedUpdated(uint8 rewardType, IJToken indexed jToken, uint256 newSpeed);

    /// @notice Emitted when JOE/AVAX is distributed to a supplier
    event DistributedSupplierReward(
        uint8 rewardType,
        IJToken indexed jToken,
        address indexed supplier,
        uint256 rewardDelta,
        uint256 rewardSupplyIndex
    );

    /// @notice Emitted when JOE/AVAX is distributed to a borrower
    event DistributedBorrowerReward(
        uint8 rewardType,
        IJToken indexed jToken,
        address indexed borrower,
        uint256 rewardDelta,
        uint256 rewardBorrowIndex
    );

    /// @notice Emitted when JOE is granted by admin
    event RewardGranted(uint8 rewardType, address recipient, uint256 amount);

    /// @notice Emitted when Joe address is changed by admin
    event JoeSet(EIP20Interface indexed joe);

    /// @notice Emitted when Joetroller address is changed by admin
    event JoetrollerSet(IJoetroller indexed newJoetroller);

    /// @notice Emitted when admin is transfered
    event AdminTransferred(address oldAdmin, address newAdmin);

    /// @notice Emitted when accruedRewards is set
    event AccruedRewardsSet(uint8 rewardType, address indexed user, uint256 amount);

    /// @notice Emitted when the setAccruedRewardsForUsers function is locked
    event InitializeRewardAccruedLocked();

    /**
     * @notice Checks if caller is admin
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    /**
     * @notice Checks if caller is joetroller or admin
     */
    modifier onlyJoetrollerOrAdmin() {
        require(msg.sender == address(joetroller) || msg.sender == admin, "only joetroller or admin");
        _;
    }

    /**
     * @notice Checks that reward type is valid
     */
    modifier verifyRewardType(uint8 rewardType) {
        require(rewardType <= 1, "rewardType is invalid");
        _;
    }

    /**
     * @notice Initialize function, in 2 times to avoid redeploying joetroller
     * @dev first call is made by the deploy script, the second one by joeTroller
     * when calling `_setRewardDistributor`
     */
    function initialize() public {
        require(address(joetroller) == address(0), "already initialized");
        if (admin == address(0)) {
            admin = msg.sender;
        } else {
            joetroller = IJoetroller(msg.sender);
        }
    }

    /**
     * @notice Payable function needed to receive AVAX
     */
    function() external payable {}

    /*** User functions ***/

    /**
     * @notice Claim all the JOE/AVAX accrued by holder in all markets
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to claim JOE/AVAX for
     */
    function claimReward(uint8 rewardType, address payable holder) external {
        _claimReward(rewardType, holder, joetroller.getAllMarkets(), true, true);
    }

    /**
     * @notice Claim all the JOE/AVAX accrued by holder in the specified markets
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to claim JOE/AVAX for
     * @param jTokens The list of markets to claim JOE/AVAX in
     */
    function claimReward(
        uint8 rewardType,
        address payable holder,
        IJToken[] calldata jTokens
    ) external {
        _claimReward(rewardType, holder, jTokens, true, true);
    }

    /**
     * @notice Claim all JOE/AVAX accrued by the holders
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holders The addresses to claim JOE/AVAX for
     * @param jTokens The list of markets to claim JOE/AVAX in
     * @param borrowers Whether or not to claim JOE/AVAX earned by borrowing
     * @param suppliers Whether or not to claim JOE/AVAX earned by supplying
     */
    function claimReward(
        uint8 rewardType,
        address payable[] calldata holders,
        IJToken[] calldata jTokens,
        bool borrowers,
        bool suppliers
    ) external {
        uint256 len = holders.length;
        for (uint256 i; i < len; i++) {
            _claimReward(rewardType, holders[i], jTokens, borrowers, suppliers);
        }
    }

    /**
     * @notice Returns the pending JOE/AVAX reward accrued by the holder
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to check pending JOE/AVAX for
     * @return pendingReward The pending JOE/AVAX reward of that holder
     */
    function pendingReward(uint8 rewardType, address holder) external view returns (uint256) {
        return _pendingReward(rewardType, holder, joetroller.getAllMarkets());
    }

    /*** Joetroller Or Joe Distribution Admin ***/

    /**
     * @notice Refactored function to calc and rewards accounts supplier rewards
     * @param jToken The market to verify the mint against
     * @param supplier The supplier to be rewarded
     */
    function updateAndDistributeSupplierRewardsForToken(IJToken jToken, address supplier)
        external
        onlyJoetrollerOrAdmin
    {
        for (uint8 rewardType; rewardType <= 1; rewardType++) {
            _updateRewardSupplyIndex(rewardType, jToken);
            uint256 reward = _distributeSupplierReward(rewardType, jToken, supplier);
            rewardAccrued[rewardType][supplier] = rewardAccrued[rewardType][supplier].add(reward);
        }
    }

    /**
     * @notice Refactored function to calc and rewards accounts borrower rewards
     * @param jToken The market to verify the mint against
     * @param borrower Borrower to be rewarded
     * @param marketBorrowIndex Current index of the borrow market
     */
    function updateAndDistributeBorrowerRewardsForToken(
        IJToken jToken,
        address borrower,
        Exp calldata marketBorrowIndex
    ) external onlyJoetrollerOrAdmin {
        for (uint8 rewardType; rewardType <= 1; rewardType++) {
            _updateRewardBorrowIndex(rewardType, jToken, marketBorrowIndex.mantissa);
            uint256 reward = _distributeBorrowerReward(rewardType, jToken, borrower, marketBorrowIndex.mantissa);
            rewardAccrued[rewardType][borrower] = rewardAccrued[rewardType][borrower].add(reward);
        }
    }

    /*** Joe Distribution Admin ***/

    /**
     * @notice Set JOE/AVAX speed for a single market
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose reward speed to update
     * @param rewardSupplySpeed New reward supply speed for market
     * @param rewardBorrowSpeed New reward borrow speed for market
     */
    function setRewardSpeed(
        uint8 rewardType,
        IJToken jToken,
        uint256 rewardSupplySpeed,
        uint256 rewardBorrowSpeed
    ) external onlyAdmin verifyRewardType(rewardType) {
        _setRewardSupplySpeed(rewardType, jToken, rewardSupplySpeed);
        _setRewardBorrowSpeed(rewardType, jToken, rewardBorrowSpeed);
    }

    /**
     * @notice Transfer JOE/AVAX to the recipient
     * @dev Note: If there is not enough JOE, we do not perform the transfer at all.
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param recipient The address of the recipient to transfer JOE to
     * @param amount The amount of JOE to (possibly) transfer
     */
    function grantReward(
        uint8 rewardType,
        address payable recipient,
        uint256 amount
    ) external onlyAdmin verifyRewardType(rewardType) {
        uint256 amountLeft = _grantReward(rewardType, recipient, amount);
        require(amountLeft == 0, "insufficient joe for grant");
        emit RewardGranted(rewardType, recipient, amount);
    }

    /**
     * @notice Set the JOE token address
     * @param _joe The JOE token address
     */
    function setJoe(EIP20Interface _joe) external onlyAdmin {
        joe = _joe;
        emit JoeSet(_joe);
    }

    /**
     * @notice Set the Joetroller address
     * @param _joetroller The Joetroller address
     */
    function setJoetroller(IJoetroller _joetroller) external onlyAdmin {
        joetroller = _joetroller;
        emit JoetrollerSet(_joetroller);
    }

    /**
     * @notice Set the admin
     * @param newAdmin The address of the new admin
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    /**
     * @notice Initialize rewardAccrued of users for the first time
     * @dev We initialize rewardAccrued to transfer pending rewards from previous rewarder to this one.
     * Must call lockInitializeRewardAccrued() after initialization.
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param users The list of addresses of users that did not claim their rewards
     * @param amounts The list of amounts of unclaimed rewards
     */
    function initializeRewardAccrued(
        uint8 rewardType,
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyAdmin verifyRewardType(rewardType) {
        require(!isInitializeRewardAccruedLocked, "initializeRewardAccrued is locked");
        uint256 len = users.length;
        require(len == amounts.length, "length mismatch");
        for (uint256 i; i < len; i++) {
            address user = users[i];
            uint256 amount = amounts[i];
            rewardAccrued[rewardType][user] = amount;
            emit AccruedRewardsSet(rewardType, user, amount);
        }
    }

    /**
     * @notice Lock the initializeRewardAccrued function
     */
    function lockInitializeRewardAccrued() external onlyAdmin {
        isInitializeRewardAccruedLocked = true;
        emit InitializeRewardAccruedLocked();
    }

    /*** Private functions ***/

    /**
     * @notice Set JOE/AVAX supply speed
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose speed to update
     * @param newRewardSupplySpeed New JOE or AVAX supply speed for market
     */
    function _setRewardSupplySpeed(
        uint8 rewardType,
        IJToken jToken,
        uint256 newRewardSupplySpeed
    ) private {
        // Handle new supply speed
        uint256 currentRewardSupplySpeed = rewardSupplySpeeds[rewardType][address(jToken)];

        if (currentRewardSupplySpeed != 0) {
            // note that JOE speed could be set to 0 to halt liquidity rewards for a market
            _updateRewardSupplyIndex(rewardType, jToken);
        } else if (newRewardSupplySpeed != 0) {
            // Add the JOE market
            require(joetroller.isMarketListed(address(jToken)), "reward market is not listed");
            rewardSupplyState[rewardType][address(jToken)].timestamp = _safe48(_getBlockTimestamp());
        }

        if (currentRewardSupplySpeed != newRewardSupplySpeed) {
            rewardSupplySpeeds[rewardType][address(jToken)] = newRewardSupplySpeed;
            emit RewardSupplySpeedUpdated(rewardType, jToken, newRewardSupplySpeed);
        }
    }

    /**
     * @notice Set JOE/AVAX borrow speed
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose speed to update
     * @param newRewardBorrowSpeed New JOE or AVAX borrow speed for market
     */
    function _setRewardBorrowSpeed(
        uint8 rewardType,
        IJToken jToken,
        uint256 newRewardBorrowSpeed
    ) private {
        // Handle new borrow speed
        uint256 currentRewardBorrowSpeed = rewardBorrowSpeeds[rewardType][address(jToken)];

        if (currentRewardBorrowSpeed != 0) {
            // note that JOE speed could be set to 0 to halt liquidity rewards for a market
            _updateRewardBorrowIndex(rewardType, jToken, jToken.borrowIndex());
        } else if (newRewardBorrowSpeed != 0) {
            // Add the JOE market
            require(joetroller.isMarketListed(address(jToken)), "reward market is not listed");
            rewardBorrowState[rewardType][address(jToken)].timestamp = _safe48(_getBlockTimestamp());
        }

        if (currentRewardBorrowSpeed != newRewardBorrowSpeed) {
            rewardBorrowSpeeds[rewardType][address(jToken)] = newRewardBorrowSpeed;
            emit RewardBorrowSpeedUpdated(rewardType, jToken, newRewardBorrowSpeed);
        }
    }

    /**
     * @notice Accrue JOE/AVAX to the market by updating the supply index
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose supply index to update
     */
    function _updateRewardSupplyIndex(uint8 rewardType, IJToken jToken) private verifyRewardType(rewardType) {
        (uint208 supplyIndex, bool update) = _getUpdatedRewardSupplyIndex(rewardType, jToken);

        if (update) {
            rewardSupplyState[rewardType][address(jToken)].index = supplyIndex;
        }
        rewardSupplyState[rewardType][address(jToken)].timestamp = _safe48(_getBlockTimestamp());
    }

    /**
     * @notice Accrue JOE/AVAX to the market by updating the borrow index
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose borrow index to update
     * @param marketBorrowIndex Current index of the borrow market
     */
    function _updateRewardBorrowIndex(
        uint8 rewardType,
        IJToken jToken,
        uint256 marketBorrowIndex
    ) private verifyRewardType(rewardType) {
        (uint208 borrowIndex, bool update) = _getUpdatedRewardBorrowIndex(rewardType, jToken, marketBorrowIndex);

        if (update) {
            rewardBorrowState[rewardType][address(jToken)].index = borrowIndex;
        }
        rewardBorrowState[rewardType][address(jToken)].timestamp = _safe48(_getBlockTimestamp());
    }

    /**
     * @notice Calculate JOE/AVAX accrued by a supplier
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute JOE/AVAX to
     * @return supplierReward The JOE/AVAX amount of reward from market
     */
    function _distributeSupplierReward(
        uint8 rewardType,
        IJToken jToken,
        address supplier
    ) private verifyRewardType(rewardType) returns (uint208) {
        uint256 supplyIndex = rewardSupplyState[rewardType][address(jToken)].index;
        uint256 supplierIndex = rewardSupplierIndex[rewardType][address(jToken)][supplier];

        uint256 deltaIndex = supplyIndex.sub(supplierIndex);
        uint256 supplierAmount = jToken.balanceOf(supplier);
        uint208 supplierReward = _safe208(supplierAmount.mul(deltaIndex).div(doubleScale));

        if (supplyIndex != supplierIndex) {
            rewardSupplierIndex[rewardType][address(jToken)][supplier] = supplyIndex;
        }
        emit DistributedSupplierReward(rewardType, jToken, supplier, supplierReward, supplyIndex);
        return supplierReward;
    }

    /**
     * @notice Calculate JOE/AVAX accrued by a borrower
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute JOE/AVAX to
     * @param marketBorrowIndex Current index of the borrow market
     * @return borrowerReward The JOE/AVAX amount of reward from market
     */
    function _distributeBorrowerReward(
        uint8 rewardType,
        IJToken jToken,
        address borrower,
        uint256 marketBorrowIndex
    ) private verifyRewardType(rewardType) returns (uint208) {
        uint256 borrowIndex = rewardBorrowState[rewardType][address(jToken)].index;
        uint256 borrowerIndex = rewardBorrowerIndex[rewardType][address(jToken)][borrower];

        uint256 deltaIndex = borrowIndex.sub(borrowerIndex);
        uint256 borrowerAmount = jToken.borrowBalanceStored(borrower).mul(expScale).div(marketBorrowIndex);
        uint208 borrowerReward = _safe208(borrowerAmount.mul(deltaIndex).div(doubleScale));

        if (borrowIndex != borrowerIndex) {
            rewardBorrowerIndex[rewardType][address(jToken)][borrower] = borrowIndex;
        }
        emit DistributedBorrowerReward(rewardType, jToken, borrower, borrowerReward, borrowIndex);
        return borrowerReward;
    }

    /**
     * @notice Claim all JOE/AVAX accrued by the holders
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to claim JOE/AVAX for
     * @param jTokens The list of markets to claim JOE/AVAX in
     * @param borrower Whether or not to claim JOE/AVAX earned by borrowing
     * @param supplier Whether or not to claim JOE/AVAX earned by supplying
     */
    function _claimReward(
        uint8 rewardType,
        address payable holder,
        IJToken[] memory jTokens,
        bool borrower,
        bool supplier
    ) private verifyRewardType(rewardType) {
        uint256 rewards = rewardAccrued[rewardType][holder];
        uint256 len = jTokens.length;
        for (uint256 i; i < len; i++) {
            IJToken jToken = jTokens[i];
            require(joetroller.isMarketListed(address(jToken)), "market must be listed");

            if (borrower) {
                uint256 marketBorrowIndex = jToken.borrowIndex();
                _updateRewardBorrowIndex(rewardType, jToken, marketBorrowIndex);
                uint256 reward = _distributeBorrowerReward(rewardType, jToken, holder, marketBorrowIndex);
                rewards = rewards.add(reward);
            }
            if (supplier) {
                _updateRewardSupplyIndex(rewardType, jToken);
                uint256 reward = _distributeSupplierReward(rewardType, jToken, holder);
                rewards = rewards.add(reward);
            }
        }
        if (rewards != 0) {
            rewardAccrued[rewardType][holder] = _grantReward(rewardType, holder, rewards);
        }
    }

    /**
     * @notice Returns the pending JOE/AVAX reward for holder
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to return the pending JOE/AVAX reward for
     * @param jTokens The markets to return the pending JOE/AVAX reward in
     * @return uint256 The JOE/AVAX reward for that user
     */
    function _pendingReward(
        uint8 rewardType,
        address holder,
        IJToken[] memory jTokens
    ) private view verifyRewardType(rewardType) returns (uint256) {
        uint256 rewards = rewardAccrued[rewardType][holder];
        uint256 len = jTokens.length;

        for (uint256 i; i < len; i++) {
            IJToken jToken = jTokens[i];

            uint256 supplierReward = _pendingSupplyReward(rewardType, jToken, holder);
            uint256 borrowerReward = _pendingBorrowReward(rewardType, jToken, holder, jToken.borrowIndex());

            rewards = rewards.add(supplierReward).add(borrowerReward);
        }

        return rewards;
    }

    /**
     * @notice Returns the pending JOE/AVAX reward for a supplier on a market
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to return the pending JOE/AVAX reward for
     * @param jToken The market to return the pending JOE/AVAX reward in
     * @return uint256 The JOE/AVAX reward for that user
     */
    function _pendingSupplyReward(
        uint8 rewardType,
        IJToken jToken,
        address holder
    ) private view returns (uint256) {
        (uint256 supplyIndex, ) = _getUpdatedRewardSupplyIndex(rewardType, jToken);
        uint256 supplierIndex = rewardSupplierIndex[rewardType][address(jToken)][holder];

        uint256 deltaIndex = supplyIndex.sub(supplierIndex);
        uint256 supplierAmount = jToken.balanceOf(holder);
        return supplierAmount.mul(deltaIndex).div(doubleScale);
    }

    /**
     * @notice Returns the pending JOE/AVAX reward for a borrower on a market
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param holder The address to return the pending JOE/AVAX reward for
     * @param jToken The market to return the pending JOE/AVAX reward in
     * @param marketBorrowIndex Current index of the borrow market
     * @return uint256 The JOE/AVAX reward for that user
     */
    function _pendingBorrowReward(
        uint8 rewardType,
        IJToken jToken,
        address holder,
        uint256 marketBorrowIndex
    ) private view returns (uint256) {
        (uint256 borrowIndex, ) = _getUpdatedRewardBorrowIndex(rewardType, jToken, marketBorrowIndex);
        uint256 borrowerIndex = rewardBorrowerIndex[rewardType][address(jToken)][holder];

        uint256 deltaIndex = borrowIndex.sub(borrowerIndex);
        uint256 borrowerAmount = jToken.borrowBalanceStored(holder).mul(expScale).div(marketBorrowIndex);

        return borrowerAmount.mul(deltaIndex).div(doubleScale);
    }

    /**
     * @notice Returns the updated reward supply index
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose supply index to update
     * @return uint208 The updated supply state index
     * @return bool If the stored supply state index needs to be updated
     */
    function _getUpdatedRewardSupplyIndex(uint8 rewardType, IJToken jToken) private view returns (uint208, bool) {
        RewardMarketState memory supplyState = rewardSupplyState[rewardType][address(jToken)];
        uint256 supplySpeed = rewardSupplySpeeds[rewardType][address(jToken)];
        uint256 deltaTimestamps = _getBlockTimestamp().sub(supplyState.timestamp);

        if (deltaTimestamps != 0 && supplySpeed != 0) {
            uint256 supplyTokens = jToken.totalSupply();
            if (supplyTokens != 0) {
                uint256 reward = deltaTimestamps.mul(supplySpeed);
                supplyState.index = _safe208(uint256(supplyState.index).add(reward.mul(doubleScale).div(supplyTokens)));
                return (supplyState.index, true);
            }
        }
        return (supplyState.index, false);
    }

    /**
     * @notice Returns the updated reward borrow index
     * @param rewardType 0 = JOE, 1 = AVAX
     * @param jToken The market whose borrow index to update
     * @param marketBorrowIndex Current index of the borrow market
     * @return uint208 The updated borrow state index
     * @return bool If the stored borrow state index needs to be updated
     */
    function _getUpdatedRewardBorrowIndex(
        uint8 rewardType,
        IJToken jToken,
        uint256 marketBorrowIndex
    ) private view returns (uint208, bool) {
        RewardMarketState memory borrowState = rewardBorrowState[rewardType][address(jToken)];
        uint256 borrowSpeed = rewardBorrowSpeeds[rewardType][address(jToken)];
        uint256 deltaTimestamps = _getBlockTimestamp().sub(borrowState.timestamp);

        if (deltaTimestamps != 0 && borrowSpeed != 0) {
            uint256 totalBorrows = jToken.totalBorrows();
            uint256 borrowAmount = totalBorrows.mul(expScale).div(marketBorrowIndex);
            if (borrowAmount != 0) {
                uint256 reward = deltaTimestamps.mul(borrowSpeed);
                borrowState.index = _safe208(uint256(borrowState.index).add(reward.mul(doubleScale).div(borrowAmount)));
                return (borrowState.index, true);
            }
        }
        return (borrowState.index, false);
    }

    /**
     * @notice Transfer JOE/AVAX to the user
     * @dev Note: If there is not enough JOE/AVAX, we do not perform the transfer at all.
     * @param rewardType 0 = JOE, 1 = AVAX.
     * @param user The address of the user to transfer JOE/AVAX to
     * @param amount The amount of JOE/AVAX to (possibly) transfer
     * @return uint256 The amount of JOE/AVAX which was NOT transferred to the user
     */
    function _grantReward(
        uint8 rewardType,
        address payable user,
        uint256 amount
    ) private returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (rewardType == 0) {
            uint256 joeRemaining = joe.balanceOf(address(this));
            if (amount <= joeRemaining) {
                joe.transfer(user, amount);
                return 0;
            }
        } else if (rewardType == 1) {
            uint256 avaxRemaining = address(this).balance;
            if (amount <= avaxRemaining) {
                user.transfer(amount);
                return 0;
            }
        }
        return amount;
    }

    /**
     * @notice Function to get the current timestamp
     * @return uint256 The current timestamp
     */
    function _getBlockTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Return x written on 48 bits while asserting that x doesn't exceed 48 bits
     * @param x The value
     * @return uint48 The value x on 48 bits
     */
    function _safe48(uint256 x) private pure returns (uint48) {
        require(x < 2**48, "exceeds 48 bits");
        return uint48(x);
    }

    /**
     * @notice Return x written on 208 bits while asserting that x doesn't exceed 208 bits
     * @param x The value
     * @return uint208 The value x on 208 bits
     */
    function _safe208(uint256 x) private pure returns (uint208) {
        require(x < 2**208, "exceeds 208 bits");
        return uint208(x);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool success);

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
    ) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

import "./CarefulMath.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract Exponential is CarefulMath {
    uint256 constant expScale = 1e18;
    uint256 constant doubleScale = 1e36;
    uint256 constant halfExpScale = expScale / 2;
    uint256 constant mantissaOne = expScale;

    struct Exp {
        uint256 mantissa;
    }

    struct Double {
        uint256 mantissa;
    }

    /**
     * @dev Creates an exponential from numerator and denominator values.
     *      Note: Returns an error if (`num` * 10e18) > MAX_INT,
     *            or if `denom` is zero.
     */
    function getExp(uint256 num, uint256 denom) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledNumerator) = mulUInt(num, expScale);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        (MathError err1, uint256 rational) = divUInt(scaledNumerator, denom);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: rational}));
    }

    /**
     * @dev Adds two exponentials, returning a new exponential.
     */
    function addExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = addUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Subtracts two exponentials, returning a new exponential.
     */
    function subExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError error, uint256 result) = subUInt(a.mantissa, b.mantissa);

        return (error, Exp({mantissa: result}));
    }

    /**
     * @dev Multiply an Exp by a scalar, returning a new Exp.
     */
    function mulScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 scaledMantissa) = mulUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: scaledMantissa}));
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(product));
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mulScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory product) = mulScalar(a, scalar);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return addUInt(truncate(product), addend);
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Divide an Exp by a scalar, returning a new Exp.
     */
    function divScalar(Exp memory a, uint256 scalar) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 descaledMantissa) = divUInt(a.mantissa, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        return (MathError.NO_ERROR, Exp({mantissa: descaledMantissa}));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (MathError, Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        (MathError err0, uint256 numerator) = mulUInt(expScale, scalar);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }
        return getExp(numerator, divisor.mantissa);
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (MathError, uint256) {
        (MathError err, Exp memory fraction) = divScalarByExp(scalar, divisor);
        if (err != MathError.NO_ERROR) {
            return (err, 0);
        }

        return (MathError.NO_ERROR, truncate(fraction));
    }

    /**
     * @dev Divide a scalar by an Exp, returning a new Exp.
     */
    function div_ScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (Exp memory) {
        /*
          We are doing this as:
          getExp(mulUInt(expScale, scalar), divisor.mantissa)

          How it works:
          Exp = a / b;
          Scalar = s;
          `s / (a / b)` = `b * s / a` and since for an Exp `a = mantissa, b = expScale`
        */
        uint256 numerator = mul_(expScale, scalar);
        return Exp({mantissa: div_(numerator, divisor)});
    }

    /**
     * @dev Divide a scalar by an Exp, then truncate to return an unsigned integer.
     */
    function div_ScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (uint256) {
        Exp memory fraction = div_ScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    /**
     * @dev Multiplies two exponentials, returning a new exponential.
     */
    function mulExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        (MathError err0, uint256 doubleScaledProduct) = mulUInt(a.mantissa, b.mantissa);
        if (err0 != MathError.NO_ERROR) {
            return (err0, Exp({mantissa: 0}));
        }

        // We add half the scale before dividing so that we get rounding instead of truncation.
        //  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717
        // Without this change, a result like 6.6...e-19 will be truncated to 0 instead of being rounded to 1e-18.
        (MathError err1, uint256 doubleScaledProductWithHalfScale) = addUInt(halfExpScale, doubleScaledProduct);
        if (err1 != MathError.NO_ERROR) {
            return (err1, Exp({mantissa: 0}));
        }

        (MathError err2, uint256 product) = divUInt(doubleScaledProductWithHalfScale, expScale);
        // The only error `div` can return is MathError.DIVISION_BY_ZERO but we control `expScale` and it is not zero.
        assert(err2 == MathError.NO_ERROR);

        return (MathError.NO_ERROR, Exp({mantissa: product}));
    }

    /**
     * @dev Multiplies two exponentials given their mantissas, returning a new exponential.
     */
    function mulExp(uint256 a, uint256 b) internal pure returns (MathError, Exp memory) {
        return mulExp(Exp({mantissa: a}), Exp({mantissa: b}));
    }

    /**
     * @dev Multiplies three exponentials, returning a new exponential.
     */
    function mulExp3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (MathError, Exp memory) {
        (MathError err, Exp memory ab) = mulExp(a, b);
        if (err != MathError.NO_ERROR) {
            return (err, ab);
        }
        return mulExp(ab, c);
    }

    /**
     * @dev Divides two exponentials, returning a new exponential.
     *     (a/scale) / (b/scale) = (a/scale) * (scale/b) = a/b,
     *  which we can scale as an Exp by calling getExp(a.mantissa, b.mantissa)
     */
    function divExp(Exp memory a, Exp memory b) internal pure returns (MathError, Exp memory) {
        return getExp(a.mantissa, b.mantissa);
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint256 a, uint256 b) internal pure returns (uint256) {
        return add_(a, b, "addition overflow");
    }

    function add_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint256 a, Double memory b) internal pure returns (uint256) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint256 a, uint256 b) internal pure returns (uint256) {
        return div_(a, b, "divide by zero");
    }

    function div_(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.5.16;

/**
 * @title Careful Math
 * @author Compound
 * @notice Derived from OpenZeppelin's SafeMath library
 *         https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
 */
contract CarefulMath {
    /**
     * @dev Possible error codes that we can return
     */
    enum MathError {
        NO_ERROR,
        DIVISION_BY_ZERO,
        INTEGER_OVERFLOW,
        INTEGER_UNDERFLOW
    }

    /**
     * @dev Multiplies two numbers, returns an error on overflow.
     */
    function mulUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (a == 0) {
            return (MathError.NO_ERROR, 0);
        }

        uint256 c = a * b;

        if (c / a != b) {
            return (MathError.INTEGER_OVERFLOW, 0);
        } else {
            return (MathError.NO_ERROR, c);
        }
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function divUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b == 0) {
            return (MathError.DIVISION_BY_ZERO, 0);
        }

        return (MathError.NO_ERROR, a / b);
    }

    /**
     * @dev Subtracts two numbers, returns an error on overflow (i.e. if subtrahend is greater than minuend).
     */
    function subUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        if (b <= a) {
            return (MathError.NO_ERROR, a - b);
        } else {
            return (MathError.INTEGER_UNDERFLOW, 0);
        }
    }

    /**
     * @dev Adds two numbers, returns an error on overflow.
     */
    function addUInt(uint256 a, uint256 b) internal pure returns (MathError, uint256) {
        uint256 c = a + b;

        if (c >= a) {
            return (MathError.NO_ERROR, c);
        } else {
            return (MathError.INTEGER_OVERFLOW, 0);
        }
    }

    /**
     * @dev add a and b and then subtract c
     */
    function addThenSubUInt(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (MathError, uint256) {
        (MathError err0, uint256 sum) = addUInt(a, b);

        if (err0 != MathError.NO_ERROR) {
            return (err0, 0);
        }

        return subUInt(sum, c);
    }
}