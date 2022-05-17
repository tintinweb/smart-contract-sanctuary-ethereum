/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

https://github.com/GNSPS/solidity-bytes-utils/

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
*/

/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
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
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(fslot, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory res) {
        if (_length == 0) {
            return hex"";
        }
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        uint256 _totalLen = _start + 20;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Address conversion out of bounds.");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        uint256 _totalLen = _start + 32;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Uint conversion out of bounds.");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function toBytes32(bytes memory _source) internal pure returns (bytes32 result) {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes32 result) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

/** @author https://github.com/gregdhill **/

library Bech32 {
    using BytesLib for bytes;

    bytes constant CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

    function polymod(uint256[] memory values) internal pure returns (uint256) {
        uint32[5] memory GENERATOR = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
        uint256 chk = 1;
        for (uint256 p = 0; p < values.length; p++) {
            uint256 top = chk >> 25;
            chk = ((chk & 0x1ffffff) << 5) ^ values[p];
            for (uint256 i = 0; i < 5; i++) {
                if ((top >> i) & 1 == 1) {
                    chk ^= GENERATOR[i];
                }
            }
        }
        return chk;
    }

    function hrpExpand(uint256[] memory hrp) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](hrp.length + hrp.length + 1);
        for (uint256 p = 0; p < hrp.length; p++) {
            ret[p] = hrp[p] >> 5;
        }
        ret[hrp.length] = 0;
        for (uint256 p = 0; p < hrp.length; p++) {
            ret[p + hrp.length + 1] = hrp[p] & 31;
        }
        return ret;
    }

    function concat(uint256[] memory left, uint256[] memory right) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](left.length + right.length);

        uint256 i = 0;
        for (; i < left.length; i++) {
            ret[i] = left[i];
        }

        uint256 j = 0;
        while (j < right.length) {
            ret[i++] = right[j++];
        }

        return ret;
    }

    function extend(
        uint256[] memory array,
        uint256 val,
        uint256 num
    ) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](array.length + num);

        uint256 i = 0;
        for (; i < array.length; i++) {
            ret[i] = array[i];
        }

        uint256 j = 0;
        while (j < num) {
            ret[i++] = val;
            j++;
        }

        return ret;
    }

    function createChecksum(uint256[] memory hrp, uint256[] memory data) internal pure returns (uint256[] memory) {
        uint256[] memory values = extend(concat(hrpExpand(hrp), data), 0, 6);
        uint256 mod = polymod(values) ^ 1;
        uint256[] memory ret = new uint256[](6);
        for (uint256 p = 0; p < 6; p++) {
            ret[p] = (mod >> (5 * (5 - p))) & 31;
        }
        return ret;
    }

    function encode(uint256[] memory hrp, uint256[] memory data) internal pure returns (bytes memory) {
        uint256[] memory combined = concat(data, createChecksum(hrp, data));
        // TODO: prepend hrp

        bytes memory ret = new bytes(combined.length);
        for (uint256 p = 0; p < combined.length; p++) {
            ret[p] = CHARSET[combined[p]];
        }

        return ret;
    }

    function convert(
        uint256[] memory data,
        uint256 inBits,
        uint256 outBits
    ) internal pure returns (uint256[] memory) {
        uint256 value = 0;
        uint256 bits = 0;
        uint256 maxV = (1 << outBits) - 1;

        uint256[] memory ret = new uint256[](32);
        uint256 j = 0;
        for (uint256 i = 0; i < data.length; ++i) {
            value = (value << inBits) | data[i];
            bits += inBits;

            while (bits >= outBits) {
                bits -= outBits;
                ret[j] = (value >> bits) & maxV;
                j += 1;
            }
        }

        return ret;
    }
}

/** @author https://github.com/witnet/elliptic-curve-solidity **/

