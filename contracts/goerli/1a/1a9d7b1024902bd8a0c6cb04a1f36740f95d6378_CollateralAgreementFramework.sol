/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

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

enum PositionStatus {
    Idle,
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
    /// @dev Total balance deposited in the agreement.
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
}

/// @dev Adapter of agreement params for functions I/O.
struct PositionParams {
    /// @dev Holder of the position.
    address party;
    /// @dev Amount of tokens corresponding to this position.
    uint256 balance;
}

struct CriteriaResolver {
    address party;
    uint256 balance;
    bytes32[] criteriaProof;
}

contract CriteriaResolution {

    error InvalidProof();

    function _validateCriteria(uint256 criteria, CriteriaResolver calldata criteriaResolver) internal pure {
        bytes32 leaf = keccak256(abi.encode(criteriaResolver.party, criteriaResolver.balance));
        bool isValid = _verifyProof(
            criteriaResolver.criteriaProof,
            bytes32(criteria),
            leaf
        );
        if (!isValid)
            revert InvalidProof();
    }

    /// @dev Based on Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
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

/// @notice Interface for arbitrable contracts.
/// @dev Implementers must write the logic to raise and settle disputes.
interface IArbitrable {

    error OnlyArbitrator();

    /// @notice Address capable of settling disputes.
    function arbitrator() external view returns (address);

    /// @notice Settles a dispute providing settlement positions.
    /// @param id Id of the dispute to settle.
    /// @param settlement Array of final positions.
    function settleDispute(uint256 id, PositionParams[] calldata settlement) external;
}

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
    event AgreementCreated(uint256 id, bytes32 termsHash, uint256 criteria);

    /// @dev Raised when a new party joins an agreement.
    /// @param id Id of the agreement joined.
    /// @param party Address of party joined.
    /// @param balance Balance of the party joined.
    event AgreementJoined(uint256 id, address party, uint256 balance);

    /// @dev Raised when an existent party of an agreement updates its position.
    /// @param id Id of the agreement updated.
    /// @param party Address of the party updated.
    /// @param balance New balance of the party.
    /// @param status New status of the position.
    event AgreementPositionUpdated(
        uint256 id,
        address party,
        uint256 balance,
        PositionStatus status
    );

    /// @dev Raised when an agreement is finalized.
    /// @param id Id of the agreement finalized.
    event AgreementFinalized(uint256 id);

    /// @dev Raised when an agreement is in dispute.
    /// @param id Id of the agreement in dispute.
    /// @param party Address of the party that raises the dispute.
    event AgreementDisputed(uint256 id, address party);

    /* ====================================================================== //
                                        ERRORS
    // ====================================================================== */

    error NonExistentAgreement();
    error InsufficientBalance();
    error NoPartOfAgreement();
    error PartyAlreadyJoined();
    error PartyAlreadyFinalized();
    error PartyMustMatchCriteria();
    error AgreementAlreadyDisputed();
    error AgreementNotFinalized();
    error AgreementNotDisputed();

    /* ====================================================================== //
                                        VIEWS
    // ====================================================================== */

    /// @notice Retrieve general parameters of an agreement.
    /// @param id Id of the agreement to return data from.
    /// @return AgreementParams struct with the parameters of the agreement.
    function agreementParams(uint256 id) external view returns (AgreementParams memory);

    /// @notice Retrieve positions of an agreement.
    /// @param id Id of the agreement to return data from.
    /// @return Array of PositionParams with all the positions of the agreement.
    function agreementPositions(uint256 id) external view returns (PositionParams[] memory);

    /* ====================================================================== //
                                    USER ACTIONS
    // ====================================================================== */

    /// @notice Create a new agreement with given params.
    /// @param params Struct of agreement params.
    /// @return id Id of the agreement created.
    function createAgreement(AgreementParams calldata params) external returns (uint256 id);

    /// @notice Join an existent agreement.
    /// @dev Requires a deposit over agreement criteria.
    /// @param id Id of the agreement to join.
    /// @param criteriaResolver Criteria data to proof sender can join agreement.
    function joinAgreement(uint256 id, CriteriaResolver calldata criteriaResolver) external;

    /// @notice Signal the will of the caller to finalize an agreement.
    /// @param id Id of the agreement to settle.
    function finalizeAgreement(uint256 id) external;

    /// @notice Dispute agreement so arbitration is needed for finalization.
    /// @param id Id of the agreement to dispute.
    function disputeAgreement(uint256 id) external;

    /// @notice Withdraw your position from the agreement.
    /// @param id Id of the agreement to withdraw from.
    function withdrawFromAgreement(uint256 id) external;
}

