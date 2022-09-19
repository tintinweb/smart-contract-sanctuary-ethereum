// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./CustomEIP712.sol";
import "./NonceManager.sol";
import "./Component.sol";
import "./IVerifier.sol";
import "./errors.sol";

contract ValidatorManager is ReentrancyGuard, Pausable, CustomEIP712, NonceManager, Component {
    /*=========================== 1. STRUCTS =================================*/
    struct ValidatorInfo {
        uint256 gasPrice;
        address signer;
        uint64 lastSubmit;
        uint32 epoch;
    }

    struct ValidatorFullInfo {
        bytes32 validator;
        uint256 gasPrice;
        address signer;
        uint64 lastSubmit;
        uint32 epoch;
        uint256 weight;
    }

    /*=========================== 2. CONSTANTS ===============================*/
    uint256 private constant _MIN_WEIGHT = 2e16;
    uint256 private constant _CONFIRM_PERCENT = 51;
    uint256 private constant _EPOCH_TIME = 72 * 3600; // 72 hours
    uint256 private constant _REWARD_TIME = 71 * 3600; // reward: 0 ~ 71 hour, purge: 71 ~ 72 hour
    uint256 private constant _REWARD_FACTOR = 1e9;
    bytes32 private constant _SUBMIT_VALIDATOR_TYPEHASH =
        keccak256("SubmitValidator(bytes32 validator,address signer,uint256 weight,uint32 epoch)");
    bytes32 private constant _SET_FEE_RATE_TYPEHASH =
        keccak256("SetFeeRate(uint256 feeRate,uint256 nonce)");

    /*=========================== 3. STATE VARIABLES =========================*/
    address private _genesisSigner;
    bytes32 private _genesisValidator;
    uint256 private _totalWeight;
    uint256 private _weightedGasPrice;
    uint256 private _feeRate; // gas as unit

    // Mapping from signer's address to election _weightedGasPrice
    mapping(address => uint256) private _weights;

    // Mapping from signer's address to validator's address (public key)
    mapping(address => bytes32) private _signerToValidator;

    mapping(bytes32 => ValidatorInfo) private _validatorInfos;

    // Array with all token ids, used for enumeration
    bytes32[] private _validators;

    /*=========================== 4. EVENTS ==================================*/
    event FeeRateUpdated(uint256 feeRate, uint256 nonce);
    event ValidatorSubmitted(
        bytes32 indexed validator,
        address indexed signer,
        uint256 weight,
        uint32 epoch
    );
    event ValidatorPurged(
        bytes32 indexed validator,
        address indexed signer,
        uint256 weight,
        uint32 epoch
    );
    event WeightedGasPriceUpdated(uint256 previousPrice, uint256 newPrice);
    event TotalWeightUpdated(uint256 previousWeight, uint256 newWeight);

    /*=========================== 5. MODIFIERS ===============================*/
    modifier onlySigner(address signer) {
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != signer || tx.origin != signer) revert NotCalledBySigner();
        _;
    }

    /*=========================== 6. FUNCTIONS ===============================*/
    constructor(bytes32 genesisValidator, address genesisSigner) {
        _feeRate = 21000;
        _genesisSigner = genesisSigner;
        _genesisValidator = genesisValidator;
    }

    function setFeeRate(
        uint256 feeRate,
        uint256 nonce,
        bytes calldata signatures
    ) external nonReentrant whenNotPaused useNonce(nonce) coreContractValid {
        if (!verify(keccak256(abi.encode(_SET_FEE_RATE_TYPEHASH, feeRate, nonce)), signatures)) {
            revert VerificationFailed();
        }
        _feeRate = feeRate;
        emit FeeRateUpdated(feeRate, nonce);
        IVerifier(coreContract()).setFee(feeRate * _weightedGasPrice);
    }

    function submitValidator(
        bytes32 validator,
        address signer,
        uint256 weight,
        uint32 epoch,
        address rewardTo,
        bytes calldata signatures
    ) external nonReentrant whenNotPaused onlySigner(signer) coreContractValid {
        {
            // Statck too deep
            bytes32 structHash = keccak256(
                abi.encode(_SUBMIT_VALIDATOR_TYPEHASH, validator, signer, weight, epoch)
            );
            if (!verify(structHash, signatures)) revert VerificationFailed();
        }
        if (validator == bytes32(0) || validator == _genesisValidator) revert InvalidValidator();
        if (signer == address(0) || signer == _genesisSigner) revert InvalidSigner();

        ValidatorInfo memory info = _validatorInfos[validator];
        if (epoch < info.epoch || epoch != _getCurrentEpoch()) revert InvalidEpoch();

        uint256 totalWeight = _totalWeight;
        uint256 weightClear = _revokeSubmission(validator, info, false);
        if (!_inRewardTimeRange(info) || info.epoch == epoch) {
            weightClear = 0;
        }

        if (_signerToValidator[signer] != bytes32(0)) revert SignerReferencedByOtherValidator();
        if (_weights[signer] != 0) revert SignerWeightNotCleared();

        if (info.epoch == 0) {
            _validators.push(validator);
        }

        info.gasPrice = tx.gasprice;
        info.signer = signer;
        // solhint-disable-next-line not-rely-on-time
        info.lastSubmit = uint64(block.timestamp);
        info.epoch = epoch;
        _doSubmission(validator, info, weight);

        if (weightClear > 0 && rewardTo != address(0)) {
            _sendReward(rewardTo, weightClear, totalWeight);
        }
    }

    function purgeValidators(bytes32[] calldata validators, address rewardTo)
        external
        nonReentrant
        whenNotPaused
        coreContractValid
    {
        if (!_inPurgeTimeRange()) revert NotInPurgeTimeRange();
        uint256 totalWeight = _totalWeight;
        uint256 weight = 0;
        for (uint256 i = 0; i < validators.length; i++) {
            bytes32 validator = validators[i];
            ValidatorInfo memory info = _validatorInfos[validator];
            if (_canPurge(info)) {
                weight += _revokeSubmission(validator, info, true);
            }
        }

        if (weight > 0 && rewardTo != address(0)) {
            _sendReward(rewardTo, weight, totalWeight);
        }
    }

    function getGenesisValidator() external view returns (bytes32) {
        return _genesisValidator;
    }

    function getGenesisSigner() external view returns (address) {
        return _genesisSigner;
    }

    function getWeight(address signer) external view returns (uint256) {
        return _getWeight(signer, _genesisSigner, _totalWeight);
    }

    function getFeeRate() external view returns (uint256) {
        return _feeRate;
    }

    function getWeightedGasPrice() external view returns (uint256) {
        return _weightedGasPrice;
    }

    function getTotalWeight() external view returns (uint256) {
        return _totalWeight;
    }

    function getValidatorInfo(bytes32 validator) external view returns (ValidatorInfo memory) {
        return _validatorInfos[validator];
    }

    function getValidators(uint256 begin, uint256 end)
        external
        view
        returns (ValidatorFullInfo[] memory)
    {
        uint256 length = _validators.length;
        if (end > length) end = length;
        if (begin >= end) return new ValidatorFullInfo[](0);
        ValidatorFullInfo[] memory result = new ValidatorFullInfo[](end - begin);
        for ((uint256 i, uint256 j) = (begin, 0); i < end; (++i, ++j)) {
            bytes32 validator = _validators[i];
            result[j].validator = validator;
            ValidatorInfo memory info = _validatorInfos[validator];
            result[j].gasPrice = info.gasPrice;
            result[j].signer = info.signer;
            result[j].lastSubmit = info.lastSubmit;
            result[j].epoch = info.epoch;
            result[j].weight = _weights[info.signer];
        }
        return result;
    }

    function getValidatorCount() external view returns (uint256) {
        return _validators.length;
    }

    function verify(bytes32 structHash, bytes calldata signatures) public view returns (bool) {
        bytes32 typedHash = _hashTypedDataV4(structHash);
        return verifyTypedData(typedHash, signatures);
    }

    function verifyTypedData(bytes32 typedHash, bytes calldata signatures)
        public
        view
        returns (bool)
    {
        uint256 length = signatures.length;
        if (length == 0 || length % 65 != 0) revert InvalidSignatures();
        uint256 count = length / 65;

        uint256 total = _totalWeight;
        address genesis = _genesisSigner;
        address last = address(0);
        address current;

        bytes32 r;
        bytes32 s;
        uint8 v;
        uint256 i;

        uint256 weight = 0;

        for (i = 0; i < count; ++i) {
            (r, s, v) = _decodeSignature(signatures, i);
            current = ecrecover(typedHash, v, r, s);
            if (current == address(0)) revert EcrecoverFailed();
            if (current <= last) revert InvalidSignerOrder();
            last = current;
            weight += _getWeight(current, genesis, total);
        }

        uint256 adjustTotal = total > _MIN_WEIGHT ? total : _MIN_WEIGHT;
        return weight > (adjustTotal * _CONFIRM_PERCENT) / 100;
    }

    function _getWeight(
        address signer,
        address genesis,
        uint256 total
    ) internal view returns (uint256) {
        if (signer != genesis) {
            return _weights[signer];
        } else {
            return total >= _MIN_WEIGHT ? 0 : _MIN_WEIGHT - total;
        }
    }

    function _getCurrentEpoch() internal view returns (uint32) {
        // solhint-disable-next-line not-rely-on-time
        return uint32(block.timestamp / _EPOCH_TIME);
    }

    function _inRewardTimeRange(ValidatorInfo memory info) internal view returns (bool) {
        uint256 rewardTime = _REWARD_TIME;
        uint256 epochTime = _EPOCH_TIME;
        uint256 hour = 3600;
        uint256 lastDelay = info.lastSubmit % epochTime;
        if (lastDelay > rewardTime) {
            lastDelay = rewardTime;
        }
        uint256 delay = (lastDelay + rewardTime - hour) % rewardTime;
        if (delay > rewardTime - hour) {
            delay = rewardTime - hour;
        }
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp % epochTime) >= delay;
    }

    function _inPurgeTimeRange() internal view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return (block.timestamp % _EPOCH_TIME) > _REWARD_TIME;
    }

    function _canPurge(ValidatorInfo memory info) internal view returns (bool) {
        if (info.epoch >= _getCurrentEpoch()) {
            return false;
        }
        return info.signer != address(0);
    }

    function _decodeSignature(bytes calldata signatures, uint256 index)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        // |{bytes32 r}{bytes32 s}{uint8 v}|...|{bytes32 r}{bytes32 s}{uint8 v}|
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let start := signatures.offset
            let offset := mul(0x41, index)
            r := calldataload(add(start, offset))
            s := calldataload(add(start, add(offset, 0x20)))
            v := and(calldataload(add(start, add(offset, 0x21))), 0xff)
        }
    }

    function _doSubmission(
        bytes32 validator,
        ValidatorInfo memory info,
        uint256 weight
    ) private {
        address signer = info.signer;
        _signerToValidator[signer] = validator;
        _weights[signer] = weight;

        _validatorInfos[validator] = info;
        emit ValidatorSubmitted(validator, info.signer, weight, info.epoch);

        _increaseTotalWeightAndUpdateGasPrice(weight, info.gasPrice);
    }

    function _revokeSubmission(
        bytes32 validator,
        ValidatorInfo memory info,
        bool store
    ) private returns (uint256) {
        address signer = info.signer;
        if (signer == address(0)) {
            return 0;
        }
        _signerToValidator[signer] = bytes32(0);
        uint256 weight = _weights[signer];
        _weights[signer] = 0;
        _decreaseTotalWeightAndUpdateGasPrice(weight, info.gasPrice);

        info.gasPrice = 0;
        info.signer = address(0);
        if (store) {
            _validatorInfos[validator] = info;
            emit ValidatorPurged(validator, signer, weight, info.epoch);
        }
        return weight;
    }

    function _sendReward(
        address to,
        uint256 weight,
        uint256 totalWeight
    ) private {
        if (weight == 0) {
            return;
        }
        uint256 share = _REWARD_FACTOR;
        if (weight < totalWeight) {
            share = (_REWARD_FACTOR * weight) / totalWeight;
        }
        IVerifier(coreContract()).sendReward(to, share);
    }

    function _increaseTotalWeightAndUpdateGasPrice(uint256 weight, uint256 gasPrice) private {
        if (weight == 0) {
            return;
        }

        uint256 currentWeight = _totalWeight;
        uint256 newWeight = currentWeight + weight;
        _totalWeight = newWeight;
        emit TotalWeightUpdated(currentWeight, newWeight);

        uint256 currentPrice = _weightedGasPrice;
        uint256 newPrice = ((currentPrice * currentWeight) + (weight * gasPrice)) / newWeight;
        _updateWeightedGasPrice(newPrice);
    }

    function _decreaseTotalWeightAndUpdateGasPrice(uint256 weight, uint256 gasPrice) private {
        if (weight == 0) {
            return;
        }

        uint256 currentWeight = _totalWeight;
        if (weight >= currentWeight) {
            _totalWeight = 0;
            emit TotalWeightUpdated(currentWeight, 0);
            _updateWeightedGasPrice(0);
            return;
        }

        uint256 newWeight = currentWeight - weight;
        _totalWeight = newWeight;
        emit TotalWeightUpdated(currentWeight, newWeight);

        uint256 currentPrice = _weightedGasPrice;
        uint256 removalPrice = (gasPrice * weight) / currentWeight;
        if (removalPrice >= currentPrice) {
            _updateWeightedGasPrice(0);
            return;
        }

        uint256 newPrice = ((currentPrice - removalPrice) * currentWeight) / newWeight;
        _updateWeightedGasPrice(newPrice);
    }

    function _updateWeightedGasPrice(uint256 price) private {
        uint256 currentPrice = _weightedGasPrice;
        if (currentPrice == price) {
            return;
        }

        _weightedGasPrice = price;
        emit WeightedGasPriceUpdated(currentPrice, price);
        IVerifier(coreContract()).setFee(_feeRate * price);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

// This contract will be frequently called by user, custom it for gas saving

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)
pragma solidity ^0.8.14;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract CustomEIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private constant _HASHED_NAME = keccak256("Raicoin");
    bytes32 private constant _HASHED_VERSION = keccak256("1.0");
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal view virtual returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./errors.sol";

