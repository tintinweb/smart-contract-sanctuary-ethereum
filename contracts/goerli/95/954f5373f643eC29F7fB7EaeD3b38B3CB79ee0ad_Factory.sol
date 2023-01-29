// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { StorageBase } from '../StorageBase.sol';
import { Ownable } from '../Ownable.sol';
import { FarmingStorage } from '../farmingStorage/FarmingStorage.sol';
import { FactoryAutoProxy } from './FactoryAutoProxy.sol';
import { FarmingProxy } from '../farmingProxy/FarmingProxy.sol';

import { IFactoryStorage } from './IFactoryStorage.sol';
import { IFactory } from './IFactory.sol';
import { IManager } from '../manager/IManager.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IFactoryGovernedProxy } from './IFactoryGovernedProxy.sol';

import { SafeMath } from '../libraries/SafeMath.sol';

contract FactoryStorage is StorageBase, IFactoryStorage {
    address private managerProxy;

    address[] private farmingProxies;

    constructor(address _managerProxy) public {
        managerProxy = _managerProxy;
    }

    function getManagerProxy() external view returns (address) {
        return managerProxy;
    }

    function getFarmingProxyByIndex(uint256 _index) external view returns (address) {
        return farmingProxies[_index];
    }

    function getFarmingProxiesCount() external view returns (uint256) {
        return farmingProxies.length;
    }

    function pushFarmingProxy(address _farmingProxyAddress) external requireOwner {
        farmingProxies.push(_farmingProxyAddress);
    }

    function popFarmingProxy() external requireOwner {
        farmingProxies.pop();
    }

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxyAddress)
        external
        requireOwner
    {
        farmingProxies[_index] = _farmingProxyAddress;
    }

    function setManagerProxy(address _managerProxy) external requireOwner {
        managerProxy = _managerProxy;
    }
}

contract Factory is Ownable, FactoryAutoProxy, IFactory {
    using SafeMath for uint256;

    FactoryStorage public _storage;

    bool public initialized = false;

    constructor(address _proxy, address _owner)
        public
        Ownable(_owner)
        FactoryAutoProxy(_proxy, address(this))
    {}

    // Initialize contract. This function can only be called once
    function initialize(address _managerProxy) external {
        require(!initialized, 'Factory: already initialized');
        _storage = new FactoryStorage(_managerProxy);
        initialized = true;
    }

    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IFactoryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new Factory implementation
    function destroy(IGovernedContract _newImplementation) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImplementation));

        // Self destruct
        _destroy(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImplementation) external requireProxy {
        _migrate(_oldImplementation);
    }

    function managerImplementation() private view returns (address _managerImplementation) {
        _managerImplementation = address(
            IGovernedProxy_New(address(uint160(_storage.getManagerProxy()))).implementation()
        );
    }

    // Deploy a new farming pool.
    function deploy(
        address nftAddress,
        address stakedNftProxyAddress,
        address rewardTokenProxyAddress,
        uint256 payoutPerNftStaked,
        uint256 lockingPeriodInSeconds
    ) external onlyOwner {
        require(initialized, 'Factory: needs to be initialized with managerProxy address');

        address farmingStorageAddress = address(
            new FarmingStorage(
                _storage.getManagerProxy(),
                nftAddress,
                stakedNftProxyAddress,
                rewardTokenProxyAddress,
                payoutPerNftStaked,
                lockingPeriodInSeconds
            )
        );

        // Deploy farmingProxy via CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(FarmingProxy).creationCode,
            abi.encode(_storage.getManagerProxy())
        );

        bytes32 salt = keccak256(abi.encode(_storage.getFarmingProxiesCount() + 1));

        address farmingProxyAddress;
        assembly {
            farmingProxyAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Register farmingProxy, and farmingStorage into manager
        IManager(managerImplementation()).registerPool(farmingProxyAddress, farmingStorageAddress);

        _storage.pushFarmingProxy(farmingProxyAddress);

        // Emit pool creation event
        IFactoryGovernedProxy(address(uint160(proxy))).emitPoolCreated(
            farmingProxyAddress,
            nftAddress,
            stakedNftProxyAddress,
            rewardTokenProxyAddress,
            _storage.getFarmingProxiesCount(),
            lockingPeriodInSeconds
        );
    }

    function getFarmingProxiesCount() external view returns (uint256) {
        return _storage.getFarmingProxiesCount();
    }

    function getFarmingProxyByIndex(uint256 _index) external view returns (address) {
        return _storage.getFarmingProxyByIndex(_index);
    }
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { GovernedContract } from '../GovernedContract.sol';
import { FactoryGovernedProxy } from './FactoryGovernedProxy.sol';

