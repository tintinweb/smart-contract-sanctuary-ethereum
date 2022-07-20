/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

interface IVerifier {
    function verify_serialized_proof(
        uint256[] memory public_inputs, 
        uint256[] memory serialized_proof
    ) external view returns (bool);
}

/**
 * @author Matter Labs
 */
contract ZkSync2BlockVerifierProxy {
    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    event NewBlockHeader(uint64 indexed blockNumber, bytes32 indexed contentHash);
    event NewRollupState(uint64 indexed blockNumber, uint64 indexed newIndexSeq, bytes32 indexed root);

    address public verifier = address(0);

    constructor(address _verifier) {
        verifier = _verifier;
    }

    struct BlockDataAndParams {
        bytes32 previous_content_hash;
        uint64 block_number;
        uint64 block_timestamp;
        uint64 new_rollup_index_seq;
        bytes32 new_rollup_state_root;
        bytes32 aux_data_hash;
        bytes32 block_params_hash;
        bytes32 recursion_node_level_vk_hash;
        bytes32 recursion_leaf_level_vk_hash;
        bytes32 recursion_circuits_set_vks_hash;
    }

    function compose_and_verify(
        BlockDataAndParams memory params,
        uint256[] memory recurisive_aggregation_input,
        // serialized proof
        uint256[] memory serialized_proof
    ) public returns (bool) {
        // did you note the strange BlockDataAndParams structure? It's just because stack is too deep...
        emit NewRollupState(params.block_number, params.new_rollup_index_seq, params.new_rollup_state_root);

        bytes memory t = abi.encodePacked(
            abi.encodePacked(
                params.block_number,
                params.block_timestamp,
                params.new_rollup_index_seq,
                params.new_rollup_state_root,
                // placeholder for zkPorter
                uint64(0),
                bytes32(0)
            )
        );

        // form a full block input
        bytes32 state_data_hash = keccak256(
            t
        );

        bytes32 new_content_hash = keccak256(abi.encodePacked(state_data_hash, params.block_params_hash, params.aux_data_hash));
        emit NewBlockHeader(params.block_number, new_content_hash);

        bytes memory tmp = abi.encodePacked(
                params.previous_content_hash,
                new_content_hash,
                params.recursion_node_level_vk_hash,
                params.recursion_leaf_level_vk_hash,
                params.recursion_circuits_set_vks_hash,
                recurisive_aggregation_input
        );
        bytes32 new_input_hash = keccak256(
            tmp
        );

        uint256 public_input = uint256(uint248(uint256(new_input_hash)));

        // now just verify a proof itself

        IVerifier v = IVerifier(verifier);
        uint256[] memory inputs = new uint256[](1);
        inputs[0] = public_input;
        bool proof_is_valid = v.verify_serialized_proof(inputs, serialized_proof);
        require(proof_is_valid, "base proof must be valid");

        // and verify recursive part that was given to us through the public input

        PairingsBn254.G1Point memory pair_with_x = PairingsBn254.new_g1_checked(recurisive_aggregation_input[0], recurisive_aggregation_input[1]);
        PairingsBn254.G1Point memory pair_with_gen = PairingsBn254.new_g1_checked(recurisive_aggregation_input[2],recurisive_aggregation_input[3]);

        PairingsBn254.G2Point memory g2_gen = PairingsBn254.new_g2([0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed],[0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa]);
        PairingsBn254.G2Point memory g2_x = PairingsBn254.new_g2([0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0],[0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55]);

        bool success = PairingsBn254.pairingProd2(pair_with_gen, g2_gen, pair_with_x, g2_x);
        require(success, "inner aggregated proof must be valid");

        return true;
    }

    fallback() external {}
}


library PairingsBn254 {
    uint256 constant q_mod = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    } 
    
    struct Fr {
        uint256 value;
    }
    
    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod);
        return Fr({value: fr});
    }
    
    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }
    
    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }
    
    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0);
        return pow(fr, r_mod-2);
    }
    
    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }
    
    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }
    
    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }
    
    function pow(Fr memory self, uint256 power) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        return Fr({value: result[0]});
    }
    
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    
    function new_g1(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    // function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
    function new_g1_checked(uint256 x, uint256 y) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }
        
        // check encoding
        require(x < q_mod, "x axis isn't valid");
        require(y < q_mod, "y axis isn't valid");
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3        
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs, "is not on curve");

        return G1Point(x, y);
    }
    
    function new_g2(uint256[2] memory x, uint256[2] memory y) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }
    
    function copy_g1(G1Point memory self) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form
        
        return G2Point(
            [0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed],
            [0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa]
        );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(G1Point memory p1, G1Point memory p2)
        internal view returns (G1Point memory r)
    {
        point_add_into_dest(p1, p2, r);
        return r;
    }
    
    function point_add_assign(G1Point memory p1, G1Point memory p2)
        internal view
    {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(G1Point memory p1, G1Point memory p2, G1Point memory dest)
        internal view
    {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }
    
    function point_sub_assign(G1Point memory p1, G1Point memory p2)
        internal view
    {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(G1Point memory p1, G1Point memory p2, G1Point memory dest)
        internal view
    {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function point_mul(G1Point memory p, Fr memory s)
        internal view returns (G1Point memory r)
    {
        // https://eips.ethereum.org/EIPS/eip-197
        // Elliptic curve points are encoded as a Jacobian pair (X, Y) where the point at infinity is encoded as (0, 0)
        // TODO
        if(p.X == 0 && p.Y == 1){
            p.Y = 0;
        }
        point_mul_into_dest(p, s, r);
        return r;
    }
    
    function point_mul_assign(G1Point memory p, Fr memory s)
        internal view
    {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(G1Point memory p, Fr memory s, G1Point memory dest)
        internal view
    {
        uint[3] memory input;   
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }
    
    function pairing(G1Point[] memory p1, G2Point[] memory p2)
        internal view returns (bool)
    {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2)
        internal view returns (bool)
    {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}