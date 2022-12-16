// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.12;

import { IDynamicJobs } from "./interfaces/IDynamicJobs.sol";
import { IKeeperRegistry } from "./interfaces/IKeeperRegistry.sol";
import { IGasVault } from "./interfaces/IGasVault.sol";
import { IOrchestrator } from "./interfaces/IOrchestrator.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract DynamicJobs is Initializable, OwnableUpgradeable, IDynamicJobs {
    // Storage

    address public keeperRegistry;
    address public orchestrator;
    address public creator;
    uint256 public gasBalance;
    address public gasVault;

    /// @dev The mapping of jobState has 3 possiblities
    ///      1) 0 means not registered
    ///      2) 1 means registered and paused
    ///      3) 2 means unpaused and registered (active)
    mapping(bytes32 => uint256) public jobState;

    // Constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer() {}

    function initialize(
        address _orchestrator,
        address, // Steer multisig not used here
        address, // Internal governance not used here
        bytes calldata _params
    ) external initializer {
        address _creator = abi.decode(_params, (address));

        // Fetch gas vault and keeper registry from orchestrator
        keeperRegistry = IOrchestrator(_orchestrator).keeperRegistry();
        gasVault = IOrchestrator(_orchestrator).gasVault();

        __Ownable_init();
        creator = _creator;
        orchestrator = _orchestrator;
    }

    /// @dev Use this function to register jobs.
    /// @param _userProvidedData are the calldatas that are provided by the user at the registration time.
    /// @param _targetAddresses are the addresses of the contracts on which the jobs needs to be executed.
    /// @param _name should be the name of the job.
    /// @param _ipfsForJobDetails is the ipfs hash containing job details like the interval for job execution.
    function registerJob(
        bytes[] calldata _userProvidedData,
        address[] calldata _targetAddresses,
        string calldata _name,
        string calldata _ipfsForJobDetails
    ) external {
        // Validate param length
        require(
            _userProvidedData.length == _targetAddresses.length,
            "Wrong Address Count"
        );

        // Only vault owner can register jobs for this vault
        require(creator == msg.sender, "Unauthorized");

        // Record job hash
        bytes32 jobHash = keccak256(
            abi.encode(_userProvidedData, _targetAddresses)
        );

        // Job is currently unpaused
        jobState[jobHash] = 2;

        // Emit job details so that they can be used offchain
        emit JobRegistered(
            _userProvidedData,
            _targetAddresses,
            jobHash,
            _name,
            _ipfsForJobDetails
        );
    }

    /// @dev Use this function to register jobs and deposit gas in one call
    /// @dev Send the amount of gas that is needed to be deposited as msg.value.
    /// @param _userProvidedData are the calldatas that are provided by the user at the registration time.
    /// @param _targetAddresses are the addresses of the contracts on which the jobs needs to be executed.
    /// @param _name is the name of the job.
    /// @param _ipfsForJobDetails is the ipfs hash containing job details like the interval for job execution.
    function registerJobAndDepositGas(
        bytes[] calldata _userProvidedData,
        address[] calldata _targetAddresses,
        string calldata _name,
        string calldata _ipfsForJobDetails
    ) external payable {
        // Register job
        require(
            _userProvidedData.length == _targetAddresses.length,
            "Wrong Address Count"
        );
        require(creator == msg.sender, "Unauthorized");
        bytes32 jobHash = keccak256(
            abi.encode(_userProvidedData, _targetAddresses)
        );
        jobState[jobHash] = 2;
        emit JobRegistered(
            _userProvidedData,
            _targetAddresses,
            jobHash,
            _name,
            _ipfsForJobDetails
        );

        // Deposit gas
        IGasVault(gasVault).deposit{ value: msg.value }(address(this));
    }

    /// @dev Use this function to execute Jobs.
    /// @dev Only Orchestrator can call this function.
    /// @param _userProvidedData are the calldatas that are provided by the user at the registration time.
    /// @param _strategyProvidedData are the encoded parameters sent on the time of creation or execution of action in orchestrator according to the strategy.
    /// @param _targetAddresses are the addresses of the contracts on which the jobs needs to be executed.
    function executeJob(
        address[] calldata _targetAddresses,
        bytes[] calldata _userProvidedData,
        bytes[] calldata _strategyProvidedData
    ) external {
        bytes32 _jobHash = keccak256(
            abi.encode(_userProvidedData, _targetAddresses)
        );

        // Ensure passed params match user registered job
        require(jobState[_jobHash] == 2, "Paused or Not Registered");

        // Ensure that job is not paused
        require(msg.sender == orchestrator, "Unauthorized");

        uint256 jobCount = _targetAddresses.length;

        bytes memory completeData;
        bool success;
        for (uint256 i; i != jobCount; ++i) {
            completeData = abi.encodePacked(
                _userProvidedData[i],
                _strategyProvidedData[i]
            );
            (success, ) = _targetAddresses[i].call(completeData);

            // Revert if this method failed, thus reverting all methods in this job
            require(success);
        }
        emit JobExecuted(_jobHash, msg.sender);
    }

    /// @dev Use this function to pause or unpause a job
    /// @param _jobHash is the keccak of encoded parameters and target addresses
    /// @param _toggle pass 1 to pause the job and pass 2 to unpause the job
    function setJobState(bytes32 _jobHash, uint256 _toggle) external {
        require(creator == msg.sender, "Access Denied");
        require(_toggle == 1 || _toggle == 2, "Invalid");
        jobState[_jobHash] = _toggle;
        emit JobToggledByCreator(_jobHash, _toggle);
    }

    /// @dev Use this function to withdraw gas associated to this vault
    /// @dev Only creator of this vault can call this function
    /// @param _amount is the amount of ether in wei that creator of this contract wants to pull out
    /// @param to is the address at which the creator wants to pull the deposited ether out
    function withdrawGas(uint256 _amount, address payable to) external {
        require(msg.sender == creator, "Not Creator");
        IGasVault(gasVault).withdraw(_amount, to);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

interface IDynamicJobs {
    event JobExecuted(bytes32 jobHash, address executor);
    event JobRegistered(
        bytes[] jobInfo,
        address[] targetAddresses,
        bytes32 jobHash,
        string name,
        string ipfsForJobDetails
    );
    event JobToggledByCreator(bytes32 jobHash, uint256 toggle);

    function registerJob(
        bytes[] calldata _userProvidedData,
        address[] calldata _targetAddresses,
        string calldata _name,
        string calldata _ipfsForJobDetails
    ) external;

    function registerJobAndDepositGas(
        bytes[] calldata _userProvidedData,
        address[] calldata _targetAddresses,
        string calldata _name,
        string calldata _ipfsForJobDetails
    ) external payable;

    function executeJob(
        address[] calldata _targetAddresses,
        bytes[] calldata _userProvidedData,
        bytes[] calldata _strategyProvidedData
    ) external;

    function setJobState(bytes32 _jobHash, uint256 _toggle) external;

    function withdrawGas(uint256 _amount, address payable to) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

interface IGasVault {
    event Deposited(
        address indexed origin,
        address indexed target,
        uint256 amount
    );
    event Withdrawn(
        address indexed targetAddress,
        address indexed to,
        uint256 amount
    );
    event EtherUsed(address indexed account, uint256 amount, bytes32 jobHash);

    function deposit(address targetAddress) external payable;

    /**
     * @dev Withdraws given amount of ether from the vault.
     * @param amount Amount of ether to withdraw, in terms of wei.
     */
    function withdraw(
        uint256 amount,
        address targetAddress,
        address payable to
    ) external;

    function withdraw(uint256 amount, address payable to) external;

    /**
     * @dev calculates total transactions remaining. What this means is--assuming that each method (action paid for by the strategist/job owner)
     *      costs max amount of gas at max gas price, and uses the max amount of actions, how many transactions can be paid for?
     *      In other words, how many actions can this vault guarantee.
     * @param targetAddress is address actions will be performed on, and address paying gas for those actions.
     * @param highGasEstimate is highest reasonable gas price assumed for the actions
     * @return total transactions remaining, assuming max gas is used in each Method
     */
    function transactionsRemaining(
        address targetAddress,
        uint256 highGasEstimate
    ) external view returns (uint256);

    /**
     * @param targetAddress is address actions will be performed on, and address paying gas for those actions.
     * @return uint256 gasAvailable (representing amount of gas available per Method).
     */
    function gasAvailableForTransaction(address targetAddress)
        external
        view
        returns (uint256);

    /**
     * @param targetAddress is address actions were performed on
     * @param originalGas is gas passed in to the action execution order. Used to calculate gas used in the execution.
     * @dev should only ever be called by the orchestrator. Is onlyOrchestrator. This and setAsideGas are used to pull gas from the vault for strategy executions.
     */
    function reimburseGas(
        address targetAddress,
        uint256 originalGas,
        bytes32 newActionHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

interface IKeeperRegistry {
    enum permissionType {
        NONE,
        FULL,
        SLASHED
    }

    /**
     * Any given address can be in one of three different states:
        1. Not a keeper.
        2. A former keeper who is queued to leave, i.e. they no longer have a keeper license but still have some funds locked in the contract. 
        3. A current keeper.
     * Keepers can themselves each be in one of two states:
        1. In good standing. This is signified by bondHeld >= bondAmount.
        2. Not in good standing. 
        If a keepers is not in good standing, they retain their license and ability to vote, but any slash will remove their privileges.
     * The only way for a keeper's bondHeld to drop to 0 is for them to leave or be slashed. Either way they lose their license in the process.
     */
    struct WorkerDetails {
        uint256 bondHeld; // bondCoin held by this keeper.
        uint256 licenseNumber; // Index of this keeper in the license mapping, i.e. which license they own. If they don't own a license, this will be 0.
        uint256 leaveTimestamp; // If this keeper has queued to leave, they can withdraw their bond after this date.
    }

    event PermissionChanged(
        address indexed _subject,
        permissionType indexed _permissionType
    );
    event LeaveQueued(address indexed keeper, uint256 leaveTimestamp);

    /**
     * @param coinAddress the address of the ERC20 which will be used for bonds; intended to be Steer token.
     * @param keeperTransferDelay the amount of time (in seconds) between when a keeper relinquishes their license and when they can
            withdraw their funds. Intended to be 2 weeks - 1 month.
     */
    function initialize(
        address coinAddress,
        uint256 keeperTransferDelay,
        uint256 maxKeepers,
        uint256 bondSize
    ) external;

    function maxNumKeepers() external view returns (uint256);

    function currentNumKeepers() external view returns (uint256);

    /**
     * @dev setup utility function for owner to add initial keepers. Addresses must each be unique and not hold any bondToken.
     * @param joiners array of addresses to become keepers.
     * note that this function will pull bondToken from the owner equal to bondAmount * numJoiners.
     */
    function joiningForOwner(address[] calldata joiners) external;

    /**
     * @param amount Amount of bondCoin to be deposited.
     * @dev this function has three uses:
        1. If the caller is a keeper, they can increase their bondHeld by amount.
        2. If the caller is not a keeper or former keeper, they can attempt to claim a keeper license and become a keeper.
        3. If the caller is a former keeper, they can attempt to cancel their leave request, claim a keeper license, and become a keeper.
        In all 3 cases registry[msg.sender].bondHeld is increased by amount. In the latter 2, msg.sender's bondHeld after the transaction must be >= bondAmount.
     */
    function join(uint256 licenseNumber, uint256 amount) external;

    function queueToLeave() external;

    function leave() external;

    /**
     * @dev returns true if the given address has the power to vote, false otherwise. The address has the power to vote if it is within the keeper array.
     */
    function checkLicense(address targetAddress)
        external
        view
        returns (uint256);

    /**
     * @dev slashes a keeper, removing their permissions and forfeiting their bond.
     * @param targetKeeper keeper to denounce
     * @param amount amount of bondCoin to slash
     */
    function denounce(address targetKeeper, uint256 amount) external;

    /**
     * @dev withdraws slashed tokens from the vault and sends them to targetAddress.
     * @param amount amount of bondCoin to withdraw
     * @param targetAddress address receiving the tokens
     */
    function withdrawFreeCoin(uint256 amount, address targetAddress) external;

    /**
     * @dev change bondAmount to a new value.
     * @dev implicitly changes keeper permissions. If the bondAmount is being increased, existing keepers will not be slashed or removed. 
            note, they will still be able to vote until they are slashed.
     * @param amount new bondAmount.
     */
    function changeBondAmount(uint256 amount) external;

    /**
     * @dev change numKeepers to a new value. If numKeepers is being reduced, this will not remove any keepers, nor will it change orchestrator requirements.
        However, it will render keeper licenses > maxNumKeepers invalid and their votes will stop counting.
     */
    function changeMaxKeepers(uint16 newNumKeepers) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

/**
 * @dev Interface of the Orchestrator.
 */
interface IOrchestrator {
    enum ActionState {
        PENDING,
        COMPLETED
    }

    /**
     * @dev MUST trigger when actions are executed.
     * @param actionHash: keccak256(targetAddress, jobEpoch, calldatas) used to identify this action
     * @param from: the address of the keeper that executed this action
     * @param rewardPerAction: SteerToken reward for this action, to be supplied to operator nodes.
     */
    event ActionExecuted(
        bytes32 indexed actionHash,
        address from,
        uint256 rewardPerAction
    );
    event ActionFailed(bytes32 indexed actionHash);
    event Vote(
        bytes32 indexed actionHash,
        address indexed from,
        bool approved
    );

    // If an action is approved by >= approvalThresholdPercent members, it is approved
    function actionThresholdPercent() external view returns (uint256);

    // Address of GasVault, which is the contract used to recompense keepers for gas they spent executing actions
    function gasVault() external view returns (address);

    // Address of Keeper Registry, which handles keeper verification
    function keeperRegistry() external view returns (address);

    // Operator node action participation reward. Currently unused.
    function rewardPerAction() external view returns (uint256);

    /*
        bytes32 is hash of action. Calculated using keccak256(abi.encode(targetAddress, jobEpoch, calldatas))

        Action approval meaning:
        0: Pending
        1: Approved
        Both votes and overall approval status follow this standard.
    */
    function actions(bytes32) external view returns (ActionState);

    /*  
        actionHash => uint256 where each bit represents one keeper vote.
    */
    function voteBitmaps(bytes32) external view returns (uint256);

    /**
     * @dev initialize the Orchestrator
     * @param _keeperRegistry address of the keeper registry
     * @param _rewardPerAction is # of SteerToken to give to operator nodes for each completed action (currently unused)
     */
    function initialize(address _keeperRegistry, uint256 _rewardPerAction)
        external;

    /**
     * @dev allows owner to set/update gas vault address. Mainly used to resolve mutual dependency.
     */
    function setGasVault(address _gasVault) external;

    /**
     * @dev set the reward given to operator nodes for their participation in a strategy calculation
     * @param _rewardPerAction is amount of steer token to be earned as a reward, per participating operator node per action.
     */
    function setRewardPerAction(uint256 _rewardPerAction) external;

    /**
     * @dev vote (if you are a keeper) on a given action proposal
     * @param actionHash is the hash of the action to be voted on
     * @param vote is the vote to be cast. false: reject, true: approve. false only has an effect if the keeper previously voted true. It resets their vote to false.
     */
    function voteOnAction(bytes32 actionHash, bool vote) external;

    /**
     * @dev Returns true if an action with given `actionId` is approved by all existing members of the group.
     * It’s up to the contract creators to decide if this method should look at majority votes (based on ownership)
     * or if it should ask consent of all the users irrespective of their ownerships.
     */
    function actionApprovalStatus(bytes32 actionHash)
        external
        view
        returns (bool);

    /**
     * @dev Executes the action referenced by the given `actionId` as long as it is approved actionThresholdPercent of group.
     * The executeAction executes all methods as part of given action in an atomic way (either all should succeed or none should succeed).
     * Once executed, the action should be set as executed (state=3) so that it cannot be executed again.

     * @param targetAddress is the address which will be receiving the action's calls.
     * @param jobEpoch is the job epoch of this action.
     * @param calldatas is the COMPLETE calldata of each method to be called
     * note that the hash is created using the sliced calldata, but here it must be complete or the method will revert.
     * @param timeIndependentLengths--For each calldata, the number of bytes that is NOT time-sensitive. If no calldatas are time-sensitive, just pass an empty array.
     * @param jobHash is the identifier for the job this action is related to. This is used for DynamicJobs to identify separate jobs to the subgraph.
     * @return actionState corresponding to post-execution action state. Pending if execution failed, Completed if execution succeeded.
     */
    function executeAction(
        address targetAddress,
        uint256 jobEpoch,
        bytes[] calldata calldatas,
        uint256[] calldata timeIndependentLengths,
        bytes32 jobHash
    ) external returns (ActionState);
}