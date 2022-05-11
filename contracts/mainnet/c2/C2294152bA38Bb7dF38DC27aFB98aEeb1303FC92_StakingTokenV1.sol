// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "contracts/v1/ARDImplementationV1.sol";
import "@openzeppelin/contracts/utils/Checkpoints.sol";
//import "hardhat/console.sol";

/**
 * @title Staking Token (STK)
 * @author Gheis Mohammadi
 * @dev Implements a staking Protocol using ARD token.
 */
contract StakingTokenV1 is ARDImplementationV1 {
    using SafeMath for uint256;
    using SafeMath for uint64;

    /*****************************************************************
    ** STRUCTS & VARIABLES                                          **
    ******************************************************************/
    struct Stake {
        uint256 id;
        uint256 stakedAt; 
        uint256 value;
        uint64  lockPeriod;
    }

    struct StakeHolder {
        uint256 totalStaked;
        Stake[] stakes;
    }

    struct Rate {
        uint256 timestamp;
        uint256 rate;
    }

    struct RateHistory {
        Rate[] rates;
    }

    /*****************************************************************
    ** STATES                                                       **
    ******************************************************************/
    /**
     * @dev token bank for storing the punishments
     */
    address internal tokenBank;

    /**
     * @dev start/stop staking protocol
     */
    bool internal stakingEnabled;
    
    /**
     * @dev start/stop staking protocol
     */
    bool internal earlyUnstakingAllowed;

    /**
     * @dev The minimum amount of tokens to stake
     */
    uint256 internal minStake;

    /**
     * @dev The id of the last stake
     */
    uint256 internal _lastStakeID;

    /**
     * @dev staking history
     */
    Checkpoints.History internal totalStakedHistory;

    /**
     * @dev stakeholder address map to stakes records details.
     */
    mapping(address => StakeHolder) internal stakeholders;

    /**
     * @dev The reward rate history per locking period
     */
    mapping(uint256 => RateHistory) internal rewardTable;
     /**
     * @dev The punishment rate history per locking period 
     */
    mapping(uint256 => RateHistory) internal punishmentTable;


    /*****************************************************************
    ** MODIFIERS                                                    **
    ******************************************************************/
    modifier onlyActiveStaking() {
        require(stakingEnabled, "staking protocol stopped");
        _;
    }

    /*****************************************************************
    ** EVENTS                                                       **
    ******************************************************************/
    // staking/unstaking events
    event Staked(address indexed from, uint256 amount, uint256 newStake, uint256 oldStake);
    event Unstaked(address indexed from, uint256 amount, uint256 newStake, uint256 oldStake);
    // events for adding or changing reward/punishment rate
    event RewardRateChanged(uint256 timestamp, uint256 newRate, uint256 oldRate);
    event PunishmentRateChanged(uint256 timestamp, uint256 newRate, uint256 oldRate);
    // events for staking start/stop
    event StakingStatusChanged(bool _enabled);
    // events for stop early unstaking
    event earlyUnstakingAllowanceChanged(bool _isAllowed);
    /*****************************************************************
    ** FUNCTIONALITY                                                **
    ******************************************************************/
    /**
     * This constructor serves the purpose of leaving the implementation contract in an initialized state, 
     * which is a mitigation against certain potential attacks. An uncontrolled implementation
     * contract might lead to misleading state for users who accidentally interact with it.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        //initialize(name_,symbol_);
        _pause();
    }

    /**
     * @dev initials tokens, roles, staking settings and so on.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    function initialize(string memory name_, string memory symbol_, address newowner_) public initializer{
        _initialize(name_, symbol_, newowner_);
        
        // contract can mint the rewards
        _setupRole(MINTER_ROLE, address(this));

        // set last stake id
        _lastStakeID = 0;

        // disable staking by default
        stakingEnabled=false;

        // disable early unstaking by default
        earlyUnstakingAllowed=false;

        // set default minimum allowed staking to 500 ARD
        minStake=500000000;

        // set default token bank
        tokenBank=0x2a2e06169b9BF7F611b518185CEf7c3740CdAeeE;

        /*
        set default rewards
        ---------------------
        | period |   rate   |
        ---------------------
        | 30     |   0.25%  |
        | 90     |   1.00%  |
        | 180    |   2.50%  |
        | 360    |   6.00%  |
        ---------------------
        */
        _setReward(30,   25);
        _setReward(90,   100);
        _setReward(180,  250);
        _setReward(360,  600);

        /*
        set default punishments
        ---------------------
        | period |   rate   |
        ---------------------
        | 30     |  12.50%  |
        | 90     |  12.50%  |
        | 180    |  12.50%  |
        | 360    |  12.50%  |
        ---------------------
        */
        _setPunishment(30,   1250);
        _setPunishment(90,   1250);
        _setPunishment(180,  1250);
        _setPunishment(360,  1250);
    }

    /**
     * @dev set token bank account address
     * @param _tb address of the token bank account 
    */
    function setTokenBank(address _tb)
        public
        notPaused
        onlySupplyController
    {
        tokenBank=_tb;
    }

    /**
     * @dev set token bank account address
     * @return address of the token bank account 
    */
    function getTokenBank()
        public
        view
        returns(address)
    {
        return tokenBank;
    }    
    
    ///////////////////////////////////////////////////////////////////////
    // STAKING                                                           //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev enable/disable stoking
     * @param _enabled enable/disable
    */
    function enableStakingProtocol(bool _enabled)
        public
        notPaused
        onlySupplyController
    {
        require(stakingEnabled!=_enabled, "same as it is");
        stakingEnabled=_enabled;
        emit StakingStatusChanged(_enabled);
    }

    /**
     * @dev enable/disable stoking
     * @return bool wheter staking protocol is enabled or not
    */
    function isStakingProtocolEnabled()
        public
        view
        returns(bool)
    {
        return stakingEnabled;
    }

    /**
     * @dev enable/disable early unstaking
     * @param _enabled enable/disable
    */
    function enableEarlyUnstaking(bool _enabled)
        public
        notPaused
        onlySupplyController
    {
        require(earlyUnstakingAllowed!=_enabled, "same as it is");
        earlyUnstakingAllowed=_enabled;
        emit earlyUnstakingAllowanceChanged(_enabled);
    }

    /**
     * @dev check whether unstoking is allowed
     * @return bool wheter unstaking protocol is allowed or not
    */
    function isEarlyUnstakingAllowed()
        public
        view
        returns(bool)
    {
        return earlyUnstakingAllowed;
    }

    /**
     * @dev set the minimum acceptable amount of tokens to stake
     * @param _minStake minimum token amount to stake
    */
    function setMinimumStake(uint256 _minStake)
        public
        notPaused
        onlySupplyController
    {
        minStake=_minStake;
    }

    /**
     * @dev get the minimum acceptable amount of tokens to stake
     * @return uint256 minimum token amount to stake
    */
    function minimumAllowedStake()
        public
        view 
        returns (uint256)
    {
        return minStake;
    }

    /**
     * @dev A method for a stakeholder to create a stake.
     * @param _value The size of the stake to be created.
     * @param _lockPeriod the period of lock for this stake
     * @return uint256 new stake id 
    */
    function stake(uint256 _value, uint64 _lockPeriod)
        public
        returns(uint256)
    {
        return _stake(_msgSender(), _value, _lockPeriod);
    }
    /**
     * @dev A method to create a stake in behalf of a stakeholder.
     * @param _stakeholder address of the stake holder
     * @param _value The size of the stake to be created.
     * @param _lockPeriod the period of lock for this stake
     * @return uint256 new stake id 
     */
    function stakeFor(address _stakeholder, uint256 _value, uint64 _lockPeriod)
        public
        onlySupplyController
        returns(uint256)
    {
        return _stake(_stakeholder, _value, _lockPeriod);
    }

    /**
     * @dev A method for a stakeholder to remove a stake.
     * @param _stakedID id number of the stake
     * @param _value The size of the stake to be removed.
     */
    function unstake(uint256 _stakedID, uint256 _value)
        public
    {
        _unstake(_msgSender(),_stakedID,_value);
    }

    /**
     * @dev A method for supply controller to remove a stake of a stakeholder.
     * @param _stakeholder The stakeholder to unstake his tokens.
     * @param _stakedID The unique id of the stake
     * @param _value The size of the stake to be removed.
     */
    function unstakeFor(address _stakeholder, uint256 _stakedID, uint256 _value)
        public
        onlySupplyController
    {
        _unstake(_stakeholder,_stakedID,_value);
    }

    /**
     * @dev A method to retrieve the stake for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address _stakeholder)
        public
        view
        returns(uint256)
    {
        return stakeholders[_stakeholder].totalStaked;
    }

    /**
     * @dev A method to retrieve the stakes for a stakeholder.
     * @param _stakeholder The stakeholder to retrieve the stake for.
     * @return stakes history of the stake holder. 
     */
    function stakes(address _stakeholder)
        public
        view
        returns(Stake[] memory)
    {
        return(stakeholders[_stakeholder].stakes);
    }

    /**
     * @dev A method to get the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes()
        public
        view
        returns(uint256)
    {
        return Checkpoints.latest(totalStakedHistory);
    }

    /**
     * @dev A method to get the value of total locked stakes.
     * @return uint256 The total locked stakes.
     */
    function totalValueLocked()
        public
        view
        returns(uint256)
    {
        return Checkpoints.latest(totalStakedHistory);
    }

    /**
     * @dev Returns the value in the latest stakes history, or zero if there are no stakes.
     * @param _stakeholder The stakeholder to retrieve the latest stake amount.
     */
    function latest(address _stakeholder) 
        public 
        view 
        returns (uint256) 
    {
        uint256 pos = stakeholders[_stakeholder].stakes.length;
        return pos == 0 ? 0 : stakeholders[_stakeholder].stakes[pos - 1].value;
    }

    /**
     * @dev Stakes _value for a stake holder. It pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * @return uint256 new stake id 
     */
    function _stake(address _stakeholder, uint256 _value, uint64 _lockPeriod) 
        internal
        notPaused
        onlyActiveStaking
        returns(uint256)
    {
        //_burn(_msgSender(), _stake);
        require(_stakeholder!=address(0),"zero account");
        require(_value >= minStake, "less than minimum stake");
        require(_value<=balanceOf(_stakeholder), "not enough balance");
        require(rewardTable[_lockPeriod].rates.length > 0, "invalid period");
        require(punishmentTable[_lockPeriod].rates.length > 0, "invalid period");

        _transfer(_stakeholder, address(this), _value);
        //if(stakeholders[_msgSender()].totalStaked == 0) addStakeholder(_msgSender());
        
        uint256 pos = stakeholders[_stakeholder].stakes.length;
        uint256 old = stakeholders[_stakeholder].totalStaked;
        if (pos > 0 && stakeholders[_stakeholder].stakes[pos - 1].stakedAt == block.timestamp && 
            stakeholders[_stakeholder].stakes[pos - 1].lockPeriod == _lockPeriod) {
                stakeholders[_stakeholder].stakes[pos - 1].value = stakeholders[_stakeholder].stakes[pos - 1].value.add(_value);
        } else {
            // uint256 _id = 1;
            // if (pos > 0) _id = stakeholders[_stakeholder].stakes[pos - 1].id.add(1);
            _lastStakeID++;
            stakeholders[_stakeholder].stakes.push(Stake({
                id: _lastStakeID,
                stakedAt: block.timestamp,
                value: _value,
                lockPeriod: _lockPeriod
            }));
            pos++;
        }
        stakeholders[_stakeholder].totalStaked = stakeholders[_stakeholder].totalStaked.add(_value);
        // checkpoint total supply
        _updateTotalStaked(_value, true);

        emit Staked(_stakeholder,_value, stakeholders[_stakeholder].totalStaked, old);
        return(stakeholders[_stakeholder].stakes[pos-1].id);
    }

    /**
     * @dev Unstake _value from specific stake for a stake holder. It calculate the reward/punishment as well.
     * It pushes a value onto a History so that it is stored as the checkpoint for the current block.
     * Returns previous value and new value.
     */
    function _unstake(address _stakeholder, uint256 _stakedID, uint256 _value) 
        internal 
        notPaused
        onlyActiveStaking
    {
        //_burn(_msgSender(), _stake);
        require(_stakeholder!=address(0),"zero account");
        require(_value > 0, "zero unstake");
        require(_value <= stakeOf(_stakeholder) , "unstake more than staked");
        
        uint256 old = stakeholders[_stakeholder].totalStaked;
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        uint256 stakeIndex;
        bool found = false;
        for (stakeIndex = 0; stakeIndex < stakeholders[_stakeholder].stakes.length; stakeIndex += 1){
            if (stakeholders[_stakeholder].stakes[stakeIndex].id == _stakedID) {
                found = true;
                break;
            }
        }
        require(found,"invalid stake id");
        require(_value<=stakeholders[_stakeholder].stakes[stakeIndex].value,"not enough stake");
        uint256 _stakedAt = stakeholders[_stakeholder].stakes[stakeIndex].stakedAt;
        require(block.timestamp>=_stakedAt,"invalid stake");
        // make decision about reward/punishment
        uint256 stakingDays = (block.timestamp - _stakedAt) / (1 days);
        if (stakingDays>=stakeholders[_stakeholder].stakes[stakeIndex].lockPeriod) {
            //Reward
            uint256 _reward = _calculateReward(_stakedAt, block.timestamp, 
                _value, stakeholders[_stakeholder].stakes[stakeIndex].lockPeriod);
            if (_reward>0) {
                _mint(_stakeholder,_reward);
            }
            _transfer(address(this), _stakeholder, _value);
        } else {
            //Punishment
            require (earlyUnstakingAllowed, "early unstaking disabled");
            uint256 _punishment = _calculatePunishment(_stakedAt, block.timestamp, 
                _value, stakeholders[_stakeholder].stakes[stakeIndex].lockPeriod);
            _punishment = _punishment<_value ? _punishment : _value;
            //If there is punishment, send them to token bank
            if (_punishment>0) {
                _transfer(address(this), tokenBank, _punishment); 
            }
            uint256 withdrawal = _value.sub( _punishment );
            if (withdrawal>0) {
                _transfer(address(this), _stakeholder, withdrawal);
            }
        }

        // deduct unstaked amount from locked ARDs
        stakeholders[_stakeholder].stakes[stakeIndex].value = stakeholders[_stakeholder].stakes[stakeIndex].value.sub(_value);
        if (stakeholders[_stakeholder].stakes[stakeIndex].value==0) {
            removeStakeRecord(_stakeholder, stakeIndex);
        }
        stakeholders[_stakeholder].totalStaked = stakeholders[_stakeholder].totalStaked.sub(_value);

        // checkpoint total supply
        _updateTotalStaked(_value, false);

        //if no any stakes, remove stake holder
        if (stakeholders[_stakeholder].totalStaked==0) {
           delete stakeholders[_stakeholder];
        }

        emit Unstaked(_stakeholder, _value, stakeholders[_stakeholder].totalStaked, old);
    }

    /**
     * @dev removes a record from the stake array of a specific stake holder
     * @param _stakeholder The stakeholder to remove stake from.
     * @param index the stake index (uinque ID)
     * Returns previous value and new value.
     */
    function removeStakeRecord(address _stakeholder, uint index) 
        internal 
    {
        for(uint i = index; i < stakeholders[_stakeholder].stakes.length-1; i++){
            stakeholders[_stakeholder].stakes[i] = stakeholders[_stakeholder].stakes[i+1];      
        }
        stakeholders[_stakeholder].stakes.pop();
    }

    /**
     * @dev update the total stakes history
     * @param _by The amount of stake to be added or deducted from history
     * @param _increase true means new staked is added to history and false means it's unstake and stake should be deducted from history
     * Returns previous value and new value.
     */
    function _updateTotalStaked(uint256 _by, bool _increase) 
        internal 
        onlyActiveStaking
    {
        uint256 currentStake = Checkpoints.latest(totalStakedHistory);

        uint256 newStake;
        if (_increase) {
            newStake = currentStake.add(_by);
        } else {
            newStake = currentStake.sub(_by);
        }

        // add new value to total history
        Checkpoints.push(totalStakedHistory, newStake);
    }

    /**
     * @dev A method to get last stake id.
     * @return uint256 returns the ID of last stake
     */
    function lastStakeID()
        public
        view
        returns(uint256)
    {
        return _lastStakeID;
    }
    ///////////////////////////////////////////////////////////////////////
    // STAKEHOLDERS                                                      //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev A method to check if an address is a stakeholder.
     * @param _address The address to verify.
     * @return bool Whether the address is a stakeholder or not
     */
    function isStakeholder(address _address)
        public
        view
        returns(bool)
    {
        return (stakeholders[_address].totalStaked>0);
    }

    ///////////////////////////////////////////////////////////////////////
    // REWARDS / PUNISHMENTS                                             //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev set reward rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The reward per entire period for the given lock period
    */
    function setReward(uint256 _lockPeriod, uint64 _value)
        public
        notPaused
        onlySupplyController
    {
        _setReward(_lockPeriod,_value);
    }

    /**
     * @dev A method for adjust rewards table by single call. Should be called after first deployment.
     * this method merges the new table with current reward table (if it is existed)
     * @param _rtbl reward table ex:
     * const rewards = [
     *       [30,  200],
     *       [60,  300],
     *       [180, 500],
     *   ];
    */
    function setRewardTable(uint64[][] memory _rtbl)
        public
        notPaused
        onlySupplyController
    {
        for (uint64 _rIndex = 0; _rIndex<_rtbl.length; _rIndex++) {
            _setReward(_rtbl[_rIndex][0], _rtbl[_rIndex][1]);
        }
    }

    /**
     * @dev set reward rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The reward per entire period for the given lock period
    */
    function _setReward(uint256 _lockPeriod, uint64 _value)
        internal
    {
        require(_value>=0 && _value<=10000, "invalid rate");
        uint256 ratesCount = rewardTable[_lockPeriod].rates.length;
        uint256 oldRate = ratesCount>0 ? rewardTable[_lockPeriod].rates[ratesCount-1].rate : 0;
        require(_value!=oldRate, "duplicate rate");
        rewardTable[_lockPeriod].rates.push(Rate({
            timestamp: block.timestamp,
            rate: _value
        }));
        emit RewardRateChanged(block.timestamp,_value,oldRate);
    }

    /**
     * @dev A method for retrieve the latest reward rate for a give lock period
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function rewardRate(uint256 _lockPeriod)
        public
        view
        returns(uint256)
    {
        require(rewardTable[_lockPeriod].rates.length>0,"no rate");
        return _lastRate(rewardTable[_lockPeriod]);
    }

    /**
     * @dev A method for retrieve the history of the reward rate for a given lock period
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function rewardRateHistory(uint256 _lockPeriod)
        public
        view
        returns(RateHistory memory)
    {
        require(rewardTable[_lockPeriod].rates.length>0,"no rate");
        return rewardTable[_lockPeriod];
    }

    /**
     * @dev set punishment rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The punishment per entire period for the given lock period
    */
    function setPunishment(uint256 _lockPeriod, uint64 _value)
        public
        notPaused
        onlySupplyController
    {
        _setPunishment(_lockPeriod, _value);
    }

    /**
     * @dev A method for adjust punishment table by single call.
     * this method merges the new table with current punishment table (if it is existed)
     * @param _ptbl punishment table ex:
     * const punishments = [
     *       [30,  200],
     *       [60,  300],
     *       [180, 500],
     *   ];
    */
    function setPunishmentTable(uint64[][] memory _ptbl)
        public
        notPaused
        onlySupplyController
    {
        for (uint64 _pIndex = 0; _pIndex<_ptbl.length; _pIndex++) {
            _setPunishment(_ptbl[_pIndex][0], _ptbl[_pIndex][1]);
        }
    }

    /**
     * @dev set punishment rate in percentage (2 decimal zeros) for a specific lock period.
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
     * @param _value The punishment per entire period for the given lock period
    */
    function _setPunishment(uint256 _lockPeriod, uint64 _value)
        internal
    {
        require(_value>=0 && _value<=2000, "invalid rate");
        uint256 ratesCount = punishmentTable[_lockPeriod].rates.length;
        uint256 oldRate = ratesCount>0 ? punishmentTable[_lockPeriod].rates[ratesCount-1].rate : 0;
        require(_value!=oldRate, "same as it is");
        punishmentTable[_lockPeriod].rates.push(Rate({
            timestamp: block.timestamp,
            rate: _value
        }));
        emit PunishmentRateChanged(block.timestamp,_value,oldRate);
    }

    /**
     * @dev A method to get the latest punishment rate
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function punishmentRate(uint256 _lockPeriod)
        public
        view
        returns(uint256)
    {
        require(punishmentTable[_lockPeriod].rates.length>0,"no rate");
        return _lastRate(punishmentTable[_lockPeriod]);
    }

    /**
     * @dev A method for retrieve the history of the punishment rate for a give lock period
     * if there is no rate for given lock period, it throws error
     * @param _lockPeriod locking period (ex: 30,60,90,120,150, ...) in days
    */
    function punishmentRateHistory(uint256 _lockPeriod)
        public
        view
        returns(RateHistory memory)
    {
        require(punishmentTable[_lockPeriod].rates.length>0,"no rate");
        return punishmentTable[_lockPeriod];
    }

    /**
     * @dev A method to inquiry the rewards from the specific stake of the stakeholder.
     * @param _stakeholder The stakeholder to get the reward for his stake.
     * @param _stakedID The stake id.
     * @return uint256 The reward of the stake.
     */
    function rewardOf(address _stakeholder,  uint256 _stakedID)
        public
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        // uint256 _totalRewards = 0;
        // for (uint256 i = 0; i < stakeholders[_stakeholder].stakes.length; i++){
        //     Stake storage s = stakeholders[_stakeholder].stakes[i];
        //     uint256 r = _calculateReward(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
        //     _totalRewards = _totalRewards.add(r);
        // }
        // return _totalRewards;
        return calculateRewardFor(_stakeholder,_stakedID);
    }

    /**
     * @dev A method to inquiry the punishment from the early unstaking of the specific stake of the stakeholder.
     * @param _stakeholder The stakeholder to get the punishment for early unstake.
     * @param _stakedID The stake id.
     * @return uint256 The punishment of the early unstaking of the stake.
     */
    function punishmentOf(address _stakeholder,  uint256 _stakedID)
        public
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        // uint256 _totalPunishments = 0;
        // for (uint256 i = 0; i < stakeholders[_stakeholder].stakes.length; i++){
        //     Stake storage s = stakeholders[_stakeholder].stakes[i];
        //     uint256 r = _calculatePunishment(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
        //     _totalPunishments = _totalPunishments.add(r);
        // }
        // return _totalPunishments;
        return calculatePunishmentFor(_stakeholder,_stakedID);
    }

    /** 
     * @dev A simple method to calculate the rewards for a specific stake of a stakeholder.
     * The rewards only is available after stakeholder unstakes the ARDs.
     * @param _stakeholder The stakeholder to calculate rewards for.
     * @param _stakedID The stake id.
     * @return uint256 return the reward for the stake with specific ID.
     */
    function calculateRewardFor(address _stakeholder, uint256 _stakedID)
        internal
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        uint256 stakeIndex;
        bool found = false;
        for (stakeIndex = 0; stakeIndex < stakeholders[_stakeholder].stakes.length; stakeIndex += 1){
            if (stakeholders[_stakeholder].stakes[stakeIndex].id == _stakedID) {
                found = true;
                break;
            }
        }
        require(found,"invalid stake id");
        Stake storage s = stakeholders[_stakeholder].stakes[stakeIndex];
        return _calculateReward(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
    }

    /** 
     * @dev A simple method to calculates the reward for stakeholder from a given period which is set by _from and _to.
     * @param _from The start date of the period.
     * @param _to The end date of the period.
     * @param _value Amount of staking.
     * @param _lockPeriod lock period for this staking.
     * @return uint256 total reward for given period
     */
    function _calculateReward(uint256 _from, uint256 _to, uint256 _value, uint256 _lockPeriod)
        internal
        view
        returns(uint256)
    {
        require (_to>=_from,"invalid stake time");
        uint256 durationDays = _duration(_from,_to,_lockPeriod);
        if (durationDays<_lockPeriod) return 0;

        return _calculateTotal(rewardTable[_lockPeriod],_from,_to,_value,_lockPeriod);
    }

   /** 
     * @dev A simple method to calculate punishment for early unstaking of a specific stake of the stakeholder.
     * The punishment is only charges after stakeholder unstakes the ARDs.
     * @param _stakeholder The stakeholder to calculate punishment for.
     * @param _stakedID The stake id.
     * @return uint256 return the punishment for the stake with specific ID.
     */
    function calculatePunishmentFor(address _stakeholder, uint256 _stakedID)
        internal
        view
        returns(uint256)
    {
        require(stakeholders[_stakeholder].totalStaked>0,"not stake holder");
        uint256 stakeIndex;
        bool found = false;
        for (stakeIndex = 0; stakeIndex < stakeholders[_stakeholder].stakes.length; stakeIndex += 1){
            if (stakeholders[_stakeholder].stakes[stakeIndex].id == _stakedID) {
                found = true;
                break;
            }
        }
        require(found,"invalid stake id");
        Stake storage s = stakeholders[_stakeholder].stakes[stakeIndex];
        return _calculatePunishment(s.stakedAt, block.timestamp, s.value, s.lockPeriod);
    }

    /** 
     * @dev A simple method that calculates the punishment for stakeholder from a given period which is set by _from and _to.
     * @param _from The start date of the period.
     * @param _to The end date of the period.
     * @param _value Amount of staking.
     * @param _lockPeriod lock period for this staking.
     * @return uint256 total punishment for given period
     */
    function _calculatePunishment(uint256 _from, uint256 _to, uint256 _value, uint256 _lockPeriod)
        internal
        view
        returns(uint256)
    {
        require (_to>=_from,"invalid stake time");
        uint256 durationDays = _to.sub(_from).div(1 days);
        if (durationDays>=_lockPeriod) return 0;
        // retrieve latest punishment rate for the lock period
        uint256 pos = punishmentTable[_lockPeriod].rates.length;
        require (pos>0, "invalid lock period");
        
        return _value.mul(punishmentTable[_lockPeriod].rates[pos-1].rate).div(10000); 
        //return _calculateTotal(punishmentTable[_lockPeriod],_from,_to,_value,_lockPeriod);
    }

    /** 
     * @dev calculates the total amount of reward/punishment for a given period which is set by _from and _to. This method calculates 
     * based on the history of rate changes. So if in this period, three times rate have had changed, this function calculates for each
     * of the rates separately and returns total 
     * @param _history The history of rates
     * @param _from The start date of the period.
     * @param _to The end date of the period.
     * @param _value Amount of staking.
     * @param _lockPeriod lock period for this staking.
     * @return uint256 total reward/punishment for given period considering the rate changes
     */
    function _calculateTotal(RateHistory storage _history, uint256 _from, uint256 _to, uint256 _value, uint256 _lockPeriod)
        internal
        view
        returns(uint256)
    {
        //find the first rate before _from 

        require(_history.rates.length>0,"invalid period");
        uint256 rIndex;
        for (rIndex = _history.rates.length-1; rIndex>0; rIndex-- ) {
            if (_history.rates[rIndex].timestamp<=_from) break;
        }
        require(_history.rates[rIndex].timestamp<=_from, "lack of history rates");
        // if rate has been constant during the staking period, just calculate whole period using same rate
        if (rIndex==_history.rates.length-1) {
            return _value.mul(_history.rates[rIndex].rate).div(10000);  //10000 ~ 100.00
        }
        // otherwise we have to calculate reward per each rate change record from history

        /*                                       [1.5%]             [5%]               [2%]
           Rate History:    (deployed)o(R0)----------------o(R1)-------------o(R2)-----------------o(R3)--------------------
           Given Period:                   o(from)--------------------------------------o(to)
           
           Calculations:     ( 1.5%*(R1-from) + 5%*(R2-R1) + 2%*(to-R2) ) / Period
        */
        uint256 total = 0;
        uint256 totalDuration = 0;
        uint256 prevTimestamp = _from;
        uint256 diff = 0;
        uint256 maxTotalDuration = _duration(_from,_to, _lockPeriod);
        for (rIndex++; rIndex<=_history.rates.length && totalDuration<maxTotalDuration; rIndex++) {
            
            if (rIndex<_history.rates.length){
                diff = _duration(prevTimestamp, _history.rates[rIndex].timestamp, 0);
                prevTimestamp = _history.rates[rIndex].timestamp;
            }else {
                diff = _duration(prevTimestamp, _to, 0);
                prevTimestamp = _to;
            }

            totalDuration = totalDuration.add(diff);
            if (totalDuration>maxTotalDuration) {
                diff = diff.sub(totalDuration.sub(maxTotalDuration));
                totalDuration = maxTotalDuration;
            }
            total = total.add(_history.rates[rIndex-1].rate.mul(diff));
        }
        return _value.mul(total).div(_lockPeriod.mul(10000));
    }

    /**
    * @dev this function calculates the number of days between t1 and t2
    * @param t1 the period start
    * @param t2 the period end
    * @param maxDuration max duration. if the number of days is more than max, it returns max 
    * @return uint256 number of days
     */
    function _duration(uint256 t1, uint256 t2, uint256 maxDuration)
        internal
        pure
        returns(uint256)
    {
        uint256 diffDays = t2.sub(t1).div(1 days);
        if (maxDuration==0) return diffDays;
        return Math.min(diffDays,maxDuration);
    }

    /**
    * @dev this function retrieve last rate of a given rate history
    * @param _history the history of rate changes
    * @return uint256 the last rate which is current rate
     */
    function _lastRate(RateHistory storage _history)
        internal
        view
        returns(uint256)
    {
        return _history.rates[_history.rates.length-1].rate;
    }

    // storage gap for adding new states in upgrades 
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title ARDImplementation
 * @dev this contract is a Pausable ERC20 token with Burn and Mint
 * controlled by a SupplyController. By implementing ARDImplementation
 * this contract also includes external methods for setting
 * a new implementation contract for the Proxy.
 * NOTE: The storage defined here will actually be held in the Proxy
 * contract and all calls to this contract should be made through
 * the proxy, including admin actions done as owner or supplyController.
 * Any call to transfer against this contract should fail
 * with insufficient funds since no tokens will be issued there.
 */
