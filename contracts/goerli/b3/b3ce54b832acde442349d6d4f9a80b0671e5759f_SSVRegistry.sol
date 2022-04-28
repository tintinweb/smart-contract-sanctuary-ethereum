// File: contracts/SSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISSVRegistry.sol";

contract SSVRegistry is Initializable, OwnableUpgradeable, ISSVRegistry {
    using Counters for Counters.Counter;

    struct Operator {
        string name;
        address ownerAddress;
        bytes publicKey;
        uint256 score;
        bool active;
        uint indexInOwner;
    }

    struct Validator {
        address ownerAddress;
        uint256[] operatorIds;
        bool active;
        uint256 indexInOwner;
    }

    struct OperatorFee {
        uint256 blockNumber;
        uint256 fee;
    }

    struct OwnerData {
        uint256 activeValidatorCount;
        bool validatorsDisabled;
    }

    uint256 private _activeValidatorCount;

    Counters.Counter private _lastOperatorId;

    mapping(uint256 => Operator) private _operators;
    mapping(bytes => Validator) private _validators;
    mapping(uint256 => OperatorFee[]) private _operatorFees;

    mapping(address => uint256[]) private _operatorsByOwnerAddress;
    mapping(address => bytes[]) private _validatorsByOwnerAddress;
    mapping(address => OwnerData) private _owners;

    mapping(uint256 => uint256) internal validatorsPerOperator;
    uint256 public validatorsPerOperatorLimit;
    mapping(bytes => uint256) private _operatorPublicKeyToId;

    /**
     * @dev See {ISSVRegistry-initialize}.
     */
    function initialize(uint256 validatorsPerOperatorLimit_) external override initializer {
        __SSVRegistry_init(validatorsPerOperatorLimit_);
    }

    function __SSVRegistry_init(uint256 validatorsPerOperatorLimit_) internal initializer {
        __Ownable_init_unchained();
        __SSVRegistry_init_unchained(validatorsPerOperatorLimit_);
    }

    function __SSVRegistry_init_unchained(uint256 validatorsPerOperatorLimit_) internal initializer {
        validatorsPerOperatorLimit = validatorsPerOperatorLimit_;
    }

    /**
     * @dev See {ISSVRegistry-registerOperator}.
     */
    function registerOperator(
        string calldata name,
        address ownerAddress,
        bytes calldata publicKey,
        uint256 fee
    ) external onlyOwner override returns (uint256 operatorId) {
        require(
            _operatorPublicKeyToId[publicKey] == 0,
            "operator with same public key already exists"
        );

        _lastOperatorId.increment();
        operatorId = _lastOperatorId.current();
        _operators[operatorId] = Operator(name, ownerAddress, publicKey, 0, false, _operatorsByOwnerAddress[ownerAddress].length);
        _operatorsByOwnerAddress[ownerAddress].push(operatorId);
        _operatorPublicKeyToId[publicKey] = operatorId;
        _updateOperatorFeeUnsafe(operatorId, fee);
        _activateOperatorUnsafe(operatorId);

        emit OperatorAdded(operatorId, name, ownerAddress, publicKey);
    }

    /**
     * @dev See {ISSVRegistry-removeOperator}.
     */
    function removeOperator(
        uint256 operatorId
    ) external onlyOwner override {
        require(validatorsPerOperator[operatorId] == 0, "operator has validators");

        Operator storage operator = _operators[operatorId];
        _operatorsByOwnerAddress[operator.ownerAddress][operator.indexInOwner] = _operatorsByOwnerAddress[operator.ownerAddress][_operatorsByOwnerAddress[operator.ownerAddress].length - 1];
        _operators[_operatorsByOwnerAddress[operator.ownerAddress][operator.indexInOwner]].indexInOwner = operator.indexInOwner;
        _operatorsByOwnerAddress[operator.ownerAddress].pop();

        emit OperatorRemoved(operatorId, operator.ownerAddress, operator.publicKey);

        delete validatorsPerOperator[operatorId];
        delete _operatorPublicKeyToId[operator.publicKey];
        delete _operators[operatorId];
    }

    /**
     * @dev See {ISSVRegistry-activateOperator}.
     */
    function activateOperator(uint256 operatorId) external onlyOwner override {
        _activateOperatorUnsafe(operatorId);
    }

    /**
     * @dev See {ISSVRegistry-deactivateOperator}.
     */
    function deactivateOperator(uint256 operatorId) external onlyOwner override {
        _deactivateOperatorUnsafe(operatorId);
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorFee}.
     */
    function updateOperatorFee(uint256 operatorId, uint256 fee) external onlyOwner override {
        _updateOperatorFeeUnsafe(operatorId, fee);
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorScore}.
     */
    function updateOperatorScore(uint256 operatorId, uint256 score) external onlyOwner override {
        Operator storage operator = _operators[operatorId];
        operator.score = score;

        emit OperatorScoreUpdated(operatorId, operator.ownerAddress, operator.publicKey, block.number, score);
    }

    /**
     * @dev See {ISSVRegistry-registerValidator}.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        uint256[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external onlyOwner override {
        _validateValidatorParams(
            publicKey,
            operatorIds,
            sharesPublicKeys,
            encryptedKeys
        );
        require(
            _validators[publicKey].ownerAddress == address(0),
            "validator with same public key already exists"
        );

        _validators[publicKey] = Validator(ownerAddress, operatorIds, true, _validatorsByOwnerAddress[ownerAddress].length);
        _validatorsByOwnerAddress[ownerAddress].push(publicKey);

        for (uint256 index = 0; index < operatorIds.length; ++index) {
            require(++validatorsPerOperator[operatorIds[index]] <= validatorsPerOperatorLimit, "exceed validator limit");
        }

        ++_activeValidatorCount;
        ++_owners[_validators[publicKey].ownerAddress].activeValidatorCount;

        emit ValidatorAdded(ownerAddress, publicKey, operatorIds, sharesPublicKeys, encryptedKeys);
    }

    /**
     * @dev See {ISSVRegistry-updateValidator}.
     */
    function updateValidator(
        bytes calldata publicKey,
        uint256[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external onlyOwner override {
        _validateValidatorParams(
            publicKey,
            operatorIds,
            sharesPublicKeys,
            encryptedKeys
        );
        Validator storage validator = _validators[publicKey];

        for (uint256 index = 0; index < validator.operatorIds.length; ++index) {
            --validatorsPerOperator[validator.operatorIds[index]];
        }

        validator.operatorIds = operatorIds;

        for (uint256 index = 0; index < operatorIds.length; ++index) {
            require(++validatorsPerOperator[operatorIds[index]] <= validatorsPerOperatorLimit, "exceed validator limit");
        }

        emit ValidatorUpdated(validator.ownerAddress, publicKey, operatorIds, sharesPublicKeys, encryptedKeys);
    }

    /**
     * @dev See {ISSVRegistry-removeValidator}.
     */
    function removeValidator(
        bytes calldata publicKey
    ) external onlyOwner override {
        Validator storage validator = _validators[publicKey];

        for (uint256 index = 0; index < validator.operatorIds.length; ++index) {
            --validatorsPerOperator[validator.operatorIds[index]];
        }

        _validatorsByOwnerAddress[validator.ownerAddress][validator.indexInOwner] = _validatorsByOwnerAddress[validator.ownerAddress][_validatorsByOwnerAddress[validator.ownerAddress].length - 1];
        _validators[_validatorsByOwnerAddress[validator.ownerAddress][validator.indexInOwner]].indexInOwner = validator.indexInOwner;
        _validatorsByOwnerAddress[validator.ownerAddress].pop();

        --_activeValidatorCount;
        --_owners[validator.ownerAddress].activeValidatorCount;

        emit ValidatorRemoved(validator.ownerAddress, publicKey);

        delete _validators[publicKey];
    }

    function enableOwnerValidators(address ownerAddress) external onlyOwner override {
        _activeValidatorCount += _owners[ownerAddress].activeValidatorCount;
        _owners[ownerAddress].validatorsDisabled = false;

        emit OwnerValidatorsEnabled(ownerAddress);
    }

    function disableOwnerValidators(address ownerAddress) external onlyOwner override {
        _activeValidatorCount -= _owners[ownerAddress].activeValidatorCount;
        _owners[ownerAddress].validatorsDisabled = true;

        emit OwnerValidatorsDisabled(ownerAddress);
    }

    function isOwnerValidatorsDisabled(address ownerAddress) external view override returns (bool) {
        return _owners[ownerAddress].validatorsDisabled;
    }

    /**
     * @dev See {ISSVRegistry-operators}.
     */
    function operators(uint256 operatorId) external view override returns (string memory, address, bytes memory, uint256, bool) {
        Operator storage operator = _operators[operatorId];
        return (operator.name, operator.ownerAddress, operator.publicKey, operator.score, operator.active);
    }

    /**
     * @dev See {ISSVRegistry-operatorsByPublicKey}.
     */
    function operatorsByPublicKey(bytes memory publicKey) external view override returns (string memory, address, bytes memory, uint256, bool) {
        Operator storage operator = _operators[_operatorPublicKeyToId[publicKey]];
        return (operator.name, operator.ownerAddress, operator.publicKey, operator.score, operator.active);
    }

    /**
     * @dev See {ISSVRegistry-getOperatorsByOwnerAddress}.
     */
    function getOperatorsByOwnerAddress(address ownerAddress) external view override returns (uint256[] memory) {
        return _operatorsByOwnerAddress[ownerAddress];
    }

    /**
     * @dev See {ISSVRegistry-getOperatorsByValidator}.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey) external view override returns (uint256[] memory operatorIds) {
        Validator storage validator = _validators[validatorPublicKey];

        return validator.operatorIds;
    }

    /**
     * @dev See {ISSVRegistry-getOperatorOwner}.
     */
    function getOperatorOwner(uint256 operatorId) external override view returns (address) {
        return _operators[operatorId].ownerAddress;
    }

    /**
     * @dev See {ISSVRegistry-getOperatorCurrentFee}.
     */
    function getOperatorCurrentFee(uint256 operatorId) external view override returns (uint256) {
        require(_operatorFees[operatorId].length > 0, "operator not found");
        return _operatorFees[operatorId][_operatorFees[operatorId].length - 1].fee;
    }

    /**
     * @dev See {ISSVRegistry-activeValidatorCount}.
     */
    function activeValidatorCount() external view override returns (uint256) {
        return _activeValidatorCount;
    }

    /**
     * @dev See {ISSVRegistry-validators}.
     */
    function validators(bytes calldata publicKey) external view override returns (address, bytes memory, bool) {
        Validator storage validator = _validators[publicKey];

        return (validator.ownerAddress, publicKey, validator.active);
    }

    /**
     * @dev See {ISSVRegistry-getValidatorsByAddress}.
     */
    function getValidatorsByAddress(address ownerAddress) external view override returns (bytes[] memory) {
        return _validatorsByOwnerAddress[ownerAddress];
    }

    /**
     * @dev See {ISSVRegistry-getValidatorOwner}.
     */
    function getValidatorOwner(bytes calldata publicKey) external view override returns (address) {
        return _validators[publicKey].ownerAddress;
    }

    /**
     * @dev See {ISSVRegistry-setValidatorsPerOperatorLimit}.
     */
    function setValidatorsPerOperatorLimit(uint256 _validatorsPerOperatorLimit) onlyOwner external override {
        validatorsPerOperatorLimit = _validatorsPerOperatorLimit;
    }

    /**
     * @dev See {ISSVRegistry-getValidatorsPerOperatorLimit}.
     */
    function getValidatorsPerOperatorLimit() external view override returns (uint256) {
        return validatorsPerOperatorLimit;
    }

    /**
     * @dev See {ISSVRegistry-validatorsPerOperatorCount}.
     */
    function validatorsPerOperatorCount(uint256 operatorId) external override view returns (uint256) {
        return validatorsPerOperator[operatorId];
    }

    /**
     * @dev See {ISSVRegistry-activateOperator}.
     */
    function _activateOperatorUnsafe(uint256 operatorId) private {
        require(!_operators[operatorId].active, "already active");
        _operators[operatorId].active = true;

        emit OperatorActivated(operatorId, _operators[operatorId].ownerAddress, _operators[operatorId].publicKey);
    }

    /**
     * @dev See {ISSVRegistry-deactivateOperator}.
     */
    function _deactivateOperatorUnsafe(uint256 operatorId) private {
        require(_operators[operatorId].active, "already inactive");
        _operators[operatorId].active = false;

        emit OperatorDeactivated(operatorId, _operators[operatorId].ownerAddress, _operators[operatorId].publicKey);
    }

    /**
     * @dev See {ISSVRegistry-updateOperatorFee}.
     */
    function _updateOperatorFeeUnsafe(uint256 operatorId, uint256 fee) private {
        _operatorFees[operatorId].push(
            OperatorFee(block.number, fee)
        );

        emit OperatorFeeUpdated(operatorId, _operators[operatorId].ownerAddress, _operators[operatorId].publicKey, block.number, fee);
    }

    /**
     * @dev Validates the paramss for a validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator operatorIds.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function _validateValidatorParams(
        bytes calldata publicKey,
        uint256[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) private pure {
        require(publicKey.length == 48, "invalid public key length");
        require(
            operatorIds.length == sharesPublicKeys.length &&
            operatorIds.length == encryptedKeys.length &&
            operatorIds.length >= 4 && operatorIds.length % 3 == 1,
            "OESS data structure is not valid"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// File: contracts/ISSVRegistry.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.2;

interface ISSVRegistry {
    struct Oess {
        uint256 operatorId;
        bytes sharedPublicKey;
        bytes encryptedKey;
    }

    /**
     * @dev Emitted when the operator has been added.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     */
    event OperatorAdded(uint256 operatorId, string name, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been removed.
     * @param ownerAddress Operator's owner.
     */
    event OperatorRemoved(uint256 operatorId, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been activated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorActivated(uint256 operatorId, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when the operator has been deactivated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     */
    event OperatorDeactivated(uint256 operatorId, address indexed ownerAddress, bytes publicKey);

    /**
     * @dev Emitted when an operator's fee is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param fee updated fee value.
     */
    event OperatorFeeUpdated(
        uint256 operatorId,
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 fee
    );

    /**
     * @dev Emitted when an operator's score is updated.
     * @param ownerAddress Operator's owner.
     * @param publicKey Operator's public key.
     * @param blockNumber from which block number.
     * @param score updated score value.
     */
    event OperatorScoreUpdated(
        uint256 operatorId,
        address indexed ownerAddress,
        bytes publicKey,
        uint256 blockNumber,
        uint256 score
    );

    /**
     * @dev Emitted when the validator has been added.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     */
    event ValidatorAdded(
        address ownerAddress,
        bytes publicKey,
        uint256[] operatorIds,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator has been updated.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey The public key of a validator.
     */
    event ValidatorUpdated(
        address ownerAddress,
        bytes publicKey,
        uint256[] operatorIds,
        bytes[] sharesPublicKeys,
        bytes[] encryptedKeys
    );

    /**
     * @dev Emitted when the validator is removed.
     * @param ownerAddress Validator's owner.
     * @param publicKey The public key of a validator.
     */
    event ValidatorRemoved(address ownerAddress, bytes publicKey);

    event OwnerValidatorsDisabled(address ownerAddress);

    event OwnerValidatorsEnabled(address ownerAddress);

    /**
     * @dev Initializes the contract
     * @param validatorsPerOperatorLimit_ the limit for validators per operator.
     */
    function initialize(uint256 validatorsPerOperatorLimit_) external;

    /**
     * @dev Registers a new operator.
     * @param name Operator's display name.
     * @param ownerAddress Operator's ethereum address that can collect fees.
     * @param publicKey Operator's public key. Will be used to encrypt secret shares of validators keys.
     * @param fee The fee which the operator charges for each block.
     */
    function registerOperator(string calldata name, address ownerAddress, bytes calldata publicKey, uint256 fee) external returns (uint256);

    /**
     * @dev removes an operator.
     * @param operatorId Operator id.
     */
    function removeOperator(uint256 operatorId) external;

    /**
     * @dev Activates an operator.
     * @param operatorId Operator id.
     */
    function activateOperator(uint256 operatorId) external;

    /**
     * @dev Deactivates an operator.
     * @param operatorId Operator id.
     */
    function deactivateOperator(uint256 operatorId) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param fee New operator fee.
     */
    function updateOperatorFee(
        uint256 operatorId,
        uint256 fee
    ) external;

    /**
     * @dev Updates an operator fee.
     * @param operatorId Operator id.
     * @param score New score.
     */
    function updateOperatorScore(
        uint256 operatorId,
        uint256 score
    ) external;

    /**
     * @dev Registers a new validator.
     * @param ownerAddress The user's ethereum address that is the owner of the validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator ids.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function registerValidator(
        address ownerAddress,
        bytes calldata publicKey,
        uint256[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev Updates a validator.
     * @param publicKey Validator public key.
     * @param operatorIds Operator ids.
     * @param sharesPublicKeys Shares public keys.
     * @param encryptedKeys Encrypted private keys.
     */
    function updateValidator(
        bytes calldata publicKey,
        uint256[] calldata operatorIds,
        bytes[] calldata sharesPublicKeys,
        bytes[] calldata encryptedKeys
    ) external;

    /**
     * @dev removes a validator.
     * @param publicKey Validator's public key.
     */
    function removeValidator(bytes calldata publicKey) external;

    function enableOwnerValidators(address ownerAddress) external;

    function disableOwnerValidators(address ownerAddress) external;

    function isOwnerValidatorsDisabled(address ownerAddress) external view returns (bool);

    /**
     * @dev Gets an operator by operator id.
     * @param operatorId Operator id.
     */
    function operators(uint256 operatorId)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            bool
        );

    /**
     * @dev Gets an operator by public key.
     * @param publicKey Operator public key.
     */
    function operatorsByPublicKey(bytes memory publicKey)
        external view
        returns (
            string memory,
            address,
            bytes memory,
            uint256,
            bool
        );

    /**
     * @dev Returns operators for owner.
     * @param ownerAddress Owner's address.
     */
    function getOperatorsByOwnerAddress(address ownerAddress)
        external view
        returns (uint256[] memory);

    /**
     * @dev Gets operators list which are in use by validator.
     * @param validatorPublicKey Validator's public key.
     */
    function getOperatorsByValidator(bytes calldata validatorPublicKey)
        external view
        returns (uint256[] memory);

    /**
     * @dev Gets operator's owner.
     * @param operatorId Operator id.
     */
    function getOperatorOwner(uint256 operatorId) external view returns (address);

    /**
     * @dev Gets operator current fee.
     * @param operatorId Operator id.
     */
    function getOperatorCurrentFee(uint256 operatorId)
        external view
        returns (uint256);

    /**
     * @dev Gets active validator count.
     */
    function activeValidatorCount() external view returns (uint256);

    /**
     * @dev Gets an validator by public key.
     * @param publicKey Validator's public key.
     */
    function validators(bytes calldata publicKey)
        external view
        returns (
            address,
            bytes memory,
            bool
        );

    /**
     * @dev Gets a validator public keys by owner's address.
     * @param ownerAddress Owner's Address.
     */
    function getValidatorsByAddress(address ownerAddress)
        external view
        returns (bytes[] memory);

    /**
     * @dev Get validator's owner.
     * @param publicKey Validator's public key.
     */
    function getValidatorOwner(bytes calldata publicKey) external view returns (address);

    /**
     * @dev Set Max validators amount limit per Operator.
     * @param _validatorsPerOperatorLimit Amount
     */
    function setValidatorsPerOperatorLimit(uint256 _validatorsPerOperatorLimit) external;

    /**
     * @dev Get validators per operator limit.
     */
    function getValidatorsPerOperatorLimit() external view returns (uint256);

    /**
     * @dev Get validators amount per operator.
     * @param operatorId Operator public key
     */
    function validatorsPerOperatorCount(uint256 operatorId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}