// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "../libraries/BN254.sol";

interface IPlonkVerifier {
    // Flatten out TurboPlonk proof
    struct PlonkProof {
        // the first 5 are 4 inputs and 1 output wire poly commmitments
        // i.e., batch_proof.wires_poly_comms_vec.iter()
        // wire0 is 32 bytes which is a pointer to BN254.G1Point
        BN254.G1Point wire0; // 0x00
        BN254.G1Point wire1; // 0x20
        BN254.G1Point wire2; // 0x40
        BN254.G1Point wire3; // 0x60
        BN254.G1Point wire4; // 0x80
        // the next one is the  product permutation poly commitment
        // i.e., batch_proof.prod_perm_poly_comms_vec.iter()
        BN254.G1Point prodPerm; // 0xA0
        // the next 5 are split quotient poly commmitments
        // i.e., batch_proof.split_quot_poly_comms
        BN254.G1Point split0; // 0xC0
        BN254.G1Point split1; // 0xE0
        BN254.G1Point split2; // 0x100
        BN254.G1Point split3; // 0x120
        BN254.G1Point split4; // 0x140
        // witness poly com for aggregated opening at `zeta`
        // i.e., batch_proof.opening_proof
        BN254.G1Point zeta; // 0x160
        // witness poly com for shifted opening at `zeta * \omega`
        // i.e., batch_proof.shifted_opening_proof
        BN254.G1Point zetaOmega; // 0x180
        // wire poly eval at `zeta`
        uint256 wireEval0; // 0x1A0
        uint256 wireEval1; // 0x1C0
        uint256 wireEval2; // 0x1E0
        uint256 wireEval3; // 0x200
        uint256 wireEval4; // 0x220
        // extended permutation (sigma) poly eval at `zeta`
        // last (sigmaEval4) is saved by Maller Optimization
        uint256 sigmaEval0; // 0x240
        uint256 sigmaEval1; // 0x260
        uint256 sigmaEval2; // 0x280
        uint256 sigmaEval3; // 0x2A0
        // product permutation poly eval at `zeta * \omega`
        uint256 prodPermZetaOmegaEval; // 0x2C0
    }

    // The verifying key for Plonk proofs.
    struct VerifyingKey {
        uint256 domainSize; // 0x00
        uint256 numInputs; // 0x20
        // commitment to extended perm (sigma) poly
        BN254.G1Point sigma0; // 0x40
        BN254.G1Point sigma1; // 0x60
        BN254.G1Point sigma2; // 0x80
        BN254.G1Point sigma3; // 0xA0
        BN254.G1Point sigma4; // 0xC0
        // commitment to selector poly
        // first 4 are linear combination selector
        BN254.G1Point q1; // 0xE0
        BN254.G1Point q2; // 0x100
        BN254.G1Point q3; // 0x120
        BN254.G1Point q4; // 0x140
        // multiplication selector for 1st, 2nd wire
        BN254.G1Point qM12; // 0x160
        // multiplication selector for 3rd, 4th wire
        BN254.G1Point qM34; // 0x180
        // output selector
        BN254.G1Point qO; // 0x1A0
        // constant term selector
        BN254.G1Point qC; // 0x1C0
        // rescue selector qH1 * w_ai^5
        BN254.G1Point qH1; // 0x1E0
        // rescue selector qH2 * w_bi^5
        BN254.G1Point qH2; // 0x200
        // rescue selector qH3 * w_ci^5
        BN254.G1Point qH3; // 0x220
        // rescue selector qH4 * w_di^5
        BN254.G1Point qH4; // 0x240
        // elliptic curve selector
        BN254.G1Point qEcc; // 0x260
    }

