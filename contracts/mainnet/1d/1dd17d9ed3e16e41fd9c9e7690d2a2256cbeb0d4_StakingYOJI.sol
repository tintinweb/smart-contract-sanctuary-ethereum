/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract StakingYOJI {

    address owner;
    address tokenContract;
    uint256 apy;
    uint256 min;

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
    }

    Stake[] public stakes;

    mapping(address => uint256) public stakeholders;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Staked(address indexed user, uint256 index, uint256 amount, uint256 timestamp);
    event Withdrawed(address indexed user, uint256 reward, uint256 index, uint256 timestamp);

    constructor(address _tokenContract, uint256 _apy, uint256 _min) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        apy = _apy;
        min = _min;
    }
    
    function _addStake(address _user) private returns (uint256) {
        stakes.push();
        uint256 index = stakes.length - 1;
        stakes[index].user = _user;
        stakeholders[_user] = index;
        return index;
    }

    function stake(uint256 _amount) public returns (bool) {
        require(stakeholders[msg.sender] == 0);
        require(_amount >= min);

        IERC20 token = IERC20(tokenContract);
        token.transferFrom(msg.sender, address(this), _amount);

        return _stake(_amount);
    }

    function _stake(uint256 _amount) private returns (bool) {
        uint256 index = _addStake(msg.sender);

        stakes[index].amount = _amount;
        stakes[index].since = block.timestamp;

        emit Staked(msg.sender, index, _amount, block.timestamp);

        return true;
    }


    function withdrawStake() public returns (bool) {
        uint256 index = stakeholders[msg.sender];

        require(index > 0);
        
        uint256 reward = getStakeReward(index);
        
        stakeholders[msg.sender] = 0;
        
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, reward);

        emit Withdrawed(msg.sender, reward, index, block.timestamp);

        return true;
    }


    function getStakeReward(uint256 _index) public view returns (uint256) {
        uint256 diff = block.timestamp - stakes[_index].since;
        uint256 diff_date = diff / 60 / 60 / 24;

        uint256 factor = diff_date * apy;

        uint256 reward = stakes[_index].amount + stakes[_index].amount / 10000 * factor;
        return reward;
    }


    function withdrawTokens(uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(tokenContract);
        if(_amount == 0) {
            _amount = token.balanceOf(address(this));
        }
        require(token.balanceOf(address(this)) >= _amount);
        token.transfer(owner, _amount);
    }


    function setParams(address _tokenContract, uint256 _apy, uint256 _min) external onlyOwner {
        tokenContract = _tokenContract;
        apy = _apy;
        min = _min;
    }


    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }
}