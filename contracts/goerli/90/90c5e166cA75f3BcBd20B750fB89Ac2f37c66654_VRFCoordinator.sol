// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 *
 * @notice Verification of verifiable-random-function (VRF) proofs, following
 * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
 * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.
 *
 * @dev Bibliographic references:
 *
 * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
 * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
 * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05
 *
 * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
 * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
 * ****************************************************************************
 * @dev USAGE
 *
 * @dev The main entry point is randomValueFromVRFProof. See its docstring.
 * *************************f***************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is computationally indistinguishable to her from a uniform
 * @dev random sample from the output space.
 *
 * @dev The purpose of this contract is to perform that verification.
 * ****************************************************************************
 * @dev DESIGN NOTES
 *
 * @dev The VRF algorithm verified here satisfies the full uniqueness, full
 * @dev collision resistance, and full pseudo-randomness security properties.
 * @dev See "SECURITY PROPERTIES" below, and
 * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3
 *
 * @dev An elliptic curve point is generally represented in the solidity code
 * @dev as a uint256[2], corresponding to its affine coordinates in
 * @dev GF(FIELD_SIZE).
 *
 * @dev For the sake of efficiency, this implementation deviates from the spec
 * @dev in some minor ways:
 *
 * @dev - Keccak hash rather than the SHA256 hash recommended in
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
 * @dev   Keccak costs much less gas on the EVM, and provides similar security.
 *
 * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
 * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER
 *
 * @dev - hashToCurve recursively hashes until it finds a curve x-ordinate. On
 * @dev   the EVM, this is slightly more efficient than the recommendation in
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
 * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
 * @dev   nonce updated until a valid x-ordinate is found.
 *
 * @dev - hashToCurve does not include a cipher version string or the byte 0x1
 * @dev   in the hash message, as recommended in step 5.B of the draft
 * @dev   standard. They are unnecessary here because no variation in the
 * @dev   cipher suite is allowed.
 *
 * @dev - Similarly, the hash input in scalarFromCurvePoints does not include a
 * @dev   commitment to the cipher suite, either, which differs from step 2 of
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
 * @dev   . Also, the hash input is the concatenation of the uncompressed
 * @dev   points, not the compressed points as recommended in step 3.
 *
 * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
 * @dev   the value computed by Reggie as the nonce times the secp256k1
 * @dev   generator point, see steps 5 and 7 of
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
 * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
 * @dev   keccak hash of the original u. This is because we only verify the
 * @dev   calculation of u up to its address, by abusing ECRECOVER.
 * ****************************************************************************
 * @dev   SECURITY PROPERTIES
 *
 * @dev Here are the security properties for this VRF:
 *
 * @dev Full uniqueness: For any seed and valid VRF public key, there is
 * @dev   exactly one VRF output which can be proved to come from that seed, in
 * @dev   the sense that the proof will pass verifyVRFProof.
 *
 * @dev Full collision resistance: It's cryptographically infeasible to find
 * @dev   two seeds with same VRF output from a fixed, valid VRF key
 *
 * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
 * @dev   derived from a given seed, the outputs are computationally
 * @dev   indistinguishable from randomness.
 *
 * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
 * @dev for these properties.
 *
 * @dev For secp256k1, the key validation described in section
 * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
 * @dev is unnecessary, because secp256k1 has cofactor 1, and the
 * @dev representation of the public key used here (affine x- and y-ordinates
 * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
 * @dev the point at infinity.
 * ****************************************************************************
 * @dev OTHER SECURITY CONSIDERATIONS
 *
 * @dev The seed input to the VRF could in principle force an arbitrary amount
 * @dev of work in hashToCurve, by requiring extra rounds of hashing and
 * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
 * @dev However, under the Random Oracle Model the probability of choosing a
 * @dev point which forces n extra rounds in hashToCurve is 2⁻ⁿ. The base cost
 * @dev for calling hashToCurve is about 25,000 gas, and each round of checking
 * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
 * @dev which hashToCurve would cost more than 2,017,000 gas, one would have to
 * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
 * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)
 *
 * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
 * @dev this means it is infeasible for an adversary to prevent correct
 * @dev operation of this contract by choosing an adverse seed.
 *
 * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
 * @dev hashToCurve.)
 *
 * @dev It may be possible to make a secure constant-time hashToCurve function.
 * @dev See notes in hashToCurve docstring.
 */
