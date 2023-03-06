// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '../../utils/LightClientUpdateVerifier.sol';
import '../../spec/BeaconChain.sol';

contract BeaconLightClient is LightClientUpdateVerifier {
  struct LightClientUpdate {
    bytes32 attested_header_root;
    bytes32 finalized_header_root;
    bytes32 finalized_execution_state_root;
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
  }

  bytes32 _optimistic_header_root;

  bytes32 _finalized_header_root;

  bytes32 _finalized_execution_state_root;

  constructor(
    bytes32 __optimistic_header_root,
    bytes32 __finalized_header_root,
    bytes32 __execution_state_root
  ) {
    _optimistic_header_root = __optimistic_header_root;
    _finalized_header_root = __finalized_header_root;
    _finalized_execution_state_root = __execution_state_root;
  }

  function execution_state_root() public view returns (bytes32) {
    return _finalized_execution_state_root;
  }

  function optimistic_header_root() public view returns (bytes32) {
    return _optimistic_header_root;
  }

  function finalized_header_root() public view returns (bytes32) {
    return _finalized_header_root;
  }

  function light_client_update(LightClientUpdate calldata update)
    external
    payable
  {
    require(
      verifyUpdate(
        update.a,
        update.b,
        update.c,
        optimistic_header_root(),
        update.attested_header_root,
        update.finalized_header_root,
        update.finalized_execution_state_root
      ),
      '!proof'
    );

    _optimistic_header_root = update.attested_header_root;
    _finalized_header_root = update.finalized_header_root;
    _finalized_execution_state_root = update.finalized_execution_state_root;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import './Verifier.sol';

contract LightClientUpdateVerifier is Verifier {
  function verifyUpdate(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    bytes32 prev_header_hash,
    bytes32 next_header_hash,
    bytes32 finalized_header_root,
    bytes32 execution_state_root
  ) internal view returns (bool) {
    bytes32 commitment = hash(
      prev_header_hash,
      next_header_hash,
      finalized_header_root,
      execution_state_root
    );

    uint256[2] memory input;

    input[0] = (uint256(commitment) & (((1 << 253) - 1) << 3)) >> 3;
    input[1] = (uint256(commitment) & ((1 << 3) - 1));

    return verifyProof(a, b, c, input);
  }

  function hash(
    bytes32 a,
    bytes32 b,
    bytes32 c,
    bytes32 d
  ) private pure returns (bytes32) {
    bytes memory concatenated = abi.encodePacked(a, b, c, d);
    return sha256(concatenated);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './MerkleProof.sol';

contract BeaconChain is MerkleProof {
  struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposer_index;
    bytes32 parent_root;
    bytes32 state_root;
    bytes32 body_root;
  }

  function hash_tree_root(BeaconBlockHeader memory beacon_header)
    internal
    pure
    returns (bytes32)
  {
    bytes32[] memory leaves = new bytes32[](5);
    leaves[0] = bytes32(to_little_endian_64(beacon_header.slot));
    leaves[1] = bytes32(to_little_endian_64(beacon_header.proposer_index));
    leaves[2] = beacon_header.parent_root;
    leaves[3] = beacon_header.state_root;
    leaves[4] = beacon_header.body_root;
    return merkle_root(leaves);
  }

  function merkle_root(bytes32[] memory leaves)
    internal
    pure
    returns (bytes32)
  {
    uint256 len = leaves.length;
    if (len == 0) return bytes32(0);
    else if (len == 1) return hash(abi.encodePacked(leaves[0]));
    else if (len == 2) return hash_node(leaves[0], leaves[1]);
    uint256 bottom_length = get_power_of_two_ceil(len);
    bytes32[] memory o = new bytes32[](bottom_length * 2);
    for (uint256 i = 0; i < len; ++i) {
      o[bottom_length + i] = leaves[i];
    }
    for (uint256 i = bottom_length - 1; i > 0; --i) {
      o[i] = hash_node(o[i * 2], o[i * 2 + 1]);
    }
    return o[1];
  }

  //  Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
  function get_power_of_two_ceil(uint256 x) internal pure returns (uint256) {
    if (x <= 1) return 1;
    else if (x == 2) return 2;
    else return 2 * get_power_of_two_ceil((x + 1) >> 1);
  }

  function to_little_endian_64(uint64 value) internal pure returns (bytes8 r) {
    return bytes8(reverse64(value));
  }

  function reverse64(uint64 input) internal pure returns (uint64 v) {
    v = input;

    // swap bytes
    v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

    // swap 2-byte long pairs
    v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

    // swap 4-byte long pairs
    v = (v >> 32) | (v << 32);
  }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library Pairing {
  struct G1Point {
    uint256 X;
    uint256 Y;
  }
  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] X;
    uint256[2] Y;
  }

  /// @return the generator of G1
  function P1() internal pure returns (G1Point memory) {
    return G1Point(1, 2);
  }

  /// @return the generator of G2
  function P2() internal pure returns (G2Point memory) {
    // Original code point
    return
      G2Point(
        [
          11559732032986387107991004021392285783925812861821192530917403151452391805634,
          10857046999023057135944570762232829481370756359578518086990519993285655852781
        ],
        [
          4082367875863433681332203403145435568316851327593401208105741076214120093531,
          8495653923123431417604973247489272438418190587263600148770280649306958101930
        ]
      );

    /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    // The prime q in the base field F_q for G1
    uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    return G1Point(p.X, q - (p.Y % q));
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, 'pairing-add-failed');
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, 'pairing-mul-failed');
  }

  /// @return the result of computing the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
  /// return true.
  function pairing(G1Point[] memory p1, G2Point[] memory p2)
    internal
    view
    returns (bool)
  {
    require(p1.length == p2.length, 'pairing-lengths-failed');
    uint256 elements = p1.length;
    uint256 inputSize = elements * 6;
    uint256[] memory input = new uint256[](inputSize);
    for (uint256 i = 0; i < elements; i++) {
      input[i * 6 + 0] = p1[i].X;
      input[i * 6 + 1] = p1[i].Y;
      input[i * 6 + 2] = p2[i].X[0];
      input[i * 6 + 3] = p2[i].X[1];
      input[i * 6 + 4] = p2[i].Y[0];
      input[i * 6 + 5] = p2[i].Y[1];
    }
    uint256[1] memory out;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        add(input, 0x20),
        mul(inputSize, 0x20),
        out,
        0x20
      )
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, 'pairing-opcode-failed');
    return out[0] != 0;
  }

  /// Convenience method for a pairing check for two pairs.
  function pairingProd2(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](2);
    G2Point[] memory p2 = new G2Point[](2);
    p1[0] = a1;
    p1[1] = b1;
    p2[0] = a2;
    p2[1] = b2;
    return pairing(p1, p2);
  }

  /// Convenience method for a pairing check for three pairs.
  function pairingProd3(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](3);
    G2Point[] memory p2 = new G2Point[](3);
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    return pairing(p1, p2);
  }

  /// Convenience method for a pairing check for four pairs.
  function pairingProd4(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](4);
    G2Point[] memory p2 = new G2Point[](4);
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;
    return pairing(p1, p2);
  }
}

