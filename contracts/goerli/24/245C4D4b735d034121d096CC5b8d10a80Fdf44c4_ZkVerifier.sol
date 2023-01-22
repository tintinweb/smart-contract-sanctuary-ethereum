pragma solidity ^0.8.0;

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
    return
      G2Point(
        [
          10857046999023057135944570762232829481370756359578518086990519993285655852781,
          11559732032986387107991004021392285783925812861821192530917403151452391805634
        ],
        [
          8495653923123431417604973247489272438418190587263600148770280649306958101930,
          4082367875863433681332203403145435568316851327593401208105741076214120093531
        ]
      );
  }

  /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory) {
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
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success);
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
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success);
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
    require(p1.length == p2.length);
    uint256 elements = p1.length;
    uint256 inputSize = elements * 6;
    uint256[] memory input = new uint256[](inputSize);
    for (uint256 i = 0; i < elements; i++) {
      input[i * 6 + 0] = p1[i].X;
      input[i * 6 + 1] = p1[i].Y;
      input[i * 6 + 2] = p2[i].X[1];
      input[i * 6 + 3] = p2[i].X[0];
      input[i * 6 + 4] = p2[i].Y[1];
      input[i * 6 + 5] = p2[i].Y[0];
    }
    uint256[1] memory out;
    bool success;
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
    require(success);
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

contract ZkVerifier {
  using Pairing for *;
  struct VerifyingKey {
    Pairing.G1Point alpha;
    Pairing.G2Point beta;
    Pairing.G2Point gamma;
    Pairing.G2Point delta;
    Pairing.G1Point[] gamma_abc;
  }
  struct Proof {
    Pairing.G1Point a;
    Pairing.G2Point b;
    Pairing.G1Point c;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alpha = Pairing.G1Point(
      uint256(
        0x01928ae7f72ff85ce62438a6692963953aad13ff40c66ded6965839d847fa4d3
      ),
      uint256(
        0x2e4f25f6715432bcea98096d65fabcf6b7402faa38dc9837c520199b7ddc184d
      )
    );
    vk.beta = Pairing.G2Point(
      [
        uint256(
          0x17d40e0c073ec238162636cb4b856cdda0bc0f21334f5ce69d818c38133e94b0
        ),
        uint256(
          0x1b2f6dee717940d6cd5f2f849ede76b5cfa64dfd3bc1809f69c25aa24da0ba56
        )
      ],
      [
        uint256(
          0x1c2584f4826d03458f780231c554cc7db9ca44a95aea26edb2076558a52fa7d9
        ),
        uint256(
          0x0f08a608e6673a68da75a942b6cc1c03fd9b113f7f98eb4cbd69af0a2f7d5b5e
        )
      ]
    );
    vk.gamma = Pairing.G2Point(
      [
        uint256(
          0x2b9800a9360b4406025d65f8826a1a40f5baa042e98ab16ebd5900b629960e8b
        ),
        uint256(
          0x106d75801ed7fb85efb2321cb1516948e8cf20e7b880e68e2574fac881778973
        )
      ],
      [
        uint256(
          0x09febf49a3e54c4bc1af4392a9fbb3586a87fad186363a9bc0cd8f083c7381a5
        ),
        uint256(
          0x21a39912f4e54e93a9bac674e8983dfdda10aaddd3410ccd324325af241780ff
        )
      ]
    );
    vk.delta = Pairing.G2Point(
      [
        uint256(
          0x116b747d0226159864f18c554549222dad8814b728d32bf6955847c0a2019195
        ),
        uint256(
          0x20e04b220a649463b98c28cad718e7469f35b2008ba46442978a8f7cb5cc0fda
        )
      ],
      [
        uint256(
          0x0f749124a5764a1b1730f3cabda9e7461c60810e478f4588158f2a3e2f44837f
        ),
        uint256(
          0x1fda059439128f42e7e420c12161ac45a114518cb27bc98107a634ea0f89e76b
        )
      ]
    );
    vk.gamma_abc = new Pairing.G1Point[](4);
    vk.gamma_abc[0] = Pairing.G1Point(
      uint256(
        0x01da8d204e2cea4646e96efaea4accaa6cb18cee3a3fe460d19238dcefe9e1d9
      ),
      uint256(
        0x04a298c520e4ab5e6c7ee6b3c695b4e2299e6420958f9f7d0153945de0a3ce57
      )
    );
    vk.gamma_abc[1] = Pairing.G1Point(
      uint256(
        0x00934cbbcb0da71a1a4b79124def69fcc07d7701a0187c6efde20127a616892b
      ),
      uint256(
        0x06ce9b556c13774b176c709a78d6710f0d58df854288687c9fe945ca505481c2
      )
    );
    vk.gamma_abc[2] = Pairing.G1Point(
      uint256(
        0x04985fbae0fc43d09674abd35873ca2c3c3adc3d5e00b6e1970f0ad5ed76e8bb
      ),
      uint256(
        0x0f8685c5dca5fd7a3c3536f5f8b6289e5fbd5d6f9971f53e28e7cf85ac2145f9
      )
    );
    vk.gamma_abc[3] = Pairing.G1Point(
      uint256(
        0x279f01e8181d9696df883bca63fa8a388004e800d5d538e5473c7aba9a1a04c6
      ),
      uint256(
        0x0641741a432944f3f259f7aec63e7f6b64c08cbf025a14c76739f8cdbc071c60
      )
    );
  }

  function verify(uint256[] memory input, Proof memory proof)
    internal
    view
    returns (uint256)
  {
    uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    VerifyingKey memory vk = verifyingKey();
    require(input.length + 1 == vk.gamma_abc.length);
    // Compute the linear combination vk_x
    Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
    for (uint256 i = 0; i < input.length; i++) {
      require(input[i] < snark_scalar_field);
      vk_x = Pairing.addition(
        vk_x,
        Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i])
      );
    }
    vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
    if (
      !Pairing.pairingProd4(
        proof.a,
        proof.b,
        Pairing.negate(vk_x),
        vk.gamma,
        Pairing.negate(proof.c),
        vk.delta,
        Pairing.negate(vk.alpha),
        vk.beta
      )
    ) return 1;
    return 0;
  }

  function verifyTx(Proof memory proof, uint256[3] memory input)
    public
    view
    returns (bool r)
  {
    uint256[] memory inputValues = new uint256[](3);

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