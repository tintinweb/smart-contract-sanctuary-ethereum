pragma solidity ^0.8.17;

import "./interfaces/IRewardManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardManager is IRewardManager {
    FarmingRange public immutable farming;
    Staking public immutable staking;

    constructor(
        address _farmingOwner,
        IERC20 _sdexToken,
        uint256 _startFarmingCampaign
    ) {
        farming = new FarmingRange(address(this));
        staking = new Staking(_sdexToken, farming);
        farming.addCampaignInfo(staking, _sdexToken, _startFarmingCampaign);
        staking.initializeFarming();
        farming.transferOwnership(_farmingOwner);
    }

    /**
     * @notice used to resetAllowance for farming to take rewards
     */
    function resetAllowance(uint256 _campaignId) external {
        require(_campaignId < farming.campaignInfoLen(), "RewardHolder:campaignId:wrong campaign ID");

        (, IERC20 rewardToken, , , , , ) = farming.campaignInfo(_campaignId);
        rewardToken.approve(address(farming), type(uint256).max);
    }
}

pragma solidity ^0.8.17;

import "../FarmingRange.sol";
import "../Staking.sol";

interface IRewardManager {
    function resetAllowance(uint256 _campaignId) external;

    function farming() external view returns (FarmingRange);

    function staking() external view returns (Staking);
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

pragma solidity ^0.8.17;

import "./interfaces/IFarmingRange.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Farming Range allows users to stake LP Tokens to receive various rewards
contract FarmingRange is IFarmingRange, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @dev this is mostly used for extending reward period
    /// @notice Reward info is a set of {endBlock, rewardPerBlock}
    /// indexed by campaign ID
    mapping(uint256 => RewardInfo[]) public campaignRewardInfo;

    /// @dev Info of each campaign. mapped from campaigh ID
    CampaignInfo[] public campaignInfo;
    /// @dev Info of each user that stakes Staking tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice limit length of reward info
    /// how many phases are allowed
    uint256 public rewardInfoLimit;
    /// @dev reward holder account
    address public rewardManager;

