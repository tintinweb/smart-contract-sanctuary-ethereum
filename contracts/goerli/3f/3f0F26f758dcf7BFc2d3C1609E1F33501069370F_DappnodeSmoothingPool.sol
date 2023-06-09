// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * Contract responsible to manage the subscriptions and rewards of the dappnode smoothing pool
 */
contract DappnodeSmoothingPool is OwnableUpgradeable {
    /**
     * @notice Struct to store voted reports
     * @param slot Slot of the report
     * @param votes Current votes of this report
     */
    struct Report {
        uint64 slot;
        uint64 votes;
    }

    // This value is reserved as an initial voted report to mark an oracle address as active
    bytes32 public constant INITIAL_REPORT_HASH = bytes32(uint256(1));
    // 0x0000000000000000000000000000000000000000000000000000000000000001;

    // Subscription collateral
    uint256 public subscriptionCollateral;

    // Rewards merkle root, aggregate together all the validatorIDs with the same withdrawal address
    // Leaf:keccak256(abi.encodePacked(withdrawalAddress, availableBalance)
    bytes32 public rewardsRoot;

    // withdrawalAddress --> claimedBalance
    mapping(address => uint256) public claimedBalance;

    // Allow a withdrawal address to delegate his rewards to another address
    // withdrawalAddress --> rewardAddress
    mapping(address => address) public rewardRecipient;

    // The above parameters are used to synch information on the oracle

    // Smoothing pool fee expressed in % with 2 decimals
    uint256 public poolFee;

    // Smoothing pool fee recipient
    address public poolFeeRecipient;

    // Indicates the deployment block number
    uint256 public deploymentBlockNumber;

    // The above parameters are relative to the oracle

    // Indicates the last consolidated slot
    uint64 public lastConsolidatedSlot;

    // Indicates how many slots must be between checkpoints
    uint64 public checkpointSlotSize;

    // Number of reports that must match to consolidate a new rewards root (N/M)
    uint64 public quorum;

    // Will be able to add/remove members of the oracle aswell of udpate the quorum
    address public governance;

    // Will be able to accept the governance
    address public pendingGovernance;

    // Oracle member address --> current voted reportHash
    // reportHash: keccak256(abi.encodePacked(slot, rewardsRoot))
    mapping(address => bytes32) public addressToVotedReportHash;

    // reportHash --> Report(slot | votes)
    mapping(bytes32 => Report) public reportHashToReport;

    // Above parameters are just used to handly get the current oracle information
    address[] public oracleMembers;

    /**
     * @dev Emitted when the contract receives ether
     */
    event EtherReceived(address sender, uint256 donationAmount);

    /**
     * @dev Emitted when a new users subscribes
     */
    event SubscribeValidator(
        address sender,
        uint256 subscriptionCollateral,
        uint64 validatorID
    );

    /**
     * @dev Emitted when a user claim his rewards
     */
    event ClaimRewards(
        address withdrawalAddress,
        address rewardAddress,
        uint256 claimableBalance
    );

    /**
     * @dev Emitted when a validator address sets his rewards recipient
     */
    event SetRewardRecipient(address withdrawalAddress, address poolRecipient);

    /**
     * @dev Emitted when a validator unsubscribes
     */
    event UnsubscribeValidator(address sender, uint64 validatorID);

    /**
     * @dev Emitted when a hte smoothing pool is initialized
     */
    event InitSmoothingPool(uint64 initialSmoothingPoolSlot);

    /**
     * @dev Emitted when the pool fee is updated
     */
    event UpdatePoolFee(uint256 newPoolFee);

    /**
     * @dev Emitted when the pool fee recipient is updated
     */
    event UpdatePoolFeeRecipient(address newPoolFeeRecipient);

    /**
     * @dev Emitted when the checkpoint slot size is updated
     */
    event UpdateCheckpointSlotSize(uint64 newCheckpointSlotSize);

    /**
     * @dev Emitted when the subscription collateral is udpated
     */
    event UpdateSubscriptionCollateral(uint256 newSubscriptionCollateral);

    /**
     * @dev Emitted when a report is submitted
     */
    event SubmitReport(
        uint256 slotNumber,
        bytes32 newRewardsRoot,
        address oracleMember
    );

    /**
     * @dev Emitted when a report is consolidated
     */
    event ReportConsolidated(uint256 slotNumber, bytes32 newRewardsRoot);

    /**
     * @dev Emitted when the quorum is updated
     */
    event UpdateQuorum(uint64 newQuorum);

    /**
     * @dev Emitted when a new oracle member is added
     */
    event AddOracleMember(address newOracleMember);

    /**
     * @dev Emitted when a new oracle member is removed
     */
    event RemoveOracleMember(address oracleMemberRemoved);

    /**
     * @dev Emitted when the governance starts the two-step transfer setting a new pending governance
     */
    event TransferGovernance(address newPendingGovernance);

    /**
     * @dev Emitted when the pending governance accepts the governance
     */
    event AcceptGovernance(address newGovernance);

    /**
     * @param _governance Governance address
     * @param _subscriptionCollateral Subscription collateral
     * @param _poolFee Pool Fee
     * @param _poolFeeRecipient Pool fee recipient
     * @param _checkpointSlotSize Checkpoint slot size
     */
    function initialize(
        address _governance,
        uint256 _subscriptionCollateral,
        uint256 _poolFee,
        address _poolFeeRecipient,
        uint64 _checkpointSlotSize,
        uint64 _quorum
    ) external initializer {
        // Initialize requires
        require(
            _poolFee <= 10000,
            "DappnodeSmoothingPool::initialize: Pool fee cannot be greater than 100%"
        );

        require(
            _quorum != 0,
            "DappnodeSmoothingPool::initialize: Quorum cannot be 0"
        );

        // Set initialize parameters
        governance = _governance;
        subscriptionCollateral = _subscriptionCollateral;

        checkpointSlotSize = _checkpointSlotSize;
        quorum = _quorum;

        poolFee = _poolFee;
        poolFeeRecipient = _poolFeeRecipient;
        deploymentBlockNumber = block.number;

        // Initialize OZ libs
        __Ownable_init();

        // Emit events
        emit UpdatePoolFee(_poolFee);
        emit UpdatePoolFeeRecipient(_poolFeeRecipient);
        emit UpdateCheckpointSlotSize(_checkpointSlotSize);
        emit UpdateQuorum(_quorum);
    }

    /**
     * @dev Governance modifier
     */
    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "DappnodeSmoothingPool::onlyGovernance: Only governance"
        );
        _;
    }

    /**
     * @notice Be able to receive ether donations and MEV rewards
     * Oracle will be able to differenciate between MEV rewards and donations and distribute rewards accordingly
     **/
    fallback() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    ////////////////////////
    // Validators functions
    ///////////////////////

    /**
     * @notice Subscribe a validator ID to the smoothing pool
     * @param validatorID Validator ID
     */
    function subscribeValidator(uint64 validatorID) external payable {
        // Check collateral
        require(
            msg.value == subscriptionCollateral,
            "DappnodeSmoothingPool::subscribeValidator: msg.value does not equal subscription collateral"
        );

        emit SubscribeValidator(
            msg.sender,
            subscriptionCollateral,
            validatorID
        );
    }

    /**
     * @notice Claim available rewards
     * All the rewards that has the same withdrawal address and pool recipient are aggregated in the same leaf
     * @param withdrawalAddress Withdrawal address
     * @param accumulatedBalance Total available balance to claim
     * @param merkleProof Merkle proof against rewardsRoot
     */
    function claimRewards(
        address withdrawalAddress,
        uint256 accumulatedBalance,
        bytes32[] memory merkleProof
    ) external {
        // Verify the merkle proof
        bytes32 node = keccak256(
            abi.encodePacked(withdrawalAddress, accumulatedBalance)
        );

        require(
            MerkleProofUpgradeable.verify(merkleProof, rewardsRoot, node),
            "DappnodeSmoothingPool::claimRewards: Invalid merkle proof"
        );

        // Get claimable ether
        uint256 claimableBalance = accumulatedBalance -
            claimedBalance[withdrawalAddress];

        // Update claimed balance mapping
        claimedBalance[withdrawalAddress] = accumulatedBalance;

        // Load first the reward recipient for gas saving, to avoid load twice from storage
        address currentRewardRecipient = rewardRecipient[withdrawalAddress];
        address rewardAddress = currentRewardRecipient == address(0)
            ? withdrawalAddress
            : currentRewardRecipient;

        // Send ether
        (bool success, ) = rewardAddress.call{value: claimableBalance}(
            new bytes(0)
        );
        require(
            success,
            "DappnodeSmoothingPool::claimRewards: Eth transfer failed"
        );

        emit ClaimRewards(withdrawalAddress, rewardAddress, claimableBalance);
    }

    /**
     * @notice Allow a withdrawal address to set a reward recipient
     * @param rewardAddress Reward recipient
     */
    function setRewardRecipient(address rewardAddress) external {
        rewardRecipient[msg.sender] = rewardAddress;
        emit SetRewardRecipient(msg.sender, rewardAddress);
    }

    /**
     * @notice Unsubscribe a validator ID from smoothing pool
     * This call will only take effect in the oracle
     * if the msg.sender is the withdrawal address of that validator
     * @param validatorID Validator ID
     */
    function unsubscribeValidator(uint64 validatorID) external {
        emit UnsubscribeValidator(msg.sender, validatorID);
    }

    ////////////////////
    // Oracle functions
    ///////////////////

    /**
     * @notice Submit a report for a new rewards root
     * If the quorum is reached, consolidate the rewards root
     * @param slotNumber Slot number
     * @param proposedRewardsRoot Proposed rewards root
     */
    function submitReport(
        uint64 slotNumber,
        bytes32 proposedRewardsRoot
    ) external {
        // Check that the report contains the correct slot number
        uint64 cacheLastConsolidatedSlot = lastConsolidatedSlot;

        require(
            cacheLastConsolidatedSlot != 0,
            "DappnodeSmoothingPool::submitReport: Smoothing pool not initialized"
        );

        require(
            slotNumber == cacheLastConsolidatedSlot + checkpointSlotSize,
            "DappnodeSmoothingPool::submitReport: Slot number invalid"
        );

        // Check the last voted report
        bytes32 lastVotedReportHash = addressToVotedReportHash[msg.sender];

        // Check if it's a valid oracle member
        require(
            lastVotedReportHash != bytes32(0),
            "DappnodeSmoothingPool::submitReport: Not a oracle member"
        );

        // If it's not the initial report hash, check last report voted
        if (lastVotedReportHash != INITIAL_REPORT_HASH) {
            Report storage lastVotedReport = reportHashToReport[
                lastVotedReportHash
            ];

            // If this member already voted for this slot substract a vote from that report
            if (lastVotedReport.slot == slotNumber) {
                lastVotedReport.votes--;
            }
        }

        // Get the current report
        bytes32 currentReportHash = getReportHash(
            slotNumber,
            proposedRewardsRoot
        );
        Report memory currentVotedReport = reportHashToReport[
            currentReportHash
        ];

        // Check if it's a new report
        if (currentVotedReport.slot == 0) {
            // It's a new report, set slot and votes
            currentVotedReport.slot = slotNumber;
            currentVotedReport.votes = 1;
        } else {
            // It's an existing report, add a new vote
            currentVotedReport.votes++;
        }

        // Emit Submit report before check the quorum
        emit SubmitReport(slotNumber, proposedRewardsRoot, msg.sender);

        // Check if it reaches the quorum
        if (currentVotedReport.votes == quorum) {
            delete reportHashToReport[currentReportHash];

            // Consolidate report
            lastConsolidatedSlot = slotNumber;
            rewardsRoot = proposedRewardsRoot;
            emit ReportConsolidated(slotNumber, proposedRewardsRoot);
        } else {
            // Store submitted report with a new added vote
            reportHashToReport[currentReportHash] = currentVotedReport;

            // Store voted report hash
            addressToVotedReportHash[msg.sender] = currentReportHash;
        }
    }

    ////////////////////////
    // Governance functions
    ////////////////////////

    /**
     * @notice Add an oracle member
     * Only the governance can call this function
     * @param newOracleMember Address of the new oracle member
     */
    function addOracleMember(address newOracleMember) external onlyGovernance {
        require(
            addressToVotedReportHash[newOracleMember] == bytes32(0),
            "DappnodeSmoothingPool::addOracleMember: Already oracle member"
        );

        // Add oracle member
        addressToVotedReportHash[newOracleMember] = INITIAL_REPORT_HASH;

        // Add oracle member to the oracleMembers array
        oracleMembers.push(newOracleMember);

        emit AddOracleMember(newOracleMember);
    }

    /**
     * @notice Remove an oracle member
     * Only the governance can call this function
     * @param oracleMemberAddress Address of the removed oracle member
     * @param oracleMemberIndex Index of the removed oracle member
     */
    function removeOracleMember(
        address oracleMemberAddress,
        uint256 oracleMemberIndex
    ) external onlyGovernance {
        bytes32 lastVotedReportHash = addressToVotedReportHash[
            oracleMemberAddress
        ];

        require(
            lastVotedReportHash != bytes32(0),
            "DappnodeSmoothingPool::removeOracleMember: Was not an oracle member"
        );

        require(
            oracleMembers[oracleMemberIndex] == oracleMemberAddress,
            "DappnodeSmoothingPool::removeOracleMember: Oracle member index does not match"
        );

        // If it's not the initial report hash, check last report voted
        if (lastVotedReportHash != INITIAL_REPORT_HASH) {
            Report storage lastVotedReport = reportHashToReport[
                lastVotedReportHash
            ];

            // Substract a vote of this oracle member
            // If the votes == 0, that report was already consolidated
            if (lastVotedReport.votes > 0) {
                lastVotedReport.votes--;
            }
        }

        // Remove oracle member
        addressToVotedReportHash[oracleMemberAddress] = bytes32(0);

        // Remove the oracle member from the oracleMembers array
        oracleMembers[oracleMemberIndex] = oracleMembers[
            oracleMembers.length - 1
        ];
        oracleMembers.pop();

        emit RemoveOracleMember(oracleMemberAddress);
    }

    /**
     * @notice Update the quorum value
     * Only the governance can call this function
     * @param newQuorum new quorum
     */
    function updateQuorum(uint64 newQuorum) external onlyGovernance {
        require(
            newQuorum != 0,
            "DappnodeSmoothingPool::updateQuorum: Quorum cannot be 0"
        );
        quorum = newQuorum;
        emit UpdateQuorum(newQuorum);
    }

    /**
     * @notice Starts the governance transfer
     * This is a two step process, the pending governance must accepted to finalize the process
     * Only the governance can call this function
     * @param newPendingGovernance new governance address
     */
    function transferGovernance(
        address newPendingGovernance
    ) external onlyGovernance {
        pendingGovernance = newPendingGovernance;
        emit TransferGovernance(newPendingGovernance);
    }

    /**
     * @notice Allow the current pending governance to accept the governance
     */
    function acceptGovernance() external {
        require(
            pendingGovernance == msg.sender,
            "DappnodeSmoothingPool::acceptGovernance: Only pending governance"
        );

        governance = pendingGovernance;
        emit AcceptGovernance(pendingGovernance);
    }

    ///////////////////
    // Owner functions
    ///////////////////

    /**
     * @notice Initialize smoothing pool
     * Only the owner can call this function
     * @param initialSmoothingPoolSlot Initial smoothing pool slot
     */
    function initSmoothingPool(
        uint64 initialSmoothingPoolSlot
    ) external onlyOwner {
        // Smoothing pool must not have been initialized
        require(
            lastConsolidatedSlot == 0,
            "DappnodeSmoothingPool::initSmoothingPool: Smoothing pool already initialized"
        );

        // Cannot initialize smoothing pool to slot 0
        require(
            initialSmoothingPoolSlot != 0,
            "DappnodeSmoothingPool::initSmoothingPool: Cannot initialize to slot 0"
        );

        lastConsolidatedSlot = initialSmoothingPoolSlot;
        emit InitSmoothingPool(initialSmoothingPoolSlot);
    }

    /**
     * @notice Update pool fee
     * Only the owner can call this function
     * @param newPoolFee new pool fee
     */
    function updatePoolFee(uint256 newPoolFee) external onlyOwner {
        require(
            newPoolFee <= 10000,
            "DappnodeSmoothingPool::updatePoolFee: Pool fee cannot be greater than 100%"
        );
        poolFee = newPoolFee;
        emit UpdatePoolFee(newPoolFee);
    }

    /**
     * @notice Update the pool fee recipient
     * Only the owner can call this function
     * @param newPoolFeeRecipient new pool fee recipient
     */
    function updatePoolFeeRecipient(
        address newPoolFeeRecipient
    ) external onlyOwner {
        poolFeeRecipient = newPoolFeeRecipient;
        emit UpdatePoolFeeRecipient(newPoolFeeRecipient);
    }

    /**
     * @notice Update the checkpoint slot size
     * Only the owner can call this function
     * @param newCheckpointSlotSize new checkpoint slot size
     */
    function updateCheckpointSlotSize(
        uint64 newCheckpointSlotSize
    ) external onlyOwner {
        checkpointSlotSize = newCheckpointSlotSize;
        emit UpdateCheckpointSlotSize(newCheckpointSlotSize);
    }

    /**
     * @notice Update the collateral needed to subscribe a validator
     * Only the owner can call this function
     * @param newSubscriptionCollateral new subscription collateral
     */
    function updateCollateral(
        uint256 newSubscriptionCollateral
    ) external onlyOwner {
        subscriptionCollateral = newSubscriptionCollateral;
        emit UpdateSubscriptionCollateral(newSubscriptionCollateral);
    }

    ///////////////////
    // View functions
    ///////////////////

    /**
     * @notice Return oracle member index
     * @param oracleMember oracle member address
     */
    function getOracleMemberIndex(
        address oracleMember
    ) external view returns (uint256) {
        for (uint256 i = 0; i < oracleMembers.length; ++i) {
            if (oracleMembers[i] == oracleMember) {
                return i;
            }
        }

        // In case the oracle member does not exist, revert
        revert(
            "DappnodeSmoothingPool::getOracleMemberIndex: Oracle member not found"
        );
    }

    /**
     * @notice Return all the oracle members
     */
    function getAllOracleMembers() external view returns (address[] memory) {
        return oracleMembers;
    }

    /**
     * @notice Return oracle members count
     */
    function getOracleMembersCount() external view returns (uint256) {
        return oracleMembers.length;
    }

    /**
     * @notice Get the report hash given the rewards root and slot
     * @param _slot Slot
     * @param _rewardsRoot Rewards root
     */
    function getReportHash(
        uint64 _slot,
        bytes32 _rewardsRoot
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_slot, _rewardsRoot));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}