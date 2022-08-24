// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Mintable.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IBarnStaking.sol";
import "../modules/XBOND.sol";
import {Kernel, Policy, Permissions} from "../Kernel.sol";

error CannotMintZeroTokens();
error CannotCancelWarmup();
error WarmupPeriodNotComplete();

error CannotBurnZeroTokens();
error CannotCancelCooldown();
error CooldownPeriodNotComplete();

// This contract handles swapping to and from xBOND, BarnBridge's staking token.
contract BarnStakingPolicy is Policy, IBarnStaking {
    XBOND public xBOND;
    address public TOKEN;

    struct Period {
        uint256 bondAmount; // Amount of BOND deposited or going to receive
        uint256 xBondAmount; // Amount of xBOND return or going to receive
        uint256 timestamp; // timestamp for when the action occured
    }

    event WarmupInitiated(uint256 bondAmount, uint256 xBondAmount, address staker);
    event WarmupCancelled(uint256 bondAmount, uint256 xBondAmount, address staker);
    event BondStaked(uint256 bondAmount, uint256 xBondAmount, address staker);
    event CooldownInitiated(uint256 bondAmount, uint256 xBondAmount, address staker);
    event CooldownCancelled(uint256 bondAmount, uint256 xBondAmount, address staker);
    event BondRedeemed(uint256 bondAmount, uint256 xBondAmount, address staker);

    // The amount of XBOND that hasn't been minted
    uint256 public xBondWarmupTotalSupply;
    // The amount of BOND that hasn't been transfered out of the contract
    uint256 public bondCooldownTotalSupply;

    // Tracking users warmup balance
    mapping(address => Period) public balanceWarmup;
    // Tracking users cooldown balance
    mapping(address => Period) public balanceCooldown;

    // Define the BOND token contract
    constructor(Kernel _kernel, address _token) Policy(_kernel) {
        TOKEN = _token;
    }

    function configureDependencies() external override onlyKernel returns (bytes5[] memory dependencies) {
        dependencies = new bytes5[](1);

        dependencies[0] = "XBOND";
        xBOND = XBOND(getModuleAddress("XBOND"));
    }

    function requestPermissions() external view override onlyKernel returns (Permissions[] memory requests) {
        requests = new Permissions[](2);
        requests[0] = Permissions("XBOND", xBOND.mint.selector);
        requests[1] = Permissions("XBOND", xBOND.burn.selector);
    }

    // function configureReads() external override {
    //     xBOND = XBOND(getModuleAddress("XBOND"));
    // }

    // function requestRoles() external view override onlyKernel returns (bytes32[] memory roles) {
    //     roles = new bytes32[](1);
    //     roles[0] = xBOND.ISSUER();
    // }

    /// @notice Pay some BOND. Lock your tokens in a warmup period
    /// @param _amount Amount of BOND
    /// @param _staker Address to receive the xBOND shares
    function initiateWarmup(uint256 _amount, address _staker) external {
        if (_staker == address(0)) _staker = msg.sender;
        // Gets the amount of BOND locked in the contract, accounting for the amount that has said they are leaving
        uint256 totalBond = IERC20(TOKEN).balanceOf(address(this));
        uint256 totalBondShares = totalBond - bondCooldownTotalSupply;
        // Gets the amount of xBOND in existence, accounting for the amount that has said they are staking
        uint256 totalXBond = xBOND.totalSupply();
        uint256 totalXBondShares = totalXBond + xBondWarmupTotalSupply;
        // If no xBOND exists, mint it 1:1 to the amount put in
        if (totalXBondShares == 0 || totalBondShares == 0) {
            xBondWarmupTotalSupply += _amount;
            balanceWarmup[_staker] = Period({
                xBondAmount: balanceWarmup[_staker].xBondAmount + _amount,
                bondAmount: balanceWarmup[_staker].bondAmount + _amount,
                timestamp: block.timestamp
            });
            emit WarmupInitiated(_amount, _amount, _staker);
        } else {
            uint256 what = (_amount * totalXBondShares) / totalBondShares;
            xBondWarmupTotalSupply += what;
            balanceWarmup[_staker] = Period({
                xBondAmount: balanceWarmup[_staker].xBondAmount + what,
                bondAmount: balanceWarmup[_staker].bondAmount + _amount,
                timestamp: block.timestamp
            });
            emit WarmupInitiated(_amount, what, _staker);
        }
        // Pull BARN from the caller, lock the BARN in the contract
        IERC20(TOKEN).transferFrom(msg.sender, address(this), _amount);
    }

    function cancelWarmup() external {
        uint256 xBondAmount = balanceWarmup[msg.sender].xBondAmount;
        uint256 bondAmount = balanceWarmup[msg.sender].bondAmount;
        if (bondAmount == 0 || xBondAmount == 0) {
            revert CannotCancelWarmup();
        }
        // Decrementing the warmup total supply because the msg.sender is leaving
        xBondWarmupTotalSupply -= xBondAmount;
        // Resetting the msg.senders warmup balance back to 0
        balanceWarmup[msg.sender].bondAmount = 0;
        balanceWarmup[msg.sender].xBondAmount = 0;
        // Transferring the msg.sender their locked BOND tokens
        IERC20(TOKEN).transfer(msg.sender, bondAmount);
        emit WarmupCancelled(bondAmount, xBondAmount, msg.sender);
    }

    /// @notice Pay some BOND. Earn some shares. Locks BOND and mints xBOND
    /// @param _staker Address to receive the xBOND shares
    function enter(address _staker) external {
        if (_staker == address(0)) _staker = msg.sender;

        // Getting warmup balance
        uint256 xBondAmount = balanceWarmup[_staker].xBondAmount;
        uint256 bondAmount = balanceWarmup[_staker].bondAmount;
        if (bondAmount == 0 || xBondAmount == 0) {
            revert CannotMintZeroTokens();
        }
        // Ensuring the warmup period has passed
        if (balanceWarmup[_staker].timestamp + xBOND.warmupPeriod() > block.timestamp) {
            revert WarmupPeriodNotComplete();
        }
        // Decrementing the warmup total supply
        xBondWarmupTotalSupply -= xBondAmount;
        // Resetting the stakers warmup balance to 0
        balanceWarmup[_staker].xBondAmount = 0;
        balanceWarmup[_staker].bondAmount = 0;
        // Minting the stakes XBOND
        xBOND.mint(_staker, xBondAmount);
        emit BondStaked(bondAmount, xBondAmount, _staker);
    }

    /// @notice Initiate the cooldown to claim your BOND back.
    /// @param _share Amount of xBOND you are burning
    function initiateCooldown(uint256 _share) external {
        // Get the total amount of BOND in the contract, accounting for the amount that has said they are leaving
        uint256 totalBond = IERC20(TOKEN).balanceOf(address(this));
        uint256 totalBondShares = totalBond - bondCooldownTotalSupply;
        // Gets the total amount of xBOND in existence, accounting for the amount that has said they are staking
        uint256 totalXBond = xBOND.totalSupply();
        uint256 totalXBondShares = totalXBond + xBondWarmupTotalSupply;
        // Calculates the amount of BOND the xBOND is worth - scaling already implied here
        uint256 what = (_share * totalBondShares) / (totalXBondShares);
        xBOND.burn(msg.sender, _share);
        // Incrementing the amount of BOND that is already account to leaving the system
        bondCooldownTotalSupply += what;
        balanceCooldown[msg.sender] = Period({
            bondAmount: balanceCooldown[msg.sender].bondAmount + what,
            xBondAmount: balanceCooldown[msg.sender].xBondAmount + _share,
            timestamp: block.timestamp
        });
        emit CooldownInitiated(what, _share, msg.sender);
    }

    function cancelCooldown() external {
        uint256 xBondAmount = balanceCooldown[msg.sender].xBondAmount;
        uint256 bondAmount = balanceCooldown[msg.sender].bondAmount;
        if (bondAmount == 0 || xBondAmount == 0) {
            revert CannotCancelCooldown();
        }
        // Decrementing the cooldown total supply because the msg.sender is staying
        bondCooldownTotalSupply -= bondAmount;
        // Resetting the stakers cooldown balance to 0
        balanceCooldown[msg.sender].xBondAmount = 0;
        balanceCooldown[msg.sender].bondAmount = 0;
        xBOND.mint(msg.sender, xBondAmount);
        emit CooldownCancelled(bondAmount, xBondAmount, msg.sender);
    }

    // Claim back your BOND.
    function leave() external {
        uint256 xBondAmount = balanceCooldown[msg.sender].xBondAmount;
        uint256 bondAmount = balanceCooldown[msg.sender].bondAmount;
        if (bondAmount == 0 || xBondAmount == 0) {
            revert CannotBurnZeroTokens();
        }
        // Ensure the cooldown period has passed
        if (balanceCooldown[msg.sender].timestamp + xBOND.cooldownPeriod() > block.timestamp) {
            revert CooldownPeriodNotComplete();
        }
        // Decrementing the cooldown total supply because the msg.sender is exiting
        bondCooldownTotalSupply -= bondAmount;
        // Resetting the stakers cooldown balance to 0
        balanceCooldown[msg.sender].xBondAmount = 0;
        balanceCooldown[msg.sender].bondAmount = 0;
        // Transfering BOND tokens to the msg.sender
        IERC20(TOKEN).transfer(msg.sender, bondAmount);
        emit BondRedeemed(bondAmount, xBondAmount, msg.sender);
    }

    function currentRate() external view returns (uint256 xBondToReceive, uint256 bondToReceive) {
        // Gets the amount of BOND locked in the contract, accounting for the amount that has said they are leaving
        uint256 totalBond = IERC20(TOKEN).balanceOf(address(this));
        uint256 totalBondShares = totalBond - bondCooldownTotalSupply;
        // Gets the amount of xBOND in existence, accounting for the amount that has said they are staking
        uint256 totalXBond = xBOND.totalSupply();
        uint256 totalXBondShares = totalXBond + xBondWarmupTotalSupply;
        xBondToReceive = (totalXBondShares * 1E18) / totalBondShares;
        bondToReceive = (totalBondShares * 1E18) / totalXBondShares;
    }
}

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Mintable {
  function mint( address account_, uint256 ammount_ ) external;
}

