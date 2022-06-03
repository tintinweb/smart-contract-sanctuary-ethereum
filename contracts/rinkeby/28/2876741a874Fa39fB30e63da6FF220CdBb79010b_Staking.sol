// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract Staking is Ownable, ReentrancyGuard {
    // ----- STRUCTS ----- //
    struct TokenInfo {
        address collection;
        uint256 tokenId;
    }

    struct StakeInfo {
        uint256 id; // incrementing uint256 starting from 0
        bool state;
        uint256 deposit;
        uint256 startTime;
        uint256 lockPeriod;
        address staker;
    }

    // ----- STATE VARIABLES ----- //
    StakeInfo[] _stakes;
    mapping(address => uint256) _shares;
    mapping(uint256 => TokenInfo[]) _tokens;
    mapping(address => uint256) _rewards;
    mapping(address => uint256) _tokenMultipliers;
    mapping(uint256 => uint256) _lastUpdates;

    IERC20 _token;
    uint256 _totalStake;
    uint256 _monthReward = 625000000 * (10 ** 18);
    uint256 _denominator = 100;
    
    // ----- CONSTRUCTOR ----- //
    constructor(address tokenAddress) {
        _token = IERC20(tokenAddress);
    }

    // ----- EVENTS ----- //
    event Stake(address indexed account, uint256 indexed id, uint256 amount, uint256 lockDays, TokenInfo[] tokens);
    event Unstake(uint256 indexed id);
    event Claim(address indexed account, uint256 amount);
    event Update(uint256 indexed id, uint256 amount, uint256 timestamp);

    // ----- VIEWS ----- //
    function isStakeholder(address account) external view returns (bool) {
        return _shares[account] > 0;
    }

    function stakeOf(address account) external view returns (uint256) {
        return _shares[account];
    }

    function totalStake() external view returns (uint256) {
        return _totalStake;
    }

    function rewardOf(address account) external view returns (uint256) {
        return _rewards[account];
    }

    // ----- MUTATION FUNCTIONS ----- //
    function stake(uint256 amount, uint256 lockExpire, address[] memory collections, uint256[] memory tokenIds) external {
        require(amount > 0, "Stake: amount is zero");
        require(lockExpire == 0 || lockExpire == 30 || lockExpire == 60 || lockExpire == 90 || lockExpire == 120, "Stake: invalid lock time option");
        require(collections.length == tokenIds.length, "Stake: array length mismatch");
        require(tokenIds.length < 21, "Stake: token count exceeds limit");

        uint256 id = _stake(_msgSender(), amount, lockExpire, collections, tokenIds);

        emit Stake(_msgSender(), id, amount, lockExpire, _tokens[id]);
    }

    function unstake(uint256 id) external nonReentrant {
        require(_stakes[id].deposit > 0, "Unstake: no deposit");
        require(_stakes[id].state, "Unstake: already done");
        require(_msgSender() == _stakes[id].staker, "Unstake: caller is not staker");
        require(block.timestamp > _stakes[id].startTime + _stakes[id].lockPeriod, "Unstake: lock is not expired");
        require(_token.transfer(_msgSender(), _stakes[id].deposit), "Unstake: failed to transfer tokens");

        _updateReward(id);
        _stakes[id].state = false;
        _shares[_msgSender()] -= _stakes[id].deposit;
        _totalStake -= _stakes[id].deposit;

        emit Unstake(id);
    }

    function updateReward(uint256 id) external {
        require(_stakes[id].deposit > 0, "Update: no deposit");
        require(_stakes[id].state, "Update: unstaked");

        _updateReward(id);
    }

    function claimReward() external nonReentrant {
        require(_rewards[_msgSender()] > 0, "Claim: no reward");
        require(_token.transfer(_msgSender(), _rewards[_msgSender()]), "Claim: failed to transfer tokens");

        emit Claim(_msgSender(), _rewards[_msgSender()]);
        _rewards[_msgSender()] = 0;
    }

    // ----- INTERNAL FUNCTIONS ----- //
    function _stake(address account, uint256 amount, uint256 lockExpire, address[] memory collections, uint256[] memory tokenIds) internal returns (uint256) {
        require(_token.transferFrom(account, address(this), amount), "Stake: failed to transfer tokens");

        for(uint i; i < collections.length; i++) {
            IERC721(collections[i]).safeTransferFrom(account, address(this), tokenIds[i]);
            _tokens[_stakes.length].push(TokenInfo(collections[i], tokenIds[i]));
        }

        StakeInfo memory newStake;
        newStake.id = _stakes.length;
        newStake.state = true;
        newStake.deposit = amount;
        newStake.startTime = block.timestamp;
        newStake.lockPeriod = lockExpire * 1 days;
        newStake.staker = account;

        _stakes.push(newStake);
        _lastUpdates[newStake.id] = block.timestamp;
        _shares[account] += amount;
        _totalStake += amount;

        return newStake.id;
    }

    function _updateReward(uint256 id) internal {
        uint monthCount = (block.timestamp - _lastUpdates[id]) / 30 days;
        if(monthCount > 0) {
            uint256 newReward = monthCount * _calculateReward(id);
            _rewards[_stakes[id].staker] += newReward;
            _lastUpdates[id] += monthCount * 30 days;

            emit Update(id, newReward, _lastUpdates[id]);
        }
    }

    function _calculateReward(uint256 id) internal view returns (uint256) {
        uint lockMultiplier = (_stakes[id].lockPeriod / 30 days) * 25;
        uint tokenMultiplier;
        for(uint i; i < _tokens[id].length; i++) {
            tokenMultiplier += _tokenMultipliers[_tokens[id][i].collection];
        }

        uint256 bonus = _stakes[id].deposit * (lockMultiplier + tokenMultiplier) / _denominator;
        return _monthReward * (_stakes[id].deposit + bonus) / (_totalStake + bonus);
    }

    // ----- RESTRICTED FUNCTIONS ----- //
    function setMonthReward(uint256 value) external onlyOwner {
        _monthReward = value;
    }

    function setTokenMultiplier(address collection, uint256 value) external onlyOwner {
        _tokenMultipliers[collection] = value;
    }
}