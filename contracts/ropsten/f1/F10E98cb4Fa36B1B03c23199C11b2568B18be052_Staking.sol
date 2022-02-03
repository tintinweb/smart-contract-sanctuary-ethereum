// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Staking {
    address public dogeStaking;
    address public loriaStaking;
    address public dogeReward;
    address public loriaReward;

    event Staked(address user, uint amount, uint index);
    event Withdrawn(address user, uint amount);
    event RewardPaid(address user, uint amount);
    event RecoverStaking(address user, uint amount);
    event Claimed(address user, uint amount);

    uint public DogeAPY = 2;
    uint public LoriaAPY = 2;
    uint public DogeElig = 15;
    uint public LoriaElig = 30;
    uint public DogePenalty = 100;
    uint public LoriaPenalty = 100;
    uint private day = 24 * 3600;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint private _totalDogeSupply;
    uint private _totalLoriaSupply;
    uint256 private _totalStakedUserCount;
    address[] private _stakedAddressList;
    address private owner;
    
    struct StakingItem {
        uint _stakedToken;
        uint _initBalance;
        uint _period;
        uint _apy;
        uint _eligibility;
        uint _penalty;
        uint _claimedBalance;
        uint256 _updated_at;
        uint256 _created_at;
        bool _isRewarded;
    }

    mapping(address => StakingItem[]) private _stakingList;
    
    constructor(address _dogeStaking, address _loriaStaking, address _dogeReward, address _loriaReward) {
        dogeStaking = _dogeStaking;
        loriaStaking = _loriaStaking;
        dogeReward = _dogeReward;
        loriaReward = _loriaReward;
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function stake(uint _type, uint _amount, uint _period) external {
        require(_type < 2,"No existed token");
        if (_type == 0) {
            IERC20(dogeStaking).transferFrom(msg.sender, address(this), _amount);
            _totalDogeSupply += _amount;
        }
        else {
            IERC20(loriaStaking).transferFrom(msg.sender, address(this), _amount);
            _totalLoriaSupply += _amount;
        }
        
        bool flag = false;
        if (_stakingList[msg.sender].length > 0) {
            uint lastIdx = _stakingList[msg.sender].length - 1;
            if (_stakingList[msg.sender][lastIdx]._stakedToken == _type) {
                if (_stakingList[msg.sender][lastIdx]._stakedToken == 0) {
                    if (_stakingList[msg.sender][lastIdx]._apy != LoriaAPY || _stakingList[msg.sender][lastIdx]._eligibility != LoriaElig || _stakingList[msg.sender][lastIdx]._penalty != LoriaPenalty) {
                        flag = true;
                    }
                }
                
                else {
                    if (_stakingList[msg.sender][lastIdx]._apy != DogeAPY || _stakingList[msg.sender][lastIdx]._eligibility != DogeElig || _stakingList[msg.sender][lastIdx]._penalty != LoriaPenalty) {
                        flag = true;
                    }
                }

                if (!flag) {
                    _stakingList[msg.sender][lastIdx]._initBalance += _amount;
                    _stakingList[msg.sender][lastIdx]._created_at = block.timestamp;
                    _stakingList[msg.sender][lastIdx]._updated_at = block.timestamp;
                    _stakingList[msg.sender][lastIdx]._isRewarded = false;
                }
            }

            else flag = true;
        }
        else flag = true;

        if (flag) {
            uint _elig = _type == 0 ? LoriaElig : DogeElig;
            uint _apy = _type == 0 ? LoriaAPY : DogeAPY;
            uint _penalty = _type == 0 ? LoriaPenalty : DogePenalty;

            StakingItem memory item = StakingItem({
                _stakedToken: _type,
                _initBalance: _amount,
                _created_at: block.timestamp,
                _updated_at: block.timestamp,
                _period: _period,
                _eligibility: _elig,
                _apy: _apy,
                _penalty: _penalty,
                _claimedBalance: 0,
                _isRewarded: false
            });
            _stakingList[msg.sender].push(item);
        }

        uint index = _stakingList[msg.sender].length - 1;
        receiveReward(index, _amount, _type);
        emit Staked(msg.sender, _amount, index);
    }

    function allWithdraw() external {
        StakingItem[] memory item = _stakingList[msg.sender];
        uint timestamp = block.timestamp;
        uint _dogeStaked = 0;
        uint _loriaStaked = 0;
        uint _dogeReward = 0;
        uint _loriaReward = 0;
        for (uint i = 0; i < item.length; i ++) {
            if (timestamp - item[i]._created_at >= item[i]._eligibility * 1 days) {
                if (item[i]._stakedToken == 0) {
                    _dogeStaked += item[i]._initBalance;
                    _dogeReward += item[i]._initBalance;
                }
                
                else {
                    _loriaReward += _stakingList[msg.sender][i]._initBalance;
                    _loriaStaked += item[i]._initBalance;
                }
            }
        }

        if (_dogeReward > 0) IERC20(dogeReward).transferFrom(msg.sender,address(this), _dogeReward);
        else if (_loriaReward > 0) IERC20(loriaReward).transferFrom(msg.sender,address(this), _loriaReward);

        if (_dogeStaked > 0) IERC20(dogeStaking).transfer(msg.sender, _dogeStaked);
        else if (_loriaStaked > 0) IERC20(loriaStaking).transfer(msg.sender, _loriaStaked);
        delete _stakingList[msg.sender];
    }
    
    function withdraw(uint idx) public {
        if (_stakingList[msg.sender][idx]._stakedToken == 0) {
            IERC20(dogeReward).transferFrom(msg.sender, address(this), _stakingList[msg.sender][idx]._initBalance);
            if (block.timestamp - _stakingList[msg.sender][idx]._created_at >= _stakingList[msg.sender][idx]._eligibility * 1 days) {
                IERC20(dogeStaking).transfer(msg.sender, _stakingList[msg.sender][idx]._initBalance);
            }
        }
        else {
            IERC20(loriaReward).transferFrom(msg.sender, address(this), _stakingList[msg.sender][idx]._initBalance);
            if (block.timestamp - _stakingList[msg.sender][idx]._created_at >= _stakingList[msg.sender][idx]._eligibility * 1 days) {
                IERC20(loriaStaking).transfer(msg.sender, _stakingList[msg.sender][idx]._initBalance);
            }
        }
        delete _stakingList[msg.sender][idx];
    }

    function claim(uint idx) public {
        uint timestamp = block.timestamp;
        uint diff = timestamp - _stakingList[msg.sender][idx]._updated_at;
        uint created = timestamp - _stakingList[msg.sender][idx]._created_at;

        if ( diff >= _stakingList[msg.sender][idx]._eligibility * 1 days && created < _stakingList[msg.sender][idx]._period * 30 * 1 days) {
            uint count = (diff / _stakingList[msg.sender][idx]._eligibility / day);
            uint _rewards = _stakingList[msg.sender][idx]._initBalance * _stakingList[msg.sender][idx]._apy / 100 * count;
            if (_stakingList[msg.sender][idx]._stakedToken == 0) {
                _rewards /= 1000;
                IERC20(loriaStaking).transfer(msg.sender, _rewards);
            }
            else {
                _rewards *= 1000;
                IERC20(loriaStaking).transfer(msg.sender, _rewards);
            }
            _stakingList[msg.sender][idx]._updated_at = timestamp;
            _stakingList[msg.sender][idx]._claimedBalance += _rewards;
        }

        else if (created >= _stakingList[msg.sender][idx]._period * 30 * 1 days) {
            withdraw(idx);
        }

    }
    
    function allClaim() external {
        StakingItem[] memory item = _stakingList[msg.sender];
        for (uint i = 0; i < item.length; i ++) claim(i);
    }

    function recoverToken(uint amount) external onlyOwner {
        IERC20(dogeStaking).transfer(owner, amount);
        IERC20(loriaStaking).transfer(owner, amount);
        emit RecoverStaking(owner, amount);
    }

    function setDogeAPY(uint _apy) external onlyOwner {
        require(_apy > 0, "APY must be greater than zero.");
        DogeAPY = _apy;
    }
    
    function setDogeElig(uint _day) external onlyOwner {
        require(_day > 0, "Date must be greater than zero.");
        DogeElig = _day;
    }

    function setLoriaAPY(uint _apy) external onlyOwner {
        require(_apy > 0, "APY must be greater than zero.");
        LoriaAPY = _apy;
    }
    
    function setLoriaElig(uint _day) external onlyOwner {
        require(_day > 0, "Date error");
        LoriaElig = _day;
    }

    function setDogePenalty(uint penalty) external onlyOwner{
        DogePenalty = penalty;
    }

    function setLoriaPenalty(uint penalty) external onlyOwner{
        LoriaPenalty = penalty;
    }

    function getStakedList() external view returns(StakingItem[] memory list) {
        return _stakingList[msg.sender];
    }

    function getNow() external view returns(uint) {
        return block.timestamp;
    }

    function receiveReward(uint _idx, uint _amount, uint _type) private {
        require(!_stakingList[msg.sender][_idx]._isRewarded, "You have received!");
        _stakingList[msg.sender][_idx]._isRewarded = true;
        if (_type == 0) IERC20(dogeReward).transfer(msg.sender, _amount);
        else IERC20(loriaReward).transfer(msg.sender, _amount);
    }
}