library EllipticCurve {
    // Pre-computed constant for 2 ** 255
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    /// @dev Modular exponentiation, b^e % _PP.
    /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
    /// @param _base base
    /// @param _exp exponent
    /// @return r such that r = b**e (mod _PP)
    function expMod(
        uint256 _base,
        uint256 _exp
    ) internal pure returns (uint256) {
        require(PP != 0, "Modulus is zero");

        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = U255_MAX_PLUS_1;
        assembly {
            for {

            } gt(bit, 0) {

            } {
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, bit)))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), PP)
                r := mulmod(mulmod(r, r, PP), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), PP)
                bit := div(bit, 16)
            }
        }

        return r;
    }

    /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
    /// @param _prefix parity byte (0x02 even, 0x03 odd)
    /// @param _x coordinate x
    /// @return y coordinate y
    function deriveY(uint8 _prefix, uint256 _x) internal pure returns (uint256) {
        require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

        // x^3 + ax + b
        uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, PP), PP), addmod(mulmod(_x, AA, PP), BB, PP), PP);
        y2 = expMod(y2, (PP + 1) / 4);
        // uint256 cmp = yBit ^ y_ & 1;
        uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : PP - y2;

        return y;
    }
}

contract TerraClaimable {
    error InvalidSignatureLength();
    error InvalidSignature();
    error InvalidAddress();

    function canClaim(bytes memory _signature, bytes memory _compPubKey) public view returns (bool) {
        bytes32 hashedAddress = sha256(abi.encodePacked(msg.sender));

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        address recoveredAddress = ecrecover(hashedAddress, v, r, s);
        if (recoveredAddress == address(0)) revert InvalidSignature();

        bytes memory _pubKey = decompressPubKey(_compPubKey);

        address computedAddress = address(uint160(uint256(keccak256(_pubKey))));

        if (recoveredAddress != computedAddress) revert InvalidAddress();

        return true;
    }

    function convertToArray(bytes memory _data) internal pure returns (uint256[] memory output) {
        output = new uint256[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            output[i] = uint256(uint8(_data[i]));
        }
    }

    function addressFromPublicKey(bytes memory _compPubKey) public pure returns (string memory result) {
        bytes memory pubKeyHash = abi.encodePacked(ripemd160(abi.encodePacked(sha256(abi.encodePacked(_compPubKey)))));

        uint256[] memory pubKeyNumbers = convertToArray(pubKeyHash);
        uint256[] memory pubKey5BitBase = Bech32.convert(pubKeyNumbers, 8, 5);

        result = string.concat("terra1", string(Bech32.encode(convertToArray(bytes("terra")), pubKey5BitBase)));
    }

    function splitSignature(bytes memory _sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        if (_sig.length != 65) revert InvalidSignatureLength();

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function decompressPubKey(bytes memory _compPubKey) internal pure returns (bytes memory pubKey) {
        uint8 prefix;
        uint256 x;

        assembly {
            prefix := byte(0, mload(add(_compPubKey, 32)))
            x := mload(add(_compPubKey, 33))
        }

        uint256 y = EllipticCurve.deriveY(prefix, x);

        pubKey = bytes.concat(bytes32(x), bytes32(y));
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

contract LunacyDAO is ERC20, TerraClaimable {
    address immutable minter;

    mapping(address => bool) public hasClaimed;

    error AlreadyClaimed();
    error CannotClaim();

    event Claim(address indexed to, uint256 amount);

    constructor(address _minter) ERC20("LunacyDAO", "LUNAC", 18) {
        minter = _minter;

        _mint(msg.sender, 100_000_000e18); // TODO: Finalise the team tokens amount
    }

    function claim(
        uint256 amount,
        bytes memory _minterSignature,
        bytes memory _terraSignature,
        bytes memory _terraPubKey
    ) external {
        if (hasClaimed[msg.sender]) revert AlreadyClaimed();
        if (!canClaim(_terraSignature, _terraPubKey)) revert CannotClaim();

        string memory terraAddress = addressFromPublicKey(_terraPubKey);

        bytes32 hashedMessage = sha256(abi.encodePacked(msg.sender, amount, terraAddress));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_minterSignature);
        address recoveredAddress = ecrecover(hashedMessage, v, r, s);

        if (recoveredAddress == address(0)) revert InvalidSignature();
        if (recoveredAddress != minter) revert InvalidAddress();

        hasClaimed[msg.sender] = true;
        _mint(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }
}