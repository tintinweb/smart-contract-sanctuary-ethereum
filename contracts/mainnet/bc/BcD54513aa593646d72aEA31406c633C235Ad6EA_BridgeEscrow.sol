// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import { GraphUpgradeable } from "../upgrades/GraphUpgradeable.sol";
import { Managed } from "../governance/Managed.sol";
import { IGraphToken } from "../token/IGraphToken.sol";

/**
 * @title Bridge Escrow
 * @dev This contracts acts as a gateway for an L2 bridge (or several). It simply holds GRT and has
 * a set of spenders that can transfer the tokens; the L1 side of each L2 bridge has to be
 * approved as a spender.
 */
contract BridgeEscrow is Initializable, GraphUpgradeable, Managed {
    /**
     * @notice Initialize the BridgeEscrow contract.
     * @param _controller Address of the Controller that manages this contract
     */
    function initialize(address _controller) external onlyImpl initializer {
        Managed._initialize(_controller);
    }

    /**
     * @notice Approve a spender (i.e. a bridge that manages the GRT funds held by the escrow)
     * @param _spender Address of the spender that will be approved
     */
    function approveAll(address _spender) external onlyGovernor {
        graphToken().approve(_spender, type(uint256).max);
    }

    /**
     * @notice Revoke a spender (i.e. a bridge that will no longer manage the GRT funds held by the escrow)
     * @param _spender Address of the spender that will be revoked
     */
    function revokeAll(address _spender) external onlyGovernor {
        graphToken().approve(_spender, 0);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IGraphProxy } from "./IGraphProxy.sol";

/**
 * @title Graph Upgradeable
 * @dev This contract is intended to be inherited from upgradeable contracts.
 */
abstract contract GraphUpgradeable {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Check if the caller is the proxy admin.
     */
    modifier onlyProxyAdmin(IGraphProxy _proxy) {
        require(msg.sender == _proxy.admin(), "Caller must be the proxy admin");
        _;
    }

    /**
     * @dev Check if the caller is the implementation.
     */
    modifier onlyImpl() {
        require(msg.sender == _implementation(), "Only implementation");
        _;
    }

    /**
     * @dev Returns the current implementation.
     * @return impl Address of the current implementation
     */
    function _implementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Accept to be an implementation of proxy.
     * @param _proxy Proxy to accept
     */
    function acceptProxy(IGraphProxy _proxy) external onlyProxyAdmin(_proxy) {
        _proxy.acceptUpgrade();
    }

    /**
     * @notice Accept to be an implementation of proxy and then call a function from the new
     * implementation as specified by `_data`, which should be an encoded function call. This is
     * useful to initialize new storage variables in the proxied contract.
     * @param _proxy Proxy to accept
     * @param _data Calldata for the initialization function call (including selector)
     */
    function acceptProxyAndCall(IGraphProxy _proxy, bytes calldata _data)
        external
        onlyProxyAdmin(_proxy)
    {
        _proxy.acceptUpgradeAndCall(_data);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import { IController } from "./IController.sol";

import { ICuration } from "../curation/ICuration.sol";
import { IEpochManager } from "../epochs/IEpochManager.sol";
import { IRewardsManager } from "../rewards/IRewardsManager.sol";
import { IStaking } from "../staking/IStaking.sol";
import { IGraphToken } from "../token/IGraphToken.sol";
import { ITokenGateway } from "../arbitrum/ITokenGateway.sol";

import { IManaged } from "./IManaged.sol";

/**
 * @title Graph Managed contract
 * @dev The Managed contract provides an interface to interact with the Controller.
 * It also provides local caching for contract addresses. This mechanism relies on calling the
 * public `syncAllContracts()` function whenever a contract changes in the controller.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract Managed is IManaged {
    // -- State --

    /// Controller that contract is registered with
    IController public controller;
    /// @dev Cache for the addresses of the contracts retrieved from the controller
    mapping(bytes32 => address) private _addressCache;
    /// @dev Gap for future storage variables
    uint256[10] private __gap;

    // Immutables
    bytes32 private immutable CURATION = keccak256("Curation");
    bytes32 private immutable EPOCH_MANAGER = keccak256("EpochManager");
    bytes32 private immutable REWARDS_MANAGER = keccak256("RewardsManager");
    bytes32 private immutable STAKING = keccak256("Staking");
    bytes32 private immutable GRAPH_TOKEN = keccak256("GraphToken");
    bytes32 private immutable GRAPH_TOKEN_GATEWAY = keccak256("GraphTokenGateway");

    // -- Events --

    /// Emitted when a contract parameter has been updated
    event ParameterUpdated(string param);
    /// Emitted when the controller address has been set
    event SetController(address controller);

    /// Emitted when contract with `nameHash` is synced to `contractAddress`.
    event ContractSynced(bytes32 indexed nameHash, address contractAddress);

    // -- Modifiers --

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    function _notPartialPaused() internal view {
        require(!controller.paused(), "Paused");
        require(!controller.partialPaused(), "Partial-paused");
    }

    /**
     * @dev Revert if the controller is paused
     */
    function _notPaused() internal view virtual {
        require(!controller.paused(), "Paused");
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    function _onlyGovernor() internal view {
        require(msg.sender == controller.getGovernor(), "Only Controller governor");
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    function _onlyController() internal view {
        require(msg.sender == address(controller), "Caller must be Controller");
    }

    /**
     * @dev Revert if the controller is paused or partially paused
     */
    modifier notPartialPaused() {
        _notPartialPaused();
        _;
    }

    /**
     * @dev Revert if the controller is paused
     */
    modifier notPaused() {
        _notPaused();
        _;
    }

    /**
     * @dev Revert if the caller is not the Controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }

    /**
     * @dev Revert if the caller is not the governor
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    // -- Functions --

    /**
     * @dev Initialize a Managed contract
     * @param _controller Address for the Controller that manages this contract
     */
    function _initialize(address _controller) internal {
        _setController(_controller);
    }

    /**
     * @notice Set Controller. Only callable by current controller.
     * @param _controller Controller contract address
     */
    function setController(address _controller) external override onlyController {
        _setController(_controller);
    }

    /**
     * @dev Set controller.
     * @param _controller Controller contract address
     */
    function _setController(address _controller) internal {
        require(_controller != address(0), "Controller must be set");
        controller = IController(_controller);
        emit SetController(_controller);
    }

    /**
     * @dev Return Curation interface
     * @return Curation contract registered with Controller
     */
    function curation() internal view returns (ICuration) {
        return ICuration(_resolveContract(CURATION));
    }

    /**
     * @dev Return EpochManager interface
     * @return Epoch manager contract registered with Controller
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(EPOCH_MANAGER));
    }

    /**
     * @dev Return RewardsManager interface
     * @return Rewards manager contract registered with Controller
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(REWARDS_MANAGER));
    }

    /**
     * @dev Return Staking interface
     * @return Staking contract registered with Controller
     */
    function staking() internal view returns (IStaking) {
        return IStaking(_resolveContract(STAKING));
    }

    /**
     * @dev Return GraphToken interface
     * @return Graph token contract registered with Controller
     */
    function graphToken() internal view returns (IGraphToken) {
        return IGraphToken(_resolveContract(GRAPH_TOKEN));
    }

    /**
     * @dev Return GraphTokenGateway (L1 or L2) interface
     * @return Graph token gateway contract registered with Controller
     */
    function graphTokenGateway() internal view returns (ITokenGateway) {
        return ITokenGateway(_resolveContract(GRAPH_TOKEN_GATEWAY));
    }

    /**
     * @dev Resolve a contract address from the cache or the Controller if not found
     * @param _nameHash keccak256 hash of the contract name
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = _addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = controller.getContractProxy(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @dev Cache a contract address from the Controller registry.
     * @param _name Name of the contract to sync into the cache
     */
    function _syncContract(string memory _name) internal {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        address contractAddress = controller.getContractProxy(nameHash);
        if (_addressCache[nameHash] != contractAddress) {
            _addressCache[nameHash] = contractAddress;
            emit ContractSynced(nameHash, contractAddress);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the Controller registry
     * @dev This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a Proxy contract change in the
     * controller to ensure the protocol is using the latest version
     */
    function syncAllContracts() external {
        _syncContract("Curation");
        _syncContract("EpochManager");
        _syncContract("RewardsManager");
        _syncContract("Staking");
        _syncContract("GraphToken");
        _syncContract("GraphTokenGateway");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGraphToken is IERC20 {
    // -- Mint and Burn --

    function burn(uint256 amount) external;

    function burnFrom(address _from, uint256 amount) external;

    function mint(address _to, uint256 _amount) external;

    // -- Mint Admin --

    function addMinter(address _account) external;

    function removeMinter(address _account) external;

    function renounceMinter() external;

    function isMinter(address _account) external view returns (bool);

    // -- Permit --

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    // -- Allowance --

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IGraphProxy {
    function admin() external returns (address);

    function setAdmin(address _newAdmin) external;

    function implementation() external returns (address);

    function pendingImplementation() external returns (address);

    function upgradeTo(address _newImplementation) external;

    function acceptUpgrade() external;

    function acceptUpgradeAndCall(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "./IGraphCurationToken.sol";

interface ICuration {
    // -- Configuration --

    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    function setMinimumCurationDeposit(uint256 _minimumCurationDeposit) external;

    function setCurationTaxPercentage(uint32 _percentage) external;

    function setCurationTokenMaster(address _curationTokenMaster) external;

    // -- Curation --

    function mint(
        bytes32 _subgraphDeploymentID,
        uint256 _tokensIn,
        uint256 _signalOutMin
    ) external returns (uint256, uint256);

    function burn(
        bytes32 _subgraphDeploymentID,
        uint256 _signalIn,
        uint256 _tokensOutMin
    ) external returns (uint256);

    function collect(bytes32 _subgraphDeploymentID, uint256 _tokens) external;

    // -- Getters --

    function isCurated(bytes32 _subgraphDeploymentID) external view returns (bool);

    function getCuratorSignal(address _curator, bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getCurationPoolSignal(bytes32 _subgraphDeploymentID) external view returns (uint256);

    function getCurationPoolTokens(bytes32 _subgraphDeploymentID) external view returns (uint256);

    function tokensToSignal(bytes32 _subgraphDeploymentID, uint256 _tokensIn)
        external
        view
        returns (uint256, uint256);

    function signalToTokens(bytes32 _subgraphDeploymentID, uint256 _signalIn)
        external
        view
        returns (uint256);

    function curationTaxPercentage() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IEpochManager {
    // -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IRewardsManager {
    /**
     * @dev Stores accumulated rewards and snapshots related to a particular SubgraphDeployment.
     */
    struct Subgraph {
        uint256 accRewardsForSubgraph;
        uint256 accRewardsForSubgraphSnapshot;
        uint256 accRewardsPerSignalSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    // -- Config --

    function setIssuanceRate(uint256 _issuanceRate) external;

    function setMinimumSubgraphSignal(uint256 _minimumSubgraphSignal) external;

    // -- Denylist --

    function setSubgraphAvailabilityOracle(address _subgraphAvailabilityOracle) external;

    function setDenied(bytes32 _subgraphDeploymentID, bool _deny) external;

    function setDeniedMany(bytes32[] calldata _subgraphDeploymentID, bool[] calldata _deny)
        external;

    function isDenied(bytes32 _subgraphDeploymentID) external view returns (bool);

    // -- Getters --

    function getNewRewardsPerSignal() external view returns (uint256);

    function getAccRewardsPerSignal() external view returns (uint256);

    function getAccRewardsForSubgraph(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getAccRewardsPerAllocatedToken(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256, uint256);

    function getRewards(address _allocationID) external view returns (uint256);

    // -- Updates --

    function updateAccRewardsPerSignal() external returns (uint256);

    function takeRewards(address _allocationID) external returns (uint256);

    // -- Hooks --

    function onSubgraphSignalUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);

    function onSubgraphAllocationUpdate(bytes32 _subgraphDeploymentID) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;
pragma abicoder v2;

import "./IStakingData.sol";

interface IStaking is IStakingData {
    // -- Allocation Data --

    /**
     * @dev Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    // -- Configuration --

    function setMinimumIndexerStake(uint256 _minimumIndexerStake) external;

    function setThawingPeriod(uint32 _thawingPeriod) external;

    function setCurationPercentage(uint32 _percentage) external;

    function setProtocolPercentage(uint32 _percentage) external;

    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    function setDelegationRatio(uint32 _delegationRatio) external;

    function setDelegationParameters(
        uint32 _indexingRewardCut,
        uint32 _queryFeeCut,
        uint32 _cooldownBlocks
    ) external;

    function setDelegationParametersCooldown(uint32 _blocks) external;

    function setDelegationUnbondingPeriod(uint32 _delegationUnbondingPeriod) external;

    function setDelegationTaxPercentage(uint32 _percentage) external;

    function setSlasher(address _slasher, bool _allowed) external;

    function setAssetHolder(address _assetHolder, bool _allowed) external;

    // -- Operation --

    function setOperator(address _operator, bool _allowed) external;

    function isOperator(address _operator, address _indexer) external view returns (bool);

    // -- Staking --

    function stake(uint256 _tokens) external;

    function stakeTo(address _indexer, uint256 _tokens) external;

    function unstake(uint256 _tokens) external;

    function slash(
        address _indexer,
        uint256 _tokens,
        uint256 _reward,
        address _beneficiary
    ) external;

    function withdraw() external;

    function setRewardsDestination(address _destination) external;

    // -- Delegation --

    function delegate(address _indexer, uint256 _tokens) external returns (uint256);

    function undelegate(address _indexer, uint256 _shares) external returns (uint256);

    function withdrawDelegated(address _indexer, address _newIndexer) external returns (uint256);

    // -- Channel management and allocations --

    function allocate(
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function allocateFrom(
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function closeAllocation(address _allocationID, bytes32 _poi) external;

    function closeAllocationMany(CloseAllocationRequest[] calldata _requests) external;

    function closeAndAllocate(
        address _oldAllocationID,
        bytes32 _poi,
        address _indexer,
        bytes32 _subgraphDeploymentID,
        uint256 _tokens,
        address _allocationID,
        bytes32 _metadata,
        bytes calldata _proof
    ) external;

    function collect(uint256 _tokens, address _allocationID) external;

    function claim(address _allocationID, bool _restake) external;

    function claimMany(address[] calldata _allocationID, bool _restake) external;

    // -- Getters and calculations --

    function hasStake(address _indexer) external view returns (bool);

    function getIndexerStakedTokens(address _indexer) external view returns (uint256);

    function getIndexerCapacity(address _indexer) external view returns (uint256);

    function getAllocation(address _allocationID) external view returns (Allocation memory);

    function getAllocationState(address _allocationID) external view returns (AllocationState);

    function isAllocation(address _allocationID) external view returns (bool);

    function getSubgraphAllocatedTokens(bytes32 _subgraphDeploymentID)
        external
        view
        returns (uint256);

    function getDelegation(address _indexer, address _delegator)
        external
        view
        returns (Delegation memory);

    function isDelegator(address _indexer, address _delegator) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Originally copied from:
 * https://github.com/OffchainLabs/arbitrum/tree/e3a6307ad8a2dc2cad35728a2a9908cfd8dd8ef9/packages/arb-bridge-peripherals
 *
 * MODIFIED from Offchain Labs' implementation:
 * - Changed solidity version to 0.7.6 ([email protected])
 *
 */

pragma solidity ^0.7.6;

interface ITokenGateway {
    /// @notice event deprecated in favor of DepositInitiated and WithdrawalInitiated
    // event OutboundTransferInitiated(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    /// @notice event deprecated in favor of DepositFinalized and WithdrawalFinalized
    // event InboundTransferFinalized(
    //     address token,
    //     address indexed _from,
    //     address indexed _to,
    //     uint256 indexed _transferId,
    //     uint256 _amount,
    //     bytes _data
    // );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable;

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev the L1 and L2 address oracles may not always be in sync.
     * For example, a custom token may have been registered but not deployed or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

interface IManaged {
    function setController(address _controller) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGraphCurationToken is IERC20Upgradeable {
    function initialize(address _owner) external;

    function burnFrom(address _account, uint256 _amount) external;

    function mint(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12 <0.8.0;

interface IStakingData {
    /**
     * @dev Allocate GRT tokens for the purpose of serving queries of a subgraph deployment
     * An allocation is created in the allocate() function and consumed in claim()
     */
    struct Allocation {
        address indexer;
        bytes32 subgraphDeploymentID;
        uint256 tokens; // Tokens allocated to a SubgraphDeployment
        uint256 createdAtEpoch; // Epoch when it was created
        uint256 closedAtEpoch; // Epoch when it was closed
        uint256 collectedFees; // Collected fees for the allocation
        uint256 effectiveAllocation; // Effective allocation when closed
        uint256 accRewardsPerAllocatedToken; // Snapshot used for reward calc
    }

    /**
     * @dev Represents a request to close an allocation with a specific proof of indexing.
     * This is passed when calling closeAllocationMany to define the closing parameters for
     * each allocation.
     */
    struct CloseAllocationRequest {
        address allocationID;
        bytes32 poi;
    }

    // -- Delegation Data --

    /**
     * @dev Delegation pool information. One per indexer.
     */
    struct DelegationPool {
        uint32 cooldownBlocks; // Blocks to wait before updating parameters
        uint32 indexingRewardCut; // in PPM
        uint32 queryFeeCut; // in PPM
        uint256 updatedAtBlock; // Block when the pool was last updated
        uint256 tokens; // Total tokens as pool reserves
        uint256 shares; // Total shares minted in the pool
        mapping(address => Delegation) delegators; // Mapping of delegator => Delegation
    }

    /**
     * @dev Individual delegation data of a delegator in a pool.
     */
    struct Delegation {
        uint256 shares; // Shares owned by a delegator in the pool
        uint256 tokensLocked; // Tokens locked for undelegation
        uint256 tokensLockedUntil; // Block when locked tokens can be withdrawn
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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