    event Deposit(address indexed user, uint256 amount, uint256 campaign);
    event Withdraw(address indexed user, uint256 amount, uint256 campaign);
    event EmergencyWithdraw(address indexed user, uint256 amount, uint256 campaign);
    event AddCampaignInfo(uint256 indexed campaignID, IERC20 stakingToken, IERC20 rewardToken, uint256 startBlock);
    event AddRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);
    event UpdateRewardInfo(uint256 indexed campaignID, uint256 indexed phase, uint256 endBlock, uint256 rewardPerBlock);
    event RemoveRewardInfo(uint256 indexed campaignID, uint256 indexed phase);
    event SetRewardInfoLimit(uint256 rewardInfoLimit);
    event SetRewardManager(address rewardManager);

    constructor(address _rewardManager) {
        //@DEV we can use it as month, years... Or whatever.
        rewardInfoLimit = 52; // 52 weeks, 1 year
        rewardManager = _rewardManager;
    }

    function upgradePrecision() external onlyOwner {
        uint256 length = campaignInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            campaignInfo[pid].accRewardPerShare = campaignInfo[pid].accRewardPerShare * 1e8;
        }
    }

    /// @notice function for setting a reward manager who is responsible for adding rewards
    function setRewardManager(address _rewardManager) external onlyOwner {
        rewardManager = _rewardManager;
        emit SetRewardManager(_rewardManager);
    }

    /// @notice set new reward info limit
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external onlyOwner {
        rewardInfoLimit = _updatedRewardInfoLimit;
        emit SetRewardInfoLimit(rewardInfoLimit);
    }

    /// @notice reward campaign, one campaign represents a pair of staking and reward token, last reward Block and acc reward Per Share
    function addCampaignInfo(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _startBlock
    ) external onlyOwner {
        campaignInfo.push(
            CampaignInfo({
                stakingToken: _stakingToken,
                rewardToken: _rewardToken,
                startBlock: _startBlock,
                lastRewardBlock: _startBlock,
                accRewardPerShare: 0,
                totalStaked: 0,
                totalRewards: 0
            })
        );
        emit AddCampaignInfo(campaignInfo.length - 1, _stakingToken, _rewardToken, _startBlock);
    }

    /// @notice if the new reward info is added, the reward & its end block will be extended by the newly pushed reward info.
    function addRewardInfo(
        uint256 _campaignID,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) public onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        require(
            rewardInfo.length < rewardInfoLimit,
            "FarmingRange::addRewardInfo::reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock >= block.number,
            "FarmingRange::addRewardInfo::reward period ended"
        );
        require(
            rewardInfo.length == 0 || rewardInfo[rewardInfo.length - 1].endBlock < _endBlock,
            "FarmingRange::addRewardInfo::bad new endblock"
        );
        uint256 startBlock = rewardInfo.length == 0 ? campaign.startBlock : rewardInfo[rewardInfo.length - 1].endBlock;
        uint256 blockRange = _endBlock - startBlock;
        uint256 totalRewards = _rewardPerBlock * blockRange;
        _transferFromWithAllowance(campaign.rewardToken, totalRewards, _campaignID);
        campaign.totalRewards = campaign.totalRewards + totalRewards;
        rewardInfo.push(RewardInfo({ endBlock: _endBlock, rewardPerBlock: _rewardPerBlock }));
        emit AddRewardInfo(_campaignID, rewardInfo.length - 1, _endBlock, _rewardPerBlock);
    }

    /// @notice add multiple reward Info into a campaign in one tx.
    function addRewardInfoMultiple(
        uint256 _campaignID,
        uint256[] calldata _endBlock,
        uint256[] calldata _rewardPerBlock
    ) external onlyOwner {
        require(_endBlock.length == _rewardPerBlock.length, "FarmingRange::addRewardMultiple::wrong parameters length");
        for (uint256 i = 0; i < _endBlock.length; i++) {
            addRewardInfo(_campaignID, _endBlock[i], _rewardPerBlock[i]);
        }
    }

    /// @notice : update a campaign reward info for a specified range index
    function updateRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) public onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo storage selectedRewardInfo = rewardInfo[_rewardIndex];
        uint256 previousEndBlock = selectedRewardInfo.endBlock;
        _updateCampaign(_campaignID);
        require(previousEndBlock >= block.number, "FarmingRange::updateRewardInfo::reward period ended");
        if (_rewardIndex != 0) {
            require(
                rewardInfo[_rewardIndex - 1].endBlock < _endBlock,
                "FarmingRange::updateRewardInfo::bad new endblock"
            );
        }
        if (rewardInfo.length > _rewardIndex + 1) {
            require(
                _endBlock < rewardInfo[_rewardIndex + 1].endBlock,
                "FarmingRange::updateRewardInfo::reward period end is in next range"
            );
        }
        (bool refund, uint256 diff) = _updateRewardsDiff(
            _rewardIndex,
            _endBlock,
            _rewardPerBlock,
            rewardInfo,
            campaign,
            selectedRewardInfo
        );
        if (!refund && diff > 0) {
            _transferFromWithAllowance(campaign.rewardToken, diff, _campaignID);
        }

        // If _endblock is changed, and if we have another range after the updated one,
        // we need to update rewardPerBlock to distribute on the next new range or we could run out of tokens
        if (_endBlock != previousEndBlock && rewardInfo.length - 1 > _rewardIndex) {
            RewardInfo storage nextRewardInfo = rewardInfo[_rewardIndex + 1];
            uint256 nextRewardInfoEndBlock = nextRewardInfo.endBlock;
            uint256 initialBlockRange = nextRewardInfoEndBlock - previousEndBlock;
            uint256 nextBlockRange = nextRewardInfoEndBlock - _endBlock;
            uint256 initialNextTotal = initialBlockRange * nextRewardInfo.rewardPerBlock;
            nextRewardInfo.rewardPerBlock = (nextRewardInfo.rewardPerBlock * initialBlockRange) / nextBlockRange;
            uint256 nextTotal = nextBlockRange * nextRewardInfo.rewardPerBlock;
            if (nextTotal < initialNextTotal) {
                campaign.rewardToken.safeTransfer(rewardManager, initialNextTotal - nextTotal);
            }
        }
        // UPDATE total
        campaign.totalRewards = refund ? campaign.totalRewards - diff : campaign.totalRewards + diff;
        selectedRewardInfo.endBlock = _endBlock;
        selectedRewardInfo.rewardPerBlock = _rewardPerBlock;
        emit UpdateRewardInfo(_campaignID, _rewardIndex, _endBlock, _rewardPerBlock);
    }

    function _updateRewardsDiff(
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock,
        RewardInfo[] storage rewardInfo,
        CampaignInfo storage campaign,
        RewardInfo storage selectedRewardInfo
    ) internal returns (bool refund, uint256 diff) {
        uint256 previousStartBlock = _rewardIndex == 0 ? campaign.startBlock : rewardInfo[_rewardIndex - 1].endBlock;
        uint256 newStartBlock = block.number > previousStartBlock ? block.number : previousStartBlock;
        uint256 previousBlockRange = selectedRewardInfo.endBlock - previousStartBlock;
        uint256 newBlockRange = _endBlock - newStartBlock;
        uint256 selectedRewardPerBlock = selectedRewardInfo.rewardPerBlock;
        uint256 accumulatedRewards = (newStartBlock - previousStartBlock) * selectedRewardPerBlock;
        uint256 previousTotalRewards = selectedRewardPerBlock * previousBlockRange;
        uint256 totalRewards = _rewardPerBlock * newBlockRange;
        refund = previousTotalRewards > totalRewards + accumulatedRewards;
        diff = refund
            ? previousTotalRewards - totalRewards - accumulatedRewards
            : totalRewards + accumulatedRewards - previousTotalRewards;
        if (refund) {
            campaign.rewardToken.safeTransfer(rewardManager, diff);
        }
    }

    function _transferFromWithAllowance(
        IERC20 _rewardToken,
        uint256 _amount,
        uint256 _campaignID
    ) internal {
        try _rewardToken.transferFrom(rewardManager, address(this), _amount) {} catch {
            rewardManager.call(abi.encodeWithSignature("resetAllowance(uint256)", _campaignID));
            _rewardToken.safeTransferFrom(rewardManager, address(this), _amount);
        }
    }

    /// @notice : update multiple campaign rewards info for all range index
    function updateRewardMultiple(
        uint256 _campaignID,
        uint256[] memory _rewardIndex,
        uint256[] memory _endBlock,
        uint256[] memory _rewardPerBlock
    ) public onlyOwner {
        require(
            _rewardIndex.length == _endBlock.length && _rewardIndex.length == _rewardPerBlock.length,
            "FarmingRange::updateRewardMultiple::wrong parameters length"
        );
        for (uint256 i = 0; i < _rewardIndex.length; i++) {
            updateRewardInfo(_campaignID, _rewardIndex[i], _endBlock[i], _rewardPerBlock[i]);
        }
    }

    /// @notice : update multiple campaigns and rewards info for all range index
    function updateCampaignsRewards(
        uint256[] calldata _campaignID,
        uint256[][] calldata _rewardIndex,
        uint256[][] calldata _endBlock,
        uint256[][] calldata _rewardPerBlock
    ) external onlyOwner {
        require(
            _campaignID.length == _rewardIndex.length &&
                _rewardIndex.length == _endBlock.length &&
                _rewardIndex.length == _rewardPerBlock.length,
            "FarmingRange::updateCampaignsRewards::wrong rewardInfo length"
        );
        for (uint256 i = 0; i < _campaignID.length; i++) {
            updateRewardMultiple(_campaignID[i], _rewardIndex[i], _endBlock[i], _rewardPerBlock[i]);
        }
    }

    /// @notice : remove last reward info for specified campaign
    function removeLastRewardInfo(uint256 _campaignID) external onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        uint256 rewardInfoLength = rewardInfo.length;
        require(rewardInfoLength > 0, "FarmingRange::updateCampaignsRewards::no rewardInfoLen");
        RewardInfo storage lastRewardInfo = rewardInfo[rewardInfoLength - 1];
        uint256 lastRewardInfoEndBlock = lastRewardInfo.endBlock;
        require(lastRewardInfoEndBlock > block.number, "FarmingRange::removeLastRewardInfo::reward period ended");
        _updateCampaign(_campaignID);
        if (lastRewardInfo.rewardPerBlock != 0) {
            (bool refund, uint256 diff) = _updateRewardsDiff(
                rewardInfoLength - 1,
                block.number > lastRewardInfoEndBlock ? block.number : lastRewardInfoEndBlock,
                0,
                rewardInfo,
                campaign,
                lastRewardInfo
            );
            if (refund) {
                campaign.totalRewards = campaign.totalRewards - diff;
            }
        }
        rewardInfo.pop();
        emit RemoveRewardInfo(_campaignID, rewardInfoLength - 1);
    }

    function rewardInfoLen(uint256 _campaignID) external view returns (uint256) {
        return campaignRewardInfo[_campaignID].length;
    }

    function campaignInfoLen() external view returns (uint256) {
        return campaignInfo.length;
    }

    /// @notice this will return end block based on the current block number.
    function currentEndBlock(uint256 _campaignID) external view returns (uint256) {
        return _endBlockOf(_campaignID, block.number);
    }

    function _endBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockNumber <= rewardInfo[i].endBlock) return rewardInfo[i].endBlock;
        }
        /// @dev when couldn't find any reward info, it means that _blockNumber exceed endblock
        /// so return the latest reward info.
        return rewardInfo[len - 1].endBlock;
    }

    /// @notice this will return reward per block based on the current block number.
    function currentRewardPerBlock(uint256 _campaignID) external view returns (uint256) {
        return _rewardPerBlockOf(_campaignID, block.number);
    }

    function _rewardPerBlockOf(uint256 _campaignID, uint256 _blockNumber) internal view returns (uint256) {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockNumber <= rewardInfo[i].endBlock) return rewardInfo[i].rewardPerBlock;
        }
        /// @dev when couldn't find any reward info, it means that timestamp exceed endblock
        /// so return 0
        return 0;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _endBlock
    ) public pure returns (uint256) {
        if ((_from >= _endBlock) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endBlock) {
            return _to - _from;
        }
        return _endBlock - _from;
    }

    /// @notice View function to see pending Reward on frontend.
    function pendingReward(uint256 _campaignID, address _user) external view returns (uint256) {
        return
            _pendingReward(_campaignID, userInfo[_campaignID][_user].amount, userInfo[_campaignID][_user].rewardDebt);
    }

    function _pendingReward(
        uint256 _campaignID,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view returns (uint256) {
        CampaignInfo memory campaign = campaignInfo[_campaignID];
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 accRewardPerShare = campaign.accRewardPerShare;
        if (block.number > campaign.lastRewardBlock && campaign.totalStaked != 0) {
            uint256 cursor = campaign.lastRewardBlock;
            for (uint256 i = 0; i < rewardInfo.length; ++i) {
                uint256 multiplier = getMultiplier(cursor, block.number, rewardInfo[i].endBlock);
                if (multiplier == 0) continue;
                cursor = rewardInfo[i].endBlock;
                accRewardPerShare =
                    accRewardPerShare +
                    ((multiplier * rewardInfo[i].rewardPerBlock * 1e20) / campaign.totalStaked);
            }
        }
        return ((_amount * accRewardPerShare) / 1e20) - _rewardDebt;
    }

    function updateCampaign(uint256 _campaignID) external nonReentrant {
        _updateCampaign(_campaignID);
    }

    /// @notice Update reward variables of the given campaign to be up-to-date.
    function _updateCampaign(uint256 _campaignID) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        if (block.number <= campaign.lastRewardBlock) {
            return;
        }
        if (campaign.totalStaked == 0) {
            // if there is no total supply, return and use the campaign's start block as the last reward block
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward block will be its block number
            // in order to keep the multiplier = 0
            if (block.number > _endBlockOf(_campaignID, block.number)) {
                campaign.lastRewardBlock = block.number;
            }
            return;
        }
        /// @dev for each reward info
        for (uint256 i = 0; i < rewardInfo.length; ++i) {
            // @dev get multiplier based on current Block and rewardInfo's end block
            // multiplier will be a range of either (current block - campaign.lastRewardBlock)
            // or (reward info's endblock - campaign.lastRewardBlock) or 0
            uint256 multiplier = getMultiplier(campaign.lastRewardBlock, block.number, rewardInfo[i].endBlock);
            if (multiplier == 0) continue;
            // @dev if currentBlock exceed end block, use end block as the last reward block
            // so that for the next iteration, previous endBlock will be used as the last reward block
            if (block.number > rewardInfo[i].endBlock) {
                campaign.lastRewardBlock = rewardInfo[i].endBlock;
            } else {
                campaign.lastRewardBlock = block.number;
            }
            campaign.accRewardPerShare =
                campaign.accRewardPerShare +
                ((multiplier * rewardInfo[i].rewardPerBlock * 1e20) / campaign.totalStaked);
        }
    }

    /// @notice Update reward variables for all campaigns. gas spending is HIGH in this method call, BE CAREFUL
    function massUpdateCampaigns() external nonReentrant {
        uint256 length = campaignInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updateCampaign(pid);
        }
    }

    /// @notice Stake Staking tokens to FarmingRange
    function deposit(uint256 _campaignID, uint256 _amount) public nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        _updateCampaign(_campaignID);
        if (user.amount > 0) {
            uint256 pending = (user.amount * campaign.accRewardPerShare) / 1e20 - user.rewardDebt;
            if (pending > 0) {
                campaign.rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            campaign.stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
            user.amount = user.amount + _amount;
            campaign.totalStaked = campaign.totalStaked + _amount;
        }
        user.rewardDebt = (user.amount * campaign.accRewardPerShare) / (1e20);
        emit Deposit(msg.sender, _amount, _campaignID);
    }

    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        bool approveMax,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        SafeERC20.safePermit(
            IERC20Permit(address(campaignInfo[_campaignID].stakingToken)),
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : _amount,
            deadline,
            v,
            r,
            s
        );

        deposit(_campaignID, _amount);
    }

    /// @notice Withdraw Staking tokens from STAKING.
    function withdraw(uint256 _campaignID, uint256 _amount) external nonReentrant {
        _withdraw(_campaignID, _amount);
    }

    /// @notice internal method for withdraw (withdraw and harvest method depend on this method)
    function _withdraw(uint256 _campaignID, uint256 _amount) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        require(user.amount >= _amount, "FarmingRange::withdraw::bad withdraw amount");
        _updateCampaign(_campaignID);
        uint256 pending = (user.amount * campaign.accRewardPerShare) / 1e20 - user.rewardDebt;
        if (pending > 0) {
            campaign.rewardToken.safeTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            campaign.stakingToken.safeTransfer(msg.sender, _amount);
            campaign.totalStaked = campaign.totalStaked - _amount;
        }
        user.rewardDebt = (user.amount * campaign.accRewardPerShare) / 1e20;

        emit Withdraw(msg.sender, _amount, _campaignID);
    }

    /// @notice method for harvest campaigns (used when the user want to claim their reward token based on specified campaigns)
    function harvest(uint256[] calldata _campaignIDs) external nonReentrant {
        for (uint256 i = 0; i < _campaignIDs.length; ++i) {
            _withdraw(_campaignIDs[i], 0);
        }
    }

    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _campaignID) external nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        uint256 _amount = user.amount;
        campaign.totalStaked = campaign.totalStaked - _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        campaign.stakingToken.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _amount, _campaignID);
    }

    /// @notice Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(
        uint256 _campaignID,
        uint256 _amount,
        address _beneficiary
    ) external onlyOwner nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        uint256 currentStakingPendingReward = _pendingReward(_campaignID, campaign.totalStaked, 0);
        require(
            currentStakingPendingReward + _amount <= campaign.totalRewards,
            "FarmingRange::emergencyRewardWithdraw::not enough reward token"
        );
        campaign.totalRewards = campaign.totalRewards - _amount;
        campaign.rewardToken.safeTransfer(_beneficiary, _amount);
    }
}

