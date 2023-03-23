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
pragma solidity ^0.8.9;

import {Commands} from "../libraries/Commands.sol";
import {RouterImmutables} from "./RouterImmutables.sol";
import {RouterManagement} from "./RouterManagement.sol";

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {BytesLib} from "../libraries/BytesLib.sol";

import {UniswapRouter} from "../modules/UniswapRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CurveRouter} from "../modules/CurveRouter.sol";

abstract contract Dispatcher is RouterManagement, UniswapRouter, CurveRouter {
    error NothingReceived();

    /// @notice Dispatch the call to the right DEX or Bridge
    /// @param commandType The command for the transaction
    /// @param addrLocation The location of the address in the inputs bytes
    /// @param amountLocation The location of the amount in the inputs bytes
    /// @param inputs The inputs bytes for the command
    /// @param valueAfterFee The amount of ETH to (fees have been applied to this)
    /// @return success Whether the call was successful
    /// @return output The output bytes from the call
    function dispatch(
        bytes1 commandType,
        uint256 addrLocation,
        uint256 amountLocation,
        bytes memory inputs,
        uint256 valueAfterFee
    ) internal returns (bool success, bytes memory output) {
        uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK);
        if (command < 0x06) {
            if (command < 0x03) {
                if (command == Commands.UNISWAP_V2) {
                    (output) = swapV2(
                        inputs,
                        BytesLib.toAddress(inputs, addrLocation),
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                    success = true;
                } else if (command == Commands.UNISWAP_V3) {
                    (output) = swapV3(
                        inputs,
                        BytesLib.toAddress(inputs, addrLocation),
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                    success = true;
                } else if (command == Commands.V2_FORK) {
                    uint256 destinationCode = BytesLib.toUint8(
                        inputs,
                        inputs.length - 0x01
                    );
                    (success, output) = sendCall(
                        destinationCode == 0
                            ? SUSHISWAP_ROUTER
                            : destinationCode == 1
                            ? PANCAKESWAP_ROUTER
                            : SHIBASWAP_ROUTER,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        BytesLib.sliceBytes(inputs, 0x0, inputs.length - 0x01)
                    );
                }
            } else {
                if (command == Commands.CURVE) {
                    (output) = swapCurve(
                        inputs,
                        BytesLib.toAddress(inputs, addrLocation),
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                    success = true;
                } else if (command == Commands.BALANCER) {
                    if (valueAfterFee == 0)
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            BALANCER_ROUTER,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                    if (commandType & Commands.FLAG_MULTI_SWAP != 0x00) {
                        inputs = BytesLib.sliceBytes(
                            inputs,
                            0x0,
                            inputs.length - 0x14
                        );
                    }
                    (success, output) = BALANCER_ROUTER.call{
                        value: valueAfterFee
                    }(inputs);
                } else if (command == Commands.BANCOR) {
                    (success, output) = sendCall(
                        BANCOR_ROUTER,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                }
            }
        } else if (command < 0x0f) {
            if (command < 0x0a) {
                if (command == Commands.HOP_BRIDGE) {
                    uint256 destinationCode = BytesLib.toUint8(
                        inputs,
                        inputs.length - 0x01
                    );
                    address destination = destinationCode < 3
                        ? destinationCode == 0
                            ? HOP_ETH_BRIDGE
                            : destinationCode == 1
                            ? HOP_USDC_BRIDGE
                            : HOP_WBTC_BRIDGE
                        : destinationCode == 3
                        ? HOP_USDT_BRIDGE
                        : destinationCode == 4
                        ? HOP_DAI_BRIDGE
                        : HOP_MATIC_BRIDGE;
                    if (valueAfterFee == 0)
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            destination,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                    (success, output) = destination.call{value: valueAfterFee}(
                        BytesLib.sliceBytes(inputs, 0x0, 0xF8)
                    );
                } else if (command == Commands.ACROSS_BRIDGE) {
                    (success, output) = sendCall(
                        ACROSS_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                } else if (command == Commands.CELER_BRIDGE) {
                    (success, output) = sendCall(
                        CELER_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                } else if (command == Commands.SYNAPSE_BRIDGE) {
                    (success, output) = sendCall(
                        SYNAPSE_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                }
            } else {
                if (command == Commands.MULTICHAIN_BRIDGE) {
                    if (valueAfterFee == 0) {
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            MULTICHAIN_ERC20_BRIDGE,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                        (success, output) = MULTICHAIN_ERC20_BRIDGE.call(
                            BytesLib.sliceBytes(inputs, 0x0, 0x90)
                        );
                    } else {
                        (success, output) = MULTICHAIN_ETH_BRIDGE.call{
                            value: valueAfterFee
                        }(inputs);
                    }
                } else if (command == Commands.HYPHEN_BRIDGE) {
                    (success, output) = sendCall(
                        HYPHEN_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                } else if (command == Commands.PORTAL_BRIDGE) {
                    if (valueAfterFee == 0)
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            PORTAL_BRIDGE,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                    bytes memory adjustedInputs = abi.encode(
                        bytes32(
                            uint256(uint160(BytesLib.toAddress(inputs, 0x70)))
                        ),
                        BytesLib.toUint256(inputs, 0x84),
                        block.timestamp
                    );
                    (success, output) = PORTAL_BRIDGE.call{
                        value: valueAfterFee
                    }(
                        BytesLib.concat(
                            BytesLib.sliceBytes(inputs, 0x0, 0x64),
                            adjustedInputs
                        )
                    );
                } else if (command == Commands.ALL_BRIDGE) {
                    (success, output) = sendCall(
                        ALL_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                }
            }
        } else {
            if (command == Commands.OPTIMISM_BRIDGE) {
                (success, output) = sendCall(
                    OPTIMISM_BRIDGE,
                    addrLocation,
                    amountLocation,
                    valueAfterFee,
                    inputs
                );
            } else if (command == Commands.POLYGON_POS_BRIDGE) {
                if (valueAfterFee == 0)
                    SafeTransferLib.safeApprove(
                        ERC20(BytesLib.toAddress(inputs, addrLocation)),
                        POLYGON_APPROVE_ADDR,
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                (success, output) = POLYGON_POS_BRIDGE.call{
                    value: valueAfterFee
                }(inputs);
            } else if (command == Commands.OMNI_BRIDGE) {
                (success, output) = sendCall(
                    OMNI_BRIDGE,
                    addrLocation,
                    amountLocation,
                    0,
                    inputs
                );
            }
        }
    }

    /// @notice Sends a call to the destination contract
    /// @param destination The destination contract address
    /// @param addrLocation The location of the token address in the input
    /// @param amountLocation The location of the amount in the input
    /// @param valueAfterFee The amount of ETH to send with the call
    /// @param input The input data to send to the destination contract
    /// @return success The success of the call
    /// @return output The output of the call
    function sendCall(
        address destination,
        uint256 addrLocation,
        uint256 amountLocation,
        uint256 valueAfterFee,
        bytes memory input
    ) internal returns (bool success, bytes memory output) {
        if (valueAfterFee == 0)
            SafeTransferLib.safeApprove(
                ERC20(BytesLib.toAddress(input, addrLocation)),
                destination,
                BytesLib.toUint256(input, amountLocation)
            );
        (success, output) = destination.call{value: valueAfterFee}(input);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IWETH} from "../interfaces/IWETH.sol";

struct RouterParameters {
    address weth;
    address balancerRouter;
    address bancorRouter;
    address uniswapV2Factory;
    address uniswapV3Factory;
    address sushiswapRouter;
    address pancakeswapRouter;
    address shibaswapRouter;
    address hyphenBridge;
    address celerBridge;
    address hopEthBridge;
    address hopUsdcBridge;
    address hopUsdtBridge;
    address hopDaiBridge;
    address hopWbtcBridge;
    address hopMaticBridge;
    address acrossBridge;
    address multichainEthBridge;
    address multichainErc20Bridge;
    address synapseBridge;
    address allBridge;
    address portalBridge;
    address optimismBridge;
    address polygonPosBridge;
    address polygonApproveAddr;
    address omniBridge;
}

contract RouterImmutables {
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant _MIN_SQRT_RATIO = 4295128739 + 1;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant _MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342 - 1;

    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    IWETH internal immutable WETH;

    address internal immutable BALANCER_ROUTER;

    address internal immutable BANCOR_ROUTER;

    address internal immutable UNISWAP_V2_FACTORY;

    address internal immutable UNISWAP_V3_FACTORY;

    address internal immutable SUSHISWAP_ROUTER;

    address internal immutable PANCAKESWAP_ROUTER;

    address internal immutable SHIBASWAP_ROUTER;

    address internal immutable HYPHEN_BRIDGE;

    address internal immutable CELER_BRIDGE;

    address internal immutable HOP_ETH_BRIDGE;

    address internal immutable HOP_USDC_BRIDGE;

    address internal immutable HOP_USDT_BRIDGE;

    address internal immutable HOP_DAI_BRIDGE;

    address internal immutable HOP_WBTC_BRIDGE;

    address internal immutable HOP_MATIC_BRIDGE;

    address internal immutable ACROSS_BRIDGE;

    address internal immutable MULTICHAIN_ETH_BRIDGE;

    address internal immutable MULTICHAIN_ERC20_BRIDGE;

    address internal immutable SYNAPSE_BRIDGE;

    address internal immutable ALL_BRIDGE;

    address internal immutable PORTAL_BRIDGE;

    address internal immutable OPTIMISM_BRIDGE;

    address internal immutable POLYGON_POS_BRIDGE;

    address internal immutable POLYGON_APPROVE_ADDR;

    address internal immutable OMNI_BRIDGE;

    constructor(RouterParameters memory params) {
        WETH = IWETH(params.weth);
        BALANCER_ROUTER = params.balancerRouter;
        BANCOR_ROUTER = params.bancorRouter;
        UNISWAP_V2_FACTORY = params.uniswapV2Factory;
        UNISWAP_V3_FACTORY = params.uniswapV3Factory;
        SUSHISWAP_ROUTER = params.sushiswapRouter;
        PANCAKESWAP_ROUTER = params.pancakeswapRouter;
        SHIBASWAP_ROUTER = params.shibaswapRouter;
        HYPHEN_BRIDGE = params.hyphenBridge;
        CELER_BRIDGE = params.celerBridge;
        HOP_ETH_BRIDGE = params.hopEthBridge;
        HOP_USDC_BRIDGE = params.hopUsdcBridge;
        HOP_USDT_BRIDGE = params.hopUsdtBridge;
        HOP_DAI_BRIDGE = params.hopDaiBridge;
        HOP_WBTC_BRIDGE = params.hopWbtcBridge;
        HOP_MATIC_BRIDGE = params.hopMaticBridge;
        ACROSS_BRIDGE = params.acrossBridge;
        MULTICHAIN_ETH_BRIDGE = params.multichainEthBridge;
        MULTICHAIN_ERC20_BRIDGE = params.multichainErc20Bridge;
        SYNAPSE_BRIDGE = params.synapseBridge;
        ALL_BRIDGE = params.allBridge;
        PORTAL_BRIDGE = params.portalBridge;
        OPTIMISM_BRIDGE = params.optimismBridge;
        POLYGON_POS_BRIDGE = params.polygonPosBridge;
        POLYGON_APPROVE_ADDR = params.polygonApproveAddr;
        OMNI_BRIDGE = params.omniBridge;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {RouterImmutables} from "./RouterImmutables.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {Commands} from "../libraries/Commands.sol";

abstract contract RouterManagement is RouterImmutables {
    error InvalidCommand();

    /// @notice Collects token fees from user and adjusts input bytes
    /// @param commands The commands bytes
    /// @param inputs The inputs bytes for the command
    /// @return amountLocation The location of the amount in the inputs bytes
    /// @return addrLocation The location of the address in the inputs bytes
    /// @return inputs The adjusted input bytes after fees deducted
    function collectTokenFees(
        bytes memory commands,
        bytes memory inputs
    )
        internal
        returns (uint256 amountLocation, uint256 addrLocation, bytes memory)
    {
        uint256 command = uint8(
            bytes1(commands[0]) & Commands.COMMAND_TYPE_MASK
        );

        if (command != 0x04) {
            addrLocation = uint8(commands[1]);
            amountLocation = uint8(commands[2]);
        } else {
            if (bytes1(commands[0]) & Commands.FLAG_MULTI_SWAP == 0x00) {
                addrLocation = 0x130;
                amountLocation = 0x164;
            } else {
                addrLocation = inputs.length - 0x14;
                amountLocation =
                    0x60 +
                    0x144 +
                    BytesLib.toUint256(inputs, 0x144);
                uint256 limitLocation = BytesLib.toUint256(inputs, 0xE4) +
                    0x24 +
                    (0x20 * BytesLib.toUint256(inputs, amountLocation - 0x40));
                bytes memory appendedBytes = BytesLib.concat(
                    abi.encode(
                        (BytesLib.toUint256(inputs, limitLocation) * 9998) /
                            10_000
                    ),
                    BytesLib.sliceBytes(
                        inputs,
                        limitLocation + 32,
                        inputs.length - limitLocation - 32
                    )
                );
                inputs = BytesLib.concat(
                    BytesLib.sliceBytes(inputs, 0, limitLocation),
                    appendedBytes
                );
            }
        }

        if (command > 0x0a && msg.value > 0)
            return (amountLocation, addrLocation, inputs);

        uint256 amount = BytesLib.toUint256(inputs, amountLocation);

        if (msg.value == 0)
            SafeTransferLib.safeTransferFrom(
                ERC20(BytesLib.toAddress(inputs, addrLocation)),
                msg.sender,
                address(this),
                amount
            );
        bytes memory adjustedBytes = BytesLib.concat(
            abi.encode((amount * 9998) / 10_000),
            BytesLib.sliceBytes(
                inputs,
                amountLocation + 32,
                inputs.length - amountLocation - 32
            )
        );

        if (command == 0x01 || command == 0x02)
            return (amountLocation, addrLocation, adjustedBytes);

        inputs = BytesLib.concat(
            BytesLib.sliceBytes(inputs, 0, amountLocation),
            adjustedBytes
        );

        return (amountLocation, addrLocation, inputs);
    }

    /// @notice Adjusts the amountIn for the next command when chained
    /// @param _previousCommand The previous command bytes
    /// @param _nextCommand The next command bytes
    /// @param _amountInLocation The location of amountIn for next command
    /// @param _nextInputBytes The input bytes for the next command
    /// @param _amountOutBytes The amountOut output bytes for the previous command
    /// @return adjustedBytes The adjusted input bytes for the next command
    function adjustAmountIn(
        bytes1 _previousCommand,
        bytes1 _nextCommand,
        uint256 _amountInLocation,
        bytes memory _nextInputBytes,
        bytes memory _amountOutBytes
    ) internal pure returns (bytes memory adjustedBytes) {
        // NOTE: When command >0x0a and flag fromEth bridge we return as no amount input used
        if (
            _nextCommand & Commands.COMMAND_TYPE_MASK > 0x0a &&
            _nextCommand & Commands.FLAG_MULTI_SWAP != 0x00
        ) return _nextInputBytes;

        uint256 _startSlice;
        // NOTE: Balancer multiswap will have amountOutBytes > 32 bytes
        if (_previousCommand == 0x04 && _amountOutBytes.length > 0x20) {
            _amountOutBytes = abi.encode(
                uint256(
                    -(
                        abi.decode(
                            BytesLib.sliceBytes(_amountOutBytes, 64, 32),
                            (int256)
                        )
                    )
                )
            );
        } else {
            if (_previousCommand > 0x00 && _previousCommand < 0x05) {
                // NOTE: AmountOut starts at 0 bytes for V2, V3, Curve, and Balancer single
            } else if (_previousCommand == 0x00) {
                _startSlice = _amountOutBytes.length - 0x20;
            } else if (_previousCommand == 0x05) {
                _startSlice = 0x44;
            } else {
                revert InvalidCommand();
            }
        }

        if (
            _nextCommand & Commands.COMMAND_TYPE_MASK == 0x04 &&
            _nextCommand & Commands.FLAG_MULTI_SWAP != 0x00
        ) {
            // NOTE: 0xE4 used as 0xE0 + 4 bytes for funcSelector
            // NOTE: 0x24 skips first slot for length of limit + 4 bytes for func selector as bytes do not factor this in
            uint256 limitLocation = BytesLib.toUint256(_nextInputBytes, 0xE4) +
                0x24 +
                (0x20 *
                    BytesLib.toUint256(
                        _nextInputBytes,
                        _amountInLocation - 0x40
                    ));
            bytes memory appendedBytes = BytesLib.concat(
                BytesLib.sliceBytes(_amountOutBytes, _startSlice, 32),
                BytesLib.sliceBytes(
                    _nextInputBytes,
                    limitLocation + 32,
                    _nextInputBytes.length - limitLocation - 32
                )
            );
            _nextInputBytes = BytesLib.concat(
                BytesLib.sliceBytes(_nextInputBytes, 0, limitLocation),
                appendedBytes
            );
        }

        // NOTE: Slice bytes up to the amountInLocation
        adjustedBytes = BytesLib.sliceBytes(
            _nextInputBytes,
            0,
            _amountInLocation
        );

        // NOTE: Concatenate amountOut bytes and appending bytes to sliced bytes
        adjustedBytes = BytesLib.concat(
            adjustedBytes,
            BytesLib.concat(
                BytesLib.sliceBytes(_amountOutBytes, _startSlice, 32),
                BytesLib.sliceBytes(
                    _nextInputBytes,
                    _amountInLocation + 32,
                    _nextInputBytes.length - _amountInLocation - 32
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

interface ICryptoPool {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable;

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IErrors {
    error ThrowingError(bytes message);

    /// @notice Thrown when swap fails
    error FailedSwap();

    /// @notice Thrown when reserves are insufficient
    error InsufficientLiquidity();

    /// @notice Thrown when amountOut is insufficient
    error InsufficientOutput();

    /// @notice Thrown when ETH value does not equal amountIn
    error IncorrectETHValue();

    /// @notice Thrown if swapType is not exactInput in V3
    error BadSwapType();

    /// @notice Thrown when pool is incorrect in callback
    error BadPool();

    /// @notice Incorrect fromToken input
    error IncorrectFromToken();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapPair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV3Pool {
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniversalRouter {
    /// @notice Thrown when deadline for execution is more than timestamp
    error DeadlinePassed();

    /// @notice Thrown when the commands array and input array mismatch
    error InvalidInputLength();

    /// @notice Thrown when a command fails
    error FailedCommand(bytes1 command, uint256 commandNum, bytes output);

    /// @notice Thrown when an unauthorized address tries to call a function
    error Unauthorized();

    /// @notice Thrown when invalid token is used for Stargate bridge
    error InvalidToken();

    /// @notice Thrown when invalid amount is used for Stargate bridge
    error InvalidTokenAmount();

    /// @notice Thrown when ethBalance is less than start
    error InsufficientEth();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

/// @title Library for Bytes Manipulation
pragma solidity ^0.8.9;

library BytesLib {
    // TODO: Checks for the byte length
    // TODO: Check gas cost as single function vs. two functions
    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address tempAddress)
    {
        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x3), _start))
        }
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x2), _start))
        }
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x1), _start))
        }
    }

    // TODO: May need to manipulate amountIn for bytes

    /// @param _bytes The bytes input
    /// @param _start The start index of the slice
    /// @param _length The length of the slice
   function sliceBytes(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory slicedBytes)
    {
        assembly {
                slicedBytes := mload(0x40)

                let lengthmod := and(_length, 31)
                
                let mc := add(add(slicedBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(slicedBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
        }
        return slicedBytes;
    }

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Commands {
    /// TODO: Review these masks
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant FLAG_CHAIN_ORDER = 0x40;
    bytes1 internal constant FLAG_MULTI_SWAP = 0x20;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x1f;

    // Command Types where value <0x04, first block
    uint256 constant V2_FORK = 0x00; // Was 0x02
    uint256 constant UNISWAP_V2 = 0x01; // Was 0x00
    uint256 constant UNISWAP_V3 = 0x02; // Was 0x05

    // Command Types where value <0x06, second block
    uint256 constant CURVE = 0x03; // Was 0x07
    uint256 constant BALANCER = 0x04; // Was 0x08
    uint256 constant BANCOR = 0x05; // Was 0x09

    // Command Types where value >0x05 and <0x0b, third block
    uint256 constant HOP_BRIDGE = 0x06; // Was 0x0e
    uint256 constant ACROSS_BRIDGE = 0x07; // Was 0x0d
    uint256 constant CELER_BRIDGE = 0x08; // Was 0x0c
    uint256 constant SYNAPSE_BRIDGE = 0x09; // Was 0x0a // Was 0x0f

    // Command Types where value >0x0a <0x0f, fourth block
    uint256 constant STARGATE_BRIDGE = 0x0a; // Was 0x0b // Was 0x19
    uint256 constant ALL_BRIDGE = 0x0b; // Was 0x0a // Was 0x09 // Was 0x0b // Was 0x11 before 0x0b
    uint256 constant MULTICHAIN_BRIDGE = 0x0c; // Was 0x10 // Was 0x0f before 0x10
    uint256 constant HYPHEN_BRIDGE = 0x0d; // Was 0x11 // Was 0x0b before
    uint256 constant PORTAL_BRIDGE = 0x0e; // Was 0x12

    // Command Types where value >0x0e fourth block
    uint256 constant OPTIMISM_BRIDGE = 0x0f; // Was 0x13
    uint256 constant POLYGON_POS_BRIDGE = 0x10; // Was 0x16
    uint256 constant OMNI_BRIDGE = 0x11; // Was 0x18
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {ICurvePool, ICryptoPool} from "../interfaces/ICurvePool.sol";
import {IErrors} from "../interfaces/IErrors.sol";

abstract contract CurveRouter is IErrors {
    /// @notice Swaps tokens on Curve
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    function swapCurve(
        bytes memory input,
        address fromToken,
        uint256 amountIn
    ) internal returns (bytes memory output) {
        uint256 swapLength = BytesLib.toUint8(input, input.length - 2);
        address recipient = BytesLib.toUint8(input, input.length - 1) == 0
            ? msg.sender
            : BytesLib.toAddress(input, input.length - 22);
        uint256 skipToInfo = (0x54 + (swapLength * 0x28));
        uint256 balanceBefore;

        for (uint256 i; i < swapLength; ) {
            address pool = BytesLib.toAddress(input, 0x54 + (i * 0x28));
            address toToken = BytesLib.toAddress(input, 0x68 + (i * 0x28));
            bool toEth = toToken == address(0);

            /**
            Location is: 
            - Pushing past pool info and fromToken (20 + (i * 40 bytes)) = (0x54 + (swapLength * 0x28)) 
            - Pushing past each grouping of info (6 bytes * 1) + 0x40 for amountIn and out = (i * 0x06) 
            --> BytesLib.sliceBytes(input, (0x54 + (swapLength * 0x28)) + (i * 0x06), 0x40);

            Step 1 - Encodes: selector, i, j, amountIn
            Step 2 - Appends empty 32 bytes or amountOutMin

             */
            output = BytesLib.concat(
                BytesLib.sliceBytes(input, skipToInfo + (i * 0x6), 0x04),
                abi.encode(
                    BytesLib.toUint8(input, skipToInfo + (i * 0x6) + 0x04),
                    BytesLib.toUint8(input, skipToInfo + (i * 0x6) + 0x05),
                    amountIn
                )
            );

            if (fromToken != address(0) && !toEth) {
                SafeTransferLib.safeApprove(ERC20(fromToken), pool, amountIn);
                output = BytesLib.concat(
                    output,
                    i == swapLength - 1
                        ? BytesLib.sliceBytes(input, 0x34, 0x20)
                        : abi.encode(0)
                );
                balanceBefore = ERC20(toToken).balanceOf(address(this));
            } else {
                if (fromToken != address(0)) {
                    SafeTransferLib.safeApprove(
                        ERC20(fromToken),
                        pool,
                        amountIn
                    );
                }

                output = BytesLib.concat(
                    output,
                    BytesLib.concat(
                        i == swapLength - 1
                            ? BytesLib.sliceBytes(input, 0x34, 0x20)
                            : abi.encode(0),
                        abi.encode(true)
                    )
                );

                balanceBefore = toEth
                    ? address(this).balance
                    : ERC20(toToken).balanceOf(address(this));
            }

            (bool success, bytes memory message) = pool.call{
                value: fromToken == address(0) ? amountIn : 0
            }(output);
            if (!success) revert ThrowingError(message);

            amountIn = toEth
                ? address(this).balance - balanceBefore
                : ERC20(toToken).balanceOf(address(this)) - balanceBefore;
            fromToken = toToken;

            unchecked {
                i++;
            }
        }

        // NOTE: Re-using fromToken for toToken as declared outside of loop
        if (recipient != address(this)) {
            if (fromToken != address(0)) {
                SafeTransferLib.safeTransfer(
                    ERC20(fromToken),
                    recipient,
                    amountIn
                );
            } else {
                SafeTransferLib.safeTransferETH(recipient, amountIn);
            }
        }
        output = abi.encode(amountIn);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {IErrors} from "../interfaces/IErrors.sol";
import {RouterImmutables} from "../base/RouterImmutables.sol";
import {IUniswapPair} from "../interfaces/IUniswapPair.sol";
import {IUniswapV3SwapCallback} from "../interfaces/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";

abstract contract UniswapRouter is
    RouterImmutables,
    IErrors,
    IUniswapV3SwapCallback
{
    ///////////// UNISWAP_V2 LOGIC //////////////

    /// @notice Swaps tokens on Uniswap V2
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    function swapV2(
        bytes memory input,
        address fromToken,
        uint256 amountIn
    ) internal returns (bytes memory output) {
        uint256 swapLength = BytesLib.toUint8(input, input.length - 2);
        address recipient = BytesLib.toUint8(input, input.length - 1) == 0
            ? msg.sender
            : BytesLib.toAddress(input, input.length - 22);

        (
            address[] memory pairs,
            address[] memory tokens,
            uint256[] memory amounts
        ) = V2Helper(input, fromToken, amountIn, swapLength);

        if (swapLength > 1) {
            bool zeroForOne = tokens[0] < tokens[1] ? true : false;
            IUniswapPair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                pairs[1],
                ""
            );
            uint256 finalIndex = swapLength - 1;
            for (uint256 i = 1; i < finalIndex; ) {
                zeroForOne = tokens[i] < tokens[i + 1] ? true : false;
                IUniswapPair(pairs[i]).swap(
                    zeroForOne ? 0 : amounts[i],
                    zeroForOne ? amounts[i] : 0,
                    pairs[i + 1],
                    ""
                );

                unchecked {
                    i++;
                }
            }
            zeroForOne = tokens[finalIndex] < tokens[swapLength] ? true : false;
            IUniswapPair(pairs[finalIndex]).swap(
                zeroForOne ? 0 : amounts[finalIndex],
                zeroForOne ? amounts[finalIndex] : 0,
                recipient,
                ""
            );
        } else {
            bool zeroForOne = tokens[0] < tokens[1] ? true : false;
            IUniswapPair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                recipient,
                ""
            );
        }
        uint256 amountOut = amounts[swapLength - 1];
        output = abi.encode(amountOut);

        if (recipient == address(this) && tokens[swapLength] == address(WETH)) {
            if (BytesLib.toAddress(input, input.length - 42) == address(this)) {
                if (BytesLib.toUint8(input, input.length - 43) == 1)
                    WETH.withdraw(amountOut);
                return output;
            }
            WETH.withdraw(amountOut);
            SafeTransferLib.safeTransferETH(
                BytesLib.toAddress(input, input.length - 42),
                amountOut
            );
        }
    }

    /// @notice Helper function to get values for swaps
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    /// @param swapLength The number of swaps
    function V2Helper(
        bytes memory input,
        address fromToken,
        uint256 amountIn,
        uint256 swapLength
    )
        internal
        returns (
            address[] memory pairs,
            address[] memory tokens,
            uint256[] memory amounts
        )
    {
        pairs = new address[](swapLength);
        tokens = new address[](swapLength + 1);
        amounts = new uint256[](swapLength);

        address token0;
        address token1;
        uint256 cachedIn = amountIn;
        tokens[0] = fromToken == address(0) ? address(WETH) : fromToken;

        for (uint256 i; i < swapLength; ) {
            tokens[i + 1] = BytesLib.toAddress(input, 64 + ((i + 1) * 0x14));
            token0 = tokens[i];
            token1 = tokens[i + 1];
            pairs[i] = pairFor(token0, token1);

            (uint256 reserveIn, uint256 reserveOut, ) = IUniswapPair(pairs[i])
                .getReserves();

            if (token0 > token1)
                (reserveIn, reserveOut) = (reserveOut, reserveIn);

            amounts[i] =
                ((cachedIn * 997) * reserveOut) /
                ((reserveIn * 1000) + (cachedIn * 997));
            cachedIn = amounts[i];

            unchecked {
                i++;
            }
        }

        if (cachedIn < BytesLib.toUint256(input, 32))
            revert InsufficientOutput();

        if (fromToken == address(0)) WETH.deposit{value: amountIn}();

        SafeTransferLib.safeTransfer(ERC20(tokens[0]), pairs[0], amountIn);
    }

    /// @notice Gets the pair address for a given token pair using UniswapV2 Factory settings
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @return pair The pair address
    function pairFor(
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        require(tokenA != tokenB, "V2:DUP_ADDRESS");
        (tokenA, tokenB) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(tokenA != address(0), "V2:ZERO_ADDRESS");
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_V2_FACTORY,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    ///////////// UNISWAP_V3 LOGIC //////////////

    /// @notice Swaps tokens using UniswapV3
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    /// @return output The output bytes
    function swapV3(
        bytes memory input,
        address fromToken,
        uint256 amountIn
    ) internal returns (bytes memory output) {
        uint256 swapLength = BytesLib.toUint8(input, input.length - 2);
        address recipient = BytesLib.toUint8(input, input.length - 1) == 0
            ? msg.sender
            : BytesLib.toAddress(input, input.length - 22);

        if (fromToken == address(0)) WETH.deposit{value: amountIn}();

        if (swapLength > 1) {
            amountIn = _swap(
                address(this),
                amountIn,
                BytesLib.sliceBytes(input, 0x40, 43)
            );
            uint256 finalIndex = swapLength - 1;
            for (uint256 i = 1; i < finalIndex; ) {
                amountIn = _swap(
                    address(this),
                    amountIn,
                    BytesLib.sliceBytes(input, 0x40 + (i * 23), 43)
                );
                unchecked {
                    i++;
                }
            }
            amountIn = _swap(
                recipient,
                amountIn,
                BytesLib.sliceBytes(input, 0x40 + (finalIndex * 23), 43)
            );
        } else {
            amountIn = _swap(
                recipient,
                amountIn,
                BytesLib.sliceBytes(input, 0x40, 43)
            );
        }

        if (amountIn < BytesLib.toUint256(input, 32))
            revert InsufficientOutput();

        if (recipient == address(this)) {
            if (
                BytesLib.toAddress(input, 0x40 + (swapLength * 23)) ==
                address(WETH)
            ) {
                if (
                    BytesLib.toAddress(input, input.length - 42) ==
                    address(this)
                ) {
                    if (BytesLib.toUint8(input, input.length - 43) == 1)
                        WETH.withdraw(amountIn);
                } else {
                    WETH.withdraw(amountIn);
                    SafeTransferLib.safeTransferETH(
                        BytesLib.toAddress(input, input.length - 42),
                        amountIn
                    );
                }
            }
        }

        output = abi.encode(amountIn);
    }

    /// @notice Swaps tokens using UniswapV3
    /// @param recipient The recipient of the swap
    /// @param amount The amount to swap
    /// @param path The path to swap - used to tokenIn, tokenOut, and fee
    function _swap(
        address recipient,
        uint256 amount,
        bytes memory path
    ) internal returns (uint256) {
        address tokenIn = BytesLib.toAddress(path, 0);
        if (tokenIn == address(0)) tokenIn = address(WETH);
        uint24 fee = BytesLib.toUint24(path, 20);
        address tokenOut = BytesLib.toAddress(path, 23);
        bool zeroForOne = tokenIn < tokenOut;

        if (zeroForOne) {
            (, int256 amountOut) = IUniswapV3Pool(
                getPool(tokenIn, tokenOut, fee)
            ).swap(
                    recipient,
                    zeroForOne,
                    int256(amount),
                    _MIN_SQRT_RATIO,
                    path
                );
            return uint256(-amountOut);
        } else {
            (int256 amountOut, ) = IUniswapV3Pool(
                getPool(tokenIn, tokenOut, fee)
            ).swap(
                    recipient,
                    zeroForOne,
                    int256(amount),
                    _MAX_SQRT_RATIO,
                    path
                );
            return uint256(-amountOut);
        }
    }

    /// @notice Callback function executed from interaction with V3 pool - checks valid call and executes swap with pool
    /// @param amount0Delta The amount of token0 to swap
    /// @param amount1Delta The amount of token1 to swap
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = decodePool(_data);
        tokenIn = tokenIn == address(0) ? address(WETH) : tokenIn;

        if (msg.sender != getPool(tokenIn, tokenOut, fee)) revert BadPool();

        SafeTransferLib.safeTransfer(
            ERC20(tokenIn),
            msg.sender,
            amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta)
        );
    }

    /// @notice Gets the pool address for a given token pair and fee
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @param fee The fee
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_V3_FACTORY,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /// @notice Decodes the pool address from the path
    /// @param path The path to decode
    /// @return tokenA The first token
    /// @return tokenB The second token
    /// @return fee The fee
    function decodePool(
        bytes memory path
    ) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = BytesLib.toAddress(path, 0);
        fee = BytesLib.toUint24(path, 20);
        tokenB = BytesLib.toAddress(path, 23);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Dispatcher, BytesLib, RouterImmutables, RouterManagement, Commands, ERC20, SafeTransferLib} from "./base/Dispatcher.sol";
import {RouterParameters} from "./base/RouterImmutables.sol";
import {IUniversalRouter} from "./interfaces/IUniversalRouter.sol";

contract UniversalRouter is Dispatcher, IUniversalRouter {
    address constant owner = 0xE9290C80b28db1B3d9853aB1EE60c6630B87F57E;

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert DeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params) RouterImmutables(params) {}

    /// @notice Executes a command or multiple commands within the deadline
    /// @param commands The array of command bytes (can be a single command)
    /// @param inputs The array of input bytes for the commands (can be a single input)
    function routeExecute(
        bytes[] memory commands,
        bytes[] memory inputs,
        uint256 deadline
    ) external payable checkDeadline(deadline) {
        commands.length > 1
            ? multiExecute(commands, inputs)
            : singleExecute(commands[0], inputs[0]);
    }

    /// @notice Executes a single command
    /// @param commands The command bytes
    /// @param input The input bytes for the command
    function singleExecute(
        bytes memory commands,
        bytes memory input
    ) public payable {
        bool success;
        bytes memory output;

        uint256 amountLocation;
        uint256 addrLocation;
        uint256 cachedBalance = address(this).balance - msg.value;

        (amountLocation, addrLocation, input) = collectTokenFees(
            commands,
            input
        );

        (success, output) = dispatch(
            commands[0],
            addrLocation,
            amountLocation,
            input,
            msg.value == 0 ? 0 : (msg.value * 9998) / 10_000
        );

        if (!success) revert FailedCommand(commands[0], 0, output);

        if (address(this).balance < cachedBalance) revert InsufficientEth();
    }

    /// @notice Executes multiple commands in a single transaction
    /// @param commands The array of command bytes
    /// @param inputs The array of input bytes for the commands
    function multiExecute(
        bytes[] memory commands,
        bytes[] memory inputs
    ) public payable {
        bool success;
        bytes memory output;

        uint256 amountLocation;
        uint256 addrLocation;

        uint256 ethInput;
        uint256 cachedBalance = address(this).balance - msg.value;

        for (uint256 commandNum; commandNum < inputs.length; ) {
            bytes1 command = commands[commandNum][0];
            bytes memory input = inputs[commandNum];
            bytes1 maskedCommand = command & Commands.COMMAND_TYPE_MASK;

            if (commandNum > 0 && chainedOrder(command)) {
                addrLocation = maskedCommand != 0x04
                    ? uint8(commands[commandNum][1])
                    : BytesLib.toUint16(commands[commandNum], 0x01);

                amountLocation = maskedCommand != 0x04
                    ? uint8(commands[commandNum][2])
                    : BytesLib.toUint16(commands[commandNum], 0x03);

                input = adjustAmountIn(
                    commands[commandNum - 1][0] & Commands.COMMAND_TYPE_MASK,
                    command,
                    amountLocation,
                    input,
                    output
                );

                // NOTE: Multiswap flag re-used to signal chained fromETH when bridging
                // NOTE: These tx's need to know diff between newly received and cached balance
                if (
                    maskedCommand > 0x05 &&
                    command & Commands.FLAG_MULTI_SWAP != 0x00
                ) {
                    ethInput = address(this).balance - cachedBalance;
                }
            } else {
                (amountLocation, addrLocation, input) = collectTokenFees(
                    commands[commandNum],
                    inputs[commandNum]
                );
            }

            (success, output) = dispatch(
                command,
                addrLocation,
                amountLocation,
                input,
                commandNum == 0
                    ? msg.value == 0 ? 0 : (msg.value * 9998) / 10000
                    : ethInput
            );

            if (!success) revert FailedCommand(command, commandNum, output);

            if (ethInput != 0) ethInput = 0;

            unchecked {
                commandNum++;
            }
        }
        if (address(this).balance < cachedBalance) revert InsufficientEth();
    }

    // MASK CHECKS //
    /// @notice Checking if success if required for the current command
    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /// @notice Checking if the current command is a chained command
    function chainedOrder(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_CHAIN_ORDER == 0;
    }

    // ADMIN FUNCTIONS //
    /// @notice Allows the owner to update to withdraw ETH
    /// @param _receiver The address to send the ETH to
    function withdrawETH(address _receiver) external {
        if (msg.sender != owner) revert Unauthorized();
        payable(_receiver).transfer(address(this).balance);
    }

    /// @notice Allows the owner to update to withdraw ERC20 tokens
    /// @param _tokens The array of ERC20 tokens to withdraw
    /// @param _receiver The address to send the tokens to
    function withdrawERC20(
        ERC20[] calldata _tokens,
        address _receiver
    ) external {
        if (msg.sender != owner) revert Unauthorized();
        for (uint256 i = 0; i < _tokens.length; ) {
            SafeTransferLib.safeTransfer(
                _tokens[i],
                _receiver,
                _tokens[i].balanceOf(address(this))
            );
            unchecked {
                i++;
            }
        }
    }

    receive() external payable {}
}