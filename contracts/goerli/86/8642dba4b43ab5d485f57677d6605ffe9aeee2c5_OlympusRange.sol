// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import {TransferHelper} from "../libraries/TransferHelper.sol";
import {FullMath} from "../libraries/FullMath.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {Kernel, Module} from "../Kernel.sol";

error RANGE_InvalidParams();

/// @title  Olympus Range Data
/// @notice Olympus Range Data (Module) Contract
/// @dev    The Olympus Range Data contract stores information about the Olympus Range market operations status.
///         It provides a standard interface for Range data, including range prices and capacities of each range side.
///         The data provided by this contract is used by the Olympus Range Operator to perform market operations.
///         The Olympus Range Data is updated each epoch by the Olympus Range Operator contract.
contract OlympusRange is Module {
    using TransferHelper for ERC20;
    using FullMath for uint256;

    /* ========== EVENTS =========== */

    event WallUp(bool high, uint256 timestamp, uint256 capacity);
    event WallDown(bool high, uint256 timestamp);
    event CushionUp(bool high, uint256 timestamp, uint256 capacity);
    event CushionDown(bool high, uint256 timestamp);

    /* ========== STRUCTS =========== */

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
        uint256 lastMarketCapacity; // Capacity of the side's market at the last update. Used to determine how much capacity the market sold since the last update.
    }

    struct Range {
        Side low; // Data specific to the low side of the range
        Side high; // Data specific to the high side of the range
        Band cushion; // Data relevant to cushions on both sides of the range
        Band wall; // Data relevant to walls on both sides of the range
    }

    /* ========== STATE VARIABLES ========== */

    Kernel.Role public constant OPERATOR = Kernel.Role.wrap("RANGE_Operator");

    /// Range data singleton. See range().
    Range internal _range;

    /// @notice Threshold factor for the change, a percent in 2 decimals (i.e. 1000 = 10%). Determines how much of the capacity must be spent before the side is taken down.
    /// @dev    A threshold is required so that a wall is not "active" with a capacity near zero, but unable to be depleted practically (dust).
    uint256 public thresholdFactor;

    /// Constants
    uint256 public constant FACTOR_SCALE = 1e4;

    /// Tokens
    /// @notice OHM token contract address
    ERC20 public immutable ohm;

    /// @notice Reserve token contract address
    ERC20 public immutable reserve;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        Kernel kernel_,
        ERC20[2] memory tokens_,
        uint256[3] memory rangeParams_ // [thresholdFactor, cushionSpread, wallSpread]
    ) Module(kernel_) {
        _range = Range({
            low: Side({
                active: false,
                lastActive: uint48(block.timestamp),
                capacity: 0,
                threshold: 0,
                market: type(uint256).max,
                lastMarketCapacity: 0
            }),
            high: Side({
                active: false,
                lastActive: uint48(block.timestamp),
                capacity: 0,
                threshold: 0,
                market: type(uint256).max,
                lastMarketCapacity: 0
            }),
            cushion: Band({
                low: Line({price: 0}),
                high: Line({price: 0}),
                spread: rangeParams_[1]
            }),
            wall: Band({
                low: Line({price: 0}),
                high: Line({price: 0}),
                spread: rangeParams_[2]
            })
        });

        thresholdFactor = rangeParams_[0];
        ohm = tokens_[0];
        reserve = tokens_[1];
    }

    /* ========== FRAMEWORK CONFIGURATION ========== */
    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Kernel.Keycode) {
        return Kernel.Keycode.wrap("RANGE");
    }

    function ROLES() public pure override returns (Kernel.Role[] memory roles) {
        roles = new Kernel.Role[](1);
        roles[0] = OPERATOR;
    }

    /* ========== POLICY FUNCTIONS ========== */
    /// @notice                 Update the capacity for a side of the range.
    /// @notice                 Access restricted to approved policies.
    /// @param high_            Specifies the side of the range to update capacity for (true = high side, false = low side).
    /// @param capacity_        Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    /// @param marketCapacity_  Amount to set the market capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateCapacity(
        bool high_,
        uint256 capacity_,
        uint256 marketCapacity_
    ) external onlyRole(OPERATOR) {
        if (high_) {
            /// Update capacity and market capacity if they changed
            /// @dev the function is used by different modules which may not update both capacities at once
            /// checking if the values have changed saves potential SSTOREs
            if (_range.high.capacity != capacity_) {
                _range.high.capacity = capacity_;
            }
            if (_range.high.lastMarketCapacity != marketCapacity_) {
                _range.high.lastMarketCapacity = marketCapacity_;
            }

            /// If the new capacity is below the threshold, deactivate the cushion and wall if they are currently active
            if (capacity_ < _range.high.threshold && _range.high.active) {
                /// Set wall to inactive
                _range.high.active = false;
                _range.high.lastActive = uint48(block.timestamp);

                /// Set cushion to inactive
                updateMarket(true, type(uint256).max, 0);

                /// Emit event
                emit WallDown(true, block.timestamp);
            }
        } else {
            /// Update capacity and market capacity if they changed
            /// @dev the function is used by different modules which may not update both capacities at once
            /// checking if the values have changed saves potential SSTOREs
            if (_range.low.capacity != capacity_) {
                _range.low.capacity = capacity_;
            }
            if (_range.low.lastMarketCapacity != marketCapacity_) {
                _range.low.lastMarketCapacity = marketCapacity_;
            }

            /// If the new capacity is below the threshold, deactivate the cushion and wall if they are currently active
            if (capacity_ < _range.low.threshold && _range.low.active) {
                /// Set wall to inactive
                _range.low.active = false;
                _range.low.lastActive = uint48(block.timestamp);

                /// Set cushion to inactive
                updateMarket(false, type(uint256).max, 0);

                /// Emit event
                emit WallDown(false, block.timestamp);
            }
        }
    }

    /// @notice                 Update the prices for the low and high sides.
    /// @notice                 Access restricted to approved policies.
    /// @param movingAverage_   Current moving average price to set range prices from.
    function updatePrices(uint256 movingAverage_) external onlyRole(OPERATOR) {
        /// Cache the spreads
        uint256 wallSpread = _range.wall.spread;
        uint256 cushionSpread = _range.cushion.spread;

        /// Calculate new wall and cushion values from moving average and spread
        _range.wall.low.price =
            (movingAverage_ * (FACTOR_SCALE - wallSpread)) /
            FACTOR_SCALE;
        _range.wall.high.price =
            (movingAverage_ * (FACTOR_SCALE + wallSpread)) /
            FACTOR_SCALE;

        _range.cushion.low.price =
            (movingAverage_ * (FACTOR_SCALE - cushionSpread)) /
            FACTOR_SCALE;
        _range.cushion.high.price =
            (movingAverage_ * (FACTOR_SCALE + cushionSpread)) /
            FACTOR_SCALE;
    }

    /// @notice                 Regenerate a side of the range to a specific capacity.
    /// @notice                 Access restricted to approved policies.
    /// @param high_            Specifies the side of the range to regenerate (true = high side, false = low side).
    /// @param capacity_        Amount to set the capacity to (OHM tokens for high side, Reserve tokens for low side).
    function regenerate(bool high_, uint256 capacity_)
        external
        onlyRole(OPERATOR)
    {
        uint256 threshold = (capacity_ * thresholdFactor) / FACTOR_SCALE;

        if (high_) {
            /// Re-initialize the high side
            _range.high = Side({
                active: true,
                lastActive: uint48(block.timestamp),
                capacity: capacity_,
                threshold: threshold,
                market: type(uint256).max,
                lastMarketCapacity: 0
            });
        } else {
            /// Reinitialize the low side
            _range.low = Side({
                active: true,
                lastActive: uint48(block.timestamp),
                capacity: capacity_,
                threshold: threshold,
                market: type(uint256).max,
                lastMarketCapacity: 0
            });
        }

        emit WallUp(high_, block.timestamp, capacity_);
    }

    /// @notice                 Update the market ID and market capacity (cushion) for a side of the range.
    /// @notice                 Access restricted to approved policies.
    /// @param high_            Specifies the side of the range to update market for (true = high side, false = low side).
    /// @param market_          Market ID to set for the side.
    /// @param marketCapacity_  Amount to set the last market capacity to (OHM tokens for high side, Reserve tokens for low side).
    function updateMarket(
        bool high_,
        uint256 market_,
        uint256 marketCapacity_
    ) public onlyRole(OPERATOR) {
        /// If market id is max uint256, then marketCapacity must be 0
        if (market_ == type(uint256).max && marketCapacity_ != 0)
            revert RANGE_InvalidParams();

        /// Store updated state
        if (high_) {
            _range.high.market = market_;
            _range.high.lastMarketCapacity = marketCapacity_;
        } else {
            _range.low.market = market_;
            _range.low.lastMarketCapacity = marketCapacity_;
        }

        /// Emit events
        if (market_ == type(uint256).max) {
            emit CushionDown(high_, block.timestamp);
        } else {
            emit CushionUp(high_, block.timestamp, marketCapacity_);
        }
    }

    /// @notice                 Set the wall and cushion spreads.
    /// @notice                 Access restricted to approved policies.
    /// @param cushionSpread_   Percent spread to set the cushions at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @param wallSpread_      Percent spread to set the walls at above/below the moving average, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev The new spreads will not go into effect until the next time updatePrices() is called.
    function setSpreads(uint256 cushionSpread_, uint256 wallSpread_)
        external
        onlyRole(OPERATOR)
    {
        /// Confirm spreads are within allowed values
        if (
            wallSpread_ > 10000 ||
            wallSpread_ < 100 ||
            cushionSpread_ > 10000 ||
            cushionSpread_ < 100 ||
            cushionSpread_ > wallSpread_
        ) revert RANGE_InvalidParams();

        /// Set spreads
        _range.wall.spread = wallSpread_;
        _range.cushion.spread = cushionSpread_;
    }

    /// @notice                 Set the threshold factor for when a wall is considered "down".
    /// @notice                 Access restricted to approved policies.
    /// @param thresholdFactor_ Percent of capacity that the wall should close below, assumes 2 decimals (i.e. 1000 = 10%).
    /// @dev The new threshold factor will not go into effect until the next time regenerate() is called for each side of the wall.
    function setThresholdFactor(uint256 thresholdFactor_)
        external
        onlyRole(OPERATOR)
    {
        /// Confirm threshold factor is within allowed values
        if (thresholdFactor_ > 10000 || thresholdFactor_ < 100)
            revert RANGE_InvalidParams();

        /// Set threshold factor
        thresholdFactor = thresholdFactor_;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Get the full Range data in a struct.
    function range() external view returns (Range memory) {
        return _range;
    }

    /// @notice         Get the capacity for a side of the range.
    /// @param high_    Specifies the side of the range to get capacity for (true = high side, false = low side).
    function capacity(bool high_) external view returns (uint256) {
        if (high_) {
            return _range.high.capacity;
        } else {
            return _range.low.capacity;
        }
    }

    /// @notice         Get the status of a side of the range (whether it is active or not).
    /// @param high_    Specifies the side of the range to get status for (true = high side, false = low side).
    function active(bool high_) external view returns (bool) {
        if (high_) {
            return _range.high.active;
        } else {
            return _range.low.active;
        }
    }

    /// @notice         Get the price for the wall or cushion for a side of the range.
    /// @param wall_    Specifies the band to get the price for (true = wall, false = cushion).
    /// @param high_    Specifies the side of the range to get the price for (true = high side, false = low side).
    function price(bool wall_, bool high_) external view returns (uint256) {
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

    /// @notice        Get the spread for the wall or cushion band.
    /// @param wall_   Specifies the band to get the spread for (true = wall, false = cushion).
    function spread(bool wall_) external view returns (uint256) {
        if (wall_) {
            return _range.wall.spread;
        } else {
            return _range.cushion.spread;
        }
    }

    /// @notice         Get the market ID for a side of the range.
    /// @param high_    Specifies the side of the range to get market for (true = high side, false = low side).
    function market(bool high_) external view returns (uint256) {
        if (high_) {
            return _range.high.market;
        } else {
            return _range.low.market;
        }
    }

    /// @notice         Get the last market capacity for a side of the range.
    /// @param high_    Specifies the side of the range to get last market capacity for (true = high side, false = low side).
    function lastMarketCapacity(bool high_) external view returns (uint256) {
        if (high_) {
            return _range.high.lastMarketCapacity;
        } else {
            return _range.low.lastMarketCapacity;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Safe ERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// @author Taken from Solmate.
library TransferHelper {
    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(
                ERC20.transferFrom.selector,
                from,
                to,
                amount
            )
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.transfer.selector, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(ERC20.approve.selector, to, amount)
        );

        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "APPROVE_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// ######################## ~ ERRORS ~ ########################

// MODULE

error Module_NotAuthorized();

// POLICY

error Policy_ModuleDoesNotExist(Kernel.Keycode keycode_);
error Policy_OnlyKernel(address caller_);

// KERNEL

error Kernel_OnlyExecutor(address caller_);
error Kernel_ModuleAlreadyInstalled(Kernel.Keycode module_);
error Kernel_ModuleAlreadyExists(Kernel.Keycode module_);
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

    modifier onlyRole(Kernel.Role role_) {
        if (kernel.hasRole(msg.sender, role_) == false) {
            revert Module_NotAuthorized();
        }
        _;
    }

    function KEYCODE() public pure virtual returns (Kernel.Keycode);

    function ROLES() public pure virtual returns (Kernel.Role[] memory roles);

    /// @notice Specify which version of a module is being implemented.
    /// @dev Minor version change retains interface. Major version upgrade indicates
    ///      breaking change to the interface.
    function VERSION()
        external
        pure
        virtual
        returns (uint8 major, uint8 minor)
    {}
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

    function requestRoles()
        external
        view
        virtual
        returns (Kernel.Role[] memory roles)
    {}

    function getModuleAddress(bytes5 keycode_) internal view returns (address) {
        Kernel.Keycode keycode = Kernel.Keycode.wrap(keycode_);
        address moduleForKeycode = kernel.getModuleForKeycode(keycode);

        if (moduleForKeycode == address(0))
            revert Policy_ModuleDoesNotExist(keycode);

        return moduleForKeycode;
    }
}

contract Kernel {
    // ######################## ~ TYPES ~ ########################

    type Role is bytes32;
    type Keycode is bytes5;

    // ######################## ~ VARS ~ ########################

    address public executor;

    // ######################## ~ DEPENDENCY MANAGEMENT ~ ########################

    address[] public allPolicies;

    mapping(Keycode => address) public getModuleForKeycode; // get contract for module keycode

    mapping(address => Keycode) public getKeycodeForModule; // get module keycode for contract

    mapping(address => bool) public approvedPolicies; // whitelisted apps

    mapping(address => mapping(Role => bool)) public hasRole;

    // ######################## ~ EVENTS ~ ########################

    event RolesUpdated(
        Role indexed role_,
        address indexed policy_,
        bool indexed granted_
    );

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
            executor = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    // ######################## ~ KERNEL INTERNAL ~ ########################

    function _installModule(address newModule_) internal {
        Keycode keycode = Module(newModule_).KEYCODE();

        // @NOTE check newModule_ != 0
        if (getModuleForKeycode[keycode] != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
    }

    function _upgradeModule(address newModule_) internal {
        Keycode keycode = Module(newModule_).KEYCODE();
        address oldModule = getModuleForKeycode[keycode];

        if (oldModule == address(0) || oldModule == newModule_)
            revert Kernel_ModuleAlreadyExists(keycode);

        getKeycodeForModule[oldModule] = Keycode.wrap(bytes5(0));
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        _reconfigurePolicies();
    }

    function _approvePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == true)
            revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        Policy(policy_).configureReads();

        Role[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, true);

        allPolicies.push(policy_);
    }

    function _terminatePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == false)
            revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;

        Role[] memory requests = Policy(policy_).requestRoles();

        _setPolicyRoles(policy_, requests, false);
    }

    function _reconfigurePolicies() internal {
        for (uint256 i = 0; i < allPolicies.length; i++) {
            address policy_ = allPolicies[i];

            if (approvedPolicies[policy_] == true)
                Policy(policy_).configureReads();
        }
    }

    function _setPolicyRoles(
        address policy_,
        Role[] memory requests_,
        bool grant_
    ) internal {
        uint256 l = requests_.length;

        for (uint256 i = 0; i < l; ) {
            Role request = requests_[i];

            hasRole[policy_][request] = grant_;

            emit RolesUpdated(request, policy_, grant_);

            unchecked {
                i++;
            }
        }
    }
}