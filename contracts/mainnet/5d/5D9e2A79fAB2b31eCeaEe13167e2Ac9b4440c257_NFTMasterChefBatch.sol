// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts, https://www.starblockdao.io/

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./NFTMasterChef_interfaces.sol";

contract NFTMasterChefBatch is INFTMasterChefBatch, Ownable, ReentrancyGuard {
    INFTPool public immutable nftPool;
    INFTMasterChef public immutable nftMasterChef;
    ITokenPriceUtils public tokenPriceUtils;//tokenPriceUtils Contract of $STB

    ICollectionUtils public collectionUtils;

    IERC20 public immutable weth;
    
    struct WrappedPoolInfo {
        uint256 pid;
        INFTMasterChef.PoolInfo poolInfo;
        INFTMasterChef.RewardInfo currentReward;
        UserInfo userInfo;
        uint256 currentRewardIndex;
        uint256 currentRewardEndBlock;
        uint256 endBlock;
        IERC721Metadata nft;
        INFTMasterChef.RewardInfo[] rewards;

        uint256 rewardedToken;
        uint256 rewardedDividend;
    }
   
    struct UserInfo {
        uint256 ethBalance;
        uint256 wethBalance;
        uint256 tokenBalance;

        uint256 mining;
        uint256 dividend;
        uint256 nftQuantity;
        uint256 wnftQuantity;
        bool isNFTApproved;
        bool isWNFTApproved;

        uint256[] ownedNFTTokenIds;
        uint256[] ownedWNFTTokenIds;
    }

    struct PoolSta {
        uint256 blockNumber;
        uint256 blockTime;
        uint256 tokenPrice;
        uint256 totalPoolAmount;
        uint256 totalNFTAmount;
        uint256 totalRewardedToken;
        uint256 totalRewardedDividend;
    }

    struct NFTDepositInfo {
        uint256 tokenId;
        address owner;
        bool deposited;// Is it deposited in NFTMasterChef
        uint256 mining;
        uint256 dividend;
        bool withdrawedInWNFT;// Is it withdrawed from WNFT contract
    }

    mapping(uint256 => uint256) poolDividends;

    constructor(ICollectionUtils _collectionUtils, INFTPool _nftPool, ITokenPriceUtils _tokenPriceUtils, IERC20 _weth) {
        require(address(_collectionUtils) != address(0) && address(_nftPool) != address(0), "Batch: error!");
        collectionUtils = _collectionUtils;

        nftPool = _nftPool;
        nftMasterChef = _nftPool.nftMasterChef();
        require(address(nftMasterChef) != address(0), "Batch: error!");
        
        tokenPriceUtils = _tokenPriceUtils;
        weth = _weth;
    }
    
    function setCollectionUtils(ICollectionUtils _collectionUtils) external onlyOwner nonReentrant {
        require(address(_collectionUtils) != address(0), "Batch: _collectionUtils can not be zero!");
        collectionUtils = _collectionUtils;
    }
   
    function setTokenPriceUtils(ITokenPriceUtils _tokenPriceUtils) external onlyOwner nonReentrant {
        require(address(_tokenPriceUtils) != address(0), "Batch: _tokenPriceUtils can not be zero!");
        tokenPriceUtils = _tokenPriceUtils;
    }

    function getTokenPrice() public view returns (uint256) {
        if(address(tokenPriceUtils) != address(0)){
            return tokenPriceUtils.getTokenPrice(address(nftMasterChef.token()));
        }
        return 0;
    }
    
    function addPoolDividends(uint256[] memory _pids, uint256[] memory _dividends) external onlyOwner nonReentrant {
        require(_pids.length > 0 && (_pids.length == _dividends.length), "Batch: error!");
        for(uint256 index = 0; index < _pids.length; index ++){
            poolDividends[_pids[index]] += _dividends[index];
        }
    }

    function getPoolSta(address _user, bool _withPoolInfo) external view returns (PoolSta memory _poolSta, UserInfo memory _userInfo, WrappedPoolInfo[] memory _wrappedPoolInfos) {
        _poolSta.blockNumber = block.number;
        _poolSta.blockTime = block.timestamp;
        _poolSta.tokenPrice = getTokenPrice();
        _poolSta.totalPoolAmount = nftMasterChef.poolLength();
        if(_user != address(0)){
            _userInfo.ethBalance = _user.balance;
            if(address(weth) != address(0)){
                _userInfo.wethBalance = weth.balanceOf(_user);
            }
            _userInfo.tokenBalance = nftMasterChef.token().balanceOf(_user);
        }
        if(_withPoolInfo){
            _wrappedPoolInfos = new WrappedPoolInfo[](_poolSta.totalPoolAmount);
        }
        for(uint256 pid = 0; pid < _poolSta.totalPoolAmount; pid ++){
            WrappedPoolInfo memory _wrappedPoolInfo = getPoolInfo(pid, _user, false);
            if(_withPoolInfo){
                _wrappedPoolInfos[pid] = _wrappedPoolInfo;
            }
            _poolSta.totalNFTAmount += _wrappedPoolInfo.poolInfo.amount;
            _poolSta.totalRewardedToken += _wrappedPoolInfo.rewardedToken;
            _poolSta.totalRewardedDividend += _wrappedPoolInfo.rewardedDividend;

            if(_user != address(0)){
                UserInfo memory userInfo = _wrappedPoolInfo.userInfo;
                _userInfo.mining += userInfo.mining;
                _userInfo.dividend += userInfo.dividend;
                _userInfo.nftQuantity += userInfo.nftQuantity;
                _userInfo.wnftQuantity += userInfo.wnftQuantity;
            }
        }
    }

    function getAllPoolInfos(address _user, bool _canDeposite, bool _deposited) external view returns (WrappedPoolInfo[] memory _wrappedPoolInfos) {
        if(_user == address(0)){
            _canDeposite = false;
            _deposited = false;
        }
        uint256 maxPid = nftMasterChef.poolLength() - 1;
        if(maxPid > 0){
            uint256 number;
            if(!_canDeposite && !_deposited){
                number = maxPid + 1;
            }else{
                for(uint256 pid = 0; pid <= maxPid; pid ++){
                    IWrappedNFT wnft = nftMasterChef.poolInfos(pid).wnft;
                    if((_canDeposite && wnft.nft().balanceOf(_user) > 0) 
                        || (_deposited && wnft.balanceOf(_user) > 0)){
                        number ++;
                    }
                }
            }
            if(number > 0){
                _wrappedPoolInfos = new WrappedPoolInfo[](number);
                uint256 index = 0;
                for(uint256 pid = 0; pid <= maxPid; pid ++){
                    IWrappedNFT wnft = nftMasterChef.poolInfos(pid).wnft;
                    if((!_canDeposite && !_deposited) 
                        || (_canDeposite && wnft.nft().balanceOf(_user) > 0) 
                        || (_deposited && wnft.balanceOf(_user) > 0)){
                        _wrappedPoolInfos[index] = getPoolInfo(pid, _user, false);
                        index ++;
                    }
                }
            }
        }
    }

    function getPoolInfo(uint256 _pid, address _user, bool _withOwnedTokenIds) public view returns (WrappedPoolInfo memory _wrappedPoolInfo) {
        require(_pid < nftMasterChef.poolLength(), "Batch: error!");
        _wrappedPoolInfo.pid = _pid;
        _wrappedPoolInfo.poolInfo = nftMasterChef.poolInfos(_pid);
        _wrappedPoolInfo.endBlock = nftMasterChef.getPoolEndBlock(_pid);
        _wrappedPoolInfo.nft = _wrappedPoolInfo.poolInfo.wnft.nft();
        _wrappedPoolInfo.rewards = getPoolRewards(_pid);
        (_wrappedPoolInfo.rewardedToken, _wrappedPoolInfo.rewardedDividend) = poolRewarded(_pid);

        _wrappedPoolInfo.currentRewardIndex = _wrappedPoolInfo.poolInfo.currentRewardIndex;
        _wrappedPoolInfo.currentRewardEndBlock = _wrappedPoolInfo.poolInfo.currentRewardEndBlock;
        uint256 poolRewardNumber = _wrappedPoolInfo.rewards.length;
        _wrappedPoolInfo.currentReward = _wrappedPoolInfo.rewards[_wrappedPoolInfo.currentRewardIndex];
        // Check whether to adjust multipliers and reward per block
        while ((block.number > _wrappedPoolInfo.currentRewardEndBlock) && (_wrappedPoolInfo.currentRewardIndex < (poolRewardNumber - 1))) {
            // Update rewards per block
            _wrappedPoolInfo.currentRewardIndex ++;
            _wrappedPoolInfo.currentReward = _wrappedPoolInfo.rewards[_wrappedPoolInfo.currentRewardIndex];
            // Adjust the end block
            _wrappedPoolInfo.currentRewardEndBlock += _wrappedPoolInfo.currentReward.rewardBlock;
        }

        if (_user != address(0)) {
            _wrappedPoolInfo.userInfo = getUserInfo(_pid, _user, _withOwnedTokenIds);
        }
    }

    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) public view returns (uint256 _mining, uint256 _dividend){
        (_mining, _dividend) = nftPool.pending(_pid, _wnftTokenIds);
    }

    function getUserInfo(uint256 _pid, address _user, bool _withOwnedTokenIds) public view returns (UserInfo memory _userInfo) {
        require(_pid < nftMasterChef.poolLength(), "Batch: error!");
        if (_user != address(0)) {
            IWrappedNFT wnft = nftMasterChef.poolInfos(_pid).wnft;
            uint256[] memory ownedWNFTTokenIds = collectionUtils.ownedNFTTokenIds(wnft, _user);
            if (ownedWNFTTokenIds.length > 0) {
                (_userInfo.mining, _userInfo.dividend) = pending(_pid, ownedWNFTTokenIds);
            }
            _userInfo.nftQuantity = wnft.nft().balanceOf(_user);
            _userInfo.wnftQuantity = wnft.balanceOf(_user);
            _userInfo.isNFTApproved = wnft.nft().isApprovedForAll(_user, address(wnft));
            _userInfo.isWNFTApproved = wnft.isApprovedForAll(_user, address(nftMasterChef));

            if(_withOwnedTokenIds){
                _userInfo.ownedNFTTokenIds = collectionUtils.ownedNFTTokenIds(wnft.nft(), _user);
                _userInfo.ownedWNFTTokenIds = ownedWNFTTokenIds;
            }
       }
    }
    
    function getPoolInfosByPids(uint256[] memory _pids, address _user, bool _withOwnedTokenIds) external view returns (WrappedPoolInfo[] memory _wrappedPoolInfos) {
        require(_pids.length > 0, "Batch: error!");
        _wrappedPoolInfos = new WrappedPoolInfo[](_pids.length);
        for(uint256 index = 0; index < _pids.length; index ++){
            _wrappedPoolInfos[index] = getPoolInfo(_pids[index], _user, _withOwnedTokenIds);
        }
    }

    function getPoolInfosUserCanDeposit(address _user, bool _withOwnedTokenIds) external view returns (WrappedPoolInfo[] memory _wrappedPoolInfos) {
    	require(nftMasterChef.poolLength() > 0 && _user != address(0), "Batch: error!");
    	uint256 maxPid = nftMasterChef.poolLength() - 1;

        uint256 number;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
        	IWrappedNFT wnft = nftMasterChef.poolInfos(pid).wnft;
        	if(wnft.nft().balanceOf(_user) > 0){
        		number ++;
        	}
        }
        if(number > 0){
            _wrappedPoolInfos = new WrappedPoolInfo[](number);
            uint256 index = 0;
            for(uint256 pid = 0; pid <= maxPid; pid ++){
                IWrappedNFT wnft = nftMasterChef.poolInfos(pid).wnft;
                if(wnft.nft().balanceOf(_user) > 0){
                    _wrappedPoolInfos[index] = getPoolInfo(pid, _user, _withOwnedTokenIds);
                    index ++;
                }
            }
        }
    }

    function getPoolInfosUserDeposited(address _user, bool _withOwnedTokenIds) external view returns (WrappedPoolInfo[] memory _wrappedPoolInfos) {
    	require(nftMasterChef.poolLength() > 0 && _user != address(0), "Batch: error!");
    	uint256 maxPid = nftMasterChef.poolLength() - 1;

        uint256 number;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
        	IWrappedNFT wnft = nftMasterChef.poolInfos(pid).wnft;
        	if(wnft.balanceOf(_user) > 0){
        		number ++;
        	}
        }

        if(number > 0){
            _wrappedPoolInfos = new WrappedPoolInfo[](number);
            uint256 index = 0;
            for(uint256 pid = 0; pid <= maxPid; pid ++){
                IWrappedNFT wnft = nftMasterChef.poolInfos(pid).wnft;
                if(wnft.balanceOf(_user) > 0){
                    _wrappedPoolInfos[index] = getPoolInfo(pid, _user, _withOwnedTokenIds);
                    index ++;
                }
            }
        }
    }

    function getPoolInfosByNFTorWNFTs(IERC721Metadata[] memory _nftOrWNFTs, address _user, bool _withOwnedTokenIds) 
            external view returns (WrappedPoolInfo[] memory _wrappedPoolInfos) {
        require(_nftOrWNFTs.length > 0, "Batch: error!");
        _wrappedPoolInfos = new WrappedPoolInfo[](_nftOrWNFTs.length);
        for(uint256 index = 0; index < _nftOrWNFTs.length; index ++){
            IERC721Metadata nft = _nftOrWNFTs[index];
            (bool poolExists, uint256 pid) = nftPoolExists(nft);
            if(poolExists){
                _wrappedPoolInfos[index] = getPoolInfo(pid, _user, _withOwnedTokenIds);
            }
        }
    }

    function getPoolsDepositedNFTs(uint256[] memory _pids) external view returns (NFTDepositInfo[][] memory _nftInfos) {
        require(_pids.length > 0, "Batch: error!");
        _nftInfos = new NFTDepositInfo[][](_pids.length);
        for(uint256 index = 0; index < _pids.length; index ++){
            _nftInfos[index] = getPoolDepositedNFTs(_pids[index]);
        }
    }

    function getPoolDepositedNFTs(uint256 _pid) public view returns (NFTDepositInfo[] memory _nftInfos) {
        require(_pid < nftMasterChef.poolLength(), "Batch: error!");
        INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(_pid);
        if(poolInfo.amount > 0){
            _nftInfos = new NFTDepositInfo[](poolInfo.amount);

            IERC721 nft = poolInfo.wnft.nft();
            (uint256 minTokenId, uint256 maxTokenId) = collectionUtils.tokenIdRangeMay(nft);
            uint256 index = 0;
            for (uint256 tokenId = minTokenId; tokenId <= maxTokenId; tokenId ++) {
                if (collectionUtils.tokenIdExistsMay(nft, tokenId)) {
                    INFTMasterChef.NFTInfo memory nftInfo = nftMasterChef.poolNFTInfos(_pid, tokenId);
                    if(nftInfo.deposited == true){
                        _nftInfos[index].tokenId = tokenId;
                        _nftInfos[index].owner = nft.ownerOf(tokenId);
                        _nftInfos[index].deposited = true;
                        uint256[] memory wnftTokenIds = new uint256[](1);
                        wnftTokenIds[0] = tokenId;
                        (_nftInfos[index].mining, _nftInfos[index].dividend) = pending(_pid, wnftTokenIds);
                        _nftInfos[index].withdrawedInWNFT = (address(_nftInfos[index].owner) != address(poolInfo.wnft));
                        index ++;
                    }
                }
            }
        }
    }
   
    function getPoolsRewards(uint256[] memory _pids) external view returns (INFTMasterChef.RewardInfo[][] memory _rewards) {
        require(_pids.length > 0, "Batch: error!");
        _rewards = new INFTMasterChef.RewardInfo[][](_pids.length);
        for(uint256 index = 0; index < _pids.length; index ++){
            _rewards[index] = getPoolRewards(_pids[index]);
        }
    }
   
    function getPoolRewards(uint256 _pid) public view returns (INFTMasterChef.RewardInfo[] memory _rewards) {
        uint256 rewardLength = nftMasterChef.poolRewardLength(_pid);
        _rewards = new INFTMasterChef.RewardInfo[](rewardLength);
        for(uint256 rewardIndex = 0; rewardIndex < rewardLength; rewardIndex ++){
        	INFTMasterChef.RewardInfo memory reward = nftMasterChef.poolsRewardInfos(_pid, rewardIndex);
            _rewards[rewardIndex] = reward;
        }
    }

    //_nftOrWNFT can be NFT or WNFT
    function getPoolInfoByNFT(IERC721Metadata _nftOrWNFT, address _user, bool _withOwnedTokenIds) external view returns (WrappedPoolInfo memory _wrappedPoolInfo) {
        require(address(_nftOrWNFT) != address(0), "Batch: error!");
        (bool poolExists, uint256 pid) = nftPoolExists(_nftOrWNFT);
        if(poolExists){
            _wrappedPoolInfo = getPoolInfo(pid, _user, _withOwnedTokenIds);
        }
    }

    //_nftOrWNFT can be NFT or WNFT
    function nftPoolId(IERC721Metadata _nftOrWNFT) public view returns (uint256 _pid) {
        require(address(_nftOrWNFT) != address(0), "Batch: error!");
        for(_pid = 0; _pid < nftMasterChef.poolLength(); _pid ++){
            INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(_pid);
            if(poolInfo.wnft == _nftOrWNFT || poolInfo.wnft.nft() == _nftOrWNFT){
                return _pid;
            }
        }
        return nftMasterChef.poolLength();
    }

    //_nftOrWNFT can be NFT or WNFT
    function nftPoolExists(IERC721Metadata _nftOrWNFT) public view returns (bool _poolExists, uint256 _pid) {
        require(address(_nftOrWNFT) != address(0), "Batch: error!");
        _pid = nftPoolId(_nftOrWNFT);
        _poolExists = _pid < nftMasterChef.poolLength();
    }

    //the total unharvest reward for one pool
    function poolPending(uint256 _pid) external view returns (uint256 _mining, uint256 _dividend, uint256[] memory _wnftTokenIds) {
        require(_pid < nftMasterChef.poolLength(), "Batch: error!");
        INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(_pid);
        if(poolInfo.amount > 0){
            _wnftTokenIds = collectionUtils.ownedNFTTokenIds(poolInfo.wnft.nft(), address(poolInfo.wnft));
            if(_wnftTokenIds.length > 0){
                (_mining, _dividend) = pending(_pid, _wnftTokenIds);
            }
        }
    }

    //the rewarded STB and dividend for one pool, calculate by the rewards
    function poolRewarded(uint256 _pid) public view returns (uint256 _mining, uint256 _dividend) {
        require(_pid < nftMasterChef.poolLength(), "Batch: error!");
        INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(_pid);
        INFTMasterChef.RewardInfo[] memory rewards = getPoolRewards(_pid);
        if(poolInfo.startBlock <= block.number && rewards.length > 0){
            uint256 startBlock = poolInfo.startBlock;
            for(uint256 index = 0; index < rewards.length; index ++){
                INFTMasterChef.RewardInfo memory reward = rewards[index];
                uint256 nextStartBlock = startBlock + reward.rewardBlock;
                if(nextStartBlock > block.number){
                    if(poolInfo.currentRewardEndBlock <= block.number){
                        _mining += (poolInfo.currentRewardEndBlock - startBlock) * reward.rewardForEachBlock;
                    }else{
                        _mining += (block.number - startBlock) * reward.rewardForEachBlock;
                    }
                    break;
                }else{
                    if(poolInfo.currentRewardEndBlock <= nextStartBlock){
                        _mining += (poolInfo.currentRewardEndBlock - startBlock) * reward.rewardForEachBlock;
                        if(poolInfo.currentRewardIndex == rewards.length - 1){
                            break;
                        }
                    }else{
                        _mining += reward.rewardBlock * reward.rewardForEachBlock;
                    }
                }
                startBlock = nextStartBlock;
            }
        }

        _dividend = poolDividends[_pid];
    }

    function pendingAll(address _forUser) external view returns (UserInfo memory _userInfo, uint256 _blockNumber, uint256 _blockTime) {
        require(_forUser != address(0), "Batch: error!");
        _blockNumber = block.number;
        _blockTime = block.timestamp;
        _userInfo.ethBalance = _forUser.balance;
        if(address(weth) != address(0)){
            _userInfo.wethBalance = weth.balanceOf(_forUser);
        }
        _userInfo.tokenBalance = nftMasterChef.token().balanceOf(_forUser);
        uint256 maxPid = nftMasterChef.poolLength() - 1;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
            INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
            uint256[] memory wnftTokenIds = collectionUtils.ownedNFTTokenIds(poolInfo.wnft, _forUser);
            if (wnftTokenIds.length > 0) {
                UserInfo memory userInfo = getUserInfo(pid, _forUser, false);
                _userInfo.mining += userInfo.mining;
                _userInfo.dividend += userInfo.dividend;
                _userInfo.nftQuantity += userInfo.nftQuantity;
                _userInfo.wnftQuantity += userInfo.wnftQuantity;
            }
        }
    }
    
    function harvestAll(address _forUser) external returns (uint256 _mining, uint256 _dividend) {
        if(_forUser == address(0)){
        	_forUser = msg.sender;
        }
        uint256 maxPid = nftMasterChef.poolLength() - 1;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
            INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
            uint256[] memory wnftTokenIds = collectionUtils.ownedNFTTokenIds(poolInfo.wnft, _forUser);
            if (wnftTokenIds.length > 0) {
                (uint256 mining, uint256 dividend) = nftMasterChef.harvest(pid, _forUser, wnftTokenIds);
                _mining += mining;
                _dividend += dividend;
            }
        }
    }

    function pendingByNFTorWNFT(IERC721Metadata _nftOrWNFT, uint256[] memory _poolWNFTTokenIds) external view 
            returns (bool _poolExists, uint256 _pid, uint256 _mining, uint256 _dividend) {
        require(address(_nftOrWNFT) != address(0) && _poolWNFTTokenIds.length > 0, "Batch: error!");
        (_poolExists, _pid) = nftPoolExists(_nftOrWNFT);
        if(_poolExists){
            if (_poolWNFTTokenIds.length > 0) {
                (_mining, _dividend) = pending(_pid, _poolWNFTTokenIds);
            }
        }
    }

    function harvestAllByWNFTTokenIds(address _forUser, uint256[] memory _pids, uint256[][] memory _poolWNFTTokenIds) external returns (uint256 _mining, uint256 _dividend) {
        require(_pids.length > 0 && _pids.length == _poolWNFTTokenIds.length, "Batch: error!");
        if(_forUser == address(0)){
        	_forUser = msg.sender;
        }
        for(uint256 index = 0; index < _pids.length; index ++){
            uint256 pid = _pids[index];
            uint256[] memory wnftTokenIds = _poolWNFTTokenIds[index];
            if (wnftTokenIds.length > 0) {
                (uint256 mining, uint256 dividend) = nftMasterChef.harvest(pid, _forUser, wnftTokenIds);
                _mining += mining;
                _dividend += dividend;
            }
        }
    }
    
    function ownedNFTsTokenIdsByPids(uint256[] memory _pids, address _user) external view returns (uint256[][] memory _ownedTokenIds) {
        require(_pids.length > 0, "Batch: error!");
        _ownedTokenIds = new uint256[][](_pids.length);
        uint256 poolLength = nftMasterChef.poolLength();
        for(uint256 index = 0; index < _pids.length; index ++){
            uint256 pid = _pids[index];
            require(pid < poolLength, "Batch: pid >= poolLength!");
            INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
            _ownedTokenIds[index] = ownedNFTTokenIds(poolInfo.wnft.nft(), _user);
        }
    }

    function ownedWNFTsTokenIdsByPids(uint256[] memory _pids, address _user) external view returns (uint256[][] memory _ownedTokenIds) {
        require(_pids.length > 0, "Batch: error!");
        _ownedTokenIds = new uint256[][](_pids.length);
        uint256 poolLength = nftMasterChef.poolLength();
        for(uint256 index = 0; index < _pids.length; index ++){
            uint256 pid = _pids[index];
            require(pid < poolLength, "Batch: pid >= poolLength!");
            INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
            _ownedTokenIds[index] = ownedNFTTokenIds(poolInfo.wnft, _user);
        }
    }

    function ownedNFTTokenIds(IERC721 _nft, address _user) public view returns (uint256[] memory _ownedTokenIds) {
        return collectionUtils.ownedNFTTokenIds(_nft, _user);
    }

    function nftShouldSetMaxTokenId(IERC721 _nft) public view returns (bool) {
        return !collectionUtils.canEnumerate(_nft);
    }

    //return the pids that should set maxTokenId
    function poolsShouldSetMaxTokenId() external view returns (uint256[] memory _pids, IERC721[] memory _nfts) {
    	uint256 maxPid = nftMasterChef.poolLength() - 1;
    	uint256 number;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
            INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
            if(nftShouldSetMaxTokenId(poolInfo.wnft.nft())){
				number ++;
			}
        }
        if(number > 0){
        	_pids = new uint256[](number);
        	_nfts = new IERC721[](number);
			uint256 index;
			for(uint256 pid = 0; pid <= maxPid; pid ++){
				INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
				if(nftShouldSetMaxTokenId(poolInfo.wnft.nft())){
					_pids[index] = pid;
					_nfts[index] = poolInfo.wnft.nft();
					index ++;
				}
			}
        }
    }
}