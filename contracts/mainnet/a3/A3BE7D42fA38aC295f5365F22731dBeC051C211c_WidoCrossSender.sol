// SPDX-License-Identifier: MIT.
pragma solidity 0.8.7;

import "./interfaces/IWidoRouter.sol";
import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts-v4/security/ReentrancyGuard.sol";

contract WidoCrossSender is ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using SafeTransferLib for address;

    IWidoRouter public immutable widoRouter;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param sender The msg.sender
    /// @param recipient Recipient of the final tokens on destination chain
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    event CrossOrderInitiated(
        IWidoRouter.Order order,
        address sender,
        address indexed recipient,
        uint256 feeBps,
        address indexed partner
    );

    error SingleTokenOutputExpected();
    error InsufficientFee(uint256 expected, uint256 actual);
    error FeeOutOfRange(uint256 feeBps);
    error InvalidBridgeAddress();
    error ZeroAddressWidoRouter();
    error BridgeFailSilently();

    error BridgeFeeCannotBeZero();
    error InvalidBridgeStep();
    error SlippageTooHigh(uint256 expected, uint256 actual);
    error FailedToCallBridgeContract(string reason);

    constructor(IWidoRouter _widoRouter) {
        if (address(_widoRouter) == address(0)) revert ZeroAddressWidoRouter();

        widoRouter = _widoRouter;
    }

    /// @notice Execute a cross order
    /// @param order Order object describing the requirements of the zap
    /// @param steps Array of pre-bridge steps
    /// @param bridgeStep Bridge step
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    /// @param bridgeFee Gas/Fee for the bridge call
    /// @param recipient Recipient of the final tokens on destination chain
    function executeCrossOrder(
        IWidoRouter.Order calldata order,
        IWidoRouter.Step[] calldata steps,
        IWidoRouter.Step calldata bridgeStep,
        uint256 feeBps,
        address partner,
        uint256 bridgeFee,
        address recipient
    ) external payable nonReentrant {
        if (order.outputs.length != 1) revert SingleTokenOutputExpected();
        if (bridgeStep.targetAddress == address(0)) revert InvalidBridgeAddress();
        if (bridgeStep.fromToken != order.outputs[0].tokenAddress) revert InvalidBridgeStep();
        if (feeBps > 100) revert FeeOutOfRange(feeBps);
        if (bridgeFee <= 0) revert BridgeFeeCannotBeZero();
        if (msg.value < bridgeFee) revert InsufficientFee(bridgeFee, msg.value);

        if (steps.length > 0) {
            // Send the tokens directly to WidoRouter, escape the order.inputs.
            _sendTokens(order.inputs, address(widoRouter));

            IWidoRouter.Order memory modifiedOrder = order;
            modifiedOrder.user = address(this);
            delete modifiedOrder.inputs;

            // Run Execute Order for pre-bridge steps, no fee collection.
            widoRouter.executeOrder{value: msg.value - bridgeFee}(modifiedOrder, steps, 0, partner);
        } else {
            _sendTokens(order.inputs, address(this));
        }

        // Collect fees
        uint256 amount = _collectFees(bridgeStep, feeBps, bridgeFee);

        // Validate the amount to be bridged.
        if (amount < order.outputs[0].minOutputAmount) revert SlippageTooHigh(order.outputs[0].minOutputAmount, amount);

        // Prepare payload for bridge call
        bytes memory editedBridgeData;
        if (bridgeStep.amountIndex >= 0) {
            uint256 idx = uint256(int256(bridgeStep.amountIndex));
            editedBridgeData = bytes.concat(bridgeStep.data[:idx], abi.encode(amount), bridgeStep.data[idx + 32:]);
        } else {
            editedBridgeData = bridgeStep.data;
        }

        // Approve tokens to bridge contract
        _approveTokens(bridgeStep, amount);

        // Calculate bridge value
        uint256 bridgeValue = bridgeFee;
        if (bridgeStep.fromToken == address(0)) {
            bridgeValue += amount;
        }

        // Call bridge contract
        (bool success, bytes memory result) = bridgeStep.targetAddress.call{value: bridgeValue}(editedBridgeData);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert BridgeFailSilently();
            assembly {
                result := add(result, 0x04)
            }
            revert FailedToCallBridgeContract(abi.decode(result, (string)));
        }

        emit CrossOrderInitiated(order, msg.sender, recipient, feeBps, partner);
    }

    /// @notice Transfers tokens from the sender to the receiver
    /// @param inputs Array of input objects, see OrderInput and Order
    /// @param receiver Address to receive the tokens
    function _sendTokens(IWidoRouter.OrderInput[] calldata inputs, address receiver) private {
        for (uint256 i = 0; i < inputs.length; ) {
            IWidoRouter.OrderInput memory input = inputs[i];
            unchecked {
                i++;
            }

            if (input.tokenAddress == address(0)) {
                continue;
            }

            ERC20(input.tokenAddress).safeTransferFrom(msg.sender, receiver, input.amount);
        }
    }

    function _approveTokens(IWidoRouter.Step calldata bridgeStep, uint256 amount) private {
        if (bridgeStep.fromToken != address(0)) {
            if (ERC20(bridgeStep.fromToken).allowance(address(this), bridgeStep.targetAddress) < amount) {
                ERC20(bridgeStep.fromToken).safeApprove(bridgeStep.targetAddress, amount);
            }
        }
    }

    /// @notice Collects fees from the contract
    /// @param bridgeStep Bridge step
    /// @param feeBps Fee in basis points (bps)
    /// @param bridgeFee Gas/Fee for the bridge call
    /// @return amount Amount to be bridged
    function _collectFees(
        IWidoRouter.Step calldata bridgeStep,
        uint256 feeBps,
        uint256 bridgeFee
    ) private returns (uint256) {
        uint256 amount;
        if (bridgeStep.fromToken == address(0)) {
            amount = address(this).balance - bridgeFee;
        } else {
            amount = ERC20(bridgeStep.fromToken).balanceOf(address(this));
        }

        if (feeBps != 0) {
            address bank = widoRouter.bank();
            uint256 fee = (amount * feeBps) / 10000;
            if (bridgeStep.fromToken == address(0)) {
                bank.safeTransferETH(fee);
            } else {
                ERC20(bridgeStep.fromToken).safeTransfer(bank, fee);
            }
            amount = amount - fee;
        }

        return amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "../WidoTokenManager.sol";

interface IWidoRouter {
    /// @notice OrderInput object describing the desired token inputs
    /// @param tokenAddress Address of the input token
    /// @param fromTokenAmount Amount of the input token to spend on the user's behalf
    /// @dev amount must == msg.value when token == address(0)
    struct OrderInput {
        address tokenAddress;
        uint256 amount;
    }

    /// @notice OrderOutput object describing the desired token outputs
    /// @param tokenAddress Address of the output token
    /// @param minOutputAmount Minimum amount of the output token the user is willing to accept for this order
    struct OrderOutput {
        address tokenAddress;
        uint256 minOutputAmount;
    }

    /// @notice Order object describing the requirements of the zap
    /// @param inputs Array of input objects, see OrderInput
    /// @param outputs Array of output objects, see OrderOutput
    /// @param user Address of user placing the order
    /// @param nonce Number used once to ensure an order requested by a signature only executes once
    /// @param expiration Timestamp until which the order is valid to execute
    struct Order {
        OrderInput[] inputs;
        OrderOutput[] outputs;
        address user;
        uint32 nonce;
        uint32 expiration;
    }

    /// @notice Step object describing a single token transformation
    /// @param fromToken Address of the from token
    /// @param targetAddress Address of the contract performing the transformation
    /// @param data Data which the swap contract will be called with
    /// @param amountIndex Index for the from token amount that can be found in data and needs to be updated with the most recent value.
    struct Step {
        address fromToken;
        address targetAddress;
        bytes data;
        int32 amountIndex;
    }

    function widoTokenManager() external view returns (WidoTokenManager);

    function bank() external view returns (address);

    function verifyOrder(Order calldata order, uint8 v, bytes32 r, bytes32 s) external view returns (bool);

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable;

    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable;

    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;
import "./IWidoRouter.sol";

interface IWidoTokenManager {
    function pullTokens(address user, IWidoRouter.OrderInput[] calldata inputs) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts-v4/access/Ownable.sol";
import "./interfaces/IWidoTokenManager.sol";

contract WidoTokenManager is IWidoTokenManager, Ownable {
    using SafeTransferLib for ERC20;

    /// @notice Transfers tokens or native tokens from the user
    /// @param user The address of the order user
    /// @param inputs Array of input objects, see OrderInput and Order
    function pullTokens(address user, IWidoRouter.OrderInput[] calldata inputs) external override onlyOwner {
        for (uint256 i = 0; i < inputs.length; i++) {
            IWidoRouter.OrderInput calldata input = inputs[i];

            if (input.tokenAddress == address(0)) {
                continue;
            }

            ERC20(input.tokenAddress).safeTransferFrom(user, owner(), input.amount);
        }
    }
}

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