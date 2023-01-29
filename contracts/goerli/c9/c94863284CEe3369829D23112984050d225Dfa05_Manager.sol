// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _txOrigin() internal view returns (address payable) {
        return tx.origin;
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

interface IERC20Mint {
    function mint(address account, uint256 reward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IERC721MintAndBurn {
    function burn(uint256 tokenId) external;

    function mint(address to, uint256 tokenId) external;
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }
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

interface IManagerGovernedProxy {
    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IManagerStorage {
    // View

    function getOperatorAddress() external view returns (address _operatorAddress);

    function getFactoryProxyAddress() external view returns (address _factoryProxyAddress);

    function getAllFarmingStoragesCount() external view returns (uint256 _count);

    function getFarmingStorage(address _farmingProxy)
        external
        view
        returns (address _farmingStorage);

    function getFarmingStorageByIndex(uint256 _index)
        external
        view
        returns (address _farmingStorage);

    function getFarmingProxyByIndex(uint256 _index) external view returns (address _farmingProxy);

    function getAllFarmingProxiesCount() external view returns (uint256 _count);

    // Mutative

    function setFarmingStorage(address _farmingProxy, address _farmingStorage) external;

    function setOperatorAddress(address _operatorAddress) external;

    function setFactoryProxyAddress(address _factoryProxyAddress) external;

    function pushFarmingProxy(address _farmingProxy) external;

    function popFarmingProxy() external;

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxy) external;

    function pushFarmingStorage(address _farmingStorage) external;

    function popFarmingStorage() external;

    function setFarmingStorageByIndex(uint256 _index, address _farmingStorage) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';
import { Pausable } from '../Pausable.sol';
import { StorageBase } from '../StorageBase.sol';
import { ManagerAutoProxy } from './ManagerAutoProxy.sol';

import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IFarmingProxy } from '../farmingProxy/IFarmingProxy.sol';
import { IFarmingStorage } from '../farmingStorage/IFarmingStorage.sol';
import { IManagerGovernedProxy } from './IManagerGovernedProxy.sol';
import { IManagerStorage } from './IManagerStorage.sol';
import { IManager } from './IManager.sol';
import { IERC20Mint } from '../interfaces/IERC20Mint.sol';
import { IERC721MintAndBurn } from '../interfaces/IERC721MintAndBurn.sol';

import { Math } from '../libraries/Math.sol';
import { SafeMath } from '../libraries/SafeMath.sol';

contract ManagerStorage is StorageBase, IManagerStorage {
    // Address of the factory contract
    address private factoryProxyAddress;
    // Address of operator
    address private operatorAddress;
    // The farmingProxy at index x in the array allFarmingProxies
    // belongs to the farmingStorage at index x in the array allFarmingStorages
    address[] private allFarmingProxies;
    address[] private allFarmingStorages;
    // FarmingProxy => FarmingStorage
    mapping(address => address) private farmingStorage;

    constructor(address _factoryProxyAddress, address _operatorAddress) public {
        factoryProxyAddress = _factoryProxyAddress;
        operatorAddress = _operatorAddress;
    }

    function getOperatorAddress() external view returns (address _operatorAddress) {
        _operatorAddress = operatorAddress;
    }

    function getFactoryProxyAddress() external view returns (address _factoryProxyAddress) {
        _factoryProxyAddress = factoryProxyAddress;
    }

    function getFarmingStorage(address _farmingProxy)
        external
        view
        returns (address _farmingStorage)
    {
        _farmingStorage = farmingStorage[_farmingProxy];
    }

    function getFarmingStorageByIndex(uint256 _index)
        external
        view
        returns (address _farmingStorage)
    {
        _farmingStorage = allFarmingStorages[_index];
    }

    function getFarmingProxyByIndex(uint256 _index) external view returns (address _farmingProxy) {
        _farmingProxy = allFarmingProxies[_index];
    }

    function getAllFarmingProxiesCount() external view returns (uint256 _count) {
        _count = allFarmingProxies.length;
    }

    function getAllFarmingStoragesCount() external view returns (uint256 _count) {
        _count = allFarmingStorages.length;
    }

    function setFarmingStorage(address _farmingProxy, address _farmingStorage)
        external
        requireOwner
    {
        farmingStorage[_farmingProxy] = _farmingStorage;
    }

    function setOperatorAddress(address _operatorAddress) external requireOwner {
        operatorAddress = _operatorAddress;
    }

    function setFactoryProxyAddress(address _factoryProxyAddress) external requireOwner {
        factoryProxyAddress = _factoryProxyAddress;
    }

    function pushFarmingProxy(address _farmingProxy) external requireOwner {
        allFarmingProxies.push(_farmingProxy);
    }

    function popFarmingProxy() external requireOwner {
        allFarmingProxies.pop();
    }

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxy) external requireOwner {
        allFarmingProxies[_index] = _farmingProxy;
    }

    function pushFarmingStorage(address _farmingStorage) external requireOwner {
        allFarmingStorages.push(_farmingStorage);
    }

    function popFarmingStorage() external requireOwner {
        allFarmingStorages.pop();
    }

    function setFarmingStorageByIndex(uint256 _index, address _farmingStorage)
        external
        requireOwner
    {
        allFarmingStorages[_index] = _farmingStorage;
    }
}

contract Manager is Pausable, NonReentrant, ManagerAutoProxy, IManager {
    using SafeMath for uint256;

    ManagerStorage public _storage;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _proxy,
        address _factoryProxyAddress,
        address _operatorAddress,
        address _owner
    ) public Pausable(_owner) ManagerAutoProxy(_proxy, address(this)) {
        _storage = new ManagerStorage(_factoryProxyAddress, _operatorAddress);
    }

