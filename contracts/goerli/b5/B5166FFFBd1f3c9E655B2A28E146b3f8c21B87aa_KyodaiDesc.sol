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

// File: contracts\KyodaiDescriptor-test.sol

//TODO change all from MiniMiao to CyberKyodai
//TODO add off-chain IPFS for PNG for twitter profile picture. So the art is both on and off chain
contract KyodaiDesc is IKyodaiDesc {
    function tokenURI(
        uint256 tokenId,
        string memory tokenHash,
        string memory baseURI
    ) external view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    KyodaiLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Cyber Kyodai #',
                                    KyodaiLibrary.toString(tokenId),
                                    '", "description": "Cyber Kyodai  is a collection of 10,000 unique smol cats. Omnichain NFT so you can pspsps your cat accross chains. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API.","image": ',
                                    baseURI,
                                    tokenId,
                                    '"vector": "data:image/svg+xml;base64, ',
                                    KyodaiLibrary.encode(
                                        bytes(hashToSVG(tokenHash))
                                    ),
                                    '","attributes":',
                                    hashToMetadata(tokenHash),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
        internal
        view
        returns (string memory)
    {
        string[6] memory parts;
        //eyes
        // parts[0] =
        // getEyesSVG(
        //     KyodaiLibrary.parseInt(KyodaiLibrary.substring(_hash, 2, 3))
        // );
        parts[0] = getEyesSVG(
            KyodaiLibrary.decodeHashIndex(KyodaiLibrary.substring(_hash, 2, 3))
        );
        // misc
        // parts[1] = getMiscgSVG(
        //     KyodaiLibrary.parseInt(KyodaiLibrary.substring(_hash, 1, 2))
        // );
        parts[1] = getMiscgSVG(
            KyodaiLibrary.decodeHashIndex(KyodaiLibrary.substring(_hash, 1, 2))
        );

        //head
        // parts[2] = headSVGs[
        //     KyodaiLibrary.parseInt(KyodaiLibrary.substring(_hash, 0, 1))
        // ];
        parts[2] = headSVGs[
            KyodaiLibrary.decodeHashIndex(KyodaiLibrary.substring(_hash, 0, 1))
        ];

        //toes
        parts[3] = string(
            abi.encodePacked(
                '<path style="fill:',
                // toeColors[
                //     KyodaiLibrary.parseInt(KyodaiLibrary.substring(_hash, 3, 4))
                // ],
                toeColors[
                    KyodaiLibrary.decodeHashIndex(
                        KyodaiLibrary.substring(_hash, 3, 4)
                    )
                ],
                '" d="M8 16h1v1H8zm2 0h1v1h-1zm4 0h1v1h-1zm2 0h1v1h-1z"/>'
            )
        );

        //body
        // parts[4] = getBodySVG(
        //     KyodaiLibrary.parseInt(KyodaiLibrary.substring(_hash, 4, 5))
        // );
        parts[4] = getBodySVG(
            KyodaiLibrary.decodeHashIndex(KyodaiLibrary.substring(_hash, 4, 5))
        );

        //bg
        // parts[5] = string(
        //     abi.encodePacked(
        //         '<path style="fill:',
        //         bgColors[
        //             KyodaiLibrary.parseInt(KyodaiLibrary.substring(_hash, 5, 6))
        //         ],
        //         '" d="M0 17h24v7H0ZM0 0h24v17H0Z"/>'
        //     )
        // );
        parts[5] = string(
            abi.encodePacked(
                '<path style="fill:',
                bgColors[
                    KyodaiLibrary.decodeHashIndex(
                        KyodaiLibrary.substring(_hash, 5, 6)
                    )
                ],
                '" d="M0 17h24v7H0ZM0 0h24v17H0Z"/>'
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg  xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24" style="shape-rendering:crispedges"> ',
                    parts[5],
                    parts[4],
                    parts[3],
                    parts[2],
                    parts[1],
                    parts[0],
                    "<style>rect{width:1px;height:1px;}</style></svg>"
                )
            );
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash)
        internal
        view
        returns (string memory)
    {
        string memory metadataString;

        for (uint8 i = 0; i < 6; ++i) {
            uint8 thisTraitIndex = KyodaiLibrary.parseInt(
                KyodaiLibrary.substring(_hash, i, i + 1)
            );
            string memory traitType;
            string memory traitName;
            if (i == 0) {
                traitType = "Head";
                traitName = headNames[thisTraitIndex];
            }
            if (i == 1) {
                traitType = "Misc";
                traitName = miscNames[thisTraitIndex];
            }
            if (i == 2) {
                traitType = "Eyes";
                traitName = eyeNames[thisTraitIndex];
            }
            if (i == 3) {
                traitType = "Toes";
                traitName = toeNames[thisTraitIndex];
            }
            if (i == 4) {
                traitType = "Fur";
                traitName = furNames[thisTraitIndex];
            }
            if (i == 5) {
                traitType = "Birth Chain";
                traitName = bgNames[thisTraitIndex];
            }
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    traitName,
                    '"}'
                )
            );

            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function getBodySVG(uint256 traitIndex)
        internal
        view
        returns (string memory)
    {
        string memory outlineColor;
        string memory furColor;

        outlineColor = outlineColors[traitIndex];
        furColor = furColors[traitIndex];
        return
            string(
                abi.encodePacked(
                    string(
                        abi.encodePacked(
                            '<path style="fill:',
                            outlineColor,
                            '" d="M5 8h1v1H5Zm0 1h1v1H5Zm0 1h1v1H5Zm0 1h1v1H5Zm0 1h1v1H5Zm1 1h1v1H6Zm1 3h1v1H7Zm0-1h1v1H7Zm0-1h1v1H7Zm1 0h1v1H8Zm1 0h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm-5 3h1v1H7Zm1 0h1v1H8Zm1-1h1v1H9Zm0 1h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm2-1h1v1h-1zm-1 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1Zm-1-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm1 1h1v1h-1zm0 1h1v1h-1zm-1 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1Zm-1-1h1v1h-1zm-1 1h1v1h-1zm-1 1h1v1h-1zm-1 0h1v1h-1ZM9 8h1v1H9ZM8 8h1v1H8ZM7 7h1v1H7ZM6 6h1v1H6ZM5 7h1v1H5Z"/>'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            '<path style="fill:',
                            furColor,
                            '" d="M8 15h1v1H8Zm1 0h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-8 1h1v1H8Zm2 0h1v1h-1zm-1 0h1v1H9Zm3 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1H9Zm-1 0h1v1H8Zm3 2h1v1h-1zm-1 0h1v1h-1zm-2 0h1v1H8Zm-1 0h1v1H7Zm0-2h1v1H7Zm-1 0h1v1H6Zm0 1h1v1H6Zm0 1h1v1H6Zm1 1h1v1H7Zm1 0h1v1H8Zm1 0h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm1-1h1v1h-1zm0 1h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-2h1v1h-1zm-1 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1ZM9 9h1v1H9ZM8 9h1v1H8ZM7 9h1v1H7ZM6 9h1v1H6Zm1-1h1v1H7Zm2 4h1v1H9ZM6 7h1v1H6Z"/>'
                        )
                    ),
                    '<path style="fill:#ff8acb" d="M13 8h1v1h-1ZM6 8h1v1H6Z"/>'
                )
            );
    }

    function getEyesSVG(uint256 traitIndex)
        internal
        view
        returns (string memory)
    {
        string memory svgString;
        if (traitIndex == 0) {
            svgString = '<rect style="fill:#ffef00" x="7" y="11"/><rect style="fill:#00a1ff" x="11" y="11"/>';
        } else if (traitIndex == 1) {
            svgString = '<path style="fill:#ec3b4b" d="M0 11h11v1H0Zm11 0h1v1h-1z"/>';
        } else {
            svgString = string(
                abi.encodePacked(
                    '<path style="fill:',
                    eyeColors[traitIndex - 2],
                    '"  d="M11 11h1v1h-1zm-4 0h1v1H7Z"/>'
                )
            );
        }
        return svgString;
    }

    function getMiscgSVG(uint256 traitIndex)
        internal
        view
        returns (string memory)
    {
        string memory svgString;
        if (traitIndex == 0) {
            svgString = string(abi.encodePacked(miscSVGs[0], miscSVGs[1]));
        } else if (traitIndex == 1) {
            svgString = string(abi.encodePacked(miscSVGs[0], miscSVGs[2]));
        } else {
            svgString = miscSVGs[traitIndex - 2];
        }
        return svgString;
    }

    string[7] bgNames = ["ETH", "POLY", "BNB", "AVAX", "FTM", "OPT", "ARB"];
    string[10] furNames = [
        "Ghost",
        "Gold",
        "Green",
        "Blue",
        "Spinx",
        "Orange",
        "Brown",
        "Black",
        "White",
        "Grey"
    ];
    string[10] eyeNames = [
        "Heterochromia",
        "Laser",
        "Cyan",
        "Purple",
        "Blue",
        "Red",
        "Orange",
        "Green",
        "Yellow",
        "Black"
    ];
    string[10] toeNames = [
        "Cyan",
        "Lime",
        "Purple",
        "Blue",
        "Violet",
        "Green",
        "Red",
        "Orange",
        "Mocha",
        "Grey"
    ];
    string[10] headNames = [
        "Nounish",
        "Halo",
        "Crown",
        "Ninja Headband",
        "Bandana",
        "Flower",
        "Headphone",
        "Ribbon",
        "Cap",
        "None"
    ];

    string[7] miscNames = [
        "Hoverboard + Rainbow",
        "Skateboard + Rainbow",
        "Rainbow",
        "Hoverboard",
        "Skateboard",
        "Cigarette",
        "None"
    ];

    string[7] bgColors = [
        "#d2d2d2",
        "#f8daff",
        "#fff1b0",
        "#ffc8d4",
        "#bbf2f7",
        "#ffd8a8",
        "#c9d2ff"
    ];

    string[10] outlineColors = [
        "#84ffd1",
        "#e5dd65",
        "#82d1c4",
        "#91beeb",
        "#ffa0b5",
        "#ffac71",
        "#c49484",
        "#302c57",
        "#f1eeea",
        "#9592ad"
    ];

    string[10] furColors = [
        "#ffffff",
        "#fff88c",
        "#c9fce9",
        "#c9e5fa",
        "#ffc8d4",
        "#ffc79f",
        "#ebbd91",
        "#433f6b",
        "#ffffff",
        "#b8b6c4"
    ];

    string[8] eyeColors = [
        "#42fcff",
        "#ff00ff",
        "#0000ff",
        "#ff0000",
        "#ff8000",
        "#00ff00",
        "#ffef00",
        "#000000"
    ];

    string[10] toeColors = [
        "#00cccc",
        "#99cc00",
        "#cc00cc",
        "#0000cc",
        "#6600cc",
        "#00cc00",
        "#cc0000",
        "#cc6600",
        "#e8ae00",
        "#767676"
    ];
    string[10] headSVGs = [
        '<path style="fill:#ff5363" d="M13 11h2v1h-2zm-2 1h1v1h-1zm1-1h1v2h-1zm-2 0h1v2h-1zm0-1h3v1h-3zm-1 1h1v1H9Zm-2 1h1v1H7Zm1-1h1v2H8Zm-2 0h1v2H6Zm0-1h3v1H6Zm-1 1h1v1H5Z"/>',
        '<path style="fill:#ffff8e" d="M12 5h1v1h-1ZM7 5h1v1H7Zm1 1h4v1H8Zm0-2h4v1H8Z"/>',
        '<path style="fill:#ffff8e" d="M10 5h1v1h-1ZM8 5h1v1H8Zm0 1h5v1H8Zm0 1h4v1H8Zm4-2h1v1h-1z"/>',
        '<path style="fill:#e5ddff" d="M7 9h5v1H7z"/><path style="fill:#5c3c68" d="M15 8h1v1h-1ZM6 8h7v1H6Zm6 1h3v1h-3ZM5 9h2v1H5Zm10 2h1v1h-1ZM5 10h10v1H5Z"/>',
        '<path style="fill:#ff5363" d="M8 7h4v1H8ZM7 8h6v1H7Zm8 2h1v1h-1zm0-2h1v1h-1ZM5 9h10v1H5Z"/>',
        '<path style="fill:#c479ea" d="M11 9h1v1h-1zm1-1h1v1h-1Zm-1-1h1v1h-1zm-1 1h1v1h-1z"/><path style="fill:#ffff8e" d="M11 8h1v1h-1z"/>',
        '<path style="fill:#1c1f44" d="M7 6h6v1H7ZM5 7h2v3H5Zm8 0h2v3h-2z"/>',
        '<path style="fill:#ff5363" d="M11 7h1v1h-1zm1 1h1v1h-1z"/>',
        '<path style="fill:#5ed690" d="M9 6h2v1H9ZM8 7h4v1H8ZM7 8h5v1H7ZM6 8h1v1H6Z"/>',
        ""
    ];

    string[5] miscSVGs = [
        '<path style="fill:#93ffab" d="M22 16h2v1h-2zm-2-1h2v1h-2zm-2 1h2v1h-2z"/><path style="fill:#ffff8e" d="M22 15h2v1h-2zm-2-1h2v1h-2zm-2 1h2v1h-2z"/><path style="fill:#ff8792" d="M22 14h2v1h-2zm-2-1h2v1h-2zm-2 1h2v1h-2z"/>',
        '<path style="fill:#ff81cb" d="M19 17h1v1h-1ZM6 18h13v1H6Zm-1-1h1v1H5Z"/>',
        '<path style="fill:#907864" d="M19 17h1v1h-1ZM6 18h13v1H6Zm-1-1h1v1H5Z"/><path style="fill:#433f6b" d="M15 19h2v2h-2zm-7 0h2v2H8Z"/>',
        '<path style="fill:#4d4c5d" d="M3 13h6v1H3z"/><path style="fill:#fafafa" d="M3 8h1v4H3z"/>',
        ""
    ];
}