/**
 * FactoryAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract FactoryAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(new FactoryGovernedProxy(_implementation));
        }
        proxy = _proxy;
    }
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { ISporkRegistry } from '../interfaces/ISporkRegistry.sol';
import { IUpgradeProposal } from '../interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IFactoryGovernedProxy } from './IFactoryGovernedProxy.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract FactoryGovernedProxy is
    NonReentrant,
    IGovernedContract,
    IGovernedProxy_New,
    IFactoryGovernedProxy
{
    IGovernedContract public implementation;
    IGovernedProxy_New public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'FactoryGovernedProxy: Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(implementation),
            'FactoryGovernedProxy: Only calls from implementation are allowed!'
        );
        _;
    }

    constructor(address _implementation) public {
        implementation = IGovernedContract(_implementation);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy_New(_sporkProxy);
    }

    // Due to backward compatibility of old Energi proxies
    function impl() external view returns (IGovernedContract) {
        return implementation;
    }

    // Emit PoolCreated event
    function emitPoolCreated(
        address pool,
        address nftAddress,
        address stakedNftProxyAddress,
        address rewardTokenProxyAddress,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds
    ) external onlyImpl {
        emit PoolCreated(
            pool,
            nftAddress,
            stakedNftProxyAddress,
            rewardTokenProxyAddress,
            allPoolsLength,
            lockingPeriodInSeconds
        );
    }

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImplementation != implementation, 'FactoryGovernedProxy: Already active!');
        require(_newImplementation.proxy() == address(this), 'FactoryGovernedProxy: Wrong proxy!');

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImplementation,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImplementation;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImplementation, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(newImplementation != implementation, 'FactoryGovernedProxy: Already active!');
        // in case it changes in the flight
        require(address(newImplementation) != address(0), 'FactoryGovernedProxy: Not registered!');
        require(_proposal.isAccepted(), 'FactoryGovernedProxy: Not accepted!');

        IGovernedContract oldImplementation = implementation;

        newImplementation.migrate(oldImplementation);
        implementation = newImplementation;
        oldImplementation.destroy(newImplementation);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(newImplementation, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation)
    {
        newImplementation = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(address(newImplementation) != address(0), 'FactoryGovernedProxy: Not registered!');
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external {
        revert('FactoryGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('FactoryGovernedProxy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory
        IGovernedContract implementation_m = implementation;

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'FactoryGovernedProxy: delegatecall cannot be used'
            );
        }

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), implementation_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFactory {
    function deploy(
        address nftAddress,
        address stakedNftProxyAddress,
        address rewardTokenProxyAddress,
        uint256 payoutPerNftStaked,
        uint256 lockingPeriodInSeconds
    ) external;

    function getFarmingProxiesCount() external view returns (uint256);

    function getFarmingProxyByIndex(uint256 _index) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFactoryGovernedProxy {
    event PoolCreated(
        address pool,
        address nftAddress,
        address stakedNftProxyAddress,
        address rewardTokenProxyAddress,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds
    );

    function emitPoolCreated(
        address pool,
        address nftAddress,
        address stakedNftProxyAddress,
        address rewardTokenProxyAddress,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds
    ) external;

    function spork_proxy() external view returns (address);

    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFactoryStorage {
    function getFarmingProxyByIndex(uint256 _index) external view returns (address);

    function getFarmingProxiesCount() external view returns (uint256);

    function getManagerProxy() external view returns (address);

    function setManagerProxy(address _managerProxy) external;

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxyAddress) external;

    function pushFarmingProxy(address _farmingProxyAddress) external;

    function popFarmingProxy() external;
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IManager } from '../manager/IManager.sol';
import { IFarmingProxy } from './IFarmingProxy.sol';
import { IERC721 } from '../interfaces/IERC721.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract FarmingProxy is NonReentrant, IFarmingProxy {
    address public managerProxyAddress;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        require(tx.origin == msg.sender, 'FarmingProxy: FORBIDDEN, not a direct call');
        _;
    }

    modifier requireManager() {
        require(msg.sender == manager(), 'FarmingProxy: FORBIDDEN, not Manager');
        _;
    }

    constructor(address _managerProxyAddress) public {
        managerProxyAddress = _managerProxyAddress;
    }

    function manager() private view returns (address _manager) {
        _manager = address(
            IGovernedProxy_New(address(uint160(managerProxyAddress))).implementation()
        );
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external noReentry requireManager {
        IERC721(_token).transferFrom(_from, _to, _tokenId);
    }

    function emitStaked(
        address user,
        uint256 tokenId,
        uint256 lockTime
    ) external requireManager {
        emit Staked(user, tokenId, lockTime);
    }

    function emitWithdrawn(address user, uint256 tokenId) external requireManager {
        emit Withdrawn(user, tokenId);
    }

    function emitRewardPaid(address user, uint256 reward) external requireManager {
        emit RewardPaid(user, reward);
    }

    function emitLockingPeriodUpdate(uint256 lockingPeriodInSeconds) external requireManager {
        emit LockingPeriodUpdate(lockingPeriodInSeconds);
    }

    function proxy() external view returns (address) {
        return address(this);
    }

    // Proxy all other calls to Manager.
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        IManager _manager = IManager(manager());

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(sub(gas(), 10000), _manager, callvalue(), ptr, calldatasize(), 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFarmingProxy {
    event Staked(address indexed user, uint256 tokenId, uint256 lockTime);
    event Withdrawn(address indexed user, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);
    event LockingPeriodUpdate(uint256 lockingPeriodInSeconds);

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function emitStaked(
        address user,
        uint256 tokenId,
        uint256 lockTime
    ) external;

    function emitWithdrawn(address user, uint256 tokenId) external;

    function emitRewardPaid(address user, uint256 reward) external;

    function emitLockingPeriodUpdate(uint256 lockingPeriodInSeconds) external;
}

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

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract is IGovernedContract {
    address public proxy;

    constructor(address _proxy) public {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // Function overridden in child contract
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // Function overridden in child contract
    function destroy(IGovernedContract _newImpl) external requireProxy {
        _destroy(_newImpl);
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _implementation,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256 callGas, uint256 xferGas);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IManager {
    // View

    function getBalance(address farmingProxy, address account) external view returns (uint256);

    function getOwedRewards(address farmingProxy, address staker) external view returns (uint256);

    function getStakedTokenAmount(address farmingProxy) external view returns (uint256);

    function getLockingPeriodInSeconds(address farmingProxy) external view returns (uint256);

    function getFarmingStorage(address farmingProxy) external view returns (address);

    function getFarmingProxyByIndex(uint256 index) external view returns (address);

    function getAllFarmingProxiesCount() external view returns (uint256);

    function getPayoutPerNftStaked(address farmingProxy) external view returns (uint256);

    function getNftAddress(address farmingProxy) external view returns (address);

    function getOperatorAddress() external view returns (address);

    // Mutative

    function stake(uint256 tokenId) external;

    function stake(address farmingProxy, uint256 tokenId) external;

    function stakeBatch(address[] calldata farmingProxies, uint256[] calldata tokenIds) external;

    function withdrawIfUnlocked(uint256 amount) external;

    function withdrawIfUnlocked(address farmingProxy, uint256 amount) external;

    function withdrawIfUnlockedBatch(address[] calldata farmingProxies, uint256[] calldata tokenIds)
        external;

    function withdrawAllUnlocked() external;

    function withdrawAllUnlocked(address farmingProxy) external;

    function withdrawAllUnlockedBatch(address[] calldata farmingProxies) external;

    function claim() external;

    function claim(address farmingProxy) external;

    function claimBatch(address[] calldata farmingProxies) external;

    function exitIfUnlocked(uint256 tokenId) external;

    function exitIfUnlocked(address farmingProxy, uint256 tokenId) external;

    function exitIfUnlockedBatch(address[] calldata farmingProxies, uint256[] calldata tokenIds)
        external;

    function exitAllUnlocked() external;

    function exitAllUnlocked(address farmingProxy) external;

    function exitAllUnlockedBatch(address[] calldata farmingProxies) external;

    function returnNFTsInBatches(
        address farmingProxy,
        address[] calldata stakerAccounts,
        uint256[] calldata tokenIds,
        bool checkIfUnlocked
    ) external;

    function registerPool(address _farmingProxy, address _farmingStorage) external;

    function setOperatorAddress(address _newOperatorAddress) external;

    function setLockingPeriodInSeconds(address farmingProxy, uint256 lockingPeriod) external;

    function setMaxStakedTokenIdsCount(address farmingProxy, uint256 _maxStakedTokenIdsCount)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address _owner) public {
        owner = _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = address(uint160(address(_newOwner)));
    }

    function kill() external requireOwner {
        selfdestruct(msg.sender);
    }
}