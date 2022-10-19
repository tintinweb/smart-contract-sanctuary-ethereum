// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Upgradable.sol";

contract StakingPool is Upgradable {
    using SafeERC20 for IERC20;

    constructor() {
        _transferController(msg.sender);
    }

    /*================================ MAIN FUNCTIONS ================================*/

    function _updateReward(string memory poolId, address account) internal {
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][account];
        // Update reward
        if(pool.pool == 0) {
            pool.rewardPerTokenStored = rewardPerToken(poolId);
        }
        pool.lastUpdateTime = block.timestamp;
        data.reward = earned(poolId,account);
        if(pool.pool == 0) {
            data.rewardPerTokenPaid = pool.rewardPerTokenStored;
        }
    }

    /**
     * @dev Stake token to a pool
     * @param strs: poolId(0), internalTxID(1)
     * @param amount: amount of token user want to stake to the pool
    */
    function stakeToken(
        string[] memory strs,
        uint256 amount
    ) external poolExist(strs[0]) notBlocked {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][msg.sender];
        uint256 rewardPerTokenPaidBefore = data.rewardPerTokenPaid;
        uint256 rewardPerTokenStoredBefore = pool.rewardPerTokenStored;
        uint256 lastUpdateTimeBefore = pool.lastUpdateTime;
        require(block.timestamp >= pool.configs[0] && block.timestamp <= pool.configs[3], "Staking time is invalid");
        require(!blackList[msg.sender], "Caller has been blocked");
        require(amount > 0, amountInvalid);
        if (pool.configs.length >= 6) {
            require(pool.configs[5] == 0,"This pool has been Stopped");
        } 
        if(pool.configs.length >= 5){
            require(amount + pool.stakedBalance  <= pool.configs[4], "amount exceeds staking limit");
        }

        // Update reward
        _updateReward(poolId, msg.sender);
        uint256 rewardPerTokenStoredAfter = pool.rewardPerTokenStored;

        // Update staked balance
        data.balance += amount;
        
        // Update staking time
        data.stakedTime = block.timestamp;

        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked += 1;
        }
        
        // Update user's total staked balance 
        totalStakedBalancePerUser[msg.sender] += amount;
        
        if (stakedBalancePerUser[poolId][msg.sender] == 0) {
            pool.totalUserStaked += 1;
        }
        
        // Update user's staked balance to the pool
        stakedBalancePerUser[poolId][msg.sender] += amount;
        
        // Update pool staked balance 
        pool.stakedBalance += amount;
        
        // Update total staked balance to pools
        totalAmountStaked += amount;
        
        // Transfer user's token to the contract
        IERC20(pool.stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256[] memory infoBeforeAndAfter = new uint256[](4);
        infoBeforeAndAfter[0] = rewardPerTokenPaidBefore;
        infoBeforeAndAfter[1] = rewardPerTokenStoredBefore;
        infoBeforeAndAfter[2] = rewardPerTokenStoredAfter;
        infoBeforeAndAfter[3] = lastUpdateTimeBefore;
        emit StakingEvent(
            amount, 
            msg.sender, 
            poolId,
            strs[1],
            infoBeforeAndAfter
        );
    }
    
    /**
     * @dev Unstake token of a pool
     * @param strs: poolId(0), internalTxID(1)
     * @param amount: amount of token user want to unstake
   */
    function unstakeToken(string[] memory strs, uint256 amount)
        external
        poolExist(strs[0]) notBlocked
    {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage data = tokenStakingData[poolId][msg.sender];
        uint256 rewardPerTokenPaidBefore = data.rewardPerTokenPaid;
        uint256 rewardPerTokenStoredBefore = pool.rewardPerTokenStored;
        uint256 lastUpdateTimeBefore = pool.lastUpdateTime;

        require(amount <= data.balance, amountInvalid);
        require(0 < amount, amountInvalid);
        require(canGetReward(poolId),"Not enough staking time");
        // Update reward
        _updateReward(poolId, msg.sender);
        uint256 rewardPerTokenStoredAfter = pool.rewardPerTokenStored;

        // Update user staked balance
        totalStakedBalancePerUser[msg.sender] -= amount;
        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked -= 1;
        }
        
        // Update user staked balance by pool
        stakedBalancePerUser[poolId][msg.sender] -= amount;
        if (stakedBalancePerUser[poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }

        data.unstakedTime = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
        
        // Update staking amount
        data.balance -= amount;
        
        // Update pool staked balance
        pool.stakedBalance -= amount;
        
        // Update total staked balance user staked to pools
        totalAmountStaked -= amount;
        
        uint256 reward = 0;
        
        // If user unstake all token and has reward
        if (canGetReward(poolId) && data.reward > 0 && data.balance == 0) {
            reward = data.reward; 
            
            // Update pool reward claimed
            pool.totalRewardClaimed += reward;
            
            // Update pool reward fund
            pool.rewardFund -= reward;
            
            // Update total reward claimed
            totalRewardClaimed += reward;
            
            // Update reward user claimed by the pool
            rewardClaimedPerUser[poolId][msg.sender] += reward;
            
            // Update reward user claimed by pools
            totalRewardClaimedPerUser[msg.sender] += reward;
            
            // Reset reward
            data.reward = 0;
            
            // Transfer reward to user
            IERC20(pool.rewardToken).safeTransfer(msg.sender, reward);
        } 
        
        // Transfer token back to user
        IERC20(pool.stakingToken).safeTransfer(msg.sender, amount);
        uint256[] memory infoBeforeAndAfter = new uint256[](4);
        infoBeforeAndAfter[0] = rewardPerTokenPaidBefore;
        infoBeforeAndAfter[1] = rewardPerTokenStoredBefore;
        infoBeforeAndAfter[2] = rewardPerTokenStoredAfter;
        infoBeforeAndAfter[3] = lastUpdateTimeBefore;
        emit UnStakingEvent(
            amount, 
            msg.sender, 
            poolId,
            strs[1],
            infoBeforeAndAfter
        );
    } 
    
    /**
     * @dev Claim reward when user has staked to the pool for a period of time 
     * @param strs: poolId(0), internalTxID(1)
    */
    function claimReward(string[] memory strs)
        external
        poolExist(strs[0]) notBlocked
    { 
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        StakingData storage item = tokenStakingData[poolId][msg.sender];
        uint256 rewardPerTokenPaidBefore = item.rewardPerTokenPaid;
        uint256 rewardPerTokenStoredBefore = pool.rewardPerTokenStored;
        uint256 lastUpdateTimeBefore = pool.lastUpdateTime;

        // Update reward
        _updateReward(poolId, msg.sender);
        uint256 rewardPerTokenStoredAfter = pool.rewardPerTokenStored;

        uint256 reward = item.reward;
        require(reward > 0, "Reward is 0");
        require(IERC20(pool.rewardToken).balanceOf(address(this)) >= reward, "Pool balance is not enough");
        require(canGetReward(poolId), "Not enough staking time"); 

        item.unstakedTime = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];

        // Reset reward
        item.reward = 0;
        
        // Update reward claimed by the pool
        pool.totalRewardClaimed += reward;
        
        // Update pool reward fund
        pool.rewardFund -= reward; 
        
        // Update total reward claimed
        totalRewardClaimed += reward;
        
        // Update reward user claimed by the pool
        rewardClaimedPerUser[poolId][msg.sender] += reward;
        
        // Update total reward user claimed by pools
        totalRewardClaimedPerUser[msg.sender] += reward;
        
        // Transfer reward token to user
        IERC20(pool.rewardToken).safeTransfer(msg.sender, reward);
        uint256[] memory infoBeforeAndAfter = new uint256[](4);
        infoBeforeAndAfter[0] = rewardPerTokenPaidBefore;
        infoBeforeAndAfter[1] = rewardPerTokenStoredBefore;
        infoBeforeAndAfter[2] = rewardPerTokenStoredAfter;
        infoBeforeAndAfter[3] = lastUpdateTimeBefore;
        emit ClaimTokenEvent(
            reward, 
            msg.sender, 
            poolId,
            strs[1],
            infoBeforeAndAfter
        );
    }

    /**
     * @dev Claim reward when user has staked to the pool for a period of time and random get NFT 721
     * @param _signer: signer
     * @param _to: account claim reward
     * @param _tokenAddress: contract address of NFT
     * @param _tokenId: token ID
     * @param strs: poolId(0), internalTxID(1)
    */
    
    function claimReward721NFT (
        address _signer,
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory signature,
        string[] memory strs
    )
        external
        poolExist(strs[0])
    {
        require(msg.sender == _to);
        require(canGetReward(strs[0]),"Cant get Reward");
        require(rewardNFT721pPerPool[strs[0]][_tokenAddress][_tokenId] != 0,"Pool not has this tokenId");
        require(!invalidSignature[signature], "This signature has been used");
        require(verify(_signer, _to, _tokenAddress, _tokenId, 1, strs[0], signature), "Dont have NFT reward");
        invalidSignature[signature] = true;
        rewardNFT721pPerPool[strs[0]][_tokenAddress][_tokenId] -= 1;
        IERC721(_tokenAddress).safeTransferFrom(address(this), _to, _tokenId);
        emit ClaimRewardNFT(_to, address(this), _signer, _tokenId, 1, strs[0], strs[1]);
    }

    /**
     * @dev Claim reward when user has staked to the pool for a period of time and random get NFT 721
     * @param _signer: signer
     * @param _to: account claim reward
     * @param _tokenAddress: contract address of NFT
     * @param _tokenId: token ID
     * @param strs: poolId(0), internalTxID(1)
    */
    function claimReward1155NFT (
        address _signer,
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        bytes memory signature,
        string[] memory strs
    )
        external
        poolExist(strs[0])
    {
        require(msg.sender == _to);
        require(canGetReward(strs[0]),"Cant get Reward");
        require(rewardNFT1155pPerPool[strs[0]][_tokenAddress][_tokenId] >= 1, "Pool not has enough balance of this tokenId");
        require(!invalidSignature[signature], "This signature has been used");
        require(verify(_signer, _to, _tokenAddress, _tokenId, 1, strs[0], signature), "Dont have NFT reward");
        invalidSignature[signature] = true;
        rewardNFT1155pPerPool[strs[0]][_tokenAddress][_tokenId] -= 1;
        IERC1155(_tokenAddress).safeTransferFrom(address(this),_to,  _tokenId, 1, "");
        emit ClaimRewardNFT(_to, address(this), _signer, _tokenId, 1, strs[0], strs[1]);
    }
    
    /**
     * @dev Check if enough time to claim reward
     * @param poolId: Pool id
    */
    function canGetReward(string memory poolId) public view returns (bool) {
        PoolInfo memory pool = poolInfo[poolId];
        
        // If flexible pool
        if (pool.configs[2] == 0) return true;
        if(pool.configs.length >= 6) {
            if(pool.configs[5] == 1) return true;
        }
        StakingData memory data = tokenStakingData[poolId][msg.sender];
        
        // Pool with staking period
        return data.stakedTime + pool.configs[2] * ONE_DAY_IN_SECONDS<= block.timestamp;
    }

    /**
     * @dev Check amount of reward a user can receive
     * @param poolId: Pool id
     * @param account: wallet address of user
    */
    function earned(string memory poolId, address account) 
        public
        view
        returns (uint256)
    {
        StakingData storage item = tokenStakingData[poolId][account]; 
        PoolInfo memory pool = poolInfo[poolId];
        // If staked amount = 0
        if (item.balance == 0) return 0;
        // If pool time now < pool start date
        if (block.timestamp < pool.configs[0]) return 0;
        uint256 amount = 0;
        if(pool.pool == 0) {
            amount = item.balance * (rewardPerToken(poolId) - item.rewardPerTokenPaid) / 1e20 + item.reward;
        } else {
            uint256 currentTimestamp = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
            uint256 lastUpdateTime = item.stakedTime < item.unstakedTime ? item.unstakedTime : item.stakedTime;
            amount = (currentTimestamp - lastUpdateTime) * item.balance * pool.apr * pool.configs[6] / ONE_YEAR_IN_SECONDS / 1e4 + item.reward;
        }
         
        return pool.rewardFund > amount ? amount : pool.rewardFund;
    }
    
    /**
     * @dev Return amount of reward token distibuted per second
     * @param poolId: Pool id
    */
    function rewardPerToken(string memory poolId) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        require(pool.pool == 0,"Only Pool Allocation");
        // poolDuration = poolEndDatfe - poolStartDate
        uint256 poolDuration = pool.configs[1] - pool.configs[0]; 
        
        // Get current timestamp, if currentTimestamp > poolEndDate then poolEndDate will be currentTimestamp
        uint256 currentTimestamp = block.timestamp < pool.configs[1] ? block.timestamp : pool.configs[1];
        
        // If block timestamp < pool start date
        if (block.timestamp < pool.configs[0]) return 0;

        // If stakeBalance = 0 or poolDuration = 0
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        
        // If the pool has ended then stop calculate reward per token
        if (currentTimestamp <= pool.lastUpdateTime) return pool.rewardPerTokenStored;
        if (pool.configs.length >= 6) {
            if (pool.configs[5] == 1) return pool.rewardPerTokenStored;
        }
        // result = result * 1e8 for zero prevention
        uint256 rewardPool = pool.initialFund * (currentTimestamp - pool.lastUpdateTime) * 1e20;
        
        // newRewardPerToken = rewardPerToken(newPeriod) + lastRewardPertoken    
        return rewardPool / (poolDuration * pool.stakedBalance) + pool.rewardPerTokenStored;
    }
    
    /**
     * @dev Return annual percentage rate of a pool
     * @param poolId: Pool id
    */
    function apr(string memory poolId) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[poolId];
        
        // poolDuration = poolEndDate - poolStartDate
        uint256 poolDuration = pool.configs[1] - pool.configs[0];
        if (pool.stakedBalance == 0 || poolDuration == 0) return 0;
        
        return (ONE_YEAR_IN_SECONDS * pool.rewardFund / poolDuration - pool.totalRewardClaimed) * 100 / pool.stakedBalance; 
    }

    /**
     * @dev Return MaxTVL of PoolInfo
     * @param poolId: Pool id
    */
    function showMaxTVL(string memory poolId) 
        external 
        poolExist(poolId) view returns(uint256) 
    {
        PoolInfo memory pool = poolInfo[poolId];
        require(pool.configs.length > 4 ,"Pool doesn't have MaxTVL");
        return pool.configs[4];
    }

    /**
     * @dev set signer
     * @param _signer: signer
    */
    function setSigner(address _signer) external onlyController{
        signer = _signer;
    }

    /**
     * @dev Return Message Hash
     * @param _to: address of user claim reward
     * @param _tokenAddress: address of token
     * @param _tokenId: id of token
     * @param _amount: amount of token
     * @param poolId: id of Pool
    */
    function getMessageHash(
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        string memory poolId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _tokenAddress, _tokenId, _amount, poolId));
    }

    /**
     * @dev Return ETH Signed Message Hash
     * @param _messageHash: Message Hash
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    /**
     * @dev Return True/False
     * @param _signer: address of signer
     * @param _to: address of user claim reward
     * @param _tokenAddress: address of token
     * @param _tokenId: id of token
     * @param _amount: equal 1 with NFT721
     * @param poolId: id of Pool
     * @param signature: sign the message hash offchain
    */
    function verify(
        address _signer,
        address _to,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        string memory poolId,
        bytes memory signature
    ) internal view returns (bool) {
        require(_signer == signer, "This signer is invalid");
        bytes32 messageHash = getMessageHash(_to, _tokenAddress, _tokenId, _amount, poolId);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev Return address of signer
     * @param _ethSignedMessageHash: ETH Signed Message Hash
     * @param _signature: sign the message hash offchain
    */
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /**
     * @dev Return split Signature
     * @param sig: sign the message hash offchain
    */
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /*================================ ADMINISTRATOR FUNCTIONS ================================*/
    
    /**
     * @dev Create pool
     * @param strs: poolId(0), internalTxID(1)
     * @param addr: stakingToken(0), rewardToken(1)
     * @param data: rewardFund(0), typePool(1), apr(2)
     * @param configs: startDate(0), endDate(1), duration(2), endStakedTime(3), stakingLimit_for_Linear(4),stopPool(5),exchangeRateRewardToStaking(6)
   */
    function createPool(string[] memory strs, address[] memory addr, uint256[] memory data, uint256[] memory configs) external onlyAdmins {
        require(poolInfo[strs[0]].initialFund == 0, "Pool already exists");
        require(data[0] > 0, "Reward fund must be greater than 0");
        require(configs[0] < configs[1], "End date must be greater than start date");
        require(configs[0] < configs[3], "End staking date must be greater than start date");
        uint256 poolDuration = configs[1] - configs[0];
        uint256 MaxTVL = (data[0]*1e20)/poolDuration;
        require(data[0] * 1e20 / poolDuration > 1, "Can't create pool");
        
        if(configs[4] == 0 ) {
            PoolInfo memory pool = PoolInfo(addr[0], addr[1], 0, 0, data[0], data[0], 0, 0, 0, 1, configs, data[1],0, data[2]);
            poolInfo[strs[0]] = pool;
            poolInfo[strs[0]].configs[4] = MaxTVL;
        } else {
            uint256 rewardFund = poolDuration * configs[4] * data[2] * configs[6] / ONE_YEAR_IN_SECONDS / 1e4;
            PoolInfo memory pool = PoolInfo(addr[0], addr[1], 0, 0, rewardFund, rewardFund, 0, 0, 0, 1, configs, data[1],1, data[2]);
            poolInfo[strs[0]] = pool;
        }
        
        totalPoolCreated += 1;
        totalRewardFund += poolInfo[strs[0]].rewardFund;
        
        emit PoolUpdated(poolInfo[strs[0]].rewardFund, msg.sender, strs[0], strs[1]); 
    }

    /**
     * @dev Update pool
     * @param strs: poolId(0), internalTxID(1)
     * @param newConfigs: startDate(0), endDate(1), rewardFund(2), endStakingDate(3), stakingLimit(4)
   */
    function updatePool(string[] memory strs, uint256[] memory newConfigs)
        external
        onlyAdmins
        poolExist(strs[0])
    {
        string memory poolId = strs[0];
        PoolInfo storage pool = poolInfo[poolId];
        
        // if (newConfigs[0] != 0) {
        //     require(pool.configs[0] > block.timestamp, "Pool is already published");
        //     pool.configs[0] = newConfigs[0];
        // }
        // if (newConfigs[1] != 0) {
        //     require(newConfigs[1] > pool.configs[0], "End date must be greater than start date");
        //     require(newConfigs[1] >= block.timestamp, "End date must not be the past");
        //     pool.configs[1] = newConfigs[1];
        // }
        if (newConfigs[2] != 0) {
            // require(
            //     newConfigs[2] >= pool.initialFund,
            //     "New reward fund must be greater than or equals to existing reward fund"
            // );
            
            // totalRewardFund = totalRewardFund - pool.initialFund + newConfigs[2];
            pool.rewardFund = newConfigs[2];
            // pool.initialFund = newConfigs[2];
        }
        // if (newConfigs[3] != 0) {
        //     require(newConfigs[3] > pool.configs[0] && newConfigs[3] <= pool.configs[1], "End stake date is invalid");
        //     pool.configs[3] = newConfigs[3];
        // }

        if (pool.configs.length >= 5) {
            uint256 poolDuration = pool.configs[1]- pool.configs[0];
            pool.configs[4] = (pool.initialFund*1e20)/poolDuration;
        }
        emit PoolUpdated(pool.initialFund, msg.sender, strs[0], strs[1]);
    }

    function showConfigs(string memory poolId) external view poolExist(poolId) returns(uint256[] memory) {
        PoolInfo storage pool = poolInfo[poolId];
        return pool.configs;
    }


    /**
     * @dev set stop pool
     * @param poolId: poolId
    */
    function setStopPool(string memory poolId) external onlyAdmins poolExist(poolId) {
        PoolInfo storage pool = poolInfo[poolId];
        if(pool.pool == 0) {
            pool.rewardPerTokenStored = rewardPerToken(poolId);
        } else {
            pool.configs[1] = block.timestamp;
        }
        require(block.timestamp < pool.configs[1] || block.timestamp > pool.configs[0], "time invalid");
        if (pool.configs.length >= 6) {
            require(pool.configs[5] == 0,"This Pool is already stop");
            pool.configs[5] = 1;
        } else {
            pool.configs.push(1);
        }
        emit StopPool(poolId);
    }
 
    /**
     * @dev Emercency withdraw staking token, all staked data will be deleted, onlyProxyOwner can execute this function
     * @param _poolId: the poolId
     * @param _account: the user wallet address want to withdraw token
    */
    function emercencyWithdrawToken(string memory _poolId, address _account) external onlyController {
        PoolInfo memory pool = poolInfo[_poolId];
        StakingData memory data = tokenStakingData[_poolId][_account];
        require(data.balance > 0, "Staked balance is 0");

        // Transfer staking token back to user
        IERC20(pool.stakingToken).safeTransfer(_account, data.balance);
        uint256 amount = data.balance;

        // Update user staked balance
        totalStakedBalancePerUser[msg.sender] -= amount;
        if (totalStakedBalancePerUser[msg.sender] == 0) {
            totalUserStaked -= 1;
        }

        // Update user staked balance by pool
        stakedBalancePerUser[_poolId][msg.sender] -= amount;
        if (stakedBalancePerUser[_poolId][msg.sender] == 0) {
            pool.totalUserStaked -= 1;
        }

        // Update pool staked balance
        pool.stakedBalance -= amount;

        // Update total staked balance user staked to pools
        totalAmountStaked -= amount;

        // Delete data
        delete tokenStakingData[_poolId][_account];
    }
    
    /**
     * @dev Withdraw fund admin has sent to the pool
     * @param _tokenAddress: the token contract owner want to withdraw fund
     * @param _account: the account which is used to receive fund
     * @param _amount: the amount contract owner want to withdraw
    */
    function withdrawFund(address _tokenAddress, address _account, uint256 _amount) external onlyController {
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "Pool not has enough balance");
        // Transfer fund back to account
        IERC20(_tokenAddress).safeTransfer(_account, _amount);
    }

    /**
     * @dev Withdraw NFT721 with tokenId admin has sent to contract 
     * @param _tokenAddress: address of token
     * @param _account: to account
     * @param tokenId: token ID
     * @param strs: poolId(0), internalTxID(1)
    */
    function withDrawNFT721(address _tokenAddress, address _account, uint256 tokenId, string[] memory strs)
        external
        onlyAdmins
        poolExist(strs[0])
    {
        string memory poolId = strs[0];
        require(rewardNFT721pPerPool[poolId][_tokenAddress][tokenId] != 0,"error");
        
        rewardNFT721pPerPool[poolId][_tokenAddress][tokenId] -= 1;
        // Transfer token back to account
        IERC721(_tokenAddress).safeTransferFrom(address(this), _account, tokenId);
        emit WithdrawNFT( _tokenAddress, address(this), _account, tokenId, 1, poolId, strs[0]);
    }
    
    /**
     * @dev Withdraw NFT1155 with tokenId and amount admin has sent to contract 
     * @param _tokenAddress: address of token
     * @param _account: to account
     * @param tokenId: token ID
     * @param amount: amount of tokenID
     * @param strs: poolId(0), internalTxID(1)
    */
    function withDrawNFT1155(address _tokenAddress, address _account, uint256 tokenId, uint256 amount, string[] memory strs)
        external
        onlyAdmins
        poolExist(strs[0])
    {
        string memory poolId = strs[0];
        require(rewardNFT1155pPerPool[poolId][_tokenAddress][tokenId] >= amount, "error");
        
        rewardNFT1155pPerPool[poolId][_tokenAddress][tokenId] -= amount;
        // Transfer token back to account
        IERC1155(_tokenAddress).safeTransferFrom(address(this), _account, tokenId, amount, "");
        emit WithdrawNFT( _tokenAddress, address(this), _account, tokenId, amount, poolId, strs[1]);
    }

    /**
     * @dev Deposit NFT721 with tokenId
     * @param _tokenAddress: address of token
     * @param strs: poolId(0), internalTxID(1)
     * @param tokenId: token ID
    */
    function depositNFT721(address _tokenAddress, uint256 tokenId, string[] memory strs)
        external
        onlyAdmins
    {
        string memory poolId = strs[0];
        IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        rewardNFT721pPerPool[poolId][_tokenAddress][tokenId] = 1;
        emit DepositNFT( _tokenAddress, msg.sender, address(this), tokenId, 1, poolId, strs[1]);
    }

    /**
     * @dev Deposit NFT1155 with tokenId
     * @param _tokenAddress: address of token
     * @param strs: poolId(0), internalTxID(1)
     * @param tokenId: token ID
     * @param amount: amount
    */
    function depositNFT1155(address _tokenAddress, uint256 tokenId, uint256 amount, string[] memory strs)
        external
        onlyAdmins
    {
        string memory poolId = strs[0];
        IERC1155(_tokenAddress).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        rewardNFT1155pPerPool[poolId][_tokenAddress][tokenId] += amount;
        emit DepositNFT( _tokenAddress, msg.sender, address(this), tokenId, amount, poolId, strs[1]);
    }
    
    /**
     * @dev Contract owner set admin for execute administrator functions
     * @param _address: wallet address of admin
     * @param _value: true/false
    */
    function setAdmin(address _address, bool _value) external onlyController { 
        adminList[_address] = _value;

        emit AdminSet(_address, _value);
    } 

    /**
     * @dev Check if a wallet address is admin or not
     * @param _address: wallet address of the user
    */
    function isAdmin(address _address) external view returns (bool) {
        return adminList[_address];
    }

    /**
     * @dev Block users
     * @param _address: wallet address of user
     * @param _value: true/false
    */
    function setBlacklist(address _address, bool _value) external onlyAdmins {
        blackList[_address] = _value;
        emit BlacklistSet(_address, _value);
    }
    
    /**
     * @dev Check if a user has been blocked
     * @param _address: user wallet 
    */
    function isBlackList(address _address) external view returns (bool) {
        return blackList[_address];
    }
    
    /**
     * @dev Set pool active/deactive
     * @param _poolId: the pool id
     * @param _value: true/false
    */
    function setPoolActive(string memory _poolId, uint256 _value) external onlyAdmins {
        poolInfo[_poolId].active = _value;

        emit PoolActivationSet(msg.sender, _poolId, _value);
    }

    /**
     * @dev Transfers controller of the contract to a new account (`newController`).
     * Can only be called by the current controller.
    */
    function transferController(address _newController) external {
        // Check if controller has been initialized in proxy contract
        // Caution: If set controller != proxyOwnerAddress then all functions require controller permission cannot be called from proxy contract
        if (controller != address(0)) {
            require(msg.sender == controller, "Only controller");
        }
        require(_newController != address(0), "New controller is the zero address");
        _transferController(_newController);
    }

    /**
     * @dev Transfers controller of the contract to a new account (`newController`).
     * Internal function without access restriction.
    */
    function _transferController(address _newController) internal {
        address oldController = controller;
        controller = _newController;
        emit ControllerTransferred(oldController, controller);
    }

     /**
     * @dev this function for the contract can receive ERC1155.
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function blockTime() public view returns(uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Upgradable {
    mapping(address => bool) adminList; // admin list for updating pool
    mapping(address => bool) blackList; // blocked users
    uint256 constant ONE_YEAR_IN_SECONDS = 31536000;
    uint256 constant ONE_DAY_IN_SECONDS = 86400;
    uint256 public totalAmountStaked; // balance of nft and token staked to the pools
    uint256 public totalRewardClaimed; // total reward user has claimed
    uint256 public totalPoolCreated; // total pool created by admin
    uint256 public totalRewardFund; // total pools reward fund
    uint256 public totalUserStaked; // total user has staked to pools
    mapping(string => PoolInfo) public poolInfo; // poolId => data: pools info
    mapping(address => uint256) public totalStakedBalancePerUser; // userAddr => amount: total value users staked to the pool
    mapping(address => uint256) public totalRewardClaimedPerUser; // userAddr => amount: total reward users claimed
    mapping(string => mapping(address => StakingData)) public tokenStakingData; // poolId => user => token staked data
    mapping(string => mapping(address => uint256)) public stakedBalancePerUser; // poolId => userAddr => amount: total value each user staked to the pool
    mapping(string => mapping(address => uint256)) public rewardClaimedPerUser; // poolId => userAddr => amount: reward each user has claimed
    address public controller;
    mapping(string => mapping(address => mapping(uint256 => uint256))) public rewardNFT1155pPerPool; // poolId => tokenAddress =>  tokenId => amount: reward NFT in pool 
    mapping(string => mapping(address => mapping(uint256 => uint256))) public rewardNFT721pPerPool; //poolId => tokenAddress => tokenId =>amount: reward NFT in pool 
    mapping(bytes => bool) public invalidSignature; //signature => true/false : check invalid signature
    address public signer;
    string amountInvalid = "Amount is invalid";

    /*================================ MODIFIERS ================================*/
    
    modifier onlyAdmins() {
        require(adminList[msg.sender] || msg.sender == controller, "Only admins");
        _;
    }
    
    modifier poolExist(string memory poolId) {
        require(poolInfo[poolId].initialFund != 0, "Pool is not exist");
        require(poolInfo[poolId].active == 1, "Pool has been disabled");
        _;
    }

    modifier notBlocked() {
        require(!blackList[msg.sender], "Caller has been blocked");
        _;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Only controller");
        _;
    }
    
    /*================================ EVENTS ================================*/
    // infoBeforeAndAfter: rewardPerTokenPaidBefore, rewardPerTokenStoredBefore, rewardPerTokenStoredAfter, poolLastUpdateTime
    // strs: PoolID, internalTxID
    event StakingEvent(
        uint256 amount,
        address indexed account,
        string poolId,
        string internalTxId,
        uint256[] infoBeforeAndAfter
    );
    
    event PoolUpdated(
        uint256 rewardFund,
        address indexed creator,
        string poolId,
        string internalTxID
    );

    event AdminSet(
        address indexed admin,
        bool isSet
    );

    event BlacklistSet(
        address indexed user,
        bool isSet
    );

    event PoolActivationSet(
        address indexed admin,
        string poolId,
        uint256 isActive
    );

    event ControllerTransferred(
        address indexed previousController, 
        address indexed newController
    );

    event ClaimRewardNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        string poolId,
        string internalTxID
    );

    event DepositNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        string poolId,
        string internalTxID
    );

    event WithdrawNFT(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        string poolId,
        string internalTxID
    );

    event StopPool(
        string poolId
    );
    // infoBeforeAndAfter: rewardPerTokenPaidBefore, rewardPerTokenStoredBefore, rewardPerTokenStoredAfter, poolLastUpdateTime
    // strs: PoolID, internalTxID
    event UnStakingEvent( 
        uint256 amount,
        address indexed account,
        string poolId,
        string internalTxId,
        uint256[] infoBeforeAndAfter
    );
    // infoBeforeAndAfter: rewardPerTokenPaidBefore, rewardPerTokenStoredBefore, rewardPerTokenStoredAfter, poolLastUpdateTime
    event ClaimTokenEvent( 
        uint256 amount,
        address indexed account,
        string poolId,
        string internalTxId,
        uint256[] infoBeforeAndAfter
    );
    
    /*================================ STRUCTS ================================*/
     
    struct StakingData {
        uint256 balance; // staked value
        uint256 stakedTime; // staked time
        uint256 unstakedTime; // unstaked time
        uint256 reward; // the total reward
        uint256 rewardPerTokenPaid; // reward per token paid
        address account; // staked account
    }
    
    struct PoolInfo {
        address stakingToken; // token staking of the pool
        address rewardToken; //  reward token of  the pool
        uint256 stakedBalance; // total balance staked the pool
        uint256 totalRewardClaimed; // total reward user has claimed
        uint256 rewardFund; // pool amount for reward token available
        uint256 initialFund; // initial reward fund
        uint256 lastUpdateTime; // last update time
        uint256 rewardPerTokenStored; // reward distributed
        uint256 totalUserStaked; // total user staked
        uint256 active; // pool activation status, 0: disable, 1: active
        uint256[] configs; // startDate(0), endDate(1), duration(2), endStakeDate(3), stakingLimit(4),stopPool(5), exchangeRateRewardToStaking(6),
        uint256 typePool; // 0: pool tokenReward, 1: pool tokenReward and NFT reward
        uint256 pool; // 0: poolAlowcation, 1: poolLinear;
        uint256 apr; //annual percentage rate
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}