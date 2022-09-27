// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "./handlers/Handler.sol";
import "./interfaces/ILaserWallet.sol";
import "./state/LaserState.sol";

/**
 * @title  LaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a secure smart contract wallet (vault) made for the Ethereum Virtual Machine.
 */
contract LaserWallet is ILaserWallet, LaserState, Handler {
    /*//////////////////////////////////////////////////////////////
                             LASER METADATA
    //////////////////////////////////////////////////////////////*/

    string public constant VERSION = "1.0.0";

    string public constant NAME = "Laser Wallet";

    /*//////////////////////////////////////////////////////////////
                            SIGNATURE TYPES
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256("LaserOperation(address to,uint256 value,bytes callData,uint256 nonce)");

    /**
     * @dev Sets the owner of the implementation address (singleton) to 'this'.
     *      This will make the base contract unusable, even though it does not have 'delegatecall'.
     */
    constructor() {
        owner = address(this);
    }

    receive() external payable {}

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner           The owner of the wallet.
     * @param _guardians       Array of guardians.
     * @param _recoveryOwners  Array of recovery owners.
     * @param ownerSignature   Signature of the owner that validates the correctness of the address.
     */
    function init(
        address _owner,
        address[] calldata _guardians,
        address[] calldata _recoveryOwners,
        bytes calldata ownerSignature
    ) external {
        // activateWallet verifies that the current owner is address 0, reverts otherwise.
        // This is more than enough to avoid being called after initialization.
        activateWallet(_owner, _guardians, _recoveryOwners);

        // This is primarily to verify that the owner address is correct.
        // It also provides some extra security guarantes (the owner really approved the guardians and recovery owners).
        bytes32 signedHash = keccak256(abi.encodePacked(_guardians, _recoveryOwners, block.chainid));

        address signer = Utils.returnSigner(signedHash, ownerSignature, 0);

        if (signer != _owner) revert LW__init__notOwner();
    }

    /**
     * @notice Executes a generic transaction.
     *         The transaction is required to be signed by the owner + recovery owner or owner + guardian
     *         while the wallet is not locked.
     *
     * @param to         Destination address.
     * @param value      Amount in WEI to transfer.
     * @param callData   Data payload to send.
     * @param _nonce     Anti-replay number.
     * @param signatures Signatures of the hash of the transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        bytes calldata signatures
    ) public returns (bool success) {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__exec__invalidNonce();
        }

        if (walletConfig.isLocked) {
            verifyTimelock();
        }

        // We get the hash for this transaction.
        bytes32 signedHash = keccak256(encodeOperation(to, value, callData, _nonce));

        if (signatures.length < 130) revert LW__exec__invalidSignatureLength();

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        address signer2 = Utils.returnSigner(signedHash, signatures, 1);

        if (signer1 != owner || (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))) {
            revert LW__exec__invalidSignature();
        }

        success = Utils.call(to, value, callData, gasleft());
        if (!success) revert LW__exec__callFailed();

        emit ExecSuccess(to, value, nonce, bytes4(callData));
    }

    /**
     * @notice Executes a batch of transactions.
     *
     * @param transactions An array of Laser transactions.
     */
    function multiCall(Transaction[] calldata transactions) external {
        uint256 transactionsLength = transactions.length;

        // @todo custom errors and optimization.
        // This is a mockup, not final.
        for (uint256 i = 0; i < transactionsLength; ) {
            Transaction calldata transaction = transactions[i];

            exec(transaction.to, transaction.value, transaction.callData, transaction.nonce, transaction.signatures);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Triggers the recovery mechanism.
     *
     * @param callData   Data payload, can only be either lock(), unlock() or recover(address).
     * @param signatures Signatures of the hash of the transaction.
     */
    function recovery(
        uint256 _nonce,
        bytes calldata callData,
        bytes calldata signatures
    ) external {
        // We immediately increase the nonce to avoid replay attacks.
        unchecked {
            if (nonce++ != _nonce) revert LW__recovery__invalidNonce();
        }

        bytes4 functionSelector = bytes4(callData);

        // All calls require at least 2 signatures.
        if (signatures.length < 130) revert LW__recovery__invalidSignatureLength();

        bytes32 signedHash = keccak256(abi.encodePacked(_nonce, keccak256(callData), address(this), block.chainid));

        address signer1 = Utils.returnSigner(signedHash, signatures, 0);
        address signer2 = Utils.returnSigner(signedHash, signatures, 1);

        if (signer1 == signer2) revert LW__recovery__duplicateSigner();

        if (functionSelector == 0xa69df4b5) {
            // bytes4(keccak256("unlock()"))

            // Only the old owner + recovery owner || old owner + guardian can unlock the wallet.

            if (
                signer1 != walletConfig.oldOwner ||
                (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))
            ) {
                revert LW__recoveryUnlock__invalidSignature();
            }

            // It can only be called during the time delay.
            uint256 elapsedTime = block.timestamp - walletConfig.timestamp;
            if (2 days < elapsedTime) revert LW__recoveryUnlock__time();
        } else if (functionSelector == 0x0cd865ec) {
            // bytes4(keccak256("recover(address)"))

            // Only the recovery owner + recovery owner || recovery owner + guardian can recover the wallet.
            if (
                recoveryOwners[signer1] == address(0) ||
                (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))
            ) revert LW__recoveryRecover__invalidSignature();

            // Can't be called once the recovery period is activated.
            if (walletConfig.timestamp > 0) revert LW__recoveryRecover__walletLocked();
        } else {
            // Else, the operation is not allowed.
            revert LW__recovery__invalidOperation();
        }

        bool success = Utils.call(address(this), 0, callData, gasleft());
        if (!success) revert LW__recovery__callFailed();
    }

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) external view returns (bytes32) {
        return keccak256(encodeOperation(to, value, callData, _nonce));
    }

    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4) {
        address signer1 = Utils.returnSigner(hash, signature, 0);
        address signer2 = Utils.returnSigner(hash, signature, 1);

        if (signer1 != owner || (recoveryOwners[signer2] == address(0) && guardians[signer2] == address(0))) {
            revert LaserWallet__invalidSignature();
        }

        // bytes4(keccak256("isValidSignature(bytes32,bytes)")
        return 0x1626ba7e;
    }

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() public view returns (uint256 chainId) {
        return block.chainid;
    }

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    /**
     * @notice Encodes the transaction data.
     */
    function encodeOperation(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) internal view returns (bytes memory) {
        bytes32 opHash = keccak256(abi.encode(LASER_TYPE_STRUCTURE, to, value, keccak256(callData), _nonce));

        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), opHash);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title Access
 *
 * @author Inspired by Gnosis Safe.
 *
 * @notice Modifier that only allows this contract to be the 'msg.sender'.
 */
