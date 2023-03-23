// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.4;

import "./interfaces/across.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ACROSS} from "../../static/RouteIdentifiers.sol";

/**
 * @title Across-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Across-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AcrossImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract AcrossImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AcrossIdentifier = ACROSS;

    /// @notice Function-selector for ERC20-token bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ACROSS_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,bytes32,address,address,uint32,uint64)"
            )
        );

    /// @notice Function-selector for Native bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable ACROSS_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(uint256,uint256,bytes32,address,uint32,uint64)"
            )
        );

    bytes4 public immutable ACROSS_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,address,uint32,uint64,bytes32))"
            )
        );

    /// @notice spokePool Contract instance used to deposit ERC20 and Native on to Across-Bridge
    /// @dev contract instance is to be initialized in the constructor using the spokePoolAddress passed as constructor argument
    SpokePool public immutable spokePool;
    address public immutable spokePoolAddress;

    /// @notice address of WETH token to be initialised in constructor
    address public immutable WETH;

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AcrossBridgeDataNoToken {
        uint256 toChainId;
        address receiverAddress;
        uint32 quoteTimestamp;
        uint64 relayerFeePct;
        bytes32 metadata;
    }

    struct AcrossBridgeData {
        uint256 toChainId;
        address receiverAddress;
        address token;
        uint32 quoteTimestamp;
        uint64 relayerFeePct;
        bytes32 metadata;
    }

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure spokepool, weth-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _spokePool,
        address _wethAddress,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        spokePool = SpokePool(_spokePool);
        spokePoolAddress = _spokePool;
        WETH = _wethAddress;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AcrossBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AcrossBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AcrossBridgeData memory acrossBridgeData = abi.decode(
            bridgeData,
            (AcrossBridgeData)
        );

        if (acrossBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            spokePool.deposit{value: amount}(
                acrossBridgeData.receiverAddress,
                WETH,
                amount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        } else {
            spokePool.deposit(
                acrossBridgeData.receiverAddress,
                acrossBridgeData.token,
                amount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        }

        emit SocketBridge(
            amount,
            acrossBridgeData.token,
            acrossBridgeData.toChainId,
            AcrossIdentifier,
            msg.sender,
            acrossBridgeData.receiverAddress,
            acrossBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AcrossBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param acrossBridgeData encoded data for AcrossBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        AcrossBridgeDataNoToken calldata acrossBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );
        if (token == NATIVE_TOKEN_ADDRESS) {
            spokePool.deposit{value: bridgeAmount}(
                acrossBridgeData.receiverAddress,
                WETH,
                bridgeAmount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        } else {
            spokePool.deposit(
                acrossBridgeData.receiverAddress,
                token,
                bridgeAmount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            acrossBridgeData.toChainId,
            AcrossIdentifier,
            msg.sender,
            acrossBridgeData.receiverAddress,
            acrossBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Across-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param quoteTimestamp timestamp for quote and this is to be used by Across-Bridge contract
     * @param relayerFeePct feePct that will be relayed by the Bridge to the relayer
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint32 quoteTimestamp,
        uint64 relayerFeePct
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        spokePool.deposit(
            receiverAddress,
            address(token),
            amount,
            toChainId,
            relayerFeePct,
            quoteTimestamp
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AcrossIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Across-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param quoteTimestamp timestamp for quote and this is to be used by Across-Bridge contract
     * @param relayerFeePct feePct that will be relayed by the Bridge to the relayer
     */
    function bridgeNativeTo(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        uint32 quoteTimestamp,
        uint64 relayerFeePct
    ) external payable {
        spokePool.deposit{value: amount}(
            receiverAddress,
            WETH,
            amount,
            toChainId,
            relayerFeePct,
            quoteTimestamp
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            AcrossIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice interface with functions to interact with SpokePool contract of Across-Bridge
interface SpokePool {
    /**************************************
     *         DEPOSITOR FUNCTIONS        *
     **************************************/

    /**
     * @notice Called by user to bridge funds from origin to destination chain. Depositor will effectively lock
     * tokens in this contract and receive a destination token on the destination chain. The origin => destination
     * token mapping is stored on the L1 HubPool.
     * @notice The caller must first approve this contract to spend amount of originToken.
     * @notice The originToken => destinationChainId must be enabled.
     * @notice This method is payable because the caller is able to deposit native token if the originToken is
     * wrappedNativeToken and this function will handle wrapping the native token to wrappedNativeToken.
     * @param recipient Address to receive funds at on destination chain.
     * @param originToken Token to lock into this contract to initiate deposit.
     * @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
     * @param destinationChainId Denotes network where user will receive funds from SpokePool by a relayer.
     * @param relayerFeePct % of deposit amount taken out to incentivize a fast relayer.
     * @param quoteTimestamp Timestamp used by relayers to compute this deposit's realizedLPFeePct which is paid
     * to LP pool on HubPool.
     */
    function deposit(
        address recipient,
        address originToken,
        uint256 amount,
        uint256 destinationChainId,
        uint64 relayerFeePct,
        uint32 quoteTimestamp
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {ANYSWAP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Anyswap-V4-Route L1 Implementation
 * @notice Route implementation with functions to bridge ERC20 via Anyswap-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AnyswapImplementation
 * This is the L1 implementation, so this is used when transferring from l1 to supported l1s or L1.
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */

/// @notice Interface to interact with AnyswapV4-Router Implementation
interface AnyswapV4Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AnyswapIdentifier = ANYSWAP;

    /// @notice Function-selector for ERC20-token bridging on Anyswap-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ANYSWAP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,bytes32,address,address,address)"
            )
        );

    bytes4 public immutable ANYSWAP_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,address,address,bytes32))"
            )
        );

    /// @notice AnSwapV4Router Contract instance used to deposit ERC20 on to Anyswap-Bridge
    /// @dev contract instance is to be initialized in the constructor using the router-address passed as constructor argument
    AnyswapV4Router public immutable router;

    /**
     * @notice Constructor sets the router address and socketGateway address.
     * @dev anyswap 4 router is immutable. so no setter function required.
     */
    constructor(
        address _router,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = AnyswapV4Router(_router);
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeDataNoToken {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeData {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
        /// @notice address of token being bridged
        address token;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AnyswapBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AnyswapBridgeData memory anyswapBridgeData = abi.decode(
            bridgeData,
            (AnyswapBridgeData)
        );
        ERC20(anyswapBridgeData.token).safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            amount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            amount,
            anyswapBridgeData.token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress,
            anyswapBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param anyswapBridgeData encoded data for AnyswapBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        AnyswapBridgeDataNoToken calldata anyswapBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        ERC20(token).safeApprove(address(router), bridgeAmount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            bridgeAmount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress,
            anyswapBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Anyswap-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param wrapperTokenAddress address of wrapperToken, WrappedVersion of the token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        address token,
        address wrapperTokenAddress
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            wrapperTokenAddress,
            receiverAddress,
            amount,
            toChainId
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AnyswapIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {ANYSWAP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Anyswap-V4-Route L1 Implementation
 * @notice Route implementation with functions to bridge ERC20 via Anyswap-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AnyswapImplementation
 * This is the L2 implementation, so this is used when transferring from l2.
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
interface AnyswapV4Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapL2Impl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AnyswapIdentifier = ANYSWAP;

    /// @notice Function-selector for ERC20-token bridging on Anyswap-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ANYSWAP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,bytes32,address,address,address)"
            )
        );

    bytes4 public immutable ANYSWAP_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,address,address,bytes32))"
            )
        );

    // polygon router multichain router v4
    AnyswapV4Router public immutable router;

    /**
     * @notice Constructor sets the router address and socketGateway address.
     * @dev anyswap v4 router is immutable. so no setter function required.
     */
    constructor(
        address _router,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = AnyswapV4Router(_router);
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeDataNoToken {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeData {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
        /// @notice address of token being bridged
        address token;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AnyswapBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AnyswapBridgeData memory anyswapBridgeData = abi.decode(
            bridgeData,
            (AnyswapBridgeData)
        );
        ERC20(anyswapBridgeData.token).safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            amount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            amount,
            anyswapBridgeData.token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress,
            anyswapBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param anyswapBridgeData encoded data for AnyswapBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        AnyswapBridgeDataNoToken calldata anyswapBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        ERC20(token).safeApprove(address(router), bridgeAmount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            bridgeAmount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress,
            anyswapBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Anyswap-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param wrapperTokenAddress address of wrapperToken, WrappedVersion of the token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        address token,
        address wrapperTokenAddress
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            wrapperTokenAddress,
            receiverAddress,
            amount,
            toChainId
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AnyswapIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.8.0;

/**
 * @title L1gatewayRouter for native-arbitrum
 */
interface L1GatewayRouter {
    /**
     * @notice outbound function to bridge ERC20 via NativeArbitrum-Bridge
     * @param _token address of token being bridged via GatewayRouter
     * @param _to recipient of the token on arbitrum chain
     * @param _amount amount of ERC20 token being bridged
     * @param _maxGas a depositParameter for bridging the token
     * @param _gasPriceBid  a depositParameter for bridging the token
     * @param _data a depositParameter for bridging the token
     * @return calldata returns the output of transactioncall made on gatewayRouter
     */
    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {L1GatewayRouter} from "../interfaces/arbitrum.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {NATIVE_ARBITRUM} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Native Arbitrum-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 via NativeArbitrum-Bridge
 * @notice Called via SocketGateway if the routeId in the request maps to the routeId of NativeArbitrum-Implementation
 * @notice This is used when transferring from ethereum chain to arbitrum via their native bridge.
 * @notice Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * @notice RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract NativeArbitrumImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativeArbitrumIdentifier = NATIVE_ARBITRUM;

    uint256 public constant DESTINATION_CHAIN_ID = 42161;

    /// @notice Function-selector for ERC20-token bridging on NativeArbitrum
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_ARBITRUM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,uint256,uint256,bytes32,address,address,address,bytes)"
            )
        );

    bytes4 public immutable NATIVE_ARBITRUM_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,uint256,uint256,address,address,bytes32,bytes))"
            )
        );

    /// @notice router address of NativeArbitrum Bridge
    /// @notice GatewayRouter looks up ERC20Token's gateway, and finding that it's Standard ERC20 gateway (the L1ERC20Gateway contract).
    address public immutable router;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = _router;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct NativeArbitrumBridgeDataNoToken {
        uint256 value;
        /// @notice maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 maxGas;
        /// @notice gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 gasPriceBid;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of Gateway which handles the token bridging for the token
        /// @notice gatewayAddress is unique for each token
        address gatewayAddress;
        /// @notice socket offchain created hash
        bytes32 metadata;
        /// @notice data is a depositParameter derived from erc20Bridger of nativeArbitrum
        bytes data;
    }

    struct NativeArbitrumBridgeData {
        uint256 value;
        /// @notice maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 maxGas;
        /// @notice gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 gasPriceBid;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of Gateway which handles the token bridging for the token
        /// @notice gatewayAddress is unique for each token
        address gatewayAddress;
        /// @notice address of token being bridged
        address token;
        /// @notice socket offchain created hash
        bytes32 metadata;
        /// @notice data is a depositParameter derived from erc20Bridger of nativeArbitrum
        bytes data;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativeArbitrumBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for NativeArbitrumBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        NativeArbitrumBridgeData memory nativeArbitrumBridgeData = abi.decode(
            bridgeData,
            (NativeArbitrumBridgeData)
        );
        ERC20(nativeArbitrumBridgeData.token).safeApprove(
            nativeArbitrumBridgeData.gatewayAddress,
            amount
        );

        L1GatewayRouter(router).outboundTransfer{
            value: nativeArbitrumBridgeData.value
        }(
            nativeArbitrumBridgeData.token,
            nativeArbitrumBridgeData.receiverAddress,
            amount,
            nativeArbitrumBridgeData.maxGas,
            nativeArbitrumBridgeData.gasPriceBid,
            nativeArbitrumBridgeData.data
        );

        emit SocketBridge(
            amount,
            nativeArbitrumBridgeData.token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            nativeArbitrumBridgeData.receiverAddress,
            nativeArbitrumBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativeArbitrumBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param nativeArbitrumBridgeData encoded data for NativeArbitrumBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        NativeArbitrumBridgeDataNoToken calldata nativeArbitrumBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );
        ERC20(token).safeApprove(
            nativeArbitrumBridgeData.gatewayAddress,
            bridgeAmount
        );

        L1GatewayRouter(router).outboundTransfer{
            value: nativeArbitrumBridgeData.value
        }(
            token,
            nativeArbitrumBridgeData.receiverAddress,
            bridgeAmount,
            nativeArbitrumBridgeData.maxGas,
            nativeArbitrumBridgeData.gasPriceBid,
            nativeArbitrumBridgeData.data
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            nativeArbitrumBridgeData.receiverAddress,
            nativeArbitrumBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativeArbitrum-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param value value
     * @param maxGas maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
     * @param gasPriceBid gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param gatewayAddress address of Gateway which handles the token bridging for the token, gatewayAddress is unique for each token
     * @param data data is a depositParameter derived from erc20Bridger of nativeArbitrum
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 value,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes32 metadata,
        address receiverAddress,
        address token,
        address gatewayAddress,
        bytes memory data
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(gatewayAddress, amount);

        L1GatewayRouter(router).outboundTransfer{value: value}(
            token,
            receiverAddress,
            amount,
            maxGas,
            gasPriceBid,
            data
        );

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {OnlySocketGatewayOwner, OnlySocketDeployer} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Bridge Implementation will follow this interface.
 */
abstract contract BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketDeployFactory;

    /// @notice immutable variable with instance of SocketRoute to access route functions
    ISocketRoute public immutable socketRoute;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketBridge(
        uint256 amount,
        address token,
        uint256 toChainId,
        bytes32 bridgeName,
        address sender,
        address receiver,
        bytes32 metadata
    );

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     * @param _socketDeployFactory Socket Deploy Factory address, an immutable variable to set.
     */
    constructor(address _socketGateway, address _socketDeployFactory) {
        socketGateway = _socketGateway;
        socketDeployFactory = _socketDeployFactory;
        socketRoute = ISocketRoute(_socketGateway);
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketDeployFactory() {
        if (msg.sender != socketDeployFactory) {
            revert OnlySocketDeployer();
        }
        _;
    }

    /****************************************
     *    RESTRICTED FUNCTIONS              *
     ****************************************/

    /**
     * @notice function to rescue the ERC20 tokens in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    function killme() external isSocketDeployFactory {
        selfdestruct(payable(msg.sender));
    }

    /******************************
     *    VIRTUAL FUNCTIONS       *
     *****************************/

    /**
     * @notice function to bridge which is succeeding the swap function
     * @notice this function is to be used only when bridging as a succeeding step
     * @notice All bridge implementation contracts must implement this function
     * @notice bridge-implementations will have a bridge specific struct with properties used in bridging
     * @param bridgeData encoded value of properties in the bridgeData Struct
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libraries/Pb.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/cbridge.sol";
import "./interfaces/ICelerStorageWrapper.sol";
import {TransferIdExists, InvalidCelerRefund, CelerAlreadyRefunded, CelerRefundNotReady} from "../../errors/SocketErrors.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {CBRIDGE} from "../../static/RouteIdentifiers.sol";

/**
 * @title Celer-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Celer-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of CelerImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract CelerImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable CBridgeIdentifier = CBRIDGE;

    /// @notice Utility to perform operation on Buffer
    using Pb for Pb.Buffer;

    /// @notice Function-selector for ERC20-token bridging on Celer-Route
    /// @dev This function selector is to be used while building transaction-data to bridge ERC20 tokens
    bytes4 public immutable CELER_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,uint256,bytes32,uint64,uint64,uint32)"
            )
        );

    /// @notice Function-selector for Native bridging on Celer-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable CELER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,uint256,bytes32,uint64,uint64,uint32)"
            )
        );

    bytes4 public immutable CELER_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,uint64,uint32,uint64,bytes32))"
            )
        );

    /// @notice router Contract instance used to deposit ERC20 and Native on to Celer-Bridge
    /// @dev contract instance is to be initialized in the constructor using the routerAddress passed as constructor argument
    ICBridge public immutable router;

    /// @notice celerStorageWrapper Contract instance used to store the transferId generated during ERC20 and Native bridge on to Celer-Bridge
    /// @dev contract instance is to be initialized in the constructor using the celerStorageWrapperAddress passed as constructor argument
    ICelerStorageWrapper public immutable celerStorageWrapper;

    /// @notice WETH token address
    address public immutable weth;

    /// @notice chainId used during generation of transferId generated while bridging ERC20 and Native on to Celer-Bridge
    /// @dev this is to be initialised in the constructor
    uint64 public immutable chainId;

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    }

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure routerAddress, weth-address, celerStorageWrapperAddress are set properly for the chainId in which the contract is being deployed
    constructor(
        address _routerAddress,
        address _weth,
        address _celerStorageWrapperAddress,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = ICBridge(_routerAddress);
        celerStorageWrapper = ICelerStorageWrapper(_celerStorageWrapperAddress);
        weth = _weth;
        chainId = uint64(block.chainid);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct CelerBridgeDataNoToken {
        address receiverAddress;
        uint64 toChainId;
        uint32 maxSlippage;
        uint64 nonce;
        bytes32 metadata;
    }

    struct CelerBridgeData {
        address token;
        address receiverAddress;
        uint64 toChainId;
        uint32 maxSlippage;
        uint64 nonce;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for CelerBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        CelerBridgeData memory celerBridgeData = abi.decode(
            bridgeData,
            (CelerBridgeData)
        );

        if (celerBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    weth,
                    amount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

            router.sendNative{value: amount}(
                celerBridgeData.receiverAddress,
                amount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        } else {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    celerBridgeData.token,
                    amount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
            router.send(
                celerBridgeData.receiverAddress,
                celerBridgeData.token,
                amount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        }

        emit SocketBridge(
            amount,
            celerBridgeData.token,
            celerBridgeData.toChainId,
            CBridgeIdentifier,
            msg.sender,
            celerBridgeData.receiverAddress,
            celerBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param celerBridgeData encoded data for CelerBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        CelerBridgeDataNoToken calldata celerBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    weth,
                    bridgeAmount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

            router.sendNative{value: bridgeAmount}(
                celerBridgeData.receiverAddress,
                bridgeAmount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        } else {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    token,
                    bridgeAmount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
            router.send(
                celerBridgeData.receiverAddress,
                token,
                bridgeAmount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            celerBridgeData.toChainId,
            CBridgeIdentifier,
            msg.sender,
            celerBridgeData.receiverAddress,
            celerBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Celer-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of recipient
     * @param token address of token being bridged
     * @param amount amount of token for bridging
     * @param toChainId destination ChainId
     * @param nonce nonce of the sender-account address
     * @param maxSlippage maximum Slippage for the bridging
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        uint256 amount,
        bytes32 metadata,
        uint64 toChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable {
        /// @notice transferId is generated using the request-params and nonce of the account
        /// @notice transferId should be unique for each request and this is used while handling refund from celerBridge
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                receiverAddress,
                token,
                amount,
                toChainId,
                nonce,
                chainId
            )
        );

        /// @notice stored in the CelerStorageWrapper contract
        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        router.send(
            receiverAddress,
            token,
            amount,
            toChainId,
            nonce,
            maxSlippage
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            CBridgeIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Celer-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of recipient
     * @param amount amount of token for bridging
     * @param toChainId destination ChainId
     * @param nonce nonce of the sender-account address
     * @param maxSlippage maximum Slippage for the bridging
     */
    function bridgeNativeTo(
        address receiverAddress,
        uint256 amount,
        bytes32 metadata,
        uint64 toChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable {
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                receiverAddress,
                weth,
                amount,
                toChainId,
                nonce,
                chainId
            )
        );

        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        router.sendNative{value: amount}(
            receiverAddress,
            amount,
            toChainId,
            nonce,
            maxSlippage
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            CBridgeIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle refund from CelerBridge-Router
     * @param _request request data generated offchain using the celer-SDK
     * @param _sigs generated offchain using the celer-SDK
     * @param _signers  generated offchain using the celer-SDK
     * @param _powers generated offchain using the celer-SDK
     */
    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        WithdrawMsg memory request = decWithdrawMsg(_request);
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.chainid,
                request.seqnum,
                request.receiver,
                request.token,
                request.amount
            )
        );
        uint256 _initialNativeBalance = address(this).balance;
        uint256 _initialTokenBalance = ERC20(request.token).balanceOf(
            address(this)
        );
        if (!router.withdraws(transferId)) {
            router.withdraw(_request, _sigs, _signers, _powers);
        }

        if (request.receiver != socketGateway) {
            revert InvalidCelerRefund();
        }

        address _receiver = celerStorageWrapper.getAddressFromTransferId(
            request.refid
        );
        celerStorageWrapper.deleteTransferId(request.refid);

        if (_receiver == address(0)) {
            revert CelerAlreadyRefunded();
        }

        uint256 _nativeBalanceAfter = address(this).balance;
        uint256 _tokenBalanceAfter = ERC20(request.token).balanceOf(
            address(this)
        );
        if (_nativeBalanceAfter > _initialNativeBalance) {
            if ((_nativeBalanceAfter - _initialNativeBalance) != request.amount)
                revert CelerRefundNotReady();
            payable(_receiver).transfer(request.amount);
            return;
        }

        if (_tokenBalanceAfter > _initialTokenBalance) {
            if ((_tokenBalanceAfter - _initialTokenBalance) != request.amount)
                revert CelerRefundNotReady();
            ERC20(request.token).safeTransfer(_receiver, request.amount);
            return;
        }

        revert CelerRefundNotReady();
    }

    function decWithdrawMsg(
        bytes memory raw
    ) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

import {OnlySocketGateway, TransferIdExists, TransferIdDoesnotExist} from "../../errors/SocketErrors.sol";

/**
 * @title CelerStorageWrapper
 * @notice handle storageMappings used while bridging ERC20 and native on CelerBridge
 * @dev all functions ehich mutate the storage are restricted to Owner of SocketGateway
 * @author Socket dot tech.
 */
contract CelerStorageWrapper {
    /// @notice Socketgateway-address to be set in the constructor of CelerStorageWrapper
    address public immutable socketGateway;

    /// @notice mapping to store the transferId generated during bridging on Celer to message-sender
    mapping(bytes32 => address) private transferIdMapping;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @param transferIdAddress message sender who is making the bridging on CelerBridge
     */
    function setAddressForTransferId(
        bytes32 transferId,
        address transferIdAddress
    ) external {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        if (transferIdMapping[transferId] != address(0)) {
            revert TransferIdExists();
        }
        transferIdMapping[transferId] = transferIdAddress;
    }

    /**
     * @notice function to delete the transferId when the celer bridge processes a refund.
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     */
    function deleteTransferId(bytes32 transferId) external {
        if (msg.sender != socketGateway) {
            revert OnlySocketGateway();
        }
        if (transferIdMapping[transferId] == address(0)) {
            revert TransferIdDoesnotExist();
        }

        delete transferIdMapping[transferId];
    }

    /**
     * @notice function to lookup the address mapped to the transferId
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @return address of account mapped to transferId
     */
    function getAddressFromTransferId(
        bytes32 transferId
    ) external view returns (address) {
        return transferIdMapping[transferId];
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface ICBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title Celer-StorageWrapper interface
 * @notice Interface to handle storageMappings used while bridging ERC20 and native on CelerBridge
 * @dev all functions ehich mutate the storage are restricted to Owner of SocketGateway
 * @author Socket dot tech.
 */
interface ICelerStorageWrapper {
    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @param transferIdAddress message sender who is making the bridging on CelerBridge
     */
    function setAddressForTransferId(
        bytes32 transferId,
        address transferIdAddress
    ) external;

    /**
     * @notice function to store the transferId and message-sender of a bridging activity
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     */
    function deleteTransferId(bytes32 transferId) external;

    /**
     * @notice function to lookup the address mapped to the transferId
     * @param transferId transferId generated during the bridging of ERC20 or native on CelerBridge
     * @return address of account mapped to transferId
     */
    function getAddressFromTransferId(
        bytes32 transferId
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title HopAMM
 * @notice Interface to handle the token bridging to L2 chains.
 */
interface HopAMM {
    /**
     * @notice To send funds L2->L1 or L2->L2, call the swapAndSend on the L2 AMM Wrapper contract
     * @param chainId chainId of the L2 contract
     * @param recipient receiver address
     * @param amount amount is the amount the user wants to send plus the Bonder fee
     * @param bonderFee fees
     * @param amountOutMin minimum amount
     * @param deadline deadline for bridging
     * @param destinationAmountOutMin minimum amount expected to be bridged on L2
     * @param destinationDeadline destination time before which token is to be bridged on L2
     */
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title L1Bridge Hop Interface
 * @notice L1 Hop Bridge, Used to transfer from L1 to L2s.
 */
interface IHopL1Bridge {
    /**
     * @notice `amountOutMin` and `deadline` should be 0 when no swap is intended at the destination.
     * @notice `amount` is the total amount the user wants to send including the relayer fee
     * @dev Send tokens to a supported layer-2 to mint hToken and optionally swap the hToken in the
     * AMM at the destination.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the relayer at the destination.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     */
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IHopL1Bridge.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {HOP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Hop-L1 Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hop-Bridge from L1 to Supported L2s
 * Called via SocketGateway if the routeId in the request maps to the routeId of HopImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HopImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HopIdentifier = HOP;

    /// @notice Function-selector for ERC20-token bridging on Hop-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,address,uint256,uint256,uint256,uint256,(uint256,bytes32))"
            )
        );

    /// @notice Function-selector for Native bridging on Hop-L1-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,address,uint256,uint256,uint256,uint256,uint256,bytes32)"
            )
        );

    bytes4 public immutable HOP_L1_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,address,uint256,uint256,uint256,uint256,bytes32))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HopDataNoToken {
        // The address receiving funds at the destination
        address receiverAddress;
        // address of the Hop-L1-Bridge to handle bridging the tokens
        address l1bridgeAddr;
        // relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
        address relayer;
        // The chainId of the destination chain
        uint256 toChainId;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
        uint256 relayerFee;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // socket offchain created hash
        bytes32 metadata;
    }

    struct HopData {
        /// @notice address of token being bridged
        address token;
        // The address receiving funds at the destination
        address receiverAddress;
        // address of the Hop-L1-Bridge to handle bridging the tokens
        address l1bridgeAddr;
        // relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
        address relayer;
        // The chainId of the destination chain
        uint256 toChainId;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
        uint256 relayerFee;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // socket offchain created hash
        bytes32 metadata;
    }

    struct HopERC20Data {
        uint256 deadline;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Hop-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HopData memory hopData = abi.decode(bridgeData, (HopData));

        if (hopData.token == NATIVE_TOKEN_ADDRESS) {
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2{value: amount}(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        } else {
            // perform bridging
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        }

        emit SocketBridge(
            amount,
            hopData.token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param hopData encoded data for HopData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        HopDataNoToken calldata hopData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2{value: bridgeAmount}(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        } else {
            // perform bridging
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hop-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param token token being bridged
     * @param l1bridgeAddr address of the Hop-L1-Bridge to handle bridging the tokens
     * @param relayer The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
     * @param toChainId The chainId of the destination chain
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     * @param hopData extra data needed to build the tx
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        address l1bridgeAddr,
        address relayer,
        uint256 toChainId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 relayerFee,
        HopERC20Data calldata hopData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        // perform bridging
        IHopL1Bridge(l1bridgeAddr).sendToL2(
            toChainId,
            receiverAddress,
            amount,
            amountOutMin,
            hopData.deadline,
            relayer,
            relayerFee
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hop-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param l1bridgeAddr address of the Hop-L1-Bridge to handle bridging the tokens
     * @param relayer The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
     * @param toChainId The chainId of the destination chain
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     */
    function bridgeNativeTo(
        address receiverAddress,
        address l1bridgeAddr,
        address relayer,
        uint256 toChainId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 relayerFee,
        uint256 deadline,
        bytes32 metadata
    ) external payable {
        IHopL1Bridge(l1bridgeAddr).sendToL2{value: amount}(
            toChainId,
            receiverAddress,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/amm.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {HOP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Hop-L2 Route Implementation
 * @notice This is the L2 implementation, so this is used when transferring from l2 to supported l2s
 * Called via SocketGateway if the routeId in the request maps to the routeId of HopL2-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HopImplL2 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HopIdentifier = HOP;

    /// @notice Function-selector for ERC20-token bridging on Hop-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HOP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,(uint256,uint256,uint256,uint256,uint256,bytes32))"
            )
        );

    /// @notice Function-selector for Native bridging on Hop-L2-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable HOP_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bytes32)"
            )
        );

    bytes4 public immutable HOP_L2_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes32))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {}

    /// @notice Struct to be used as a input parameter for Bridging tokens via Hop-L2-route
    /// @dev while building transactionData,values should be set in this sequence of properties in this struct
    struct HopBridgeRequestData {
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HopBridgeDataNoToken {
        // The address receiving funds at the destination
        address receiverAddress;
        // AMM address of Hop on L2
        address hopAMM;
        // The chainId of the destination chain
        uint256 toChainId;
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    struct HopBridgeData {
        /// @notice address of token being bridged
        address token;
        // The address receiving funds at the destination
        address receiverAddress;
        // AMM address of Hop on L2
        address hopAMM;
        // The chainId of the destination chain
        uint256 toChainId;
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Hop-L2-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HopBridgeData memory hopData = abi.decode(bridgeData, (HopBridgeData));

        if (hopData.token == NATIVE_TOKEN_ADDRESS) {
            HopAMM(hopData.hopAMM).swapAndSend{value: amount}(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        } else {
            // perform bridging
            HopAMM(hopData.hopAMM).swapAndSend(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        }

        emit SocketBridge(
            amount,
            hopData.token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param hopData encoded data for HopData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        HopBridgeDataNoToken calldata hopData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            HopAMM(hopData.hopAMM).swapAndSend{value: bridgeAmount}(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        } else {
            // perform bridging
            HopAMM(hopData.hopAMM).swapAndSend(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hop-L2-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param token token being bridged
     * @param hopAMM AMM address of Hop on L2
     * @param amount The amount being bridged
     * @param toChainId The chainId of the destination chain
     * @param hopBridgeRequestData extraData for Bridging across Hop-L2
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        HopBridgeRequestData calldata hopBridgeRequestData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);

        HopAMM(hopAMM).swapAndSend(
            toChainId,
            receiverAddress,
            amount,
            hopBridgeRequestData.bonderFee,
            hopBridgeRequestData.amountOutMin,
            hopBridgeRequestData.deadline,
            hopBridgeRequestData.amountOutMinDestination,
            hopBridgeRequestData.deadlineDestination
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            hopBridgeRequestData.metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hop-L2-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param hopAMM AMM address of Hop on L2
     * @param amount The amount being bridged
     * @param toChainId The chainId of the destination chain
     * @param bonderFee fees passed to relayer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     * @param amountOutMinDestination Minimum amount expected to be received or bridged to destination
     * @param deadlineDestination deadline for bridging to destination
     */
    function bridgeNativeTo(
        address receiverAddress,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 amountOutMinDestination,
        uint256 deadlineDestination,
        bytes32 metadata
    ) external payable {
        // token address might not be indication thats why passed through extraData
        // perform bridging
        HopAMM(hopAMM).swapAndSend{value: amount}(
            toChainId,
            receiverAddress,
            amount,
            bonderFee,
            amountOutMin,
            deadline,
            amountOutMinDestination,
            deadlineDestination
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/hyphen.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {HYPHEN} from "../../static/RouteIdentifiers.sol";

/**
 * @title Hyphen-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hyphen-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of HyphenImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HyphenImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HyphenIdentifier = HYPHEN;

    /// @notice Function-selector for ERC20-token bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HYPHEN_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeERC20To(uint256,bytes32,address,address,uint256)")
        );

    /// @notice Function-selector for Native bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable HYPHEN_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,bytes32,address,uint256)"));

    bytes4 public immutable HYPHEN_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256("swapAndBridge(uint32,bytes,(address,uint256,bytes32))")
        );

    /// @notice liquidityPoolManager - liquidityPool Manager of Hyphen used to bridge ERC20 and native
    /// @dev this is to be initialized in constructor with a valid deployed address of hyphen-liquidityPoolManager
    HyphenLiquidityPoolManager public immutable liquidityPoolManager;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure liquidityPoolManager-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _liquidityPoolManager,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        liquidityPoolManager = HyphenLiquidityPoolManager(
            _liquidityPoolManager
        );
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HyphenData {
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    struct HyphenDataNoToken {
        /// @notice address of receiver
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
        /// @notice chainId of destination
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for HyphenBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HyphenData memory hyphenData = abi.decode(bridgeData, (HyphenData));

        if (hyphenData.token == NATIVE_TOKEN_ADDRESS) {
            liquidityPoolManager.depositNative{value: amount}(
                hyphenData.receiverAddress,
                hyphenData.toChainId,
                "SOCKET"
            );
        } else {
            liquidityPoolManager.depositErc20(
                hyphenData.toChainId,
                hyphenData.token,
                hyphenData.receiverAddress,
                amount,
                "SOCKET"
            );
        }

        emit SocketBridge(
            amount,
            hyphenData.token,
            hyphenData.toChainId,
            HyphenIdentifier,
            msg.sender,
            hyphenData.receiverAddress,
            hyphenData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param hyphenData encoded data for hyphenData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        HyphenDataNoToken calldata hyphenData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );
        if (token == NATIVE_TOKEN_ADDRESS) {
            liquidityPoolManager.depositNative{value: bridgeAmount}(
                hyphenData.receiverAddress,
                hyphenData.toChainId,
                "SOCKET"
            );
        } else {
            liquidityPoolManager.depositErc20(
                hyphenData.toChainId,
                token,
                hyphenData.receiverAddress,
                bridgeAmount,
                "SOCKET"
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            hyphenData.toChainId,
            HyphenIdentifier,
            msg.sender,
            hyphenData.receiverAddress,
            hyphenData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hyphen-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param token address of token being bridged
     * @param toChainId chainId of destination
     */
    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        liquidityPoolManager.depositErc20(
            toChainId,
            token,
            receiverAddress,
            amount,
            "SOCKET"
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HyphenIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hyphen-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param toChainId chainId of destination
     */
    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId
    ) external payable {
        liquidityPoolManager.depositNative{value: amount}(
            receiverAddress,
            toChainId,
            "SOCKET"
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HyphenIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/**
 * @title HyphenLiquidityPoolManager
 * @notice interface with functions to bridge ERC20 and Native via Hyphen-Bridge
 * @author Socket dot tech.
 */
interface HyphenLiquidityPoolManager {
    /**
     * @dev Function used to deposit tokens into pool to initiate a cross chain token transfer.
     * @param toChainId Chain id where funds needs to be transfered
     * @param tokenAddress ERC20 Token address that needs to be transfered
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param amount Amount of token being transfered
     */
    function depositErc20(
        uint256 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string calldata tag
    ) external;

    /**
     * @dev Function used to deposit native token into pool to initiate a cross chain token transfer.
     * @param receiver Address on toChainId where tokens needs to be transfered
     * @param toChainId Chain id where funds needs to be transfered
     */
    function depositNative(
        address receiver,
        uint256 toChainId,
        string calldata tag
    ) external payable;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface L1StandardBridge {
    /**
     * @dev Performs the logic for deposits by storing the ETH and informing the L2 ETH Gateway of
     * the deposit.
     * @param _to Account to give the deposit to on L2.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositETHTo(
        address _to,
        uint32 _l2Gas,
        bytes calldata _data
    ) external payable;

    /**
     * @dev deposit an amount of ERC20 to a recipient's balance on L2.
     * @param _l1Token Address of the L1 ERC20 we are depositing
     * @param _l2Token Address of the L1 respective L2 ERC20
     * @param _to L2 address to credit the withdrawal to.
     * @param _amount Amount of the ERC20 to deposit.
     * @param _l2Gas Gas limit required to complete the deposit on L2.
     * @param _data Optional data to forward to L2. This data is provided
     *        solely as a convenience for external contracts. Aside from enforcing a maximum
     *        length, these contracts provide no guarantees about its content.
     */
    function depositERC20To(
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint32 _l2Gas,
        bytes calldata _data
    ) external;
}

interface OldL1TokenGateway {
    /**
     * @dev Transfer SNX to L2 First, moves the SNX into the deposit escrow
     *
     * @param _to Account to give the deposit to on L2
     * @param _amount Amount of the ERC20 to deposit.
     */
    function depositTo(address _to, uint256 _amount) external;

    /**
     * @dev Transfer SNX to L2 First, moves the SNX into the deposit escrow
     *
     * @param currencyKey currencyKey for the SynthToken
     * @param destination Account to give the deposit to on L2
     * @param amount Amount of the ERC20 to deposit.
     */
    function initiateSynthTransfer(
        bytes32 currencyKey,
        address destination,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/optimism.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {UnsupportedInterfaceId} from "../../../errors/SocketErrors.sol";
import {NATIVE_OPTIMISM} from "../../../static/RouteIdentifiers.sol";

/**
 * @title NativeOptimism-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via NativeOptimism-Bridge
 * Tokens are bridged from Ethereum to Optimism Chain.
 * Called via SocketGateway if the routeId in the request maps to the routeId of NativeOptimism-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract NativeOptimismImpl is BridgeImplBase {
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativeOptimismIdentifier = NATIVE_OPTIMISM;

    uint256 public constant DESTINATION_CHAIN_ID = 10;

    /// @notice Function-selector for ERC20-token bridging on Native-Optimism-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_OPTIMISM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint32,(bytes32,bytes32),uint256,uint256,address,bytes)"
            )
        );

    /// @notice Function-selector for Native bridging on Native-Optimism-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native balance
    bytes4
        public immutable NATIVE_OPTIMISM_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint32,uint256,bytes32,bytes)"
            )
        );

    bytes4 public immutable NATIVE_OPTIMISM_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,bytes32,bytes32,address,address,uint32,address,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct OptimismBridgeDataNoToken {
        // interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
        uint256 interfaceId;
        // currencyKey of the token beingBridged
        bytes32 currencyKey;
        // socket offchain created hash
        bytes32 metadata;
        // address of receiver of bridged tokens
        address receiverAddress;
        /**
         * OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
         * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
         */
        address customBridgeAddress;
        // Gas limit required to complete the deposit on L2.
        uint32 l2Gas;
        // Address of the L1 respective L2 ERC20
        address l2Token;
        // additional data , for ll contracts this will be 0x data or empty data
        bytes data;
    }

    struct OptimismBridgeData {
        // interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
        uint256 interfaceId;
        // currencyKey of the token beingBridged
        bytes32 currencyKey;
        // socket offchain created hash
        bytes32 metadata;
        // address of receiver of bridged tokens
        address receiverAddress;
        /**
         * OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
         * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
         */
        address customBridgeAddress;
        /// @notice address of token being bridged
        address token;
        // Gas limit required to complete the deposit on L2.
        uint32 l2Gas;
        // Address of the L1 respective L2 ERC20
        address l2Token;
        // additional data , for ll contracts this will be 0x data or empty data
        bytes data;
    }

    struct OptimismERC20Data {
        bytes32 currencyKey;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in OptimismBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Optimism-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        OptimismBridgeData memory optimismBridgeData = abi.decode(
            bridgeData,
            (OptimismBridgeData)
        );

        emit SocketBridge(
            amount,
            optimismBridgeData.token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            optimismBridgeData.receiverAddress,
            optimismBridgeData.metadata
        );
        if (optimismBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            L1StandardBridge(optimismBridgeData.customBridgeAddress)
                .depositETHTo{value: amount}(
                optimismBridgeData.receiverAddress,
                optimismBridgeData.l2Gas,
                optimismBridgeData.data
            );
        } else {
            if (optimismBridgeData.interfaceId == 0) {
                revert UnsupportedInterfaceId();
            }

            ERC20(optimismBridgeData.token).safeApprove(
                optimismBridgeData.customBridgeAddress,
                amount
            );

            if (optimismBridgeData.interfaceId == 1) {
                // deposit into standard bridge
                L1StandardBridge(optimismBridgeData.customBridgeAddress)
                    .depositERC20To(
                        optimismBridgeData.token,
                        optimismBridgeData.l2Token,
                        optimismBridgeData.receiverAddress,
                        amount,
                        optimismBridgeData.l2Gas,
                        optimismBridgeData.data
                    );
                return;
            }

            // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
            if (optimismBridgeData.interfaceId == 2) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .depositTo(optimismBridgeData.receiverAddress, amount);
                return;
            }

            if (optimismBridgeData.interfaceId == 3) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .initiateSynthTransfer(
                        optimismBridgeData.currencyKey,
                        optimismBridgeData.receiverAddress,
                        amount
                    );
                return;
            }
        }
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in OptimismBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param optimismBridgeData encoded data for OptimismBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        OptimismBridgeDataNoToken calldata optimismBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            optimismBridgeData.receiverAddress,
            optimismBridgeData.metadata
        );
        if (token == NATIVE_TOKEN_ADDRESS) {
            L1StandardBridge(optimismBridgeData.customBridgeAddress)
                .depositETHTo{value: bridgeAmount}(
                optimismBridgeData.receiverAddress,
                optimismBridgeData.l2Gas,
                optimismBridgeData.data
            );
        } else {
            if (optimismBridgeData.interfaceId == 0) {
                revert UnsupportedInterfaceId();
            }

            ERC20(token).safeApprove(
                optimismBridgeData.customBridgeAddress,
                bridgeAmount
            );

            if (optimismBridgeData.interfaceId == 1) {
                // deposit into standard bridge
                L1StandardBridge(optimismBridgeData.customBridgeAddress)
                    .depositERC20To(
                        token,
                        optimismBridgeData.l2Token,
                        optimismBridgeData.receiverAddress,
                        bridgeAmount,
                        optimismBridgeData.l2Gas,
                        optimismBridgeData.data
                    );
                return;
            }

            // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
            if (optimismBridgeData.interfaceId == 2) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .depositTo(
                        optimismBridgeData.receiverAddress,
                        bridgeAmount
                    );
                return;
            }

            if (optimismBridgeData.interfaceId == 3) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .initiateSynthTransfer(
                        optimismBridgeData.currencyKey,
                        optimismBridgeData.receiverAddress,
                        bridgeAmount
                    );
                return;
            }
        }
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativeOptimism-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param receiverAddress address of receiver of bridged tokens
     * @param customBridgeAddress OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
     *                           contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     * @param l2Gas Gas limit required to complete the deposit on L2.
     * @param optimismData extra data needed for optimism bridge
     * @param amount amount being bridged
     * @param interfaceId interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
     * @param l2Token Address of the L1 respective L2 ERC20
     * @param data additional data , for ll contracts this will be 0x data or empty data
     */
    function bridgeERC20To(
        address token,
        address receiverAddress,
        address customBridgeAddress,
        uint32 l2Gas,
        OptimismERC20Data calldata optimismData,
        uint256 amount,
        uint256 interfaceId,
        address l2Token,
        bytes calldata data
    ) external payable {
        if (interfaceId == 0) {
            revert UnsupportedInterfaceId();
        }

        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(customBridgeAddress, amount);

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            receiverAddress,
            optimismData.metadata
        );
        if (interfaceId == 1) {
            // deposit into standard bridge
            L1StandardBridge(customBridgeAddress).depositERC20To(
                token,
                l2Token,
                receiverAddress,
                amount,
                l2Gas,
                data
            );
            return;
        }

        // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
        if (interfaceId == 2) {
            OldL1TokenGateway(customBridgeAddress).depositTo(
                receiverAddress,
                amount
            );
            return;
        }

        if (interfaceId == 3) {
            OldL1TokenGateway(customBridgeAddress).initiateSynthTransfer(
                optimismData.currencyKey,
                receiverAddress,
                amount
            );
            return;
        }
    }

    /**
     * @notice function to handle native balance bridging to receipent via NativeOptimism-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of receiver of bridged tokens
     * @param customBridgeAddress OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
     *                           contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     * @param l2Gas Gas limit required to complete the deposit on L2.
     * @param amount amount being bridged
     * @param data additional data , for ll contracts this will be 0x data or empty data
     */
    function bridgeNativeTo(
        address receiverAddress,
        address customBridgeAddress,
        uint32 l2Gas,
        uint256 amount,
        bytes32 metadata,
        bytes calldata data
    ) external payable {
        L1StandardBridge(customBridgeAddress).depositETHTo{value: amount}(
            receiverAddress,
            l2Gas,
            data
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title RootChain Manager Interface for Polygon Bridge.
 */
interface IRootChainManager {
    /**
     * @notice Move ether from root to child chain, accepts ether transfer
     * Keep in mind this ether cannot be used to pay gas on child chain
     * Use Matic tokens deposited using plasma mechanism for that
     * @param user address of account that should receive WETH on child chain
     */
    function depositEtherFor(address user) external payable;

    /**
     * @notice Move tokens from root to child chain
     * @dev This mechanism supports arbitrary tokens as long as its predicate has been registered and the token is mapped
     * @param sender address of account that should receive this deposit on child chain
     * @param token address of token that is being deposited
     * @param extraData bytes data that is sent to predicate and child token contracts to handle deposit
     */
    function depositFor(
        address sender,
        address token,
        bytes memory extraData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/polygon.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {NATIVE_POLYGON} from "../../static/RouteIdentifiers.sol";

/**
 * @title NativePolygon-Route Implementation
 * @notice This is the L1 implementation, so this is used when transferring from ethereum to polygon via their native bridge.
 * @author Socket dot tech.
 */
contract NativePolygonImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativePolyonIdentifier = NATIVE_POLYGON;

    /// @notice destination-chain-Id for this router is always arbitrum
    uint256 public constant DESTINATION_CHAIN_ID = 137;

    /// @notice max value for uint256
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @notice Function-selector for ERC20-token bridging on NativePolygon-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_POLYGON_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeERC20To(uint256,bytes32,address,address)"));

    /// @notice Function-selector for Native bridging on NativePolygon-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable NATIVE_POLYGON_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,bytes32,address)"));

    bytes4 public immutable NATIVE_POLYGON_SWAP_BRIDGE_SELECTOR =
        bytes4(keccak256("swapAndBridge(uint32,address,bytes32,bytes)"));

    /// @notice root chain manager proxy on the ethereum chain
    /// @dev to be initialised in the constructor
    IRootChainManager public immutable rootChainManagerProxy;

    /// @notice ERC20 Predicate proxy on the ethereum chain
    /// @dev to be initialised in the constructor
    address public immutable erc20PredicateProxy;

    /**
     * // @notice We set all the required addresses in the constructor while deploying the contract.
     * // These will be constant addresses.
     * // @dev Please use the Proxy addresses and not the implementation addresses while setting these
     * // @param _rootChainManagerProxy address of the root chain manager proxy on the ethereum chain
     * // @param _erc20PredicateProxy address of the ERC20 Predicate proxy on the ethereum chain.
     * // @param _socketGateway address of the socketGateway contract that calls this contract
     */
    constructor(
        address _rootChainManagerProxy,
        address _erc20PredicateProxy,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        rootChainManagerProxy = IRootChainManager(_rootChainManagerProxy);
        erc20PredicateProxy = _erc20PredicateProxy;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativePolygon-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for NativePolygon-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        (address token, address receiverAddress, bytes32 metadata) = abi.decode(
            bridgeData,
            (address, address, bytes32)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: amount
            }(receiverAddress);
        } else {
            if (
                amount >
                ERC20(token).allowance(address(this), erc20PredicateProxy)
            ) {
                ERC20(token).safeApprove(erc20PredicateProxy, UINT256_MAX);
            }

            // deposit into rootchain manager
            IRootChainManager(rootChainManagerProxy).depositFor(
                receiverAddress,
                token,
                abi.encodePacked(amount)
            );
        }

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativePolygon-BridgeData struct
     * @param swapId routeId for the swapImpl
     * @param receiverAddress address of the receiver
     * @param swapData encoded data for swap
     */
    function swapAndBridge(
        uint32 swapId,
        address receiverAddress,
        bytes32 metadata,
        bytes calldata swapData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: bridgeAmount
            }(receiverAddress);
        } else {
            if (
                bridgeAmount >
                ERC20(token).allowance(address(this), erc20PredicateProxy)
            ) {
                ERC20(token).safeApprove(erc20PredicateProxy, UINT256_MAX);
            }

            // deposit into rootchain manager
            IRootChainManager(rootChainManagerProxy).depositFor(
                receiverAddress,
                token,
                abi.encodePacked(bridgeAmount)
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativePolygon-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of tokens being bridged
     * @param receiverAddress recipient address
     * @param token address of token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token
    ) external payable {
        ERC20 tokenInstance = ERC20(token);

        // set allowance for erc20 predicate
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        if (
            amount > ERC20(token).allowance(address(this), erc20PredicateProxy)
        ) {
            ERC20(token).safeApprove(erc20PredicateProxy, UINT256_MAX);
        }

        // deposit into rootchain manager
        rootChainManagerProxy.depositFor(
            receiverAddress,
            token,
            abi.encodePacked(amount)
        );

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via NativePolygon-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of tokens being bridged
     * @param receiverAddress recipient address
     */
    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress
    ) external payable {
        rootChainManagerProxy.depositEtherFor{value: amount}(receiverAddress);

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    function setApprovalForRouters(
        address[] memory routeAddresses,
        address[] memory tokenAddresses,
        bool isMax
    ) external isSocketGatewayOwner {
        for (uint32 index = 0; index < routeAddresses.length; ) {
            ERC20(tokenAddresses[index]).safeApprove(
                routeAddresses[index],
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

/// @notice interface with functions to interact with Refuel contract
interface IRefuel {
    /**
     * @notice function to deposit nativeToken to Destination-address on destinationChain
     * @param destinationChainId chainId of the Destination chain
     * @param _to recipient address
     */
    function depositNativeToken(
        uint256 destinationChainId,
        address _to
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/refuel.sol";
import "../BridgeImplBase.sol";
import {REFUEL} from "../../static/RouteIdentifiers.sol";

/**
 * @title Refuel-Route Implementation
 * @notice Route implementation with functions to bridge Native via Refuel-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of RefuelImplementation
 * @author Socket dot tech.
 */
contract RefuelBridgeImpl is BridgeImplBase {
    bytes32 public immutable RefuelIdentifier = REFUEL;

    /// @notice refuelBridge-Contract address used to deposit Native on Refuel-Bridge
    address public immutable refuelBridge;

    /// @notice Function-selector for Native bridging via Refuel-Bridge
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,address,uint256,bytes32)"));

    bytes4 public immutable REFUEL_NATIVE_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256("swapAndBridge(uint32,address,uint256,bytes32,bytes)")
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure _refuelBridge are set properly for the chainId in which the contract is being deployed
    constructor(
        address _refuelBridge,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        refuelBridge = _refuelBridge;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct RefuelBridgeData {
        address receiverAddress;
        uint256 toChainId;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in RefuelBridgeData struct
     * @param amount amount of tokens being bridged. this must be only native
     * @param bridgeData encoded data for RefuelBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        RefuelBridgeData memory refuelBridgeData = abi.decode(
            bridgeData,
            (RefuelBridgeData)
        );
        IRefuel(refuelBridge).depositNativeToken{value: amount}(
            refuelBridgeData.toChainId,
            refuelBridgeData.receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            refuelBridgeData.toChainId,
            RefuelIdentifier,
            msg.sender,
            refuelBridgeData.receiverAddress,
            refuelBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in RefuelBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param receiverAddress receiverAddress
     * @param toChainId toChainId
     * @param swapData encoded data for swap
     */
    function swapAndBridge(
        uint32 swapId,
        address receiverAddress,
        uint256 toChainId,
        bytes32 metadata,
        bytes calldata swapData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, ) = abi.decode(result, (uint256, address));
        IRefuel(refuelBridge).depositNativeToken{value: bridgeAmount}(
            toChainId,
            receiverAddress
        );

        emit SocketBridge(
            bridgeAmount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            RefuelIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Refuel-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of native being refuelled to destination chain
     * @param receiverAddress recipient address of the refuelled native
     * @param toChainId destinationChainId
     */
    function bridgeNativeTo(
        uint256 amount,
        address receiverAddress,
        uint256 toChainId,
        bytes32 metadata
    ) external payable {
        IRefuel(refuelBridge).depositNativeToken{value: amount}(
            toChainId,
            receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            RefuelIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

/**
 * @title IBridgeStargate Interface Contract.
 * @notice Interface used by Stargate-L1 and L2 Router implementations
 * @dev router and routerETH addresses will be distinct for L1 and L2
 */
interface IBridgeStargate {
    // @notice Struct to hold the additional-data for bridging ERC20 token
    struct lzTxObj {
        // gas limit to bridge the token in Stargate to destinationChain
        uint256 dstGasForCall;
        // destination nativeAmount, this is always set as 0
        uint256 dstNativeAmount;
        // destination nativeAddress, this is always set as 0x
        bytes dstNativeAddr;
    }

    /// @notice function in stargate bridge which is used to bridge ERC20 tokens to recipient on destinationChain
    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    /// @notice function in stargate bridge which is used to bridge native tokens to recipient on destinationChain
    function swapETH(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        uint256 _amountLD, // the amount, in Local Decimals, to be swapped
        uint256 _minAmountLD // the minimum amount accepted out on destination
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/stargate.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {STARGATE} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Stargate-L1-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Stargate-L1-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of Stargate-L1-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract StargateImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable StargateIdentifier = STARGATE;

    /// @notice Function-selector for ERC20-token bridging on Stargate-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable STARGATE_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,(uint256,uint256,uint256,uint256,bytes32,bytes,uint16))"
            )
        );

    /// @notice Function-selector for Native bridging on Stargate-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable STARGATE_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint16,uint256,uint256,uint256,bytes32)"
            )
        );

    bytes4 public immutable STARGATE_L1_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,uint16,uint256,uint256,uint256,uint256,uint256,uint256,bytes32,bytes))"
            )
        );

    /// @notice Stargate Router to bridge ERC20 tokens
    IBridgeStargate public immutable router;

    /// @notice Stargate Router to bridge native tokens
    IBridgeStargate public immutable routerETH;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router, routerEth are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _routerEth,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    struct StargateBridgeExtraData {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 destinationGasLimit;
        uint256 minReceivedAmt;
        bytes32 metadata;
        bytes destinationPayload;
        uint16 stargateDstChainId; // stargate defines chain id in its way
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct StargateBridgeDataNoToken {
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes32 metadata;
        bytes destinationPayload;
    }

    struct StargateBridgeData {
        address token;
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes32 metadata;
        bytes destinationPayload;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Stargate-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        StargateBridgeData memory stargateBridgeData = abi.decode(
            bridgeData,
            (StargateBridgeData)
        );

        if (stargateBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{value: amount + stargateBridgeData.optionalValue}(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                amount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(stargateBridgeData.token).safeApprove(
                address(router),
                amount
            );
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            stargateBridgeData.token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress,
            stargateBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param stargateBridgeData encoded data for StargateBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        StargateBridgeDataNoToken calldata stargateBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{
                value: bridgeAmount + stargateBridgeData.optionalValue
            }(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                bridgeAmount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(token).safeApprove(address(router), bridgeAmount);
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    bridgeAmount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress,
            stargateBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param senderAddress address of sender
     * @param receiverAddress address of recipient
     * @param amount amount of token being bridge
     * @param value value
     * @param stargateBridgeExtraData stargate bridge extradata
     */
    function bridgeERC20To(
        address token,
        address senderAddress,
        address receiverAddress,
        uint256 amount,
        uint256 value,
        StargateBridgeExtraData calldata stargateBridgeExtraData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        {
            router.swap{value: value}(
                stargateBridgeExtraData.stargateDstChainId,
                stargateBridgeExtraData.srcPoolId,
                stargateBridgeExtraData.dstPoolId,
                payable(senderAddress), // default to refund to main contract
                amount,
                stargateBridgeExtraData.minReceivedAmt,
                IBridgeStargate.lzTxObj(
                    stargateBridgeExtraData.destinationGasLimit,
                    0, // zero amount since this is a ERC20 bridging
                    "0x" //empty data since this is for only ERC20
                ),
                abi.encodePacked(receiverAddress),
                stargateBridgeExtraData.destinationPayload
            );
        }

        emit SocketBridge(
            amount,
            token,
            stargateBridgeExtraData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress,
            stargateBridgeExtraData.metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of receipient
     * @param senderAddress address of sender
     * @param stargateDstChainId stargate defines chain id in its way
     * @param amount amount of token being bridge
     * @param minReceivedAmt defines the slippage, the min qty you would accept on the destination
     * @param optionalValue optionalValue Native amount
     */
    function bridgeNativeTo(
        address receiverAddress,
        address senderAddress,
        uint16 stargateDstChainId,
        uint256 amount,
        uint256 minReceivedAmt,
        uint256 optionalValue,
        bytes32 metadata
    ) external payable {
        // perform bridging
        routerETH.swapETH{value: amount + optionalValue}(
            stargateDstChainId,
            payable(senderAddress),
            abi.encodePacked(receiverAddress),
            amount,
            minReceivedAmt
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/stargate.sol";
import "../../../errors/SocketErrors.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {STARGATE} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Stargate-L2-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Stargate-L2-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of Stargate-L2-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract StargateImplL2 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable StargateIdentifier = STARGATE;

    /// @notice Function-selector for ERC20-token bridging on Stargate-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable STARGATE_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,uint256,(uint256,uint256,uint256,uint256,bytes32,bytes,uint16))"
            )
        );

    bytes4 public immutable STARGATE_L1_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,uint16,uint256,uint256,uint256,uint256,uint256,uint256,bytes32,bytes))"
            )
        );

    /// @notice Function-selector for Native bridging on Stargate-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable STARGATE_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint16,uint256,uint256,uint256,bytes32)"
            )
        );

    /// @notice Stargate Router to bridge ERC20 tokens
    IBridgeStargate public immutable router;

    /// @notice Stargate Router to bridge native tokens
    IBridgeStargate public immutable routerETH;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router, routerEth are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _routerEth,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    /// @notice Struct to be used as a input parameter for Bridging tokens via Stargate-L2-route
    /// @dev while building transactionData,values should be set in this sequence of properties in this struct
    struct StargateBridgeExtraData {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 destinationGasLimit;
        uint256 minReceivedAmt;
        bytes32 metadata;
        bytes destinationPayload;
        uint16 stargateDstChainId; // stargate defines chain id in its way
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct StargateBridgeDataNoToken {
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes32 metadata;
        bytes destinationPayload;
    }

    struct StargateBridgeData {
        address token;
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes32 metadata;
        bytes destinationPayload;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Stargate-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        StargateBridgeData memory stargateBridgeData = abi.decode(
            bridgeData,
            (StargateBridgeData)
        );

        if (stargateBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{value: amount + stargateBridgeData.optionalValue}(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                amount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(stargateBridgeData.token).safeApprove(
                address(router),
                amount
            );
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            stargateBridgeData.token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress,
            stargateBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swapping.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param stargateBridgeData encoded data for StargateBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        StargateBridgeDataNoToken calldata stargateBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            routerETH.swapETH{
                value: bridgeAmount + stargateBridgeData.optionalValue
            }(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                bridgeAmount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(token).safeApprove(address(router), bridgeAmount);
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    bridgeAmount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0,
                        "0x"
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress,
            stargateBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param senderAddress address of sender
     * @param receiverAddress address of recipient
     * @param amount amount of token being bridge
     * @param value value
     * @param optionalValue optionalValue
     * @param stargateBridgeExtraData stargate bridge extradata
     */
    function bridgeERC20To(
        address token,
        address senderAddress,
        address receiverAddress,
        uint256 amount,
        uint256 value,
        uint256 optionalValue,
        StargateBridgeExtraData calldata stargateBridgeExtraData
    ) external payable {
        // token address might not be indication thats why passed through extraData
        if (token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{value: amount + optionalValue}(
                stargateBridgeExtraData.stargateDstChainId,
                payable(senderAddress),
                abi.encodePacked(receiverAddress),
                amount,
                stargateBridgeExtraData.minReceivedAmt
            );
        } else {
            ERC20 tokenInstance = ERC20(token);
            tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
            tokenInstance.safeApprove(address(router), amount);
            {
                router.swap{value: value}(
                    stargateBridgeExtraData.stargateDstChainId,
                    stargateBridgeExtraData.srcPoolId,
                    stargateBridgeExtraData.dstPoolId,
                    payable(senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeExtraData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeExtraData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(receiverAddress),
                    stargateBridgeExtraData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            token,
            stargateBridgeExtraData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress,
            stargateBridgeExtraData.metadata
        );
    }

    function bridgeNativeTo(
        address receiverAddress,
        address senderAddress,
        uint16 stargateDstChainId,
        uint256 amount,
        uint256 minReceivedAmt,
        uint256 optionalValue,
        bytes32 metadata
    ) external payable {
        // perform bridging
        routerETH.swapETH{value: amount + optionalValue}(
            stargateDstChainId,
            payable(senderAddress),
            abi.encodePacked(receiverAddress),
            amount,
            minReceivedAmt
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";

/// @title BaseController Controller
/// @notice Base contract for all controller contracts
abstract contract BaseController {
    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice Address used to identify if it is a Zero address
    address public immutable NULL_ADDRESS = address(0);

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGatewayAddress;

    /// @notice immutable variable with instance of SocketRoute to access route functions
    ISocketRoute public immutable socketRoute;

    /**
     * @notice Construct the base for all controllers.
     * @param _socketGatewayAddress Socketgateway address, an immutable variable to set.
     * @notice initialize the immutable variables of SocketRoute, SocketGateway
     */
    constructor(address _socketGatewayAddress) {
        socketGatewayAddress = _socketGatewayAddress;
        socketRoute = ISocketRoute(_socketGatewayAddress);
    }

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param routeId routeId mapped to the routrImplementation
     * @param data transactionData generated with arguments of bridgeRequest (offchain or by caller)
     * @return returns the bytes response of the route execution (bridging, refuel or swap executions)
     */
    function _executeRoute(
        uint32 routeId,
        bytes memory data
    ) internal returns (bytes memory) {
        (bool success, bytes memory result) = socketRoute
            .getRoute(routeId)
            .delegatecall(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BaseController} from "./BaseController.sol";
import {ISocketRequest} from "../interfaces/ISocketRequest.sol";

/**
 * @title FeesTaker-Controller Implementation
 * @notice Controller with composed actions to deduct-fees followed by Refuel, Swap and Bridge
 *          to be executed Sequentially and this is atomic
 * @author Socket dot tech.
 */
contract FeesTakerController is BaseController {
    using SafeTransferLib for ERC20;

    /// @notice event emitted upon fee-deduction to fees-taker address
    event SocketFeesDeducted(
        uint256 fees,
        address feesToken,
        address feesTaker
    );

    /// @notice Function-selector to invoke deduct-fees and swap token
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("takeFeesAndSwap((address,address,uint256,uint32,bytes))")
        );

    /// @notice Function-selector to invoke deduct-fees and bridge token
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeesAndBridge((address,address,uint256,uint32,bytes))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees and bridge multiple tokens
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeesAndMultiBridge((address,address,uint256,uint32[],bytes[]))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees followed by swapping of a token and bridging the swapped bridge
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeeAndSwapAndBridge((address,address,uint256,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice Function-selector to invoke deduct-fees refuel
    /// @notice followed by swapping of a token and bridging the swapped bridge
    /// @dev This function selector is to be used while building transaction-data
    bytes4 public immutable FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "takeFeeAndRefuelAndSwapAndBridge((address,address,uint256,uint32,bytes,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BaseController
    constructor(
        address _socketGatewayAddress
    ) BaseController(_socketGatewayAddress) {}

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and swap token
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftsRequest feesTakerSwapRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_SWAP_FUNCTION_SELECTOR
     * @return output bytes from the swap operation (last operation in the composed actions)
     */
    function takeFeesAndSwap(
        ISocketRequest.FeesTakerSwapRequest calldata ftsRequest
    ) external payable returns (bytes memory) {
        if (ftsRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftsRequest.feesTakerAddress).transfer(
                ftsRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftsRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftsRequest.feesTakerAddress,
                ftsRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftsRequest.feesAmount,
            ftsRequest.feesTakerAddress,
            ftsRequest.feesToken
        );

        //call bridge function (executeRoute for the swapRequestData)
        return _executeRoute(ftsRequest.routeId, ftsRequest.swapRequestData);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and bridge amount to destinationChain
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftbRequest feesTakerBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_BRIDGE_FUNCTION_SELECTOR
     * @return output bytes from the bridge operation (last operation in the composed actions)
     */
    function takeFeesAndBridge(
        ISocketRequest.FeesTakerBridgeRequest calldata ftbRequest
    ) external payable returns (bytes memory) {
        if (ftbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftbRequest.feesTakerAddress).transfer(
                ftbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftbRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftbRequest.feesTakerAddress,
                ftbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftbRequest.feesAmount,
            ftbRequest.feesTakerAddress,
            ftbRequest.feesToken
        );

        //call bridge function (executeRoute for the bridgeData)
        return _executeRoute(ftbRequest.routeId, ftbRequest.bridgeRequestData);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain and bridge amount to destinationChain
     * @notice multiple bridge-requests are to be generated and sequence and number of routeIds should match with the bridgeData array
     * @dev ensure correct function selector is used to generate transaction-data for bridgeRequest
     * @param ftmbRequest feesTakerMultiBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_MULTI_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeesAndMultiBridge(
        ISocketRequest.FeesTakerMultiBridgeRequest calldata ftmbRequest
    ) external payable {
        if (ftmbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(ftmbRequest.feesTakerAddress).transfer(
                ftmbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(ftmbRequest.feesToken).safeTransferFrom(
                msg.sender,
                ftmbRequest.feesTakerAddress,
                ftmbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            ftmbRequest.feesAmount,
            ftmbRequest.feesTakerAddress,
            ftmbRequest.feesToken
        );

        // multiple bridge-requests are to be generated and sequence and number of routeIds should match with the bridgeData array
        for (
            uint256 index = 0;
            index < ftmbRequest.bridgeRouteIds.length;
            ++index
        ) {
            //call bridge function (executeRoute for the bridgeData)
            _executeRoute(
                ftmbRequest.bridgeRouteIds[index],
                ftmbRequest.bridgeRequestDataItems[index]
            );
        }
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain followed by swap the amount on sourceChain followed by
     *         bridging the swapped amount to destinationChain
     * @dev while generating implData for swap and bridgeRequests, ensure correct function selector is used
     *      bridge action corresponds to the bridgeAfterSwap function of the bridgeImplementation
     * @param fsbRequest feesTakerSwapBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_SWAP_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeeAndSwapAndBridge(
        ISocketRequest.FeesTakerSwapBridgeRequest calldata fsbRequest
    ) external payable returns (bytes memory) {
        if (fsbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(fsbRequest.feesTakerAddress).transfer(
                fsbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(fsbRequest.feesToken).safeTransferFrom(
                msg.sender,
                fsbRequest.feesTakerAddress,
                fsbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            fsbRequest.feesAmount,
            fsbRequest.feesTakerAddress,
            fsbRequest.feesToken
        );

        // execute swap operation
        bytes memory swapResponseData = _executeRoute(
            fsbRequest.swapRouteId,
            fsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        // swapped amount is to be bridged to the recipient on destinationChain
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            fsbRequest.bridgeData
        );

        // execute bridge operation and return the byte-data from response of bridge operation
        return _executeRoute(fsbRequest.bridgeRouteId, bridgeImpldata);
    }

    /**
     * @notice function to deduct-fees to fees-taker address on source-chain followed by refuel followed by
     *          swap the amount on sourceChain followed by bridging the swapped amount to destinationChain
     * @dev while generating implData for refuel, swap and bridge Requests, ensure correct function selector is used
     *      bridge action corresponds to the bridgeAfterSwap function of the bridgeImplementation
     * @param frsbRequest feesTakerRefuelSwapBridgeRequest object generated either off-chain or the calling contract using
     *                   the function-selector FEES_TAKER_REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR
     */
    function takeFeeAndRefuelAndSwapAndBridge(
        ISocketRequest.FeesTakerRefuelSwapBridgeRequest calldata frsbRequest
    ) external payable returns (bytes memory) {
        if (frsbRequest.feesToken == NATIVE_TOKEN_ADDRESS) {
            //transfer the native amount to the feeTakerAddress
            payable(frsbRequest.feesTakerAddress).transfer(
                frsbRequest.feesAmount
            );
        } else {
            //transfer feesAmount to feesTakerAddress
            ERC20(frsbRequest.feesToken).safeTransferFrom(
                msg.sender,
                frsbRequest.feesTakerAddress,
                frsbRequest.feesAmount
            );
        }

        emit SocketFeesDeducted(
            frsbRequest.feesAmount,
            frsbRequest.feesTakerAddress,
            frsbRequest.feesToken
        );

        // refuel is also done via bridge execution via refuelRouteImplementation identified by refuelRouteId
        _executeRoute(frsbRequest.refuelRouteId, frsbRequest.refuelData);

        // execute swap operation
        bytes memory swapResponseData = _executeRoute(
            frsbRequest.swapRouteId,
            frsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        // swapped amount is to be bridged to the recipient on destinationChain
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            frsbRequest.bridgeData
        );

        // execute bridge operation and return the byte-data from response of bridge operation
        return _executeRoute(frsbRequest.bridgeRouteId, bridgeImpldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ISocketRequest} from "../interfaces/ISocketRequest.sol";
import {ISocketRoute} from "../interfaces/ISocketRoute.sol";
import {BaseController} from "./BaseController.sol";

/**
 * @title RefuelSwapAndBridge Controller Implementation
 * @notice Controller with composed actions for Refuel,Swap and Bridge to be executed Sequentially and this is atomic
 * @author Socket dot tech.
 */
contract RefuelSwapAndBridgeController is BaseController {
    /// @notice Function-selector to invoke refuel-swap-bridge function
    /// @dev This function selector is to be used while buidling transaction-data
    bytes4 public immutable REFUEL_SWAP_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "refuelAndSwapAndBridge((uint32,bytes,uint32,bytes,uint32,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BaseController
    constructor(
        address _socketGatewayAddress
    ) BaseController(_socketGatewayAddress) {}

    /**
     * @notice function to handle refuel followed by Swap and Bridge actions
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param rsbRequest Request with data to execute refuel followed by swap and bridge
     * @return output data from bridging operation
     */
    function refuelAndSwapAndBridge(
        ISocketRequest.RefuelSwapBridgeRequest calldata rsbRequest
    ) public payable returns (bytes memory) {
        _executeRoute(rsbRequest.refuelRouteId, rsbRequest.refuelData);

        // refuel is also a bridging activity via refuel-route-implementation
        bytes memory swapResponseData = _executeRoute(
            rsbRequest.swapRouteId,
            rsbRequest.swapData
        );

        uint256 swapAmount = abi.decode(swapResponseData, (uint256));

        //sequence of arguments for implData: amount, token, data
        // Bridging the swapAmount received in the preceeding step
        bytes memory bridgeImpldata = abi.encodeWithSelector(
            BRIDGE_AFTER_SWAP_SELECTOR,
            swapAmount,
            rsbRequest.bridgeData
        );

        return _executeRoute(rsbRequest.bridgeRouteId, bridgeImpldata);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner} from "../errors/SocketErrors.sol";

contract DisabledSocketRoute {
    using SafeTransferLib for ERC20;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;
    error RouteDisabled();

    /**
     * @notice Construct the base for all BridgeImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway) {
        socketGateway = _socketGateway;
    }

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /**
     * @notice function to rescue the ERC20 tokens in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the bridge Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    /**
     * @notice Handle route function calls gracefully.
     */
    fallback() external payable {
        revert RouteDisabled();
    }

    /**
     * @notice Support receiving ether to handle refunds etc.
     */
    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketBridgeBase} from "../interfaces/ISocketBridgeBase.sol";

/**
 * @dev In the constructor, set up the initialization code for socket
 * contracts as well as the keccak256 hash of the given initialization code.
 * that will be used to deploy any transient contracts, which will deploy any
 * socket contracts that require the use of a constructor.
 *
 * Socket contract initialization code (29 bytes):
 *
 *       0x5860208158601c335a63aaf10f428752fa158151803b80938091923cf3
 *
 * Description:
 *
 * pc|op|name         | [stack]                                | <memory>
 *
 * ** set the first stack item to zero - used later **
 * 00 58 getpc          [0]                                       <>
 *
 * ** set second stack item to 32, length of word returned from staticcall **
 * 01 60 push1
 * 02 20 outsize        [0, 32]                                   <>
 *
 * ** set third stack item to 0, position of word returned from staticcall **
 * 03 81 dup2           [0, 32, 0]                                <>
 *
 * ** set fourth stack item to 4, length of selector given to staticcall **
 * 04 58 getpc          [0, 32, 0, 4]                             <>
 *
 * ** set fifth stack item to 28, position of selector given to staticcall **
 * 05 60 push1
 * 06 1c inpos          [0, 32, 0, 4, 28]                         <>
 *
 * ** set the sixth stack item to msg.sender, target address for staticcall **
 * 07 33 caller         [0, 32, 0, 4, 28, caller]                 <>
 *
 * ** set the seventh stack item to msg.gas, gas to forward for staticcall **
 * 08 5a gas            [0, 32, 0, 4, 28, caller, gas]            <>
 *
 * ** set the eighth stack item to selector, "what" to store via mstore **
 * 09 63 push4
 * 10 aaf10f42 selector [0, 32, 0, 4, 28, caller, gas, 0xaaf10f42]    <>
 *
 * ** set the ninth stack item to 0, "where" to store via mstore ***
 * 11 87 dup8           [0, 32, 0, 4, 28, caller, gas, 0xaaf10f42, 0] <>
 *
 * ** call mstore, consume 8 and 9 from the stack, place selector in memory **
 * 12 52 mstore         [0, 32, 0, 4, 0, caller, gas]             <0xaaf10f42>
 *
 * ** call staticcall, consume items 2 through 7, place address in memory **
 * 13 fa staticcall     [0, 1 (if successful)]                    <address>
 *
 * ** flip success bit in second stack item to set to 0 **
 * 14 15 iszero         [0, 0]                                    <address>
 *
 * ** push a third 0 to the stack, position of address in memory **
 * 15 81 dup2           [0, 0, 0]                                 <address>
 *
 * ** place address from position in memory onto third stack item **
 * 16 51 mload          [0, 0, address]                           <>
 *
 * ** place address to fourth stack item for extcodesize to consume **
 * 17 80 dup1           [0, 0, address, address]                  <>
 *
 * ** get extcodesize on fourth stack item for extcodecopy **
 * 18 3b extcodesize    [0, 0, address, size]                     <>
 *
 * ** dup and swap size for use by return at end of init code **
 * 19 80 dup1           [0, 0, address, size, size]               <>
 * 20 93 swap4          [size, 0, address, size, 0]               <>
 *
 * ** push code position 0 to stack and reorder stack items for extcodecopy **
 * 21 80 dup1           [size, 0, address, size, 0, 0]            <>
 * 22 91 swap2          [size, 0, address, 0, 0, size]            <>
 * 23 92 swap3          [size, 0, size, 0, 0, address]            <>
 *
 * ** call extcodecopy, consume four items, clone runtime code to memory **
 * 24 3c extcodecopy    [size, 0]                                 <code>
 *
 * ** return to deploy final code in memory **
 * 25 f3 return         []                                        *deployed!*
 */
contract SocketDeployFactory is Ownable {
    using SafeTransferLib for ERC20;
    address public immutable disabledRouteAddress;

    mapping(address => address) _implementations;
    mapping(uint256 => bool) isDisabled;
    mapping(uint256 => bool) isRouteDeployed;
    mapping(address => bool) canDisableRoute;

    event Deployed(address _addr);
    event DisabledRoute(address _addr);
    event Destroyed(address _addr);
    error ContractAlreadyDeployed();
    error NothingToDestroy();
    error AlreadyDisabled();
    error CannotBeDisabled();
    error OnlyDisabler();

    constructor(address _owner, address disabledRoute) Ownable(_owner) {
        disabledRouteAddress = disabledRoute;
        canDisableRoute[_owner] = true;
    }

    modifier onlyDisabler() {
        if (!canDisableRoute[msg.sender]) {
            revert OnlyDisabler();
        }
        _;
    }

    function addDisablerAddress(address disabler) external onlyOwner {
        canDisableRoute[disabler] = true;
    }

    function removeDisablerAddress(address disabler) external onlyOwner {
        canDisableRoute[disabler] = false;
    }

    /**
     * @notice Deploys a route contract at predetermined location
     * @notice Caller must first deploy the route contract at another location and pass its address as implementation.
     * @param routeId route identifier
     * @param implementationContract address of deployed route contract. Its byte code will be copied to predetermined location.
     */
    function deploy(
        uint256 routeId,
        address implementationContract
    ) external onlyOwner returns (address) {
        // assign the initialization code for the socket contract.

        bytes memory initCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );

        // determine the address of the socket contract.
        address routeContractAddress = _getContractAddress(routeId);

        if (isRouteDeployed[routeId]) {
            revert ContractAlreadyDeployed();
        }

        isRouteDeployed[routeId] = true;

        //first we deploy the code we want to deploy on a separate address
        // store the implementation to be retrieved by the socket contract.
        _implementations[routeContractAddress] = implementationContract;
        address addr;
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load init code's length.
            addr := create2(0, encoded_data, encoded_size, routeId) // routeId is used as salt
        }
        require(
            addr == routeContractAddress,
            "Failed to deploy the new socket contract."
        );
        emit Deployed(addr);
        return addr;
    }

    /**
     * @notice Destroy the route deployed at a location.
     * @param routeId route identifier to be destroyed.
     */
    function destroy(uint256 routeId) external onlyDisabler {
        // determine the address of the socket contract.
        _destroy(routeId);
    }

    /**
     * @notice Deploy a disabled contract at destroyed route to handle it gracefully.
     * @param routeId route identifier to be disabled.
     */
    function disableRoute(
        uint256 routeId
    ) external onlyDisabler returns (address) {
        return _disableRoute(routeId);
    }

    /**
     * @notice Destroy a list of routeIds
     * @param routeIds array of routeIds to be destroyed.
     */
    function multiDestroy(uint256[] calldata routeIds) external onlyDisabler {
        for (uint32 index = 0; index < routeIds.length; ) {
            _destroy(routeIds[index]);
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Deploy a disabled contract at list of routeIds.
     * @param routeIds array of routeIds to be disabled.
     */
    function multiDisableRoute(
        uint256[] calldata routeIds
    ) external onlyDisabler {
        for (uint32 index = 0; index < routeIds.length; ) {
            _disableRoute(routeIds[index]);
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @dev External view function for calculating a socket contract address
     * given a particular routeId.
     */
    function getContractAddress(
        uint256 routeId
    ) external view returns (address) {
        // determine the address of the socket contract.
        return _getContractAddress(routeId);
    }

    //those two functions are getting called by the socket Contract
    function getImplementation()
        external
        view
        returns (address implementation)
    {
        return _implementations[msg.sender];
    }

    function _disableRoute(uint256 routeId) internal returns (address) {
        // assign the initialization code for the socket contract.
        bytes memory initCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );

        // determine the address of the socket contract.
        address routeContractAddress = _getContractAddress(routeId);

        if (!isRouteDeployed[routeId]) {
            revert CannotBeDisabled();
        }

        if (isDisabled[routeId]) {
            revert AlreadyDisabled();
        }

        isDisabled[routeId] = true;

        //first we deploy the code we want to deploy on a separate address
        // store the implementation to be retrieved by the socket contract.
        _implementations[routeContractAddress] = disabledRouteAddress;
        address addr;
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load init code's length.
            addr := create2(0, encoded_data, encoded_size, routeId) // routeId is used as salt.
        }
        require(
            addr == routeContractAddress,
            "Failed to deploy the new socket contract."
        );
        emit Deployed(addr);
        return addr;
    }

    function _destroy(uint256 routeId) internal {
        // determine the address of the socket contract.
        address routeContractAddress = _getContractAddress(routeId);

        if (!isRouteDeployed[routeId]) {
            revert NothingToDestroy();
        }
        ISocketBridgeBase(routeContractAddress).killme();
        emit Destroyed(routeContractAddress);
    }

    /**
     * @dev Internal view function for calculating a socket contract address
     * given a particular routeId.
     */
    function _getContractAddress(
        uint256 routeId
    ) internal view returns (address) {
        // determine the address of the socket contract.

        bytes memory initCode = (
            hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3"
        );
        return
            address(
                uint160( // downcast to match the address type.
                    uint256( // convert to uint to truncate upper digits.
                        keccak256( // compute the CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                hex"ff", // start with 0xff to distinguish from RLP.
                                address(this), // this contract will be the caller.
                                routeId, // the routeId is used as salt.
                                keccak256(abi.encodePacked(initCode)) // the init code hash.
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error CelerRefundNotReady();
error OnlySocketDeployer();
error OnlySocketGatewayOwner();
error OnlySocketGateway();
error OnlyOwner();
error OnlyNominee();
error TransferIdExists();
error TransferIdDoesnotExist();
error Address0Provided();
error SwapFailed();
error UnsupportedInterfaceId();
error InvalidCelerRefund();
error CelerAlreadyRefunded();
error IncorrectBridgeRatios();
error ZeroAddressNotAllowed();
error ArrayLengthMismatch();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISocketBridgeBase {
    function killme() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketController
 * @notice Interface for SocketController functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 *      only restriction is that this should have functions to manage controllers
 * @author Socket dot tech.
 */
interface ISocketController {
    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param _controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address _controllerAddress
    ) external returns (uint32);

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param _controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 _controllerId) external;

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param _controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 _controllerId) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketGateway
 * @notice Interface for SocketGateway functions.
 * @dev functions can be added here for invocation from external contracts or off-chain
 * @author Socket dot tech.
 */
interface ISocketGateway {
    /**
     * @notice Request-struct for controllerRequests
     * @dev ensure the value for data is generated using the function-selectors defined in the controllerImplementation contracts
     */
    struct SocketControllerRequest {
        // controllerId is the id mapped to the controllerAddress
        uint32 controllerId;
        // transactionImplData generated off-chain or by caller using function-selector of the controllerContract
        bytes data;
    }

    // @notice view to get owner-address
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketRoute
 * @notice Interface with Request DataStructures to invoke controller functions.
 * @author Socket dot tech.
 */
interface ISocketRequest {
    struct SwapMultiBridgeRequest {
        uint32 swapRouteId;
        bytes swapImplData;
        uint32[] bridgeRouteIds;
        bytes[] bridgeImplDataItems;
        uint256[] bridgeRatios;
        bytes[] eventDataItems;
    }

    // Datastructure for Refuel-Swap-Bridge function
    struct RefuelSwapBridgeRequest {
        uint32 refuelRouteId;
        bytes refuelData;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }

    // Datastructure for DeductFees-Swap function
    struct FeesTakerSwapRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 routeId;
        bytes swapRequestData;
    }

    // Datastructure for DeductFees-Bridge function
    struct FeesTakerBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 routeId;
        bytes bridgeRequestData;
    }

    // Datastructure for DeductFees-MultiBridge function
    struct FeesTakerMultiBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32[] bridgeRouteIds;
        bytes[] bridgeRequestDataItems;
    }

    // Datastructure for DeductFees-Swap-Bridge function
    struct FeesTakerSwapBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }

    // Datastructure for DeductFees-Refuel-Swap-Bridge function
    struct FeesTakerRefuelSwapBridgeRequest {
        address feesTakerAddress;
        address feesToken;
        uint256 feesAmount;
        uint32 refuelRouteId;
        bytes refuelData;
        uint32 swapRouteId;
        bytes swapData;
        uint32 bridgeRouteId;
        bytes bridgeData;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ISocketRoute
 * @notice Interface for routeManagement functions in SocketGateway.
 * @author Socket dot tech.
 */
interface ISocketRoute {
    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(address routeAddress) external returns (uint256);

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external;

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Functions taken out from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
library LibBytes {
    // solhint-disable no-inline-assembly

    // LibBytes specific errors
    error SliceOverflow();
    error SliceOutOfBounds();
    error AddressOutOfBounds();
    error UintOutOfBounds();

    // -------------------------

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
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
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        if (_length + 31 < _length) {
            revert SliceOverflow();
        }
        if (_bytes.length < _start + _length) {
            revert SliceOutOfBounds();
        }

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LibBytes.sol";

/// @title LibUtil library
/// @notice library with helper functions to operate on bytes-data and addresses
/// @author socket dot tech
library LibUtil {
    /// @notice LibBytes library to handle operations on bytes
    using LibBytes for bytes;

    /// @notice function to extract revertMessage from bytes data
    /// @dev use the revertMessage and then further revert with a custom revert and message
    /// @param _res bytes data received from the transaction call
    function getRevertMsg(
        bytes memory _res
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_res.length < 68) {
            return "Transaction reverted silently";
        }
        bytes memory revertData = _res.slice(4, _res.length - 4); // Remove the selector which is the first 4 bytes
        return abi.decode(revertData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(
        bytes memory raw
    ) internal pure returns (Buffer memory buf) {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(
        Buffer memory buf
    ) internal pure returns (uint256 tag, WireType wiretype) {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(
        Buffer memory buf
    ) internal pure returns (bytes memory b) {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(
        bytes memory b
    ) internal pure returns (address payable v) {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {LibUtil} from "./libraries/LibUtil.sol";
import "./libraries/LibBytes.sol";
import {ISocketRoute} from "./interfaces/ISocketRoute.sol";
import {ISocketRequest} from "./interfaces/ISocketRequest.sol";
import {ISocketGateway} from "./interfaces/ISocketGateway.sol";
import {IncorrectBridgeRatios, ZeroAddressNotAllowed, ArrayLengthMismatch} from "./errors/SocketErrors.sol";

/// @title SocketGatewayContract
/// @notice Socketgateway is a contract with entrypoint functions for all interactions with socket liquidity layer
/// @author Socket Team
contract SocketGatewayTemplate is Ownable {
    using LibBytes for bytes;
    using LibBytes for bytes4;
    using SafeTransferLib for ERC20;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice storage variable to keep track of total number of routes registered in socketgateway
    uint32 public routesCount = 385;

    /// @notice storage variable to keep track of total number of controllers registered in socketgateway
    uint32 public controllerCount;

    address public immutable disabledRouteAddress;

    uint256 public constant CENT_PERCENT = 100e18;

    /// @notice storage mapping for route implementation addresses
    mapping(uint32 => address) public routes;

    /// storage mapping for controller implemenation addresses
    mapping(uint32 => address) public controllers;

    // Events ------------------------------------------------------------------------------------------------------->

    /// @notice Event emitted when a router is added to socketgateway
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    /// @notice Event emitted when a route is disabled
    event RouteDisabled(uint32 indexed routeId);

    /// @notice Event emitted when ownership transfer is requested by socket-gateway-owner
    event OwnershipTransferRequested(
        address indexed _from,
        address indexed _to
    );

    /// @notice Event emitted when a controller is added to socketgateway
    event ControllerAdded(
        uint32 indexed controllerId,
        address indexed controllerAddress
    );

    /// @notice Event emitted when a controller is disabled
    event ControllerDisabled(uint32 indexed controllerId);

    constructor(address _owner, address _disabledRoute) Ownable(_owner) {
        disabledRouteAddress = _disabledRoute;
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /*******************************************
     *          EXTERNAL AND PUBLIC FUNCTIONS  *
     *******************************************/

    /**
     * @notice executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in routeData to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeId route identifier
     * @param routeData functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoute(
        uint32 routeId,
        bytes calldata routeData
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = addressAt(routeId).delegatecall(
            routeData
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice swaps a token on sourceChain and split it across multiple bridge-recipients
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the swap-data and bridge-data is generated using the function-selector defined as a constant in the implementation address
     * @param swapMultiBridgeRequest request
     */
    function swapAndMultiBridge(
        ISocketRequest.SwapMultiBridgeRequest calldata swapMultiBridgeRequest
    ) external payable {
        uint256 requestLength = swapMultiBridgeRequest.bridgeRouteIds.length;

        if (
            requestLength != swapMultiBridgeRequest.bridgeImplDataItems.length
        ) {
            revert ArrayLengthMismatch();
        }
        uint256 ratioAggregate;
        for (uint256 index = 0; index < requestLength; ) {
            ratioAggregate += swapMultiBridgeRequest.bridgeRatios[index];
        }

        if (ratioAggregate != CENT_PERCENT) {
            revert IncorrectBridgeRatios();
        }

        (bool swapSuccess, bytes memory swapResult) = addressAt(
            swapMultiBridgeRequest.swapRouteId
        ).delegatecall(swapMultiBridgeRequest.swapImplData);

        if (!swapSuccess) {
            assembly {
                revert(add(swapResult, 32), mload(swapResult))
            }
        }

        uint256 amountReceivedFromSwap = abi.decode(swapResult, (uint256));

        uint256 bridgedAmount;

        for (uint256 index = 0; index < requestLength; ) {
            uint256 bridgingAmount;

            // if it is the last bridge request, bridge the remaining amount
            if (index == requestLength - 1) {
                bridgingAmount = amountReceivedFromSwap - bridgedAmount;
            } else {
                // bridging amount is the multiplication of bridgeRatio and amountReceivedFromSwap
                bridgingAmount =
                    (amountReceivedFromSwap *
                        swapMultiBridgeRequest.bridgeRatios[index]) /
                    (CENT_PERCENT);
            }

            // update the bridged amount, this would be used for computation for last bridgeRequest
            bridgedAmount += bridgingAmount;

            bytes memory bridgeImpldata = abi.encodeWithSelector(
                BRIDGE_AFTER_SWAP_SELECTOR,
                bridgingAmount,
                swapMultiBridgeRequest.bridgeImplDataItems[index]
            );

            (bool bridgeSuccess, bytes memory bridgeResult) = addressAt(
                swapMultiBridgeRequest.bridgeRouteIds[index]
            ).delegatecall(bridgeImpldata);

            if (!bridgeSuccess) {
                assembly {
                    revert(add(bridgeResult, 32), mload(bridgeResult))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sequentially executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each dataItem to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeIds a list of route identifiers
     * @param dataItems a list of functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoutes(
        uint32[] calldata routeIds,
        bytes[] calldata dataItems
    ) external payable {
        uint256 routeIdslength = routeIds.length;
        if (routeIdslength != dataItems.length) revert ArrayLengthMismatch();
        for (uint256 index = 0; index < routeIdslength; ) {
            (bool success, bytes memory result) = addressAt(routeIds[index])
                .delegatecall(dataItems[index]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice execute a controller function identified using the controllerId in the request
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param socketControllerRequest socketControllerRequest with controllerId to identify the
     *                                   controllerAddress and byteData constructed using functionSelector
     *                                   of the function being invoked
     * @return bytes data received from the call delegated to controller
     */
    function executeController(
        ISocketGateway.SocketControllerRequest calldata socketControllerRequest
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = controllers[
            socketControllerRequest.controllerId
        ].delegatecall(socketControllerRequest.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice sequentially executes all controller requests
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each controller-request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param controllerRequests a list of socketControllerRequest
     *                              Each controllerRequest contains controllerId to identify the controllerAddress and
     *                              byteData constructed using functionSelector of the function being invoked
     */
    function executeControllers(
        ISocketGateway.SocketControllerRequest[] calldata controllerRequests
    ) external payable {
        for (uint32 index = 0; index < controllerRequests.length; ) {
            (bool success, bytes memory result) = controllers[
                controllerRequests[index].controllerId
            ].delegatecall(controllerRequests[index].data);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(
        address routeAddress
    ) external onlyOwner returns (uint32) {
        uint32 routeId = routesCount;
        routes[routeId] = routeAddress;

        routesCount += 1;

        emit NewRouteAdded(routeId, routeAddress);

        return routeId;
    }

    /**
     * @notice Give Infinite or 0 approval to bridgeRoute for the tokenAddress
               This is a restricted function to be called by only socketGatewayOwner
     */

    function setApprovalForRouters(
        address[] memory routeAddresses,
        address[] memory tokenAddresses,
        bool isMax
    ) external onlyOwner {
        for (uint32 index = 0; index < routeAddresses.length; ) {
            ERC20(tokenAddresses[index]).approve(
                routeAddresses[index],
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address controllerAddress
    ) external onlyOwner returns (uint32) {
        uint32 controllerId = controllerCount;

        controllers[controllerId] = controllerAddress;

        controllerCount += 1;

        emit ControllerAdded(controllerId, controllerAddress);

        return controllerId;
    }

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 controllerId) public onlyOwner {
        controllers[controllerId] = disabledRouteAddress;
        emit ControllerDisabled(controllerId);
    }

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external onlyOwner {
        routes[routeId] = disabledRouteAddress;
        emit RouteDisabled(routeId);
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTIONS    *
     *******************************************/

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) public view returns (address) {
        return addressAt(routeId);
    }

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 controllerId) public view returns (address) {
        return controllers[controllerId];
    }

    function addressAt(uint32 routeId) public view returns (address) {
        if (routeId < 385) {
            if (routeId < 257) {
                if (routeId < 129) {
                    if (routeId < 65) {
                        if (routeId < 33) {
                            if (routeId < 17) {
                                if (routeId < 9) {
                                    if (routeId < 5) {
                                        if (routeId < 3) {
                                            if (routeId == 1) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 3) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 7) {
                                            if (routeId == 5) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 7) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 13) {
                                        if (routeId < 11) {
                                            if (routeId == 9) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 11) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 15) {
                                            if (routeId == 13) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 15) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 25) {
                                    if (routeId < 21) {
                                        if (routeId < 19) {
                                            if (routeId == 17) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 19) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 23) {
                                            if (routeId == 21) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 23) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 29) {
                                        if (routeId < 27) {
                                            if (routeId == 25) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 27) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 31) {
                                            if (routeId == 29) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 31) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 49) {
                                if (routeId < 41) {
                                    if (routeId < 37) {
                                        if (routeId < 35) {
                                            if (routeId == 33) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 35) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 39) {
                                            if (routeId == 37) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 39) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 45) {
                                        if (routeId < 43) {
                                            if (routeId == 41) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 43) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 47) {
                                            if (routeId == 45) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 47) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 57) {
                                    if (routeId < 53) {
                                        if (routeId < 51) {
                                            if (routeId == 49) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 51) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 55) {
                                            if (routeId == 53) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 55) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 61) {
                                        if (routeId < 59) {
                                            if (routeId == 57) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 59) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 63) {
                                            if (routeId == 61) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 63) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 97) {
                            if (routeId < 81) {
                                if (routeId < 73) {
                                    if (routeId < 69) {
                                        if (routeId < 67) {
                                            if (routeId == 65) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 67) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 71) {
                                            if (routeId == 69) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 71) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 77) {
                                        if (routeId < 75) {
                                            if (routeId == 73) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 75) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 79) {
                                            if (routeId == 77) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 79) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 89) {
                                    if (routeId < 85) {
                                        if (routeId < 83) {
                                            if (routeId == 81) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 83) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 87) {
                                            if (routeId == 85) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 87) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 93) {
                                        if (routeId < 91) {
                                            if (routeId == 89) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 91) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 95) {
                                            if (routeId == 93) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 95) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 113) {
                                if (routeId < 105) {
                                    if (routeId < 101) {
                                        if (routeId < 99) {
                                            if (routeId == 97) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 99) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 103) {
                                            if (routeId == 101) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 103) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 109) {
                                        if (routeId < 107) {
                                            if (routeId == 105) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 107) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 111) {
                                            if (routeId == 109) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 111) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 121) {
                                    if (routeId < 117) {
                                        if (routeId < 115) {
                                            if (routeId == 113) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 115) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 119) {
                                            if (routeId == 117) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 119) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 125) {
                                        if (routeId < 123) {
                                            if (routeId == 121) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 123) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 127) {
                                            if (routeId == 125) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 127) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (routeId < 193) {
                        if (routeId < 161) {
                            if (routeId < 145) {
                                if (routeId < 137) {
                                    if (routeId < 133) {
                                        if (routeId < 131) {
                                            if (routeId == 129) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 131) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 135) {
                                            if (routeId == 133) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 135) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 141) {
                                        if (routeId < 139) {
                                            if (routeId == 137) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 139) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 143) {
                                            if (routeId == 141) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 143) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 153) {
                                    if (routeId < 149) {
                                        if (routeId < 147) {
                                            if (routeId == 145) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 147) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 151) {
                                            if (routeId == 149) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 151) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 157) {
                                        if (routeId < 155) {
                                            if (routeId == 153) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 155) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 159) {
                                            if (routeId == 157) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 159) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 177) {
                                if (routeId < 169) {
                                    if (routeId < 165) {
                                        if (routeId < 163) {
                                            if (routeId == 161) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 163) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 167) {
                                            if (routeId == 165) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 167) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 173) {
                                        if (routeId < 171) {
                                            if (routeId == 169) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 171) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 175) {
                                            if (routeId == 173) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 175) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 185) {
                                    if (routeId < 181) {
                                        if (routeId < 179) {
                                            if (routeId == 177) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 179) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 183) {
                                            if (routeId == 181) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 183) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 189) {
                                        if (routeId < 187) {
                                            if (routeId == 185) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 187) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 191) {
                                            if (routeId == 189) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 191) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 225) {
                            if (routeId < 209) {
                                if (routeId < 201) {
                                    if (routeId < 197) {
                                        if (routeId < 195) {
                                            if (routeId == 193) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 195) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 199) {
                                            if (routeId == 197) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 199) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 205) {
                                        if (routeId < 203) {
                                            if (routeId == 201) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 203) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 207) {
                                            if (routeId == 205) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 207) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 217) {
                                    if (routeId < 213) {
                                        if (routeId < 211) {
                                            if (routeId == 209) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 211) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 215) {
                                            if (routeId == 213) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 215) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 221) {
                                        if (routeId < 219) {
                                            if (routeId == 217) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 219) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 223) {
                                            if (routeId == 221) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 223) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 241) {
                                if (routeId < 233) {
                                    if (routeId < 229) {
                                        if (routeId < 227) {
                                            if (routeId == 225) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 227) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 231) {
                                            if (routeId == 229) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 231) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 237) {
                                        if (routeId < 235) {
                                            if (routeId == 233) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 235) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 239) {
                                            if (routeId == 237) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 239) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 249) {
                                    if (routeId < 245) {
                                        if (routeId < 243) {
                                            if (routeId == 241) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 243) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 247) {
                                            if (routeId == 245) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 247) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 253) {
                                        if (routeId < 251) {
                                            if (routeId == 249) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 251) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 255) {
                                            if (routeId == 253) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        } else {
                                            if (routeId == 255) {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            } else {
                                                return
                                                    0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (routeId < 321) {
                    if (routeId < 289) {
                        if (routeId < 273) {
                            if (routeId < 265) {
                                if (routeId < 261) {
                                    if (routeId < 259) {
                                        if (routeId == 257) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 259) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 263) {
                                        if (routeId == 261) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 263) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 269) {
                                    if (routeId < 267) {
                                        if (routeId == 265) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 267) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 271) {
                                        if (routeId == 269) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 271) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 281) {
                                if (routeId < 277) {
                                    if (routeId < 275) {
                                        if (routeId == 273) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 275) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 279) {
                                        if (routeId == 277) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 279) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 285) {
                                    if (routeId < 283) {
                                        if (routeId == 281) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 283) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 287) {
                                        if (routeId == 285) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 287) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 305) {
                            if (routeId < 297) {
                                if (routeId < 293) {
                                    if (routeId < 291) {
                                        if (routeId == 289) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 291) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 295) {
                                        if (routeId == 293) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 295) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 301) {
                                    if (routeId < 299) {
                                        if (routeId == 297) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 299) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 303) {
                                        if (routeId == 301) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 303) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 313) {
                                if (routeId < 309) {
                                    if (routeId < 307) {
                                        if (routeId == 305) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 307) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 311) {
                                        if (routeId == 309) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 311) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 317) {
                                    if (routeId < 315) {
                                        if (routeId == 313) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 315) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 319) {
                                        if (routeId == 317) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 319) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (routeId < 353) {
                        if (routeId < 337) {
                            if (routeId < 329) {
                                if (routeId < 325) {
                                    if (routeId < 323) {
                                        if (routeId == 321) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 323) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 327) {
                                        if (routeId == 325) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 327) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 333) {
                                    if (routeId < 331) {
                                        if (routeId == 329) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 331) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 335) {
                                        if (routeId == 333) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 335) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 345) {
                                if (routeId < 341) {
                                    if (routeId < 339) {
                                        if (routeId == 337) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 339) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 343) {
                                        if (routeId == 341) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 343) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 349) {
                                    if (routeId < 347) {
                                        if (routeId == 345) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 347) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 351) {
                                        if (routeId == 349) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 351) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 369) {
                            if (routeId < 361) {
                                if (routeId < 357) {
                                    if (routeId < 355) {
                                        if (routeId == 353) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 355) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 359) {
                                        if (routeId == 357) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 359) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 365) {
                                    if (routeId < 363) {
                                        if (routeId == 361) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 363) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 367) {
                                        if (routeId == 365) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 367) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 377) {
                                if (routeId < 373) {
                                    if (routeId < 371) {
                                        if (routeId == 369) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 371) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 375) {
                                        if (routeId == 373) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 375) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 381) {
                                    if (routeId < 379) {
                                        if (routeId == 377) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 379) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                } else {
                                    if (routeId < 383) {
                                        if (routeId == 381) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    } else {
                                        if (routeId == 383) {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        } else {
                                            return
                                                0x822D4B4e63499a576Ab1cc152B86D1CFFf794F4f;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (routes[routeId] == address(0)) revert ZeroAddressNotAllowed();
        return routes[routeId];
    }

    /// @notice fallback function to handle swap, bridge execution
    /// @dev ensure routeId is converted to bytes4 and sent as msg.sig in the transaction
    fallback() external payable {
        address routeAddress = addressAt(uint32(msg.sig));

        bytes memory result;

        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 4, sub(calldatasize(), 4))
            // execute function call using the facet
            result := delegatecall(
                gas(),
                routeAddress,
                0,
                sub(calldatasize(), 4),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import "./utils/Ownable.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {LibUtil} from "./libraries/LibUtil.sol";
import "./libraries/LibBytes.sol";
import {ISocketRoute} from "./interfaces/ISocketRoute.sol";
import {ISocketRequest} from "./interfaces/ISocketRequest.sol";
import {ISocketGateway} from "./interfaces/ISocketGateway.sol";
import {IncorrectBridgeRatios, ZeroAddressNotAllowed, ArrayLengthMismatch} from "./errors/SocketErrors.sol";

/// @title SocketGatewayContract
/// @notice Socketgateway is a contract with entrypoint functions for all interactions with socket liquidity layer
/// @author Socket Team
contract SocketGateway is Ownable {
    using LibBytes for bytes;
    using LibBytes for bytes4;
    using SafeTransferLib for ERC20;

    /// @notice FunctionSelector used to delegatecall from swap to the function of bridge router implementation
    bytes4 public immutable BRIDGE_AFTER_SWAP_SELECTOR =
        bytes4(keccak256("bridgeAfterSwap(uint256,bytes)"));

    /// @notice storage variable to keep track of total number of routes registered in socketgateway
    uint32 public routesCount = 385;

    /// @notice storage variable to keep track of total number of controllers registered in socketgateway
    uint32 public controllerCount;

    address public immutable disabledRouteAddress;

    uint256 public constant CENT_PERCENT = 100e18;

    /// @notice storage mapping for route implementation addresses
    mapping(uint32 => address) public routes;

    /// storage mapping for controller implemenation addresses
    mapping(uint32 => address) public controllers;

    // Events ------------------------------------------------------------------------------------------------------->

    /// @notice Event emitted when a router is added to socketgateway
    event NewRouteAdded(uint32 indexed routeId, address indexed route);

    /// @notice Event emitted when a route is disabled
    event RouteDisabled(uint32 indexed routeId);

    /// @notice Event emitted when ownership transfer is requested by socket-gateway-owner
    event OwnershipTransferRequested(
        address indexed _from,
        address indexed _to
    );

    /// @notice Event emitted when a controller is added to socketgateway
    event ControllerAdded(
        uint32 indexed controllerId,
        address indexed controllerAddress
    );

    /// @notice Event emitted when a controller is disabled
    event ControllerDisabled(uint32 indexed controllerId);

    constructor(address _owner, address _disabledRoute) Ownable(_owner) {
        disabledRouteAddress = _disabledRoute;
    }

    // Able to receive ether
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /*******************************************
     *          EXTERNAL AND PUBLIC FUNCTIONS  *
     *******************************************/

    /**
     * @notice executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in routeData to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeId route identifier
     * @param routeData functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoute(
        uint32 routeId,
        bytes calldata routeData
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = addressAt(routeId).delegatecall(
            routeData
        );

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice swaps a token on sourceChain and split it across multiple bridge-recipients
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being swapped
     * @dev ensure the swap-data and bridge-data is generated using the function-selector defined as a constant in the implementation address
     * @param swapMultiBridgeRequest request
     */
    function swapAndMultiBridge(
        ISocketRequest.SwapMultiBridgeRequest calldata swapMultiBridgeRequest
    ) external payable {
        uint256 requestLength = swapMultiBridgeRequest.bridgeRouteIds.length;

        if (
            requestLength != swapMultiBridgeRequest.bridgeImplDataItems.length
        ) {
            revert ArrayLengthMismatch();
        }
        uint256 ratioAggregate;
        for (uint256 index = 0; index < requestLength; ) {
            ratioAggregate += swapMultiBridgeRequest.bridgeRatios[index];
        }

        if (ratioAggregate != CENT_PERCENT) {
            revert IncorrectBridgeRatios();
        }

        (bool swapSuccess, bytes memory swapResult) = addressAt(
            swapMultiBridgeRequest.swapRouteId
        ).delegatecall(swapMultiBridgeRequest.swapImplData);

        if (!swapSuccess) {
            assembly {
                revert(add(swapResult, 32), mload(swapResult))
            }
        }

        uint256 amountReceivedFromSwap = abi.decode(swapResult, (uint256));

        uint256 bridgedAmount;

        for (uint256 index = 0; index < requestLength; ) {
            uint256 bridgingAmount;

            // if it is the last bridge request, bridge the remaining amount
            if (index == requestLength - 1) {
                bridgingAmount = amountReceivedFromSwap - bridgedAmount;
            } else {
                // bridging amount is the multiplication of bridgeRatio and amountReceivedFromSwap
                bridgingAmount =
                    (amountReceivedFromSwap *
                        swapMultiBridgeRequest.bridgeRatios[index]) /
                    (CENT_PERCENT);
            }

            // update the bridged amount, this would be used for computation for last bridgeRequest
            bridgedAmount += bridgingAmount;

            bytes memory bridgeImpldata = abi.encodeWithSelector(
                BRIDGE_AFTER_SWAP_SELECTOR,
                bridgingAmount,
                swapMultiBridgeRequest.bridgeImplDataItems[index]
            );

            (bool bridgeSuccess, bytes memory bridgeResult) = addressAt(
                swapMultiBridgeRequest.bridgeRouteIds[index]
            ).delegatecall(bridgeImpldata);

            if (!bridgeSuccess) {
                assembly {
                    revert(add(bridgeResult, 32), mload(bridgeResult))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice sequentially executes functions in the routes identified using routeId and functionSelectorData
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each dataItem to be built using the function-selector defined as a
     *         constant in the route implementation contract
     * @param routeIds a list of route identifiers
     * @param dataItems a list of functionSelectorData generated using the function-selector defined in the route Implementation
     */
    function executeRoutes(
        uint32[] calldata routeIds,
        bytes[] calldata dataItems
    ) external payable {
        uint256 routeIdslength = routeIds.length;
        if (routeIdslength != dataItems.length) revert ArrayLengthMismatch();
        for (uint256 index = 0; index < routeIdslength; ) {
            (bool success, bytes memory result) = addressAt(routeIds[index])
                .delegatecall(dataItems[index]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice execute a controller function identified using the controllerId in the request
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param socketControllerRequest socketControllerRequest with controllerId to identify the
     *                                   controllerAddress and byteData constructed using functionSelector
     *                                   of the function being invoked
     * @return bytes data received from the call delegated to controller
     */
    function executeController(
        ISocketGateway.SocketControllerRequest calldata socketControllerRequest
    ) external payable returns (bytes memory) {
        (bool success, bytes memory result) = controllers[
            socketControllerRequest.controllerId
        ].delegatecall(socketControllerRequest.data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        return result;
    }

    /**
     * @notice sequentially executes all controller requests
     * @notice The caller must first approve this contract to spend amount of ERC20-Token being bridged/swapped
     * @dev ensure the data in each controller-request to be built using the function-selector defined as a
     *         constant in the controller implementation contract
     * @param controllerRequests a list of socketControllerRequest
     *                              Each controllerRequest contains controllerId to identify the controllerAddress and
     *                              byteData constructed using functionSelector of the function being invoked
     */
    function executeControllers(
        ISocketGateway.SocketControllerRequest[] calldata controllerRequests
    ) external payable {
        for (uint32 index = 0; index < controllerRequests.length; ) {
            (bool success, bytes memory result) = controllers[
                controllerRequests[index].controllerId
            ].delegatecall(controllerRequests[index].data);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            unchecked {
                ++index;
            }
        }
    }

    /**************************************
     *          ADMIN FUNCTIONS           *
     **************************************/

    /**
     * @notice Add route to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure routeAddress is a verified bridge or middleware implementation address
     * @param routeAddress The address of bridge or middleware implementation contract deployed
     * @return Id of the route added to the routes-mapping in socketGateway storage
     */
    function addRoute(
        address routeAddress
    ) external onlyOwner returns (uint32) {
        uint32 routeId = routesCount;
        routes[routeId] = routeAddress;

        routesCount += 1;

        emit NewRouteAdded(routeId, routeAddress);

        return routeId;
    }

    /**
     * @notice Give Infinite or 0 approval to bridgeRoute for the tokenAddress
               This is a restricted function to be called by only socketGatewayOwner
     */

    function setApprovalForRouters(
        address[] memory routeAddresses,
        address[] memory tokenAddresses,
        bool isMax
    ) external onlyOwner {
        for (uint32 index = 0; index < routeAddresses.length; ) {
            ERC20(tokenAddresses[index]).approve(
                routeAddresses[index],
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }

    /**
     * @notice Add controller to the socketGateway
               This is a restricted function to be called by only socketGatewayOwner
     * @dev ensure controllerAddress is a verified controller implementation address
     * @param controllerAddress The address of controller implementation contract deployed
     * @return Id of the controller added to the controllers-mapping in socketGateway storage
     */
    function addController(
        address controllerAddress
    ) external onlyOwner returns (uint32) {
        uint32 controllerId = controllerCount;

        controllers[controllerId] = controllerAddress;

        controllerCount += 1;

        emit ControllerAdded(controllerId, controllerAddress);

        return controllerId;
    }

    /**
     * @notice disable controller by setting ZeroAddress to the entry in controllers-mapping
               identified by controllerId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param controllerId The Id of controller-implementation in the controllers mapping
     */
    function disableController(uint32 controllerId) public onlyOwner {
        controllers[controllerId] = disabledRouteAddress;
        emit ControllerDisabled(controllerId);
    }

    /**
     * @notice disable a route by setting ZeroAddress to the entry in routes-mapping
               identified by routeId as key.
               This is a restricted function to be called by only socketGatewayOwner
     * @param routeId The Id of route-implementation in the routes mapping
     */
    function disableRoute(uint32 routeId) external onlyOwner {
        routes[routeId] = disabledRouteAddress;
        emit RouteDisabled(routeId);
    }

    /*******************************************
     *          RESTRICTED RESCUE FUNCTIONS    *
     *******************************************/

    /**
     * @notice Rescues the ERC20 token to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param token address of the ERC20 token being rescued
     * @param userAddress address to which ERC20 is to be rescued
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external onlyOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice Rescues the native balance to an address
               this is a restricted function to be called by only socketGatewayOwner
     * @dev as this is a restricted to socketGatewayOwner, ensure the userAddress is a known address
     * @param userAddress address to which native-balance is to be rescued
     * @param amount amount of native-balance being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external onlyOwner {
        userAddress.transfer(amount);
    }

    /*******************************************
     *          VIEW FUNCTIONS                  *
     *******************************************/

    /**
     * @notice Get routeImplementation address mapped to the routeId
     * @param routeId routeId is the key in the mapping for routes
     * @return route-implementation address
     */
    function getRoute(uint32 routeId) public view returns (address) {
        return addressAt(routeId);
    }

    /**
     * @notice Get controllerImplementation address mapped to the controllerId
     * @param controllerId controllerId is the key in the mapping for controllers
     * @return controller-implementation address
     */
    function getController(uint32 controllerId) public view returns (address) {
        return controllers[controllerId];
    }

    function addressAt(uint32 routeId) public view returns (address) {
        if (routeId < 385) {
            if (routeId < 257) {
                if (routeId < 129) {
                    if (routeId < 65) {
                        if (routeId < 33) {
                            if (routeId < 17) {
                                if (routeId < 9) {
                                    if (routeId < 5) {
                                        if (routeId < 3) {
                                            if (routeId == 1) {
                                                return
                                                    0x8cd6BaCDAe46B449E2e5B34e348A4eD459c84D50;
                                            } else {
                                                return
                                                    0x31524750Cd865fF6A3540f232754Fb974c18585C;
                                            }
                                        } else {
                                            if (routeId == 3) {
                                                return
                                                    0xEd9b37342BeC8f3a2D7b000732ec87498aA6EC6a;
                                            } else {
                                                return
                                                    0xE8704Ef6211F8988Ccbb11badC89841808d66890;
                                            }
                                        }
                                    } else {
                                        if (routeId < 7) {
                                            if (routeId == 5) {
                                                return
                                                    0x9aFF58C460a461578C433e11C4108D1c4cF77761;
                                            } else {
                                                return
                                                    0x2D1733886cFd465B0B99F1492F40847495f334C5;
                                            }
                                        } else {
                                            if (routeId == 7) {
                                                return
                                                    0x715497Be4D130F04B8442F0A1F7a9312D4e54FC4;
                                            } else {
                                                return
                                                    0x90C8a40c38E633B5B0e0d0585b9F7FA05462CaaF;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 13) {
                                        if (routeId < 11) {
                                            if (routeId == 9) {
                                                return
                                                    0xa402b70FCfF3F4a8422B93Ef58E895021eAdE4F6;
                                            } else {
                                                return
                                                    0xc1B718522E15CD42C4Ac385a929fc2B51f5B892e;
                                            }
                                        } else {
                                            if (routeId == 11) {
                                                return
                                                    0xa97bf2f7c26C43c010c349F52f5eA5dC49B2DD38;
                                            } else {
                                                return
                                                    0x969423d71b62C81d2f28d707364c9Dc4a0764c53;
                                            }
                                        }
                                    } else {
                                        if (routeId < 15) {
                                            if (routeId == 13) {
                                                return
                                                    0xF86729934C083fbEc8C796068A1fC60701Ea1207;
                                            } else {
                                                return
                                                    0xD7cC2571F5823caCA26A42690D2BE7803DD5393f;
                                            }
                                        } else {
                                            if (routeId == 15) {
                                                return
                                                    0x7c8837a279bbbf7d8B93413763176de9F65d5bB9;
                                            } else {
                                                return
                                                    0x13b81C27B588C07D04458ed7dDbdbD26D1e39bcc;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 25) {
                                    if (routeId < 21) {
                                        if (routeId < 19) {
                                            if (routeId == 17) {
                                                return
                                                    0x52560Ac678aFA1345D15474287d16Dc1eA3F78aE;
                                            } else {
                                                return
                                                    0x1E31e376551459667cd7643440c1b21CE69065A0;
                                            }
                                        } else {
                                            if (routeId == 19) {
                                                return
                                                    0xc57D822CB3288e7b97EF8f8af0EcdcD1B783529B;
                                            } else {
                                                return
                                                    0x2197A1D9Af24b4d6a64Bff95B4c29Fcd3Ff28C30;
                                            }
                                        }
                                    } else {
                                        if (routeId < 23) {
                                            if (routeId == 21) {
                                                return
                                                    0xE3700feAa5100041Bf6b7AdBA1f72f647809Fd00;
                                            } else {
                                                return
                                                    0xc02E8a0Fdabf0EeFCEA025163d90B5621E2b9948;
                                            }
                                        } else {
                                            if (routeId == 23) {
                                                return
                                                    0xF5144235E2926cAb3c69b30113254Fa632f72d62;
                                            } else {
                                                return
                                                    0xBa3F92313B00A1f7Bc53b2c24EB195c8b2F57682;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 29) {
                                        if (routeId < 27) {
                                            if (routeId == 25) {
                                                return
                                                    0x77a6856fe1fFA5bEB55A1d2ED86E27C7c482CB76;
                                            } else {
                                                return
                                                    0x4826Ff4e01E44b1FCEFBfb38cd96687Eb7786b44;
                                            }
                                        } else {
                                            if (routeId == 27) {
                                                return
                                                    0x55FF3f5493cf5e80E76DEA7E327b9Cd8440Af646;
                                            } else {
                                                return
                                                    0xF430Db544bE9770503BE4aa51997aA19bBd5BA4f;
                                            }
                                        }
                                    } else {
                                        if (routeId < 31) {
                                            if (routeId == 29) {
                                                return
                                                    0x0f166446ce1484EE3B0663E7E67DF10F5D240115;
                                            } else {
                                                return
                                                    0x6365095D92537f242Db5EdFDd572745E72aC33d9;
                                            }
                                        } else {
                                            if (routeId == 31) {
                                                return
                                                    0x5c7BC93f06ce3eAe75ADf55E10e23d2c1dE5Bc65;
                                            } else {
                                                return
                                                    0xe46383bAD90d7A08197ccF08972e9DCdccCE9BA4;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 49) {
                                if (routeId < 41) {
                                    if (routeId < 37) {
                                        if (routeId < 35) {
                                            if (routeId == 33) {
                                                return
                                                    0xf0f21710c071E3B728bdc4654c3c0b873aAaa308;
                                            } else {
                                                return
                                                    0x63Bc9ed3AcAAeB0332531C9fB03b0a2352E9Ff25;
                                            }
                                        } else {
                                            if (routeId == 35) {
                                                return
                                                    0xd1CE808625CB4007a1708824AE82CdB0ece57De9;
                                            } else {
                                                return
                                                    0x57BbB148112f4ba224841c3FE018884171004661;
                                            }
                                        }
                                    } else {
                                        if (routeId < 39) {
                                            if (routeId == 37) {
                                                return
                                                    0x037f7d6933036F34DFabd40Ff8e4D789069f92e3;
                                            } else {
                                                return
                                                    0xeF978c280915CfF3Dca4EDfa8932469e40ADA1e1;
                                            }
                                        } else {
                                            if (routeId == 39) {
                                                return
                                                    0x92ee9e071B13f7ecFD62B7DED404A16CBc223CD3;
                                            } else {
                                                return
                                                    0x94Ae539c186e41ed762271338Edf140414D1E442;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 45) {
                                        if (routeId < 43) {
                                            if (routeId == 41) {
                                                return
                                                    0x30A64BBe4DdBD43dA2368EFd1eB2d80C10d84DAb;
                                            } else {
                                                return
                                                    0x3aEABf81c1Dc4c1b73d5B2a95410f126426FB596;
                                            }
                                        } else {
                                            if (routeId == 43) {
                                                return
                                                    0x25b08aB3D0C8ea4cC9d967b79688C6D98f3f563a;
                                            } else {
                                                return
                                                    0xea40cB15C9A3BBd27af6474483886F7c0c9AE406;
                                            }
                                        }
                                    } else {
                                        if (routeId < 47) {
                                            if (routeId == 45) {
                                                return
                                                    0x9580113Cc04e5a0a03359686304EF3A80b936Dd3;
                                            } else {
                                                return
                                                    0xD211c826d568957F3b66a3F4d9c5f68cCc66E619;
                                            }
                                        } else {
                                            if (routeId == 47) {
                                                return
                                                    0xCEE24D0635c4C56315d133b031984d4A6f509476;
                                            } else {
                                                return
                                                    0x3922e6B987983229798e7A20095EC372744d4D4c;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 57) {
                                    if (routeId < 53) {
                                        if (routeId < 51) {
                                            if (routeId == 49) {
                                                return
                                                    0x2d92D03413d296e1F31450479349757187F2a2b7;
                                            } else {
                                                return
                                                    0x0fe5308eE90FC78F45c89dB6053eA859097860CA;
                                            }
                                        } else {
                                            if (routeId == 51) {
                                                return
                                                    0x08Ba68e067C0505bAF0C1311E0cFB2B1B59b969c;
                                            } else {
                                                return
                                                    0x9bee5DdDF75C24897374f92A534B7A6f24e97f4a;
                                            }
                                        }
                                    } else {
                                        if (routeId < 55) {
                                            if (routeId == 53) {
                                                return
                                                    0x1FC5A90B232208704B930c1edf82FFC6ACc02734;
                                            } else {
                                                return
                                                    0x5b1B0417cb44c761C2a23ee435d011F0214b3C85;
                                            }
                                        } else {
                                            if (routeId == 55) {
                                                return
                                                    0x9d70cDaCA12A738C283020760f449D7816D592ec;
                                            } else {
                                                return
                                                    0x95a23b9CB830EcCFDDD5dF56A4ec665e3381Fa12;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 61) {
                                        if (routeId < 59) {
                                            if (routeId == 57) {
                                                return
                                                    0x483a957Cf1251c20e096C35c8399721D1200A3Fc;
                                            } else {
                                                return
                                                    0xb4AD39Cb293b0Ec7FEDa743442769A7FF04987CD;
                                            }
                                        } else {
                                            if (routeId == 59) {
                                                return
                                                    0x4C543AD78c1590D81BAe09Fc5B6Df4132A2461d0;
                                            } else {
                                                return
                                                    0x471d5E5195c563902781734cfe1FF3981F8B6c86;
                                            }
                                        }
                                    } else {
                                        if (routeId < 63) {
                                            if (routeId == 61) {
                                                return
                                                    0x1B12a54B5E606D95B8B8D123c9Cb09221Ee37584;
                                            } else {
                                                return
                                                    0xE4127cC550baC433646a7D998775a84daC16c7f3;
                                            }
                                        } else {
                                            if (routeId == 63) {
                                                return
                                                    0xecb1b55AB12E7dd788D585c6C5cD61B5F87be836;
                                            } else {
                                                return
                                                    0xf91ef487C5A1579f70601b6D347e19756092eEBf;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 97) {
                            if (routeId < 81) {
                                if (routeId < 73) {
                                    if (routeId < 69) {
                                        if (routeId < 67) {
                                            if (routeId == 65) {
                                                return
                                                    0x34a16a7e9BADEEFD4f056310cbE0b1423Fa1b760;
                                            } else {
                                                return
                                                    0x60E10E80c7680f429dBbC232830BEcd3D623c4CF;
                                            }
                                        } else {
                                            if (routeId == 67) {
                                                return
                                                    0x66465285B8D65362A1d86CE00fE2bE949Fd6debF;
                                            } else {
                                                return
                                                    0x5aB231B7e1A3A74a48f67Ab7bde5Cdd4267022E0;
                                            }
                                        }
                                    } else {
                                        if (routeId < 71) {
                                            if (routeId == 69) {
                                                return
                                                    0x3A1C3633eE79d43366F5c67802a746aFD6b162Ba;
                                            } else {
                                                return
                                                    0x0C4BfCbA8dC3C811437521a80E81e41DAF479039;
                                            }
                                        } else {
                                            if (routeId == 71) {
                                                return
                                                    0x6caf25d2e139C5431a1FA526EAf8d73ff2e6252C;
                                            } else {
                                                return
                                                    0x74ad21e09FDa68638CE14A3009A79B6D16574257;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 77) {
                                        if (routeId < 75) {
                                            if (routeId == 73) {
                                                return
                                                    0xD4923A61008894b99cc1CD3407eF9524f02aA0Ca;
                                            } else {
                                                return
                                                    0x6F159b5EB823BD415886b9271aA2A723a00a1987;
                                            }
                                        } else {
                                            if (routeId == 75) {
                                                return
                                                    0x742a8aA42E7bfB4554dE30f4Fb07FFb6f2068863;
                                            } else {
                                                return
                                                    0x4AE9702d3360400E47B446e76DE063ACAb930101;
                                            }
                                        }
                                    } else {
                                        if (routeId < 79) {
                                            if (routeId == 77) {
                                                return
                                                    0x0E19a0a44ddA7dAD854ec5Cc867d16869c4E80F4;
                                            } else {
                                                return
                                                    0xE021A51968f25148F726E326C88d2556c5647557;
                                            }
                                        } else {
                                            if (routeId == 79) {
                                                return
                                                    0x64287BDDDaeF4d94E4599a3D882bed29E6Ada4B6;
                                            } else {
                                                return
                                                    0xcBB57Fd2e19cc7e9D444d5b4325A2F1047d0C73f;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 89) {
                                    if (routeId < 85) {
                                        if (routeId < 83) {
                                            if (routeId == 81) {
                                                return
                                                    0x373DE80DF7D82cFF6D76F29581b360C56331e957;
                                            } else {
                                                return
                                                    0x0466356E131AD61596a51F86BAd1C03A328960D8;
                                            }
                                        } else {
                                            if (routeId == 83) {
                                                return
                                                    0x01726B960992f1b74311b248E2a922fC707d43A6;
                                            } else {
                                                return
                                                    0x2E21bdf9A4509b89795BCE7E132f248a75814CEc;
                                            }
                                        }
                                    } else {
                                        if (routeId < 87) {
                                            if (routeId == 85) {
                                                return
                                                    0x769512b23aEfF842379091d3B6E4B5456F631D42;
                                            } else {
                                                return
                                                    0xe7eD9be946a74Ec19325D39C6EEb57887ccB2B0D;
                                            }
                                        } else {
                                            if (routeId == 87) {
                                                return
                                                    0xc4D01Ec357c2b511d10c15e6b6974380F0E62e67;
                                            } else {
                                                return
                                                    0x5bC49CC9dD77bECF2fd3A3C55611e84E69AFa3AE;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 93) {
                                        if (routeId < 91) {
                                            if (routeId == 89) {
                                                return
                                                    0x48bcD879954fA14e7DbdAeb56F79C1e9DDcb69ec;
                                            } else {
                                                return
                                                    0xE929bDde21b462572FcAA4de6F49B9D3246688D0;
                                            }
                                        } else {
                                            if (routeId == 91) {
                                                return
                                                    0x85Aae300438222f0e3A9Bc870267a5633A9438bd;
                                            } else {
                                                return
                                                    0x51f72E1096a81C55cd142d66d39B688C657f9Be8;
                                            }
                                        }
                                    } else {
                                        if (routeId < 95) {
                                            if (routeId == 93) {
                                                return
                                                    0x3A8a05BF68ac54B01E6C0f492abF97465F3d15f9;
                                            } else {
                                                return
                                                    0x145aA67133F0c2C36b9771e92e0B7655f0D59040;
                                            }
                                        } else {
                                            if (routeId == 95) {
                                                return
                                                    0xa030315d7DB11F9892758C9e7092D841e0ADC618;
                                            } else {
                                                return
                                                    0xdF1f8d81a3734bdDdEfaC6Ca1596E081e57c3044;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 113) {
                                if (routeId < 105) {
                                    if (routeId < 101) {
                                        if (routeId < 99) {
                                            if (routeId == 97) {
                                                return
                                                    0xFF2833123B58aa05d04D7fb99f5FB768B2b435F8;
                                            } else {
                                                return
                                                    0xc8f09c1fD751C570233765f71b0e280d74e6e743;
                                            }
                                        } else {
                                            if (routeId == 99) {
                                                return
                                                    0x3026DA6Ceca2E5A57A05153653D9212FFAaA49d8;
                                            } else {
                                                return
                                                    0xdE68Ee703dE0D11f67B0cE5891cB4a903de6D160;
                                            }
                                        }
                                    } else {
                                        if (routeId < 103) {
                                            if (routeId == 101) {
                                                return
                                                    0xE23a7730e81FB4E87A6D0bd9f63EE77ac86C3DA4;
                                            } else {
                                                return
                                                    0x8b1DBe04aD76a7d8bC079cACd3ED4D99B897F4a0;
                                            }
                                        } else {
                                            if (routeId == 103) {
                                                return
                                                    0xBB227240FA459b69C6889B2b8cb1BE76F118061f;
                                            } else {
                                                return
                                                    0xC062b9b3f0dB28BB8afAfcD4d075729344114ffe;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 109) {
                                        if (routeId < 107) {
                                            if (routeId == 105) {
                                                return
                                                    0x553188Aa45f5FDB83EC4Ca485982F8fC082480D1;
                                            } else {
                                                return
                                                    0x0109d83D746EaCb6d4014953D9E12d6ca85e330b;
                                            }
                                        } else {
                                            if (routeId == 107) {
                                                return
                                                    0x45B1bEd29812F5bf6711074ACD180B2aeB783AD9;
                                            } else {
                                                return
                                                    0xdA06eC8c19aea31D77F60299678Cba40E743e1aD;
                                            }
                                        }
                                    } else {
                                        if (routeId < 111) {
                                            if (routeId == 109) {
                                                return
                                                    0x3cC5235c97d975a9b4FD4501B3446c981ea3D855;
                                            } else {
                                                return
                                                    0xa1827267d6Bd989Ff38580aE3d9deff6Acf19163;
                                            }
                                        } else {
                                            if (routeId == 111) {
                                                return
                                                    0x3663CAA0433A3D4171b3581Cf2410702840A735A;
                                            } else {
                                                return
                                                    0x7575D0a7614F655BA77C74a72a43bbd4fA6246a3;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 121) {
                                    if (routeId < 117) {
                                        if (routeId < 115) {
                                            if (routeId == 113) {
                                                return
                                                    0x2516Defc18bc07089c5dAFf5eafD7B0EF64611E2;
                                            } else {
                                                return
                                                    0xfec5FF08E20fbc107a97Af2D38BD0025b84ee233;
                                            }
                                        } else {
                                            if (routeId == 115) {
                                                return
                                                    0x0FB5763a87242B25243e23D73f55945fE787523A;
                                            } else {
                                                return
                                                    0xe4C00db89678dBf8391f430C578Ca857Dd98aDE1;
                                            }
                                        }
                                    } else {
                                        if (routeId < 119) {
                                            if (routeId == 117) {
                                                return
                                                    0x8F2A22061F9F35E64f14523dC1A5f8159e6a21B7;
                                            } else {
                                                return
                                                    0x18e4b838ae966917E20E9c9c5Ad359cDD38303bB;
                                            }
                                        } else {
                                            if (routeId == 119) {
                                                return
                                                    0x61ACb1d3Dcb3e3429832A164Cc0fC9849fb75A4a;
                                            } else {
                                                return
                                                    0x7681e3c8e7A41DCA55C257cc0d1Ae757f5530E65;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 125) {
                                        if (routeId < 123) {
                                            if (routeId == 121) {
                                                return
                                                    0x806a2AB9748C3D1DB976550890E3f528B7E8Faec;
                                            } else {
                                                return
                                                    0xBDb8A5DD52C2c239fbC31E9d43B763B0197028FF;
                                            }
                                        } else {
                                            if (routeId == 123) {
                                                return
                                                    0x474EC9203706010B9978D6bD0b105D36755e4848;
                                            } else {
                                                return
                                                    0x8dfd0D829b303F2239212E591a0F92a32880f36E;
                                            }
                                        }
                                    } else {
                                        if (routeId < 127) {
                                            if (routeId == 125) {
                                                return
                                                    0xad4BcE9745860B1adD6F1Bd34a916f050E4c82C2;
                                            } else {
                                                return
                                                    0xBC701115b9fe14bC8CC5934cdC92517173e308C4;
                                            }
                                        } else {
                                            if (routeId == 127) {
                                                return
                                                    0x0D1918d786Db8546a11aDeD475C98370E06f255E;
                                            } else {
                                                return
                                                    0xee44f57cD6936DB55B99163f3Df367B01EdA785a;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (routeId < 193) {
                        if (routeId < 161) {
                            if (routeId < 145) {
                                if (routeId < 137) {
                                    if (routeId < 133) {
                                        if (routeId < 131) {
                                            if (routeId == 129) {
                                                return
                                                    0x63044521fe5a1e488D7eD419cD0e35b7C24F2aa7;
                                            } else {
                                                return
                                                    0x410085E73BD85e90d97b84A68C125aDB9F91f85b;
                                            }
                                        } else {
                                            if (routeId == 131) {
                                                return
                                                    0x7913fe97E07C7A397Ec274Ab1d4E2622C88EC5D1;
                                            } else {
                                                return
                                                    0x977f9fE93c064DCf54157406DaABC3a722e8184C;
                                            }
                                        }
                                    } else {
                                        if (routeId < 135) {
                                            if (routeId == 133) {
                                                return
                                                    0xCD2236468722057cFbbABad2db3DEA9c20d5B01B;
                                            } else {
                                                return
                                                    0x17c7287A491cf5Ff81E2678cF2BfAE4333F6108c;
                                            }
                                        } else {
                                            if (routeId == 135) {
                                                return
                                                    0x354D9a5Dbf96c71B79a265F03B595C6Fdc04dadd;
                                            } else {
                                                return
                                                    0xb4e409EB8e775eeFEb0344f9eee884cc7ed21c69;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 141) {
                                        if (routeId < 139) {
                                            if (routeId == 137) {
                                                return
                                                    0xa1a3c4670Ad69D9be4ab2D39D1231FEC2a63b519;
                                            } else {
                                                return
                                                    0x4589A22199870729C1be5CD62EE93BeD858113E6;
                                            }
                                        } else {
                                            if (routeId == 139) {
                                                return
                                                    0x8E7b864dB26Bd6C798C38d4Ba36EbA0d6602cF11;
                                            } else {
                                                return
                                                    0xA2D17C7260a4CB7b9854e89Fc367E80E87872a2d;
                                            }
                                        }
                                    } else {
                                        if (routeId < 143) {
                                            if (routeId == 141) {
                                                return
                                                    0xC7F0EDf0A1288627b0432304918A75e9084CBD46;
                                            } else {
                                                return
                                                    0xE4B4EF1f9A4aBFEdB371fA7a6143993B15d4df25;
                                            }
                                        } else {
                                            if (routeId == 143) {
                                                return
                                                    0xfe3D84A2Ef306FEBb5452441C9BDBb6521666F6A;
                                            } else {
                                                return
                                                    0x8A12B6C64121920110aE58F7cd67DfEc21c6a4C3;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 153) {
                                    if (routeId < 149) {
                                        if (routeId < 147) {
                                            if (routeId == 145) {
                                                return
                                                    0x76c4d9aFC4717a2BAac4e5f26CccF02351f7a3DA;
                                            } else {
                                                return
                                                    0xd4719BA550E397aeAcca1Ad2201c1ba69024FAAf;
                                            }
                                        } else {
                                            if (routeId == 147) {
                                                return
                                                    0x9646126Ce025224d1682C227d915a386efc0A1Fb;
                                            } else {
                                                return
                                                    0x4DD8Af2E3F2044842f0247920Bc4BABb636915ea;
                                            }
                                        }
                                    } else {
                                        if (routeId < 151) {
                                            if (routeId == 149) {
                                                return
                                                    0x8e8a327183Af0cf8C2ece9F0ed547C42A160D409;
                                            } else {
                                                return
                                                    0x9D49614CaE1C685C71678CA6d8CDF7584bfd0740;
                                            }
                                        } else {
                                            if (routeId == 151) {
                                                return
                                                    0x5a00ef257394cbc31828d48655E3d39e9c11c93d;
                                            } else {
                                                return
                                                    0xC9a2751b38d3dDD161A41Ca0135C5C6c09EC1d56;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 157) {
                                        if (routeId < 155) {
                                            if (routeId == 153) {
                                                return
                                                    0x7e1c261640a525C94Ca4f8c25b48CF754DD83590;
                                            } else {
                                                return
                                                    0x409Fe24ba6F6BD5aF31C1aAf8059b986A3158233;
                                            }
                                        } else {
                                            if (routeId == 155) {
                                                return
                                                    0x704Cf5BFDADc0f55fDBb53B6ed8B582E018A72A2;
                                            } else {
                                                return
                                                    0x3982bF65d7d6E77E3b6661cd6F6468c247512737;
                                            }
                                        }
                                    } else {
                                        if (routeId < 159) {
                                            if (routeId == 157) {
                                                return
                                                    0x3982b9f26FFD67a13Ee371e2C0a9Da338BA70E7f;
                                            } else {
                                                return
                                                    0x6D834AB385900c1f49055D098e90264077FbC4f2;
                                            }
                                        } else {
                                            if (routeId == 159) {
                                                return
                                                    0x11FE5F70779A094B7166B391e1Fb73d422eF4e4d;
                                            } else {
                                                return
                                                    0xD347e4E47280d21F13B73D89c6d16f867D50DD13;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 177) {
                                if (routeId < 169) {
                                    if (routeId < 165) {
                                        if (routeId < 163) {
                                            if (routeId == 161) {
                                                return
                                                    0xb6035eDD53DDA28d8B69b4ae9836E40C80306CD7;
                                            } else {
                                                return
                                                    0x54c884e6f5C7CcfeCA990396c520C858c922b6CA;
                                            }
                                        } else {
                                            if (routeId == 163) {
                                                return
                                                    0x5eA93E240b083d686558Ed607BC013d88057cE46;
                                            } else {
                                                return
                                                    0x4C7131eE812De685cBe4e2cCb033d46ecD46612E;
                                            }
                                        }
                                    } else {
                                        if (routeId < 167) {
                                            if (routeId == 165) {
                                                return
                                                    0xc1a5Be9F0c33D8483801D702111068669f81fF91;
                                            } else {
                                                return
                                                    0x9E5fAb91455Be5E5b2C05967E73F456c8118B1Fc;
                                            }
                                        } else {
                                            if (routeId == 167) {
                                                return
                                                    0x3d9A05927223E0DC2F382831770405885e22F0d8;
                                            } else {
                                                return
                                                    0x6303A011fB6063f5B1681cb5a9938EA278dc6128;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 173) {
                                        if (routeId < 171) {
                                            if (routeId == 169) {
                                                return
                                                    0xe9c60795c90C66797e4c8E97511eA07CdAda32bE;
                                            } else {
                                                return
                                                    0xD56cC98e69A1e13815818b466a8aA6163d84234A;
                                            }
                                        } else {
                                            if (routeId == 171) {
                                                return
                                                    0x47EbB9D36a6e40895316cD894E4860D774E2c531;
                                            } else {
                                                return
                                                    0xA5EB293629410065d14a7B1663A67829b0618292;
                                            }
                                        }
                                    } else {
                                        if (routeId < 175) {
                                            if (routeId == 173) {
                                                return
                                                    0x1b3B4C8146F939cE00899db8B3ddeF0062b7E023;
                                            } else {
                                                return
                                                    0x257Bbc11653625EbfB6A8587eF4f4FBe49828EB3;
                                            }
                                        } else {
                                            if (routeId == 175) {
                                                return
                                                    0x44cc979C01b5bB1eAC21301E73C37200dFD06F59;
                                            } else {
                                                return
                                                    0x2972fDF43352225D82754C0174Ff853819D1ef2A;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 185) {
                                    if (routeId < 181) {
                                        if (routeId < 179) {
                                            if (routeId == 177) {
                                                return
                                                    0x3e54144f032648A04D62d79f7B4b93FF3aC2333b;
                                            } else {
                                                return
                                                    0x444016102dB8adbE73C3B6703a1ea7F2f75A510D;
                                            }
                                        } else {
                                            if (routeId == 179) {
                                                return
                                                    0xac079143f98a6eb744Fde34541ebF243DF5B5dED;
                                            } else {
                                                return
                                                    0xAe9010767Fb112d29d35CEdfba2b372Ad7A308d3;
                                            }
                                        }
                                    } else {
                                        if (routeId < 183) {
                                            if (routeId == 181) {
                                                return
                                                    0xfE0BCcF9cCC2265D5fB3450743f17DfE57aE1e56;
                                            } else {
                                                return
                                                    0x04ED8C0545716119437a45386B1d691C63234C7D;
                                            }
                                        } else {
                                            if (routeId == 183) {
                                                return
                                                    0x636c14013e531A286Bc4C848da34585f0bB73d59;
                                            } else {
                                                return
                                                    0x2Fa67fc7ECC5cAA01C653d3BFeA98ecc5db9C42A;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 189) {
                                        if (routeId < 187) {
                                            if (routeId == 185) {
                                                return
                                                    0x23e9a0FC180818aA872D2079a985217017E97bd9;
                                            } else {
                                                return
                                                    0x79A95c3Ef81b3ae64ee03A9D5f73e570495F164E;
                                            }
                                        } else {
                                            if (routeId == 187) {
                                                return
                                                    0xa7EA0E88F04a84ba0ad1E396cb07Fa3fDAD7dF6D;
                                            } else {
                                                return
                                                    0xd23cA1278a2B01a3C0Ca1a00d104b11c1Ebe6f42;
                                            }
                                        }
                                    } else {
                                        if (routeId < 191) {
                                            if (routeId == 189) {
                                                return
                                                    0x707bc4a9FA2E349AED5df4e9f5440C15aA9D14Bd;
                                            } else {
                                                return
                                                    0x7E290F2dd539Ac6CE58d8B4C2B944931a1fD3612;
                                            }
                                        } else {
                                            if (routeId == 191) {
                                                return
                                                    0x707AA5503088Ce06Ba450B6470A506122eA5c8eF;
                                            } else {
                                                return
                                                    0xFbB3f7BF680deeb149f4E7BC30eA3DDfa68F3C3f;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 225) {
                            if (routeId < 209) {
                                if (routeId < 201) {
                                    if (routeId < 197) {
                                        if (routeId < 195) {
                                            if (routeId == 193) {
                                                return
                                                    0xDE74aD8cCC3dbF14992f49Cf24f36855912f4934;
                                            } else {
                                                return
                                                    0x409BA83df7777F070b2B50a10a41DE2468d2a3B3;
                                            }
                                        } else {
                                            if (routeId == 195) {
                                                return
                                                    0x5CB7Be90A5DD7CfDa54e87626e254FE8C18255B4;
                                            } else {
                                                return
                                                    0x0A684fE12BC64fb72B59d0771a566F49BC090356;
                                            }
                                        }
                                    } else {
                                        if (routeId < 199) {
                                            if (routeId == 197) {
                                                return
                                                    0xDf30048d91F8FA2bCfC54952B92bFA8e161D3360;
                                            } else {
                                                return
                                                    0x050825Fff032a547C47061CF0696FDB0f65AEa5D;
                                            }
                                        } else {
                                            if (routeId == 199) {
                                                return
                                                    0xd55e671dAC1f03d366d8535073ada5DB2Aab1Ea2;
                                            } else {
                                                return
                                                    0x9470C704A9616c8Cd41c595Fcd2181B6fe2183C2;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 205) {
                                        if (routeId < 203) {
                                            if (routeId == 201) {
                                                return
                                                    0x2D9ffD275181F5865d5e11CbB4ced1521C4dF9f1;
                                            } else {
                                                return
                                                    0x816d28Dec10ec95DF5334f884dE85cA6215918d8;
                                            }
                                        } else {
                                            if (routeId == 203) {
                                                return
                                                    0xd1f87267c4A43835E666dd69Df077e578A3b6299;
                                            } else {
                                                return
                                                    0x39E89Bde9DACbe5468C025dE371FbDa12bDeBAB1;
                                            }
                                        }
                                    } else {
                                        if (routeId < 207) {
                                            if (routeId == 205) {
                                                return
                                                    0x7b40A3207956ecad6686E61EfcaC48912FcD0658;
                                            } else {
                                                return
                                                    0x090cF10D793B1Efba9c7D76115878814B663859A;
                                            }
                                        } else {
                                            if (routeId == 207) {
                                                return
                                                    0x312A59c06E41327878F2063eD0e9c282C1DA3AfC;
                                            } else {
                                                return
                                                    0x4F1188f46236DD6B5de11Ebf2a9fF08716E7DeB6;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 217) {
                                    if (routeId < 213) {
                                        if (routeId < 211) {
                                            if (routeId == 209) {
                                                return
                                                    0x0A6F9a3f4fA49909bBfb4339cbE12B42F53BbBeD;
                                            } else {
                                                return
                                                    0x01d13d7aCaCbB955B81935c80ffF31e14BdFa71f;
                                            }
                                        } else {
                                            if (routeId == 211) {
                                                return
                                                    0x691a14Fa6C7360422EC56dF5876f84d4eDD7f00A;
                                            } else {
                                                return
                                                    0x97Aad18d886d181a9c726B3B6aE15a0A69F5aF73;
                                            }
                                        }
                                    } else {
                                        if (routeId < 215) {
                                            if (routeId == 213) {
                                                return
                                                    0x2917241371D2099049Fa29432DC46735baEC33b4;
                                            } else {
                                                return
                                                    0x5F20F20F7890c2e383E29D4147C9695A371165f5;
                                            }
                                        } else {
                                            if (routeId == 215) {
                                                return
                                                    0xeC0a60e639958335662C5219A320cCEbb56C6077;
                                            } else {
                                                return
                                                    0x96d63CF5062975C09845d17ec672E10255866053;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 221) {
                                        if (routeId < 219) {
                                            if (routeId == 217) {
                                                return
                                                    0xFF57429e57D383939CAB50f09ABBfB63C0e6c9AD;
                                            } else {
                                                return
                                                    0x18E393A7c8578fb1e235C242076E50013cDdD0d7;
                                            }
                                        } else {
                                            if (routeId == 219) {
                                                return
                                                    0xE7E5238AF5d61f52E9B4ACC025F713d1C0216507;
                                            } else {
                                                return
                                                    0x428401D4d0F25A2EE1DA4d5366cB96Ded425D9bD;
                                            }
                                        }
                                    } else {
                                        if (routeId < 223) {
                                            if (routeId == 221) {
                                                return
                                                    0x42E5733551ff1Ee5B48Aa9fc2B61Af9b58C812E6;
                                            } else {
                                                return
                                                    0x64Df9c7A0551B056d860Bc2419Ca4c1EF75320bE;
                                            }
                                        } else {
                                            if (routeId == 223) {
                                                return
                                                    0x46006925506145611bBf0263243D8627dAf26B0F;
                                            } else {
                                                return
                                                    0x8D64BE884314662804eAaB884531f5C50F4d500c;
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 241) {
                                if (routeId < 233) {
                                    if (routeId < 229) {
                                        if (routeId < 227) {
                                            if (routeId == 225) {
                                                return
                                                    0x157a62D92D07B5ce221A5429645a03bBaCE85373;
                                            } else {
                                                return
                                                    0xaF037D33e1F1F2F87309B425fe8a9d895Ef3722B;
                                            }
                                        } else {
                                            if (routeId == 227) {
                                                return
                                                    0x921D1154E494A2f7218a37ad7B17701f94b4B40e;
                                            } else {
                                                return
                                                    0xF282b4555186d8Dea51B8b3F947E1E0568d09bc4;
                                            }
                                        }
                                    } else {
                                        if (routeId < 231) {
                                            if (routeId == 229) {
                                                return
                                                    0xa794E2E1869765a4600b3DFd8a4ebcF16350f6B6;
                                            } else {
                                                return
                                                    0xFEFb048e20c5652F7940A49B1980E0125Ec4D358;
                                            }
                                        } else {
                                            if (routeId == 231) {
                                                return
                                                    0x220104b641971e9b25612a8F001bf48AbB23f1cF;
                                            } else {
                                                return
                                                    0xcB9D373Bb54A501B35dd3be5bF4Ba43cA31F7035;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 237) {
                                        if (routeId < 235) {
                                            if (routeId == 233) {
                                                return
                                                    0x37D627F56e3FF36aC316372109ea82E03ac97DAc;
                                            } else {
                                                return
                                                    0x4E81355FfB4A271B4EA59ff78da2b61c7833161f;
                                            }
                                        } else {
                                            if (routeId == 235) {
                                                return
                                                    0xADd8D65cAF6Cc9ad73127B49E16eA7ac29d91e87;
                                            } else {
                                                return
                                                    0x630F9b95626487dfEAe3C97A44DB6C59cF35d996;
                                            }
                                        }
                                    } else {
                                        if (routeId < 239) {
                                            if (routeId == 237) {
                                                return
                                                    0x78CE2BC8238B679680A67FCB98C5A60E4ec17b2D;
                                            } else {
                                                return
                                                    0xA38D776028eD1310b9A6b086f67F788201762E21;
                                            }
                                        } else {
                                            if (routeId == 239) {
                                                return
                                                    0x7Bb5178827B76B86753Ed62a0d662c72cEcb1bD3;
                                            } else {
                                                return
                                                    0x4faC26f61C76eC5c3D43b43eDfAFF0736Ae0e3da;
                                            }
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 249) {
                                    if (routeId < 245) {
                                        if (routeId < 243) {
                                            if (routeId == 241) {
                                                return
                                                    0x791Bb49bfFA7129D6889FDB27744422Ac4571A85;
                                            } else {
                                                return
                                                    0x26766fFEbb5fa564777913A6f101dF019AB32afa;
                                            }
                                        } else {
                                            if (routeId == 243) {
                                                return
                                                    0x05e98E5e95b4ECBbbAf3258c3999Cc81ed8048Be;
                                            } else {
                                                return
                                                    0xC5c4621e52f1D6A1825A5ed4F95855401a3D9C6b;
                                            }
                                        }
                                    } else {
                                        if (routeId < 247) {
                                            if (routeId == 245) {
                                                return
                                                    0xfcb15f909BA7FC7Ea083503Fb4c1020203c107EB;
                                            } else {
                                                return
                                                    0xbD27603279d969c74f2486ad14E71080829DFd38;
                                            }
                                        } else {
                                            if (routeId == 247) {
                                                return
                                                    0xff2f756BcEcC1A55BFc09a30cc5F64720458cFCB;
                                            } else {
                                                return
                                                    0x3bfB968FEbC12F4e8420B2d016EfcE1E615f7246;
                                            }
                                        }
                                    }
                                } else {
                                    if (routeId < 253) {
                                        if (routeId < 251) {
                                            if (routeId == 249) {
                                                return
                                                    0x982EE9Ffe23051A2ec945ed676D864fa8345222b;
                                            } else {
                                                return
                                                    0xe101899100785E74767d454FFF0131277BaD48d9;
                                            }
                                        } else {
                                            if (routeId == 251) {
                                                return
                                                    0x4F730C0c6b3B5B7d06ca511379f4Aa5BfB2E9525;
                                            } else {
                                                return
                                                    0x5499c36b365795e4e0Ef671aF6C2ce26D7c78265;
                                            }
                                        }
                                    } else {
                                        if (routeId < 255) {
                                            if (routeId == 253) {
                                                return
                                                    0x8AF51F7237Fc8fB2fc3E700488a94a0aC6Ad8b5a;
                                            } else {
                                                return
                                                    0xda8716df61213c0b143F2849785FB85928084857;
                                            }
                                        } else {
                                            if (routeId == 255) {
                                                return
                                                    0xF040Cf9b1ebD11Bf28e04e80740DF3DDe717e4f5;
                                            } else {
                                                return
                                                    0xB87ba32f759D14023C7520366B844dF7f0F036C2;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                if (routeId < 321) {
                    if (routeId < 289) {
                        if (routeId < 273) {
                            if (routeId < 265) {
                                if (routeId < 261) {
                                    if (routeId < 259) {
                                        if (routeId == 257) {
                                            return
                                                0x0Edde681b8478F0c3194f468EdD2dB5e75c65CDD;
                                        } else {
                                            return
                                                0x59C70900Fca06eE2aCE1BDd5A8D0Af0cc3BBA720;
                                        }
                                    } else {
                                        if (routeId == 259) {
                                            return
                                                0x8041F0f180D17dD07087199632c45E17AeB0BAd5;
                                        } else {
                                            return
                                                0x4fB4727064BA595995DD516b63b5921Df9B93aC6;
                                        }
                                    }
                                } else {
                                    if (routeId < 263) {
                                        if (routeId == 261) {
                                            return
                                                0x86e98b594565857eD098864F560915C0dAfd6Ea1;
                                        } else {
                                            return
                                                0x70f8818E8B698EFfeCd86A513a4c87c0c380Bef6;
                                        }
                                    } else {
                                        if (routeId == 263) {
                                            return
                                                0x78Ed227c8A897A21Da2875a752142dd80d865158;
                                        } else {
                                            return
                                                0xd02A30BB5C3a8C51d2751A029a6fcfDE2Af9fbc6;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 269) {
                                    if (routeId < 267) {
                                        if (routeId == 265) {
                                            return
                                                0x0F00d5c5acb24e975e2a56730609f7F40aa763b8;
                                        } else {
                                            return
                                                0xC3e2091edc2D3D9D98ba09269138b617B536834A;
                                        }
                                    } else {
                                        if (routeId == 267) {
                                            return
                                                0xa6FbaF7F30867C9633908998ea8C3da28920E75C;
                                        } else {
                                            return
                                                0xE6dDdcD41E2bBe8122AE32Ac29B8fbAB79CD21d9;
                                        }
                                    }
                                } else {
                                    if (routeId < 271) {
                                        if (routeId == 269) {
                                            return
                                                0x537aa8c1Ef6a8Eaf039dd6e1Eb67694a48195cE4;
                                        } else {
                                            return
                                                0x96ABAC485fd2D0B03CF4a10df8BD58b8dED28300;
                                        }
                                    } else {
                                        if (routeId == 271) {
                                            return
                                                0xda8e7D46d04Bd4F62705Cd80355BDB6d441DafFD;
                                        } else {
                                            return
                                                0xbE50018E7a5c67E2e5f5414393e971CC96F293f2;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 281) {
                                if (routeId < 277) {
                                    if (routeId < 275) {
                                        if (routeId == 273) {
                                            return
                                                0xa1b3907D6CB542a4cbe2eE441EfFAA909FAb62C3;
                                        } else {
                                            return
                                                0x6d08ee8511C0237a515013aC389e7B3968Cb1753;
                                        }
                                    } else {
                                        if (routeId == 275) {
                                            return
                                                0x22faa5B5Fe43eAdbB52745e35a5cdA8bD5F96bbA;
                                        } else {
                                            return
                                                0x7a673eB74D79e4868D689E7852abB5f93Ec2fD4b;
                                        }
                                    }
                                } else {
                                    if (routeId < 279) {
                                        if (routeId == 277) {
                                            return
                                                0x0b8531F8AFD4190b76F3e10deCaDb84c98b4d419;
                                        } else {
                                            return
                                                0x78eABC743A93583DeE403D6b84795490e652216B;
                                        }
                                    } else {
                                        if (routeId == 279) {
                                            return
                                                0x3A95D907b2a7a8604B59BccA08585F58Afe0Aa64;
                                        } else {
                                            return
                                                0xf4271f0C8c9Af0F06A80b8832fa820ccE64FAda8;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 285) {
                                    if (routeId < 283) {
                                        if (routeId == 281) {
                                            return
                                                0x74b2DF841245C3748c0d31542e1335659a25C33b;
                                        } else {
                                            return
                                                0xdFC99Fd0Ad7D16f30f295a5EEFcE029E04d0fa65;
                                        }
                                    } else {
                                        if (routeId == 283) {
                                            return
                                                0xE992416b6aC1144eD8148a9632973257839027F6;
                                        } else {
                                            return
                                                0x54ce55ba954E981BB1fd9399054B35Ce1f2C0816;
                                        }
                                    }
                                } else {
                                    if (routeId < 287) {
                                        if (routeId == 285) {
                                            return
                                                0xD4AB52f9e7E5B315Bd7471920baD04F405Ab1c38;
                                        } else {
                                            return
                                                0x3670C990994d12837e95eE127fE2f06FD3E2104B;
                                        }
                                    } else {
                                        if (routeId == 287) {
                                            return
                                                0xDcf190B09C47E4f551E30BBb79969c3FdEA1e992;
                                        } else {
                                            return
                                                0xa65057B967B59677237e57Ab815B209744b9bc40;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 305) {
                            if (routeId < 297) {
                                if (routeId < 293) {
                                    if (routeId < 291) {
                                        if (routeId == 289) {
                                            return
                                                0x6Efc86B40573e4C7F28659B13327D55ae955C483;
                                        } else {
                                            return
                                                0x06BcC25CF8e0E72316F53631b3aA7134E9f73Ae0;
                                        }
                                    } else {
                                        if (routeId == 291) {
                                            return
                                                0x710b6414E1D53882b1FCD3A168aD5Ccd435fc6D0;
                                        } else {
                                            return
                                                0x5Ebb2C3d78c4e9818074559e7BaE7FCc99781DC1;
                                        }
                                    }
                                } else {
                                    if (routeId < 295) {
                                        if (routeId == 293) {
                                            return
                                                0xAf0a409c3AEe0bD08015cfb29D89E90b6e89A88F;
                                        } else {
                                            return
                                                0x522559d8b99773C693B80cE06DF559036295Ce44;
                                        }
                                    } else {
                                        if (routeId == 295) {
                                            return
                                                0xB65290A5Bae838aaa7825c9ECEC68041841a1B64;
                                        } else {
                                            return
                                                0x801b8F2068edd5Bcb659E6BDa0c425909043C420;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 301) {
                                    if (routeId < 299) {
                                        if (routeId == 297) {
                                            return
                                                0x29b5F00515d093627E0B7bd0b5c8E84F6b4cDb87;
                                        } else {
                                            return
                                                0x652839Ae74683cbF9f1293F1019D938F87464D3E;
                                        }
                                    } else {
                                        if (routeId == 299) {
                                            return
                                                0x5Bc95dCebDDE9B79F2b6DC76121BC7936eF8D666;
                                        } else {
                                            return
                                                0x90db359CEA62E53051158Ab5F99811C0a07Fe686;
                                        }
                                    }
                                } else {
                                    if (routeId < 303) {
                                        if (routeId == 301) {
                                            return
                                                0x2c3625EedadbDcDbB5330eb0d17b3C39ff269807;
                                        } else {
                                            return
                                                0xC3f0324471b5c9d415acD625b8d8694a4e48e001;
                                        }
                                    } else {
                                        if (routeId == 303) {
                                            return
                                                0x8C60e7E05fa0FfB6F720233736f245134685799d;
                                        } else {
                                            return
                                                0x98fAF2c09aa4EBb995ad0B56152993E7291a500e;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 313) {
                                if (routeId < 309) {
                                    if (routeId < 307) {
                                        if (routeId == 305) {
                                            return
                                                0x802c1063a861414dFAEc16bacb81429FC0d40D6e;
                                        } else {
                                            return
                                                0x11C4AeFCC0dC156f64195f6513CB1Fb3Be0Ae056;
                                        }
                                    } else {
                                        if (routeId == 307) {
                                            return
                                                0xEff1F3258214E31B6B4F640b4389d55715C3Be2B;
                                        } else {
                                            return
                                                0x47e379Abe8DDFEA4289aBa01235EFF7E93758fd7;
                                        }
                                    }
                                } else {
                                    if (routeId < 311) {
                                        if (routeId == 309) {
                                            return
                                                0x3CC26384c3eA31dDc8D9789e8872CeA6F20cD3ff;
                                        } else {
                                            return
                                                0xEdd9EFa6c69108FAA4611097d643E20Ba0Ed1634;
                                        }
                                    } else {
                                        if (routeId == 311) {
                                            return
                                                0xCb93525CA5f3D371F74F3D112bC19526740717B8;
                                        } else {
                                            return
                                                0x7071E0124EB4438137e60dF1b8DD8Af1BfB362cF;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 317) {
                                    if (routeId < 315) {
                                        if (routeId == 313) {
                                            return
                                                0x4691096EB0b78C8F4b4A8091E5B66b18e1835c10;
                                        } else {
                                            return
                                                0x8d953c9b2d1C2137CF95992079f3A77fCd793272;
                                        }
                                    } else {
                                        if (routeId == 315) {
                                            return
                                                0xbdCc2A3Bf6e3Ba49ff86595e6b2b8D70d8368c92;
                                        } else {
                                            return
                                                0x95E6948aB38c61b2D294E8Bd896BCc4cCC0713cf;
                                        }
                                    }
                                } else {
                                    if (routeId < 319) {
                                        if (routeId == 317) {
                                            return
                                                0x607b27C881fFEE4Cb95B1c5862FaE7224ccd0b4A;
                                        } else {
                                            return
                                                0x09D28aFA166e566A2Ee1cB834ea8e78C7E627eD2;
                                        }
                                    } else {
                                        if (routeId == 319) {
                                            return
                                                0x9c01449b38bDF0B263818401044Fb1401B29fDfA;
                                        } else {
                                            return
                                                0x1F7723599bbB658c051F8A39bE2688388d22ceD6;
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    if (routeId < 353) {
                        if (routeId < 337) {
                            if (routeId < 329) {
                                if (routeId < 325) {
                                    if (routeId < 323) {
                                        if (routeId == 321) {
                                            return
                                                0x52B71603f7b8A5d15B4482e965a0619aa3210194;
                                        } else {
                                            return
                                                0x01c0f072CB210406653752FecFA70B42dA9173a2;
                                        }
                                    } else {
                                        if (routeId == 323) {
                                            return
                                                0x3021142f021E943e57fc1886cAF58D06147D09A6;
                                        } else {
                                            return
                                                0xe6f2AF38e76AB09Db59225d97d3E770942D3D842;
                                        }
                                    }
                                } else {
                                    if (routeId < 327) {
                                        if (routeId == 325) {
                                            return
                                                0x06a25554e5135F08b9e2eD1DEC1fc3CEd52e0B48;
                                        } else {
                                            return
                                                0x71d75e670EE3511C8290C705E0620126B710BF8D;
                                        }
                                    } else {
                                        if (routeId == 327) {
                                            return
                                                0x8b9cE142b80FeA7c932952EC533694b1DF9B3c54;
                                        } else {
                                            return
                                                0xd7Be24f32f39231116B3fDc483C2A12E1521f73B;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 333) {
                                    if (routeId < 331) {
                                        if (routeId == 329) {
                                            return
                                                0xb40cafBC4797d4Ff64087E087F6D2e661f954CbE;
                                        } else {
                                            return
                                                0xBdDCe7771EfEe81893e838f62204A4c76D72757e;
                                        }
                                    } else {
                                        if (routeId == 331) {
                                            return
                                                0x5d3D299EA7Fd4F39AcDb336E26631Dfee41F9287;
                                        } else {
                                            return
                                                0x6BfEE09E1Fc0684e0826A9A0dC1352a14B136FAC;
                                        }
                                    }
                                } else {
                                    if (routeId < 335) {
                                        if (routeId == 333) {
                                            return
                                                0xd0001bB8E2Cb661436093f96458a4358B5156E3c;
                                        } else {
                                            return
                                                0x1867c6485CfD1eD448988368A22bfB17a7747293;
                                        }
                                    } else {
                                        if (routeId == 335) {
                                            return
                                                0x8997EF9F95dF24aB67703AB6C262aABfeEBE33bD;
                                        } else {
                                            return
                                                0x1e39E9E601922deD91BCFc8F78836302133465e2;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 345) {
                                if (routeId < 341) {
                                    if (routeId < 339) {
                                        if (routeId == 337) {
                                            return
                                                0x8A8ec6CeacFf502a782216774E5AF3421562C6ff;
                                        } else {
                                            return
                                                0x3B8FC561df5415c8DC01e97Ee6E38435A8F9C40A;
                                        }
                                    } else {
                                        if (routeId == 339) {
                                            return
                                                0xD5d5f5B37E67c43ceA663aEDADFFc3a93a2065B0;
                                        } else {
                                            return
                                                0xCC8F55EC43B4f25013CE1946FBB740c43Be5B96D;
                                        }
                                    }
                                } else {
                                    if (routeId < 343) {
                                        if (routeId == 341) {
                                            return
                                                0x18f586E816eEeDbb57B8011239150367561B58Fb;
                                        } else {
                                            return
                                                0xd0CD802B19c1a52501cb2f07d656e3Cd7B0Ce124;
                                        }
                                    } else {
                                        if (routeId == 343) {
                                            return
                                                0xe0AeD899b39C6e4f2d83e4913a1e9e0cf6368abE;
                                        } else {
                                            return
                                                0x0606e1b6c0f1A398C38825DCcc4678a7Cbc2737c;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 349) {
                                    if (routeId < 347) {
                                        if (routeId == 345) {
                                            return
                                                0x2d188e85b27d18EF80f16686EA1593ABF7Ed2A63;
                                        } else {
                                            return
                                                0x64412292fA4A135a3300E24366E99ff59Db2eAc1;
                                        }
                                    } else {
                                        if (routeId == 347) {
                                            return
                                                0x38b74c173f3733E8b90aAEf0e98B89791266149F;
                                        } else {
                                            return
                                                0x36DAA49A79aaEF4E7a217A11530D3cCD84414124;
                                        }
                                    }
                                } else {
                                    if (routeId < 351) {
                                        if (routeId == 349) {
                                            return
                                                0x10f088FE2C88F90270E4449c46c8B1b232511d58;
                                        } else {
                                            return
                                                0x4FeDbd25B58586838ABD17D10272697dF1dC3087;
                                        }
                                    } else {
                                        if (routeId == 351) {
                                            return
                                                0x685278209248CB058E5cEe93e37f274A80Faf6eb;
                                        } else {
                                            return
                                                0xDd9F8F1eeC3955f78168e2Fb2d1e808fa8A8f15b;
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        if (routeId < 369) {
                            if (routeId < 361) {
                                if (routeId < 357) {
                                    if (routeId < 355) {
                                        if (routeId == 353) {
                                            return
                                                0x7392aEeFD5825aaC28817031dEEBbFaAA20983D9;
                                        } else {
                                            return
                                                0x0Cc182555E00767D6FB8AD161A10d0C04C476d91;
                                        }
                                    } else {
                                        if (routeId == 355) {
                                            return
                                                0x90E52837d56715c79FD592E8D58bFD20365798b2;
                                        } else {
                                            return
                                                0x6F4451DE14049B6770ad5BF4013118529e68A40C;
                                        }
                                    }
                                } else {
                                    if (routeId < 359) {
                                        if (routeId == 357) {
                                            return
                                                0x89B97ef2aFAb9ed9c7f0FDb095d02E6840b52d9c;
                                        } else {
                                            return
                                                0x92A5cC5C42d94d3e23aeB1214fFf43Db2B97759E;
                                        }
                                    } else {
                                        if (routeId == 359) {
                                            return
                                                0x63ddc52F135A1dcBA831EAaC11C63849F018b739;
                                        } else {
                                            return
                                                0x692A691533B571C2c54C1D7F8043A204b3d8120E;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 365) {
                                    if (routeId < 363) {
                                        if (routeId == 361) {
                                            return
                                                0x97c7492CF083969F61C6f302d45c8270391b921c;
                                        } else {
                                            return
                                                0xDeFD2B8643553dAd19548eB14fd94A57F4B9e543;
                                        }
                                    } else {
                                        if (routeId == 363) {
                                            return
                                                0x30645C04205cA3f670B67b02F971B088930ACB8C;
                                        } else {
                                            return
                                                0xA6f80ed2d607Cd67aEB4109B64A0BEcc4D7d03CF;
                                        }
                                    }
                                } else {
                                    if (routeId < 367) {
                                        if (routeId == 365) {
                                            return
                                                0xBbbbC6c276eB3F7E674f2D39301509236001c42f;
                                        } else {
                                            return
                                                0xC20E77d349FB40CE88eB01824e2873ad9f681f3C;
                                        }
                                    } else {
                                        if (routeId == 367) {
                                            return
                                                0x5fCfD9a962De19294467C358C1FA55082285960b;
                                        } else {
                                            return
                                                0x4D87BD6a0E4E5cc6332923cb3E85fC71b287F58A;
                                        }
                                    }
                                }
                            }
                        } else {
                            if (routeId < 377) {
                                if (routeId < 373) {
                                    if (routeId < 371) {
                                        if (routeId == 369) {
                                            return
                                                0x3AA5B757cd6Dde98214E56D57Dde7fcF0F7aB04E;
                                        } else {
                                            return
                                                0xe28eFCE7192e11a2297f44059113C1fD6967b2d4;
                                        }
                                    } else {
                                        if (routeId == 371) {
                                            return
                                                0x3251cAE10a1Cf246e0808D76ACC26F7B5edA0eE5;
                                        } else {
                                            return
                                                0xbA2091cc9357Cf4c4F25D64F30d1b4Ba3A5a174B;
                                        }
                                    }
                                } else {
                                    if (routeId < 375) {
                                        if (routeId == 373) {
                                            return
                                                0x49c8e1Da9693692096F63C82D11b52d738566d55;
                                        } else {
                                            return
                                                0xA0731615aB5FFF451031E9551367A4F7dB27b39c;
                                        }
                                    } else {
                                        if (routeId == 375) {
                                            return
                                                0xFb214541888671AE1403CecC1D59763a12fc1609;
                                        } else {
                                            return
                                                0x1D6bCB17642E2336405df73dF22F07688cAec020;
                                        }
                                    }
                                }
                            } else {
                                if (routeId < 381) {
                                    if (routeId < 379) {
                                        if (routeId == 377) {
                                            return
                                                0xfC9c0C7bfe187120fF7f4E21446161794A617a9e;
                                        } else {
                                            return
                                                0xBa5bF37678EeE2dAB17AEf9D898153258252250E;
                                        }
                                    } else {
                                        if (routeId == 379) {
                                            return
                                                0x7c55690bd2C9961576A32c02f8EB29ed36415Ec7;
                                        } else {
                                            return
                                                0xcA40073E868E8Bc611aEc8Fe741D17E68Fe422f6;
                                        }
                                    }
                                } else {
                                    if (routeId < 383) {
                                        if (routeId == 381) {
                                            return
                                                0x31641bAFb87E9A58f78835050a7BE56921986339;
                                        } else {
                                            return
                                                0xA54766424f6dA74b45EbCc5Bf0Bd1D74D2CCcaAB;
                                        }
                                    } else {
                                        if (routeId == 383) {
                                            return
                                                0xc7bBa57F8C179EDDBaa62117ddA360e28f3F8252;
                                        } else {
                                            return
                                                0x5e663ED97ea77d393B8858C90d0683bF180E0ffd;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (routes[routeId] == address(0)) revert ZeroAddressNotAllowed();
        return routes[routeId];
    }

    /// @notice fallback function to handle swap, bridge execution
    /// @dev ensure routeId is converted to bytes4 and sent as msg.sig in the transaction
    fallback() external payable {
        address routeAddress = addressAt(uint32(msg.sig));

        bytes memory result;

        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 4, sub(calldatasize(), 4))
            // execute function call using the facet
            result := delegatecall(
                gas(),
                routeAddress,
                0,
                sub(calldatasize(), 4),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
bytes32 constant ACROSS = keccak256("Across");

bytes32 constant ANYSWAP = keccak256("Anyswap");

bytes32 constant CBRIDGE = keccak256("CBridge");

bytes32 constant HOP = keccak256("Hop");

bytes32 constant HYPHEN = keccak256("Hyphen");

bytes32 constant NATIVE_OPTIMISM = keccak256("NativeOptimism");

bytes32 constant NATIVE_ARBITRUM = keccak256("NativeArbitrum");

bytes32 constant NATIVE_POLYGON = keccak256("NativePolygon");

bytes32 constant REFUEL = keccak256("Refuel");

bytes32 constant STARGATE = keccak256("Stargate");

bytes32 constant ONEINCH = keccak256("OneInch");

bytes32 constant ZEROX = keccak256("Zerox");

bytes32 constant RAINBOW = keccak256("Rainbow");

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {SwapFailed} from "../../errors/SocketErrors.sol";
import {ONEINCH} from "../../static/RouteIdentifiers.sol";

/**
 * @title OneInch-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via OneInch-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of OneInchImplementation
 * @author Socket dot tech.
 */
contract OneInchImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable OneInchIdentifier = ONEINCH;

    /// @notice address of OneInchAggregator to swap the tokens on Chain
    address public immutable ONEINCH_AGGREGATOR;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @dev ensure _oneinchAggregator are set properly for the chainId in which the contract is being deployed
    constructor(
        address _oneinchAggregator,
        address _socketGateway,
        address _socketDeployFactory
    ) SwapImplBase(_socketGateway, _socketDeployFactory) {
        ONEINCH_AGGREGATOR = _oneinchAggregator;
    }

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     *         via OneInch-Middleware-Aggregator
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param receiverAddress address of toToken recipient
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes calldata swapExtraData
    ) external payable override returns (uint256) {
        uint256 returnAmount;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(ONEINCH_AGGREGATOR, amount);
            {
                // additional data is generated in off-chain using the OneInch API which takes in
                // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
                (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call(
                    swapExtraData
                );
                token.safeApprove(ONEINCH_AGGREGATOR, 0);

                if (!success) {
                    revert SwapFailed();
                }

                returnAmount = abi.decode(result, (uint256));
            }
        } else {
            // additional data is generated in off-chain using the OneInch API which takes in
            // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
            (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call{
                value: amount
            }(swapExtraData);
            if (!success) {
                revert SwapFailed();
            }
            returnAmount = abi.decode(result, (uint256));
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            OneInchIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     *         via OneInch-Middleware-Aggregator
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes calldata swapExtraData
    ) external payable override returns (uint256, address) {
        uint256 returnAmount;

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(ONEINCH_AGGREGATOR, amount);
            {
                // additional data is generated in off-chain using the OneInch API which takes in
                // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
                (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call(
                    swapExtraData
                );
                token.safeApprove(ONEINCH_AGGREGATOR, 0);

                if (!success) {
                    revert SwapFailed();
                }

                returnAmount = abi.decode(result, (uint256));
            }
        } else {
            // additional data is generated in off-chain using the OneInch API which takes in
            // fromTokenAddress, toTokenAddress, amount, fromAddress, slippage, destReceiver, disableEstimate
            (bool success, bytes memory result) = ONEINCH_AGGREGATOR.call{
                value: amount
            }(swapExtraData);
            if (!success) {
                revert SwapFailed();
            }
            returnAmount = abi.decode(result, (uint256));
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            OneInchIdentifier,
            socketGateway
        );

        return (returnAmount, toToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {Address0Provided, SwapFailed} from "../../errors/SocketErrors.sol";
import {RAINBOW} from "../../static/RouteIdentifiers.sol";

/**
 * @title Rainbow-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via Rainbow-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of RainbowImplementation
 * @author Socket dot tech.
 */
contract RainbowSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable RainbowIdentifier = RAINBOW;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Rainbow-Router");

    /// @notice address of rainbow-swap-aggregator to swap the tokens on Chain
    address payable public immutable rainbowSwapAggregator;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice rainbow swap aggregator contract is payable to allow ethereum swaps
    /// @dev ensure _rainbowSwapAggregator are set properly for the chainId in which the contract is being deployed
    constructor(
        address _rainbowSwapAggregator,
        address _socketGateway,
        address _socketDeployFactory
    ) SwapImplBase(_socketGateway, _socketDeployFactory) {
        rainbowSwapAggregator = payable(_rainbowSwapAggregator);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @notice This method is payable because the caller is doing token transfer and swap operation
     * @param fromToken address of token being Swapped
     * @param toToken address of token that recipient will receive after swap
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient-address
     * @param swapExtraData additional Data to perform Swap via Rainbow-Aggregator
     * @return swapped amount (in toToken Address)
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes calldata swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 toTokenERC20 = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            toTokenERC20.transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            RainbowIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes calldata swapExtraData
    ) external payable override returns (uint256, address) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 toTokenERC20 = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, socketGateway, amount);
            token.safeApprove(rainbowSwapAggregator, amount);

            // solhint-disable-next-line
            (bool success, ) = rainbowSwapAggregator.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(rainbowSwapAggregator, 0);
        } else {
            (bool success, ) = rainbowSwapAggregator.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = toTokenERC20.balanceOf(socketGateway);
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            RainbowIdentifier,
            socketGateway
        );

        return (returnAmount, toToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ISocketGateway} from "../interfaces/ISocketGateway.sol";
import {OnlySocketGatewayOwner, OnlySocketDeployer} from "../errors/SocketErrors.sol";

/**
 * @title Abstract Implementation Contract.
 * @notice All Swap Implementation will follow this interface.
 * @author Socket dot tech.
 */
abstract contract SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    /// @notice Address used to identify if it is a native token transfer or not
    address public immutable NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketGateway;

    /// @notice immutable variable to store the socketGateway address
    address public immutable socketDeployFactory;

    /// @notice FunctionSelector used to delegatecall to the performAction function of swap-router-implementation
    bytes4 public immutable SWAP_FUNCTION_SELECTOR =
        bytes4(
            keccak256("performAction(address,address,uint256,address,bytes)")
        );

    /// @notice FunctionSelector used to delegatecall to the performActionWithIn function of swap-router-implementation
    bytes4 public immutable SWAP_WITHIN_FUNCTION_SELECTOR =
        bytes4(keccak256("performActionWithIn(address,address,uint256,bytes)"));

    /****************************************
     *               EVENTS                 *
     ****************************************/

    event SocketSwapTokens(
        address fromToken,
        address toToken,
        uint256 buyAmount,
        uint256 sellAmount,
        bytes32 routeName,
        address receiver
    );

    /**
     * @notice Construct the base for all SwapImplementations.
     * @param _socketGateway Socketgateway address, an immutable variable to set.
     */
    constructor(address _socketGateway, address _socketDeployFactory) {
        socketGateway = _socketGateway;
        socketDeployFactory = _socketDeployFactory;
    }

    /****************************************
     *               MODIFIERS              *
     ****************************************/

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketGatewayOwner() {
        if (msg.sender != ISocketGateway(socketGateway).owner()) {
            revert OnlySocketGatewayOwner();
        }
        _;
    }

    /// @notice Implementing contract needs to make use of the modifier where restricted access is to be used
    modifier isSocketDeployFactory() {
        if (msg.sender != socketDeployFactory) {
            revert OnlySocketDeployer();
        }
        _;
    }

    /****************************************
     *    RESTRICTED FUNCTIONS              *
     ****************************************/

    /**
     * @notice function to rescue the ERC20 tokens in the Swap-Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param token address of ERC20 token being rescued
     * @param userAddress receipient address to which ERC20 tokens will be rescued to
     * @param amount amount of ERC20 tokens being rescued
     */
    function rescueFunds(
        address token,
        address userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        ERC20(token).safeTransfer(userAddress, amount);
    }

    /**
     * @notice function to rescue the native-balance in the  Swap-Implementation contract
     * @notice this is a function restricted to Owner of SocketGateway only
     * @param userAddress receipient address to which native-balance will be rescued to
     * @param amount amount of native balance tokens being rescued
     */
    function rescueEther(
        address payable userAddress,
        uint256 amount
    ) external isSocketGatewayOwner {
        userAddress.transfer(amount);
    }

    function killme() external isSocketDeployFactory {
        selfdestruct(payable(msg.sender));
    }

    /******************************
     *    VIRTUAL FUNCTIONS       *
     *****************************/

    /**
     * @notice function to swap tokens on the chain
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param  toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param receiverAddress recipient address of toToken
     * @param data encoded value of properties in the swapData Struct
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes memory data
    ) external payable virtual returns (uint256);

    /**
     * @notice function to swapWith - swaps tokens on the chain to socketGateway as recipient
     *         All swap implementation contracts must implement this function
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes memory swapExtraData
    ) external payable virtual returns (uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../SwapImplBase.sol";
import {Address0Provided, SwapFailed} from "../../errors/SocketErrors.sol";
import {ZEROX} from "../../static/RouteIdentifiers.sol";

/**
 * @title ZeroX-Swap-Route Implementation
 * @notice Route implementation with functions to swap tokens via ZeroX-Swap
 * Called via SocketGateway if the routeId in the request maps to the routeId of ZeroX-Swap-Implementation
 * @author Socket dot tech.
 */
contract ZeroXSwapImpl is SwapImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable ZeroXIdentifier = ZEROX;

    /// @notice unique name to identify the router, used to emit event upon successful bridging
    bytes32 public immutable NAME = keccak256("Zerox-Router");

    /// @notice address of ZeroX-Exchange-Proxy to swap the tokens on Chain
    address payable public immutable zeroXExchangeProxy;

    /// @notice socketGatewayAddress to be initialised via storage variable SwapImplBase
    /// @notice ZeroXExchangeProxy contract is payable to allow ethereum swaps
    /// @dev ensure _zeroXExchangeProxy are set properly for the chainId in which the contract is being deployed
    constructor(
        address _zeroXExchangeProxy,
        address _socketGateway,
        address _socketDeployFactory
    ) SwapImplBase(_socketGateway, _socketDeployFactory) {
        zeroXExchangeProxy = payable(_zeroXExchangeProxy);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @notice function to swap tokens on the chain and transfer to receiver address
     * @dev This is called only when there is a request for a swap.
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken is to be swapped
     * @param amount amount to be swapped
     * @param receiverAddress address of toToken recipient
     * @param swapExtraData data required for zeroX Exchange to get the swap done
     */
    function performAction(
        address fromToken,
        address toToken,
        uint256 amount,
        address receiverAddress,
        bytes calldata swapExtraData
    ) external payable override returns (uint256) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 erc20ToToken = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        if (toToken == NATIVE_TOKEN_ADDRESS) {
            payable(receiverAddress).transfer(returnAmount);
        } else {
            erc20ToToken.transfer(receiverAddress, returnAmount);
        }

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
            receiverAddress
        );

        return returnAmount;
    }

    /**
     * @notice function to swapWithIn SocketGateway - swaps tokens on the chain to socketGateway as recipient
     * @param fromToken token to be swapped
     * @param toToken token to which fromToken has to be swapped
     * @param amount amount of fromToken being swapped
     * @param swapExtraData encoded value of properties in the swapData Struct
     * @return swapped amount (in toToken Address)
     */
    function performActionWithIn(
        address fromToken,
        address toToken,
        uint256 amount,
        bytes calldata swapExtraData
    ) external payable override returns (uint256, address) {
        if (fromToken == address(0)) {
            revert Address0Provided();
        }

        bytes memory swapCallData = abi.decode(swapExtraData, (bytes));

        uint256 _initialBalanceTokenOut;
        uint256 _finalBalanceTokenOut;

        ERC20 erc20ToToken = ERC20(toToken);
        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _initialBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _initialBalanceTokenOut = address(this).balance;
        }

        if (fromToken != NATIVE_TOKEN_ADDRESS) {
            ERC20 token = ERC20(fromToken);
            token.safeTransferFrom(msg.sender, address(this), amount);
            token.safeApprove(zeroXExchangeProxy, amount);

            // solhint-disable-next-line
            (bool success, ) = zeroXExchangeProxy.call(swapCallData);

            if (!success) {
                revert SwapFailed();
            }

            token.safeApprove(zeroXExchangeProxy, 0);
        } else {
            (bool success, ) = zeroXExchangeProxy.call{value: amount}(
                swapCallData
            );
            if (!success) {
                revert SwapFailed();
            }
        }

        if (toToken != NATIVE_TOKEN_ADDRESS) {
            _finalBalanceTokenOut = erc20ToToken.balanceOf(address(this));
        } else {
            _finalBalanceTokenOut = address(this).balance;
        }

        uint256 returnAmount = _finalBalanceTokenOut - _initialBalanceTokenOut;

        emit SocketSwapTokens(
            fromToken,
            toToken,
            returnAmount,
            amount,
            ZeroXIdentifier,
            socketGateway
        );

        return (returnAmount, toToken);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {OnlyOwner, OnlyNominee} from "../errors/SocketErrors.sol";

abstract contract Ownable {
    address private _owner;
    address private _nominee;

    event OwnerNominated(address indexed nominee);
    event OwnerClaimed(address indexed claimer);

    constructor(address owner_) {
        _claimOwner(owner_);
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function nominee() public view returns (address) {
        return _nominee;
    }

    function nominateOwner(address nominee_) external {
        if (msg.sender != _owner) {
            revert OnlyOwner();
        }
        _nominee = nominee_;
        emit OwnerNominated(_nominee);
    }

    function claimOwner() external {
        if (msg.sender != _nominee) {
            revert OnlyNominee();
        }
        _claimOwner(msg.sender);
    }

    function _claimOwner(address claimer_) internal {
        _owner = claimer_;
        _nominee = address(0);
        emit OwnerClaimed(claimer_);
    }
}