contract VRF {
    // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
    // Number of points in Secp256k1
    uint256 private constant GROUP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // Prime characteristic of the galois field over which Secp256k1 is defined
    uint256 private constant FIELD_SIZE =
    // solium-disable-next-line indentation
     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 private constant WORD_LENGTH_BYTES = 0x20;

    // (base^exponent) % FIELD_SIZE
    // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    function bigModExp(uint256 base, uint256 exponent) internal view returns (uint256 exponentiation) {
        uint256 callResult;
        uint256[6] memory bigModExpContractInputs;
        bigModExpContractInputs[0] = WORD_LENGTH_BYTES; // Length of base
        bigModExpContractInputs[1] = WORD_LENGTH_BYTES; // Length of exponent
        bigModExpContractInputs[2] = WORD_LENGTH_BYTES; // Length of modulus
        bigModExpContractInputs[3] = base;
        bigModExpContractInputs[4] = exponent;
        bigModExpContractInputs[5] = FIELD_SIZE;
        uint256[1] memory output;
        assembly {
            // solhint-disable-line no-inline-assembly
            callResult :=
                staticcall(
                    not(0), // Gas cost: no limit
                    0x05, // Bigmodexp contract address
                    bigModExpContractInputs,
                    0xc0, // Length of input segment: 6*0x20-bytes
                    output,
                    0x20 // Length of output segment
                )
        }
        if (callResult == 0) {
            revert("bigModExp failure!");
        }
        return output[0];
    }

    // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
    // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
    uint256 private constant SQRT_POWER = (FIELD_SIZE + 1) >> 2;

    // Computes a s.t. a^2 = x in the field. Assumes a exists
    function squareRoot(uint256 x) internal view returns (uint256) {
        return bigModExp(x, SQRT_POWER);
    }

    // The value of y^2 given that (x,y) is on secp256k1.
    function ySquared(uint256 x) internal pure returns (uint256) {
        // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
        uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
        return addmod(xCubed, 7, FIELD_SIZE);
    }

    // True iff p is on secp256k1
    function isOnCurve(uint256[2] memory p) internal pure returns (bool) {
        // Section 2.3.6. in https://www.secg.org/sec1-v2.pdf
        // requires each ordinate to be in [0, ..., FIELD_SIZE-1]
        require(p[0] < FIELD_SIZE, "invalid x-ordinate");
        require(p[1] < FIELD_SIZE, "invalid y-ordinate");
        return ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
    }

    // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
    function fieldHash(bytes memory b) internal pure returns (uint256 x_) {
        x_ = uint256(keccak256(b));
        // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
        // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
        // string_to_point in the IETF draft
        while (x_ >= FIELD_SIZE) {
            x_ = uint256(keccak256(abi.encodePacked(x_)));
        }
    }

    // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
    // is always even, due to
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
    // step 5.C, which references arbitrary_string_to_point, defined in
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
    // returning the point with given x ordinate, and even y ordinate.
    function newCandidateSecp256k1Point(bytes memory b) internal view returns (uint256[2] memory p) {
        unchecked {
            p[0] = fieldHash(b);
            p[1] = squareRoot(ySquared(p[0]));
            if (p[1] % 2 == 1) {
                // Note that 0 <= p[1] < FIELD_SIZE
                // so this cannot wrap, we use unchecked to save gas.
                p[1] = FIELD_SIZE - p[1];
            }
        }
    }

    // Domain-separation tag for initial hash in hashToCurve. Corresponds to
    // vrf.go/hashToCurveHashPrefix
    uint256 internal constant HASH_TO_CURVE_HASH_PREFIX = 1;

    // Cryptographic hash function onto the curve.
    //
    // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
    // DESIGN NOTES above for slight differences.)
    //
    // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
    // "Construction of Rational Points on Elliptic Curves over Finite Fields"
    // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
    // and suggested by
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
    // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
    //
    // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
    // https://www.pivotaltracker.com/story/show/171120900
    function hashToCurve(uint256[2] memory pk, uint256 input) internal view returns (uint256[2] memory rv) {
        rv = newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX, pk, input));
        while (!isOnCurve(rv)) {
            rv = newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
        }
    }

    /**
     *
     * @notice Check that product==scalar*multiplicand
     *
     * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
     *
     * @param multiplicand: secp256k1 point
     * @param scalar: non-zero GF(GROUP_ORDER) scalar
     * @param product: secp256k1 expected to be multiplier * multiplicand
     * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
     */
    function ecmulVerify(uint256[2] memory multiplicand, uint256 scalar, uint256[2] memory product)
        internal
        pure
        returns (bool verifies)
    {
        require(scalar != 0, "zero scalar"); // Rules out an ecrecover failure case
        uint256 x = multiplicand[0]; // x ordinate of multiplicand
        uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
        // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
        // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
        bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
        address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
        // Explicit conversion to address takes bottom 160 bits
        address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
        return (actual == expected);
    }

    // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
    function projectiveSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
        internal
        pure
        returns (uint256 x3, uint256 z3)
    {
        unchecked {
            uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
            // Note this cannot wrap since x2 is a point in [0, FIELD_SIZE-1]
            // we use unchecked to save gas.
            uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
            (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
        }
    }

    // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
    function projectiveMul(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
        internal
        pure
        returns (uint256 x3, uint256 z3)
    {
        (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

    /**
     *
     *     @notice Computes elliptic-curve sum, in projective co-ordinates
     *
     *     @dev Using projective coordinates avoids costly divisions
     *
     *     @dev To use this with p and q in affine coordinates, call
     *     @dev projectiveECAdd(px, py, qx, qy). This will return
     *     @dev the addition of (px, py, 1) and (qx, qy, 1), in the
     *     @dev secp256k1 group.
     *
     *     @dev This can be used to calculate the z which is the inverse to zInv
     *     @dev in isValidVRFOutput. But consider using a faster
     *     @dev re-implementation such as ProjectiveECAdd in the golang vrf package.
     *
     *     @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
     *          coordinates of secp256k1 points. That is safe in this contract,
     *          because this method is only used by linearCombination, which checks
     *          points are on the curve via ecrecover.
     *
     *     @param px The first affine coordinate of the first summand
     *     @param py The second affine coordinate of the first summand
     *     @param qx The first affine coordinate of the second summand
     *     @param qy The second affine coordinate of the second summand
     *
     *     (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
     *
     *     Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
     *     on secp256k1, in P²(𝔽ₙ)
     *     @return sx
     *     @return sy
     *     @return sz
     */
    function projectiveECAdd(uint256 px, uint256 py, uint256 qx, uint256 qy)
        internal
        pure
        returns (uint256 sx, uint256 sy, uint256 sz)
    {
        unchecked {
            // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
            // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
            // We take the equations there for (sx,sy), and homogenize them to
            // projective coordinates. That way, no inverses are required, here, and we
            // only need the one inverse in affineECAdd.

            // We only need the "point addition" equations from Hankerson et al. Can
            // skip the "point doubling" equations because p1 == p2 is cryptographically
            // impossible, and required not to be the case in linearCombination.

            // Add extra "projective coordinate" to the two points
            (uint256 z1, uint256 z2) = (1, 1);

            // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
            // Cannot wrap since px and py are in [0, FIELD_SIZE-1]
            uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
            uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

            uint256 dx; // Accumulates denominator from sx calculation
            // sx=((qy-py)/(qx-px))^2-px-qx
            (sx, dx) = projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
            (sx, dx) = projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
            (sx, dx) = projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

            uint256 dy; // Accumulates denominator from sy calculation
            // sy=((qy-py)/(qx-px))(px-sx)-py
            (sy, dy) = projectiveSub(px, z1, sx, dx); // px-sx
            (sy, dy) = projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
            (sy, dy) = projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

            if (dx != dy) {
                // Cross-multiply to put everything over a common denominator
                sx = mulmod(sx, dy, FIELD_SIZE);
                sy = mulmod(sy, dx, FIELD_SIZE);
                sz = mulmod(dx, dy, FIELD_SIZE);
            } else {
                // Already over a common denominator, use that for z ordinate
                sz = dx;
            }
        }
    }

    // p1+p2, as affine points on secp256k1.
    //
    // invZ must be the inverse of the z returned by projectiveECAdd(p1, p2).
    // It is computed off-chain to save gas.
    //
    // p1 and p2 must be distinct, because projectiveECAdd doesn't handle
    // point doubling.
    function affineECAdd(uint256[2] memory p1, uint256[2] memory p2, uint256 invZ)
        internal
        pure
        returns (uint256[2] memory)
    {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
        require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
        // Clear the z ordinate of the projective representation by dividing through
        // by it, to obtain the affine representation
        return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
    }

    // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
    // cryptographically high probability.)
    function verifyLinearCombinationWithGenerator(uint256 c, uint256[2] memory p, uint256 s, address lcWitness)
        internal
        pure
        returns (bool)
    {
        // Rule out ecrecover failure modes which return address 0.
        unchecked {
            require(lcWitness != address(0), "bad witness");
            uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
            // Note this cannot wrap (X - Y % X), but we use unchecked to save
            // gas.
            bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
            bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
            // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
            // The point corresponding to the address returned by
            // ecrecover(-s*p[0],v,p[0],c*p[0]) is
            // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
            // See https://crypto.stackexchange.com/a/18106
            // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
            address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
            return computed == lcWitness;
        }
    }

    // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
    // requires cp1Witness != sp2Witness (which is fine for this application,
    // since it is cryptographically impossible for them to be equal. In the
    // (cryptographically impossible) case that a prover accidentally derives
    // a proof with equal c*p1 and s*p2, they should retry with a different
    // proof nonce.) Assumes that all points are on secp256k1
    // (which is checked in verifyVRFProof below.)
    function linearCombination(
        uint256 c,
        uint256[2] memory p1,
        uint256[2] memory cp1Witness,
        uint256 s,
        uint256[2] memory p2,
        uint256[2] memory sp2Witness,
        uint256 zInv
    ) internal pure returns (uint256[2] memory) {
        unchecked {
            // Note we are relying on the wrap around here
            require((cp1Witness[0] % FIELD_SIZE) != (sp2Witness[0] % FIELD_SIZE), "points in sum must be distinct");
            require(ecmulVerify(p1, c, cp1Witness), "First mul check failed");
            require(ecmulVerify(p2, s, sp2Witness), "Second mul check failed");
            return affineECAdd(cp1Witness, sp2Witness, zInv);
        }
    }

    // Domain-separation tag for the hash taken in scalarFromCurvePoints.
    // Corresponds to scalarFromCurveHashPrefix in vrf.go
    uint256 internal constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

    // Pseudo-random number from inputs. Matches vrf.go/scalarFromCurvePoints, and
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
    // The draft calls (in step 7, via the definition of string_to_int, in
    // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
    // first hash without checking that it corresponds to a number less than the
    // group order, which will lead to a slight bias in the sample.
    //
    // TODO(alx): We could save a bit of gas by following the standard here and
    // using the compressed representation of the points, if we collated the y
    // parities into a single bytes32.
    // https://www.pivotaltracker.com/story/show/171120588
    function scalarFromCurvePoints(
        uint256[2] memory hash,
        uint256[2] memory pk,
        uint256[2] memory gamma,
        address uWitness,
        uint256[2] memory v
    ) internal pure returns (uint256 s) {
        return uint256(keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX, hash, pk, gamma, v, uWitness)));
    }

    // True if (gamma, c, s) is a correctly constructed randomness proof from pk
    // and seed. zInv must be the inverse of the third ordinate from
    // projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
    // section 5.3 of the IETF draft.
    //
    // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
    // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
    // (which I could make a uint256 without using any extra space.) Would save
    // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
    function verifyVRFProof(
        uint256[2] memory pk,
        uint256[2] memory gamma,
        uint256 c,
        uint256 s,
        uint256 seed,
        address uWitness,
        uint256[2] memory cGammaWitness,
        uint256[2] memory sHashWitness,
        uint256 zInv
    ) internal view {
        unchecked {
            require(isOnCurve(pk), "public key is not on curve");
            require(isOnCurve(gamma), "gamma is not on curve");
            require(isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
            require(isOnCurve(sHashWitness), "sHashWitness is not on curve");
            // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
            // we use the address of u instead of u itself. Also, here we add the
            // terms instead of taking the difference, and in the proof construction in
            // vrf.GenerateProof, we correspondingly take the difference instead of
            // taking the sum as they do in step 7 of section 5.1.)
            require(verifyLinearCombinationWithGenerator(c, pk, s, uWitness), "addr(c*pk+s*g)!=_uWitness");
            // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
            uint256[2] memory hash = hashToCurve(pk, seed);
            // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
            uint256[2] memory v = linearCombination(c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
            // Steps 7. and 8. of IETF draft section 5.3
            uint256 derivedC = scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
            require(c == derivedC, "invalid proof");
        }
    }

    // Domain-separation tag for the hash used as the final VRF output.
    // Corresponds to vrfRandomOutputHashPrefix in vrf.go
    uint256 internal constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

    struct Request {
        address sender;
        uint256 nonce;
        bytes32 oracleId;
        uint32 nbWords;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        address callbackAddress;
        bytes4 callbackSelector;
        uint64 blockNumber;
    }

    struct Proof {
        uint256[2] pk;
        uint256[2] gamma;
        uint256 c;
        uint256 s;
        uint256 seed;
        address uWitness;
        uint256[2] cGammaWitness;
        uint256[2] sHashWitness;
        uint256 zInv;
    }

    /* ***************************************************************************
     * @notice Returns proof's output, if proof is valid. Otherwise reverts

     * @param proof vrf proof components
     * @param seed  seed used to generate the vrf output
     *
     * Throws if proof is invalid, otherwise:
     * @return output i.e., the random output implied by the proof
     * ***************************************************************************
     */
    function randomValueFromVRFProof(Proof memory proof, uint256 seed) internal view returns (uint256 output) {
        verifyVRFProof(
            proof.pk,
            proof.gamma,
            proof.c,
            proof.s,
            seed,
            proof.uWitness,
            proof.cGammaWitness,
            proof.sHashWitness,
            proof.zInv
        );
        output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, proof.gamma)));
    }
}

