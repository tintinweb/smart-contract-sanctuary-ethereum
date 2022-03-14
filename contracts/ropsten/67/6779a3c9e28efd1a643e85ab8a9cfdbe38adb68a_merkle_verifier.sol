/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: Apache-2.0.
//---------------------------------------------------------------------------//
// Copyright (c) 2021 Mikhail Komarov <[email protected]>
// Copyright (c) 2021 Ilias Khairullin <[email protected]>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//---------------------------------------------------------------------------//
pragma solidity >=0.6.0;

library merkle_verifier {

    struct path_element {
        uint256 position;
        bytes32 hash;
    }

    struct merkle_proof {
        uint256 li;
        bytes32 root;
        path_element[] path;
    }

    // only one co-element on each layer as arity is always 2
    uint256 constant LAYER_SIZE = 56; // 8  number of co-path elements on the layer
                                      // 8  co-path element position on the layer
                                      // 8  co-path element hash value length
                                      // 32 co-path element hash value

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Merkle proof has the following structure:
    // [0:8] - leaf index
    // [8:16] - root length (which is always 32 bytes in current implementation)
    // [16:48] - root
    // [48:56] - merkle tree depth
    //
    // Depth number of layers with co-path elements follows then.
    // Each layer has following structure (actually indexes begin from a certain offset):
    // [0:8] - number of co-path elements on the layer
    //  (layer_size = arity-1 actually, which (arity) is always 2 in current implementation)
    //
    // layer_size number of co-path elements for every layer in merkle proof follows then.
    // Each element has following structure (actually indexes begin from a certain offset):
    // [0:8] - co-path element position on the layer
    // [8:16] - co-path element hash value length (which is always 32 bytes in current implementation)
    // [16:48] - co-path element hash value
    function parse_merkle_proof_be(bytes memory blob, uint256 offset)
    internal pure returns (merkle_proof memory proof, uint256 proof_size) {
        require(offset < blob.length);
        uint256 len = blob.length - offset;

        // layers_offset = 56
        require(56 <= len);

        // proof.li
        assembly {
            mstore(proof, shr(0xc0, mload(add(add(blob, 0x20), offset))))
        }

//        // root_length
//        assembly {
//            tmp_value := shr(0xc0, mload(add(add(blob, 0x20), add(offset, 8))))
//        }
//        require(tmp_value == 32, uint2str(tmp_value));

        // proof.root
        assembly {
            mstore(add(proof, 0x20), mload(add(add(add(blob, 0x20), offset), 16)))
        }

        uint256 depth = 0;
        assembly {
            depth := shr(0xc0, mload(add(add(blob, 0x20), add(offset, 48))))
        }

        // only one co-element on each layer as arity is always 2
        uint256 layer_size = 8   // number of co-path elements on the layer
                           + 8   // co-path element position on the layer
                           + 8   // co-path element hash value length
                           + 32; // co-path element hash value
        proof_size = 56 + layer_size * depth;
        require(proof_size <= len);
        proof.path = new path_element[](depth);

        uint256 layer_offset = 0;
        uint256 layer_hash_offset = 0;
        for (uint256 cur_layer_i = 0; cur_layer_i < depth; cur_layer_i++) {
            layer_offset = offset + 56 + layer_size * cur_layer_i;
            // tmp_value := shr(0xc0, mload(add(add(blob, 0x20), add(layer_offset, 8))))
            // proof.path[cur_layer_i].position = tmp_value;
            assembly {
                mstore(
                    mload(
                        add(
                            mload(add(proof, 0x40)),
                            add(0x20, mul(0x20, cur_layer_i))
                        )
                    ),
                    shr(0xc0, mload(add(add(blob, 0x20), add(layer_offset, 8))))
                )
            }

            layer_hash_offset = 0x20 + layer_offset + 24;
            // hash_value := mload(add(blob, layer_hash_offset))
            // proof.path[cur_layer_i].hash = hash_value;
            assembly {
                mstore(
                    add(
                        mload(
                            add(
                                mload(add(proof, 0x40)),
                                add(0x20, mul(0x20, cur_layer_i))
                            )
                        ),
                        0x20
                    ),
                    mload(add(blob, layer_hash_offset))
                )
            }
        }
    }

    function get_merkle_proof_size_be(bytes memory blob, uint256 offset)
    internal pure returns (uint256 proof_size) {
        require(offset < blob.length);
        uint256 len = blob.length - offset;

        // layers_offset = 56
        require(56 <= len, "here");

        uint256 depth = 0;
        assembly {
            depth := shr(0xc0, mload(add(add(blob, 0x20), add(offset, 48))))
        }

        proof_size = 56 + LAYER_SIZE * depth;
        require(proof_size <= len, "here");
    }

    function verify_merkle_proof(
        merkle_proof memory proof,
        bytes32 verified_data
    ) internal pure returns (bool) {
        assembly {
            mstore(0, verified_data)
            switch mload(mload(add(mload(add(proof, 0x40)), 0x20)))
            case 0 {
                mstore(0x20, keccak256(0, 0x20))
            }
            case 1 {
                mstore(0x00, keccak256(0, 0x20))
            }
        }
        for (uint256 cur_layer_i = 0; cur_layer_i < proof.path.length - 1; cur_layer_i++) {
            assembly {
                let path_ptr := add(mload(add(proof, 0x40)), add(0x20, mul(0x20, cur_layer_i)))
                switch mload(mload(path_ptr))
                case 0 {
                    mstore(0x00, mload(add(mload(path_ptr), 0x20)))
                    switch mload(mload(add(path_ptr, 0x20)))
                    case 0 {
                        mstore(0x20, keccak256(0, 0x40))
                    }
                    case 1 {
                        mstore(0, keccak256(0, 0x40))
                    }
                }
                case 1 {
                    mstore(0x20, mload(add(mload(path_ptr), 0x20)))
                    switch mload(mload(add(path_ptr, 0x20)))
                    case 0 {
                        mstore(0x20, keccak256(0, 0x40))
                    }
                    case 1 {
                        mstore(0, keccak256(0, 0x40))
                    }
                }
            }
        }
        assembly {
            let path_ptr := add(mload(add(proof, 0x40)), add(0x20, mul(0x20, sub(mload(mload(add(proof, 0x40))), 1))))
            switch mload(mload(path_ptr))
            case 0 {
                mstore(0x00, mload(add(mload(path_ptr), 0x20)))
                verified_data := keccak256(0, 0x40)
            }
            case 1 {
                mstore(0x20, mload(add(mload(path_ptr), 0x20)))
                verified_data := keccak256(0, 0x40)
            }
        }

        return verified_data == proof.root;
    }

    function parse_verify_merkle_proof_be(bytes memory blob, uint256 offset, bytes32 verified_data)
    internal pure returns (bool result, uint256 proof_size) {
        require(offset < blob.length);
        uint256 len = blob.length - offset;

        // layers_offset = 56
        require(56 <= len);

        // proof.root
        bytes32 root;
        assembly {
            root := mload(add(add(blob, 0x20), add(offset, 16)))
        }

        uint256 depth;
        assembly {
            depth := shr(0xc0, mload(add(add(blob, 0x20), add(offset, 48))))
        }

        proof_size = 56 + LAYER_SIZE * depth;
        require(proof_size <= len);
        uint256 layer_offset = offset + 56;
        uint256 layer_hash_offset = 0;

        // hash verified_data to get corresponding merkle tree leaf
        assembly {
            let first_pos := shr(0xc0, mload(add(add(blob, 0x20), add(layer_offset, 8))))
            mstore(0, verified_data)
            switch first_pos
            case 0 {
                mstore(0x20, keccak256(0, 0x20))
            }
            case 1 {
                mstore(0x00, keccak256(0, 0x20))
            }
        }

        for (uint256 cur_layer_i = 0; cur_layer_i < depth - 1; cur_layer_i++) {
            layer_offset = offset + 56 + LAYER_SIZE * cur_layer_i;
            layer_hash_offset = 0x20 + layer_offset + 24;
            assembly {
                let pos := shr(0xc0, mload(add(add(blob, 0x20), add(layer_offset, 8))))
                let next_pos := shr(0xc0, mload(add(add(blob, 0x20), add(add(layer_offset, 8), LAYER_SIZE))))
                switch pos
                case 0 {
                    mstore(0x00, mload(add(blob, layer_hash_offset)))
                    switch next_pos
                    case 0 {
                        mstore(0x20, keccak256(0, 0x40))
                    }
                    case 1 {
                        mstore(0, keccak256(0, 0x40))
                    }
                }
                case 1 {
                    mstore(0x20, mload(add(blob, layer_hash_offset)))
                    switch next_pos
                    case 0 {
                        mstore(0x20, keccak256(0, 0x40))
                    }
                    case 1 {
                        mstore(0, keccak256(0, 0x40))
                    }
                }
            }
        }

        layer_offset = offset + 56 + LAYER_SIZE * (depth - 1);
        layer_hash_offset = 0x20 + layer_offset + 24;
        assembly {
            let pos := shr(0xc0, mload(add(add(blob, 0x20), add(layer_offset, 8))))
            switch pos
            case 0 {
                mstore(0x00, mload(add(blob, layer_hash_offset)))
                verified_data := keccak256(0, 0x40)
            }
            case 1 {
                mstore(0x20, mload(add(blob, layer_hash_offset)))
                verified_data := keccak256(0, 0x40)
            }
        }

        result = (verified_data == root);
    }
}