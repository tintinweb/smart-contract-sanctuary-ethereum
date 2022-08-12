/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IUSDT {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract StakingUSDT {

    address owner;
    address usdtContract;
    uint[] public plans;
    uint[] public mins;
    uint[] public locks;
    uint[] public periods;
    uint[] public limits;

    struct Stake {
        address user;
        uint256 amount;
        uint8 plan;
        uint256 since;
    }

    Stake[] public stakes;

    mapping(address => uint256) public stakeholders;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public trial;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notBlacklisted {
        require(blacklist[msg.sender] == false);
        _;
    }

    event Staked(address indexed user, uint256 index, uint256 amount, uint8 plan, uint256 timestamp);
    event Withdrawed(address indexed user, uint256 reward, uint256 index, uint256 timestamp);

    constructor(address _usdtContract, uint256 _plan1, uint256 _plan2, uint256 _plan3, uint256 _min1, uint256 _min2, uint256 _min3, uint256 _lock1, uint256 _lock2, uint256 _lock3) {
        owner = msg.sender;
        usdtContract = _usdtContract;
        plans.push(0);
        plans.push(_plan1);
        plans.push(_plan2);
        plans.push(_plan3);
        mins.push(0);
        mins.push(_min1);
        mins.push(_min2);
        mins.push(_min3);
        locks.push(0);
        locks.push(_lock1);
        locks.push(_lock2);
        locks.push(_lock3);
        periods.push(0);
        periods.push(5);
        periods.push(7);
        periods.push(14);
        limits.push(0);
        limits.push(3);
        limits.push(48);
        limits.push(24);
        stakes.push();
    }
    
    function _addStake(address _user) private returns (uint256) {
        stakes.push();
        uint256 index = stakes.length - 1;
        stakes[index].user = _user;
        stakeholders[_user] = index;
        return index;
    }

    function stake(uint256 _amount, uint8 _plan) public returns (bool) {
        if(_plan == 1) {
            require(trial[msg.sender] == false);
        }
        require(stakeholders[msg.sender] == 0);
        require(plans[_plan] != 0);
        require(_amount >= mins[_plan]);

        IUSDT usdt = IUSDT(usdtContract);
        usdt.transferFrom(msg.sender, address(this), _amount);

        return _stake(_amount, _plan);
    }

    function _stake(uint256 _amount, uint8 _plan) private returns (bool) {
        uint256 index = _addStake(msg.sender);

        stakes[index].amount = _amount;
        stakes[index].plan = _plan;
        stakes[index].since = block.timestamp;

        emit Staked(msg.sender, index, _amount, _plan, block.timestamp);

        return true;
    }


    function withdrawStake() public notBlacklisted returns (bool) {
        uint256 index = stakeholders[msg.sender];

        require(index > 0);
        
        uint256 reward = getStakeReward(index);
        
        stakeholders[msg.sender] = 0;

        if(stakes[index].plan == 1) {
            trial[msg.sender] = true;
        }
        
        IUSDT usdt = IUSDT(usdtContract);
        usdt.transfer(msg.sender, reward);

        emit Withdrawed(msg.sender, reward, index, block.timestamp);

        return true;
    }


    function getStakeReward(uint256 _index) public view returns (uint256) {
        uint256 diff = block.timestamp - stakes[_index].since;
        uint256 diff_date = diff / 60 / periods[stakes[_index].plan];

        require(diff_date >= locks[stakes[_index].plan]);

        if(diff_date > limits[stakes[_index].plan]) {
            diff_date = limits[stakes[_index].plan];
        }

        uint256 factor = diff_date * plans[stakes[_index].plan];

        uint256 reward = stakes[_index].amount + stakes[_index].amount / 10000 * factor;
        return reward;
    }


    function withdrawUsdt(uint256 amount) external onlyOwner {
        IUSDT usdt = IUSDT(usdtContract);
        if(amount == 0) {
            amount = usdt.balanceOf(address(this));
        }
        require(usdt.balanceOf(address(this)) >= amount);
        usdt.transfer(msg.sender, amount);
    }


    function addToBlacklist(address user) external onlyOwner {
        blacklist[user] = true;
    }

    function removeFromBlacklist(address user) external onlyOwner {
        blacklist[user] = false;
    }


    function setFirstParams(address _usdtContract, uint256 _plan1, uint256 _plan2, uint256 _plan3, uint256 _min1, uint256 _min2, uint256 _min3) external onlyOwner {
        usdtContract = _usdtContract;
        plans[1] = _plan1;
        plans[2] = _plan2;
        plans[3] = _plan3;
        mins[1] = _min1;
        mins[2] = _min2;
        mins[3] = _min3;
    }


    function setSecondParams(uint256 _lock1, uint256 _lock2, uint256 _lock3, uint256 _period1, uint256 _period2, uint256 _period3, uint256 _limit1, uint256 _limit2, uint256 _limit3) external onlyOwner {
        locks[1] = _lock1;
        locks[2] = _lock2;
        locks[3] = _lock3;
        periods[1] = _period1;
        periods[2] = _period2;
        periods[3] = _period3;
        limits[1] = _limit1;
        limits[2] = _limit2;
        limits[3] = _limit3;
    }


    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }
}