contract Access {
    error Access__notAllowed();

    modifier access() {
        if (msg.sender != address(this)) revert Access__notAllowed();

        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../interfaces/IEIP1271.sol";

/**
 * @title Utils
 *
 * @notice Helper functions for Laser wallet.
 */
library Utils {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error Utils__returnSigner__invalidSignature();

    error Utils__returnSigner__invalidContractSignature();

    /**
     * @param signedHash  The hash that was signed.
     * @param signatures  Result of signing the has.
     * @param pos         Position of the signer.
     *
     * @return signer      Address that signed the hash.
     */
    function returnSigner(
        bytes32 signedHash,
        bytes memory signatures,
        uint256 pos
    ) internal view returns (address signer) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = splitSigs(signatures, pos);

        if (v == 0) {
            // If v is 0, then it is a contract signature.
            // The address of the contract is encoded into r.
            signer = address(uint160(uint256(r)));

            // The signature(s) of the EOA's that control the target contract.
            bytes memory contractSignature;

            assembly {
                contractSignature := add(signatures, s)
            }

            if (IEIP1271(signer).isValidSignature(signedHash, contractSignature) != 0x1626ba7e) {
                revert Utils__returnSigner__invalidContractSignature();
            }
        } else if (v > 30) {
            signer = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", signedHash)),
                v - 4,
                r,
                s
            );
        } else {
            signer = ecrecover(signedHash, v, r, s);
        }

        if (signer == address(0)) revert Utils__returnSigner__invalidSignature();
    }

    /**
     * @dev Returns the r, s and v values of the signature.
     *
     * @param pos Which signature to read.
     */
    function splitSigs(bytes memory signatures, uint256 pos)
        internal
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
     *
     * @param to        Destination address.
     * @param value     Amount in WEI to transfer.
     * @param callData  Data payload for the transaction.
     */
    function call(
        address to,
        uint256 value,
        bytes memory callData,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(callData, 0x20), mload(callData), 0, 0)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../interfaces/IHandler.sol";
import "../interfaces/IERC165.sol";

/**
 * @title Handler
 *
 * @notice Supports token callbacks.
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
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            _interfaceId == 0x1626ba7e || // EIP 1271.
            _interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            _interfaceId == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support.
            _interfaceId == 0xae029e0b || // Laser Wallet contract: bytes4(keccak256("I_AM_LASER")).
            _interfaceId == 0x150b7a02; // ERC721 onErc721Received.
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IEIP1271
 *
 * @notice Interface to call external contracts to validate signature.
 */
interface IEIP1271 {
    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title IERC165
 * @notice Support of ERC165.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     *
     * @param interfaceID The interface identifier, as specified in ERC-165
     *
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     *
     * @return `true` if the contract implements `interfaceID` and
     * interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IHandler
 *
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
pragma solidity 0.8.16;

/**
 * @notice Wallet configuration for the recovery mechanism.
 *
 * @param isLocked  Boolean if the wallet is currently locked.
 * @param timestamp The time (block.timestamp) when the wallet was locked.
 */
struct WalletConfig {
    bool isLocked;
    uint256 timestamp;
    address oldOwner;
}

/**
 * @title   LaserState
 *
 * @author  Rodrigo Herrera I.
 *
 * @notice  Has all the state(storage) for a Laser wallet and implements
 *          Smart Social Recovery.
 *
 * @dev    This interface has all events, errors, and external function for LaserState.
 */
interface ILaserState {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event WalletUnlocked();

    event RecoverActivated(address newOwner);

    event OwnerChanged(address newOwner);

    event SingletonChanged(address newSingleton);

    event NewGuardian(address newGuardian);

    event GuardianRemoved(address removedGuardian);

    event NewRecoveryOwner(address NewRecoveryOwner);

    event RecoveryOwnerRemoved(address removedRecoveryOwner);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LS__recover__invalidAddress();

    error LS__changeOwner__invalidAddress();

    error LS__changeSingleton__invalidAddress();

    error LS__addGuardian__invalidAddress();

    error LS__removeGuardian__invalidAddress();

    error LS__removeGuardian__incorrectPreviousGuardian();

    error LS__removeGuardian__underflow();

    error LS__addRecoveryOwner__invalidAddress();

    error LS__removeRecoveryOwner__invalidAddress();

    error LS__removeRecoveryOwner__incorrectPreviousGuardian();

    error LS__verifyTimeLock__timeLock();

    error LS__removeRecoveryOwner__underflow();

    error LS__initGuardians__underflow();

    error LS__initGuardians__invalidAddress();

    error LS__initRecoveryOwners__underflow();

    error LS__initRecoveryOwners__invalidAddress();

    error LS__activateWallet__walletInitialized();

    error LS__activateWallet__invalidOwnerAddress();

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    function singleton() external view returns (address);

    function owner() external view returns (address);

    function nonce() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Unlocks the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev    Restricted, can only be called by address(this).
     */
    function unlock() external;

    /**
     * @notice Recovers the wallet. Can only be called by the recovery owner + recovery owner
     *         or recovery owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function recover(address newOwner) external;

    /**
     * @notice Changes the owner of the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function changeOwner(address newOwner) external;

    /**
     * @notice Changes the singleton. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newSingleton  Address of the new singleton.
     */
    function changeSingleton(address newSingleton) external;

    /**
     * @notice Adds a new guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newGuardian  Address of the new guardian.
     */
    function addGuardian(address newGuardian) external;

    /**
     * @notice Removes a guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevGuardian      Address of the previous guardian in the linked list.
     * @param guardianToRemove  Address of the guardian to be removed.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove) external;

    /**
     * @notice Adds a new recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newRecoveryOwner  Address of the new recovery owner.
     */
    function addRecoveryOwner(address newRecoveryOwner) external;

    /**
     * @notice Removes a recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevRecoveryOwner      Address of the previous recovery owner in the linked list.
     * @param recoveryOwnerToRemove  Address of the recovery owner to be removed.
     */
    function removeRecoveryOwner(address prevRecoveryOwner, address recoveryOwnerToRemove) external;

    /**
     * @return Array of guardians for this wallet.
     */
    function getGuardians() external view returns (address[] memory);

    /**
     * @return Array of recovery owners for this wallet.
     */
    function getRecoveryOwners() external view returns (address[] memory);

    /**
     * @return
     * configTimestamp  Time when the recover was triggered.
     * _isLocked        Boolean if the wallet is currently locked.
     */
    function getConfig()
        external
        view
        returns (
            uint256 configTimestamp,
            bool _isLocked,
            address oldOwner
        );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

struct Transaction {
    address to;
    uint256 value;
    bytes callData;
    uint256 nonce;
    bytes signatures;
}

/**
 * @title  ILaserWallet
 *
 * @author Rodrigo Herrera I.
 *
 * @notice Laser is a secure smart contract wallet (vault) made for the Ethereum Virtual Machine.
 *
 * @dev    This interface has all events, errors, and external function for LaserWallet.
 */
interface ILaserWallet {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ExecSuccess(address to, uint256 value, uint256 nonce, bytes4 funcSig);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LW__init__notOwner();

    error LW__exec__invalidNonce();

    error LW__exec__walletLocked();

    error LW__exec__invalidSignatureLength();

    error LW__exec__invalidSignature();

    error LW__exec__callFailed();

    error LW__recovery__invalidNonce();

    error LW__recovery__invalidSignatureLength();

    error LW__recovery__duplicateSigner();

    error LW__recoveryLock__invalidSignature();

    error LW__recoveryUnlock__time();

    error LW__recoveryUnlock__invalidSignature();

    error LW__recoveryRecover__walletLocked();

    error LW__recoveryRecover__invalidSignature();

    error LW__recovery__invalidOperation();

    error LW__recovery__callFailed();

    error LaserWallet__invalidSignature();

    /*//////////////////////////////////////////////////////////////
                                EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Setup function, sets initial storage of the wallet.
     *         It can't be called after initialization.
     *
     * @param _owner           The owner of the wallet.
     * @param _guardians       Array of guardians.
     * @param _recoveryOwners  Array of recovery owners.
     * @param ownerSignature   Signature of the owner that validates the correctness of the address.
     */
    function init(
        address _owner,
        address[] calldata _guardians,
        address[] calldata _recoveryOwners,
        bytes calldata ownerSignature
    ) external;

    /**
     * @notice Executes a generic transaction.
     *         The transaction is required to be signed by the owner + recovery owner or owner + guardian
     *         while the wallet is not locked.
     *
     * @param to         Destination address.
     * @param value      Amount in WEI to transfer.
     * @param callData   Data payload to send.
     * @param _nonce     Anti-replay number.
     * @param signatures Signatures of the hash of the transaction.
     */
    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        bytes calldata signatures
    ) external returns (bool success);

    /**
     * @notice Executes a batch of transactions.
     *
     * @param transactions An array of Laser transactions.
     */
    function multiCall(Transaction[] calldata transactions) external;

    /**
     * @notice Triggers the recovery mechanism.
     *
     * @param callData   Data payload, can only be either lock(), unlock() or recover().
     * @param signatures Signatures of the hash of the transaction.
     */
    function recovery(
        uint256 _nonce,
        bytes calldata callData,
        bytes calldata signatures
    ) external;

    /**
     * @notice Returns the hash to be signed to execute a transaction.
     */
    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce
    ) external view returns (bytes32);

    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() external view returns (uint256 chainId);

    /**
     * @notice Domain separator for this wallet.
     */
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../access/Access.sol";
import "../common/Utils.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ILaserState.sol";

/**
 * @title   LaserState
 *
 * @author  Rodrigo Herrera I.
 *
 * @notice  Has all the state(storage) for a Laser wallet and implements
 *          Smart Social Recovery.
 */
contract LaserState is ILaserState, Access {
    address internal constant POINTER = address(0x1); // POINTER for the link list.

    /*//////////////////////////////////////////////////////////////
                          LASER WALLET STORAGE
    //////////////////////////////////////////////////////////////*/

    address public singleton;

    address public owner;

    uint256 public nonce;

    uint256 internal guardianCount;

    uint256 internal recoveryOwnerCount;

    mapping(address => address) public guardians;

    mapping(address => address) public recoveryOwners;

    WalletConfig walletConfig;

    /**
     * @notice Unlocks the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev    Restricted, can only be called by address(this).
     */
    function unlock() external access {
        address oldOwner = walletConfig.oldOwner;
        owner = oldOwner;

        walletConfig.isLocked = false;
        walletConfig.timestamp = 0;
        walletConfig.oldOwner = address(0);

        emit WalletUnlocked();
        emit OwnerChanged(oldOwner);
    }

    /**
     * @notice Recovers the wallet. Can only be called by the recovery owner + recovery owner
     *         or recovery owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function recover(address newOwner) external access {
        if (newOwner.code.length != 0 || newOwner == owner || newOwner == address(0)) {
            revert LS__recover__invalidAddress();
        }

        walletConfig.isLocked = true;
        walletConfig.timestamp = block.timestamp;
        walletConfig.oldOwner = owner;

        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    /**
     * @notice Changes the owner of the wallet. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newOwner  Address of the new owner.
     */
    function changeOwner(address newOwner) external access {
        if (newOwner.code.length != 0 || newOwner == owner || newOwner == address(0)) {
            revert LS__changeOwner__invalidAddress();
        }

        owner = newOwner;

        emit OwnerChanged(newOwner);
    }

    /**
     * @notice Changes the singleton. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newSingleton  Address of the new singleton.
     */
    function changeSingleton(address newSingleton) external access {
        //bytes4(keccak256("I_AM_LASER"))
        if (
            newSingleton == singleton ||
            newSingleton == address(this) ||
            !IERC165(newSingleton).supportsInterface(0xae029e0b)
        ) revert LS__changeSingleton__invalidAddress();

        singleton = newSingleton;

        emit SingletonChanged(newSingleton);
    }

    /**
     * @notice Adds a new guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newGuardian  Address of the new guardian.
     */
    function addGuardian(address newGuardian) external access {
        if (
            newGuardian == address(0) ||
            newGuardian == owner ||
            guardians[newGuardian] != address(0) ||
            recoveryOwners[newGuardian] != address(0) ||
            newGuardian == POINTER
        ) revert LS__addGuardian__invalidAddress();

        if (newGuardian.code.length > 0) {
            if (!IERC165(newGuardian).supportsInterface(0x1626ba7e)) {
                revert LS__addGuardian__invalidAddress();
            }
        }

        guardians[newGuardian] = guardians[POINTER];
        guardians[POINTER] = newGuardian;

        unchecked {
            guardianCount++;
        }

        emit NewGuardian(newGuardian);
    }

    /**
     * @notice Removes a guardian. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevGuardian      Address of the previous guardian in the linked list.
     * @param guardianToRemove  Address of the guardian to be removed.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove) external access {
        if (guardianToRemove == POINTER) {
            revert LS__removeGuardian__invalidAddress();
        }

        if (guardians[prevGuardian] != guardianToRemove) {
            revert LS__removeGuardian__incorrectPreviousGuardian();
        }

        // There needs to be at least 1 guardian.
        if (guardianCount - 1 < 1) revert LS__removeGuardian__underflow();

        guardians[prevGuardian] = guardians[guardianToRemove];
        guardians[guardianToRemove] = address(0);

        unchecked {
            guardianCount--;
        }

        emit GuardianRemoved(guardianToRemove);
    }

    /**
     * @notice Adds a new recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param newRecoveryOwner  Address of the new recovery owner.
     */
    function addRecoveryOwner(address newRecoveryOwner) external access {
        if (
            newRecoveryOwner == address(0) ||
            newRecoveryOwner == owner ||
            recoveryOwners[newRecoveryOwner] != address(0) ||
            guardians[newRecoveryOwner] != address(0) ||
            newRecoveryOwner == POINTER
        ) revert LS__addRecoveryOwner__invalidAddress();

        if (newRecoveryOwner.code.length > 0) {
            if (!IERC165(newRecoveryOwner).supportsInterface(0x1626ba7e)) {
                revert LS__addRecoveryOwner__invalidAddress();
            }
        }

        recoveryOwners[newRecoveryOwner] = recoveryOwners[POINTER];
        recoveryOwners[POINTER] = newRecoveryOwner;

        unchecked {
            recoveryOwnerCount++;
        }

        emit NewRecoveryOwner(newRecoveryOwner);
    }

    /**
     * @notice Removes a recovery owner. Can only be called by the owner + recovery owner
     *         or owner + guardian.
     *
     * @dev   Restricted, can only be called by address(this).
     *
     * @param prevRecoveryOwner      Address of the previous recovery owner in the linked list.
     * @param recoveryOwnerToRemove  Address of the recovery owner to be removed.
     */
    function removeRecoveryOwner(address prevRecoveryOwner, address recoveryOwnerToRemove) external access {
        if (recoveryOwnerToRemove == POINTER) {
            revert LS__removeRecoveryOwner__invalidAddress();
        }

        if (recoveryOwners[prevRecoveryOwner] != recoveryOwnerToRemove) {
            revert LS__removeRecoveryOwner__incorrectPreviousGuardian();
        }

        // There needs to be at least 1 recovery owner.
        if (recoveryOwnerCount - 1 < 1) revert LS__removeRecoveryOwner__underflow();

        recoveryOwners[prevRecoveryOwner] = recoveryOwners[recoveryOwnerToRemove];
        recoveryOwners[recoveryOwnerToRemove] = address(0);

        unchecked {
            recoveryOwnerCount--;
        }

        emit RecoveryOwnerRemoved(recoveryOwnerToRemove);
    }

    /**
     * @return Array of guardians for this wallet.
     */
    function getGuardians() external view returns (address[] memory) {
        address[] memory guardiansArray = new address[](guardianCount);
        address currentGuardian = guardians[POINTER];

        uint256 index = 0;
        while (currentGuardian != POINTER) {
            guardiansArray[index] = currentGuardian;
            currentGuardian = guardians[currentGuardian];
            index++;
        }
        return guardiansArray;
    }

    /**
     * @return Array of recovery owners for this wallet.
     */
    function getRecoveryOwners() external view returns (address[] memory) {
        address[] memory recoveryOwnersArray = new address[](recoveryOwnerCount);
        address currentRecoveryOwner = recoveryOwners[POINTER];

        uint256 index = 0;
        while (currentRecoveryOwner != POINTER) {
            recoveryOwnersArray[index] = currentRecoveryOwner;
            currentRecoveryOwner = recoveryOwners[currentRecoveryOwner];
            index++;
        }
        return recoveryOwnersArray;
    }

    /**
     * @return
     * configTimestamp  Time when the recover was triggered.
     * _isLocked        Boolean if the wallet is currently locked.
     */
    function getConfig()
        external
        view
        returns (
            uint256 configTimestamp,
            bool _isLocked,
            address oldOwner
        )
    {
        configTimestamp = walletConfig.timestamp;
        _isLocked = walletConfig.isLocked;
        oldOwner = walletConfig.oldOwner;
    }

    /**
     * @notice Verifies that the time delay has passed.
     */
    function verifyTimelock() internal {
        uint256 elapsedTime = block.timestamp - walletConfig.timestamp;
        if (2 days > elapsedTime) revert LS__verifyTimeLock__timeLock();

        walletConfig.isLocked = false;
        walletConfig.timestamp = 0;
        walletConfig.oldOwner = address(0);
    }

    /**
     * @notice Inits the guardians.
     *
     * @param _guardians Array of guardian addresses.
     */
    function initGuardians(address[] calldata _guardians) internal {
        uint256 guardiansLength = _guardians.length;
        // There needs to be at least 1 guardian.
        if (guardiansLength < 1) revert LS__initGuardians__underflow();

        address currentGuardian = POINTER;

        for (uint256 i = 0; i < guardiansLength; ) {
            address guardian = _guardians[i];
            if (
                guardian == owner ||
                guardian == address(0) ||
                guardian == POINTER ||
                guardian == currentGuardian ||
                guardians[guardian] != address(0)
            ) revert LS__initGuardians__invalidAddress();

            if (guardian.code.length > 0) {
                // If the guardian is a smart contract wallet, it needs to support EIP1271.
                if (!IERC165(guardian).supportsInterface(0x1626ba7e)) {
                    revert LS__initGuardians__invalidAddress();
                }
            }

            unchecked {
                i++;
            }
            guardians[currentGuardian] = guardian;
            currentGuardian = guardian;
        }

        guardians[currentGuardian] = POINTER;
        guardianCount = guardiansLength;
    }

    /**
     * @notice Inits the recovery owners.
     *
     * @param _recoveryOwners Array of recovery owner addresses.
     */
    function initRecoveryOwners(address[] calldata _recoveryOwners) internal {
        uint256 recoveryOwnersLength = _recoveryOwners.length;
        // There needs to be at least 1 recovery owner.
        if (recoveryOwnersLength < 1) revert LS__initRecoveryOwners__underflow();

        address currentRecoveryOwner = POINTER;

        for (uint256 i = 0; i < recoveryOwnersLength; ) {
            address recoveryOwner = _recoveryOwners[i];
            if (
                recoveryOwner == owner ||
                recoveryOwner == address(0) ||
                recoveryOwner == POINTER ||
                recoveryOwner == currentRecoveryOwner ||
                recoveryOwners[recoveryOwner] != address(0) ||
                guardians[recoveryOwner] != address(0)
            ) revert LS__initRecoveryOwners__invalidAddress();

            if (recoveryOwner.code.length > 0) {
                // If the recovery owner is a smart contract wallet, it needs to support EIP1271.
                if (!IERC165(recoveryOwner).supportsInterface(0x1626ba7e)) {
                    revert LS__initRecoveryOwners__invalidAddress();
                }
            }

            unchecked {
                i++;
            }
            recoveryOwners[currentRecoveryOwner] = recoveryOwner;
            currentRecoveryOwner = recoveryOwner;
        }

        recoveryOwners[currentRecoveryOwner] = POINTER;
        recoveryOwnerCount = recoveryOwnersLength;
    }

    /**
     * @notice Activates the wallet for the first time.
     *
     * @dev    Cannot be called after initialization.
     */
    function activateWallet(
        address _owner,
        address[] calldata _guardians,
        address[] calldata _recoveryOwners
    ) internal {
        // If owner is not address(0), the wallet is already active.
        if (owner != address(0)) revert LS__activateWallet__walletInitialized();

        if (_owner.code.length != 0) {
            revert LS__activateWallet__invalidOwnerAddress();
        }

        // We set the owner. There is no need for further verification.
        owner = _owner;

        // We init the guardians.
        initGuardians(_guardians);

        // We init the recovery owners.
        initRecoveryOwners(_recoveryOwners);
    }
}