pragma solidity ^0.8.10;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../Kernel.sol";
import "../interfaces/IBarnStaking.sol";
import "../modules/BNDNG.sol";
import "../modules/TRSRY.sol";

contract BarnBondingPolicy is Policy {
    using SafeTransferLib for ERC20;
    address public TOKEN;
    BarnTreasury public TRSRY;
    BarnBondingModule public BNDNG;
    address public barnStaking;
    address public priceFeed;

    constructor(
        Kernel _kernel,
        address _token,
        address _barnStaking,
        address _priceFeed
    ) Policy(_kernel) {
        TOKEN = _token;
        barnStaking = _barnStaking;
        priceFeed = _priceFeed;
    }

    function configureReads() external override {
        BNDNG = BarnBondingModule(getModuleAddress("BNDNG"));
        TRSRY = BarnTreasury(getModuleAddress("TRSRY"));
    }

    function requestRoles() external view override onlyKernel returns (bytes32[] memory roles) {
        roles = new bytes32[](2);
        roles[0] = BNDNG.ALLOCATOR();
        roles[1] = TRSRY.EXECUTIVE();
    }

    /**
     *  @notice deposit bond
     *  @param _principle address
     *  @param _depositor address
     *  @param _amount uint
     *  @param _maxPrice uint
     */
    function deposit(
        address _principle,
        address _depositor,
        uint256 _amount,
        uint256 _maxPrice
    ) external {
        // If depositor isn't specified use msg.sender
        if (_depositor == address(0)) _depositor = msg.sender;
        require(BNDNG.pendingPayoutFor(_principle, _depositor) == 0, "Active Bond Exists");
        // Get current price of BOND from oracle
        uint256 price = BNDNG.bondPrice(_principle, bondPrice());
        require(price <= _maxPrice, "Max Price too high");
        // Decay amount of debt we have
        BNDNG.decayDebt(_principle);
        (, uint256 _maxDebt, , , uint256 _fee, uint256 _currentDebt) = BNDNG.getTerms(_principle);
        uint256 bondAvailable = _maxDebt - _currentDebt;
        uint256 value = (_amount * 1E8) / price;
        // Check to see if we have enough debt available for someone to bond
        if (value > bondAvailable) {
            value = bondAvailable;
            _amount = (value * price) / 1E8;
        }

        // Transfering from the user into the treasury
        ERC20(_principle).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_principle).approve(address(TRSRY), _amount);
        TRSRY.deposit(_principle, address(this), _amount);

        // TODEV: review formula
        // Get the amount of BOND the user should receive after bonding
        uint256 fee = (value * _fee) / 10_000;
        require(value > fee);
        value = value - fee;
        // Withdrawing BOND from the treasury to pay when bond fully vests
        TRSRY.withdraw(TOKEN, value);

        BNDNG.deposit(_principle, _depositor, price, value);
    }

    /**
     *  @notice redeem bond for user
     *  @param _principle address
     *  @param _recipient address
     *  @param _stake bool
     */
    function redeem(
        address _principle,
        address _recipient,
        bool _stake
    ) external {
        uint256 payout = BNDNG.redeem(_principle, msg.sender);
        stakeOrSend(_recipient, _stake, payout);
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _recipient address
     *  @param _stake bool
     *  @param _amount uint
     */
    function stakeOrSend(
        address _recipient,
        bool _stake,
        uint256 _amount
    ) internal {
        if (!_stake) {
            IERC20(TOKEN).transfer(_recipient, _amount); // send payout
        } else {
            IERC20(TOKEN).approve(barnStaking, _amount);
            IBarnStaking(barnStaking).initiateWarmup(_amount, _recipient);
        }
    }

    function bondPrice() internal view returns (uint256 _price) {
        (, int256 answer, , uint256 updatedAt, ) = AggregatorV3Interface(priceFeed).latestRoundData();
        require(updatedAt > block.timestamp - 1 days, "Price Feed is Stale");
        _price = uint256(answer);
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
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IBarnStaking {
    function initiateWarmup(uint256 _amount, address _staker) external;

    function enter(address _staker) external;

    function initiateCooldown(uint256 _share) external;

    function leave() external;
}

pragma solidity ^0.8.10;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "../Kernel.sol";

contract BarnBondingModule is Module {
    using SafeTransferLib for ERC20;

    bytes32 public constant ALLOCATOR = "BNDNG_Allocator";
    bytes32 public constant MANAGER = "BNDNG_Manager";

    //////////////////////////////////////////////////////////////////////////////
    //                              SYSTEM CONFIG                               //
    //////////////////////////////////////////////////////////////////////////////

    constructor(Kernel kernel_) Module(kernel_) {}

    function KEYCODE() public pure override returns (bytes5) {
        return "BNDNG";
    }

    function ROLES() public pure override returns (bytes32[] memory roles) {
        roles = new bytes32[](2);
        roles[0] = ALLOCATOR;
        roles[1] = MANAGER;
    }

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price, In thousandths of a % i.e. 500 = 0.5%
        uint256 maxDebt; // Maximum amount of debt we can take on
        uint256 decayLength; // Amount of time it takes for debt to decay
        uint256 vestingTerm; // in timestamp
        uint256 fee; // as % of bond payout, in hundreths. ( 50 = 0.5%)
    }

    enum PARAMETER {
        VESTING,
        DECAY,
        FEE,
        DEBT,
        CONTROL
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; // BOND remaining to be paid
        uint256 vesting; // Time left to vest
        uint256 lastBlockTimestamp; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
    }
    mapping(address => Terms) public terms; // stores terms for new bonds
    mapping(address => uint256) public lastDecay; // stores the timestamp for when the bond was last decayed
    mapping(address => uint256) public currentDebt; // stores the amount of debt we currently have for an asset
    mapping(address => mapping(address => Bond)) public bondInfo; // stores bond information for depositors
    mapping(address => bool) public acceptedAsset;

    /////////////////////////////////////////////////////////////////////////////////
    //                             Policy Interface                                //
    /////////////////////////////////////////////////////////////////////////////////

    event AssetAdded(address indexed token);
    event AssetRemoved(address indexed token);
    event BondCreated(address indexed token, uint256 payout, uint256 expires, uint256 price);
    event BondRedeemed(address indexed token, address recipient, uint256 payout, uint256 remaining);

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _fee uint
     *  @param _asset address
     */
    function configureBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _maxDebt,
        uint256 _decayLength,
        uint256 _fee,
        address _asset
    ) external onlyRole(MANAGER) {
        terms[_asset] = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            maxDebt: _maxDebt,
            decayLength: _decayLength,
            fee: _fee
        });
        if (lastDecay[_asset] == 0) lastDecay[_asset] = block.timestamp;
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _asset asset
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(
        address _asset,
        PARAMETER _parameter,
        uint256 _input
    ) external onlyRole(MANAGER) {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 129600, "Vesting must be longer than 36 hours");
            terms[_asset].vestingTerm = _input;
        } else if (_parameter == PARAMETER.DECAY) {
            // 1
            require(_input >= 1 days, "DAO decay must be greater than 1 day");
            terms[_asset].decayLength = _input;
        } else if (_parameter == PARAMETER.FEE) {
            // 2
            terms[_asset].fee = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 3
            terms[_asset].maxDebt = _input;
        } else if (_parameter == PARAMETER.CONTROL) {
            // 4
            terms[_asset].controlVariable = _input;
        }
    }

    /**
     *  @notice deposit bond
     *  @param _asset address
     *  @param _depositor address
     *  @param _priceInUSD uint
     *  @param _payout uint
     */
    function deposit(
        address _asset,
        address _depositor,
        uint256 _priceInUSD,
        uint256 _payout
    ) external onlyRole(ALLOCATOR) {
        require(acceptedAsset[_asset], "Asset hasn't been added");
        // depositor info is stored
        bondInfo[_depositor][_asset] = Bond({
            payout: bondInfo[_depositor][_asset].payout + _payout,
            vesting: terms[_asset].vestingTerm,
            lastBlockTimestamp: block.timestamp,
            pricePaid: _priceInUSD
        });
        currentDebt[_asset] += _payout;
        emit BondCreated(_asset, _payout, block.timestamp + terms[_asset].vestingTerm, _priceInUSD);
    }

    /**
     *  @notice redeem bond for user
     *  @param _asset address
     *  @param _recipient address
     *  @return uint
     */
    function redeem(address _asset, address _recipient) external onlyRole(ALLOCATOR) returns (uint256) {
        Bond memory info = bondInfo[_recipient][_asset];
        uint256 percentVested = percentVestedFor(_asset, _recipient); // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_recipient][_asset]; // delete user info
            emit BondRedeemed(_asset, _recipient, info.payout, 0); // emit bond data
            return info.payout;
        } else {
            uint256 payout = (info.payout * percentVested) / 10000;

            // store updated deposit info
            bondInfo[_recipient][_asset] = Bond({
                payout: info.payout - payout,
                vesting: info.vesting - (block.timestamp - info.lastBlockTimestamp),
                lastBlockTimestamp: block.timestamp,
                pricePaid: info.pricePaid
            });

            emit BondRedeemed(_asset, _recipient, payout, bondInfo[_recipient][_asset].payout);
            return payout;
        }
    }

    function decayDebt(address _asset) external onlyRole(ALLOCATOR) {
        Terms memory term = terms[_asset];
        uint256 decay = (term.maxDebt / term.decayLength) * (block.timestamp - lastDecay[_asset]);
        lastDecay[_asset] = block.timestamp;
        if (decay > currentDebt[_asset]) {
            currentDebt[_asset] = 0;
        } else {
            currentDebt[_asset] = currentDebt[_asset] - decay;
        }
    }

    function addAcceptedAsset(address token_) external onlyRole(MANAGER) {
        require(terms[token_].vestingTerm != 0, "Must have a valid term");
        acceptedAsset[token_] = true;

        emit AssetAdded(token_);
    }

    function removeAcceptedAsset(address token_) external onlyRole(MANAGER) {
        acceptedAsset[token_] = false;

        emit AssetRemoved(token_);
    }

    /////////////////////////////////////////////////////////////////////////////////
    //                            External Functions                               //
    /////////////////////////////////////////////////////////////////////////////////

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _asset address
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _asset, address _depositor) public view returns (uint256 percentVested_) {
        Bond memory bond = bondInfo[_depositor][_asset];
        uint256 blocksSinceLast = block.timestamp - bond.lastBlockTimestamp;
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = (blocksSinceLast * 10000) / vesting;
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of BOND available for claim by depositor
     *  @param _asset address
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _asset, address _depositor) external view returns (uint256 pendingPayout_) {
        uint256 percentVested = percentVestedFor(_asset, _depositor);
        uint256 payout = bondInfo[_depositor][_asset].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = (payout * percentVested) / 10000;
        }
    }

    function bondPrice(address _asset, uint256 currentPrice) external view returns (uint256 price_) {
        price_ = currentPrice - ((terms[_asset].controlVariable * currentPrice) / 100000);
    }

    function getTerms(address _asset)
        public
        view
        returns (
            uint256 controlVariable,
            uint256 maxDebt,
            uint256 decayLength,
            uint256 vestingTerm,
            uint256 fee,
            uint256 currentDebt_
        )
    {
        return (
            terms[_asset].controlVariable,
            terms[_asset].maxDebt,
            terms[_asset].decayLength,
            terms[_asset].vestingTerm,
            terms[_asset].fee,
            currentDebt[_asset]
        );
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or BARN) to the DAO
     *  @return bool
     */
    // function recoverLostToken(address _token) external returns (bool) {
    //     require(_token != BARN);
    //     require(_token != principle);
    //     IERC20(_token).safeTransfer(DAO, IERC20(_token).balanceOf(address(this)));
    //     return true;
    // }
}

