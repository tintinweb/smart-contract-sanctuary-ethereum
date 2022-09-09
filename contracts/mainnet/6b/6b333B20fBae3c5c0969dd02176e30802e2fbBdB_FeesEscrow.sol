// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

import "../interfaces/IPool.sol";
import "../interfaces/IFeesEscrow.sol";

/**
 * @title FeesEscrow
 *
 * @dev FeesEscrow contract is used to receive tips from validators and transfer
 * them to the Pool contract via calling transferToPool method by RewardEthToken contract.
 */
contract FeesEscrow is IFeesEscrow {
    // @dev Pool contract's address.
    IPool private immutable pool;

    // @dev RewardEthToken contract's address.
    address private immutable rewardEthToken;

    constructor(IPool _pool, address _rewardEthToken) {
        pool = _pool;
        rewardEthToken = _rewardEthToken;
    }

    /**
     * @dev See {IFeesEscrow-transferToPool}.
     */
    function transferToPool() external override returns (uint256) {
        require(msg.sender == rewardEthToken, "FeesEscrow: invalid caller");

        uint256 balance = address(this).balance;

        if (balance == 0) {
            return balance;
        }

        pool.receiveFees{value: balance}();

        emit FeesTransferred(balance);

        return balance;
    }

    /**
     * @dev Allows FeesEscrow contract to receive MEV rewards and priority fees. Later these rewards will be transferred
     * to the `Pool` contract by `FeesEscrow.transferToPool` method which is called by the `RewardEthToken` contract.
     */
    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IDepositContract.sol";
import "./IPoolValidators.sol";

/**
 * @dev Interface of the Pool contract.
 */
interface IPool {
    /**
    * @dev Event for tracking registered validators.
    * @param publicKey - validator public key.
    * @param operator - address of the validator operator.
    */
    event ValidatorRegistered(bytes publicKey, address operator);

    /**
    * @dev Event for tracking scheduled deposit activation.
    * @param sender - address of the deposit sender.
    * @param validatorIndex - index of the activated validator.
    * @param value - deposit amount to be activated.
    */
    event ActivationScheduled(address indexed sender, uint256 validatorIndex, uint256 value);

    /**
    * @dev Event for tracking activated deposits.
    * @param account - account the deposit was activated for.
    * @param validatorIndex - index of the activated validator.
    * @param value - amount activated.
    * @param sender - address of the transaction sender.
    */
    event Activated(address indexed account, uint256 validatorIndex, uint256 value, address indexed sender);

    /**
    * @dev Event for tracking activated validators updates.
    * @param activatedValidators - new total amount of activated validators.
    * @param sender - address of the transaction sender.
    */
    event ActivatedValidatorsUpdated(uint256 activatedValidators, address sender);

    /**
    * @dev Event for tracking updates to the minimal deposit amount considered for the activation period.
    * @param minActivatingDeposit - new minimal deposit amount considered for the activation.
    * @param sender - address of the transaction sender.
    */
    event MinActivatingDepositUpdated(uint256 minActivatingDeposit, address sender);

    /**
    * @dev Event for tracking pending validators limit.
    * When it's exceeded, the deposits will be set for the activation.
    * @param pendingValidatorsLimit - pending validators percent limit.
    * @param sender - address of the transaction sender.
    */
    event PendingValidatorsLimitUpdated(uint256 pendingValidatorsLimit, address sender);

    /**
    * @dev Event for tracking added deposits with partner.
    * @param partner - address of the partner.
    * @param amount - the amount added.
    */
    event StakedWithPartner(address indexed partner, uint256 amount);

    /**
    * @dev Event for tracking added deposits with referrer.
    * @param referrer - address of the referrer.
    * @param amount - the amount added.
    */
    event StakedWithReferrer(address indexed referrer, uint256 amount);

    /**
    * @dev Function for getting the total validator deposit.
    */
    // solhint-disable-next-line func-name-mixedcase
    function VALIDATOR_TOTAL_DEPOSIT() external view returns (uint256);

    /**
    * @dev Function for retrieving the total amount of pending validators.
    */
    function pendingValidators() external view returns (uint256);

    /**
    * @dev Function for retrieving the total amount of activated validators.
    */
    function activatedValidators() external view returns (uint256);

    /**
    * @dev Function for retrieving the withdrawal credentials used to
    * initiate pool validators withdrawal from the beacon chain.
    */
    function withdrawalCredentials() external view returns (bytes32);

    /**
    * @dev Function for getting the minimal deposit amount considered for the activation.
    */
    function minActivatingDeposit() external view returns (uint256);

    /**
    * @dev Function for getting the pending validators percent limit.
    * When it's exceeded, the deposits will be set for the activation.
    */
    function pendingValidatorsLimit() external view returns (uint256);

    /**
    * @dev Function for getting the amount of activating deposits.
    * @param account - address of the account to get the amount for.
    * @param validatorIndex - index of the activated validator.
    */
    function activations(address account, uint256 validatorIndex) external view returns (uint256);

    /**
    * @dev Function for setting minimal deposit amount considered for the activation period.
    * @param newMinActivatingDeposit - new minimal deposit amount considered for the activation.
    */
    function setMinActivatingDeposit(uint256 newMinActivatingDeposit) external;

    /**
    * @dev Function for changing the total amount of activated validators.
    * @param newActivatedValidators - new total amount of activated validators.
    */
    function setActivatedValidators(uint256 newActivatedValidators) external;

    /**
    * @dev Function for changing pending validators limit.
    * @param newPendingValidatorsLimit - new pending validators limit. When it's exceeded, the deposits will be set for the activation.
    */
    function setPendingValidatorsLimit(uint256 newPendingValidatorsLimit) external;

    /**
    * @dev Function for checking whether validator index can be activated.
    * @param validatorIndex - index of the validator to check.
    */
    function canActivate(uint256 validatorIndex) external view returns (bool);

    /**
    * @dev Function for retrieving the validator registration contract address.
    */
    function validatorRegistration() external view returns (IDepositContract);

    /**
    * @dev Function for receiving native tokens without minting sETH.
    */
    function receiveFees() external payable;

    /**
    * @dev Function for staking ether to the pool to the different tokens' recipient.
    * @param recipient - address of the tokens recipient.
    */
    function stakeOnBehalf(address recipient) external payable;

    /**
    * @dev Function for staking ether to the pool.
    */
    function stake() external payable;

    /**
    * @dev Function for staking ether with the partner that will receive the revenue share from the protocol fee.
    * @param partner - address of partner who will get the revenue share.
    */
    function stakeWithPartner(address partner) external payable;

    /**
    * @dev Function for staking ether with the partner that will receive the revenue share from the protocol fee
    * and the different tokens' recipient.
    * @param partner - address of partner who will get the revenue share.
    * @param recipient - address of the tokens recipient.
    */
    function stakeWithPartnerOnBehalf(address partner, address recipient) external payable;

    /**
    * @dev Function for staking ether with the referrer who will receive the one time bonus.
    * @param referrer - address of referrer who will get its referral bonus.
    */
    function stakeWithReferrer(address referrer) external payable;

    /**
    * @dev Function for staking ether with the referrer who will receive the one time bonus
    * and the different tokens' recipient.
    * @param referrer - address of referrer who will get its referral bonus.
    * @param recipient - address of the tokens recipient.
    */
    function stakeWithReferrerOnBehalf(address referrer, address recipient) external payable;

    /**
    * @dev Function for minting account's tokens for the specific validator index.
    * @param account - account address to activate the tokens for.
    * @param validatorIndex - index of the activated validator.
    */
    function activate(address account, uint256 validatorIndex) external;

    /**
    * @dev Function for minting account's tokens for the specific validator indexes.
    * @param account - account address to activate the tokens for.
    * @param validatorIndexes - list of activated validator indexes.
    */
    function activateMultiple(address account, uint256[] calldata validatorIndexes) external;

    /**
    * @dev Function for registering new pool validator registration.
    * @param depositData - the deposit data to submit for the validator.
    */
    function registerValidator(IPoolValidators.DepositData calldata depositData) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

/**
 * @dev Interface of the FeesEscrow contract.
 */
interface IFeesEscrow {
    /**
    * @dev Event for tracking fees withdrawals to Pool contract.
    * @param amount - the number of fees.
    */
    event FeesTransferred(uint256 amount);

    /**
    * @dev Function is used to transfer accumulated rewards to Pool contract.
    * Can only be executed by the RewardEthToken contract.
    */
    function transferToPool() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
/// https://github.com/ethereum/eth2.0-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @dev Interface of the PoolValidators contract.
 */
interface IPoolValidators {
    /**
    * @dev Structure for storing operator data.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param committed - defines whether operator has committed its readiness to host validators.
    */
    struct Operator {
        bytes32 depositDataMerkleRoot;
        bool committed;
    }

    /**
    * @dev Structure for passing information about the validator deposit data.
    * @param operator - address of the operator.
    * @param withdrawalCredentials - withdrawal credentials used for generating the deposit data.
    * @param depositDataRoot - hash tree root of the deposit data, generated by the operator.
    * @param publicKey - BLS public key of the validator, generated by the operator.
    * @param signature - BLS signature of the validator, generated by the operator.
    */
    struct DepositData {
        address operator;
        bytes32 withdrawalCredentials;
        bytes32 depositDataRoot;
        bytes publicKey;
        bytes signature;
    }

    /**
    * @dev Event for tracking new operators.
    * @param operator - address of the operator.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param depositDataMerkleProofs - validators deposit data merkle proofs.
    */
    event OperatorAdded(
        address indexed operator,
        bytes32 indexed depositDataMerkleRoot,
        string depositDataMerkleProofs
    );

    /**
    * @dev Event for tracking operator's commitments.
    * @param operator - address of the operator that expressed its readiness to host validators.
    */
    event OperatorCommitted(address indexed operator);

    /**
    * @dev Event for tracking operators' removals.
    * @param sender - address of the transaction sender.
    * @param operator - address of the operator.
    */
    event OperatorRemoved(
        address indexed sender,
        address indexed operator
    );

    /**
    * @dev Constructor for initializing the PoolValidators contract.
    * @param _admin - address of the contract admin.
    * @param _pool - address of the Pool contract.
    * @param _oracles - address of the Oracles contract.
    */
    function initialize(address _admin, address _pool, address _oracles) external;

    /**
    * @dev Function for retrieving the operator.
    * @param _operator - address of the operator to retrieve the data for.
    */
    function getOperator(address _operator) external view returns (bytes32, bool);

    /**
    * @dev Function for checking whether validator is registered.
    * @param validatorId - hash of the validator public key to receive the status for.
    */
    function isValidatorRegistered(bytes32 validatorId) external view returns (bool);

    /**
    * @dev Function for adding new operator.
    * @param _operator - address of the operator to add or update.
    * @param depositDataMerkleRoot - validators deposit data merkle root.
    * @param depositDataMerkleProofs - validators deposit data merkle proofs.
    */
    function addOperator(
        address _operator,
        bytes32 depositDataMerkleRoot,
        string calldata depositDataMerkleProofs
    ) external;

    /**
    * @dev Function for committing operator. Must be called by the operator address
    * specified through the `addOperator` function call.
    */
    function commitOperator() external;

    /**
    * @dev Function for removing operator. Can be called either by operator or admin.
    * @param _operator - address of the operator to remove.
    */
    function removeOperator(address _operator) external;

    /**
    * @dev Function for registering the validator.
    * @param depositData - deposit data of the validator.
    * @param merkleProof - an array of hashes to verify whether the deposit data is part of the merkle root.
    */
    function registerValidator(DepositData calldata depositData, bytes32[] calldata merkleProof) external;
}