    /// @dev Batch verify multiple TurboPlonk proofs.
    /// @param verifyingKeys An array of verifying keys
    /// @param publicInputs A two-dimensional array of public inputs.
    /// @param proofs An array of Plonk proofs
    /// @param extraTranscriptInitMsgs An array of bytes from
    /// transcript initialization messages
    /// @return _ A boolean that is true for successful verification, false otherwise
    function batchVerify(
        VerifyingKey[] memory verifyingKeys,
        uint256[][] memory publicInputs,
        PlonkProof[] memory proofs,
        bytes[] memory extraTranscriptInitMsgs
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// Based on:
// - Christian Reitwiessner: https://gist.githubusercontent.com/chriseth/f9be9d9391efc5beb9704255a8e2989d/raw/4d0fb90847df1d4e04d507019031888df8372239/snarktest.solidity
// - Aztec: https://github.com/AztecProtocol/aztec-2-bug-bounty

pragma solidity ^0.8.0;

import "./Utils.sol";

/// @notice Barreto-Naehrig curve over a 254 bit prime field
library BN254 {
    // use notation from https://datatracker.ietf.org/doc/draft-irtf-cfrg-pairing-friendly-curves/
    //
    // Elliptic curve is defined over a prime field GF(p), with embedding degree k.
    // Short Weierstrass (SW form) is, for a, b \in GF(p^n) for some natural number n > 0:
    //   E: y^2 = x^3 + a * x + b
    //
    // Pairing is defined over cyclic subgroups G1, G2, both of which are of order r.
    // G1 is a subgroup of E(GF(p)), G2 is a subgroup of E(GF(p^k)).
    //
    // BN family are parameterized curves with well-chosen t,
    //   p = 36 * t^4 + 36 * t^3 + 24 * t^2 + 6 * t + 1
    //   r = 36 * t^4 + 36 * t^3 + 18 * t^2 + 6 * t + 1
    // for some integer t.
    // E has the equation:
    //   E: y^2 = x^3 + b
    // where b is a primitive element of multiplicative group (GF(p))^* of order (p-1).
    // A pairing e is defined by taking G1 as a subgroup of E(GF(p)) of order r,
    // G2 as a subgroup of E'(GF(p^2)),
    // and G_T as a subgroup of a multiplicative group (GF(p^12))^* of order r.
    //
    // BN254 is defined over a 254-bit prime order p, embedding degree k = 12.
    uint256 public constant P_MOD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 public constant R_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fp2 = x0 * z + x1
    struct G2Point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    /// @return the generator of G1
    // solhint-disable-next-line func-name-mixedcase
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    // solhint-disable-next-line func-name-mixedcase
    function P2() internal pure returns (G2Point memory) {
        return
            G2Point({
                x0: 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                x1: 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed,
                y0: 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                y1: 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            });
    }

    /// @dev check if a G1 point is Infinity
    /// @notice precompile bn256Add at address(6) takes (0, 0) as Point of Infinity,
    /// some crypto libraries (such as arkwork) uses a boolean flag to mark PoI, and
    /// just use (0, 1) as affine coordinates (not on curve) to represents PoI.
    function isInfinity(G1Point memory point) internal pure returns (bool result) {
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))
            result := and(iszero(x), iszero(y))
        }
    }

    /// @return r the negation of p, i.e. p.add(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        if (isInfinity(p)) {
            return p;
        }
        return G1Point(p.x, P_MOD - (p.y % P_MOD));
    }

    /// @return res = -fr the negation of scalar field element.
    function negate(uint256 fr) internal pure returns (uint256 res) {
        return R_MOD - (fr % R_MOD);
    }

    /// @return r the sum of two points of G1
    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(0, 0)
            }
        }
        require(success, "Bn254: group addition failed!");
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.mul(1) and p.add(p) == p.mul(2) for all points p.
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(0, 0)
            }
        }
        require(success, "Bn254: scalar mul failed!");
    }

    /// @dev Multi-scalar Mulitiplication (MSM)
    /// @return r = \Prod{B_i^s_i} where {s_i} are `scalars` and {B_i} are `bases`
    function multiScalarMul(G1Point[] memory bases, uint256[] memory scalars)
        internal
        view
        returns (G1Point memory r)
    {
        require(scalars.length == bases.length, "MSM error: length does not match");

        r = scalarMul(bases[0], scalars[0]);
        for (uint256 i = 1; i < scalars.length; i++) {
            r = add(r, scalarMul(bases[i], scalars[i]));
        }
    }

    /// @dev Compute f^-1 for f \in Fr scalar field
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function invert(uint256 fr) internal view returns (uint256 output) {
        bool success;
        uint256 p = R_MOD;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), fr)
            mstore(add(mPtr, 0x80), sub(p, 2))
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            output := mload(0x00)
        }
        require(success, "Bn254: pow precompile failed!");
    }

    /**
     * validate the following:
     *   x != 0
     *   y != 0
     *   x < p
     *   y < p
     *   y^2 = x^3 + 3 mod p
     */
    /// @dev validate G1 point and check if it is on curve
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function validateG1Point(G1Point memory point) internal pure {
        bool isWellFormed;
        uint256 p = P_MOD;
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))

            isWellFormed := and(
                and(and(lt(x, p), lt(y, p)), not(or(iszero(x), iszero(y)))),
                eq(mulmod(y, y, p), addmod(mulmod(x, mulmod(x, x, p), p), 3, p))
            )
        }
        require(isWellFormed, "Bn254: invalid G1 point");
    }

    /// @dev Validate scalar field, revert if invalid (namely if fr > r_mod).
    /// @notice Writing this inline instead of calling it might save gas.
    function validateScalarField(uint256 fr) internal pure {
        bool isValid;
        assembly {
            isValid := lt(fr, R_MOD)
        }
        require(isValid, "Bn254: invalid scalar field");
    }

    /// @dev Evaluate the following pairing product:
    /// @dev e(a1, a2).e(-b1, b2) == 1
    /// @dev caller needs to ensure that a1, a2, b1 and b2 are within proper group
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        uint256 out;
        bool success;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, mload(a1))
            mstore(add(mPtr, 0x20), mload(add(a1, 0x20)))
            mstore(add(mPtr, 0x40), mload(a2))
            mstore(add(mPtr, 0x60), mload(add(a2, 0x20)))
            mstore(add(mPtr, 0x80), mload(add(a2, 0x40)))
            mstore(add(mPtr, 0xa0), mload(add(a2, 0x60)))

            mstore(add(mPtr, 0xc0), mload(b1))
            mstore(add(mPtr, 0xe0), mload(add(b1, 0x20)))
            mstore(add(mPtr, 0x100), mload(b2))
            mstore(add(mPtr, 0x120), mload(add(b2, 0x20)))
            mstore(add(mPtr, 0x140), mload(add(b2, 0x40)))
            mstore(add(mPtr, 0x160), mload(add(b2, 0x60)))
            success := staticcall(gas(), 8, mPtr, 0x180, 0x00, 0x20)
            out := mload(0x00)
        }
        require(success, "Bn254: Pairing check failed!");
        return (out != 0);
    }

    function fromLeBytesModOrder(bytes memory leBytes) internal pure returns (uint256 ret) {
        for (uint256 i = 0; i < leBytes.length; i++) {
            ret = mulmod(ret, 256, R_MOD);
            ret = addmod(ret, uint256(uint8(leBytes[leBytes.length - 1 - i])), R_MOD);
        }
    }

    /// @dev Check if y-coordinate of G1 point is negative.
    function isYNegative(G1Point memory point) internal pure returns (bool) {
        return (point.y << 1) < P_MOD;
    }

    // @dev Perform a modular exponentiation.
    // @return base^exponent (mod modulus)
    // This method is ideal for small exponents (~64 bits or less), as it is cheaper than using the pow precompile
    // @notice credit: credit: Aztec, Spilsbury Holdings Ltd
    function powSmall(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 input = base;
        uint256 count = 1;

        assembly {
            let endpoint := add(exponent, 0x01)
            for {

            } lt(count, endpoint) {
                count := add(count, count)
            } {
                if and(exponent, count) {
                    result := mulmod(result, input, modulus)
                }
                input := mulmod(input, input, modulus)
            }
        }

        return result;
    }

    function g1Serialize(G1Point memory point) internal pure returns (bytes memory) {
        uint256 mask;

        // Set the 254-th bit to 1 for infinity
        // https://docs.rs/ark-serialize/0.3.0/src/ark_serialize/flags.rs.html#117
        if (isInfinity(point)) {
            mask |= 0x4000000000000000000000000000000000000000000000000000000000000000;
        }

        // Set the 255-th bit to 1 for positive Y
        // https://docs.rs/ark-serialize/0.3.0/src/ark_serialize/flags.rs.html#118
        if (!isYNegative(point)) {
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
        }

        return abi.encodePacked(Utils.reverseEndianness(point.x | mask));
    }

    function g1Deserialize(bytes32 input) internal view returns (G1Point memory point) {
        uint256 mask = 0x4000000000000000000000000000000000000000000000000000000000000000;
        uint256 x = Utils.reverseEndianness(uint256(input));
        uint256 y;
        bool isQuadraticResidue;
        bool isYPositive;
        if (x & mask != 0) {
            // the 254-th bit == 1 for infinity
            x = 0;
            y = 0;
        } else {
            // Set the 255-th bit to 1 for positive Y
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
            isYPositive = (x & mask != 0);
            // mask off the first two bits of x
            mask = 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            x &= mask;

            // solve for y where E: y^2 = x^3 + 3
            y = mulmod(x, x, P_MOD);
            y = mulmod(y, x, P_MOD);
            y = addmod(y, 3, P_MOD);
            (isQuadraticResidue, y) = quadraticResidue(y);

            require(isQuadraticResidue, "deser fail: not on curve");

            if (isYPositive) {
                y = P_MOD - y;
            }
        }

        point = G1Point(x, y);
    }

    function quadraticResidue(uint256 x)
        internal
        view
        returns (bool isQuadraticResidue, uint256 a)
    {
        bool success;
        // e = (p+1)/4
        uint256 e = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;
        uint256 p = P_MOD;

        // we have p == 3 mod 4 therefore
        // a = x^((p+1)/4)
        assembly {
            // credit: Aztec
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), x)
            mstore(add(mPtr, 0x80), e)
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            a := mload(0x00)
        }
        require(success, "pow precompile call failed!");

        // ensure a < p/2
        if (a << 1 > p) {
            a = p - a;
        }

        // check if a^2 = x, if not x is not a quadratic residue
        e = mulmod(a, a, p);

        isQuadraticResidue = (e == x);
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import {BN254} from "../libraries/BN254.sol";

