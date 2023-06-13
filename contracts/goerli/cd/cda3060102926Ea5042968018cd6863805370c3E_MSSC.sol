//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {MSSCBase, CycleType} from "./base/MSSCBase.sol";
import {MembraneAuth} from "./lib/MembraneAuth.sol";
import {InstructionManagerLib as InstructionMgrLib} from "./lib/InstructionManagerLib.sol";
import {OnePeriodLockManagerLib as OnePeriodLockMgrLib} from "./lib/OnePeriodLockManagerLib.sol";
import {PeriodicLockManagerLib as PeriodicLockMgrLib} from "./lib/PeriodicLockManagerLib.sol";
import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol";

contract MSSC is MSSCBase, MembraneAuth, ReentrancyGuard {
    using InstructionMgrLib for InstructionMgrLib.Instruction;
    using PeriodicLockMgrLib for PeriodicLockMgrLib.PeriodicLockInfo;
    using OnePeriodLockMgrLib for OnePeriodLockMgrLib.OnePeriodLockInfo;

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL STATE-CHANGING METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register Settlement Cycle, this function can only be perfomed by a Membrane wallet.
     * @dev    Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to register.
     * @param  instructions instructions to register.
     */
    function registerCycle(
        bytes32 cycleId,
        InstructionMgrLib.Instruction[] calldata instructions
    ) external requiresAuth {
        _register(cycleId, instructions, CycleType.Unlocked);

        emit RegisterCycle(cycleId, instructions);
    }

    /**
     * @notice Register Settlement Cycle with infinite periodic locks,
     *             this function can only be perfomed by a Membrane wallet.
     * @dev    Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to register.
     * @param  instructions instructions to register.
     * @param  hashlock hashlock to be set for the hybrid cycle, will be used for further checks.
     */
    function registerCycleWithPeriodicLocks(
        bytes32 cycleId,
        InstructionMgrLib.Instruction[] calldata instructions,
        bytes32 hashlock
    ) external requiresAuth {
        _register(cycleId, instructions, CycleType.PeriodicLock);

        _periodicLocks[cycleId].storeHashlock(hashlock);
        _periodicLocks[cycleId].init(cycleId);

        emit RegisterCycleWithPeriodicLocks(cycleId, instructions, hashlock);
    }

    /**
     * @notice Register Settlement Cycle with a single lock, this function can only be perfomed by a Membrane wallet.
     * @dev    Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to register.
     * @param  instructions instructions to register.
     * @param  hashlock hashlock to be set for the hybrid cycle, will be used for further checks.
     * @param  deadline Unix timestamp which is the moment the lock period will finish.
     */
    function registerCycleWithOnePeriodLock(
        bytes32 cycleId,
        InstructionMgrLib.Instruction[] calldata instructions,
        bytes32 hashlock,
        uint32 deadline
    ) external requiresAuth deadlineIsLargeEnough(deadline) {
        _register(cycleId, instructions, CycleType.OnePeriodLock);

        _onePeriodLocks[cycleId].init(cycleId, hashlock, deadline);

        emit RegisterCycleWithOnePeriodLock(cycleId, instructions, hashlock);
    }

    /**
     * @notice Execute instructions in a Settlement Cycle, anyone can call this function as long as
     *         every required deposit is fulfilled.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to execute.
     */
    function executeCycle(
        bytes32 cycleId
    ) external cycleExists(cycleId) noHybrid(cycleId) nonReentrant {
        _execute(cycleId);

        emit ExecuteCycle(cycleId);
    }

    /**
     * @notice Execute instructions in an Hybrid Settlement Cycle, anyone can call this function as long as
     *         every required deposit is fullfilled and secret is revealed.
     *
     * @param  cycleId Cycle's bytes32 obfuscatedId to execute.
     */
    function executeHybridCycle(
        bytes32 cycleId
    )
        external
        cycleExists(cycleId)
        isHybrid(cycleId)
        nonReentrant
        secretIsRevealed(cycleId)
    {
        _execute(cycleId);

        emit ExecuteHybridCycle(cycleId);
    }

    function _beforeDeposit(
        bytes32 cycleId,
        bytes32 instructionId
    )
        internal
        override
        cycleExists(cycleId)
        belongsTo(instructionId, cycleId)
        nonReentrant
        returns (InstructionMgrLib.Instruction storage)
    {
        if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertIsNotLocked(_periodicLockConfig);
        }

        return _instructions[instructionId];
    }

    /**
     * @notice Withdraw funds from a settlement. Caller must be the sender of instruction.
     *
     * @param  instructionId Instruction to withdraw deposited funds from.
     */
    function _beforeRefund(
        bytes32 cycleId,
        bytes32 instructionId
    )
        internal
        override
        cycleExists(cycleId)
        belongsTo(instructionId, cycleId)
        nonReentrant
        returns (InstructionMgrLib.Instruction storage)
    {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertIsNotLocked();
        } else if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertIsNotLocked(_periodicLockConfig);
        }

        return _instructions[instructionId];
    }

    function _beforeClaim(
        bytes32 cycleId,
        bytes32 instructionId
    )
        internal
        override
        cycleExists(cycleId)
        isHybrid(cycleId)
        belongsTo(instructionId, cycleId)
        nonReentrant
        secretIsRevealed(cycleId)
        returns (InstructionMgrLib.Instruction storage)
    {
        if (_allInstructionsClaimed(cycleId)) {
            _cycles[cycleId].executed = true;
        }

        return _instructions[instructionId];
    }

    /**
     * @notice Publish the secret from a Settlement Cycle.
     * @dev    The caller can be anyone with the correct secret.
     *
     * @param  cycleId Cycle to reveal secret.
     * @param  secret  Secret to be published.
     */
    function publishSecret(
        bytes32 cycleId,
        string calldata secret
    ) external cycleExists(cycleId) isHybrid(cycleId) {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].validateSecret(cycleId, secret);
        } else {
            // Periodic Lock
            _periodicLocks[cycleId].validateSecret(cycleId, secret);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice View function to get the instructions ids in a settlement cycle.
     *
     * @param cycleId Cycle to check.
     */
    function getSettlementInstructions(
        bytes32 cycleId
    ) external view cycleExists(cycleId) returns (bytes32[] memory) {
        return _cycles[cycleId].instructions;
    }

    /**
     * @notice View function to check if a cycle has been registered.
     *
     * @param cycleId Cycle to check.
     */
    function registered(bytes32 cycleId) external view returns (bool) {
        return _exists(cycleId);
    }

    /**
     * @notice View function to check if a cycle has been executed.
     *
     * @param cycleId Cycle to check.
     */
    function executed(
        bytes32 cycleId
    ) external view cycleExists(cycleId) returns (bool) {
        return _cycles[cycleId].executed;
    }

    /**
     * @notice View function to check an instruction's info
     *
     * @param instructionId Instruction to check.
     */

    function getInstructionInfo(
        bytes32 instructionId
    ) external view returns (InstructionMgrLib.Instruction memory) {
        return _instructions[instructionId];
    }

    /**
     * @notice View function to check a cycle's lock info.
     *
     * @param cycleId Cycle to get lock property from.
     */

    function getPeriodicLockInfo(
        bytes32 cycleId
    ) external view returns (PeriodicLockMgrLib.PeriodicLockInfo memory) {
        return _periodicLocks[cycleId];
    }

    /**
     * @notice View function to check a cycle's lock info.
     *
     * @param cycleId Cycle to get lock property from.
     */

    function getOnePeriodLockInfo(
        bytes32 cycleId
    ) external view returns (OnePeriodLockMgrLib.OnePeriodLockInfo memory) {
        return _onePeriodLocks[cycleId];
    }

    function periodicLockCycleIsLocked(
        bytes32 cycleId
    ) external view returns (bool) {
        return _periodicLocks[cycleId].isLocked(_periodicLockConfig);
    }

    /**
     * @notice View function to check global lock config
     */
    function periodicLockConfig()
        external
        view
        returns (uint256, uint256, uint256)
    {
        return (
            _periodicLockConfig.originTimestamp,
            _periodicLockConfig.periodInSecs / 3600,
            _periodicLockConfig.lockDurationInSecs / 3600
        );
    }

    function setPeriodicLockConfig(
        uint256 originTimestamp,
        uint256 periodInHours,
        uint256 lockDurationInHours
    ) external requiresAuth {
        PeriodicLockMgrLib.PeriodicLockConfig
            memory newConfig = PeriodicLockMgrLib.PeriodicLockConfig({
                originTimestamp: originTimestamp,
                periodInSecs: periodInHours * 3600,
                lockDurationInSecs: lockDurationInHours * 3600
            });

        // Validate new config
        if (
            newConfig.originTimestamp > block.timestamp ||
            newConfig.periodInSecs < PeriodicLockMgrLib.MIN_PERIOD_DURATION ||
            newConfig.periodInSecs > PeriodicLockMgrLib.MAX_PERIOD_DURATION ||
            newConfig.lockDurationInSecs <
            PeriodicLockMgrLib.MIN_LOCK_DURATION ||
            newConfig.lockDurationInSecs >
            newConfig.periodInSecs - PeriodicLockMgrLib.MIN_UNLOCK_DURATION
        ) {
            revert InvalidPeriodicLockConfiguration();
        }

        // Let's make sure the lock status is not changed
        bool isOldConfigLocked = PeriodicLockMgrLib.isLockedGlobal(
            _periodicLockConfig
        );

        bool isNewConfigLocked = PeriodicLockMgrLib.isLockedGlobal(newConfig);

        if (isOldConfigLocked != isNewConfigLocked) {
            revert PeriodicLockStatusChanged();
        }

        // Update config
        _periodicLockConfig = newConfig;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.19;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";
import {IPaymentChannel} from "./interfaces/IPaymentChannel.sol";

contract PaymentChannel is IPaymentChannel {
    address public immutable mssc;

    error ForBidden();

    constructor() {
        mssc = msg.sender;
    }

    modifier onlyMSSC() {
        if (msg.sender != mssc) revert ForBidden();
        _;
    }

    function transferETH(address _to, uint256 _amount) external onlyMSSC {
        SafeTransferLib.safeTransferETH(_to, _amount);
    }

    function transferERC20(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyMSSC {
        SafeTransferLib.safeTransfer(ERC20(_token), _to, _amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Clones} from "@openzeppelin/proxy/Clones.sol";
import {PaymentChannel, IPaymentChannel} from "./PaymentChannel.sol";

contract PaymentChannelFactory {
    using Clones for address;

    address public immutable implementation;

    event PaymentChannelCreated(
        bytes32 settlementId,
        address user,
        address paymentChannel
    );

    constructor() {
        implementation = address(new PaymentChannel());
    }

    function computePaymentChannelAddress(
        bytes32 _settlementId,
        address _user
    ) external view returns (address) {
        return _computePaymentChannelAddress(_settlementId, _user);
    }

    function _getPaymentChannel(
        bytes32 _settlementId,
        address _user
    ) internal returns (IPaymentChannel pch) {
        address computedAddr = _computePaymentChannelAddress(
            _settlementId,
            _user
        );
        pch = PaymentChannel(computedAddr);

        uint256 codeLen;
        assembly {
            codeLen := extcodesize(computedAddr)
        }

        // If code length is 0, then the contract has not been deployed yet
        if (codeLen == 0) {
            __deployPaymentChannel(_settlementId, _user);
        }
    }

    function _computePaymentChannelAddress(
        bytes32 _settlementId,
        address _user
    ) internal view returns (address) {
        return
            implementation.predictDeterministicAddress(
                keccak256(abi.encodePacked(_settlementId, _user))
            );
    }

    function __deployPaymentChannel(
        bytes32 _settlementId,
        address _user
    ) private {
        address pchAddr = implementation.cloneDeterministic(
            keccak256(abi.encodePacked(_settlementId, _user))
        );

        emit PaymentChannelCreated(_settlementId, _user, pchAddr);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";

import {PaymentChannelFactory, IPaymentChannel} from "./PaymentChannelFactory.sol";
import {InstructionManagerLib} from "./lib/InstructionManagerLib.sol";

contract Hooks {
    bytes32 private constant NULL =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    function _beforeDeposit(
        bytes32 _settlementId,
        bytes32 _instructionId
    )
        internal
        virtual
        returns (InstructionManagerLib.Instruction storage s_instruction)
    {
        assembly {
            s_instruction.slot := NULL
        }
    }

    function _beforeRefund(
        bytes32 _settlementId,
        bytes32 _instructionId
    )
        internal
        virtual
        returns (InstructionManagerLib.Instruction storage s_instruction)
    {
        assembly {
            s_instruction.slot := NULL
        }
    }

    function _beforeClaim(
        bytes32 _settlementId,
        bytes32 _instructionId
    )
        internal
        virtual
        returns (InstructionManagerLib.Instruction storage s_instruction)
    {
        assembly {
            s_instruction.slot := NULL
        }
    }
}

contract PaymentChannelManager is PaymentChannelFactory, Hooks {
    event Deposit(address indexed from, bytes32 indexed instruction);
    event Refund(bytes32 indexed instruction);
    event Claim(bytes32 indexed instruction);

    mapping(bytes32 => bool) public instructionClaimed;

    function deposit(
        bytes32 _settlementId,
        bytes32 _instructionId
    ) external payable {
        InstructionManagerLib.Instruction
            storage s_instruction = _beforeDeposit(
                _settlementId,
                _instructionId
            );

        address pchAddress = _computePaymentChannelAddress(
            _settlementId,
            s_instruction.recipient
        );

        address asset = s_instruction.asset;
        uint256 amount = s_instruction.amount;

        if (asset != address(0)) {
            uint256 balanceBefore = __balanceOf(pchAddress, asset);

            SafeTransferLib.safeTransferFrom(
                ERC20(asset),
                msg.sender,
                pchAddress,
                amount
            );

            uint256 balanceAfter = __balanceOf(pchAddress, asset);

            uint256 actualAmount = balanceAfter - balanceBefore;

            // Revert if the received amount don't match the expected amount
            if (actualAmount != amount) {
                revert UnexpectedReceivedAmount(asset, amount, actualAmount);
            }
        } else {
            if (msg.value != amount) {
                revert InvalidSuppliedETHAmount();
            }

            SafeTransferLib.safeTransferETH(pchAddress, amount);
        }

        emit Deposit(msg.sender, _instructionId);
    }

    function claim(bytes32 _settlementId, bytes32 _instructionId) external {
        require(
            !instructionClaimed[_instructionId],
            "PaymentChannelManager: instruction already claimed"
        );

        _claim(_settlementId, _instructionId);
    }

    function _claim(bytes32 _settlementId, bytes32 _instructionId) internal {
        // MSSC.sol will set the rules for when a claim can be made
        InstructionManagerLib.Instruction storage s_instruction = _beforeClaim(
            _settlementId,
            _instructionId
        );

        IPaymentChannel pch = _getPaymentChannel(
            _settlementId,
            s_instruction.recipient
        );

        __transferFromPaymentChannel(
            pch,
            s_instruction.asset,
            s_instruction.recipient,
            s_instruction.amount
        );

        instructionClaimed[_instructionId] = true;

        emit Claim(_instructionId);
    }

    function refund(bytes32 _settlementId, bytes32 _instructionId) external {
        // MSSC.sol will set the rules for when a refund can be made
        InstructionManagerLib.Instruction storage s_instruction = _beforeRefund(
            _settlementId,
            _instructionId
        );

        IPaymentChannel pch = _getPaymentChannel(
            _settlementId,
            s_instruction.recipient
        );

        address asset = s_instruction.asset;

        __transferFromPaymentChannel(
            pch,
            asset,
            s_instruction.refundAddress,
            __balanceOf(address(pch), asset)
        );

        emit Refund(_instructionId);
    }

    function __transferFromPaymentChannel(
        IPaymentChannel pch,
        address _asset,
        address _recipient,
        uint256 _amount
    ) private {
        if (__balanceOf(address(pch), _asset) < _amount) {
            revert InsufficientBalanceInPCH(address(pch), _asset, _amount);
        }

        if (_asset != address(0)) {
            pch.transferERC20(_asset, _recipient, _amount);
        } else {
            pch.transferETH(_recipient, _amount);
        }
    }

    function __balanceOf(
        address _account,
        address _asset
    ) private view returns (uint256 bal) {
        if (_asset != address(0)) {
            bal = __ERC20Balance(_account, _asset);
        } else {
            bal = __ETHBalance(_account);
        }
    }

    function __ERC20Balance(
        address _account,
        address _token
    ) private view returns (uint256 bal) {
        (bool success, bytes memory data) = _token.staticcall(
            // 0x70a08231 = bytes4(keccak256("balanceOf(address)"))
            abi.encodeWithSelector(0x70a08231, address(_account))
        );

        if (!success || data.length != 32)
            revert("PaymentChannel: ERC20 balanceOf failed");

        bal = abi.decode(data, (uint256));
    }

    function __ETHBalance(address _account) private view returns (uint256 bal) {
        bal = address(_account).balance;
    }

    /**
     * @dev Revert with an error when {msg.value} does not match the required ETH amount
     *      required by an instruction.
     */
    error InvalidSuppliedETHAmount();

    /**
     * @dev Revert with an error if the received amount don't match the expected amount.
     */
    error UnexpectedReceivedAmount(
        address asset,
        uint256 expected,
        uint256 actual
    );

    /**
     * @dev Revert with an error if the payment channel does not have enough balance.
     */
    error InsufficientBalanceInPCH(address pch, address asset, uint256 amount);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {PeriodicLockManagerLib} from "../lib/PeriodicLockManagerLib.sol";
import {OnePeriodLockManagerLib} from "../lib/OnePeriodLockManagerLib.sol";
import {InstructionManagerLib} from "../lib/InstructionManagerLib.sol";
import {PaymentChannelManager} from "../PaymentChannelManager.sol";

enum CycleType {
    Unlocked,
    PeriodicLock,
    OnePeriodLock
}

abstract contract MSSCBase is PaymentChannelManager {
    using InstructionManagerLib for InstructionManagerLib.Instruction;
    using PeriodicLockManagerLib for PeriodicLockManagerLib.PeriodicLockInfo;
    using OnePeriodLockManagerLib for OnePeriodLockManagerLib.OnePeriodLockInfo;

    event RegisterCycle(
        bytes32 indexed cycleId,
        InstructionManagerLib.Instruction[] instructions
    );
    event RegisterCycleWithPeriodicLocks(
        bytes32 indexed cycleId,
        InstructionManagerLib.Instruction[] instructions,
        bytes32 hashlock
    );
    event RegisterCycleWithOnePeriodLock(
        bytes32 indexed cycleId,
        InstructionManagerLib.Instruction[] instructions,
        bytes32 hashlock
    );

    event ExecuteCycle(bytes32 indexed cycleId);
    event ExecuteHybridCycle(bytes32 indexed cycleId);

    modifier cycleExists(bytes32 cycleId) {
        if (!_exists(cycleId)) {
            revert NoCycle();
        }
        _;
    }

    modifier isHybrid(bytes32 cycleId) {
        if (!_isHybrid(cycleId)) {
            revert NotHybrid();
        }

        _;
    }

    modifier isLocked(bytes32 cycleId) {
        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertIsLocked();
        } else if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertIsLockedPeriod(_periodicLockConfig);
        }

        _;
    }

    modifier noHybrid(bytes32 cycleId) {
        if (_isHybrid(cycleId)) {
            revert HybridCycle();
        }

        _;
    }

    modifier secretIsRevealed(bytes32 cycleId) {
        _;

        if (_cycles[cycleId].cycleType == CycleType.OnePeriodLock) {
            _onePeriodLocks[cycleId].assertSecretIsRevealed();
        } else if (_cycles[cycleId].cycleType == CycleType.PeriodicLock) {
            _periodicLocks[cycleId].assertSecretIsRevealed();
        }
    }

    modifier belongsTo(bytes32 instructionId, bytes32 cycleId) {
        uint256 instructionsCount = _cycles[cycleId].instructions.length;
        bool found = false;
        for (uint256 i = 0; i < instructionsCount; ) {
            if (_cycles[cycleId].instructions[i] == instructionId) {
                found = true;
                break;
            }
            unchecked {
                ++i;
            }
        }
        if (!found) {
            revert InstructionDoesntBelongToCycle();
        }

        _;
    }

    modifier deadlineIsLargeEnough(uint32 deadline) {
        if (
            deadline <
            block.timestamp + OnePeriodLockManagerLib.MIN_DEADLINE_SPAN
        ) revert SmallDeadline();

        _;
    }

    struct SettlementCycle {
        bytes32[] instructions;
        CycleType cycleType;
        bool executed;
    }

    mapping(bytes32 => SettlementCycle) internal _cycles;
    mapping(bytes32 => PeriodicLockManagerLib.PeriodicLockInfo)
        internal _periodicLocks;
    mapping(bytes32 => OnePeriodLockManagerLib.OnePeriodLockInfo)
        internal _onePeriodLocks;
    mapping(bytes32 => InstructionManagerLib.Instruction)
        internal _instructions;

    PeriodicLockManagerLib.PeriodicLockConfig internal _periodicLockConfig;

    constructor() {
        // Reference: Mon Jan 02 2023 00:00:00 GMT+0000
        _periodicLockConfig.originTimestamp = 1672617600;

        _periodicLockConfig.periodInSecs = 7 days;
        _periodicLockConfig.lockDurationInSecs = 4 days;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _register(
        bytes32 cycleId,
        InstructionManagerLib.Instruction[] calldata instructions,
        CycleType cycleType
    ) internal {
        if (_exists(cycleId)) {
            revert CycleAlreadyRegistered();
        }

        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        if (totalInstructions == 0) {
            revert CycleHasNoInstruction();
        }

        _cycles[cycleId].cycleType = cycleType;
        bytes32[] storage newInstructions = _cycles[cycleId].instructions;

        for (uint256 i = 0; i < totalInstructions; ) {
            InstructionManagerLib.Instruction
                calldata instructionArgs = instructions[i];

            bytes32 instructionId = instructionArgs.id;

            InstructionManagerLib.Instruction
                storage instruction = _instructions[instructionId];

            instruction.register(instructionArgs);

            newInstructions.push(instructionId);

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    function _execute(bytes32 cycleId) internal {
        if (_cycles[cycleId].executed) revert CycleAlreadyExecuted();

        _cycles[cycleId].executed = true;
        bytes32[] memory instructions = _cycles[cycleId].instructions;

        // Retrieve the total number of instructions and place on the stack.
        uint256 totalInstructions = instructions.length;

        for (uint256 i = 0; i < totalInstructions; ) {
            InstructionManagerLib.Instruction
                storage instruction = _instructions[instructions[i]];

            // Ignore claimed instructions, this comes handy when dealing with hybrid Settlement Cycles.
            if (!instructionClaimed[instructions[i]]) {
                _claim(cycleId, instruction.id);
            }

            // Skip overflow check as for loop is indexed starting at zero.
            unchecked {
                ++i;
            }
        }
    }

    function _exists(bytes32 cycleId) internal view returns (bool) {
        return _cycles[cycleId].instructions.length > 0;
    }

    function _allInstructionsClaimed(
        bytes32 cycleId
    ) internal view returns (bool) {
        uint256 instructionsCount = _cycles[cycleId].instructions.length;

        for (uint256 i = 0; i < instructionsCount; ) {
            if (!instructionClaimed[_cycles[cycleId].instructions[i]])
                return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function _isHybrid(bytes32 cycleId) internal view returns (bool) {
        return _cycles[cycleId].cycleType != CycleType.Unlocked;
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when trying to register an existent Settlement Cycle.
     */
    error CycleAlreadyRegistered();

    /**
     * @dev Revert with an error when executing a previously executed Settlement Cycle.
     */
    error CycleAlreadyExecuted();

    /**
     * @dev Revert with an error when attempting to interact with a cycle that
     *      does not yet exist.
     */
    error NoCycle();

    /**
     * @dev Revert with an error when attempting to register a cycle without a
     *      single instruction.
     */
    error CycleHasNoInstruction();

    /**
     * @dev Revert with an error when attempting to perform Hybrid logic in a normal cycle.
     */
    error NotHybrid();

    /**
     * @dev Revert with an error when attempting to perform invalid logic in an Hybrid cycle.
     */
    error HybridCycle();

    /**
     * @dev Revert with an error when received instruction does not belong to the received cycle.
     */
    error InstructionDoesntBelongToCycle();

    /**
     * @dev Revert with an error when a cycle's deadline is very small.
     *
     */
    error SmallDeadline();

    /**
     * @dev Revert with an error when a new lock config is invalid.
     *
     */
    error InvalidPeriodicLockConfiguration();

    /**
     * @dev Revert with an error when setting a new lock config would change the current lock status.
     *
     */
    error PeriodicLockStatusChanged();
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPaymentChannel {
    function transferETH(address _to, uint256 _amount) external;

    function transferERC20(
        address _token,
        address _to,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

/**
 * @title   InstructionManagerLib
 * @notice  Contains logic for managing instructions such as
 *          registration, deposits, withdrawals and payments.
 */

library InstructionManagerLib {
    using SafeTransferLib for ERC20;
    event Deposit(address indexed account, bytes32 instruction);
    event Withdraw(address indexed account, bytes32 instruction);
    event Claim(bytes32 instruction);

    struct Instruction {
        bytes32 id;
        address recipient;
        address refundAddress;
        address asset;
        uint256 amount;
    }

    /**
     * @dev    Validate and register instruction data.
     *
     * @param  sInstruction Storage pointer where data will be saved.
     * @param  instructionArgs data to register.
     */

    function register(
        Instruction storage sInstruction,
        Instruction calldata instructionArgs
    ) internal {
        // Copy values to memory so that we save extra SLOADs
        Instruction memory instruction = sInstruction;

        // Ensure that instruction doesn't exist by checking its amount.
        if (instruction.amount > 0) {
            revert InstructionExists(instructionArgs.id);
        }

        _assertValidInstructionData(instructionArgs);

        sInstruction.id = instructionArgs.id;
        sInstruction.recipient = instructionArgs.recipient;
        sInstruction.amount = instructionArgs.amount;
        sInstruction.asset = instructionArgs.asset;
    }

    // function deposit(Instruction storage sInstruction) internal {
    //     // Copy values to memory so that we save extra SLOADs
    //     Instruction memory mInstruction = sInstruction;

    //     // Ensure that instruction does exist by checking its amount.
    //     if (mInstruction.amount == 0) {
    //         revert NoInstruction();
    //     }

    //     // Revert if the is not awaiting deposits
    //     if (mInstruction.depositStatus != DepositStatus.PENDING) {
    //         revert AlreadyFulfilled(mInstruction.id, mInstruction.payer);
    //     }

    //     sInstruction.depositStatus = DepositStatus.AVAILABLE;
    //     sInstruction.payer = msg.sender;

    //     // is not native ETH
    //     _performTransfer(
    //         mInstruction.asset,
    //         msg.sender,
    //         address(this),
    //         mInstruction.amount
    //     );

    //     emit Deposit(msg.sender, mInstruction.id);
    // }

    // function withdraw(Instruction storage sInstruction) internal {
    //     // Copy values to memory so that we save extra SLOADs
    //     Instruction memory mInstruction = sInstruction;

    //     if (mInstruction.payer != msg.sender) {
    //         revert NotPayer();
    //     }
    //     _assertFundsAreAvailable(mInstruction);

    //     // revert deposit status
    //     sInstruction.depositStatus = DepositStatus.PENDING;

    //     _performTransfer(
    //         mInstruction.asset,
    //         address(this),
    //         mInstruction.payer,
    //         mInstruction.amount
    //     );

    //     emit Withdraw(msg.sender, mInstruction.id);
    // }

    // function claim(Instruction storage sInstruction) internal {
    //     // Copy values to memory so that we save extra SLOADs
    //     Instruction memory mInstruction = sInstruction;

    //     _assertFundsAreAvailable(mInstruction);

    //     // update status to claimed
    //     sInstruction.depositStatus = DepositStatus.CLAIMED;

    //     _performTransfer(
    //         mInstruction.asset,
    //         address(this),
    //         mInstruction.recipient,
    //         mInstruction.amount
    //     );

    //     emit Claim(mInstruction.id);
    // }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER HELPERS
    //////////////////////////////////////////////////////////////*/

    // Perform a transfer of funds from one address to another.
    //
    // NOTE: This function performs checks to ensure that the correct amount of
    //       funds are transferred. If the amount transferred is not equal to the
    //       expected amount, the transaction will be reverted. This is to
    //       prevent tokens with a transfer fee from being used.
    function _performTransfer(
        address asset,
        address from,
        address to,
        uint256 amount
    ) private {
        // is not native ETH
        if (asset != address(0)) {
            uint256 balanceBefore = ERC20(asset).balanceOf(to);

            if (from == address(this)) {
                ERC20(asset).safeTransfer(to, amount);
            } else {
                ERC20(asset).safeTransferFrom(from, to, amount);
            }

            uint256 balanceAfter = ERC20(asset).balanceOf(to);

            uint256 actualAmount = balanceAfter - balanceBefore;

            // Revert if the received amount don't match the expected amount
            if (actualAmount != amount) {
                revert UnexpectedReceivedAmount(asset, amount, actualAmount);
            }
        } else {
            if (from != address(this)) {
                if (msg.value != amount) {
                    revert InvalidSuppliedETHAmount();
                }
            } else {
                SafeTransferLib.safeTransferETH(to, amount);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                           ASSERTIONS
    //////////////////////////////////////////////////////////////*/

    // function _assertFundsAreAvailable(
    //     Instruction memory instruction,
    //     address paymentChannelAddress
    // ) private pure {
    //     // Revert if there's no sufficient balance deposited in PaymentChannel address.
    //     if (
    //         paymentChannelAddress._balance(instruction.asset) <
    //         instruction.amount
    //     ) {
    //         revert InsufficientBalanceForInstruction(instruction.id);
    //     }
    // }

    /**
     * @dev Internal view function to ensure that a given instruction tuple has valid data.
     *
     * @param instruction  The instruction tuple to check.
     */

    function _assertValidInstructionData(
        Instruction calldata instruction
    ) internal view {
        _assertNonZeroAmount(instruction);

        _assertReceiverIsNotZeroAddress(instruction);

        _assertValidAsset(instruction);
    }

    /**
     * @dev Internal pure function to ensure that a given item amount is not
     *      zero.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertNonZeroAmount(
        Instruction calldata instruction
    ) internal pure {
        // Revert if the supplied amount is equal to zero.
        if (instruction.amount == 0) {
            revert ZeroAmount(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that {sender} and {recipient} in a given
     *      instruction are non-zero addresses.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertReceiverIsNotZeroAddress(
        Instruction calldata instruction
    ) private pure {
        if (
            instruction.refundAddress == address(0) ||
            instruction.recipient == address(0)
        ) {
            revert RecipientOrRefundAddressIsZeroNull(instruction.id);
        }
    }

    /**
     * @dev Internal view function to ensure that {asset} is a valid contract or null address
     *      for ETH transfers.
     *
     * @param instruction  The instruction tuple to check.
     */
    function _assertValidAsset(Instruction calldata instruction) private view {
        if (
            instruction.asset.code.length == 0 &&
            instruction.asset != address(0)
        ) {
            revert InvalidAsset(instruction.id);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when attempting to interact with an instruction that
     *      does not yet exist.
     */
    error NoInstruction();

    /**
     * @dev Revert with an error when trying to register an existent instruction.
     *
     * @param instruction The instruction that already exists.
     *
     */
    error InstructionExists(bytes32 instruction);

    /**
     * @dev Revert with an error when an asset of a instruction is invalid.
     *
     * @param instruction The instruction that contain the invalid asset.
     */
    error InvalidAsset(bytes32 instruction);

    /**
     * @dev Revert with an error when attempting to register a receiver or refund account
     *      and supplying the null address.
     *
     * @param instruction The instruction that contain the zero address.
     */
    error RecipientOrRefundAddressIsZeroNull(bytes32 instruction);

    /**
     * @dev Revert with an error when {msg.value} does not match the required ETH amount
     *      required by an instruction.
     */
    error InvalidSuppliedETHAmount();

    /**
     * @dev Revert with an error when an account is not the payer of the instruction.
     */
    error NotPayer();

    /**
     * @dev Revert with an error when attempting to register a Settlement with no amount.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error ZeroAmount(bytes32 instruction);

    /**
     * @dev Revert with an error when a instruction has no deposits.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     */
    error InsufficientBalanceForInstruction(bytes32 instruction);

    /**
     * @dev Revert with an error when a instruction has deposits.
     *
     * @param instruction  The instruction identifier of the attempted operation.
     * @param payer        The address which deposited and fulfilled the intruction's amount.
     */
    error AlreadyFulfilled(bytes32 instruction, address payer);

    /**
     * @dev Revert with an error if the received amount don't match the expected amount.
     */
    error UnexpectedReceivedAmount(
        address asset,
        uint256 expected,
        uint256 actual
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice A generic contract which provides custom auth logic to Membrane operations.
/// @author Membrane Labs
abstract contract MembraneAuth {
    mapping(address => bool) private _isOperator;

    constructor() {
        _isOperator[msg.sender] = true;
    }

    modifier requiresAuth() virtual {
        if (!_isOperator[msg.sender]) revert Unauthorized();

        _;
    }

    /**
     * @notice  grant or revoke an account access to auth ops
     * @dev     expected to be called by other operator
     *
     * @param   account_ account to update authorization
     * @param   isAuthorized_ to grant or revoke access
     */
    function setAccountAccess(
        address account_,
        bool isAuthorized_
    ) external requiresAuth {
        if (msg.sender == account_) {
            revert EditOwnAuthorization();
        }
        _isOperator[account_] = isAuthorized_;
    }

    /**
     * @notice  Returns wheter account is a Membrane operator.
     * @dev     expected to be call by account owner
     *          usually user should only give access to helper contracts
     * @param   account_ account to check
     */

    function isAllowedOperator(address account_) external view returns (bool) {
        return _isOperator[account_];
    }

    error Unauthorized();

    error EditOwnAuthorization();
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

/**
 * @title   LockManagerLib
 *
 * @notice  Library for managing hash-time Locks from Hybrid Settlement Cycles.
 */
library OnePeriodLockManagerLib {
    event InitLock(bytes32 cycleId, bytes32 hashlock, uint32 deadline);
    event DisruptLock(bytes32 cycleId);
    event SecretRevealed(bytes32 cycleId, string secret);

    uint32 public constant MIN_DEADLINE_SPAN = 1 days;

    struct OnePeriodLockInfo {
        bytes32 hashlock;
        uint32 deadline;
        bool secretRevealed;
    }

    /**
     * @notice Initialize absolute time-lock periods for a Settlement Cycle.
     *
     * @dev    Lock period is intended to allow claims, executions and secret revelation
     *         as long as the correct secret is provided. On the other hand, Unlock period is
     *         mean to allow withdrawls (hence disrupt the lock).
     *
     * @dev    This function must be called once all required deposits are fulfilled.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     */
    function init(
        OnePeriodLockInfo storage lock,
        bytes32 cycleId,
        bytes32 hashlock_,
        uint32 deadline
    ) internal {
        if (lock.hashlock != bytes32(0)) {
            revert AlreadyInitialized();
        }

        if (uint32(block.timestamp) >= deadline) {
            revert InvalidDeadline();
        }

        if (hashlock_ == bytes32(0)) {
            revert HashlockIsZero();
        }

        lock.hashlock = hashlock_;
        lock.deadline = deadline;

        emit InitLock(cycleId, hashlock_, deadline);
    }

    /**
     * @notice Reveal Lock's secret and infinitely extend claimable period.
     *
     * @dev    This method must be called when a cycle is within locked period and
     *         before performing any logic that requires being within the claimable period.
     * @dev    Once the secret is known, subsequent calls to {claim} or {executeInstuctions}
     *         may not require the secret to be sent in calldata anymore.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     * @param  secret String to be validated against stored hashlock.
     */
    function validateSecret(
        OnePeriodLockInfo storage lock,
        bytes32 cycleId,
        string calldata secret
    ) internal {
        if (_hash(secret) != lock.hashlock) {
            revert InvalidSecret();
        }

        lock.secretRevealed = true;

        emit SecretRevealed(cycleId, secret);
    }

    function isLocked(
        OnePeriodLockInfo memory lock
    ) internal view returns (bool) {
        return (uint32(block.timestamp) < lock.deadline) || lock.secretRevealed;
    }

    function assertSecretIsRevealed(
        OnePeriodLockInfo memory lock
    ) internal pure {
        if (!lock.secretRevealed) {
            revert SecretNotRevealedYet();
        }
    }

    function assertIsNotLocked(OnePeriodLockInfo memory lock) internal view {
        if (isLocked(lock)) revert Locked();
    }

    function assertIsLocked(OnePeriodLockInfo memory lock) internal view {
        if (!isLocked(lock)) revert UnLocked();
    }

    function isExpired(
        OnePeriodLockInfo memory lock
    ) internal view returns (bool) {
        return (uint32(block.timestamp) >= lock.deadline);
    }

    function assertIsNotExpired(OnePeriodLockInfo memory lock) internal view {
        if (isExpired(lock)) revert LockExpired();
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _hash(string calldata preimage) private pure returns (bytes32) {
        return sha256(abi.encodePacked(preimage));
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when a attempting interact with locked object.
     *
     */
    error Locked();

    /**
     * @dev Revert with an error when a attempting interact with unlocked object.
     *
     */
    error UnLocked();

    /**
     * @dev Revert with an error when a attempting to claim unlocked funds.
     *
     */
    error AlreadyInitialized();

    /**
     * @dev Revert with an error when a attempting to claim unlocked funds.
     *
     */
    error InvalidDeadline();

    /**
     * @dev Revert with an error when a provided secret is incorrect.
     *
     */
    error InvalidSecret();

    /**
     * @dev Revert with an error when a provided hashlock is `bytes32(0)`.
     *
     */
    error HashlockIsZero();

    /**
     * @dev Revert with an error when a cycle's lock has been already relocated.
     *
     */
    error SecretNotRevealedYet();

    /**
     * @dev Revert with an error when a cycle's lock has been expired.
     *
     */
    error LockExpired();
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

/**
 * @title   LockManagerLib
 *
 * @notice  Library for managing hash-time Locks from Hybrid Settlement Cycles.
 */
library PeriodicLockManagerLib {
    event InitLock(bytes32 cycleId, bytes32 hashlock);
    event DisruptLock(bytes32 cycleId);
    event SecretRevealed(bytes32 cycleId, string secret);

    uint32 public constant MAX_PERIOD_DURATION = 7 days;

    uint32 public constant MIN_PERIOD_DURATION = 6 hours;
    uint32 public constant MIN_LOCK_DURATION = 4 hours;
    uint32 public constant MIN_UNLOCK_DURATION = 2 hours;

    enum LockStatus {
        UNINITIALIZED,
        INITIALIZED,
        SECRET_REVEALED
    }

    struct PeriodicLockInfo {
        bytes32 hashlock;
        LockStatus status;
    }

    struct PeriodicLockConfig {
        uint256 originTimestamp;
        uint256 periodInSecs;
        uint256 lockDurationInSecs;
    }

    /**
     * @notice Record hashlock derived from a secret.
     * @dev    This function must be called once an Hybrid Settlement Cycle is being registered as the
     *         {hashlock} property will determine whether a cycle is hybrid or not.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  hashlock_ hashlock to be set, will be used to validate secrets sent to MSSC.
     */
    function storeHashlock(
        PeriodicLockInfo storage lock,
        bytes32 hashlock_
    ) internal {
        if (lock.hashlock != bytes32(0)) {
            revert AlreadyCommited();
        }
        if (hashlock_ == bytes32(0)) {
            revert HashlockIsZero();
        }

        lock.hashlock = hashlock_;
    }

    /**
     * @notice Initialize absolute time-lock periods for a Settlement Cycle.
     *
     * @dev    Lock period is intended to allow claims, executions and secret revelation
     *         as long as the correct secret is provided. On the other hand, Unlock period is
     *         mean to allow withdrawls (hence disrupt the lock).
     *
     * @dev    This function must be called once all required deposits are fulfilled.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     */
    function init(PeriodicLockInfo storage lock, bytes32 cycleId) internal {
        if (lock.status != LockStatus.UNINITIALIZED) {
            revert AlreadyInitialized();
        }
        lock.status = LockStatus.INITIALIZED;

        emit InitLock(cycleId, lock.hashlock);
    }

    /**
     * @notice Disrupt time-lock periods for a Cycle.
     * @dev    This function must be called once a withdrawal is made while lock's status is INITIALIZED.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     */
    function disrupt(
        PeriodicLockInfo storage lock,
        bytes32 cycleId,
        PeriodicLockConfig memory lockConfig
    ) internal {
        if (isLocked(lock, lockConfig)) revert Locked();

        lock.status = LockStatus.UNINITIALIZED;

        emit DisruptLock(cycleId);
    }

    /**
     * @notice Reveal Lock's secret and infinitely extend claimable period.
     *
     * @dev    This method must be called when a cycle is within locked period and
     *         before performing any logic that requires being within the claimable period.
     * @dev    Once the secret is known, subsequent calls to {claim} or {executeInstuctions}
     *         may not require the secret to be sent in calldata anymore.
     *
     * @param  lock Storage pointer of the lock of a cycle.
     * @param  cycleId Cycle that owns the lock, used purely for log purposes.
     * @param  secret String to be validated against stored hashlock.
     */
    function validateSecret(
        PeriodicLockInfo storage lock,
        bytes32 cycleId,
        string calldata secret
    ) internal {
        if (_hash(secret) != lock.hashlock) {
            revert InvalidSecret();
        }

        lock.status = LockStatus.SECRET_REVEALED;

        emit SecretRevealed(cycleId, secret);
    }

    function isLocked(
        PeriodicLockInfo memory lock,
        PeriodicLockConfig memory lockConfig
    ) internal view returns (bool) {
        if (lock.status == LockStatus.UNINITIALIZED) return false;
        if (lock.status == LockStatus.SECRET_REVEALED) return true;

        return isLockedGlobal(lockConfig);
    }

    function assertSecretIsRevealed(
        PeriodicLockInfo memory lock
    ) internal pure {
        if (lock.status != LockStatus.SECRET_REVEALED) {
            revert SecretNotRevealedYet();
        }
    }

    function assertIsNotLocked(
        PeriodicLockInfo memory lock,
        PeriodicLockConfig memory lockConfig
    ) internal view {
        if (isLocked(lock, lockConfig)) revert Locked();
    }

    function assertIsLockedPeriod(
        PeriodicLockInfo memory lock,
        PeriodicLockConfig memory lockConfig
    ) internal view {
        if (!isLocked(lock, lockConfig)) revert UnLocked();
    }

    // Check if the contract is locked globally (i.e. for all cycles)
    function isLockedGlobal(
        PeriodicLockConfig memory lockConfig
    ) internal view returns (bool) {
        unchecked {
            return
                ((block.timestamp - lockConfig.originTimestamp) %
                    lockConfig.periodInSecs) < lockConfig.lockDurationInSecs;
        }
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _hash(string calldata preimage) private pure returns (bytes32) {
        return sha256(abi.encodePacked(preimage));
    }

    function _getCurrentHour() private view returns (uint256) {
        return (block.timestamp % 1 days);
    }

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Revert with an error when a attempting interact with locked object.
     *
     */
    error Locked();

    /**
     * @dev Revert with an error when a attempting interact with unlocked object.
     *
     */
    error UnLocked();

    /**
     * @dev Revert with an error when a attempting to claim unlocked funds.
     *
     */
    error AlreadyInitialized();

    /**
     * @dev Revert with an error when a provided secret is incorrect.
     *
     */
    error InvalidSecret();

    /**
     * @dev Revert with an error when a provided hashlock is `bytes32(0)`.
     *
     */
    error HashlockIsZero();

    /**
     * @dev Revert with an error when a cycle has been already commited to be locked.
     *
     */
    error AlreadyCommited();

    /**
     * @dev Revert with an error when a cycle's lock has been already relocated.
     *
     */
    error SecretNotRevealedYet();
}