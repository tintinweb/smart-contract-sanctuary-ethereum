// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../thirdparty/BytesUtil.sol";
import "./AddressUtil.sol";
import "./MathUint.sol";
import "./ERC1271.sol";


/// @title SignatureUtil
/// @author Daniel Wang - <[email protected]>
/// @dev This method supports multihash standard. Each signature's last byte indicates
///      the signature's type.
library SignatureUtil
{
    using BytesUtil     for bytes;
    using MathUint      for uint;
    using AddressUtil   for address;

    enum SignatureType {
        ILLEGAL,
        INVALID,
        EIP_712,
        ETH_SIGN,
        WALLET   // deprecated
    }

    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function verifySignatures(
        bytes32          signHash,
        address[] memory signers,
        bytes[]   memory signatures
        )
        internal
        view
        returns (bool)
    {
        require(signers.length == signatures.length, "BAD_SIGNATURE_DATA");
        address lastSigner;
        for (uint i = 0; i < signers.length; i++) {
            require(signers[i] > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i];
            if (!verifySignature(signHash, signers[i], signatures[i])) {
                return false;
            }
        }
        return true;
    }

    function verifySignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        internal
        view
        returns (bool)
    {
        if (signer == address(0)) {
            return false;
        }

        return signer.isContract()?
            verifyERC1271Signature(signHash, signer, signature):
            verifyEOASignature(signHash, signer, signature);
    }

    function recoverECDSASigner(
        bytes32      signHash,
        bytes memory signature
        )
        internal
        pure
        returns (address)
    {
        if (signature.length != 65) {
            return address(0);
        }

        bytes32 r;
        bytes32 s;
        uint8   v;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := and(mload(add(signature, 0x41)), 0xff)
        }
        // See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v == 27 || v == 28) {
            return ecrecover(signHash, v, r, s);
        } else {
            return address(0);
        }
    }

    function verifyEOASignature(
        bytes32        signHash,
        address        signer,
        bytes   memory signature
        )
        private
        pure
        returns (bool success)
    {
        if (signer == address(0)) {
            return false;
        }

        uint signatureTypeOffset = signature.length.sub(1);
        SignatureType signatureType = SignatureType(signature.toUint8(signatureTypeOffset));

        // Strip off the last byte of the signature by updating the length
        assembly {
            mstore(signature, signatureTypeOffset)
        }

        if (signatureType == SignatureType.EIP_712) {
            success = (signer == recoverECDSASigner(signHash, signature));
        } else if (signatureType == SignatureType.ETH_SIGN) {
            bytes32 hash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", signHash)
            );
            success = (signer == recoverECDSASigner(hash, signature));
        } else {
            success = false;
        }

        // Restore the signature length
        assembly {
            mstore(signature, add(signatureTypeOffset, 1))
        }

        return success;
    }

    function verifyERC1271Signature(
        bytes32 signHash,
        address signer,
        bytes   memory signature
        )
        private
        view
        returns (bool)
    {
        bytes memory callData = abi.encodeWithSelector(
            ERC1271.isValidSignature.selector,
            signHash,
            signature
        );
        (bool success, bytes memory result) = signer.staticcall(callData);
        return (
            success &&
            result.length == 32 &&
            result.toBytes4(0) == ERC1271_MAGICVALUE
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
//Mainly taken from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
pragma solidity ^0.7.0;

library BytesUtil {

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        require(_bytes.length >= (_start + 1));
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        require(_bytes.length >= (_start + 2));
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint24(bytes memory _bytes, uint _start) internal  pure returns (uint24) {
        require(_bytes.length >= (_start + 3));
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        require(_bytes.length >= (_start + 4));
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        require(_bytes.length >= (_start + 8));
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        require(_bytes.length >= (_start + 12));
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        require(_bytes.length >= (_start + 16));
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4(bytes memory _bytes, uint _start) internal  pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes20(bytes memory _bytes, uint _start) internal  pure returns (bytes20) {
        require(_bytes.length >= (_start + 20));
        bytes20 tempBytes20;

        assembly {
            tempBytes20 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes20;
    }

    function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }


    function toAddressUnsafe(bytes memory _bytes, uint _start) internal  pure returns (address) {
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint8) {
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint16) {
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint24Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint24) {
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint32) {
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint64) {
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint96) {
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint128) {
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }


    function toUint248Unsafe(bytes memory _bytes, uint _start) internal  pure returns (uint248) {
        uint248 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1f), _start))
        }

        return tempUint;
    }

    function toUintUnsafe(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes4Unsafe(bytes memory _bytes, uint _start) internal  pure returns (bytes4) {
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes4;
    }

    function toBytes20Unsafe(bytes memory _bytes, uint _start) internal  pure returns (bytes20) {
        bytes20 tempBytes20;

        assembly {
            tempBytes20 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes20;
    }

    function toBytes32Unsafe(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }


    function fastSHA256(
        bytes memory data
        )
        internal
        view
        returns (bytes32)
    {
        bytes32[] memory result = new bytes32[](1);
        bool success;
        assembly {
             let ptr := add(data, 32)
             success := staticcall(sub(gas(), 2000), 2, ptr, mload(data), add(result, 32), 32)
        }
        require(success, "SHA256_FAILED");
        return result[0];
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for addresses
/// @author Daniel Wang - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library AddressUtil
{
    using AddressUtil for *;

    function isContract(
        address addr
        )
        internal
        view
        returns (bool)
    {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(addr) }
        return (codehash != 0x0 &&
                codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function toPayable(
        address addr
        )
        internal
        pure
        returns (address payable)
    {
        return payable(addr);
    }

    // Works like address.send but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        if (amount == 0) {
            return true;
        }
        address payable recipient = to.toPayable();
        /* solium-disable-next-line */
        (success, ) = recipient.call{value: amount, gas: gasLimit}("");
    }

    // Works like address.transfer but with a customizable gas limit
    // Make sure your code is safe for reentrancy when using this function!
    function sendETHAndVerify(
        address to,
        uint    amount,
        uint    gasLimit
        )
        internal
        returns (bool success)
    {
        success = to.sendETH(amount, gasLimit);
        require(success, "TRANSFER_FAILURE");
    }

    // Works like call but is slightly more efficient when data
    // needs to be copied from memory to do the call.
    function fastCall(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bool success, bytes memory returnData)
    {
        if (to != address(0)) {
            assembly {
                // Do the call
                success := call(gasLimit, to, value, add(data, 32), mload(data), 0, 0)
                // Copy the return data
                let size := returndatasize()
                returnData := mload(0x40)
                mstore(returnData, size)
                returndatacopy(add(returnData, 32), 0, size)
                // Update free memory pointer
                mstore(0x40, add(returnData, add(32, size)))
            }
        }
    }

    // Like fastCall, but throws when the call is unsuccessful.
    function fastCallAndVerify(
        address to,
        uint    gasLimit,
        uint    value,
        bytes   memory data
        )
        internal
        returns (bytes memory returnData)
    {
        bool success;
        (success, returnData) = fastCall(to, gasLimit, value, data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint
{
    using MathUint for uint;

    function mul(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a * b;
        require(a == 0 || c / a == b, "MUL_OVERFLOW");
    }

    function sub(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }

    function add(
        uint a,
        uint b
        )
        internal
        pure
        returns (uint c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function add64(
        uint64 a,
        uint64 b
        )
        internal
        pure
        returns (uint64 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

abstract contract ERC1271 {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
        bytes32      _hash,
        bytes memory _signature)
        external
        view
        virtual
        returns (bytes4 magicValueB32);

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ERC20 Token Interface
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <[email protected]>
abstract contract ERC20
{
    function totalSupply()
        public
        virtual
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        virtual
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        virtual
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        virtual
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        virtual
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./ERC20.sol";


/// @title ERC2612 Token with permit – 712-signed approvals but with
///        bytes as signature
/// @dev see https://eips.ethereum.org/EIPS/eip-2612
/// @author Daniel Wang - <[email protected]>
abstract contract ERC2612 is ERC20
{
    function nonces(address owner)
        public
        view
        virtual
        returns (uint);

    function permit(
        address        owner,
        address        spender,
        uint256        value,
        uint256        deadline,
        bytes calldata signature
        )
        external
        virtual;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./MathUint.sol";
import "../thirdparty/SafeCast.sol";


/// @title Utility Functions for floats
/// @author Brecht Devos - <[email protected]>
library FloatUtil
{
    using MathUint for uint;
    using SafeCast for uint;

    // Decodes a decimal float value that is encoded like `exponent | mantissa`.
    // Both exponent and mantissa are in base 10.
    // Decoding to an integer is as simple as `mantissa * (10 ** exponent)`
    // Will throw when the decoded value overflows an uint96
    /// @param f The float value with 5 bits for the exponent
    /// @param numBits The total number of bits (numBitsMantissa := numBits - numBitsExponent)
    /// @return value The decoded integer value.
    function decodeFloat(
        uint f,
        uint numBits
        )
        internal
        pure
        returns (uint96 value)
    {
        if (f == 0) {
            return 0;
        }
        uint numBitsMantissa = numBits.sub(5);
        uint exponent = f >> numBitsMantissa;
        // log2(10**77) = 255.79 < 256
        require(exponent <= 77, "EXPONENT_TOO_LARGE");
        uint mantissa = f & ((1 << numBitsMantissa) - 1);
        value = mantissa.mul(10 ** exponent).toUint96();
    }

    // Decodes a decimal float value that is encoded like `exponent | mantissa`.
    // Both exponent and mantissa are in base 10.
    // Decoding to an integer is as simple as `mantissa * (10 ** exponent)`
    // Will throw when the decoded value overflows an uint96
    /// @param f The float value with 5 bits exponent, 11 bits mantissa
    /// @return value The decoded integer value.
    function decodeFloat16(
        uint16 f
        )
        internal
        pure
        returns (uint96)
    {
        uint value = ((uint(f) & 2047) * (10 ** (uint(f) >> 11)));
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    // Decodes a decimal float value that is encoded like `exponent | mantissa`.
    // Both exponent and mantissa are in base 10.
    // Decoding to an integer is as simple as `mantissa * (10 ** exponent)`
    // Will throw when the decoded value overflows an uint96
    /// @param f The float value with 5 bits exponent, 19 bits mantissa
    /// @return value The decoded integer value.
    function decodeFloat24(
        uint24 f
        )
        internal
        pure
        returns (uint96)
    {
        uint value = ((uint(f) & 524287) * (10 ** (uint(f) >> 19)));
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }
}

// SPDX-License-Identifier: MIT
// Taken from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/SafeCast.sol

pragma solidity ^0.7.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value < 2**248, "SafeCast: value doesn\'t fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "SafeCast: value doesn\'t fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


library EIP712
{
    struct Domain {
        string  name;
        string  version;
        address verifyingContract;
    }

    bytes32 constant internal EIP712_DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    string constant internal EIP191_HEADER = "\x19\x01";

    function hash(Domain memory domain)
        internal
        pure
        returns (bytes32)
    {
        uint _chainid;
        assembly { _chainid := chainid() }

        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(domain.name)),
                keccak256(bytes(domain.version)),
                _chainid,
                domain.verifyingContract
            )
        );
    }

    function hashPacked(
        bytes32 domainHash,
        bytes32 dataHash
        )
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                domainHash,
                dataHash
            )
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../thirdparty/proxies/Proxy.sol";


/// @title SimpleProxy
/// @author Daniel Wang  - <[email protected]>
contract SimpleProxy is Proxy
{
    bytes32 private constant implementationPosition = keccak256(
        "org.loopring.protocol.simple.proxy"
    );

    constructor(address _implementation) {
        if (_implementation != address(0)) {
            setImplementation(_implementation);
        }
    }

    function setImplementation(address _implementation)
        public
    {
        address _impl = implementation();
        require(_impl == address(0), "INITIALIZED_ALREADY");

        bytes32 position = implementationPosition;
        assembly {sstore(position, _implementation) }
    }

    function implementation()
        public
        override
        view
        returns (address)
    {
        address impl;
        bytes32 position = implementationPosition;
        assembly { impl := sload(position) }
        return impl;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/OpenZeppelin/openzeppelin-labs
// with minor modifications.
pragma solidity ^0.7.0;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
  /**
  * @dev Tells the address of the implementation where every call will be delegated.
  * @return impl address of the implementation to which it will be delegated
  */
  function implementation() public view virtual returns (address impl);

  receive() payable external {
    _fallback();
  }

  fallback() payable external {
    _fallback();
  }

  function _fallback() private {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title AddressSet
/// @author Daniel Wang - <[email protected]>
contract AddressSet
{
    struct Set
    {
        address[] addresses;
        mapping (address => uint) positions;
        uint count;
    }
    mapping (bytes32 => Set) private sets;

    function addAddressToSet(
        bytes32 key,
        address addr,
        bool maintainList
        ) internal
    {
        Set storage set = sets[key];
        require(set.positions[addr] == 0, "ALREADY_IN_SET");

        if (maintainList) {
            require(set.addresses.length == set.count, "PREVIOUSLY_NOT_MAINTAILED");
            set.addresses.push(addr);
        } else {
            require(set.addresses.length == 0, "MUST_MAINTAIN");
        }

        set.count += 1;
        set.positions[addr] = set.count;
    }

    function removeAddressFromSet(
        bytes32 key,
        address addr
        )
        internal
    {
        Set storage set = sets[key];
        uint pos = set.positions[addr];
        require(pos != 0, "NOT_IN_SET");

        delete set.positions[addr];
        set.count -= 1;

        if (set.addresses.length > 0) {
            address lastAddr = set.addresses[set.count];
            if (lastAddr != addr) {
                set.addresses[pos - 1] = lastAddr;
                set.positions[lastAddr] = pos;
            }
            set.addresses.pop();
        }
    }

    function removeSet(bytes32 key)
        internal
    {
        delete sets[key];
    }

    function isAddressInSet(
        bytes32 key,
        address addr
        )
        internal
        view
        returns (bool)
    {
        return sets[key].positions[addr] != 0;
    }

    function numAddressesInSet(bytes32 key)
        internal
        view
        returns (uint)
    {
        Set storage set = sets[key];
        return set.count;
    }

    function addressesInSet(bytes32 key)
        internal
        view
        returns (address[] memory)
    {
        Set storage set = sets[key];
        require(set.count == set.addresses.length, "NOT_MAINTAINED");
        return sets[key].addresses;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./AddressUtil.sol";
import "./ERC20.sol";
import "./ERC20SafeTransfer.sol";


/// @title Drainable
/// @author Brecht Devos - <[email protected]>
/// @dev Standard functionality to allow draining funds from a contract.
abstract contract Drainable
{
    using AddressUtil       for address;
    using ERC20SafeTransfer for address;

    event Drained(
        address to,
        address token,
        uint    amount
    );

    function drain(
        address to,
        address token
        )
        public
        returns (uint amount)
    {
        require(canDrain(msg.sender, token), "UNAUTHORIZED");

        if (token == address(0)) {
            amount = address(this).balance;
            to.sendETHAndVerify(amount, gasleft());   // ETH
        } else {
            amount = ERC20(token).balanceOf(address(this));
            token.safeTransferAndVerify(to, amount);  // ERC20 token
        }

        emit Drained(to, token, amount);
    }

    // Needs to return if the address is authorized to call drain.
    function canDrain(address drainer, address token)
        public
        virtual
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title ERC20 safe transfer
/// @dev see https://github.com/sec-bit/badERC20Fix
/// @author Brecht Devos - <[email protected]opring.org>
library ERC20SafeTransfer
{
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransferAndVerify(
        address token,
        address to,
        uint    value
        )
        internal
    {
        safeTransferWithGasLimitAndVerify(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferWithGasLimit(
            token,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferWithGasLimitAndVerify(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        require(
            safeTransferWithGasLimit(token, to, value, gasLimit),
            "TRANSFER_FAILURE"
        );
    }

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        // A transfer is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        require(isContract(token), "ERC20SafeTransfer: call to non-contract");

        // bytes4(keccak256("transfer(address,uint256)")) = 0xa9059cbb
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0xa9059cbb),
            to,
            value
        );
        (bool success, ) = token.call{gas: gasLimit}(callData);
        return checkReturnValue(success);
    }

    function safeTransferFromAndVerify(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
    {
        safeTransferFromWithGasLimitAndVerify(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint    value
        )
        internal
        returns (bool)
    {
        return safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasleft()
        );
    }

    function safeTransferFromWithGasLimitAndVerify(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
    {
        bool result = safeTransferFromWithGasLimit(
            token,
            from,
            to,
            value,
            gasLimit
        );
        require(result, "TRANSFER_FAILURE");
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        internal
        returns (bool)
    {
        // A transferFrom is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)

        require(isContract(token), "ERC20SafeTransfer: call to non-contract");

        // bytes4(keccak256("transferFrom(address,address,uint256)")) = 0x23b872dd
        bytes memory callData = abi.encodeWithSelector(
            bytes4(0x23b872dd),
            from,
            to,
            value
        );
        (bool success, ) = token.call{gas: gasLimit}(callData);
        return checkReturnValue(success);
    }

    function checkReturnValue(
        bool success
        )
        internal
        pure
        returns (bool)
    {
        // A transfer/transferFrom is successful when 'call' is successful and depending on the token:
        // - No value is returned: we assume a revert when the transfer failed (i.e. 'call' returns false)
        // - A single boolean is returned: this boolean needs to be true (non-zero)
        if (success) {
            assembly {
                switch returndatasize()
                // Non-standard ERC20: nothing is returned so if 'call' was successful we assume the transfer succeeded
                case 0 {
                    success := 1
                }
                // Standard ERC20: a single boolean value is returned which needs to be true
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                // None of the above: not successful
                default {
                    success := 0
                }
            }
        }
        return success;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./MathUint.sol";


/// @title ERC20 Token Implementation
/// @dev see https://github.com/ethereum/EIPs/issues/20
/// @author Daniel Wang - <[email protected]>
contract ERC20Token is ERC20
{
    using MathUint for uint;

    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint    public totalSupply_;

    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) internal allowed;

    event Transfer(
        address indexed from,
        address indexed to,
        uint            value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint            value
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint8         _decimals,
        uint          _totalSupply,
        address       _firstHolder
        )
    {
        require(_totalSupply > 0, "INVALID_VALUE");
        require(_firstHolder != address(0), "ZERO_ADDRESS");
        checkSymbolAndName(_symbol,_name);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;

        balances[_firstHolder] = totalSupply_;
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply()
        public
        override
        view
        returns (uint)
    {
        return totalSupply_;
    }

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(
        address _to,
        uint    _value
        )
        public
        override
        returns (bool)
    {
        require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[msg.sender], "INVALID_VALUE");

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return balance An uint representing the amount owned by the passed address.
    */
    function balanceOf(
        address _owner
        )
        public
        override
        view
        returns (uint balance)
    {
        return balances[_owner];
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint    _value
        )
        public
        override
        returns (bool)
    {
        require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[_from], "INVALID_VALUE");
        require(_value <= allowed[_from][msg.sender], "INVALID_VALUE");

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(
        address _spender,
        uint    _value
        )
        public
        override
        returns (bool)
    {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
        )
        public
        override
        view
        returns (uint)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(
        address _spender,
        uint    _addedValue
        )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(
        address _spender,
        uint    _subtractedValue
        )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    // Make sure symbol has 3-8 chars in [A-Za-z._] and name has up to 128 chars.
    function checkSymbolAndName(
        string memory _symbol,
        string memory _name
        )
        internal
        pure
    {
        bytes memory s = bytes(_symbol);
        require(s.length >= 3 && s.length <= 8, "INVALID_SIZE");
        for (uint i = 0; i < s.length; i++) {
            // make sure symbol contains only [A-Za-z._]
            require(
                s[i] == 0x2E || (
                s[i] == 0x5F) || (
                s[i] >= 0x41 && s[i] <= 0x5A) || (
                s[i] >= 0x61 && s[i] <= 0x7A), "INVALID_VALUE");
        }
        bytes memory n = bytes(_name);
        require(n.length >= s.length && n.length <= 128, "INVALID_SIZE");
        for (uint i = 0; i < n.length; i++) {
            require(n[i] >= 0x20 && n[i] <= 0x7E, "INVALID_VALUE");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./Ownable.sol";


/// @title Claimable
/// @author Brecht Devos - <[email protected]>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Ownable
/// @author Brecht Devos - <[email protected]>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Taken from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/970f687f04d20e01138a3e8ccf9278b1d4b3997b/contracts/utils/Create2.sol

pragma solidity ^0.7.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}. Note that
     * a contract cannot be deployed twice using the same salt.
     */
    function deploy(bytes32 salt, bytes memory bytecode) internal returns (address payable) {
        address payable addr;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "CREATE2_FAILED");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the `bytecode`
     * or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes memory bytecode) internal view returns (address) {
        return computeAddress(salt, bytecode, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes memory bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 bytecodeHashHash = keccak256(bytecodeHash);
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHashHash)
        );
        return address(bytes20(_data << 96));
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./AddressSet.sol";
import "./Claimable.sol";


contract OwnerManagable is Claimable, AddressSet
{
    bytes32 internal constant MANAGER = keccak256("__MANAGED__");

    event ManagerAdded  (address indexed manager);
    event ManagerRemoved(address indexed manager);

    modifier onlyManager
    {
        require(isManager(msg.sender), "NOT_MANAGER");
        _;
    }

    modifier onlyOwnerOrManager
    {
        require(msg.sender == owner || isManager(msg.sender), "NOT_OWNER_OR_MANAGER");
        _;
    }

    constructor() Claimable() {}

    /// @dev Gets the managers.
    /// @return The list of managers.
    function managers()
        public
        view
        returns (address[] memory)
    {
        return addressesInSet(MANAGER);
    }

    /// @dev Gets the number of managers.
    /// @return The numer of managers.
    function numManagers()
        public
        view
        returns (uint)
    {
        return numAddressesInSet(MANAGER);
    }

    /// @dev Checks if an address is a manger.
    /// @param addr The address to check.
    /// @return True if the address is a manager, False otherwise.
    function isManager(address addr)
        public
        view
        returns (bool)
    {
        return isAddressInSet(MANAGER, addr);
    }

    /// @dev Adds a new manager.
    /// @param manager The new address to add.
    function addManager(address manager)
        public
        onlyOwner
    {
        addManagerInternal(manager);
    }

    /// @dev Removes a manager.
    /// @param manager The manager to remove.
    function removeManager(address manager)
        public
        onlyOwner
    {
        removeAddressFromSet(MANAGER, manager);
        emit ManagerRemoved(manager);
    }

    function addManagerInternal(address manager)
        internal
    {
        addAddressToSet(MANAGER, manager, true);
        emit ManagerAdded(manager);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./ERC20.sol";


/// @title Burnable ERC20 Token Interface
/// @author Brecht Devos - <[email protected]>
abstract contract BurnableERC20 is ERC20
{
    function burn(
        uint value
        )
        public
        virtual
        returns (bool);

    function burnFrom(
        address from,
        uint value
        )
        public
        virtual
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title Poseidon hash function
///        See: https://eprint.iacr.org/2019/458.pdf
///        Code auto-generated by generate_poseidon_EVM_code.py
/// @author Brecht Devos - <[email protected]>
library Poseidon
{
    //
    // hash_t5f6p52
    //

    struct HashInputs5
    {
        uint t0;
        uint t1;
        uint t2;
        uint t3;
        uint t4;
    }

    function hash_t5f6p52_internal(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4,
        uint q
        )
        internal
        pure
        returns (uint)
    {
        assembly {
            function mix(_t0, _t1, _t2, _t3, _t4, _q) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := mulmod(_t0, 4977258759536702998522229302103997878600602264560359702680165243908162277980, _q)
                nt0 := addmod(nt0, mulmod(_t1, 19167410339349846567561662441069598364702008768579734801591448511131028229281, _q), _q)
                nt0 := addmod(nt0, mulmod(_t2, 14183033936038168803360723133013092560869148726790180682363054735190196956789, _q), _q)
                nt0 := addmod(nt0, mulmod(_t3, 9067734253445064890734144122526450279189023719890032859456830213166173619761, _q), _q)
                nt0 := addmod(nt0, mulmod(_t4, 16378664841697311562845443097199265623838619398287411428110917414833007677155, _q), _q)
                nt1 := mulmod(_t0, 107933704346764130067829474107909495889716688591997879426350582457782826785, _q)
                nt1 := addmod(nt1, mulmod(_t1, 17034139127218860091985397764514160131253018178110701196935786874261236172431, _q), _q)
                nt1 := addmod(nt1, mulmod(_t2, 2799255644797227968811798608332314218966179365168250111693473252876996230317, _q), _q)
                nt1 := addmod(nt1, mulmod(_t3, 2482058150180648511543788012634934806465808146786082148795902594096349483974, _q), _q)
                nt1 := addmod(nt1, mulmod(_t4, 16563522740626180338295201738437974404892092704059676533096069531044355099628, _q), _q)
                nt2 := mulmod(_t0, 13596762909635538739079656925495736900379091964739248298531655823337482778123, _q)
                nt2 := addmod(nt2, mulmod(_t1, 18985203040268814769637347880759846911264240088034262814847924884273017355969, _q), _q)
                nt2 := addmod(nt2, mulmod(_t2, 8652975463545710606098548415650457376967119951977109072274595329619335974180, _q), _q)
                nt2 := addmod(nt2, mulmod(_t3, 970943815872417895015626519859542525373809485973005165410533315057253476903, _q), _q)
                nt2 := addmod(nt2, mulmod(_t4, 19406667490568134101658669326517700199745817783746545889094238643063688871948, _q), _q)
                nt3 := mulmod(_t0, 2953507793609469112222895633455544691298656192015062835263784675891831794974, _q)
                nt3 := addmod(nt3, mulmod(_t1, 19025623051770008118343718096455821045904242602531062247152770448380880817517, _q), _q)
                nt3 := addmod(nt3, mulmod(_t2, 9077319817220936628089890431129759976815127354480867310384708941479362824016, _q), _q)
                nt3 := addmod(nt3, mulmod(_t3, 4770370314098695913091200576539533727214143013236894216582648993741910829490, _q), _q)
                nt3 := addmod(nt3, mulmod(_t4, 4298564056297802123194408918029088169104276109138370115401819933600955259473, _q), _q)
                nt4 := mulmod(_t0, 8336710468787894148066071988103915091676109272951895469087957569358494947747, _q)
                nt4 := addmod(nt4, mulmod(_t1, 16205238342129310687768799056463408647672389183328001070715567975181364448609, _q), _q)
                nt4 := addmod(nt4, mulmod(_t2, 8303849270045876854140023508764676765932043944545416856530551331270859502246, _q), _q)
                nt4 := addmod(nt4, mulmod(_t3, 20218246699596954048529384569730026273241102596326201163062133863539137060414, _q), _q)
                nt4 := addmod(nt4, mulmod(_t4, 1712845821388089905746651754894206522004527237615042226559791118162382909269, _q), _q)
            }

            function ark(_t0, _t1, _t2, _t3, _t4, _q, c) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := addmod(_t0, c, _q)
                nt1 := addmod(_t1, c, _q)
                nt2 := addmod(_t2, c, _q)
                nt3 := addmod(_t3, c, _q)
                nt4 := addmod(_t4, c, _q)
            }

            function sbox_full(_t0, _t1, _t2, _t3, _t4, _q) -> nt0, nt1, nt2, nt3, nt4 {
                nt0 := mulmod(_t0, _t0, _q)
                nt0 := mulmod(nt0, nt0, _q)
                nt0 := mulmod(_t0, nt0, _q)
                nt1 := mulmod(_t1, _t1, _q)
                nt1 := mulmod(nt1, nt1, _q)
                nt1 := mulmod(_t1, nt1, _q)
                nt2 := mulmod(_t2, _t2, _q)
                nt2 := mulmod(nt2, nt2, _q)
                nt2 := mulmod(_t2, nt2, _q)
                nt3 := mulmod(_t3, _t3, _q)
                nt3 := mulmod(nt3, nt3, _q)
                nt3 := mulmod(_t3, nt3, _q)
                nt4 := mulmod(_t4, _t4, _q)
                nt4 := mulmod(nt4, nt4, _q)
                nt4 := mulmod(_t4, nt4, _q)
            }

            function sbox_partial(_t, _q) -> nt {
                nt := mulmod(_t, _t, _q)
                nt := mulmod(nt, nt, _q)
                nt := mulmod(_t, nt, _q)
            }

            // round 0
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 1
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 2
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 3
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 4
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 5
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 6
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 7
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 8
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 9
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 10
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 11
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 12
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 13
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 14
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 15
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 16
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 17
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 18
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 19
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 20
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 21
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 22
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 23
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 24
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 25
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 26
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 27
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 28
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 29
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 30
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 31
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 32
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 33
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 34
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 35
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 36
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 37
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 38
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 71447649211767888770311304010816315780740050029903404046389165015534756512)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 39
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 40
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 41
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 42
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 43
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 44
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 45
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 46
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 47
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 48
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 49
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 50
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 51
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 52
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 53
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 54
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849)
            t0 := sbox_partial(t0, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 55
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 56
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
            // round 57
            t0, t1, t2, t3, t4 := ark(t0, t1, t2, t3, t4, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544)
            t0, t1, t2, t3, t4 := sbox_full(t0, t1, t2, t3, t4, q)
            t0, t1, t2, t3, t4 := mix(t0, t1, t2, t3, t4, q)
        }
        return t0;
    }

    function hash_t5f6p52(HashInputs5 memory i, uint q) internal pure returns (uint)
    {
        // validate inputs
        require(i.t0 < q, "INVALID_INPUT");
        require(i.t1 < q, "INVALID_INPUT");
        require(i.t2 < q, "INVALID_INPUT");
        require(i.t3 < q, "INVALID_INPUT");
        require(i.t4 < q, "INVALID_INPUT");

        return hash_t5f6p52_internal(i.t0, i.t1, i.t2, i.t3, i.t4, q);
    }

    //
    // hash_t6f6p52
    //

    struct HashInputs6
    {
        uint t0;
        uint t1;
        uint t2;
        uint t3;
        uint t4;
        uint t5;
    }


    function mix(HashInputs6 memory i, uint q) internal pure 
    {
        HashInputs6 memory o;
        o.t0 = mulmod(i.t0, 19167410339349846567561662441069598364702008768579734801591448511131028229281, q);
        o.t0 = addmod(o.t0, mulmod(i.t1, 14183033936038168803360723133013092560869148726790180682363054735190196956789, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t2, 9067734253445064890734144122526450279189023719890032859456830213166173619761, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t3, 16378664841697311562845443097199265623838619398287411428110917414833007677155, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t4, 12968540216479938138647596899147650021419273189336843725176422194136033835172, q), q);
        o.t0 = addmod(o.t0, mulmod(i.t5, 3636162562566338420490575570584278737093584021456168183289112789616069756675, q), q);
        o.t1 = mulmod(i.t0, 17034139127218860091985397764514160131253018178110701196935786874261236172431, q);
        o.t1 = addmod(o.t1, mulmod(i.t1, 2799255644797227968811798608332314218966179365168250111693473252876996230317, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t2, 2482058150180648511543788012634934806465808146786082148795902594096349483974, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t3, 16563522740626180338295201738437974404892092704059676533096069531044355099628, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t4, 10468644849657689537028565510142839489302836569811003546969773105463051947124, q), q);
        o.t1 = addmod(o.t1, mulmod(i.t5, 3328913364598498171733622353010907641674136720305714432354138807013088636408, q), q);
        o.t2 = mulmod(i.t0, 18985203040268814769637347880759846911264240088034262814847924884273017355969, q);
        o.t2 = addmod(o.t2, mulmod(i.t1, 8652975463545710606098548415650457376967119951977109072274595329619335974180, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t2, 970943815872417895015626519859542525373809485973005165410533315057253476903, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t3, 19406667490568134101658669326517700199745817783746545889094238643063688871948, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t4, 17049854690034965250221386317058877242629221002521630573756355118745574274967, q), q);
        o.t2 = addmod(o.t2, mulmod(i.t5, 4964394613021008685803675656098849539153699842663541444414978877928878266244, q), q);
        o.t3 = mulmod(i.t0, 19025623051770008118343718096455821045904242602531062247152770448380880817517, q);
        o.t3 = addmod(o.t3, mulmod(i.t1, 9077319817220936628089890431129759976815127354480867310384708941479362824016, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t2, 4770370314098695913091200576539533727214143013236894216582648993741910829490, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t3, 4298564056297802123194408918029088169104276109138370115401819933600955259473, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t4, 6905514380186323693285869145872115273350947784558995755916362330070690839131, q), q);
        o.t3 = addmod(o.t3, mulmod(i.t5, 4783343257810358393326889022942241108539824540285247795235499223017138301952, q), q);
        o.t4 = mulmod(i.t0, 16205238342129310687768799056463408647672389183328001070715567975181364448609, q);
        o.t4 = addmod(o.t4, mulmod(i.t1, 8303849270045876854140023508764676765932043944545416856530551331270859502246, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t2, 20218246699596954048529384569730026273241102596326201163062133863539137060414, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t3, 1712845821388089905746651754894206522004527237615042226559791118162382909269, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t4, 13001155522144542028910638547179410124467185319212645031214919884423841839406, q), q);
        o.t4 = addmod(o.t4, mulmod(i.t5, 16037892369576300958623292723740289861626299352695838577330319504984091062115, q), q);
        o.t5 = mulmod(i.t0, 15162889384227198851506890526431746552868519326873025085114621698588781611738, q);
        o.t5 = addmod(o.t5, mulmod(i.t1, 13272957914179340594010910867091459756043436017766464331915862093201960540910, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t2, 9416416589114508529880440146952102328470363729880726115521103179442988482948, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t3, 8035240799672199706102747147502951589635001418759394863664434079699838251138, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t4, 21642389080762222565487157652540372010968704000567605990102641816691459811717, q), q);
        o.t5 = addmod(o.t5, mulmod(i.t5, 20261355950827657195644012399234591122288573679402601053407151083849785332516, q), q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
        i.t4 = o.t4;
        i.t5 = o.t5;
    }

    function ark(HashInputs6 memory i, uint q, uint c) internal pure 
    {
        HashInputs6 memory o;
        o.t0 = addmod(i.t0, c, q);
        o.t1 = addmod(i.t1, c, q);
        o.t2 = addmod(i.t2, c, q);
        o.t3 = addmod(i.t3, c, q);
        o.t4 = addmod(i.t4, c, q);
        o.t5 = addmod(i.t5, c, q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
        i.t4 = o.t4;
        i.t5 = o.t5;
    }

    function sbox_full(HashInputs6 memory i, uint q) internal pure 
    {
        HashInputs6 memory o;
        o.t0 = mulmod(i.t0, i.t0, q);
        o.t0 = mulmod(o.t0, o.t0, q);
        o.t0 = mulmod(i.t0, o.t0, q);
        o.t1 = mulmod(i.t1, i.t1, q);
        o.t1 = mulmod(o.t1, o.t1, q);
        o.t1 = mulmod(i.t1, o.t1, q);
        o.t2 = mulmod(i.t2, i.t2, q);
        o.t2 = mulmod(o.t2, o.t2, q);
        o.t2 = mulmod(i.t2, o.t2, q);
        o.t3 = mulmod(i.t3, i.t3, q);
        o.t3 = mulmod(o.t3, o.t3, q);
        o.t3 = mulmod(i.t3, o.t3, q);
        o.t4 = mulmod(i.t4, i.t4, q);
        o.t4 = mulmod(o.t4, o.t4, q);
        o.t4 = mulmod(i.t4, o.t4, q);
        o.t5 = mulmod(i.t5, i.t5, q);
        o.t5 = mulmod(o.t5, o.t5, q);
        o.t5 = mulmod(i.t5, o.t5, q);
        i.t0 = o.t0;
        i.t1 = o.t1;
        i.t2 = o.t2;
        i.t3 = o.t3;
        i.t4 = o.t4;
        i.t5 = o.t5;
    }

    function sbox_partial(HashInputs6 memory i, uint q) internal pure 
    {
        HashInputs6 memory o;
        o.t0 = mulmod(i.t0, i.t0, q);
        o.t0 = mulmod(o.t0, o.t0, q);
        o.t0 = mulmod(i.t0, o.t0, q);
        i.t0 = o.t0;
    }

    function hash_t6f6p52(HashInputs6 memory i, uint q) internal pure returns (uint)
    {
        // validate inputs
        require(i.t0 < q, "INVALID_INPUT");
        require(i.t1 < q, "INVALID_INPUT");
        require(i.t2 < q, "INVALID_INPUT");
        require(i.t3 < q, "INVALID_INPUT");
        require(i.t4 < q, "INVALID_INPUT");
        require(i.t5 < q, "INVALID_INPUT");

        // round 0
        ark(i, q, 14397397413755236225575615486459253198602422701513067526754101844196324375522);
        sbox_full(i, q);
        mix(i, q);
        // round 1
        ark(i, q, 10405129301473404666785234951972711717481302463898292859783056520670200613128);
        sbox_full(i, q);
        mix(i, q);
        // round 2
        ark(i, q, 5179144822360023508491245509308555580251733042407187134628755730783052214509);
        sbox_full(i, q);
        mix(i, q);
        // round 3
        ark(i, q, 9132640374240188374542843306219594180154739721841249568925550236430986592615);
        sbox_partial(i, q);
        mix(i, q);
        // round 4
        ark(i, q, 20360807315276763881209958738450444293273549928693737723235350358403012458514);
        sbox_partial(i, q);
        mix(i, q);
        // round 5
        ark(i, q, 17933600965499023212689924809448543050840131883187652471064418452962948061619);
        sbox_partial(i, q);
        mix(i, q);
        // round 6
        ark(i, q, 3636213416533737411392076250708419981662897009810345015164671602334517041153);
        sbox_partial(i, q);
        mix(i, q);
        // round 7
        ark(i, q, 2008540005368330234524962342006691994500273283000229509835662097352946198608);
        sbox_partial(i, q);
        mix(i, q);
        // round 8
        ark(i, q, 16018407964853379535338740313053768402596521780991140819786560130595652651567);
        sbox_partial(i, q);
        mix(i, q);
        // round 9
        ark(i, q, 20653139667070586705378398435856186172195806027708437373983929336015162186471);
        sbox_partial(i, q);
        mix(i, q);
        // round 10
        ark(i, q, 17887713874711369695406927657694993484804203950786446055999405564652412116765);
        sbox_partial(i, q);
        mix(i, q);
        // round 11
        ark(i, q, 4852706232225925756777361208698488277369799648067343227630786518486608711772);
        sbox_partial(i, q);
        mix(i, q);
        // round 12
        ark(i, q, 8969172011633935669771678412400911310465619639756845342775631896478908389850);
        sbox_partial(i, q);
        mix(i, q);
        // round 13
        ark(i, q, 20570199545627577691240476121888846460936245025392381957866134167601058684375);
        sbox_partial(i, q);
        mix(i, q);
        // round 14
        ark(i, q, 16442329894745639881165035015179028112772410105963688121820543219662832524136);
        sbox_partial(i, q);
        mix(i, q);
        // round 15
        ark(i, q, 20060625627350485876280451423010593928172611031611836167979515653463693899374);
        sbox_partial(i, q);
        mix(i, q);
        // round 16
        ark(i, q, 16637282689940520290130302519163090147511023430395200895953984829546679599107);
        sbox_partial(i, q);
        mix(i, q);
        // round 17
        ark(i, q, 15599196921909732993082127725908821049411366914683565306060493533569088698214);
        sbox_partial(i, q);
        mix(i, q);
        // round 18
        ark(i, q, 16894591341213863947423904025624185991098788054337051624251730868231322135455);
        sbox_partial(i, q);
        mix(i, q);
        // round 19
        ark(i, q, 1197934381747032348421303489683932612752526046745577259575778515005162320212);
        sbox_partial(i, q);
        mix(i, q);
        // round 20
        ark(i, q, 6172482022646932735745595886795230725225293469762393889050804649558459236626);
        sbox_partial(i, q);
        mix(i, q);
        // round 21
        ark(i, q, 21004037394166516054140386756510609698837211370585899203851827276330669555417);
        sbox_partial(i, q);
        mix(i, q);
        // round 22
        ark(i, q, 15262034989144652068456967541137853724140836132717012646544737680069032573006);
        sbox_partial(i, q);
        mix(i, q);
        // round 23
        ark(i, q, 15017690682054366744270630371095785995296470601172793770224691982518041139766);
        sbox_partial(i, q);
        mix(i, q);
        // round 24
        ark(i, q, 15159744167842240513848638419303545693472533086570469712794583342699782519832);
        sbox_partial(i, q);
        mix(i, q);
        // round 25
        ark(i, q, 11178069035565459212220861899558526502477231302924961773582350246646450941231);
        sbox_partial(i, q);
        mix(i, q);
        // round 26
        ark(i, q, 21154888769130549957415912997229564077486639529994598560737238811887296922114);
        sbox_partial(i, q);
        mix(i, q);
        // round 27
        ark(i, q, 20162517328110570500010831422938033120419484532231241180224283481905744633719);
        sbox_partial(i, q);
        mix(i, q);
        // round 28
        ark(i, q, 2777362604871784250419758188173029886707024739806641263170345377816177052018);
        sbox_partial(i, q);
        mix(i, q);
        // round 29
        ark(i, q, 15732290486829619144634131656503993123618032247178179298922551820261215487562);
        sbox_partial(i, q);
        mix(i, q);
        // round 30
        ark(i, q, 6024433414579583476444635447152826813568595303270846875177844482142230009826);
        sbox_partial(i, q);
        mix(i, q);
        // round 31
        ark(i, q, 17677827682004946431939402157761289497221048154630238117709539216286149983245);
        sbox_partial(i, q);
        mix(i, q);
        // round 32
        ark(i, q, 10716307389353583413755237303156291454109852751296156900963208377067748518748);
        sbox_partial(i, q);
        mix(i, q);
        // round 33
        ark(i, q, 14925386988604173087143546225719076187055229908444910452781922028996524347508);
        sbox_partial(i, q);
        mix(i, q);
        // round 34
        ark(i, q, 8940878636401797005293482068100797531020505636124892198091491586778667442523);
        sbox_partial(i, q);
        mix(i, q);
        // round 35
        ark(i, q, 18911747154199663060505302806894425160044925686870165583944475880789706164410);
        sbox_partial(i, q);
        mix(i, q);
        // round 36
        ark(i, q, 8821532432394939099312235292271438180996556457308429936910969094255825456935);
        sbox_partial(i, q);
        mix(i, q);
        // round 37
        ark(i, q, 20632576502437623790366878538516326728436616723089049415538037018093616927643);
        sbox_partial(i, q);
        mix(i, q);
        // round 38
        ark(i, q, 71447649211767888770311304010816315780740050029903404046389165015534756512);
        sbox_partial(i, q);
        mix(i, q);
        // round 39
        ark(i, q, 2781996465394730190470582631099299305677291329609718650018200531245670229393);
        sbox_partial(i, q);
        mix(i, q);
        // round 40
        ark(i, q, 12441376330954323535872906380510501637773629931719508864016287320488688345525);
        sbox_partial(i, q);
        mix(i, q);
        // round 41
        ark(i, q, 2558302139544901035700544058046419714227464650146159803703499681139469546006);
        sbox_partial(i, q);
        mix(i, q);
        // round 42
        ark(i, q, 10087036781939179132584550273563255199577525914374285705149349445480649057058);
        sbox_partial(i, q);
        mix(i, q);
        // round 43
        ark(i, q, 4267692623754666261749551533667592242661271409704769363166965280715887854739);
        sbox_partial(i, q);
        mix(i, q);
        // round 44
        ark(i, q, 4945579503584457514844595640661884835097077318604083061152997449742124905548);
        sbox_partial(i, q);
        mix(i, q);
        // round 45
        ark(i, q, 17742335354489274412669987990603079185096280484072783973732137326144230832311);
        sbox_partial(i, q);
        mix(i, q);
        // round 46
        ark(i, q, 6266270088302506215402996795500854910256503071464802875821837403486057988208);
        sbox_partial(i, q);
        mix(i, q);
        // round 47
        ark(i, q, 2716062168542520412498610856550519519760063668165561277991771577403400784706);
        sbox_partial(i, q);
        mix(i, q);
        // round 48
        ark(i, q, 19118392018538203167410421493487769944462015419023083813301166096764262134232);
        sbox_partial(i, q);
        mix(i, q);
        // round 49
        ark(i, q, 9386595745626044000666050847309903206827901310677406022353307960932745699524);
        sbox_partial(i, q);
        mix(i, q);
        // round 50
        ark(i, q, 9121640807890366356465620448383131419933298563527245687958865317869840082266);
        sbox_partial(i, q);
        mix(i, q);
        // round 51
        ark(i, q, 3078975275808111706229899605611544294904276390490742680006005661017864583210);
        sbox_partial(i, q);
        mix(i, q);
        // round 52
        ark(i, q, 7157404299437167354719786626667769956233708887934477609633504801472827442743);
        sbox_partial(i, q);
        mix(i, q);
        // round 53
        ark(i, q, 14056248655941725362944552761799461694550787028230120190862133165195793034373);
        sbox_partial(i, q);
        mix(i, q);
        // round 54
        ark(i, q, 14124396743304355958915937804966111851843703158171757752158388556919187839849);
        sbox_partial(i, q);
        mix(i, q);
        // round 55
        ark(i, q, 11851254356749068692552943732920045260402277343008629727465773766468466181076);
        sbox_full(i, q);
        mix(i, q);
        // round 56
        ark(i, q, 9799099446406796696742256539758943483211846559715874347178722060519817626047);
        sbox_full(i, q);
        mix(i, q);
        // round 57
        ark(i, q, 10156146186214948683880719664738535455146137901666656566575307300522957959544);
        sbox_full(i, q);
        mix(i, q);

        return i.t0;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint96
{
    function add(
        uint96 a,
        uint96 b
        )
        internal
        pure
        returns (uint96 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(
        uint96 a,
        uint96 b
        )
        internal
        pure
        returns (uint96 c)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 DeGate DAO
pragma solidity ^0.7.0;


/// @title Utility Functions for uint
/// @author Daniel Wang - <[email protected]>
library MathUint248
{
    function add(
        uint248 a,
        uint248 b
        )
        internal
        pure
        returns (uint248 c)
    {
        c = a + b;
        require(c >= a, "ADD_OVERFLOW");
    }

    function sub(
        uint248 a,
        uint248 b
        )
        internal
        pure
        returns (uint248 c)
    {
        require(b <= a, "SUB_UNDERFLOW");
        return a - b;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ReentrancyGuard
/// @author Brecht Devos - <[email protected]>
/// @dev Exposes a modifier that guards a function against reentrancy
///      Changing the value of the same storage value multiple times in a transaction
///      is cheap (starting from Istanbul) so there is no need to minimize
///      the number of times the value is changed
contract ReentrancyGuard
{
    //The default value must be 0 in order to work behind a proxy.
    uint private _guardValue;

    // Use this modifier on a function to prevent reentrancy
    modifier nonReentrant()
    {
        // Check if the guard value has its original value
        require(_guardValue == 0, "REENTRANCY");

        // Set the value to something else
        _guardValue = 1;

        // Function body
        _;

        // Set the value back
        _guardValue = 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ITokenSeller
/// @dev Use this contract to sell tokenS for as many tokenB.
/// @author Daniel Wang  - <[email protected]>
interface ITokenSeller
{
    /// @dev Sells all tokenS for tokenB
    /// @param tokenS The token or Ether (0x0) to sell.
    /// @param tokenB The token to buy.
    /// @return success True if success, false otherwise.
    function sellToken(
        address tokenS,
        address tokenB
        )
        external
        payable
        returns (bool success);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../agents/FastWithdrawalAgent.sol";
import "../../lib/OwnerManagable.sol";
import "../../lib/EIP712.sol";
import "../../lib/ERC20.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../../lib/SignatureUtil.sol";


/// @title Basic contract storing funds for a liquidity provider.
/// @author Brecht Devos - <[email protected]>
contract FastWithdrawalLiquidityProvider is ReentrancyGuard, OwnerManagable
{
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;
    using SignatureUtil     for bytes32;

    struct FastWithdrawalApproval
    {
        address exchange;
        address from;
        address to;
        address token;
        uint248  amount;
        uint32  storageID;
        uint64  validUntil; // most significant 32 bits as block height, least significant 32 bits as block time
        address signer;
        bytes   signature;  // signer's signature
    }

    bytes32 constant public FASTWITHDRAWAL_APPROVAL_TYPEHASH = keccak256(
        "FastWithdrawalApproval(address exchange,address from,address to,address token,uint248 amount,uint32 storageID,uint64 validUntil)"
    );

    bytes32 public immutable DOMAIN_SEPARATOR;

    FastWithdrawalAgent public immutable agent;

    constructor(FastWithdrawalAgent _agent)
    {
        agent = _agent;
        DOMAIN_SEPARATOR = EIP712.hash(EIP712.Domain("FastWithdrawalLiquidityProvider", "1.0", address(this)));
    }

    // Execute the fast withdrawals.
    // Full approvals are posted onchain so they can be used by anyone to speed up the
    // withdrawal by calling , but the approvals are not validated when done by the
    // owner or one of the managers.
    function execute(FastWithdrawalApproval[] calldata approvals)
        external
        nonReentrant
    {
        // Prepare the data and validate the approvals when necessary
        FastWithdrawalAgent.Withdrawal[] memory withdrawals =
            new FastWithdrawalAgent.Withdrawal[](approvals.length);

        bool skipApprovalCheck = isManager(msg.sender);
        for (uint i = 0; i < approvals.length; i++) {
            require(skipApprovalCheck || isApprovalValid(approvals[i]), "PROHIBITED");
            withdrawals[i] = translate(approvals[i]);
        }

        // Calculate how much ETH we need to send to the agent contract.
        // We could also send the full ETH balance each time, but that'll need
        // an additional transfer to send funds back, which may actually be more efficient.
        uint value = 0;
        for (uint i = 0; i < withdrawals.length; i++) {
            if (withdrawals[i].token == address(0)) {
                value = value.add(withdrawals[i].amount);
            }
        }
        // Execute all the fast withdrawals
        agent.executeFastWithdrawals{value: value}(withdrawals);
    }

    // Allows the LP to transfer funds back out of this contract.
    function drain(
        address to,
        address token,
        uint    amount
        )
        external
        nonReentrant
        onlyOwner
    {
        if (token == address(0)) {
            to.sendETHAndVerify(amount, gasleft()); // ETH
        } else {
            token.safeTransferAndVerify(to, amount);  // ERC20 token
        }
    }

    // Allows the LP to enable the necessary ERC20 approvals
    function approve(
        address token,
        address spender,
        uint    amount
        )
        external
        nonReentrant
        onlyOwner
    {
        require(ERC20(token).approve(spender, amount), "APPROVAL_FAILED");
    }

    function isApprovalValid(
        FastWithdrawalApproval calldata approval
        )
        internal
        view
        returns (bool)
    {
        // Compute the hash
        bytes32 hash = EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encodePacked(
                    FASTWITHDRAWAL_APPROVAL_TYPEHASH,
                    approval.exchange,
                    approval.from,
                    approval.to,
                    approval.token,
                    approval.amount,
                    approval.storageID,
                    approval.validUntil
                )
            )
        );

        return hash.verifySignature(approval.signer, approval.signature) &&
            checkValidUntil(approval.validUntil) &&
            isManager(approval.signer);
    }

    receive() payable external {}

    // -- Internal --

    function checkValidUntil(uint64 validUntil)
        internal
        view
        returns (bool)
    {
        return (validUntil & 0xFFFFFFFF) >= block.timestamp ||
            (validUntil >> 32) >= block.number;
    }

    function translate(FastWithdrawalApproval calldata approval)
        internal
        pure
        returns (FastWithdrawalAgent.Withdrawal memory)
    {
        return FastWithdrawalAgent.Withdrawal({
            exchange: approval.exchange,
            from: approval.from,
            to: approval.to,
            token: approval.token,
            amount: approval.amount,
            storageID: approval.storageID
        });
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../core/iface/IAgentRegistry.sol";
import "../../core/iface/IExchangeV3.sol";
import "../../lib/Claimable.sol";
import "../../lib/EIP712.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../../lib/SignatureUtil.sol";

/// @title Fast withdrawal agent implementation. With the help of liquidity providers (LPs),
///        exchange operators can convert any normal withdrawals into fast withdrawals.
///
///        Fast withdrawals are a way for the owner to provide instant withdrawals for
///        users with the help of a liquidity provider and conditional transfers.
///
///        A fast withdrawal requires the non-trustless cooperation of 2 parties:
///        - A liquidity provider which provides funds to users immediately onchain
///        - The operator which will make sure the user has sufficient funds offchain
///          so that the liquidity provider can be paid back.
///          The operator also needs to process those withdrawals so that the
///          liquidity provider receives its funds back.
///
///        We require the fast withdrawals to be executed by the liquidity provider (as msg.sender)
///        so that the liquidity provider can impose its own rules on how its funds are spent. This will
///        inevitably need to be done in close cooperation with the operator, or by the operator
///        itself using a smart contract where the liquidity provider enforces who, how
///        and even if their funds can be used to facilitate the fast withdrawals.
///
///        The liquidity provider can call `executeFastWithdrawals` to provide users
///        immediately with funds onchain. This allows the security of the funds to be handled
///        by any EOA or smart contract.
///
///        Users that want to make use of this functionality have to
///        authorize this contract as their agent.
///
/// @author Brecht Devos - <[email protected]>
/// @author Kongliang Zhong - <[email protected]>
/// @author Daniel Wang - <[email protected]>
contract FastWithdrawalAgent is ReentrancyGuard, IAgent
{
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;

    event Processed(
        address exchange,
        address from,
        address to,
        address token,
        uint248  amount,
        address provider,
        bool    success
    );

    struct Withdrawal
    {
        address exchange;
        address from;                   // The owner of the account
        address to;                     // The `to` address of the withdrawal
        address token;
        uint248  amount;
        uint32  storageID;
    }

    // This method needs to be called by any liquidity provider
    function executeFastWithdrawals(Withdrawal[] calldata withdrawals)
        external
        nonReentrant
        payable
    {
        // Do all fast withdrawals
        for (uint i = 0; i < withdrawals.length; i++) {
            executeInternal(withdrawals[i]);
        }
        // Return any ETH left into this contract
        // (can happen when more ETH is sent than needed for the fast withdrawals)
        msg.sender.sendETHAndVerify(address(this).balance, gasleft());
    }

    // -- Internal --

    function executeInternal(Withdrawal calldata withdrawal)
        internal
    {
        require(
            withdrawal.exchange != address(0) &&
            withdrawal.from != address(0) &&
            withdrawal.to != address(0) &&
            withdrawal.amount != 0,
            "INVALID_WITHDRAWAL"
        );

        // The liquidity provider always authorizes the fast withdrawal by being the direct caller
        address payable liquidityProvider = msg.sender;

        bool success;
        // Override the destination address of a withdrawal to the address of the liquidity provider
        try IExchangeV3(withdrawal.exchange).setWithdrawalRecipient(
            withdrawal.from,
            withdrawal.to,
            withdrawal.token,
            withdrawal.amount,
            withdrawal.storageID,
            liquidityProvider
        ) {
            // Transfer the tokens immediately to the requested address
            // using funds from the liquidity provider (`msg.sender`).
            transfer(
                liquidityProvider,
                withdrawal.to,
                withdrawal.token,
                withdrawal.amount
            );
            success = true;
        } catch {
            success = false;
        }

        emit Processed(
            withdrawal.exchange,
            withdrawal.from,
            withdrawal.to,
            withdrawal.token,
            withdrawal.amount,
            liquidityProvider,
            success
        );
    }

    function transfer(
        address from,
        address to,
        address token,
        uint    amount
        )
        internal
    {
        if (amount > 0) {
            if (token == address(0)) {
                to.sendETHAndVerify(amount, gasleft()); // ETH
            } else {
                token.safeTransferFromAndVerify(from, to, amount);  // ERC20 token
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

interface IAgent{}

abstract contract IAgentRegistry
{
    /// @dev Returns whether an agent address is an agent of an account owner
    /// @param owner The account owner.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address owner,
        address agent
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether an agent address is an agent of all account owners
    /// @param owners The account owners.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address[] calldata owners,
        address            agent
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether an agent address is a universal agent.
    /// @param agent The agent address
    /// @return True if the agent address is a universal agent, else false
    function isUniversalAgent(address agent)
        public
        virtual
        view
        returns (bool);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "../../lib/Claimable.sol";
import "./ExchangeData.sol";

/// @title IExchangeV3
/// @dev Note that Claimable and RentrancyGuard are inherited here to
///      ensure all data members are declared on IExchangeV3 to make it
///      easy to support upgradability through proxies.
///
///      Subclasses of this contract must NOT define constructor to
///      initialize data.
///
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
abstract contract IExchangeV3 is Claimable
{
    // -- Events --

    event ExchangeCloned(
        address exchangeAddress,
        address owner,
        bytes32 genesisMerkleRoot
    );

    event TokenRegistered(
        address token,
        uint32  tokenId
    );

    event Shutdown(
        uint timestamp
    );

    event WithdrawalModeActivated(
        uint timestamp
    );

    event BlockSubmitted(
        uint    indexed blockIdx,
        bytes32         merkleRoot,
        bytes32         publicDataHash
    );

    event DepositRequested(
        address from,
        address to,
        address token,
        uint32  tokenId,
        uint248  amount
    );

    event ForcedWithdrawalRequested(
        address owner,
        address token,
        uint32  accountID
    );

    event WithdrawalCompleted(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event WithdrawalFailed(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event ProtocolFeesUpdated(
        uint8 protocolFeeBips,
        uint8 previousProtocolFeeBips
    );

    event TransactionApproved(
        address owner,
        bytes32 transactionHash
    );

    event TransactionsApproved(
        address[] owners,
        bytes32[] transactionHashes
    );

    event BlockVerifierRefreshed(address blockVerifier);
    event DepositContractUpdate(address depositContract);
    event WithdrawExchangeFees(address token, address recipient);

    event WithdrawalRecipientUpdate(
        address from,
        address to,
        address token,
        uint248 amount,
        uint32 storageID,
        address newRecipient
    );

    event DepositParamsUpdate(
        uint256 freeDepositMax,
        uint256 freeDepositRemained,
        uint256 freeSlotPerBlock,
        uint256 depositFee
    );

    event AllowOnchainTransferFrom(bool value);

    // -- Initialization --
    /// @dev Initializes this exchange. This method can only be called once.
    /// @param  loopring The LoopringV3 contract address.
    /// @param  owner The owner of this exchange.
    /// @param  genesisMerkleRoot The initial Merkle tree state.
    /// @param  genesisMerkleAssetRoot The initial Asset Merkle tree state.
    function initialize(
        address loopring,
        address owner,
        bytes32 genesisMerkleRoot,
        bytes32 genesisMerkleAssetRoot
        )
        virtual
        external;

    ///      Can only be called by the exchange owner once.
    /// @param depositContract The deposit contract to be used
    function setDepositContract(address depositContract)
        external
        virtual;

    /// @dev refresh the blockVerifier contract which maybe changed in loopringV3 contract.
    function refreshBlockVerifier(address blockVerifierAddress)
        external
        virtual;

    /// @dev Gets the deposit contract used by the exchange.
    /// @return the deposit contract
    function getDepositContract()
        external
        virtual
        view
        returns (IDepositContract);

    // @dev Exchange owner set params for deposit.
    // @param freeDepositMax Max slots for free deposit
    // @param freeDepositRemained Remained free deposit
    // @param freeSlotPerBlock Free slot for every block
    // @param depositFee Deposit fee in ETH
    function setDepositParams(
        uint256 freeDepositMax,
        uint256 freeDepositRemained,
        uint256 freeSlotPerBlock,
        uint256 depositFee
    ) external virtual;

    // @dev Exchange owner withdraws fees from the exchange.
    // @param token Fee token address
    // @param feeRecipient Fee recipient address
    function withdrawExchangeFees(
        address token,
        address feeRecipient
        )
        external
        virtual;

    // -- Constants --
    /// @dev Returns a list of constants used by the exchange.
    /// @return constants The list of constants.
    function getConstants()
        external
        virtual
        pure
        returns(ExchangeData.Constants memory);

    // -- Mode --
    /// @dev Returns hether the exchange is in withdrawal mode.
    /// @return Returns true if the exchange is in withdrawal mode, else false.
    function isInWithdrawalMode()
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether the exchange is shutdown.
    /// @return Returns true if the exchange is shutdown, else false.
    function isShutdown()
        external
        virtual
        view
        returns (bool);

    // -- Tokens --
    /// @dev Registers an ERC20 token for a token id. Note that different exchanges may have
    ///      different ids for the same ERC20 token.
    ///
    ///      Please note that 1 is reserved for Ether (ETH), 2 is reserved for Wrapped Ether (ETH),
    ///      and 3 is reserved for Loopring Token (LRC).
    ///
    ///      This function is only callable by the exchange owner.
    ///
    /// @param  tokenAddress The token's address
    /// @return tokenID The token's ID in this exchanges.
    function registerToken(
        address tokenAddress
        )
        external
        virtual
        returns (uint32 tokenID);

    /// @dev Returns the id of a registered token.
    /// @param  tokenAddress The token's address
    /// @return tokenID The token's ID in this exchanges.
    function getTokenID(
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint32 tokenID);

    /// @dev Returns the address of a registered token.
    /// @param  tokenID The token's ID in this exchanges.
    /// @return tokenAddress The token's address
    function getTokenAddress(
        uint32 tokenID
        )
        external
        virtual
        view
        returns (address tokenAddress);

    // -- Stakes --
    /// @dev Gets the amount of LRC the owner has staked onchain for this exchange.
    ///      The stake will be burned if the exchange does not fulfill its duty by
    ///      processing user requests in time. Please note that order matching may potentially
    ///      performed by another party and is not part of the exchange's duty.
    ///
    /// @return The amount of LRC staked
    function getExchangeStake()
        external
        virtual
        view
        returns (uint);

    /// @dev Withdraws the amount staked for this exchange.
    ///      This can only be done if the exchange has been correctly shutdown:
    ///      - The exchange owner has shutdown the exchange
    ///      - All deposit requests are processed
    ///      - All funds are returned to the users (merkle root is reset to initial state)
    ///
    ///      Can only be called by the exchange owner.
    ///
    /// @return amountLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        address recipient
        )
        external
        virtual
        returns (uint amountLRC);

    /// @dev Can by called by anyone to burn the stake of the exchange when certain
    ///      conditions are fulfilled.
    ///
    ///      Currently this will only burn the stake of the exchange if
    ///      the exchange is in withdrawal mode.
    function burnExchangeStake()
        external
        virtual;

    // -- Blocks --

    /// @dev Gets the current Merkle root of this exchange's virtual blockchain.
    /// @return The current Merkle root.
    function getMerkleRoot()
        external
        virtual
        view
        returns (bytes32);

    /// @dev Gets the current Asset Merkle root of this exchange's virtual blockchain.
    /// @return The current Asset Merkle root.
    function getMerkleAssetRoot()
        external
        virtual
        view
        returns (bytes32);

    /// @dev Gets the height of this exchange's virtual blockchain. The block height for a
    ///      new exchange is 1.
    /// @return The virtual blockchain height which is the index of the last block.
    function getBlockHeight()
        external
        virtual
        view
        returns (uint);

    /// @dev Gets some minimal info of a previously submitted block that's kept onchain.
    ///      A DEX can use this function to implement a payment receipt verification
    ///      contract with a challange-response scheme.
    /// @param blockIdx The block index.
    function getBlockInfo(uint blockIdx)
        external
        virtual
        view
        returns (ExchangeData.BlockInfo memory);

    /// @dev Sumbits new blocks to the rollup blockchain.
    ///
    ///      This function can only be called by the exchange operator.
    ///
    /// @param blocks The blocks being submitted
    ///      - blockType: The type of the new block
    ///      - blockSize: The number of onchain or offchain requests/settlements
    ///        that have been processed in this block
    ///      - blockVersion: The circuit version to use for verifying the block
    ///      - storeBlockInfoOnchain: If the block info for this block needs to be stored on-chain
    ///      - data: The data for this block
    ///      - offchainData: Arbitrary data, mainly for off-chain data-availability, i.e.,
    ///        the multihash of the IPFS file that contains the block data.
    function submitBlocks(ExchangeData.Block[] calldata blocks)
        external
        virtual;

    /// @dev Gets the number of available forced request slots.
    /// @return The number of available slots.
    function getNumAvailableForcedSlots()
        external
        virtual
        view
        returns (uint);

    // -- Deposits --

    /// @dev Deposits Ether or ERC20 tokens to the specified account.
    ///
    ///      This function is only callable by an agent of 'from'.
    ///
    ///      A fee to the owner is paid in ETH to process the deposit.
    ///      The operator is not forced to do the deposit and the user can send
    ///      any fee amount.
    ///
    /// @param from The address that deposits the funds to the exchange
    /// @param to The account owner's address receiving the funds
    /// @param tokenAddress The address of the token, use `0x0` for Ether.
    /// @param amount The amount of tokens to deposit
    /// @param auxiliaryData Optional extra data used by the deposit contract
    function deposit(
        address from,
        address to,
        address tokenAddress,
        uint248  amount,
        bytes   calldata auxiliaryData
        )
        external
        virtual
        payable;

    /// @dev Gets the amount of tokens that may be added to the owner's account.
    /// @param owner The destination address for the amount deposited.
    /// @param tokenAddress The address of the token, use `0x0` for Ether.
    /// @return The amount of tokens pending.
    function getPendingDepositAmount(
        address owner,
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint248);

    // -- Withdrawals --
    /// @dev Submits an onchain request to force withdraw Ether or ERC20 tokens.
    ///      This request always withdraws the full balance.
    ///
    ///      This function is only callable by an agent of the account.
    ///
    ///      The total fee in ETH that the user needs to pay is 'withdrawalFee'.
    ///      If the user sends too much ETH the surplus is sent back immediately.
    ///
    ///      Note that after such an operation, it will take the owner some
    ///      time (no more than MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE) to process the request
    ///      and create the deposit to the offchain account.
    ///
    /// @param owner The expected owner of the account
    /// @param tokenAddress The address of the token, use `0x0` for Ether.
    /// @param accountID The address the account in the Merkle tree.
    function forceWithdraw(
        address owner,
        address tokenAddress,
        uint32  accountID
        )
        external
        virtual
        payable;

    /// @dev Checks if a forced withdrawal is pending for an account balance.
    /// @param  accountID The accountID of the account to check.
    /// @param  token The token address
    /// @return True if a request is pending, false otherwise
    function isForcedWithdrawalPending(
        uint32  accountID,
        address token
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Gets the time the protocol fee for a token was last withdrawn.
    /// @param tokenAddress The address of the token, use `0x0` for Ether.
    /// @return The time the protocol fee was last withdrawn.
    function getProtocolFeeLastWithdrawnTime(
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint);

    /// @dev Allows anyone to withdraw funds for a specified user using the balances stored
    ///      in the Merkle tree. The funds will be sent to the owner of the acount.
    ///
    ///      Can only be used in withdrawal mode (i.e. when the owner has stopped
    ///      committing blocks and is not able to commit any more blocks).
    ///
    ///      This will NOT modify the onchain merkle root! The merkle root stored
    ///      onchain will remain the same after the withdrawal. We store if the user
    ///      has withdrawn the balance in State.withdrawnInWithdrawMode.
    ///
    /// @param  merkleProof The Merkle inclusion proof
    function withdrawFromMerkleTree(
        ExchangeData.MerkleProof calldata merkleProof
        )
        external
        virtual;

    /// @dev Checks if the balance for the account was withdrawn with `withdrawFromMerkleTree`.
    /// @param  accountID The accountID of the balance to check.
    /// @param  token The token address
    /// @return True if it was already withdrawn, false otherwise
    function isWithdrawnInWithdrawalMode(
        uint32  accountID,
        address token
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Allows withdrawing funds deposited to the contract in a deposit request when
    ///      it was never processed by the owner within the maximum time allowed.
    ///
    ///      Can be called by anyone. The deposited tokens will be sent back to
    ///      the owner of the account they were deposited in.
    ///
    /// @param  owner The address of the account the withdrawal was done for.
    /// @param  token The token address
    function withdrawFromDepositRequest(
        address owner,
        address token
        )
        external
        virtual;

    /// @dev Allows withdrawing funds after a withdrawal request (either onchain
    ///      or offchain) was submitted in a block by the operator.
    ///
    ///      Can be called by anyone. The withdrawn tokens will be sent to
    ///      the owner of the account they were withdrawn out.
    ///
    ///      Normally it is should not be needed for users to call this manually.
    ///      Funds from withdrawal requests will be sent to the account owner
    ///      immediately by the owner when the block is submitted.
    ///      The user will however need to call this manually if the transfer failed.
    ///
    ///      Tokens and owners must have the same size.
    ///
    /// @param  owners The addresses of the account the withdrawal was done for.
    /// @param  tokens The token addresses
    function withdrawFromApprovedWithdrawals(
        address[] calldata owners,
        address[] calldata tokens
        )
        external
        virtual;

    /// @dev Gets the amount that can be withdrawn immediately with `withdrawFromApprovedWithdrawals`.
    /// @param  owner The address of the account the withdrawal was done for.
    /// @param  token The token address
    /// @return The amount withdrawable
    function getAmountWithdrawable(
        address owner,
        address token
        )
        external
        virtual
        view
        returns (uint);

    /// @dev Notifies the exchange that the owner did not process a forced request.
    ///      If this is indeed the case, the exchange will enter withdrawal mode.
    ///
    ///      Can be called by anyone.
    ///
    /// @param  accountID The accountID the forced request was made for
    /// @param  token The token address of the the forced request
    function notifyForcedRequestTooOld(
        uint32  accountID,
        address token
        )
        external
        virtual;

    /// @dev Allows a withdrawal to be done to an adddresss that is different
    ///      than initialy specified in the withdrawal request. This can be used to
    ///      implement functionality like fast withdrawals.
    ///
    ///      This function can only be called by an agent.
    ///
    /// @param from The address of the account that does the withdrawal.
    /// @param to The address to which 'amount' tokens were going to be withdrawn.
    /// @param token The address of the token that is withdrawn ('0x0' for ETH).
    /// @param amount The amount of tokens that are going to be withdrawn.
    /// @param storageID The storageID of the withdrawal request.
    /// @param newRecipient The new recipient address of the withdrawal.
    function setWithdrawalRecipient(
        address from,
        address to,
        address token,
        uint248  amount,
        uint32  storageID,
        address newRecipient
        )
        external
        virtual;

    /// @dev Gets the withdrawal recipient.
    ///
    /// @param from The address of the account that does the withdrawal.
    /// @param to The address to which 'amount' tokens were going to be withdrawn.
    /// @param token The address of the token that is withdrawn ('0x0' for ETH).
    /// @param amount The amount of tokens that are going to be withdrawn.
    /// @param storageID The storageID of the withdrawal request.
    function getWithdrawalRecipient(
        address from,
        address to,
        address token,
        uint248  amount,
        uint32  storageID
        )
        external
        virtual
        view
        returns (address);

    /// @dev Allows an agent to transfer ERC-20 tokens for a user using the allowance
    ///      the user has set for the exchange. This way the user only needs to approve a single exchange contract
    ///      for all exchange/agent features, which allows for a more seamless user experience.
    ///
    ///      This function can only be called by an agent.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (ETH is and cannot be suppported).
    /// @param amount The amount of tokens transferred.
    function onchainTransferFrom(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        virtual;

    /// @dev Allows an agent to approve a rollup tx.
    ///
    ///      This function can only be called by an agent.
    ///
    /// @param owner The owner of the account
    /// @param txHash The hash of the transaction
    function approveTransaction(
        address owner,
        bytes32 txHash
        )
        external
        virtual;

    /// @dev Allows an agent to approve multiple rollup txs.
    ///
    ///      This function can only be called by an agent.
    ///
    /// @param owners The account owners
    /// @param txHashes The hashes of the transactions
    function approveTransactions(
        address[] calldata owners,
        bytes32[] calldata txHashes
        )
        external
        virtual;

    /// @dev Checks if a rollup tx is approved using the tx's hash.
    ///
    /// @param owner The owner of the account that needs to authorize the tx
    /// @param txHash The hash of the transaction
    /// @return True if the tx is approved, else false
    function isTransactionApproved(
        address owner,
        bytes32 txHash
        )
        external
        virtual
        view
        returns (bool);

    // -- Admins --
    /// @dev Sets the max time deposits have to wait before becoming withdrawable.
    /// @param newValue The new value.
    /// @return  The old value.
    function setMaxAgeDepositUntilWithdrawable(
        uint32 newValue
        )
        external
        virtual
        returns (uint32);

    /// @dev Returns the max time deposits have to wait before becoming withdrawable.
    /// @return The value.
    function getMaxAgeDepositUntilWithdrawable()
        external
        virtual
        view
        returns (uint32);

    /// @dev Shuts down the exchange.
    ///      Once the exchange is shutdown all onchain requests are permanently disabled.
    ///      When all requirements are fulfilled the exchange owner can withdraw
    ///      the exchange stake with withdrawStake.
    ///
    ///      Note that the exchange can still enter the withdrawal mode after this function
    ///      has been invoked successfully. To prevent entering the withdrawal mode before the
    ///      the echange stake can be withdrawn, all withdrawal requests still need to be handled
    ///      for at least MIN_TIME_IN_SHUTDOWN seconds.
    ///
    ///      Can only be called by the exchange owner.
    ///
    /// @return success True if the exchange is shutdown, else False
    function shutdown()
        external
        virtual
        returns (bool success);

    /// @dev Gets the protocol fees for this exchange.
    /// @return syncedAt The timestamp the protocol fees were last updated
    /// @return protocolFeeBips The protocol fee
    /// @return previousProtocolFeeBips The previous protocol fee
    /// @return executeTimeOfNextProtocolFeeBips The timestamp the next protocol fees will be updated
    /// @return nextProtocolFeeBips The next protocol fee
    function getProtocolFeeValues()
        external
        virtual
        view
        returns (
            uint32 syncedAt,
            uint8 protocolFeeBips,
            uint8 previousProtocolFeeBips,
            uint32 executeTimeOfNextProtocolFeeBips,
            uint32 nextProtocolFeeBips
        );

    /// @dev Gets the domain separator used in this exchange.
    function getDomainSeparator()
        external
        virtual
        view
        returns (bytes32);

    /// @dev Gets the uncomfirmed balance in DepositContract, which can be used for DepositTransaction.
    /// @param tokenAddress The address of the token, use `0x0` for Ether.
    /// @return Unconfirmed balance of the token
    function getUnconfirmedBalance(
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint256);

    /// @dev Gets free deposit slots
    function getFreeDepositRemained()
        external
        virtual
        view
        returns (uint256);

    /// @dev Gets token deposit balance
    /// @param tokenAddress The address of the token, use `0x0` for Ether.
    /// @return deposit balance of the token
    function getDepositBalance(
        address tokenAddress
        )
        external
        virtual
        view
        returns (uint248);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "./IAgentRegistry.sol";
import "./IBlockVerifier.sol";
import "./IDepositContract.sol";
import "./ILoopringV3.sol";

/// @title ExchangeData
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeData
{
    // -- Enums --
    enum TransactionType
    {
        NOOP,
        DEPOSIT,
        WITHDRAWAL,
        TRANSFER,
        SPOT_TRADE,
        ACCOUNT_UPDATE,
        ORDER_CANCEL,
        BATCH_SPOT_TRADE,
        APPKEY_UPDATE
    }

    // -- Structs --
    struct Token
    {
        address token;
    }

    struct ProtocolFeeData
    {
        uint32 syncedAt; // only valid before 2105 (85 years to go)
        uint8  protocolFeeBips;
        uint8  previousProtocolFeeBips;

        uint32 executeTimeOfNextProtocolFeeBips;
        uint8  nextProtocolFeeBips;
    }

    // General auxiliary data for each conditional transaction
    struct AuxiliaryData
    {
        bytes data;
    }

    // This is the (virtual) block the owner  needs to submit onchain to maintain the
    // per-exchange (virtual) blockchain.
    struct Block
    {
        uint8      blockType;
        uint16     blockSize;
        uint8      blockVersion;
        bytes      data;
        uint256[8] proof;

        // Whether we should store the @BlockInfo for this block on-chain.
        bool storeBlockInfoOnchain;

        // Block specific data that is only used to help process the block on-chain.
        // It is not used as input for the circuits and it is not necessary for data-availability.
        // This bytes array contains the abi encoded AuxiliaryData[] data.
        bytes auxiliaryData;

        // Arbitrary data, mainly for off-chain data-availability, i.e.,
        // the multihash of the IPFS file that contains the block data.
        bytes offchainData;
    }

    struct BlockInfo
    {
        // The time the block was submitted on-chain.
        uint32  timestamp;
        // The public data hash of the block (the 28 most significant bytes).
        bytes28 blockDataHash;
    }

    // Represents an onchain deposit request.
    struct Deposit
    {
        uint248 amount;
        uint64 timestamp;
    }

    // A forced withdrawal request.
    // If the actual owner of the account initiated the request (we don't know who the owner is
    // at the time the request is being made) the full balance will be withdrawn.
    struct ForcedWithdrawal
    {
        address owner;
        uint64  timestamp;
    }

    struct Constants
    {
        uint SNARK_SCALAR_FIELD;
        uint MAX_OPEN_FORCED_REQUESTS;
        uint MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE;
        uint TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS;
        uint MAX_NUM_ACCOUNTS;
        uint MAX_NUM_TOKENS;
        uint MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED;
        uint MIN_TIME_IN_SHUTDOWN;
        uint TX_DATA_AVAILABILITY_SIZE;
        uint MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND;
        uint MAX_FORCED_WITHDRAWAL_FEE;
        uint MAX_PROTOCOL_FEE_BIPS;
        uint DEFAULT_PROTOCOL_FEE_BIPS;
    }

    // This is the prime number that is used for the alt_bn128 elliptic curve, see EIP-196.
    uint public constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint public constant MAX_OPEN_FORCED_REQUESTS = 100;
    uint public constant MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE = 1 days;
    uint public constant TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS = 7 days;
    uint public constant BINARY_TREE_DEPTH_ACCOUNTS = 32;
    uint public constant MAX_NUM_ACCOUNTS = 2 ** BINARY_TREE_DEPTH_ACCOUNTS;
    uint public constant BINARY_TREE_DEPTH_TOKENS = 32;
    uint public constant MAX_NUM_TOKENS = 2 ** BINARY_TREE_DEPTH_TOKENS;
    uint public constant MAX_NUM_RESERVED_TOKENS = 32;
    uint public constant MAX_NUM_NORMAL_TOKENS = 2 ** BINARY_TREE_DEPTH_TOKENS - 32;

    uint public constant MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED = 1 days;
    uint public constant MIN_TIME_IN_SHUTDOWN = 3 days;
    uint32 public constant MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND = 1 days;
    uint32 public constant ACCOUNTID_PROTOCOLFEE = 0;

    // The amount of bytes each rollup transaction uses in the block data for data-availability.
    // This is the maximum amount of bytes of all different transaction types.
    uint public constant TX_DATA_AVAILABILITY_SIZE = 83;
    uint public constant TX_DATA_AVAILABILITY_SIZE_PART_1 = 80;
    uint public constant TX_DATA_AVAILABILITY_SIZE_PART_2 = 3;

    uint public constant MAX_FORCED_WITHDRAWAL_FEE = 0.25 ether;

    uint8 public constant MAX_PROTOCOL_FEE_BIPS = 100;
    uint8 public constant DEFAULT_PROTOCOL_FEE_BIPS = 18;

    struct AccountLeaf
    {
        uint32   accountID;
        address  owner;
        uint     pubKeyX;
        uint     pubKeyY;
        uint32   nonce;
    }

    struct BalanceLeaf
    {
        uint32  tokenID;
        uint248 balance;
    }

    struct MerkleProof
    {
        ExchangeData.AccountLeaf accountLeaf;
        ExchangeData.BalanceLeaf balanceLeaf;
        uint[48]                 accountMerkleProof;
        uint[48]                 balanceMerkleProof;
    }

    struct BlockContext
    {
        bytes32 DOMAIN_SEPARATOR;
        uint32  timestamp;
    }

   struct DepositState {
        uint256 freeDepositMax;
        uint256 freeDepositRemained;
        uint256 lastDepositBlockNum;
        uint256 freeSlotPerBlock;
        uint256 depositFee;
    }

    struct ModeTime {
        // Time when the exchange was shutdown
        uint shutdownModeStartTime;

        // Time when the exchange has entered withdrawal mode
        uint withdrawalModeStartTime;
    }

    // Represents the entire exchange state except the owner of the exchange.
    struct State
    {
        uint32  maxAgeDepositUntilWithdrawable;
        bytes32 DOMAIN_SEPARATOR;

        ILoopringV3      loopring;
        IBlockVerifier   blockVerifier;
        IAgentRegistry   agentRegistry;
        IDepositContract depositContract;
        DepositState depositState;
        // The merkle root of the offchain data stored in a Merkle tree. The Merkle tree
        // stores balances for users using an account model.
        bytes32 merkleRoot;
        bytes32 merkleAssetRoot;

        // List of all blocks
        mapping(uint => BlockInfo) blocks;
        uint  numBlocks;

        // List of all tokens
        Token[] reservedTokens;
        Token[] normalTokens;

        // A map from a tokenID to deposit balance
        mapping(uint32 => uint248) tokenIdToDepositBalance;

        // A map from a token to its tokenID + 1
        mapping (address => uint32) tokenToTokenId;
        mapping (uint32 => address) tokenIdToToken;

        // A map from an accountID to a tokenID to if the balance is withdrawn
        mapping (uint32 => mapping (uint32 => bool)) withdrawnInWithdrawMode;

        // A map from an account to a token to the amount withdrawable for that account.
        // This is only used when the automatic distribution of the withdrawal failed.
        mapping (address => mapping (uint32 => uint248)) amountWithdrawable;

        // A map from an account to a token to the forced withdrawal (always full balance)
        mapping (uint32 => mapping (uint32 => ForcedWithdrawal)) pendingForcedWithdrawals;

        // A map from an address to a token to a deposit
        mapping (address => mapping (uint32 => Deposit)) pendingDeposits;

        // A map from an account owner to an approved transaction hash to if the transaction is approved or not
        mapping (address => mapping (bytes32 => bool)) approvedTx;

        // A map from an account owner to a destination address to a tokenID to an amount to a storageID to a new recipient address
        mapping (address => mapping (address => mapping (uint32 => mapping (uint => mapping (uint32 => address))))) withdrawalRecipient;

        // Counter to keep track of how many of forced requests are open so we can limit the work that needs to be done by the owner
        uint32 numPendingForcedTransactions;

        // Cached data for the protocol fee
        ProtocolFeeData protocolFeeData;

        ModeTime modeTime;

        // Last time the protocol fee was withdrawn for a specific token
        mapping (address => uint) protocolFeeLastWithdrawnTime;
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "../../lib/Claimable.sol";

/// @title IBlockVerifier
/// @author Brecht Devos - <[email protected]>
abstract contract IBlockVerifier is Claimable
{
    // -- Events --

    event CircuitRegistered(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CircuitDisabled(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    // -- Public functions --

    /// @dev Sets the verifying key for the specified circuit.
    ///      Every block permutation needs its own circuit and thus its own set of
    ///      verification keys. Only a limited number of block sizes per block
    ///      type are supported.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param vk The verification key
    function registerCircuit(
        uint8    blockType,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        virtual;

    /// @dev Disables the use of the specified circuit.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    function disableCircuit(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual;

    /// @dev Verifies blocks with the given public data and proofs.
    ///      Verifying a block makes sure all requests handled in the block
    ///      are correctly handled by the operator.
    /// @param blockType The type of block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param publicInputs The hash of all the public data of the blocks
    /// @param proofs The ZK proofs proving that the blocks are correct
    /// @return True if the block is valid, false otherwise
    function verifyProofs(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Checks if a circuit with the specified parameters is registered.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is registered, false otherwise
    function isCircuitRegistered(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Checks if a circuit can still be used to commit new blocks.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is enabled, false otherwise
    function isCircuitEnabled(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title IDepositContract.
/// @dev   Contract storing and transferring funds for an exchange.
///
///        ERC1155 tokens can be supported by registering pseudo token addresses calculated
///        as `address(keccak256(real_token_address, token_params))`. Then the custom
///        deposit contract can look up the real token address and paramsters with the
///        pseudo token address before doing the transfers.
/// @author Brecht Devos - <[email protected]>
interface IDepositContract
{
    /// @dev Returns if a token is suppoprted by this contract.
    function isTokenSupported(address token)
        external
        view
        returns (bool);

    /// @dev Transfers tokens from a user to the exchange. This function will
    ///      be called when a user deposits funds to the exchange.
    ///      In a simple implementation the funds are simply stored inside the
    ///      deposit contract directly. More advanced implementations may store the funds
    ///      in some DeFi application to earn interest, so this function could directly
    ///      call the necessary functions to store the funds there.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param token The address of the token to transfer (`0x0` for ETH).
    /// @param amount The amount of tokens to transfer.
    /// @param extraData Opaque data that can be used by the contract to handle the deposit
    /// @return amountReceived The amount to deposit to the user's account in the Merkle tree
    function deposit(
        address from,
        address token,
        uint248  amount,
        bytes   calldata extraData
        )
        external
        payable
        returns (uint248 amountReceived);

    /// @dev Transfers tokens from the exchange to a user. This function will
    ///      be called when a withdrawal is done for a user on the exchange.
    ///      In the simplest implementation the funds are simply stored inside the
    ///      deposit contract directly so this simply transfers the requested tokens back
    ///      to the user. More advanced implementations may store the funds
    ///      in some DeFi application to earn interest so the function would
    ///      need to get those tokens back from the DeFi application first before they
    ///      can be transferred to the user.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address from which 'amount' tokens are transferred.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (`0x0` for ETH).
    /// @param amount The amount of tokens transferred.
    function withdraw(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        payable;

    /// @dev Transfers tokens (ETH not supported) for a user using the allowance set
    ///      for the exchange. This way the approval can be used for all functionality (and
    ///      extended functionality) of the exchange.
    ///      Should NOT be used to deposit/withdraw user funds, `deposit`/`withdraw`
    ///      should be used for that as they will contain specialised logic for those operations.
    ///      This function can be called by the exchange to transfer onchain funds of users
    ///      necessary for Agent functionality.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (ETH is and cannot be suppported).
    /// @param amount The amount of tokens transferred.
    function transfer(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        payable;

    /// @dev Checks if the given address is used for depositing ETH or not.
    ///      Is used while depositing to send the correct ETH amount to the deposit contract.
    ///
    ///      Note that 0x0 is always registered for deposting ETH when the exchange is created!
    ///      This function allows additional addresses to be used for depositing ETH, the deposit
    ///      contract can implement different behaviour based on the address value.
    ///
    /// @param addr The address to check
    /// @return True if the address is used for depositing ETH, else false.
    function isETH(address addr)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../lib/Claimable.sol";


/// @title ILoopringV3
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
abstract contract ILoopringV3 is Claimable
{
    // == Events ==
    event ExchangeStakeDeposited(address exchangeAddr, uint amount);
    event ExchangeStakeWithdrawn(address exchangeAddr, uint amount);
    event ExchangeStakeBurned(address exchangeAddr, uint amount);
    event SettingsUpdated(uint time);

    // == Public Variables ==
    mapping (address => uint) internal exchangeStake;

    uint    public totalStake;
    address public blockVerifierAddress;
    uint    public forcedWithdrawalFee;
    uint8   public protocolFeeBips;
    

    address payable public protocolFeeVault;

    // == Public Functions ==

    /// @dev Returns the LRC token address
    /// @return the LRC token address
    function lrcAddress()
        external
        view
        virtual
        returns (address);

    /// @dev Updates the global exchange settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateSettings(
        address payable _protocolFeeVault,   // address(0) not allowed
        uint    _forcedWithdrawalFee
        )
        external
        virtual;

    /// @dev Updates the global protocol fee settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateProtocolFeeSettings(
        uint8 _protocolFeeBips
        )
        external
        virtual;

    /// @dev Gets the amount of staked LRC for an exchange.
    /// @param exchangeAddr The address of the exchange
    /// @return stakedLRC The amount of LRC
    function getExchangeStake(
        address exchangeAddr
        )
        external
        virtual
        view
        returns (uint stakedLRC);

    /// @dev Burns a certain amount of staked LRC for a specific exchange.
    ///      This function is meant to be called only from exchange contracts.
    /// @return burnedLRC The amount of LRC burned. If the amount is greater than
    ///         the staked amount, all staked LRC will be burned.
    function burnExchangeStake(
        uint amount
        )
        external
        virtual
        returns (uint burnedLRC);

    /// @dev Stakes more LRC for an exchange.
    /// @param  exchangeAddr The address of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositExchangeStake(
        address exchangeAddr,
        uint    amountLRC
        )
        external
        virtual
        returns (uint stakedLRC);

    /// @dev Withdraws a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  recipient The address to receive LRC
    /// @param  requestedAmount The amount of LRC to withdraw
    /// @return amountLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        address recipient,
        uint    requestedAmount
        )
        external
        virtual
        returns (uint amountLRC);

    /// @dev Gets the protocol fee values for an exchange.
    /// @return feeBips The protocol fee
    function getProtocolFeeValues(
        )
        external
        virtual
        view
        returns (
            uint8 feeBips
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../core/iface/IAgentRegistry.sol";
import "../../lib/AddressSet.sol";
import "../../lib/Claimable.sol";


contract AgentRegistry is IAgentRegistry, AddressSet, Claimable
{
    bytes32 internal constant UNIVERSAL_AGENTS = keccak256("__UNVERSAL_AGENTS__");

    event AgentRegistered(
        address indexed user,
        address indexed agent,
        bool            registered
    );

    event TrustUniversalAgents(
        address indexed user,
        bool            trust
    );

    constructor() Claimable() {}

    function isAgent(
        address user,
        address agent
        )
        external
        override
        view
        returns (bool)
    {
        return isUniversalAgent(agent) || isUserAgent(user, agent);
    }

    function isAgent(
        address[] calldata users,
        address            agent
        )
        external
        override
        view
        returns (bool)
    {
        if (isUniversalAgent(agent)) {
            return true;
        }
        for (uint i = 0; i < users.length; i++) {
            if (!isUserAgent(users[i], agent)) {
                return false;
            }
        }
        return true;
    }

    function registerUniversalAgent(
        address agent,
        bool    toRegister
        )
        external
        onlyOwner
    {
        registerInternal(UNIVERSAL_AGENTS, agent, toRegister);
        emit AgentRegistered(address(0), agent, toRegister);
    }

    function isUniversalAgent(address agent)
        public
        override
        view
        returns (bool)
    {
        return isAddressInSet(UNIVERSAL_AGENTS, agent);
    }

    function registerUserAgent(
        address agent,
        bool    toRegister
        )
        external
    {
        registerInternal(userKey(msg.sender), agent, toRegister);
        emit AgentRegistered(msg.sender, agent, toRegister);
    }

    function isUserAgent(
        address user,
        address agent
        )
        public
        view
        returns (bool)
    {
        return isAddressInSet(userKey(user), agent);
    }

    function registerInternal(
        bytes32 key,
        address agent,
        bool    toRegister
        )
        private
    {
        require(agent != address(0), "ZERO_ADDRESS");
        if (toRegister) {
            addAddressToSet(key, agent, false /* maintanList */);
        } else {
            removeAddressFromSet(key, agent);
        }
    }

    function userKey(address addr)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("__AGENT__", addr));
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../core/iface/IExchangeV3.sol";
import "../../lib/ReentrancyGuard.sol";
import "../../lib/OwnerManagable.sol";
import "../../lib/AddressUtil.sol";
import "../../lib/Drainable.sol";

/// @author Kongliang Zhong - <[email protected]>
contract ForcedWithdrawalAgent is ReentrancyGuard, OwnerManagable, Drainable
{
    using AddressUtil for address;

    function canDrain(address /*drainer*/, address /*token*/)
        public
        override
        view
        returns (bool) {
        return msg.sender == owner || isManager(msg.sender);
    }

    function doForcedWithdrawalFor(
        address exchangeAddress,
        address from,
        address token,
        uint32 accountID
        )
        external
        payable
        nonReentrant
        onlyOwnerOrManager
    {
        IExchangeV3(exchangeAddress).forceWithdraw{value: msg.value}(from, token, accountID);

        if (address(this).balance > 0) {
            drain(msg.sender, address(0));
        }
    }

    receive() external payable { }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "../../lib/ReentrancyGuard.sol";
import "../../lib/Drainable.sol";

abstract contract ILoopringV3Partial
{
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        virtual
        returns (uint amount);
}

/// @author Kongliang Zhong - <[email protected]>
/// @dev This contract enables an alternative approach of getting back assets from Loopring Exchange v1.
/// Now you don't have to withdraw using merkle proofs (very expensive);
/// instead, all assets will be distributed on Loopring Exchange v2 - Loopring's new zkRollup implementation.
/// Please activate and unlock your address on https://exchange.loopring.io to claim your assets.
contract MigrationToLoopringExchangeV2 is Drainable
{
    function canDrain(address /*drainer*/, address /*token*/)
        public
        override
        view
        returns (bool) {
        return isMigrationOperator();
    }

    function withdrawExchangeStake(
        address loopringV3,
        uint exchangeId,
        uint amount,
        address recipient
        )
        external
    {
        require(isMigrationOperator(), "INVALID_SENDER");
        ILoopringV3Partial(loopringV3).withdrawExchangeStake(exchangeId, recipient, amount);
    }

    function isMigrationOperator() internal view returns (bool) {
        return msg.sender == 0x4374D3d032B3c96785094ec9f384f07077792768;
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../aux/compression/ZeroDecompressor.sol";
import "../../core/iface/IExchangeV3.sol";
import "../../thirdparty/BytesUtil.sol";
import "../../lib/AddressUtil.sol";
import "../../lib/Drainable.sol";
import "../../lib/ERC1271.sol";
import "../../lib/MathUint.sol";
import "../../lib/SignatureUtil.sol";
import "./SelectorBasedAccessManager.sol";
import "./IBlockReceiver.sol";


contract LoopringIOExchangeOwner is SelectorBasedAccessManager, ERC1271, Drainable
{
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using BytesUtil         for bytes;
    using MathUint          for uint;
    using SignatureUtil     for bytes32;

    bytes4    private constant SUBMITBLOCKS_SELECTOR = IExchangeV3.submitBlocks.selector;
    bool      public  open;

    event SubmitBlocksAccessOpened(bool open);

    struct TxCallback
    {
        uint16 txIdx;
        uint16 numTxs;
        uint16 receiverIdx;
        bytes  data;
    }

    struct BlockCallback
    {
        uint16        blockIdx;
        TxCallback[]  txCallbacks;
    }

    struct CallbackConfig
    {
        BlockCallback[] blockCallbacks;
        address[]       receivers;
    }

    constructor(
        address _exchange
        )
        SelectorBasedAccessManager(_exchange)
    {
    }

    function openAccessToSubmitBlocks(bool _open)
        external
        onlyOwner
    {
        open = _open;
        emit SubmitBlocksAccessOpened(_open);
    }

    function isValidSignature(
        bytes32        signHash,
        bytes   memory signature
        )
        external
        view
        override
        returns (bytes4)
    {
        // Role system used a bit differently here.
        return hasAccessTo(
            signHash.recoverECDSASigner(signature),
            this.isValidSignature.selector
        ) ? ERC1271_MAGICVALUE : bytes4(0);
    }

    function canDrain(address drainer, address /* token */)
        public
        override
        view
        returns (bool)
    {
        return hasAccessTo(drainer, this.drain.selector);
    }

    function submitBlocks(
        bool                     isDataCompressed,
        bytes           calldata data
        )
        external
    {
        require(
            hasAccessTo(msg.sender, SUBMITBLOCKS_SELECTOR) || open,
            "PERMISSION_DENIED"
        );
        bytes memory decompressed = isDataCompressed ?
            ZeroDecompressor.decompress(data, 1):
            data;

        require(
            decompressed.toBytes4(0) == SUBMITBLOCKS_SELECTOR,
            "INVALID_DATA"
        );

        target.fastCallAndVerify(gasleft(), 0, decompressed);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ZeroDecompressor
/// @author Brecht Devos - <[email protected]>
/// @dev Easy decompressor that compresses runs of zeros.
/// The format is very simple. Each entry consists of
/// (uint16 numDataBytes, uint16 numZeroBytes) which will
/// copy `numDataBytes` data bytes from `data` and will
/// add an additional `numZeroBytes` after it.
library ZeroDecompressor
{
    function decompress(
        bytes calldata /*data*/,
        uint  parameterIdx
        )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory uncompressed;
        uint offsetPos = 4 + 32 * parameterIdx;
        assembly {
            uncompressed := mload(0x40)
            let ptr := add(uncompressed, 32)
            let offset := add(4, calldataload(offsetPos))
            let pos := add(offset, 4)
            let dataLength := add(calldataload(offset), pos)
            let tupple := 0
            let numDataBytes := 0
            let numZeroBytes := 0

            for {} lt(pos, dataLength) {} {
                tupple := and(calldataload(pos), 0xFFFFFFFF)
                numDataBytes := shr(16, tupple)
                numZeroBytes := and(tupple, 0xFFFF)
                calldatacopy(ptr, add(32, pos), numDataBytes)
                pos := add(pos, add(4, numDataBytes))
                ptr := add(ptr, add(numDataBytes, numZeroBytes))
            }

            // Store data length
            mstore(uncompressed, sub(sub(ptr, uncompressed), 32))

            // Update free memory pointer
            mstore(0x40, add(ptr, 0x20))
        }
        return uncompressed;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../core/iface/IExchangeV3.sol";
import "../../lib/Claimable.sol";
import "../../thirdparty/BytesUtil.sol";


/// @title  SelectorBasedAccessManager
/// @author Daniel Wang - <[email protected]>
contract SelectorBasedAccessManager is Claimable
{
    using BytesUtil for bytes;

    event PermissionUpdate(
        address indexed user,
        bytes4  indexed selector,
        bool            allowed
    );

    event TargetCalled(
        address target,
        bytes data
    );

    address public immutable target;
    mapping(address => mapping(bytes4 => bool)) public permissions;

    modifier withAccess(bytes4 selector)
    {
        require(hasAccessTo(msg.sender, selector), "PERMISSION_DENIED");
        _;
    }

    constructor(address _target)
    {
        require(_target != address(0), "ZERO_ADDRESS");
        target = _target;
    }

    function grantAccess(
        address user,
        bytes4  selector,
        bool    granted
        )
        external
        onlyOwner
    {
        require(permissions[user][selector] != granted, "INVALID_VALUE");
        permissions[user][selector] = granted;
        emit PermissionUpdate(user, selector, granted);
    }

    receive() payable external {}

    fallback()
        payable
        external
    {
        transact(msg.data);
    }

    function transact(bytes memory data)
        payable
        public
        withAccess(data.toBytes4(0))
    {
        (bool success, bytes memory returnData) = target
            .call{value: msg.value}(data);

        if (!success) {
            assembly { revert(add(returnData, 32), mload(returnData)) }
        }

        emit TargetCalled(target, data);
    }

    function hasAccessTo(address user, bytes4 selector)
        public
        view
        returns (bool)
    {
        return user == owner || permissions[user][selector];
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../core/iface/ExchangeData.sol";

/// @title IBlockReceiver
/// @author Brecht Devos - <[email protected]>
abstract contract IBlockReceiver
{
    function beforeBlockSubmission(
        bytes              calldata txsData,
        bytes              calldata callbackData
        )
        external
        virtual;
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../lib/Claimable.sol";
import "./DelayedTransaction.sol";


/// @title  DelayedOwner
/// @author Brecht Devos - <[email protected]>
contract DelayedOwner is DelayedTransaction, Claimable
{
    address public defaultContract;

    event FunctionDelayUpdate(
        bytes4  functionSelector,
        uint    delay
    );

    constructor(
        address _defaultContract,
        uint    _timeToLive
        )
        DelayedTransaction(_timeToLive)
    {
        require(_defaultContract != address(0), "INVALID_ADDRESS");

        defaultContract = _defaultContract;
    }

    receive()
        external
        // nonReentrant
        payable
    {
        // Don't do anything when receiving ETH
    }

    fallback()
        external
        nonReentrant
        payable
    {
        // Don't do anything if msg.sender isn't the owner
        if (msg.sender != owner) {
            return;
        }
        transactInternal(defaultContract, msg.value, msg.data);
    }

    function isAuthorizedForTransactions(address sender)
        internal
        override
        view
        returns (bool)
    {
        return sender == owner;
    }

    function setFunctionDelay(
        bytes4  functionSelector,
        uint    delay
        )
        internal
    {
        setFunctionDelay(defaultContract, functionSelector, delay);

        emit FunctionDelayUpdate(functionSelector, delay);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../../lib/AddressUtil.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../../thirdparty/BytesUtil.sol";
import "./IDelayedTransaction.sol";


/// @title DelayedOwner
/// @author Brecht Devos - <[email protected]>
/// @dev Base class for an Owner contract where certain functions have
///      a mandatory delay for security purposes.
abstract contract DelayedTransaction is IDelayedTransaction, ReentrancyGuard
{
    using AddressUtil for address payable;
    using BytesUtil   for bytes;
    using MathUint    for uint;

    // Map from address and function to the functions's location+1 in the `delayedFunctions` array.
    mapping (address => mapping (bytes4 => uint)) private delayedFunctionMap;

    // Map from transaction ID to the transaction's location+1 in the `pendingTransactions` array.
    mapping (uint => uint) private pendingTransactionMap;

    // Used to generate a unique identifier for a delayed transaction
    uint private totalNumDelayedTransactions = 0;

    modifier onlyAuthorized
    {
        require(isAuthorizedForTransactions(msg.sender), "UNAUTHORIZED");
        _;
    }

    constructor(
        uint    _timeToLive
        )
    {
        timeToLive = _timeToLive;
    }

    // If the function that is called has no delay the function is called immediately,
    // otherwise the function call is stored on-chain and can be executed later using
    // `executeTransaction` when the necessary time has passed.
    function transact(
        address to,
        bytes   calldata data
        )
        external
        override
        nonReentrant
        payable
        onlyAuthorized
    {
        transactInternal(to, msg.value, data);
    }

    function executeTransaction(
        uint transactionId
        )
        external
        override
        nonReentrant
        onlyAuthorized
    {
        Transaction memory transaction = getTransaction(transactionId);

        // Make sure the delay is respected
        bytes4 functionSelector = transaction.data.toBytes4(0);
        uint delay = getFunctionDelay(transaction.to, functionSelector);
        require(block.timestamp >= transaction.timestamp.add(delay), "TOO_EARLY");
        require(block.timestamp <= transaction.timestamp.add(delay).add(timeToLive), "TOO_LATE");

        // Remove the transaction
        removeTransaction(transaction.id);

        // Exectute the transaction
        (bool success, bytes memory returnData) = exectuteTransaction(transaction);
        if (!success) {
            assembly { revert(add(returnData, 32), mload(returnData)) }
        }

        emit PendingTransactionExecuted(
            transaction.id,
            transaction.timestamp,
            transaction.to,
            transaction.value,
            transaction.data
        );
    }

    function cancelTransaction(
        uint transactionId
        )
        external
        override
        nonReentrant
        onlyAuthorized
    {
        cancelTransactionInternal(transactionId);
    }

    function cancelAllTransactions()
        external
        override
        nonReentrant
        onlyAuthorized
    {
        // First cache all transactions ids of the transactions we will remove
        uint[] memory transactionIds = new uint[](pendingTransactions.length);
        for(uint i = 0; i < pendingTransactions.length; i++) {
            transactionIds[i] = pendingTransactions[i].id;
        }
        // Now remove all delayed transactions
        for(uint i = 0; i < transactionIds.length; i++) {
            cancelTransactionInternal(transactionIds[i]);
        }
    }

    function getFunctionDelay(
        address to,
        bytes4  functionSelector
        )
        public
        override
        view
        returns (uint)
    {
        uint pos = delayedFunctionMap[to][functionSelector];
        if (pos == 0) {
            return 0;
        } else {
            return delayedFunctions[pos - 1].delay;
        }
    }

    function getNumPendingTransactions()
        external
        override
        view
        returns (uint)
    {
        return pendingTransactions.length;
    }

    function getNumDelayedFunctions()
        external
        override
        view
        returns (uint)
    {
        return delayedFunctions.length;
    }

    // == Internal Functions ==

    function transactInternal(
        address to,
        uint    value,
        bytes   memory data
        )
        internal
    {
        Transaction memory transaction = Transaction(
            totalNumDelayedTransactions,
            block.timestamp,
            to,
            value,
            data
        );

        bytes4 functionSelector = transaction.data.toBytes4(0);
        uint delay = getFunctionDelay(transaction.to, functionSelector);
        if (delay == 0) {
            (bool success, bytes memory returnData) = exectuteTransaction(transaction);
            if (!success) {
                assembly { revert(add(returnData, 32), mload(returnData)) }
            }
            emit TransactionExecuted(
                transaction.timestamp,
                transaction.to,
                transaction.value,
                transaction.data
            );
        } else {
            pendingTransactions.push(transaction);
            pendingTransactionMap[transaction.id] = pendingTransactions.length;
            emit TransactionDelayed(
                transaction.id,
                transaction.timestamp,
                transaction.to,
                transaction.value,
                transaction.data,
                delay
            );
            totalNumDelayedTransactions++;
        }
    }

    function setFunctionDelay(
        address to,
        bytes4  functionSelector,
        uint    delay
        )
        internal
    {
        // Check if the function already has a delay
        uint pos = delayedFunctionMap[to][functionSelector];
        if (pos > 0) {
            if (delay > 0) {
                // Just update the delay
                delayedFunctions[pos - 1].delay = delay;
            } else {
                // Remove the delayed function
                uint size = delayedFunctions.length;
                if (pos != size) {
                    DelayedFunction memory lastOne = delayedFunctions[size - 1];
                    delayedFunctions[pos - 1] = lastOne;
                    delayedFunctionMap[lastOne.to][lastOne.functionSelector] = pos;
                }
                delayedFunctions.pop();
                delete delayedFunctionMap[to][functionSelector];
            }
        } else if (delay > 0) {
            // Add the new delayed function
            DelayedFunction memory delayedFunction = DelayedFunction(
                to,
                functionSelector,
                delay
            );
            delayedFunctions.push(delayedFunction);
            delayedFunctionMap[to][functionSelector] = delayedFunctions.length;
        }
    }

    function exectuteTransaction(
        Transaction memory transaction
        )
        internal
        returns (bool success, bytes memory returnData)
    {
        // solium-disable-next-line security/no-call-value
        (success, returnData) = transaction.to.call{value: transaction.value}(transaction.data);
    }

    function cancelTransactionInternal(
        uint transactionId
        )
        internal
    {
        Transaction memory transaction = getTransaction(transactionId);

        // Remove the transaction
        removeTransaction(transaction.id);

        emit TransactionCancelled(
            transaction.id,
            transaction.timestamp,
            transaction.to,
            transaction.value,
            transaction.data
        );

        // Return the transaction value (if there is any)
        uint value = transaction.value;
        if (value > 0) {
            msg.sender.sendETHAndVerify(value, gasleft());
        }
    }

    function getTransaction(
        uint transactionId
        )
        internal
        view
        returns (Transaction storage transaction)
    {
        uint pos = pendingTransactionMap[transactionId];
        require(pos != 0, "TRANSACTION_NOT_FOUND");
        transaction = pendingTransactions[pos - 1];
    }

    function removeTransaction(
        uint transactionId
        )
        internal
    {
        uint pos = pendingTransactionMap[transactionId];
        require(pos != 0, "TRANSACTION_NOT_FOUND");

        uint size = pendingTransactions.length;
        if (pos != size) {
            Transaction memory lastOne = pendingTransactions[size - 1];
            pendingTransactions[pos - 1] = lastOne;
            pendingTransactionMap[lastOne.id] = pos;
        }

        pendingTransactions.pop();
        delete pendingTransactionMap[transactionId];
    }

    function isAuthorizedForTransactions(address sender)
        internal
        virtual
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


/// @title IDelayedTransaction
/// @author Brecht Devos - <[email protected]>
abstract contract IDelayedTransaction
{
    event TransactionDelayed(
        uint    id,
        uint    timestamp,
        address to,
        uint    value,
        bytes   data,
        uint    delay
    );

    event TransactionCancelled(
        uint    id,
        uint    timestamp,
        address to,
        uint    value,
        bytes   data
    );

    event TransactionExecuted(
        uint    timestamp,
        address to,
        uint    value,
        bytes   data
    );

    event PendingTransactionExecuted(
        uint    id,
        uint    timestamp,
        address to,
        uint    value,
        bytes   data
    );

    struct Transaction
    {
        uint    id;
        uint    timestamp;
        address to;
        uint    value;
        bytes   data;
    }

    struct DelayedFunction
    {
        address to;
        bytes4  functionSelector;
        uint    delay;
    }

    // The maximum amount of time (in seconds) a pending transaction can be executed
    // (so the amount of time than can pass after the mandatory function specific delay).
    // If the transaction hasn't been executed before then it can be cancelled so it is removed
    // from the pending transaction list.
    uint public timeToLive;

    // Active list of delayed functions (delay > 0)
    DelayedFunction[] public delayedFunctions;

    // Active list of pending transactions
    Transaction[] public pendingTransactions;

    /// @dev Executes a pending transaction.
    /// @param to The contract address to call
    /// @param data The call data
    function transact(
        address to,
        bytes   calldata data
        )
        external
        virtual
        payable;

    /// @dev Executes a pending transaction.
    /// @param transactionId The id of the pending transaction.
    function executeTransaction(
        uint transactionId
        )
        external
        virtual;

    /// @dev Cancels a pending transaction.
    /// @param transactionId The id of the pending transaction.
    function cancelTransaction(
        uint transactionId
        )
        external
        virtual;

    /// @dev Cancels all pending transactions.
    function cancelAllTransactions()
        external
        virtual;

    /// @dev Gets the delay for the given function
    /// @param functionSelector The function selector.
    /// @return The delay of the function.
    function getFunctionDelay(
        address to,
        bytes4  functionSelector
        )
        public
        virtual
        view
        returns (uint);

    /// @dev Gets the number of pending transactions.
    /// @return The number of pending transactions.
    function getNumPendingTransactions()
        external
        virtual
        view
        returns (uint);

    /// @dev Gets the number of functions that have a delay.
    /// @return The number of delayed functions.
    function getNumDelayedFunctions()
        external
        virtual
        view
        returns (uint);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title LzDecompressor
/// @author Brecht Devos - <[email protected]>
/// @dev Decompresses data compressed with a LZ77/Snappy like compressor optimized for EVM
///      Currently supports 3 modes:
///      - Copy directly from calldata (needs length)
///      - Fill memory with zeros (needs length)
///      - Copy from previously decompressed memory (needs offset, length)
///      TODO:
///      - better packing of (mode, offset, length)
///      - add mode copying from random location in calldata (faster than memory copies)
///      - add support to copy data from memory using the identity pre-compile
///        (large initital cost but cheaper copying, does not support overlapping memory ranges)
library LzDecompressor
{
    function decompress(
        bytes calldata /*data*/
        )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory uncompressed;
        assembly {
            uncompressed := mload(0x40)
            let ptr := add(uncompressed, 32)
            let dataLength := calldataload(36)
            for { let pos := 0 } lt(pos, dataLength) {} {
                // Read the mode
                pos := add(pos, 1)
                let mode := and(calldataload(add(36, pos)), 0xFF)

                switch mode
                case 0 {
                    // Copy from calldata at the current position
                    pos := add(pos, 2)
                    let length := and(calldataload(add(36, pos)), 0xFFFF)

                    calldatacopy(ptr, add(68, pos), length)
                    pos := add(pos, length)

                    ptr := add(ptr, length)
                }
                case 1 {
                    // Write out zeros
                    pos := add(pos, 2)
                    let length := and(calldataload(add(36, pos)), 0xFFFF)

                    codecopy(ptr, codesize(), length)

                    ptr := add(ptr, length)
                }
                case 2 {
                    // Copy from previously decompressed bytes in memory
                    pos := add(pos, 2)
                    let offset := and(calldataload(add(36, pos)), 0xFFFF)
                    pos := add(pos, 2)
                    let length := and(calldataload(add(36, pos)), 0xFFFF)

                    let src := sub(ptr, offset)
                    let i := 0
                    if lt(offset, 32) {
                        // If the offset is less than 32 we can't begin copying 32 bytes at a time.
                        // We first do some copies to fix this
                        mstore(add(src, offset), mload(src))
                        mstore(add(src, mul(offset, 2)), mload(src))
                        mstore(add(src, mul(offset, 4)), mload(src))
                        mstore(add(src, mul(offset, 8)), mload(src))
                        mstore(add(src, mul(offset, 16)), mload(src))
                        mstore(add(src, mul(offset, 32)), mload(src))

                        // No matter the offset, the first 32 bytes can now be copied
                        // Fix the starting data so we can copy like normal afterwards
                        i := 32
                        src := add(sub(src, 32), mod(32, offset))
                    }
                    // This can copy too many bytes, but that's okay
                    // Needs unrolling for the best performance
                    for { } lt(i, length) { } {
                        mstore(add(ptr, i), mload(add(src, i)))
                        i := add(i, 32)
                        mstore(add(ptr, i), mload(add(src, i)))
                        i := add(i, 32)
                        mstore(add(ptr, i), mload(add(src, i)))
                        i := add(i, 32)
                        mstore(add(ptr, i), mload(add(src, i)))
                        i := add(i, 32)
                    }
                    ptr := add(ptr, length)
                }
                default {
                    revert(0, 0)
                }
            }
            // Store data length
            mstore(uncompressed, sub(sub(ptr, uncompressed), 32))

            // Update free memory pointer
            mstore(0x40, add(ptr, 0x20))
        }
        return uncompressed;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../../lib/AddressUtil.sol";
import "../../lib/BurnableERC20.sol";
import "../../lib/Claimable.sol";
import "../../lib/ERC20.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../token-sellers/ITokenSeller.sol";
import "./IProtocolFeeVault.sol";


/// @title An Implementation of IProtocolFeeVault.
/// @author Daniel Wang - <[email protected]>
contract ProtocolFeeVault is Claimable, ReentrancyGuard, IProtocolFeeVault
{
    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;

    address public immutable override lrcAddress;

    constructor(address _lrcAddress)
        Claimable()
    {
        require(_lrcAddress != address(0), "ZERO_ADDRESS");
        lrcAddress = _lrcAddress;
    }

    receive() external payable { }

    function updateSettings(
        address _userStakingPoolAddress,
        address _tokenSellerAddress,
        address _daoAddress
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        require(
            userStakingPoolAddress != _userStakingPoolAddress ||
            tokenSellerAddress != _tokenSellerAddress ||
            daoAddress != _daoAddress,
            "SAME_ADDRESSES"
        );
        userStakingPoolAddress = _userStakingPoolAddress;
        tokenSellerAddress = _tokenSellerAddress;
        daoAddress = _daoAddress;

        emit SettingsUpdated(block.timestamp);
    }

    function claimStakingReward(
        uint amount
        )
        external
        override
        nonReentrant
    {
        require(amount > 0, "ZERO_VALUE");
        require(msg.sender == userStakingPoolAddress, "UNAUTHORIZED");
        lrcAddress.safeTransferAndVerify(userStakingPoolAddress, amount);
        claimedReward = claimedReward.add(amount);
        emit LRCClaimed(amount);
    }

    function fundDAO()
        external
        override
        nonReentrant
    {
        uint amountDAO;
        uint amountBurn;
        (, , , , , amountBurn, amountDAO, ) = getProtocolFeeStats();

        address recipient = daoAddress == address(0) ? owner : daoAddress;

        if (amountDAO > 0) {
            lrcAddress.safeTransferAndVerify(recipient, amountDAO);
        }

        if (amountBurn > 0) {
            require(BurnableERC20(lrcAddress).burn(amountBurn), "BURN_FAILURE");
        }

        claimedBurn = claimedBurn.add(amountBurn);
        claimedDAOFund = claimedDAOFund.add(amountDAO);

        emit DAOFunded(amountDAO, amountBurn);
    }

    function sellTokenForLRC(
        address token,
        uint    amount
        )
        external
        override
        nonReentrant
    {
        require(amount > 0, "ZERO_AMOUNT");
        require(token != lrcAddress, "PROHIBITED");

        address recipient = tokenSellerAddress == address(0) ? owner : tokenSellerAddress;

        if (token == address(0)) {
            recipient.sendETHAndVerify(amount, gasleft());
        } else {
            token.safeTransferAndVerify(recipient, amount);
        }

        require(
            tokenSellerAddress == address(0) ||
            ITokenSeller(tokenSellerAddress).sellToken(token, lrcAddress),
            "SELL_FAILURE"
        );

        emit TokenSold(token, amount);
    }

    function getProtocolFeeStats()
        public
        override
        view
        returns (
            uint accumulatedFees,
            uint accumulatedBurn,
            uint accumulatedDAOFund,
            uint accumulatedReward,
            uint remainingFees,
            uint remainingBurn,
            uint remainingDAOFund,
            uint remainingReward
        )
    {
        remainingFees = ERC20(lrcAddress).balanceOf(address(this));
        accumulatedFees = remainingFees.add(claimedReward).add(claimedDAOFund).add(claimedBurn);

        accumulatedReward = accumulatedFees.mul(REWARD_PERCENTAGE) / 100;
        accumulatedDAOFund = accumulatedFees.mul(DAO_PERDENTAGE) / 100;
        accumulatedBurn = accumulatedFees.sub(accumulatedReward).sub(accumulatedDAOFund);

        remainingReward = accumulatedReward.sub(claimedReward);
        remainingDAOFund = accumulatedDAOFund.sub(claimedDAOFund);
        remainingBurn = accumulatedBurn.sub(claimedBurn);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title IProtocolFeeVault
/// @dev This smart contract manages the distribution of protocol fees.
///     Tokens other than LRC will be sold by TokenSeller,
///     If no TokenSeller is set, the tokens or Ether will be sent to the owner
///     to sell them for LRC by other means such as using a centralized exchange.
///     For LRC token, 70% of them can be withdrawn to the UserStakingPool contract
///     to reward LRC stakers; 20% of them can be withdrawn to the Loopring DAO,
///     and the remaining 10% can be burned to reduce LRC's total supply.
abstract contract IProtocolFeeVault
{
    uint public constant REWARD_PERCENTAGE      = 70;
    uint public constant DAO_PERDENTAGE         = 20;

    address public userStakingPoolAddress;
    address public tokenSellerAddress;
    address public daoAddress;

    uint claimedReward;
    uint claimedDAOFund;
    uint claimedBurn;

    event LRCClaimed(uint amount);
    event DAOFunded(uint amountDAO, uint amountBurn);
    event TokenSold(address token, uint amount);
    event SettingsUpdated(uint time);

    /// @dev Returns the LRC token address
    /// @return the LRC token address
    function lrcAddress()
        external
        view
        virtual
        returns (address);

    /// @dev Sets depending contract addresses. All these addresses can be zero.
    /// @param _userStakingPoolAddress The address of the user staking pool.
    /// @param _tokenSellerAddress The address of the token seller.
    /// @param _daoAddress The address of the DAO contract.
    function updateSettings(
        address _userStakingPoolAddress,
        address _tokenSellerAddress,
        address _daoAddress
        )
        external
        virtual;

    /// @dev Claims LRC as staking reward to the IUserStakingPool contract.
    ///      Note that this function can only be called by
    ///      the IUserStakingPool contract.
    ///
    /// @param amount The amount of LRC to be claimed.
    function claimStakingReward(uint amount)
        external
        virtual;

    /// @dev Withdraws LRC to DAO and in the meanwhile burn some LRC according to
    ///      the predefined percentages.
    function fundDAO()
        external
        virtual;

    /// @dev Sells a non-LRC token or Ether to LRC. If no TokenSeller is set,
    ///      the tokens or Ether will be sent to the owner.
    /// @param token The token or ether (0x0) to sell.
    /// @param amount THe amout of token/ether to sell.
    function sellTokenForLRC(
        address token,
        uint    amount
        )
        external
        virtual;

    /// @dev Returns some global stats regarding fees.
    /// @return accumulatedFees The accumulated amount of LRC protocol fees.
    /// @return accumulatedBurn The accumulated amount of LRC to burn.
    /// @return accumulatedDAOFund The accumulated amount of LRC as developer pool.
    /// @return accumulatedReward The accumulated amount of LRC as staking reward.
    /// @return remainingFees The remaining amount of LRC protocol fees.
    /// @return remainingBurn The remaining amount of LRC to burn.
    /// @return remainingDAOFund The remaining amount of LRC as developer pool.
    /// @return remainingReward The remaining amount of LRC as staking reward.
    function getProtocolFeeStats()
        external
        virtual
        view
        returns (
            uint accumulatedFees,
            uint accumulatedBurn,
            uint accumulatedDAOFund,
            uint accumulatedReward,
            uint remainingFees,
            uint remainingBurn,
            uint remainingDAOFund,
            uint remainingReward
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../aux/compression/LzDecompressor.sol";

contract LzDecompressorContract {
    function decompress(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory)
    {
        return LzDecompressor.decompress(data);
    }

    function benchmark(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory)
    {
        return LzDecompressor.decompress(data);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";
import "../../core/iface/IExchangeV3.sol";

/// @author Brecht Devos - <[email protected]>
contract TEST is DummyToken {
    using SafeMath for uint;

    // Test cases
    uint8 public constant TEST_NOTHING = 0;
    uint8 public constant TEST_REENTRANCY = 1;
    uint8 public constant TEST_REQUIRE_FAIL = 2;
    uint8 public constant TEST_RETURN_FALSE = 3;
    uint8 public constant TEST_NO_RETURN_VALUE = 4;
    uint8 public constant TEST_INVALID_RETURN_SIZE = 5;
    uint8 public constant TEST_EXPENSIVE_TRANSFER = 6;
    uint8 public constant TEST_DIFFERENT_TRANSFER_AMOUNT = 7;

    uint public testCase = TEST_NOTHING;

    address public exchangeAddress = address(0);

    bytes public reentrancyCalldata;

    uint[16] private dummyStorageVariables;

    constructor() DummyToken(
        "TEST_TEST",
        "TEST",
        18,
        2 ** 128
    )
    {
    }

    function transfer(
        address _to,
        uint _value
        )
        public
        override
        returns (bool)
    {
        if (testCase == TEST_DIFFERENT_TRANSFER_AMOUNT) {
            _value = _value.mul(99) / 100;
        }
        // require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[msg.sender], "INVALID_VALUE");
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return doTestCase();
    }

    function transferFrom(
        address _from,
        address _to,
        uint _value
        )
        public
        override
        returns (bool)
    {
        if (testCase == TEST_DIFFERENT_TRANSFER_AMOUNT) {
            _value = _value.mul(99) / 100;
        }
        // require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[_from], "INVALID_VALUE");
        require(_value <= allowed[_from][msg.sender], "INVALID_VALUE");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return doTestCase();
    }

    function doTestCase()
        internal
        returns (bool)
    {
        if (testCase == TEST_NOTHING) {
            return true;
        } else if (testCase == TEST_REENTRANCY) {
            // Call the exchange function without ever throwing
            (bool success, ) = exchangeAddress.call(reentrancyCalldata);
            success; // to disable unused local variable warning

            // Copy the 100 bytes containing the revert message
            bytes memory returnData = new bytes(100);
            assembly {
                if eq(returndatasize(), 100) {
                    returndatacopy(add(returnData, 32), 0, 100)
                }
            }

            // Revert reason should match REENTRANCY
            bytes memory reentryMessageData = abi.encodeWithSelector(
                bytes4(keccak256("Error(string)")),
                "REENTRANCY"
            );

            // Throw here when the results are as expected. This way we know the test was correctly executed.
            require(keccak256(reentryMessageData) != keccak256(returnData), "REVERT_MESSAGE_OK");
            return true;
        } else if (testCase == TEST_REQUIRE_FAIL) {
            require(false, "REQUIRE_FAILED");
            return true;
        } else if (testCase == TEST_RETURN_FALSE) {
            return false;
        } else if (testCase == TEST_NO_RETURN_VALUE) {
            assembly {
                return(0, 0)
            }
        } else if (testCase == TEST_INVALID_RETURN_SIZE) {
            assembly {
                return(0, 64)
            }
        } else if (testCase == TEST_EXPENSIVE_TRANSFER) {
            // Some expensive operation
            for (uint i = 0; i < 16; i++) {
                dummyStorageVariables[i] = block.number;
            }
        }
        return true;
    }

    function setTestCase(
        uint8 _testCase
        )
        external
    {
        testCase = _testCase;
    }

    function setExchangeAddress(
        address _exchangeAddress
        )
        external
    {
        exchangeAddress = _exchangeAddress;
    }

    function setCalldata(
        bytes calldata _reentrancyCalldata
        )
        external
    {
        reentrancyCalldata = _reentrancyCalldata;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./LRCToken.sol";


/// @author Kongliang Zhong - <[email protected]>
contract DummyToken is LRCToken {
    using SafeMath for uint;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8         _decimals,
        uint          _totalSupply
    ) LRCToken(
        _name,
        _symbol,
        _decimals,
        _totalSupply,
        msg.sender
        )
    {
    }

    function setBalance(
        address _target,
        uint _value
        )
        public
    {
        uint currBalance = balanceOf(_target);
        if (_value < currBalance) {
            totalSupply_ = totalSupply_.sub(currBalance.sub(_value));
        } else {
            totalSupply_ = totalSupply_.add(_value.sub(currBalance));
        }
        balances[_target] = _value;
    }

    function addBalance(
        address _target,
        uint _value
        )
        public
    {
        uint currBalance = balanceOf(_target);
        require(_value + currBalance >= currBalance, "INVALID_VALUE");
        totalSupply_ = totalSupply_.add(_value);
        balances[_target] = currBalance.add(_value);
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address who) public view virtual returns (uint);
    function transfer(address to, uint value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint;
    mapping(address => uint) balances;
    uint totalSupply_;
    /**
     * @dev total number of tokens in existence
     */
    function totalSupply() public view override virtual returns (uint) {
        return totalSupply_;
    }
    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint _value) public override virtual returns (bool) {
        // require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[msg.sender], "TRANSFER_INSUFFICIENT_BALANCE");
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    /**
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return balance An uint representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view override virtual returns (uint balance) {
        return balances[_owner];
    }
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint);
    function transferFrom(address from, address to, uint value) public virtual returns (bool);
    function approve(address spender, uint value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}
/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {
    using SafeMath for uint;
    mapping (address => mapping (address => uint)) internal allowed;
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint _value) public override virtual returns (bool) {
        // require(_to != address(0), "ZERO_ADDRESS");
        require(_value <= balances[_from], "TRANSFERFROM_INSUFFICIENT_BALANCE");
        require(_value <= allowed[_from][msg.sender], "TRANSFERFROM_INSUFFICIENT_ALLOWANCE");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) public override returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view override returns (uint) {
        return allowed[_owner][_spender];
    }
    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

contract LRCToken is StandardToken {
    using SafeMath for uint;

    string     public name = "New Loopring token on ethereum";
    string     public symbol = "LRC";
    uint8      public decimals = 18;

    event Burn(address indexed burner, uint value);

    function burn(uint _value) public returns (bool) {
        require(_value <= balances[msg.sender], "BURN_INSUFFICIENT_BALANCE");

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
        return true;
    }

    function burnFrom(address _owner, uint _value) public returns (bool) {
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_value <= balances[_owner], "BURNFROM_INSUFFICIENT_BALANCE");
        require(_value <= allowed[_owner][msg.sender], "BURNFROM_INSUFFICIENT_ALLOWANCE");

        balances[_owner] = balances[_owner].sub(_value);
        allowed[_owner][msg.sender] = allowed[_owner][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);

        emit Burn(_owner, _value);
        emit Transfer(_owner, address(0), _value);
        return true;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8         _decimals,
        uint          _totalSupply,
        address       _firstHolder
        )
    {
        require(_totalSupply > 0, "INVALID_VALUE");
        require(_firstHolder != address(0), "ZERO_ADDRESS");
        checkSymbolAndName(_symbol,_name);

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;

        balances[_firstHolder] = totalSupply_;
    }

    // Make sure symbol has 3-8 chars in [A-Za-z._] and name has up to 128 chars.
    function checkSymbolAndName(
        string memory _symbol,
        string memory _name
        )
        internal
        pure
    {
        bytes memory s = bytes(_symbol);
        require(s.length >= 3 && s.length <= 8, "INVALID_SIZE");
        for (uint i = 0; i < s.length; i++) {
            // make sure symbol contains only [A-Za-z._]
            require(
                s[i] == 0x2E || (
                s[i] == 0x5F) || (
                s[i] >= 0x41 && s[i] <= 0x5A) || (
                s[i] >= 0x61 && s[i] <= 0x7A), "INVALID_VALUE");
        }
        bytes memory n = bytes(_name);
        require(n.length >= s.length && n.length <= 128, "INVALID_SIZE");
        for (uint i = 0; i < n.length; i++) {
            require(n[i] >= 0x20 && n[i] <= 0x7E, "INVALID_VALUE");
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract REP is DummyToken {

    constructor() DummyToken(
        "REP_TEST",
        "REP",
        18,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract LRC is DummyToken {

    constructor() DummyToken(
        "LRC_TEST",
        "LRC",
        18,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract WETH is DummyToken {

    constructor() DummyToken(
        "WETH_TEST",
        "WETH",
        18,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract RDN is DummyToken {

    constructor() DummyToken(
        "RDN_TEST",
        "RDN",
        18,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract GTO is DummyToken {

    constructor() DummyToken(
        "GTO_TEST",
        "GTO",
        18,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract INDB is DummyToken {

    constructor() DummyToken(
        "INDIVISIBLE_B",
        "INDB",
        0,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../DummyToken.sol";

contract INDA is DummyToken {

    constructor() DummyToken(
        "INDIVISIBLE_A",
        "INDA",
        0,
        10 ** 27
    )
    {
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../core/iface/IExchangeV3.sol";

import "../lib/AddressUtil.sol";
import "../lib/MathUint.sol";


contract TestAccountContract {

    using AddressUtil       for address payable;
    using MathUint          for uint;

    IExchangeV3 exchange;

    uint[16] private dummyStorageVariables;

    modifier refund()
    {
        // Send surplus to msg.sender
        uint balanceBefore = address(this).balance.sub(msg.value);
        _;
        uint balanceAfter = address(this).balance;
        msg.sender.sendETHAndVerify(balanceAfter.sub(balanceBefore), gasleft());
    }

    constructor(
        address _exchangeAddress
        )
    {
        exchange = IExchangeV3(_exchangeAddress);
    }

    function withdraw(
        address token,
        uint96 amount,
        uint32 accountID
        )
        external
        payable
        refund
    {
        //exchange.withdraw{value: msg.value}(address(this), token, amount, accountID);
    }

    receive()
        external
        payable
    {
        // Some expensive operation
        for (uint i = 0; i < 16; i++) {
            dummyStorageVariables[i] = block.number;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../lib/Claimable.sol";


/// @title DelayedTargetContract
/// @author Brecht Devos - <[email protected]>
contract DelayedTargetContract is Claimable
{
    uint public constant MAGIC_VALUE = 0xFEDCBA987654321;
    uint public value = 7;

    function delayedFunctionPayable(
        uint _value
        )
        external
        payable
        returns (uint)
    {
        value = _value;
        return _value;
    }

    function delayedFunctionRevert(
        uint _value
        )
        external
    {
        require(false, "DELAYED_REVERT");
        value = _value;
    }

    function immediateFunctionPayable(
        uint _value
        )
        external
        payable
    {
        value = _value;
    }

    function immediateFunctionView()
        external
        pure
        returns (uint)
    {
        return MAGIC_VALUE;
    }

    function immediateFunctionRevert(
        uint _value
        )
        external
        payable
    {
        require(false, "IMMEDIATE_REVERT");
        value = _value;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import '../lib/ERC20.sol';
import '../lib/MathUint.sol';

contract LPERC20 is ERC20 {
    using MathUint for uint;

    string public constant name = 'Loopring AMM';
    string public constant symbol = 'LLT';
    uint8 public constant decimals = 18;
    uint  public _totalSupply;
    mapping(address => uint) public _balanceOf;
    mapping(address => mapping(address => uint)) public _allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function totalSupply() public virtual view override returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view override virtual returns (uint balance) {
        return _balanceOf[owner];
    }

    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowance[owner][spender];
    }

    function approve(address spender, uint value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public override returns (bool) {
        if (_allowance[from][msg.sender] != uint(-1)) {
            _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply.add(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _balanceOf[from] = _balanceOf[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _balanceOf[from] = _balanceOf[from].sub(value);
        _balanceOf[to] = _balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../aux/compression/ZeroDecompressor.sol";

contract ZeroDecompressorContract {
    function decompress(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory)
    {
        return ZeroDecompressor.decompress(data, 0);
    }

    function benchmark(
        bytes calldata data
        )
        external
        pure
        returns (bytes memory)
    {
        return ZeroDecompressor.decompress(data, 0);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../lib/AddressUtil.sol";
import "../lib/ERC20SafeTransfer.sol";


contract TransferContract {

    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using ERC20SafeTransfer for address;

    uint8 public constant TEST_NOTHING = 0;
    uint8 public constant TEST_REQUIRE_FAIL = 1;
    uint8 public constant TEST_EXPENSIVE_TRANSFER = 2;

    uint public testCase = TEST_NOTHING;

    uint[16] private dummyStorageVariables;

    function safeTransferWithGasLimit(
        address token,
        address to,
        uint    value,
        uint    gasLimit
        )
        external
    {
        token.safeTransferWithGasLimitAndVerify(to, value, gasLimit);
    }

    function safeTransferFromWithGasLimit(
        address token,
        address from,
        address to,
        uint    value,
        uint    gasLimit
        )
        external
    {
        token.safeTransferFromWithGasLimitAndVerify(from, to, value, gasLimit);
    }

    function sendETH(
        address to,
        uint    amount,
        uint    gasLimit
        )
        external
    {
        to.sendETHAndVerify(amount, gasLimit);
    }

    function setTestCase(
        uint8 _testCase
        )
        external
    {
        testCase = _testCase;
    }

    receive()
        external
        payable
    {
        if (testCase == TEST_NOTHING) {
            return;
        } else if (testCase == TEST_REQUIRE_FAIL) {
            revert("ETH_FAILURE");
        } else if (testCase == TEST_EXPENSIVE_TRANSFER) {
            // Some expensive operation
            for (uint i = 0; i < 16; i++) {
                dummyStorageVariables[i] = block.number;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "../aux/access/DelayedOwner.sol";
import "./DelayedTargetContract.sol";


/// @title DelayedOwnerContract
/// @author Brecht Devos - <[email protected]>
contract DelayedOwnerContract is DelayedOwner
{
    constructor(
        address delayedTargetAddress,
        bool setDefaultFunctionDelays
        )
        DelayedOwner(delayedTargetAddress, 3 days)
    {
        if (setDefaultFunctionDelays) {
            DelayedTargetContract delayedTarget = DelayedTargetContract(delayedTargetAddress);
            setFunctionDelay(delayedTarget.delayedFunctionPayable.selector, 1 days);
            setFunctionDelay(delayedTarget.delayedFunctionRevert.selector, 2 days);
            setFunctionDelay(delayedTarget.transferOwnership.selector, 3 days);
        }
    }

    function setFunctionDelayExternal(
        address to,
        bytes4  functionSelector,
        uint    delay
        )
        external
    {
        setFunctionDelay(to, functionSelector, delay);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../lib/Poseidon.sol";
import "../core/iface/ExchangeData.sol";


contract PoseidonContract {
    function hash_t5f6p52(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4
        )
        external
        pure
        returns (uint)
    {
        Poseidon.HashInputs5 memory inputs = Poseidon.HashInputs5(t0, t1, t2, t3, t4);
        return Poseidon.hash_t5f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
    }

    function hash_t6f6p52(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4,
        uint t5
        )
        external
        pure
        returns (uint)
    {
        Poseidon.HashInputs6 memory inputs = Poseidon.HashInputs6(t0, t1, t2, t3, t4, t5);
        return Poseidon.hash_t6f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

contract Migrations
{
    address public owner;
    uint public last_completed_migration;

    modifier restricted()
    {
        if (msg.sender == owner) {
            _;
        }
    }

    constructor()
    {
        owner = msg.sender;
    }

    function setCompleted(uint completed)
        public
        restricted
    {
        last_completed_migration = completed;
    }

    function upgrade(address newAddress)
        public
        restricted
    {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(last_completed_migration);
    }
}

// SPDX-License-Identifier: UNLICENSED
/// Borrowed from https://github.com/gnosis/mock-contract
pragma solidity ^0.7.0;

interface MockInterface {
	/**
	 * @dev After calling this method, the mock will return `response` when it is called
	 * with any calldata that is not mocked more specifically below
	 * (e.g. using givenMethodReturn).
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenAnyReturn(bytes calldata response) external;
	function givenAnyReturnBool(bool response) external;
	function givenAnyReturnUint(uint response) external;
	function givenAnyReturnAddress(address response) external;

	function givenAnyRevert() external;
	function givenAnyRevertWithMessage(string calldata message) external;
	function givenAnyRunOutOfGas() external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called regardless of arguments. If the methodId and arguments
	 * are mocked more specifically (using `givenMethodAndArguments`) the latter
	 * will take precedence.
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 * @param response ABI encoded response that will be returned if method is invoked
	 */
	function givenMethodReturn(bytes calldata method, bytes calldata response) external;
	function givenMethodReturnBool(bytes calldata method, bool response) external;
	function givenMethodReturnUint(bytes calldata method, uint response) external;
	function givenMethodReturnAddress(bytes calldata method, address response) external;

	function givenMethodRevert(bytes calldata method) external;
	function givenMethodRevertWithMessage(bytes calldata method, string calldata message) external;
	function givenMethodRunOutOfGas(bytes calldata method) external;

	/**
	 * @dev After calling this method, the mock will return `response` when the given
	 * methodId is called with matching arguments. These exact calldataMocks will take
	 * precedence over all other calldataMocks.
	 * @param call ABI encoded calldata (methodId and arguments)
	 * @param response ABI encoded response that will be returned if contract is invoked with calldata
	 */
	function givenCalldataReturn(bytes calldata call, bytes calldata response) external;
	function givenCalldataReturnBool(bytes calldata call, bool response) external;
	function givenCalldataReturnUint(bytes calldata call, uint response) external;
	function givenCalldataReturnAddress(bytes calldata call, address response) external;

	function givenCalldataRevert(bytes calldata call) external;
	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external;
	function givenCalldataRunOutOfGas(bytes calldata call) external;

	/**
	 * @dev Returns the number of times anything has been called on this mock since last reset
	 */
	function invocationCount() external returns (uint);

	/**
	 * @dev Returns the number of times the given method has been called on this mock since last reset
	 * @param method ABI encoded methodId. It is valid to pass full calldata (including arguments). The mock will extract the methodId from it
	 */
	function invocationCountForMethod(bytes calldata method) external returns (uint);

	/**
	 * @dev Returns the number of times this mock has been called with the exact calldata since last reset.
	 * @param call ABI encoded calldata (methodId and arguments)
	 */
	function invocationCountForCalldata(bytes calldata call) external returns (uint);

	/**
	 * @dev Resets all mocked methods and invocation counts.
	 */
	 function reset() external;
}

/**
 * Implementation of the MockInterface.
 */
contract MockContract is MockInterface {
	enum MockType { Return, Revert, OutOfGas }

	bytes32 public constant MOCKS_LIST_START = hex"01";
	bytes public constant MOCKS_LIST_END = "0xff";
	bytes32 public constant MOCKS_LIST_END_HASH = keccak256(MOCKS_LIST_END);
	bytes4 public constant SENTINEL_ANY_MOCKS = hex"01";

	// A linked list allows easy iteration and inclusion checks
	mapping(bytes32 => bytes) calldataMocks;
	mapping(bytes => MockType) calldataMockTypes;
	mapping(bytes => bytes) calldataExpectations;
	mapping(bytes => string) calldataRevertMessage;
	mapping(bytes32 => uint) calldataInvocations;

	mapping(bytes4 => bytes4) methodIdMocks;
	mapping(bytes4 => MockType) methodIdMockTypes;
	mapping(bytes4 => bytes) methodIdExpectations;
	mapping(bytes4 => string) methodIdRevertMessages;
	mapping(bytes32 => uint) methodIdInvocations;

	MockType fallbackMockType;
	bytes fallbackExpectation;
	string fallbackRevertMessage;
	uint invocations;
	uint resetCount;

	constructor() {
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;
	}

	function trackCalldataMock(bytes memory call) private {
		bytes32 callHash = keccak256(call);
		if (calldataMocks[callHash].length == 0) {
			calldataMocks[callHash] = calldataMocks[MOCKS_LIST_START];
			calldataMocks[MOCKS_LIST_START] = call;
		}
	}

	function trackMethodIdMock(bytes4 methodId) private {
		if (methodIdMocks[methodId] == 0x0) {
			methodIdMocks[methodId] = methodIdMocks[SENTINEL_ANY_MOCKS];
			methodIdMocks[SENTINEL_ANY_MOCKS] = methodId;
		}
	}

	function _givenAnyReturn(bytes memory response) internal {
		fallbackMockType = MockType.Return;
		fallbackExpectation = response;
	}

	function givenAnyReturn(bytes calldata response) external override {
		_givenAnyReturn(response);
	}

	function givenAnyReturnBool(bool response) external override {
		uint flag = response ? 1 : 0;
		_givenAnyReturn(uintToBytes(flag));
	}

	function givenAnyReturnUint(uint response) external override {
		_givenAnyReturn(uintToBytes(response));
	}

	function givenAnyReturnAddress(address response) external override {
		_givenAnyReturn(uintToBytes(uint(response)));
	}

	function givenAnyRevert() external override {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = "";
	}

	function givenAnyRevertWithMessage(string calldata message) external override {
		fallbackMockType = MockType.Revert;
		fallbackRevertMessage = message;
	}

	function givenAnyRunOutOfGas() external override {
		fallbackMockType = MockType.OutOfGas;
	}

	function _givenCalldataReturn(bytes memory call, bytes memory response) private  {
		calldataMockTypes[call] = MockType.Return;
		calldataExpectations[call] = response;
		trackCalldataMock(call);
	}

	function givenCalldataReturn(bytes calldata call, bytes calldata response) external override {
		_givenCalldataReturn(call, response);
	}

	function givenCalldataReturnBool(bytes calldata call, bool response) external override {
		uint flag = response ? 1 : 0;
		_givenCalldataReturn(call, uintToBytes(flag));
	}

	function givenCalldataReturnUint(bytes calldata call, uint response) external override {
		_givenCalldataReturn(call, uintToBytes(response));
	}

	function givenCalldataReturnAddress(bytes calldata call, address response) external override {
		_givenCalldataReturn(call, uintToBytes(uint(response)));
	}

	function _givenMethodReturn(bytes memory call, bytes memory response) private {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Return;
		methodIdExpectations[method] = response;
		trackMethodIdMock(method);
	}

	function givenMethodReturn(bytes calldata call, bytes calldata response) external override {
		_givenMethodReturn(call, response);
	}

	function givenMethodReturnBool(bytes calldata call, bool response) external override {
		uint flag = response ? 1 : 0;
		_givenMethodReturn(call, uintToBytes(flag));
	}

	function givenMethodReturnUint(bytes calldata call, uint response) external override {
		_givenMethodReturn(call, uintToBytes(response));
	}

	function givenMethodReturnAddress(bytes calldata call, address response) external override {
		_givenMethodReturn(call, uintToBytes(uint(response)));
	}

	function givenCalldataRevert(bytes calldata call) external override {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = "";
		trackCalldataMock(call);
	}

	function givenMethodRevert(bytes calldata call) external override {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		trackMethodIdMock(method);
	}

	function givenCalldataRevertWithMessage(bytes calldata call, string calldata message) external override {
		calldataMockTypes[call] = MockType.Revert;
		calldataRevertMessage[call] = message;
		trackCalldataMock(call);
	}

	function givenMethodRevertWithMessage(bytes calldata call, string calldata message) external override {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.Revert;
		methodIdRevertMessages[method] = message;
		trackMethodIdMock(method);
	}

	function givenCalldataRunOutOfGas(bytes calldata call) external override {
		calldataMockTypes[call] = MockType.OutOfGas;
		trackCalldataMock(call);
	}

	function givenMethodRunOutOfGas(bytes calldata call) external override {
		bytes4 method = bytesToBytes4(call);
		methodIdMockTypes[method] = MockType.OutOfGas;
		trackMethodIdMock(method);
	}

	function invocationCount() external override view returns (uint) {
		return invocations;
	}

	function invocationCountForMethod(bytes calldata call) external view override returns (uint) {
		bytes4 method = bytesToBytes4(call);
		return methodIdInvocations[keccak256(abi.encodePacked(resetCount, method))];
	}

	function invocationCountForCalldata(bytes calldata call) external view override returns (uint) {
		return calldataInvocations[keccak256(abi.encodePacked(resetCount, call))];
	}

	function reset() external override {
		// Reset all exact calldataMocks
		bytes memory nextMock = calldataMocks[MOCKS_LIST_START];
		bytes32 mockHash = keccak256(nextMock);
		// We cannot compary bytes
		while(mockHash != MOCKS_LIST_END_HASH) {
			// Reset all mock maps
			calldataMockTypes[nextMock] = MockType.Return;
			calldataExpectations[nextMock] = hex"";
			calldataRevertMessage[nextMock] = "";
			// Set next mock to remove
			nextMock = calldataMocks[mockHash];
			// Remove from linked list
			calldataMocks[mockHash] = "";
			// Update mock hash
			mockHash = keccak256(nextMock);
		}
		// Clear list
		calldataMocks[MOCKS_LIST_START] = MOCKS_LIST_END;

		// Reset all any calldataMocks
		bytes4 nextAnyMock = methodIdMocks[SENTINEL_ANY_MOCKS];
		while(nextAnyMock != SENTINEL_ANY_MOCKS) {
			bytes4 currentAnyMock = nextAnyMock;
			methodIdMockTypes[currentAnyMock] = MockType.Return;
			methodIdExpectations[currentAnyMock] = hex"";
			methodIdRevertMessages[currentAnyMock] = "";
			nextAnyMock = methodIdMocks[currentAnyMock];
			// Remove from linked list
			methodIdMocks[currentAnyMock] = 0x0;
		}
		// Clear list
		methodIdMocks[SENTINEL_ANY_MOCKS] = SENTINEL_ANY_MOCKS;

		fallbackExpectation = "";
		fallbackMockType = MockType.Return;
		invocations = 0;
		resetCount += 1;
	}

	function useAllGas() private {
		while(true) {
			bool s;
			assembly {
				//expensive call to EC multiply contract
				s := call(sub(gas(), 2000), 6, 0, 0x0, 0xc0, 0x0, 0x60)
			}
		}
	}

	function bytesToBytes4(bytes memory b) private pure returns (bytes4) {
		bytes4 out;
		for (uint i = 0; i < 4; i++) {
			out |= bytes4(b[i] & 0xFF) >> (i * 8);
		}
		return out;
	}

	function uintToBytes(uint256 x) private pure returns (bytes memory b) {
		b = new bytes(32);
		assembly { mstore(add(b, 32), x) }
	}

	function updateInvocationCount(bytes4 methodId, bytes memory originalMsgData) public {
		require(msg.sender == address(this), "Can only be called from the contract itself");
		invocations += 1;
		methodIdInvocations[keccak256(abi.encodePacked(resetCount, methodId))] += 1;
		calldataInvocations[keccak256(abi.encodePacked(resetCount, originalMsgData))] += 1;
	}

	receive()
        external
        payable
    {
        // Don't do anything
    }

	fallback() payable external {
		bytes4 methodId;
		assembly {
			methodId := calldataload(0)
		}

		// First, check exact matching overrides
		if (calldataMockTypes[msg.data] == MockType.Revert) {
			revert(calldataRevertMessage[msg.data]);
		}
		if (calldataMockTypes[msg.data] == MockType.OutOfGas) {
			useAllGas();
		}
		bytes memory result = calldataExpectations[msg.data];

		// Then check method Id overrides
		if (result.length == 0) {
			if (methodIdMockTypes[methodId] == MockType.Revert) {
				revert(methodIdRevertMessages[methodId]);
			}
			if (methodIdMockTypes[methodId] == MockType.OutOfGas) {
				useAllGas();
			}
			result = methodIdExpectations[methodId];
		}

		// Last, use the fallback override
		if (result.length == 0) {
			if (fallbackMockType == MockType.Revert) {
				revert(fallbackRevertMessage);
			}
			if (fallbackMockType == MockType.OutOfGas) {
				useAllGas();
			}
			result = fallbackExpectation;
		}

		// Record invocation as separate call so we don't rollback in case we are called with STATICCALL
		(, bytes memory r) = address(this).call{gas: 100000}(abi.encodeWithSignature("updateInvocationCount(bytes4,bytes)", methodId, msg.data));
		assert(r.length == 0);

		assembly {
			return(add(0x20, result), mload(result))
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/OpenZeppelin/openzeppelin-labs
// with minor modifications.
pragma solidity ^0.7.0;

import './Proxy.sol';


/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev This event will be emitted every time the implementation gets upgraded
   * @param implementation representing the address of the upgraded implementation
   */
  event Upgraded(address indexed implementation);

  // Storage position of the address of the current implementation
  bytes32 private constant implementationPosition = keccak256("org.zeppelinos.proxy.implementation");

  /**
   * @dev Constructor function
   */
  constructor() {}

  /**
   * @dev Tells the address of the current implementation
   * @return impl address of the current implementation
   */
  function implementation() public view override returns (address impl) {
    bytes32 position = implementationPosition;
    assembly {
      impl := sload(position)
    }
  }

  /**
   * @dev Sets the address of the current implementation
   * @param newImplementation address representing the new implementation to be set
   */
  function setImplementation(address newImplementation) internal {
    bytes32 position = implementationPosition;
    assembly {
      sstore(position, newImplementation)
    }
  }

  /**
   * @dev Upgrades the implementation address
   * @param newImplementation representing the address of the new implementation to be set
   */
  function _upgradeTo(address newImplementation) internal {
    address currentImplementation = implementation();
    require(currentImplementation != newImplementation);
    setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/OpenZeppelin/openzeppelin-labs
// with minor modifications.
pragma solidity ^0.7.0;

import './UpgradabilityProxy.sol';


/**
 * @title OwnedUpgradabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradabilityProxy is UpgradeabilityProxy {
  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event ProxyOwnershipTransferred(address previousOwner, address newOwner);

  // Storage position of the owner of the contract
  bytes32 private constant proxyOwnerPosition = keccak256("org.zeppelinos.proxy.owner");

  /**
  * @dev the constructor sets the original owner of the contract to the sender account.
  */
  constructor() {
    setUpgradabilityOwner(msg.sender);
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyProxyOwner() {
    require(msg.sender == proxyOwner());
    _;
  }

  /**
   * @dev Tells the address of the owner
   * @return owner the address of the owner
   */
  function proxyOwner() public view returns (address owner) {
    bytes32 position = proxyOwnerPosition;
    assembly {
      owner := sload(position)
    }
  }

  /**
   * @dev Sets the address of the owner
   */
  function setUpgradabilityOwner(address newProxyOwner) internal {
    bytes32 position = proxyOwnerPosition;
    assembly {
      sstore(position, newProxyOwner)
    }
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferProxyOwnership(address newOwner) public onlyProxyOwner {
    require(newOwner != address(0));
    emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
    setUpgradabilityOwner(newOwner);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy.
   * @param implementation representing the address of the new implementation to be set.
   */
  function upgradeTo(address implementation) public onlyProxyOwner {
    _upgradeTo(implementation);
  }

  /**
   * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
   * to initialize whatever is needed through a low level call.
   * @param implementation representing the address of the new implementation to be set.
   * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
   * signature of the implementation to be called with the needed payload
   */
  function upgradeToAndCall(address implementation, bytes memory data) payable public onlyProxyOwner {
    upgradeTo(implementation);
    (bool success, ) = address(this).call{value: msg.value}(data);
    require(success);
  }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/HarryR/ethsnarks/blob/master/contracts/Verifier.sol
// this code is taken from https://github.com/JacobEberhardt/ZoKrates
pragma solidity ^0.7.0;

library Verifier
{
    function ScalarField ()
        internal
        pure
        returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }


    /*
    * This implements the Solidity equivalent of the following Python code:

        from py_ecc.bn128 import *

        data = # ... arguments to function [in_vk, vk_gammaABC, in_proof, proof_inputs]

        vk = [int(_, 16) for _ in data[0]]
        ic = [FQ(int(_, 16)) for _ in data[1]]
        proof = [int(_, 16) for _ in data[2]]
        inputs = [int(_, 16) for _ in data[3]]

        it = iter(ic)
        ic = [(_, next(it)) for _ in it]
        vk_alpha = [FQ(_) for _ in vk[:2]]
        vk_beta = (FQ2(vk[2:4][::-1]), FQ2(vk[4:6][::-1]))
        vk_gamma = (FQ2(vk[6:8][::-1]), FQ2(vk[8:10][::-1]))
        vk_delta = (FQ2(vk[10:12][::-1]), FQ2(vk[12:14][::-1]))

        assert is_on_curve(vk_alpha, b)
        assert is_on_curve(vk_beta, b2)
        assert is_on_curve(vk_gamma, b2)
        assert is_on_curve(vk_delta, b2)

        proof_A = [FQ(_) for _ in proof[:2]]
        proof_B = (FQ2(proof[2:4][::-1]), FQ2(proof[4:-2][::-1]))
        proof_C = [FQ(_) for _ in proof[-2:]]

        assert is_on_curve(proof_A, b)
        assert is_on_curve(proof_B, b2)
        assert is_on_curve(proof_C, b)

        vk_x = ic[0]
        for i, s in enumerate(inputs):
            vk_x = add(vk_x, multiply(ic[i + 1], s))

        check_1 = pairing(proof_B, proof_A)
        check_2 = pairing(vk_beta, neg(vk_alpha))
        check_3 = pairing(vk_gamma, neg(vk_x))
        check_4 = pairing(vk_delta, neg(proof_C))

        ok = check_1 * check_2 * check_3 * check_4
        assert ok == FQ12.one()
    */
    function Verify(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory in_proof,
        uint256[] memory proof_inputs
        )
        internal
        view
        returns (bool)
    {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length, "INVALID_VALUE");

        // Compute the linear combination vk_x
        uint256[3] memory mul_input;
        uint256[4] memory add_input;
        bool success;
        uint m = 2;

        // First two fields are used as the sum
        add_input[0] = vk_gammaABC[0];
        add_input[1] = vk_gammaABC[1];

        // Performs a sum of gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]
        for (uint i = 0; i < proof_inputs.length; i++) {
            require(proof_inputs[i] < snark_scalar_field, "INVALID_INPUT");
            mul_input[0] = vk_gammaABC[m++];
            mul_input[1] = vk_gammaABC[m++];
            mul_input[2] = proof_inputs[i];

            assembly {
                // ECMUL, output to last 2 elements of `add_input`
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
            }
            if (!success) {
                return false;
            }

            assembly {
                // ECADD
                success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
            }
            if (!success) {
                return false;
            }
        }

        uint[24] memory input = [
            // (proof.A, proof.B)
            in_proof[0], in_proof[1],                           // proof.A   (G1)
            in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)

            // (-vk.alpha, vk.beta)
            in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
            in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)

            // (-vk_x, vk.gamma)
            add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
            in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)

            // (-proof.C, vk.delta)
            in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
            in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
        ];

        uint[1] memory out;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
        }
        return success && out[0] != 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/matter-labs/Groth16BatchVerifier/blob/master/BatchedSnarkVerifier/contracts/BatchVerifier.sol
// Thanks Harry from ETHSNARKS for base code
pragma solidity ^0.7.0;

library BatchVerifier {
    function GroupOrder ()
        public pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }

    function getProofEntropy(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint proofNumber
    )
        internal pure returns (uint256)
    {
        // Truncate the least significant 3 bits from the 256bit entropy so it fits the scalar field
        return uint(
            keccak256(
                abi.encodePacked(
                    in_proof[proofNumber*8 + 0], in_proof[proofNumber*8 + 1], in_proof[proofNumber*8 + 2], in_proof[proofNumber*8 + 3],
                    in_proof[proofNumber*8 + 4], in_proof[proofNumber*8 + 5], in_proof[proofNumber*8 + 6], in_proof[proofNumber*8 + 7],
                    proof_inputs[proofNumber]
                )
            )
        ) >> 3;
    }

    function accumulate(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs, // public inputs, length is num_inputs * num_proofs
        uint256 num_proofs
    ) internal view returns (
        bool success,
        uint256[] memory proofsAandC,
        uint256[] memory inputAccumulators
    ) {
        uint256 q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 numPublicInputs = proof_inputs.length / num_proofs;
        uint256[] memory entropy = new uint256[](num_proofs);
        inputAccumulators = new uint256[](numPublicInputs + 1);

        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            if (proofNumber == 0) {
                entropy[proofNumber] = 1;
            } else {
                // entropy[proofNumber] = uint(blockhash(block.number - proofNumber)) % q;
                // Safer entropy:
                entropy[proofNumber] = getProofEntropy(in_proof, proof_inputs, proofNumber);
            }
            require(entropy[proofNumber] != 0, "Entropy should not be zero");
            // here multiplication by 1 is implied
            inputAccumulators[0] = addmod(inputAccumulators[0], entropy[proofNumber], q);
            for (uint256 i = 0; i < numPublicInputs; i++) {
                require(proof_inputs[proofNumber * numPublicInputs + i] < q, "INVALID_INPUT");
                // accumulate the exponent with extra entropy mod q
                inputAccumulators[i+1] = addmod(inputAccumulators[i+1], mulmod(entropy[proofNumber], proof_inputs[proofNumber * numPublicInputs + i], q), q);
            }
            // coefficient for +vk.alpha (mind +) is the same as inputAccumulator[0]
        }

        // inputs for scalar multiplication
        uint256[3] memory mul_input;

        // use scalar multiplications to get proof.A[i] * entropy[i]

        proofsAandC = new uint256[](num_proofs*2 + 2);

        proofsAandC[0] = in_proof[0];
        proofsAandC[1] = in_proof[1];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            require(entropy[proofNumber] < q, "INVALID_INPUT");
            mul_input[0] = in_proof[proofNumber*8];
            mul_input[1] = in_proof[proofNumber*8 + 1];
            mul_input[2] = entropy[proofNumber];
            assembly {
                // ECMUL, output proofsA[i]
                // success := staticcall(sub(gas, 2000), 7, mul_input, 0x60, add(add(proofsAandC, 0x20), mul(proofNumber, 0x40)), 0x40)
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, mul_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
            proofsAandC[proofNumber*2] = mul_input[0];
            proofsAandC[proofNumber*2 + 1] = mul_input[1];
        }

        // use scalar multiplication and addition to get sum(proof.C[i] * entropy[i])

        uint256[4] memory add_input;

        add_input[0] = in_proof[6];
        add_input[1] = in_proof[7];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            mul_input[0] = in_proof[proofNumber*8 + 6];
            mul_input[1] = in_proof[proofNumber*8 + 7];
            mul_input[2] = entropy[proofNumber];
            assembly {
                // ECMUL, output proofsA
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }

            assembly {
                // ECADD from two elements that are in add_input and output into first two elements of add_input
                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
        }

        proofsAandC[num_proofs*2] = add_input[0];
        proofsAandC[num_proofs*2 + 1] = add_input[1];
    }

    function prepareBatches(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory inputAccumulators
    ) internal view returns (
        bool success,
        uint256[4] memory finalVksAlphaX
    ) {
        // Compute the linear combination vk_x using accumulator
        // First two fields are used as the sum and are initially zero
        uint256[4] memory add_input;
        uint256[3] memory mul_input;

        // Performs a sum(gammaABC[i] * inputAccumulator[i])
        for (uint256 i = 0; i < inputAccumulators.length; i++) {
            mul_input[0] = vk_gammaABC[2*i];
            mul_input[1] = vk_gammaABC[2*i + 1];
            mul_input[2] = inputAccumulators[i];

            assembly {
                // ECMUL, output to the last 2 elements of `add_input`
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }

            assembly {
                // ECADD from four elements that are in add_input and output into first two elements of add_input
                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }
        }

        finalVksAlphaX[2] = add_input[0];
        finalVksAlphaX[3] = add_input[1];

        // add one extra memory slot for scalar for multiplication usage
        uint256[3] memory finalVKalpha;
        finalVKalpha[0] = in_vk[0];
        finalVKalpha[1] = in_vk[1];
        finalVKalpha[2] = inputAccumulators[0];

        assembly {
            // ECMUL, output to first 2 elements of finalVKalpha
            success := staticcall(sub(gas(), 2000), 7, finalVKalpha, 0x60, finalVKalpha, 0x40)
        }
        if (!success) {
            return (false, finalVksAlphaX);
        }

        finalVksAlphaX[0] = finalVKalpha[0];
        finalVksAlphaX[1] = finalVKalpha[1];
    }

    // original equation
    // e(proof.A, proof.B)*e(-vk.alpha, vk.beta)*e(-vk_x, vk.gamma)*e(-proof.C, vk.delta) == 1
    // accumulation of inputs
    // gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]

    function BatchVerify (
        uint256[14] memory in_vk, // verifying key is always constant number of elements
        uint256[4] memory vk_gammaABC, // variable length, depends on number of inputs
        uint256[] memory in_proof, // proof itself, length is 8 * num_proofs
        uint256[] memory proof_inputs, // public inputs, length is num_inputs * num_proofs
        uint256 num_proofs
    )
    internal
    view
    returns (bool success)
    {
        require(in_proof.length == num_proofs * 8, "Invalid proofs length for a batch");
        require(proof_inputs.length % num_proofs == 0, "Invalid inputs length for a batch");
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length / num_proofs, "Invalid verification key");

        // strategy is to accumulate entropy separately for some proof elements
        // (accumulate only for G1, can't in G2) of the pairing equation, as well as input verification key,
        // postpone scalar multiplication as much as possible and check only one equation
        // by using 3 + num_proofs pairings only plus 2*num_proofs + (num_inputs+1) + 1 scalar multiplications compared to naive
        // 4*num_proofs pairings and num_proofs*(num_inputs+1) scalar multiplications

        bool valid;
        uint256[] memory proofsAandC;
        uint256[] memory inputAccumulators;
        (valid, proofsAandC, inputAccumulators) = accumulate(in_proof, proof_inputs, num_proofs);
        if (!valid) {
            return false;
        }

        uint256[4] memory finalVksAlphaX;
        (valid, finalVksAlphaX) = prepareBatches(in_vk, vk_gammaABC, inputAccumulators);
        if (!valid) {
            return false;
        }

        uint256[] memory inputs = new uint256[](6*num_proofs + 18);
        // first num_proofs pairings e(ProofA, ProofB)
        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            inputs[proofNumber*6] = proofsAandC[proofNumber*2];
            inputs[proofNumber*6 + 1] = proofsAandC[proofNumber*2 + 1];
            inputs[proofNumber*6 + 2] = in_proof[proofNumber*8 + 2];
            inputs[proofNumber*6 + 3] = in_proof[proofNumber*8 + 3];
            inputs[proofNumber*6 + 4] = in_proof[proofNumber*8 + 4];
            inputs[proofNumber*6 + 5] = in_proof[proofNumber*8 + 5];
        }

        // second pairing e(-finalVKaplha, vk.beta)
        inputs[num_proofs*6] = finalVksAlphaX[0];
        inputs[num_proofs*6 + 1] = NegateY(finalVksAlphaX[1]);
        inputs[num_proofs*6 + 2] = in_vk[2];
        inputs[num_proofs*6 + 3] = in_vk[3];
        inputs[num_proofs*6 + 4] = in_vk[4];
        inputs[num_proofs*6 + 5] = in_vk[5];

        // third pairing e(-finalVKx, vk.gamma)
        inputs[num_proofs*6 + 6] = finalVksAlphaX[2];
        inputs[num_proofs*6 + 7] = NegateY(finalVksAlphaX[3]);
        inputs[num_proofs*6 + 8] = in_vk[6];
        inputs[num_proofs*6 + 9] = in_vk[7];
        inputs[num_proofs*6 + 10] = in_vk[8];
        inputs[num_proofs*6 + 11] = in_vk[9];

        // fourth pairing e(-proof.C, finalVKdelta)
        inputs[num_proofs*6 + 12] = proofsAandC[num_proofs*2];
        inputs[num_proofs*6 + 13] = NegateY(proofsAandC[num_proofs*2 + 1]);
        inputs[num_proofs*6 + 14] = in_vk[10];
        inputs[num_proofs*6 + 15] = in_vk[11];
        inputs[num_proofs*6 + 16] = in_vk[12];
        inputs[num_proofs*6 + 17] = in_vk[13];

        uint256 inputsLength = inputs.length * 32;
        uint[1] memory out;
        require(inputsLength % 192 == 0, "Inputs length should be multiple of 192 bytes");

        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(inputs, 0x20), inputsLength, out, 0x20)
        }
        return success && out[0] == 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://gist.github.com/holiman/069de8d056a531575d2b786df3345665
pragma solidity ^0.7.0;

library Cloneable {
    function clone(address a)
        external
        returns (address)
    {

    /*
    Assembly of the code that we want to use as init-code in the new contract,
    along with stack values:
                    # bottom [ STACK ] top
     PUSH1 00       # [ 0 ]
     DUP1           # [ 0, 0 ]
     PUSH20
     <address>      # [0,0, address]
     DUP1           # [0,0, address ,address]
     EXTCODESIZE    # [0,0, address, size ]
     DUP1           # [0,0, address, size, size]
     SWAP4          # [ size, 0, address, size, 0]
     DUP1           # [ size, 0, address ,size, 0,0]
     SWAP2          # [ size, 0, address, 0, 0, size]
     SWAP3          # [ size, 0, size, 0, 0, address]
     EXTCODECOPY    # [ size, 0]
     RETURN

    The code above weighs in at 33 bytes, which is _just_ above fitting into a uint.
    So a modified version is used, where the initial PUSH1 00 is replaced by `PC`.
    This is one byte smaller, and also a bit cheaper Wbase instead of Wverylow. It only costs 2 gas.

     PC             # [ 0 ]
     DUP1           # [ 0, 0 ]
     PUSH20
     <address>      # [0,0, address]
     DUP1           # [0,0, address ,address]
     EXTCODESIZE    # [0,0, address, size ]
     DUP1           # [0,0, address, size, size]
     SWAP4          # [ size, 0, address, size, 0]
     DUP1           # [ size, 0, address ,size, 0,0]
     SWAP2          # [ size, 0, address, 0, 0, size]
     SWAP3          # [ size, 0, size, 0, 0, address]
     EXTCODECOPY    # [ size, 0]
     RETURN

    The opcodes are:
    58 80 73 <address> 80 3b 80 93 80 91 92 3c F3
    We get <address> in there by OR:ing the upshifted address into the 0-filled space.
      5880730000000000000000000000000000000000000000803b80938091923cF3
     +000000xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx000000000000000000
     -----------------------------------------------------------------
      588073xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00000803b80938091923cF3

    This is simply stored at memory position 0, and create is invoked.
    */
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 ,mul(a,0x1000000000000000000)))
            retval := create(0,0, 32)
        }
        return retval;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
  event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "../../lib/ERC20.sol";


abstract contract IChiToken is ERC20
{
    function free(uint256 value)
    external
    virtual
    returns (uint256);

    function freeUpTo(uint256 value)
    external
    virtual
    returns (uint256);

    function freeFrom(address from, uint256 value)
    external
    virtual
    returns (uint256);

    function freeFromUpTo(address from, uint256 value)
    external
    virtual
    returns (uint256 freed);
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.0;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public immutable trustedForwarder;

    constructor(address _forwarder)
    {
        trustedForwarder = _forwarder;
    }

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.7.0;

interface IKnowForwarderAddress {

    /**
     * return the forwarder we trust to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function getTrustedForwarder() external view returns(address);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title Hard coded verification keys
/// @dev Generated on 18-Jul-2022 16:56:48, CST
/// @author Berg Jefferson - <[email protected]>
library VerificationKeys
{
    function getKey(
        uint blockType,
        uint blockSize,
        uint blockVersion
        )
        internal
        pure
        returns (uint[14] memory vk, uint[4] memory vk_gammaABC, bool found)
    {
        if (blockType == 0 && blockSize == 320 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              10281411527352048689531947275247127593081118036396478391442821647666120308913,
              14183766028271644690470780121877355548484926092796433542558999536886188797553,
              14349647251177890270720878224680774493644831098564173078581106028536056029223,
              15540448762688867075244269528277703422600214973471138114466012441044685509617
            ];
            vk_gammaABC = [
              2036556296679026605970417947515419195316778870434507698326069579149296210962,
              15349395870630460495061082402789532847406129257251762630279852649806199549853,
              2970255263746651339212945286134273939894820279936213692999533488550413757005,
              20792110978196173681712627864437491850879240957095988115137813293532563193144
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 170 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              4682956840302592794117972770732445682263226956788713975934573863025791110303,
              16388848861784882888589634675145717963592918816432396564828229704061563785209,
              17374855162930851919868736484596498864648735838219181623769762056149693254153,
              19151407009613833113563526940782946598731877452289219330880970240504238030391
            ];
            vk_gammaABC = [
              14277877491890615483788923438557660958420882868332469876219233439317058131714,
              17763719798841200282935388779879967660154386860649176565473486252266461816244,
              11676440789910270300805377502224217134463843339809794860688448139316117328273,
              2550682711891728640045096199092753295207803069012232991501293755789969913664
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 85 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              7176572436556340075494288443996968532283303781781727452170706971225381465456,
              16974633487402837120290705904970824777342149734047518756125810733295679483401,
              701124790896773824097555437817531168131539378259519484384912937099759446184,
              10413816355642916256252679014026612316390050207594924083742901898785171328296
            ];
            vk_gammaABC = [
              16577416683973189932177788112116668199694051930641644285264304846213834235781,
              8029124028901271703727249176267437825833448231262511110292326042239647426173,
              17164092919283319521890516803883671695099789389371545881183117706244506903503,
              12213032100002461288473760183078425124449127549097495533178521131012070789010
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 42 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              15991122211399014054858520545695515058992825947661419737316587061521089547115,
              10087301294407364395881490842035696810370038670172092730950488223488978860300,
              1475443887588386146266576117442642124181882705861470672553565939002278514472,
              18205018162955350608738335811130499992456092320051659374558313621251945051172
            ];
            vk_gammaABC = [
              11701666985805172207714976508629269208942276007531431070823617503859097856975,
              10081450245900171073611938777581003349442436088415374305589757561264604800905,
              6028260966411862903781219033850779543076525648793061295030395467354330833156,
              20262359318070559490611845745591700279454349880824732391760528882106422988393
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 20 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              4417602906978363333364539119320966552370726265813898789256384585078837390325,
              991306936432055864498290372119289294419760628409022834558954454801904066104,
              12905390383568132357564809092281370158294691219380752885361174669514602348689,
              20039526902544359258862977146902692843362181008581860198599235351698976321432
            ];
            vk_gammaABC = [
              5429535145598861903493122446598043028382019646721032879633796522908942368785,
              1594353559290590718822412556322849823880750114639389230212676576803572400567,
              7283605362129442098734434572970704215356783924569644755813234600492390681179,
              3681370426949555695979263921239784991447868245163814206854981665812768157990
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 10 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              5589845853692782918093798700451361218403826782596297099044680334081719512766,
              16872568814719374508137776421494919679598593816968091647888829987641202317026,
              9213911990469912458915358010803544007265138890761628989572682166650184075828,
              6628266818813536300630992540891301894070396127406500679289605594288504130293
            ];
            vk_gammaABC = [
              5378079414375850537507246593130226014126808587722207910960361143396242273340,
              9545472785278840640630004644579299385027334707848211218843089747665483294884,
              3602919804732032634992146901578180017522667425908714034264579560277125106745,
              16141863154397234458253515947259415515922258049666230632249761283586065498664
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 5 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              740762425135898939855909783827111402857327519032730032890074379422624835096,
              4269737538950126719147228602045146595446702787375606107810931493230002422909,
              16783530978016627329294141456128139892048905473999974821959721444983766807413,
              6044744913703755482072657932054313497583646935032862350258569946795772765536
            ];
            vk_gammaABC = [
              14979171551378673983218799401899226916444141930376281160798273912346257564167,
              202192970803325769224285261255485590655157422637474488924213158809414449002,
              113876707811528671593245045046838668773075968485353445397500408985444199547,
              13855223698095345829184539308103509884437770510363661924460511005730452504890
            ];
            found = true;
        } else {
            found = false;
        }
    }
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "../../lib/AddressUtil.sol";
import "../../lib/EIP712.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../../thirdparty/proxies/OwnedUpgradabilityProxy.sol";
import "../iface/IAgentRegistry.sol";
import "../iface/IExchangeV3.sol";
import "../iface/IBlockVerifier.sol";
import "./libexchange/ExchangeAdmins.sol";
import "./libexchange/ExchangeBalances.sol";
import "./libexchange/ExchangeBlocks.sol";
import "./libexchange/ExchangeDeposits.sol";
import "./libexchange/ExchangeGenesis.sol";
import "./libexchange/ExchangeMode.sol";
import "./libexchange/ExchangeTokens.sol";
import "./libexchange/ExchangeWithdrawals.sol";

/// @title An Implementation of IExchangeV3.
/// @dev This contract supports upgradability proxy, therefore its constructor
///      must do NOTHING.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
contract ExchangeV3 is IExchangeV3, ReentrancyGuard
{
    using AddressUtil           for address;
    using ERC20SafeTransfer     for address;
    using MathUint              for uint;
    using ExchangeAdmins        for ExchangeData.State;
    using ExchangeBalances      for ExchangeData.State;
    using ExchangeBlocks        for ExchangeData.State;
    using ExchangeDeposits      for ExchangeData.State;
    using ExchangeGenesis       for ExchangeData.State;
    using ExchangeMode          for ExchangeData.State;
    using ExchangeTokens        for ExchangeData.State;
    using ExchangeWithdrawals   for ExchangeData.State;

    ExchangeData.State public state;
    bool public allowOnchainTransferFrom = false;

    modifier onlyWhenUninitialized()
    {
        require(
            address(state.loopring) == address(0) && state.merkleRoot == bytes32(0),
            "INITIALIZED"
        );
        _;
    }

    modifier onlyFromUserOrAgent(address from)
    {
        require(isUserOrAgent(from), "UNAUTHORIZED");
        _;
    }

    /// @dev The constructor must do NOTHING to support proxy.
    constructor() {}

    function version()
        public
        pure
        returns (string memory)
    {
        return "0.1.0";
    }

    function domainSeparator()
        external
        view
        returns (bytes32)
    {
        return state.DOMAIN_SEPARATOR;
    }

    // -- Initialization --
    function initialize(
        address _loopring,
        address _owner,
        bytes32 _genesisMerkleRoot,
        bytes32 _genesisMerkleAssetRoot
        )
        external
        override
        nonReentrant
        onlyWhenUninitialized
    {
        require(address(0) != _owner, "ZERO_ADDRESS");
        owner = _owner;

        state.initializeGenesisBlock(
            _loopring,
            _genesisMerkleRoot,
            _genesisMerkleAssetRoot,
            EIP712.hash(EIP712.Domain("DeGate Protocol", version(), address(this)))
        );
    }

    function refreshBlockVerifier(address blockVerifierAddress)
        external
        override
        nonReentrant
        onlyOwner
    {
        require(blockVerifierAddress != address(0), "ZERO_ADDRESS");
        state.blockVerifier = IBlockVerifier(blockVerifierAddress);

        emit BlockVerifierRefreshed(address(state.blockVerifier));
    }

    function setDepositContract(address _depositContract)
        external
        override
        nonReentrant
        onlyOwner
    {
        require(_depositContract != address(0), "ZERO_ADDRESS");
        // Only used for initialization
        require(state.depositContract == IDepositContract(0), "ALREADY_SET");
        state.depositContract = IDepositContract(_depositContract);

        emit DepositContractUpdate(_depositContract);
    }

    function getDepositContract()
        external
        override
        view
        returns (IDepositContract)
    {
        return state.depositContract;
    }

    function withdrawExchangeFees(
        address token,
        address recipient
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        require(recipient != address(0), "INVALID_ADDRESS");

        if (token == address(0)) {
            uint amount = address(this).balance;
            recipient.sendETHAndVerify(amount, gasleft());
        } else {
            uint amount = ERC20(token).balanceOf(address(this));
            token.safeTransferAndVerify(recipient, amount);
        }

        emit WithdrawExchangeFees(token, recipient);
    }

    function setDepositParams(
        uint256 freeDepositMax,
        uint256 freeDepositRemained,
        uint256 freeSlotPerBlock,
        uint256 depositFee
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        state.setDepositParams(
            freeDepositMax,
            freeDepositRemained,
            freeSlotPerBlock,
            depositFee
        );

        emit DepositParamsUpdate(freeDepositMax, freeDepositRemained, freeSlotPerBlock, depositFee);
    }

    function isUserOrAgent(address from)
        public
        view
        returns (bool)
    {
         return from == msg.sender ||
            state.agentRegistry != IAgentRegistry(address(0)) &&
            state.agentRegistry.isAgent(from, msg.sender);
    }

    // -- Constants --
    function getConstants()
        external
        override
        pure
        returns(ExchangeData.Constants memory)
    {
        return ExchangeData.Constants(
            uint(ExchangeData.SNARK_SCALAR_FIELD),
            uint(ExchangeData.MAX_OPEN_FORCED_REQUESTS),
            uint(ExchangeData.MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE),
            uint(ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS),
            uint(ExchangeData.MAX_NUM_ACCOUNTS),
            uint(ExchangeData.MAX_NUM_TOKENS),
            uint(ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED),
            uint(ExchangeData.MIN_TIME_IN_SHUTDOWN),
            uint(ExchangeData.TX_DATA_AVAILABILITY_SIZE),
            uint(ExchangeData.MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND),
            uint(ExchangeData.MAX_FORCED_WITHDRAWAL_FEE),
            uint(ExchangeData.MAX_PROTOCOL_FEE_BIPS),
            uint(ExchangeData.DEFAULT_PROTOCOL_FEE_BIPS)
        );
    }

    // -- Mode --
    function isInWithdrawalMode()
        external
        override
        view
        returns (bool)
    {
        return state.isInWithdrawalMode();
    }

    function isShutdown()
        external
        override
        view
        returns (bool)
    {
        return state.isShutdown();
    }

    // -- Tokens --

    function registerToken(
        address tokenAddress
        )
        external
        override
        nonReentrant
        returns (uint32)
    {
        return state.registerToken(tokenAddress, msg.sender == owner);
    }

    function getTokenID(
        address tokenAddress
        )
        external
        override
        view
        returns (uint32)
    {
        return state.getTokenID(tokenAddress);
    }

    function getTokenAddress(
        uint32 tokenID
        )
        external
        override
        view
        returns (address)
    {
        return state.getTokenAddress(tokenID);
    }

    // -- Stakes --
    function getExchangeStake()
        external
        override
        view
        returns (uint)
    {
        return state.loopring.getExchangeStake(address(this));
    }

    function withdrawExchangeStake(
        address recipient
        )
        external
        override
        nonReentrant
        onlyOwner
        returns (uint)
    {
        return state.withdrawExchangeStake(recipient);
    }

    function getProtocolFeeLastWithdrawnTime(
        address tokenAddress
        )
        external
        override
        view
        returns (uint)
    {
        return state.protocolFeeLastWithdrawnTime[tokenAddress];
    }

    function burnExchangeStake()
        external
        override
        nonReentrant
    {
        // Allow burning the complete exchange stake when the exchange gets into withdrawal mode
        if (state.isInWithdrawalMode()) {
            // Burn the complete stake of the exchange
            uint stake = state.loopring.getExchangeStake(address(this));
            state.loopring.burnExchangeStake(stake);
        }
    }

    // -- Blocks --
    function getMerkleRoot()
        external
        override
        view
        returns (bytes32)
    {
        return state.merkleRoot;
    }

    // -- Blocks --
    function getMerkleAssetRoot()
        external
        override
        view
        returns (bytes32)
    {
        return state.merkleAssetRoot;
    }

    function getBlockHeight()
        external
        override
        view
        returns (uint)
    {
        return state.numBlocks;
    }

    function getBlockInfo(uint blockIdx)
        external
        override
        view
        returns (ExchangeData.BlockInfo memory)
    {
        return state.blocks[blockIdx];
    }

    function submitBlocks(ExchangeData.Block[] calldata blocks)
        external
        override
        nonReentrant
        onlyOwner
    {
        state.submitBlocks(blocks);
    }

    function getNumAvailableForcedSlots()
        external
        override
        view
        returns (uint)
    {
        return state.getNumAvailableForcedSlots();
    }

    // -- Deposits --

    function deposit(
        address from,
        address to,
        address tokenAddress,
        uint248  amount,
        bytes   calldata extraData
        )
        external
        payable
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        state.deposit(from, to, tokenAddress, amount, extraData);
    }

    function getPendingDepositAmount(
        address from,
        address tokenAddress
        )
        external
        override
        view
        returns (uint248)
    {
        uint32 tokenID = state.getTokenID(tokenAddress);
        return state.pendingDeposits[from][tokenID].amount;
    }

    // -- Withdrawals --

    function forceWithdraw(
        address from,
        address token,
        uint32  accountID
        )
        external
        override
        nonReentrant
        payable
        onlyFromUserOrAgent(from)
    {
        state.forceWithdraw(from, token, accountID);
    }

    function isForcedWithdrawalPending(
        uint32  accountID,
        address token
        )
        external
        override
        view
        returns (bool)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.pendingForcedWithdrawals[accountID][tokenID].timestamp != 0;
    }

    // We still alow anyone to withdraw these funds for the account owner
    function withdrawFromMerkleTree(
        ExchangeData.MerkleProof calldata merkleProof
        )
        external
        override
        nonReentrant
    {
        state.withdrawFromMerkleTree(merkleProof);
    }

    function isWithdrawnInWithdrawalMode(
        uint32  accountID,
        address token
        )
        external
        override
        view
        returns (bool)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.withdrawnInWithdrawMode[accountID][tokenID];
    }

    function withdrawFromDepositRequest(
        address from,
        address token
        )
        external
        override
        nonReentrant
    {
        state.withdrawFromDepositRequest(
            from,
            token
        );
    }

    function withdrawFromApprovedWithdrawals(
        address[] calldata owners,
        address[] calldata tokens
        )
        external
        override
        nonReentrant
    {
        state.withdrawFromApprovedWithdrawals(
            owners,
            tokens
        );
    }

    function getAmountWithdrawable(
        address from,
        address token
        )
        external
        override
        view
        returns (uint)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.amountWithdrawable[from][tokenID];
    }

    function notifyForcedRequestTooOld(
        uint32  accountID,
        address token
        )
        external
        override
        nonReentrant
    {
        uint32 tokenID = state.getTokenID(token);
        ExchangeData.ForcedWithdrawal storage withdrawal = state.pendingForcedWithdrawals[accountID][tokenID];
        require(withdrawal.timestamp != 0, "WITHDRAWAL_NOT_TOO_OLD");

        // Check if the withdrawal has indeed exceeded the time limit
        require(block.timestamp >= withdrawal.timestamp + ExchangeData.MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE, "WITHDRAWAL_NOT_TOO_OLD");

        // Enter withdrawal mode
        state.modeTime.withdrawalModeStartTime = block.timestamp;

        emit WithdrawalModeActivated(state.modeTime.withdrawalModeStartTime);
    }

    function setWithdrawalRecipient(
        address from,
        address to,
        address token,
        uint248  amount,
        uint32  storageID,
        address newRecipient
        )
        external
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        require(newRecipient != address(0), "INVALID_DATA");
        uint32 tokenID = state.getTokenID(token);
        require(state.withdrawalRecipient[from][to][tokenID][amount][storageID] == address(0), "CANNOT_OVERRIDE_RECIPIENT_ADDRESS");
        state.withdrawalRecipient[from][to][tokenID][amount][storageID] = newRecipient;

        emit WithdrawalRecipientUpdate(from, to, token, amount, storageID, newRecipient);
    }

    function getWithdrawalRecipient(
        address from,
        address to,
        address token,
        uint248  amount,
        uint32  storageID
        )
        external
        override
        view
        returns (address)
    {
        uint32 tokenID = state.getTokenID(token);
        return state.withdrawalRecipient[from][to][tokenID][amount][storageID];
    }

    function onchainTransferFrom(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        require(allowOnchainTransferFrom, "NOT_ALLOWED");
        state.depositContract.transfer(from, to, token, amount);
    }

    function approveTransaction(
        address from,
        bytes32 transactionHash
        )
        external
        override
        nonReentrant
        onlyFromUserOrAgent(from)
    {
        state.approvedTx[from][transactionHash] = true;
        emit TransactionApproved(from, transactionHash);
    }

    function approveTransactions(
        address[] calldata owners,
        bytes32[] calldata transactionHashes
        )
        external
        override
        nonReentrant
    {
        require(owners.length == transactionHashes.length, "INVALID_DATA");
        require(state.agentRegistry.isAgent(owners, msg.sender), "UNAUTHORIZED");
        for (uint i = 0; i < owners.length; i++) {
            state.approvedTx[owners[i]][transactionHashes[i]] = true;
        }
        emit TransactionsApproved(owners, transactionHashes);
    }

    function isTransactionApproved(
        address from,
        bytes32 transactionHash
        )
        external
        override
        view
        returns (bool)
    {
        return state.approvedTx[from][transactionHash];
    }

    function getDomainSeparator()
        external
        override
        view
        returns (bytes32)
    {
        return state.DOMAIN_SEPARATOR;
    }

    // -- Admins --
    function setMaxAgeDepositUntilWithdrawable(
        uint32 newValue
        )
        external
        override
        nonReentrant
        onlyOwner
        returns (uint32)
    {
        return state.setMaxAgeDepositUntilWithdrawable(newValue);
    }

    function getMaxAgeDepositUntilWithdrawable()
        external
        override
        view
        returns (uint32)
    {
        return state.maxAgeDepositUntilWithdrawable;
    }

    function shutdown()
        external
        override
        nonReentrant
        onlyOwner
        returns (bool success)
    {
        require(!state.isInWithdrawalMode(), "INVALID_MODE");
        require(!state.isShutdown(), "ALREADY_SHUTDOWN");
        state.modeTime.shutdownModeStartTime = block.timestamp;
        emit Shutdown(state.modeTime.shutdownModeStartTime);
        return true;
    }

    function getProtocolFeeValues()
        external
        override
        view
        returns (
            uint32 syncedAt,
            uint8  protocolFeeBips,
            uint8  previousProtocolFeeBips,
            uint32 executeTimeOfNextProtocolFeeBips,
            uint32 nextProtocolFeeBips
        )
    {
        syncedAt = state.protocolFeeData.syncedAt;
        protocolFeeBips = state.protocolFeeData.protocolFeeBips;
        previousProtocolFeeBips = state.protocolFeeData.previousProtocolFeeBips;
        executeTimeOfNextProtocolFeeBips = state.protocolFeeData.executeTimeOfNextProtocolFeeBips;
        nextProtocolFeeBips = state.protocolFeeData.nextProtocolFeeBips;
    }

    function setAllowOnchainTransferFrom(bool value)
        external
        nonReentrant
        onlyOwner
    {
        require(allowOnchainTransferFrom != value, "SAME_VALUE");
        allowOnchainTransferFrom = value;

        emit AllowOnchainTransferFrom(value);
    }

    function getUnconfirmedBalance(address token)
        external
        override
        view
        returns(uint256)
    {
        uint32 tokenId = state.getTokenID(token);

        uint256 unconfirmedBalance = 0;

        if (tokenId == 0) {
            unconfirmedBalance = address(state.depositContract).balance.sub(state.tokenIdToDepositBalance[tokenId]);
        } else {
            unconfirmedBalance = ERC20(token).balanceOf(address(state.depositContract)).sub(state.tokenIdToDepositBalance[tokenId]);
        }
        return unconfirmedBalance;
    }

    function getFreeDepositRemained()
        external
        override
        view
        returns(uint256)
    {
        return state.depositState.freeDepositRemained;
    }

    function getDepositBalance(address token)
        external
        override
        view
        returns(uint248)
    {
        uint32 tokenId = state.getTokenID(token);

        return state.tokenIdToDepositBalance[tokenId];
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/ERC20.sol";
import "../../../lib/ERC20SafeTransfer.sol";
import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "./ExchangeMode.sol";


/// @title ExchangeAdmins.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeAdmins
{
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;
    using MathUint          for uint;

    event MaxAgeDepositUntilWithdrawableChanged(
        address indexed exchangeAddr,
        uint32          oldValue,
        uint32          newValue
    );

    function setMaxAgeDepositUntilWithdrawable(
        ExchangeData.State storage S,
        uint32 newValue
        )
        public
        returns (uint32 oldValue)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(
            newValue > 0 &&
            newValue <= ExchangeData.MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND,
            "INVALID_VALUE"
        );
        oldValue = S.maxAgeDepositUntilWithdrawable;
        S.maxAgeDepositUntilWithdrawable = newValue;

        emit MaxAgeDepositUntilWithdrawableChanged(
            address(this),
            oldValue,
            newValue
        );
    }

    function withdrawExchangeStake(
        ExchangeData.State storage S,
        address recipient
        )
        public
        returns (uint)
    {
        // Exchange needs to be shutdown
        require(S.isShutdown(), "EXCHANGE_NOT_SHUTDOWN");
        require(!S.isInWithdrawalMode(), "CANNOT_BE_IN_WITHDRAWAL_MODE");

        // Need to remain in shutdown for some time
        require(block.timestamp >= S.modeTime.shutdownModeStartTime + ExchangeData.MIN_TIME_IN_SHUTDOWN, "TOO_EARLY");

        // Withdraw the complete stake
        uint amount = S.loopring.getExchangeStake(address(this));
        return S.loopring.withdrawExchangeStake(recipient, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";


/// @title ExchangeMode.
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeMode
{
    using MathUint  for uint;

    function isInWithdrawalMode(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool result)
    {
        result = S.modeTime.withdrawalModeStartTime > 0;
    }

    function isShutdown(
        ExchangeData.State storage S
        )
        internal // inline call
        view
        returns (bool)
    {
        return S.modeTime.shutdownModeStartTime > 0;
    }

    function getNumAvailableForcedSlots(
        ExchangeData.State storage S
        )
        internal
        view
        returns (uint)
    {
        return ExchangeData.MAX_OPEN_FORCED_REQUESTS - S.numPendingForcedTransactions;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/MathUint.sol";
import "../../../lib/Poseidon.sol";
import "../../iface/ExchangeData.sol";


/// @title ExchangeBalances.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeBalances
{
    using MathUint  for uint;

    function verifyAccountBalance(
        uint                              merkleRoot,
        ExchangeData.MerkleProof calldata merkleProof
        )
        public
        pure
    {
        require(
            isAccountBalanceCorrect(merkleRoot, merkleProof),
            "INVALID_MERKLE_TREE_DATA"
        );
    }

    function isAccountBalanceCorrect(
        uint                            merkleRoot,
        ExchangeData.MerkleProof memory merkleProof
        )
        public
        pure
        returns (bool)
    {
        // Calculate the Merkle root using the Merkle paths provided
        uint calculatedRoot = getBalancesRoot(
            merkleProof.balanceLeaf.tokenID,
            merkleProof.balanceLeaf.balance,
            merkleProof.balanceMerkleProof
        );
        calculatedRoot = getAccountInternalsRoot(
            merkleProof.accountLeaf.accountID,
            merkleProof.accountLeaf.owner,
            merkleProof.accountLeaf.pubKeyX,
            merkleProof.accountLeaf.pubKeyY,
            merkleProof.accountLeaf.nonce,
            calculatedRoot,
            merkleProof.accountMerkleProof
        );
        // Check against the expected Merkle root
        return (calculatedRoot == merkleRoot);
    }

    function getBalancesRoot(
        uint32   tokenID,
        uint     balance,
        uint[48] memory balanceMerkleProof
        )
        private
        pure
        returns (uint)
    {
        // Hash the balance leaf
        uint balanceItem = hashImpl(balance, 0, 0, 0);
        // Calculate the Merkle root of the balance quad Merkle tree
        uint _id = tokenID;
        for (uint depth = 0; depth < ExchangeData.BINARY_TREE_DEPTH_TOKENS/2; depth++) { // quad tree depth 
            uint base = depth * 3;
            if (_id & 3 == 0) {
                balanceItem = hashImpl(
                    balanceItem,
                    balanceMerkleProof[base],
                    balanceMerkleProof[base + 1],
                    balanceMerkleProof[base + 2]
                );
            } else if (_id & 3 == 1) {
                balanceItem = hashImpl(
                    balanceMerkleProof[base],
                    balanceItem,
                    balanceMerkleProof[base + 1],
                    balanceMerkleProof[base + 2]
                );
            } else if (_id & 3 == 2) {
                balanceItem = hashImpl(
                    balanceMerkleProof[base],
                    balanceMerkleProof[base + 1],
                    balanceItem,
                    balanceMerkleProof[base + 2]
                );
            } else if (_id & 3 == 3) {
                balanceItem = hashImpl(
                    balanceMerkleProof[base],
                    balanceMerkleProof[base + 1],
                    balanceMerkleProof[base + 2],
                    balanceItem
                );
            }
            _id = _id >> 2;
        }
        return balanceItem;
    }

    function getAccountInternalsRoot(
        uint32   accountID,
        address  owner,
        uint     pubKeyX,
        uint     pubKeyY,
        uint     nonce,
        uint     balancesRoot,
        uint[48] memory accountMerkleProof
        )
        private
        pure
        returns (uint)
    {
        // Hash the account leaf
        uint accountItem = hashAccountLeaf(uint(owner), pubKeyX, pubKeyY, nonce, balancesRoot);
        // Calculate the Merkle root of the account quad Merkle tree
        uint _id = accountID;
        for (uint depth = 0; depth < ExchangeData.BINARY_TREE_DEPTH_ACCOUNTS/2; depth++) { // quad tree depth 
            uint base = depth * 3;
            if (_id & 3 == 0) {
                accountItem = hashImpl(
                    accountItem,
                    accountMerkleProof[base],
                    accountMerkleProof[base + 1],
                    accountMerkleProof[base + 2]
                );
            } else if (_id & 3 == 1) {
                accountItem = hashImpl(
                    accountMerkleProof[base],
                    accountItem,
                    accountMerkleProof[base + 1],
                    accountMerkleProof[base + 2]
                );
            } else if (_id & 3 == 2) {
                accountItem = hashImpl(
                    accountMerkleProof[base],
                    accountMerkleProof[base + 1],
                    accountItem,
                    accountMerkleProof[base + 2]
                );
            } else if (_id & 3 == 3) {
                accountItem = hashImpl(
                    accountMerkleProof[base],
                    accountMerkleProof[base + 1],
                    accountMerkleProof[base + 2],
                    accountItem
                );
            }
            _id = _id >> 2;
        }
        return accountItem;
    }

    function hashAccountLeaf(
        uint t0,
        uint t1,
        uint t2,
        uint t3,
        uint t4
        )
        public
        pure
        returns (uint)
    {
        Poseidon.HashInputs6 memory inputs = Poseidon.HashInputs6(t0, t1, t2, t3, t4, 0);
        return Poseidon.hash_t6f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
    }

    function hashImpl(
        uint t0,
        uint t1,
        uint t2,
        uint t3
        )
        private
        pure
        returns (uint)
    {
        Poseidon.HashInputs5 memory inputs = Poseidon.HashInputs5(t0, t1, t2, t3, 0);
        return Poseidon.hash_t5f6p52(inputs, ExchangeData.SNARK_SCALAR_FIELD);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/AddressUtil.sol";
import "../../../lib/MathUint.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";
import "../../iface/IBlockVerifier.sol";
import "../libtransactions/BlockReader.sol";
import "../libtransactions/AccountUpdateTransaction.sol";
import "../libtransactions/DepositTransaction.sol";
import "../libtransactions/WithdrawTransaction.sol";
import "./ExchangeMode.sol";
import "./ExchangeWithdrawals.sol";


/// @title ExchangeBlocks.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeBlocks
{
    using AddressUtil          for address;
    using AddressUtil          for address payable;
    using BlockReader          for bytes;
    using BytesUtil            for bytes;
    using MathUint             for uint;
    using ExchangeMode         for ExchangeData.State;
    using ExchangeWithdrawals  for ExchangeData.State;
    using SignatureUtil        for bytes32;

    event BlockSubmitted(
        uint    indexed blockIdx,
        bytes32         merkleRoot,
        bytes32         publicDataHash
    );

    event ProtocolFeesUpdated(
        uint8 protocolFeeBips,
        uint8 previousProtocolFeeBips
    );

    function submitBlocks(
        ExchangeData.State   storage S,
        ExchangeData.Block[] memory  blocks
        )
        public
    {
        // Exchange cannot be in withdrawal mode
        require(!S.isInWithdrawalMode(), "INVALID_MODE");

        // Commit the blocks
        bytes32[] memory publicDataHashes = new bytes32[](blocks.length);
        for (uint i = 0; i < blocks.length; i++) {
            // Hash all the public data to a single value which is used as the input for the circuit
            publicDataHashes[i] = blocks[i].data.fastSHA256();
            // Commit the block
            commitBlock(S, blocks[i], publicDataHashes[i]);
        }

        // Verify the blocks - blocks are verified in a batch to save gas.
        verifyBlocks(S, blocks, publicDataHashes);
    }

    // == Internal Functions ==

    function commitBlock(
        ExchangeData.State storage S,
        ExchangeData.Block memory  _block,
        bytes32                    _publicDataHash
        )
        private
    {
        // Read the block header
        BlockReader.BlockHeader memory header = _block.data.readHeader();

        // Validate the exchange
        require(header.exchange == address(this), "INVALID_EXCHANGE");
        // Validate the Merkle roots
        require(header.merkleRootBefore == S.merkleRoot, "INVALID_MERKLE_ROOT");
        require(header.merkleRootAfter != header.merkleRootBefore, "EMPTY_BLOCK_DISABLED");
        require(header.merkleAssetRootBefore == S.merkleAssetRoot, "INVALID_MERKLE_ASSET_ROOT");
        require(header.merkleAssetRootAfter != header.merkleAssetRootBefore, "EMPTY_BLOCK_DISABLED");

        require(uint(header.merkleRootAfter) < ExchangeData.SNARK_SCALAR_FIELD, "INVALID_MERKLE_ROOT");
        require(uint(header.merkleAssetRootAfter) < ExchangeData.SNARK_SCALAR_FIELD, "INVALID_ASSERT_MERKLE_ROOT");
        // Validate the timestamp
        require(
            header.timestamp > block.timestamp - ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS &&
            header.timestamp < block.timestamp + ExchangeData.TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS,
            "INVALID_TIMESTAMP"
        );
        // Validate the protocol fee values
        require(
            validateAndSyncProtocolFees(S, header.protocolFeeBips),
            "INVALID_PROTOCOL_FEES"
        );

        // Process conditional transactions
        processConditionalTransactions(
            S,
            _block,
            header
        );

        // Emit an event
        uint numBlocks = S.numBlocks;
        emit BlockSubmitted(numBlocks, header.merkleRootAfter, _publicDataHash);

        S.merkleRoot = header.merkleRootAfter;
        S.merkleAssetRoot = header.merkleAssetRootAfter;

        if (_block.storeBlockInfoOnchain) {
            S.blocks[numBlocks] = ExchangeData.BlockInfo(
                uint32(block.timestamp),
                bytes28(_publicDataHash)
            );
        }

        S.numBlocks = numBlocks + 1;
    }

    function verifyBlocks(
        ExchangeData.State   storage S,
        ExchangeData.Block[] memory  blocks,
        bytes32[]            memory  publicDataHashes
        )
        private
        view
    {
        IBlockVerifier blockVerifier = S.blockVerifier;
        uint numBlocksVerified = 0;
        bool[] memory blockVerified = new bool[](blocks.length);
        ExchangeData.Block memory firstBlock;
        uint[] memory batch = new uint[](blocks.length);

        while (numBlocksVerified < blocks.length) {
            // Find all blocks of the same type
            uint batchLength = 0;
            for (uint i = 0; i < blocks.length; i++) {
                if (blockVerified[i] == false) {
                    if (batchLength == 0) {
                        firstBlock = blocks[i];
                        batch[batchLength++] = i;
                    } else {
                        ExchangeData.Block memory _block = blocks[i];
                        if (_block.blockType == firstBlock.blockType &&
                            _block.blockSize == firstBlock.blockSize &&
                            _block.blockVersion == firstBlock.blockVersion) {
                            batch[batchLength++] = i;
                        }
                    }
                }
            }

            // Prepare the data for batch verification
            uint[] memory publicInputs = new uint[](batchLength);
            uint[] memory proofs = new uint[](batchLength * 8);

            for (uint i = 0; i < batchLength; i++) {
                uint blockIdx = batch[i];
                // Mark the block as verified
                blockVerified[blockIdx] = true;
                // Strip the 3 least significant bits of the public data hash
                // so we don't have any overflow in the snark field
                publicInputs[i] = uint(publicDataHashes[blockIdx]) >> 3;
                // Copy proof
                ExchangeData.Block memory _block = blocks[blockIdx];
                for (uint j = 0; j < 8; j++) {
                    proofs[i*8 + j] = _block.proof[j];
                }
            }

            // Verify the proofs
            require(
                blockVerifier.verifyProofs(
                    uint8(firstBlock.blockType),
                    firstBlock.blockSize,
                    firstBlock.blockVersion,
                    publicInputs,
                    proofs
                ),
                "INVALID_PROOF"
            );

            numBlocksVerified += batchLength;
        }
    }

    function processConditionalTransactions(
        ExchangeData.State      storage S,
        ExchangeData.Block      memory _block,
        BlockReader.BlockHeader memory header
        )
        private
    {
        if (header.numConditionalTransactions > 0) {
            // Cache the domain seperator to save on SLOADs each time it is accessed.
            ExchangeData.BlockContext memory ctx = ExchangeData.BlockContext({
                DOMAIN_SEPARATOR: S.DOMAIN_SEPARATOR,
                timestamp: header.timestamp
            });

            ExchangeData.AuxiliaryData[] memory block_auxiliaryData;
            bytes memory blockAuxData = _block.auxiliaryData;
            assembly {
                block_auxiliaryData := add(blockAuxData, 64)
            }

            require(
                block_auxiliaryData.length == header.numConditionalTransactions,
                "AUXILIARYDATA_INVALID_LENGTH"
            );

            require(
                header.numConditionalTransactions == (header.depositSize + header.accountUpdateSize + header.withdrawSize),
                "invalid number of conditional transactions"
            );

            // Run over all conditional transactions
            uint minTxIndex = 0;
            bytes memory txData = new bytes(ExchangeData.TX_DATA_AVAILABILITY_SIZE);
            for (uint i = 0; i < block_auxiliaryData.length; i++) {
                uint txIndex;
                ExchangeData.TransactionType txType;
                if (i < header.depositSize) {
                    txType = ExchangeData.TransactionType.DEPOSIT;
                    txIndex = i; 
                }else if(i < header.depositSize + header.accountUpdateSize) {
                    txType = ExchangeData.TransactionType.ACCOUNT_UPDATE;
                    txIndex = i;
                }else {
                    txType = ExchangeData.TransactionType.WITHDRAWAL;
                    txIndex = i + _block.blockSize - header.depositSize - header.accountUpdateSize - header.withdrawSize; 
                }

                // Load the data from auxiliaryData, which is still encoded as calldata



                bytes memory auxData;
                assembly {
                    // Offset to block_auxiliaryData[i]
                    let auxOffset := mload(add(block_auxiliaryData, add(32, mul(32, i))))

                    // Load `data` (pos 0)
                    let auxDataOffset := mload(add(add(32, block_auxiliaryData), auxOffset))
                    auxData := add(add(32, block_auxiliaryData), add(auxOffset, auxDataOffset))
                }

                // Each conditional transaction needs to be processed from left to right
                require(txIndex >= minTxIndex, "AUXILIARYDATA_INVALID_ORDER");

                minTxIndex = txIndex + 1;


                // Get the transaction data
                _block.data.readTransactionData(txIndex, _block.blockSize, txData);

                // Process the transaction
                uint txDataOffset = 0;

                if (txType == ExchangeData.TransactionType.DEPOSIT) {
                    DepositTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.WITHDRAWAL) {
                    WithdrawTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else if (txType == ExchangeData.TransactionType.ACCOUNT_UPDATE) {
                    AccountUpdateTransaction.process(
                        S,
                        ctx,
                        txData,
                        txDataOffset,
                        auxData
                    );
                } else {
                    // ExchangeData.TransactionType.NOOP,
                    // ExchangeData.TransactionType.TRANSFER and
                    // ExchangeData.TransactionType.SPOT_TRADE and
                    // ExchangeData.TransactionType.ORDER_CANCEL and
                    // ExchangeData.TransactionType.BATCH_SPOT_TRADE 
                    // ExchangeData.TransactionType.APPKEY_UPDATE 
                    // are not supported
                    revert("UNSUPPORTED_TX_TYPE");
                }
            }
        }
    }

    function validateAndSyncProtocolFees(
        ExchangeData.State storage S,
        uint8 protocolFeeBips
        )
        private
        returns (bool)
    {
        ExchangeData.ProtocolFeeData memory data = S.protocolFeeData;

        uint8 protocolFeeBipsInLoopring = S.loopring.getProtocolFeeValues();
        if (data.nextProtocolFeeBips != protocolFeeBipsInLoopring ) {
            data.executeTimeOfNextProtocolFeeBips = uint32(block.timestamp + ExchangeData.MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED);
            data.nextProtocolFeeBips = protocolFeeBipsInLoopring;

            // Update the data in storage
            S.protocolFeeData = data;
        }

        if ((data.executeTimeOfNextProtocolFeeBips !=0) && (block.timestamp > data.executeTimeOfNextProtocolFeeBips)) {
            // Store the current protocol fees in the previous protocol fees
            data.previousProtocolFeeBips = data.protocolFeeBips;
            // Get the latest protocol fees for this exchange
            data.protocolFeeBips = data.nextProtocolFeeBips;
            data.syncedAt = uint32(block.timestamp);

            data.executeTimeOfNextProtocolFeeBips = 0;

            if (data.protocolFeeBips != data.previousProtocolFeeBips ) {
                emit ProtocolFeesUpdated(
                    data.protocolFeeBips,
                    data.previousProtocolFeeBips
                );
            }

            // Update the data in storage
            S.protocolFeeData = data;
        }

        // The given fee values are valid if they are the current or previous protocol fee values
        return (protocolFeeBips == data.protocolFeeBips) ||
            (protocolFeeBips == data.previousProtocolFeeBips );
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";

/// @title BlockReader
/// @author Brecht Devos - <[email protected]>
/// @dev Utility library to read block data.
library BlockReader {
    using BlockReader       for ExchangeData.Block;
    using BytesUtil         for bytes;

    uint public constant OFFSET_TO_TRANSACTIONS = 20 + 32 + 32 + 32 + 32 + 4 + 1 + 4 + 4 + 2 + 2 + 2;


    struct BlockHeader
    {
        address exchange;
        bytes32 merkleRootBefore;
        bytes32 merkleRootAfter;
        bytes32 merkleAssetRootBefore;
        bytes32 merkleAssetRootAfter;
        uint32  timestamp;
        uint8   protocolFeeBips;

        uint32  numConditionalTransactions;
        uint32  operatorAccountID;

        uint16  depositSize;
        uint16  accountUpdateSize;
        uint16  withdrawSize;
    }

    function readHeader(
        bytes memory _blockData
        )
        internal
        pure
        returns (BlockHeader memory header)
    {
        uint offset = 0;
        header.exchange = _blockData.toAddress(offset);
        offset += 20;
        header.merkleRootBefore = _blockData.toBytes32(offset);
        offset += 32;
        header.merkleRootAfter = _blockData.toBytes32(offset);
        offset += 32;
        
        header.merkleAssetRootBefore = _blockData.toBytes32(offset);
        offset += 32;
        header.merkleAssetRootAfter = _blockData.toBytes32(offset);
        offset += 32;

        header.timestamp = _blockData.toUint32(offset);
        offset += 4;

        header.protocolFeeBips = _blockData.toUint8(offset);
        offset += 1;

        header.numConditionalTransactions = _blockData.toUint32(offset);
        offset += 4;
        header.operatorAccountID = _blockData.toUint32(offset);
        offset += 4;

        header.depositSize = _blockData.toUint16(offset);
        offset += 2;
        header.accountUpdateSize = _blockData.toUint16(offset);
        offset += 2;
        header.withdrawSize = _blockData.toUint16(offset);
        offset += 2;


        assert(offset == OFFSET_TO_TRANSACTIONS);
    }

    function readTransactionData(
        bytes memory data,
        uint txIdx,
        uint blockSize,
        bytes memory txData
        )
        internal
        pure
    {
        require(txIdx < blockSize, "INVALID_TX_IDX");

        // The transaction was transformed to make it easier to compress.
        // Transform it back here.
        // Part 1
        uint txDataOffset = OFFSET_TO_TRANSACTIONS +
            txIdx * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_1;
        assembly {
            //  first 32 bytes of an Array stores the length of that array.

            // part_1 is 80 bytes, longer than 32 bytes,  80 = 32 + 32 + 16
            mstore(add(txData, 32), mload(add(data, add(txDataOffset, 32))))
            mstore(add(txData, 64), mload(add(data, add(txDataOffset, 64))))
            mstore(add(txData, 80), mload(add(data, add(txDataOffset, 80))))
        }
        // Part 2
        txDataOffset = OFFSET_TO_TRANSACTIONS +
            blockSize * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_1 +
            txIdx * ExchangeData.TX_DATA_AVAILABILITY_SIZE_PART_2;
        assembly {
            // part_2 is 3 bytes
            // 112 = 32 + 80(part_1)
            mstore(add(txData, 112 ), mload(add(data, add(txDataOffset, 32))))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/EIP712.sol";
import "../../../lib/FloatUtil.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";
import "../libexchange/ExchangeSignatures.sol";


/// @title AccountUpdateTransaction
/// @author Brecht Devos - <[email protected]>
library AccountUpdateTransaction
{
    using BytesUtil            for bytes;
    using FloatUtil            for uint16;
    using ExchangeSignatures   for ExchangeData.State;

    bytes32 constant public ACCOUNTUPDATE_TYPEHASH = keccak256(
        "AccountUpdate(address owner,uint32 accountID,uint32 feeTokenID,uint96 maxFee,uint256 publicKey,uint32 validUntil,uint32 nonce)"
    );

    struct AccountUpdate
    {
        address owner;
        uint32  accountID;
        uint32  feeTokenID;
        uint96  maxFee;
        uint96  fee;
        uint    publicKey;
        uint32  validUntil;
        uint32  nonce;
    }

    // Auxiliary data for each account update
    struct AccountUpdateAuxiliaryData
    {
        bytes  signature;
        uint96 maxFee;
        uint32 validUntil;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        // Read the account update
        AccountUpdate memory accountUpdate;
        readTx(data, offset, accountUpdate);
        AccountUpdateAuxiliaryData memory auxData = abi.decode(auxiliaryData, (AccountUpdateAuxiliaryData));

        // Fill in withdrawal data missing from DA
        accountUpdate.validUntil = auxData.validUntil;
        accountUpdate.maxFee = auxData.maxFee;
        // Validate
        require(ctx.timestamp < accountUpdate.validUntil, "ACCOUNT_UPDATE_EXPIRED");
        require(accountUpdate.fee <= accountUpdate.maxFee, "ACCOUNT_UPDATE_FEE_TOO_HIGH");

        // Calculate the tx hash
        bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, accountUpdate);

        // Check onchain authorization
        S.requireAuthorizedTx(accountUpdate.owner, auxData.signature, txHash);

    }

    function readTx(
        bytes memory data,
        uint         offset,
        AccountUpdate memory accountUpdate
        )
        private
        pure
    {
        uint _offset = offset;

        // Check that this is a conditional offset
        require(data.toUint8Unsafe(_offset) == 1, "INVALID_AUXILIARYDATA_DATA");
        _offset += 1;

        // Extract the data from the tx data
        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        accountUpdate.owner = data.toAddressUnsafe(_offset);
        _offset += 20;
        accountUpdate.accountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        accountUpdate.feeTokenID = data.toUint32Unsafe(_offset);
        _offset += 4;
        accountUpdate.fee = data.toUint16Unsafe(_offset).decodeFloat16();
        _offset += 2;
        accountUpdate.publicKey = data.toUintUnsafe(_offset);
        _offset += 32;
        accountUpdate.nonce = data.toUint32Unsafe(_offset);
        _offset += 4;
    }

    function hashTx(
        bytes32 DOMAIN_SEPARATOR,
        AccountUpdate memory accountUpdate
        )
        private
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    ACCOUNTUPDATE_TYPEHASH,
                    accountUpdate.owner,
                    accountUpdate.accountID,
                    accountUpdate.feeTokenID,
                    accountUpdate.maxFee,
                    accountUpdate.publicKey,
                    accountUpdate.validUntil,
                    accountUpdate.nonce
                )
            )
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/SignatureUtil.sol";
import "../../iface/ExchangeData.sol";


/// @title ExchangeSignatures.
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeSignatures
{
    using SignatureUtil for bytes32;

    function requireAuthorizedTx(
        ExchangeData.State storage S,
        address signer,
        bytes memory signature,
        bytes32 txHash
        )
        internal // inline call
    {
        require(signer != address(0), "INVALID_SIGNER");
        // Verify the signature if one is provided, otherwise fall back to an approved tx
        if (signature.length > 0) {
            require(txHash.verifySignature(signer, signature), "INVALID_SIGNATURE");
        } else {
            require(S.approvedTx[signer][txHash], "TX_NOT_APPROVED");
            delete S.approvedTx[signer][txHash];
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/EIP712.sol";
import "../../../lib/ERC20.sol";
import "../../../lib/MathUint248.sol";
import "../../../lib/SignatureUtil.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";

/// @title DepositTransaction
/// @author Brecht Devos - <[email protected]>
library DepositTransaction
{
    using BytesUtil for bytes;
    using MathUint248 for uint248;
    using MathUint for uint256;

    struct Deposit
    {
        uint depositType;
        address to;
        uint32 toAccountID;
        uint32 tokenID;
        uint248 amount;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  /*ctx*/,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  /*auxiliaryData*/
        )
        internal
    {
        // Read in the deposit
        Deposit memory deposit;
        readTx(data, offset, deposit);
        if (deposit.amount == 0) {
            return;
        }

        // depositType 0: deposit by exchange::deposit()
        // depositType 1: deposit by transfer tokens to DepositContract directly 
        if(deposit.depositType == 0) { 
            // Process the deposit
            ExchangeData.Deposit memory pendingDeposit = S.pendingDeposits[deposit.to][deposit.tokenID];
            // Make sure the deposit was actually done
            require(pendingDeposit.timestamp > 0, "DEPOSIT_DOESNT_EXIST");

            // Processing partial amounts of the deposited amount is allowed.
            // This is done to ensure the user can do multiple deposits after each other
            // without invalidating work done by the exchange owner for previous deposit amounts.

            require(pendingDeposit.amount >= deposit.amount, "INVALID_AMOUNT");
            pendingDeposit.amount = pendingDeposit.amount.sub(deposit.amount);

            // If the deposit was fully consumed, reset it so the storage is freed up
            // and the owner receives a gas refund.
            if (pendingDeposit.amount == 0) {
                delete S.pendingDeposits[deposit.to][deposit.tokenID];
            } else {
                S.pendingDeposits[deposit.to][deposit.tokenID] = pendingDeposit;
            }

        }else if(deposit.depositType == 1) {
            uint32 tokenId = deposit.tokenID;
            uint256 unconfirmedBalance;

            if (tokenId == 0) {
                unconfirmedBalance = address(S.depositContract).balance.sub(S.tokenIdToDepositBalance[tokenId]);
            } else {
                address token = S.tokenIdToToken[tokenId];
                unconfirmedBalance = ERC20(token).balanceOf(address(S.depositContract)).sub(S.tokenIdToDepositBalance[tokenId]);
            }

            require(unconfirmedBalance >= deposit.amount, "INVALID_DIRECT_DEPOSIT_AMOUNT");

            S.tokenIdToDepositBalance[deposit.tokenID] = S.tokenIdToDepositBalance[deposit.tokenID].add(deposit.amount);
        }else{
            revert("INVALID_DEPOSIT_TYPE");
        }
    }

    function readTx(
        bytes   memory data,
        uint           offset,
        Deposit memory deposit
        )
        internal
        pure
    {
        uint _offset = offset;

        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.

        deposit.depositType = data.toUint8Unsafe(_offset);
        _offset += 1;
        deposit.to = data.toAddressUnsafe(_offset);
        _offset += 20;
        deposit.toAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        deposit.tokenID = data.toUint32Unsafe(_offset);
        _offset += 4;
        deposit.amount = data.toUint248Unsafe(_offset);
        _offset += 31;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/EIP712.sol";
import "../../../lib/FloatUtil.sol";
import "../../../lib/MathUint.sol";
import "../../../lib/SignatureUtil.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";
import "../libexchange/ExchangeMode.sol";
import "../libexchange/ExchangeSignatures.sol";
import "../libexchange/ExchangeWithdrawals.sol";


/// @title WithdrawTransaction
/// @author Brecht Devos - <[email protected]>
/// @dev The following 4 types of withdrawals are supported:
///      - withdrawType = 0: offchain withdrawals with EdDSA signatures
///      - withdrawType = 1: offchain withdrawals with ECDSA signatures or onchain appprovals
///      - withdrawType = 2: onchain valid forced withdrawals (owner and accountID match), or
///                          offchain operator-initiated withdrawals for protocol fees or for
///                          users in shutdown mode
///      - withdrawType = 3: onchain invalid forced withdrawals (owner and accountID mismatch)
library WithdrawTransaction
{
    using BytesUtil            for bytes;
    using FloatUtil            for uint16;
    using MathUint             for uint;
    using SafeCast             for uint;
    using ExchangeMode         for ExchangeData.State;
    using ExchangeSignatures   for ExchangeData.State;
    using ExchangeWithdrawals  for ExchangeData.State;
    using SignatureUtil        for bytes32;

    bytes32 constant public WITHDRAWAL_TYPEHASH = keccak256(
        "Withdrawal(address owner,uint32 accountID,uint32 tokenID,uint248 amount,uint32 feeTokenID,uint96 maxFee,address to,uint248 minGas,uint32 validUntil,uint32 storageID)"
    );

    struct Withdrawal
    {
        uint    withdrawalType;
        address from;
        uint32  fromAccountID;
        uint32  tokenID;
        uint248 amount;
        uint32  feeTokenID;
        uint96  maxFee;
        uint96  fee;
        address to;
        uint248 minGas;
        uint32  validUntil;
        uint32  storageID;
        bytes20 onchainDataHash;
    }

    // Auxiliary data for each withdrawal
    struct WithdrawalAuxiliaryData
    {
        bool  storeRecipient;
        uint  gasLimit;
        bytes signature;

        uint248 minGas;
        address to;
        uint96  maxFee;
        uint32  validUntil;
        uint248 amount;
    }

    function process(
        ExchangeData.State        storage S,
        ExchangeData.BlockContext memory  ctx,
        bytes                     memory  data,
        uint                              offset,
        bytes                     memory  auxiliaryData
        )
        internal
    {
        Withdrawal memory withdrawal;
        readTx(data, offset, withdrawal);
        WithdrawalAuxiliaryData memory auxData = abi.decode(auxiliaryData, (WithdrawalAuxiliaryData));

        // Validate the withdrawal data not directly part of the DA
        bytes20 onchainDataHash = hashOnchainData(
            auxData.minGas,
            auxData.to,
            auxData.amount
        );

        // Only the 20 MSB are used, which is still 80-bit of security, which is more
        // than enough, especially when combined with validUntil.
        require(withdrawal.onchainDataHash == onchainDataHash, "INVALID_WITHDRAWAL_DATA");

        // Fill in withdrawal data missing from DA
        withdrawal.to = auxData.to;
        withdrawal.minGas = auxData.minGas;
        withdrawal.maxFee = auxData.maxFee;
        withdrawal.validUntil = auxData.validUntil;
        withdrawal.amount = auxData.amount;

        // If the account has an owner, don't allow withdrawing to the zero address
        // (which will be the protocol fee vault contract).
        require(withdrawal.from == address(0) || withdrawal.to != address(0), "INVALID_WITHDRAWAL_RECIPIENT");

        if (withdrawal.withdrawalType == 0) {
            // Signature checked offchain, nothing to do
        } else if (withdrawal.withdrawalType == 1) {
            // Validate
            require(ctx.timestamp < withdrawal.validUntil, "WITHDRAWAL_EXPIRED");
            require(withdrawal.fee <= withdrawal.maxFee, "WITHDRAWAL_FEE_TOO_HIGH");

            // Check appproval onchain
            // Calculate the tx hash
            bytes32 txHash = hashTx(ctx.DOMAIN_SEPARATOR, withdrawal);
            // Check onchain authorization
            S.requireAuthorizedTx(withdrawal.from, auxData.signature, txHash);
        } else if (withdrawal.withdrawalType == 2 || withdrawal.withdrawalType == 3) {
            // Forced withdrawals cannot make use of certain features because the
            // necessary data is not authorized by the account owner.
            // For protocol fee withdrawals, `owner` and `to` are both address(0).
            require(withdrawal.from == withdrawal.to, "INVALID_WITHDRAWAL_ADDRESS");

            // Forced withdrawal fees are charged when the request is submitted.
            require(withdrawal.fee == 0, "FEE_NOT_ZERO");

            ExchangeData.ForcedWithdrawal memory forcedWithdrawal =
                S.pendingForcedWithdrawals[withdrawal.fromAccountID][withdrawal.tokenID];

            if (forcedWithdrawal.timestamp != 0) {
                if (withdrawal.withdrawalType == 2) {
                    require(withdrawal.from == forcedWithdrawal.owner, "INCONSISENT_OWNER");
                } else { //withdrawal.withdrawalType == 3
                    require(withdrawal.from != forcedWithdrawal.owner, "INCONSISENT_OWNER");
                    require(withdrawal.amount == 0, "UNAUTHORIZED_WITHDRAWAL");
                }

                // delete the withdrawal request and free a slot
                delete S.pendingForcedWithdrawals[withdrawal.fromAccountID][withdrawal.tokenID];
                S.numPendingForcedTransactions--;
            } else {
                // Allow the owner to submit full withdrawals without authorization
                // - when in shutdown mode
                // - to withdraw protocol fees
                require(
                    withdrawal.fromAccountID == ExchangeData.ACCOUNTID_PROTOCOLFEE ||
                    S.isShutdown(),
                    "FULL_WITHDRAWAL_UNAUTHORIZED"
                );
            }
        } else {
            revert("INVALID_WITHDRAWAL_TYPE");
        }

        // Check if there is a withdrawal recipient
        address recipient = S.withdrawalRecipient[withdrawal.from][withdrawal.to][withdrawal.tokenID][withdrawal.amount][withdrawal.storageID];
        if (recipient != address(0)) {
            // Set the new recipient address
            withdrawal.to = recipient;
            // Allow any amount of gas to be used on this withdrawal (which allows the transfer to be skipped)
            withdrawal.minGas = 0;

            // Do NOT delete the recipient to prevent replay attack
            // delete S.withdrawalRecipient[withdrawal.owner][withdrawal.to][withdrawal.tokenID][withdrawal.amount][withdrawal.storageID];
        } else if (auxData.storeRecipient) {
            // Store the destination address to mark the withdrawal as done
            require(withdrawal.to != address(0), "INVALID_DESTINATION_ADDRESS");
            S.withdrawalRecipient[withdrawal.from][withdrawal.to][withdrawal.tokenID][withdrawal.amount][withdrawal.storageID] = withdrawal.to;
        }

        // Validate gas provided
        require(auxData.gasLimit >= withdrawal.minGas, "OUT_OF_GAS_FOR_WITHDRAWAL");

        // Try to transfer the tokens with the provided gas limit
        S.distributeWithdrawal(
            withdrawal.from,
            withdrawal.to,
            withdrawal.tokenID,
            withdrawal.amount,
            auxData.gasLimit
        );
    }

    function readTx(
        bytes      memory data,
        uint              offset,
        Withdrawal memory withdrawal
        )
        internal
        pure
    {
        uint _offset = offset;

        // Extract the transfer data
        // We don't use abi.decode for this because of the large amount of zero-padding
        // bytes the circuit would also have to hash.
        withdrawal.withdrawalType = data.toUint8Unsafe(_offset);
        _offset += 1;
        withdrawal.from = data.toAddressUnsafe(_offset);
        _offset += 20;
        withdrawal.fromAccountID = data.toUint32Unsafe(_offset);
        _offset += 4;
        withdrawal.tokenID = data.toUint32Unsafe(_offset);
        _offset += 4;
        withdrawal.feeTokenID = data.toUint32Unsafe(_offset);
        _offset += 4;
        withdrawal.fee = data.toUint16Unsafe(_offset).decodeFloat16();
        _offset += 2;
        withdrawal.storageID = data.toUint32Unsafe(_offset);
        _offset += 4;
        withdrawal.onchainDataHash = data.toBytes20Unsafe(_offset);
        _offset += 20;
    }

    function hashTx(
        bytes32 DOMAIN_SEPARATOR,
        Withdrawal memory withdrawal
        )
        private
        pure
        returns (bytes32)
    {
        return EIP712.hashPacked(
            DOMAIN_SEPARATOR,
            keccak256(
                abi.encode(
                    WITHDRAWAL_TYPEHASH,
                    withdrawal.from,
                    withdrawal.fromAccountID,
                    withdrawal.tokenID,
                    withdrawal.amount,
                    withdrawal.feeTokenID,
                    withdrawal.maxFee,
                    withdrawal.to,
                    withdrawal.minGas,
                    withdrawal.validUntil,
                    withdrawal.storageID
                )
            )
        );
    }

    function hashOnchainData(
        uint248 minGas,
        address to,
        uint248 amount
        )
        private
        view
        returns (bytes20)
    {
        // Only the 20 MSB are used, which is still 80-bit of security, which is more
        // than enough, especially when combined with validUntil.
        return bytes20(
            abi.encodePacked(
                minGas,
                to,
                amount
            ).fastSHA256()
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/AddressUtil.sol";
import "../../../lib/MathUint248.sol";
import "../../../thirdparty/BytesUtil.sol";
import "../../iface/ExchangeData.sol";
import "./ExchangeBalances.sol";
import "./ExchangeMode.sol";
import "./ExchangeTokens.sol";


/// @title ExchangeWithdrawals.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
library ExchangeWithdrawals
{
    enum WithdrawalCategory
    {
        DISTRIBUTION,
        FROM_MERKLE_TREE,
        FROM_DEPOSIT_REQUEST,
        FROM_APPROVED_WITHDRAWAL
    }

    using AddressUtil       for address;
    using AddressUtil       for address payable;
    using BytesUtil         for bytes;
    using MathUint          for uint;
    using MathUint248       for uint248;
    using ExchangeBalances  for ExchangeData.State;
    using ExchangeMode      for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;

    event ForcedWithdrawalRequested(
        address owner,
        address token,
        uint32  accountID
    );

    event WithdrawalCompleted(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    event WithdrawalFailed(
        uint8   category,
        address from,
        address to,
        address token,
        uint    amount
    );

    function forceWithdraw(
        ExchangeData.State storage S,
        address owner,
        address token,
        uint32  accountID
        )
        public
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        // Limit the amount of pending forced withdrawals so that the owner cannot be overwhelmed.
        require(S.getNumAvailableForcedSlots() > 0, "TOO_MANY_REQUESTS_OPEN");
        require(accountID < ExchangeData.MAX_NUM_ACCOUNTS, "INVALID_ACCOUNTID");
        require(accountID != 0, "INVALID_ACCOUNTID");

        uint32 tokenID = S.getTokenID(token);

        // A user needs to pay a fixed ETH withdrawal fee, set by the protocol.
        uint withdrawalFeeETH = S.loopring.forcedWithdrawalFee();

        // Check ETH value sent, can be larger than the expected withdraw fee
        require(msg.value >= withdrawalFeeETH, "INSUFFICIENT_WITHDRAW_FEE");

        // Send surplus of ETH back to the sender
        uint feeSurplus = msg.value.sub(withdrawalFeeETH);
        if (feeSurplus > 0) {
            msg.sender.sendETHAndVerify(feeSurplus, gasleft());
        }

        // There can only be a single forced withdrawal per (account, token) pair.
        require(
            S.pendingForcedWithdrawals[accountID][tokenID].timestamp == 0,
            "WITHDRAWAL_ALREADY_PENDING"
        );

        // Store the forced withdrawal request data
        S.pendingForcedWithdrawals[accountID][tokenID] = ExchangeData.ForcedWithdrawal({
            owner: owner,
            timestamp: uint64(block.timestamp)
        });

        // Increment the number of pending forced transactions so we can keep count.
        S.numPendingForcedTransactions++;

        emit ForcedWithdrawalRequested(
            owner,
            token,
            accountID
        );
    }

    // We alow anyone to withdraw these funds for the account owner
    function withdrawFromMerkleTree(
        ExchangeData.State       storage S,
        ExchangeData.MerkleProof calldata merkleProof
        )
        public
    {
        require(S.isInWithdrawalMode(), "NOT_IN_WITHDRAW_MODE");

        address owner = merkleProof.accountLeaf.owner;
        uint32 accountID = merkleProof.accountLeaf.accountID;
        uint32 tokenID = merkleProof.balanceLeaf.tokenID;
        uint248 balance = merkleProof.balanceLeaf.balance;

        // Make sure the funds aren't withdrawn already.
        require(S.withdrawnInWithdrawMode[accountID][tokenID] == false, "WITHDRAWN_ALREADY");

        // Verify that the provided Merkle tree data is valid by using the Merkle proof.
        ExchangeBalances.verifyAccountBalance(
            uint(S.merkleAssetRoot),
            merkleProof
        );

        // Make sure the balance can only be withdrawn once
        S.withdrawnInWithdrawMode[accountID][tokenID] = true;

        // Transfer the tokens to the account owner
        transferTokens(
            S,
            uint8(WithdrawalCategory.FROM_MERKLE_TREE),
            owner,
            owner,
            tokenID,
            balance,
            gasleft(),
            false
        );
    }

    function withdrawFromDepositRequest(
        ExchangeData.State storage S,
        address owner,
        address token
        )
        public
    {
        uint32 tokenID = S.getTokenID(token);
        ExchangeData.Deposit storage deposit = S.pendingDeposits[owner][tokenID];
        require(deposit.timestamp != 0, "DEPOSIT_NOT_WITHDRAWABLE_YET");

        // Check if the deposit has indeed exceeded the time limit of if the exchange is in withdrawal mode
        require(
            block.timestamp >= deposit.timestamp + S.maxAgeDepositUntilWithdrawable ||
            S.isInWithdrawalMode(),
            "DEPOSIT_NOT_WITHDRAWABLE_YET"
        );

        uint248 amount = deposit.amount;

        // Reset the deposit request
        delete S.pendingDeposits[owner][tokenID];

        // Transfer the tokens
        transferTokens(
            S,
            uint8(WithdrawalCategory.FROM_DEPOSIT_REQUEST),
            owner,
            owner,
            tokenID,
            amount,
            gasleft(),
            false
        );
    }

    function withdrawFromApprovedWithdrawals(
        ExchangeData.State storage S,
        address[] memory owners,
        address[] memory tokens
        )
        public
    {
        require(owners.length == tokens.length, "INVALID_INPUT_DATA");
        for (uint i = 0; i < owners.length; i++) {
            address owner = owners[i];
            uint32 tokenID = S.getTokenID(tokens[i]);
            uint248 amount = S.amountWithdrawable[owner][tokenID];

            // Make sure this amount can't be withdrawn again
            delete S.amountWithdrawable[owner][tokenID];

            // Transfer the tokens to the owner
            transferTokens(
                S,
                uint8(WithdrawalCategory.FROM_APPROVED_WITHDRAWAL),
                owner,
                owner,
                tokenID,
                amount,
                gasleft(),
                false
            );
        }
    }

    function distributeWithdrawal(
        ExchangeData.State storage S,
        address from,
        address to,
        uint32  tokenID,
        uint248    amount,
        uint    gasLimit
        )
        public
    {
        // Try to transfer the tokens
        bool success = transferTokens(
            S,
            uint8(WithdrawalCategory.DISTRIBUTION),
            from,
            to,
            tokenID,
            amount,
            gasLimit,
            true
        );
        // If the transfer was successful there's nothing left to do.
        // However, if the transfer failed the tokens are still in the contract and can be
        // withdrawn later to `to` by anyone by using `withdrawFromApprovedWithdrawal.
        if (!success) {
            S.amountWithdrawable[to][tokenID] = S.amountWithdrawable[to][tokenID].add(amount);
        }
    }

    // == Internal and Private Functions ==

    // If allowFailure is true the transfer can fail because of a transfer error or
    // because the transfer uses more than `gasLimit` gas. The function
    // will return true when successful, false otherwise.
    // If allowFailure is false the transfer is guaranteed to succeed using
    // as much gas as needed, otherwise it throws. The function always returns true.
    function transferTokens(
        ExchangeData.State storage S,
        uint8   category,
        address from,
        address to,
        uint32  tokenID,
        uint248 amount,
        uint    gasLimit,
        bool    allowFailure
        )
        private
        returns (bool success)
    {
        // Redirect withdrawals to address(0) to the protocol fee vault
        if (to == address(0)) {
            to = S.loopring.protocolFeeVault();
        }
        address token = S.getTokenAddress(tokenID);

        // Transfer the tokens from the deposit contract to the owner
        if (gasLimit > 0) {
            try S.depositContract.withdraw{gas: gasLimit}(from, to, token, amount) {
                success = true;
            } catch {
                success = false;
            }
        } else {
            success = false;
        }

        require(allowFailure || success, "TRANSFER_FAILURE");

        if (success) {
            emit WithdrawalCompleted(category, from, to, token, amount);

            // Keep track of when the protocol fees were last withdrawn
            // (only done to make this data easier available).
            if (from == address(0)) {
                S.protocolFeeLastWithdrawnTime[token] = block.timestamp;
            }

            S.tokenIdToDepositBalance[tokenID] = S.tokenIdToDepositBalance[tokenID].sub(amount);

        } else {
            emit WithdrawalFailed(category, from, to, token, amount);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/ERC20SafeTransfer.sol";
import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "./ExchangeMode.sol";

/// @title ExchangeTokens.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeTokens
{
    using MathUint          for uint;
    using ERC20SafeTransfer for address;
    using ExchangeMode      for ExchangeData.State;

    event TokenRegistered(
        address token,
        uint32  tokenId
    );

    function getTokenAddress(
        ExchangeData.State storage S,
        uint32 tokenID
        )
        public
        view
        returns (address)
    {
        require(tokenID < S.normalTokens.length.add(ExchangeData.MAX_NUM_RESERVED_TOKENS), "INVALID_TOKEN_ID");

        if (tokenID < ExchangeData.MAX_NUM_RESERVED_TOKENS) {
            return S.reservedTokens[tokenID].token;
        }

        return S.normalTokens[tokenID - ExchangeData.MAX_NUM_RESERVED_TOKENS].token;
    }

    function registerToken(
        ExchangeData.State storage S,
        address tokenAddress,
        bool isOwnerRegister
        )
        public
        returns (uint32 tokenID)
    {
        require(!S.isInWithdrawalMode(), "INVALID_MODE");
        require(S.tokenToTokenId[tokenAddress] == 0, "TOKEN_ALREADY_EXIST");

        if (isOwnerRegister) {
            require(S.reservedTokens.length < ExchangeData.MAX_NUM_RESERVED_TOKENS, "TOKEN_REGISTRY_FULL");
        } else {
            require(S.normalTokens.length < ExchangeData.MAX_NUM_NORMAL_TOKENS, "TOKEN_REGISTRY_FULL");
        }

        // Check if the deposit contract supports the new token
        if (S.depositContract != IDepositContract(0)) {
            require(S.depositContract.isTokenSupported(tokenAddress), "UNSUPPORTED_TOKEN");
        }

        // Assign a tokenID and store the token
        ExchangeData.Token memory token = ExchangeData.Token(tokenAddress);

        if (isOwnerRegister) {
            tokenID = uint32(S.reservedTokens.length);
            S.reservedTokens.push(token);
        } else {
            tokenID = uint32(S.normalTokens.length.add(ExchangeData.MAX_NUM_RESERVED_TOKENS));
            S.normalTokens.push(token);
        }
        S.tokenToTokenId[tokenAddress] = tokenID + 1;
        S.tokenIdToToken[tokenID] = tokenAddress;

        S.tokenIdToDepositBalance[tokenID] = 0;

        emit TokenRegistered(tokenAddress, tokenID);
    }

    function getTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        internal  // inline call
        view
        returns (uint32 tokenID)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        require(tokenID != 0, "TOKEN_NOT_FOUND");
        tokenID = tokenID - 1;
    }

    function findTokenID(
        ExchangeData.State storage S,
        address tokenAddress
        )
        internal  // inline call
        view
        returns (uint32 tokenID, bool found)
    {
        tokenID = S.tokenToTokenId[tokenAddress];
        if(tokenID == 0) {
            return (0, false);
        }
        tokenID = tokenID - 1;
        found = true;
    }

}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/AddressUtil.sol";
import "../../../lib/MathUint248.sol";
import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "./ExchangeMode.sol";
import "./ExchangeTokens.sol";


/// @title ExchangeDeposits.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeDeposits
{
    using AddressUtil       for address payable;
    using MathUint248       for uint248;
    using MathUint          for uint;
    using ExchangeMode      for ExchangeData.State;
    using ExchangeTokens    for ExchangeData.State;

    event DepositRequested(
        address from,
        address to,
        address token,
        uint32  tokenId,
        uint248  amount
    );

    event DepositFee(
        uint256  amount
    );

    function deposit(
        ExchangeData.State storage S,
        address from,
        address to,
        address tokenAddress,
        uint248  amount,                 // can be zero
        bytes   memory extraData
        )
        internal  // inline call
    {
        require(to != address(0), "ZERO_ADDRESS");

        // Deposits are still possible when the exchange is being shutdown, or even in withdrawal mode.
        // This is fine because the user can easily withdraw the deposited amounts again.
        // We don't want to make all deposits more expensive just to stop that from happening.

        (uint32 tokenID, bool tokenFound) = S.findTokenID(tokenAddress);
        if(!tokenFound) {
            tokenID = S.registerToken(tokenAddress, false);
        }

        if (tokenID == 0 && amount == 0) {
            require(msg.value == 0, "INVALID_ETH_DEPOSIT");
        }

        // A user may need to pay a fixed ETH deposit fee, set by the protocol.
        uint256 depositFeeETH = 0;
        if (needChargeDepositFee(S)) {
            depositFeeETH = S.depositState.depositFee;
            emit DepositFee(depositFeeETH);
        }

        // Check ETH value sent
        require(msg.value >= depositFeeETH, "INSUFFICIENT_DEPOSIT_FEE");

        uint256 ethAmountToDeposit = msg.value - depositFeeETH;

        // Transfer the tokens to this contract
        uint248 amountDeposited = S.depositContract.deposit{value: ethAmountToDeposit}(
            from,
            tokenAddress,
            amount,
            extraData
        );

        // Add the amount to the deposit request and reset the time the operator has to process it
        ExchangeData.Deposit memory _deposit = S.pendingDeposits[to][tokenID];
        _deposit.timestamp = uint64(block.timestamp);
        _deposit.amount = _deposit.amount.add(amountDeposited);
        S.pendingDeposits[to][tokenID] = _deposit;


        S.tokenIdToDepositBalance[tokenID] = S.tokenIdToDepositBalance[tokenID].add(amountDeposited);

        emit DepositRequested(
            from,
            to,
            tokenAddress,
            tokenID,
            amountDeposited
        );
    }

    function setDepositParams(
        ExchangeData.State storage S,
        uint256 freeDepositMax,
        uint256 freeDepositRemained,
        uint256 freeSlotPerBlock,
        uint256 depositFee
    ) internal {
        S.depositState.freeDepositMax = freeDepositMax;
        S.depositState.freeDepositRemained = freeDepositRemained;
        S.depositState.freeSlotPerBlock = freeSlotPerBlock;
        S.depositState.depositFee = depositFee;
    }

    function needChargeDepositFee(ExchangeData.State storage S)
        private
        returns (bool)
    {
        bool needCharge = false;

        // S.depositState.freeDepositRemained + (block.number - S.depositState.lastDepositBlockNum) * S.depositState.freeSlotPerBlock;
        uint256 freeDepositRemained = S.depositState.freeDepositRemained.add(
            (block.number.sub(S.depositState.lastDepositBlockNum)).mul(S.depositState.freeSlotPerBlock)
        );
        
        if (freeDepositRemained > S.depositState.freeDepositMax) {
            freeDepositRemained = S.depositState.freeDepositMax;
        }

        if (freeDepositRemained > 0) {
            freeDepositRemained -= 1;
        } else {
            needCharge = true;
        }

        S.depositState.freeDepositRemained = freeDepositRemained;
        S.depositState.lastDepositBlockNum = block.number;

        return needCharge;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "../../../lib/MathUint.sol";
import "../../iface/ExchangeData.sol";
import "../../iface/IAgentRegistry.sol";
import "../../iface/IBlockVerifier.sol";
import "../../iface/ILoopringV3.sol";
import "./ExchangeTokens.sol";


/// @title ExchangeGenesis.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeGenesis
{
    using ExchangeTokens    for ExchangeData.State;

    event ExchangeGenesisBlockInitialized(
        address loopringAddr,
        bytes32 genesisMerkleRoot,
        bytes32 genesisMerkleAssetRoot,
        bytes32 domainSeparator
    );

    function initializeGenesisBlock(
        ExchangeData.State storage S,
        address _loopringAddr,
        bytes32 _genesisMerkleRoot,
        bytes32 _genesisMerkleAssetRoot,
        bytes32 _domainSeparator
        )
        public
    {
        require(address(0) != _loopringAddr, "INVALID_LOOPRING_ADDRESS");
        require(_genesisMerkleRoot != 0, "INVALID_GENESIS_MERKLE_ROOT");
        require(_genesisMerkleAssetRoot != 0, "INVALID_GENESIS_MERKLE_ASSET_ROOT");

        S.maxAgeDepositUntilWithdrawable = ExchangeData.MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND;
        S.DOMAIN_SEPARATOR = _domainSeparator;

        ILoopringV3 loopring = ILoopringV3(_loopringAddr);
        S.loopring = loopring;

        S.blockVerifier = IBlockVerifier(loopring.blockVerifierAddress());

        S.merkleRoot = _genesisMerkleRoot;
        S.merkleAssetRoot = _genesisMerkleAssetRoot;
        S.blocks[0] = ExchangeData.BlockInfo(uint32(block.timestamp), bytes28(0));
        S.numBlocks = 1;

        // Get the protocol fees for this exchange
        S.protocolFeeData.syncedAt = uint32(0);

        S.protocolFeeData.protocolFeeBips = S.loopring.protocolFeeBips();
        S.protocolFeeData.previousProtocolFeeBips = S.protocolFeeData.protocolFeeBips;

        S.protocolFeeData.nextProtocolFeeBips = S.protocolFeeData.protocolFeeBips;
        S.protocolFeeData.executeTimeOfNextProtocolFeeBips = uint32(0);

        // Call these after the main state has been set up
        S.registerToken(address(0), true);
        S.registerToken(loopring.lrcAddress(), true);

        emit ExchangeGenesisBlockInitialized(_loopringAddr, _genesisMerkleRoot, _genesisMerkleAssetRoot, _domainSeparator);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "../../lib/ReentrancyGuard.sol";
import "../../thirdparty/verifiers/BatchVerifier.sol";
import "../../thirdparty/verifiers/Verifier.sol";
import "../iface/ExchangeData.sol";
import "../iface/IBlockVerifier.sol";
import "./VerificationKeys.sol";

/// @title An Implementation of IBlockVerifier.
/// @author Brecht Devos - <[email protected]>
contract BlockVerifier is ReentrancyGuard, IBlockVerifier
{
    struct Circuit
    {
        bool registered;
        bool enabled;
        uint[18] verificationKey;
    }

    mapping (uint8 => mapping (uint16 => mapping (uint8 => Circuit))) public circuits;

    constructor() Claimable() {}

    function registerCircuit(
        uint8    blockType,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        Circuit storage circuit = circuits[blockType][blockSize][blockVersion];

        require(circuit.registered == false, "ALREADY_REGISTERED");

        // Store the verification key on-chain.
        for (uint i = 0; i < 18; i++) {
            circuit.verificationKey[i] = vk[i];
        }
        circuit.registered = true;
        circuit.enabled = true;

        emit CircuitRegistered(
            blockType,
            blockSize,
            blockVersion
        );
    }

    function disableCircuit(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        Circuit storage circuit = circuits[blockType][blockSize][blockVersion];
        require(circuit.registered == true, "NOT_REGISTERED");
        require(circuit.enabled == true, "ALREADY_DISABLED");

        // Disable the circuit
        circuit.enabled = false;

        emit CircuitDisabled(
            blockType,
            blockSize,
            blockVersion
        );
    }

    function verifyProofs(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        override
        view
        returns (bool)
    {
        // First try to find the verification key in the hard coded list
        (uint[14] memory _vk, uint[4] memory _vk_gammaABC, bool found) = VerificationKeys.getKey(
            blockType,
            blockSize,
            blockVersion
        );
        if (!found) {
            Circuit storage circuit = circuits[blockType][blockSize][blockVersion];
            require(circuit.registered == true, "NOT_REGISTERED");
            require(circuit.enabled == true, "NOT_ENABLED");

            // Load the verification key from storage.
            uint[18] storage vk = circuit.verificationKey;
            _vk = [
                vk[0], vk[1], vk[2], vk[3], vk[4], vk[5], vk[6],
                vk[7], vk[8], vk[9], vk[10], vk[11], vk[12], vk[13]
            ];
            _vk_gammaABC = [vk[14], vk[15], vk[16], vk[17]];
        }

        // Verify the proof.
        // Batched proof verification has a fixed overhead which makes it more
        // expensive to verify a single proof compared to the non-batched code
        // This is why we don't use the batched verification code here when only
        // a single proof needs to be verified.
        if (publicInputs.length == 1) {
            return Verifier.Verify(_vk, _vk_gammaABC, proofs, publicInputs);
        } else {
            return BatchVerifier.BatchVerify(
                _vk,
                _vk_gammaABC,
                proofs,
                publicInputs,
                publicInputs.length
            );
        }
    }

    function isCircuitRegistered(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        override
        view
        returns (bool)
    {
        return circuits[blockType][blockSize][blockVersion].registered;
    }

    function isCircuitEnabled(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        override
        view
        returns (bool)
    {
        return circuits[blockType][blockSize][blockVersion].enabled;
    }

    function getVerificationKey(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        public
        view
        returns (uint[18] memory)
    {
        return circuits[blockType][blockSize][blockVersion].verificationKey;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../lib/AddressUtil.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../lib/ReentrancyGuard.sol";
import "../iface/IExchangeV3.sol";
import "../iface/ILoopringV3.sol";


/// @title LoopringV3
/// @dev This contract does NOT support proxy.
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
contract LoopringV3 is ILoopringV3, ReentrancyGuard
{
    using AddressUtil       for address payable;
    using MathUint          for uint;
    using ERC20SafeTransfer for address;

    address public immutable override lrcAddress;

    // -- Constructor --
    constructor(
        address _lrcAddress,
        address payable _protocolFeeVault,
        address _blockVerifierAddress
        )
        Claimable()
    {
        require(address(0) != _lrcAddress, "ZERO_ADDRESS");

        lrcAddress = _lrcAddress;
        blockVerifierAddress = _blockVerifierAddress;

        protocolFeeBips = ExchangeData.DEFAULT_PROTOCOL_FEE_BIPS;

        updateSettingsInternal(_protocolFeeVault, 0);
    }

    // == Public Functions ==
    function updateSettings(
        address payable _protocolFeeVault,
        uint    _forcedWithdrawalFee
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        updateSettingsInternal(
            _protocolFeeVault,
            _forcedWithdrawalFee
        );
    }

    function updateProtocolFeeSettings(
        uint8 _protocolFeeBips
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        require(_protocolFeeBips <= ExchangeData.MAX_PROTOCOL_FEE_BIPS, "INVALID_PROTOCOL_FEE_BIPS");

        protocolFeeBips = _protocolFeeBips;

        emit SettingsUpdated(block.timestamp);
    }

    function getExchangeStake(
        address exchangeAddr
        )
        external
        override
        view
        returns (uint)
    {
        return exchangeStake[exchangeAddr];
    }

    function burnExchangeStake(
        uint amount
        )
        external
        override
        nonReentrant
        returns (uint burnedLRC)
    {
        require(amount > 0, "ZERO_VALUE");

        burnedLRC = exchangeStake[msg.sender];

        if (amount < burnedLRC) {
            burnedLRC = amount;
        }
        if (burnedLRC > 0) {
            lrcAddress.safeTransferAndVerify(protocolFeeVault, burnedLRC);
            exchangeStake[msg.sender] = exchangeStake[msg.sender].sub(burnedLRC);
            totalStake = totalStake.sub(burnedLRC);
        }
        emit ExchangeStakeBurned(msg.sender, burnedLRC);
    }

    function depositExchangeStake(
        address exchangeAddr,
        uint    amountLRC
        )
        external
        override
        nonReentrant
        returns (uint stakedLRC)
    {
        require(amountLRC > 0, "ZERO_VALUE");

        lrcAddress.safeTransferFromAndVerify(msg.sender, address(this), amountLRC);

        stakedLRC = exchangeStake[exchangeAddr].add(amountLRC);
        exchangeStake[exchangeAddr] = stakedLRC;
        totalStake = totalStake.add(amountLRC);

        emit ExchangeStakeDeposited(exchangeAddr, amountLRC);
    }

    function withdrawExchangeStake(
        address recipient,
        uint    requestedAmount
        )
        external
        override
        nonReentrant
        returns (uint amountLRC)
    {
        require(requestedAmount > 0, "ZERO_VALUE");

        uint stake = exchangeStake[msg.sender];
        amountLRC = (stake > requestedAmount) ? requestedAmount : stake;

        if (amountLRC > 0) {
            lrcAddress.safeTransferAndVerify(recipient, amountLRC);
            exchangeStake[msg.sender] = exchangeStake[msg.sender].sub(amountLRC);
            totalStake = totalStake.sub(amountLRC);
        }

        emit ExchangeStakeWithdrawn(msg.sender, amountLRC);
    }

    function getProtocolFeeValues()
        external
        override
        view
        returns (
            uint8 feeBips
        )
    {
        return protocolFeeBips;
    }

    // == Internal Functions ==
    function updateSettingsInternal(
        address payable  _protocolFeeVault,
        uint    _forcedWithdrawalFee
        )
        private
    {
        require(address(0) != _protocolFeeVault, "ZERO_ADDRESS");
        require(_forcedWithdrawalFee <= ExchangeData.MAX_FORCED_WITHDRAWAL_FEE, "INVALID_FORCED_WITHDRAWAL_FEE");

        protocolFeeVault = _protocolFeeVault;
        forcedWithdrawalFee = _forcedWithdrawalFee;

        emit SettingsUpdated(block.timestamp);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../lib/AddressUtil.sol";
import "../../lib/Claimable.sol";
import "../../lib/ERC20.sol";
import "../../lib/ERC20SafeTransfer.sol";
import "../../lib/MathUint.sol";
import "../../thirdparty/SafeCast.sol";
import "../iface/IDepositContract.sol";


/// @title DefaultDepositContract
/// @dev   Default implementation of IDepositContract that just stores
///        all funds without doing anything with them.
///
///        Should be able to work with proxy contracts so the contract
///        can be updated easily (but with great caution and transparency!)
///        when necessary.
///
/// @author Brecht Devos - <[email protected]>
contract DefaultDepositContract is IDepositContract, Claimable
{
    using AddressUtil       for address;
    using ERC20SafeTransfer for address;
    using MathUint          for uint;
    using SafeCast          for uint;

    address public exchange;

    mapping (address => bool) private needCheckBalance;

    modifier onlyExchange()
    {
        require(msg.sender == exchange, "UNAUTHORIZED");
        _;
    }

    modifier ifNotZero(uint amount)
    {
        if (amount == 0) return;
        else  _;
    }

    event CheckBalance(
        address indexed token,
        bool            checkBalance
    );

    receive() external payable { }

    function initialize(
        address _exchange
        )
        external
    {
        require(
            exchange == address(0) && _exchange != address(0),
            "INVALID_EXCHANGE"
        );
        owner = msg.sender;
        exchange = _exchange;
    }

    function setCheckBalance(
        address token,
        bool    checkBalance
        )
        external
        onlyOwner
    {
        require(needCheckBalance[token] != checkBalance, "INVALID_VALUE");

        needCheckBalance[token] = checkBalance;
        emit CheckBalance(token, checkBalance);
    }

    function isTokenSupported(address /*token*/)
        external
        override
        pure
        returns (bool)
    {
        return true;
    }

    function deposit(
        address from,
        address token,
        uint248  amount, // 0-value supported
        bytes   calldata /*extraData*/
        )
        external
        override
        payable
        onlyExchange
        returns (uint248 amountReceived)
    {
        uint ethToReturn = 0;

        if (isETHInternal(token)) {
            require(msg.value >= amount, "INVALID_ETH_DEPOSIT");
            amountReceived = amount;
            ethToReturn = msg.value - amount;
        } else {
            // When checkBalance is enabled for a token we check the balance change
            // on the contract instead of counting on transferFrom to transfer exactly
            // the amount of tokens that is specified in the transferFrom call.
            // This is to support non-standard tokens which do custom transfer logic.
            bool checkBalance = needCheckBalance[token];
            uint balanceBefore = checkBalance ? ERC20(token).balanceOf(address(this)) : 0;

            token.safeTransferFromAndVerify(from, address(this), uint(amount));

            uint balanceAfter = checkBalance ? ERC20(token).balanceOf(address(this)) : amount;
            uint diff = balanceAfter.sub(balanceBefore);
            amountReceived = diff.toUint248();

            ethToReturn = msg.value;
        }

        if (ethToReturn > 0) {
            from.sendETHAndVerify(ethToReturn, gasleft());
        }
    }

    function withdraw(
        address /*from*/,
        address to,
        address token,
        uint    amount
        )
        external
        override
        payable
        onlyExchange
        ifNotZero(amount)
    {
        if (isETHInternal(token)) {
            to.sendETHAndVerify(amount, gasleft());
        } else {
            // Try to transfer the amount requested.
            // If this fails try to transfer the remaining balance in this contract.
            // This is to guard against non-standard token behavior where total supply
            // has changed in unexpected ways.
            if (!token.safeTransfer(to, amount)){
                uint amountPaid = ERC20(token).balanceOf(address(this));
                require(amountPaid < amount, "UNEXPECTED");
                token.safeTransferAndVerify(to, amountPaid);
            }
        }
    }

    function transfer(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        override
        payable
        onlyExchange
        ifNotZero(amount)
    {
        token.safeTransferFromAndVerify(from, to, amount);
    }

    function isETH(address addr)
        external
        override
        pure
        returns (bool)
    {
        return isETHInternal(addr);
    }

    // -- private --

    function isETHInternal(address addr)
        private
        pure
        returns (bool)
    {
        return addr == address(0);
    }
}