// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
pragma solidity ^0.8.15;

import "src/utils/KernelUtils.sol";

// ######################## ~ ERRORS ~ ########################

// KERNEL ADAPTER

error KernelAdapter_OnlyKernel(address caller_);

// MODULE

error Module_PolicyNotAuthorized(address policy_);

// POLICY

error Policy_OnlyRole(Role role_);
error Policy_ModuleDoesNotExist(Keycode keycode_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_OnlyAdmin(address caller_);
error Kernel_ModuleAlreadyInstalled(Keycode module_);
error Kernel_InvalidModuleUpgrade(Keycode module_);
error Kernel_PolicyAlreadyApproved(address policy_);
error Kernel_PolicyNotApproved(address policy_);
error Kernel_AddressAlreadyHasRole(address addr_, Role role_);
error Kernel_AddressDoesNotHaveRole(address addr_, Role role_);
error Kernel_RoleDoesNotExist(Role role_);

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
    Keycode keycode;
    bytes4 funcSelector;
}

type Keycode is bytes5;
type Role is bytes32;

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

abstract contract Policy is KernelAdapter  {

    bool public isActive;

    constructor(Kernel kernel_) KernelAdapter(kernel_) {}

    modifier onlyRole(bytes32 role_) {
        Role role = toRole(role_);
        if(!kernel.hasRole(msg.sender, role))
            revert Policy_OnlyRole(role);
        _;
    }

    function configureDependencies() external virtual onlyKernel returns (Keycode[] memory dependencies) {}

    function requestPermissions() external view virtual onlyKernel returns (Permissions[] memory requests) {}

    function getModuleAddress(Keycode keycode_) internal view returns (address) {
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
    Keycode[] public allKeycodes;
    mapping(Keycode => Module) public getModuleForKeycode; // get contract for module keycode
    mapping(Module => Keycode) public getKeycodeForModule; // get module keycode for contract
    
    // Module dependents data. Manages module dependencies for policies
    mapping(Keycode => Policy[]) public moduleDependents;
    mapping(Keycode => mapping(Policy => uint256)) public getDependentIndex;

    // Module <> Policy Permissions. Policy -> Keycode -> Function Selector -> Permission
    mapping(Keycode => mapping(Policy => mapping(bytes4 => bool))) public modulePermissions; // for policy addr, check if they have permission to call the function in the module

    // List of all active policies
    Policy[] public activePolicies;
    mapping(Policy => uint256) public getPolicyIndex;

    // Policy roles data
    mapping(address => mapping(Role => bool)) public hasRole;
    mapping(Role => bool) public isRole;

    // ######################## ~ EVENTS ~ ########################

    event PermissionsUpdated(
        Keycode indexed keycode_,
        Policy indexed policy_,
        bytes4 funcSelector_,
        bool granted_
    );
    event RoleGranted(Role indexed role_, address indexed addr_);
    event RoleRevoked(Role indexed role_, address indexed addr_);
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
        if (policy_.isActive()) revert Kernel_PolicyAlreadyApproved(address(policy_));

        // Grant permissions for policy to access restricted module functions
        Permissions[] memory requests = policy_.requestPermissions();
        _setPolicyPermissions(policy_, requests, true);

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

            // Record new index and delete terminated policy index
            getDependentIndex[keycode][lastPolicy] = origIndex;
            delete getDependentIndex[keycode][policy_];

            unchecked {
                ++i;
            }
        }
    }

    function grantRole(Role role_, address addr_) public onlyAdmin {
        if (hasRole[addr_][role_]) revert Kernel_AddressAlreadyHasRole(addr_, role_);

        ensureValidRole(role_);
        if (!isRole[role_]) isRole[role_] = true;

        hasRole[addr_][role_] = true;

        emit RoleGranted(role_, addr_);
    }

    function revokeRole(Role role_, address addr_) public onlyAdmin {
        if (!isRole[role_]) revert Kernel_RoleDoesNotExist(role_);
        if (!hasRole[addr_][role_]) revert Kernel_AddressDoesNotHaveRole(addr_, role_);

        hasRole[addr_][role_] = false;

        emit RoleRevoked(role_, addr_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

// [VOTES] The Votes Module is the ERC20 token that represents voting power in the network.

pragma solidity ^0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Kernel, Module, Keycode } from "src/Kernel.sol";

error IsAlreadyReserveAsset();
error NotReserveAsset();

contract DefaultTreasury is Module {

    constructor(Kernel kernel_, ERC20[] memory initialAssets_) Module(kernel_) {
        uint256 length = initialAssets_.length;
        for (uint256 i; i < length;) {
            ERC20 asset = initialAssets_[i];
            isReserveAsset[asset] = true;
            reserveAssets.push(asset);
            unchecked {
                ++i;
            }
        }   
    }

    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("TRSRY");
    }

    // VARIABLES

    mapping(ERC20 => bool) public isReserveAsset;
    ERC20[] public reserveAssets;

    // Policy Interface

    function getReserveAssets() public view returns (ERC20[] memory reserveAssets_) {
        reserveAssets_ = reserveAssets;
    }

    // whitelisting: add and remove reserve assets (if the treasury supports these currencies)

    function addReserveAsset(ERC20 asset_) public permissioned {
        if (isReserveAsset[asset_]) {revert IsAlreadyReserveAsset();}
        isReserveAsset[asset_] = true;
        reserveAssets.push(asset_);
    }

    function removeReserveAsset(ERC20 asset_) public permissioned {
        if (!isReserveAsset[asset_]) {revert NotReserveAsset();}       
        isReserveAsset[asset_] = false;
        
        uint numAssets = reserveAssets.length;
        for (uint i; i < numAssets;) {
            if (reserveAssets[i] == asset_) {
                reserveAssets[i] = reserveAssets[numAssets - 1];
                reserveAssets.pop();
                break;
            }
            unchecked {++i;}
        }
    }

    // more convenient than "transferFrom", since users only have to approve the Treasury
    // and any policy can make approved transfers on the Treasury's behalf.
    // beware of approving malicious policies that can rug the user.

    function depositFrom(address depositor_, ERC20 asset_, uint256 amount_) external permissioned {
        if (!isReserveAsset[asset_]) {revert NotReserveAsset();}
        asset_.transferFrom(depositor_, address(this), amount_);
    }

    // must withdraw assets to approved policies, where withdrawn assets are handled in their internal logic.
    // no direct withdraws to arbitrary addresses allowed.
    function withdraw(ERC20 asset_, uint256 amount_) external permissioned {
        if (!isReserveAsset[asset_]) {revert NotReserveAsset();}
        asset_.transfer(msg.sender, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

// [VOTES] The Votes Module is the ERC20 token that represents voting power in the network.

pragma solidity ^0.8.15;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { Kernel, Module, Keycode } from "src/Kernel.sol";

error VOTES_TransferDisabled();

contract DefaultVotes is Module, ERC20 {
    constructor(Kernel kernel_) Module(kernel_) ERC20("Voting Tokens", "VOTES", 3) {}

    function KEYCODE() public pure override returns (Keycode) {
        return Keycode.wrap("VOTES");
    }

    // Policy Interface

    function mintTo(address wallet_, uint256 amount_) external permissioned {
        _mint(wallet_, amount_);
    }

    function burnFrom(address wallet_, uint256 amount_) external permissioned {
        _burn(wallet_, amount_);
    }

    function transfer(address, uint256) public override returns (bool) {
        revert VOTES_TransferDisabled();
        return true;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public override permissioned returns (bool) {
        // skip the approve function because callers must be pre-approved via governance

        balanceOf[from_] -= amount_;
        unchecked {
            balanceOf[to_] += amount_;
        }

        emit Transfer(from_, to_, amount_);
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Proxy Bonds are a modified gradual dutch auction mechanism for protocols to sell their native tokens.

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { DefaultVotes } from "../modules/VOTES.sol";
import { DefaultTreasury } from "../modules/TRSRY.sol";
import { Kernel, Policy, Permissions, Keycode } from "../Kernel.sol";
import { toKeycode } from "../utils/KernelUtils.sol";

pragma solidity ^0.8.15;


interface IBond {
    
    // purchasing
    event TokensPurchased(address buyer, uint256 tokens, uint256 totalCost);
    error NotEnoughInventory();
    error ExecutionPriceTooHigh();
}


contract Bond is Policy, IBond {


    /////////////////////////////////////////////////////////////////////////////////
    //                         Kernel Policy Configuration                         //
    /////////////////////////////////////////////////////////////////////////////////


    DefaultVotes public VOTES;
    DefaultTreasury public TRSRY;

    constructor(Kernel kernel_, ERC20 DAI_) Policy(kernel_) {
        DAI = DAI_; // set the address of payment currency
    }

    function configureDependencies() external override onlyKernel returns (Keycode[] memory dependencies) {
        dependencies = new Keycode[](2);
        
        dependencies[0] = toKeycode("VOTES");
        VOTES = DefaultVotes(getModuleAddress(toKeycode("VOTES")));

        dependencies[1] = toKeycode("TRSRY");
        TRSRY = DefaultTreasury(getModuleAddress(toKeycode("TRSRY")));
    }

    function requestPermissions() external view override onlyKernel returns (Permissions[] memory requests) {
        requests = new Permissions[](2);
        requests[0] = Permissions(toKeycode("VOTES"), VOTES.mintTo.selector);
        requests[1] = Permissions(toKeycode("TRSRY"), TRSRY.depositFrom.selector);

    }


    /////////////////////////////////////////////////////////////////////////////////
    //                                Policy Variables                             //
    /////////////////////////////////////////////////////////////////////////////////


    ERC20 public DAI; // DAI contract addr

    uint256 public constant EMISSION_RATE = 25000; // tokens added to auction inventory per day
    uint256 public constant SLIPPAGE_RATE = 15; // price increase per token, denominated in 1/10,000th's of a cent (+ 15c / 10,000 tokens)
    uint256 public constant PRICE_DECAY_RATE = 187_500; // the rate that token prices decay each day, denominated in 1/10,000th's of a cent (~.19c / day)
    uint256 public constant MAX_INVENTORY = 1_000_000; // maximum number of tokens available for purchase in the auction
    uint256 public constant RESERVE_PRICE = 1_000_000; // lowest possible price for tokens to be sold in auction

    uint256 public basePrice = 1_000_000; // the base price of the auction after the last sale, priced in 1/10,000th's of a cent (starts at $1.00)
    uint256 public prevSaleTimestamp = block.timestamp; // the timestamp of the last purchase made at the bond
    
    uint256 internal prevInventory = 400_000; // the amount of tokens available for purchase in the auction (initially 400,000 PROX)


    /////////////////////////////////////////////////////////////////////////////////
    //                              View Functions                                 //
    /////////////////////////////////////////////////////////////////////////////////


    // Utility Functions.

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    // INVENTORY

    // The auction can hold up to a maximum of 1,000,000 tokens in the inventory at a given time. 
    // The inventory "refills" over time at a rate of 25,000 tokens per day.

    function getCurrentInventory() public view returns (uint256 currentInventory) {
        // calculate the total tokens available in the auction since based on available inventory and emissions
        uint256 newEmissions = (block.timestamp - prevSaleTimestamp) * EMISSION_RATE / 1 days;

        // calculate the current inventory based on previous inventory and new emissions
        currentInventory = _min(prevInventory + newEmissions, MAX_INVENTORY);
    }


    // PRICE

    // The auction price is a factor of two variables how many tokens are purchased and 
    // time elapsed since the previous sale. Each token purchased increases the price of
    // each subsequent token, and the price goes down linearly over time.

    /// @param tokensPurchased_ The integer amount of tokens to purchase
    /// @return totalCost the total cost in dollars. $1 = 1e6.
    /// @return newBasePrice the new base price in dollars. $1 = 1e6.
    function getTotalCost(uint256 tokensPurchased_) public view returns (uint256 totalCost, uint256 newBasePrice) {
        // price decay in cents, decays $ // maximum amount of liquidity that can be 0.25 per day ($0.01c every 3456 seconds, or ~57 minutes)
        uint256 priceDecay = (block.timestamp - prevSaleTimestamp) * PRICE_DECAY_RATE / 1 days;

        // calculate starting price of current sale based on the last recorded base price and timestamp from the previous sale
        uint256 startingPrice = basePrice > priceDecay ? _max(basePrice - priceDecay, RESERVE_PRICE) : RESERVE_PRICE;

        // final price of current sale including slippage from on tokens purchased
        uint256 finalPrice = startingPrice + (SLIPPAGE_RATE * tokensPurchased_);

        // get the average execution price
        totalCost = tokensPurchased_ * ((startingPrice + finalPrice) / 2);
        newBasePrice = finalPrice;
    }

    /// @param tokensPurchased_ the integer amount of tokens to purchase
    /// @param maxPrice_ the price in dollars. $1 = 1e6
    function purchase(uint256 tokensPurchased_, uint256 maxPrice_) external {

        uint256 currentInventory = getCurrentInventory();
        (uint256 totalCost, uint256 newBasePrice) = getTotalCost(tokensPurchased_);

        // revert the tx if there's not enough liquidity in the auction for the desired purchase amount
        if (tokensPurchased_ > currentInventory) { revert NotEnoughInventory(); }

        // revert if the execution price is worse than the minPrice_
        if (totalCost > maxPrice_ * tokensPurchased_) { revert ExecutionPriceTooHigh(); }

        // save the new inventory after purchase
        prevInventory = currentInventory - tokensPurchased_;

        // reset the purchase timestamp
        prevSaleTimestamp = block.timestamp;

        // set the new base price after purchase
        basePrice = newBasePrice;

        // transfer dai from and mint VOTES to buyer
        TRSRY.depositFrom(msg.sender, DAI, totalCost * 1e12); // total DAI = totalCost * 1e18 (decimals) / 1e6 (10,000th's of a cent), in dollars
        VOTES.mintTo(msg.sender, tokensPurchased_ * 1e3);

        emit TokensPurchased(msg.sender, tokensPurchased_, totalCost);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {Keycode, Role} from "../Kernel.sol";

error TargetNotAContract(address target_);
error InvalidKeycode(Keycode keycode_);
error InvalidRole(Role role_);

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
    assembly("memory-safe") {
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