interface IVRFCoordinator {
    event RequestRandomWords(
        bytes32 requestId,
        address sender,
        uint256 nonce,
        bytes32 oracleId,
        uint32 nbWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        address callbackAddress,
        bytes4 callbackSelector
    );
    event FulfillRandomWords(bytes32 requestId);

    error InvalidRequestConfirmations();
    error InvalidCallbackGasLimit();
    error InvalidNumberOfWords();
    error InvalidOracleId();
    error InvalidCommitment();
    error InvalidRequestParameters();
    error FailedToFulfillRandomness();

    function requestRandomWords(
        bytes32 _oracleId,
        uint32 _nbWords,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        address _callbackAddress,
        bytes4 _callbackSelector
    ) external returns (bytes32);

    function fulfillRandomWords(
        VRF.Proof memory _proof,
        VRF.Request memory _request
    ) external;
}

/**
 * @custom:attribution https://github.com/hamdiallam/Solidity-RLP
 * @title RLPReader
 * @notice RLPReader is a library for parsing RLP-encoded byte arrays into Solidity types. Adapted
 *         from Solidity-RLP (https://github.com/hamdiallam/Solidity-RLP) by Hamdi Allam with
 *         various tweaks to improve readability.
 */
library RLPReader {
    /**
     * Custom pointer type to avoid confusion between pointers and uint256s.
     */
    type MemoryPointer is uint256;

    /**
     * @notice RLP item types.
     *
     * @custom:value DATA_ITEM Represents an RLP data item (NOT a list).
     * @custom:value LIST_ITEM Represents an RLP list item.
     */
    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /**
     * @notice Struct representing an RLP item.
     *
     * @custom:field length Length of the RLP item.
     * @custom:field ptr    Pointer to the RLP item in memory.
     */
    struct RLPItem {
        uint256 length;
        MemoryPointer ptr;
    }

    /**
     * @notice Max list length that this library will accept.
     */
    uint256 internal constant MAX_LIST_LENGTH = 32;

    /**
     * @notice Converts bytes to a reference to memory position and length.
     *
     * @param _in Input bytes to convert.
     *
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        // Empty arrays are not RLP items.
        require(
            _in.length > 0,
            "RLPReader: length of an RLP item must be greater than zero to be decodable"
        );

        MemoryPointer ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * @notice Reads an RLP list value into a list of RLP items.
     *
     * @param _in RLP list value.
     *
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, uint256 listLength, RLPItemType itemType) = _decodeLength(_in);

        require(
            itemType == RLPItemType.LIST_ITEM,
            "RLPReader: decoded item type for list is not a list item"
        );

        require(
            listOffset + listLength == _in.length,
            "RLPReader: list item has an invalid data remainder"
        );

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({
                    length: _in.length - offset,
                    ptr: MemoryPointer.wrap(MemoryPointer.unwrap(_in.ptr) + offset)
                })
            );

            // We don't need to check itemCount < out.length explicitly because Solidity already
            // handles this check on our behalf, we'd just be wasting gas.
            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: MemoryPointer.wrap(MemoryPointer.unwrap(_in.ptr) + offset)
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * @notice Reads an RLP list value into a list of RLP items.
     *
     * @param _in RLP list value.
     *
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * @notice Reads an RLP bytes value into bytes.
     *
     * @param _in RLP bytes value.
     *
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "RLPReader: decoded item type for bytes is not a data item"
        );

        require(
            _in.length == itemOffset + itemLength,
            "RLPReader: bytes value contains an invalid remainder"
        );

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * @notice Reads an RLP bytes value into bytes.
     *
     * @param _in RLP bytes value.
     *
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * @notice Reads the raw bytes of an RLP item.
     *
     * @param _in RLP item to read.
     *
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }

    /**
     * @notice Decodes the length of an RLP item.
     *
     * @param _in RLP item to decode.
     *
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        // Short-circuit if there's nothing to decode, note that we perform this check when
        // the user creates an RLP item via toRLPItem, but it's always possible for them to bypass
        // that function and create an RLP item directly. So we need to check this anyway.
        require(
            _in.length > 0,
            "RLPReader: length of an RLP item must be greater than zero to be decodable"
        );

        MemoryPointer ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.
            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(
                _in.length > strLen,
                "RLPReader: length of content must be greater than string length (short string)"
            );

            bytes1 firstByteOfContent;
            assembly {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                strLen != 1 || firstByteOfContent >= 0x80,
                "RLPReader: invalid prefix, single byte < 0x80 are not prefixed (short string)"
            );

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "RLPReader: length of content must be > than length of string length (long string)"
            );

            bytes1 firstByteOfContent;
            assembly {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                firstByteOfContent != 0x00,
                "RLPReader: length of content must not have any leading zeros (long string)"
            );

            uint256 strLen;
            assembly {
                strLen := shr(sub(256, mul(8, lenOfStrLen)), mload(add(ptr, 1)))
            }

            require(
                strLen > 55,
                "RLPReader: length of content must be greater than 55 bytes (long string)"
            );

            require(
                _in.length > lenOfStrLen + strLen,
                "RLPReader: length of content must be greater than total length (long string)"
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(
                _in.length > listLen,
                "RLPReader: length of content must be greater than list length (short list)"
            );

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(
                _in.length > lenOfListLen,
                "RLPReader: length of content must be > than length of list length (long list)"
            );

            bytes1 firstByteOfContent;
            assembly {
                firstByteOfContent := and(mload(add(ptr, 1)), shl(248, 0xff))
            }

            require(
                firstByteOfContent != 0x00,
                "RLPReader: length of content must not have any leading zeros (long list)"
            );

            uint256 listLen;
            assembly {
                listLen := shr(sub(256, mul(8, lenOfListLen)), mload(add(ptr, 1)))
            }

            require(
                listLen > 55,
                "RLPReader: length of content must be greater than 55 bytes (long list)"
            );

            require(
                _in.length > lenOfListLen + listLen,
                "RLPReader: length of content must be greater than total length (long list)"
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * @notice Copies the bytes from a memory location.
     *
     * @param _src    Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     *
     * @return Copied bytes.
     */
    function _copy(
        MemoryPointer _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (_length == 0) {
            return out;
        }

        // Mostly based on Solidity's copy_memory_to_memory:
        // solhint-disable max-line-length
        // https://github.com/ethereum/solidity/blob/34dd30d71b4da730488be72ff6af7083cf2a91f6/libsolidity/codegen/YulUtilFunctions.cpp#L102-L114
        uint256 src = MemoryPointer.unwrap(_src) + _offset;
        assembly {
            let dest := add(out, 32)
            let i := 0
            for {

            } lt(i, _length) {
                i := add(i, 32)
            } {
                mstore(add(dest, i), mload(add(src, i)))
            }

            if gt(i, _length) {
                mstore(add(dest, _length), 0)
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

        uint256 ptr = MemoryPointer.unwrap(_in.ptr) + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(uint160(readUint256(_in)));
    }
}

contract BlockHashStore {
    mapping(uint256 => bytes32) public blockHashes;
    uint256 public latestBlockNumber;

    /// @notice Gets a block hash at a particular block number.
    /// @param _n The block number;
    function getBlockHash(uint256 _n) external view returns (bytes32) {
        bytes32 h = blockHashes[_n];
        require(h != 0, "block hash not available");
        return h;
    }

    /// @notice Stores block hashes for a range of blocks using the blockhash opcode.
    /// @param _blockNumbers The block numbers to store hashes for.
    function storeBlockHashesViaOpCode(uint256[] memory _blockNumbers) external {
        for (uint256 i = 0; i < _blockNumbers.length; i++) {
            bytes32 h = blockhash(_blockNumbers[i]);
            require(h != 0, "block hash not available");
            blockHashes[_blockNumbers[i]] = h;
        }
    }

    /// @notice Stores block hashes for a range of blocks using merkle proofs.
    /// @param _blockHeaders The block headers to store hashes for.
    function storeBlockHashesViaMerkleProofs(bytes[] memory _blockHeaders) external {
        for (uint256 i = 0; i < _blockHeaders.length; i++) {
            RLPReader.RLPItem[] memory blockHeader = RLPReader.readList(_blockHeaders[i]);

            uint256 blockNumber = RLPReader.readUint256(blockHeader[8]);
            bytes32 blockHash = keccak256(_blockHeaders[i]);
            require(blockHashes[blockNumber] == blockHash, "Block hash not proven");

            uint256 parentNumber = blockNumber - 1;
            bytes32 parentHash = RLPReader.readBytes32(blockHeader[0]);
            blockHashes[parentNumber] = parentHash;
        }
    }
}

/// @title VRFCoordinator
/// @notice This contract handles requests and fulfillments of random words from a VRF.
contract VRFCoordinator is VRF, IVRFCoordinator {
    /// @notice The oracle identifier used for validating the VRF proof came from the oracle.
    bytes32 public constant ORACLE_ID = 0x8e8d1df6c3c3e29a24c7a114ded0000e32f8f40414d3ab3a830f735a3553e18e;

    /// @notice The oracle address used for validating that the VRF proof came from the oracle.
    address public constant ORACLE_ADDRESS = 0xDEd0000E32f8F40414d3ab3a830f735a3553E18e;

    /// @notice The minimum number of request confirmatins.
    uint16 public constant MINIMUM_REQUEST_CONFIRMATIONS = 0;

    /// @notice The maximum callback gas limit.
    uint64 public constant MAXIMUM_CALLBACK_GAS_LIMIT = 10000000;

    /// @notice The maximum number of random words that can be provided in the callback.
    uint64 public constant MAXIMUM_NB_WORDS = 64;

    /// @notice The request nonce.
    uint256 public nonce = 0;

    /// @notice The storage proof oracle.
    BlockHashStore public blockHashStore;

    /// @notice The mapping of request ids to commitments to what is stored in the request.
    mapping(bytes32 => bytes32) public requests;

    /// @notice The mapping of oracle ids to oracle addresses.
    mapping(bytes32 => address) public oracles;

    constructor(address _blockHashStore) {
        oracles[ORACLE_ID] = ORACLE_ADDRESS;
        blockHashStore = BlockHashStore(_blockHashStore);
    }

    /// @notice Requests random words from the VRF.
    /// @param _oracleId The address of the operator to get shares for.
    /// @param _requestConfirmations The number of blocks to wait before posting the VRF request.
    /// @param _callbackGasLimit The maximum amount of gas the callback can use.
    /// @param _nbWords The number of random words to request.
    /// @param _callbackSelector The selector of the callback function.
    function requestRandomWords(
        bytes32 _oracleId,
        uint32 _nbWords,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        address _callbackAddress,
        bytes4 _callbackSelector
    ) external returns (bytes32) {
        if (_requestConfirmations < MINIMUM_REQUEST_CONFIRMATIONS) {
            revert InvalidRequestConfirmations();
        } else if (_callbackGasLimit > MAXIMUM_CALLBACK_GAS_LIMIT) {
            revert InvalidCallbackGasLimit();
        } else if (_nbWords > MAXIMUM_NB_WORDS) {
            revert InvalidNumberOfWords();
        }

        bytes32 seed = keccak256(abi.encode(_callbackAddress, nonce));
        bytes32 requestId = keccak256(abi.encode(_oracleId, seed));
        requests[requestId] = keccak256(
            abi.encode(
                requestId,
                msg.sender,
                nonce,
                _oracleId,
                _nbWords,
                _requestConfirmations,
                _callbackGasLimit,
                _callbackAddress,
                _callbackSelector
            )
        );

        emit RequestRandomWords(
            requestId,
            msg.sender,
            nonce,
            _oracleId,
            _nbWords,
            _requestConfirmations,
            _callbackGasLimit,
            _callbackAddress,
            _callbackSelector
        );

        nonce += 1;
        return requestId;
    }

    /// @notice Fulfills the request for random words.
    /// @param _proof The address of the operator to get shares for.
    /// @param _request The number of shares for the operator.
    function fulfillRandomWords(VRF.Proof memory _proof, VRF.Request memory _request) external {
        bytes32 oracleId = keccak256(abi.encode(_proof.pk));
        address oracle = oracles[oracleId];
        if (oracle == address(0)) {
            revert("Invalid oracle id");
        }

        bytes32 seed = keccak256(abi.encode(_request.callbackAddress, _request.nonce));
        bytes32 requestId = keccak256(abi.encode(oracleId, seed));
        bytes32 commitment = requests[requestId];
        bytes32 expectedCommitment = keccak256(
            abi.encode(
                requestId,
                _request.sender,
                _request.nonce,
                _request.oracleId,
                _request.nbWords,
                _request.requestConfirmations,
                _request.callbackGasLimit,
                _request.callbackAddress,
                _request.callbackSelector
            )
        );
        if (commitment == bytes32(0)) {
            revert("Invalid commitment 1");
        } else if (commitment != expectedCommitment) {
            revert("Invalid commitment 2");
        }
        delete requests[requestId];

        bytes32 blockHash;
        if (block.number - 256 > _request.blockNumber) {
            blockHash = blockHashStore.getBlockHash(_request.blockNumber);
        } else {
            blockHash = blockhash(_request.blockNumber);
        }
        uint256 actualSeed = uint256(keccak256(abi.encodePacked(seed, blockHash)));

        uint256 randomness = VRF.randomValueFromVRFProof(_proof, actualSeed);
        uint256[] memory randomWords = new uint256[](_request.nbWords);
        for (uint256 i = 0; i < _request.nbWords; i++) {
            randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
        }

        bytes memory fulfillRandomnessCall = abi.encodeWithSelector(_request.callbackSelector, requestId, randomWords);
        (bool status,) = _request.callbackAddress.call(fulfillRandomnessCall);

        if (!status) {
            revert("Failed to fulfill randomness");
        }

        emit FulfillRandomWords(requestId);
    }
}