    /* ========== MODIFIERS ========== */

    modifier requireFarmingProxy() {
        require(
            _storage.getFarmingStorage(msg.sender) != address(0),
            'FORBIDDEN, not a farming proxy'
        );
        _;
    }

    modifier requireNotProxyOrFarmingProxy() {
        require(
            _storage.getFarmingStorage(msg.sender) == address(0),
            'FORBIDDEN, call directly not through farming proxy'
        );
        require(msg.sender != proxy, 'Calls via manager proxy forbidden');
        _;
    }

    modifier onlyFactoryImplementation() {
        require(
            msg.sender ==
                address(
                    IGovernedProxy_New(address(uint160(_storage.getFactoryProxyAddress())))
                        .implementation()
                ),
            'Not factory implementation!'
        );
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner || msg.sender == _storage.getOperatorAddress(),
            'Not owner or operator!'
        );
        _;
    }

    /* ========== GOVERNANCE FUNCTIONS ========== */

    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IManagerGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new contract implementation
    function destroy(IGovernedContract _newImplementation) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImplementation));
        // Self destruct
        _destroy(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImplementation) external requireProxy {
        _migrate(_oldImplementation);
    }

    /* ========== VIEWS ========== */

    // A smart contract can not call through the fallback function of a token contract with the Energi proxy-implementation pattern. We need to call the token implementation directly.
    function getImplementation(address token) private view returns (address) {
        return address(IGovernedProxy_New(address(uint160(token))).implementation());
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // This function is called by the factory implementation at a new farming pool creation.
    // It registers a new FarmingProxy address, and FarmingStorage address in this manager contract.
    function registerPool(address _farmingProxy, address _farmingStorage)
        external
        whenNotPaused
        onlyFactoryImplementation
    {
        _storage.setFarmingStorage(_farmingProxy, _farmingStorage);
        _storage.pushFarmingStorage(_farmingStorage);
        _storage.pushFarmingProxy(_farmingProxy);
    }

    // This function includes the logic to stake NFTs in a farming pool.
    function _stake(
        address farmingProxy,
        uint256 tokenId,
        address account
    ) private noReentry whenNotPaused {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        require(
            farmingStorage.getIsStaked(account, tokenId) == false,
            'Manager: NFT aleady staked'
        );

        require(
            farmingStorage.getStakedTokenIdsCount(account) <
                farmingStorage.getMaxStakedTokenIdsCount(),
            'Manager: MaxStakedTokenIdsCount reached'
        );

        farmingStorage.setStakedTokenAmount(farmingStorage.getStakedTokenAmount().add(1));

        farmingStorage.setBalance(account, farmingStorage.getBalance(account).add(1));

        farmingStorage.pushStakedTokenId(account, tokenId);

        uint256 reward = farmingStorage.getOwedRewards(account) +
            farmingStorage.getPayoutPerNftStaked();
        farmingStorage.setOwedRewards(account, reward);

        farmingStorage.setIsStaked(account, tokenId, true);
        farmingStorage.setLockTime(account, tokenId, block.timestamp);

        IFarmingProxy(farmingProxy).transferFrom(
            farmingStorage.getNftAddress(),
            account,
            farmingProxy,
            tokenId
        );

        IERC721MintAndBurn(getImplementation(farmingStorage.getStakedNftProxyAddress())).mint(
            account,
            tokenId
        );

        IFarmingProxy(farmingProxy).emitStaked(account, tokenId, block.timestamp);
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function stake(uint256 tokenId) external requireFarmingProxy {
        _stake(msg.sender, tokenId, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function stake(address farmingProxy, uint256 tokenId) external requireNotProxyOrFarmingProxy {
        _stake(farmingProxy, tokenId, msg.sender);
    }

    // This batch function can be called by a smart contract as well as
    // an externally owned address.
    function stakeBatch(address[] calldata farmingProxies, uint256[] calldata tokenIds)
        external
        requireNotProxyOrFarmingProxy
    {
        require(farmingProxies.length == tokenIds.length, 'Error in lengths of arrays');
        for (uint256 i = 0; i < farmingProxies.length; i++) {
            _stake(farmingProxies[i], tokenIds[i], msg.sender);
        }
    }

    // This function includes the logic to withdraw NFTs from a farming pool.
    // It only withdraws the NFT if `checkIfUnlocked` is false or the NFT is already unlocked.
    function _withdraw(
        address farmingProxy,
        uint256 tokenId,
        address account,
        bool checkIfUnlocked
    ) private noReentry whenNotPaused {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        require(farmingStorage.getIsStaked(account, tokenId) == true, 'Manager: NFT not staked');

        uint256 lockingPeriodInSeconds = farmingStorage.getLockingPeriodInSeconds();

        uint256 lockTime = block.timestamp - lockingPeriodInSeconds;

        // Only withdraw NFT if `checkIfUnlocked` is false or the NFT is already unlocked.
        if (checkIfUnlocked == false || farmingStorage.getLockTime(account, tokenId) <= lockTime) {
            farmingStorage.setIsStaked(account, tokenId, false);
            farmingStorage.setStakedTokenAmount(farmingStorage.getStakedTokenAmount().sub(1));
            farmingStorage.setBalance(account, farmingStorage.getBalance(account).sub(1));

            uint256 stakedTokenIdsCount = farmingStorage.getStakedTokenIdsCount(account);

            // Replace the tokenId at index i with the tokenId at the last index and then pop the tokenId at the last index
            for (uint256 i = 0; i < stakedTokenIdsCount - 1; i++) {
                if (farmingStorage.getStakedTokenIdByIndex(account, i) == tokenId) {
                    farmingStorage.setStakedTokenIdByIndex(
                        account,
                        i,
                        farmingStorage.getStakedTokenIdByIndex(account, stakedTokenIdsCount - 1)
                    );
                }
            }

            farmingStorage.popStakedTokenId(account);

            IFarmingProxy(farmingProxy).transferFrom(
                farmingStorage.getNftAddress(),
                farmingProxy,
                account,
                tokenId
            );

            IERC721MintAndBurn(getImplementation(farmingStorage.getStakedNftProxyAddress())).burn(
                tokenId
            );

            IFarmingProxy(farmingProxy).emitWithdrawn(account, tokenId);
        }
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function withdrawIfUnlocked(uint256 tokenId) external requireFarmingProxy {
        _withdraw(msg.sender, tokenId, tx.origin, true);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function withdrawIfUnlocked(address farmingProxy, uint256 tokenId)
        external
        requireNotProxyOrFarmingProxy
    {
        _withdraw(farmingProxy, tokenId, msg.sender, true);
    }

    // This batch function can be called by a smart contract as well as
    // an externally owned address.
    function withdrawIfUnlockedBatch(address[] calldata farmingProxies, uint256[] calldata tokenIds)
        external
        requireNotProxyOrFarmingProxy
    {
        require(farmingProxies.length == tokenIds.length, 'Error in lengths of arrays');
        for (uint256 i = 0; i < farmingProxies.length; i++) {
            _withdraw(farmingProxies[i], tokenIds[i], msg.sender, true);
        }
    }

    // This function includes the logic to withdraw all its unlocked NFTs from that farming pool.
    function _withdrawAllUnlocked(address farmingProxy, address account) private {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        uint256[] memory stakedTokenIdsArray = farmingStorage.getStakedTokenIdsArray(account);

        for (uint256 i = 0; i < stakedTokenIdsArray.length; i++) {
            _withdraw(farmingProxy, stakedTokenIdsArray[i], account, true);
        }
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function withdrawAllUnlocked() external requireFarmingProxy {
        _withdrawAllUnlocked(msg.sender, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function withdrawAllUnlocked(address farmingProxy) external requireNotProxyOrFarmingProxy {
        _withdrawAllUnlocked(farmingProxy, msg.sender);
    }

    // This batch function can be called by a smart contract as well as
    // an externally owned address.
    function withdrawAllUnlockedBatch(address[] calldata farmingProxies)
        external
        requireNotProxyOrFarmingProxy
    {
        for (uint256 i = 0; i < farmingProxies.length; i++) {
            _withdrawAllUnlocked(farmingProxies[i], msg.sender);
        }
    }

    // This function includes the logic to claim rewards from a farming pool.
    function _claim(address farmingProxy, address account) private noReentry whenNotPaused {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        uint256 reward = farmingStorage.getOwedRewards(account);

        if (reward > 0) {
            farmingStorage.setOwedRewards(account, 0);

            IERC20Mint(getImplementation(farmingStorage.getRewardTokenProxyAddress())).mint(
                account,
                reward
            );

            IFarmingProxy(farmingProxy).emitRewardPaid(account, reward);
        }
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function claim() external requireFarmingProxy {
        _claim(msg.sender, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function claim(address farmingProxy) external requireNotProxyOrFarmingProxy {
        _claim(farmingProxy, msg.sender);
    }

    // This batch function can be called by a smart contract as well as
    // an externally owned address.
    function claimBatch(address[] calldata farmingProxies) external requireNotProxyOrFarmingProxy {
        for (uint256 i = 0; i < farmingProxies.length; i++) {
            _claim(farmingProxies[i], msg.sender);
        }
    }

    // This function includes the logic to claim rewards from a farming pool
    // and withdraw the NFT from that farming pool if it is unlocked.
    function _exitIfUnlocked(
        address farmingProxy,
        uint256 tokenId,
        address account
    ) private {
        _withdraw(farmingProxy, tokenId, account, true);

        _claim(farmingProxy, account);
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function exitIfUnlocked(uint256 tokenId) external requireFarmingProxy {
        _exitIfUnlocked(msg.sender, tokenId, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function exitIfUnlocked(address farmingProxy, uint256 tokenId)
        external
        requireNotProxyOrFarmingProxy
    {
        _exitIfUnlocked(farmingProxy, tokenId, msg.sender);
    }

    // This batch function can be called by a smart contract as well as
    // an externally owned address.
    function exitIfUnlockedBatch(address[] calldata farmingProxies, uint256[] calldata tokenIds)
        external
        requireNotProxyOrFarmingProxy
    {
        require(farmingProxies.length == tokenIds.length, 'Error in lengths of arrays');
        for (uint256 i = 0; i < farmingProxies.length; i++) {
            _exitIfUnlocked(farmingProxies[i], tokenIds[i], msg.sender);
        }
    }

    // This function includes the logic to claim rewards from a farming pool
    // and withdraw all its unlocked NFTs from that farming pool.
    function _exitAllUnlocked(address farmingProxy, address account) private {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        uint256[] memory stakedTokenIdsArray = farmingStorage.getStakedTokenIdsArray(account);

        for (uint256 i = 0; i < stakedTokenIdsArray.length; i++) {
            _withdraw(farmingProxy, stakedTokenIdsArray[i], account, true);
        }

        _claim(farmingProxy, account);
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function exitAllUnlocked() external requireFarmingProxy {
        _exitAllUnlocked(msg.sender, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function exitAllUnlocked(address farmingProxy) external requireNotProxyOrFarmingProxy {
        _exitAllUnlocked(farmingProxy, msg.sender);
    }

    // This batch function can be called by a smart contract as well as
    // an externally owned address.
    function exitAllUnlockedBatch(address[] calldata farmingProxies)
        external
        requireNotProxyOrFarmingProxy
    {
        for (uint256 i = 0; i < farmingProxies.length; i++) {
            _exitAllUnlocked(farmingProxies[i], msg.sender);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // This function can be used to return NFTs to stakers. If `checkIfUnlocked` variable is true the
    // function execution will only succeed if the stakers have already enough unlocked NFTs.
    function returnNFTsInBatches(
        address farmingProxy,
        address[] calldata stakerAccounts,
        uint256[] calldata tokenIds,
        bool checkIfUnlocked
    ) external onlyOwnerOrOperator {
        require(
            stakerAccounts.length > 0 && stakerAccounts.length == tokenIds.length,
            'Error in lengths of arrays'
        );

        for (uint256 i = 0; i < stakerAccounts.length; i++) {
            _withdraw(farmingProxy, tokenIds[i], stakerAccounts[i], checkIfUnlocked);
        }
    }

    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        _storage.setOperatorAddress(_newOperatorAddress);
    }

    function setLockingPeriodInSeconds(address farmingProxy, uint256 lockingPeriod)
        external
        onlyOwner
    {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        farmingStorage.setLockingPeriodInSeconds(lockingPeriod);

        IFarmingProxy(farmingProxy).emitLockingPeriodUpdate(lockingPeriod);
    }

    function setMaxStakedTokenIdsCount(address farmingProxy, uint256 maxStakedTokenIdsCount)
        external
        onlyOwner
    {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        farmingStorage.setMaxStakedTokenIdsCount(maxStakedTokenIdsCount);
    }

    /* ========== GETTER FUNCTIONS ========== */

    function getBalance(address farmingProxy, address account) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getBalance(account);
    }

    function getOperatorAddress() external view returns (address) {
        return _storage.getOperatorAddress();
    }

    function getFarmingStorage(address farmingProxy) external view returns (address) {
        return _storage.getFarmingStorage(farmingProxy);
    }

    function getFarmingProxyByIndex(uint256 index) external view returns (address) {
        return _storage.getFarmingProxyByIndex(index);
    }

    function getAllFarmingProxiesCount() external view returns (uint256) {
        return _storage.getAllFarmingProxiesCount();
    }

    // Expose FarmingStorage getter functions

    function getLockingPeriodInSeconds(address farmingProxy) external view returns (uint256) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        return farmingStorage.getLockingPeriodInSeconds();
    }

    function getOwedRewards(address farmingProxy, address staker) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getOwedRewards(staker);
    }

    function getPayoutPerNftStaked(address farmingProxy) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getPayoutPerNftStaked();
    }

    function getNftAddress(address farmingProxy) external view returns (address) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getNftAddress();
    }

    function getStakedTokenAmount(address farmingProxy) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getStakedTokenAmount();
    }
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { GovernedContract } from '../GovernedContract.sol';
import { ManagerGovernedProxy } from './ManagerGovernedProxy.sol';

/**
 * ManagerAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract ManagerAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(new ManagerGovernedProxy(_implementation));
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

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract ManagerGovernedProxy is NonReentrant, IGovernedContract, IGovernedProxy_New {
    IGovernedContract public implementation;
    IGovernedProxy_New public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'ManagerGovernedProxy: Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(implementation),
            'ManagerGovernedProxy: Only calls from implementation are allowed!'
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
        require(_newImplementation != implementation, 'ManagerGovernedProxy: Already active!');
        require(_newImplementation.proxy() == address(this), 'ManagerGovernedProxy: Wrong proxy!');

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
        require(newImplementation != implementation, 'ManagerGovernedProxy: Already active!');
        // in case it changes in the flight
        require(address(newImplementation) != address(0), 'ManagerGovernedProxy: Not registered!');
        require(_proposal.isAccepted(), 'ManagerGovernedProxy: Not accepted!');

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
        require(address(newImplementation) != address(0), 'ManagerGovernedProxy: Not registered!');
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
        revert('ManagerGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('ManagerGovernedProxy: Good try');
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
                'ManagerGovernedProxy: delegatecall cannot be used'
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

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';
import { SafeMath } from './libraries/SafeMath.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    constructor(address _owner) public Ownable(_owner) {}

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number.add(blocks);
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
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