// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "IERC20.sol";
import "Staking.sol";

contract RavenToken is IERC20, Staking {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address private _controller;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    modifier onlyController {
        require(_controller == msg.sender, "Caller is not the controller");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _controller = msg.sender;
        _name = name_;
        _symbol = symbol_;
        balances[msg.sender] = totalSupply();
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 4.333333333e9;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external virtual override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom (address _from, address _to, uint256 _value) external virtual override returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(balances[_from] >= _value, "Insufficient balance");
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Cannot burn from zero address");
        require(balances[account] >= amount, "Cannot burn more than the account owns");

        balances[account] = balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "DevToken: cannot mint to zero address");

        _totalSupply = _totalSupply + (amount);
        balances[account] = balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function stake(uint256 _amount) public {
        require(_amount < balances[msg.sender], "Cannot stake more than you own");
        _stake(_amount);
        _burn(msg.sender, _amount);
    }

    function withdrawStake(uint256 amount, uint256 stake_index)  public {
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);
        _mint(msg.sender, amount_to_mint);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * Interface of the ERC20 standard as defined in the EIP-20 https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external pure returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Staking {

    uint256 internal rewardPerHour = 1000;
    Stakeholder[] internal stakeholders;
    mapping(address => uint256) internal stakes;
    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    constructor() {
        stakeholders.push();
    }

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint256 claimable;
    }

    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary {
        uint256 total_amount;
        Stake[] stakes;
    }

    function _addStakeholder(address staker) internal returns (uint256) {
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(uint256 _amount) internal {
        require(_amount > 0, "Cannot stake nothing");
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        if (index == 0) {
            index = _addStakeholder(msg.sender);
        }
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, 0));
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
        return (((block.timestamp - _current_stake.since) / 1 hours) * _current_stake.amount) / rewardPerHour;
    }

    function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount - amount;
        if (current_stake.amount == 0) {
            delete stakeholders[user_index].address_stakes[index];
        } else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }

        return amount+reward;
    }

    function hasStake(address _staker) public view returns(StakingSummary memory){
        uint256 totalStakeAmount;
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
        }
        summary.total_amount = totalStakeAmount;
        return summary;
    }
}