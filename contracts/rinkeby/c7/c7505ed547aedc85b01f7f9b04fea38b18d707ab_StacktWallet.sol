// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lib/StacktMath.sol";
import "./base/Singleton.sol";
import "./base/FallbackManager.sol";
import "./base/StacktGuardManager.sol";
import "./base/StacktOwnerManager.sol";
import "./base/StacktFeeCollector.sol";

/// @title StacktWallet - A multisignature wallet with support for confirmations using signed messages based on ERC191.
contract StacktWallet is Singleton, StacktOwnerManager, FallbackManager, StacktGuardManager {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error InsufficientGas();
    error TransactionFailed();
    error FailedToPayGasCostWithEther();
    error ThresholdNotDefined();
    error SignatureDataTooShort();
    error UnapprovedHash();
    error InvalidOwner();
    error NotAnOwner();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event StacktWalletReceived(address indexed sender, uint256 value);
    event WalletSetup(address indexed initiator, uint256 startFundingTime, uint256 fundPrice);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutedTransaction(
        address indexed to, 
        uint256 value, 
        bytes data, 
        Operation operation, 
        uint256 gas, 
        bool refundGas, 
        bytes signatures,
        uint256 nonce,
        address executor,
        uint256 threshold,
        uint256 ownerCount
    );

    event NameChanged(string name);
    event DescriptionChanged(string description);
    event ImageChanged(string image);

    /* -------------------------------------------------------------------------- */
    /*                                  libraries                                 */
    /* -------------------------------------------------------------------------- */
    using StacktMath for uint256;

    /* -------------------------------------------------------------------------- */
    /*                              public constants                              */
    /* -------------------------------------------------------------------------- */
    string public constant STACKT_VERSION = "0.0.1";

    /* -------------------------------------------------------------------------- */
    /*                              private constants                             */
    /* -------------------------------------------------------------------------- */
    // keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256("StacktTx(address to,uint256 value,bytes data,uint8 operation,uint256 gas,bool refundGas,uint256 nonce)");
    bytes32 private constant STACKT_TX_TYPEHASH = 0xffe0f8665a4358ea9667233e7e6bb03b752950edb379165f4373d9e1cddc64e1;

    // https://github.com/ethereum/go-ethereum/blob/b3b8b268eb585dfd3c1c9e9bbebc55968f3bec4b/params/protocol_params.go#L88
    uint256 private constant DATA_BYTE_GAS_COSTS = 16;
    uint256 private constant PAYMENT_GAS_COSTS = 8000;
    uint256 private constant MISC_GAS_COSTS = 3000;

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    string public name;
    string public description;
    string public image;
    uint256 public nonce;
    // Mapping to keep track of all message hashes that have been approve by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approve by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    /* -------------------------------------------------------------------------- */
    /*                                 constructor                                */
    /* -------------------------------------------------------------------------- */
    // This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor() {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Wallet with 0 owners and threshold 1.
        // This is an unusable Wallet, perfect for the singleton
        threshold = 1;
    }

    struct StacktWalletSetup { 
        string name;
        string description;
        string image;
        address msgSender;
        uint256 startFundingTime;
        uint256 fundingDuration;
        uint256 fundPrice;
        uint256 funderLimit;
    }

    /// @dev Setup function sets initial storage of contract.
    function setup(
        StacktWalletSetup calldata stacktSetup,
        address fallbackHandler,
        address guard
    ) external payable {
        name = stacktSetup.name;
        description = stacktSetup.description;
        image = stacktSetup.image;

        // setupOwners checks if threshold is already set, ensuring `setup` only called once
        setupOwners(stacktSetup.msgSender, stacktSetup.startFundingTime, stacktSetup.fundingDuration, stacktSetup.fundPrice, stacktSetup.funderLimit);

        if (fallbackHandler != address(0)) _setFallbackHandler(fallbackHandler);
        
        setupGuard(guard);

        emit WalletSetup(msg.sender, stacktSetup.startFundingTime, stacktSetup.fundPrice);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   receive                                  */
    /* -------------------------------------------------------------------------- */
    receive() external payable {
        emit StacktWalletReceived(msg.sender, msg.value);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */
    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param gas Gas that should be used for the Safe transaction.
    /// @param refundGas Whether to refund transaction gas costs
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 gas,
        bool refundGas,
        bytes memory signatures
    ) public payable virtual returns (bool success) {

        uint256 startGas = gasleft();
        bytes32 txHash;
        uint256 _nonce = nonce;

        // Note: Scopes are used to limit variable lifetime and prevent `stack too deep` errors

        /* ---------------------------- check signatures ---------------------------- */
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    gas,
                    refundGas,
                    // Signature info
                    _nonce
                );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, signatures);
        }

        /* ---------------------------------- guard --------------------------------- */
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    gas,
                    refundGas,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }

        /* -------------------------------- check gas ------------------------------- */
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        if (gasleft() < ((gas * 64) / 63).max(gas + 2500) + 500) { revert InsufficientGas(); }
        
        /* -------------------------------- execution ------------------------------- */
        {
            // execute
            // - if gas is 0 we assume that nearly all available gas can be used (always > gas)
            // - only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still > gas
            success = _execute(to, value, data, operation, gas == 0 ? (gasleft() - 2500) : gas);
            if (!success) { revert TransactionFailed(); }

            uint256 gasUsed = startGas - gasleft();

            // refund transaction gas cost
            uint256 payment = 0;
            if (refundGas) {
                payment = (gasUsed + PAYMENT_GAS_COSTS + MISC_GAS_COSTS + msg.data.length * DATA_BYTE_GAS_COSTS) * tx.gasprice;
                bool s = payable(tx.origin).send(payment);
                if (!s) { revert FailedToPayGasCostWithEther(); }
            }
        }

        /* ---------------------------- guard check after --------------------------- */
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }

        /* ---------------------------------- emit ---------------------------------- */
        emit ExecutedTransaction(to, value, data, operation, gas, refundGas, signatures, _nonce, tx.origin, funderLimit, ownerCount);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data
     * @param signatures Signature data that should be verified. Can be ECDSA signature or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        if (_threshold == 0) { revert ThresholdNotDefined(); }
        checkNSignatures(dataHash, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param signatures Signature data that should be verified. Can be ECDSA signature or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        if (signatures.length < requiredSignatures * 65) { revert SignatureDataTooShort(); }
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = _signatureSplit(signatures, i);
            if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                if (msg.sender != currentOwner && approvedHashes[currentOwner][dataHash] == 0) {
                    revert UnapprovedHash();
                }
                
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }

            if (currentOwner <= lastOwner || owners[currentOwner] == address(0) || currentOwner == SENTINEL_OWNERS) {
                revert InvalidOwner();
            }
            lastOwner = currentOwner;
        }
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        if (owners[msg.sender] == address(0)) {
            revert NotAnOwner();
        }
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param gas Gas that should be used for the safe transaction.
    /// @param refundGas Whether to refund transaction gas costs
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 gas,
        bool refundGas,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    STACKT_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    operation,
                    gas,
                    refundGas,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param gas Gas that should be used for the safe transaction.
    /// @param refundGas Whether to refund transaction gas costs
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 gas,
        bool refundGas,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, gas, refundGas, _nonce));
    }

    function setName(string calldata _name) external authorized {
        name = _name;
        emit NameChanged(_name);
    }

    function setDescription(string calldata _description) external authorized {
        description = _description;
        emit DescriptionChanged(_description);
    }

    function setImage(string calldata _image) external authorized {
        image = _image;
        emit ImageChanged(_image);
    }

    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  internal                                  */
    /* -------------------------------------------------------------------------- */
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function _signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }

    function _execute(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Operation.DelegateCall) {
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

/* -------------------------------------------------------------------------- */
/*                                  with fees                                 */
/* -------------------------------------------------------------------------- */
contract StacktWalletWithFee is StacktWallet, StacktFeeCollector {
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 gas,
        bool refundGas,
        bytes memory signatures
    ) public override payable virtual returns (bool success) {
        collectFee();
        return super.execTransaction(to, value, data, operation, gas, refundGas, signatures);        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library StacktMath {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// must be the first inherited contract
contract Singleton {
    address internal singleton;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../common/SelfAuthorized.sol";

// 
contract FallbackManager is SelfAuthorized {
    event NewFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function _setFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        assembly {
            sstore(slot, handler)
        }
    }

    function setFallbackHandler(address handler) public authorized {
        _setFallbackHandler(handler);
        emit NewFallbackHandler(handler);
    }

    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            mstore(calldatasize(), shl(96, caller())) // shift address left by 12 bytes (address only takes up 20 out of the 32 bytes)
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../common/SelfAuthorized.sol";
import "openzeppelin-contracts/utils/introspection/IERC165.sol";

enum Operation { Call, DelegateCall }

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 safeTxGas,
        bool refundGas,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

contract StacktGuardManager is SelfAuthorized {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error AlreadySetup();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event ChangedGuard(address guard);

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    // keccak256("guard_manager.setup.address")
    bytes32 internal constant SETUP_STORAGE_SLOT = 0xac6b4b4c91b961f50b5cda5ba75b03d57713b69c71326dc577aa2ff0b32e0286;

    /* -------------------------------------------------------------------------- */
    /*                                    setup                                   */
    /* -------------------------------------------------------------------------- */
    function setupGuard(address guard) internal {
        bool hasSetup;
        assembly {
            hasSetup := sload(SETUP_STORAGE_SLOT)
        }
        if (hasSetup) { revert AlreadySetup(); }
        assembly {
            sstore(SETUP_STORAGE_SLOT, true)
        }
        if (guard != address(0)) {
            _setGuard(guard);
        }
    }
    
    /* -------------------------------------------------------------------------- */
    /*                             getters and setters                            */
    /* -------------------------------------------------------------------------- */
    function getGuard() public view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        assembly {
            guard := sload(slot)
        }
    }

    function _setGuard(address guard) private {
        bytes32 slot = GUARD_STORAGE_SLOT;
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "../common/SelfAuthorized.sol";

contract StacktOwnerManager is SelfAuthorized {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error IncorrectFundingAmount();
    error FundingPeriodNotStarted();
    error FundingPeriodEnded();
    error MaxFundersReached();
    error AlreadyFunded();
    error ThresholdExceedsOwnerCount();
    error ThresholdIsZero();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event ChangedThreshold(uint256 threshold);
    event StacktFund(address indexed funder, address indexed wallet);

    /* -------------------------------------------------------------------------- */
    /*                                   states                                   */
    /* -------------------------------------------------------------------------- */
    uint256 public startFundingTime;
    uint256 public fundingDuration;
    uint256 public fundPrice;
    uint256 public funderLimit;

    address internal constant SENTINEL_OWNERS = address(0x1);
    mapping(address => address) internal owners;
    uint256 public ownerCount;
    uint256 internal threshold;
    bool public useAutoThreshold;

    /* -------------------------------------------------------------------------- */
    /*                                    setup                                   */
    /* -------------------------------------------------------------------------- */
    function setupOwners(
        address msgSender,
        uint256 _startFundingTime,
        uint256 _fundingDuration,
        uint256 _fundPrice,
        uint256 _funderLimit
    ) internal {
        // check correct funding amount
        if (msg.value != _fundPrice) { revert IncorrectFundingAmount(); }

        startFundingTime = _startFundingTime;
        fundingDuration = _fundingDuration;
        fundPrice = _fundPrice;
        funderLimit = _funderLimit;

        // initialize funders
        owners[SENTINEL_OWNERS] = msgSender;
        owners[msgSender] = SENTINEL_OWNERS;
        ownerCount = 1;
        threshold = 1;

        // initialize threshold
        useAutoThreshold = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   public                                   */
    /* -------------------------------------------------------------------------- */
    function fund() external payable {
        // check time
        if (block.timestamp < startFundingTime) { revert FundingPeriodNotStarted(); }
        if (block.timestamp > startFundingTime + fundingDuration) { revert FundingPeriodEnded(); }

        // check limit
        if (ownerCount >= funderLimit) { revert MaxFundersReached(); }

        // check funding amount
        if (msg.value != fundPrice)  { revert IncorrectFundingAmount(); }

        // check hasn't already deposited
        // using msg.sender so smart contract wallets can be funders
        if (owners[msg.sender] != address(0)) { revert AlreadyFunded(); }

        owners[msg.sender] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = msg.sender;
        ownerCount += 1;

        // update threshold
        if (useAutoThreshold) {

            uint256 newOwnerCount = ownerCount;
            uint256 currentThreshold = threshold;
            uint256 newThreshold = currentThreshold;
            uint256 _funderLimit = funderLimit;

            // 100% threshold
            if (newOwnerCount <= _funderLimit * 10 / 100) {
                newThreshold = newOwnerCount;
            }

            // 90% threshold
            else if (newOwnerCount <= _funderLimit * 20 / 100) {
                newThreshold = newOwnerCount * 90 / 100;
            }

            // 80% threshold
            else if (newOwnerCount <= _funderLimit * 30 / 100) {
                newThreshold = newOwnerCount * 80 / 100;
            }

            // 70% threshold
            else {
                newThreshold = newOwnerCount * 70 / 100;
            }

            // update threshold
            if (newThreshold != currentThreshold) {
                threshold = newThreshold;
            }
        }

        emit StacktFund(msg.sender, address(this));
    }

    // update
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        if (_threshold > ownerCount) { revert ThresholdExceedsOwnerCount(); }

        // There has to be at least one Safe owner.
        if (_threshold == 0) { revert ThresholdIsZero(); }

        threshold = _threshold;

        // disable auto threshold
        if (useAutoThreshold) {
            useAutoThreshold = false;
        }

        emit ChangedThreshold(threshold);
    }

    // getters
    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "uniswap-v2/interfaces/IUniswapV2Router02.sol";

contract StacktFeeCollector is Ownable {

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bytes32 internal constant FEE_COLLECTOR_ADDRESS_STORAGE_SLOT = 0x000; ///
    bytes32 internal constant COLLECT_FEE_STORAGE_SLOT = 0x000; ///
    bytes32 internal constant TOKEN_FEE_PER_TRANSACTION_STORAGE_SLOT = 0x000; ///
    bytes32 internal constant TOKEN_CONTRACT_ADDRESS_STORAGE_SLOT = 0x000; ///

    function collectFee() internal {

        // check if collecting fee
        if (!_getCollectFee()) { return; }

        uint256 feePerTransaction = _getFeePerTransaction();
        IERC20 token = IERC20(_getTokenContractAddress());
        address feeCollectorAddress = _getFeeCollectorAddress();

        // buy token
        if (token.balanceOf(address(this)) < feePerTransaction) {
            // generate the uniswap pair path of weth -> token
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(token);

            // swap
            uniswapV2Router.swapETHForExactTokens(
                feePerTransaction - token.balanceOf(address(this)), 
                path, 
                address(this), 
                block.timestamp
            );
        }

        // transfer token
        token.transfer(feeCollectorAddress, feePerTransaction);
    }

    /* -------------------------------------------------------------------------- */
    /*                         private getters and setters                        */
    /* -------------------------------------------------------------------------- */
    function _getFeeCollectorAddress() private view returns (address) {
        address feeCollectorAddress;
        assembly {
            feeCollectorAddress := sload(FEE_COLLECTOR_ADDRESS_STORAGE_SLOT)
        }
        return feeCollectorAddress;
    }

    function _setFeeCollectorAddress(address _feeCollectorAddress) private {
        bytes32 slot = FEE_COLLECTOR_ADDRESS_STORAGE_SLOT;
        assembly {
            sstore(slot, _feeCollectorAddress)
        }
    }

    function _getCollectFee() private view returns (bool) {
        bool collectFee;
        assembly {
            collectFee := sload(COLLECT_FEE_STORAGE_SLOT)
        }
        return collectFee;
    }

    function _setCollectFee(bool _collectFee) private {
        bytes32 slot = COLLECT_FEE_STORAGE_SLOT;
        assembly {
            sstore(slot, _collectFee)
        }
    }

    function _getFeePerTransaction() private view returns (uint256) {
        uint256 feePerTransaction;
        assembly {
            feePerTransaction := sload(TOKEN_FEE_PER_TRANSACTION_STORAGE_SLOT)
        }
        return feePerTransaction;
    }

    function _setFeePerTransaction(uint256 _feePerTransaction) private {
        bytes32 slot = TOKEN_FEE_PER_TRANSACTION_STORAGE_SLOT;
        assembly {
            sstore(slot, _feePerTransaction)
        }
    }

    function _getTokenContractAddress() private view returns (address) {
        address tokenContractAddress;
        assembly {
            tokenContractAddress := sload(TOKEN_CONTRACT_ADDRESS_STORAGE_SLOT)
        }
        return tokenContractAddress;
    }

    function _setTokenContractAddress(address _tokenContractAddress) private {
        bytes32 slot = TOKEN_CONTRACT_ADDRESS_STORAGE_SLOT;
        assembly {
            sstore(slot, _tokenContractAddress)
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                 owners only                                */
    /* -------------------------------------------------------------------------- */
    function setCollectFee(bool _c) external onlyOwner {
        _setCollectFee(_c);
    }

    function setFeeCollectorAddress(address _feeCollectorAddress) external onlyOwner {
        _setFeeCollectorAddress(_feeCollectorAddress);
    }

    function setFeePerTransaction(uint256 _feePerTransaction) external onlyOwner {
        _setFeePerTransaction(_feePerTransaction);
    }

    function setTokenContractAddress(address _tokenContractAddress) external onlyOwner {
        _setTokenContractAddress(_tokenContractAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract SelfAuthorized {

    error NotSelfAuthorized();

    function requireSelfCall() private view {
        if (msg.sender != address(this)) { revert NotSelfAuthorized(); }
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}