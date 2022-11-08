// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

/// @title Bit Mask Library
/// @author Stephen Chen
/// @notice Implements bit mask with dynamic array
library Bitmask {
    /// @notice Set a bit in the bit mask
    function setBit(
        mapping(uint256 => uint256) storage bitmask,
        uint256 _bit,
        bool _value
    ) public {
        // calculate the number of bits has been store in bitmask now
        uint256 positionOfMask = uint256(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        if (_value) {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] |
                (1 << positionOfBit);
        } else {
            bitmask[positionOfMask] =
                bitmask[positionOfMask] &
                ~(1 << positionOfBit);
        }
    }

    /// @notice Get a bit in the bit mask
    function getBit(mapping(uint256 => uint256) storage bitmask, uint256 _bit)
        public
        view
        returns (bool)
    {
        // calculate the number of bits has been store in bitmask now
        uint256 positionOfMask = uint256(_bit / 256);
        uint256 positionOfBit = _bit % 256;

        return ((bitmask[positionOfMask] & (1 << positionOfBit)) != 0);
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title CartesiMath
/// @author Felipe Argento
pragma solidity ^0.8.0;

library CartesiMathV2 {
    // mapping values are packed as bytes3 each
    // see test/TestCartesiMath.ts for decimal values
    bytes constant log2tableTimes1M =
        hex"0000000F4240182F421E8480236E082771822AD63A2DC6C0305E8532B04834C96736B3C23876D73A187A3B9D4A3D09003E5EA63FA0C540D17741F28843057D440BA745062945F60246DC1047B917488DC7495ABA4A207C4ADF8A4B98544C4B404CF8AA4DA0E64E44434EE3054F7D6D5013B750A61A5134C851BFF05247BD52CC58534DE753CC8D54486954C19C55384255AC75561E50568DE956FB575766B057D00758376F589CFA5900BA5962BC59C3135A21CA5A7EF15ADA945B34BF5B8D805BE4DF5C3AEA5C8FA95CE3265D356C5D86835DD6735E25455E73005EBFAD5F0B525F55F75F9FA25FE85A60302460770860BD0A61023061467F6189FD61CCAE620E98624FBF62902762CFD5630ECD634D12638AA963C7966403DC643F7F647A8264B4E864EEB56527EC6560906598A365D029660724663D9766738566A8F066DDDA6712476746386779AF67ACAF67DF3A6811526842FA68743268A4FC68D55C6905536934E169640A6992CF69C13169EF326A1CD46A4A186A76FF6AA38C6ACFC0";

    /// @notice Approximates log2 * 1M
    /// @param _num number to take log2 * 1M of
    /// @return approximate log2 times 1M
    function log2ApproxTimes1M(uint256 _num) public pure returns (uint256) {
        require(_num > 0, "Number cannot be zero");
        uint256 leading = 0;

        if (_num == 1) return 0;

        while (_num > 128) {
            _num = _num >> 1;
            leading += 1;
        }
        return (leading * uint256(1000000)) + (getLog2TableTimes1M(_num));
    }

    /// @notice navigates log2tableTimes1M
    /// @param _num number to take log2 of
    /// @return result after table look-up
    function getLog2TableTimes1M(uint256 _num) public pure returns (uint256) {
        bytes3 result = 0;
        for (uint8 i = 0; i < 3; i++) {
            bytes3 tempResult = log2tableTimes1M[(_num - 1) * 3 + i];
            result = result | (tempResult >> (i * 8));
        }

        return uint256(uint24(result));
    }

    /// @notice get floor of log2 of number
    /// @param _num number to take floor(log2) of
    /// @return floor(log2) of _num
    function getLog2Floor(uint256 _num) public pure returns (uint8) {
        require(_num != 0, "log of zero is undefined");

        return uint8(255 - clz(_num));
    }

    /// @notice checks if a number is Power of 2
    /// @param _num number to check
    /// @return true if number is power of 2, false if not
    function isPowerOf2(uint256 _num) public pure returns (bool) {
        if (_num == 0) return false;

        return _num & (_num - 1) == 0;
    }

    /// @notice count trailing zeros
    /// @param _num number you want the ctz of
    /// @dev this a binary search implementation
    function ctz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
            n = n + 128;
            _num = _num >> 128;
        }
        if (_num & 0x000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF == 0) {
            n = n + 64;
            _num = _num >> 64;
        }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF == 0) {
            n = n + 32;
            _num = _num >> 32;
        }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000FFFF == 0) {
            n = n + 16;
            _num = _num >> 16;
        }
        if (_num & 0x00000000000000000000000000000000000000000000000000000000000000FF == 0) {
            n = n + 8;
            _num = _num >> 8;
        }
        if (_num & 0x000000000000000000000000000000000000000000000000000000000000000F == 0) {
            n = n + 4;
            _num = _num >> 4;
        }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000003 == 0) {
            n = n + 2;
            _num = _num >> 2;
        }
        if (_num & 0x0000000000000000000000000000000000000000000000000000000000000001 == 0) {
            n = n + 1;
        }

        return n;
    }

    /// @notice count leading zeros
    /// @param _num number you want the clz of
    /// @dev this a binary search implementation
    function clz(uint256 _num) public pure returns (uint256) {
        if (_num == 0) return 256;

        uint256 n = 0;
        if (_num & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000 == 0) {
            n = n + 128;
            _num = _num << 128;
        }
        if (_num & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 == 0) {
            n = n + 64;
            _num = _num << 64;
        }
        if (_num & 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000 == 0) {
            n = n + 32;
            _num = _num << 32;
        }
        if (_num & 0xFFFF000000000000000000000000000000000000000000000000000000000000 == 0) {
            n = n + 16;
            _num = _num << 16;
        }
        if (_num & 0xFF00000000000000000000000000000000000000000000000000000000000000 == 0) {
            n = n + 8;
            _num = _num << 8;
        }
        if (_num & 0xF000000000000000000000000000000000000000000000000000000000000000 == 0) {
            n = n + 4;
            _num = _num << 4;
        }
        if (_num & 0xC000000000000000000000000000000000000000000000000000000000000000 == 0) {
            n = n + 2;
            _num = _num << 2;
        }
        if (_num & 0x8000000000000000000000000000000000000000000000000000000000000000 == 0) {
            n = n + 1;
        }

        return n;
    }
}

// Copyright 2020 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Library for Merkle proofs
pragma solidity ^0.8.0;

import "./CartesiMathV2.sol";

