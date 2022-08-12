//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./base/MSSCBase.sol";
import "./base/MembraneAuth.sol";
import "./lib/InstructionManagerLib.sol";
import "./lib/HTLC.sol";

contract MSSCHybrid is MSSCBase, MembraneAuth, HTLC {
  using InstructionManagerLib for Instruction;

  constructor(uint256 lockPeriod_, uint256 unlockPeriod_)
    payable
    HTLC(lockPeriod_, unlockPeriod_)
  {}

  /*//////////////////////////////////////////////////////////////
                    EXTERNAL STATE-CHANGING METHODS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Register settlementCycle, this function can only be perfomed by a Membrane wallet.
   *         Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
   *
   * @param cycleId Cycle's bytes32 obfuscatedId to register.
   * @param instructions instructions to register.
   */
  function registerSettlementCycle(
    bytes32 cycleId,
    InstructionArgs[] calldata instructions
  ) external requiresAuth {
    _register(cycleId, instructions);

    emit RegisterHybridCycle(cycleId, instructions);
  }

  /**
   * @notice Register settlementCycle, this function can only be perfomed by a Membrane wallet.
   *         Caller must transform obfuscatedId string to bytes32, pure strings are not supported.
   *
   * @param cycleId Cycle's bytes32 obfuscatedId to register.
   * @param instructions instructions to register.
   */
  function registerSettlementCycle(
    bytes32 cycleId,
    InstructionArgs[] calldata instructions,
    bytes32 commintment
  ) external requiresAuth {
    _register(cycleId, instructions);

    commit(cycleId, commintment);

    emit RegisterHybridCycle(cycleId, instructions);
  }

  /**
   * @notice Execute instructions in a SettlementCycle, anyone can call this function as long as
   *         every required deposit is fullfilled.
   *
   * @param  cycleId Cycle's bytes32 obfuscatedId to execute.
   */
  function executeInstructions(bytes32 cycleId) external isNotLocked(cycleId) {
    _execute(cycleId);

    emit ExecuteHybridCycle(cycleId);
  }

  /**
   * @notice Execute instructions in a SettlementCycle, anyone can call this function as long as
   *         every required deposit is fullfilled.
   *
   * @param  cycleId Cycle's bytes32 obfuscatedId to execute.
   */
  function executeInstructions(bytes32 cycleId, string calldata secret)
    external
    unlock(cycleId, secret)
  {
    _execute(cycleId);

    emit ExecuteHybridCycle(cycleId);
  }

  /**
   * @notice Make deposits (Native coin or ERC20 tokens) to a existent instruction, {msg.sender} will become
   *         the {sender} of the instruction hence will be the only account which is able to withdraw
   *         those allocated funds.
   *
   * @param  instructionId Instruction to allocate funds.
   */
  function deposit(bytes32 cycleId, bytes32 instructionId) external payable {
    _instructions[instructionId].deposit();

    if (_locks[cycleId].commitment != bytes32(0)) {
      ++_cycles[cycleId].instructionsWithDeposits;

      if (
        _cycles[cycleId].instructionsWithDeposits ==
        _cycles[cycleId].instructions.length
      ) {
        lock(cycleId);
      }
    }
  }

  /**
   * @notice Withdraw funds from a settlement. Caller must be the sender of instruction.
   *
   * @param  instructionId Instruction to withdraw deposited funds from.
   */
  function withdraw(bytes32 cycleId, bytes32 instructionId)
    external
    isNotLocked(cycleId)
  {
    _instructions[instructionId].withdraw();

    if (_locks[cycleId].commitment != bytes32(0)) {
      if (
        _cycles[cycleId].instructionsWithDeposits <
        _cycles[cycleId].instructions.length
      ) --_cycles[cycleId].instructionsWithDeposits;
    }
  }

  /**
   * @notice Claim locked funds from an instruction.
   * @dev    Caller must be the recipient.
   *
   * @param  instructionId Instruction to claim deposited funds.
   */
  function claim(
    bytes32 cycleId,
    bytes32 instructionId,
    string calldata secret
  ) external isLocked(cycleId) unlock(cycleId, secret) {
    _instructions[instructionId].pay();
  }

  /*//////////////////////////////////////////////////////////////
                        EXTERNAL VIEW METHODS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice View function to get the instructions ids in a settlement cycle.
   *
   * @param cycleId Cycle to check.
   */
  function getSettlementInstructions(bytes32 cycleId)
    external
    view
    returns (bytes32[] memory)
  {
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
  function executed(bytes32 cycleId) external view returns (bool) {
    return _cycles[cycleId].executed;
  }

  /**
   * @notice View function to check an instruction's info
   *
   * @param instructionId Instruction to check.
   */

  function getInstructionInfo(bytes32 instructionId)
    external
    view
    returns (Instruction memory)
  {
    return _instructions[instructionId];
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../lib/InstructionManagerLib.sol";

abstract contract MSSCBase {
  using InstructionManagerLib for Instruction;

  event RegisterHybridCycle(
    bytes32 indexed cycleId,
    InstructionArgs[] instructions
  );
  event ExecuteHybridCycle(bytes32 indexed cycleId);

  mapping(bytes32 => SettlementCycle) internal _cycles;
  mapping(bytes32 => Instruction) internal _instructions;

  /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPERS
  //////////////////////////////////////////////////////////////*/

  function _register(bytes32 cycleId, InstructionArgs[] calldata instructions)
    internal
  {
    if (_exists(cycleId)) {
      revert CycleAlreadyRegistered();
    }

    // Retrieve the total number of instructions and place on the stack.
    uint256 totalInstructions = instructions.length;

    if (totalInstructions == 0) {
      revert CycleHasNoInstruction();
    }

    bytes32[] storage newInstructions = _cycles[cycleId].instructions;

    for (uint256 i = 0; i < totalInstructions; ) {
      InstructionArgs calldata instructionArgs = instructions[i];
      bytes32 instructionId = instructionArgs.id;

      Instruction storage instruction = _instructions[instructionId];

      instruction.register(instructionArgs);

      newInstructions.push(instructionId);

      // Skip overflow check as for loop is indexed starting at zero.
      unchecked {
        ++i;
      }
    }
  }

  function _execute(bytes32 cycleId) internal {
    // Assertions
    if (!_exists(cycleId)) revert NoCycle();
    if (_cycles[cycleId].executed) revert CycleAlreadyExecuted();

    _cycles[cycleId].executed = true;
    bytes32[] memory instructions = _cycles[cycleId].instructions;

    // Retrieve the total number of instructions and place on the stack.
    uint256 totalInstructions = instructions.length;

    for (uint256 i = 0; i < totalInstructions; ) {
      Instruction storage instruction = _instructions[instructions[i]];

      instruction.pay();

      // Skip overflow check as for loop is indexed starting at zero.
      unchecked {
        ++i;
      }
    }
  }

  // Check that cycleId is registered by looking at instructions length, this function may change its logic later
  function _exists(bytes32 cycleId) internal view returns (bool) {
    return _cycles[cycleId].instructions.length > 0;
  }

  /*///////////////////////////////////////////////////////////////
                          RECIEVE ETHER LOGIC
  //////////////////////////////////////////////////////////////*/

  /// @dev Required for the Instructions to be able to receive unwrapped ETH.
  receive() external payable {}
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
    require(_isOperator[msg.sender], "Unauthorized");

    _;
  }

  /**
   * @notice  grant or revoke an account access to auth ops
   * @dev     expected to be called by other operator
   *
   * @param   account_ account to update authorization
   * @param   isAuthorized_ to grant or revoke access
   */
  function setAccountAccess(address account_, bool isAuthorized_)
    external
    requiresAuth
  {
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
}

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.4;

import "../config/errors.sol";
import "../config/types.sol";
import "@solmate/utils/SafeTransferLib.sol";
import "@solmate/tokens/ERC20.sol";

/**
 * @title   InstructionManagerLib
 * @notice  Contains logic for managing instructions such as
 *          registration, deposits, withdrawals and payments.
 */

library InstructionManagerLib {
  using SafeTransferLib for ERC20;

  /**
   * @dev    Validate and register instruction data.
   *
   * @param  s_instruction Storage pointer where data will be saved.
   * @param  instructionArgs data to register.
   */

  function register(
    Instruction storage s_instruction,
    InstructionArgs calldata instructionArgs
  ) internal {
    // Copy values to memory so that we save extra SLOADs
    Instruction memory instruction = s_instruction;

    // Ensure that instruction doesn't exist by checking its amount.
    if (instruction.amount > 0) {
      revert InstructionExists(instructionArgs.id);
    }

    _assertValidInstructionData(instructionArgs);

    s_instruction.id = instructionArgs.id;
    s_instruction.recipient = instructionArgs.receiver;
    s_instruction.amount = instructionArgs.amount;
    s_instruction.asset = instructionArgs.asset;
  }

  /**
   * @dev    Fulfill a instruction's required amount by depositing into the MSSC contract.
   *
   * @param  s_instruction Instruction to make the deposit.
   */
  function deposit(Instruction storage s_instruction) internal {
    // Copy values to memory so that we save extra SLOADs
    Instruction memory m_instruction = s_instruction;

    // Ensure that instruction does exist by checking its amount.
    if (m_instruction.amount == 0) {
      revert NoInstruction();
    }

    // Revert if the is not awaiting deposits
    if (m_instruction.depositStatus != DepositStatus.PENDING) {
      revert AlreadyFulfilled(m_instruction.id, m_instruction.payer);
    }

    s_instruction.depositStatus = DepositStatus.AVAILABLE;
    s_instruction.payer = msg.sender;

    // is not native ETH
    _transferToThis(m_instruction.asset, m_instruction.amount);

    //TODO: Emit an event
  }

  /**
   * @dev    Withdraw funds previously deposited to an instruction, {msg.sender} must be the payer.
   *
   * @param  s_instruction Instruction to withdraw funds from.
   */
  function withdraw(Instruction storage s_instruction) internal {
    // Copy values to memory so that we save extra SLOADs
    Instruction memory m_instruction = s_instruction;

    if (m_instruction.payer != msg.sender) {
      revert NotPayer();
    }
    _assertFundsAreAvailable(m_instruction);

    // revert deposit status
    s_instruction.depositStatus = DepositStatus.PENDING;

    _transfer(m_instruction.asset, m_instruction.payer, m_instruction.amount);

    //TODO: Emit an event
  }

  /**
   * @dev    Pay allocated funds to its corresponding recipient.
   *
   * @param  s_instruction Instruction to withdraw funds from.
   */

  function pay(Instruction storage s_instruction) internal {
    // Copy values to memory so that we save extra SLOADs
    Instruction memory m_instruction = s_instruction;

    _assertFundsAreAvailable(m_instruction);

    // update status to claimed
    s_instruction.depositStatus = DepositStatus.CLAIMED;

    _transfer(
      m_instruction.asset,
      m_instruction.recipient,
      m_instruction.amount
    );

    //TODO: Emit an event
  }

  /*//////////////////////////////////////////////////////////////
                           TRANSFER HELPERS
  //////////////////////////////////////////////////////////////*/

  // perform transfers from {this}.
  function _transfer(
    address asset,
    address to,
    uint256 amount
  ) private {
    // is not native ETH
    if (asset != address(0)) {
      ERC20(asset).safeTransfer(to, amount);
    } else {
      SafeTransferLib.safeTransferETH(to, amount);
    }
  }

  // perform transfers to {this}.
  function _transferToThis(address asset, uint256 amount) private {
    // is not native ETH
    if (asset != address(0)) {
      ERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
    } else {
      if (msg.value != amount) {
        revert InvalidSuppliedETHAmount();
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                           ASSERTIONS
  //////////////////////////////////////////////////////////////*/

  /**
    @dev Ensure that required amount in a instruction is fullfiled.
   */
  function _assertFundsAreAvailable(Instruction memory instruction)
    private
    pure
  {
    // Revert if there's no deposits
    if (
      instruction.depositStatus != DepositStatus.AVAILABLE ||
      instruction.payer == address(0)
    ) {
      revert NoDeposits(instruction.id);
    }
  }

  /**
   * @dev Internal view function to ensure that a given instruction tuple has valid data.
   *
   * @param instruction  The instruction tuple to check.
   */

  function _assertValidInstructionData(InstructionArgs calldata instruction)
    internal
    view
  {
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
  function _assertNonZeroAmount(InstructionArgs calldata instruction)
    internal
    pure
  {
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
  function _assertReceiverIsNotZeroAddress(InstructionArgs calldata instruction)
    private
    pure
  {
    if (instruction.receiver == address(0)) {
      revert ReceiverIsZeroAddress(instruction.id);
    }
  }

  /**
   * @dev Internal view function to ensure that {asset} is a valid contract or null address
   *      for ETH transfers.
   *
   * @param instruction  The instruction tuple to check.
   */
  function _assertValidAsset(InstructionArgs calldata instruction)
    private
    view
  {
    if (instruction.asset.code.length == 0 && instruction.asset != address(0)) {
      revert InvalidAsset(instruction.id);
    }
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title HTLC
 *
 * @dev   Abstract contract for handling hashed time locks to be
 *        implemented into the MSSC contract
 */

abstract contract HTLC {
  uint256 immutable claimablePeriod;
  uint256 immutable refundablePeriod;

  constructor(uint256 claimablePeriod_, uint256 refundablePeriod_) {
    claimablePeriod = claimablePeriod_;
    refundablePeriod = refundablePeriod_;
  }

  struct Lock {
    bytes32 commitment;
    uint256 startTime;
  }

  modifier unlock(bytes32 lockId_, string calldata secret) {
    if (_isLocked(lockId_)) {
      require(_hash(secret) == _locks[lockId_].commitment, "Invalid Secret");
    }

    _;
  }

  modifier isNotLocked(bytes32 lockId_) {
    require(!_isLocked(lockId_), "Has active lock");

    _;
  }

  modifier isLocked(bytes32 lockId_) {
    require(_isLocked(lockId_), "Has no active lock");

    _;
  }

  mapping(bytes32 => Lock) internal _locks;

  function lock(bytes32 lockId_) internal {
    require(!_isActive(lockId_), "Lock already started");

    _locks[lockId_].startTime = block.timestamp;
  }

  function commit(bytes32 lockId_, bytes32 commitment_) internal {
    require(_locks[lockId_].commitment == bytes32(0), "Commitment already set");

    _locks[lockId_].commitment = commitment_;
  }

  function _isLocked(bytes32 lockId_) private view returns (bool) {
    if (!_isActive(lockId_)) return false;

    uint256 activeTime = block.timestamp - _locks[lockId_].startTime;

    return
      (activeTime % (claimablePeriod + refundablePeriod)) < claimablePeriod;
  }

  function _hash(string calldata preimage) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(preimage));
  }

  function _isActive(bytes32 lockId_) private view returns (bool) {
    return _locks[lockId_].startTime != 0;
  }

  function getLockInfo(bytes32 lockId_) external view returns (Lock memory) {
    return _locks[lockId_];
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

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
 * @dev Revert with an error when trying to register an existent instruction.
 *
 * @param instruction The instruction that already exists.
 *
 */
error InstructionExists(bytes32 instruction);

/**
 * @dev Revert with an error when attempting to interact with an instruction that
 *      does not yet exist.
 */
error NoInstruction();

/**
 * @dev Revert with an error when an asset of a instruction is invalid.
 *
 * @param instruction The instruction that contain the invalid asset.
 */
error InvalidAsset(bytes32 instruction);

/**
 * @dev Revert with an error when attempting to register a receiver account
 *      and supplying the null address.
 *
 * @param instruction The instruction that contain the zero address.
 */
error ReceiverIsZeroAddress(bytes32 instruction);

/**
 * @dev Revert with an error when invalid ether is deposited for an instruction.
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
error NoDeposits(bytes32 instruction);

/**
 * @dev Revert with an error when a instruction has deposits.
 *
 * @param instruction  The instruction identifier of the attempted operation.
 * @param payer        The address which deposited and fulfilled the intruction's amount.
 */
error AlreadyFulfilled(bytes32 instruction, address payer);

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./enums.sol";

struct Instruction {
  bytes32 id;
  address recipient;
  address asset;
  uint256 amount;
  address payer;
  DepositStatus depositStatus;
}

struct InstructionArgs {
  bytes32 id;
  address receiver;
  address asset;
  uint256 amount;
}

struct SettlementCycle {
  bytes32[] instructions;
  uint256 instructionsWithDeposits;
  bool executed;
}

struct DepositItem {
  DepositType depositType;
  bytes32 instructionId;
  address token;
}

struct TransferDepositedItem {
  DepositItem depositItem;
  address to;
  uint256 amount;
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

enum DepositType {
  NATIVE,
  ERC20
}

enum DepositStatus {
  PENDING,
  AVAILABLE,
  CLAIMED
}