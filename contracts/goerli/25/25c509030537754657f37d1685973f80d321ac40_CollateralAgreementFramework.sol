// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IAllowanceTransfer } from "permit2/src/interfaces/IAllowanceTransfer.sol";
import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";

import { Permit2 } from "permit2/src/Permit2.sol";
import { Permit2Lib } from "permit2/src/libraries/Permit2Lib.sol";
import { ERC20 } from "solmate/src/tokens/ERC20.sol";
import { ReentrancyGuard } from "solmate/src/utils/ReentrancyGuard.sol";
import { SafeTransferLib } from "solmate/src/utils/SafeTransferLib.sol";

import {
    AgreementData,
    AgreementParams,
    AgreementStatus,
    PositionData,
    PositionParams,
    PositionStatus
} from "src/interfaces/AgreementTypes.sol";
import "src/interfaces/AgreementErrors.sol";
import {
    SettlementPositionsMustMatch,
    SettlementBalanceMustMatch
} from "src/interfaces/ArbitrationErrors.sol";
import { IAgreementFramework } from "src/interfaces/IAgreementFramework.sol";
import { IArbitrable, OnlyArbitrator } from "src/interfaces/IArbitrable.sol";

import { AgreementFramework } from "src/frameworks/AgreementFramework.sol";
import { CriteriaResolver, CriteriaResolution } from "src/libraries/CriteriaResolution.sol";
import { DepositConfig } from "src/utils/interfaces/Deposits.sol";
import { Owned } from "src/utils/Owned.sol";

/// @notice Data structure for positions in the agreement.
struct Position {
    /// @dev Address of the owner of the position.
    address party;
    /// @dev Amount of agreement tokens in the position.
    uint256 balance;
    /// @dev Amount of tokens deposited for dispute costs.
    uint256 deposit;
    /// @dev Status of the position.
    PositionStatus status;
}

/// @dev Data estructure for collateral agreements.
struct Agreement {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
    /// @dev ERC20 token to use as collateral.
    address token;
    /// @dev Total amount of collateral tokens deposited in the agreement.
    uint256 balance;
    /// @dev Number of finalizations.
    uint256 finalizations;
    /// @dev Signal if agreement is disputed.
    bool disputed;
    /// @dev List of parties involved in the agreement.
    address[] party;
    /// @dev Position by party.
    mapping(address => Position) position;
}

