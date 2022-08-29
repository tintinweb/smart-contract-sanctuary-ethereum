// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Mutex.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";

contract ParaStaking is Ownable, Mutex, IERC721Receiver {
    using Address for address;

    // ----- STRUCTS ----- //
    struct TokenInfo {
        address collection;
        uint256 tokenId;
    }

    struct StakeInfo {
        uint256 id;
        bool state;
        uint256 amount;
        uint256 startTime;
        uint256 lockPeriod;
        address staker;
    }

    struct RewardInfo {
        uint256 amount;
        uint256 updateTime;
    }

    struct UserInfo {
        uint256 amount;
        uint256 tokenCnt;
        uint256 reward;
        uint256[] stakes;
    }

    // ----- STATE VARIABLES ----- //
    StakeInfo[] _stakes;  // array of all stakes
    mapping(uint256 => TokenInfo[]) _tokens;  // indexing token id to array of token infos
    mapping(uint256 => RewardInfo) _rewards;  // indexing token id to reward info
    mapping(address => UserInfo) _users;  // indexing address to user info
    mapping(address => uint256) _multipliers;  // indexing collection address to multiplier value

    IERC20 _token;
    uint256 _totalStake;
    uint256 _totalToken;
    uint256 _baseReward = 5800000 * (10 ** 18);
    uint256 constant _denominator = 100;
    bool public isUnlocked;
    address public rewardPool;

    // ----- CONSTRUCTOR ----- //
    constructor(address token) {
        _token = IERC20(token);
        rewardPool = _msgSender();
    }

    // ----- EVENTS ----- //
    event Stake(uint256 indexed id, address indexed account, uint256 amount, uint8 lockDays, TokenInfo[] tokens);
    event Unstake(uint256 indexed id);
    event Claim(uint256 indexed id, uint256 amount);
    event Update(uint256 indexed id, uint256 amount, uint256 updateTime);
    
    // ----- VIEWS ----- //
    function isStakeholder(address account) external view returns (bool) {
        return _users[account].stakes.length > 0;
    }

    function stakeOf(address account) external view returns (uint256) {
        return _users[account].amount;
    }

    function numOfToken(address account) external view returns (uint256) {
        return _users[account].tokenCnt;
    }

    function rewardOf(address account) external view returns (uint256) {
        return _users[account].reward;
    }

    function totalStake() external view returns (uint256) {
        return _totalStake;
    }

    function totalToken() external view returns (uint256) {
        return _totalToken;
    }

    function multiplierOf(address collection) external view returns (uint256) {
        return _multipliers[collection];
    }

    function baseReward() external view returns (uint256) {
        return _baseReward;
    }

    function getReward(uint256 id) external view returns (uint256) {
        uint dayCnt = (block.timestamp - _rewards[id].updateTime) / 1 days;
        uint256 reward = _rewards[id].amount + dayCnt * _calculateReward(id);
        return reward;
    }
    // ----- MUTATION FUNCTIONS ----- //
    function stake(uint256 amount, uint8 lockDays, address[] memory collections, uint256[] memory tokenIds) external {
        require(amount > 0, "Stake: deposit zero");
        require(lockDays == 0 || lockDays == 30 || lockDays == 60 || lockDays == 90 || lockDays == 120, "Stake: invalid lock option");
        require(collections.length == tokenIds.length, "Stake: array length mismatch");
        require(tokenIds.length < 21, "Stake: token limit exceeds");
        require(_token.transferFrom(_msgSender(), address(this), amount), "Stake: failed to transfer deposit");

        StakeInfo memory newStake;
        newStake.id = _stakes.length;
        newStake.state = true;
        newStake.amount = amount;
        newStake.startTime = block.timestamp;
        newStake.lockPeriod = lockDays * 1 days;
        newStake.staker = _msgSender();
        
        for(uint8 i; i < collections.length; i++) {
            require(IERC721(collections[i]).isApprovedForAll(_msgSender(), address(this)), "Stake: unapproved collection");
            IERC721(collections[i]).safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
            _tokens[newStake.id].push(TokenInfo(collections[i], tokenIds[i]));
        }

        _stakes.push(newStake);
        _rewards[newStake.id].updateTime = block.timestamp;
        _totalStake += amount;
        _totalToken += collections.length;
        _users[_msgSender()].amount += amount;
        _users[_msgSender()].tokenCnt += collections.length;
        _users[_msgSender()].stakes.push(newStake.id);

        emit Stake(newStake.id, _msgSender(), amount, lockDays, _tokens[newStake.id]);
    }

    function unstake(uint256 id) external nonReentrant {
        require(_stakes[id].state, "Unstake: invalid stake");
        require(_msgSender() == _stakes[id].staker, "Unstake: caller is not staker");
        if(!isUnlocked)
            require(block.timestamp > _stakes[id].startTime + _stakes[id].lockPeriod, "Unstake: lock is not expired");
        require(_token.transfer(_msgSender(), _stakes[id].amount), "Unstake: failed to transfer tokens");

        if(block.timestamp > _rewards[id].updateTime + 1 days)
            _updateReward(id);

        if(_rewards[id].amount > 0) {
            require(_token.transferFrom(rewardPool, _msgSender(), _rewards[id].amount), "Claim: failed to transfer tokens");
            emit Claim(id, _rewards[id].amount);
            _users[_msgSender()].reward -= _rewards[id].amount;
            _rewards[id].amount = 0;
        }

        for(uint8 i; i < _tokens[id].length; i++) {
            IERC721(_tokens[id][i].collection).safeTransferFrom(address(this), _msgSender(), _tokens[id][i].tokenId);
            delete _tokens[id][i];
        }

        _users[_msgSender()].amount -= _stakes[id].amount;
        _users[_msgSender()].tokenCnt -= _tokens[id].length;
        _totalStake -= _stakes[id].amount;
        _totalToken -= _tokens[id].length;

        _stakes[id].state = false;
        _stakes[id].amount = 0;

        emit Unstake(id);
    }

    function updateReward(uint256 id) external {
        require(_stakes[id].state, "Update: invalid stake");
        require(block.timestamp > _rewards[id].updateTime + 1 days, "Update: early time for update");

        _updateReward(id);
    }

    function claimReward(uint256 id) external nonReentrant {
        require(_stakes[id].state, "Claim: invalid stake");
        require(block.timestamp > _rewards[id].updateTime + 1 days, "Claim: to early for claim.");
        _updateReward(id);

        require(_rewards[id].amount > 0, "Claim: no reward");
        require(_token.transferFrom(rewardPool, _msgSender(), _rewards[id].amount), "Claim: failed to transfer token");

        emit Claim(id, _rewards[id].amount);
        _users[_msgSender()].reward -= _rewards[id].amount;
        _rewards[id].amount = 0;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ----- INTERNAL FUNCTIONS ----- //
    function _updateReward(uint256 id) internal {
        uint dayCnt = (block.timestamp - _rewards[id].updateTime) / 1 days;
        uint256 reward = dayCnt * _calculateReward(id);
        _rewards[id].amount += reward;
        _rewards[id].updateTime += dayCnt * 1 days;
        _users[_msgSender()].reward += reward;

        

        emit Update(id, reward, _rewards[id].updateTime);
    }

    function _calculateReward(uint256 id) internal view returns (uint256) {
        uint lockMultiplier = (_stakes[id].lockPeriod / 30 days) * 25;
        uint tokenMultiplier;
        for(uint8 i; i < _tokens[id].length; i++) {
            tokenMultiplier += _multipliers[_tokens[id][i].collection];
        }
        uint256 bonus = _stakes[id].amount * (lockMultiplier + tokenMultiplier) / _denominator;
        return _baseReward * (_stakes[id].amount + bonus) / (_totalStake + bonus);
    }

    // ----- RESTRICTED FUNCTIONS ----- //
    function setBaseReward(uint256 value) external onlyOwner {
        _baseReward = value;
    }

    function setMultiplier(address collection, uint256 value) external onlyOwner {
        require(collection.isContract(), "invalid address");
        _multipliers[collection] = value;
    }

    function unlock(bool flag) external onlyOwner {
        isUnlocked = flag;
    }

    function setRewardPool(address account) external onlyOwner {
        rewardPool = account;
    }
    function updateTokenAddress(address tokenAddress) external onlyOwner {
         _token = IERC20(tokenAddress);
    }
    function stakeIds(address stakeAddress) external returns (uint[] memory _stakeIds){
        _users[stakeAddress].stakes = new uint[](_users[stakeAddress].stakes.length);
        for(uint i=0;i<_users[stakeAddress].stakes.length;i++)
        {
            _stakeIds[i] = _users[stakeAddress].stakes[i];
        }
    }

}