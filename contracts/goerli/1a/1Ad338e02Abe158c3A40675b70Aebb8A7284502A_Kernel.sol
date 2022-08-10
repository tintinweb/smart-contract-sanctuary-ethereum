// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

// ######################## ~ ERRORS ~ ########################

// MODULE

error Module_NotAuthorized();

// POLICY

// error Policy_ModuleDoesNotExist(Kernel.Keycode keycode_);
error Policy_ModuleDoesNotExist(bytes5 keycode_);
error Policy_OnlyKernel(address caller_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
// error Kernel_ModuleAlreadyInstalled(Kernel.Keycode module_);
// error Kernel_ModuleAlreadyExists(Kernel.Keycode module_);
error Kernel_ModuleAlreadyInstalled(bytes5 module_);
error Kernel_ModuleAlreadyExists(bytes5 module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);

// ######################## ~ GLOBAL TYPES ~ ########################

enum Actions {
    InstallModule,
    UpgradeModule,
    ApprovePolicy,
    TerminatePolicy,
    ChangeExecutor
}

struct Instruction {
    Actions action;
    address target;
}

// ######################## ~ CONTRACT TYPES ~ ########################

abstract contract Module {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    // Kernel.Role role_
    modifier onlyRole(bytes32 role_) {
        if (!kernel.hasRole(msg.sender, role_)) {
            revert Module_NotAuthorized();
        }
        _;
    }

    // function KEYCODE() public pure virtual returns (Kernel.Keycode);
    function KEYCODE() public pure virtual returns (bytes5);

    // function ROLES() public pure virtual returns (Kernel.Role[] memory roles);
    function ROLES() public pure virtual returns (bytes32[] memory roles);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    ///      breaking change to the interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}
}

abstract contract Policy {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert Policy_OnlyKernel(msg.sender);
        _;
    }

    function configureReads() external virtual onlyKernel {}

    // function requestRoles() external view virtual returns (Kernel.Role[] memory roles) {}
    function requestRoles() external view virtual returns (bytes32[] memory roles) {}

    function getModuleAddress(bytes5 keycode) internal view returns (address) {
        // Kernel.Keycode keycode = Kernel.Keycode.wrap(keycode_);
        address moduleForKeycode = kernel.getModuleForKeycode(keycode);

        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode);

        return moduleForKeycode;
    }
}

contract Kernel {
    // ######################## ~ TYPES ~ ########################

    // TODEV: throw error in @openzeppelin/hardhat-upgrades
    // type Role is bytes32;
    // type Keycode is bytes5;

    // ######################## ~ VARS ~ ########################

    address public executor;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    address[] public allPolicies;

    // Keycode => address
    mapping(bytes5 => address) public getModuleForKeycode; // get contract for module keycode

    // address => Keycode
    mapping(address => bytes5) public getKeycodeForModule; // get module keycode for contract

    mapping(address => bool) public approvedPolicies; // whitelisted apps

    // address => Role => bool
    mapping(address => mapping(bytes32 => bool)) public hasRole;

    // ######################## ~ EVENTS ~ ########################

    event RolesUpdated(bytes32 indexed role_, address indexed policy_, bool indexed granted_);

    event ActionExecuted(Actions indexed action_, address indexed target_);

    // ######################## ~ BODY ~ ########################

    constructor() {
        executor = msg.sender;
    }

    // ######################## ~ MODIFIERS ~ ########################

    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    // ######################## ~ KERNEL INTERFACE ~ ########################

    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            _installModule(target_);
        } else if (action_ == Actions.UpgradeModule) {
            _upgradeModule(target_);
        } else if (action_ == Actions.ApprovePolicy) {
            _approvePolicy(target_);
        } else if (action_ == Actions.TerminatePolicy) {
            _terminatePolicy(target_);
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(address newModule_) internal {
        // Keycode keycode = Module(newModule_).KEYCODE();
        bytes5 keycode = Module(newModule_).KEYCODE();

        // @NOTE check newModule_ != 0
        if (getModuleForKeycode[keycode] != address(0)) revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
    }

    function _upgradeModule(address newModule_) internal {
        // Keycode keycode = Module(newModule_).KEYCODE();
        bytes5 keycode = Module(newModule_).KEYCODE();
        address oldModule = getModuleForKeycode[keycode];

        if (oldModule == address(0) || oldModule == newModule_) revert Kernel_ModuleAlreadyExists(keycode);

        // getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[oldModule] = bytes5(0);
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        _reconfigurePolicies();
    }

    function _approvePolicy(address policy_) internal {
        if (approvedPolicies[policy_]) revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        Policy(policy_).configureReads();

        // Role[] memory requests = Policy(policy_).requestRoles();
        bytes32[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, true);

        allPolicies.push(policy_);
    }

    function _terminatePolicy(address policy_) internal {
        if (!approvedPolicies[policy_]) revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;

        // Role[] memory requests = Policy(policy_).requestRoles();
        bytes32[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, false);
    }

    function _reconfigurePolicies() internal {
        for (uint256 i = 0; i < allPolicies.length; i++) {
            address policy_ = allPolicies[i];

            if (approvedPolicies[policy_]) Policy(policy_).configureReads();
        }
    }

    // Role[] memory requests_,
    function _setPolicyRoles(
        address policy_,
        bytes32[] memory requests_,
        bool grant_
    ) internal {
        uint256 l = requests_.length;

        for (uint256 i = 0; i < l; ) {
            bytes32 request = requests_[i];

            hasRole[policy_][request] = grant_;

            emit RolesUpdated(request, policy_, grant_);

            unchecked {
                i++;
            }
        }
    }
}