contract CollateralAgreementFramework is AgreementFramework, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using Permit2Lib for ERC20;

    /// @notice Address of the Permit2 contract deployment.
    Permit2 public immutable permit2;

    /// @notice Dispute deposits configuration.
    DepositConfig public deposits;

    /// @dev Agreements by id
    mapping(bytes32 => Agreement) internal agreement;

    /* ====================================================================== */
    /*                                  VIEWS
    /* ====================================================================== */

    /// @notice Retrieve basic data of an agreement.
    /// @param id Id of the agreement to return data from.
    /// @return data Data struct of the agreement.
    function agreementData(bytes32 id) external view returns (AgreementData memory data) {
        Agreement storage agreement_ = agreement[id];

        data = AgreementData(
            agreement_.termsHash,
            agreement_.criteria,
            agreement_.metadataURI,
            agreement_.token,
            agreement_.balance,
            _agreementStatus(agreement_)
        );
    }

    /// @notice Retrieve positions of an agreement.
    /// @param id Id of the agreement to return data from.
    /// @return Array of the positions of the agreement in PositionData structs.
    function agreementPositions(bytes32 id) external view returns (PositionData[] memory) {
        Agreement storage agreement_ = agreement[id];
        uint256 partyLength = agreement_.party.length;
        PositionData[] memory positions = new PositionData[](partyLength);

        for (uint256 i = 0; i < partyLength; i++) {
            address party = agreement_.party[i];
            Position memory position = agreement_.position[party];
            positions[i] = PositionData(position.party, position.balance, position.status);
        }

        return positions;
    }

    /* ====================================================================== */
    /*                                  SETUP
    /* ====================================================================== */

    constructor(Permit2 permit2_, address owner) Owned(owner) {
        permit2 = permit2_;
    }

    /// @notice Set up framework params;
    /// @param arbitrator_ Address allowed to settle disputes.
    /// @param deposits_ Configuration of the framework's deposits in DepositConfig format.
    function setUp(address arbitrator_, DepositConfig calldata deposits_) external onlyOwner {
        deposits = deposits_;
        arbitrator = arbitrator_;

        emit ArbitrationTransferred(arbitrator_);
    }

    /* ====================================================================== */
    /*                                USER LOGIC
    /* ====================================================================== */

    /// @notice Create a new collateral agreement with given params.
    /// @param params Struct of agreement params.
    /// @param salt Extra bytes to avoid collisions between agreements with the same terms hash in the framework.
    /// @return id Id of the agreement created, generated from encoding hash of the address of the framework, hash of the terms and a provided salt.
    function createAgreement(
        AgreementParams calldata params,
        bytes32 salt
    ) external returns (bytes32 id) {
        if (params.criteria == 0) revert InvalidCriteria();

        id = keccak256(abi.encode(address(this), params.termsHash, salt));
        Agreement storage newAgreement = agreement[id];

        if (newAgreement.criteria != 0) revert AlreadyExistentAgreement();

        newAgreement.termsHash = params.termsHash;
        newAgreement.criteria = params.criteria;
        newAgreement.metadataURI = params.metadataURI;
        newAgreement.token = params.token;

        emit AgreementCreated(
            id,
            params.termsHash,
            params.criteria,
            params.metadataURI,
            params.token
        );
    }

    /// @inheritdoc IAgreementFramework
    function joinAgreement(
        bytes32 id,
        CriteriaResolver calldata resolver,
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes calldata signature
    ) external override nonReentrant {
        Agreement storage agreement_ = agreement[id];

        _canJoinAgreement(agreement_, resolver, msg.sender);

        DepositConfig memory deposit = deposits;

        // validate permit tokens & generate transfer details
        if (permit.permitted[0].token != deposit.token) revert InvalidPermit();
        if (permit.permitted[1].token != agreement_.token) revert InvalidPermit();
        ISignatureTransfer.SignatureTransferDetails[] memory transferDetails = _joinTransferDetails(
            resolver.balance,
            deposit.amount
        );

        permit2.permitTransferFrom(permit, transferDetails, msg.sender, signature);

        _addPosition(agreement_, PositionParams(msg.sender, resolver.balance), deposit.amount);

        emit AgreementJoined(id, msg.sender, resolver.balance);
    }

    /// @inheritdoc IAgreementFramework
    function joinAgreementApproved(
        bytes32 id,
        CriteriaResolver calldata resolver
    ) external override nonReentrant {
        Agreement storage agreement_ = agreement[id];

        _canJoinAgreement(agreement_, resolver, msg.sender);

        DepositConfig memory deposit = deposits;

        // transfer deposit & collateral tokens
        ERC20(deposit.token).transferFrom2(msg.sender, address(this), deposit.amount);
        ERC20(agreement_.token).transferFrom2(msg.sender, address(this), resolver.balance);

        _addPosition(agreement_, PositionParams(msg.sender, resolver.balance), deposit.amount);

        emit AgreementJoined(id, msg.sender, resolver.balance);
    }

    /// @inheritdoc IAgreementFramework
    /// @notice Only allows to increase the collateral of a joined position.
    function adjustPosition(
        bytes32 id,
        PositionParams calldata newPosition,
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature
    ) external override nonReentrant {
        Agreement storage agreement_ = agreement[id];

        _isOngoing(agreement_);
        if (!_isPartOfAgreement(agreement_, newPosition.party)) revert NoPartOfAgreement();

        Position memory lastPosition = agreement_.position[newPosition.party];
        if (lastPosition.status == PositionStatus.Finalized) revert PartyAlreadyFinalized();
        if (lastPosition.balance > newPosition.balance) revert InvalidBalance();
        uint256 diff = newPosition.balance - lastPosition.balance;

        // validate permit tokens & generate transfer details
        if (permit.permitted.token != agreement_.token) revert InvalidPermit();
        ISignatureTransfer.SignatureTransferDetails memory transferDetails = ISignatureTransfer
            .SignatureTransferDetails(address(this), diff);

        permit2.permitTransferFrom(permit, transferDetails, msg.sender, signature);

        _updatePosition(agreement_, newPosition, lastPosition.status);

        emit AgreementPositionUpdated(
            id,
            newPosition.party,
            newPosition.balance,
            lastPosition.status
        );
    }

    /// @inheritdoc IAgreementFramework
    function finalizeAgreement(bytes32 id) external {
        Agreement storage agreement_ = agreement[id];

        _isOngoing(agreement_);
        if (!_isPartOfAgreement(agreement_, msg.sender)) revert NoPartOfAgreement();
        if (agreement_.position[msg.sender].status == PositionStatus.Finalized) {
            revert PartyAlreadyFinalized();
        }

        agreement_.position[msg.sender].status = PositionStatus.Finalized;
        agreement_.finalizations += 1;

        emit AgreementPositionUpdated(
            id,
            msg.sender,
            agreement_.position[msg.sender].balance,
            PositionStatus.Finalized
        );

        if (_isFinalized(agreement_)) emit AgreementFinalized(id);
    }

    /// @inheritdoc IAgreementFramework
    function disputeAgreement(bytes32 id) external override {
        Agreement storage agreement_ = agreement[id];

        _isOngoing(agreement_);
        if (!_isPartOfAgreement(agreement_, msg.sender)) revert NoPartOfAgreement();

        DepositConfig memory deposit = deposits;
        Position storage position = agreement_.position[msg.sender];
        uint256 disputeDeposit = position.deposit;

        // update agreement & position
        agreement_.disputed = true;
        position.status = PositionStatus.Disputed;
        position.deposit = 0;

        SafeTransferLib.safeTransfer(ERC20(deposit.token), deposit.recipient, disputeDeposit);

        emit AgreementPositionUpdated(id, msg.sender, position.balance, PositionStatus.Disputed);
        emit AgreementDisputed(id, msg.sender);
    }

    /// @inheritdoc IAgreementFramework
    /// @dev Requires the agreement to be finalized.
    function withdrawFromAgreement(bytes32 id) external override nonReentrant {
        Agreement storage agreement_ = agreement[id];
        DepositConfig memory deposit = deposits;

        if (!_isFinalized(agreement_)) revert AgreementNotFinalized();
        if (!_isPartOfAgreement(agreement_, msg.sender)) revert NoPartOfAgreement();

        Position storage position = agreement_.position[msg.sender];
        uint256 withdrawBalance = position.balance;
        uint256 withdrawDeposit = position.deposit;

        // update position
        position.balance = 0;
        position.deposit = 0;
        position.status = PositionStatus.Withdrawn;

        SafeTransferLib.safeTransfer(ERC20(agreement_.token), msg.sender, withdrawBalance);
        SafeTransferLib.safeTransfer(ERC20(deposit.token), msg.sender, withdrawDeposit);

        emit AgreementPositionUpdated(id, msg.sender, 0, PositionStatus.Withdrawn);
    }

    /* ====================================================================== */
    /*                              Arbitration
    /* ====================================================================== */

    /// @inheritdoc IArbitrable
    /// @dev Allows the arbitrator to finalize an agreement in dispute with the provided set of positions.
    /// @dev The provided settlement parties must match the parties of the agreement and the total balance of the settlement must match the previous agreement balance.
    function settleDispute(bytes32 id, PositionParams[] calldata settlement) external override {
        if (msg.sender != arbitrator) revert OnlyArbitrator();

        Agreement storage agreement_ = agreement[id];
        if (!agreement_.disputed) revert AgreementNotDisputed();
        if (_isFinalized(agreement_)) revert AgreementIsFinalized();

        uint256 positionsLength = settlement.length;
        uint256 newBalance;

        if (positionsLength != agreement_.party.length) revert SettlementPositionsMustMatch();
        for (uint256 i = 0; i < positionsLength; i++) {
            // Revert if previous positions parties do not match.
            if (agreement_.party[i] != settlement[i].party) revert SettlementPositionsMustMatch();

            _updatePosition(agreement_, settlement[i], PositionStatus.Finalized);
            newBalance += settlement[i].balance;

            emit AgreementPositionUpdated(
                id,
                settlement[i].party,
                settlement[i].balance,
                PositionStatus.Finalized
            );
        }

        if (newBalance != agreement_.balance) revert SettlementBalanceMustMatch();

        // Finalize agreement.
        agreement_.finalizations = positionsLength;
        emit AgreementFinalized(id);
    }

    /* ====================================================================== */
    /*                              INTERNAL LOGIC
    /* ====================================================================== */

    /// @dev Retrieve a simplified status of the agreement from its attributes.
    function _agreementStatus(
        Agreement storage agreement_
    ) internal view virtual returns (AgreementStatus) {
        if (agreement_.party.length > 0) {
            if (agreement_.finalizations >= agreement_.party.length) {
                return AgreementStatus.Finalized;
            }
            if (agreement_.disputed) return AgreementStatus.Disputed;
            // else
            return AgreementStatus.Ongoing;
        } else if (agreement_.criteria != 0) {
            return AgreementStatus.Created;
        }
        revert NonExistentAgreement();
    }

    /// @dev Check if the party can join the agreement.
    function _canJoinAgreement(
        Agreement storage agreement_,
        CriteriaResolver calldata resolver,
        address party
    ) internal view {
        _isOngoing(agreement_);
        if (_isPartOfAgreement(agreement_, party)) revert PartyAlreadyJoined();
        if (party != resolver.account) revert InvalidCriteria();
        CriteriaResolution.validateCriteria(bytes32(agreement_.criteria), resolver);
    }

    /// @dev Check if the agreement provided is ongoing (or created).
    function _isOngoing(Agreement storage agreement_) internal view {
        if (agreement_.criteria == 0) revert NonExistentAgreement();
        if (agreement_.disputed) revert AgreementIsDisputed();
        if (_isFinalized(agreement_)) revert AgreementIsFinalized();
    }

    /// @dev Retrieve if an agreement is finalized.
    /// @dev An agreement is finalized when all positions are finalized.
    /// @param agreement_ Agreement to check.
    /// @return A boolean signaling if the agreement is finalized or not.
    function _isFinalized(Agreement storage agreement_) internal view returns (bool) {
        return (agreement_.party.length > 0 && agreement_.finalizations >= agreement_.party.length);
    }

    /// @dev Check if an account is part of an agreement.
    /// @param agreement_ Agreement to check.
    /// @param account Account to check.
    /// @return A boolean signaling if the account is part of the agreement or not.
    function _isPartOfAgreement(
        Agreement storage agreement_,
        address account
    ) internal view returns (bool) {
        return ((agreement_.party.length > 0) && (agreement_.position[account].party == account));
    }

    /// @dev Fill Permit2 transferDetails array for deposit & collateral transfer.
    /// @param collateral Amount of collateral token.
    /// @param deposit Amount of deposits token.
    function _joinTransferDetails(
        uint256 collateral,
        uint256 deposit
    ) internal view returns (ISignatureTransfer.SignatureTransferDetails[] memory transferDetails) {
        transferDetails = new ISignatureTransfer.SignatureTransferDetails[](2);
        transferDetails[0] = ISignatureTransfer.SignatureTransferDetails(address(this), deposit);
        transferDetails[1] = ISignatureTransfer.SignatureTransferDetails(address(this), collateral);
    }

    function _addPosition(
        Agreement storage agreement_,
        PositionParams memory position,
        uint256 deposit
    ) internal {
        // uint256 partyId = agreement_.party.length;
        agreement_.party.push(position.party);
        agreement_.position[position.party] = Position(
            position.party,
            position.balance,
            deposit,
            PositionStatus.Joined
        );
        agreement_.balance += position.balance;
    }

    function _updatePosition(
        Agreement storage agreement_,
        PositionParams memory params,
        PositionStatus status
    ) internal {
        Position storage position = agreement_.position[params.party];
        agreement_.position[params.party] = Position(
            params.party,
            params.balance,
            position.deposit,
            status
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {PermitHash} from "./libraries/PermitHash.sol";
import {SignatureVerification} from "./libraries/SignatureVerification.sol";
import {EIP712} from "./EIP712.sol";
import {IAllowanceTransfer} from "../src/interfaces/IAllowanceTransfer.sol";
import {SignatureExpired, InvalidNonce} from "./PermitErrors.sol";
import {Allowance} from "./libraries/Allowance.sol";

contract AllowanceTransfer is IAllowanceTransfer, EIP712 {
    using SignatureVerification for bytes;
    using SafeTransferLib for ERC20;
    using PermitHash for PermitSingle;
    using PermitHash for PermitBatch;
    using Allowance for PackedAllowance;

    /// @notice Maps users to tokens to spender addresses and information about the approval on the token
    /// @dev Indexed in the order of token owner address, token address, spender address
    /// @dev The stored word saves the allowed amount, expiration on the allowance, and nonce
    mapping(address => mapping(address => mapping(address => PackedAllowance))) public allowance;

    /// @inheritdoc IAllowanceTransfer
    function approve(address token, address spender, uint160 amount, uint48 expiration) external {
        PackedAllowance storage allowed = allowance[msg.sender][token][spender];
        allowed.updateAmountAndExpiration(amount, expiration);
        emit Approval(msg.sender, token, spender, amount, expiration);
    }

    /// @inheritdoc IAllowanceTransfer
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external {
        if (block.timestamp > permitSingle.sigDeadline) revert SignatureExpired(permitSingle.sigDeadline);

        // Verify the signer address from the signature.
        signature.verify(_hashTypedData(permitSingle.hash()), owner);

        _updateApproval(permitSingle.details, owner, permitSingle.spender);
    }

    /// @inheritdoc IAllowanceTransfer
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external {
        if (block.timestamp > permitBatch.sigDeadline) revert SignatureExpired(permitBatch.sigDeadline);

        // Verify the signer address from the signature.
        signature.verify(_hashTypedData(permitBatch.hash()), owner);

        address spender = permitBatch.spender;
        unchecked {
            uint256 length = permitBatch.details.length;
            for (uint256 i = 0; i < length; ++i) {
                _updateApproval(permitBatch.details[i], owner, spender);
            }
        }
    }

    /// @inheritdoc IAllowanceTransfer
    function transferFrom(address from, address to, uint160 amount, address token) external {
        _transfer(from, to, amount, token);
    }

    /// @inheritdoc IAllowanceTransfer
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external {
        unchecked {
            uint256 length = transferDetails.length;
            for (uint256 i = 0; i < length; ++i) {
                AllowanceTransferDetails memory transferDetail = transferDetails[i];
                _transfer(transferDetail.from, transferDetail.to, transferDetail.amount, transferDetail.token);
            }
        }
    }

    /// @notice Internal function for transferring tokens using stored allowances
    /// @dev Will fail if the allowed timeframe has passed
    function _transfer(address from, address to, uint160 amount, address token) private {
        PackedAllowance storage allowed = allowance[from][token][msg.sender];

        if (block.timestamp > allowed.expiration) revert AllowanceExpired(allowed.expiration);

        uint256 maxAmount = allowed.amount;
        if (maxAmount != type(uint160).max) {
            if (amount > maxAmount) {
                revert InsufficientAllowance(maxAmount);
            } else {
                unchecked {
                    allowed.amount = uint160(maxAmount) - amount;
                }
            }
        }

        // Transfer the tokens from the from address to the recipient.
        ERC20(token).safeTransferFrom(from, to, amount);
    }

    /// @inheritdoc IAllowanceTransfer
    function lockdown(TokenSpenderPair[] calldata approvals) external {
        address owner = msg.sender;
        // Revoke allowances for each pair of spenders and tokens.
        unchecked {
            uint256 length = approvals.length;
            for (uint256 i = 0; i < length; ++i) {
                address token = approvals[i].token;
                address spender = approvals[i].spender;

                allowance[owner][token][spender].amount = 0;
                emit Lockdown(owner, token, spender);
            }
        }
    }

    /// @inheritdoc IAllowanceTransfer
    function invalidateNonces(address token, address spender, uint48 newNonce) external {
        uint48 oldNonce = allowance[msg.sender][token][spender].nonce;

        if (newNonce <= oldNonce) revert InvalidNonce();

        // Limit the amount of nonces that can be invalidated in one transaction.
        unchecked {
            uint48 delta = newNonce - oldNonce;
            if (delta > type(uint16).max) revert ExcessiveInvalidation();
        }

        allowance[msg.sender][token][spender].nonce = newNonce;
        emit NonceInvalidation(msg.sender, token, spender, newNonce, oldNonce);
    }

    /// @notice Sets the new values for amount, expiration, and nonce.
    /// @dev Will check that the signed nonce is equal to the current nonce and then incrememnt the nonce value by 1.
    /// @dev Emits a Permit event.
    function _updateApproval(PermitDetails memory details, address owner, address spender) private {
        uint48 nonce = details.nonce;
        address token = details.token;
        uint160 amount = details.amount;
        uint48 expiration = details.expiration;
        PackedAllowance storage allowed = allowance[owner][token][spender];

        if (allowed.nonce != nonce) revert InvalidNonce();

        allowed.updateAll(amount, expiration, nonce);
        emit Permit(owner, token, spender, amount, expiration, nonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice EIP712 helpers for permit2
/// @dev Maintains cross-chain replay protection in the event of a fork
/// @dev Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol
contract EIP712 {
    // Cache the domain separator as an immutable value, but also store the chain id that it
    // corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private constant _HASHED_NAME = keccak256("Permit2");
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    constructor() {
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Returns the domain separator for the current chain.
    /// @dev Uses cached version if chainid and address are unchanged from construction.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Builds a domain separator using the current chainId and contract address.
    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, block.chainid, address(this)));
    }

    /// @notice Creates an EIP-712 typed data hash
    function _hashTypedData(bytes32 dataHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SignatureTransfer} from "./SignatureTransfer.sol";
import {AllowanceTransfer} from "./AllowanceTransfer.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
contract Permit2 is SignatureTransfer, AllowanceTransfer {
// Permit2 unifies the two contracts so users have maximal flexibility with their approval.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {Permit2} from "../Permit2.sol";
import {IDAIPermit} from "../interfaces/IDAIPermit.sol";
import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {SafeCast160} from "./SafeCast160.sol";

/// @title Permit2Lib
/// @notice Enables efficient transfers and EIP-2612/DAI
/// permits for any token by falling back to Permit2.
library Permit2Lib {
    using SafeCast160 for uint256;
    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev The unique EIP-712 domain domain separator for the DAI token contract.
    bytes32 internal constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    /// @dev The address for the WETH9 contract on Ethereum mainnet, encoded as a bytes32.
    bytes32 internal constant WETH9_ADDRESS = 0x000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2;

    /// @dev The address of the Permit2 contract the library will use.
    Permit2 internal constant PERMIT2 = Permit2(address(0x000000000022D473030F116dDEE9F6B43aC78BA3));

    /// @notice Transfer a given amount of tokens from one user to another.
    /// @param token The token to transfer.
    /// @param from The user to transfer from.
    /// @param to The user to transfer to.
    /// @param amount The amount to transfer.
    function transferFrom2(ERC20 token, address from, address to, uint256 amount) internal {
        // Generate calldata for a standard transferFrom call.
        bytes memory inputData = abi.encodeCall(ERC20.transferFrom, (from, to, amount));

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        assembly {
            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0), 1), iszero(returndatasize())),
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the first slot of scratch space.
                    call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 32)
                )
        }

        // We'll fall back to using Permit2 if calling transferFrom on the token directly reverted.
        if (!success) PERMIT2.transferFrom(from, to, amount.toUint160(), address(token));
    }

    /*//////////////////////////////////////////////////////////////
                              PERMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Permit a user to spend a given amount of
    /// another user's tokens via the owner's EIP-712 signature.
    /// @param token The token to permit spending.
    /// @param owner The user to permit spending from.
    /// @param spender The user to permit spending to.
    /// @param amount The amount to permit spending.
    /// @param deadline  The timestamp after which the signature is no longer valid.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        // Generate calldata for a call to DOMAIN_SEPARATOR on the token.
        bytes memory inputData = abi.encodeWithSelector(ERC20.DOMAIN_SEPARATOR.selector);

        bool success; // Call the token contract as normal, capturing whether it succeeded.
        bytes32 domainSeparator; // If the call succeeded, we'll capture the return value here.

        assembly {
            // If the token is WETH9, we know it doesn't have a DOMAIN_SEPARATOR, and we'll skip this step.
            // We make sure to mask the token address as its higher order bits aren't guaranteed to be clean.
            if iszero(eq(and(token, 0xffffffffffffffffffffffffffffffffffffffff), WETH9_ADDRESS)) {
                success :=
                    and(
                        // Should resolve false if its not 32 bytes or its first word is 0.
                        and(iszero(iszero(mload(0))), eq(returndatasize(), 32)),
                        // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                        // Counterintuitively, this call must be positioned second to the and() call in the
                        // surrounding and() call or else returndatasize() will be zero during the computation.
                        // We send a maximum of 5000 gas to prevent tokens with fallbacks from using a ton of gas.
                        // which should be plenty to allow tokens to fetch their DOMAIN_SEPARATOR from storage, etc.
                        staticcall(5000, token, add(inputData, 32), mload(inputData), 0, 32)
                    )

                domainSeparator := mload(0) // Copy the return value into the domainSeparator variable.
            }
        }

        // If the call to DOMAIN_SEPARATOR succeeded, try using permit on the token.
        if (success) {
            // We'll use DAI's special permit if it's DOMAIN_SEPARATOR matches,
            // otherwise we'll just encode a call to the standard permit function.
            inputData = domainSeparator == DAI_DOMAIN_SEPARATOR
                ? abi.encodeCall(IDAIPermit.permit, (owner, spender, token.nonces(owner), deadline, true, v, r, s))
                : abi.encodeCall(ERC20.permit, (owner, spender, amount, deadline, v, r, s));

            assembly {
                success := call(gas(), token, 0, add(inputData, 32), mload(inputData), 0, 0)
            }
        }

        if (!success) {
            // If the initial DOMAIN_SEPARATOR call on the token failed or a
            // subsequent call to permit failed, fall back to using Permit2.

            (,, uint48 nonce) = PERMIT2.allowance(owner, address(token), spender);

            PERMIT2.permit(
                owner,
                IAllowanceTransfer.PermitSingle({
                    details: IAllowanceTransfer.PermitDetails({
                        token: address(token),
                        amount: amount.toUint160(),
                        // Use an unlimited expiration because it most
                        // closely mimics how a standard approval works.
                        expiration: type(uint48).max,
                        nonce: nonce
                    }),
                    spender: spender,
                    sigDeadline: deadline
                }),
                bytes.concat(r, s, bytes1(v))
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IDAIPermit {
    /// @param holder The address of the token owner.
    /// @param spender The address of the token spender.
    /// @param nonce The owner's nonce, increases at each call to permit.
    /// @param expiry The timestamp at which the permit is no longer valid.
    /// @param allowed Boolean that sets approval amount, true for type(uint256).max and false for 0.
    /// @param v Must produce valid secp256k1 signature from the owner along with r and s.
    /// @param r Must produce valid secp256k1 signature from the owner along with v and s.
    /// @param s Must produce valid secp256k1 signature from the owner along with r and v.
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Shared errors between signature based transfers and allowance based transfers.

/// @notice Thrown when validating an inputted signature that is stale
/// @param signatureDeadline The timestamp at which a signature is no longer valid
error SignatureExpired(uint256 signatureDeadline);

/// @notice Thrown when validating that the inputted nonce has not been used
error InvalidNonce();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISignatureTransfer} from "./interfaces/ISignatureTransfer.sol";
import {SignatureExpired, InvalidNonce} from "./PermitErrors.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {SignatureVerification} from "./libraries/SignatureVerification.sol";
import {PermitHash} from "./libraries/PermitHash.sol";
import {EIP712} from "./EIP712.sol";

contract SignatureTransfer is ISignatureTransfer, EIP712 {
    using SignatureVerification for bytes;
    using SafeTransferLib for ERC20;
    using PermitHash for PermitTransferFrom;
    using PermitHash for PermitBatchTransferFrom;

    /// @inheritdoc ISignatureTransfer
    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

    /// @inheritdoc ISignatureTransfer
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external {
        _permitTransferFrom(permit, transferDetails, owner, permit.hash(), signature);
    }

    /// @inheritdoc ISignatureTransfer
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external {
        _permitTransferFrom(
            permit, transferDetails, owner, permit.hashWithWitness(witness, witnessTypeString), signature
        );
    }

    /// @notice Transfers a token using a signed permit message.
    /// @param permit The permit data signed over by the owner
    /// @param dataHash The EIP-712 hash of permit data to include when checking signature
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function _permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 dataHash,
        bytes calldata signature
    ) private {
        uint256 requestedAmount = transferDetails.requestedAmount;

        if (block.timestamp > permit.deadline) revert SignatureExpired(permit.deadline);
        if (requestedAmount > permit.permitted.amount) revert InvalidAmount(permit.permitted.amount);

        _useUnorderedNonce(owner, permit.nonce);

        signature.verify(_hashTypedData(dataHash), owner);

        ERC20(permit.permitted.token).safeTransferFrom(owner, transferDetails.to, requestedAmount);
    }

    /// @inheritdoc ISignatureTransfer
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external {
        _permitTransferFrom(permit, transferDetails, owner, permit.hash(), signature);
    }

    /// @inheritdoc ISignatureTransfer
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external {
        _permitTransferFrom(
            permit, transferDetails, owner, permit.hashWithWitness(witness, witnessTypeString), signature
        );
    }

    /// @notice Transfers tokens using a signed permit messages
    /// @param permit The permit data signed over by the owner
    /// @param dataHash The EIP-712 hash of permit data to include when checking signature
    /// @param owner The owner of the tokens to transfer
    /// @param signature The signature to verify
    function _permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 dataHash,
        bytes calldata signature
    ) private {
        uint256 numPermitted = permit.permitted.length;

        if (block.timestamp > permit.deadline) revert SignatureExpired(permit.deadline);
        if (numPermitted != transferDetails.length) revert LengthMismatch();

        _useUnorderedNonce(owner, permit.nonce);
        signature.verify(_hashTypedData(dataHash), owner);

        unchecked {
            for (uint256 i = 0; i < numPermitted; ++i) {
                TokenPermissions memory permitted = permit.permitted[i];
                uint256 requestedAmount = transferDetails[i].requestedAmount;

                if (requestedAmount > permitted.amount) revert InvalidAmount(permitted.amount);

                if (requestedAmount != 0) {
                    // allow spender to specify which of the permitted tokens should be transferred
                    ERC20(permitted.token).safeTransferFrom(owner, transferDetails[i].to, requestedAmount);
                }
            }
        }
    }

    /// @inheritdoc ISignatureTransfer
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external {
        nonceBitmap[msg.sender][wordPos] |= mask;

        emit UnorderedNonceInvalidation(msg.sender, wordPos, mask);
    }

    /// @notice Returns the index of the bitmap and the bit position within the bitmap. Used for unordered nonces
    /// @param nonce The nonce to get the associated word and bit positions
    /// @return wordPos The word position or index into the nonceBitmap
    /// @return bitPos The bit position
    /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function bitmapPositions(uint256 nonce) private pure returns (uint256 wordPos, uint256 bitPos) {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);
    }

    /// @notice Checks whether a nonce is taken and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use the nonce at
    /// @param nonce The nonce to spend
    function _useUnorderedNonce(address from, uint256 nonce) internal {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

        if (flipped & bit == 0) revert InvalidNonce();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1271 {
    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";

library Allowance {
    // note if the expiration passed is 0, then it the approval set to the block.timestamp
    uint256 private constant BLOCK_TIMESTAMP_EXPIRATION = 0;

    /// @notice Sets the allowed amount, expiry, and nonce of the spender's permissions on owner's token.
    /// @dev Nonce is incremented.
    /// @dev If the inputted expiration is 0, the stored expiration is set to block.timestamp
    function updateAll(
        IAllowanceTransfer.PackedAllowance storage allowed,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    ) internal {
        uint48 storedNonce;
        unchecked {
            storedNonce = nonce + 1;
        }

        uint48 storedExpiration = expiration == BLOCK_TIMESTAMP_EXPIRATION ? uint48(block.timestamp) : expiration;

        uint256 word = pack(amount, storedExpiration, storedNonce);
        assembly {
            sstore(allowed.slot, word)
        }
    }

    /// @notice Sets the allowed amount and expiry of the spender's permissions on owner's token.
    /// @dev Nonce does not need to be incremented.
    function updateAmountAndExpiration(
        IAllowanceTransfer.PackedAllowance storage allowed,
        uint160 amount,
        uint48 expiration
    ) internal {
        // If the inputted expiration is 0, the allowance only lasts the duration of the block.
        allowed.expiration = expiration == 0 ? uint48(block.timestamp) : expiration;
        allowed.amount = amount;
    }

    /// @notice Computes the packed slot of the amount, expiration, and nonce that make up PackedAllowance
    function pack(uint160 amount, uint48 expiration, uint48 nonce) internal pure returns (uint256 word) {
        word = (uint256(nonce) << 208) | uint256(expiration) << 160 | amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "../interfaces/ISignatureTransfer.sol";

library PermitHash {
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");

    bytes32 public constant _PERMIT_SINGLE_TYPEHASH = keccak256(
        "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    bytes32 public constant _PERMIT_BATCH_TYPEHASH = keccak256(
        "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    string public constant _TOKEN_PERMISSIONS_TYPESTRING = "TokenPermissions(address token,uint256 amount)";

    string public constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    string public constant _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB =
        "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,";

    function hash(IAllowanceTransfer.PermitSingle memory permitSingle) internal pure returns (bytes32) {
        bytes32 permitHash = _hashPermitDetails(permitSingle.details);
        return
            keccak256(abi.encode(_PERMIT_SINGLE_TYPEHASH, permitHash, permitSingle.spender, permitSingle.sigDeadline));
    }

    function hash(IAllowanceTransfer.PermitBatch memory permitBatch) internal pure returns (bytes32) {
        uint256 numPermits = permitBatch.details.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitDetails(permitBatch.details[i]);
        }
        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                permitBatch.spender,
                permitBatch.sigDeadline
            )
        );
    }

    function hash(ISignatureTransfer.PermitTransferFrom memory permit) internal view returns (bytes32) {
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(
            abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline)
        );
    }

    function hash(ISignatureTransfer.PermitBatchTransferFrom memory permit) internal view returns (bytes32) {
        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                msg.sender,
                permit.nonce,
                permit.deadline
            )
        );
    }

    function hashWithWitness(
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeString));

        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(abi.encode(typeHash, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline, witness));
    }

    function hashWithWitness(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash =
            keccak256(abi.encodePacked(_PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, witnessTypeString));

        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                typeHash,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                msg.sender,
                permit.nonce,
                permit.deadline,
                witness
            )
        );
    }

    function _hashPermitDetails(IAllowanceTransfer.PermitDetails memory details) private pure returns (bytes32) {
        return keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, details));
    }

    function _hashTokenPermissions(ISignatureTransfer.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeCast160 {
    /// @notice Thrown when a valude greater than type(uint160).max is cast to uint160
    error UnsafeCast();

    /// @notice Safely casts uint256 to uint160
    /// @param value The uint256 to be cast
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) revert UnsafeCast();
        return uint160(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1271} from "../interfaces/IERC1271.sol";

library SignatureVerification {
    /// @notice Thrown when the passed in signature is not a valid length
    error InvalidSignatureLength();

    /// @notice Thrown when the recovered signer is equal to the zero address
    error InvalidSignature();

    /// @notice Thrown when the recovered signer does not equal the claimedSigner
    error InvalidSigner();

    /// @notice Thrown when the recovered contract signature is incorrect
    error InvalidContractSignature();

    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    function verify(bytes calldata signature, bytes32 hash, address claimedSigner) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }
            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) revert InvalidSignature();
            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(hash, signature);
            if (magicValue != IERC1271.isValidSignature.selector) revert InvalidContractSignature();
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { IArbitrable } from "src/interfaces/IArbitrable.sol";
import { IAgreementFramework } from "src/interfaces/IAgreementFramework.sol";
import { Owned } from "src/utils/Owned.sol";

abstract contract AgreementFramework is IAgreementFramework, Owned {
    /// @inheritdoc IArbitrable
    address public arbitrator;

    /// @notice Raised when the arbitration power is transferred.
    /// @param newArbitrator Address of the new arbitrator.
    event ArbitrationTransferred(address indexed newArbitrator);

    /// @notice Transfer the arbitration power of the agreement.
    /// @param newArbitrator Address of the new arbitrator.
    function transferArbitration(address newArbitrator) public virtual onlyOwner {
        arbitrator = newArbitrator;

        emit ArbitrationTransferred(newArbitrator);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice Thrown when trying to access to an agreement that doesn't exist.
error NonExistentAgreement();
/// @notice Thrown when trying to override an already existing agreement.
error AlreadyExistentAgreement();
/// @notice Thrown when trying to perform an invalid operation on a disputed agreement.
error AgreementIsDisputed();
/// @notice Thrown when trying to perform an invalid operation on a finalized agreement.
error AgreementIsFinalized();
/// @notice Thrown when trying to perform an invalid operation on a non-finalized agreement.
error AgreementNotFinalized();
/// @notice Thrown when trying to perform an invalid operation on a non-disputed agreement.
error AgreementNotDisputed();

/// @notice Thrown when a given party is not part of a given agreement.
error NoPartOfAgreement();
/// @notice Thrown when a party is trying to join an agreement after already have joined the agreement.
error PartyAlreadyJoined();
/// @notice Thrown when a party is trying to finalize an agreement after already have finalized the agreement.
error PartyAlreadyFinalized();
/// @notice Thrown when the provided criteria doesn't match the account trying to join.
error InvalidCriteria();
/// @notice Thrown when the provided permit doesn't match the agreement token requirements.
error InvalidPermit();
/// @notice Thrown when trying to use an invalid balance for a position in an agreement.
error InvalidBalance();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @dev Posible status for a position in the agreement.
enum PositionStatus {
    Idle,
    Joined,
    Finalized,
    Withdrawn,
    Disputed
}

/// @dev Posible status for an agreement.
enum AgreementStatus {
    Created,
    Ongoing,
    Finalized,
    Disputed
}

/// @notice Parameters to create new positions.
struct PositionParams {
    /// @dev Address of the owner of the position.
    address party;
    /// @dev Amount of agreement tokens in the position.
    uint256 balance;
}

/// @notice Data of position in the agreement.
struct PositionData {
    /// @dev Address of the owner of the position.
    address party;
    /// @dev Amount of agreement tokens in the position.
    uint256 balance;
    /// @dev Status of the position.
    PositionStatus status;
}

/// @dev Params to create new agreements.
struct AgreementParams {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
    /// @dev ERC20 token address to use for the agreement.
    address token;
}

/// @notice Data of an agreement.
struct AgreementData {
    /// @dev Hash of the detailed terms of the agreement.
    bytes32 termsHash;
    /// @dev Required amount to join or merkle root of (address,amount).
    uint256 criteria;
    /// @dev URI of the metadata of the agreement.
    string metadataURI;
    /// @dev ERC20 token address to use for the agreement.
    address token;
    /// @dev Total amount of token hold in the agreement.
    uint256 balance;
    /// @dev Status of the agreement.
    AgreementStatus status;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @dev Thrown when trying to access an agreement that doesn't exist.
error NonExistentResolution();
/// @dev Thrown when trying to execute a resolution that is locked.
error ResolutionIsLocked();
/// @dev Thrown when trying to actuate a resolution that is already executed.
error ResolutionIsExecuted();
/// @dev Thrown when trying to actuate a resolution that is appealed.
error ResolutionIsAppealed();
/// @dev Thrown when trying to appeal a resolution that is endorsed.
error ResolutionIsEndorsed();

/// @dev Thrown when an account that is not part of a settlement tries to access a function restricted to the parties of a settlement.
error NoPartOfSettlement();
/// @dev Thrown when the positions on a settlement don't match the ones in the dispute.
error SettlementPositionsMustMatch();
/// @dev Thrown when the total balance of a settlement don't match the one in the dispute.
error SettlementBalanceMustMatch();

/// @notice Thrown when the provided permit doesn't match the agreement token requirements.
error InvalidPermit();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice Data estructure used to prove membership to a criteria tree.
/// @dev Account, token & amount are used to encode the leaf.
struct CriteriaResolver {
    // Address that is part of the criteria tree
    address account;
    // Amount of ERC20 token
    uint256 balance;
    // Proof of membership to the tree
    bytes32[] proof;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IArbitrable } from "src/interfaces/IArbitrable.sol";
import { CriteriaResolver } from "src/interfaces/CriteriaTypes.sol";
import {
    AgreementData,
    AgreementStatus,
    PositionData,
    PositionParams,
    PositionStatus
} from "src/interfaces/AgreementTypes.sol";

interface IAgreementFramework is IArbitrable {
    /// @dev Raised when a new agreement is created.
    /// @param id Id of the new created agreement.
    /// @param termsHash Hash of the detailed terms of the agreement.
    /// @param criteria Criteria requirements to join the agreement.
    /// @param metadataURI URI of the metadata of the agreement.
    /// @param token ERC20 token address to use in the agreement.
    event AgreementCreated(
        bytes32 indexed id,
        bytes32 termsHash,
        uint256 criteria,
        string metadataURI,
        address token
    );

    /// @dev Raised when a new party joins an agreement.
    /// @param id Id of the agreement joined.
    /// @param party Address of party joined.
    /// @param balance Balance of the party joined.
    event AgreementJoined(bytes32 indexed id, address indexed party, uint256 balance);

    /// @dev Raised when an existing party of an agreement updates its position.
    /// @param id Id of the agreement updated.
    /// @param party Address of the party updated.
    /// @param balance New balance of the party.
    /// @param status New status of the position.
    event AgreementPositionUpdated(
        bytes32 indexed id,
        address indexed party,
        uint256 balance,
        PositionStatus status
    );

    /// @dev Raised when an agreement is finalized.
    /// @param id Id of the agreement finalized.
    event AgreementFinalized(bytes32 indexed id);

    /// @dev Raised when an agreement is in dispute.
    /// @param id Id of the agreement in dispute.
    /// @param party Address of the party that raises the dispute.
    event AgreementDisputed(bytes32 indexed id, address indexed party);

    /// @notice Join an existing agreement with a signed permit.
    /// @param id Id of the agreement to join.
    /// @param resolver Criteria data to prove sender can join agreement.
    /// @param permit Permit2 batched permit to allow the required token transfers.
    /// @param signature Signature of the permit.
    function joinAgreement(
        bytes32 id,
        CriteriaResolver calldata resolver,
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes calldata signature
    ) external;

    /// @notice Join an existing agreement with transfers previously approved.
    /// @param id Id of the agreement to join.
    /// @param resolver Criteria data to prove sender can join agreement.
    function joinAgreementApproved(bytes32 id, CriteriaResolver calldata resolver) external;

    /// @notice Adjust a position part of an agreement.
    /// @param id Id of the agreement to adjust the position from.
    /// @param newPosition Position params to adjust.
    /// @param permit Permit2 permit to allow the required token transfers.
    /// @param signature Signature of the permit.
    function adjustPosition(
        bytes32 id,
        PositionParams calldata newPosition,
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature
    ) external;

    /// @notice Signal the will of the caller to finalize an agreement.
    /// @param id Id of the agreement to settle.
    function finalizeAgreement(bytes32 id) external;

    /// @notice Raise a dispute over an agreement.
    /// @param id Id of the agreement to dispute.
    function disputeAgreement(bytes32 id) external;

    /// @notice Withdraw your position from the agreement.
    /// @param id Id of the agreement to withdraw from.
    function withdrawFromAgreement(bytes32 id) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { PositionParams } from "src/interfaces/AgreementTypes.sol";

/// @dev Thrown when trying to perform an operation restricted to the arbitrator without being the arbitrator.
error OnlyArbitrator();

/// @notice Minimal interface for arbitrable contracts.
/// @dev Implementers must write the logic to raise and settle disputes.
interface IArbitrable {
    /// @notice Address capable of settling disputes.
    function arbitrator() external view returns (address);

    /// @notice Settles the dispute `id` with the provided settlement.
    /// @param id Id of the dispute to settle.
    /// @param settlement Array of PositionParams to set as final positions.
    function settleDispute(bytes32 id, PositionParams[] calldata settlement) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { CriteriaResolver } from "src/interfaces/CriteriaTypes.sol";

/// @dev Thrown when the proof provided can't be verified against the criteria tree.
error InvalidCriteriaProof();

/// @dev Methods to verify membership to a criteria Merkle tree.
library CriteriaResolution {
    /// @dev Check that given resolver is valid for the provided criteria.
    /// @param criteria Root of the Merkle tree.
    /// @param resolver Struct with the required params to prove membership to the tree.
    function validateCriteria(bytes32 criteria, CriteriaResolver calldata resolver) external pure {
        bool isValid = verifyProof(resolver.proof, criteria, encodeLeaf(resolver));

        if (!isValid) {
            revert InvalidCriteriaProof();
        }
    }

    /// @dev Encode resolver params into merkle leaf
    function encodeLeaf(CriteriaResolver calldata resolver) public pure returns (bytes32 leaf) {
        leaf = keccak256(abi.encode(resolver.account, resolver.balance));
    }

    /// @dev Based on Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/MerkleProofLib.sol)
    ///      Verify proofs for given root and leaf are correct.
    function verifyProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Simple single owner authorization mixin.
/// @dev Adapted from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// @notice Raised when the ownership is transferred.
    /// @param user Address of the user that transferred the ownerhip.
    /// @param newOwner Address of the new owner.
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    error Unauthorized();

    /// @notice Address that owns the contract.
    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    constructor(address owner_) {
        owner = owner_;

        emit OwnershipTransferred(msg.sender, owner_);
    }

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address of the new owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @dev Data estructure to configure contract deposits.
struct DepositConfig {
    /// @dev Address of the ERC20 token used for deposits.
    address token;
    /// @dev Amount of tokens to deposit.
    uint256 amount;
    /// @dev Address recipient of the deposit.
    address recipient;
}