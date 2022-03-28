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

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Freeze2In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 7)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                5118137774697846205332813764527928981094534629179826197661885163309718792664
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                21444510867008360096097791654924066970628086592132286765149218644570218218958
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                8803078987858664729272498900762799875194584982758288268215987493230494163132
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                2433303804972293717223914306424233027859258355453999879123493306111951897773
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                3260803333275595200572169884988811547059839215101652317716205725226978273005
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                3613466037895382109608881276133312019690204476510004381563636709063308697093
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                2899439069156777615431510251772750434873724497570948892914993632800602868003
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                8379069052308825781842073463279139505822176676050290986587894691217284563176
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                11732815069861807091165298838511758216456754114248634732985660813617441774658
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                13166648630773672378735632573860809427570624939066078822309995911184719468349
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3491113372305405096734724369052497193940883294098266073462122391919346338715
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                9827940866231584614489847721346069816554104560301469101889136447541239075558
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                13435736629650136340196094187820825115318808951343660439499146542480924445056
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                17982003639419860944219119425071532203644939147988825284644182004036282633420
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9420441314344923881108805693844267870391289724837370305813596950535269618889
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                14052028114719021167053334693322209909986772869796949309216011765205181071250
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                5993794253539477186956400554691260472169114800994727061541419240125118730670
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                7932960467420473760327919608797843731121974235494949218022535850994096308221
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                20429406452243707916630058273965650451352739230543746812138739882954609124362
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                19692763177526054221606086118119451355223254880919552106296824049356634107628
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                5116116081275540865026368436909879211124168610156815899416152073819842308833
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                19842614482623746480218449373220727139999815807703100436601033251034509288020
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                3222495709067365879961349438698872943831082393186134710609177690951286365439
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                3703532585269560394637679600890000571417416525562741673639173852507841008896
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                14390471925844384916287376853753782482889671388409569687933776522892272411453
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                12261059506574689542871751331715340905672203590996080541963527436628201655551
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                212133813390818941086614328570019936880884093617125797928913969643819686094
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                2058275687345409085609950154451527352761528547310163982911053914079075244754
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                7507728187668840967683000771945777493711131652056583548804845913578647015848
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                15764897865018924692970368330703479768257677759902236501992745661340099646248
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                18302496468173370667823199324779836313672317342261283918121073083547306893947
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                8286815911028648157724790867291052312955947067988434001008620797971639607610
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                3470304694844212768511296992238419575123994956442939632524758781128057967608
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                9660892985889164184033149081062412611630238705975373538019042544308335432760
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                2964316839877400858567376484261923751031240259689039666960763176068018735519
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                12811532772714855857084788747474913882317963037829729036129619334772557515102
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Freeze3In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 9)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                13960731824189571867091334541157339805012676983241098249236778497915465352053
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15957967148909612161116218663566087497068811688498797226467515095325657152045
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                10072587287838607559866316765624459623039578259829899225485734337870604479821
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15609102652788964903340031795269302405421393375766454476378251576322947285858
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                6565707169634610873662073730120423414251877113110818166564470784428289496576
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                9611712776953584296612678707999788907754017999002246476393974258810867124564
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                19122400063214294010991425447556532201595762243736666161415050184531098654161
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                8531074110951311734071734321378003618052738734286317677359289798683215129985
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                18914674706112982859579196036464470962561796494057486369943014188445892675591
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                8521550178820292984099911306615540388090622911114862049753515592863829430736
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                14630335835391046544786473024276900306274085179180854494149987003151236405693
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                11927636740621831793456799535735389934490350641107279163802406976389995490906
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                12724914112829888521503996001370933887413324349676112061904353298191125761834
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                3433370683786676509006167821257247081483834358490691629467376279251656650897
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9566744544381523978155846140753126684369534823789897373672815695046810310988
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                260017699035964770662690666115311602214922546306804012310168827438556483441
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                18742890127040989288898023133652949889864689947035150783791742574000686319400
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                18749161983189150319356152659011703669863797011859087161475368338926038180308
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                20773233313791930222139945008080890514898946888819625041024291924369611870607
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                13521724424975535658347353167027580945107539483287924982357298371687877483981
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                10660982607928179139814177842882617778440401746692506684983260589289268170379
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                15139413484465466645149010003574654339361200137557967877891360282092282891685
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                17250558007005834955604250406579207360748810924758511953913092810009135851470
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11258418978437321501318046240697776859180107275977030400553604411488978149668
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                18952078950487788846193130112459018587473354670050028821020889375362878213321
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                17193026626593699161155564126784943150078109362562131961513990003707313130311
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                14543481681504505345294846715453463092188884601462120536722150134676588633429
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                18051927297986484527611703191585266713528321784715802343699150271856051244721
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                17183091890960203175777065490726876011944304977299231686457191186480347944964
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                4490401529426574565331238171714181866458606184922225399124187058005801778892
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                1221754396433704762941109064372027557900417150628742839724350141274324105531
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                5852202975250895807153833762470523277935452126865915206223172229093142057204
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                15942219407079940317108327336758085920828255563342347502490598820248118460133
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                13932908789216121516788648116401360726086794781411868046768741292235436938527
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                11253921189643581015308547816247612243572238063440388125238308675751100437670
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                21538818198962061056994656088458979220103547193654086011201760604068846580076
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Mint1In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 16384)
            // num of public inputs
            mstore(add(vk, 0x20), 22)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                14708041522873209202464618950611504807168696855480720848360413590326729841973
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                2753391240893238116569628860982882954353792578019920766428726340611015647581
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                3736215203151709462427825581991044329817961401819325086573903036518525176090
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                12284473618321395163309979733066433449809233564826193169921444928840687100523
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                11948153932361754444295437431688112113763465916556532032853808907007255324832
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                5247166478759706764702942889858430530186042193040312355719301585036655612459
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                17184781586365391989471544204947701083939573062775992140067289916802254834188
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                1695548810031655609675397387003567906043418871571997772255611361115032629003
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                4501183465908078766709944423483386166697765379860531518789327025791827694266
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                17179919563903728314665267245084588379374464645703406635631119875332721091062
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                8233664603830467551407560711982259529601063264885744179029753653795440811880
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                15890473389663313484400232619457945250113260815521617218577960950923821395961
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                14842917854453150581899781597532237976322234382964084206933989618934323526445
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                16447842172982150537473552975294340243672291348134029457070764238385172728852
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9473551627160998361000472320259848783011643008757616507618705701015024223999
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                11314416338785822922260197499038268393262643508579752114469422388580655977102
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                3736408701597418834318726881826839552728418266216645424811344776852549712816
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                9236488906535632856862877101736177223606785065252708856745807157980987984387
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                14102260043757883202366109964215541081299927672047603711818995797147714865094
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                17534575210236353125951475539478479017023300116581894838767353256804423795888
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                9147214868025953364750888491087621905427748656716737534941501783669122960379
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                1392401634629635498019533543932086568632128115192597982401550578444977393547
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                10905264501530050014704452452494914745596183555206362825031535539577170367475
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                17138899495046135206471329677572657240135846790961757879454458120765242310575
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                16573281449079492002777383418086249227397635509941971752517637461403659421155
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                4575446980340017635017887407539797482781705198893380506254262640090465211655
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                9089742723053765306677953175198389661353135493790082378155841294705327694917
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                11133242012031704156289281393180107718619015102295906028702493235407386901280
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                10009477156249913501931891243909788618345391893663991287711709770530743764439
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                2335006503907830689782212423634682006869891487153768081847010024128012642090
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                204582489322604335877947037789506354815242950315871800117188914050721754147
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                4017254452065892946191861754786121551706223202798323858822829895419210960406
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                3674255676567461700605617197873932900311232245160095442299763249794134579502
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                14717173916044651338237546750276495403229974586112157441016319173772835390378
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                12191628753324517001666106106337946847104780287136368645491927996790130156414
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                13305212653333031744208722140065322148127616384688600512629199891590396358314
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer1In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 14)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                2601115423116897239893469437783815282674518870859439140584670982404446568425
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                21387703072596271753684269571766318413616637905846906200885488548605232081311
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                18093207667326166260941967361503597170970820090303504008548886520781612262607
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15506241883427907423143246742207987178296655397323901395523216644162934801027
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                17224030688930263671215927622085796838744685640551295700644356316087606194453
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                9871892688266980794424413228644800345365261123544262124587988616929094794446
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                1653423479825136378929731986206672195437753469049273770949830103289522081013
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                18540430158936383317781049369976810237215202752760467051838384048905582651431
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                6182405487934559918414504166029367587453938777975619206648907759838313063029
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                6303636105426570943547672403434638798256828205198194404179645009191642748039
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                18352717355200151877063864360131237083352005873169286557578537755751979692274
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                18535115788456072630383925322523695497891623428396234248738154081372899880584
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                9908258779995310745701077146291771577159654333216970234243768106420988535639
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                5222835988549975732420424607539021146071370844807206884805011103538281824730
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                6941500137865112460544627950260307723514017850007311936769317146419972927588
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                15349893608573380976411985659730584619173031566937770787699017806561190627468
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                21168364095257448760606101143948858356172338924320104703900203452473902441433
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                16660170798361651209023038026794900976183585114965877304784822006074874509205
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                9190952913639104387810968179432225180425197597955362124827814569885452163057
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                18827142612117658766343514941168256204525012530604946506087566444465709027496
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                3087614871980473279723363167422819790187289361998206527420814175739516849267
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                16862987149935139591372068460264503091703957897443470436032581481036423083811
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                9706719488655451993063181268308257527997835452929632143872066940077818386420
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                6236623652447614250698035805861101061802099331620117231564769714805411900300
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                1411379008735327479737723833603528702843470627344722114111584994556861154980
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                3993135852184128345174580298872023693588782847706666657191331001722079392092
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                9846511696349440200252734974300757392144763505883256681697549590162985402181
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                2943021693042093632574100039021179834063372575819762871426673095266988807850
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                6939009262544205005507648947300385820226307867525750603310876841608771115967
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                1744542086304213974542290661478181313186513167898968854980022885020012543803
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                8552076371570768937374027634488546934769058846143601491495678997242529143831
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                9579090530940855809150547321287606050563533435045744882440421353731349593486
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                14499786686191977429340953516175958437978725979354053072854149749281625153583
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                12761628950782571856606556112616580736578801583124069040637032554972765433582
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                11861036760044642147557768929016751187676005432645929589927048931795306751324
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                7411647397974044716846852003118581558974144934962247144410611563600239777076
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer2In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 27)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                7628022919529421911135408904372797627127922903613932517951676759551756614275
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                1331524275175103536317606472081114729669777307477986149584111942393705962450
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                11385474208217093339197684484172860602491108849062309339809203517524255705814
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                14742740373953540087108822854363852587371950907295700017218827187367528919422
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                16656283720893277505520180576834218330228640426319787818259624147689712896181
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                13325231528863913137181084237184355058186595356556894827411039178877487474770
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                9189791310770551336126945048086887553526802063485610994702148384774531567947
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                14841018178006034931401800499802155298679474918739530511330632965796343701845
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                2291377454368026633206063421914664920045658737580871725587615825936361194543
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                1302015066005114004951991020555380375564758415605740891074815812171114380677
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                20820380636256451755441529461019761091650992355545157191471886785846828368458
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                21593297517126223340469128837410501412961385490498992377256325174187721359792
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                18739722115441254876917366518913137925104098218293815822076739449944538511463
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                21704728059513369811801942736237462547455258303739352819235283602004201892046
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                14641591741781012837232454331455337179912058515648809221995273046957404689696
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                7809440494808817863276605374028021971161141718007334574770841741782286482045
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                12825820090241151628814776520261182308841765265286885643232345964438926321859
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                953744090209979424715539850359172951613856725623925496688974323728989047678
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                12851524982620297419850126451077057609693331882274130781000694680394484937072
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                275368615438300238729991830030823846019265755187066004752089508827060302546
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                5220853497691242543339709197361896971155747151782855394304800304146652028430
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                9450857245879300465114294127329293155426034414913673478235624018652474647192
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                1021365006885138582377179911145719040433890015638098596677854082251708776428
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11359935238758701707761945142588661021143398751723216197162452144578378060887
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                13464643739714429050907960983453767858349630205445421978818631227665532763905
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                10339488547668992208892459748774743478364544079101005770106713704130208623574
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                9601738305327057050177966434793538325547418147491497810469219037972470343030
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                19301188629352152421673613863134089760610229764460440766611052882385794236638
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                21079123752659904011291969128982548366933951092885387880640877829556396468124
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                8511476146119618724794262516873338224284052557219121087531014728412456998247
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                15303909812921746731917671857484723288453878023898728858584106908662401059224
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                18170356242761746817628282114440738046388581044315241707586116980550978579010
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                4268233897088460316569641617170115742335233153775249443326146549729427293896
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                18974976451146753275247755359852354432882026367027102555776389253422694257840
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                14659915475225256091079096704713344128669967309925492152251233149380462089822
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                2059804379395436696412483294937073085747522899756612651966178273428617505712
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.

// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer2In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 32)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                6443282669730485407595271828674707172530216643022146287503622911791463804043
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15696097649475290076149769009458172575519992828166990254810336060070104703870
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                11681656213736165656499497372446107771337122700468758173231970786274856928411
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                10450606707405144471114037991073355878505225379403084661718401703948084026025
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                14949874541546323431113184056978425503852064124202616618464991230985415809296
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                2755002423044532136780993773451846084085886241086886025824873450959670484164
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                21207788223959789592306767368195516108258319638600005910214663887334522784476
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                20339433485992657720503614053002752589189874711150471281419370881536035034628
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                18631493768208670705485520853887976536695065332427205279642440535222886092292
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                6840987554837946884416088276166870742357021362040861629505787964758864275100
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                16178651459227636862542353073855555416097463500529848793096041715723051182880
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                5970323786617048090410648683745859437837321145537762222392610864665454314628
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                21487420887626536768737123653635887952476328827973824853831940683917744860629
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                14035356773640867098841015480173597833708530762839998143633620124000312604569
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9545837141279670455258503437926586302673276681048196091959382223343565663038
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                15947614763344839229459794400790751428004401834477218923635864884401496441892
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                12080091524919005971356953696076991358627192379181758361749359305653171768953
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                17439684987066542572766750059569630478427935655895555459166833681417844092930
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                5701950446803590644135190089832346121657991411362732243298925416080446841465
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                8332659994290731968190641056516336791258763359210625476231835314984112766413
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                13253969218388213652706314130513753359438541493687814506877280541684975690258
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                16009690647717929647856071917243036723170363003070166259833423021444206394391
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                5576536153829630973927473424831889868656235111882426196623002728030063738858
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11726598312732354680625205255493076317120545671716157650418651212412840704738
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                5405551642410088215503372225048806703517930422578070794318382858583234132381
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                494379166121476157530708105968326435548569494079142065684457716255857242276
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                20704187523716756528180282857397988056049614305908938091015985169373590947598
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                1711039150215717904294641678907719765410368126472104372784057294224997327419
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                18822945583248183258553997348222993649454022267053574236466619892496459777859
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                14151738140577784330561552892602560699610764417317335382613984109360136167394
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                2387304647210058180508070573733250363855112630235812789983280252196793324601
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                7685115375159715883862846923594198876658684538946803569647901707992033051886
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                16435018905297869097928961780716739903270571476633582949015154935556284135350
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                2036767712865186869762381470608151410855938900352103040184478909748435318476
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                6779994430033977349039006350128159237422794493764381621361585638109046042910
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                13084743573268695049814429704952197464938266719700894058263626618858073954657
            )
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

