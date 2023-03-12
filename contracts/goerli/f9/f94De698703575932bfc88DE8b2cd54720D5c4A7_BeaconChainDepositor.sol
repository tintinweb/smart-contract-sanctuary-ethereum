// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
pragma solidity 0.8.9;

import {MemUtils} from "../common/lib/MemUtils.sol";

interface IDepositContract {
    function get_deposit_root() external view returns (bytes32 rootHash);

    function deposit(
        bytes calldata pubkey, // 48 bytes
        bytes calldata withdrawal_credentials, // 32 bytes
        bytes calldata signature, // 96 bytes
        bytes32 deposit_data_root
    ) external payable;
}

contract BeaconChainDepositor {
    uint256 internal constant PUBLIC_KEY_LENGTH = 48;
    uint256 internal constant SIGNATURE_LENGTH = 96;
    uint256 internal constant DEPOSIT_SIZE = 32 ether;

    /// @dev deposit amount 32eth in gweis converted to little endian uint64
    /// DEPOSIT_SIZE_IN_GWEI_LE64 = toLittleEndian64(32 ether / 1 gwei)
    uint64 internal constant DEPOSIT_SIZE_IN_GWEI_LE64 = 0x0040597307000000;

    IDepositContract public immutable DEPOSIT_CONTRACT;

    constructor(address _depositContract) {
        if (_depositContract == address(0)) revert DepositContractZeroAddress();
        DEPOSIT_CONTRACT = IDepositContract(_depositContract);
    }

    /// @dev Invokes a deposit call to the official Beacon Deposit contract
    /// @param _keysCount amount of keys to deposit
    /// @param _withdrawalCredentials Commitment to a public key for withdrawals
    /// @param _publicKeysBatch A BLS12-381 public keys batch
    /// @param _signaturesBatch A BLS12-381 signatures batch
    function _makeBeaconChainDeposits32ETH(
        uint256 _keysCount,
        bytes memory _withdrawalCredentials,
        bytes memory _publicKeysBatch,
        bytes memory _signaturesBatch
    ) internal {
        if (_publicKeysBatch.length != PUBLIC_KEY_LENGTH * _keysCount) {
            revert InvalidPublicKeysBatchLength(_publicKeysBatch.length, PUBLIC_KEY_LENGTH * _keysCount);
        }
        if (_signaturesBatch.length != SIGNATURE_LENGTH * _keysCount) {
            revert InvalidSignaturesBatchLength(_signaturesBatch.length, SIGNATURE_LENGTH * _keysCount);
        }

        bytes memory publicKey = MemUtils.unsafeAllocateBytes(PUBLIC_KEY_LENGTH);
        bytes memory signature = MemUtils.unsafeAllocateBytes(SIGNATURE_LENGTH);

        for (uint256 i; i < _keysCount;) {
            MemUtils.copyBytes(_publicKeysBatch, publicKey, i * PUBLIC_KEY_LENGTH, 0, PUBLIC_KEY_LENGTH);
            MemUtils.copyBytes(_signaturesBatch, signature, i * SIGNATURE_LENGTH, 0, SIGNATURE_LENGTH);

            DEPOSIT_CONTRACT.deposit{value: DEPOSIT_SIZE}(
                publicKey, _withdrawalCredentials, signature, _computeDepositDataRoot(_withdrawalCredentials, publicKey, signature)
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @dev computes the deposit_root_hash required by official Beacon Deposit contract
    /// @param _publicKey A BLS12-381 public key.
    /// @param _signature A BLS12-381 signature
    function _computeDepositDataRoot(bytes memory _withdrawalCredentials, bytes memory _publicKey, bytes memory _signature)
        private
        pure
        returns (bytes32)
    {
        // Compute deposit data root (`DepositData` hash tree root) according to deposit_contract.sol
        bytes memory sigPart1 = MemUtils.unsafeAllocateBytes(64);
        bytes memory sigPart2 = MemUtils.unsafeAllocateBytes(SIGNATURE_LENGTH - 64);
        MemUtils.copyBytes(_signature, sigPart1, 0, 0, 64);
        MemUtils.copyBytes(_signature, sigPart2, 64, 0, SIGNATURE_LENGTH - 64);

        bytes32 publicKeyRoot = sha256(abi.encodePacked(_publicKey, bytes16(0)));
        bytes32 signatureRoot = sha256(abi.encodePacked(sha256(abi.encodePacked(sigPart1)), sha256(abi.encodePacked(sigPart2, bytes32(0)))));

        return sha256(
                abi.encodePacked(
                    sha256(abi.encodePacked(publicKeyRoot, _withdrawalCredentials)),
                    sha256(abi.encodePacked(DEPOSIT_SIZE_IN_GWEI_LE64, bytes24(0), signatureRoot))
                )
            );
    }

    error DepositContractZeroAddress();
    error InvalidPublicKeysBatchLength(uint256 actual, uint256 expected);
    error InvalidSignaturesBatchLength(uint256 actual, uint256 expected);
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
// solhint-disable-next-line lido/fixed-compiler-version
pragma solidity >=0.4.24 <0.9.0;


library MemUtils {
    /**
     * @dev Allocates a memory byte array of `_len` bytes without zeroing it out.
     */
    function unsafeAllocateBytes(uint256 _len) internal pure returns (bytes memory result) {
        assembly {
            result := mload(0x40)
            mstore(result, _len)
            let freeMemPtr := add(add(result, 32), _len)
            // align free mem ptr to 32 bytes as the compiler does now
            mstore(0x40, and(add(freeMemPtr, 31), not(31)))
        }
    }

    /**
     * Performs a memory copy of `_len` bytes from position `_src` to position `_dst`.
     */
    function memcpy(uint256 _src, uint256 _dst, uint256 _len) internal pure {
        assembly {
            // while al least 32 bytes left, copy in 32-byte chunks
            for { } gt(_len, 31) { } {
                mstore(_dst, mload(_src))
                _src := add(_src, 32)
                _dst := add(_dst, 32)
                _len := sub(_len, 32)
            }
            if gt(_len, 0) {
                // read the next 32-byte chunk from _dst, replace the first N bytes
                // with those left in the _src, and write the transformed chunk back
                let mask := sub(shl(mul(8, sub(32, _len)), 1), 1) // 2 ** (8 * (32 - _len)) - 1
                let srcMasked := and(mload(_src), not(mask))
                let dstMasked := and(mload(_dst), mask)
                mstore(_dst, or(dstMasked, srcMasked))
            }
        }
    }

    /**
     * Copies `_len` bytes from `_src`, starting at position `_srcStart`, into `_dst`, starting at position `_dstStart` into `_dst`.
     */
    function copyBytes(bytes memory _src, bytes memory _dst, uint256 _srcStart, uint256 _dstStart, uint256 _len) internal pure {
        require(_srcStart + _len <= _src.length && _dstStart + _len <= _dst.length, "BYTES_ARRAY_OUT_OF_BOUNDS");
        uint256 srcStartPos;
        uint256 dstStartPos;
        assembly {
            srcStartPos := add(add(_src, 32), _srcStart)
            dstStartPos := add(add(_dst, 32), _dstStart)
        }
        memcpy(srcStartPos, dstStartPos, _len);
    }

    /**
     * Copies bytes from `_src` to `_dst`, starting at position `_dstStart` into `_dst`.
     */
    function copyBytes(bytes memory _src, bytes memory _dst, uint256 _dstStart) internal pure {
        copyBytes(_src, _dst, 0, _dstStart, _src.length);
    }

    /**
     * Calculates keccak256 over a uint256 memory array contents.
     *
     * keccakUint256Array(array) is a more gas-efficient equivalent
     * to keccak256(abi.encodePacked(array)) since copying memory
     * is avoided.
     */
    function keccakUint256Array(uint256[] memory _arr) internal pure returns (bytes32 result) {
        assembly {
            let ptr := add(_arr, 32)
            let len := mul(mload(_arr), 32)
            result := keccak256(ptr, len)
        }
    }

    /**
     * Decreases length of a uint256 memory array `_arr` by the `_trimBy` items.
     */
    function trimUint256Array(uint256[] memory _arr, uint256 _trimBy) internal pure {
        uint256 newLen = _arr.length - _trimBy;
        assembly {
            mstore(_arr, newLen)
        }
    }
}