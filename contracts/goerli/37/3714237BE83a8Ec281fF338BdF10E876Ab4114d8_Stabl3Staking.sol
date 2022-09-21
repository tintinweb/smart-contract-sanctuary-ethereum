// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./SafeMathUpgradeable.sol";
import "./ABDKMath64x64.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";
import "./IROI.sol";

contract Stabl3Staking is Ownable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    uint8 private constant BUY_POOL = 0;

    uint8 private constant BOND_POOL = 1;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 3;
    uint8 private constant STAKE_REWARD_POOL = 4;
    uint8 private constant LEND_REWARD_POOL = 5;

    ITreasury public treasury;
    IROI public ROI;
    address public HQ;

    IERC20 public stabl3;

    uint256[] public treasuryPercentages;
    uint256[] public ROIPercentages;
    uint256[] public HQPercentages;

    uint256 public unstakeFeePercentage;

    uint256 public maxPoolPercentage;

    uint256 oneMinuteTime;
    uint256 oneYearTime;
    uint256[4] public lockTimes;

    uint256 public lendingStabl3ClaimTime;

    bool public stakeState;

    // structs

    struct Staking {
        uint256 index;
        address user;
        bool status;
        uint8 stakingType;
        IERC20 token;
        uint256 amountTokenStaked;
        uint256 startTime;
        uint256 rewardWithdrawn;
        uint256 rewardWithdrawTimeLast;
        bool isLending;
        bool isClaimedStabl3Lending;
        uint256 amountTokenLending;
        uint256 amountStabl3Lending;
    }

    struct ExternalStaking {
        uint256 index;
        address user;
        bool status;
        uint8 stakingType;
        IERC20 token;
        uint256 amountTokenStaked;
        uint256 startTime;
        uint256 rewardWithdrawn;
        uint256 rewardWithdrawTimeLast;
    }

    struct Record {
        uint256 totalAmountTokenStaked;
        uint256 totalRewardWithdrawn;
        uint256 totalAmountStabl3Withdrawn;
    }

    // mappings

    // user stakings
    mapping (address => Staking[]) public getStakings;

    // user lifetime record
    mapping (address => mapping (bool => Record)) public getRecords;

    // user external stakings
    mapping (address => ExternalStaking[]) public getExternalStakings;

    // contracts with permission to access certain Staking functions
    mapping (address => bool) public permitted;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedROI(address newROI, address oldROI);

    event UpdatedHQ(address newHQ, address oldHQ);

    event UpdatedUnstakeFeePercentage(uint256 newUnstakeFeePercentage, uint256 oldUnstakeFeePercentage);

    event UpdatedLockTime(uint256[4] newLockTimes, uint256[4] oldLockTimes);

    event UpdatedLendingStabl3Percentage(uint256 newLendingStabl3Percentage, uint256 oldLendingStabl3Percentage);

    event UpdatedLendingStabl3ClaimTime(uint256 newLendingStabl3ClaimTime, uint256 oldLendingStabl3ClaimTime);

    event UpdatedPermission(address contractAddress, bool state);

    event Stake(
        address indexed user,
        uint256 index,
        uint8 stakingType,
        IERC20 token,
        uint256 amountToken,
        uint256 totalAmountToken,
        bool isLend,
        uint256 timestamp
    );

    event WithdrewReward(
        address indexed user,
        uint256 index,
        IERC20 token,
        uint256 rewardWithdrawn,
        uint256 totalRewardWithdrawn,
        bool isLend,
        uint256 timestamp
    );

    event ClaimedLendingStabl3(
        address indexed user,
        uint256 index,
        IERC20 token,
        uint256 amountTokenLending,
        uint256 amountStabl3Lending,
        uint256 totalAmountStabl3Withdrawn,
        uint256 timestamp
    );

    event Unstake(address indexed user, uint256 index, IERC20 token, uint256 amountToken, uint256 reward, uint8 stakingType, bool isLend);

    // constructor

    constructor(address _treasury, address _ROI) {
        treasury = ITreasury(_treasury);
        ROI = IROI(_ROI);
        HQ = 0x294d0487fdf7acecf342ae70AFc5549A6E90f3e0;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        treasuryPercentages = [975, 800];
        ROIPercentages = [0, 175];
        HQPercentages = [25, 25];

        unstakeFeePercentage = 50;

        maxPoolPercentage = 700;

        // TODO remove
        oneMinuteTime = 30;
        oneYearTime = 10800;
        lockTimes = [2700, 5400, 8100, 10800];   // 0:45, 1:30, 2:15 and 3:00 hours time in seconds
        // oneMinuteTime = 60;
        // oneYearTime = 31104000;
        // lockTimes = [7776000, 15552000, 23328000, 31104000];   // 3, 6, 9 and 12 months time in seconds

        // TODO remove
        lendingStabl3ClaimTime = 900; // 0:15 hours time in seconds
        // lendingStabl3ClaimTime = 2592000; // 1 month time in seconds
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "Stabl3Staking: Treasury is already this address");
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updateROI(address _ROI) external onlyOwner {
        require(address(ROI) != _ROI, "Stabl3Staking: ROI is already this address");
        emit UpdatedROI(_ROI, address(ROI));
        ROI = IROI(_ROI);
    }

    function updateHQ(address _HQ) external onlyOwner {
        require(HQ != _HQ, "Stabl3Staking: HQ is already this address");
        emit UpdatedHQ(_HQ, HQ);
        HQ = _HQ;
    }

    function updateDistributionPercentages(
        uint256[2] memory _treasuryPercentages,
        uint256[2] memory _ROIPercentages,
        uint256[2] memory _HQPercentages
    ) external onlyOwner {
        require(_treasuryPercentages[0] + _ROIPercentages[0] + _HQPercentages[0] == 1000,
            "Stabl3Staking: Sum of magnified Stake percentages should equal 1000");
        require(_treasuryPercentages[1] + _ROIPercentages[1] + _HQPercentages[1] == 1000,
            "Stabl3Staking: Sum of magnified Lend percentages should equal 1000");

        treasuryPercentages = _treasuryPercentages;
        ROIPercentages = _ROIPercentages;
        HQPercentages = _HQPercentages;
    }

    function updateUnstakeFeePercentage(uint256 _unstakeFeePercentage) external onlyOwner {
        require(unstakeFeePercentage != _unstakeFeePercentage, "Stabl3Staking: Unstake Fee is already this value");
        emit UpdatedUnstakeFeePercentage(_unstakeFeePercentage, unstakeFeePercentage);
        unstakeFeePercentage = _unstakeFeePercentage;
    }

    function updateMaxPoolPercentage(uint256 _maxPoolPercentage) external onlyOwner {
        require(maxPoolPercentage != _maxPoolPercentage, "Stabl3Staking: Max Pool Percentage is already this value");
        maxPoolPercentage = _maxPoolPercentage;
    }

    function updateLockTimes(uint256[4] memory _lockTimes) external onlyOwner {
        emit UpdatedLockTime(_lockTimes, lockTimes);
        lockTimes = _lockTimes;
    }

    function updateLendingStabl3ClaimTime(uint256 _lendingStabl3ClaimTime) external onlyOwner {
        require(lendingStabl3ClaimTime != _lendingStabl3ClaimTime, "Stabl3Staking: Lending Stabl3 Claim Time is already this value");
        emit UpdatedLendingStabl3ClaimTime(_lendingStabl3ClaimTime, lendingStabl3ClaimTime);
        lendingStabl3ClaimTime = _lendingStabl3ClaimTime;
    }

    function updateStakeState(bool _state) external onlyOwner {
        require(stakeState != _state, "Stabl3Staking: Stake State is already of the value 'state'");
        stakeState = _state;
    }

    function updatePermission(address _contractAddress, bool _state) external onlyOwner {
        require(permitted[_contractAddress] != _state, "Stabl3Staking: Contract is already of the value 'state'");
        permitted[_contractAddress] = _state;
        emit UpdatedPermission(_contractAddress, _state);
    }

    function allStakingsLength(address _user) external view returns (uint256) {
        return getStakings[_user].length;
    }

    function allStakings(address _user) external view returns (
        Staking[] memory unlockedLending,
        Staking[] memory lockedLending,
        Staking[] memory unlockedStaking,
        Staking[] memory lockedStaking
    ) {
        uint256 unlockedLendingLength;
        uint256 lockedLendingLength;
        uint256 unlockedStakingLength;
        uint256 lockedStakingLength;

        for (uint256 i = 0 ; i < getStakings[_user].length ; i++) {
            Staking memory staking = getStakings[_user][i];

            if (staking.status) {
                uint256 endTime = staking.startTime + lockTimes[staking.stakingType - 1];

                if (block.timestamp >= endTime) {
                    if (staking.isLending) {
                        unlockedLendingLength++;
                    }
                    else {
                        unlockedStakingLength++;
                    }
                }
                else {
                    if (staking.isLending) {
                        lockedLendingLength++;
                    }
                    else {
                        lockedStakingLength++;
                    }
                }
            }
        }

        unlockedLending = new Staking[](unlockedLendingLength);
        lockedLending = new Staking[](lockedLendingLength);
        unlockedStaking = new Staking[](unlockedStakingLength);
        lockedStaking = new Staking[](lockedStakingLength);

        unlockedLendingLength = 0;
        lockedLendingLength = 0;
        unlockedStakingLength = 0;
        lockedStakingLength = 0;

        for (uint256 i = 0 ; i < getStakings[_user].length ; i++) {
            Staking memory staking = getStakings[_user][i];

            if (staking.status) {
                uint256 endTime = staking.startTime + lockTimes[staking.stakingType - 1];

                if (block.timestamp >= endTime) {
                    if (staking.isLending) {
                        unlockedLending[unlockedLendingLength] = staking;
                        unlockedLendingLength++;
                    }
                    else {
                        unlockedStaking[unlockedStakingLength] = staking;
                        unlockedStakingLength++;
                    }
                }
                else {
                    if (staking.isLending) {
                        lockedLending[lockedLendingLength] = staking;
                        lockedLendingLength++;
                    }
                    else {
                        lockedStaking[lockedStakingLength] = staking;
                        lockedStakingLength++;
                    }
                }
            }
        }
    }

    function validatePool(IERC20 _token, uint256 _amountToken) public view stakeActive reserved(_token) returns (bool) {
        uint256 maxPool;
        uint256 currentPool;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);
            if (treasury.isReservedToken(reservedToken)) {
                uint256 boughtAmountReservedToken = treasury.getTreasuryPool(BUY_POOL, reservedToken);
                uint256 bondedAmountReservedToken = treasury.getTreasuryPool(BOND_POOL, reservedToken);

                uint256 stakedAmountReservedToken = treasury.sumOfAllPools(STAKE_POOL, reservedToken);
                uint256 lendedAmountReservedToken = treasury.sumOfAllPools(LEND_POOL, reservedToken);

                uint256 decimalsReservedToken = reservedToken.decimals();

                if (decimalsReservedToken < 18) {
                    boughtAmountReservedToken = boughtAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                    bondedAmountReservedToken = bondedAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                    stakedAmountReservedToken = stakedAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                    lendedAmountReservedToken = lendedAmountReservedToken * (10 ** (18 - decimalsReservedToken));
                }

                maxPool += boughtAmountReservedToken + bondedAmountReservedToken;
                currentPool += stakedAmountReservedToken + lendedAmountReservedToken;
            }
        }

        maxPool = maxPool.mul(maxPoolPercentage).div(1000);

        if (_token.decimals() < 18) {
            _amountToken = _amountToken.mul(10 ** (18 - _token.decimals()));
        }

        bool isValid = (currentPool + _amountToken) <= maxPool;

        return isValid;
    }

    function stake(IERC20 _token, uint256 _amountToken, uint8 _stakingType, bool _isLending) public stakeActive reserved(_token) {
        require(_amountToken > 0, "Stabl3Staking: Amount should be greater than zero");
        require(1 <= _stakingType && _stakingType <= 4, "Stabl3Staking: Incorrect staking type");
        require(validatePool(_token, _amountToken), "Stabl3Staking: Staking pool limit reached");

        uint256 amountTokenLending;
        uint256 amountStabl3Lending;

        if (_isLending) {
            uint256 amountTreasury = _amountToken.mul(treasuryPercentages[1]).div(1000);

            uint256 amountROI = _amountToken.mul(ROIPercentages[1]).div(1000);

            uint256 amountHQ = _amountToken.mul(HQPercentages[1]).div(1000);

            amountTokenLending = amountROI + amountHQ;
            amountStabl3Lending = treasury.getAmountOut(_token, amountTokenLending);

            uint256 totalAmountDistributed = amountTreasury + amountROI + amountHQ;
            if (_amountToken > totalAmountDistributed) {
                amountTreasury += _amountToken - totalAmountDistributed;
            }

            SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTreasury);
            SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountROI);
            SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

            stabl3.transferFrom(address(treasury), address(this), amountStabl3Lending);

            treasury.updatePool(STAKE_POOL, _token, amountTreasury, amountROI, amountHQ, true);
            treasury.updatePool(BUY_POOL, _token, 0, amountROI, amountHQ, true);
            treasury.updateRate(_token, amountTokenLending);
        }
        else {
            uint256 amountTreasury = _amountToken.mul(treasuryPercentages[0]).div(1000);

            uint256 amountROI = _amountToken.mul(ROIPercentages[0]).div(1000);

            uint256 amountHQ = _amountToken.mul(HQPercentages[0]).div(1000);

            uint256 totalAmountDistributed = amountTreasury + amountROI + amountHQ;
            if (_amountToken > totalAmountDistributed) {
                amountTreasury += _amountToken - totalAmountDistributed;
            }

            SafeERC20.safeTransferFrom(_token, msg.sender, address(treasury), amountTreasury);
            SafeERC20.safeTransferFrom(_token, msg.sender, address(ROI), amountROI);
            SafeERC20.safeTransferFrom(_token, msg.sender, HQ, amountHQ);

            treasury.updatePool(STAKE_POOL, _token, amountTreasury, amountROI, amountHQ, true);
        }

        uint256 timestampToConsider = block.timestamp;

        Staking memory staking = Staking(
            getStakings[msg.sender].length,
            msg.sender,
            true,
            _stakingType,
            _token,
            _amountToken,
            timestampToConsider,
            0,
            timestampToConsider,
            _isLending,
            false,
            amountTokenLending,
            amountStabl3Lending
        );

        getStakings[msg.sender].push(staking);

        getRecords[msg.sender][_isLending].totalAmountTokenStaked += _amountToken;

        ROI.updateAPR();

        emit Stake(
            staking.user,
            staking.index,
            staking.stakingType,
            staking.token,
            staking.amountTokenStaked,
            getRecords[staking.user][staking.isLending].totalAmountTokenStaked,
            staking.isLending,
            timestampToConsider
        );
    }

    function stakeRealEstate(address _user, IERC20 _token, uint256 _amountToken, uint8 _stakingType) public permission reserved(_token) {
        require(_amountToken > 0, "Stabl3Staking: Amount should be greater than zero");
        require(validatePool(_token, _amountToken), "Stabl3Staking: Staking pool limit reached");

        uint256 timestampToConsider = block.timestamp;

        ExternalStaking memory externalStaking = ExternalStaking(
            getStakings[_user].length,
            _user,
            true,
            _stakingType,
            _token,
            _amountToken,
            timestampToConsider,
            0,
            timestampToConsider
        );

        getExternalStakings[_user].push(externalStaking);
    }

    function getAmountRewardSingle(
        address _user,
        uint256 _index,
        bool _isLending,
        uint256 _timestamp
    ) public view stakeActive returns (uint256) {
        uint256 reward;

        Staking memory staking = getStakings[_user][_index];

        if (
            staking.status &&
            staking.isLending == _isLending
        ) {
            uint256 numberOfMinutes = (_timestamp - staking.rewardWithdrawTimeLast) / oneMinuteTime;

            if (numberOfMinutes > 0) {
                uint256 ratio = ROI.getAPR();

                uint256 rewardTotal = _compound(
                    staking.amountTokenStaked,
                    ratio,
                    1
                );

                reward = (rewardTotal * oneMinuteTime * numberOfMinutes) / oneYearTime;
            }
        }

        return reward;
    }

    function getAmountRewardAll(address _user, bool _isLending) public view stakeActive returns (uint256) {
        uint256 totalReward;

        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getStakings[_user].length ; i++) {
            Staking memory staking = getStakings[_user][i];

            if (staking.isLending == _isLending) {
                uint256 reward = getAmountRewardSingle(_user, i, _isLending, timestampToConsider);

                if (reward > 0) {
                    uint256 decimals = staking.token.decimals();

                    if (decimals < 18) {
                        reward *= 10 ** (18 - decimals);
                    }

                    totalReward += reward;
                }
            }
        }

        return totalReward;
    }

    function _withdrawAmountRewardSingle(uint256 _index, bool _isLending, uint256 _timestamp) internal {
        Staking storage staking = getStakings[msg.sender][_index];

        uint256 reward = getAmountRewardSingle(msg.sender, _index, _isLending, _timestamp);

        if (reward > 0) {
            Record storage record = getRecords[msg.sender][staking.isLending];

            uint8 poolType = STAKE_POOL;
            if (staking.isLending) {
                poolType = LEND_POOL;
            }

            _evaluateReward(staking.token, reward, poolType);

            staking.rewardWithdrawn += reward;
            staking.rewardWithdrawTimeLast = _timestamp;

            record.totalRewardWithdrawn += reward;

            ROI.updateAPR();

            emit WithdrewReward(
                staking.user,
                staking.index,
                staking.token,
                reward,
                record.totalRewardWithdrawn,
                _isLending,
                _timestamp
            );
        }
    }

    function withdrawAmountRewardAll(bool _isLending) external stakeActive {
        require(getAmountRewardAll(msg.sender, _isLending) > 0, "Stabl3Staking: No reward to withdraw");

        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getStakings[msg.sender].length ; i++) {
            _withdrawAmountRewardSingle(i, _isLending, timestampToConsider);
        }
    }

    // function getAmountRewardSingle(
    //     address _user,
    //     uint256 _index,
    //     bool _isLending,
    //     uint256 _timestamp
    // ) public view stakeActive returns (uint256) {

    // function getAmountRewardAll(address _user, bool _isLending) public view stakeActive returns (uint256) {

    // function _withdrawAmountRewardSingle(uint256 _index, bool _isLending, uint256 _timestamp) internal {

    // function withdrawAmountRewardAll(bool _isLending) external stakeActive {

    function getClaimableStabl3LendingSingle(
        address _user,
        uint256 _index,
        uint256 _timestamp
    ) public view stakeActive returns (uint256) {
        uint256 claimableStabl3Lending;

        Staking memory staking = getStakings[_user][_index];

        if (
            staking.status &&
            staking.isLending == true &&
            !staking.isClaimedStabl3Lending &&
            _timestamp > staking.startTime + lendingStabl3ClaimTime
        ) {
            claimableStabl3Lending = staking.amountStabl3Lending;
        }

        return claimableStabl3Lending;
    }

    function getClaimableStabl3LendingAll(address _user) public view stakeActive returns (uint256) {
        uint256 totalClaimableStabl3Lending;

        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getStakings[_user].length ; i++) {
            uint256 claimableStabl3Lending = getClaimableStabl3LendingSingle(_user, i, timestampToConsider);

            if (claimableStabl3Lending > 0) {
                totalClaimableStabl3Lending += claimableStabl3Lending;
            }
        }

        return totalClaimableStabl3Lending;
    }

    function _claimStabl3LendingSingle(uint256 _index, uint256 _timestamp) internal {
        Staking storage staking = getStakings[msg.sender][_index];

        Record storage record = getRecords[msg.sender][true];

        uint256 amountStabl3Lending = getClaimableStabl3LendingSingle(msg.sender, _index, _timestamp);

        if (amountStabl3Lending > 0) {
            stabl3.transfer(msg.sender, amountStabl3Lending);

            staking.isClaimedStabl3Lending = true;

            record.totalAmountStabl3Withdrawn += amountStabl3Lending;

            emit ClaimedLendingStabl3(
                staking.user,
                staking.index,
                staking.token,
                staking.amountTokenLending,
                staking.amountStabl3Lending,
                record.totalAmountStabl3Withdrawn,
                _timestamp
            );
        }
    }

    function claimStabl3LendingAll() external stakeActive {
        require(getClaimableStabl3LendingAll(msg.sender) > 0, "Stabl3Staking: No Lending Stabl3 to claim");

        uint256 timestampToConsider = block.timestamp;

        for (uint256 i = 0 ; i < getStakings[msg.sender].length ; i++) {
            _claimStabl3LendingSingle(i, timestampToConsider);
        }
    }

    function _unstakeSingle(uint256 _index, uint256 _amountToUnstake) internal {
        Staking storage staking = getStakings[msg.sender][_index];

        uint256 fee = staking.amountTokenStaked.mul(unstakeFeePercentage).div(1000);

        uint256 amountToWithdrawWithFee = staking.amountTokenStaked - fee;

        uint8 poolType = STAKE_POOL;
        if (staking.isLending) {
            poolType = LEND_POOL;
        }

        SafeERC20.safeTransferFrom(staking.token, address(treasury), address(ROI), fee);

        SafeERC20.safeTransferFrom(staking.token, address(treasury), msg.sender, amountToWithdrawWithFee);

        treasury.updatePool(poolType, staking.token, staking.amountTokenStaked, 0, 0, false);
        treasury.updatePool(poolType, staking.token, 0, fee, 0, true);

        ROI.updateAPR();

        staking.status = false;

        emit Unstake(
            staking.user,
            staking.index,
            staking.token,
            _amountToUnstake,
            staking.rewardWithdrawn,
            staking.stakingType,
            staking.isLending
        );
    }

    function restakeSingle(uint256 _index, uint256 _amountToWithdraw, uint8 _stakingType) external stakeActive {
        Staking storage staking = getStakings[msg.sender][_index];

        require(staking.status, "Stabl3Staking: Wrong index given");
        require(block.timestamp > staking.startTime + lockTimes[staking.stakingType - 1], "Stabl3Staking: Cannot unstake before end time");
        require(_amountToWithdraw < staking.amountTokenStaked, "Stabl3Staking: Incorrect amount for restaking");

        uint256 timestampToConsider = block.timestamp;

        if (staking.isLending) {
            _claimStabl3LendingSingle(_index, timestampToConsider);
        }

        _withdrawAmountRewardSingle(_index, staking.isLending, timestampToConsider);

        _unstakeSingle(_index, _amountToWithdraw);

        uint256 amountToRestake = staking.amountTokenStaked - _amountToWithdraw;

        stake(staking.token, amountToRestake, _stakingType, staking.isLending);
    }

    function unstakeSingle(uint256 _index) public stakeActive {
        Staking storage staking = getStakings[msg.sender][_index];

        require(staking.status, "Stabl3Staking: Wrong index given");
        require(block.timestamp > staking.startTime + lockTimes[staking.stakingType - 1], "Stabl3Staking: Cannot unstake before end time");

        uint256 timestampToConsider = block.timestamp;

        if (staking.isLending) {
            _claimStabl3LendingSingle(_index, timestampToConsider);
        }

        _withdrawAmountRewardSingle(_index, staking.isLending, timestampToConsider);

        _unstakeSingle(_index, staking.amountTokenStaked);
    }

    function unstakeMultiple(uint256[] memory _indexes) external stakeActive {
        for (uint256 i = 0 ; i < _indexes.length ; i++) {
            unstakeSingle(_indexes[i]);
        }
    }

    function _evaluateReward(IERC20 _rewardToken, uint256 _amountRewardToken, uint8 _poolType) internal {
        uint8 rewardPoolType = _poolType + 2;

        uint256 amountRewardTokenROI = _rewardToken.balanceOf(address(ROI));

        if (_amountRewardToken > amountRewardTokenROI) {
            if (amountRewardTokenROI != 0) {
                SafeERC20.safeTransferFrom(_rewardToken, address(ROI), msg.sender, amountRewardTokenROI);

                _amountRewardToken -= amountRewardTokenROI;

                treasury.updatePool(_poolType, _rewardToken, 0, amountRewardTokenROI, 0, false);
                treasury.updatePool(rewardPoolType, _rewardToken, 0, amountRewardTokenROI, 0, true);
            }

            uint256 decimalsRewardToken = _rewardToken.decimals();

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() && _amountRewardToken > 0 ; i++) {
                IERC20 reservedToken = treasury.allReservedTokens(i);

                if (
                    treasury.isReservedToken(reservedToken) &&
                    reservedToken != _rewardToken &&
                    _amountRewardToken != 0
                ) {
                    uint256 amountReservedTokenROI = reservedToken.balanceOf(address(ROI));

                    uint256 decimalsReservedToken = reservedToken.decimals();

                    uint256 amountRewardTokenConverted;
                    if (decimalsRewardToken > decimalsReservedToken) {
                        amountRewardTokenConverted = _amountRewardToken / (10 ** (decimalsRewardToken - decimalsReservedToken));
                    }
                    else if (decimalsRewardToken < decimalsReservedToken) {
                        amountRewardTokenConverted = _amountRewardToken * (10 ** (decimalsReservedToken - decimalsRewardToken));
                    }

                    if (amountRewardTokenConverted > amountReservedTokenROI) {
                        SafeERC20.safeTransferFrom(reservedToken, address(ROI), msg.sender, amountReservedTokenROI);

                        treasury.updatePool(_poolType, reservedToken, 0, amountReservedTokenROI, 0, false);
                        treasury.updatePool(rewardPoolType, reservedToken, 0, amountReservedTokenROI, 0, true);

                        if (decimalsRewardToken > decimalsReservedToken) {
                            _amountRewardToken -= amountReservedTokenROI * (10 ** (decimalsRewardToken - decimalsReservedToken));
                        }
                        else if (decimalsRewardToken < decimalsReservedToken) {
                            _amountRewardToken -= amountReservedTokenROI / (10 ** (decimalsReservedToken - decimalsRewardToken));
                        }
                    }
                    else {
                        SafeERC20.safeTransferFrom(reservedToken, address(ROI), msg.sender, amountRewardTokenConverted);

                        treasury.updatePool(_poolType, reservedToken, 0, amountRewardTokenConverted, 0, false);
                        treasury.updatePool(rewardPoolType, reservedToken, 0, amountRewardTokenConverted, 0, true);

                        _amountRewardToken = 0;
                        break;
                    }
                }
            }
        }
        else {
            SafeERC20.safeTransferFrom(_rewardToken, address(ROI), msg.sender, _amountRewardToken);

            treasury.updatePool(_poolType, _rewardToken, 0, _amountRewardToken, 0, false);
            treasury.updatePool(rewardPoolType, _rewardToken, 0, _amountRewardToken, 0, true);
        }
    }

    function _compound(uint256 _principal, uint256 _ratio, uint256 _exponent) internal pure returns (uint256) {
        if (_exponent == 0) {
            return 0;
        }

        uint256 accruedReward = ABDKMath64x64.mulu(ABDKMath64x64.pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), ABDKMath64x64.divu(_ratio,10**18)), _exponent), _principal);

        return accruedReward.sub(_principal);
    }

    // TODO remove
    // Testing only
    function testWithdrawAllFunds(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // modifiers

    modifier stakeActive() {
        require(stakeState, "Stabl3Staking: Stake and Lend not yet started");
        _;
    }

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "Stabl3Staking: Not permitted");
        _;
    }

    modifier reserved(IERC20 _token) {
        require(treasury.isReservedToken(_token), "Stabl3Staking: Not a reserved token");
        _;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./IERC20.sol";

interface IROI {
    function updateTreasury(address _treasury) external;

    function initializeUCD(address _ucd) external;

    function updatePermission(address _contractAddress, bool _state) external;

    function getReserves() external view returns (uint256);

    function getAPR() external view returns (uint256);

    function updateAPR() external;

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) external;

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external;

    function withdrawAllFunds(IERC20 _token) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./IERC20.sol";

interface ITreasury {
    function exchangeFee() external view returns (uint256);

    function isReservedToken(IERC20 _token) external view returns (bool);

    function allReservedTokens(uint) external view returns (IERC20);

    function getTreasuryPool(uint8, IERC20) external view returns (uint256);
    function getROIPool(uint8, IERC20) external view returns (uint256);
    function getHQPool(uint8, IERC20) external view returns (uint256);

    function updateROI(address _ROI) external;

    function updateHQ(address _HQ) external;

    function initializeUCD(address _ucd) external;

    function updatePermission(address _contractAddress, bool _state) external;

    function updateReservedToken(IERC20 _token, bool _state) external;

    function allReservedTokensLength() external view returns (uint256);

    function allPools(uint8 _type, IERC20 _token) external view returns (uint256, uint256, uint256);

    function sumOfAllPools(uint8 _type, IERC20 _token) external view returns (uint256);

    function getReserves() external view returns (uint256);

    function getTotalValueLocked() external view returns (uint256);

    function getRate() external view returns (uint256);

    function getRateImpact(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getRateImpact(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function getAmountOut(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function getExchangeAmountOut(IERC20 _exchangingToken, IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getExchangeAmountIn(IERC20 _exchangingToken, uint256 _amountExchangingToken, IERC20 _token) external view returns (uint256);

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external;

    function updateRate(IERC20 _token, uint256 _amountToken) external;

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) external;

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external;

    function withdrawAllFunds(IERC20 _token) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the current rounding of the division of two numbers.
     *
     * This differs from standard division with `/` in that it can round up and
     * down depending on the floating point.
     */
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a * 10 / b;
        if (result % 10 >= 5) {
            result = a / b + (a % b == 0 ? 0 : 1);
        }
        else {
            result = a / b;
        }

        return result;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, without an overflow flag
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            if (b > a) return 0;
            return a - b;
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Context.sol";

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

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint256);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}