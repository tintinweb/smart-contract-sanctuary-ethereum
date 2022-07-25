// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "src/utils/KernelUtils.sol";

// ######################## ~ ERRORS ~ ########################

// MODULE

error Module_PolicyNotAuthorized(address policy_);

// POLICY

error Policy_OnlyKernel(address caller_);
error Policy_OnlyRole(Role role_);
error Policy_ModuleDoesNotExist(Keycode keycode_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_OnlyAdmin(address caller_);
error Kernel_ModuleAlreadyInstalled(Keycode module_);
error Kernel_InvalidModuleUpgrade(Keycode module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);
error Kernel_AddressAlreadyHasRole(address address_);
error Kernel_RoleAlreadyExistsForAddress(Role role_);
error Kernel_RoleDoesNotExistForAddress(address address_);
error Kernel_InvalidTargetNotAContract(address target_);
error Kernel_InvalidKeycode(Keycode keycode_);
error Kernel_InvalidRole(Role role_);

// ######################## ~ GLOBAL TYPES ~ ########################

enum Actions {
    InstallModule,
    UpgradeModule,
    ApprovePolicy,
    TerminatePolicy,
    ChangeExecutor,
    ChangeAdmin
}

struct Instruction {
    Actions action;
    address target;
}

struct Permissions {
    Keycode keycode;
    bytes4 funcSelector;
}

// ######################## ~ MODULE ABSTRACT ~ ########################

abstract contract Module {
    event PermissionSet(bytes4 funcSelector_, address policy_, bool permission_);

    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert Policy_OnlyKernel(msg.sender);
        _;
    }

    modifier permissioned() {
        if (!kernel.policyPermissions(Policy(msg.sender), KEYCODE(), msg.sig))
            revert Module_PolicyNotAuthorized(msg.sender);
        _;
    }

    function KEYCODE() public pure virtual returns (Keycode);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    /// @dev breaking change to the interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module.
    /// @dev This function is called when the module is installed or upgraded by the kernel.
    /// @dev Used to encompass any upgrade logic. Must be gated by onlyKernel.
    function INIT() external virtual onlyKernel {}
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

    modifier onlyRole(bytes32 role_) {
        if (fromRole(kernel.getRoleOfAddress(msg.sender)) != role_)
            revert Policy_OnlyRole(Role.wrap(role_));
        _;
    }

    function configureDependencies() external virtual onlyKernel returns (Keycode[] memory dependencies) {}

    function requestPermissions() external view virtual onlyKernel returns (Permissions[] memory requests) {}

    function getModuleAddress(Keycode keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));

        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);

        return moduleForKeycode;
    }
}

