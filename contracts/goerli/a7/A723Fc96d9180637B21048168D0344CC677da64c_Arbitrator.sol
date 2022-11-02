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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

import { IArbitrable } from "./interfaces/IArbitrable.sol";
import { IArbitrator } from "./interfaces/IArbitrator.sol";

import { PositionParams } from "./lib/AgreementStructs.sol";
import { Resolution, ResolutionStatus } from "./lib/ResolutionStructs.sol";
import { Controlled } from "./lib/auth/Controlled.sol";
import { FeeCollector } from "./lib/FeeCollector.sol";
import { Toggleable } from "./lib/Toggleable.sol";
import { Permit } from "./lib/Permit.sol";

/// @notice Contract with the power to arbitrate Nation3 agreements.
/// @dev The DAO will be expected to own this contract and set a controller to operate it.
/// @dev The owner set the working parameters and manage the fees.
/// @dev The owner can disable submissions and executions at any moment.
/// @dev The owner can replace the controller at any time.
/// @dev Only parties of a resolution can appeal the resolution.
/// @dev The owner can override appeals by backing resolutions.
/// @dev Everyone can execute non-appealed resolutions after a locking period.
contract Arbitrator is IArbitrator, Controlled(msg.sender, msg.sender), Toggleable, FeeCollector {
    /// @dev Number of blocks needed to wait before executing a resolution.
    uint256 public executionLockPeriod;

    /// @dev Mapping of all submitted resolutions.
    mapping(bytes32 => Resolution) public resolution;

    /// @notice Setup arbitrator variables.
    /// @param feeToken_ Token used to pay arbitration costs.
    /// @param fee_ Fee cost.
    /// @param executionLockPeriod_ Number of blocks needed to wait before executing a resolution.
    /// @param enabled_ Status of the arbitrator.
    function setUp(
        ERC20 feeToken_,
        uint256 fee_,
        uint256 executionLockPeriod_,
        bool enabled_
    ) external onlyOwner {
        _setFee(feeToken_, address(this), fee_);
        executionLockPeriod = executionLockPeriod_;
        enabled = enabled_;
    }

    /// @inheritdoc Toggleable
    /// @dev Allows owner to disable submissions and executions.
    function setEnabled(bool status) external override onlyOwner {
        enabled = status;
    }

    /// @inheritdoc FeeCollector
    /// @dev Allows owner to update the arbitration fees.
    function setFee(
        ERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyOwner {
        _setFee(token, recipient, amount);
    }

    /// @notice Withdraw ERC20 tokens from the contract.
    function withdrawTokens(
        ERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        _withdraw(token, to, amount);
    }

    /// @inheritdoc IArbitrator
    /// @dev Only controller is able to submit resolutions.
    function submitResolution(
        IArbitrable framework,
        bytes32 id,
        string calldata metadataURI,
        PositionParams[] calldata settlement
    ) public isEnabled onlyController returns (bytes32) {
        bytes32 hash = _resolutionHash(address(framework), id);
        Resolution storage resolution_ = resolution[hash];

        if (resolution_.status == ResolutionStatus.Executed) revert ResolutionIsExecuted();

        resolution_.status = ResolutionStatus.Pending;
        resolution_.mark = keccak256(abi.encode(settlement));
        resolution_.metadataURI = metadataURI;
        resolution_.unlockBlock = block.number + executionLockPeriod;

        emit ResolutionSubmitted(address(framework), id, hash);

        return hash;
    }

    /// @inheritdoc IArbitrator
    function executeResolution(
        IArbitrable framework,
        bytes32 id,
        PositionParams[] calldata settlement
    ) public isEnabled {
        bytes32 hash = _resolutionHash(address(framework), id);
        Resolution storage resolution_ = resolution[hash];

        if (resolution_.status == ResolutionStatus.Appealed) revert ResolutionIsAppealed();
        if (resolution_.status == ResolutionStatus.Executed) revert ResolutionIsExecuted();
        if (
            resolution_.status != ResolutionStatus.Endorsed &&
            block.number < resolution_.unlockBlock
        ) revert ExecutionStillLocked();
        if (resolution_.mark != keccak256(abi.encode(settlement))) revert ResolutionMustMatch();

        framework.settleDispute(id, settlement);

        resolution_.status = ResolutionStatus.Executed;

        emit ResolutionExecuted(hash);
    }

    /// @inheritdoc IArbitrator
    function appealResolution(bytes32 hash, PositionParams[] calldata settlement) external {
        _canAppeal(msg.sender, hash, settlement);

        SafeTransferLib.safeTransferFrom(feeToken, msg.sender, address(this), fee);

        resolution[hash].status = ResolutionStatus.Appealed;

        emit ResolutionAppealed(hash, msg.sender);
    }

    /// @inheritdoc IArbitrator
    function appealResolutionWithPermit(
        bytes32 hash,
        PositionParams[] calldata settlement,
        Permit calldata permit
    ) external {
        _canAppeal(msg.sender, hash, settlement);

        feeToken.permit(
            msg.sender,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        SafeTransferLib.safeTransferFrom(feeToken, msg.sender, address(this), fee);

        resolution[hash].status = ResolutionStatus.Appealed;

        emit ResolutionAppealed(hash, msg.sender);
    }

    /// @inheritdoc IArbitrator
    function endorseResolution(bytes32 hash, PositionParams[] calldata settlement)
        external
        onlyOwner
    {
        Resolution storage resolution_ = resolution[hash];

        if (resolution_.status == ResolutionStatus.Default) revert ResolutionNotSubmitted();
        if (resolution_.status == ResolutionStatus.Executed) revert ResolutionIsExecuted();
        if (resolution_.mark != keccak256(abi.encode(settlement))) revert ResolutionMustMatch();

        resolution_.status = ResolutionStatus.Endorsed;

        emit ResolutionEndorsed(hash);
    }

    /* ====================================================================== */
    /*                              INTERNAL UTILS
    /* ====================================================================== */

    /// @dev Get resolution hash for given dispute.
    /// @param framework address of the framework of the agreement in dispute.
    /// @param id identifier of the agreement in dispute.
    function _resolutionHash(address framework, bytes32 id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(framework, id));
    }

    /// @dev Check if account can appeal a resolution.
    /// @param account address to check.
    /// @param hash hash of the resolution.
    function _canAppeal(
        address account,
        bytes32 hash,
        PositionParams[] calldata settlement
    ) internal view {
        Resolution storage resolution_ = resolution[hash];

        if (resolution_.status == ResolutionStatus.Default) revert ResolutionNotSubmitted();
        if (resolution_.status == ResolutionStatus.Executed) revert ResolutionIsExecuted();
        if (resolution_.status == ResolutionStatus.Endorsed) revert ResolutionIsEndorsed();
        if (resolution_.mark != keccak256(abi.encode(settlement))) revert ResolutionMustMatch();
        if (!_isParty(account, settlement)) revert NoPartOfResolution();
    }

    /// @dev Check if an account is part of a settlement.
    /// @param account Address to check.
    /// @param settlement Array of positions.
    function _isParty(address account, PositionParams[] calldata settlement)
        internal
        pure
        returns (bool found)
    {
        for (uint256 i = 0; !found && i < settlement.length; i++) {
            if (settlement[i].party == account) found = true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;
import { PositionParams } from "../lib/AgreementStructs.sol";

/// @notice Interface for arbitrable contracts.
/// @dev Implementers must write the logic to raise and settle disputes.
interface IArbitrable {
    error OnlyArbitrator();

    /// @notice Address capable of settling disputes.
    function arbitrator() external view returns (address);

    /// @notice Settles a dispute providing settlement positions.
    /// @param id Id of the dispute to settle.
    /// @param settlement Array of final positions.
    function settleDispute(bytes32 id, PositionParams[] calldata settlement) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { PositionParams } from "../lib/AgreementStructs.sol";
import { Permit } from "../lib/Permit.sol";
import { IArbitrable } from "./IArbitrable.sol";

interface IArbitrator {
    event ResolutionSubmitted(address indexed framework, bytes32 indexed id, bytes32 indexed hash);
    event ResolutionAppealed(bytes32 indexed hash, address account);
    event ResolutionEndorsed(bytes32 indexed hash);
    event ResolutionExecuted(bytes32 indexed hash);

    error ResolutionNotSubmitted();
    error ResolutionIsAppealed();
    error ResolutionIsExecuted();
    error ResolutionIsEndorsed();
    error ExecutionStillLocked();
    error ResolutionMustMatch();
    error NoPartOfResolution();

    /// @notice Submit a resolution for a dispute.
    /// @dev Any new resolution for the same dispute overrides the last one.
    /// @param framework address of the framework of the agreement in dispute.
    /// @param id identifier of the agreement in dispute.
    /// @param settlement Array of final positions in the resolution.
    /// @return Hash of the resolution submitted.
    function submitResolution(
        IArbitrable framework,
        bytes32 id,
        string calldata metadataURI,
        PositionParams[] calldata settlement
    ) external returns (bytes32);

    /// @notice Execute a submitted resolution.
    /// @param framework address of the framework of the agreement in dispute.
    /// @param id identifier of the agreement in dispute.
    /// @param settlement Array of final positions in the resolution.
    function executeResolution(
        IArbitrable framework,
        bytes32 id,
        PositionParams[] calldata settlement
    ) external;

    /// @notice Appeal a submitted resolution.
    /// @param hash Hash of the resolution to appeal.
    /// @param settlement Array of final positions in the resolution.
    function appealResolution(bytes32 hash, PositionParams[] calldata settlement) external;

    /// @notice Appeal a submitted resolution with EIP-2612 permit.
    /// @param hash Hash of the resolution to appeal.
    /// @param settlement Array of final positions in the resolution.
    /// @param permit EIP-2612 permit data to approve transfer of tokens.
    function appealResolutionWithPermit(
        bytes32 hash,
        PositionParams[] calldata settlement,
        Permit calldata permit
    ) external;

    /// @notice Endorse a submitted resolution so it can't be appealed.
    /// @param hash Hash of the resolution to endorse.
    /// @param settlement Array of final positions in the resolution.
    function endorseResolution(bytes32 hash, PositionParams[] calldata settlement) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

enum AgreementStatus {
    Created,
    Ongoing,
    Finalized,
    Disputed
}

enum PositionStatus {
    Idle,
    Joined,
    Finalized
}

/// @dev Agreement party position
struct Position {
    /// @dev Matches index of the party in the agreement
    uint256 id;
    /// @dev Amount of tokens corresponding to this position.
    uint256 balance;
    /// @dev Status of the position
    PositionStatus status;
}

struct Agreement {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
    /// @dev Total amount of collateral tokens deposited in the agreement.
    uint256 balance;
    /// @dev Number of finalizations confirmations.
    uint256 finalizations;
    /// @dev Signal if agreement is disputed.
    bool disputed;
    /// @dev List of parties involved in the agreement.
    address[] party;
    /// @dev Position by party.
    mapping(address => Position) position;
}

/// @dev Adapter of agreement params for functions I/O.
struct AgreementParams {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
}

/// @dev Params to create new positions.
struct PositionParams {
    /// @dev Holder of the position.
    address party;
    /// @dev Amount of tokens corresponding to this position.
    uint256 balance;
}

/// @dev Agreement position data.
struct AgreementPosition {
    /// @dev Holder of the position.
    address party;
    /// @dev Amount of tokens corresponding to this position.
    uint256 balance;
    /// @dev Status of the position.
    PositionStatus status;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";


/// @notice Simple mixin to setup and collect fees.
abstract contract FeeCollector {

    /// @dev Token used to collect fees.
    ERC20 public feeToken;

    /// @dev Default fee recipient.
    address public feeRecipient;

    /// @dev Amount of tokens to collect as fee.
    uint256 public fee;

    /// @dev Raised when the recipient is not valid.
    error InvalidRecipient();

    /// @notice Withdraw any fees in the contract to the default recipient.
    function collectFees() external virtual {
        if (feeRecipient == address(0)) revert InvalidRecipient();

        uint256 amount = feeToken.balanceOf(address(this));
        _withdraw(feeToken, feeRecipient, amount);
    }

    /// @notice Set fee parameters.
    /// @param token ERC20 token to collect fees with.
    /// @param recipient Default recipient for the fees.
    /// @param amount Amount of fee tokens per fee.
    function setFee(ERC20 token, address recipient, uint256 amount) external virtual {
        _setFee(token, recipient, amount);
    }

    /// @dev Withdraw ERC20 tokens from the contract.
    function _withdraw(ERC20 token, address to, uint256 amount) internal virtual {
        SafeTransferLib.safeTransfer(token, to, amount);
    }

    /// @dev Set fee parameters.
    function _setFee(ERC20 token, address recipient, uint256 amount) internal {
        if (recipient == address(0)) revert InvalidRecipient();

        feeToken = token;
        feeRecipient = recipient;
        fee = amount;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @dev EIP-2612 Permit
///      Together with a EIP-2612 compliant token,
///      allows a contract to approve transfer of funds through signature.
///      This is specially usefull to implement operations 
///      that approve and transfer funds on the same transaction.
struct Permit {
    uint256 value;
    uint256 deadline;
    /// ECDSA Signature components.
    uint8 v;
    bytes32 r;
    bytes32 s;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

enum ResolutionStatus {
    Default,
    Pending,
    Endorsed,
    Appealed,
    Executed
}

struct Resolution {
    ResolutionStatus status;
    bytes32 mark;
    string metadataURI;
    uint256 unlockBlock;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice Simple mixin to enable / disable a contract.
abstract contract Toggleable {

    error IsDisabled();

    /// @dev Set status of the arbitrator.
    bool public enabled;

    /// @dev Requires to be enabled before performing function.
    modifier isEnabled() {
        if (!enabled) revert IsDisabled();
        _;
    }

    /// @notice Enable / disable a contract.
    /// @param status New enabled status.
    function setEnabled(bool status) external virtual {
        enabled = status;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { Owned } from "./Owned.sol";

/// @notice Authorization mixin that extends Owned with Controller rol.
abstract contract Controlled is Owned {

    event ControllerUpdated(address indexed user, address indexed newController);

    address public controller;

    modifier onlyController() virtual {
        if (msg.sender != controller) revert Unauthorized();

        _;
    }

    modifier onlyOwnerOrController() virtual {
        if (msg.sender != owner && msg.sender != controller) revert Unauthorized();

        _;
    }

    constructor(address owner_, address controller_) Owned(owner_) {
        controller = controller_;

        emit ControllerUpdated(msg.sender, controller_);
    }

    function setController(address newController) public virtual onlyOwner {
        controller = newController;

        emit ControllerUpdated(msg.sender, newController);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice Simple single owner authorization mixin.
/// @dev Adapted from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {

    event OwnerUpdated(address indexed user, address indexed newOwner);

    error Unauthorized();

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    constructor(address owner_) {
        owner = owner_;

        emit OwnerUpdated(msg.sender, owner_);
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}