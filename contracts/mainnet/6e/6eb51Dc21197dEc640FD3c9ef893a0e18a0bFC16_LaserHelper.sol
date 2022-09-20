// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

import "../interfaces/IEIP1271.sol";

interface ILaser {
    function owner() external view returns (address);

    function getGuardians() external view returns (address[] memory);

    function getRecoveryOwners() external view returns (address[] memory);

    function singleton() external view returns (address);

    function isLocked() external view returns (bool);

    function getConfigTimestamp() external view returns (uint256);

    function nonce() external view returns (uint256);
}

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
            bool isLocked,
            uint256 configTimestamp,
            uint256 nonce,
            uint256 balance
        )
    {
        ILaser laser = ILaser(laserWallet);

        owner = laser.owner();
        guardians = laser.getGuardians();
        recoveryOwners = laser.getRecoveryOwners();
        singleton = laser.singleton();
        isLocked = laser.isLocked();
        configTimestamp = laser.getConfigTimestamp();
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