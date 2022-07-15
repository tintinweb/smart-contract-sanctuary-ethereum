// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "./core/Singleton.sol";
import "./handlers/Handler.sol";
import "./interfaces/ILaserWallet.sol";
import "./ssr/SSR.sol";

/**
 * @title LaserWallet - EVM based smart contract wallet. Implementes smart social recovery mechanism.
 * @author Rodrigo Herrera I.
 */
contract LaserWallet is ILaserWallet, Singleton, SSR, Handler {
    string public constant VERSION = "1.0.0";

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256(
            "LaserOperation(address to,uint256 value,bytes callData,uint256 nonce,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 gasLimit)"
        );

    bytes4 private constant EIP1271_MAGIC_VALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    uint256 public nonce;

    event Here(uint256 gasleft);

    constructor() {
        // This makes the singleton unusable. e.g. (parity wallet hack). (Even though there are no delegate calls ...)
        owner = address(this);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Setup function, sets initial storage of contract.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwners Array of recovery owners. Implementation of Sovereign Social Recovery.
     * @param _guardians Addresses that can activate the social recovery mechanism.
     * @notice It can't be called after initialization.
     */
    function init(
        address _owner,
        address[] calldata _recoveryOwners,
        address[] calldata _guardians,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata ownerSignature
    ) external {
        // initOwner() requires that the current owner is address 0.
        // This is enough to protect init() from being called after initialization.
        initOwner(_owner);

        // We initialize the guardians ...
        initGuardians(_guardians);

        // We initialize the recovery owners ...
        initRecoveryOwners(_recoveryOwners);

        {
            // Scope to avoid stack too deep ...

            bytes32 signedHash = keccak256(
                abi.encodePacked(maxFeePerGas, maxPriorityFeePerGas, gasLimit, block.chainid)
            );

            (bytes32 r, bytes32 s, uint8 v) = splitSigs(ownerSignature, 0);

            address signer = returnSigner(signedHash, r, s, v, ownerSignature);

            //@todo Optimize this.
            if (signer != _owner) revert LW__init__notOwner();
        }

        if (gasLimit > 0) {
            // If gas limit is greater than 0, then the transaction was sent through a relayer.
            // We calculate the gas price, as per the user's request ...
            uint256 gasPrice = calculateGasPrice(maxFeePerGas, maxPriorityFeePerGas);

            // gasUsed is the total amount of gas consumed for this transaction.
            // This is contemplating the initial callData cost, the main transaction,
            // and we add the surplus for what is left (refund the relayer).
            uint256 gasUsed = gasLimit - gasleft() + 7000;
            uint256 refundAmount = gasUsed * gasPrice;

            // We refund the relayer ...
            bool success = _call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());

            // If the transaction returns false, we revert ...
            if (!success) revert LW__init__refundFailure();
        }

        emit Setup(_owner, _recoveryOwners, _guardians);
    }

    /**
     * @dev Executes a generic transaction. It does not support 'delegatecall' for security reasons.
     * @param to Destination address.
     * @param value Amount to send.
     * @param callData Data payload for the transaction.
     * @param _nonce Unsigned integer to avoid replay attacks. It needs to match the current wallet's nonce.
     * @param maxFeePerGas Maximum amount that the user is willing to pay for a unit of gas.
     * @param maxPriorityFeePerGas Miner's tip.
     * @param gasLimit The transaction's gas limit. It needs to be the same as the actual transaction gas limit.
     * @param relayer Address that forwards the transaction so it abstracts away the gas costs.
     * @param signatures The signatures of the transaction.
     * @notice If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     * It is the relayer's responsability to make sure that they are the same, the user does not get affected if a mistake is made.
     * We prefer to prioritize the user's safety (not overpay) over the relayer.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external {
        emit Here(gasleft());
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__exec__invalidNonce();
        }

        // Verifies the correctness of the transaction. It checks that the signatures are
        // correct and that the signer has access for the transaction.
        verifyTransaction(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit, signatures);

        // Once we verified that the transaction is correct, we execute the main call.
        // We subtract 10_000 to have enough gas to complete the function.
        bool success = _call(to, value, callData, gasleft() - 10000);

        // We do not revert the call if it fails, because the wallet needs to pay the relayer even in case of failure.
        if (success) emit ExecSuccess(to, value, nonce);
        else emit ExecFailure(to, value, nonce);

        // We calculate the gas price, as per the user's request ...
        uint256 gasPrice = calculateGasPrice(maxFeePerGas, maxPriorityFeePerGas);

        // gasUsed is the total amount of gas consumed for this transaction.
        // This is contemplating the initial callData cost, the main transaction,
        // and we add the surplus for what is left (refund the relayer).
        uint256 gasUsed = gasLimit - gasleft() + 7000;
        uint256 refundAmount = gasUsed * gasPrice;

        // We refund the relayer ...
        payable(relayer).transfer(refundAmount);
        // success = _call(relayer == address(0) ? tx.origin : relayer, refundAmount, new bytes(0), gasleft());
        // // If the transaction returns false, we revert ..
        // if (!success) revert LW__exec__refundFailure();
    }

    //9603
    /**
     * @dev Executes a series of generic transactions. It can only be called from exec.
     * @param transactions Basic transactions array (to, value, calldata).
     */
    function multiCall(Transaction[] calldata transactions) external onlyMe {
        uint256 transactionsLength = transactions.length;
        for (uint256 i = 0; i < transactionsLength; ) {
            Transaction calldata transaction = transactions[i];

            // We get the actual function selector to determine access ...
            bytes4 funcSelector = bytes4(transaction.callData);

            // access() checks if the wallet is locked for the owner or guardians and returns who has access ...
            Access access = access(funcSelector);

            // Only the owner is allowed to trigger a multiCall.
            // The signatures were already verified in 'exec', here we just need to make sure that access == owner.
            if (access != Access.Owner) revert LW__multiCall__notOwner();

            bool success = _call(transaction.to, transaction.value, transaction.callData, gasleft());

            // We do not revert the call if it fails, because the wallet needs to pay the relayer even in case of failure.
            (success);

            //@todo Return the success transactions and return data in an array.

            unchecked {
                // Won't overflow .... You would need way more gas usage than current available block gas (30m) to overflow it.
                ++i;
            }
        }
    }

    /**c
     * @dev Simulates a transaction. This should be called from the relayer, to verify that the transaction will not revert.
     * This does not guarantees 100% that the transaction will succeed, the state will be different next block.
     * @notice Needs to be called off-chain from  address zero.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        bytes calldata signatures
    ) external returns (uint256 totalGas) {
        if (nonce++ != _nonce) revert LW__simulateTransaction__invalidNonce();
        verifyTransaction(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit, signatures);
        bool success = _call(to, value, callData, gasleft());
        if (!success) revert LW__simulateTransaction__mainCallError();
        uint256 gasPrice = calculateGasPrice(maxFeePerGas, maxPriorityFeePerGas);
        uint256 gasUsed = gasLimit - gasleft() + 7000;
        uint256 refundAmount = gasUsed * gasPrice;
        success = _call(msg.sender, refundAmount, new bytes(0), gasleft());
        if (!success) revert LW__simulateTransaction__refundFailure();
        totalGas = gasLimit - gasleft();
        require(msg.sender == address(0), "Must be called off-chain from address zero.");
    }

    /**
     * @dev The transaction's hash. This is necessary to check that the signatures are correct and to avoid replay attacks.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32) {
        return keccak256(encodeOperation(to, value, callData, _nonce, maxFeePerGas, maxPriorityFeePerGas, gasLimit));
    }

    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = splitSigs(signature, 0);
        address recovered = returnSigner(hash, r, s, v, signature);

        // The guardians and recovery owners should not be able to sign transactions that are out of scope from this wallet.
        // Only the owner should be able to sign external data.
        if (recovered != owner) revert LaserWallet__invalidSignature();
        return EIP1271_MAGIC_VALUE;
    }

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    /**
     * @dev Verifies that the transaction is correct (signatures match the parameters).
     */
    function verifyTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        bytes calldata signatures
    ) internal view {
        // We encode the transaction data.
        bytes memory encodedData = encodeOperation(
            to,
            value,
            callData,
            _nonce,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasLimit
        );

        // Now we hash it ...
        bytes32 dataHash = keccak256(encodedData);

        // We get the actual function selector to determine access ...
        bytes4 funcSelector = bytes4(callData);

        // access() checks if the wallet is locked for the owner or guardians and returns who has access ...
        Access access = access(funcSelector);

        // We verify that the signatures are correct depending on the transaction type ...
        verifySignatures(access, dataHash, signatures);
    }

    /**
     * @dev Verifies that the signature(s) match the transaction type and sender.
     * @param _access Who has permission to invoke this transaction.
     * @param dataHash The keccak256 has of the transaction's data playload.
     * @param signatures The signature(s) of the hash.
     */
    function verifySignatures(
        Access _access,
        bytes32 dataHash,
        bytes calldata signatures
    ) internal view {
        // If it is the owner or guardian, then only 1 signature is required.
        // For all other operations, 2 signatures are required.
        uint256 requiredSignatures = _access == Access.Owner || _access == Access.Guardian ? 1 : 2;

        if (signatures.length < requiredSignatures * 65) revert LW__verifySignatures__invalidSignatureLength();

        address signer;
        bytes32 r;
        bytes32 s;
        uint8 v;

        for (uint256 i = 0; i < requiredSignatures; ) {
            (r, s, v) = splitSigs(signatures, i);

            signer = returnSigner(dataHash, r, s, v, signatures);

            if (_access == Access.Owner) {
                // If access == owner, the signer needs to be the owner.

                // We do not need further checks e.g 'is the wallet locked', they were done in 'access'.
                if (owner != signer) revert LW__verifySignatures__notOwner();
            } else if (_access == Access.Guardian) {
                // If access == guardian, the signer needs to be a guardian.

                // The guardian by itself can only lock the wallet, additional checks were done in 'access'.
                if (guardians[signer] == address(0)) revert LW__verifySignatures__notGuardian();
            } else if (_access == Access.OwnerAndGuardian) {
                // If access == owner and guardian, the first signer needs to be the owner.
                if (i == 0) {
                    // The first signer needs to be the owner.
                    if (owner != signer) revert LW__verifySignatures__notOwner();
                } else {
                    // The second signer needs to be a guardian.
                    if (guardians[signer] == address(0)) revert LW__verifySignatures__notGuardian();
                }
            } else if (_access == Access.RecoveryOwnerAndGuardian) {
                // If access == recovery owner and guardian, the first signer needs to be the recovery owner.

                // We do not need further checks, they were done in 'access'.
                if (i == 0) {
                    // The first signer needs to be a recovery owner.

                    // validateRecoveryOwner() handles all the necessary checks.
                    validateRecoveryOwner(signer);
                } else {
                    // The second signer needs to be a guardian.
                    if (guardians[signer] == address(0)) revert LW__verifySignatures__notGuardian();
                }
            } else if (_access == Access.OwnerAndRecoveryOwner) {
                // If access == owner and recovery owner, the first signer needs to be the owner.

                if (i == 0) {
                    if (owner != signer) revert LW__verifySignatures__notOwner();
                } else {
                    // The second signer needs to be the recovery owner.

                    // validateRecoveryOwner() handles all the necessary checks.
                    validateRecoveryOwner(signer);
                }
            } else {
                // This else statement should never reach.
                revert();
            }

            unchecked {
                // Won't overflow ...
                ++i;
            }
        }
    }

    function encodeOperation(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) internal view returns (bytes memory) {
        bytes32 opHash = keccak256(
            abi.encode(
                LASER_TYPE_STRUCTURE,
                to,
                value,
                keccak256(callData),
                _nonce,
                maxFeePerGas,
                maxPriorityFeePerGas,
                gasLimit
            )
        );

        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), opHash);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IERC165.sol";
