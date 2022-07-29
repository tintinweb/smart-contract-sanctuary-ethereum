// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts, https://www.starblockdao.io/

pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./wnft_interfaces.sol";

interface INFTMasterChef {
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
        uint256 accDividendPerShare;

        uint256 depositFee;// ETH charged when user deposit.
    }
   
    function token() external view returns (IERC20);

    function poolLength() external view returns (uint256);
    function poolRewardLength(uint256 _pid) external view returns (uint256);

    function poolInfos(uint256 _pid) external view returns (PoolInfo memory _poolInfo);
    function poolsRewardInfos(uint256 _pid, uint256 _rewardInfoId) external view returns (RewardInfo memory _rewardInfo);
    function poolNFTInfos(uint256 _pid, uint256 _nftTokenId) external view returns (NFTInfo memory _nftInfo);

    function getPoolCurrentReward(uint256 _pid) external view returns (RewardInfo memory _rewardInfo, uint256 _currentRewardIndex);
    function getPoolEndBlock(uint256 _pid) external view returns (uint256 _poolEndBlock);
    function isPoolEnd(uint256 _pid) external view returns (bool);

    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) external view returns (uint256 _mining, uint256 _dividend);
    function deposit(uint256 _pid, uint256[] memory _tokenIds) external payable;
    function withdraw(uint256 _pid, uint256[] memory _wnftTokenIds) external;
    function withdrawWithoutHarvest(uint256 _pid, uint256[] memory _wnftTokenIds) external;
    function harvest(uint256 _pid, address _forUser, uint256[] memory _wnftTokenIds) external returns (uint256 _mining, uint256 _dividend);

    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;
}

interface INFTPool {
    event UpdatePool(uint256 _pid, uint256 _oldRewardIndex, uint256 _newRewardIndex);

    function nftMasterChef() external view returns (INFTMasterChef);
    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) external view returns (uint256 _mining, uint256 _dividend);
}

