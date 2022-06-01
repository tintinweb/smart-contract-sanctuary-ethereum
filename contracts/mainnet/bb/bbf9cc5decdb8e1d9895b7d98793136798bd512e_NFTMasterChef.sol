// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC721Metadata.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC2981.sol";

import "./wnft_interfaces.sol";
import "./ArrayUtils.sol";

// harvest strategy contract, for havesting permission
interface IHarvestStrategy {
    function canHarvest(uint256 _pid, address _forUser, uint256[] memory _wnfTokenIds) external view returns (bool);
}

interface INFTMasterChef {
    event AddPoolInfo(IERC721Metadata nft, IWrappedNFT wnft, uint256 startBlock, 
                    RewardInfo[] rewards, uint256 depositFee, IERC20 dividendToken, bool withUpdate);
    event SetStartBlock(uint256 pid, uint256 startBlock);
    event UpdatePoolReward(uint256 pid, uint256 rewardIndex, uint256 rewardBlock, uint256 rewardForEachBlock, uint256 rewardPerNFTForEachBlock);
    event SetPoolDepositFee(uint256 pid, uint256 depositFee);
    event SetHarvestStrategy(IHarvestStrategy harvestStrategy);
    event SetPoolDividendToken(uint256 pid, IERC20 dividendToken);

    event AddTokenRewardForPool(uint256 pid, uint256 addTokenPerPool, uint256 addTokenPerBlock, bool withTokenTransfer);
    event AddDividendForPool(uint256 pid, uint256 addDividend);

    event UpdateDevAddress(address payable devAddress);
    event EmergencyStop(address user, address to);
    event ClosePool(uint256 pid, address payable to);

    event Deposit(address indexed user, uint256 indexed pid, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256 indexed pid, uint256[] wnfTokenIds);
    event WithdrawWithoutHarvest(address indexed user, uint256 indexed pid, uint256[] wnfTokenIds);
    event Harvest(address indexed user, uint256 indexed pid, uint256[] wnftTokenIds, 
                    uint256 mining, uint256 dividend);

    // Info of each NFT.
    struct NFTInfo {
        bool deposited;     // If the NFT is deposited.
        uint256 rewardDebt; // Reward debt.

        uint256 dividendDebt; // Dividend debt.
    }

    //Info of each Reward 
    struct RewardInfo {
        uint256 rewardBlock;
        uint256 rewardForEachBlock;    //Reward for each block, can only be set one with rewardPerNFTForEachBlock
        uint256 rewardPerNFTForEachBlock;    //Reward for each block for every NFT, can only be set one with rewardForEachBlock
    }

    // Info of each pool.
    struct PoolInfo {
        IWrappedNFT wnft;// Address of wnft contract.

        uint256 startBlock; // Reward start block.

        uint256 currentRewardIndex;// the current reward phase index for poolsRewardInfos
        uint256 currentRewardEndBlock;  // the current reward end block.

        uint256 amount;     // How many NFTs the pool has.
        
        uint256 lastRewardBlock;  // Last block number that token distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12.
        
        IERC20 dividendToken;
        uint256 accDividendPerShare; // Accumulated dividend per share, times 1e12.
        
        uint256 depositFee;// ETH charged when user deposit.
    }
    
    function poolLength() external view returns (uint256);
    function poolRewardLength(uint256 _pid) external view returns (uint256);

    function poolInfos(uint256 _pid) external view returns (IWrappedNFT _wnft, 
                uint256 _startBlock, uint256 _currentRewardIndex, uint256 _currentRewardEndBlock, uint256 _amount, uint256 _lastRewardBlock, 
                uint256 _accTokenPerShare, IERC20 _dividendToken, uint256 _accDividendPerShare, uint256 _depositFee);
    function poolsRewardInfos(uint256 _pid, uint256 _rewardInfoId) external view returns (uint256 _rewardBlock, uint256 _rewardForEachBlock, uint256 _rewardPerNFTForEachBlock);
    function poolNFTInfos(uint256 _pid, uint256 _nftTokenId) external view returns (bool _deposited, uint256 _rewardDebt, uint256 _dividendDebt);

