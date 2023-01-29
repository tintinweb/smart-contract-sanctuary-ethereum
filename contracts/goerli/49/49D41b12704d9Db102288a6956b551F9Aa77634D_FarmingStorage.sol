// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedProxy_New } from './../interfaces/IGovernedProxy_New.sol';
import { IFarmingStorage } from './IFarmingStorage.sol';

contract FarmingStorage is IFarmingStorage {
    // Whenever a staker adds a new NFT to this farming pool
    // a LockingParcel is created which tracks the lockTime
    // that this NFT was added to this farming pool.
    struct LockingParcel {
        uint256 lockTime;
        bool isStaked;
    }

    // NFT token address
    address private nftAddress;
    // When the staker stakes an NFT, an associated stakedNft will be minted to the staker from the stakedNftProxyAddress contract.
    // When the staker withdraws its NFT, its associated stakedNft will be burned from the address of the staker.
    address private stakedNftProxyAddress;
    // rewardToken proxy address
    address private rewardTokenProxyAddress;
    // Amount of reward tokens to be paid for every NFT staked
    uint256 private payoutPerNftStaked;
    // Max number of tokenIds that a staker can stake.
    // All tokenIds staked by a staker are stored in the array `stakedTokenIdsArray`.
    // We need to restrict the length of this array so we can iterate through it in the smart contract code without running out of gas.
    // The `stakedTokenIdsArrays` have up to `maxStakedTokenIdsCount` of elements.
    uint256 private maxStakedTokenIdsCount = 20;
    // ManagerProxy address
    address private managerProxyAddress;
    // Amount of NFT tokens staked in this farming pool
    uint256 private stakedTokenAmount;
    // NFTs in this farming pool will be locked for some amount of time before they can be withdrawn.
    uint256 private lockingPeriodInSeconds;

    // stakerAddress => [stakedTokenIdsArray]
    mapping(address => uint256[]) private stakedTokenIdsArray;

    // The `lockingParcels` store if a specific tokenId is staked by the stakerAddress
    // and the timestamp (lockTime) when the lockingParcel was staked.
    // stakerAddress => tokenId  => LockingParcel
    mapping(address => mapping(uint256 => LockingParcel)) private lockingParcels;

    // stakerAddress => owed rewards to the staker (rewards that have not been payed out to the staker yet)
    mapping(address => uint256) private owedRewards;

    // stakerAddress => amount of NFT tokens staked by the staker
    mapping(address => uint256) private balances;

    constructor(
        address _managerProxyAddress,
        address _nftAddress,
        address _stakedNftProxyAddress,
        address _rewardTokenProxyAddress,
        uint256 _payoutPerNftStaked,
        uint256 _lockingPeriodInSeconds
    ) public {
        managerProxyAddress = _managerProxyAddress;
        nftAddress = _nftAddress;
        stakedNftProxyAddress = _stakedNftProxyAddress;
        rewardTokenProxyAddress = _rewardTokenProxyAddress;
        payoutPerNftStaked = _payoutPerNftStaked;
        lockingPeriodInSeconds = _lockingPeriodInSeconds;
    }

    modifier requireManager() {
        require(
            msg.sender ==
                address(IGovernedProxy_New(address(uint160(managerProxyAddress))).implementation()),
            'FarmingStorage: FORBIDDEN, not Manager'
        );
        _;
    }

    function getLockTime(address _staker, uint256 _tokenId) external view returns (uint256) {
        return lockingParcels[_staker][_tokenId].lockTime;
    }

    function getStakedTokenIdsArray(address _staker) external view returns (uint256[] memory) {
        return stakedTokenIdsArray[_staker];
    }

    function getStakedTokenIdsCount(address _staker) external view returns (uint256) {
        return stakedTokenIdsArray[_staker].length;
    }

    function getMaxStakedTokenIdsCount() external view returns (uint256) {
        return maxStakedTokenIdsCount;
    }

    function getStakedTokenIdByIndex(address _staker, uint256 _index)
        external
        view
        returns (uint256)
    {
        return stakedTokenIdsArray[_staker][_index];
    }

    function getIsStaked(address _staker, uint256 _tokenId) external view returns (bool) {
        return lockingParcels[_staker][_tokenId].isStaked;
    }

    function getLockingParcel(address _stakerAddress, uint256 _tokenId)
        external
        view
        returns (uint256 lockTime, bool isStaked)
    {
        return (
            lockingParcels[_stakerAddress][_tokenId].lockTime,
            lockingParcels[_stakerAddress][_tokenId].isStaked
        );
    }

    function getNftAddress() external view returns (address) {
        return nftAddress;
    }

    function getStakedNftProxyAddress() external view returns (address) {
        return stakedNftProxyAddress;
    }

    function getPayoutPerNftStaked() external view returns (uint256) {
        return payoutPerNftStaked;
    }

    function getRewardTokenProxyAddress() external view returns (address) {
        return rewardTokenProxyAddress;
    }

    function getLockingPeriodInSeconds() external view returns (uint256) {
        return lockingPeriodInSeconds;
    }

    function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function getManagerProxyAddress() external view returns (address) {
        return managerProxyAddress;
    }

    function getOwedRewards(address _account) external view returns (uint256) {
        return owedRewards[_account];
    }

    function getStakedTokenAmount() external view returns (uint256) {
        return stakedTokenAmount;
    }

    function setLockTime(
        address _staker,
        uint256 _tokenId,
        uint256 _lockTime
    ) external requireManager {
        lockingParcels[_staker][_tokenId].lockTime = _lockTime;
    }

    function setIsStaked(
        address _staker,
        uint256 _tokenId,
        bool _isStaked
    ) external requireManager {
        lockingParcels[_staker][_tokenId].isStaked = _isStaked;
    }

    function setLockingParcel(
        address _staker,
        uint256 _tokenId,
        uint256 _lockTime,
        bool _isStaked
    ) external requireManager {
        lockingParcels[_staker][_tokenId].lockTime = _lockTime;
        lockingParcels[_staker][_tokenId].isStaked = _isStaked;
    }

    function setStakedTokenIdsArray(address _staker, uint256[] calldata _tokenIds)
        external
        requireManager
    {
        stakedTokenIdsArray[_staker] = _tokenIds;
    }

    function setStakedTokenIdByIndex(
        address _staker,
        uint256 _index,
        uint256 _tokenId
    ) external requireManager {
        stakedTokenIdsArray[_staker][_index] = _tokenId;
    }

    function pushStakedTokenId(address _staker, uint256 _tokenId) external requireManager {
        stakedTokenIdsArray[_staker].push(_tokenId);
    }

    function popStakedTokenId(address _staker) external requireManager {
        stakedTokenIdsArray[_staker].pop();
    }

    function setMaxStakedTokenIdsCount(uint256 _maxStakedTokenIdsCount) external requireManager {
        maxStakedTokenIdsCount = _maxStakedTokenIdsCount;
    }

    function setNftAddress(address _nftAddress) external requireManager {
        nftAddress = _nftAddress;
    }

    function setStakedNftProxyAddress(address _stakedNftProxyAddress) external requireManager {
        stakedNftProxyAddress = _stakedNftProxyAddress;
    }

    function setPayoutPerNftStaked(uint256 _payoutPerNftStaked) external requireManager {
        payoutPerNftStaked = _payoutPerNftStaked;
    }

    function setRewardTokenProxyAddress(address _rewardTokenProxyAddress) external requireManager {
        rewardTokenProxyAddress = _rewardTokenProxyAddress;
    }

    function setManagerProxyAddress(address _managerProxyAddress) external requireManager {
        managerProxyAddress = _managerProxyAddress;
    }

    function setStakedTokenAmount(uint256 _stakedTokenAmount) external requireManager {
        stakedTokenAmount = _stakedTokenAmount;
    }

    function setBalance(address _account, uint256 _balance) external requireManager {
        balances[_account] = _balance;
    }

    function setOwedRewards(address _account, uint256 _owedRewards) external requireManager {
        owedRewards[_account] = _owedRewards;
    }

    function setLockingPeriodInSeconds(uint256 _lockingPeriodInSeconds) external requireManager {
        lockingPeriodInSeconds = _lockingPeriodInSeconds;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFarmingStorage {
    // View

    function getNftAddress() external view returns (address);

    function getLockTime(address _staker, uint256 _tokenId) external view returns (uint256);

    function getIsStaked(address _staker, uint256 _tokenId) external view returns (bool);

    function getLockingParcel(address _stakerAddress, uint256 _tokenId)
        external
        view
        returns (uint256 lockTime, bool isStaked);

    function getPayoutPerNftStaked() external view returns (uint256);

    function getStakedNftProxyAddress() external view returns (address);

    function getBalance(address _account) external view returns (uint256);

    function getManagerProxyAddress() external view returns (address);

    function getOwedRewards(address _account) external view returns (uint256);

    function getLockingPeriodInSeconds() external view returns (uint256);

    function getStakedTokenAmount() external view returns (uint256);

    function getRewardTokenProxyAddress() external view returns (address);

    function getStakedTokenIdsArray(address _staker) external view returns (uint256[] memory);

    function getMaxStakedTokenIdsCount() external view returns (uint256);

    function getStakedTokenIdByIndex(address _staker, uint256 _index)
        external
        view
        returns (uint256);

    function getStakedTokenIdsCount(address _staker) external view returns (uint256);

    // Mutative

    function setStakedTokenIdsArray(address _staker, uint256[] calldata _tokenIds) external;

    function setStakedTokenIdByIndex(
        address _staker,
        uint256 _index,
        uint256 _tokenId
    ) external;

    function pushStakedTokenId(address _staker, uint256 _tokenId) external;

    function popStakedTokenId(address _staker) external;

    function setMaxStakedTokenIdsCount(uint256 _maxStakedTokenIdsCount) external;

    function setStakedTokenAmount(uint256 _stakedTokenAmount) external;

    function setRewardTokenProxyAddress(address _rewardTokenProxyAddress) external;

    function setManagerProxyAddress(address _managerProxyAddress) external;

    function setLockTime(
        address _staker,
        uint256 _tokenId,
        uint256 _lockTime
    ) external;

    function setIsStaked(
        address _staker,
        uint256 _tokenId,
        bool _isStaked
    ) external;

    function setLockingParcel(
        address _staker,
        uint256 _tokenId,
        uint256 _lockTime,
        bool _isStaked
    ) external;

    function setNftAddress(address _nftAddress) external;

    function setStakedNftProxyAddress(address _stakedNftProxyAddress) external;

    function setPayoutPerNftStaked(uint256 _payoutPerNftStaked) external;

    function setBalance(address _account, uint256 _balance) external;

    function setOwedRewards(address _account, uint256 _owedRewards) external;

    function setLockingPeriodInSeconds(uint256 _lockingPeriodInSeconds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy_New {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external view returns (IGovernedContract);

    function implementation() external view returns (IGovernedContract);

    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}