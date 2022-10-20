// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";

import {PRICEv1} from "src/modules/PRICE/PRICE.v1.sol";
import "src/Kernel.sol";

/// @notice Price oracle data storage contract.
contract OlympusPrice is PRICEv1 {
    // =========  STATE ========= //

    // Scale factor for converting prices, calculated from decimal values.
    uint256 internal immutable _scaleFactor;

    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        AggregatorV2V3Interface ohmEthPriceFeed_,
        uint48 ohmEthUpdateThreshold_,
        AggregatorV2V3Interface reserveEthPriceFeed_,
        uint48 reserveEthUpdateThreshold_,
        uint48 observationFrequency_,
        uint48 movingAverageDuration_
    ) Module(kernel_) {
        /// @dev Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (movingAverageDuration_ == 0 || movingAverageDuration_ % observationFrequency_ != 0)
            revert Price_InvalidParams();

        // Set price feeds, decimals, and scale factor
        ohmEthPriceFeed = ohmEthPriceFeed_;
        ohmEthUpdateThreshold = ohmEthUpdateThreshold_;
        uint8 ohmEthDecimals = ohmEthPriceFeed.decimals();

        reserveEthPriceFeed = reserveEthPriceFeed_;
        reserveEthUpdateThreshold = reserveEthUpdateThreshold_;
        uint8 reserveEthDecimals = reserveEthPriceFeed.decimals();

        uint256 exponent = decimals + reserveEthDecimals - ohmEthDecimals;
        if (exponent > 38) revert Price_InvalidParams();
        _scaleFactor = 10**exponent;

        // Set parameters and calculate number of observations
        observationFrequency = observationFrequency_;
        movingAverageDuration = movingAverageDuration_;

        numObservations = uint32(movingAverageDuration_ / observationFrequency_);

        // Store blank observations array
        observations = new uint256[](numObservations);
        // nextObsIndex is initialized to 0

        emit MovingAverageDurationChanged(movingAverageDuration_);
        emit ObservationFrequencyChanged(observationFrequency_);
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("PRICE");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc PRICEv1
    function updateMovingAverage() external override permissioned {
        // Revert if not initialized
        if (!initialized) revert Price_NotInitialized();

        // Cache numbe of observations to save gas.
        uint32 numObs = numObservations;

        // Get earliest observation in window
        uint256 earliestPrice = observations[nextObsIndex];

        uint256 currentPrice = getCurrentPrice();

        // Calculate new cumulative observation total
        cumulativeObs = cumulativeObs + currentPrice - earliestPrice;

        // Push new observation into storage and store timestamp taken at
        observations[nextObsIndex] = currentPrice;
        lastObservationTime = uint48(block.timestamp);
        nextObsIndex = (nextObsIndex + 1) % numObs;

        emit NewObservation(block.timestamp, currentPrice, getMovingAverage());
    }

    /// @inheritdoc PRICEv1
    function initialize(uint256[] memory startObservations_, uint48 lastObservationTime_)
        external
        override
        permissioned
    {
        if (initialized) revert Price_AlreadyInitialized();

        // Cache numObservations to save gas.
        uint256 numObs = observations.length;

        // Check that the number of start observations matches the number expected
        if (startObservations_.length != numObs || lastObservationTime_ > uint48(block.timestamp))
            revert Price_InvalidParams();

        // Push start observations into storage and total up observations
        uint256 total;
        for (uint256 i; i < numObs; ) {
            if (startObservations_[i] == 0) revert Price_InvalidParams();
            total += startObservations_[i];
            observations[i] = startObservations_[i];
            unchecked {
                ++i;
            }
        }

        // Set cumulative observations, last observation time, and initialized flag
        cumulativeObs = total;
        lastObservationTime = lastObservationTime_;
        initialized = true;
    }

    /// @inheritdoc PRICEv1
    function changeMovingAverageDuration(uint48 movingAverageDuration_)
        external
        override
        permissioned
    {
        // Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (movingAverageDuration_ == 0 || movingAverageDuration_ % observationFrequency != 0)
            revert Price_InvalidParams();

        // Calculate the new number of observations
        uint256 newObservations = uint256(movingAverageDuration_ / observationFrequency);

        // Store blank observations array of new size
        observations = new uint256[](newObservations);

        // Set initialized to false and update state variables
        initialized = false;
        lastObservationTime = 0;
        cumulativeObs = 0;
        nextObsIndex = 0;
        movingAverageDuration = movingAverageDuration_;
        numObservations = uint32(newObservations);

        emit MovingAverageDurationChanged(movingAverageDuration_);
    }

    /// @inheritdoc PRICEv1
    function changeObservationFrequency(uint48 observationFrequency_)
        external
        override
        permissioned
    {
        // Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (observationFrequency_ == 0 || movingAverageDuration % observationFrequency_ != 0)
            revert Price_InvalidParams();

        // Calculate the new number of observations
        uint256 newObservations = uint256(movingAverageDuration / observationFrequency_);

        // Since the old observations will not be taken at the right intervals,
        // the observations array will need to be reinitialized.
        // Although, there are a handful of situations that could be handled
        // (e.g. clean multiples of the old frequency),
        // it is easier to do so off-chain and reinitialize the array.

        // Store blank observations array of new size
        observations = new uint256[](newObservations);

        // Set initialized to false and update state variables
        initialized = false;
        lastObservationTime = 0;
        cumulativeObs = 0;
        nextObsIndex = 0;
        observationFrequency = observationFrequency_;
        numObservations = uint32(newObservations);

        emit ObservationFrequencyChanged(observationFrequency_);
    }

    //============================================================================================//
    //                                      VIEW FUNCTIONS                                        //
    //============================================================================================//

    /// @inheritdoc PRICEv1
    function getCurrentPrice() public view override returns (uint256) {
        if (!initialized) revert Price_NotInitialized();

        // Get prices from feeds
        uint256 ohmEthPrice;
        uint256 reserveEthPrice;
        {
            (
                uint80 roundId,
                int256 ohmEthPriceInt,
                ,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = ohmEthPriceFeed.latestRoundData();

            // Validate chainlink price feed data
            // 1. Answer should be greater than zero
            // 2. Updated at timestamp should be within the update threshold
            // 3. Answered in round ID should be the same as the round ID
            if (
                ohmEthPriceInt <= 0 ||
                updatedAt < block.timestamp - uint256(ohmEthUpdateThreshold) ||
                answeredInRound < roundId
            ) revert Price_BadFeed(address(ohmEthPriceFeed));
            ohmEthPrice = uint256(ohmEthPriceInt);

            int256 reserveEthPriceInt;
            (roundId, reserveEthPriceInt, , updatedAt, answeredInRound) = reserveEthPriceFeed
                .latestRoundData();
            if (
                reserveEthPriceInt <= 0 ||
                updatedAt < block.timestamp - uint256(reserveEthUpdateThreshold) ||
                answeredInRound < roundId
            ) revert Price_BadFeed(address(reserveEthPriceFeed));
            reserveEthPrice = uint256(reserveEthPriceInt);
        }

        // Convert to OHM/RESERVE price
        uint256 currentPrice = (ohmEthPrice * _scaleFactor) / reserveEthPrice;

        return currentPrice;
    }

    /// @inheritdoc PRICEv1
    function getLastPrice() external view override returns (uint256) {
        if (!initialized) revert Price_NotInitialized();
        uint32 lastIndex = nextObsIndex == 0 ? numObservations - 1 : nextObsIndex - 1;
        return observations[lastIndex];
    }

    /// @inheritdoc PRICEv1
    function getMovingAverage() public view override returns (uint256) {
        if (!initialized) revert Price_NotInitialized();
        return cumulativeObs / numObservations;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";
import "src/Kernel.sol";

/// @notice Price oracle data storage
/// @dev    The Olympus Price Oracle contract provides a standard interface for OHM price data against a reserve asset.
///         It also implements a moving average price calculation (same as a TWAP) on the price feed data over a configured
///         duration and observation frequency. The data provided by this contract is used by the Olympus Range Operator to
///         perform market operations. The Olympus Price Oracle is updated each epoch by the Olympus Heart contract.
abstract contract PRICEv1 is Module {
    // =========  EVENTS ========= //

    event NewObservation(uint256 timestamp_, uint256 price_, uint256 movingAverage_);
    event MovingAverageDurationChanged(uint48 movingAverageDuration_);
    event ObservationFrequencyChanged(uint48 observationFrequency_);

    // =========  ERRORS ========= //

    error Price_InvalidParams();
    error Price_NotInitialized();
    error Price_AlreadyInitialized();
    error Price_BadFeed(address priceFeed);

    // =========  STATE ========= //

    /// @dev    Price feeds. Chainlink typically provides price feeds for an asset in ETH. Therefore, we use two price feeds against ETH, one for OHM and one for the Reserve asset, to calculate the relative price of OHM in the Reserve asset.
    /// @dev    Update thresholds are the maximum amount of time that can pass between price feed updates before the price oracle is considered stale. These should be set based on the parameters of the price feed.

    /// @notice OHM/ETH price feed
    AggregatorV2V3Interface public ohmEthPriceFeed;

    /// @notice Maximum expected time between OHM/ETH price feed updates
    uint48 public ohmEthUpdateThreshold;

    /// @notice Reserve/ETH price feed
    AggregatorV2V3Interface public reserveEthPriceFeed;

    /// @notice Maximum expected time between OHM/ETH price feed updates
    uint48 public reserveEthUpdateThreshold;

    /// @notice    Running sum of observations to calculate the moving average price from
    /// @dev       See getMovingAverage()
    uint256 public cumulativeObs;

    /// @notice Array of price observations. Check nextObsIndex to determine latest data point.
    /// @dev    Observations are stored in a ring buffer where the moving average is the sum of all observations divided by the number of observations.
    ///         Observations can be cleared by changing the movingAverageDuration or observationFrequency and must be re-initialized.
    uint256[] public observations;

    /// @notice Index of the next observation to make. The current value at this index is the oldest observation.
    uint32 public nextObsIndex;

    /// @notice Number of observations used in the moving average calculation. Computed from movingAverageDuration / observationFrequency.
    uint32 public numObservations;

    /// @notice Frequency (in seconds) that observations should be stored.
    uint48 public observationFrequency;

    /// @notice Duration (in seconds) over which the moving average is calculated.
    uint48 public movingAverageDuration;

    /// @notice Unix timestamp of last observation (in seconds).
    uint48 public lastObservationTime;

    /// @notice Whether the price module is initialized (and therefore active).
    bool public initialized;

    /// @notice Number of decimals in the price values provided by the contract.
    uint8 public constant decimals = 18;

    // =========  FUNCTIONS ========= //

    /// @notice Trigger an update of the moving average. Permissioned.
    /// @dev    This function does not have a time-gating on the observationFrequency on this contract. It is set on the Heart policy contract.
    ///         The Heart beat frequency should be set to the same value as the observationFrequency.
    function updateMovingAverage() external virtual;

    /// @notice Initialize the price module
    /// @notice Access restricted to activated policies
    /// @param  startObservations_ - Array of observations to initialize the moving average with. Must be of length numObservations.
    /// @param  lastObservationTime_ - Unix timestamp of last observation being provided (in seconds).
    /// @dev    This function must be called after the Price module is deployed to activate it and after updating the observationFrequency
    ///         or movingAverageDuration (in certain cases) in order for the Price module to function properly.
    function initialize(uint256[] memory startObservations_, uint48 lastObservationTime_)
        external
        virtual;

    /// @notice Change the moving average window (duration)
    /// @param  movingAverageDuration_ - Moving average duration in seconds, must be a multiple of observation frequency
    /// @dev    Changing the moving average duration will erase the current observations array
    ///         and require the initialize function to be called again. Ensure that you have saved
    ///         the existing data and can re-populate before calling this function.
    function changeMovingAverageDuration(uint48 movingAverageDuration_) external virtual;

    /// @notice   Change the observation frequency of the moving average (i.e. how often a new observation is taken)
    /// @param    observationFrequency_ - Observation frequency in seconds, must be a divisor of the moving average duration
    /// @dev      Changing the observation frequency clears existing observation data since it will not be taken at the right time intervals.
    ///           Ensure that you have saved the existing data and/or can re-populate before calling this function.
    function changeObservationFrequency(uint48 observationFrequency_) external virtual;

    /// @notice Get the current price of OHM in the Reserve asset from the price feeds
    function getCurrentPrice() external view virtual returns (uint256);

    /// @notice Get the last stored price observation of OHM in the Reserve asset
    function getLastPrice() external view virtual returns (uint256);

    /// @notice Get the moving average of OHM in the Reserve asset over the defined window (see movingAverageDuration and observationFrequency).
    function getMovingAverage() external view virtual returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

//============================================================================================//
//                                        GLOBAL TYPES                                        //
//============================================================================================//

/// @notice Actions to trigger state changes in the kernel. Passed by the executor
enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    MigrateKernel
}

/// @notice Used by executor to select an action and a target contract for a kernel action
struct Instruction {
    Actions action;
    address target;
}

/// @notice Used to define which module functions a policy needs access to
struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;

//============================================================================================//
//                                       UTIL FUNCTIONS                                       //
//============================================================================================//

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);

// solhint-disable-next-line func-visibility
function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

// solhint-disable-next-line func-visibility
function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

// solhint-disable-next-line func-visibility
function ensureContract(address target_) view {
    if (target_.code.length == 0) revert TargetNotAContract(target_);
}

// solhint-disable-next-line func-visibility
function ensureValidKeycode(Keycode keycode_) pure {
    bytes5 unwrapped = Keycode.unwrap(keycode_);
    for (uint256 i = 0; i < 5; ) {
        bytes1 char = unwrapped[i];
        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only
        unchecked {
            i++;
        }
    }
}

//============================================================================================//
//                                        COMPONENTS                                          //
//============================================================================================//

/// @notice Generic adapter interface for kernel access in modules and policies.
abstract contract KernelAdapter {
    error KernelAdapter_OnlyKernel(address caller_);

    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    /// @notice Modifier to restrict functions to be called only by kernel.
    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    /// @notice Function used by kernel when migrating to a new kernel.
    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

/// @notice Base level extension of the kernel. Modules act as independent state components to be
///         interacted with and mutated through policies.
/// @dev    Modules are installed and uninstalled via the executor.
abstract contract Module is KernelAdapter {
    error Module_PolicyNotPermitted(address policy_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Modifier to restrict which policies have access to module functions.
    modifier permissioned() {
        if (!kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig))
            revert Module_PolicyNotPermitted(msg.sender);
        _;
    }

    /// @notice 5 byte identifier for a module.
    function KEYCODE() public pure virtual returns (Keycode) {}

    /// @notice Returns which semantic version of a module is being implemented.
    /// @return major - Major version upgrade indicates breaking change to the interface.
    /// @return minor - Minor version change retains backward-compatible interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module
    /// @dev    This function is called when the module is installed or upgraded by the kernel.
    /// @dev    MUST BE GATED BY onlyKernel. Used to encompass any initialization or upgrade logic.
    function INIT() external virtual onlyKernel {}
}

/// @notice Policies are application logic and external interface for the kernel and installed modules.
/// @dev    Policies are activated and deactivated in the kernel by the executor.
/// @dev    Module dependencies and function permissions must be defined in appropriate functions.
abstract contract Policy is KernelAdapter {
    error Policy_ModuleDoesNotExist(Keycode keycode_);

    /// @notice Denote if a policy is activated or not.
    bool public isActive;

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    /// @notice Function to let kernel grant or revoke active status.
    function setActiveStatus(bool activate_) external onlyKernel {
        isActive = activate_;
    }

    /// @notice Function to grab module address from a given keycode.
    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Define module dependencies for this policy.
    /// @return dependencies - Keycode array of module dependencies.
    function configureDependencies() external virtual returns (Keycode[] memory dependencies) {}

    /// @notice Function called by kernel to set module function permissions.
    /// @return requests - Array of keycodes and function selectors for requested permissions.
    function requestPermissions() external view virtual returns (Permissions[] memory requests) {}
}

/// @notice Main contract that acts as a central component registry for the protocol.
/// @dev    The kernel manages modules and policies. The kernel is mutated via predefined Actions,
/// @dev    which are input from any address assigned as the executor. The executor can be changed as needed.
contract Kernel {
    // =========  EVENTS ========= //

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event ActionExecuted(Actions indexed action_, address indexed target_);

    // =========  ERRORS ========= //

    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(Keycode module_);
    error Kernel_InvalidModuleUpgrade(Keycode module_);
    error Kernel_PolicyAlreadyActivated(address policy_);
    error Kernel_PolicyNotActivated(address policy_);

    // =========  PRIVILEGED ADDRESSES ========= //

    /// @notice Address that is able to initiate Actions in the kernel. Can be assigned to a multisig or governance contract.
    address public executor;

    // =========  MODULE MANAGEMENT ========= //

    /// @notice Array of all modules currently installed.
    Keycode[] public allKeycodes;

    /// @notice Mapping of module address to keycode.
    mapping(Keycode => Module) public getModuleForKeycode;

    /// @notice Mapping of keycode to module address.
    mapping(Module => Keycode) public getKeycodeForModule;

    /// @notice Mapping of a keycode to all of its policy dependents. Used to efficiently reconfigure policy dependencies.
    mapping(Keycode => Policy[]) public moduleDependents;

    /// @notice Helper for module dependent arrays. Prevents the need to loop through array.
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    /// @notice Module <> Policy Permissions.
    /// @dev    Keycode -> Policy -> Function Selector -> bool for permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions;

    // =========  POLICY MANAGEMENT ========= //

    /// @notice List of all active policies
    Policy[] public activePolicies;

    /// @notice Helper to get active policy quickly. Prevents need to loop through array.
    mapping(Policy => uint256) public getPolicyIndex;

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    constructor() {
        executor = msg.sender;
    }

    /// @notice Modifier to check if caller is the executor.
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    /// @notice Main kernel function. Initiates state changes to kernel depending on Action passed in.
    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());
            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_)
            revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (policy_.isActive() && activePolicies[getPolicyIndex[policy_]] == policy_)
            revert Kernel_PolicyAlreadyActivated(address(policy_));

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            Keycode keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);

        // Set policy status to active
        policy_.setActiveStatus(true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!policy_.isActive() && activePolicies[getPolicyIndex[policy_]] != policy_)
            revert Kernel_PolicyNotActivated(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_];
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);

        // Set policy status to inactive
        policy_.setActiveStatus(false);
    }

    /// @notice All functionality will move to the new kernel. WARNING: ACTION WILL BRICK THIS KERNEL.
    /// @dev    New kernel must add in all of the modules and policies via executeAction.
    /// @dev    NOTE: Data does not get cleared from this kernel.
    function _migrateKernel(Kernel newKernel_) internal {
        uint256 keycodeLen = allKeycodes.length;
        for (uint256 i; i < keycodeLen; ) {
            Module module = Module(getModuleForKeycode[allKeycodes[i]]);
            module.changeKernel(newKernel_);
            unchecked {
                ++i;
            }
        }

        uint256 policiesLen = activePolicies.length;
        for (uint256 j; j < policiesLen; ) {
            Policy policy = activePolicies[j];

            // Deactivate before changing kernel
            policy.setActiveStatus(false);
            policy.changeKernel(newKernel_);
            unchecked {
                ++j;
            }
        }
    }

    function _reconfigurePolicies(Keycode keycode_) internal {
        Policy[] memory dependents = moduleDependents[keycode_];
        uint256 depLength = dependents.length;

        for (uint256 i; i < depLength; ) {
            dependents[i].configureDependencies();

            unchecked {
                ++i;
            }
        }
    }

    function _setPolicyPermissions(
        Policy policy_,
        Permissions[] memory requests_,
        bool grant_
    ) internal {
        uint256 reqLength = requests_.length;
        for (uint256 i = 0; i < reqLength; ) {
            Permissions memory request = requests_[i];
            modulePermissions[request.keycode][policy_][request.funcSelector] = grant_;

            emit PermissionsUpdated(request.keycode, policy_, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Keycode keycode = dependencies[i];
            Policy[] storage dependents = moduleDependents[keycode];

            uint256 origIndex = getDependentIndex[keycode][policy_];
            Policy lastPolicy = dependents[dependents.length - 1];

            // Swap with last and pop
            dependents[origIndex] = lastPolicy;
            dependents.pop();

            // Record new index and delete deactivated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }
}