// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../interfaces/IEIP1271.sol";
import "../interfaces/ILaserState.sol";

/**
 * @title LaserHelper
 *
 * @notice Allows to batch multiple requests in a single rpc call.
 */
contract LaserHelper {
    error Utils__returnSigner__invalidSignature();

    error Utils__returnSigner__invalidContractSignature();

    // @notice This is temporary, all of this code does not go here.

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
    ) external view returns (address signer) {
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

    function getLaserState(address laserWallet)
        external
        view
        returns (
            address owner,
            address[] memory guardians,
            address[] memory recoveryOwners,
            address singleton,
            bool _isLocked,
            uint256 configTimestamp,
            uint256 nonce,
            uint256 balance,
            address oldOwner
        )
    {
        ILaserState laser = ILaserState(laserWallet);

        owner = laser.owner();
        guardians = laser.getGuardians();
        recoveryOwners = laser.getRecoveryOwners();
        singleton = laser.singleton();
        (configTimestamp, _isLocked, oldOwner) = laser.getConfig();
        nonce = laser.nonce();
        balance = address(laserWallet).balance;
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