contract Kernel {
    // ######################## ~ VARS ~ ########################
    address public executor;
    address public admin;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    // Module Management
    mapping(Keycode => Module) public getModuleForKeycode; // get contract for module keycode
    mapping(Module => Keycode) public getKeycodeForModule; // get module keycode for contract
    mapping(Keycode => Policy[]) public moduleDependents;
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    // Length of this array is number of approved policies
    Policy[] public activePolicies;
    // Reverse lookup for policy index. NOTE: Offset by 1 to be able to use 0 as a null value
    mapping(Policy => uint256) public getPolicyIndex;

    // Module <> Policy Permissions
    mapping(Policy => mapping(Keycode => mapping(bytes4 => bool))) public policyPermissions; // for policy addr, check if they have permission to call the function int he module

    // Policy Roles
    mapping(address => Role) public getRoleOfAddress;
    mapping(Role => address) public getAddressOfRole;

    // ######################## ~ EVENTS ~ ########################

    event PermissionsUpdated(
        Policy indexed policy_,
        Keycode indexed keycode_,
        bytes4 funcSelector_,
        bool indexed granted_
    );

    event RolesUpdated(Role indexed role_, address indexed addr_, bool indexed granted_);

    event ActionExecuted(Actions indexed action_, address indexed target_);

    // ######################## ~ BODY ~ ########################

    constructor() {
        executor = msg.sender;
        admin = msg.sender;
    }

    // ######################## ~ MODIFIERS ~ ########################

    // Role reserved for governor or any executing address
    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    // Role for managing policy roles
    modifier onlyAdmin() {
        if (msg.sender != admin) revert Kernel_OnlyAdmin(msg.sender);
        _;
    }

    // ######################## ~ KERNEL INTERFACE ~ ########################

    function executeAction(Actions action_, address target_) external onlyExecutor {
        if (action_ == Actions.InstallModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());

            _installModule(Module(target_));
        } else if (action_ == Actions.UpgradeModule) {
            ensureContract(target_);
            ensureValidKeycode(Module(target_).KEYCODE());

            _upgradeModule(Module(target_));
        } else if (action_ == Actions.ApprovePolicy) {
            ensureContract(target_);

            _approvePolicy(Policy(target_));
        } else if (action_ == Actions.TerminatePolicy) {
            ensureContract(target_);

            _terminatePolicy(Policy(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.ChangeAdmin) {
            admin = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(Module newModule_) internal {
        Keycode keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;

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

    function _approvePolicy(Policy policy_) internal {
        if (getPolicyIndex[policy_] != 0) revert Kernel_PolicyAlreadyApproved(address(policy_));

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length;

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
    }

    function _terminatePolicy(Policy policy_) internal {
        if (getPolicyIndex[policy_] == 0) revert Kernel_PolicyNotApproved(address(policy_));

        // Revoke permissions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, false);

        // Remove policy from all policy data structures
        uint256 idx = getPolicyIndex[policy_] - 1;
        Policy lastPolicy = activePolicies[activePolicies.length - 1];

        activePolicies[idx] = lastPolicy;
        activePolicies.pop();
        getPolicyIndex[lastPolicy] = idx + 1;
        delete getPolicyIndex[policy_];

        // Remove policy from module dependents
        _pruneFromDependents(policy_);
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
            policyPermissions[policy_][request.keycode][request.funcSelector] = grant_;

            emit PermissionsUpdated(policy_, request.keycode, request.funcSelector, grant_);

            unchecked {
                ++i;
            }
        }
    }

    /*
    // TODO Naiive implementation. O(n*m). Optimize.
    function _pruneFromDependents(Policy policy_) internal {
        Keycode[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            Policy[] storage dependents = moduleDependents[dependencies[i]];
            uint256 deptLength = dependents.length;

            for (uint256 j; j < deptLength; ) {
                if (dependents[j] == policy_) {
                    // Swap with last element if its not last element
                    if(j != deptLength - 1) {
                        dependents[j] = dependents[deptLength - 1];
                    }
                    dependents.pop();
                    break;
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }
    */

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

            // Record new index and delete terminated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }

    function registerRole(address address_, Role role_) public onlyAdmin {
        if (fromRole(getRoleOfAddress[address_]) != bytes32(0))
            revert Kernel_AddressAlreadyHasRole(address_);
        if (getAddressOfRole[role_] != address(0)) revert Kernel_RoleAlreadyExistsForAddress(role_);

        ensureValidRole(role_);

        getRoleOfAddress[address_] = role_;
        getAddressOfRole[role_] = address_;
    }

    function revokeRole(address address_) public onlyAdmin {
        Role roleOfAddress = getRoleOfAddress[address_];
        if (getAddressOfRole[roleOfAddress] == address(0))
            revert Kernel_RoleDoesNotExistForAddress(address_);

        getAddressOfRole[roleOfAddress] = address(0);
        getRoleOfAddress[address_] = Role.wrap(bytes32(0));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);
error InvalidRole(Role role_);

type Keycode is bytes5;
type Role is bytes32;

function toKeycode(bytes5 keycode_) pure returns (Keycode) {
    return Keycode.wrap(keycode_);
}

function fromKeycode(Keycode keycode_) pure returns (bytes5) {
    return Keycode.unwrap(keycode_);
}

function toRole(bytes32 role_) pure returns (Role) {
    return Role.wrap(role_);
}

function fromRole(Role role_) pure returns (bytes32) {
    return Role.unwrap(role_);
}

function ensureContract(address target_) view {
    uint256 size;
    assembly ("memory-safe") {
        size := extcodesize(target_)
    }
    if (size == 0) revert TargetNotAContract(target_);
}

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

function ensureValidRole(Role role_) pure {
    bytes32 unwrapped = Role.unwrap(role_);

    for (uint256 i = 0; i < 32; ) {
        bytes1 char = unwrapped[i];
        if ((char < 0x61 || char > 0x7A) && char != 0x00) {
            revert InvalidRole(role_); // a-z only
        }
        unchecked {
            i++;
        }
    }
}