pragma solidity ^0.8.17;

import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Implementation of an APY staking pool
 * Users can deposit SDEX for a share in the pool
 * New shares depend of current shares supply and SDEX in the pool
 * Pool will receive SDEX rewards fees by external transfer from admin or contract
 * but also from farming pool
 * Each deposit/withdraw will harvest in the farming pool
 */
contract Staking is IStaking, ERC20 {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 shares; // shares owned in the staking
        uint256 lastBlockUpdate; // last block the user called deposit or withdraw
    }

    uint256 public constant CAMPAIGN_ID = 0;

    bool public farmingInitialized = false;

    IERC20 public immutable smardexToken;
    IFarmingRange public immutable farming;

    mapping(address => UserInfo) public userInfo;
    uint256 public totalShares;

    constructor(IERC20 _smardexToken, IFarmingRange _farming) ERC20("Staked Smardex Token", "stSDEX") {
        smardexToken = _smardexToken;
        farming = _farming;
    }

    modifier isFarmingInitialized() {
        require(farmingInitialized == true, "Staking::isFarmingInitialized::Farming campaign not initialized");
        _;
    }

    modifier checkUserBlock() {
        require(
            userInfo[msg.sender].lastBlockUpdate < block.number,
            "Staking::checkUserBlock::User already called deposit or withdraw this block"
        );
        userInfo[msg.sender].lastBlockUpdate = block.number;
        _;
    }

    /**
     * @notice Initialize staking connection with farming
     * Mint one token of stSDEX and then deposit in the staking farming pool
     * This contract should be the only participant of the staking farming pool
     */
    function initializeFarming() external {
        require(farmingInitialized == false, "Staking::initializeFarming::Farming campaign already initialized");
        _approve(address(this), address(farming), 1);
        _mint(address(this), 1);
        farming.deposit(CAMPAIGN_ID, 1);

        farmingInitialized = true;
    }

    /**
     * @notice Send SDEX to get shares in the staking pool
     * @param depositAmount The amount of SDEX to send
     */
    function deposit(uint256 depositAmount) public isFarmingInitialized checkUserBlock {
        require(depositAmount > 0, "Staking::deposit::can't deposit zero token");

        harvestFarming();

        uint256 currentBalance = smardexToken.balanceOf(address(this));
        uint256 newShares = _tokensToShares(depositAmount, currentBalance);

        smardexToken.safeTransferFrom(msg.sender, address(this), depositAmount);

        totalShares += newShares;
        userInfo[msg.sender].shares += newShares;

        emit Deposit(msg.sender, newShares);
    }

    function depositWithPermit(
        uint256 depositAmount,
        bool approveMax,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        SafeERC20.safePermit(
            IERC20Permit(address(smardexToken)),
            msg.sender,
            address(this),
            approveMax ? type(uint256).max : depositAmount,
            deadline,
            v,
            r,
            s
        );

        deposit(depositAmount);
    }

    /**
     * @notice Harvest and withdraw SDEX for the amount of shares defined
     * @param to The address who will receive SDEX
     * @param sharesAmount The amount of shares to use
     */
    function withdraw(address to, uint256 sharesAmount) external isFarmingInitialized checkUserBlock {
        require(
            sharesAmount > 0 && userInfo[msg.sender].shares >= sharesAmount,
            "Staking::withdraw::can't withdraw more than user shares or zero"
        );

        harvestFarming();

        uint256 currentBalance = smardexToken.balanceOf(address(this));
        uint256 tokensToWithdraw = _sharesToTokens(sharesAmount, currentBalance);

        userInfo[msg.sender].shares -= sharesAmount;
        totalShares -= sharesAmount;
        smardexToken.safeTransfer(to, tokensToWithdraw);

        emit Withdraw(msg.sender, to, tokensToWithdraw);
    }

    /**
     * @notice Harvest the farming pool for the staking, will increase the SDEX
     */
    function harvestFarming() public {
        farming.withdraw(CAMPAIGN_ID, 0);
    }

    /**
     * @notice Calculate shares qty for an amount of sdex tokens
     * @param tokens amount of sdex
     * @return Shares qty
     */
    function tokensToShares(uint256 tokens) external view returns (uint256) {
        uint256 currentBalance = smardexToken.balanceOf(address(this));
        currentBalance += farming.pendingReward(0, address(this));

        return _tokensToShares(tokens, currentBalance);
    }

    function _tokensToShares(uint256 tokens, uint256 currentBalance) internal view returns (uint256) {
        return totalShares > 0 ? (tokens * totalShares) / currentBalance : tokens * 1e27;
    }

    /**
     * @notice Calculate shares values in sdex tokens
     * @param shares amount of shares
     * @return The SDEX value
     */
    function sharesToTokens(uint256 shares) external view returns (uint256) {
        uint256 currentBalance = smardexToken.balanceOf(address(this));
        currentBalance += farming.pendingReward(0, address(this));

        return _sharesToTokens(shares, currentBalance);
    }

    function _sharesToTokens(uint256 shares, uint256 currentBalance) internal view returns (uint256) {
        return totalShares > 0 ? (shares * currentBalance) / totalShares : shares / 1e27;
    }
}

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFarmingRange {
    /// @dev Info of each user.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    /// @dev Info of each reward distribution campaign.
    struct CampaignInfo {
        IERC20 stakingToken; // Address of Staking token contract.
        IERC20 rewardToken; // Address of Reward token contract
        uint256 startBlock; // start block of the campaign
        uint256 lastRewardBlock; // Last block number that Reward Token distribution occurs.
        uint256 accRewardPerShare; // Accumulated Reward Token per share, times 1e20. See below.
        uint256 totalStaked; // total staked amount each campaign's stake token, typically, each campaign has the same stake token, so need to track it separatedly
        uint256 totalRewards;
    }

    /// @dev Reward info
    struct RewardInfo {
        uint256 endBlock;
        uint256 rewardPerBlock;
    }

    function upgradePrecision() external;

    function setRewardManager(address _rewardManager) external;

    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit) external;

    function addCampaignInfo(
        IERC20 _stakingToken,
        IERC20 _rewardToken,
        uint256 _startBlock
    ) external;

    function addRewardInfo(
        uint256 _campaignID,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) external;

    function addRewardInfoMultiple(
        uint256 _campaignID,
        uint256[] calldata _endBlock,
        uint256[] calldata _rewardPerBlock
    ) external;

    function updateRewardInfo(
        uint256 _campaignID,
        uint256 _rewardIndex,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) external;

    function updateRewardMultiple(
        uint256 _campaignID,
        uint256[] memory _rewardIndex,
        uint256[] memory _endBlock,
        uint256[] memory _rewardPerBlock
    ) external;

    function updateCampaignsRewards(
        uint256[] calldata _campaignID,
        uint256[][] calldata _rewardIndex,
        uint256[][] calldata _endBlock,
        uint256[][] calldata _rewardPerBlock
    ) external;

    function removeLastRewardInfo(uint256 _campaignID) external;

    function rewardInfoLen(uint256 _campaignID) external view returns (uint256);

    function campaignInfoLen() external view returns (uint256);

    function currentEndBlock(uint256 _campaignID) external view returns (uint256);

    function currentRewardPerBlock(uint256 _campaignID) external view returns (uint256);

    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _endBlock
    ) external returns (uint256);

    function pendingReward(uint256 _campaignID, address _user) external view returns (uint256);

    function updateCampaign(uint256 _campaignID) external;

    function massUpdateCampaigns() external;

    function deposit(uint256 _campaignID, uint256 _amount) external;

    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        bool approveMax,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(uint256 _campaignID, uint256 _amount) external;

    function harvest(uint256[] calldata _campaignIDs) external;

    function emergencyWithdraw(uint256 _campaignID) external;

    function emergencyRewardWithdraw(
        uint256 _campaignID,
        uint256 _amount,
        address _beneficiary
    ) external;

    function campaignRewardInfo(uint256, uint256) external view returns (uint256, uint256);

    function campaignInfo(uint256)
        external
        view
        returns (
            IERC20,
            IERC20,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256, address) external view returns (uint256, uint256);

    function rewardInfoLimit() external view returns (uint256);

    function rewardManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
interface IERC20Permit {
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

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFarmingRange.sol";

interface IStaking {
    event Deposit(address indexed from, uint256 newShares);
    event Withdraw(address indexed from, address indexed to, uint256 tokenReceived);

    function initializeFarming() external;

    function deposit(uint256 depositAmount) external;

    function depositWithPermit(
        uint256 depositAmount,
        bool approveMax,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(address to, uint256 sharesAmount) external;

    function harvestFarming() external;

    function tokensToShares(uint256 tokens) external view returns (uint256);

    function sharesToTokens(uint256 shares) external view returns (uint256);

    function CAMPAIGN_ID() external view returns (uint256);

    function farmingInitialized() external view returns (bool);

    function smardexToken() external view returns (IERC20);

    function farming() external view returns (IFarmingRange);

    function userInfo(address) external view returns (uint256, uint256);

    function totalShares() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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