// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IUnit {
    function balanceOf(address _address) external view returns (uint256);
    function stake(address _address) external;
    function unstake(address _address) external;
    function getStakingStatus(address _address) external view returns (bool);
    function stakingInformation() external view returns (address, bool);
}

interface genericBalanceOf {
    function balanceOf(address _address) external view returns (uint256);
}

error CallerIsSmartContract();
error CallerNotOwner();
error CallerNotApprovedUnit();
error NewOwnerZeroAddress();

contract MythicalDreamlandPreSeason {
  
    struct _stakeableUnit {
        IUnit stakeableContract;
        uint256 dailyYield;
        uint256 baseYield;
    }

    struct _stakerData {
        uint128 accumulatedRewards;
        uint64 lastClaimTimestamp;
        uint64 stakedUnlockTimestamp;
    }

    struct _seasonData {
        bool active;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    address internal _owner;
    genericBalanceOf public INHIB;
    genericBalanceOf public LORD;

    uint256 private immutable etherConversion = 1000000000000000000;

    uint256 public totalStakeableUnits;
    uint256 public lordBonus = 20;
    uint256 public inhibitorBonus = 10;
    uint256 public lockedBonus = 50;
    uint256 public optionalLockPeriod = 30;
    _seasonData public seasonData;

    mapping (address => bool) private _approvedUnits;
    mapping (address => uint256) private _stakeableUnitsLocations;
    mapping (uint256 => _stakeableUnit) private stakeableUnits;
    mapping (address => _stakerData) private stakerData;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _inhibAddress) {
        _transferOwnership(_msgSender());
        setInhibitor(_inhibAddress);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    modifier callerIsUser() {
        if (tx.origin != _msgSender() || _msgSender().code.length != 0) revert CallerIsSmartContract();
        _;
    }

    modifier onlyOwner() {
        if (owner() != _msgSender()) revert CallerNotOwner();
        _;
    }

    modifier onlyApprovedUnit() {
      if (!_approvedUnits[_msgSender()]) revert CallerNotApprovedUnit();
        _;
    }
    /**
     * @dev Returns the current timestamp rewards are calculated against.
     */
    function getTimestamp() public view returns (uint256) {
        uint256 currentTimeStamp = block.timestamp;
        if (seasonData.endTimestamp == 0) return currentTimeStamp;
        return (currentTimeStamp > seasonData.endTimestamp ? seasonData.endTimestamp : currentTimeStamp);
    }

    /**
     * @dev Stakes the `caller` tokens for `_stakingContract`. If the user elects to opt into time lock, tokens will be locked for 30 days.
     * Requirements:
     *
     * - The season must be active.
     * - The `caller` must own an Inhibitor.
     * - The `_stakingContract` must be an approved unit.
     * - the tokens of `caller` must currently be unstaked.
     */
    function stakeUnits(address _stakingContract, bool _optIntoLock) public callerIsUser {
        require(seasonData.active, "SeasonHasEnded");
        require(INHIB.balanceOf(_msgSender()) > 0, "NoInhibitorOwned");
        uint256 location = _stakeableUnitsLocations[_stakingContract];
        require(location != 0, "UnknownStakeableUnit");

        if (getUserIsStaked(_msgSender())) {
            aggregateRewards(_msgSender());
        } else {
            stakerData[_msgSender()].lastClaimTimestamp = uint64(block.timestamp);
        }

        if (_optIntoLock) {
            stakerData[_msgSender()].stakedUnlockTimestamp = uint64(block.timestamp + (optionalLockPeriod * 1 days));
        } 

        if (!stakeableUnits[location].stakeableContract.getStakingStatus(_msgSender()) && stakeableUnits[location].stakeableContract.balanceOf(_msgSender()) > 0){
            stakeableUnits[location].stakeableContract.stake(_msgSender());
        } else {
            revert("NoUnitsToStake");
        }
    }

    /**
     * @dev Unstakes the `caller` tokens for `_stakingContract`.
     * Requirements:
     *
     * - The tokens of `caller` must not currently be optionally locked.
     * - The `_stakingContract` must be an approved unit.
     * - the tokens of `caller` must currently be staked.
     */
    function unstakeUnits(address _stakingContract) public callerIsUser {
        uint256 location = _stakeableUnitsLocations[_stakingContract];
        require(location != 0, "UnknownStakeableUnit");
        require(stakerData[_msgSender()].stakedUnlockTimestamp < block.timestamp, "TimeLockActive");
        aggregateRewards(_msgSender());

        if (stakeableUnits[location].stakeableContract.getStakingStatus(_msgSender())){
            stakeableUnits[location].stakeableContract.unstake(_msgSender());
        } else {
            revert("NoUnitsToUnstake");
        }
    }

    /**
     * @dev Locks in rewards of `_address` for staking.
     * Requirements:
     *
     * - The `caller` must either be `_address` or an approved unit itself.
     */
    function aggregateRewards(address _address) public {
        require (_approvedUnits[_msgSender()] || _address == _msgSender(), "CallerLacksPermissions");
        uint256 rewards = getPendingRewards(_address);
        stakerData[_address].lastClaimTimestamp = uint64(block.timestamp);
        stakerData[_address].accumulatedRewards += uint128(rewards);
    }

    /**
     * @dev Returns the current total rewards of `_address` from staking.
     */
    function getAccumulatedRewards(address _address) public view returns (uint256) {
        unchecked {
            return getPendingRewards(_address) + stakerData[_address].accumulatedRewards;
        }
    }

    /**
     * @dev Returns the current pending rewards of `_address` from staking.
     */
    function getPendingRewards(address _address) public view returns (uint256) {
        uint256 units = totalStakeableUnits;
        if (units == 0) return 0;
        uint256 rewards;
        unchecked {
            for (uint256 i = 1; i <= units; i++){
                if (stakeableUnits[i].stakeableContract.getStakingStatus(_address)){
                    rewards += stakeableUnits[i].stakeableContract.balanceOf(_address) * stakeableUnits[i].baseYield;
                }
            }
        return rewards * getTimeSinceClaimed(_address) * getStakingMultiplier(_address) / 100;
        }
    }

    /**
     * @dev Returns the time in seconds it has been since `_address` has last locked in rewards from staking.
     */
    function getTimeSinceClaimed(address _address) public view returns (uint256) {
        if (stakerData[_address].lastClaimTimestamp == 0) return getTimestamp() - seasonData.startTimestamp;
        return stakerData[_address].lastClaimTimestamp > getTimestamp() ? 0 : getTimestamp() - stakerData[_address].lastClaimTimestamp;
    }

    /**
     * @dev Returns the total staking multiplier of `_address`.
     */
    function getStakingMultiplier(address _address) public view returns (uint256) {
        return 100 + getInhibitorMultiplier(_address) + getLockedMultiplier(_address) + getLordMultiplier(_address);
    }

    /**
     * @dev Returns the Inhibitor staking multiplier of `_address`.
     */
    function getInhibitorMultiplier(address _address) public view returns (uint256) {
        uint256 inhibBonus = INHIB.balanceOf(_address) * inhibitorBonus;
        return inhibBonus > 100 ? 100 : inhibBonus;
    }

    /**
     * @dev Returns the optional lock staking multiplier of `_address`.
     */
    function getLockedMultiplier(address _address) public view returns (uint256) {
        return stakerData[_address].stakedUnlockTimestamp > 0 ? lockedBonus : 0;
    }

    /**
     * @dev Returns the Lord staking multiplier of `_address`.
     */
    function getLordMultiplier(address _address) public view returns (uint256) {
        if (address(LORD) == address(0)) return 0;
        return LORD.balanceOf(_address) > 0 ? lordBonus : 0;
    }

    /**
     * @dev Returns the current `_stakingContract` unit balance of `_address`.
     */
    function getUserUnitBalance(address _address, address _stakingContract) public view returns (uint256) {
        return stakeableUnits[_stakeableUnitsLocations[_stakingContract]].stakeableContract.balanceOf(_address);
    }

    /**
     * @dev Returns whether `_address` is staked overall or not.
     */
    function getUserIsStaked(address _address) public view returns (bool) {
        uint256 units = totalStakeableUnits;
        if (units == 0) return false;
        for (uint256 i = 1; i <= units; i++){
            if (stakeableUnits[i].stakeableContract.getStakingStatus(_address)){
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Returns whether `_address` has `_stakingContract` units staked or not.
     */
    function getUserStakingStatus(address _address, address _stakingContract) public view returns (bool) {
        return stakeableUnits[_stakeableUnitsLocations[_stakingContract]].stakeableContract.getStakingStatus(_address);
    }

    /**
     * @dev Returns the daily token yield of `_address`.
     * - Note: This is returned in wei which is the tiniest unit so to see the daily yield in whole tokens divide by 1000000000000000000.
     */
    function getUserDailyYield(address _address) public view returns (uint256) {
        uint256 units = totalStakeableUnits;
        if (units == 0) return 0;
        uint256 rewards;
            for (uint256 i = 1; i <= units; i++){
                if (stakeableUnits[i].stakeableContract.getStakingStatus(_address)){
                    rewards += stakeableUnits[i].stakeableContract.balanceOf(_address) * stakeableUnits[i].dailyYield;
                }
            }
        return rewards * getStakingMultiplier(_address) / 100;
    }

    /**
     * @dev Updates the yield of `_stakingContract`, only the smart contract owner can call this.
     */
    function updateUnitYield(address _stakingContract, uint256 _newYield) public onlyOwner {
        uint256 location = _stakeableUnitsLocations[_stakingContract];
        require(location != 0, "UnknownStakeableUnit");
        stakeableUnits[location].dailyYield = _newYield * etherConversion;
        stakeableUnits[location].baseYield = stakeableUnits[location].dailyYield / 86400;
    }

    /**
     * @dev Returns whether `_address` will lock in rewards on receiving a new staked token. Must have been > 1 hour since last claim.
     */
    function needsRewardsUpdate(address _address) public view returns (bool) {
        return 3600 < getTimeSinceClaimed(_address);
    }

    /**
     * @dev Adds `_unitAddress` as a stakeable unit, only the smart contract owner can call this.
     */
    function addApprovedUnit(address _unitAddress) public onlyOwner {
      _approvedUnits[_unitAddress] = true;
    }

    /**
     * @dev Removes `_unitAddress` as a stakeable unit, only the smart contract owner can call this.
     */
    function removeApprovedUnit(address _unitAddress) public onlyOwner {
      delete _approvedUnits[_unitAddress];
    }

    /**
     * @dev Start staking for an approved unit with the daily yield of `_dailyYield`, only approved units can call this.
     */
    function startSeason(uint256 _dailyYield) public onlyApprovedUnit {
        uint256 newUnit = ++totalStakeableUnits;
        _stakeableUnitsLocations[_msgSender()] = newUnit;
        stakeableUnits[newUnit].stakeableContract = IUnit(_msgSender());
        stakeableUnits[newUnit].dailyYield = _dailyYield * etherConversion;
        stakeableUnits[newUnit].baseYield = stakeableUnits[newUnit].dailyYield / 86400;
        if (!seasonData.active){
            seasonData.active = true;
            seasonData.startTimestamp = block.timestamp;
        } 
    }

    /**
     * @dev Ends staking for all approved units, only approved units can call this.
     */
    function endSeason() public onlyApprovedUnit {
        seasonData.endTimestamp = block.timestamp;
        delete seasonData.active;
    }

    /**
     * @dev Updates the Inhibitor smart contract address to `_address`, only the smart contract owner can call this.
     */
    function setInhibitor(address _address) public onlyOwner {
        INHIB = genericBalanceOf(_address);
    }

    /**
     * @dev Updates the Lord smart contract address to `_address`, only the smart contract owner can call this.
     */
    function setLord(address _address) public onlyOwner {
        LORD = genericBalanceOf(_address);
    }

    /**
     * @dev Returns the current smart contract owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns information about the current Staking Season. 
     * - In the format: Whether Staking is active or not, what time staking started, what time staking ended (0 = has not ended). 
     */
    function getSeasonData() public view returns (_seasonData memory) {
        return seasonData;
    }

    /**
     * @dev Returns information about `_address` approved unit.
     * - In the format: Contract Address, Tokens generated per day, tokens generated per second.
     * - If zeros are returns, `_address` is not an approved unit. 
     */
    function getUnitDataByAddress(address _address) public view returns (_stakeableUnit memory) {
        return stakeableUnits[_stakeableUnitsLocations[_address]];
    }

    /**
     * @dev Returns information about the number `_location` approved unit.
     * - In the format: Contract Address, Tokens generated per day, tokens generated per second.
     * - If zeros are returns, that unit location does not exist. 
     */
    function getUnitDataByLocation(uint256 _location) public view returns (_stakeableUnit memory) {
        return stakeableUnits[_location];
    }

    /**
     * @dev Returns information about `_address`'s staking data.
     * - In the format: Total Accumulated rewards in Wei, Timestamp since last token claim, timestamp tokens are unstakeable (0 = unlocked).
     * - If zeros are returns, `_address` has no data. 
     */
    function getAddressData(address _address) public view returns (_stakerData memory) {
        return stakerData[_address];
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NewOwnerZeroAddress();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}