contract ARDImplementationV1 is ERC20Upgradeable, 
                                OwnableUpgradeable, 
                                AccessControlUpgradeable,
                                PausableUpgradeable, 
                                ReentrancyGuardUpgradeable {

    /*****************************************************************
    ** MATH                                                         **
    ******************************************************************/
    using SafeMath for uint256;

    /*****************************************************************
    ** ROLES                                                        **
    ******************************************************************/
    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant ASSET_PROTECTION_ROLE = keccak256("ASSET_PROTECTION_ROLE");
    bytes32 public constant SUPPLY_CONTROLLER_ROLE = keccak256("SUPPLY_CONTROLLER_ROLE");

    /*****************************************************************
    ** MODIFIERS                                                    **
    ******************************************************************/
    modifier onlySuperAdminRole() {
        require(hasRole(SUPER_ADMIN_ROLE, _msgSender()), "only super admin role");
        _;
    }

    modifier onlyAssetProtectionRole() {
        require(hasRole(ASSET_PROTECTION_ROLE, _msgSender()), "only asset protection role");
        _;
    }

    modifier onlySupplyController() {
        require(hasRole(SUPPLY_CONTROLLER_ROLE, _msgSender()), "only supply controller role");
        _;
    }

    modifier onlyMinterRole() {
        require(hasRole(MINTER_ROLE, _msgSender()), "only minter role");
        _;
    }

    modifier onlyBurnerRole() {
        require(hasRole(BURNER_ROLE, _msgSender()), "only burner role");
        _;
    }

    modifier notPaused() {
        require(!paused(), "is paused");
        _;
    }
    /*****************************************************************
    ** EVENTS                                                       **
    ******************************************************************/
    // ASSET PROTECTION EVENTS
    event AddressFrozen(address indexed addr);
    event AddressUnfrozen(address indexed addr);
    event FrozenAddressWiped(address indexed addr);
    event AssetProtectionRoleSet (
        address indexed oldAssetProtectionRole,
        address indexed newAssetProtectionRole
    );

    // SUPPLY CONTROL EVENTS
    event SupplyIncreased(address indexed to, uint256 value);
    event SupplyDecreased(address indexed from, uint256 value);
    event SupplyControllerSet(
        address indexed oldSupplyController,
        address indexed newSupplyController
    );

    /*****************************************************************
    ** DATA                                                         **
    ******************************************************************/

    uint8 internal _decimals;

    address internal _curSuperadmin;

    // ASSET PROTECTION DATA
    mapping(address => bool) internal frozen;

    /*****************************************************************
    ** FUNCTIONALITY                                                **
    ******************************************************************/
    /**
     * @dev sets 0 initials tokens, the owner, and the supplyController.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    //uint256 private _totalSupply;
    function _initialize(string memory name_, string memory symbol_, address newowner_) internal {
        __Ownable_init();
        __ERC20_init(name_, symbol_);

        // it lets deployer set other address as owner rather than sender. It helps to make contract owned by multisig wallet 
        address owner_ =  newowner_==address(0) ?  _msgSender() : newowner_;
        
        //set super admin role for manage admins
        _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
        _curSuperadmin = owner_;
        //set default admin role for all roles
        _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
        //setup other roles
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ASSET_PROTECTION_ROLE, ADMIN_ROLE);
        _setRoleAdmin(SUPPLY_CONTROLLER_ROLE, ADMIN_ROLE);

        // Grant the contract deployer the default super admin role
        // super admin is able to grant and revoke admin roles
        _setupRole(SUPER_ADMIN_ROLE, owner_);
        // Grant the contract deployer all other roles by default
        _grantAllRoles(owner_);

        if (owner_!=_msgSender()) {
            _transferOwnership(owner_);
        }
        // set the number of decimals to 6
        _decimals = 6;
    }

    /**
    The number of decimals
    */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /**
    The protocol implementation version
    */
    function protocolVersion() public pure returns (bytes32) {
        return "1.0";
    }
    ///////////////////////////////////////////////////////////////////////
    // OWNERSHIP                                                         //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * it transfers all the roles as well
     * Can only be called by the current owner.
     */
    function transferOwnershipAndRoles(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _revokeAllRoles(owner());
        _grantAllRoles(newOwner);
        if (_curSuperadmin==owner()) {
            transferSupeAdminTo(newOwner);
        }
        _transferOwnership(newOwner);
    }
    ///////////////////////////////////////////////////////////////////////
    // BEFORE/AFTER TOKEN TRANSFER                                       //
    ///////////////////////////////////////////////////////////////////////

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
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {
        // check to not to be paused
        require(!paused(),"is paused");
        // amount has to be more than 0
        require(amount>0, "zero amount");
        // check the addresses no to be frozen
        require(!frozen[_msgSender()], "caller is frozen");
        require(!frozen[from] || from==address(0), "address from is frozen");
        require(!frozen[to] || to==address(0), "address to is frozen");
        // check the roles in case of minting or burning
        // if (from == address(0)) {       // is minting
        //     require(hasRole(MINTER_ROLE,_msgSender()) || hasRole(SUPPLY_CONTROLLER_ROLE,_msgSender()), "Caller is not a minter");
        // } else if (to == address(0)) {  // is burning
        //     require(hasRole(BURNER_ROLE,_msgSender()) || hasRole(SUPPLY_CONTROLLER_ROLE,_msgSender()), "Caller is not a burner");
        // }
    }

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
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override virtual {

        require(amount>0,"zero amount");
        if (from == address(0)) {       // is minted
            emit SupplyIncreased( to, amount);
        } else if (to == address(0)) {  // is burned
            emit SupplyDecreased( from, amount);
        }
        
    }

    ///////////////////////////////////////////////////////////////////////
    // APPROVE                                                           //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(!paused(),"is paused");
        require(!frozen[_msgSender()], "caller is frozen");
        require(!frozen[spender], "address spender is frozen");
        _approve(_msgSender(), spender, amount);
        return true;
    }

    ///////////////////////////////////////////////////////////////////////
    // PAUSE / UNPAUSE                                                   //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlySuperAdminRole {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlySuperAdminRole {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////////////
    // ROLE MANAGEMENT                                                   //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function grantRole(bytes32 role, address account) public override notPaused onlyRole(getRoleAdmin(role)) {
        require(account!=address(0),"zero account");
        require(role!=SUPER_ADMIN_ROLE,"invalid role");
        _grantRole(role, account);
    }

    /**
     * @dev Grants all roles to `account`.
     *
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function _grantAllRoles(address account) internal {
        require(account!=address(0),"zero account");
        _grantRole(ADMIN_ROLE, account);
        _grantRole(MINTER_ROLE, account);
        _grantRole(BURNER_ROLE, account);
        _grantRole(ASSET_PROTECTION_ROLE, account);
        _grantRole(SUPPLY_CONTROLLER_ROLE, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function revokeRole(bytes32 role, address account) public override notPaused onlyRole(getRoleAdmin(role)) {
        require(account!=address(0),"zero account");
        require(role!=SUPER_ADMIN_ROLE,"invalid role");
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes all roles from `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - contract not to be paused
     * - account can't be zero address 
     */
    function _revokeAllRoles(address account) internal {
        require(account!=address(0),"zero account");
        _revokeRole(ADMIN_ROLE, account);
        _revokeRole(MINTER_ROLE, account);
        _revokeRole(BURNER_ROLE, account);
        _revokeRole(ASSET_PROTECTION_ROLE, account);
        _revokeRole(SUPPLY_CONTROLLER_ROLE, account);
    }

    /**
     * @dev transfer the Super Admin role to specific account. Only one account can be super admin
     * @param _addr The address to assign super admin role.
     */
    function transferSupeAdminTo(address _addr) public notPaused onlyOwner {
        _revokeRole(SUPER_ADMIN_ROLE, _curSuperadmin);
        _grantRole(SUPER_ADMIN_ROLE, _addr);
        _curSuperadmin=_addr;
    }
    function superAdmin() public view returns (address) {
        return _curSuperadmin;
    }

    /**
     * @dev set/revoke the Role's Admin role to specific account
     * @param _addr The address to assign minter role.
     */
    function setAdminRole(address _addr) public {
        grantRole(ADMIN_ROLE, _addr);
    }
    function revokeAdminRole(address _addr) public {
        revokeRole(ADMIN_ROLE, _addr);
    }
    function isAdmin(address _addr) public view returns (bool) {
        return hasRole(ADMIN_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Minter role to specific account
     * @param _addr The address to assign minter role.
     */
    function setMinterRole(address _addr) public {
        grantRole(MINTER_ROLE, _addr);
    }
    function revokeMinterRole(address _addr) public {
        revokeRole(MINTER_ROLE, _addr);
    }
    function isMinter(address _addr) public view returns (bool) {
        return hasRole(MINTER_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Burner role to specific account
     * @param _addr The address to assign burner role.
     */
    function setBurnerRole(address _addr) public {
        grantRole(BURNER_ROLE, _addr);
    }
    function revokeBurnerRole(address _addr) public {
        revokeRole(BURNER_ROLE, _addr);
    }
    function isBurner(address _addr) public view returns (bool) {
        return hasRole(BURNER_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Asset Protection role to specific account
     * @param _addr The address to assign asset protection role.
     */
    function setAssetProtectionRole(address _addr) public {
        grantRole(ASSET_PROTECTION_ROLE, _addr);
    }
    function revokeAssetProtectionRole(address _addr) public {
        revokeRole(ASSET_PROTECTION_ROLE, _addr);
    }
    function isAssetProtection(address _addr) public view returns (bool) {
        return hasRole(ASSET_PROTECTION_ROLE, _addr);
    }

    /**
     * @dev set/revoke the Supply Controller role to specific account
     * @param _addr The address to assign supply controller role.
     */
    function setSupplyControllerRole(address _addr) public {
        grantRole(SUPPLY_CONTROLLER_ROLE, _addr);
    }
    function revokeSupplyControllerRole(address _addr) public {
        revokeRole(SUPPLY_CONTROLLER_ROLE, _addr);
    }
    function isSupplyController(address _addr) public view returns (bool) {
        return hasRole(SUPPLY_CONTROLLER_ROLE, _addr);
    }

    ///////////////////////////////////////////////////////////////////////
    // ASSET PROTECTION FUNCTIONALITY                                    //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Freezes an address balance from being transferred.
     * @param _addr The new address to freeze.
     */
    function freeze(address _addr) public notPaused onlyAssetProtectionRole {
        require(_addr!=owner(), "can't freeze owner");
        require(_addr!=_msgSender(), "can't freeze itself");
        require(!frozen[_addr], "address already frozen");
        //TODO: shouldn't be able to freeze admin,minter,burner,asset protection,supply controller roles
        frozen[_addr] = true;
        emit AddressFrozen(_addr);
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param _addr The new address to unfreeze.
     */
    function unfreeze(address _addr) public notPaused onlyAssetProtectionRole {
        require(frozen[_addr], "address already unfrozen");
        frozen[_addr] = false;
        emit AddressUnfrozen(_addr);
    }

    /**
     * @dev Wipes the balance of a frozen address, burning the tokens
     * and setting the approval to zero.
     * @param _addr The new frozen address to wipe.
     */
    function wipeFrozenAddress(address _addr) public notPaused onlyAssetProtectionRole {
        require(frozen[_addr], "address is not frozen");
        uint256 _balance = balanceOf(_addr);
        frozen[_addr] = false;
        _burn(_addr,_balance);
        frozen[_addr] = true;
        emit FrozenAddressWiped(_addr);
    }

    /**
    * @dev Gets whether the address is currently frozen.
    * @param _addr The address to check if frozen.
    * @return A bool representing whether the given address is frozen.
    */
    function isFrozen(address _addr) public view returns (bool) {
        return frozen[_addr];
    }


    ///////////////////////////////////////////////////////////////////////
    // MINTING / BURNING                                                 //
    ///////////////////////////////////////////////////////////////////////

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address account, uint256 amount) public onlyMinterRole {
        _mint(account, amount);
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
    function burn(address account, uint256 amount) public onlyBurnerRole {
        _burn(account, amount);
    }

    ///////////////////////////////////////////////////////////////////////
    // SUPPLY CONTROL                                                    //
    ///////////////////////////////////////////////////////////////////////
    /**
     * @dev Increases the total supply by minting the specified number of tokens to the supply controller account.
     * @param _value The number of tokens to add.
     * @return A boolean that indicates if the operation was successful.
     */
    function increaseSupply(uint256 _value) public onlySupplyController returns (bool) {
        _mint(_msgSender(), _value);
        return true;
    }

    /**
     * @dev Decreases the total supply by burning the specified number of tokens from the supply controller account.
     * @param _value The number of tokens to remove.
     * @return A boolean that indicates if the operation was successful.
     */
    function decreaseSupply(uint256 _value) public onlySupplyController returns (bool) {
        require(_value <= balanceOf(_msgSender()), "not enough supply");
        _burn(_msgSender(), _value);
        return true;
    }

    // storage gap for adding new states in upgrades 
    uint256[50] private __stgap0;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Checkpoints.sol)
pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    /**
     * @dev Returns the value in the latest checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint256) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (self._checkpoints[mid]._blockNumber > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        uint256 pos = self._checkpoints.length;
        uint256 old = latest(self);
        if (pos > 0 && self._checkpoints[pos - 1]._blockNumber == block.number) {
            self._checkpoints[pos - 1]._value = SafeCast.toUint224(value);
        } else {
            self._checkpoints.push(
                Checkpoint({_blockNumber: SafeCast.toUint32(block.number), _value: SafeCast.toUint224(value)})
            );
        }
        return (old, value);
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMath {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

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
        __Context_init_unchained();
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
    uint256[49] private __gap;
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
        __Context_init_unchained();
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
     * - input must fit into 8 bits.
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
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}