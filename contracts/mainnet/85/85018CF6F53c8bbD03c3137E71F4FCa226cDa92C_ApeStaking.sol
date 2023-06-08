// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IApeCoinStaking.sol";
import "./interfaces/IApePool.sol";
import "./interfaces/IPTokenApeStaking.sol";
import "./interfaces/ITokenLending.sol";
import "./interfaces/INftGateway.sol";
import "./ApeStakingStorage.sol";

/**
 * @title Pawnfi's ApeStaking Contract
 * @author Pawnfi
 */
contract ApeStaking is ERC721HolderUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable, ApeStakingStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    function initialize(
        address apePool_,
        address nftGateway_,
        address pawnToken_,
        address feeTo_,
        StakingConfiguration memory stakingConfiguration_
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REINVEST_ROLE, msg.sender);
        apeCoinStaking = IApePool(apePool_).apeCoinStaking();
        apePool = apePool_;
        nftGateway = nftGateway_;
        pawnToken = pawnToken_;
        feeTo = feeTo_;
        stakingConfiguration = stakingConfiguration_;

        apeCoin = IApeCoinStaking(apeCoinStaking).apeCoin();
        ( , pbaycAddr, , , ) = INftGateway(nftGateway_).marketInfo(BAYC_ADDR);
        ( , pmaycAddr, , , ) = INftGateway(nftGateway_).marketInfo(MAYC_ADDR);
        ( , pbakcAddr, , , ) = INftGateway(nftGateway_).marketInfo(BAKC_ADDR);

        _nftInfo[BAYC_ADDR].poolId = BAYC_POOL_ID;
        _nftInfo[MAYC_ADDR].poolId = MAYC_POOL_ID;
        _nftInfo[BAKC_ADDR].poolId = BAKC_POOL_ID;

        IERC721Upgradeable(BAYC_ADDR).setApprovalForAll(pbaycAddr, true);
        IERC721Upgradeable(MAYC_ADDR).setApprovalForAll(pmaycAddr, true);
        IERC721Upgradeable(BAKC_ADDR).setApprovalForAll(pbakcAddr, true);
    }

    /**
     * @notice Get IDs of staked NFTs
     * @param nftAsset nft asset address
     * @return nftIds nft id array
     */
    function getStakeNftIds(address nftAsset) external view returns (uint256[] memory nftIds) {
        uint256 length = _nftInfo[nftAsset].stakeIds.length();
        nftIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            nftIds[i] = _nftInfo[nftAsset].stakeIds.at(i);
        }
    }

    /**
     * @notice Get user info
     * @param userAddr User address
     * @param nftAsset nft asset address
     * @return collectRate Collect rate
     * @return iTokenAmount iToken amount
     * @return pTokenAmount Amount of P-Token corresponding to iToken
     * @return interestReward P-Token reward
     * @return stakeNftIds Staked nft ids
     * @return depositNftIds Deposited nft ids
     */
    function getUserInfo(address userAddr, address nftAsset) external returns (
        uint256 collectRate,
        uint256 iTokenAmount,
        uint256 pTokenAmount,
        uint256 interestReward,
        uint256[] memory stakeNftIds,
        uint256[] memory depositNftIds
    ) {
        UserInfo storage userInfo = _userInfo[userAddr];
        collectRate = userInfo.collectRate;

        uint256 poolId = _nftInfo[nftAsset].poolId;
        iTokenAmount = userInfo.iTokenAmount[poolId];

        (address iTokenAddr, , uint256 pieceCount, , ) = INftGateway(nftGateway).marketInfo(nftAsset);
        pTokenAmount = ITokenLending(iTokenAddr).exchangeRateCurrent() * iTokenAmount / BASE_PERCENTS;

        uint256 length = userInfo.stakeIds[poolId].length();
        stakeNftIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            stakeNftIds[i] = userInfo.stakeIds[poolId].at(i);
        }

        length = userInfo.depositIds[poolId].length();
        depositNftIds = new uint256[](length);
        for(uint256 i = 0; i < length; i++) {
            depositNftIds[i] = userInfo.depositIds[poolId].at(i);
        }

        uint256 amount = length * pieceCount;
        interestReward = pTokenAmount > amount ? pTokenAmount - amount : 0;
    }

    /**
     * @notice Get staked nft id info
     * @param poolId Pool ID
     * @param nftId nft id
     * @return uint256 Deposited amount + unclaimed rewards
     * @return uint256 Deposited amount
     * @return uint256 Unclaimed rewards
     */
    function getStakeInfo(uint256 poolId, uint256 nftId) public view returns (uint256, uint256, uint256) {
        IApeCoinStaking apeCoinStakingContract = IApeCoinStaking(apeCoinStaking);
        (uint256 stakingAmount, ) = apeCoinStakingContract.nftPosition(poolId, nftId);
        uint256 pendingRewards = apeCoinStakingContract.pendingRewards(poolId, address(0), nftId);
        return (stakingAmount + pendingRewards, stakingAmount, pendingRewards);
    }

    /**
     * @notice Get reward rate per block
     * @param poolId pool id
     * @param addAmount Addd staked amount
     * @return uint256 Reward rate per block
     */
    function getRewardRatePerBlock(uint256 poolId, uint256 addAmount) public view returns (uint256) {
        IApeCoinStaking apeCoinStakingContract = IApeCoinStaking(apeCoinStaking);
        ( , uint256 lastRewardsRangeIndex, uint256 stakedAmount, ) = apeCoinStakingContract.pools(poolId);
        stakedAmount += addAmount;
        stakedAmount = stakedAmount == 0 ? 1 : stakedAmount;
        IApeCoinStaking.TimeRange memory timeRange = apeCoinStakingContract.getTimeRangeBy(poolId, lastRewardsRangeIndex);
        // 8760 = 24 * 365
        return (uint256(timeRange.rewardsPerHour) * 8760 * BASE_PERCENTS) / (stakedAmount * BLOCKS_PER_YEAR);
    }
    
    /**
     * @notice Get user's rewards and borrowing interest per block
     * @param userAddr User address
     * @return totalIncome Rewards per block
     * @return totalPay Borrowing interest per block
     */
    function getUserHealth(address userAddr) public returns (uint256 totalIncome, uint256 totalPay) {
        UserInfo storage userInfo = _userInfo[userAddr];
        
        for(uint256 poolId = BAYC_POOL_ID; poolId <= BAKC_POOL_ID; poolId++) {
            uint256 poolStakingRatePerBlock = getRewardRatePerBlock(poolId, 0);
            totalIncome += userInfo.stakeAmount[poolId] * poolStakingRatePerBlock / BASE_PERCENTS;
        }
        uint256 borrowRate = IApePool(apePool).borrowRatePerBlock();
        uint256 borrowedAmount = IApePool(apePool).borrowBalanceCurrent(userAddr);
        totalPay = borrowedAmount * borrowRate / BASE_PERCENTS;
    }

    /**
     * @notice Get agency address of NFT staking
     * @param nftAsset nft asset address
     * @return address Agency address of staking
     */
    function _getPTokenStaking(address nftAsset) internal view returns (address) {
        require(nftAsset == BAYC_ADDR || nftAsset == MAYC_ADDR);
        return nftAsset == BAYC_ADDR ? pbaycAddr : pmaycAddr;
    }

    /**
     * @notice Delete user deposit information
     * @param userAddr User address
     * @param nftAsset nft asset address
     * @param nftId nft id
     * @return iTokenAmount iToken amount
     */
    function _delUserDepositInfo(address userAddr, address nftAsset, uint256 nftId) internal returns (uint256 iTokenAmount){
        NftInfo storage nftInfo = _nftInfo[nftAsset];
        iTokenAmount = nftInfo.iTokenAmount[nftId];
        delete nftInfo.depositor[nftId];
        delete nftInfo.iTokenAmount[nftId];

        UserInfo storage userInfo = _userInfo[userAddr];
        userInfo.depositIds[nftInfo.poolId].remove(nftId);
        userInfo.iTokenAmount[nftInfo.poolId] -= iTokenAmount;
    }

    /**
     * @notice Withdraw NFT from lending market
     * @param userAddr User address
     * @param nftAsset nft asset address
     * @param nftId nft id
     */
    function _withdrawNftFromLending(address userAddr, address nftAsset, uint256 nftId) internal {
        uint256 iTokenAmount = _delUserDepositInfo(userAddr, nftAsset, nftId);
        (address iTokenAddr, address pTokenAddr, uint256 pieceCount, , ) = INftGateway(nftGateway).marketInfo(nftAsset);

        uint balanceBefore = IERC20Upgradeable(pTokenAddr).balanceOf(address(this));
        ITokenLending(iTokenAddr).redeem(iTokenAmount);
        uint balanceAfter = IERC20Upgradeable(pTokenAddr).balanceOf(address(this));
        uint256 redeemAmount = balanceAfter - balanceBefore;
        require(redeemAmount >= pieceCount,"less");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = nftId;
        IPTokenApeStaking(pTokenAddr).withdraw(tokenIds);
        IERC721Upgradeable(nftAsset).safeTransferFrom(address(this), userAddr, nftId);
        uint256 remainingAmount = redeemAmount - pieceCount;
        _transferAsset(pTokenAddr, userAddr, remainingAmount);
        emit WithdrawNftFromStake(userAddr, nftAsset, nftId, redeemAmount, pieceCount);
    }

    function _approveMax(address tokenAddr, address spender, uint256 amount) internal {
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddr);
        uint256 allowance = token.allowance(address(this), spender);
        if(allowance < amount) {
            token.safeApprove(spender, 0);
            token.safeApprove(spender, type(uint256).max);
        }
    }

    /**
     * @notice Supply NFT to lending market
     * @param userAddr User address
     * @param nftAsset nft asset address
     * @param nftIds nft ids
     */
    function _depositNftToLending(address userAddr, address nftAsset, uint256[] memory nftIds) internal {
        uint length = nftIds.length;
        if(length > 0) {
            NftInfo storage nftInfo = _nftInfo[nftAsset];
            UserInfo storage userInfo = _userInfo[userAddr];

            (address iTokenAddr, address pTokenAddr, , , ) = INftGateway(nftGateway).marketInfo(nftAsset);
            for(uint256 i = 0; i < length; i++) {
                uint256 nftId = nftIds[i];
                IERC721Upgradeable(nftAsset).safeTransferFrom(userAddr, address(this), nftId);
                userInfo.depositIds[nftInfo.poolId].add(nftId);
                nftInfo.depositor[nftId] = userAddr;
            }
            
            uint256 tokenAmount = IPTokenApeStaking(pTokenAddr).deposit(nftIds, type(uint256).max);
            _approveMax(pTokenAddr, iTokenAddr, tokenAmount);

            uint256 iTokenBalanceBefore = IERC20Upgradeable(iTokenAddr).balanceOf(address(this));
            ITokenLending(iTokenAddr).mint(tokenAmount);
            uint256 iTokenBalanceAfter = IERC20Upgradeable(iTokenAddr).balanceOf(address(this));

            uint256 amount = iTokenBalanceAfter - iTokenBalanceBefore;
            uint256 singleQuantity = amount / length;
            for(uint i = 0; i < length; i++) {
                nftInfo.iTokenAmount[nftIds[i]] = singleQuantity;
            }
            userInfo.iTokenAmount[nftInfo.poolId] += amount;

            emit DepositNftToStake(userAddr, nftAsset, nftIds, amount, tokenAmount);
        }
    }

    function _storeUserInfo(
        address userAddr,
        address nftAsset,
        IApeCoinStaking.SingleNft[] memory _nfts,
        IApeCoinStaking.PairNftDepositWithAmount[] memory _nftPairs
    ) internal returns (uint256, uint256) {
        NftInfo storage nftInfo = _nftInfo[nftAsset];
        UserInfo storage userInfo = _userInfo[userAddr];

        address ptokenStaking = _getPTokenStaking(nftAsset);

        uint256 amount;
        uint256 tokenId;

        uint256 nftAmount = 0;
        for (uint256 index = 0; index < _nfts.length; index++) {
            tokenId = _nfts[index].tokenId;
            _store(userAddr, ptokenStaking, nftAsset, tokenId);
            amount = _nfts[index].amount;
            nftAmount += amount;
            
            emit StakeSingleNft(userAddr, nftAsset, tokenId, amount);
        }
        userInfo.stakeAmount[nftInfo.poolId] += nftAmount;

        uint256 nftPairAmount = 0;
        for (uint256 index = 0; index < _nftPairs.length; index++) {
            tokenId = _nftPairs[index].bakcTokenId;
            require(_validOwner(userAddr, ptokenStaking, nftAsset, _nftPairs[index].mainTokenId),"main");
            _store(userAddr, pbakcAddr, BAKC_ADDR, tokenId);
            amount =_nftPairs[index].amount;
            nftPairAmount += amount;
            emit StakePairNft(userAddr, nftAsset, _nftPairs[index].mainTokenId, tokenId, amount);
        }
        userInfo.stakeAmount[_nftInfo[BAKC_ADDR].poolId] += nftPairAmount;
        return (nftAmount, nftPairAmount);
    }

    function _store(address userAddr, address ptokenStaking, address nftAsset, uint256 nftId) internal {
        require(_validOwner(userAddr, ptokenStaking, nftAsset, nftId),"owner");
        NftInfo storage nftInfo = _nftInfo[nftAsset];
        
        if(nftInfo.staker[nftId] == address(0)) {
            nftInfo.staker[nftId] = userAddr;
            nftInfo.stakeIds.add(nftId);

            UserInfo storage userInfo = _userInfo[userAddr];
            userInfo.stakeIds[nftInfo.poolId].add(nftId);

            (uint256 stakingAmount, ) = IApeCoinStaking(apeCoinStaking).nftPosition(nftInfo.poolId, nftId);
            userInfo.stakeAmount[nftInfo.poolId] += stakingAmount;
        }
    }

    /**
     * @notice Supply and stake NFT
     * @param depositInfo NFT supplying info
     * @param stakingInfo NFT staking info
     * @param _nfts List of single NFT staking
     * @param _nftPairs List of paired NFT staking
     */
    function depositAndBorrowApeAndStake(
        DepositInfo memory depositInfo,
        StakingInfo memory stakingInfo,
        IApeCoinStaking.SingleNft[] calldata _nfts,
        IApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external nonReentrant {
        address userAddr = msg.sender;
        address ptokenStaking = _getPTokenStaking(stakingInfo.nftAsset);

        // 1, handle borrow part and send ape to ptokenAddress
        if(stakingInfo.borrowAmount > 0) {
            uint256 borrowRate = IApePool(apePool).borrowRatePerBlock();
            uint256 stakingRate = getRewardRatePerBlock(_nftInfo[stakingInfo.nftAsset].poolId, stakingInfo.borrowAmount);
            require(borrowRate + stakingConfiguration.addMinStakingRate < stakingRate,"rate");
            IApePool(apePool).borrowBehalf(userAddr, stakingInfo.borrowAmount);
            IERC20Upgradeable(apeCoin).safeTransfer(ptokenStaking, stakingInfo.borrowAmount);
        }

        // 2, send cash part to ptokenAddress
        if(stakingInfo.cashAmount > 0) {
            IERC20Upgradeable(apeCoin).safeTransferFrom(userAddr, ptokenStaking, stakingInfo.cashAmount);
        }

        _depositNftToLending(userAddr, stakingInfo.nftAsset, depositInfo.mainTokenIds);
        _depositNftToLending(userAddr, BAKC_ADDR, depositInfo.bakcTokenIds);

        (uint256 nftAmount, uint256 nftPairAmount) = _storeUserInfo(userAddr, stakingInfo.nftAsset, _nfts, _nftPairs);

        // 3, deposit bayc or mayc pool
        if(_nfts.length > 0) {
            IPTokenApeStaking(ptokenStaking).depositApeCoin(nftAmount, _nfts);
        }

        // 4, deposit bakc pool
        if(_nftPairs.length > 0) {
            IPTokenApeStaking(ptokenStaking).depositBAKC(nftPairAmount, _nftPairs);
        }
    }

    /**
     * @notice Verify NFT owner
     * @param userAddr User address
     * @param ptokenStaking Address of NFT staking agency
     * @param nftAsset nft asset address
     * @param nftId nft id
     * @return bool true：Verification pass false：Verification fail
     */
    function _validOwner(address userAddr, address ptokenStaking, address nftAsset, uint256 nftId) internal view returns (bool) {
        address holder = _nftInfo[nftAsset].depositor[nftId];
        if(holder == address(0)) {
            address nftOwner = IPTokenApeStaking(ptokenStaking).getNftOwner(nftId);
            holder = INftGateway(nftOwner).nftOwner(userAddr, nftAsset, nftId);
        }
        return holder == userAddr;
    }

    /**
     * @notice Claim ApeCoins for single NFT staking
     * @param nftAsset nft asset address
     * @param _nfts Claim ApeCoins for single NFT staking
     */
    function withdrawApeCoin(address nftAsset, IApeCoinStaking.SingleNft[] calldata _nfts, IApeCoinStaking.PairNftWithdrawWithAmount[] calldata _nftPairs) external nonReentrant {
        _withdrawApeCoin(msg.sender, nftAsset, _nfts, _nftPairs, RewardAction.WITHDRAW);
    }

    /**
     * @notice Verify NFT staker
     * @param userAddr User address
     * @param ptokenStaking Address of NFT staking agency
     * @param nftAsset nft asset address
     * @param nftId nft id
     * @param actionType Event type
     * @return RewardAction Event type
     */
    function _validStaker(address userAddr, address ptokenStaking, address nftAsset, uint256 nftId, RewardAction actionType) internal view returns (RewardAction) {
        address staker = _nftInfo[nftAsset].staker[nftId];
        require(staker == userAddr,"staker");
        if(!_validOwner(userAddr, ptokenStaking, nftAsset, nftId) && actionType == RewardAction.WITHDRAW){
            return RewardAction.REDEEM;
        }
        return actionType;
    }

    function _removeUserInfo(address nftAsset, uint256 nftId, uint withdrawAmount, bool maximum) internal returns (uint256, uint256) {
        NftInfo storage nftInfo = _nftInfo[nftAsset];
        uint256 poolId = nftInfo.poolId;
        ( , uint256 stakingAmount, uint256 claimAmount) = getStakeInfo(poolId, nftId);
        withdrawAmount = maximum ? stakingAmount : withdrawAmount;
        require(stakingAmount >= withdrawAmount,"more");

        UserInfo storage userInfo = _userInfo[nftInfo.staker[nftId]];
        if(withdrawAmount == stakingAmount) {
            
            delete nftInfo.staker[nftId];
            nftInfo.stakeIds.remove(nftId);
            userInfo.stakeIds[poolId].remove(nftId);
            
        } else {
            claimAmount = 0;
        }
        userInfo.stakeAmount[poolId] -= withdrawAmount;
        return (withdrawAmount, claimAmount);
    }

    function _withdrawApeCoin(
        address userAddr,
        address nftAsset,
        IApeCoinStaking.SingleNft[] memory _nfts,
        IApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs,
        RewardAction actionType
    ) internal {
        address ptokenStaking = _getPTokenStaking(nftAsset);
        uint256 totalWithdrawAmount = 0;
        uint256 totalClaimAmount = 0;


        // 1, check nfts owner
        for (uint256 index = 0; index < _nfts.length; index++) {
            actionType = _validStaker(userAddr, ptokenStaking, nftAsset, _nfts[index].tokenId, actionType);
            (uint256 withdrawAmount, uint256 claimAmount) = _removeUserInfo(nftAsset, _nfts[index].tokenId, _nfts[index].amount, false);
            totalWithdrawAmount += withdrawAmount;
            totalClaimAmount += claimAmount;
            emit UnstakeSingleNft(userAddr, nftAsset, _nfts[index].tokenId, _nfts[index].amount, claimAmount);
        }

        for (uint256 index = 0; index < _nftPairs.length; index++) {
            actionType = _validStaker(userAddr, pbakcAddr, BAKC_ADDR, _nftPairs[index].bakcTokenId, actionType);
            (uint256 withdrawAmount, uint256 claimAmount) = _removeUserInfo(BAKC_ADDR, _nftPairs[index].bakcTokenId, _nftPairs[index].amount, _nftPairs[index].isUncommit);
            totalWithdrawAmount += withdrawAmount;
            totalClaimAmount += claimAmount;
            emit UnstakePairNft(userAddr, nftAsset, _nftPairs[index].mainTokenId, _nftPairs[index].bakcTokenId, _nftPairs[index].amount, claimAmount);
        }

        // 2, claim rewards
        if(_nfts.length > 0) {
            IPTokenApeStaking(ptokenStaking).withdrawApeCoin(_nfts, address(this));
        }
        if(_nftPairs.length > 0) {
            IPTokenApeStaking(ptokenStaking).withdrawBAKC(_nftPairs, address(this));
        }

        // 3, repay if borrowed and mint and claim
        _repayAndClaim(userAddr, totalWithdrawAmount, totalClaimAmount, actionType);
    }

    /**
     * @notice Claiming staking rewards for a single NFT
     * @param nftAsset nft asset address
     * @param _nfts Array of NFTs staked
     */
    function claimApeCoin(address nftAsset, uint256[] calldata _nfts, IApeCoinStaking.PairNft[] calldata _nftPairs) external nonReentrant {
        _claimApeCoin(msg.sender, nftAsset, _nfts, _nftPairs, RewardAction.CLAIM);
    }

    function _claimVerify(address userAddr, address ptokenStaking, address nftAsset, uint256 nftId) internal view returns (uint256 claimAmount) {
        require(_validOwner(userAddr, ptokenStaking, nftAsset, nftId),"owner");
        ( , , claimAmount) = getStakeInfo(_nftInfo[nftAsset].poolId, nftId);
        require(claimAmount > 0,"claim");
    }

    function _claimApeCoin(
        address userAddr,
        address nftAsset,
        uint256[] calldata nftIds,
        IApeCoinStaking.PairNft[] calldata _nftPairs,
        RewardAction actionType
    ) internal {
        address ptokenStaking = _getPTokenStaking(nftAsset);
        uint256 totalClaimAmount = 0;

        uint256 claimAmount;
        uint256 tokenId;
        // 1, check nfts owner
        for (uint256 index = 0; index < nftIds.length; index++) {
            tokenId = nftIds[index];
            claimAmount = _claimVerify(userAddr, ptokenStaking, nftAsset, tokenId);
            totalClaimAmount += claimAmount;
            emit ClaimSingleNft(userAddr, nftAsset, tokenId, claimAmount);
        }

        for (uint256 index = 0; index < _nftPairs.length; index++) {
            require(_validOwner(userAddr, ptokenStaking, nftAsset, _nftPairs[index].mainTokenId),"main");
            tokenId = _nftPairs[index].bakcTokenId;
            claimAmount = _claimVerify(userAddr, pbakcAddr, BAKC_ADDR, tokenId);
            totalClaimAmount += claimAmount;
            emit ClaimPairNft(userAddr, nftAsset, _nftPairs[index].mainTokenId, tokenId, claimAmount);
        }

        // 2, claim rewards
        if(nftIds.length > 0) {
            IPTokenApeStaking(ptokenStaking).claimApeCoin(nftIds, address(this));
        }
        if(_nftPairs.length > 0) {
            IPTokenApeStaking(ptokenStaking).claimBAKC(_nftPairs, address(this));
        }

        // 3, repay if borrowed and mint and claim
        _repayAndClaim(userAddr, 0, totalClaimAmount, actionType);
    }

    /**
     * @notice Repay and reinvest
     * @param userAddr User address
     * @param allAmount Deposit amount
     * @param allClaimAmount Reward amount
     * @param actionType Event type
     */
    function _repayAndClaim(address userAddr, uint256 allAmount, uint256 allClaimAmount, RewardAction actionType) internal {
        uint256 fee = allClaimAmount * stakingConfiguration.feeRate / BASE_PERCENTS;
        allClaimAmount -= fee;
        _transferAsset(apeCoin, feeTo, fee);

        uint256 totalAmount = allAmount + allClaimAmount;
        _approveMax(address(apeCoin), apePool, totalAmount);

        // 1, repay if borrowed
        uint256 repayed = IApePool(apePool).borrowBalanceCurrent(userAddr);

        if(repayed > 0) {
            if(allAmount < repayed) {
                repayed -= allAmount;
                allAmount = 0;
                if(allClaimAmount < repayed) {
                    allClaimAmount = 0;
                } else {
                    allClaimAmount -= repayed;
                }
            } else {
                allAmount -= repayed;
            }
            IApePool(apePool).repayBorrowBehalf(userAddr, totalAmount - (allAmount + allClaimAmount));
        }

        totalAmount = allAmount + allClaimAmount;
        if(totalAmount > 0) {
            if(actionType == RewardAction.REDEEM || actionType == RewardAction.ONREDEEM) {//only return staking amount
                // transfer left Ape to user
                _transferAsset(apeCoin, userAddr, allAmount);
                // transfer left claim Ape to feeTo
                _transferAsset(apeCoin, feeTo, allClaimAmount);
            } else {
                uint256 claimAmount = totalAmount * _userInfo[userAddr].collectRate / BASE_PERCENTS;
                _transferAsset(apeCoin, userAddr, claimAmount);
                if(totalAmount > claimAmount) {
                    uint256 mintAmount = totalAmount - claimAmount;
                    IApePool(apePool).mintBehalf(userAddr, mintAmount);
                }            
            }
        }
    }

    function _transferAsset(address token, address to, uint256 amount) internal {
        if(amount > 0) {
            IERC20Upgradeable(token).safeTransfer(to, amount);
        }
    }

    /**
     * @notice Reward reinvestment
     * @param userAddr User address
     * @param baycNfts bayc nft ids
     * @param maycNfts mayc nft ids
     * @param baycPairNfts List of bayc-bakc pair
     * @param maycPairNfts List of mayc-bakc pair
     */
    function claimAndRestake(
        address userAddr,
        uint256[] calldata baycNfts,
        uint256[] calldata maycNfts,
        IApeCoinStaking.PairNft[] calldata baycPairNfts,
        IApeCoinStaking.PairNft[] calldata maycPairNfts
    ) external nonReentrant {
        require(msg.sender == userAddr || hasRole(REINVEST_ROLE, msg.sender));
        _claimApeCoin(userAddr, BAYC_ADDR, baycNfts, baycPairNfts, RewardAction.RESTAKE);
        _claimApeCoin(userAddr, MAYC_ADDR, maycNfts, maycPairNfts, RewardAction.RESTAKE);
    }

    /**
     * @notice Suspend staking for users with high health factor
     * @param userAddr User address
     * @param nftAssets Array of NFT address
     * @param nftIds nft ids
     */
    function unstakeAndRepay(address userAddr, address[] calldata nftAssets, uint256[] calldata nftIds) external nonReentrant {
        require(nftAssets.length == nftIds.length);
        uint256 totalIncome;
        uint256 totalPay;
        (totalIncome, totalPay) = getUserHealth(userAddr);
        require(totalIncome * BASE_PERCENTS < totalPay * stakingConfiguration.liquidateRate,"income");
        for(uint256 i = 0; i < nftAssets.length; i++) {
            require(userAddr == _nftInfo[nftAssets[i]].staker[nftIds[i]],"staker");
            _onStopStake(nftAssets[i], nftIds[i], RewardAction.STOPSTAKE);
            (totalIncome, totalPay) = getUserHealth(userAddr);
            if(totalIncome * BASE_PERCENTS >= totalPay * stakingConfiguration.borrowSafeRate) {
                _transferAsset(pawnToken, msg.sender, stakingConfiguration.liquidatePawnAmount);           
                break;
            }
        }
    }

    /**
     * @notice NFT can be withdrawn after withdrawing all staked ApeCoins
     * @param baycTokenIds bayc nft ids
     * @param maycTokenIds mayc nft ids
     * @param bakcTokenIds bakc nft ids
     */
    function withdraw(
        uint256[] calldata baycTokenIds,
        uint256[] calldata maycTokenIds,
        uint256[] calldata bakcTokenIds
    ) external nonReentrant {
        address userAddr = msg.sender;
        for(uint256 i = 0; i < baycTokenIds.length; i++) {
            _withdraw(userAddr, BAYC_ADDR, baycTokenIds[i], false);
        }
        for(uint256 i = 0; i < maycTokenIds.length; i++) {
            _withdraw(userAddr, MAYC_ADDR, maycTokenIds[i], false);
        }      
        for(uint256 i = 0; i < bakcTokenIds.length; i++) {
            _withdraw(userAddr, BAKC_ADDR, bakcTokenIds[i], true);
        }
    }

    /**
     * @notice Withdraw single staked NFT
     * @param userAddr User address
     * @param nftAsset nft asset address
     * @param nftId nft id
     * @param paired Whether to pair
     */
    function _withdraw(address userAddr, address nftAsset, uint256 nftId, bool paired) internal {
        NftInfo storage nftInfo = _nftInfo[nftAsset];
        require(userAddr == nftInfo.depositor[nftId],"depositor");
        require(nftInfo.staker[nftId] == address(0),"staker");

        if(!paired) {
            (uint256 tokenId,bool isPaired) = IApeCoinStaking(apeCoinStaking).mainToBakc(nftInfo.poolId, nftId);
            if(isPaired){
                require(_nftInfo[BAKC_ADDR].staker[tokenId] == address(0),"pair");
            }
        }
        _withdrawNftFromLending(userAddr, nftAsset, nftId);
    }

    /**
     * @notice Suspend staking due to third-party reasons
     * @param caller Caller
     * @param nftAsset nft asset address
     * @param nftIds nft ids
     * @param actionType Event type
     */
    function onStopStake(address caller, address nftAsset, uint256[] calldata nftIds, RewardAction actionType) external{
        require(msg.sender == pbaycAddr || msg.sender == pmaycAddr || msg.sender == pbakcAddr);
        if(caller != address(this)) {
            for(uint i = 0; i < nftIds.length; i++) {
                _onStopStake(nftAsset, nftIds[i], actionType);
            }
        }
    }

    struct PairVars {
        address nftAsset;
        bool isPaired;
        uint256 mainTokenId;
        uint256 bakcTokenId;
    }

    /**
     * @notice Suspend staking due to third-party reasons
     * @param nftAsset nft asset address
     * @param nftId nft id
     * @param actionType Event type
     */
    function _onStopStake(address nftAsset, uint256 nftId, RewardAction actionType) private {
        NftInfo storage nftInfo = _nftInfo[nftAsset];
        IApeCoinStaking.SingleNft[] memory _nfts;
        PairVars memory pairVars;

        address userAddr = nftInfo.staker[nftId];
        if(nftAsset == BAYC_ADDR || nftAsset == MAYC_ADDR) {
            pairVars.nftAsset = nftAsset;
            pairVars.mainTokenId = nftId;
            ( , uint256 stakingAmount, ) = getStakeInfo(nftInfo.poolId, nftId);
            (pairVars.bakcTokenId, pairVars.isPaired) = IApeCoinStaking(apeCoinStaking).mainToBakc(nftInfo.poolId, nftId);
            
            if(stakingAmount > 0 && userAddr != address(0)) {
                _nfts = new IApeCoinStaking.SingleNft[](1);
                _nfts[0] = IApeCoinStaking.SingleNft({
                    tokenId: uint32(nftId),
                    amount: uint224(stakingAmount)
                });
            }
        } else if(nftAsset == BAKC_ADDR) {
            pairVars.nftAsset = BAYC_ADDR;
            pairVars.bakcTokenId = nftId;
            (pairVars.mainTokenId, pairVars.isPaired) = IApeCoinStaking(apeCoinStaking).bakcToMain(nftId, _nftInfo[pairVars.nftAsset].poolId);
            if(!pairVars.isPaired) {
                pairVars.nftAsset = MAYC_ADDR;
                (pairVars.mainTokenId, pairVars.isPaired) = IApeCoinStaking(apeCoinStaking).bakcToMain(nftId, _nftInfo[pairVars.nftAsset].poolId);
            }
        }
        
        _onStopStakePairNft(userAddr, pairVars, _nfts, actionType);
    }

    function _onStopStakePairNft(address mainUserAddr, PairVars memory pairVars, IApeCoinStaking.SingleNft[] memory _nfts, RewardAction actionType) internal {
        IApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs;
        address bakcUserAddr = _nftInfo[BAKC_ADDR].staker[pairVars.bakcTokenId];
        if(pairVars.isPaired) {
            ( , uint256 stakingAmount, ) = getStakeInfo(_nftInfo[BAKC_ADDR].poolId, pairVars.bakcTokenId);
            if(stakingAmount > 0 && bakcUserAddr != address(0)) {
                _nftPairs = new IApeCoinStaking.PairNftWithdrawWithAmount[](1);
                _nftPairs[0] = IApeCoinStaking.PairNftWithdrawWithAmount({
                    mainTokenId: uint32(pairVars.mainTokenId),
                    bakcTokenId: uint32(pairVars.bakcTokenId),
                    amount: uint184(stakingAmount),
                    isUncommit: true
                });
            }
            
        }
        if(_nfts.length > 0 || _nftPairs.length > 0) {
            address userAddr = mainUserAddr != address(0) ? mainUserAddr : bakcUserAddr;
            _withdrawApeCoin(userAddr, pairVars.nftAsset, _nfts, _nftPairs, actionType);
        }
    }

    /**
     * @notice Set collect rate
     * @param newCollectRate Collect rate
     */
    function setCollectRate(uint256 newCollectRate) external {
        require(newCollectRate <= BASE_PERCENTS);
        _userInfo[msg.sender].collectRate = newCollectRate;
        emit SetCollectRate(msg.sender, newCollectRate);
    }

    /**
     * @notice Set fee address
     * @param newFeeTo Fee address
     */
    function setFeeTo(address newFeeTo) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeTo = newFeeTo;
    }

    /**
     * @notice Set contract configuration info
     * @param newStakingConfiguration New configuration info
     */
    function setStakingConfiguration(StakingConfiguration memory newStakingConfiguration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingConfiguration = newStakingConfiguration;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

/**
 * @title Pawnfi's ApeStakingStorage Contract
 * @author Pawnfi
 */
abstract contract ApeStakingStorage {
    uint256 internal constant BASE_PERCENTS = 1e18;
    uint256 internal constant BLOCKS_PER_YEAR = 2102400;
    uint256 internal constant APECOIN_POOL_ID = 0;
    uint256 internal constant BAYC_POOL_ID = 1;
    uint256 internal constant MAYC_POOL_ID = 2;
    uint256 internal constant BAKC_POOL_ID = 3;

    address internal constant BAYC_ADDR = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address internal constant MAYC_ADDR = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address internal constant BAKC_ADDR = 0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623;

    // keccak256("REINVEST_ROLE")
    bytes32 internal constant REINVEST_ROLE = 0xd93ff0403c1db5bd4fbb77a795131f2a70890eb98caff8a0284dcba25677aeb2;

    /// @notice ApeCoinStaking address
    address public apeCoinStaking;

    /// @notice ApeCoin address
    address public apeCoin;

    /// @notice ApePool address
    address public apePool;

    /// @notice nftGateway address
    address public nftGateway;

    /// @notice PawnToken address
    address public pawnToken;

    /// @notice P-BAYC address
    address public pbaycAddr;

    /// @notice P-MAYC address
    address public pmaycAddr;

    /// @notice P-BAKC address
    address public pbakcAddr;

    /// @notice Fee address
    address public feeTo;

    /**
     * @notice Contract configuration info
     * @member addMinStakingRate Staking rate threshold
     * @member liquidateRate Safety threshold
     * @member borrowSafeRate Suspension rate
     * @member liquidatePawnAmount PAWN reward for triggering suspension
     * @member feeRate Reinvestment fee
     */
    struct StakingConfiguration {
        uint256 addMinStakingRate;
        uint256 liquidateRate;
        uint256 borrowSafeRate;
        uint256 liquidatePawnAmount;
        uint256 feeRate;
    }

    /// @notice Get contract configuration info
    StakingConfiguration public stakingConfiguration;

    /**
     * @notice User info
     * @member collectRate Collect rate
     * @member stakeAmount APE staked amount in each pool
     * @member iTokenAmount Amount of iToken received upon deposit in each pool
     * @member stakeIds NFT IDs in each staking pool
     * @member depositIds NFT IDs deposited in each pool
     */
    struct UserInfo {
        uint256 collectRate;

        mapping(uint256 => uint256) stakeAmount;

        mapping(uint256 => uint256) iTokenAmount;

        mapping(uint256 => EnumerableSetUpgradeable.UintSet) stakeIds;

        mapping(uint256 => EnumerableSetUpgradeable.UintSet) depositIds;
    }

    // Store user information.
    mapping(address => UserInfo) internal _userInfo;

    /**
     * @notice Nft info 
     * @member poolId Pool id
     * @member stakeIds All staked NFT IDs
     * @member staker nft id Corresponding staker
     * @member depositor nft id Corresponding supplier
     * @member iTokenAmount nft id Corresponding iToken amount
     */
    struct NftInfo {
        uint256 poolId;

        EnumerableSetUpgradeable.UintSet stakeIds;

        mapping(uint256 => address) staker;

        mapping(uint256 => address) depositor;

        mapping(uint256 => uint256) iTokenAmount;        
    }

    // Store NFT info
    mapping(address => NftInfo) internal _nftInfo;

    struct StakingInfo {
        address nftAsset;
        uint256 cashAmount;
        uint256 borrowAmount;
    }

    struct DepositInfo {
        uint256[] mainTokenIds;
        uint256[] bakcTokenIds;
    }
    
    enum RewardAction {
        CLAIM, // User claims reward
        WITHDRAW, // User withdraws staked principal (user remains OWNER)
        REDEEM,// After consignment or leverage default, user is no longer OWNER; when user actively withdraws staked principal to stop staking, unclaimed rewards are not returned
        RESTAKE,// Reinvest
        STOPSTAKE,// Health factor issue, suspend staking
        ONWITHDRAW,// NFT's OWNER changes, terminate user staking (consignment/leverage redemption, purchase during consignment, withdrawal from lending market, NFT liquidation)
        ONREDEEM // After consignment or leverage default, user is no longer OWNER, acquired by others, only returning staked principal
    }

    event DepositNftToStake(address userAddr, address nftAsset, uint256[] nftIds, uint256 iTokenAmount, uint256 ptokenAmount);
    event WithdrawNftFromStake(address userAddr, address nftAsset, uint256 nftId, uint256 iTokenAmount, uint256 ptokenAmount);

    event StakeSingleNft(address userAddr, address nftAsset, uint256 nftId, uint256 amount);
    event UnstakeSingleNft(address userAddr, address nftAsset, uint256 nftId, uint256 amount, uint256 rewardAmount);
    event ClaimSingleNft(address userAddr, address nftAsset, uint256 nftId, uint256 rewardAmount);

    event StakePairNft(address userAddr, address nftAsset, uint256 mainTokenId, uint256 bakcTokenId, uint256 amount);
    event UnstakePairNft(address userAddr, address nftAsset, uint256 mainTokenId, uint256 bakcTokenId, uint256 amount, uint256 rewardAmount);
    event ClaimPairNft(address userAddr, address nftAsset, uint256 mainTokenId, uint256 bakcTokenId, uint256 rewardAmount);
    
    event SetCollectRate(address userAddr, uint256 collectRate);
 }

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface IApeCoinStaking {
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }

    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    /// @dev Per address amount and reward tracking
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
        /// @notice State for ApeCoin, BAYC, MAYC, and Pair Pools
    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }
    function addressPosition(address)
        external
        view
        returns (uint256 stakedAmount, int256 rewardsDebt);

    function apeCoin() external view returns (address);

    function bakcToMain(uint256, uint256)
        external
        view
        returns (uint248 tokenId, bool isPaired);

    function claimApeCoin(address _recipient) external;

    function claimBAKC(
        PairNft[] memory _baycPairs,
        PairNft[] memory _maycPairs,
        address _recipient
    ) external;

    function claimBAYC(uint256[] memory _nfts, address _recipient) external;

    function claimMAYC(uint256[] memory _nfts, address _recipient) external;

    function claimSelfApeCoin() external;

    function claimSelfBAKC(
        PairNft[] memory _baycPairs,
        PairNft[] memory _maycPairs
    ) external;

    function claimSelfBAYC(uint256[] memory _nfts) external;

    function claimSelfMAYC(uint256[] memory _nfts) external;

    function depositApeCoin(uint256 _amount, address _recipient) external;

    function depositBAKC(
        PairNftDepositWithAmount[] memory _baycPairs,
        PairNftDepositWithAmount[] memory _maycPairs
    ) external;

    function depositBAYC(SingleNft[] memory _nfts) external;

    function depositMAYC(SingleNft[] memory _nfts) external;

    function depositSelfApeCoin(uint256 _amount) external;

    function getAllStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getApeCoinStake(address _address)
        external
        view
        returns (DashboardStake memory);

    function getBakcStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getBaycStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getMaycStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getPoolsUI()
        external
        view
        returns (
            PoolUI memory,
            PoolUI memory,
            PoolUI memory,
            PoolUI memory
        );

    function getSplitStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getTimeRangeBy(uint256 _poolId, uint256 _index)
        external
        view
        returns (TimeRange memory);

    function mainToBakc(uint256, uint256)
        external
        view
        returns (uint248 tokenId, bool isPaired);

    function nftContracts(uint256) external view returns (address);

    function nftPosition(uint256, uint256)
        external
        view
        returns (uint256 stakedAmount, int256 rewardsDebt);

    function pendingRewards(
        uint256 _poolId,
        address _address,
        uint256 _tokenId
    ) external view returns (uint256);

    function pools(uint256)
        external
        view
        returns (
            uint48 lastRewardedTimestampHour,
            uint16 lastRewardsRangeIndex,
            uint96 stakedAmount,
            uint96 accumulatedRewardsPerShare
        );

    function removeLastTimeRange(uint256 _poolId) external;

    function renounceOwnership() external;

    function rewardsBy(
        uint256 _poolId,
        uint256 _from,
        uint256 _to
    ) external view returns (uint256, uint256);

    function stakedTotal(address _address) external view returns (uint256);

    function updatePool(uint256 _poolId) external;

    function withdrawApeCoin(uint256 _amount, address _recipient) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] memory _baycPairs,
        PairNftWithdrawWithAmount[] memory _maycPairs
    ) external;

    function withdrawBAYC(
        SingleNft[] memory _nfts,
        address _recipient
    ) external;

    function withdrawMAYC(
        SingleNft[] memory _nfts,
        address _recipient
    ) external;

    function withdrawSelfApeCoin(uint256 _amount) external;

    function withdrawSelfBAYC(SingleNft[] memory _nfts) external;

    function withdrawSelfMAYC(SingleNft[] memory _nfts) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface IApePool {

    function _setApeStaking(address newApeStaking) external returns (uint256);

    function _setInterestRateModel(address newInterestRateModel)
        external
        returns (uint256);

    function _setReinvestmentFee(uint256 newReinvestmentFee)
        external
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function apeCoinStaking() external view returns (address);

    function apeStaking() external view returns (address);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowBehalf(address borrower, uint256 borrowAmount)
        external
        returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function decimals() external view returns (uint8);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);

    function getPendingRewards() external view returns (uint256, uint256);

    function getRewardRatePerBlock() external view returns (uint256);

    function harvest() external returns (uint256);

    function interestRateModel() external view returns (address);

    function mint(uint256 mintAmount) external returns (uint256);

    function mintBehalf(address minter, uint256 mintAmount)
        external
        returns (uint256);

    function owner() external view returns (address);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function reinvestmentFee() external view returns (uint256);

    function renounceOwnership() external;

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function sweepToken(address token) external;

    function totalBorrows() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function transferOwnership(address newOwner) external;

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface INftGateway {
    function mintNft(address, uint[] calldata) external;
    function redeemNft(address, uint[] calldata) external;
    function marketInfo(address) external view returns(address, address, uint, uint, bool);
    function nftOwner(address, address,uint256) external view returns(address);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "../interfaces/IApeCoinStaking.sol";

interface IPToken {

    /*** User Interface ***/
    function factory() external view returns(address);
    function nftAddress() external view returns(address);
    function pieceCount() external view returns(uint256);
    function DOMAIN_SEPARATOR() external view returns(bytes32);
    function nonces(address) external view returns(uint256);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function randomTrade(uint256 nftIdCount) external returns(uint256[] memory nftIds);
    function specificTrade(uint256[] memory nftIds) external;
    function deposit(uint256[] memory nftIds) external returns(uint256 tokenAmount);
    function deposit(uint256[] memory nftIds, uint256 blockNumber) external returns(uint256 tokenAmount);
    function withdraw(uint256[] memory nftIds) external returns(uint256 tokenAmount);
    function convert(uint256[] memory nftIds) external;
    function getRandNftCount() external view returns(uint256);
    function getRandNft(uint256 _tokenIndex) external view returns (uint256);
}

interface IPTokenApeStaking is IPToken {
    function depositApeCoin(uint256, IApeCoinStaking.SingleNft[] calldata) external;
    function withdrawApeCoin(IApeCoinStaking.SingleNft[] calldata, address) external;
    function claimApeCoin(uint256[] calldata, address) external;
    function depositBAKC(uint256, IApeCoinStaking.PairNftDepositWithAmount[] calldata) external;
    function withdrawBAKC(IApeCoinStaking.PairNftWithdrawWithAmount[] calldata, address) external;
    function claimBAKC(IApeCoinStaking.PairNft[] calldata, address) external;
    function getNftOwner(uint256) external view returns(address);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface ITokenLending {
    function exchangeRateCurrent() external returns (uint);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
}