pragma solidity ^0.8.10;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";

import "../interfaces/ITreasury.sol";
import "../Kernel.sol";

contract BarnTreasury is Module, ITreasury {
    bytes32 public constant MANAGER = "TRSRY_Manager";
    bytes32 public constant EXECUTIVE = "TRSRY_Executive";

    //////////////////////////////////////////////////////////////////////////////
    //                              SYSTEM CONFIG                               //
    //////////////////////////////////////////////////////////////////////////////

    constructor(Kernel kernel_) Module(kernel_) {}

    function KEYCODE() public pure override returns (bytes5) {
        return "TRSRY";
    }

    function ROLES() public pure override returns (bytes32[] memory roles) {
        roles = new bytes32[](2);
        roles[0] = EXECUTIVE;
        roles[1] = MANAGER;
    }

    // function KEYCODE() public pure override returns (bytes5) {
    //     return "TRSRY";
    // }

    mapping(address => bool) public trackedAsset;
    mapping(address => uint256) public totalInflowsForAsset;
    mapping(address => uint256) public totalOutflowsForAsset;

    ////////////////////////////////////////////////////////////////////////////
    //                           POLICY INTERFACE                             //
    ////////////////////////////////////////////////////////////////////////////

    function addTrackedAsset(address token_) external override onlyRole(MANAGER) {
        trackedAsset[token_] = true;

        emit AssetAdded(token_);
    }

    function deposit(
        address token_,
        address from_,
        uint256 amount_
    ) external override onlyRole(EXECUTIVE) {
        require(trackedAsset[token_], "cannot deposit(): token is not an accepted currency by the treasury");

        ERC20(token_).transferFrom(from_, address(this), amount_);

        totalInflowsForAsset[token_] += amount_;

        emit FundsDeposited(from_, token_, amount_);
    }

    function withdraw(address token_, uint256 amount_) external override onlyRole(EXECUTIVE) {
        require(trackedAsset[token_], "cannot withdraw(): token is not an accepted currency by the treasury");

        ERC20(token_).transfer(msg.sender, amount_);

        totalOutflowsForAsset[token_] += amount_;

        emit FundsWithdrawn(msg.sender, token_, amount_);
    }
}

pragma solidity ^0.8.0;

interface ITreasury {
  event AssetAdded(address indexed token);
  event FundsDeposited(address indexed token, address indexed from, uint256 amount);
  event FundsWithdrawn(address indexed token, address indexed to, uint256 amount);
  
  function addTrackedAsset(address token_) external;
  function deposit(address token_, address from_, uint256 amount_) external;
  function withdraw(address token_, uint256 amount_) external;
}