import "../interfaces/IPlonkVerifier.sol";
import "./Transfer1In2Out24DepthVk.sol";
import "./Transfer2In2Out24DepthVk.sol";
import "./Transfer2In3Out24DepthVk.sol";
import "./Mint1In2Out24DepthVk.sol";
import "./Freeze2In2Out24DepthVk.sol";
import "./Freeze3In3Out24DepthVk.sol";

library VerifyingKeys {
    function getVkById(uint256 encodedId)
        external
        pure
        returns (IPlonkVerifier.VerifyingKey memory)
    {
        if (encodedId == getEncodedId(0, 1, 2, 24)) {
            // transfer/burn-1-input-2-output-24-depth
            return Transfer1In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 2, 2, 24)) {
            // transfer/burn-2-input-2-output-24-depth
            return Transfer2In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 2, 3, 24)) {
            // transfer/burn-2-input-3-output-24-depth
            return Transfer2In3Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(1, 1, 2, 24)) {
            // mint-1-input-2-output-24-depth
            return Mint1In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(2, 2, 2, 24)) {
            // freeze-2-input-2-output-24-depth
            return Freeze2In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(2, 3, 3, 24)) {
            // freeze-3-input-3-output-24-depth
            return Freeze3In3Out24DepthVk.getVk();
        } else {
            revert("Unknown vk ID");
        }
    }

    // returns (noteType, numInput, numOutput, treeDepth) as a 4*8 = 32 byte = uint256
    // as the encoded ID.
    function getEncodedId(
        uint8 noteType,
        uint8 numInput,
        uint8 numOutput,
        uint8 treeDepth
    ) public pure returns (uint256 encodedId) {
        assembly {
            encodedId := add(
                shl(24, noteType),
                add(shl(16, numInput), add(shl(8, numOutput), treeDepth))
            )
        }
    }
}