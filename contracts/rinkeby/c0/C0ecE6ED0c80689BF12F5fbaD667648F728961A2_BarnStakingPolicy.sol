// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Mintable.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IBarnStaking.sol";
import "../Kernel.sol";
import "../modules/XBOND.sol";

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

    function configureReads() external override {
        xBOND = XBOND(getModuleAddress("XBOND"));
    }

    function requestRoles() external view override onlyKernel returns (bytes32[] memory roles) {
        roles = new bytes32[](1);
        roles[0] = xBOND.ISSUER();
    }

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
        } else {
            uint256 what = (_amount * totalXBondShares) / totalBondShares;
            xBondWarmupTotalSupply += what;
            balanceWarmup[_staker] = Period({
                xBondAmount: balanceWarmup[_staker].xBondAmount + what,
                bondAmount: balanceWarmup[_staker].bondAmount + _amount,
                timestamp: block.timestamp
            });
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

    function enter(address _staker) external;

    function initiateCooldown(uint256 _share) external;

    function leave() external;
}

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
        if (kernel.hasRole(msg.sender, role_) == false) {
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
        if (approvedPolicies[policy_] == true) revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        Policy(policy_).configureReads();

        // Role[] memory requests = Policy(policy_).requestRoles();
        bytes32[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, true);

        allPolicies.push(policy_);
    }

    function _terminatePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == false) revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;

        // Role[] memory requests = Policy(policy_).requestRoles();
        bytes32[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, false);
    }

    function _reconfigurePolicies() internal {
        for (uint256 i = 0; i < allPolicies.length; i++) {
            address policy_ = allPolicies[i];

            if (approvedPolicies[policy_] == true) Policy(policy_).configureReads();
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

// SPDX-License-Identifier: AGPL-3.0-only

// [XBOND] The xbond Module is the ERC20 token that represents voting power in the network.

pragma solidity ^0.8.10;

import {Kernel, Module} from "../Kernel.sol";
import "@rari-capital/solmate/src/tokens/ERC20.sol";

error XBOND_TransferDisabled();

contract XBOND is Module, ERC20 {
    bytes32 public constant ISSUER = "XBOND_Issuer";
    bytes32 public constant GOVERNOR = "XBOND_Governor";
    bytes32 public constant MANAGER = "XBOND_Manager";

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

    function ROLES() public pure override returns (bytes32[] memory roles) {
        roles = new bytes32[](3);
        roles[0] = ISSUER;
        roles[1] = GOVERNOR;
        roles[2] = MANAGER;
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function configureStakingPeriods(PARAMETER _parameter, uint256 _input) external onlyRole(MANAGER) {
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
    function mint(address wallet_, uint256 amount_) external onlyRole(ISSUER) {
        _mint(wallet_, amount_);
    }

    function burn(address wallet_, uint256 amount_) external onlyRole(ISSUER) {
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
    ) public override onlyRole(GOVERNOR) returns (bool) {
        balanceOf[from_] -= amount_;
        unchecked {
            balanceOf[to_] += amount_;
        }

        emit Transfer(from_, to_, amount_);
        return true;
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