    function getPoolCurrentReward(uint256 _pid) external view returns (RewardInfo memory _rewardInfo, uint256 _currentRewardIndex);
    function getPoolEndBlock(uint256 _pid) external view returns (uint256 _poolEndBlock);
    function isPoolEnd(uint256 _pid) external view returns (bool);

    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) external view returns (uint256 _mining, uint256 _dividend);
    function deposit(uint256 _pid, uint256[] memory _tokenIds) external payable;
    function withdraw(uint256 _pid, uint256[] memory _wnftTokenIds) external;
    function withdrawWithoutHarvest(uint256 _pid, uint256[] memory _wnftTokenIds) external;
    function harvest(uint256 _pid, address _forUser, uint256[] memory _wnftTokenIds) external returns (uint256 _mining, uint256 _dividend);
}

contract NFTMasterChef is INFTMasterChef, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ArrayUtils for uint256[];

    uint256 private constant ACC_TOKEN_PRECISION = 1e12;

    IWrappedNFTFactory public immutable wnftFactory;
    IERC20 public immutable token;// The reward TOKEN!
    
    IHarvestStrategy public harvestStrategy;

    address payable public devAddress;

    PoolInfo[] public poolInfos;// Info of each pool.
    RewardInfo[][] public poolsRewardInfos;
    mapping (uint256 => NFTInfo)[] public poolNFTInfos;// the nftInfo for pool

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfos.length, "NFTMasterChef: Pool does not exist");
        _;
    }

    constructor(
        IWrappedNFTFactory _wnftFactory,
        IERC20 _token,
        address payable _devAddress
    )  {
        require(address(_wnftFactory) != address(0) && address(_token) != address(0) 
                && address(_devAddress) != address(0), "NFTMasterChef: invalid parameters!");
        wnftFactory = _wnftFactory;
        token = _token;
        devAddress = _devAddress;
    }

    function poolLength() external view returns (uint256) {
        return poolInfos.length;
    }

    function poolRewardLength(uint256 _pid) external view validatePoolByPid(_pid) returns (uint256) {
        return poolsRewardInfos[_pid].length;
    }

    // Add a new NFT to the pool. Can only be called by the owner.
    function addPoolInfo(IERC721Metadata _nft, uint256 _startBlock, RewardInfo[] memory _rewards, 
            uint256 _depositFee, IERC20 _dividendToken, bool _withUpdate) external onlyOwner nonReentrant {
        require(address(_nft) != address(0), "NFTMasterChef: wrong _nft or _dividendToken!");
        require(_rewards.length > 0, "NFTMasterChef: _rewards must be set!");
        uint256 rewardForEachBlock = _rewards[0].rewardForEachBlock;
        uint256 rewardPerNFTForEachBlock = _rewards[0].rewardPerNFTForEachBlock;
        //allow pool with dividend and without mining, or must have mining. Mining can only have either rewardForEachBlock or _rewardPerNFTForEachBlock set.
        require((address(_dividendToken) != address(0) && (rewardForEachBlock == 0 && rewardPerNFTForEachBlock == 0)) || 
                ((rewardForEachBlock == 0 && rewardPerNFTForEachBlock > 0) || (rewardForEachBlock > 0 && rewardPerNFTForEachBlock == 0)), 
                "NFTMasterChef: rewardForEachBlock or rewardPerNFTForEachBlock must be greater than zero!");
        IWrappedNFT wnft = wnftFactory.wnfts(_nft);
        require(address(wnft) != address(0) && wnft.nft() == _nft && wnft.factory() == wnftFactory && wnft.delegator() == address(this), "NFTMasterChef: wrong wnft!");
        if (_withUpdate) {
            massUpdatePools();
        }
        PoolInfo storage pool = poolInfos.push();
        pool.wnft = wnft;
        pool.amount = 0;
        pool.startBlock = block.number > _startBlock ? block.number : _startBlock;
        pool.lastRewardBlock = pool.startBlock;
        pool.accTokenPerShare = 0;
        pool.depositFee = _depositFee;

        pool.dividendToken = _dividendToken;
        pool.accDividendPerShare = 0;
        
        RewardInfo[] storage rewards = poolsRewardInfos.push();
        _setPoolRewards(poolInfos.length - 1, _rewards);
        pool.currentRewardEndBlock = pool.startBlock + rewards[0].rewardBlock; 

        poolNFTInfos.push();
        
        emit AddPoolInfo(_nft, wnft, _startBlock, _rewards, _depositFee, _dividendToken, _withUpdate);
    }

    function _setPoolRewards(uint256 _pid, RewardInfo[] memory _rewards) internal {
        RewardInfo[] storage rewards = poolsRewardInfos[_pid];
        bool rewardForEachBlockSet;
        if(_rewards.length > 0){
            rewardForEachBlockSet = _rewards[0].rewardForEachBlock > 0;
        }
        for (uint256 i = 0; i < _rewards.length; i++) {
            RewardInfo memory reward = _rewards[i];
            require(reward.rewardBlock > 0, "NFTMasterChef: rewardBlock error!");
            require(!(reward.rewardForEachBlock > 0 && reward.rewardPerNFTForEachBlock > 0), "NFTMasterChef: reward can only set one!");
            require((rewardForEachBlockSet && reward.rewardForEachBlock > 0) || (!rewardForEachBlockSet && reward.rewardPerNFTForEachBlock > 0)
                    || (reward.rewardForEachBlock == 0 && reward.rewardPerNFTForEachBlock == 0), "NFTMasterChef: setting error!");
            rewards.push(RewardInfo({
                rewardBlock: reward.rewardBlock,
                rewardForEachBlock: reward.rewardForEachBlock,
                rewardPerNFTForEachBlock: reward.rewardPerNFTForEachBlock
            }));
        }
    }

    // update the pool reward of specified index
    function updatePoolReward(uint256 _pid, uint256 _rewardIndex, uint256 _rewardBlock, uint256 _rewardForEachBlock, uint256 _rewardPerNFTForEachBlock) 
                            external validatePoolByPid(_pid) onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        require(!isPoolEnd(_pid), "NFTMasterChef: pool is end!");
        require(_rewardBlock > 0, "NFTMasterChef: rewardBlock error!");
        require(_rewardIndex < poolsRewardInfos[_pid].length, "NFTMasterChef: _rewardIndex not exists!");
        (, uint256 _currentRewardIndex) = getPoolCurrentReward(_pid);
        require(_rewardIndex >= _currentRewardIndex, "NFTMasterChef: _rewardIndex error!");
        RewardInfo storage reward = poolsRewardInfos[_pid][_rewardIndex];
        require(_rewardBlock >= reward.rewardBlock, "NFTMasterChef: _rewardBlock error!");
        require(!(_rewardForEachBlock > 0 && _rewardPerNFTForEachBlock > 0), "NFTMasterChef: reward can only set one!");
        require((reward.rewardForEachBlock > 0 && _rewardForEachBlock > 0) || (reward.rewardPerNFTForEachBlock > 0 && _rewardPerNFTForEachBlock > 0) 
                || (_rewardForEachBlock == 0 && _rewardPerNFTForEachBlock == 0), "NFTMasterChef: invalid parameters!");
        updatePool(_pid);
        if(_rewardIndex == _currentRewardIndex){
            pool.currentRewardEndBlock = pool.currentRewardEndBlock + _rewardBlock - reward.rewardBlock;
        }
        reward.rewardBlock = _rewardBlock;
        reward.rewardForEachBlock = _rewardForEachBlock;
        reward.rewardPerNFTForEachBlock = _rewardPerNFTForEachBlock;
        
        emit UpdatePoolReward(_pid, _rewardIndex, _rewardBlock, _rewardForEachBlock, _rewardPerNFTForEachBlock);
    }

    // Update the given pool's pool info. Can only be called by the owner.
    function setStartBlock(uint256 _pid, uint256 _startBlock) external validatePoolByPid(_pid) onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        require(block.number < pool.startBlock, "NFTMasterChef: can not change start block of started pool!");
        require(block.number < _startBlock, "NFTMasterChef: _startBlock must be less than block.number!");
        pool.startBlock = _startBlock;
        emit SetStartBlock(_pid, _startBlock);
    }

    function isPoolEnd(uint256 _pid) public view returns (bool) {
        uint256 poolEndBlock = getPoolEndBlock(_pid);
        return block.number > poolEndBlock;
    }

    function getPoolEndBlock(uint256 _pid) public view returns (uint256 _poolEndBlock) {
        PoolInfo storage pool = poolInfos[_pid];
        _poolEndBlock = pool.currentRewardEndBlock;
        RewardInfo[] storage rewards = poolsRewardInfos[_pid];
        for(uint256 index = pool.currentRewardIndex + 1; index < rewards.length; index ++){
            _poolEndBlock = _poolEndBlock.add(rewards[index].rewardBlock);
        }
    }

    function getPoolCurrentReward(uint256 _pid) public view returns (RewardInfo memory _rewardInfo, uint256 _currentRewardIndex){
        PoolInfo storage pool = poolInfos[_pid];
        _currentRewardIndex = pool.currentRewardIndex;
        uint256 poolCurrentRewardEndBlock = pool.currentRewardEndBlock;
        uint256 poolRewardNumber = poolsRewardInfos[_pid].length;
        _rewardInfo = poolsRewardInfos[_pid][_currentRewardIndex];
        // Check whether to adjust multipliers and reward per block
        while ((block.number > poolCurrentRewardEndBlock) && (_currentRewardIndex < (poolRewardNumber - 1))) {
            // Update rewards per block
            _currentRewardIndex ++;
            _rewardInfo = poolsRewardInfos[_pid][_currentRewardIndex];
            // Adjust the end block
            poolCurrentRewardEndBlock = poolCurrentRewardEndBlock.add(_rewardInfo.rewardBlock);
        }
    }

    // Update the given pool's pool info. Can only be called by the owner.
    function setPoolDividendToken(uint256 _pid, IERC20 _dividendToken) external validatePoolByPid(_pid) onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        require(!isPoolEnd(_pid), "NFTMasterChef: pool is end!");
        require(address(pool.dividendToken) == address(0) || pool.accDividendPerShare == 0, "NFTMasterChef: dividendToken can not be modified!");
        pool.dividendToken = _dividendToken;
        emit SetPoolDividendToken(_pid, _dividendToken);
    }

    // Update the given pool's operation fee
    function setPoolDepositFee(uint256 _pid, uint256 _depositFee) public validatePoolByPid(_pid) onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        require(!isPoolEnd(_pid), "NFTMasterChef: pool is end!");
        pool.depositFee = _depositFee;
        emit SetPoolDepositFee(_pid, _depositFee);
    }

    //harvestStrategy change be changed and can be zero.
    function setHarvestStrategy(IHarvestStrategy _harvestStrategy) external onlyOwner nonReentrant {
        harvestStrategy = _harvestStrategy;
        emit SetHarvestStrategy(_harvestStrategy);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        if(_to > _from){
            return _to.sub(_from);
        }
        return 0;
    }

    function _getMultiplier(uint256 _lastRewardBlock, uint256 _currentRewardEndBlock) internal view returns (uint256 _multiplier) {
        if(block.number < _lastRewardBlock){
            return 0;
        }else if (block.number > _currentRewardEndBlock){
            _multiplier = getMultiplier(_lastRewardBlock, _currentRewardEndBlock);
        }else{
            _multiplier = getMultiplier(_lastRewardBlock, block.number);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfos[_pid];
        if (block.number <= pool.lastRewardBlock){
            return;
        }
        if (block.number < pool.startBlock){
            return;
        }
        if (pool.lastRewardBlock >= getPoolEndBlock(_pid)){
             return;
        }
        RewardInfo[] storage rewards = poolsRewardInfos[_pid];
        if(rewards.length == 0 || pool.currentRewardIndex > (rewards.length - 1)){
            return;
        }
        RewardInfo storage reward = rewards[pool.currentRewardIndex];
        if(reward.rewardForEachBlock == 0 && reward.rewardPerNFTForEachBlock == 0){// only dividend pool do not need update pool
            return;
        }
        if (pool.lastRewardBlock < pool.startBlock) {
            pool.lastRewardBlock = pool.startBlock;
        }
        if (pool.amount == 0) {
            pool.lastRewardBlock = block.number;
            // update current reward index
            while ((pool.lastRewardBlock > pool.currentRewardEndBlock) && (pool.currentRewardIndex < (poolsRewardInfos[_pid].length - 1))) {
                // Update rewards per block
                pool.currentRewardIndex ++;
                // Adjust the end block
                pool.currentRewardEndBlock = pool.currentRewardEndBlock.add(reward.rewardBlock);
            }
            return;
        }
        uint256 multiplier = _getMultiplier(pool.lastRewardBlock, pool.currentRewardEndBlock);
        uint256 rewardForEachBlock = reward.rewardForEachBlock;
        if(rewardForEachBlock == 0){
            rewardForEachBlock = pool.amount.mul(reward.rewardPerNFTForEachBlock);
        }
        uint256 poolReward = multiplier.mul(rewardForEachBlock);
        uint256 poolRewardNumber = poolsRewardInfos[_pid].length;
        // Check whether to adjust multipliers and reward per block
        while ((block.number > pool.currentRewardEndBlock) && (pool.currentRewardIndex < (poolRewardNumber - 1))) {
            // Update rewards per block
            pool.currentRewardIndex ++;
            
            uint256 previousEndBlock = pool.currentRewardEndBlock;
            
            reward = poolsRewardInfos[_pid][pool.currentRewardIndex];
            // Adjust the end block
            pool.currentRewardEndBlock = pool.currentRewardEndBlock.add(reward.rewardBlock);
            
            // Adjust multiplier to cover the missing periods with other lower inflation schedule
            uint256 newMultiplier = _getMultiplier(previousEndBlock, pool.currentRewardEndBlock);
            rewardForEachBlock = reward.rewardForEachBlock;
            if(rewardForEachBlock == 0){
                rewardForEachBlock = pool.amount.mul(reward.rewardPerNFTForEachBlock);
            }
            // Adjust token rewards
            poolReward = poolReward.add(newMultiplier.mul(rewardForEachBlock));
        }

        if (block.number > pool.currentRewardEndBlock){
            pool.lastRewardBlock = pool.currentRewardEndBlock;
        }else{
            pool.lastRewardBlock = block.number;
        }
        pool.accTokenPerShare = pool.accTokenPerShare.add(poolReward.mul(ACC_TOKEN_PRECISION).div(pool.amount));
    }

    // View function to see mining tokens and dividend on frontend.
    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) public view validatePoolByPid(_pid) returns (uint256 _mining, uint256 _dividend) {
        _requireTokenIds(_wnftTokenIds);

        PoolInfo storage pool =  poolInfos[_pid];

        mapping(uint256 => NFTInfo) storage nfts = poolNFTInfos[_pid];
        RewardInfo[] storage rewards = poolsRewardInfos[_pid];
        RewardInfo storage reward = rewards[pool.currentRewardIndex];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 rewardForEachBlock = reward.rewardForEachBlock;
        if(rewardForEachBlock == 0){
            rewardForEachBlock = pool.amount.mul(reward.rewardPerNFTForEachBlock);
        }
        if(rewardForEachBlock > 0){
            uint256 lastRewardBlock = pool.lastRewardBlock;
            if (lastRewardBlock < pool.startBlock) {
                lastRewardBlock = pool.startBlock;
            }
            if (block.number > lastRewardBlock && block.number >= pool.startBlock && pool.amount > 0){
                uint256 multiplier = _getMultiplier(lastRewardBlock, pool.currentRewardEndBlock);

                uint256 poolReward = multiplier.mul(rewardForEachBlock);
                uint256 poolRewardNumber = poolsRewardInfos[_pid].length;
                uint256 poolCurrentRewardIndex = pool.currentRewardIndex;
                uint256 poolEndBlock = pool.currentRewardEndBlock;
                // Check whether to adjust multipliers and reward per block
                while ((block.number > poolEndBlock) && (poolCurrentRewardIndex < (poolRewardNumber - 1))) {
                    // Update rewards per block
                    poolCurrentRewardIndex ++;

                    uint256 previousEndBlock = poolEndBlock;
                    
                    reward = rewards[poolCurrentRewardIndex];
                    // Adjust the end block
                    poolEndBlock = poolEndBlock.add(reward.rewardBlock);

                    // Adjust multiplier to cover the missing periods with other lower inflation schedule
                    uint256 newMultiplier = getMultiplier(previousEndBlock, poolEndBlock);
                    
                    rewardForEachBlock = reward.rewardForEachBlock;
                    if(rewardForEachBlock == 0){
                        rewardForEachBlock = pool.amount.mul(reward.rewardPerNFTForEachBlock);
                    }
                    // Adjust token rewards
                    poolReward = poolReward.add(newMultiplier.mul(rewardForEachBlock));
                }

                accTokenPerShare = accTokenPerShare.add(poolReward.mul(ACC_TOKEN_PRECISION).div(pool.amount));
            }
        }

        uint256 temp;
        NFTInfo storage nft;
        for(uint256 i = 0; i < _wnftTokenIds.length; i ++){
            uint256 wnftTokenId = _wnftTokenIds[i];
            nft = nfts[wnftTokenId];
            if(nft.deposited == true){
                temp = accTokenPerShare.div(ACC_TOKEN_PRECISION);
                _mining = _mining.add(temp.sub(nft.rewardDebt));

                if(pool.accDividendPerShare > 0 && address(pool.dividendToken) != address(0)){
                    _dividend = _dividend.add(pool.accDividendPerShare.div(ACC_TOKEN_PRECISION).sub(nft.dividendDebt));
                }
            }
        }
    }
   
    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Deposit NFTs to MasterChef for token allocation, do not give user reward.
    function deposit(uint256 _pid, uint256[] memory _tokenIds) external validatePoolByPid(_pid) payable nonReentrant {
        _requireTokenIds(_tokenIds);
        updatePool(_pid);
        PoolInfo storage pool = poolInfos[_pid];
        require(block.number >= pool.startBlock, "NFTMasterChef: pool is not start!");
        require(!isPoolEnd(_pid), "NFTMasterChef: pool is end!");
        if(pool.depositFee > 0){// charge for fee
            require(msg.value == pool.depositFee, "NFTMasterChef: Fee is not enough or too much!");
            devAddress.transfer(pool.depositFee);
        }
        mapping(uint256 => NFTInfo) storage nfts = poolNFTInfos[_pid];
        uint256 tokenId;
        NFTInfo storage nft;
        uint256 depositNumber;
        for(uint256 i = 0; i < _tokenIds.length; i ++){
            tokenId = _tokenIds[i];
            //ownerOf will return error if tokenId does not exist.
            require(pool.wnft.nft().ownerOf(tokenId) == msg.sender, "NFTMasterChef: can not deposit nft not owned!");
            nft = nfts[tokenId];
            //If tokenId have reward not harvest, drop it.
            if(nft.deposited == false){
                depositNumber ++;
                nft.deposited = true;
            }
            nft.rewardDebt = pool.accTokenPerShare.div(ACC_TOKEN_PRECISION);
            nft.dividendDebt = pool.accDividendPerShare.div(ACC_TOKEN_PRECISION);
        }
        pool.wnft.deposit(msg.sender, _tokenIds);
        pool.amount = pool.amount.add(depositNumber);
        emit Deposit(msg.sender, _pid, _tokenIds);
    }

    // Withdraw NFTs from MasterChef.
    function withdraw(uint256 _pid, uint256[] memory _wnftTokenIds) external validatePoolByPid(_pid) nonReentrant {
        _harvest(_pid, msg.sender, _wnftTokenIds);
        _withdrawWithoutHarvest(_pid, _wnftTokenIds);
        emit Withdraw(msg.sender, _pid, _wnftTokenIds);
    }

    // Withdraw NFTs from MasterChef without reward
    function _withdrawWithoutHarvest(uint256 _pid, uint256[] memory _wnftTokenIds) internal validatePoolByPid(_pid) {
        _requireTokenIds(_wnftTokenIds);
        PoolInfo storage pool = poolInfos[_pid];
        mapping(uint256 => NFTInfo) storage nfts = poolNFTInfos[_pid];
        uint256 wnftTokenId;
        NFTInfo storage nft;
        uint256 withdrawNumber;
        for(uint256 i = 0; i < _wnftTokenIds.length; i ++){
            wnftTokenId = _wnftTokenIds[i];
            require(pool.wnft.ownerOf(wnftTokenId) == msg.sender, "NFTMasterChef: can not withdraw nft now owned!");
            nft = nfts[wnftTokenId];
            if(nft.deposited == true){
                withdrawNumber ++;
                nft.deposited = false;
            }
            nft.rewardDebt = 0;
            nft.dividendDebt = 0;
        }
        pool.wnft.withdraw(msg.sender, _wnftTokenIds);
        pool.amount = pool.amount.sub(withdrawNumber);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function withdrawWithoutHarvest(uint256 _pid, uint256[] memory _wnftTokenIds) external validatePoolByPid(_pid) nonReentrant {
        updatePool(_pid);
        _withdrawWithoutHarvest(_pid, _wnftTokenIds);
        emit WithdrawWithoutHarvest(msg.sender, _pid, _wnftTokenIds);
    }

    // Harvest the mining reward and dividend
    function harvest(uint256 _pid, address _forUser, uint256[] memory _wnftTokenIds) external validatePoolByPid(_pid) nonReentrant returns (uint256 _mining, uint256 _dividend) {
       return _harvest(_pid, _forUser, _wnftTokenIds);
    }

    function canHarvest(uint256 _pid, address _forUser, uint256[] memory _wnftTokenIds) public view validatePoolByPid(_pid) returns (bool) {
        if(address(harvestStrategy) != address(0)){
            return harvestStrategy.canHarvest(_pid, _forUser, _wnftTokenIds);
        }
        return true;
    }

    function _harvest(uint256 _pid, address _forUser, uint256[] memory _wnftTokenIds) internal validatePoolByPid(_pid) returns (uint256 _mining, uint256 _dividend) {
        _requireTokenIds(_wnftTokenIds);
        if(_forUser == address(0)){
            _forUser = msg.sender;
        }
        require(canHarvest(_pid, _forUser, _wnftTokenIds), "NFTMasterChef: can not harvest!");
        updatePool(_pid);
        PoolInfo storage pool =  poolInfos[_pid];
        mapping(uint256 => NFTInfo) storage nfts = poolNFTInfos[_pid];
        uint256 wnftTokenId;
        NFTInfo storage nft;
        uint256 temp = 0;
        for(uint256 i = 0; i < _wnftTokenIds.length; i ++){
            wnftTokenId = _wnftTokenIds[i];
            nft = nfts[wnftTokenId];
            require(pool.wnft.ownerOf(wnftTokenId) == _forUser, "NFTMasterChef: can not harvest nft now owned!");
            if(nft.deposited == true){
                temp = pool.accTokenPerShare.div(ACC_TOKEN_PRECISION);
                _mining = _mining.add(temp.sub(nft.rewardDebt));
                nft.rewardDebt = temp;

                if(pool.accDividendPerShare > 0 && address(pool.dividendToken) != address(0)){
                    temp = pool.accDividendPerShare.div(ACC_TOKEN_PRECISION);
                    _dividend = _dividend.add(temp.sub(nft.dividendDebt));
                    nft.dividendDebt = temp;
                }
            }
        }
        if (_mining > 0) {
            _safeTransferTokenFromThis(token, _forUser, _mining);
        }
        if(_dividend > 0){
            _safeTransferTokenFromThis(pool.dividendToken, _forUser, _dividend);
        }
        emit Harvest(_forUser, _pid, _wnftTokenIds, _mining, _dividend);
    }

    function emergencyStop(address payable _to) external onlyOwner nonReentrant {
        if(_to == address(0)){
            _to = payable(msg.sender);
        }
        uint256 addrBalance = token.balanceOf(address(this));
        if(addrBalance > 0){
            token.safeTransfer(_to, addrBalance);
        }
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++ pid) {
            closePool(pid, _to);

            PoolInfo storage pool = poolInfos[pid];
            if(pool.accDividendPerShare > 0 && address(pool.dividendToken) != address(0)){
                uint256 bal = pool.dividendToken.balanceOf(address(this));
                if(bal > 0){
                    pool.dividendToken.safeTransfer(_to, bal);
                }
            }
        }
        emit EmergencyStop(msg.sender, _to);
    }

    function closePool(uint256 _pid, address payable _to) public validatePoolByPid(_pid) onlyOwner {
        PoolInfo storage pool = poolInfos[_pid];
        if(isPoolEnd(_pid)){
            return;
        }
        if(poolsRewardInfos[_pid].length > 0){
            pool.currentRewardIndex = poolsRewardInfos[_pid].length - 1;
        }
        pool.currentRewardEndBlock = block.number;
        if(_to == address(0)){
            _to = payable(msg.sender);
        }
        emit ClosePool(_pid, _to);
    }

    function _safeTransferTokenFromThis(IERC20 _token, address _to, uint256 _amount) internal {
        uint256 bal = _token.balanceOf(address(this));
        if (_amount > bal) {
            _token.safeTransfer(_to, bal);
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }

    // Update dev1 address by the previous dev.
    function updateDevAddress(address payable _devAddress) external nonReentrant {
        require(msg.sender == devAddress, "NFTMasterChef: dev: wut?");
        require(_devAddress != address(0), "NFTMasterChef: address can not be zero!");
        devAddress = _devAddress;
        emit UpdateDevAddress(_devAddress);
    }

    function addDividendForPool(uint256 _pid, uint256 _addDividend) external validatePoolByPid(_pid) onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfos[_pid];
        require(_addDividend > 0, "NFTMasterChef: add token error!");
        require(address(pool.dividendToken) != address(0), "NFTMasterChef: no dividend token set!");
        require(!isPoolEnd(_pid), "NFTMasterChef: pool is end!");

        pool.accDividendPerShare = pool.accDividendPerShare.add(_addDividend.mul(ACC_TOKEN_PRECISION).div(pool.amount));
        pool.dividendToken.safeTransferFrom(msg.sender, address(this), _addDividend);
        emit AddDividendForPool(_pid, _addDividend);
    }

    function _requireTokenIds(uint256[] memory _tokenIds) internal pure {
        require(_tokenIds.length > 0, "NFTMasterChef: tokenIds can not be empty!");
        require(!_tokenIds.hasDuplicate(), "NFTMasterChef: tokenIds can not contain duplicate ones!");
    }
}