contract NonceManager {
    uint256 private _nonce;

    modifier useNonce(uint256 nonce) {
        if (nonce != _nonce) revert NonceMismatch();
        _nonce++;
        _;
    }

    function getNonce() public view returns (uint256) {
        return _nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./errors.sol";

abstract contract Component {
    address private immutable _deployer;
    address private _coreContract;

    event CoreContractSet(address);

    modifier onlyCoreContract() {
        if (msg.sender != _coreContract) revert NotCalledByCoreContract();
        _;
    }

    modifier coreContractValid() {
        if (_coreContract == address(0)) revert CoreContractNotSet();
        _;
    }

    constructor() {
        _deployer = msg.sender;
    }

    function setCoreContract(address core) external {
        if (core == address(0)) revert InvalidCoreContract();
        if (msg.sender != _deployer) revert NotCalledByDeployer();
        if (_coreContract != address(0)) revert CoreContractAreadySet();
        _coreContract = core;
        emit CoreContractSet(_coreContract);
    }

    function deployer() public view returns (address) {
        return _deployer;
    }

    function coreContract() public view returns (address) {
        return _coreContract;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IVerifier {
    function setFee(uint256 fee) external;

    function sendReward(address recipient, uint256 share) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

error NotCalledByCoreContract();
error CoreContractNotSet();
error InvalidCoreContract();
error NotCalledByDeployer();
error CoreContractAreadySet();
error VerificationFailed();
error InvalidImplementation();
error InvalidTokenAddress();
error InvalidAmount();
error InvalidRecipient();
error TokenTypeNotMatch();
error CanNotMapWrappedToken();
error InvalidBalance();
error InvalidShare();
error InvalidValue();
error TokenIdAlreadyMapped();
error ZeroBlockNumber();
error TokenIdAlreadyOwned();
error TransferFailed();
error InvalidSender();
error AlreadySubmitted();
error TokenNotInitialized();
error CanNotUnmapWrappedToken();
error TokenIdNotMapped();
error TokenIdNotOwned();
error WrappedTokenAlreadyCreated();
error CreateWrappedTokenFailed();
error InvalidOriginalChainId();
error InvalidOriginalContract();
error WrappedTokenNotCreated();
error NotWrappedToken();
error TokenAlreadyInitialized();
error NotERC721Token();
error NonceMismatch();
error NotCalledBySigner();
error InvalidValidator();
error InvalidSigner();
error InvalidEpoch();
error SignerReferencedByOtherValidator();
error SignerWeightNotCleared();
error NotInPurgeTimeRange();
error InvalidSignatures();
error EcrecoverFailed();
error InvalidSignerOrder();
error NotCalledByValidatorManager();
error FeeTooLow();
error SendRewardFailed();
error ChainIdMismatch();

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