library MerkleV2 {
    using CartesiMathV2 for uint256;

    uint128 constant L_WORD_SIZE = 3; // word = 8 bytes, log = 3
    // number of hashes in EMPTY_TREE_HASHES
    uint128 constant EMPTY_TREE_SIZE = 1952; // 61*32=1952. 32 bytes per 61 indexes (64 words)

    // merkle root hashes of trees of zero concatenated
    // 32 bytes for each root, first one is keccak(0), second one is
    // keccak(keccack(0), keccak(0)) and so on

    bytes constant EMPTY_TREE_HASHES =
        hex"011b4d03dd8c01f1049143cf9c4c817e4b167f1d1b83e5c6f0f10d89ba1e7bce4d9470a821fbe90117ec357e30bad9305732fb19ddf54a07dd3e29f440619254ae39ce8537aca75e2eff3e38c98011dfe934e700a0967732fc07b430dd656a233fc9a15f5b4869c872f81087bb6104b7d63e6f9ab47f2c43f3535eae7172aa7f17d2dd614cddaa4d879276b11e0672c9560033d3e8453a1d045339d34ba601b9c37b8b13ca95166fb7af16988a70fcc90f38bf9126fd833da710a47fb37a55e68e7a427fa943d9966b389f4f257173676090c6e95f43e2cb6d65f8758111e30930b0b9deb73e155c59740bacf14a6ff04b64bb8e201a506409c3fe381ca4ea90cd5deac729d0fdaccc441d09d7325f41586ba13c801b7eccae0f95d8f3933efed8b96e5b7f6f459e9cb6a2f41bf276c7b85c10cd4662c04cbbb365434726c0a0c9695393027fb106a8153109ac516288a88b28a93817899460d6310b71cf1e6163e8806fa0d4b197a259e8c3ac28864268159d0ac85f8581ca28fa7d2c0c03eb91e3eee5ca7a3da2b3053c9770db73599fb149f620e3facef95e947c0ee860b72122e31e4bbd2b7c783d79cc30f60c6238651da7f0726f767d22747264fdb046f7549f26cc70ed5e18baeb6c81bb0625cb95bb4019aeecd40774ee87ae29ec517a71f6ee264c5d761379b3d7d617ca83677374b49d10aec50505ac087408ca892b573c267a712a52e1d06421fe276a03efb1889f337201110fdc32a81f8e152499af665835aabfdc6740c7e2c3791a31c3cdc9f5ab962f681b12fc092816a62f27d86025599a41233848702f0cfc0437b445682df51147a632a0a083d2d38b5e13e466a8935afff58bb533b3ef5d27fba63ee6b0fd9e67ff20af9d50deee3f8bf065ec220c1fd4ba57e341261d55997f85d66d32152526736872693d2b437a233e2337b715f6ac9a6a272622fdc2d67fcfe1da3459f8dab4ed7e40a657a54c36766c5e8ac9a88b35b05c34747e6507f6b044ab66180dc76ac1a696de03189593fedc0d0dbbd855c8ead673544899b0960e4a5a7ca43b4ef90afe607de7698caefdc242788f654b57a4fb32a71b335ef6ff9a4cc118b282b53bdd6d6192b7a82c3c5126b9c7e33c8e5a5ac9738b8bd31247fb7402054f97b573e8abb9faad219f4fd085aceaa7f542d787ee4196d365f3cc566e7bbcfbfd451230c48d804c017d21e2d8fa914e2559bb72bf0ab78c8ab92f00ef0d0d576eccdd486b64138a4172674857e543d1d5b639058dd908186597e366ad5f3d9c7ceaff44d04d1550b8d33abc751df07437834ba5acb32328a396994aebb3c40f759c2d6d7a3cb5377e55d5d218ef5a296dda8ddc355f3f50c3d0b660a51dfa4d98a6a5a33564556cf83c1373a814641d6a1dcef97b883fee61bb84fe60a3409340217e629cc7e4dcc93b85d8820921ff5826148b60e6939acd7838e1d7f20562bff8ee4b5ec4a05ad997a57b9796fdcb2eda87883c2640b072b140b946bfdf6575cacc066fdae04f6951e63624cbd316a677cad529bbe4e97b9144e4bc06c4afd1de55dd3e1175f90423847a230d34dfb71ed56f2965a7f6c72e6aa33c24c303fd67745d632656c5ef90bec80f4f5d1daa251988826cef375c81c36bf457e09687056f924677cb0bccf98dff81e014ce25f2d132497923e267363963cdf4302c5049d63131dc03fd95f65d8b6aa5934f817252c028c90f56d413b9d5d10d89790707dae2fabb249f649929927c21dd71e3f656826de5451c5da375aadecbd59d5ebf3a31fae65ac1b316a1611f1b276b26530f58d7247df459ce1f86db1d734f6f811932f042cee45d0e455306d01081bc3384f82c5fb2aacaa19d89cdfa46cc916eac61121475ba2e6191b4feecbe1789717021a158ace5d06744b40f551076b67cd63af60007f8c99876e1424883a45ec49d497ddaf808a5521ca74a999ab0b3c7aa9c80f85e93977ec61ce68b20307a1a81f71ca645b568fcd319ccbb5f651e87b707d37c39e15f945ea69e2f7c7d2ccc85b7e654c07e96f0636ae4044fe0e38590b431795ad0f8647bdd613713ada493cc17efd313206380e6a685b8198475bbd021c6e9d94daab2214947127506073e44d5408ba166c512a0b86805d07f5a44d3c41706be2bc15e712e55805248b92e8677d90f6d284d1d6ffaff2c430657042a0e82624fa3717b06cc0a6fd12230ea586dae83019fb9e06034ed2803c98d554b93c9a52348cafff75c40174a91f9ae6b8647854a156029f0b88b83316663ce574a4978277bb6bb27a31085634b6ec78864b6d8201c7e93903d75815067e378289a3d072ae172dafa6a452470f8d645bebfad9779594fc0784bb764a22e3a8181d93db7bf97893c414217a618ccb14caa9e92e8c61673afc9583662e812adba1f87a9c68202d60e909efab43c42c0cb00695fc7f1ffe67c75ca894c3c51e1e5e731360199e600f6ced9a87b2a6a87e70bf251bb5075ab222138288164b2eda727515ea7de12e2496d4fe42ea8d1a120c03cf9c50622c2afe4acb0dad98fd62d07ab4e828a94495f6d1ab973982c7ccbe6c1fae02788e4422ae22282fa49cbdb04ba54a7a238c6fc41187451383460762c06d1c8a72b9cd718866ad4b689e10c9a8c38fe5ef045bd785b01e980fc82c7e3532ce81876b778dd9f1ceeba4478e86411fb6fdd790683916ca832592485093644e8760cd7b4c01dba1ccc82b661bf13f0e3f34acd6b88";

    /// @notice Gets merkle root hash of drive with a replacement
    /// @param _position position of _drive
    /// @param _logSizeOfReplacement log2 of size the replacement
    /// @param _logSizeOfFullDrive log2 of size the full drive, which can be the entire machine
    /// @param _replacement hash of the replacement
    /// @param siblings of replacement that merkle root can be calculated
    function getRootAfterReplacementInDrive(
        uint256 _position,
        uint256 _logSizeOfReplacement,
        uint256 _logSizeOfFullDrive,
        bytes32 _replacement,
        bytes32[] calldata siblings
    ) public pure returns (bytes32) {
        require(
            _logSizeOfFullDrive >= _logSizeOfReplacement && _logSizeOfReplacement >= 3 && _logSizeOfFullDrive <= 64,
            "3 <= logSizeOfReplacement <= logSizeOfFullDrive <= 64"
        );

        uint256 size = 1 << _logSizeOfReplacement;

        require(((size - 1) & _position) == 0, "Position is not aligned");
        require(siblings.length == _logSizeOfFullDrive - _logSizeOfReplacement, "Proof length does not match");

        for (uint256 i; i < siblings.length; i++) {
            if ((_position & (size << i)) == 0) {
                _replacement = keccak256(abi.encodePacked(_replacement, siblings[i]));
            } else {
                _replacement = keccak256(abi.encodePacked(siblings[i], _replacement));
            }
        }

        return _replacement;
    }

    /// @notice Gets precomputed hash of zero in empty tree hashes
    /// @param _index of hash wanted
    /// @dev first index is keccak(0), second index is keccak(keccak(0), keccak(0))
    function getEmptyTreeHashAtIndex(uint256 _index) public pure returns (bytes32) {
        uint256 start = _index * 32;
        require(EMPTY_TREE_SIZE >= start + 32, "index out of bounds");
        bytes32 hashedZeros;
        bytes memory zeroTree = EMPTY_TREE_HASHES;

        // first word is length, then skip index words
        assembly {
            hashedZeros := mload(add(add(zeroTree, 0x20), start))
        }
        return hashedZeros;
    }

    /// @notice get merkle root of generic array of bytes
    /// @param _data array of bytes to be merklelized
    /// @param _log2Size log2 of total size of the drive
    /// @dev _data is padded with zeroes until is multiple of 8
    /// @dev root is completed with zero tree until log2size is complete
    /// @dev hashes are taken word by word (8 bytes by 8 bytes)
    function getMerkleRootFromBytes(bytes calldata _data, uint256 _log2Size) public pure returns (bytes32) {
        require(_log2Size >= 3 && _log2Size <= 64, "range of log2Size: [3,64]");

        // if _data is empty return pristine drive of size log2size
        if (_data.length == 0) return getEmptyTreeHashAtIndex(_log2Size - 3);

        // total size of the drive in words
        uint256 size = 1 << (_log2Size - 3);
        require(size << L_WORD_SIZE >= _data.length, "data is bigger than drive");
        // the stack depth is log2(_data.length / 8) + 2
        uint256 stack_depth = 2 + ((_data.length) >> L_WORD_SIZE).getLog2Floor();
        bytes32[] memory stack = new bytes32[](stack_depth);

        uint256 numOfHashes; // total number of hashes on stack (counting levels)
        uint256 stackLength; // total length of stack
        uint256 numOfJoins; // number of hashes of the same level on stack
        uint256 topStackLevel; // hash level of the top of the stack

        while (numOfHashes < size) {
            if ((numOfHashes << L_WORD_SIZE) < _data.length) {
                // we still have words to hash
                stack[stackLength] = getHashOfWordAtIndex(_data, numOfHashes);
                numOfHashes++;

                numOfJoins = numOfHashes;
            } else {
                // since padding happens in hashOfWordAtIndex function
                // we only need to complete the stack with pre-computed
                // hash(0), hash(hash(0),hash(0)) and so on
                topStackLevel = numOfHashes.ctz();

                stack[stackLength] = getEmptyTreeHashAtIndex(topStackLevel);

                //Empty Tree Hash summarizes many hashes
                numOfHashes = numOfHashes + (1 << topStackLevel);
                numOfJoins = numOfHashes >> topStackLevel;
            }

            stackLength++;

            // while there are joins, hash top of stack together
            while (numOfJoins & 1 == 0) {
                bytes32 h2 = stack[stackLength - 1];
                bytes32 h1 = stack[stackLength - 2];

                stack[stackLength - 2] = keccak256(abi.encodePacked(h1, h2));
                stackLength = stackLength - 1; // remove hashes from stack

                numOfJoins = numOfJoins >> 1;
            }
        }
        require(stackLength == 1, "stack error");

        return stack[0];
    }

    /// @notice Get the hash of a word in an array of bytes
    /// @param _data array of bytes
    /// @param _wordIndex index of word inside the bytes to get the hash of
    /// @dev if word is incomplete (< 8 bytes) it gets padded with zeroes
    function getHashOfWordAtIndex(bytes calldata _data, uint256 _wordIndex) public pure returns (bytes32) {
        uint256 start = _wordIndex << L_WORD_SIZE;
        uint256 end = start + (1 << L_WORD_SIZE);

        // TODO: in .lua this just returns zero, but this might be more consistent
        require(start <= _data.length, "word out of bounds");

        if (end <= _data.length) {
            return keccak256(abi.encodePacked(_data[start:end]));
        }

        // word is incomplete
        // fill paddedSlice with incomplete words - the rest is going to be bytes(0)
        bytes memory paddedSlice = new bytes(8);
        uint256 remaining = _data.length - start;

        for (uint256 i; i < remaining; i++) {
            paddedSlice[i] = _data[start + i];
        }

        return keccak256(paddedSlice);
    }

    /// @notice Calculate the root of Merkle tree from an array of power of 2 elements
    /// @param hashes The array containing power of 2 elements
    /// @return byte32 the root hash being calculated
    function calculateRootFromPowerOfTwo(bytes32[] memory hashes) public pure returns (bytes32) {
        // revert when the input is not of power of 2
        require((hashes.length).isPowerOf2(), "array len not power of 2");

        if (hashes.length == 1) {
            return hashes[0];
        } else {
            bytes32[] memory newHashes = new bytes32[](hashes.length >> 1);

            for (uint256 i; i < hashes.length; i += 2) {
                newHashes[i >> 1] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
            }

            return calculateRootFromPowerOfTwo(newHashes);
        }
    }
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

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Output facet
pragma solidity ^0.8.0;

import {Bitmask} from "@cartesi/util/contracts/Bitmask.sol";
import {MerkleV2} from "@cartesi/util/contracts/MerkleV2.sol";

import {IOutput, OutputValidityProof} from "../interfaces/IOutput.sol";

import {LibOutput} from "../libraries/LibOutput.sol";
import {LibFeeManager} from "../libraries/LibFeeManager.sol";

contract OutputFacet is IOutput {
    using LibOutput for LibOutput.DiamondStorage;

    // Here we only need 248 bits as keys in the mapping, but we use 256 bits for gas optimization
    using Bitmask for mapping(uint256 => uint256);

    uint256 constant KECCAK_LOG2_SIZE = 5; // keccak log2 size

    // max size of voucher metadata memory range 32 * (2^16) bytes
    uint256 constant VOUCHER_METADATA_LOG2_SIZE = 21;
    // max size of epoch voucher memory range 32 * (2^32) bytes
    uint256 constant EPOCH_VOUCHER_LOG2_SIZE = 37;

    // max size of notice metadata memory range 32 * (2^16) bytes
    uint256 constant NOTICE_METADATA_LOG2_SIZE = 21;
    // max size of epoch notice memory range 32 * (2^32) bytes
    uint256 constant EPOCH_NOTICE_LOG2_SIZE = 37;

    /// @notice functions modified by noReentrancy are not subject to recursion
    modifier noReentrancy() {
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();

        require(!outputDS.lock, "reentrancy not allowed");
        outputDS.lock = true;
        _;
        outputDS.lock = false;
    }

    /// @notice executes voucher
    /// @param _destination address that will execute the payload
    /// @param _payload payload to be executed by destination
    /// @param _v validity proof for this encoded voucher
    /// @return true if voucher was executed successfully
    /// @dev  vouchers can only be executed once
    function executeVoucher(
        address _destination,
        bytes calldata _payload,
        OutputValidityProof calldata _v
    ) public override noReentrancy returns (bool) {
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();
        LibFeeManager.DiamondStorage storage feeManagerDS = LibFeeManager
            .diamondStorage();

        // avoid a malicious DApp developer from draining the Fee Manager's bank account
        require(_destination != address(feeManagerDS.bank), "bad destination");

        bytes memory encodedVoucher = abi.encode(_destination, _payload);

        // check if validity proof matches the voucher provided
        isValidVoucherProof(
            encodedVoucher,
            outputDS.epochHashes[_v.epochIndex],
            _v
        );

        uint256 voucherPosition = getBitMaskPosition(
            _v.outputIndex,
            _v.inputIndex,
            _v.epochIndex
        );

        // check if voucher has been executed
        require(
            !outputDS.voucherBitmask.getBit(voucherPosition),
            "re-execution not allowed"
        );

        // execute voucher
        (bool succ, ) = _destination.call(_payload);

        // if properly executed, mark it as executed and emit event
        if (succ) {
            outputDS.voucherBitmask.setBit(voucherPosition, true);
            emit VoucherExecuted(voucherPosition);
        }

        return succ;
    }

    /// @notice validates notice
    /// @param _notice notice to be verified
    /// @param _v validity proof for this notice
    /// @return true if notice is valid
    function validateNotice(
        bytes calldata _notice,
        OutputValidityProof calldata _v
    ) public view override returns (bool) {
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();

        bytes memory encodedNotice = abi.encode(_notice);

        // reverts if validity proof doesnt match
        isValidNoticeProof(
            encodedNotice,
            outputDS.epochHashes[_v.epochIndex],
            _v
        );

        return true;
    }

    /// @notice isValidProof reverts if the proof is invalid
    ///  @dev _outputsEpochRootHash must be _v.vouchersEpochRootHash or
    ///                                  or _v.noticesEpochRootHash
    function isValidProof(
        bytes memory _encodedOutput,
        bytes32 _epochHash,
        bytes32 _outputsEpochRootHash,
        uint256 _outputEpochLog2Size,
        uint256 _outputHashesLog2Size,
        OutputValidityProof calldata _v
    ) internal pure {
        // prove that outputs hash is represented in a finalized epoch
        require(
            keccak256(
                abi.encodePacked(
                    _v.vouchersEpochRootHash,
                    _v.noticesEpochRootHash,
                    _v.machineStateHash
                )
            ) == _epochHash,
            "epochHash incorrect"
        );

        // prove that output metadata memory range is contained in epoch's output memory range
        require(
            MerkleV2.getRootAfterReplacementInDrive(
                getIntraDrivePosition(_v.inputIndex, KECCAK_LOG2_SIZE),
                KECCAK_LOG2_SIZE,
                _outputEpochLog2Size,
                _v.outputHashesRootHash,
                _v.outputHashesInEpochSiblings
            ) == _outputsEpochRootHash,
            "outputsEpochRootHash incorrect"
        );

        // The hash of the output is converted to bytes (abi.encode) and
        // treated as data. The metadata output memory range stores that data while
        // being indifferent to its contents. To prove that the received
        // output is contained in the metadata output memory range we need to
        // prove that x, where:
        // x = keccak(
        //          keccak(
        //              keccak(hashOfOutput[0:7]),
        //              keccak(hashOfOutput[8:15])
        //          ),
        //          keccak(
        //              keccak(hashOfOutput[16:23]),
        //              keccak(hashOfOutput[24:31])
        //          )
        //     )
        // is contained in it. We can't simply use hashOfOutput because the
        // log2size of the leaf is three (8 bytes) not  five (32 bytes)
        bytes32 merkleRootOfHashOfOutput = MerkleV2.getMerkleRootFromBytes(
            abi.encodePacked(keccak256(_encodedOutput)),
            KECCAK_LOG2_SIZE
        );

        // prove that merkle root hash of bytes(hashOfOutput) is contained
        // in the output metadata array memory range
        require(
            MerkleV2.getRootAfterReplacementInDrive(
                getIntraDrivePosition(_v.outputIndex, KECCAK_LOG2_SIZE),
                KECCAK_LOG2_SIZE,
                _outputHashesLog2Size,
                merkleRootOfHashOfOutput,
                _v.keccakInHashesSiblings
            ) == _v.outputHashesRootHash,
            "outputHashesRootHash incorrect"
        );
    }

    /// @notice isValidVoucherProof reverts if the proof is invalid
    function isValidVoucherProof(
        bytes memory _encodedVoucher,
        bytes32 _epochHash,
        OutputValidityProof calldata _v
    ) public pure {
        isValidProof(
            _encodedVoucher,
            _epochHash,
            _v.vouchersEpochRootHash,
            EPOCH_VOUCHER_LOG2_SIZE,
            VOUCHER_METADATA_LOG2_SIZE,
            _v
        );
    }

    /// @notice isValidNoticeProof reverts if the proof is invalid
    function isValidNoticeProof(
        bytes memory _encodedNotice,
        bytes32 _epochHash,
        OutputValidityProof calldata _v
    ) public pure {
        isValidProof(
            _encodedNotice,
            _epochHash,
            _v.noticesEpochRootHash,
            EPOCH_NOTICE_LOG2_SIZE,
            NOTICE_METADATA_LOG2_SIZE,
            _v
        );
    }

    /// @notice get voucher position on bitmask
    /// @param _voucher of voucher inside the input
    /// @param _input which input, inside the epoch, the voucher belongs to
    /// @param _epoch which epoch the voucher belongs to
    /// @return position of that voucher on bitmask
    function getBitMaskPosition(
        uint256 _voucher,
        uint256 _input,
        uint256 _epoch
    ) public pure returns (uint256) {
        // voucher * 2 ** 128 + input * 2 ** 64 + epoch
        // this can't overflow because its impossible to have > 2**128 vouchers
        return (((_voucher << 128) | (_input << 64)) | _epoch);
    }

    /// @notice returns the position of a intra memory range on a memory range
    //          with  contents with the same size
    /// @param _index index of intra memory range
    /// @param _log2Size of intra memory range
    function getIntraDrivePosition(
        uint256 _index,
        uint256 _log2Size
    ) public pure returns (uint256) {
        return (_index << _log2Size);
    }

    /// @notice get number of finalized epochs
    function getNumberOfFinalizedEpochs()
        public
        view
        override
        returns (uint256)
    {
        LibOutput.DiamondStorage storage outputDS = LibOutput.diamondStorage();
        return outputDS.getNumberOfFinalizedEpochs();
    }

    /// @notice get log2 size of voucher metadata memory range
    function getVoucherMetadataLog2Size()
        public
        pure
        override
        returns (uint256)
    {
        return VOUCHER_METADATA_LOG2_SIZE;
    }

    /// @notice get log2 size of epoch voucher memory range
    function getEpochVoucherLog2Size() public pure override returns (uint256) {
        return EPOCH_VOUCHER_LOG2_SIZE;
    }

    /// @notice get log2 size of notice metadata memory range
    function getNoticeMetadataLog2Size()
        public
        pure
        override
        returns (uint256)
    {
        return NOTICE_METADATA_LOG2_SIZE;
    }

    /// @notice get log2 size of epoch notice memory range
    function getEpochNoticeLog2Size() public pure override returns (uint256) {
        return EPOCH_NOTICE_LOG2_SIZE;
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// @title Bank interface
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBank {
    /// @notice returns the token used internally
    function getToken() external view returns (IERC20);

    /// @notice get balance of `_owner`
    /// @param _owner account owner
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice transfer `_value` tokens from bank to `_to`
    /// @notice decrease the balance of caller by `_value`
    /// @param _to account that will receive `_value` tokens
    /// @param _value amount of tokens to be transfered
    function transferTokens(address _to, uint256 _value) external;

    /// @notice transfer `_value` tokens from caller to bank
    /// @notice increase the balance of `_to` by `_value`
    /// @dev you may need to call `token.approve(bank, _value)`
    /// @param _to account that will have their balance increased by `_value`
    /// @param _value amount of tokens to be transfered
    function depositTokens(address _to, uint256 _value) external;

    /// @notice `value` tokens were transfered from the bank to `to`
    /// @notice the balance of `from` was decreased by `value`
    /// @dev is triggered on any successful call to `transferTokens`
    /// @param from the account/contract that called `transferTokens` and
    ///              got their balance decreased by `value`
    /// @param to the one that received `value` tokens from the bank
    /// @param value amount of tokens that were transfered
    event Transfer(address indexed from, address to, uint256 value);

    /// @notice `value` tokens were transfered from `from` to bank
    /// @notice the balance of `to` was increased by `value`
    /// @dev is triggered on any successful call to `depositTokens`
    /// @param from the account/contract that called `depositTokens` and
    ///              transfered `value` tokens to the bank
    /// @param to the one that got their balance increased by `value`
    /// @param value amount of tokens that were transfered
    event Deposit(address from, address indexed to, uint256 value);
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Output interface
pragma solidity >=0.7.0;

/// @notice Data used to prove the validity of an output (notices and vouchers)
/// @param epochIndex which epoch the output belongs to
/// @param inputIndex which input, inside the epoch, the output belongs to
/// @param outputIndex index of output inside the input
/// @param outputHashesRootHash merkle root of all output metadata hashes of the related input
/// @param vouchersEpochRootHash merkle root of all voucher metadata hashes of the related epoch
/// @param noticesEpochRootHash merkle root of all notice metadata hashes of the related epoch
/// @param machineStateHash hash of the machine state claimed for the related epoch
/// @param keccakInHashesSiblings proof that this output metadata is in metadata memory range
/// @param outputHashesInEpochSiblings proof that this output metadata is in epoch's output memory range
struct OutputValidityProof {
    uint256 epochIndex;
    uint256 inputIndex;
    uint256 outputIndex;
    bytes32 outputHashesRootHash;
    bytes32 vouchersEpochRootHash;
    bytes32 noticesEpochRootHash;
    bytes32 machineStateHash;
    bytes32[] keccakInHashesSiblings;
    bytes32[] outputHashesInEpochSiblings;
}

interface IOutput {
    /// @notice Executes a voucher
    /// @param _destination address of the target contract that will execute the payload
    /// @param _payload payload to be executed by the destination contract, containing a method signature and ABI-encoded parameters
    /// @param _v validity proof for the voucher
    /// @return true if voucher was executed successfully
    /// @dev vouchers can only be successfully executed one time, and only if the provided proof is valid
    function executeVoucher(
        address _destination,
        bytes calldata _payload,
        OutputValidityProof calldata _v
    ) external returns (bool);

    /// @notice Validates a notice
    /// @param _notice notice to be validated
    /// @param _v validity proof for the notice
    /// @return true if notice is valid
    function validateNotice(
        bytes calldata _notice,
        OutputValidityProof calldata _v
    ) external view returns (bool);

    /// @notice Get number of finalized epochs
    function getNumberOfFinalizedEpochs() external view returns (uint256);

    /// @notice Get log2 size of voucher metadata memory range
    function getVoucherMetadataLog2Size() external pure returns (uint256);

    /// @notice Get log2 size of epoch voucher memory range
    function getEpochVoucherLog2Size() external pure returns (uint256);

    /// @notice Get log2 size of notice metadata memory range
    function getNoticeMetadataLog2Size() external pure returns (uint256);

    /// @notice Get log2 size of epoch notice memory range
    function getEpochNoticeLog2Size() external pure returns (uint256);

    /// @notice Indicates that a voucher was executed
    /// @param voucherPosition voucher unique identifier considering epoch, input and output indices
    event VoucherExecuted(uint256 voucherPosition);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Validator Manager interface
pragma solidity >=0.7.0;

// NoConflict - No conflicting claims or consensus
// Consensus - All validators had equal claims
// Conflict - Claim is conflicting with previous one
enum Result {
    NoConflict,
    Consensus,
    Conflict
}

// TODO: What is the incentive for validators to not just copy the first claim that arrived?
interface IValidatorManager {
    /// @notice get current claim
    function getCurrentClaim() external view returns (bytes32);

    /// @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on new Epoch
    event NewEpoch(bytes32 claim);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title ClaimsMask library
pragma solidity >=0.8.8;

// ClaimsMask is used to keep track of the number of claims for up to 8 validators
// | agreement mask | consensus goal mask | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
// |     8 bits     |        8 bits       |      30 bits       |      30 bits       | ... |      30 bits       |
// In Validator Manager, #claims_validator indicates the #claims the validator has made.
// In Fee Manager, #claims_validator indicates the #claims the validator has redeemed. In this case,
//      agreement mask and consensus goal mask are not used.

type ClaimsMask is uint256;

library LibClaimsMask {
    uint256 constant claimsBitLen = 30; // #bits used for each #claims

    /// @notice this function creates a new ClaimsMask variable with value _value
    /// @param  _value the value following the format of ClaimsMask
    function newClaimsMask(uint256 _value) internal pure returns (ClaimsMask) {
        return ClaimsMask.wrap(_value);
    }

    /// @notice this function creates a new ClaimsMask variable with the consensus goal mask set,
    ///         according to the number of validators
    /// @param  _numValidators the number of validators
    function newClaimsMaskWithConsensusGoalSet(
        uint256 _numValidators
    ) internal pure returns (ClaimsMask) {
        require(_numValidators <= 8, "up to 8 validators");
        uint256 consensusMask = (1 << _numValidators) - 1;
        return ClaimsMask.wrap(consensusMask << 240); // 256 - 8 - 8 = 240
    }

    /// @notice this function returns the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    ///     this index can be obtained though `getNumberOfClaimsByIndex` function in Validator Manager
    function getNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex
    ) internal pure returns (uint256) {
        require(_validatorIndex < 8, "index out of range");
        uint256 bitmask = (1 << claimsBitLen) - 1;
        return
            (ClaimsMask.unwrap(_claimsMask) >>
                (claimsBitLen * _validatorIndex)) & bitmask;
    }

    /// @notice this function increases the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    /// @param  _value the increase amount
    function increaseNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex,
        uint256 _value
    ) internal pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        uint256 currentNum = getNumClaims(_claimsMask, _validatorIndex);
        uint256 newNum = currentNum + _value; // overflows checked by default with sol0.8
        return setNumClaims(_claimsMask, _validatorIndex, newNum);
    }

    /// @notice this function sets the #claims for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    /// @param  _value the set value
    function setNumClaims(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex,
        uint256 _value
    ) internal pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        require(_value <= ((1 << claimsBitLen) - 1), "ClaimsMask Overflow");
        uint256 bitmask = ~(((1 << claimsBitLen) - 1) <<
            (claimsBitLen * _validatorIndex));
        uint256 clearedClaimsMask = ClaimsMask.unwrap(_claimsMask) & bitmask;
        _claimsMask = ClaimsMask.wrap(
            clearedClaimsMask | (_value << (claimsBitLen * _validatorIndex))
        );
        return _claimsMask;
    }

    /// @notice get consensus goal mask
    /// @param  _claimsMask the ClaimsMask value
    function clearAgreementMask(
        ClaimsMask _claimsMask
    ) internal pure returns (ClaimsMask) {
        uint256 clearedMask = ClaimsMask.unwrap(_claimsMask) & ((1 << 248) - 1); // 256 - 8 = 248
        return ClaimsMask.wrap(clearedMask);
    }

    /// @notice get the entire agreement mask
    /// @param  _claimsMask the ClaimsMask value
    function getAgreementMask(
        ClaimsMask _claimsMask
    ) internal pure returns (uint256) {
        return (ClaimsMask.unwrap(_claimsMask) >> 248); // get the first 8 bits
    }

    /// @notice check if a validator has already claimed
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function alreadyClaimed(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex
    ) internal pure returns (bool) {
        // get the first 8 bits. Then & operation on the validator's bit to see if it's set
        return
            (((ClaimsMask.unwrap(_claimsMask) >> 248) >> _validatorIndex) &
                1) != 0;
    }

    /// @notice set agreement mask for the specified validator
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function setAgreementMask(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex
    ) internal pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        uint256 setMask = (ClaimsMask.unwrap(_claimsMask) |
            (1 << (248 + _validatorIndex))); // 256 - 8 = 248
        return ClaimsMask.wrap(setMask);
    }

    /// @notice get the entire consensus goal mask
    /// @param  _claimsMask the ClaimsMask value
    function getConsensusGoalMask(
        ClaimsMask _claimsMask
    ) internal pure returns (uint256) {
        return ((ClaimsMask.unwrap(_claimsMask) << 8) >> 248); // get the second 8 bits
    }

    /// @notice remove validator from the ClaimsMask
    /// @param  _claimsMask the ClaimsMask value
    /// @param  _validatorIndex index of the validator in the validator array, starting from 0
    function removeValidator(
        ClaimsMask _claimsMask,
        uint256 _validatorIndex
    ) internal pure returns (ClaimsMask) {
        require(_validatorIndex < 8, "index out of range");
        uint256 claimsMaskValue = ClaimsMask.unwrap(_claimsMask);
        // remove validator from agreement bitmask
        uint256 zeroMask = ~(1 << (_validatorIndex + 248)); // 256 - 8 = 248
        claimsMaskValue = (claimsMaskValue & zeroMask);
        // remove validator from consensus goal mask
        zeroMask = ~(1 << (_validatorIndex + 240)); // 256 - 8 - 8 = 240
        claimsMaskValue = (claimsMaskValue & zeroMask);
        // remove validator from #claims
        return
            setNumClaims(ClaimsMask.wrap(claimsMaskValue), _validatorIndex, 0);
    }
}

// Copyright 2022 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Fee Manager library
pragma solidity ^0.8.0;

import {LibValidatorManager} from "../libraries/LibValidatorManager.sol";
import {LibClaimsMask, ClaimsMask} from "../libraries/LibClaimsMask.sol";
import {IBank} from "../IBank.sol";

library LibFeeManager {
    using LibValidatorManager for LibValidatorManager.DiamondStorage;
    using LibFeeManager for LibFeeManager.DiamondStorage;
    using LibClaimsMask for ClaimsMask;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("FeeManager.diamond.storage");

    struct DiamondStorage {
        address owner; // owner of Fee Manager
        uint256 feePerClaim;
        IBank bank; // bank that holds the tokens to pay validators
        bool lock; // reentrancy lock
        // A bit set used for up to 8 validators.
        // The first 16 bits are not used to keep compatibility with the validator manager contract.
        // The following every 30 bits are used to indicate the number of total claims each validator has made
        // |     not used    | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
        // |     16 bits     |      30 bits       |      30 bits       | ... |      30 bits       |
        ClaimsMask numClaimsRedeemed;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function onlyOwner(DiamondStorage storage ds) internal view {
        require(ds.owner == msg.sender, "caller is not the owner");
    }

    /// @notice this function can be called to check the number of claims that's redeemable for the validator
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator
    function numClaimsRedeemable(
        DiamondStorage storage ds,
        address _validator
    ) internal view returns (uint256) {
        require(_validator != address(0), "address should not be 0");

        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = validatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        uint256 totalClaims = validatorManagerDS.claimsMask.getNumClaims(
            valIndex
        );
        uint256 redeemedClaims = ds.numClaimsRedeemed.getNumClaims(valIndex);

        // underflow checked by default with sol0.8
        // which means if the validator is removed, calling this function will
        // either return 0 or revert
        return totalClaims - redeemedClaims;
    }

    /// @notice this function can be called to check the number of claims that has been redeemed for the validator
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator
    function getNumClaimsRedeemed(
        DiamondStorage storage ds,
        address _validator
    ) internal view returns (uint256) {
        require(_validator != address(0), "address should not be 0");

        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = validatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        uint256 redeemedClaims = ds.numClaimsRedeemed.getNumClaims(valIndex);

        return redeemedClaims;
    }

    /// @notice contract owner can reset the value of fee per claim
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _value the new value of fee per claim
    function resetFeePerClaim(
        DiamondStorage storage ds,
        uint256 _value
    ) internal {
        // before resetting the feePerClaim, pay fees for all validators as per current rates
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        for (
            uint256 valIndex;
            valIndex < validatorManagerDS.maxNumValidators;
            valIndex++
        ) {
            address validator = validatorManagerDS.validators[valIndex];
            if (validator != address(0)) {
                uint256 nowRedeemingClaims = ds.numClaimsRedeemable(validator);
                if (nowRedeemingClaims > 0) {
                    ds.numClaimsRedeemed = ds
                        .numClaimsRedeemed
                        .increaseNumClaims(valIndex, nowRedeemingClaims);

                    uint256 feesToSend = nowRedeemingClaims * ds.feePerClaim; // number of erc20 tokens to send
                    ds.bank.transferTokens(validator, feesToSend); // will revert if transfer fails
                    // emit the number of claimed being redeemed, instead of the amount of tokens
                    emit FeeRedeemed(validator, nowRedeemingClaims);
                }
            }
        }
        ds.feePerClaim = _value;
        emit FeePerClaimReset(_value);
    }

    /// @notice this function can be called to redeem fees for validators
    /// @param  ds pointer to FeeManager's diamond storage
    /// @param  _validator address of the validator that is redeeming
    function redeemFee(DiamondStorage storage ds, address _validator) internal {
        // follow the Checks-Effects-Interactions pattern for security

        // ** checks **
        uint256 nowRedeemingClaims = ds.numClaimsRedeemable(_validator);
        require(nowRedeemingClaims > 0, "nothing to redeem yet");

        // ** effects **
        LibValidatorManager.DiamondStorage
            storage validatorManagerDS = LibValidatorManager.diamondStorage();
        uint256 valIndex = validatorManagerDS.getValidatorIndex(_validator); // will revert if not found
        ds.numClaimsRedeemed = ds.numClaimsRedeemed.increaseNumClaims(
            valIndex,
            nowRedeemingClaims
        );

        // ** interactions **
        uint256 feesToSend = nowRedeemingClaims * ds.feePerClaim; // number of erc20 tokens to send
        ds.bank.transferTokens(_validator, feesToSend); // will revert if transfer fails
        // emit the number of claimed being redeemed, instead of the amount of tokens
        emit FeeRedeemed(_validator, nowRedeemingClaims);
    }

    /// @notice removes a validator
    /// @param ds diamond storage pointer
    /// @param index index of validator to be removed
    function removeValidator(
        DiamondStorage storage ds,
        uint256 index
    ) internal {
        ds.numClaimsRedeemed = ds.numClaimsRedeemed.setNumClaims(index, 0);
    }

    /// @notice emitted on resetting feePerClaim
    event FeePerClaimReset(uint256 value);

    /// @notice emitted on ERC20 funds redeemed by validator
    event FeeRedeemed(address validator, uint256 claims);
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Output library
pragma solidity ^0.8.0;

library LibOutput {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Output.diamond.storage");

    struct DiamondStorage {
        mapping(uint256 => uint256) voucherBitmask;
        bytes32[] epochHashes;
        bool lock; //reentrancy lock
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice to be called when an epoch is finalized
    /// @param ds diamond storage pointer
    /// @param epochHash hash of finalized epoch
    /// @dev an epoch being finalized means that its vouchers can be called
    function onNewEpoch(DiamondStorage storage ds, bytes32 epochHash) internal {
        ds.epochHashes.push(epochHash);
    }

    /// @notice get number of finalized epochs
    /// @param ds diamond storage pointer
    function getNumberOfFinalizedEpochs(
        DiamondStorage storage ds
    ) internal view returns (uint256) {
        return ds.epochHashes.length;
    }
}

// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Validator Manager library
pragma solidity ^0.8.0;

import {Result} from "../interfaces/IValidatorManager.sol";

import {LibClaimsMask, ClaimsMask} from "../libraries/LibClaimsMask.sol";
import {LibFeeManager} from "../libraries/LibFeeManager.sol";

library LibValidatorManager {
    using LibClaimsMask for ClaimsMask;
    using LibFeeManager for LibFeeManager.DiamondStorage;

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("ValidatorManager.diamond.storage");

    struct DiamondStorage {
        bytes32 currentClaim; // current claim - first claim of this epoch
        address payable[] validators; // up to 8 validators
        uint256 maxNumValidators; // the maximum number of validators, set in the constructor
        // A bit set used for up to 8 validators.
        // The first 8 bits are used to indicate whom supports the current claim
        // The second 8 bits are used to indicate those should have claimed in order to reach consensus
        // The following every 30 bits are used to indicate the number of total claims each validator has made
        // | agreement mask | consensus mask | #claims_validator7 | #claims_validator6 | ... | #claims_validator0 |
        // |     8 bits     |     8 bits     |      30 bits       |      30 bits       | ... |      30 bits       |
        ClaimsMask claimsMask;
    }

    /// @notice emitted on Claim received
    event ClaimReceived(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on Dispute end
    event DisputeEnded(
        Result result,
        bytes32[2] claims,
        address payable[2] validators
    );

    /// @notice emitted on new Epoch
    event NewEpoch(bytes32 claim);

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice called when a dispute ends in rollups
    /// @param ds diamond storage pointer
    /// @param winner address of dispute winner
    /// @param loser address of dispute loser
    /// @param winningClaim the winnning claim
    /// @return result of dispute being finished
    function onDisputeEnd(
        DiamondStorage storage ds,
        address payable winner,
        address payable loser,
        bytes32 winningClaim
    ) internal returns (Result, bytes32[2] memory, address payable[2] memory) {
        removeValidator(ds, loser);

        if (winningClaim == ds.currentClaim) {
            // first claim stood, dont need to update the bitmask
            return
                isConsensus(ds)
                    ? emitDisputeEndedAndReturn(
                        Result.Consensus,
                        [winningClaim, bytes32(0)],
                        [winner, payable(0)]
                    )
                    : emitDisputeEndedAndReturn(
                        Result.NoConflict,
                        [winningClaim, bytes32(0)],
                        [winner, payable(0)]
                    );
        }

        // if first claim lost, and other validators have agreed with it
        // there is a new dispute to be played
        if (ds.claimsMask.getAgreementMask() != 0) {
            return
                emitDisputeEndedAndReturn(
                    Result.Conflict,
                    [ds.currentClaim, winningClaim],
                    [getClaimerOfCurrentClaim(ds), winner]
                );
        }
        // else there are no valdiators that agree with losing claim
        // we can update current claim and check for consensus in case
        // the winner is the only validator left
        ds.currentClaim = winningClaim;
        updateClaimAgreementMask(ds, winner);
        return
            isConsensus(ds)
                ? emitDisputeEndedAndReturn(
                    Result.Consensus,
                    [winningClaim, bytes32(0)],
                    [winner, payable(0)]
                )
                : emitDisputeEndedAndReturn(
                    Result.NoConflict,
                    [winningClaim, bytes32(0)],
                    [winner, payable(0)]
                );
    }

    /// @notice called when a new epoch starts
    /// @param ds diamond storage pointer
    /// @return current claim
    function onNewEpoch(DiamondStorage storage ds) internal returns (bytes32) {
        // reward validators who has made the correct claim by increasing their #claims
        claimFinalizedIncreaseCounts(ds);

        bytes32 tmpClaim = ds.currentClaim;

        // clear current claim
        ds.currentClaim = bytes32(0);
        // clear validator agreement bit mask
        ds.claimsMask = ds.claimsMask.clearAgreementMask();

        emit NewEpoch(tmpClaim);
        return tmpClaim;
    }

    /// @notice called when a claim is received by rollups
    /// @param ds diamond storage pointer
    /// @param sender address of sender of that claim
    /// @param claim claim received by rollups
    /// @return result of claim, Consensus | NoConflict | Conflict
    /// @return [currentClaim, conflicting claim] if there is Conflict
    ///         [currentClaim, bytes32(0)] if there is Consensus or NoConflcit
    /// @return [claimer1, claimer2] if there is  Conflcit
    ///         [claimer1, address(0)] if there is Consensus or NoConflcit
    function onClaim(
        DiamondStorage storage ds,
        address payable sender,
        bytes32 claim
    ) internal returns (Result, bytes32[2] memory, address payable[2] memory) {
        require(claim != bytes32(0), "empty claim");
        require(isValidator(ds, sender), "sender not allowed");

        // require the validator hasn't claimed in the same epoch before
        uint256 index = getValidatorIndex(ds, sender);
        require(
            !ds.claimsMask.alreadyClaimed(index),
            "sender had claimed in this epoch before"
        );

        // cant return because a single claim might mean consensus
        if (ds.currentClaim == bytes32(0)) {
            ds.currentClaim = claim;
        } else if (claim != ds.currentClaim) {
            return
                emitClaimReceivedAndReturn(
                    Result.Conflict,
                    [ds.currentClaim, claim],
                    [getClaimerOfCurrentClaim(ds), sender]
                );
        }
        updateClaimAgreementMask(ds, sender);

        return
            isConsensus(ds)
                ? emitClaimReceivedAndReturn(
                    Result.Consensus,
                    [claim, bytes32(0)],
                    [sender, payable(0)]
                )
                : emitClaimReceivedAndReturn(
                    Result.NoConflict,
                    [claim, bytes32(0)],
                    [sender, payable(0)]
                );
    }

    /// @notice emits dispute ended event and then return
    /// @param result to be emitted and returned
    /// @param claims to be emitted and returned
    /// @param validators to be emitted and returned
    /// @dev this function existis to make code more clear/concise
    function emitDisputeEndedAndReturn(
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory validators
    ) internal returns (Result, bytes32[2] memory, address payable[2] memory) {
        emit DisputeEnded(result, claims, validators);
        return (result, claims, validators);
    }

    /// @notice emits claim received event and then return
    /// @param result to be emitted and returned
    /// @param claims to be emitted and returned
    /// @param validators to be emitted and returned
    /// @dev this function existis to make code more clear/concise
    function emitClaimReceivedAndReturn(
        Result result,
        bytes32[2] memory claims,
        address payable[2] memory validators
    ) internal returns (Result, bytes32[2] memory, address payable[2] memory) {
        emit ClaimReceived(result, claims, validators);
        return (result, claims, validators);
    }

    /// @notice only call this function when a claim has been finalized
    ///         Either a consensus has been reached or challenge period has past
    /// @param ds pointer to diamond storage
    function claimFinalizedIncreaseCounts(DiamondStorage storage ds) internal {
        uint256 agreementMask = ds.claimsMask.getAgreementMask();
        for (uint256 i; i < ds.validators.length; i++) {
            // if a validator agrees with the current claim
            if ((agreementMask & (1 << i)) != 0) {
                // increase #claims by 1
                ds.claimsMask = ds.claimsMask.increaseNumClaims(i, 1);
            }
        }
    }

    /// @notice removes a validator
    /// @param ds diamond storage pointer
    /// @param validator address of validator to be removed
    function removeValidator(
        DiamondStorage storage ds,
        address validator
    ) internal {
        LibFeeManager.DiamondStorage storage feeManagerDS = LibFeeManager
            .diamondStorage();
        for (uint256 i; i < ds.validators.length; i++) {
            if (validator == ds.validators[i]) {
                // put address(0) in validators position
                ds.validators[i] = payable(0);
                // remove the validator from ValidatorManager's claimsMask
                ds.claimsMask = ds.claimsMask.removeValidator(i);
                // remove the validator from FeeManager's claimsMask (#redeems)
                feeManagerDS.removeValidator(i);
                break;
            }
        }
    }

    /// @notice check if consensus has been reached
    /// @param ds pointer to diamond storage
    function isConsensus(
        DiamondStorage storage ds
    ) internal view returns (bool) {
        ClaimsMask claimsMask = ds.claimsMask;
        return
            claimsMask.getAgreementMask() == claimsMask.getConsensusGoalMask();
    }

    /// @notice get one of the validators that agreed with current claim
    /// @param ds diamond storage pointer
    /// @return validator that agreed with current claim
    function getClaimerOfCurrentClaim(
        DiamondStorage storage ds
    ) internal view returns (address payable) {
        // TODO: we are always getting the first validator
        // on the array that agrees with the current claim to enter a dispute
        // should this be random?
        uint256 agreementMask = ds.claimsMask.getAgreementMask();
        for (uint256 i; i < ds.validators.length; i++) {
            if (agreementMask & (1 << i) != 0) {
                return ds.validators[i];
            }
        }
        revert("Agreeing validator not found");
    }

    /// @notice updates mask of validators that agreed with current claim
    /// @param ds diamond storage pointer
    /// @param sender address of validator that will be included in mask
    function updateClaimAgreementMask(
        DiamondStorage storage ds,
        address payable sender
    ) internal {
        uint256 validatorIndex = getValidatorIndex(ds, sender);
        ds.claimsMask = ds.claimsMask.setAgreementMask(validatorIndex);
    }

    /// @notice check if the sender is a validator
    /// @param ds pointer to diamond storage
    /// @param sender sender address
    function isValidator(
        DiamondStorage storage ds,
        address sender
    ) internal view returns (bool) {
        require(sender != address(0), "address 0");

        for (uint256 i; i < ds.validators.length; i++) {
            if (sender == ds.validators[i]) return true;
        }

        return false;
    }

    /// @notice find the validator and return the index or revert
    /// @param ds pointer to diamond storage
    /// @param sender validator address
    /// @return validator index or revert
    function getValidatorIndex(
        DiamondStorage storage ds,
        address sender
    ) internal view returns (uint256) {
        require(sender != address(0), "address 0");
        for (uint256 i; i < ds.validators.length; i++) {
            if (sender == ds.validators[i]) return i;
        }
        revert("validator not found");
    }

    /// @notice get number of claims the sender has made
    /// @param ds pointer to diamond storage
    /// @param _sender validator address
    /// @return #claims
    function getNumberOfClaimsByAddress(
        DiamondStorage storage ds,
        address payable _sender
    ) internal view returns (uint256) {
        for (uint256 i; i < ds.validators.length; i++) {
            if (_sender == ds.validators[i]) {
                return getNumberOfClaimsByIndex(ds, i);
            }
        }
        // if validator not found
        return 0;
    }

    /// @notice get number of claims by the index in the validator set
    /// @param ds pointer to diamond storage
    /// @param index the index in validator set
    /// @return #claims
    function getNumberOfClaimsByIndex(
        DiamondStorage storage ds,
        uint256 index
    ) internal view returns (uint256) {
        return ds.claimsMask.getNumClaims(index);
    }

    /// @notice get the maximum number of validators defined in validator manager
    /// @param ds pointer to diamond storage
    /// @return the maximum number of validators
    function getMaxNumValidators(
        DiamondStorage storage ds
    ) internal view returns (uint256) {
        return ds.maxNumValidators;
    }
}