import "../interfaces/ISingleton.sol";
import "./Me.sol";

/**
 * @title Singleton - Master copy contract. 
 */
contract Singleton is ISingleton, Me {
    ///@dev Singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    /// It should also always be ensured that the address is stored alone (uses a full word).
    address public singleton;

    /**
     * @dev Migrates to a new singleton (implementation).
     * @param _singleton New implementation address.
     */
    function upgradeSingleton(address _singleton) external onlyMe {
        if (_singleton == address(this)) revert Singleton__upgradeSingleton__incorrectAddress();

        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) {
            //bytes4(keccak256("I_AM_LASER")))
            revert Singleton__upgradeSingleton__notLaser();
        } else {
            assembly {
                // We store the singleton at storage slot 0 through inline assembly to save some gas and to be very explicit about slot positions.
                sstore(0, _singleton)
            }
            emit SingletonChanged(_singleton);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/IHandler.sol";
import "../interfaces/IERC165.sol";

/**
 * @title TokenHandler - Supports token callbacks.
 */
contract Handler is IHandler, IERC165 {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result) {
        return 0xbc197c81;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure {}

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
            _interfaceId == 0x1626ba7e || // EIP 1271
            _interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155
            _interfaceId == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
            _interfaceId == 0xae029e0b || // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
            _interfaceId == 0x150b7a02; // ERC721 onErc721Received
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title ILaserWallet
 * @author Rodrigo Herrera I.
 * @notice Has all the external functions, structs, events and errors for LaserWallet.sol.
 */
interface ILaserWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes callData;
    }

    event Received(address indexed sender, uint256 amount);
    event Setup(address owner, address[] recoveryOwners, address[] guardians);
    event ExecSuccess(address to, uint256 value, uint256 nonce);
    event ExecFailure(address to, uint256 value, uint256 nonce);

    ///@dev init() custom error.
    error LW__init__notOwner();
    error LW__init__refundFailure();

    ///@dev exec() custom errors.
    error LW__exec__invalidNonce();
    error LW__exec__refundFailure();

    ///@dev multiCall() custom error.
    error LW__multiCall__notOwner();

    ///@dev simulateTransaction() custom errors.
    error LW__simulateTransaction__invalidNonce();
    error LW__simulateTransaction__mainCallError();
    error LW__simulateTransaction__refundFailure();

    ///@dev isValidSignature() Laser custom error.
    error LaserWallet__invalidSignature();

    ///@dev verifySignatures() custom errors.
    error LW__verifySignatures__invalidSignatureLength();
    error LW__verifySignatures__notOwner();
    error LW__verifySignatures__notGuardian();

    /**
     * @dev Setup function, sets initial storage of contract.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwners Array of recovery owners. Implementation of Sovereign Social Recovery.
     * @param _guardians Addresses that can activate the social recovery mechanism.
     * @notice It can't be called after initialization.
     */
    function init(
        address _owner,
        address[] calldata _recoveryOwners,
        address[] calldata _guardians,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata ownerSignature
    ) external;

    /**
     * @dev Executes a generic transaction. It does not support 'delegatecall' for security reasons.
     * @param to Destination address.
     * @param value Amount to send.
     * @param callData Data payload for the transaction.
     * @param _nonce Unsigned integer to avoid replay attacks. It needs to match the current wallet's nonce.
     * @param maxFeePerGas Maximum amount that the user is willing to pay for a unit of gas.
     * @param maxPriorityFeePerGas Miner's tip.
     * @param gasLimit The transaction's gas limit. It needs to be the same as the actual transaction gas limit.
     * @param signatures The signatures of the transaction.
     * @notice If 'gasLimit' does not match the actual gas limit of the transaction, the relayer can incur losses.
     * It is the relayer's responsability to make sure that they are the same, the user does not get affected if a mistake is made.
     * We prefer to prioritize the user's safety (not overpay) over the relayer.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        address relayer,
        bytes calldata signatures
    ) external;

    /**
     * @dev Executes a series of generic transactions. It can only be called from exec.
     * @param transactions Basic transactions array (to, value, calldata).
     */
    function multiCall(Transaction[] calldata transactions) external;

    /**
     * @dev Simulates a transaction. This should be called from the relayer, to verify that the transaction will not revert.
     * This does not guarantees 100% that the transaction will succeed, the state will be different next block.
     * @notice Needs to be called off-chain from  address zero.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit,
        bytes calldata signatures
    ) external returns (uint256 totalGas);

    /**
     * @dev The transaction's hash. This is necessary to check that the signatures are correct and to avoid replay attacks.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasLimit
    ) external view returns (bytes32);

    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external returns (bytes4);

    /**
     * @dev Returns the chain id of this.
     */
    function getChainId() external view returns (uint256);

    /**
     * @dev Returns the domain separator of this.
     * @notice This is done to avoid replay attacks.
     */
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../core/Owner.sol";
import "../interfaces/IEIP1271.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ISSR.sol";
import "../utils/Utils.sol";

/**
 * @title SSR - Smart Social Recovery
 * @notice Laser's recovery mechanism.
 * @author Rodrigo Herrera I.
 */
contract SSR is ISSR, Owner, Utils {
    ///@dev pointer address for the nested mapping.
    address internal constant pointer = address(0x1);

    uint256 internal recoveryOwnerCount;

    uint256 internal guardianCount;

    uint256 public timeLock;

    bool public isLocked;

    ///@dev If guardians are locked, they cannot do any transaction.
    ///This is to completely prevent from guardians misbehaving.
    bool public guardiansLocked;

    // Recovery owners in a link list.
    mapping(address => address) internal recoveryOwners;

    // Guardians in a link list.
    mapping(address => address) internal guardians;

    /**
     * @dev Locks the wallet. Can only be called by a guardian.
     */
    function lock() external onlyMe {
        timeLock = block.timestamp;
        isLocked = true;
        emit WalletLocked();
    }

    /**
     * @dev Unlocks the wallet. Can only be called by the owner + a guardian.
     */
    function unlock() external onlyMe {
        timeLock = 0;
        isLocked = false;
        emit WalletUnlocked();
    }

    /**
     * @dev Unlocks the wallet. Can only be called by the owner + a recovery owner.
     * This is to avoid the wallet being locked forever if a guardian misbehaves.
     * The guardians will be locked until the owner decides otherwise.
     */
    function recoveryUnlock() external onlyMe {
        isLocked = false;
        guardiansLocked = true;
        emit RecoveryUnlocked();
    }

    /**
     * @dev Unlocks the guardians. Can only be called by the owner.
     */
    function unlockGuardians() external onlyMe {
        guardiansLocked = false;
    }

    /**
     * @dev Can only recover with the signature of a recovery owner and guardian.
     * @param newOwner The new owner address. This is generated instantaneously.
     */
    function recover(address newOwner) external onlyMe {
        timeLock = 0;
        isLocked = false;
        owner = newOwner;
        emit WalletRecovered(newOwner);
    }

    /**
     * @dev Adds a guardian to the wallet.
     * @param newGuardian Address of the new guardian.
     * @notice Can only be called by the owner.
     */
    function addGuardian(address newGuardian) external onlyMe {
        verifyNewRecoveryOwnerOrGuardian(newGuardian);
        guardians[newGuardian] = guardians[pointer];
        guardians[pointer] = newGuardian;

        unchecked {
            // If this overflows, this bug would be the least of the problems ..
            ++guardianCount;
        }
        emit NewGuardian(newGuardian);
    }

    /**
     * @dev Removes a guardian from the wallet.
     * @param prevGuardian Address of the previous guardian in the linked list.
     * @param guardianToRemove Address of the guardian to be removed.
     * @notice Can only be called by the owner.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove) external onlyMe {
        // There needs to be at least 2 guardian ...
        if (guardianCount - 2 < 1) revert SSR__removeGuardian__underflow();

        if (guardianToRemove == pointer) revert SSR__removeGuardian__invalidAddress();

        if (guardians[prevGuardian] != guardianToRemove) revert SSR__removeGuardian__incorrectPreviousGuardian();

        guardians[prevGuardian] = guardians[guardianToRemove];
        guardians[guardianToRemove] = address(0);

        unchecked {
            // Can't underflow, there needs to be more than 2 guardians to reach here.
            --guardianCount;
        }
        emit GuardianRemoved(guardianToRemove);
    }

    /**
     * @dev Swaps a guardian for a new address.
     * @param prevGuardian The address of the previous guardian in the link list.
     * @param newGuardian The address of the new guardian.
     * @param oldGuardian The address of the current guardian to be swapped by the new one.
     */
    function swapGuardian(
        address prevGuardian,
        address newGuardian,
        address oldGuardian
    ) external onlyMe {
        verifyNewRecoveryOwnerOrGuardian(newGuardian);
        if (guardians[prevGuardian] != oldGuardian) revert SSR__swapGuardian__invalidPrevGuardian();

        if (oldGuardian == pointer) revert SSR__swapGuardian__invalidOldGuardian();

        guardians[newGuardian] = guardians[oldGuardian];
        guardians[prevGuardian] = newGuardian;
        guardians[oldGuardian] = address(0);
        emit GuardianSwapped(newGuardian, oldGuardian);
    }

    /**
     * @dev Adds a recovery owner to the wallet.
     * @param newRecoveryOwner Address of the new recovery owner.
     * @notice Can only be called by the owner.
     */
    function addRecoveryOwner(address newRecoveryOwner) external onlyMe {
        verifyNewRecoveryOwnerOrGuardian(newRecoveryOwner);
        recoveryOwners[newRecoveryOwner] = recoveryOwners[pointer];
        recoveryOwners[pointer] = newRecoveryOwner;

        unchecked {
            // If this overflows, this bug would be the least of the problems ...
            ++recoveryOwnerCount;
        }
        emit NewRecoveryOwner(newRecoveryOwner);
    }

    /**
     * @dev Removes a recovery owner  to the wallet.
     * @param prevRecoveryOwner Address of the previous recovery owner in the linked list.
     * @param recoveryOwnerToRemove Address of the recovery owner to be removed.
     * @notice Can only be called by the owner.
     */
    function removeRecoveryOwner(address prevRecoveryOwner, address recoveryOwnerToRemove) external onlyMe {
        // There needs to be at least 2 recovery owners ...
        if (recoveryOwnerCount - 1 < 2) revert SSR__removeRecoveryOwner__underflow();

        if (recoveryOwnerToRemove == pointer) revert SSR__removeRecoveryOwner__invalidAddress();

        if (recoveryOwners[prevRecoveryOwner] != recoveryOwnerToRemove) {
            revert SSR__removeRecoveryOwner__incorrectPreviousRecoveryOwner();
        }

        recoveryOwners[prevRecoveryOwner] = recoveryOwners[recoveryOwnerToRemove];
        recoveryOwners[recoveryOwnerToRemove] = address(0);

        unchecked {
            // Can't underflow, there needs to be more than 2 recovery owners to reach here.
            --recoveryOwnerCount;
        }
        emit RecoveryOwnerRemoved(recoveryOwnerToRemove);
    }

    /**
     * @dev Swaps a recovery owner for a new address.
     * @param prevRecoveryOwner The address of the previous owner in the link list.
     * @param newRecoveryOwner The address of the new recovery owner.
     * @param oldRecoveryOwner The address of the current recovery owner to be swapped by the new one.
     */
    function swapRecoveryOwner(
        address prevRecoveryOwner,
        address newRecoveryOwner,
        address oldRecoveryOwner
    ) external onlyMe {
        verifyNewRecoveryOwnerOrGuardian(newRecoveryOwner);
        if (recoveryOwners[prevRecoveryOwner] != oldRecoveryOwner) {
            revert SSR__swapRecoveryOwner__invalidPrevRecoveryOwner();
        }

        if (oldRecoveryOwner == pointer) {
            revert SSR__swapRecoveryOwner__invalidOldRecoveryOwner();
        }

        recoveryOwners[newRecoveryOwner] = recoveryOwners[oldRecoveryOwner];
        recoveryOwners[prevRecoveryOwner] = newRecoveryOwner;
        recoveryOwners[oldRecoveryOwner] = address(0);
        emit RecoveryOwnerSwapped(newRecoveryOwner, oldRecoveryOwner);
    }

    /**
     * @param guardian Requested address.
     * @return Boolean if the address is a guardian of the current wallet.
     */
    function isGuardian(address guardian) external view returns (bool) {
        return guardian != pointer && guardians[guardian] != address(0);
    }

    /**
     * @param recoveryOwner Requested address.
     * @return Boolean if the address is a recovery owner of the current wallet.
     */
    function isRecoveryOwner(address recoveryOwner) external view returns (bool) {
        return recoveryOwner != pointer && recoveryOwners[recoveryOwner] != address(0);
    }

    /**
     * @return Array of the guardians of this wallet.
     */
    function getGuardians() external view returns (address[] memory) {
        address[] memory guardiansArray = new address[](guardianCount);
        address currentGuardian = guardians[pointer];

        uint256 index = 0;
        while (currentGuardian != pointer) {
            guardiansArray[index] = currentGuardian;
            currentGuardian = guardians[currentGuardian];
            unchecked {
                //Even if it is a view function, we reduce gas costs if it is called by another contract.
                ++index;
            }
        }
        return guardiansArray;
    }

    /**
     * @return Array of the recovery owners of this wallet.
     */
    function getRecoveryOwners() external view returns (address[] memory) {
        address[] memory recoveryOwnersArray = new address[](recoveryOwnerCount);
        address currentRecoveryOwner = recoveryOwners[pointer];

        uint256 index;
        while (currentRecoveryOwner != pointer) {
            recoveryOwnersArray[index] = currentRecoveryOwner;
            currentRecoveryOwner = recoveryOwners[currentRecoveryOwner];
            unchecked {
                // Even if it is a view function, we reduce gas costs if it is called by another contract.
                ++index;
            }
        }
        return recoveryOwnersArray;
    }

    /**
     * @dev Sets up the initial guardian configuration. Can only be called from the init function.
     * @param _guardians Array of guardians.
     */
    function initGuardians(address[] calldata _guardians) internal {
        uint256 guardiansLength = _guardians.length;
        // There needs to be at least 2 guardians.
        if (guardiansLength < 2) revert SSR__initGuardians__underflow();

        address currentGuardian = pointer;

        for (uint256 i = 0; i < guardiansLength; ) {
            address guardian = _guardians[i];
            unchecked {
                // If this overflows, this bug would be the least of the problems ...
                ++i;
            }
            guardians[currentGuardian] = guardian;
            currentGuardian = guardian;
            verifyNewRecoveryOwnerOrGuardian(guardian);
        }

        guardians[currentGuardian] = pointer;
        guardianCount = guardiansLength;
    }

    /**
     * @dev Inits the recovery owners.
     * @param _recoveryOwners Array of ricovery owners.
     * @notice There needs to be at least 2 recovery owners.
     */
    function initRecoveryOwners(address[] calldata _recoveryOwners) internal {
        uint256 recoveryOwnersLength = _recoveryOwners.length;
        // There needs to be at least 2 recovery owners.
        if (recoveryOwnersLength < 2) revert SSR__initRecoveryOwners__underflow();

        address currentRecoveryOwner = pointer;
        for (uint256 i = 0; i < recoveryOwnersLength; ) {
            address recoveryOwner = _recoveryOwners[i];
            recoveryOwners[currentRecoveryOwner] = recoveryOwner;
            currentRecoveryOwner = recoveryOwner;
            verifyNewRecoveryOwnerOrGuardian(recoveryOwner);

            unchecked {
                // If this overflows, this bug would be the least of the problems ...
                ++i;
            }
        }

        recoveryOwners[currentRecoveryOwner] = pointer;
        recoveryOwnerCount = recoveryOwnersLength;
    }

    /**
     * @dev Returns who has access to call a specific function.
     * @param funcSelector The function selector: bytes4(keccak256(...)).
     */
    function access(bytes4 funcSelector) internal view returns (Access) {
        if (funcSelector == this.lock.selector) {
            // Only a guardian can lock the wallet ...

            // If  guardians are locked, we revert ...
            if (guardiansLocked) revert SSR__access__guardiansLocked();
            else return Access.Guardian;
        } else if (funcSelector == this.unlock.selector) {
            // Only a guardian + the owner can unlock the wallet ...

            return Access.OwnerAndGuardian;
        } else if (funcSelector == this.recoveryUnlock.selector) {
            // This is in case a guardian is misbehaving ...

            //Only the owner + a recovery owner can trigger this ...
            return Access.OwnerAndRecoveryOwner;
        } else if (funcSelector == this.recover.selector) {
            // Only the recovery owner + the guardian can recover the wallet (change the owner keys) ...

            return Access.RecoveryOwnerAndGuardian;
        } else {
            // Else is the owner ... If the the wallet is locked, we revert ...

            if (isLocked) revert SSR__access__walletLocked();
            else return Access.Owner;
        }
    }

    /**
     * @dev Validates that a recovery owner can execute an operation 'now'.
     * @param signer The returned address from the provided signature and hash.
     */
    function validateRecoveryOwner(address signer) internal view {
        // Time elapsed since the recovery mechanism was activated.
        uint256 elapsedTime = block.timestamp - timeLock;
        address currentRecoveryOwner = recoveryOwners[pointer];
        bool authorized;
        uint256 index;

        while (currentRecoveryOwner != pointer) {
            if (elapsedTime > 1 weeks * index) {
                // Each recovery owner (index ordered) has access to sign the transaction after 1 week.
                // e.g. The first recovery owner (indexed 0) can sign immediately, the second recovery owner needs to wait 1 week, the third 2 weeks, and so on ...

                if (currentRecoveryOwner == signer) authorized = true;
            }
            currentRecoveryOwner = recoveryOwners[currentRecoveryOwner];

            unchecked {
                ++index;
            }
        }

        if (!authorized) revert SSR__validateRecoveryOwner__notAuthorized();
    }

    /**
     * @dev Checks that the provided address is correct for a new recovery owner or guardian.
     * @param toVerify The address to verify.
     */
    function verifyNewRecoveryOwnerOrGuardian(address toVerify) internal view {
        if (toVerify.code.length > 0) {
            // If the recovery owner is a smart contract wallet, it needs to support EIP1271.
            if (!IERC165(toVerify).supportsInterface(0x1626ba7e)) {
                revert SSR__verifyNewRecoveryOwnerOrGuardian__invalidAddress();
            }
        }

        if (
            toVerify == address(0) ||
            toVerify == owner ||
            guardians[toVerify] != address(0) ||
            recoveryOwners[toVerify] != address(0)
        ) revert SSR__verifyNewRecoveryOwnerOrGuardian__invalidAddress();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title IERC165
 * @notice Support of ERC165.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     * interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title ISingleton
 * @notice Has all the external functions, events and errors for Singleton.sol.
 */

interface ISingleton {
    event SingletonChanged(address indexed newSingleton);

    ///@dev upgradeSingleton() custom errors.
    error Singleton__upgradeSingleton__incorrectAddress();
    error Singleton__upgradeSingleton__notLaser();

    /**
     * @dev Migrates to a new singleton (implementation).
     * @param singleton New implementation address.
     */
    function upgradeSingleton(address singleton) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title Me - Only address(this) can perform certain operations.
 */
contract Me {
    error Me__notMe();

    modifier onlyMe() {
        if (msg.sender != address(this)) revert Me__notMe();

        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IHandler
 * @notice Has all the external functions for Handler.sol.
 */
interface IHandler {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 result);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result);

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IOwner.sol";
import "./Me.sol";

/**
 * @title Owner
 * @notice Handles the owners addresses.
 */
contract Owner is IOwner, Me {
    ///@dev owner should always bet at storage slot 1.
    address public owner;

    /**
     * @dev Changes the owner of the wallet.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external onlyMe {
        if (newOwner.code.length != 0 || newOwner == address(0) || newOwner == owner) {
            revert Owner__changeOwner__invalidOwnerAddress();
        }
        assembly {
            // We store the owner at storage slot 1 through inline assembly to save some gas and to be very explicit about slot positions.
            sstore(1, newOwner)
        }
        emit OwnerChanged(newOwner);
    }

    /**
     * @dev Inits the owner. This can only be called at creation.
     * @param _owner The owner of the wallet.
     */
    function initOwner(address _owner) internal {
        // If owner is not address 0, the wallet was already initialized ...
        if (owner != address(0)) revert Owner__initOwner__walletInitialized();

        if (_owner.code.length != 0 || _owner == address(0)) revert Owner__initOwner__invalidOwnerAddress();

        assembly {
            // We store the owner at storage slot 1 through inline assembly to save some gas and to be very explicit about slot positions.
            sstore(1, _owner)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IEIP1271
 * @notice Interface to call external contracts to validate signature.
 */
interface IEIP1271 {
    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title ISSR
 * @notice Has all the external functions, structs, events and errors for SSR.sol.
 */
interface ISSR {
    ///@dev Determines who has access to call a specific function.
    enum Access {
        Owner,
        Guardian,
        OwnerAndGuardian,
        RecoveryOwnerAndGuardian,
        OwnerAndRecoveryOwner
    }

    event WalletLocked();
    event WalletUnlocked();
    event RecoveryUnlocked();
    event NewGuardian(address newGuardian);
    event GuardianRemoved(address removedGuardian);
    event GuardianSwapped(address newGuardian, address oldGuardian);
    event NewRecoveryOwner(address newRecoveryOwner);
    event RecoveryOwnerRemoved(address removedRecoveryOwner);
    event RecoveryOwnerSwapped(address newRecoveryOwner, address oldRecoveryOwner);
    event WalletRecovered(address newOwner);

    ///@dev addGuardian() custom errors.
    error SSR__addGuardian__invalidAddress();

    ///@dev removeGuardian() custom errors.
    error SSR__removeGuardian__underflow();
    error SSR__removeGuardian__invalidAddress();
    error SSR__removeGuardian__incorrectPreviousGuardian();

    ///@dev swapRecoveryOwner() custom errors.
    error SSR__swapGuardian__invalidPrevGuardian();
    error SSR__swapGuardian__invalidOldGuardian();

    ///@dev addRecoveryOwner() custom error.
    error SSR__addRecoveryOwner__invalidAddress();

    ///@dev removeRecoveryOwner() custom errors.
    error SSR__removeRecoveryOwner__underflow();
    error SSR__removeRecoveryOwner__invalidAddress();
    error SSR__removeRecoveryOwner__incorrectPreviousRecoveryOwner();

    ///@dev swapRecoveryOwner() custom errors.
    error SSR__swapRecoveryOwner__invalidPrevRecoveryOwner();
    error SSR__swapRecoveryOwner__invalidOldRecoveryOwner();

    ///@dev initRecoveryOwners() custom error.
    error SSR__initRecoveryOwners__underflow();
    error SSR__initRecoveryOwners__invalidAddress();

    ///@dev initGuardians() custom errors.
    error SSR__initGuardians__underflow();
    error SSR__initGuardians__invalidAddress();

    ///@dev access() custom errors.
    error SSR__access__guardiansLocked();
    error SSR__access__walletLocked();

    ///@dev validateRecoveryOwner() custom error.
    error SSR__validateRecoveryOwner__notAuthorized();

    ///@dev verifyNewRecoveryOwnerOrGuardian() custom error.
    error SSR__verifyNewRecoveryOwnerOrGuardian__invalidAddress();

    /**
     * @dev Locks the wallet. Can only be called by a guardian.
     */
    function lock() external;

    /**
     * @dev Unlocks the wallet. Can only be called by a guardian + the owner.
     */
    function unlock() external;

    /**
     * @dev Unlocks the wallet. Can only be called by the owner + a recovery owner.
     * This is to avoid the wallet being locked forever if a guardian misbehaves.
     * The guardians will be locked until the owner decides otherwise.
     */
    function recoveryUnlock() external;

    /**
     * @dev Unlocks the guardians. Can only be called by the owner.
     */
    function unlockGuardians() external;

    /**
     * @dev Can only recover with the signature of a recovery owner and guardian.
     * @param newOwner The new owner address. This is generated instantaneously.
     */
    function recover(address newOwner) external;

    /**
     * @dev Adds a guardian to the wallet.
     * @param newGuardian Address of the new guardian.
     * @notice Can only be called by the owner.
     */
    function addGuardian(address newGuardian) external;

    /**
     * @dev Removes a guardian to the wallet.
     * @param prevGuardian Address of the previous guardian in the linked list.
     * @param guardianToRemove Address of the guardian to be removed.
     * @notice Can only be called by the owner.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove) external;

    /**
     * @dev Swaps a guardian for a new address.
     * @param prevGuardian The address of the previous guardian in the link list.
     * @param newGuardian The address of the new guardian.
     * @param oldGuardian The address of the current guardian to be swapped by the new one.
     */
    function swapGuardian(
        address prevGuardian,
        address newGuardian,
        address oldGuardian
    ) external;

    /**
     * @dev Adds a recovery owner to the wallet.
     * @param newRecoveryOwner Address of the new recovery owner.
     * @notice Can only be called by the owner.
     */
    function addRecoveryOwner(address newRecoveryOwner) external;

    /**
     * @dev Removes a recovery owner  to the wallet.
     * @param prevRecoveryOwner Address of the previous recovery owner in the linked list.
     * @param recoveryOwnerToRemove Address of the recovery owner to be removed.
     * @notice Can only be called by the owner.
     */
    function removeRecoveryOwner(address prevRecoveryOwner, address recoveryOwnerToRemove) external;

    /**
     * @dev Swaps a recovery owner for a new address.
     * @param prevRecoveryOwner The address of the previous owner in the link list.
     * @param newRecoveryOwner The address of the new recovery owner.
     * @param oldRecoveryOwner The address of the current recovery owner to be swapped by the new one.
     */
    function swapRecoveryOwner(
        address prevRecoveryOwner,
        address newRecoveryOwner,
        address oldRecoveryOwner
    ) external;

    /**
     * @param guardian Requested address.
     * @return Boolean if the address is a guardian of the current wallet.
     */
    function isGuardian(address guardian) external view returns (bool);

    /**
     * @param recoveryOwner Requested address.
     * @return Boolean if the address is a recovery owner of the current wallet.
     */
    function isRecoveryOwner(address recoveryOwner) external view returns (bool);

    /**
     * @return Array of the guardians of this wallet.
     */
    function getGuardians() external view returns (address[] memory);

    /**
     * @return Array of the recovery owners of this wallet.
     */
    function getRecoveryOwners() external view returns (address[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IUtils.sol";
import "../interfaces/IEIP1271.sol";

/**
 * @title Utils - Helper functions for Laser wallet.
 */
contract Utils is IUtils {
    /**
     * @dev Returns the signer of the hash.
     * @param dataHash The hash that was signed.
     */
    function returnSigner(
        bytes32 dataHash,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory signatures
    ) public view returns (address signer) {
        if (v == 0) {
            // If v is 0, then it is a contract signature.
            // The address of the contract is encoded into r.
            signer = address(uint160(uint256(r)));

            // // The actual signature.
            bytes memory contractSignature;

            assembly {
                contractSignature := add(add(signatures, s), 0x20)
            }

            if (IEIP1271(signer).isValidSignature(dataHash, contractSignature) != 0x1626ba7e) {
                revert Utils__returnSigner__invalidContractSignature();
            }
        } else if (v > 30) {
            signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
        } else {
            signer = ecrecover(dataHash, v, r, s);
        }

        if (signer == address(0)) revert Utils__returnSigner__invalidSignature();
    }

    /**
     * @dev Returns the r, s and v of the signature.
     * @param signatures Signature.
     * @param pos Which signature to read.
     */
    function splitSigs(bytes memory signatures, uint256 pos)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            let sigPos := mul(0x41, pos)
            r := mload(add(signatures, add(sigPos, 0x20)))
            s := mload(add(signatures, add(sigPos, 0x40)))
            v := byte(0, mload(add(signatures, add(sigPos, 0x60))))
        }
    }

    /**
     * @dev Calls a target address, sends value and / or data payload.
     * @param to Destination address.
     * @param value Amount to send in ETH.
     * @param data Data payload.
     * @param txGas Amount of gas to forward.
     */
    function _call(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            // We execute a call to the target address and return boolean...
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    /**
     * @dev Calculates the gas price.
     */
    function calculateGasPrice(uint256 maxFeePerGas, uint256 maxPriorityFeePerGas)
        internal
        view
        returns (uint256 gasPrice)
    {
        if (maxFeePerGas == 0 && maxPriorityFeePerGas == 0) {
            // When guardians / recovery owners sign.
            gasPrice = tx.gasprice;
        } else if (maxFeePerGas == maxPriorityFeePerGas) {
            // Legacy mode.
            gasPrice = maxFeePerGas;
        } else {
            gasPrice = min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IOwner
 * @notice Has all the external functions, events and errors for Owner.sol.
 */
interface IOwner {
    event OwnerChanged(address newOwner);

    ///@dev changeOwner() custom error.
    error Owner__changeOwner__invalidOwnerAddress();

    ///@dev initOwner() custom errors.
    error Owner__initOwner__walletInitialized();
    error Owner__initOwner__invalidOwnerAddress();

    /**
     * @dev Changes the owner of the wallet.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IUtils
 * @notice Has all the external functions and errors for Utils.sol.
 */
interface IUtils {
    ///@dev returnSigner() custom error.
    error Utils__returnSigner__invalidSignature();
    error Utils__returnSigner__invalidContractSignature();

    /**
     * @dev Returns the signer of the hash.
     * @param dataHash The hash that was signed.
     */
    function returnSigner(
        bytes32 dataHash,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory signatures
    ) external view returns (address signer);

    /**
     * @dev Returns the r, s and v of the signature.
     * @param signatures Signature.
     * @param pos Which signature to read.
     */
    function splitSigs(bytes memory signatures, uint256 pos)
        external
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        );
}