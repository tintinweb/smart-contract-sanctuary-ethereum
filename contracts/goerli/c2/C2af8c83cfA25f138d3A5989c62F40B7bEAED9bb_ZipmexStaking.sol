// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ZipMex Launchpad Staking
 */
contract ZipmexStaking is ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct StakeData {
        uint256 stakeAmount; // Stake Amount
        uint256 lastClaimTime; // Last reward claim time
        uint256 stakeUnlockTime; // Stake Unlock Timestamp
        uint256 rewardPerSecond; // reward for this stake per second
    }

    // Total stake in the platform
    uint256 private _totalStake;

    // Total expected reward in the platform
    uint256 private _totalExpectedBonus;

    // Total bonus pool amount
    uint256 private _bonusPoolAmount;

    // Bonus pool amount threshold
    uint256 private _bonusPoolThreshold;

    // Owner of the contract
    address private _owner;

    // Token contract address
    IERC20Upgradeable private _tokenAddress;

    // Potential owner's address
    address private _potentialOwner;

    // Penalty percentage
    uint256 private _penaltyRate; // 10000 max

    // Penalties collected by the platform
    uint256 private _collectedPenalties;

    // locking period vaults
    uint256[4] private _vaults;

    /** Mappings */

    // staker address => vault => StakeData
    mapping(address => mapping(uint256 => StakeData)) private _stakeData;
    // vault => reward rate
    mapping(uint256 => uint256) private _rewardRate;
    // staker => vault => exist or not
    mapping(address => mapping(uint256 => bool)) private _stakeExist;

    event NominateOwner(address indexed potentialOwner);
    event OwnerChanged(address indexed newOwner);
    event Stake(
        address indexed staker,
        uint256 vault,
        uint256 amount,
        uint256 rewardPerSecond,
        uint256 unStakeTime
    );
    event UnStake(
        address indexed staker,
        uint256 vault,
        uint256 amount,
        uint256 penalty
    );
    event PenaltyWithdraw(address indexed owner, uint256 penaltyAmount);
    event PenaltyRateChanged(uint256 indexed newRate);
    event BonusThresholdChanged(uint256 newThreshold);
    event BonusThresholdReached(
        uint256 currentPoolBalance,
        uint256 currentExpectedReward
    );
    event BonusPoolAmountAdded(uint256 amount, uint256 newBalance);
    event RewardReleased(address indexed staker, uint256 vault, uint256 reward);
    event VaultAdded(
        uint256 indexed vault,
        uint256 indexed lockingPeriod,
        uint256 rewardRate
    );
    event VaultModified(
        uint256 indexed vault,
        uint256 indexed lockingPeriod,
        uint256 rewardRate
    );
    event VaultRemoved(uint256 indexed vault, uint256 indexed lockingPeriod);

    // modifier for checking the owner
    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "ZipmexStaking: Only owner can call this function"
        );
        _;
    }

    // modifier for checking rate
    modifier checkRate(uint256 rate) {
        require(
            rate > 0 && rate <= 10000,
            "ZipmexStaking: In-valid fine percentage"
        );
        _;
    }

    // modifier for checking address
    modifier checkAddress(address account) {
        require(account != address(0), "ZipmexStaking: Zero address");
        _;
    }

    function initialize(
        address tokenAddress_,
        address owner_,
        uint256 penaltyRate_
    )
        external
        initializer
        checkRate(penaltyRate_)
        checkAddress(tokenAddress_)
        checkAddress(owner_)
    {
        _tokenAddress = IERC20Upgradeable(tokenAddress_);
        _owner = owner_;
        _penaltyRate = penaltyRate_;
    }

    /* View Methods Start */

    /**
     * @notice This function is used to get All the stake details for a user
     * @param account address of the staker
     * @return stakeData Struct
     */
    function getAllStakes(address account)
        external
        view
        returns (StakeData[4] memory stakeData)
    {
        for (uint256 i; i < 4; i++) {
            stakeData[i] = _stakeData[account][i];
        }
    }

    /**
     * @notice This function is used to get Stake's details for a particular vault
     * @param account address of the staker
     * @param vault vault number of the stake
     * @return StakeData Struct
     */
    function getStake(address account, uint256 vault)
        external
        view
        returns (StakeData memory)
    {
        require(
            _stakeExist[account][vault] == true,
            "ZipmexStaking: Stake does not exist for the staker for this vault"
        );
        return _stakeData[account][vault];
    }

    /**
     * @notice This function is used to show the reward details for a particular vault
     * @dev this will simply show the reward till that point if they are claiming at that moment
     * @param vault vault number of the stake
     * @return reward Reward till that time
     */
    function showMyReward(uint256 vault)
        external
        view
        returns (uint256 reward)
    {
        _checkStakeExist(vault);
        StakeData memory stakeData = _stakeData[msg.sender][vault];
        reward = _getTotalReward(
            stakeData.rewardPerSecond,
            _getInterval(stakeData.stakeUnlockTime, stakeData.lastClaimTime)
        );
    }

    /**
     * @notice This function is used to get all the vault's details
     */
    function getAllVaults()
        external
        view
        returns (uint256[4] memory lockingPeriod, uint256[4] memory rewardRate)
    {
        for (uint256 i; i < 4; i++) {
            rewardRate[i] = _rewardRate[i];
        }
        lockingPeriod = _vaults;
    }

    /**
     * @notice This function is used to get a particular vault's details
     */
    function getVault(uint256 vault)
        external
        view
        returns (uint256 lockingPeriod, uint256 rewardRate)
    {
        lockingPeriod = _vaults[vault];
        rewardRate = _rewardRate[vault];
    }

    /**
     * @notice This function is used to get the penalty percentage
     * @return _penaltyRate of the platform
     */
    function penaltyRate() external view returns (uint256) {
        return _penaltyRate;
    }

    /**
     * @notice This function is used to get the contract owner's address
     * @return Address of the contract owner
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @notice This function is used to get the potential owner's address
     * @return Address of the potential owner
     */
    function potentialOwner() external view returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice This function is used to get the total staked amount
     * @return _totalStake of the platform
     */
    function totalStake() external view returns (uint256) {
        return _totalStake;
    }

    /**
     * @notice This function is used to get the total expected reward (bonus) amount
     * @return _totalExpectedBonus of the platform
     */
    function totalExpectedBonus() external view returns (uint256) {
        return _totalExpectedBonus;
    }

    /**
     * @notice This function is used to get the remaining bonus pool amount
     * @return _bonusPoolAmount of the platform
     */
    function bonusPoolAmount() external view returns (uint256) {
        return _bonusPoolAmount;
    }

    /**
     * @notice This function is used to get the bonus pool threshold
     * @return _bonusPoolThreshold of the platform
     */
    function bonusPoolThreshold() external view returns (uint256) {
        return _bonusPoolThreshold;
    }

    /**
     * @notice This function is used to get the total collected penalties
     * @return _collectedPenalties of the platform
     */
    function collectedPenalties() external view returns (uint256) {
        return _collectedPenalties;
    }

    /**
     * @notice This function is used to get the token address
     * @return _tokenAddress of the platform
     */
    function tokenAddress() external view returns (IERC20Upgradeable) {
        return _tokenAddress;
    }

    /* View Methods End */

    /* Owner Methods Start */

    /**
     * @notice This function is used to add a vault's Locking period and reward percentage
     * @dev Only the owner can call this function
     * @param rewardRate reward rate to be set
     * @param lockingPeriod Locking period in seconds
     * @param vault vault number
     */
    function addVault(
        uint256 vault,
        uint256 lockingPeriod,
        uint256 rewardRate
    ) external onlyOwner checkRate(rewardRate) {
        require(vault < 4, "ZipmexStaking: Invalid vault");
        require(_rewardRate[vault] == 0, "ZipmexStaking: Vault exist");

        _vaults[vault] = lockingPeriod;
        _rewardRate[vault] = rewardRate;
        emit VaultAdded(vault, lockingPeriod, rewardRate);
    }

    /**
     * @notice This function is used to modify reward rate for a particular vault
     * @dev Only the owner can call this function
     * @param rewardRate reward rate to be set
     * @param lockingPeriod Locking period in seconds
     * @param vault vault number to be modified
     */
    function modifyVault(
        uint256 vault,
        uint256 lockingPeriod,
        uint256 rewardRate
    ) external onlyOwner checkRate(rewardRate) {
        _checkVault(vault);

        _vaults[vault] = lockingPeriod;
        _rewardRate[vault] = rewardRate;
        emit VaultModified(vault, lockingPeriod, rewardRate);
    }

    /**
     * @notice This function is used to remove a particular vault
     * @dev Only the owner can call this function
     * @param vault vault number to be removed
     */
    function removeVault(uint256 vault) external onlyOwner {
        _checkVault(vault);

        uint256 lockingPeriod = _vaults[vault];
        _vaults[vault] = 0;
        delete _rewardRate[vault];

        emit VaultRemoved(vault, lockingPeriod);
    }

    /**
     * @notice This function is used to change penalty rate
     * @dev Only the owner can call this function
     * @param penaltyRate_ reward rate to be set
     */
    function changePenaltyRate(uint256 penaltyRate_)
        external
        onlyOwner
        checkRate(penaltyRate_)
    {
        require(
            _penaltyRate != penaltyRate_,
            "ZipmexStaking: Penalty rate same"
        );

        _penaltyRate = penaltyRate_;
        emit PenaltyRateChanged(penaltyRate_);
    }

    /**
     * @notice This function is used to withdraw all the penalties
     * @dev Only the owner can call this function
     */
    function withdrawPenalties() external onlyOwner nonReentrant {
        require(
            _collectedPenalties > 0,
            "ZipmexStaking: No penalty has been collected"
        );

        uint256 penaltyToTransfer = _collectedPenalties;
        _collectedPenalties = 0;

        emit PenaltyWithdraw(msg.sender, penaltyToTransfer);
        _tokenAddress.safeTransfer(_owner, penaltyToTransfer);
    }

    /**
     * @notice This function is used to add a potential owner of the contract
     * @dev Only the owner can call this function
     * @param potentialOwner_ Address of the potential owner
     */
    function addPotentialOwner(address potentialOwner_)
        external
        onlyOwner
        checkAddress(potentialOwner_)
    {
        require(
            potentialOwner_ != _owner,
            "ZipmexStaking: Potential Owner should not be owner"
        );
        require(
            potentialOwner_ != _potentialOwner,
            "ZipmexStaking: Already a potential owner"
        );
        _potentialOwner = potentialOwner_;
        emit NominateOwner(potentialOwner_);
    }

    /**
     * @notice This function is used to change bonus pool threshold
     * @dev Only the owner can call this function
     * @param bonusThreshold_ new bonus pool threshold
     */
    function changeBonusPoolThreshold(uint256 bonusThreshold_)
        external
        onlyOwner
        checkRate(bonusThreshold_)
    {
        require(
            _bonusPoolThreshold != bonusThreshold_,
            "ZipmexStaking: Bonus threshold same"
        );

        _bonusPoolThreshold = bonusThreshold_;
        emit BonusThresholdChanged(bonusThreshold_);
    }

    /**
     * @notice This function is used to add bonus pool amount
     * @dev Only the owner can call this function
     * @param amount_ amount to be added
     */
    function addBonusPoolAmount(uint256 amount_) external onlyOwner {
        _paymentPrecheck(amount_);

        uint256 bonusAmount_ = _bonusPoolAmount;
        bonusAmount_ += amount_;
        _bonusPoolAmount = bonusAmount_;

        emit BonusPoolAmountAdded(amount_, bonusAmount_);
        _tokenAddress.safeTransferFrom(msg.sender, address(this), amount_);
    }

    /* Owner Methods End */

    /* Potential Owner Methods Start */

    /**
     * @notice This function is used to accept ownership of the contract
     */
    function acceptOwnership() external checkAddress(msg.sender) {
        require(
            msg.sender == _potentialOwner,
            "ZipmexStaking: Only the potential owner can accept ownership"
        );
        _owner = _potentialOwner;
        _potentialOwner = address(0);
        emit OwnerChanged(_owner);
    }

    /* Potential Owner Methods End */

    /* User Methods Start */

    /**
     * @notice This function is used to stake the coins
     * @dev if the stake for the vault already exist then
     * it should add the amount to the existing stake and
     * release reward till that point and re calcualte the reward with
     * new amount and new unlocking period
     * @dev if unlock is over and amount is zero then we need to restake the
     * previous stake amount
     * @param amount Amount of coins to stake
     * @param vault vault number which represents a particular locking period in seconds
     */
    function stake(uint256 amount, uint256 vault) external nonReentrant {
        StakeData memory stakeData = _stakeData[msg.sender][vault];

        _checkVault(vault);

        uint256 rewardToTransfer;
        bool unlockOver;
        // check if stake for this vault already exist
        if (_stakeExist[msg.sender][vault] == true) {
            (, rewardToTransfer, unlockOver) = _getPenaltyAndRewards(
                stakeData,
                false
            );
            // check if unlockover; then if amount is zero then consider the previous staked amount
            if (!unlockOver || amount != 0) {
                _paymentPrecheck(amount);
                stakeData.stakeAmount += amount;
            }
        } else {
            _paymentPrecheck(amount);
            stakeData.stakeAmount += amount;
            _stakeExist[msg.sender][vault] = true;
        }

        // update the stake details
        uint256 rewardRate_ = _rewardRate[vault];
        uint256 lockingPeriod = _vaults[vault];
        uint256 rewardPerSecond = _getReward(
            stakeData.stakeAmount,
            rewardRate_
        );

        uint256 reward = _getTotalReward(rewardPerSecond, lockingPeriod);
        uint256 totalStake_ = _totalStake;
        uint256 totalReward_ = _totalExpectedBonus;
        totalStake_ += amount;
        totalReward_ += reward;

        // check balance of the contract for the reward amount
        require(
            totalReward_ <= _bonusPoolAmount,
            "ZipmexStaking: Insufficient balance in bonus pool"
        );

        stakeData.lastClaimTime = block.timestamp;
        stakeData.stakeUnlockTime = block.timestamp + lockingPeriod;
        stakeData.rewardPerSecond = rewardPerSecond;

        _stakeData[msg.sender][vault] = stakeData;
        _totalStake = totalStake_;
        _totalExpectedBonus = totalReward_;

        emit Stake(
            msg.sender,
            vault,
            stakeData.stakeAmount,
            rewardPerSecond,
            stakeData.stakeUnlockTime
        );

        // check for the bonus pool threshold
        _checkPoolThreshold();

        // transfer the token to the smart contract if amount is not zero
        if (amount > 0) {
            _tokenAddress.safeTransferFrom(msg.sender, address(this), amount);
        }

        // transfer reward if there is any
        if (rewardToTransfer > 0) {
            emit RewardReleased(msg.sender, vault, rewardToTransfer);
            _bonusPoolAmount -= rewardToTransfer;
            _tokenAddress.safeTransfer(msg.sender, rewardToTransfer);
        }
    }

    /**
     * @notice This function is used to unstake the tokens
     * @dev remaining rewards sent along with the amount
     * @dev only full amount unstake option; cannot unstake a particular amount
     * @param vault vault number of the stake which has to be unstake
     */
    function unStake(uint256 vault) external nonReentrant {
        _checkStakeExist(vault);

        StakeData memory stakeData = _stakeData[msg.sender][vault];
        (uint256 penalty, uint256 reward, ) = _getPenaltyAndRewards(
            stakeData,
            true
        );

        uint256 amountToTransfer;
        if (reward > 0) {
            amountToTransfer = stakeData.stakeAmount + reward - penalty;
            _bonusPoolAmount -= reward;
        } else {
            amountToTransfer = stakeData.stakeAmount - penalty;
        }
        _stakeExist[msg.sender][vault] = false;
        _totalStake -= stakeData.stakeAmount;

        emit UnStake(msg.sender, vault, stakeData.stakeAmount, penalty);
        emit RewardReleased(msg.sender, vault, reward);
        delete _stakeData[msg.sender][vault];

        _tokenAddress.safeTransfer(msg.sender, amountToTransfer);
    }

    /**
     * @notice This function is used to claiming the reward for a particular vault's stake
     * @dev we will compute the reward since last claim time
     * @param vault vault number of the stake of which reward has to be claimed
     */
    function claimReward(uint256 vault) external nonReentrant {
        _checkStakeExist(vault);

        StakeData memory stakeData = _stakeData[msg.sender][vault];

        uint256 interval = _getInterval(
            stakeData.stakeUnlockTime,
            stakeData.lastClaimTime
        );

        require(interval > 0, "ZipmexStaking: Zero interval");
        uint256 reward = _getTotalReward(stakeData.rewardPerSecond, interval);

        stakeData.lastClaimTime = block.timestamp;
        _totalExpectedBonus -= reward;
        _bonusPoolAmount -= reward;

        emit RewardReleased(msg.sender, vault, reward);
        _tokenAddress.safeTransfer(msg.sender, reward);
    }

    /* User Methods End */

    /* Internal Helper Methods Start */

    /**
     * @notice function for calculating the reward per second based on APY
     * @dev this is an internal function which is used inside the staking function
     * @param rewardRate reward rate based on the locking period
     * @param amount stake amount
     * @return reward reward per second is returned from this function
     */
    function _getReward(uint256 amount, uint256 rewardRate)
        internal
        pure
        returns (uint256 reward)
    {
        reward = (amount * rewardRate) / (10000 * 365 days);
    }

    /* Internal Helper Methods End */

    /* Private Helper Methods Start */

    /**
     * @notice function for calculating the penalty
     * @dev this is a private function which is used inside the unstake function
     * @dev if the unstake time is over, they should be getting the reward
     * only till the original unlock time.
     * @param stakeData entire stake data of a staker for a particular vault
     * @param isUnstake this is to determine if the call is from unstake or stake more
     * @return penalty penalty for the unstake
     * @return reward reward for this stake at the time of unstaking
     */
    function _getPenaltyAndRewards(StakeData memory stakeData, bool isUnstake)
        private
        returns (
            uint256,
            uint256,
            bool
        )
    {
        uint256 unspentReward;
        uint256 penalty;
        uint256 interval;
        bool unlockOver;

        if (block.timestamp < stakeData.stakeUnlockTime) {
            interval = block.timestamp - stakeData.lastClaimTime;
            unspentReward = _getTotalReward(
                stakeData.rewardPerSecond,
                stakeData.stakeUnlockTime - block.timestamp
            );
            if (isUnstake) {
                penalty = ((stakeData.stakeAmount * _penaltyRate) / 10000);
                _collectedPenalties += penalty;
            } else {
                penalty = 0;
            }
        } else {
            interval = stakeData.stakeUnlockTime - stakeData.lastClaimTime;
            penalty = 0;
            unspentReward = 0;
            unlockOver = true;
        }

        uint256 reward = _getTotalReward(stakeData.rewardPerSecond, interval);

        _totalExpectedBonus -= (reward + unspentReward);
        return (penalty, reward, unlockOver);
    }

    /**
     * @notice function for checking the bonus pool threshold
     * @dev this is a private function which check if the
     * threshold has been reached
     * @dev difference of the bonus pool and current total bonus
     * should be less than the threshold
     */
    function _checkPoolThreshold() private {
        uint256 bonusPool = _bonusPoolAmount;
        uint256 expectedBonus = _totalExpectedBonus;
        uint256 threshold = (bonusPool * _bonusPoolThreshold) / 10000;

        if (threshold > (bonusPool - expectedBonus)) {
            emit BonusThresholdReached(bonusPool, expectedBonus);
        }
    }

    /* Private View */

    /**
     * @notice function for checking the vault requirement
     * @dev this is a private function
     * @param vault vault number for the stake
     */
    function _checkVault(uint256 vault) private view {
        require(_rewardRate[vault] > 0, "ZipmexStaking: Invalid vault");
    }

    /**
     * @notice function for checking stake exist requirement
     * @dev this is a private function
     * @param vault vault number for the stake
     */
    function _checkStakeExist(uint256 vault) private view {
        require(
            _stakeExist[msg.sender][vault] == true,
            "ZipmexStaking: Stake does not exist for this vault"
        );
    }

    /**
     * @notice function for checking amount requirements before the payment
     * @dev this is a private function
     * @param amount amount
     */
    function _paymentPrecheck(uint256 amount) private view {
        require(
            amount > 0,
            "ZipmexStaking: Amount should be greater than zero"
        );

        require(
            _tokenAddress.balanceOf(msg.sender) >= amount,
            "ZipmexStaking: Insufficient balance"
        );
    }

    /**
     * @notice function for calculating the interval for the rewards
     * @dev this is a private function
     * @param unlockTime unlock time of the stake
     * @param lastClaimTime last claim time of the stake's reward
     * @return interval reward per second is returned from this function
     */
    function _getInterval(uint256 unlockTime, uint256 lastClaimTime)
        private
        view
        returns (uint256 interval)
    {
        if (unlockTime > block.timestamp) {
            interval = block.timestamp - lastClaimTime;
        } else {
            interval = unlockTime - lastClaimTime;
        }
    }

    /* Private View Ends

    /* Private Pure */

    /**
     * @notice function for calculating the total reward for the given time
     * @dev this is a private function
     * @param rewardPerSecond reward per second
     * @param interval duration for the reward
     * @return totalReward_ reward per second is returned from this function
     */
    function _getTotalReward(uint256 rewardPerSecond, uint256 interval)
        private
        pure
        returns (uint256 totalReward_)
    {
        totalReward_ = rewardPerSecond * interval;
    }

    /* Private Pure Ends */

    /* Private Helper Methods End */
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