library PolynomialEval {
    /// @dev a Radix 2 Evaluation Domain
    struct EvalDomain {
        uint256 logSize; // log_2(self.size)
        uint256 size; // Size of the domain as a field element
        uint256 sizeInv; // Inverse of the size in the field
        uint256 groupGen; // A generator of the subgroup
        uint256 groupGenInv; // Inverse of the generator of the subgroup
    }

    /// @dev stores vanishing poly, lagrange at 1, and Public input poly
    struct EvalData {
        uint256 vanishEval;
        uint256 lagrangeOne;
        uint256 piEval;
    }

    /// @dev compute the EvalData for a given domain and a challenge zeta
    function evalDataGen(
        EvalDomain memory self,
        uint256 zeta,
        uint256[] memory publicInput
    ) internal view returns (EvalData memory evalData) {
        evalData.vanishEval = evaluateVanishingPoly(self, zeta);
        evalData.lagrangeOne = evaluateLagrangeOne(self, zeta, evalData.vanishEval);
        evalData.piEval = evaluatePiPoly(self, publicInput, zeta, evalData.vanishEval);
    }

    /// @dev Create a new Radix2EvalDomain with `domainSize` which should be power of 2.
    /// @dev Will revert if domainSize is not among {2^14, 2^15, 2^16, 2^17}
    function newEvalDomain(uint256 domainSize) internal pure returns (EvalDomain memory) {
        if (domainSize == 16384) {
            return
                EvalDomain(
                    14,
                    domainSize,
                    0x30638CE1A7661B6337A964756AA75257C6BF4778D89789AB819CE60C19B04001,
                    0x2D965651CDD9E4811F4E51B80DDCA8A8B4A93EE17420AAE6ADAA01C2617C6E85,
                    0x281C036F06E7E9E911680D42558E6E8CF40976B0677771C0F8EEE934641C8410
                );
        } else if (domainSize == 32768) {
            return
                EvalDomain(
                    15,
                    domainSize,
                    0x3063edaa444bddc677fcd515f614555a777997e0a9287d1e62bf6dd004d82001,
                    0x2d1ba66f5941dc91017171fa69ec2bd0022a2a2d4115a009a93458fd4e26ecfb,
                    0x05d33766e4590b3722701b6f2fa43d0dc3f028424d384e68c92a742fb2dbc0b4
                );
        } else if (domainSize == 65536) {
            return
                EvalDomain(
                    16,
                    domainSize,
                    0x30641e0e92bebef818268d663bcad6dbcfd6c0149170f6d7d350b1b1fa6c1001,
                    0x00eeb2cb5981ed45649abebde081dcff16c8601de4347e7dd1628ba2daac43b7,
                    0x0b5d56b77fe704e8e92338c0082f37e091126414c830e4c6922d5ac802d842d4
                );
        } else if (domainSize == 131072) {
            return
                EvalDomain(
                    17,
                    domainSize,
                    0x30643640b9f82f90e83b698e5ea6179c7c05542e859533b48b9953a2f5360801,
                    0x1bf82deba7d74902c3708cc6e70e61f30512eca95655210e276e5858ce8f58e5,
                    0x244cf010c43ca87237d8b00bf9dd50c4c01c7f086bd4e8c920e75251d96f0d22
                );
        } else {
            revert("Poly: size must in 2^{14~17}");
        }
    }

    // This evaluates the vanishing polynomial for this domain at zeta.
    // For multiplicative subgroups, this polynomial is
    // `z(X) = X^self.size - 1`.
    function evaluateVanishingPoly(EvalDomain memory self, uint256 zeta)
        internal
        pure
        returns (uint256 res)
    {
        uint256 p = BN254.R_MOD;
        uint256 logSize = self.logSize;

        assembly {
            switch zeta
            case 0 {
                res := sub(p, 1)
            }
            default {
                res := zeta
                for {
                    let i := 0
                } lt(i, logSize) {
                    i := add(i, 1)
                } {
                    res := mulmod(res, res, p)
                }
                // since zeta != 0 we know that res is not 0
                // so we can safely do a subtraction
                res := sub(res, 1)
            }
        }
    }

    /// @dev Evaluate the lagrange polynomial at point `zeta` given the vanishing polynomial evaluation `vanish_eval`.
    function evaluateLagrangeOne(
        EvalDomain memory self,
        uint256 zeta,
        uint256 vanishEval
    ) internal view returns (uint256 res) {
        if (vanishEval == 0) {
            return 0;
        }

        uint256 p = BN254.R_MOD;
        uint256 divisor;
        uint256 vanishEvalMulSizeInv = self.sizeInv;

        // =========================
        // lagrange_1_eval = vanish_eval / self.size / (zeta - 1)
        // =========================
        assembly {
            vanishEvalMulSizeInv := mulmod(vanishEval, vanishEvalMulSizeInv, p)

            switch zeta
            case 0 {
                divisor := sub(p, 1)
            }
            default {
                divisor := sub(zeta, 1)
            }
        }
        divisor = BN254.invert(divisor);
        assembly {
            res := mulmod(vanishEvalMulSizeInv, divisor, p)
        }
    }

    /// @dev Evaluate public input polynomial at point `zeta`.
    function evaluatePiPoly(
        EvalDomain memory self,
        uint256[] memory pi,
        uint256 zeta,
        uint256 vanishEval
    ) internal view returns (uint256 res) {
        if (vanishEval == 0) {
            return 0;
        }

        uint256 p = BN254.R_MOD;
        uint256 length = pi.length;
        uint256 ithLagrange;
        uint256 ithDivisor;
        uint256 tmp;
        uint256 vanishEvalDivN = self.sizeInv;
        uint256 divisorProd;
        uint256[] memory localDomainElements = domainElements(self, length);
        uint256[] memory divisors = new uint256[](length);

        assembly {
            // vanish_eval_div_n = (zeta^n-1)/n
            vanishEvalDivN := mulmod(vanishEvalDivN, vanishEval, p)

            // Now we need to compute
            //  \sum_{i=0..l} L_{i,H}(zeta) * pub_input[i]
            // where
            // - L_{i,H}(zeta)
            //      = Z_H(zeta) * v_i / (zeta - g^i)
            //      = vanish_eval_div_n * g^i / (zeta - g^i)
            // - v_i = g^i / n
            //
            // we want to use batch inversion method where we compute
            //
            //      divisorProd = 1 / \prod (zeta - g^i)
            //
            // and then each 1 / (zeta - g^i) can be computed via (length - 1)
            // multiplications:
            //
            //      1 / (zeta - g^i) = divisorProd * \prod_{j!=i} (zeta - g^j)
            //
            // In total this takes n(n-1) multiplications and 1 inversion,
            // instead of doing n inversions.
            divisorProd := 1

            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 1)
            } {
                // tmp points to g^i
                // first 32 bytes of reference is the length of an array
                tmp := mload(add(add(localDomainElements, 0x20), mul(i, 0x20)))
                // compute (zeta - g^i)
                ithDivisor := addmod(sub(p, tmp), zeta, p)
                // accumulate (zeta - g^i) to the divisorProd
                divisorProd := mulmod(divisorProd, ithDivisor, p)
                // store ithDivisor in the array
                mstore(add(add(divisors, 0x20), mul(i, 0x20)), ithDivisor)
            }
        }

        // compute 1 / \prod_{i=0}^length (zeta - g^i)
        divisorProd = BN254.invert(divisorProd);

        assembly {
            for {
                let i := 0
            } lt(i, length) {
                i := add(i, 1)
            } {
                // tmp points to g^i
                // first 32 bytes of reference is the length of an array
                tmp := mload(add(add(localDomainElements, 0x20), mul(i, 0x20)))
                // vanish_eval_div_n * g^i
                ithLagrange := mulmod(vanishEvalDivN, tmp, p)

                // now we compute vanish_eval_div_n * g^i / (zeta - g^i) via
                // vanish_eval_div_n * g^i * divisorProd * \prod_{j!=i} (zeta - g^j)
                ithLagrange := mulmod(ithLagrange, divisorProd, p)
                for {
                    let j := 0
                } lt(j, length) {
                    j := add(j, 1)
                } {
                    if iszero(eq(i, j)) {
                        ithDivisor := mload(add(add(divisors, 0x20), mul(j, 0x20)))
                        ithLagrange := mulmod(ithLagrange, ithDivisor, p)
                    }
                }

                // multiply by pub_input[i] and update res
                // tmp points to public input
                tmp := mload(add(add(pi, 0x20), mul(i, 0x20)))
                ithLagrange := mulmod(ithLagrange, tmp, p)
                res := addmod(res, ithLagrange, p)
            }
        }
    }

    /// @dev Generate the domain elements for indexes 0..length
    /// which are essentially g^0, g^1, ..., g^{length-1}
    function domainElements(EvalDomain memory self, uint256 length)
        internal
        pure
        returns (uint256[] memory elements)
    {
        uint256 groupGen = self.groupGen;
        uint256 tmp = 1;
        uint256 p = BN254.R_MOD;
        elements = new uint256[](length);
        assembly {
            if not(iszero(length)) {
                let ptr := add(elements, 0x20)
                let end := add(ptr, mul(0x20, length))
                mstore(ptr, 1)
                ptr := add(ptr, 0x20)
                // for (; ptr < end; ptr += 32) loop through the memory of `elements`
                for {

                } lt(ptr, end) {
                    ptr := add(ptr, 0x20)
                } {
                    tmp := mulmod(tmp, groupGen, p)
                    mstore(ptr, tmp)
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library Utils {
    function reverseEndianness(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v =
            ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v =
            ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v =
            ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v =
            ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import {BN254} from "../libraries/BN254.sol";
import "hardhat/console.sol";
import "../interfaces/IPlonkVerifier.sol";
import {PolynomialEval as Poly} from "../libraries/PolynomialEval.sol";
import "./Transcript.sol";

contract PlonkVerifier is IPlonkVerifier {
    using Transcript for Transcript.TranscriptData;

    // _COSET_K0 = 1, has no effect during multiplication, thus avoid declaring it here.
    uint256 private constant _COSET_K1 =
        0x2f8dd1f1a7583c42c4e12a44e110404c73ca6c94813f85835da4fb7bb1301d4a;
    uint256 private constant _COSET_K2 =
        0x1ee678a0470a75a6eaa8fe837060498ba828a3703b311d0f77f010424afeb025;
    uint256 private constant _COSET_K3 =
        0x2042a587a90c187b0a087c03e29c968b950b1db26d5c82d666905a6895790c0a;
    uint256 private constant _COSET_K4 =
        0x2e2b91456103698adf57b799969dea1c8f739da5d8d40dd3eb9222db7c81e881;

    // Parsed from Aztec's Ignition CRS,
    // `beta_h` \in G2 where \beta is the trapdoor, h is G2 generator `BN254.P2()`
    // See parsing code: https://github.com/alxiong/crs
    BN254.G2Point private _betaH =
        BN254.G2Point({
            x0: 0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
            x1: 0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0,
            y0: 0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
            y1: 0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55
        });

    /// The number of wire types of the circuit, TurboPlonk has 5.
    uint256 private constant _NUM_WIRE_TYPES = 5;

    /// @dev polynomial commitment evaluation info.
    struct PcsInfo {
        // a random combiner that was used to combine evaluations at point
        uint256 u; // 0x00
        // the point to be evaluated at
        uint256 evalPoint; // 0x20
        // the shifted point to be evaluated at
        uint256 nextEvalPoint; // 0x40
        // the polynomial evaluation value
        uint256 eval; // 0x60
        // scalars of poly comm for MSM
        uint256[] commScalars; // 0x80
        // bases of poly comm for MSM
        BN254.G1Point[] commBases; // 0xa0
        // proof of evaluations at point `eval_point`
        BN254.G1Point openingProof; // 0xc0
        // proof of evaluations at point `next_eval_point`
        BN254.G1Point shiftedOpeningProof; // 0xe0
    }

    /// @dev Plonk IOP verifier challenges.
    struct Challenges {
        uint256 alpha; // 0x00
        uint256 alpha2; // 0x20
        uint256 alpha3; // 0x40
        uint256 beta; // 0x60
        uint256 gamma; // 0x80
        uint256 zeta; // 0xA0
        uint256 v; // 0xC0
        uint256 u; // 0xE0
    }

    /// @dev Batch verify multiple TurboPlonk proofs.
    /// @param verifyingKeys An array of verifier keys
    /// @param publicInputs A two-dimensional array of public inputs.
    /// @param proofs An array of Plonk proofs
    /// @param extraTranscriptInitMsgs An array of bytes from
    /// transcript initialization messages
    function batchVerify(
        VerifyingKey[] memory verifyingKeys,
        uint256[][] memory publicInputs,
        PlonkProof[] memory proofs,
        bytes[] memory extraTranscriptInitMsgs
    ) external view returns (bool) {
        require(
            verifyingKeys.length == proofs.length &&
                publicInputs.length == proofs.length &&
                extraTranscriptInitMsgs.length == proofs.length,
            "Plonk: invalid input param"
        );
        require(proofs.length > 0, "Plonk: need at least 1 proof");

        PcsInfo[] memory pcsInfos = new PcsInfo[](proofs.length);
        for (uint256 i = 0; i < proofs.length; i++) {
            // validate proofs are proper group/field elements
            _validateProof(proofs[i]);
            // validate public input are all proper scalar fields
            for (uint256 j = 0; j < publicInputs[i].length; j++) {
                BN254.validateScalarField(publicInputs[i][j]);
            }
            // prepare pcs info
            pcsInfos[i] = _preparePcsInfo(
                verifyingKeys[i],
                publicInputs[i],
                proofs[i],
                extraTranscriptInitMsgs[i]
            );
        }

        return _batchVerifyOpeningProofs(pcsInfos);
    }

    /// @dev Validate all group points and scalar fields. Revert if
    /// any are invalid.
    /// @param proof A Plonk proof
    function _validateProof(PlonkProof memory proof) internal pure {
        BN254.validateG1Point(proof.wire0);
        BN254.validateG1Point(proof.wire1);
        BN254.validateG1Point(proof.wire2);
        BN254.validateG1Point(proof.wire3);
        BN254.validateG1Point(proof.wire4);
        BN254.validateG1Point(proof.prodPerm);
        BN254.validateG1Point(proof.split0);
        BN254.validateG1Point(proof.split1);
        BN254.validateG1Point(proof.split2);
        BN254.validateG1Point(proof.split3);
        BN254.validateG1Point(proof.split4);
        BN254.validateG1Point(proof.zeta);
        BN254.validateScalarField(proof.wireEval0);
        BN254.validateScalarField(proof.wireEval1);
        BN254.validateScalarField(proof.wireEval2);
        BN254.validateScalarField(proof.wireEval3);
        BN254.validateScalarField(proof.wireEval4);
        BN254.validateScalarField(proof.sigmaEval0);
        BN254.validateScalarField(proof.sigmaEval1);
        BN254.validateScalarField(proof.sigmaEval2);
        BN254.validateScalarField(proof.sigmaEval3);
        BN254.validateScalarField(proof.prodPermZetaOmegaEval);
    }

    function _preparePcsInfo(
        VerifyingKey memory verifyingKey,
        uint256[] memory publicInput,
        PlonkProof memory proof,
        bytes memory extraTranscriptInitMsg
    ) internal view returns (PcsInfo memory res) {
        require(publicInput.length == verifyingKey.numInputs, "Plonk: wrong verifying key");

        Challenges memory chal = _computeChallenges(
            verifyingKey,
            publicInput,
            proof,
            extraTranscriptInitMsg
        );

        Poly.EvalDomain memory domain = Poly.newEvalDomain(verifyingKey.domainSize);
        // pre-compute evaluation data
        Poly.EvalData memory evalData = Poly.evalDataGen(domain, chal.zeta, publicInput);

        // compute opening proof in poly comm.
        uint256[] memory commScalars = new uint256[](30);
        BN254.G1Point[] memory commBases = new BN254.G1Point[](30);

        uint256 eval = _prepareOpeningProof(
            verifyingKey,
            evalData,
            proof,
            chal,
            commScalars,
            commBases
        );

        uint256 zeta = chal.zeta;
        uint256 omega = domain.groupGen;
        uint256 p = BN254.R_MOD;
        uint256 zetaOmega;
        assembly {
            zetaOmega := mulmod(zeta, omega, p)
        }

        res = PcsInfo(
            chal.u,
            zeta,
            zetaOmega,
            eval,
            commScalars,
            commBases,
            proof.zeta,
            proof.zetaOmega
        );
    }

    function _computeChallenges(
        VerifyingKey memory verifyingKey,
        uint256[] memory publicInput,
        PlonkProof memory proof,
        bytes memory extraTranscriptInitMsg
    ) internal pure returns (Challenges memory res) {
        Transcript.TranscriptData memory transcript;
        uint256 p = BN254.R_MOD;

        transcript.appendMessage(extraTranscriptInitMsg);
        transcript.appendVkAndPubInput(verifyingKey, publicInput);
        transcript.appendGroupElement(proof.wire0);
        transcript.appendGroupElement(proof.wire1);
        transcript.appendGroupElement(proof.wire2);
        transcript.appendGroupElement(proof.wire3);
        transcript.appendGroupElement(proof.wire4);

        // have to compute tau, but not really used anywhere
        transcript.getAndAppendChallenge();
        res.beta = transcript.getAndAppendChallenge();
        res.gamma = transcript.getAndAppendChallenge();

        transcript.appendGroupElement(proof.prodPerm);

        res.alpha = transcript.getAndAppendChallenge();

        transcript.appendGroupElement(proof.split0);
        transcript.appendGroupElement(proof.split1);
        transcript.appendGroupElement(proof.split2);
        transcript.appendGroupElement(proof.split3);
        transcript.appendGroupElement(proof.split4);

        res.zeta = transcript.getAndAppendChallenge();

        transcript.appendProofEvaluations(proof);
        res.v = transcript.getAndAppendChallenge();

        transcript.appendGroupElement(proof.zeta);
        transcript.appendGroupElement(proof.zetaOmega);
        res.u = transcript.getAndAppendChallenge();

        assembly {
            let alpha := mload(res)
            let alpha2 := mulmod(alpha, alpha, p)
            let alpha3 := mulmod(alpha2, alpha, p)
            mstore(add(res, 0x20), alpha2)
            mstore(add(res, 0x40), alpha3)
        }
    }

    /// @dev Compute the constant term of the linearization polynomial.
    /// ```
    /// r_plonk = PI - L1(x) * alpha^2 - alpha * \prod_i=1..m-1 (w_i + beta * sigma_i + gamma) * (w_m + gamma) * z(xw)
    /// ```
    /// where m is the number of wire types.
    function _computeLinPolyConstantTerm(
        Challenges memory chal,
        PlonkProof memory proof,
        Poly.EvalData memory evalData
    ) internal pure returns (uint256 res) {
        uint256 p = BN254.R_MOD;
        uint256 lagrangeOneEval = evalData.lagrangeOne;
        uint256 piEval = evalData.piEval;
        uint256 perm = 1;

        assembly {
            let beta := mload(add(chal, 0x60))
            let gamma := mload(add(chal, 0x80))

            // \prod_i=1..m-1 (w_i + beta * sigma_i + gamma)
            {
                let w0 := mload(add(proof, 0x1a0))
                let sigma0 := mload(add(proof, 0x240))
                perm := mulmod(perm, addmod(add(w0, gamma), mulmod(beta, sigma0, p), p), p)
            }
            {
                let w1 := mload(add(proof, 0x1c0))
                let sigma1 := mload(add(proof, 0x260))
                perm := mulmod(perm, addmod(add(w1, gamma), mulmod(beta, sigma1, p), p), p)
            }
            {
                let w2 := mload(add(proof, 0x1e0))
                let sigma2 := mload(add(proof, 0x280))
                perm := mulmod(perm, addmod(add(w2, gamma), mulmod(beta, sigma2, p), p), p)
            }
            {
                let w3 := mload(add(proof, 0x200))
                let sigma3 := mload(add(proof, 0x2a0))
                perm := mulmod(perm, addmod(add(w3, gamma), mulmod(beta, sigma3, p), p), p)
            }

            // \prod_i=1..m-1 (w_i + beta * sigma_i + gamma) * (w_m + gamma) * z(xw)
            {
                let w4 := mload(add(proof, 0x220))
                let permNextEval := mload(add(proof, 0x2c0))
                perm := mulmod(perm, mulmod(addmod(w4, gamma, p), permNextEval, p), p)
            }

            let alpha := mload(chal)
            let alpha2 := mload(add(chal, 0x20))
            // PI - L1(x) * alpha^2 - alpha * \prod_i=1..m-1 (w_i + beta * sigma_i + gamma) * (w_m + gamma) * z(xw)
            res := addmod(piEval, sub(p, mulmod(alpha2, lagrangeOneEval, p)), p)
            res := addmod(res, sub(p, mulmod(alpha, perm, p)), p)
        }
    }

    /// @dev Compute components in [E]1 and [F]1 used for PolyComm opening verification
    /// equivalent of JF's https://github.com/EspressoSystems/jellyfish/blob/main/plonk/src/proof_system/verifier.rs#L154-L170
    /// caller allocates the memory fr commScalars and commBases
    /// requires Arrays of size 30.
    /// @param verifyingKey A verifier key
    /// @param evalData A polynomial evaluation
    /// @param proof A Plonk proof
    /// @param chal A set of challenges
    /// @param commScalars Common scalars
    /// @param commBases Common bases
    // The returned commitment is a generalization of
    // `[F]1` described in Sec 8.4, step 10 of https://eprint.iacr.org/2019/953.pdf
    // Returned evaluation is the scalar in `[E]1` described in Sec 8.4, step 11 of https://eprint.iacr.org/2019/953.pdf
    function _prepareOpeningProof(
        VerifyingKey memory verifyingKey,
        Poly.EvalData memory evalData,
        PlonkProof memory proof,
        Challenges memory chal,
        uint256[] memory commScalars,
        BN254.G1Point[] memory commBases
    ) internal pure returns (uint256 eval) {
        // compute the constant term of the linearization polynomial
        uint256 linPolyConstant = _computeLinPolyConstantTerm(chal, proof, evalData);

        _preparePolyCommitments(verifyingKey, chal, evalData, proof, commScalars, commBases);

        eval = _prepareEvaluations(linPolyConstant, proof, commScalars);
    }

    /// @dev Similar to `aggregate_poly_commitments()` in Jellyfish, but we are not aggregating multiple,
    /// but rather preparing for `[F]1` from a single proof.
    /// The caller allocates the memory fr commScalars and commBases.
    /// Requires Arrays of size 30.
    function _preparePolyCommitments(
        VerifyingKey memory verifyingKey,
        Challenges memory chal,
        Poly.EvalData memory evalData,
        PlonkProof memory proof,
        uint256[] memory commScalars,
        BN254.G1Point[] memory commBases
    ) internal pure {
        _linearizationScalarsAndBases(verifyingKey, chal, evalData, proof, commBases, commScalars);

        uint256 p = BN254.R_MOD;
        uint256 v = chal.v;
        uint256 vBase = v;

        // Add wire witness polynomial commitments.
        commScalars[20] = vBase;
        commBases[20] = proof.wire0;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[21] = vBase;
        commBases[21] = proof.wire1;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[22] = vBase;
        commBases[22] = proof.wire2;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[23] = vBase;
        commBases[23] = proof.wire3;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[24] = vBase;
        commBases[24] = proof.wire4;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        // Add wire sigma polynomial commitments. The last sigma commitment is excluded.
        commScalars[25] = vBase;
        commBases[25] = verifyingKey.sigma0;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[26] = vBase;
        commBases[26] = verifyingKey.sigma1;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[27] = vBase;
        commBases[27] = verifyingKey.sigma2;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        commScalars[28] = vBase;
        commBases[28] = verifyingKey.sigma3;
        assembly {
            vBase := mulmod(vBase, v, p)
        }

        // Add poly commitments to be evaluated at point `zeta * g`.
        commScalars[29] = chal.u;
        commBases[29] = proof.prodPerm;
    }

    /// @dev `aggregate_evaluations()` in Jellyfish, but since we are not aggregating multiple, but rather preparing `[E]1` from a single proof.
    /// @dev caller allocates the memory fr commScalars
    /// requires Arrays of size 30.
    /// @param linPolyConstant A linear polynomial constant
    /// @param proof A Plonk proof
    /// @param commScalars An array of common scalars
    /// The returned value is the scalar in `[E]1` described in Sec 8.4, step 11 of https://eprint.iacr.org/2019/953.pdf
    function _prepareEvaluations(
        uint256 linPolyConstant,
        PlonkProof memory proof,
        uint256[] memory commScalars
    ) internal pure returns (uint256 eval) {
        uint256 p = BN254.R_MOD;
        assembly {
            eval := sub(p, linPolyConstant)
            for {
                let i := 0
            } lt(i, 10) {
                i := add(i, 1)
            } {
                // the first u256 stores the length of this array;
                // the next 20 elements are used to store the linearization of the scalars
                // the first free space starts from 21
                let combiner := mload(add(commScalars, mul(add(i, 21), 0x20)))
                let termEval := mload(add(proof, add(0x1a0, mul(i, 0x20))))
                eval := addmod(eval, mulmod(combiner, termEval, p), p)
            }
        }
    }

    /// @dev Batchly verify multiple PCS opening proofs.
    /// `open_key` has been assembled from BN254.P1(), BN254.P2() and contract variable _betaH
    /// @param pcsInfos An array of PcsInfo
    /// @dev Returns true if the entire batch verifiies and false otherwise.
    function _batchVerifyOpeningProofs(PcsInfo[] memory pcsInfos) internal view returns (bool) {
        uint256 pcsLen = pcsInfos.length;
        uint256 p = BN254.R_MOD;
        // Compute a pseudorandom challenge from the instances
        uint256 r = 1; // for a single proof, no need to use `r` (`r=1` has no effect)
        if (pcsLen > 1) {
            Transcript.TranscriptData memory transcript;
            for (uint256 i = 0; i < pcsLen; i++) {
                transcript.appendChallenge(pcsInfos[i].u);
            }
            r = transcript.getAndAppendChallenge();
        }

        BN254.G1Point memory a1;
        BN254.G1Point memory b1;

        // Compute A := A0 + r * A1 + ... + r^{m-1} * Am
        {
            uint256[] memory scalars = new uint256[](2 * pcsLen);
            BN254.G1Point[] memory bases = new BN254.G1Point[](2 * pcsLen);
            uint256 rBase = 1;
            for (uint256 i = 0; i < pcsLen; i++) {
                scalars[2 * i] = rBase;
                bases[2 * i] = pcsInfos[i].openingProof;

                {
                    uint256 tmp;
                    uint256 u = pcsInfos[i].u;
                    assembly {
                        tmp := mulmod(rBase, u, p)
                    }
                    scalars[2 * i + 1] = tmp;
                }
                bases[2 * i + 1] = pcsInfos[i].shiftedOpeningProof;

                assembly {
                    rBase := mulmod(rBase, r, p)
                }
            }
            a1 = BN254.multiScalarMul(bases, scalars);
        }

        // Compute B := B0 + r * B1 + ... + r^{m-1} * Bm
        {
            uint256[] memory scalars;
            BN254.G1Point[] memory bases;
            {
                // variable scoping to avoid "Stack too deep"
                uint256 scalarsLenPerInfo = pcsInfos[0].commScalars.length;
                uint256 totalScalarsLen = (2 + scalarsLenPerInfo) * pcsInfos.length + 1;
                scalars = new uint256[](totalScalarsLen);
                bases = new BN254.G1Point[](totalScalarsLen);
            }
            uint256 sumEvals = 0;
            uint256 idx = 0;
            uint256 rBase = 1;
            for (uint256 i = 0; i < pcsInfos.length; i++) {
                for (uint256 j = 0; j < pcsInfos[0].commScalars.length; j++) {
                    {
                        // scalars[idx] = (rBase * pcsInfos[i].commScalars[j]) % BN254.R_MOD;
                        uint256 s = pcsInfos[i].commScalars[j];
                        uint256 tmp;
                        assembly {
                            tmp := mulmod(rBase, s, p)
                        }
                        scalars[idx] = tmp;
                    }
                    bases[idx] = pcsInfos[i].commBases[j];
                    idx += 1;
                }

                {
                    // scalars[idx] = (rBase * pcsInfos[i].evalPoint) % BN254.R_MOD;
                    uint256 evalPoint = pcsInfos[i].evalPoint;
                    uint256 tmp;
                    assembly {
                        tmp := mulmod(rBase, evalPoint, p)
                    }
                    scalars[idx] = tmp;
                }
                bases[idx] = pcsInfos[i].openingProof;
                idx += 1;

                {
                    // scalars[idx] = (rBase * pcsInfos[i].u * pcsInfos[i].nextEvalPoint) % BN254.R_MOD;
                    uint256 u = pcsInfos[i].u;
                    uint256 nextEvalPoint = pcsInfos[i].nextEvalPoint;
                    uint256 tmp;
                    assembly {
                        tmp := mulmod(rBase, mulmod(u, nextEvalPoint, p), p)
                    }
                    scalars[idx] = tmp;
                }
                bases[idx] = pcsInfos[i].shiftedOpeningProof;
                idx += 1;

                {
                    // sumEvals = (sumEvals + rBase * pcsInfos[i].eval) % BN254.R_MOD;
                    // rBase = (rBase * r) % BN254.R_MOD;
                    uint256 eval = pcsInfos[i].eval;
                    assembly {
                        sumEvals := addmod(sumEvals, mulmod(rBase, eval, p), p)
                        rBase := mulmod(rBase, r, p)
                    }
                }
            }
            scalars[idx] = BN254.negate(sumEvals);
            bases[idx] = BN254.P1();
            b1 = BN254.negate(BN254.multiScalarMul(bases, scalars));
        }

        // Check e(A, [x]2) ?= e(B, [1]2)
        return BN254.pairingProd2(a1, _betaH, b1, BN254.P2());
    }

    /// @dev Compute the linearization of the scalars and bases.
    /// The caller allocates the memory from commScalars and commBases.
    /// Requires arrays of size 30.
    /// @param verifyingKey The verifying key
    /// @param challenge A set of challenges
    /// @param evalData Polynomial evaluation data
    /// @param proof A Plonk proof
    /// @param bases An array of BN254 G1 points
    /// @param scalars An array of scalars
    function _linearizationScalarsAndBases(
        VerifyingKey memory verifyingKey,
        Challenges memory challenge,
        Poly.EvalData memory evalData,
        PlonkProof memory proof,
        BN254.G1Point[] memory bases,
        uint256[] memory scalars
    ) internal pure {
        uint256 firstScalar;
        uint256 secondScalar;
        uint256 rhs;
        uint256 tmp;
        uint256 tmp2;
        uint256 p = BN254.R_MOD;

        // ============================================
        // Compute coefficient for the permutation product polynomial commitment.
        // firstScalar =
        //          L1(zeta) * alpha^2
        //          + alpha
        //              * (beta * zeta      + wireEval0 + gamma)
        //              * (beta * k1 * zeta + wireEval1 + gamma)
        //              * (beta * k2 * zeta + wireEval2 + gamma)
        //              * ...
        // where wireEval0, wireEval1, wireEval2, ... are in w_evals
        // ============================================
        // first base and scala:
        // - proof.prodPerm
        // - firstScalar
        assembly {
            // firstScalar = alpha^2 * L1(zeta)
            firstScalar := mulmod(mload(add(challenge, 0x20)), mload(add(evalData, 0x20)), p)

            // rhs = alpha
            rhs := mload(challenge)

            // tmp = beta * zeta
            tmp := mulmod(mload(add(challenge, 0x60)), mload(add(challenge, 0xA0)), p)

            // =================================
            // k0 (which is 1) component
            // (beta * zeta + wireEval0 + gamma)
            // =================================
            tmp2 := addmod(tmp, mload(add(proof, 0x1A0)), p)
            tmp2 := addmod(tmp2, mload(add(challenge, 0x80)), p)

            rhs := mulmod(tmp2, rhs, p)

            // =================================
            // k1 component
            // (beta * zeta * k1 + wireEval1 + gamma)
            // =================================
            tmp2 := mulmod(tmp, _COSET_K1, p)
            tmp2 := addmod(tmp2, mload(add(proof, 0x1C0)), p)
            tmp2 := addmod(tmp2, mload(add(challenge, 0x80)), p)

            rhs := mulmod(tmp2, rhs, p)

            // =================================
            // k2 component
            // (beta * zeta * k2 + wireEval2 + gamma)
            // =================================
            tmp2 := mulmod(tmp, _COSET_K2, p)
            tmp2 := addmod(tmp2, mload(add(proof, 0x1E0)), p)
            tmp2 := addmod(tmp2, mload(add(challenge, 0x80)), p)
            rhs := mulmod(tmp2, rhs, p)

            // =================================
            // k3 component
            // (beta * zeta * k3 + wireEval3 + gamma)
            // =================================
            tmp2 := mulmod(tmp, _COSET_K3, p)
            tmp2 := addmod(tmp2, mload(add(proof, 0x200)), p)
            tmp2 := addmod(tmp2, mload(add(challenge, 0x80)), p)
            rhs := mulmod(tmp2, rhs, p)

            // =================================
            // k4 component
            // (beta * zeta * k4 + wireEval4 + gamma)
            // =================================
            tmp2 := mulmod(tmp, _COSET_K4, p)
            tmp2 := addmod(tmp2, mload(add(proof, 0x220)), p)
            tmp2 := addmod(tmp2, mload(add(challenge, 0x80)), p)
            rhs := mulmod(tmp2, rhs, p)

            firstScalar := addmod(firstScalar, rhs, p)
        }
        bases[0] = proof.prodPerm;
        scalars[0] = firstScalar;

        // ============================================
        // Compute coefficient for the last wire sigma polynomial commitment.
        // secondScalar = alpha * beta * z_w * [s_sigma_3]_1
        //              * (wireEval0 + gamma + beta * sigmaEval0)
        //              * (wireEval1 + gamma + beta * sigmaEval1)
        //              * ...
        // ============================================
        // second base and scala:
        // - verifyingKey.sigma4
        // - secondScalar
        assembly {
            // secondScalar = alpha * beta * z_w
            secondScalar := mulmod(mload(challenge), mload(add(challenge, 0x60)), p)
            secondScalar := mulmod(secondScalar, mload(add(proof, 0x2C0)), p)

            // (wireEval0 + gamma + beta * sigmaEval0)
            tmp := mulmod(mload(add(challenge, 0x60)), mload(add(proof, 0x240)), p)
            tmp := addmod(tmp, mload(add(proof, 0x1A0)), p)
            tmp := addmod(tmp, mload(add(challenge, 0x80)), p)

            secondScalar := mulmod(secondScalar, tmp, p)

            // (wireEval1 + gamma + beta * sigmaEval1)
            tmp := mulmod(mload(add(challenge, 0x60)), mload(add(proof, 0x260)), p)
            tmp := addmod(tmp, mload(add(proof, 0x1C0)), p)
            tmp := addmod(tmp, mload(add(challenge, 0x80)), p)

            secondScalar := mulmod(secondScalar, tmp, p)

            // (wireEval2 + gamma + beta * sigmaEval2)
            tmp := mulmod(mload(add(challenge, 0x60)), mload(add(proof, 0x280)), p)
            tmp := addmod(tmp, mload(add(proof, 0x1E0)), p)
            tmp := addmod(tmp, mload(add(challenge, 0x80)), p)

            secondScalar := mulmod(secondScalar, tmp, p)

            // (wireEval3 + gamma + beta * sigmaEval3)
            tmp := mulmod(mload(add(challenge, 0x60)), mload(add(proof, 0x2A0)), p)
            tmp := addmod(tmp, mload(add(proof, 0x200)), p)
            tmp := addmod(tmp, mload(add(challenge, 0x80)), p)

            secondScalar := mulmod(secondScalar, tmp, p)
        }
        bases[1] = verifyingKey.sigma4;
        scalars[1] = p - secondScalar;

        // ============================================
        // next 13 are for selectors:
        //
        // the selectors are organized as
        // - q_lc
        // - q_mul
        // - q_hash
        // - q_o
        // - q_c
        // - q_ecc
        // ============================================

        // ============
        // q_lc
        // ============
        // q_1...q_4
        scalars[2] = proof.wireEval0;
        scalars[3] = proof.wireEval1;
        scalars[4] = proof.wireEval2;
        scalars[5] = proof.wireEval3;
        bases[2] = verifyingKey.q1;
        bases[3] = verifyingKey.q2;
        bases[4] = verifyingKey.q3;
        bases[5] = verifyingKey.q4;

        // ============
        // q_M
        // ============
        // q_M12 and q_M34
        // q_M12 = w_evals[0] * w_evals[1];
        assembly {
            tmp := mulmod(mload(add(proof, 0x1A0)), mload(add(proof, 0x1C0)), p)
        }
        scalars[6] = tmp;
        bases[6] = verifyingKey.qM12;

        assembly {
            tmp := mulmod(mload(add(proof, 0x1E0)), mload(add(proof, 0x200)), p)
        }
        scalars[7] = tmp;
        bases[7] = verifyingKey.qM34;

        // ============
        // q_H
        // ============
        // w_evals[0].pow([5]);
        assembly {
            tmp := mload(add(proof, 0x1A0))
            tmp2 := mulmod(tmp, tmp, p)
            tmp2 := mulmod(tmp2, tmp2, p)
            tmp := mulmod(tmp, tmp2, p)
        }
        scalars[8] = tmp;
        bases[8] = verifyingKey.qH1;

        // w_evals[1].pow([5]);
        assembly {
            tmp := mload(add(proof, 0x1C0))
            tmp2 := mulmod(tmp, tmp, p)
            tmp2 := mulmod(tmp2, tmp2, p)
            tmp := mulmod(tmp, tmp2, p)
        }
        scalars[9] = tmp;
        bases[9] = verifyingKey.qH2;

        // w_evals[2].pow([5]);
        assembly {
            tmp := mload(add(proof, 0x1E0))
            tmp2 := mulmod(tmp, tmp, p)
            tmp2 := mulmod(tmp2, tmp2, p)
            tmp := mulmod(tmp, tmp2, p)
        }
        scalars[10] = tmp;
        bases[10] = verifyingKey.qH3;

        // w_evals[3].pow([5]);
        assembly {
            tmp := mload(add(proof, 0x200))
            tmp2 := mulmod(tmp, tmp, p)
            tmp2 := mulmod(tmp2, tmp2, p)
            tmp := mulmod(tmp, tmp2, p)
        }
        scalars[11] = tmp;
        bases[11] = verifyingKey.qH4;

        // ============
        // q_o and q_c
        // ============
        // q_o
        scalars[12] = p - proof.wireEval4;
        bases[12] = verifyingKey.qO;
        // q_c
        scalars[13] = 1;
        bases[13] = verifyingKey.qC;

        // ============
        // q_Ecc
        // ============
        // q_Ecc = w_evals[0] * w_evals[1] * w_evals[2] * w_evals[3] * w_evals[4];
        assembly {
            tmp := mulmod(mload(add(proof, 0x1A0)), mload(add(proof, 0x1C0)), p)
            tmp := mulmod(tmp, mload(add(proof, 0x1E0)), p)
            tmp := mulmod(tmp, mload(add(proof, 0x200)), p)
            tmp := mulmod(tmp, mload(add(proof, 0x220)), p)
        }
        scalars[14] = tmp;
        bases[14] = verifyingKey.qEcc;

        // ============================================
        // the last 5 are for splitting quotient commitments
        // ============================================

        // first one is 1-zeta^n
        scalars[15] = p - evalData.vanishEval;
        bases[15] = proof.split0;
        assembly {
            // tmp = zeta^{n+2}
            tmp := addmod(mload(evalData), 1, p)
            // todo: use pre-computed zeta^2
            tmp2 := mulmod(mload(add(challenge, 0xA0)), mload(add(challenge, 0xA0)), p)
            tmp := mulmod(tmp, tmp2, p)
        }

        // second one is (1-zeta^n) zeta^(n+2)
        assembly {
            tmp2 := mulmod(mload(add(scalars, mul(16, 0x20))), tmp, p)
        }
        scalars[16] = tmp2;
        bases[16] = proof.split1;

        // third one is (1-zeta^n) zeta^2(n+2)
        assembly {
            tmp2 := mulmod(mload(add(scalars, mul(17, 0x20))), tmp, p)
        }
        scalars[17] = tmp2;
        bases[17] = proof.split2;

        // forth one is (1-zeta^n) zeta^3(n+2)
        assembly {
            tmp2 := mulmod(mload(add(scalars, mul(18, 0x20))), tmp, p)
        }
        scalars[18] = tmp2;
        bases[18] = proof.split3;

        // fifth one is (1-zeta^n) zeta^4(n+2)
        assembly {
            tmp2 := mulmod(mload(add(scalars, mul(19, 0x20))), tmp, p)
        }
        scalars[19] = tmp2;
        bases[19] = proof.split4;
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "hardhat/console.sol";
import "../libraries/Utils.sol";
import {BN254} from "../libraries/BN254.sol";
import {IPlonkVerifier} from "../interfaces/IPlonkVerifier.sol";

library Transcript {
    struct TranscriptData {
        bytes transcript;
        bytes32[2] state;
    }

    // ================================
    // Primitive functions
    // ================================
    function appendMessage(TranscriptData memory self, bytes memory message) internal pure {
        self.transcript = abi.encodePacked(self.transcript, message);
    }

    function appendFieldElement(TranscriptData memory self, uint256 fieldElement) internal pure {
        appendMessage(self, abi.encodePacked(Utils.reverseEndianness(fieldElement)));
    }

    function appendGroupElement(TranscriptData memory self, BN254.G1Point memory comm)
        internal
        pure
    {
        bytes memory commBytes = BN254.g1Serialize(comm);
        appendMessage(self, commBytes);
    }

    // ================================
    // Transcript APIs
    // ================================
    function appendChallenge(TranscriptData memory self, uint256 challenge) internal pure {
        appendFieldElement(self, challenge);
    }

    function appendCommitments(TranscriptData memory self, BN254.G1Point[] memory comms)
        internal
        pure
    {
        for (uint256 i = 0; i < comms.length; i++) {
            appendCommitment(self, comms[i]);
        }
    }

    function appendCommitment(TranscriptData memory self, BN254.G1Point memory comm)
        internal
        pure
    {
        appendGroupElement(self, comm);
    }

    function getAndAppendChallenge(TranscriptData memory self) internal pure returns (uint256) {
        bytes32 h1 = keccak256(
            abi.encodePacked(self.state[0], self.state[1], self.transcript, uint8(0))
        );
        bytes32 h2 = keccak256(
            abi.encodePacked(self.state[0], self.state[1], self.transcript, uint8(1))
        );

        self.state[0] = h1;
        self.state[1] = h2;

        return BN254.fromLeBytesModOrder(BytesLib.slice(abi.encodePacked(h1, h2), 0, 48));
    }

    /// @dev Append the verifying key and the public inputs to the transcript.
    /// @param verifyingKey verifiying key
    /// @param publicInput a list of field elements
    function appendVkAndPubInput(
        TranscriptData memory self,
        IPlonkVerifier.VerifyingKey memory verifyingKey,
        uint256[] memory publicInput
    ) internal pure {
        uint64 sizeInBits = 254;

        // Fr field size in bits
        appendMessage(
            self,
            BytesLib.slice(abi.encodePacked(Utils.reverseEndianness(sizeInBits)), 0, 8)
        );

        // domain size
        appendMessage(
            self,
            BytesLib.slice(
                abi.encodePacked(Utils.reverseEndianness(verifyingKey.domainSize)),
                0,
                8
            )
        );

        // number of inputs
        appendMessage(
            self,
            BytesLib.slice(abi.encodePacked(Utils.reverseEndianness(verifyingKey.numInputs)), 0, 8)
        );

        // =====================
        // k: coset representatives
        // =====================
        // Currently, K is hardcoded, and there are 5 of them since
        // # wire types == 5
        appendFieldElement(self, 0x1); // k0 = 1
        appendFieldElement(
            self,
            0x2f8dd1f1a7583c42c4e12a44e110404c73ca6c94813f85835da4fb7bb1301d4a
        ); // k1
        appendFieldElement(
            self,
            0x1ee678a0470a75a6eaa8fe837060498ba828a3703b311d0f77f010424afeb025
        ); // k2
        appendFieldElement(
            self,
            0x2042a587a90c187b0a087c03e29c968b950b1db26d5c82d666905a6895790c0a
        ); // k3
        appendFieldElement(
            self,
            0x2e2b91456103698adf57b799969dea1c8f739da5d8d40dd3eb9222db7c81e881
        ); // k4

        // selectors
        appendGroupElement(self, verifyingKey.q1);
        appendGroupElement(self, verifyingKey.q2);
        appendGroupElement(self, verifyingKey.q3);
        appendGroupElement(self, verifyingKey.q4);
        appendGroupElement(self, verifyingKey.qM12);
        appendGroupElement(self, verifyingKey.qM34);
        appendGroupElement(self, verifyingKey.qH1);
        appendGroupElement(self, verifyingKey.qH2);
        appendGroupElement(self, verifyingKey.qH3);
        appendGroupElement(self, verifyingKey.qH4);
        appendGroupElement(self, verifyingKey.qO);
        appendGroupElement(self, verifyingKey.qC);
        appendGroupElement(self, verifyingKey.qEcc);

        // sigmas
        appendGroupElement(self, verifyingKey.sigma0);
        appendGroupElement(self, verifyingKey.sigma1);
        appendGroupElement(self, verifyingKey.sigma2);
        appendGroupElement(self, verifyingKey.sigma3);
        appendGroupElement(self, verifyingKey.sigma4);

        // public inputs
        for (uint256 i = 0; i < publicInput.length; i++) {
            appendFieldElement(self, publicInput[i]);
        }
    }

    /// @dev Append the proof to the transcript.
    function appendProofEvaluations(
        TranscriptData memory self,
        IPlonkVerifier.PlonkProof memory proof
    ) internal pure {
        appendFieldElement(self, proof.wireEval0);
        appendFieldElement(self, proof.wireEval1);
        appendFieldElement(self, proof.wireEval2);
        appendFieldElement(self, proof.wireEval3);
        appendFieldElement(self, proof.wireEval4);

        appendFieldElement(self, proof.sigmaEval0);
        appendFieldElement(self, proof.sigmaEval1);
        appendFieldElement(self, proof.sigmaEval2);
        appendFieldElement(self, proof.sigmaEval3);

        appendFieldElement(self, proof.prodPermZetaOmegaEval);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
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
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
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
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

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
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
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
                // while(uint256(mc < end) + cb == 2)
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

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
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
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
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
}