contract NFTPool is INFTPool {
    uint256 private constant ACC_TOKEN_PRECISION = 1e12;
    INFTMasterChef public immutable nftMasterChef;

    constructor(INFTMasterChef _nftMasterChef) {
        require(address(_nftMasterChef) != address(0), "NFTPool: invalid parameters!");
        nftMasterChef = _nftMasterChef;
    }

    // Return reward multiplier over the given _from to _to block.
    function _getRealMultiplier(uint256 _from, uint256 _to) internal pure returns (uint256) {
        if(_to > _from){
            return _to - _from;
        }
        return 0;
    }

    function _getMultiplier(uint256 _lastRewardBlock, uint256 _currentRewardEndBlock) internal view returns (uint256 _multiplier) {
        if(block.number < _lastRewardBlock){
            return 0;
        }else if (block.number > _currentRewardEndBlock){
            _multiplier = _getRealMultiplier(_lastRewardBlock, _currentRewardEndBlock);
        }else{
            _multiplier = _getRealMultiplier(_lastRewardBlock, block.number);
        }
    }

    function _poolRewardInfo(uint256 _pid, uint256 _rewardIndex) internal view returns (INFTMasterChef.RewardInfo memory) {
        return nftMasterChef.poolsRewardInfos(_pid, _rewardIndex);
    }

    // View function to see mining tokens and dividend on frontend.
    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) external view returns (uint256 _mining, uint256 _dividend) {
        require(_pid < nftMasterChef.poolLength(), "NFTPool: Pool does not exist");
        _requireTokenIds(_wnftTokenIds);

        INFTMasterChef.PoolInfo memory pool =  nftMasterChef.poolInfos(_pid);

        INFTMasterChef.RewardInfo memory reward = _poolRewardInfo(_pid, pool.currentRewardIndex);

        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 rewardForEachBlock = reward.rewardForEachBlock;
        if(rewardForEachBlock == 0){
            rewardForEachBlock = pool.amount * reward.rewardPerNFTForEachBlock;
        }
        if(rewardForEachBlock > 0){
            uint256 lastRewardBlock = pool.lastRewardBlock;
            if (lastRewardBlock < pool.startBlock) {
                lastRewardBlock = pool.startBlock;
            }
            if (block.number > lastRewardBlock && block.number >= pool.startBlock && pool.amount > 0){
                uint256 multiplier = _getMultiplier(lastRewardBlock, pool.currentRewardEndBlock);

                uint256 poolReward = multiplier * rewardForEachBlock;
                uint256 poolRewardNumber = nftMasterChef.poolRewardLength(_pid);
                uint256 poolCurrentRewardIndex = pool.currentRewardIndex;
                uint256 poolEndBlock = pool.currentRewardEndBlock;
                // Check whether to adjust multipliers and reward per block
                while ((block.number > poolEndBlock) && (poolCurrentRewardIndex < (poolRewardNumber - 1))) {
                    // Update rewards per block
                    poolCurrentRewardIndex ++;

                    uint256 previousEndBlock = poolEndBlock;
                    
                    reward = _poolRewardInfo(_pid, poolCurrentRewardIndex);

                    // Adjust the end block
                    poolEndBlock += reward.rewardBlock;

                    // Adjust multiplier to cover the missing periods with other lower inflation schedule
                    uint256 newMultiplier = _getMultiplier(previousEndBlock, poolEndBlock);

                    rewardForEachBlock = reward.rewardForEachBlock;
                    if(rewardForEachBlock == 0){
                        rewardForEachBlock = pool.amount * reward.rewardPerNFTForEachBlock;
                    }
                    // Adjust token rewards
                    poolReward += newMultiplier * rewardForEachBlock;
                }

                accTokenPerShare += poolReward * ACC_TOKEN_PRECISION / pool.amount;
            }
        }

        INFTMasterChef.NFTInfo memory nft;
        for(uint256 i = 0; i < _wnftTokenIds.length; i ++){
            uint256 wnftTokenId = _wnftTokenIds[i];
            nft = nftMasterChef.poolNFTInfos(_pid, wnftTokenId);
            if(nft.deposited == true){
                _mining += accTokenPerShare / ACC_TOKEN_PRECISION - nft.rewardDebt;

                if(pool.accDividendPerShare > 0 && address(pool.dividendToken) != address(0)){
                    _dividend += pool.accDividendPerShare / ACC_TOKEN_PRECISION - nft.dividendDebt;
                }
            }
        }
    }

    function _requireTokenIds(uint256[] memory _tokenIds) internal pure {
        require(_tokenIds.length > 0, "NFTPool: tokenIds can not be empty!");
        require(!hasDuplicate(_tokenIds), "NFTPool: tokenIds can not contain duplicate ones!");
    }

    function hasDuplicate(uint256[] memory array) public pure returns(bool) {
        uint256 ivalue;
        uint256 jvalue;
        for(uint256 i = 0; i < array.length - 1; i ++){
            ivalue = array[i];
            for(uint256 j = i + 1; j < array.length; j ++){
                jvalue = array[j];
                if(ivalue == jvalue){
                    return true;
                }
            }
        }
        return false;
    }

    function shouldUpdatePools() external view returns (uint256[] memory _pids){
    	uint256 maxPid = nftMasterChef.poolLength() - 1;
        uint number = 0;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
            (, uint256 currentRewardIndex)  = nftMasterChef.getPoolCurrentReward(pid);
            if(currentRewardIndex > 0){
                INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
				if(poolInfo.currentRewardIndex < currentRewardIndex && !nftMasterChef.isPoolEnd(pid)){
                    number ++;
                }
			}
        }
        if(number > 0){
            _pids = new uint256[](number);
            uint index = 0;
            for(uint256 pid = 0; pid <= maxPid; pid ++){
                (, uint256 currentRewardIndex)  = nftMasterChef.getPoolCurrentReward(pid);
                if(currentRewardIndex > 0){
                    INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
                    if(poolInfo.currentRewardIndex < currentRewardIndex && !nftMasterChef.isPoolEnd(pid)){
                        _pids[index] = pid;
                        index ++;
                    }
                }
            }
        }
    }

    function updateShouldPools() external {
    	uint256 maxPid = nftMasterChef.poolLength() - 1;
        for(uint256 pid = 0; pid <= maxPid; pid ++){
            (, uint256 currentRewardIndex)  = nftMasterChef.getPoolCurrentReward(pid);
            if(currentRewardIndex > 0){
                INFTMasterChef.PoolInfo memory poolInfo = nftMasterChef.poolInfos(pid);
				if(poolInfo.currentRewardIndex < currentRewardIndex && !nftMasterChef.isPoolEnd(pid)){
                    nftMasterChef.updatePool(pid);
                }
			}
        }
    }
}