contract Verifier {
  using Pairing for *;
  struct VerifyingKey {
    Pairing.G1Point alfa1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] IC;
  }
  struct Proof {
    Pairing.G1Point A;
    Pairing.G2Point B;
    Pairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alfa1 = Pairing.G1Point(
      20491192805390485299153009773594534940189261866228447918068658471970481763042,
      9383485363053290200918347156157836566562967994039712273449902621266178545958
    );

    vk.beta2 = Pairing.G2Point(
      [
        4252822878758300859123897981450591353533073413197771768651442665752259397132,
        6375614351688725206403948262868962793625744043794305715222011528459656738731
      ],
      [
        21847035105528745403288232691147584728191162732299865338377159692350059136679,
        10505242626370262277552901082094356697409835680220590971873171140371331206856
      ]
    );
    vk.gamma2 = Pairing.G2Point(
      [
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781
      ],
      [
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
      ]
    );
    vk.delta2 = Pairing.G2Point(
      [
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781
      ],
      [
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
      ]
    );
    vk.IC = new Pairing.G1Point[](3);

    vk.IC[0] = Pairing.G1Point(
      2392822642995661005171555009488844088176954870319064822645652947726621638605,
      19622522825149758925846860792412025256115126012155814217617363920694413818355
    );

    vk.IC[1] = Pairing.G1Point(
      18954309538486684917164156025490115873263619829298537818491608339093110373239,
      9185979323690985945295229185629666150037261362996364025399775430832808015475
    );

    vk.IC[2] = Pairing.G1Point(
      16010199862829093037919343395088636768729563763409851148470370813861437396580,
      16457624759801426240698376800316458056002370626757831987377706347248123201023
    );
  }

  function verify(uint256[] memory input, Proof memory proof)
    internal
    view
    returns (uint256)
  {
    uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    VerifyingKey memory vk = verifyingKey();
    require(input.length + 1 == vk.IC.length, 'verifier-bad-input');
    // Compute the linear combination vk_x
    Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
    for (uint256 i = 0; i < input.length; i++) {
      require(input[i] < snark_scalar_field, 'verifier-gte-snark-scalar-field');
      vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
    }
    vk_x = Pairing.addition(vk_x, vk.IC[0]);
    if (
      !Pairing.pairingProd4(
        Pairing.negate(proof.A),
        proof.B,
        vk.alfa1,
        vk.beta2,
        vk_x,
        vk.gamma2,
        proof.C,
        vk.delta2
      )
    ) return 1;
    return 0;
  }

  /// @return r  bool true if proof is valid
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[2] memory input
  ) public view returns (bool r) {
    Proof memory proof;
    proof.A = Pairing.G1Point(a[0], a[1]);
    proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = Pairing.G1Point(c[0], c[1]);
    uint256[] memory inputValues = new uint256[](input.length);
    for (uint256 i = 0; i < input.length; i++) {
      inputValues[i] = input[i];
    }
    if (verify(inputValues, proof) == 0) {
      return true;
    } else {
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MerkleProof {
  // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
  function is_valid_merkle_branch(
    bytes32 leaf,
    bytes32[] memory branch,
    uint64 depth,
    uint64 index,
    bytes32 root
  ) internal pure returns (bool) {
    bytes32 value = leaf;
    for (uint256 i = 0; i < depth; ++i) {
      if ((index / (2**i)) % 2 == 1) {
        value = hash_node(branch[i], value);
      } else {
        value = hash_node(value, branch[i]);
      }
    }

    return value == root;
  }

  function hash_node(bytes32 left, bytes32 right)
    internal
    pure
    returns (bytes32)
  {
    return hash(abi.encodePacked(left, right));
  }

  function hash(bytes memory value) internal pure returns (bytes32) {
    return sha256(value);
  }
}