pragma solidity ^0.8.0;

interface IERC20Burnable {
    function burn(address account_, uint256 ammount_) external;
}

pragma solidity ^0.8.0;

interface IBarnStaking {
    function initiateWarmup(uint256 _amount, address _staker) external;

    function cancelWarmup() external;

    function enter(address _staker) external;

    function initiateCooldown(uint256 _share) external;

    function cancelCooldown() external;

    function leave() external;
}

// SPDX-License-Identifier: AGPL-3.0-only

// [XBOND] The xbond Module is the ERC20 token that represents voting power in the network.

pragma solidity ^0.8.10;

import {Kernel, Module} from "../Kernel.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

error XBOND_TransferDisabled();

contract XBOND is Module, ERC20 {
    // bytes32 public constant ISSUER = "XBOND_Issuer";
    // bytes32 public constant GOVERNOR = "XBOND_Governor";
    // bytes32 public constant MANAGER = "XBOND_Manager";

    enum PARAMETER {
        WARMUP,
        COOLDOWN
    }

    uint256 public warmupPeriod = 7 days;
    uint256 public cooldownPeriod = 7 days;

    constructor(Kernel kernel_) Module(kernel_) ERC20("StakedBOND", "XBOND", 18) {}

    function KEYCODE() public pure override returns (bytes5) {
        return "XBOND";
    }

    // function ROLES() public pure override returns (bytes32[] memory roles) {
    //     roles = new bytes32[](3);
    //     roles[0] = ISSUER;
    //     roles[1] = GOVERNOR;
    //     roles[2] = MANAGER;
    // }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function configureStakingPeriods(PARAMETER _parameter, uint256 _input) external permissioned {
        // onlyRole(MANAGER)
        if (_parameter == PARAMETER.WARMUP) {
            // 0
            require(_input >= 1 days, "Warmup must be greater than 1 day");
            warmupPeriod = _input;
        } else if (_parameter == PARAMETER.COOLDOWN) {
            // 1
            require(_input >= 1 days, "Cooldown must be greater than 1 day");
            cooldownPeriod = _input;
        }
    }

    // Policy Interface
    function mint(address wallet_, uint256 amount_) external permissioned {
        // onlyRole(ISSUER)
        _mint(wallet_, amount_);
    }

    function burn(address wallet_, uint256 amount_) external permissioned {
        //onlyRole(ISSUER)
        _burn(wallet_, amount_);
    }

    function transfer(address, uint256) public override returns (bool) {
        revert XBOND_TransferDisabled();
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public override permissioned returns (bool) {
        //onlyRole(GOVERNOR)
        balanceOf[from_] -= amount_;
        unchecked {
            balanceOf[to_] += amount_;
        }

        emit Transfer(from_, to_, amount_);
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./utils/KernelUtils.sol";

// ######################## ~ ERRORS ~ ########################

// KERNEL ADAPTER

error KernelAdapter_OnlyKernel(address caller_);

// MODULE

error Module_PolicyNotAuthorized(address policy_);

// POLICY

error Policy_OnlyRole(bytes32 role_);
error Policy_ModuleDoesNotExist(bytes5 keycode_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_OnlyAdmin(address caller_);
error Kernel_ModuleAlreadyInstalled(bytes5 module_);
error Kernel_InvalidModuleUpgrade(bytes5 module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);
error Kernel_AddressAlreadyHasRole(address addr_, bytes32 role_);
error Kernel_AddressDoesNotHaveRole(address addr_, bytes32 role_);
error Kernel_RoleDoesNotExist(bytes32 role_);

// ######################## ~ GLOBAL TYPES ~ ########################

enum Actions {
    InstallModule,
    UpgradeModule,
    ActivatePolicy,
    DeactivatePolicy,
    ChangeExecutor,
    ChangeAdmin,
    MigrateKernel
}

struct Instruction {
    Actions action;
    address target;
}

struct Permissions {
    bytes5 keycode;
    bytes4 funcSelector;
}

// type Keycode is bytes5;
// type Role is bytes32;

// ######################## ~ MODULE ABSTRACT ~ ########################

abstract contract KernelAdapter {
    Kernel public kernel;

    constructor(Kernel kernel_) {
        kernel = kernel_;
    }

    modifier onlyKernel() {
        if (msg.sender != address(kernel)) revert KernelAdapter_OnlyKernel(msg.sender);
        _;
    }

    function changeKernel(Kernel newKernel_) external onlyKernel {
        kernel = newKernel_;
    }
}

abstract contract Module is KernelAdapter {
    event PermissionSet(bytes4 funcSelector_, address policy_, bool permission_);

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier permissioned() {
        if (!kernel.modulePermissions(KEYCODE(), Policy(msg.sender), msg.sig))
            revert Module_PolicyNotAuthorized(msg.sender);
        _;
    }

    function KEYCODE() public pure virtual returns (bytes5);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    /// @dev breaking change to the interface.
    function VERSION() external pure virtual returns (uint8 major, uint8 minor) {}

    /// @notice Initialization function for the module.
    /// @dev This function is called when the module is installed or upgraded by the kernel.
    /// @dev Used to encompass any upgrade logic. Must be gated by onlyKernel.
    function INIT() external virtual onlyKernel {}
}

abstract contract Policy is KernelAdapter {
    bool public isActive;

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier onlyRole(bytes32 role_) {
        if (!kernel.hasRole(msg.sender, role_)) revert Policy_OnlyRole(role_);
        _;
    }

    function configureDependencies() external virtual onlyKernel returns (bytes5[] memory dependencies) {}

    function requestPermissions() external view virtual onlyKernel returns (Permissions[] memory requests) {}

    function getModuleAddress(bytes5 keycode_) internal view returns (address) {
        address moduleForKeycode = address(kernel.getModuleForKeycode(keycode_));
        if (moduleForKeycode == address(0)) revert Policy_ModuleDoesNotExist(keycode_);
        return moduleForKeycode;
    }

    /// @notice Function to let kernel grant or revoke active status
    function setActiveStatus(bool activate_) external onlyKernel {
        isActive = activate_;
    }
}

contract Kernel {
    // ######################## ~ VARS ~ ########################
    address public executor;
    address public admin;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    // Module Management
    bytes5[] public allKeycodes;
    mapping(bytes5 => Module) public getModuleForKeycode; // get contract for module keycode
    mapping(Module => bytes5) public getKeycodeForModule; // get module keycode for contract

    // Module dependents data. Manages module dependencies for policies
    mapping(bytes5 => Policy[]) public moduleDependents;
    mapping(bytes5 => mapping(Policy => uint256)) public getDependentIndex;

    // Module <> Policy Permissions. Policy -> Keycode -> Function Selector -> Permission
    mapping(bytes5 => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions; // for policy addr, check if they have permission to call the function int he module

    // List of all active policies
    Policy[] public activePolicies;
    mapping(Policy => uint256) public getPolicyIndex;

    // Policy roles data
    mapping(address => mapping(bytes32 => bool)) public hasRole;
    mapping(bytes32 => bool) public isRole;

    // ######################## ~ EVENTS ~ ########################

    event PermissionsUpdated(bytes5 indexed keycode_, Policy indexed policy_, bytes4 funcSelector_, bool granted_);
    event RoleGranted(bytes32 indexed role_, address indexed addr_);
    event RoleRevoked(bytes32 indexed role_, address indexed addr_);
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
        } else if (action_ == Actions.ActivatePolicy) {
            ensureContract(target_);
            _activatePolicy(Policy(target_));
        } else if (action_ == Actions.DeactivatePolicy) {
            ensureContract(target_);
            _deactivatePolicy(Policy(target_));
        } else if (action_ == Actions.MigrateKernel) {
            ensureContract(target_);
            _migrateKernel(Kernel(target_));
        } else if (action_ == Actions.ChangeExecutor) {
            executor = target_;
        } else if (action_ == Actions.ChangeAdmin) {
            admin = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(Module newModule_) internal {
        bytes5 keycode = newModule_.KEYCODE();

        if (address(getModuleForKeycode[keycode]) != address(0)) revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
        allKeycodes.push(keycode);

        newModule_.INIT();
    }

    function _upgradeModule(Module newModule_) internal {
        bytes5 keycode = newModule_.KEYCODE();
        Module oldModule = getModuleForKeycode[keycode];

        if (address(oldModule) == address(0) || oldModule == newModule_) revert Kernel_InvalidModuleUpgrade(keycode);

        getKeycodeForModule[oldModule] = bytes5(0);
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        newModule_.INIT();

        _reconfigurePolicies(keycode);
    }

    function _activatePolicy(Policy policy_) internal {
        if (policy_.isActive()) revert Kernel_PolicyAlreadyApproved(address(policy_));

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);

        // Add policy to list of active policies
        activePolicies.push(policy_);
        getPolicyIndex[policy_] = activePolicies.length - 1;

        // Record module dependencies
        bytes5[] memory dependencies = policy_.configureDependencies();
        uint256 depLength = dependencies.length;

        for (uint256 i; i < depLength; ) {
            bytes5 keycode = dependencies[i];

            moduleDependents[keycode].push(policy_);
            getDependentIndex[keycode][policy_] = moduleDependents[keycode].length - 1;

            unchecked {
                ++i;
            }
        }

        // Set policy status to active
        policy_.setActiveStatus(true);
    }

    function _deactivatePolicy(Policy policy_) internal {
        if (!policy_.isActive()) revert Kernel_PolicyNotApproved(address(policy_));

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

    // WARNING: ACTION WILL BRICK THIS KERNEL. All functionality will move to the new kernel
    // New kernel must add in all of the modules and policies via executeAction
    // NOTE: Data does not get cleared from this kernel
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

    function _reconfigurePolicies(bytes5 keycode_) internal {
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
        bytes5[] memory dependencies = policy_.configureDependencies();
        uint256 depcLength = dependencies.length;

        for (uint256 i; i < depcLength; ) {
            bytes5 keycode = dependencies[i];
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

    function grantRole(bytes32 role_, address addr_) public onlyAdmin {
        if (hasRole[addr_][role_]) revert Kernel_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);
        if (!isRole[role_]) isRole[role_] = true;

        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    function revokeRole(bytes32 role_, address addr_) public onlyAdmin {
        if (!isRole[role_]) revert Kernel_RoleDoesNotExist(role_);
        if (!hasRole[addr_][role_]) revert Kernel_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

error TargetNotAContract(address target_);
error InvalidKeycode(bytes5 keycode_);
error InvalidRole(bytes32 role_);

function ensureContract(address target_) view {
    uint256 size;
    assembly("memory-safe") {
        size := extcodesize(target_)
    }
    if (size == 0) revert TargetNotAContract(target_);
}

function ensureValidKeycode(bytes5 keycode_) pure {
    for (uint256 i = 0; i < 5; ) {
        bytes1 char = keycode_[i];

        if (char < 0x41 || char > 0x5A) revert InvalidKeycode(keycode_); // A-Z only

        unchecked {
            i++;
        }
    }
}

function ensureValidRole(bytes32 role_) pure {
    for (uint256 i = 0; i < 32; ) {
        bytes1 char = role_[i];
        if ((char < 0x61 || char > 0x7A) && char != 0x00) {
            revert InvalidRole(role_); // a-z only
        }
        unchecked {
            i++;
        }
    }
}