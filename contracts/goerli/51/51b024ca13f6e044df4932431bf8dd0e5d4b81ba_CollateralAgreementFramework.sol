// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

import { IAgreementFramework } from "../interfaces/IAgreementFramework.sol";
import { IArbitrable } from "../interfaces/IArbitrable.sol";

import {
    Agreement,
    AgreementParams,
    AgreementPosition,
    AgreementStatus,
    Position,
    PositionParams,
    PositionStatus
} from "../lib/AgreementStructs.sol";
import { Permit } from "../lib/Permit.sol";
import { CriteriaResolver, CriteriaResolution } from "../lib/CriteriaResolution.sol";
import { Owned } from "../lib/auth/Owned.sol";
import { FeeCollector } from "../lib/FeeCollector.sol";

/// @notice Framework to create collateral agreements.
/// @dev Funds are held on each agreement.
/// @dev Joining agreements criteria is defined by Merkle trees.
/// @dev Parties manually join previously created agreements.
/// @dev Agreements finalization by unanimity of its parties.
/// @dev Parties manually withdraw their position from agreement.
contract CollateralAgreementFramework is
    IAgreementFramework,
    CriteriaResolution,
    Owned(msg.sender),
    FeeCollector
{
    /* ====================================================================== //
                                        ERRORS
    // ====================================================================== */

    error PositionsMustMatch();
    error BalanceMustMatch();

    /* ====================================================================== //
                                        STORAGE
    // ====================================================================== */

    /// @dev Token used as collateral in agreements.
    ERC20 public collateralToken;

    /// @dev Address with the power to settle agreements in dispute.
    address public arbitrator;

    /// @dev Total amount of collateral tokens deposited in the framework.
    uint256 public totalBalance;

    /// @dev Map of agreements by id.
    mapping(bytes32 => Agreement) public agreement;

    /// @dev Internal agreement nonce.
    uint256 internal _nonce;

    function setUp(
        ERC20 collateralToken_,
        ERC20 feeToken_,
        address arbitrator_,
        uint256 fee_
    ) external onlyOwner {
        _setFee(feeToken_, arbitrator_, fee_);
        collateralToken = collateralToken_;
        arbitrator = arbitrator_;
    }

    /* ====================================================================== */
    /*                                  VIEWS
    /* ====================================================================== */

    /// @dev Retrieve an AgreementParams struct with the data of a given agreement.
    /// @inheritdoc IAgreementFramework
    function agreementParams(bytes32 id)
        external
        view
        override
        returns (AgreementParams memory params)
    {
        params = AgreementParams(
            agreement[id].termsHash,
            agreement[id].criteria,
            agreement[id].metadataURI
        );
    }

    /// @dev Retrieve the array of positions of given agreement with its balance and status.
    /// @inheritdoc IAgreementFramework
    function agreementPositions(bytes32 id)
        external
        view
        override
        returns (AgreementPosition[] memory)
    {
        uint256 partyLength = agreement[id].party.length;
        AgreementPosition[] memory positions = new AgreementPosition[](partyLength);

        for (uint256 i = 0; i < partyLength; i++) {
            address party = agreement[id].party[i];

            positions[i] = AgreementPosition(
                party,
                agreement[id].position[party].balance,
                agreement[id].position[party].status
            );
        }

        return positions;
    }

    /// @dev Retrieve a simplified status of the agreement from its attributes.
    /// @inheritdoc IAgreementFramework
    function agreementStatus(bytes32 id) external view override returns (AgreementStatus) {
        if (agreement[id].party.length > 0) {
            if (agreement[id].finalizations >= agreement[id].party.length)
                return AgreementStatus.Finalized;
            if (agreement[id].disputed) return AgreementStatus.Disputed;
            // else
            return AgreementStatus.Ongoing;
        } else if (agreement[id].criteria != 0) {
            return AgreementStatus.Created;
        }
        revert NonExistentAgreement();
    }

    /* ====================================================================== */
    /*                                USER LOGIC
    /* ====================================================================== */

    /// @dev Create a new agreement with given params.
    /// @inheritdoc IAgreementFramework
    function createAgreement(AgreementParams calldata params)
        external
        override
        returns (bytes32 agreementId)
    {
        agreementId = keccak256(abi.encode(address(this), _nonce));

        agreement[agreementId].termsHash = params.termsHash;
        agreement[agreementId].criteria = params.criteria;
        agreement[agreementId].metadataURI = params.metadataURI;

        _nonce++;

        emit AgreementCreated(agreementId, params.termsHash, params.criteria, params.metadataURI);
    }

    /// @dev Join an existent agreement providing a valid criteria resolver.
    /// @inheritdoc IAgreementFramework
    function joinAgreement(bytes32 id, CriteriaResolver calldata resolver) external override {
        _canJoinAgreement(id, resolver);

        SafeTransferLib.safeTransferFrom(
            collateralToken,
            msg.sender,
            address(this),
            resolver.balance
        );

        _addPosition(id, PositionParams(msg.sender, resolver.balance));
        totalBalance += resolver.balance;

        emit AgreementJoined(id, msg.sender, resolver.balance);
    }

    /// @inheritdoc IAgreementFramework
    /// @dev Approve tokens & transfer on the same transaction by permit.
    function joinAgreementWithPermit(
        bytes32 id,
        CriteriaResolver calldata resolver,
        Permit calldata permit
    ) external override {
        _canJoinAgreement(id, resolver);

        collateralToken.permit(
            msg.sender,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        SafeTransferLib.safeTransferFrom(
            collateralToken,
            msg.sender,
            address(this),
            resolver.balance
        );

        _addPosition(id, PositionParams(msg.sender, resolver.balance));
        totalBalance += resolver.balance;

        emit AgreementJoined(id, msg.sender, resolver.balance);
    }

    /// @inheritdoc IAgreementFramework
    /// @dev Requires the caller to be part of the agreement and not have finalized before.
    /// @dev Can't be perform on disputed agreements.
    function finalizeAgreement(bytes32 id) external override {
        if (agreement[id].disputed) revert AgreementIsDisputed();
        if (!_isPartOfAgreement(id, msg.sender)) revert NoPartOfAgreement();
        if (agreement[id].position[msg.sender].status == PositionStatus.Finalized)
            revert PartyAlreadyFinalized();

        agreement[id].position[msg.sender].status = PositionStatus.Finalized;
        agreement[id].finalizations += 1;

        emit AgreementPositionUpdated(
            id,
            msg.sender,
            agreement[id].position[msg.sender].balance,
            PositionStatus.Finalized
        );

        if (_isFinalized(id)) emit AgreementFinalized(id);
    }

    /// @inheritdoc IAgreementFramework
    function disputeAgreement(bytes32 id) external override {
        _canDisputeAgreement(id);

        SafeTransferLib.safeTransferFrom(feeToken, msg.sender, feeRecipient, fee);

        agreement[id].disputed = true;

        emit AgreementDisputed(id, msg.sender);
    }

    /// @inheritdoc IAgreementFramework
    function disputeAgreementWithPermit(bytes32 id, Permit calldata permit) external override {
        _canDisputeAgreement(id);

        feeToken.permit(
            msg.sender,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        SafeTransferLib.safeTransferFrom(feeToken, msg.sender, feeRecipient, fee);

        agreement[id].disputed = true;

        emit AgreementDisputed(id, msg.sender);
    }

    /// @notice Withdraw your position from the agreement.
    /// @inheritdoc IAgreementFramework
    /// @dev Requires the caller to be part of the agreement.
    /// @dev Requires the agreement to be finalized.
    /// @dev Draw funds from the position of the caller.
    function withdrawFromAgreement(bytes32 id) external override {
        if (!_isFinalized(id)) revert AgreementNotFinalized();
        if (!_isPartOfAgreement(id, msg.sender)) revert NoPartOfAgreement();

        uint256 withdrawBalance = agreement[id].position[msg.sender].balance;
        agreement[id].position[msg.sender].balance = 0;
        totalBalance -= withdrawBalance;

        SafeTransferLib.safeTransfer(collateralToken, msg.sender, withdrawBalance);

        emit AgreementPositionUpdated(id, msg.sender, 0, agreement[id].position[msg.sender].status);
    }

    /// @dev Check if caller can join an agreement with the criteria resolver provided.
    /// @param id Id of the agreement to check.
    /// @param resolver Criteria resolver to check against criteria.
    function _canJoinAgreement(bytes32 id, CriteriaResolver calldata resolver) internal view {
        if (agreement[id].disputed) revert AgreementIsDisputed();
        if (_isFinalized(id)) revert AgreementIsFinalized();
        if (_isPartOfAgreement(id, msg.sender)) revert PartyAlreadyJoined();
        if (msg.sender != resolver.account) revert PartyMustMatchCriteria();

        _validateCriteria(agreement[id].criteria, resolver);
    }

    /// @dev Check if caller can dispute an agreement.
    /// @dev Requires the caller to be part of the agreement.
    /// @dev Can be perform only once per agreement.
    /// @param id Id of the agreement to check.
    function _canDisputeAgreement(bytes32 id) internal view returns (bool) {
        if (agreement[id].disputed) revert AgreementIsDisputed();
        if (_isFinalized(id)) revert AgreementIsFinalized();
        if (!_isPartOfAgreement(id, msg.sender)) revert NoPartOfAgreement();
        return true;
    }

    /// @dev Check if an agreement is finalized.
    /// @dev An agreement is finalized when all positions are finalized.
    /// @param id Id of the agreement to check.
    /// @return A boolean signaling if the agreement is finalized or not.
    function _isFinalized(bytes32 id) internal view returns (bool) {
        return (agreement[id].party.length > 0 &&
            agreement[id].finalizations >= agreement[id].party.length);
    }

    /// @dev Check if an account is part of an agreement.
    /// @param id Id of the agreement to check.
    /// @param account Account to check.
    /// @return A boolean signaling if the account is part of the agreement or not.
    function _isPartOfAgreement(bytes32 id, address account) internal view returns (bool) {
        return ((agreement[id].party.length > 0) &&
            (agreement[id].party[agreement[id].position[account].id] == account));
    }

    /// @dev Add a new position to an existent agreement.
    /// @param agreementId Id of the agreement to update.
    /// @param params Struct of the position params to add.
    function _addPosition(bytes32 agreementId, PositionParams memory params) internal {
        uint256 partyId = agreement[agreementId].party.length;
        agreement[agreementId].party.push(params.party);
        agreement[agreementId].position[params.party] = Position(
            partyId,
            params.balance,
            PositionStatus.Joined
        );
        agreement[agreementId].balance += params.balance;
    }

    /* ====================================================================== */
    /*                              IArbitrable
    /* ====================================================================== */

    /// Finalize an agreement with a settlement.
    /// @inheritdoc IArbitrable
    /// @dev Update the agreement's positions with the settlement and finalize the agreement.
    /// @dev The dispute id must match an agreement in dispute.
    /// @dev Requires the caller to be the arbitrator.
    /// @dev Requires that settlement includes all previous positions
    /// @dev Requires that settlement match total balance of the agreement.
    /// @dev Allows the arbitrator to add new positions.
    function settleDispute(bytes32 id, PositionParams[] calldata settlement) external override {
        if (msg.sender != arbitrator) revert OnlyArbitrator();
        if (_isFinalized(id)) revert AgreementIsFinalized();
        if (!agreement[id].disputed) revert AgreementNotDisputed();

        uint256 positionsLength = settlement.length;
        uint256 newBalance;

        if (positionsLength != agreement[id].party.length) revert PositionsMustMatch();
        for (uint256 i = 0; i < positionsLength; i++) {
            // Revert if previous positions parties do not match.
            if (agreement[id].party[i] != settlement[i].party) revert PositionsMustMatch();

            // Update position params from settlement.
            agreement[id].position[settlement[i].party] = Position(
                i,
                settlement[i].balance,
                PositionStatus.Finalized
            );

            newBalance += settlement[i].balance;

            emit AgreementPositionUpdated(
                id,
                settlement[i].party,
                settlement[i].balance,
                PositionStatus.Finalized
            );
        }

        if (newBalance != agreement[id].balance) revert BalanceMustMatch();

        // Finalize agreement.
        agreement[id].finalizations = positionsLength;
        emit AgreementFinalized(id);
    }

    /* ====================================================================== */
    /*                                 FEE COLLECTOR
    /* ====================================================================== */

    /// @inheritdoc FeeCollector
    function setFee(
        ERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyOwner {
        _setFee(token, recipient, amount);
    }

    /// @inheritdoc FeeCollector
    /// @dev Prevents collecting deposited collateral as fees.
    /// @dev As this implementation send dispute fees directly to the feeRecipient the only tokens that would be collected as fee are tokens sent to the contract by error.
    function collectFees() external override {
        if (feeRecipient == address(0)) revert InvalidRecipient();
        uint256 amount = feeToken.balanceOf(address(this));

        if (feeToken == collateralToken) amount -= totalBalance;

        _withdraw(feeToken, feeRecipient, amount);
    }

    /// @notice Withdraw any ERC20 from the contract.
    /// @param token Token to withdraw.
    /// @param to Recipient address.
    /// @param amount Amount of tokens to withdraw.
    /// @dev Prevents withdrawing deposited collateral.
    function withdrawTokens(
        ERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        if (token == collateralToken) {
            uint256 available = token.balanceOf(address(this)) - totalBalance;
            if (amount > available) revert InsufficientBalance();
        }

        _withdraw(token, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;
import {
    AgreementStatus,
    AgreementParams,
    AgreementPosition,
    PositionParams,
    PositionStatus
} from "../lib/AgreementStructs.sol";
import { CriteriaResolver } from "../lib/CriteriaResolution.sol";
import { Permit } from "../lib/Permit.sol";
import { IArbitrable } from "./IArbitrable.sol";

/// @notice Interface for agreements frameworks.
/// @dev Implementations must write the logic to manage individual agreements.
interface IAgreementFramework is IArbitrable {
    /* ====================================================================== //
                                        EVENTS
    // ====================================================================== */

    /// @dev Raised when a new agreement is created.
    /// @param id Id of the new created agreement.
    /// @param termsHash Hash of the detailed terms of the agreement.
    /// @param criteria Criteria requirements to join the agreement.
    /// @param metadataURI URI of the metadata of the agreement.
    event AgreementCreated(bytes32 id, bytes32 termsHash, uint256 criteria, string metadataURI);

    /// @dev Raised when a new party joins an agreement.
    /// @param id Id of the agreement joined.
    /// @param party Address of party joined.
    /// @param balance Balance of the party joined.
    event AgreementJoined(bytes32 id, address party, uint256 balance);

    /// @dev Raised when an existing party of an agreement updates its position.
    /// @param id Id of the agreement updated.
    /// @param party Address of the party updated.
    /// @param balance New balance of the party.
    /// @param status New status of the position.
    event AgreementPositionUpdated(
        bytes32 id,
        address party,
        uint256 balance,
        PositionStatus status
    );

    /// @dev Raised when an agreement is finalized.
    /// @param id Id of the agreement finalized.
    event AgreementFinalized(bytes32 id);

    /// @dev Raised when an agreement is in dispute.
    /// @param id Id of the agreement in dispute.
    /// @param party Address of the party that raises the dispute.
    event AgreementDisputed(bytes32 id, address party);

    /* ====================================================================== //
                                        ERRORS
    // ====================================================================== */

    error NonExistentAgreement();
    error InsufficientBalance();
    error NoPartOfAgreement();
    error PartyAlreadyJoined();
    error PartyAlreadyFinalized();
    error PartyMustMatchCriteria();
    error AgreementIsDisputed();
    error AgreementIsFinalized();
    error AgreementNotFinalized();
    error AgreementNotDisputed();

    /* ====================================================================== //
                                        VIEWS
    // ====================================================================== */

    /// @notice Retrieve general parameters of an agreement.
    /// @param id Id of the agreement to return data from.
    /// @return AgreementParams struct with the parameters of the agreement.
    function agreementParams(bytes32 id) external view returns (AgreementParams memory);

    /// @notice Retrieve positions of an agreement.
    /// @param id Id of the agreement to return data from.
    /// @return Array of the positions of the agreement.
    function agreementPositions(bytes32 id) external view returns (AgreementPosition[] memory);

    /// @notice Retrieve the status of an agreement.
    /// @param id Id of the the agreement to return status from.
    /// @return AgreementStatus enum value.
    function agreementStatus(bytes32 id) external view returns (AgreementStatus);

    /* ====================================================================== //
                                    USER ACTIONS
    // ====================================================================== */

    /// @notice Create a new agreement with given params.
    /// @param params Struct of agreement params.
    /// @return id Id of the agreement created.
    function createAgreement(AgreementParams calldata params) external returns (bytes32 id);

    /// @notice Join an existing agreement.
    /// @dev Requires a deposit over agreement criteria.
    /// @param id Id of the agreement to join.
    /// @param resolver Criteria data to prove sender can join agreement.
    function joinAgreement(bytes32 id, CriteriaResolver calldata resolver) external;

    /// @notice Join an existing agreement with EIP-2612 permit.
    ///         Allow to approve and transfer funds on the same transaction.
    /// @param id Id of the agreement to join.
    /// @param resolver Criteria data to prove sender can join agreement.
    /// @param permit EIP-2612 permit data to approve transfer of tokens.
    function joinAgreementWithPermit(
        bytes32 id,
        CriteriaResolver calldata resolver,
        Permit calldata permit
    ) external;

    /// @notice Signal the will of the caller to finalize an agreement.
    /// @param id Id of the agreement to settle.
    function finalizeAgreement(bytes32 id) external;

    /// @notice Raise a dispute over an agreement.
    /// @param id Id of the agreement to dispute.
    function disputeAgreement(bytes32 id) external;

    /// @notice Raise a dispute over an agreement with EIP-2612 permit for posible fees.
    /// @param id Id of the agreement to dispute.
    /// @param permit EIP-2612 permit data to approve transfer of tokens.
    function disputeAgreementWithPermit(bytes32 id, Permit calldata permit) external;

    /// @notice Withdraw your position from the agreement.
    /// @param id Id of the agreement to withdraw from.
    function withdrawFromAgreement(bytes32 id) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./common/MurkyBase.sol";

/// @notice Nascent, simple, kinda efficient (and improving!) Merkle proof generator and verifier
/// @author dmfxyz
/// @dev Note Generic Merkle Tree
contract Merkle is MurkyBase {

    /********************
    * HASHING FUNCTION *
    ********************/

    /// ascending sort and concat prior to hashing
    function hashLeafPairs(bytes32 left, bytes32 right) public pure override returns (bytes32 _hash) {
       assembly {
           switch lt(left, right)
           case 0 {
               mstore(0x0, right)
               mstore(0x20, left)
           }
           default {
               mstore(0x0, left)
               mstore(0x20, right)
           }
           _hash := keccak256(0x0, 0x40)
       }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract MurkyBase {
    /***************
    * CONSTRUCTOR *
    ***************/
    constructor() {}

    /********************
    * VIRTUAL HASHING FUNCTIONS *
    ********************/
    function hashLeafPairs(bytes32 left, bytes32 right) public pure virtual returns (bytes32 _hash);


    /**********************
    * PROOF VERIFICATION *
    **********************/
    
    function verifyProof(bytes32 root, bytes32[] memory proof, bytes32 valueToProve) external pure returns (bool) {
        // proof length must be less than max array size
        bytes32 rollingHash = valueToProve;
        uint256 length = proof.length;
        unchecked {
            for(uint i = 0; i < length; ++i){
                rollingHash = hashLeafPairs(rollingHash, proof[i]);
            }
        }
        return root == rollingHash;
    }

    /********************
    * PROOF GENERATION *
    ********************/

    function getRoot(bytes32[] memory data) public pure returns (bytes32) {
        require(data.length > 1, "won't generate root for single leaf");
        while(data.length > 1) {
            data = hashLevel(data);
        }
        return data[0];
    }

    function getProof(bytes32[] memory data, uint256 node) public pure returns (bytes32[] memory) {
        require(data.length > 1, "won't generate proof for single leaf");
        // The size of the proof is equal to the ceiling of log2(numLeaves) 
        bytes32[] memory result = new bytes32[](log2ceilBitMagic(data.length));
        uint256 pos = 0;

        // Two overflow risks: node, pos
        // node: max array size is 2**256-1. Largest index in the array will be 1 less than that. Also,
           // for dynamic arrays, size is limited to 2**64-1
        // pos: pos is bounded by log2(data.length), which should be less than type(uint256).max
        while(data.length > 1) {
            unchecked {
                if(node & 0x1 == 1) {
                    result[pos] = data[node - 1];
                } 
                else if (node + 1 == data.length) {
                    result[pos] = bytes32(0);  
                } 
                else {
                    result[pos] = data[node + 1];
                }
                ++pos;
                node /= 2;
            }
            data = hashLevel(data);
        }
        return result;
    }

    ///@dev function is private to prevent unsafe data from being passed
    function hashLevel(bytes32[] memory data) private pure returns (bytes32[] memory) {
        bytes32[] memory result;

        // Function is private, and all internal callers check that data.length >=2.
        // Underflow is not possible as lowest possible value for data/result index is 1
        // overflow should be safe as length is / 2 always. 
        unchecked {
            uint256 length = data.length;
            if (length & 0x1 == 1){
                result = new bytes32[](length / 2 + 1);
                result[result.length - 1] = hashLeafPairs(data[length - 1], bytes32(0));
            } else {
                result = new bytes32[](length / 2);
        }
        // pos is upper bounded by data.length / 2, so safe even if array is at max size
            uint256 pos = 0;
            for (uint256 i = 0; i < length-1; i+=2){
                result[pos] = hashLeafPairs(data[i], data[i+1]);
                ++pos;
            }
        }
        return result;
    }

    /******************
    * MATH "LIBRARY" *
    ******************/
    
    /// @dev  Note that x is assumed > 0
    function log2ceil(uint256 x) public pure returns (uint256) {
        uint256 ceil = 0;
        uint pOf2;
        // If x is a power of 2, then this function will return a ceiling
        // that is 1 greater than the actual ceiling. So we need to check if
        // x is a power of 2, and subtract one from ceil if so. 
        assembly {
            // we check by seeing if x == (~x + 1) & x. This applies a mask
            // to find the lowest set bit of x and then checks it for equality
            // with x. If they are equal, then x is a power of 2.

            /* Example
                x has single bit set
                x := 0000_1000
                (~x + 1) = (1111_0111) + 1 = 1111_1000
                (1111_1000 & 0000_1000) = 0000_1000 == x

                x has multiple bits set
                x := 1001_0010
                (~x + 1) = (0110_1101 + 1) = 0110_1110
                (0110_1110 & x) = 0000_0010 != x
            */

            // we do some assembly magic to treat the bool as an integer later on
            pOf2 := eq(and(add(not(x), 1), x), x)
        }
        
        // if x == type(uint256).max, than ceil is capped at 256
        // if x == 0, then pO2 == 0, so ceil won't underflow
        unchecked {
            while( x > 0) {
                x >>= 1;
                ceil++;
            }
            ceil -= pOf2; // see above
        }
        return ceil;
    }

    /// Original bitmagic adapted from https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
    /// @dev Note that x assumed > 1
    function log2ceilBitMagic(uint256 x) public pure returns (uint256){
        if (x <= 1) {
            return 0;
        }
        uint256 msb = 0;
        uint256 _x = x;
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            msb += 1;
        }

        uint256 lsb = (~_x + 1) & _x;
        if ((lsb == _x) && (msb > 0)) {
            return msb;
        } else {
            return msb + 1;
        }
    }
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

/// @dev Data structure to prove membership to a criteria tree.
///      Account and balance are used to encode the leaf.
struct CriteriaResolver {
    address account;
    uint256 balance;
    bytes32[] proof;
}

/// @dev Methods to verify membership to a criteria Merkle tree.
contract CriteriaResolution {

    error InvalidProof();

    /// @dev Check that given resolver is valid for the provided criteria.
    /// @param criteria Root of the Merkle tree.
    /// @param resolver Struct with the required params to prove membership to the tree.
    function _validateCriteria(uint256 criteria, CriteriaResolver calldata resolver) internal pure {
        // Encode the leaf from the (account, balance) pair.
        bytes32 leaf = keccak256(abi.encode(resolver.account, resolver.balance));

        bool isValid = _verifyProof(
            resolver.proof,
            bytes32(criteria),
            leaf
        );

        if (!isValid)
            revert InvalidProof();
    }

    /// @dev Based on Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
    ///      Verify proofs for given root and leaf are correct.
    function _verifyProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            let computedHash := leaf // The hash starts as the leaf hash.

            // Initialize data to the offset of the proof in the calldata.
            let data := proof.offset

            // Iterate over proof elements to compute root hash.
            for {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(data, shl(5, proof.length))
            } lt(data, end) {
                data := add(data, 32) // Shift 1 word per cycle.
            } {
                // Load the current proof element.
                let loadedData := calldataload(data)

                // Slot where computedHash should be put in scratch space.
                // If computedHash > loadedData: slot 32, otherwise: slot 0.
                let computedHashSlot := shl(5, gt(computedHash, loadedData))

                // Store elements to hash contiguously in scratch space.
                // The xor puts loadedData in whichever slot computedHash is
                // not occupying, so 0 if computedHashSlot is 32, 32 otherwise.
                mstore(computedHashSlot, computedHash)
                mstore(xor(computedHashSlot, 32), loadedData)

                computedHash := keccak256(0, 64) // Hash both slots of scratch space.
            }

            isValid := eq(computedHash, root) // The proof is valid if the roots match.
        }
    }
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