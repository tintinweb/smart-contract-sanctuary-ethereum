// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


import "./IERC20.sol";
import "./Ownable.sol";


contract EnvoyStaking is Ownable {
    event NewStake(address indexed user, uint256 totalStaked, uint256 lockupPeriod, bool isEmbargo);
    event StakeFinished(address indexed user, uint256 totalRewards);
    event LockingIncreased(address indexed user, uint256 total);
    event LockingReleased(address indexed user, uint256 total);
    IERC20 token;

    uint256 dailyBonusRate_1 = 10003271876792519; //1,0003271876792519
    uint256 dailyBonusRate_3 = 11003271876792519; //1,1003271876792519
    uint256 dailyBonusRate_6 = 12003271876792519; //1,2003271876792519
    uint256 dailyBonusRate_12 = 13003271876792519; //1,3003271876792519
    
    uint256 public totalStakes;
    uint256 public totalActiveStakes;
    uint256 public totalStaked;
    uint256 public totalStakeClaimed;
    uint256 public totalRewardsClaimed;
    
    struct Stake {
        bool exists;
        uint256 createdOn;
        uint256 initialAmount;
        uint256 lockupPeriod;
        bool claimed;
        bool isEmbargo;
    }
    
    mapping(address => Stake) stakes;
    mapping(address => uint256) public lockings;

    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function increaseLocking(address _beneficiary, uint256 _total) public onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), _total), "Couldn't take the tokens");
        
        lockings[_beneficiary] += _total;
        
        emit LockingIncreased(_beneficiary, _total);
    }
    
    function releaseFromLocking(address _beneficiary, uint256 _total) public onlyOwner {
        require(lockings[_beneficiary] >= _total, "Not enough locked tokens");
        
        lockings[_beneficiary] -= _total;

        require(IERC20(token).transfer(_beneficiary, _total), "Couldn't send the tokens");
        
        emit LockingReleased(_beneficiary, _total);
    }

    function createEmbargo(address _account, uint256 _totalStake, uint256 _lockupPeriod) public onlyOwner {
        _addStake(_account, _totalStake, _lockupPeriod, true);
    }
    
    function createStake(uint256 _totalStake, uint256 _lockupPeriod) public {
        _addStake(msg.sender, _totalStake, _lockupPeriod, false);
    }
    
    function _addStake(address _beneficiary, uint256 _totalStake, uint256 _lockupPeriod, bool _isEmbargo) internal {
        require(!stakes[_beneficiary].exists, "Stake already created");
        require(_lockupPeriod == 1 || _lockupPeriod == 3 || _lockupPeriod == 6 || _lockupPeriod == 12, "Invalid lockup period");
        require(IERC20(token).transferFrom(msg.sender, address(this), _totalStake), "Couldn't take the tokens");
        
        Stake memory stake = Stake({exists:true,
                                    createdOn: block.timestamp, 
                                    initialAmount:_totalStake, 
                                    lockupPeriod:_lockupPeriod, 
                                    claimed:false,
                                    isEmbargo:_isEmbargo
        });
        
        stakes[_beneficiary] = stake;
                                    
        totalActiveStakes++;
        totalStakes++;
        totalStaked += _totalStake;
        
        emit NewStake(_beneficiary, _totalStake, _lockupPeriod, _isEmbargo);
    }
    
    function finishStake() public {
        require(!stakes[msg.sender].isEmbargo, "This is an embargo");

        _finishStake(msg.sender);
    }
    
    function finishEmbargo(address _account) public onlyOwner {
        require(stakes[_account].isEmbargo, "Not an embargo");

        _finishStake(_account);
    }
    
    function _finishStake(address _account) internal {
        require(stakes[_account].exists, "Invalid stake");
        require(!stakes[_account].claimed, "Already claimed");

        Stake storage stake = stakes[_account];
        
        uint256 finishesOn = _calculateFinishTimestamp(stake.createdOn, stake.lockupPeriod);
        require(block.timestamp > finishesOn, "Can't be finished yet");
        
        stake.claimed = true;
        
        uint256 totalRewards = calculateRewards(_account, block.timestamp);

        totalActiveStakes -= 1;
        totalStakeClaimed += stake.initialAmount;
        totalRewardsClaimed += totalRewards;
        
        require(token.transfer(msg.sender, totalRewards), "Couldn't transfer the tokens");
        
        emit StakeFinished(msg.sender, totalRewards);
    }
    
    function _truncateTotal(uint256 _total) internal pure returns(uint256) {
        return _total / 1e18 * 1e18;
    }
    
    function calculateRewards(address _account, uint256 _date) public view returns (uint256) {
        require(stakes[_account].exists, "Invalid stake");

        uint256 daysSoFar = (_date - stakes[_account].createdOn) / 1 days;
        if (daysSoFar > stakes[_account].lockupPeriod * 30 days) {
            daysSoFar = stakes[_account].lockupPeriod * 30 days;
        }
        
        uint256 totalRewards = stakes[_account].initialAmount;

        uint256 dailyBonusRate = dailyBonusRate_1;
        if (stakes[_account].lockupPeriod == 3) {
            dailyBonusRate = dailyBonusRate_3;
        }
        else if (stakes[_account].lockupPeriod == 6) {
            dailyBonusRate = dailyBonusRate_6;
        }
        else if (stakes[_account].lockupPeriod == 12) {
            dailyBonusRate = dailyBonusRate_12;
        }
        
        for (uint256 i = 0; i < daysSoFar; i++) {
            totalRewards = totalRewards * dailyBonusRate / 1e16;
        }
        
        return _truncateTotal(totalRewards);
    }
    
    function calculateFinishTimestamp(address _account) public view returns (uint256) {
        return _calculateFinishTimestamp(stakes[_account].createdOn, stakes[_account].lockupPeriod);
    }
    
    function _calculateFinishTimestamp(uint256 _timestamp, uint256 _lockupPeriod) internal pure returns (uint256) {
        return _timestamp + _lockupPeriod * 30 days;
    }
    
    function _extract(uint256 amount, address _sendTo) public onlyOwner {
        require(token.transfer(_sendTo, amount));
    }
    
    function getStake(address _account) external view returns (bool _exists, uint256 _createdOn, uint256 _initialAmount, uint256 _lockupPeriod, bool _claimed, bool _isEmbargo, uint256 _finishesOn, uint256 _rewardsSoFar, uint256 _totalRewards) {
        Stake memory stake = stakes[_account];
        if (!stake.exists) {
            return (false, 0, 0, 0, false, false, 0, 0, 0);
        }
        uint256 finishesOn = calculateFinishTimestamp(_account);
        uint256 rewardsSoFar = calculateRewards(_account, block.timestamp);
        uint256 totalRewards = calculateRewards(_account, stake.createdOn + stake.lockupPeriod * 30 days);
        return (stake.exists, stake.createdOn, stake.initialAmount, stake.lockupPeriod, stake.claimed, stake.isEmbargo, finishesOn, rewardsSoFar, totalRewards);
    }
}