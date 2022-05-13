/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

contract Module {
    error Module_OnlyApprovedPolicy(address caller_);

    Kernel public _kernel;

    constructor(Kernel kernel_) {
        _kernel = kernel_;
    }

    function KEYCODE() external pure virtual returns (bytes3) {}

    modifier onlyPolicy() {
        if (_kernel.approvedPolicies(msg.sender) != true)
            revert Module_OnlyApprovedPolicy(msg.sender);
        _;
    }
}

contract Policy {
    error Policy_ModuleDoesNotExist(bytes3 keycode_);
    error Policy_OnlyKernel(address caller_);

    Kernel public _kernel;

    constructor(Kernel kernel_) {
        _kernel = kernel_;
    }

    function requireModule(bytes3 keycode_) internal view returns (address) {
        address moduleForKeycode = _kernel.getModuleForKeycode(keycode_);

        if (moduleForKeycode == address(0))
            revert Policy_ModuleDoesNotExist(keycode_);

        return moduleForKeycode;
    }

    function configureModules() external virtual onlyKernel {}

    modifier onlyKernel() {
        if (msg.sender != address(_kernel))
            revert Policy_OnlyKernel(msg.sender);
        _;
    }
}

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

contract Kernel {
    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(bytes3 module_);
    error Kernel_ModuleAlreadyExists(bytes3 module_);
    error Kernel_PolicyAlreadyApproved(address policy_);
    error Kernel_PolicyNotApproved(address policy_);

    address public executive;

    constructor() {
        executive = msg.sender;
    }

    modifier onlyExecutor() {
        if (msg.sender != executive) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    //                                 DEPENDENCY MANAGEMENT                             //
    ///////////////////////////////////////////////////////////////////////////////////////

    mapping(bytes3 => address) public getModuleForKeycode; // get contract for module keycode
    mapping(address => bytes3) public getKeycodeForModule; // get module keycode for contract
    mapping(address => bool) public approvedPolicies; // whitelisted apps
    address[] public allPolicies;

    event ActionExecuted(Actions action_, address target_);

    function executeAction(Actions action_, address target_)
        external
        onlyExecutor
    {
        if (action_ == Actions.InstallModule) {
            _installModule(target_);
        } else if (action_ == Actions.UpgradeModule) {
            _upgradeModule(target_);
        } else if (action_ == Actions.ApprovePolicy) {
            _approvePolicy(target_);
        } else if (action_ == Actions.TerminatePolicy) {
            _terminatePolicy(target_);
        } else if (action_ == Actions.ChangeExecutor) {
            // require Kernel to install the executor module before calling ChangeExecutor on it
            if (getKeycodeForModule[target_] != "GPU")
                revert Kernel_OnlyExecutor(target_);

            executive = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(address newModule_) internal {
        bytes3 keycode = Module(newModule_).KEYCODE();

        // @NOTE check newModule_ != 0
        if (getModuleForKeycode[keycode] != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
    }

    function _upgradeModule(address newModule_) internal {
        bytes3 keycode = Module(newModule_).KEYCODE();
        address oldModule = getModuleForKeycode[keycode];

        if (oldModule == address(0) || oldModule == newModule_)
            revert Kernel_ModuleAlreadyExists(keycode);

        getKeycodeForModule[oldModule] = bytes3(0);
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        _reconfigurePolicies();
    }

    function _approvePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == true)
            revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        allPolicies.push(policy_);
        Policy(policy_).configureModules();
    }

    function _terminatePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == false)
            revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;
    }

    function _reconfigurePolicies() internal {
        for (uint256 i = 0; i < allPolicies.length; i++) {
            address policy_ = allPolicies[i];
            if (approvedPolicies[policy_]) {
                Policy(policy_).configureModules();
            }
        }
    }
}