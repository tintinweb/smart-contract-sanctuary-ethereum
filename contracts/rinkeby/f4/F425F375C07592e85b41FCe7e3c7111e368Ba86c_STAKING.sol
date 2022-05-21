//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";

contract STAKING {
    
    event Stake(address indexed _from, uint _value);

    address public owner;
    address public stakeToken;
    address public rewardToken;

    uint8 public percent;
    uint public freezing;
    uint public interval;

    struct Staker {
        uint amount;
        uint beginTime;
        uint unstakeTime;
    }

    mapping(address => Staker) private staking;
    mapping(address => uint) public rewards;

    constructor(
        uint8 _percent,
        uint _freezing,
        uint _interval,
        address _stakeToken,
        address _rewardToken
    ) {
        owner = msg.sender;
        percent = _percent;
        freezing = _freezing;
        interval = _interval;
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
    }

    modifier isOnwer() {
        require(msg.sender == owner, "You are not an owner");
        _;
    }

    function updateStaking(uint8 _percent, uint _freezing, uint _interval) external isOnwer {
        percent = _percent;
        freezing = _freezing;
        interval = _interval;
    }

    function updateRewards() private {
        uint _value;
        if (staking[msg.sender].amount > 0)
            _value = (block.timestamp - staking[msg.sender].beginTime) / interval;

        staking[msg.sender].beginTime = block.timestamp;

        if (_value > 0)
            rewards[msg.sender] += _value * (staking[msg.sender].amount * percent / 100);
    }

    function stake(uint _amount) public returns (bool) {
        require(_amount > 0, "Cant stake zero value!");
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount);

        updateRewards();
        staking[msg.sender].amount += _amount;
        staking[msg.sender].unstakeTime = block.timestamp + freezing;

        emit Stake(msg.sender, _amount);
        return true;
    }

    function claim() public {
        require(staking[msg.sender].amount > 0, "You not staking tokens!");

        updateRewards();
        uint _rewards = rewards[msg.sender];

        if (_rewards > 0) {
            rewards[msg.sender] = 0;
            IERC20(rewardToken).transfer(msg.sender, _rewards);
        }
    }

    function unstake() public returns (bool) {
        require(staking[msg.sender].unstakeTime <= block.timestamp, "Cant unstake tokens yet!");

        claim();
        uint _amount = staking[msg.sender].amount;
        staking[msg.sender].amount = 0;
        
        IERC20(stakeToken).transfer(msg.sender, _amount);
        return true;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _value) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function mint(address _account, uint _amount) external;
    function burn(address _account, uint _amount) external;
}