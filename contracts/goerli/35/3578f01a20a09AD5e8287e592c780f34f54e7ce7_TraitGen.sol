// File: contracts\utils\Base64.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.7;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// File: contracts\utils\Libraries.sol

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i; i < proof.length; ++i) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }
}

library KyodaiLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        return Base64.encode(data);
    }

    // function decodeDNA(string memory dna, ) public pure returns(uint256){}

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint;
        for (uint8 i; i < bresult.length; ++i) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; ++i) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function decodeHashIndex(string memory hash)
        internal
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < 64; i++) {
            if (
                stringToBytes32(hash) ==
                stringToBytes32(substring(TABLE, i, i + 1))
            ) return i;
        }
        revert();
    }

    function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    // function sqrt(uint256 y) internal pure returns (uint256 z) {
    //     if (y > 3) {
    //         z = y;
    //         uint256 x = y / 2 + 1;
    //         while (x < z) {
    //             z = x;
    //             x = (y / x + x) / 2;
    //         }
    //     } else if (y != 0) {
    //         z = 1;
    //     }
    // }

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
}

// File: contracts\interfaces\Interfaces.sol

interface ITraitGen {
    function genKyodaiHash(
        uint256 _t,
        address _a,
        uint256 _c,
        uint256 _gain
    ) external returns (string memory);

    function genShateiHash(
        uint256 tagId,
        uint256 _t,
        address _a,
        uint256 _c
    ) external returns (string memory);

    function genShateiLevel(
        uint256 tagId,
        uint256 _t,
        address _a,
        uint256 _c
    ) external returns (uint16);
}

interface IKyodaiDesc {
    function tokenURI(
        uint256 tokenId,
        string memory tokenHash,
        string memory baseURI
    ) external view returns (string memory);
}

interface IKyodai {
    // function ownerOf(uint256 tokenId) external view returns (address);

    function checkLevel(uint256 tokenId) external returns (uint16);
}

interface IShatei {
    // enum Class {
    //     DRUGGIE,
    //     HACKER,
    //     CYBORG
    // }

    // function ownerOf(uint256 tokenId) external view returns (address);

    function checkLevel(uint256 tokenId) external returns (uint16);

    // function checkClass(uint256 tokenId) external returns (Class);
    // function mint(uint256 tagId) external;

    function burn(uint256 tokenId, address who) external;
}

interface INeoYen {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

interface IUnderworld {
    function startDeploymentMany(
        uint256[] calldata tokenIds,
        uint8 target_,
        bool double_
    ) external;

    function stakeMany(uint256[] calldata tokenIds, address who_) external;

    function unstake(uint256 tokenId) external;
}

interface IStatManager {
    function addExp(uint256 tokenId, uint64 exp) external;

    function getLevel(uint256 tokenId) external view returns (uint16);
}

interface IDogTag {
    function mint(uint256 tokenId, address who_) external;

    function burn(
        uint256 tokenId,
        address who_,
        uint256 amount_
    ) external;
}

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

interface ILayerZeroReceiverPoly {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// File: contracts\KyodaiTraitGen.sol

//TODO combine shatei traitgen in this contract
contract TraitGen is ITraitGen {
    using KyodaiLibrary for uint8;
    uint16[][6] internal TIERS;
    uint256 internal SEED_NONCE = 0;
    mapping(string => bool) internal kyodaiHashToMinted;
    mapping(string => bool) internal shateiHashToMinted;
    mapping(uint256 => uint256) internal clanMembersCount;

    bytes32 internal entropySauce;

    constructor() {
        //TODO add more trait tiers for kyodai

        //head
        TIERS[0] = [50, 100, 100, 721, 847, 1155, 1230, 1355, 1442, 3000];

        //Misc
        TIERS[1] = [100, 100, 200, 500, 721, 1155, 7224];

        //Eyes
        TIERS[2] = [50, 100, 400, 420, 600, 721, 1559, 2050, 2050, 2050];

        //Toes
        TIERS[3] = [230, 400, 500, 721, 721, 1155, 1155, 1559, 1559, 2000];

        //Fur
        TIERS[4] = [50, 50, 300, 311, 1115, 1155, 1559, 1820, 1820, 1820];

        //BG
        TIERS[5] = [230, 500, 721, 1155, 1559, 1559, 2000];
    }

    function genKyodaiHash(
        uint256 _t,
        address _a,
        uint256 _c,
        uint256 chanceGain
    ) external override returns (string memory) {
        return hashKyodai(_t, _a, _c, chanceGain);
    }

    function genShateiHash(
        uint256 tagId,
        uint256 _t,
        address _a,
        uint256 _c
    ) external override returns (string memory) {
        return hashShatei(tagId, _t, _a, _c);
    }

    /*
     * @dev Converts a digit from 0 - 10000 into its corresponding rarity based on the given rarity tier.
     * @param _randinput The input from 0 - 10000 to use for rarity gen.
     * @param _rarityTier The tier to use.
     */
    function rarityGen(
        uint256 _randinput,
        uint8 _traitTier,
        uint256 _chance
    ) internal view returns (string memory) {
        //TODO use _chance to increase rare trait chance
        //TODO take clan type to determine next clan type (for shatei and gen2 kyodai)
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_traitTier].length; ++i) {
            uint16 thisPercentage = TIERS[_traitTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return KyodaiLibrary.substring(KyodaiLibrary.TABLE, i, i + 1);
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    /**
     * @dev Generates a 7 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */
    function hashKyodai(
        uint256 _t,
        address _a,
        uint256 _c,
        uint256 _chance
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 6 character string.
        string memory currentHash;

        for (uint8 i = 0; i < TIERS.length; ++i) {
            SEED_NONCE++;
            uint16 _randinput = getRandInput(_t, _a, _c);

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i, _chance))
            );
        }

        //TODO dogtag ID determine shatei class
        //bg hash
        // currentHash = string(
        //     abi.encodePacked(currentHash, chainIndex.toString())
        // );

        //if trait already exists
        if (kyodaiHashToMinted[currentHash])
            return hashKyodai(_t, _a, _c + 1, _chance);

        kyodaiHashToMinted[currentHash] = true;
        return currentHash;
    }

    function hashShatei(
        uint256 tagId,
        uint256 _t,
        address _a,
        uint256 _c
    ) internal returns (string memory) {
        require(_c < 10);

        // This will generate a 6 character string.
        string memory currentHash;

        for (uint8 i = 0; i < TIERS.length; ++i) {
            SEED_NONCE++;
            uint16 _randinput = getRandInput(_t, _a, _c);

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i, 0))
            );
        }

        //bg hash
        // currentHash = string(
        //     abi.encodePacked(currentHash, chainIndex.toString())
        // );

        //if trait already exists
        if (shateiHashToMinted[currentHash])
            return hashShatei(tagId, _t, _a, _c + 1);

        shateiHashToMinted[currentHash] = true;
        return currentHash;
    }

    function genShateiLevel(
        uint256 tagId,
        uint256 _t,
        address _a,
        uint256 _c
    ) external view override returns (uint16) {
        uint16[5] memory lvlTier = [4200, 2700, 1600, 1000, 500];
        uint16 _randinput = getRandInput(_t, _a, _c);
        uint16 currentLowerBound = 0;
        for (uint16 i = 0; i < lvlTier.length; ++i) {
            uint16 thisPercentage = lvlTier[i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i + (uint16((tagId - 1) / 3) * 5) + 1;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function getRandInput(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal view returns (uint16) {
        return
            uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            _t,
                            _a,
                            _c,
                            SEED_NONCE
                        )
                    )
                ) % 10000
            );
    }
}