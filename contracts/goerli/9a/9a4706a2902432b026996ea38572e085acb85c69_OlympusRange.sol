// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {RANGEv1} from "src/modules/RANGE/RANGE.v1.sol";
import "src/Kernel.sol";

/// @notice Olympus Range data storage module
/// @dev    The Olympus Range contract stores information about the Olympus Range market operations status.
///         It provides a standard interface for Range data, including range prices and capacities of each range side.
///         The data provided by this contract is used by the Olympus Range Operator to perform market operations.
///         The Olympus Range Data is updated each epoch by the Olympus Range Operator contract.
contract OlympusRange is RANGEv1 {
    uint256 public constant ONE_HUNDRED_PERCENT = 100e2;
    uint256 public constant ONE_PERCENT = 1e2;

    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        ERC20 ohm_,
        ERC20 reserve_,
        uint256 thresholdFactor_,
        uint256 cushionSpread_,
        uint256 wallSpread_
    ) Module(kernel_) {
        // Validate parameters
        if (
            wallSpread_ >= ONE_HUNDRED_PERCENT ||
            wallSpread_ < ONE_PERCENT ||
            cushionSpread_ >= ONE_HUNDRED_PERCENT ||
            cushionSpread_ < ONE_PERCENT ||
            cushionSpread_ > wallSpread_ ||
            thresholdFactor_ >= ONE_HUNDRED_PERCENT ||
            thresholdFactor_ < ONE_PERCENT
        ) revert RANGE_InvalidParams();

        _range = Range({
            low: Side({
                active: false,
                lastActive: uint48(block.timestamp),
                capacity: 0,
                threshold: 0,
                market: type(uint256).max
            }),
            high: Side({
                active: false,
                lastActive: uint48(block.timestamp),
                capacity: 0,
                threshold: 0,
                market: type(uint256).max
            }),
            cushion: Band({low: Line({price: 0}), high: Line({price: 0}), spread: cushionSpread_}),
            wall: Band({low: Line({price: 0}), high: Line({price: 0}), spread: wallSpread_})
        });

        thresholdFactor = thresholdFactor_;
        ohm = ohm_;
        reserve = reserve_;

        emit SpreadsChanged(cushionSpread_, wallSpread_);
        emit ThresholdFactorChanged(thresholdFactor_);
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("RANGE");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 0;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc RANGEv1
    function updateCapacity(bool high_, uint256 capacity_) external override permissioned {
        if (high_) {
            // Update capacity
            _range.high.capacity = capacity_;

            // If the new capacity is below the threshold, deactivate the wall if they are currently active
            if (capacity_ < _range.high.threshold && _range.high.active) {
                // Set wall to inactive
                _range.high.active = false;
                _range.high.lastActive = uint48(block.timestamp);

                emit WallDown(true, block.timestamp, capacity_);
            }
        } else {
            // Update capacity
            _range.low.capacity = capacity_;

            // If the new capacity is below the threshold, deactivate the wall if they are currently active
            if (capacity_ < _range.low.threshold && _range.low.active) {
                // Set wall to inactive
                _range.low.active = false;
                _range.low.lastActive = uint48(block.timestamp);

                emit WallDown(false, block.timestamp, capacity_);
            }
        }
    }

    /// @inheritdoc RANGEv1
    function updatePrices(uint256 movingAverage_) external override permissioned {
        // Cache the spreads
        uint256 wallSpread = _range.wall.spread;
        uint256 cushionSpread = _range.cushion.spread;

        // Calculate new wall and cushion values from moving average and spread
        _range.wall.low.price =
            (movingAverage_ * (ONE_HUNDRED_PERCENT - wallSpread)) /
            ONE_HUNDRED_PERCENT;
        _range.wall.high.price =
            (movingAverage_ * (ONE_HUNDRED_PERCENT + wallSpread)) /
            ONE_HUNDRED_PERCENT;

        _range.cushion.low.price =
            (movingAverage_ * (ONE_HUNDRED_PERCENT - cushionSpread)) /
            ONE_HUNDRED_PERCENT;
        _range.cushion.high.price =
            (movingAverage_ * (ONE_HUNDRED_PERCENT + cushionSpread)) /
            ONE_HUNDRED_PERCENT;

        emit PricesChanged(
            _range.wall.low.price,
            _range.cushion.low.price,
            _range.cushion.high.price,
            _range.wall.high.price
        );
    }

    /// @inheritdoc RANGEv1
    function regenerate(bool high_, uint256 capacity_) external override permissioned {
        uint256 threshold = (capacity_ * thresholdFactor) / ONE_HUNDRED_PERCENT;

        if (high_) {
            // Re-initialize the high side
            _range.high = Side({
                active: true,
                lastActive: uint48(block.timestamp),
                capacity: capacity_,
                threshold: threshold,
                market: _range.high.market
            });
        } else {
            // Reinitialize the low side
            _range.low = Side({
                active: true,
                lastActive: uint48(block.timestamp),
                capacity: capacity_,
                threshold: threshold,
                market: _range.low.market
            });
        }

        emit WallUp(high_, block.timestamp, capacity_);
    }

    /// @inheritdoc RANGEv1
    function updateMarket(
        bool high_,
        uint256 market_,
        uint256 marketCapacity_
    ) public override permissioned {
        // If market id is max uint256, then marketCapacity must be 0
        if (market_ == type(uint256).max && marketCapacity_ != 0) revert RANGE_InvalidParams();

        // Store updated state
        if (high_) {
            _range.high.market = market_;
        } else {
            _range.low.market = market_;
        }

        if (market_ == type(uint256).max) {
            emit CushionDown(high_, block.timestamp);
        } else {
            emit CushionUp(high_, block.timestamp, marketCapacity_);
        }
    }

    /// @inheritdoc RANGEv1
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_)
        external
        override
        permissioned
    {
        // Confirm spreads are within allowed values
        if (
            wallSpread_ >= ONE_HUNDRED_PERCENT ||
            wallSpread_ < ONE_PERCENT ||
            cushionSpread_ >= ONE_HUNDRED_PERCENT ||
            cushionSpread_ < ONE_PERCENT ||
            cushionSpread_ > wallSpread_
        ) revert RANGE_InvalidParams();

        // Set spreads
        _range.wall.spread = wallSpread_;
        _range.cushion.spread = cushionSpread_;

        emit SpreadsChanged(cushionSpread_, wallSpread_);
    }

    /// @inheritdoc RANGEv1
    function setThresholdFactor(uint256 thresholdFactor_) external override permissioned {
        if (thresholdFactor_ >= ONE_HUNDRED_PERCENT || thresholdFactor_ < ONE_PERCENT)
            revert RANGE_InvalidParams();
        thresholdFactor = thresholdFactor_;

        emit ThresholdFactorChanged(thresholdFactor_);
    }

    //============================================================================================//
    //                                      VIEW FUNCTIONS                                        //
    //============================================================================================//

    /// @inheritdoc RANGEv1
    function range() external view override returns (Range memory) {
        return _range;
    }

    /// @inheritdoc RANGEv1
    function capacity(bool high_) external view override returns (uint256) {
        if (high_) {
            return _range.high.capacity;
        } else {
            return _range.low.capacity;
        }
    }

    /// @inheritdoc RANGEv1
    function active(bool high_) external view override returns (bool) {
        if (high_) {
            return _range.high.active;
        } else {
            return _range.low.active;
        }
    }

    /// @inheritdoc RANGEv1
    function price(bool wall_, bool high_) external view override returns (uint256) {
        if (wall_) {
            if (high_) {
                return _range.wall.high.price;
            } else {
                return _range.wall.low.price;
            }
        } else {
            if (high_) {
                return _range.cushion.high.price;
            } else {
                return _range.cushion.low.price;
            }
        }
    }

    /// @inheritdoc RANGEv1
    function spread(bool wall_) external view override returns (uint256) {
        if (wall_) {
            return _range.wall.spread;
        } else {
            return _range.cushion.spread;
        }
    }

    /// @inheritdoc RANGEv1
    function market(bool high_) external view override returns (uint256) {
        if (high_) {
            return _range.high.market;
        } else {
            return _range.low.market;
        }
    }

    /// @inheritdoc RANGEv1
    function lastActive(bool high_) external view override returns (uint256) {
        if (high_) {
            return _range.high.lastActive;
        } else {
            return _range.low.lastActive;
        }
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import "src/Kernel.sol";

abstract contract RANGEv1 is Module {
    // =========  EVENTS ========= //

    event WallUp(bool high_, uint256 timestamp_, uint256 capacity_);
    event WallDown(bool high_, uint256 timestamp_, uint256 capacity_);
    event CushionUp(bool high_, uint256 timestamp_, uint256 capacity_);
    event CushionDown(bool high_, uint256 timestamp_);
    event PricesChanged(
        uint256 wallLowPrice_,
        uint256 cushionLowPrice_,
        uint256 cushionHighPrice_,
        uint256 wallHighPrice_
    );
    event SpreadsChanged(uint256 cushionSpread_, uint256 wallSpread_);
    event ThresholdFactorChanged(uint256 thresholdFactor_);

    // =========  ERRORS ========= //

    error RANGE_InvalidParams();

    // =========  STATE ========= //

    struct Line {
        uint256 price; // Price for the specified level
    }

    struct Band {
        Line high; // Price of the high side of the band
        Line low; // Price of the low side of the band
        uint256 spread; // Spread of the band (increase/decrease from the moving average to set the band prices), percent with 2 decimal places (i.e. 1000 = 10% spread)
    }

    struct Side {
        bool active; // Whether or not the side is active (i.e. the Operator is performing market operations on this side, true = active, false = inactive)
        uint48 lastActive; // Unix timestamp when the side was last active (in seconds)
        uint256 capacity; // Amount of tokens that can be used to defend the side of the range. Specified in OHM tokens on the high side and Reserve tokens on the low side.
        uint256 threshold; // Amount of tokens under which the side is taken down. Specified in OHM tokens on the high side and Reserve tokens on the low side.
        uint256 market; // Market ID of the cushion bond market for the side. If no market is active, the market ID is set to max uint256 value.
    }

    struct Range {
        Side low; // Data specific to the low side of the range
        Side high; // Data specific to the high side of the range
        Band cushion; // Data relevant to cushions on both sides of the range
        Band wall; // Data relevant to walls on both sides of the range
    }

    // Range data singleton. See range().
    Range internal _range;

    /// @notice Threshold factor for the change, a percent in 2 decimals (i.e. 1000 = 10%). Determines how much of the capacity must be spent before the side is taken down.
    /// @dev    A threshold is required so that a wall is not "active" with a capacity near zero, but unable to be depleted practically (dust).
    uint256 public thresholdFactor;

    /// @notice OHM token contract address
    ERC20 public ohm;

    /// @notice Reserve token contract address
    ERC20 public reserve;

    // =========  FUNCTIONS ========= //

    /// @notice Update the capacity for a side of the range.
    /// @notice Access restricted to activated policies.
    /// @param  high_ - Specifies the side of the range to update capacity for (true = high side, false = low side).
    /// @param  capacity_ - Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateCapacity(bool high_, uint256 capacity_) external virtual;

    /// @notice Update the prices for the low and high sides.
    /// @notice Access restricted to activated policies.
    /// @param  movingAverage_ - Current moving average price to set range prices from.
    function updatePrices(uint256 movingAverage_) external virtual;

    /// @notice Regenerate a side of the range to a specific capacity.
    /// @notice Access restricted to activated policies.
    /// @param  high_ - Specifies the side of the range to regenerate (true = high side, false = low side).
    /// @param  capacity_ - Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function regenerate(bool high_, uint256 capacity_) external virtual;

    /// @notice Update the market ID (cushion) for a side of the range.
    /// @notice Access restricted to activated policies.
    /// @param  high_ - Specifies the side of the range to update market for (true = high side, false = low side).
    /// @param  market_ - Market ID to set for the side.
    /// @param  marketCapacity_ - Amount to set the last market capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateMarket(
        bool high_,
        uint256 market_,
        uint256 marketCapacity_
    ) external virtual;

    /// @notice Set the wall and cushion spreads.
    /// @notice Access restricted to activated policies.
    /// @param  cushionSpread_ - Percent spread to set the cushions at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @param  wallSpread_ - Percent spread to set the walls at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev    The new spreads will not go into effect until the next time updatePrices() is called.
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_) external virtual;

    /// @notice Set the threshold factor for when a wall is considered "down".
    /// @notice Access restricted to activated policies.
    /// @param  thresholdFactor_ - Percent of capacity that the wall should close below, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev    The new threshold factor will not go into effect until the next time regenerate() is called for each side of the wall.
    function setThresholdFactor(uint256 thresholdFactor_) external virtual;

    /// @notice Get the full Range data in a struct.
    function range() external view virtual returns (Range memory);

    /// @notice Get the capacity for a side of the range.
    /// @param  high_ - Specifies the side of the range to get capacity for (true = high side, false = low side).
    function capacity(bool high_) external view virtual returns (uint256);

    /// @notice Get the status of a side of the range (whether it is active or not).
    /// @param  high_ - Specifies the side of the range to get status for (true = high side, false = low side).
    function active(bool high_) external view virtual returns (bool);

    /// @notice Get the price for the wall or cushion for a side of the range.
    /// @param  wall_ - Specifies the band to get the price for (true = wall, false = cushion).
    /// @param  high_ - Specifies the side of the range to get the price for (true = high side, false = low side).
    function price(bool wall_, bool high_) external view virtual returns (uint256);

    /// @notice Get the spread for the wall or cushion band.
    /// @param  wall_ - Specifies the band to get the spread for (true = wall, false = cushion).
    function spread(bool wall_) external view virtual returns (uint256);

    /// @notice Get the market ID for a side of the range.
    /// @param  high_ - Specifies the side of the range to get market for (true = high side, false = low side).
    function market(bool high_) external view virtual returns (uint256);

    /// @notice Get the timestamp when the range was last active.
    /// @param  high_ - Specifies the side of the range to get timestamp for (true = high side, false = low side).
    function lastActive(bool high_) external view virtual returns (uint256);
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