/// @notice Framework to create collateral agreements.
contract CollateralAgreementFramework is IAgreementFramework, CriteriaResolution {
    /* ====================================================================== //
                                        ERRORS
    // ====================================================================== */

    error MissingPositions();
    error PositionsMustMatch();
    error SettlementBalanceMustMatch();

    /* ====================================================================== //
                                        STORAGE
    // ====================================================================== */

    /// @dev Token used in agreements.
    ERC20 public token;

    /// @dev Address with the power to settle agreements in dispute.
    address public arbitrator;

    /// @dev Map of agreements by id.
    mapping(uint256 => Agreement) public agreement;

    /// @dev Current last agreement index.
    uint256 private _currentIndex;

    /* ====================================================================== //
                                      CONSTRUCTOR
    // ====================================================================== */

    constructor(
        ERC20 token_,
        address arbitrator_
    ) {
        arbitrator = arbitrator_;
        token = token_;
    }

    /* ====================================================================== */
    /*                                  VIEWS
    /* ====================================================================== */
    
    /// Retrieve parameters of an agreement.
    /// @inheritdoc IAgreementFramework
    function agreementParams(uint256 id) external view override returns (
        AgreementParams memory params
    ) {
        params = AgreementParams(agreement[id].termsHash, agreement[id].criteria);
    }

    /// Retrieve positions of an agreement.
    /// @inheritdoc IAgreementFramework
    function agreementPositions(uint256 id) external view override returns (
        PositionParams[] memory
    ) {
        uint256 partyLength = agreement[id].party.length;
        PositionParams[] memory positions = new PositionParams[](partyLength);

        for (uint256 i = 0; i < partyLength; i++) {
            address party = agreement[id].party[i];
            uint256 balance = agreement[id].position[party].balance;

            positions[i] = PositionParams(party, balance);
        }

        return positions;
    }

    /* ====================================================================== */
    /*                                USER LOGIC
    /* ====================================================================== */

    /// Create a new agreement with given params.
    /// @inheritdoc IAgreementFramework
    function createAgreement(AgreementParams calldata params)
        external
        override
        returns (uint256 agreementId)
    {
        agreementId = _currentIndex;

        agreement[agreementId].termsHash = params.termsHash;
        agreement[agreementId].criteria = params.criteria;

        _currentIndex++;

        emit AgreementCreated(agreementId, params.termsHash, params.criteria);
    }

    /// Join an existent agreement.
    /// @inheritdoc IAgreementFramework
    /// @dev Requires that the caller provides a valid criteria resolver.
    function joinAgreement(
        uint256 id,
        CriteriaResolver calldata resolver
    ) external override {
        if (_isPartOfAgreement(id, msg.sender))
            revert PartyAlreadyJoined();
        if (msg.sender != resolver.party)
            revert PartyMustMatchCriteria();

        _validateCriteria(agreement[id].criteria, resolver);

        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), resolver.balance);

        _addPosition(id, PositionParams(msg.sender, resolver.balance));

        emit AgreementJoined(id, msg.sender, resolver.balance);
    }

    /// Signal the will of the caller to finalize an agreement.
    /// @inheritdoc IAgreementFramework
    /// @dev Requires the caller to be part of the agreement and not have finalized before.
    /// @dev Can't be perform on disputed agreements.
    function finalizeAgreement(uint256 id) external override {
        if (agreement[id].disputed)
            revert AgreementAlreadyDisputed();
        if (!_isPartOfAgreement(id, msg.sender))
            revert NoPartOfAgreement();
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

        if (_isFinalized(id))
            emit AgreementFinalized(id);
    }

    /// Raise a dispute over an agreement.
    /// @inheritdoc IAgreementFramework
    /// @dev Requires the caller to be part of the agreement.
    /// @dev Can be perform only once per agreement.
    function disputeAgreement(uint256 id) external override {
        if (agreement[id].disputed)
            revert AgreementAlreadyDisputed();
        if (!_isPartOfAgreement(id, msg.sender))
            revert NoPartOfAgreement();

        agreement[id].disputed = true;

        emit AgreementDisputed(id, msg.sender);
    }

    /// @notice Withdraw your position from the agreement.
    /// @inheritdoc IAgreementFramework
    /// @dev Requires the caller to be part of the agreement.
    /// @dev Requires the agreement to be finalized.
    /// @dev Clear your position balance and transfer funds.
    function withdrawFromAgreement(uint256 id) external override {
        if (!_isFinalized(id))
            revert AgreementNotFinalized();
        if (!_isPartOfAgreement(id, msg.sender))
            revert NoPartOfAgreement();

        uint256 withdrawBalance = agreement[id].position[msg.sender].balance;
        agreement[id].position[msg.sender].balance = 0;

        SafeTransferLib.safeTransfer(token, msg.sender, withdrawBalance);

        emit AgreementPositionUpdated(
            id,
            msg.sender,
            0,
            agreement[id].position[msg.sender].status
        );
    }

    /// @dev Check if an agreement is finalized.
    /// @dev An agreement is finalized when all positions are finalized.
    /// @param id Id of the agreement to check.
    /// @return A boolean signaling if the agreement is finalized or not.
    function _isFinalized(uint256 id) internal view returns (bool) {
        return agreement[id].finalizations >= agreement[id].party.length;
    }

    /// @dev Check if an account is part of an agreement.
    /// @param id Id of the agreement to check.
    /// @param account Account to check.
    /// @return A boolean signaling if the account is part of the agreement or not.
    function _isPartOfAgreement(uint256 id, address account) internal view returns (bool) {
        return (
            (agreement[id].party.length > 0)
            && (agreement[id].party[agreement[id].position[account].id] == account)
        );
    }

    /// @dev Add a new position to an existent agreement.
    /// @param agreementId Id of the agreement to update.
    /// @param params Struct of the position params to add.
    function _addPosition(uint256 agreementId, PositionParams memory params) internal {
        uint256 partyId = agreement[agreementId].party.length;
        agreement[agreementId].party.push(params.party);
        agreement[agreementId].position[params.party] = Position(
            partyId,
            params.balance,
            PositionStatus.Idle
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
    function settleDispute(uint256 id, PositionParams[] calldata settlement) external override {
        if (msg.sender != arbitrator)
            revert OnlyArbitrator();
        if (!agreement[id].disputed)
            revert AgreementNotDisputed();

        uint256 positionsLength = settlement.length;
        uint256 newBalance;

        if (positionsLength < agreement[id].party.length)
            revert MissingPositions();
        for (uint256 i = 0; i < positionsLength; i++) {
            // Revert if previous positions parties do not match.
            if ((i < agreement[id].party.length)
                && (agreement[id].party[i] != settlement[i].party))
                revert PositionsMustMatch();

            // Add new parties to the agreement if needed.
            if (i >= agreement[id].party.length)
                agreement[id].party.push(settlement[i].party);

            // Update / Add position params from settlement.
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

        if (newBalance != agreement[id].balance)
            revert SettlementBalanceMustMatch();

        // Finalize agreement.
        agreement[id].finalizations = positionsLength;

        emit AgreementFinalized(id);
    }

}