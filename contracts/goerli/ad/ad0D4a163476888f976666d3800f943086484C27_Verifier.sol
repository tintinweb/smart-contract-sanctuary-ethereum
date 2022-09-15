// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return r the sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        uint256[4] memory input = [
            p1.X, p1.Y,
            p2.X, p2.Y
        ];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return r the product of a point on G1 and a scalar, i.e.
     *         p == p.scalarMul(1) and p.plus(p) == p.scalarMul(2) for all
     *         points p.
     */
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input = [p.X, p.Y, s];
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        uint256[24] memory input = [
            a1.X, a1.Y, a2.X[0], a2.X[1], a2.Y[0], a2.Y[1],
            b1.X, b1.Y, b2.X[0], b2.X[1], b2.Y[0], b2.Y[1],
            c1.X, c1.Y, c2.X[0], c2.X[1], c2.Y[0], c2.Y[1],
            d1.X, d1.Y, d2.X[0], d2.X[1], d2.Y[0], d2.Y[1]
        ];
        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, mul(24, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract Verifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[7] IC;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(8907998999939208622500590566637266966408410062787790205497052229539393817335), uint256(20674867001305001902352113719483550815741000021003735227713391276783350752321));
        vk.beta2 = Pairing.G2Point([uint256(11107796287360604242965770184363804675126362064209028733499977878455272167268), uint256(16899527531830802670266154980362210102452163897236597717604509280482582828966)], [uint256(4766526715585500142696230651179797626601275152285683542395541638309157287767), uint256(7928169183324991302973448100633264046661005454538155842334559014168389959202)]);
        vk.gamma2 = Pairing.G2Point([uint256(16514583719375238472567295048918770506855938536416363445575282161338570773430), uint256(12286201650275694579098491151151677070377139926150691816139110164729281291869)], [uint256(19987597625173932055818592356825169671017917561872562595992277733619364860323), uint256(17498890337615545563052041320170526568487190488005806057264758048254353629041)]);
        vk.delta2 = Pairing.G2Point([uint256(7393290117403372463747480558131288947790611207888391492313411638329930302256), uint256(4877235728180862323789013207725302905080768308920215442425347808394607135006)], [uint256(11425658301268047592639405947749321600368017964974408381567724126578250072054), uint256(6954873001802326560390010529284276670683505840437828535667079150995671576177)]);
        vk.IC[0] = Pairing.G1Point(uint256(7108340474680773564383491315701138927203264902526918689371282329361756500867), uint256(7471524054379259645276563310285692002641977896563292908672945957354430375176));
        vk.IC[1] = Pairing.G1Point(uint256(11396199354607530784804852350554241448535003717610824730356163717414629285749), uint256(11400502447124845441553191734932099884954334737452162657873943915098041862662));
        vk.IC[2] = Pairing.G1Point(uint256(374978992163652417347951955430332137501599872519504855611312486383436742309), uint256(21290906098660156273597564061237295968974700592046501974019273659564082507146));
        vk.IC[3] = Pairing.G1Point(uint256(6854466002793619750283710453394172880926144072029892542861018650093545766060), uint256(19028006985272749558689841112026834499339365902212643080268202134467436327842));
        vk.IC[4] = Pairing.G1Point(uint256(4272747238786658057545061353017744838555023593857638657570890116877266009387), uint256(4500452392438098052633383736429841745806595409159210681326232352086627356961));
        vk.IC[5] = Pairing.G1Point(uint256(10308452799939048509809357002506278474512139079886292859397996087667791557660), uint256(6827214210594559546490489832158525845384259759542039220061532379521955492591));
        vk.IC[6] = Pairing.G1Point(uint256(11528883414708485004559852619866524812267579856734432266759308513708252214142), uint256(7303828077439541288434162897478318162422475374529007359767439688197244896750));

    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        bytes memory proof,
        uint256[6] memory input
    ) public view returns (bool) {
        uint256[8] memory p = abi.decode(proof, (uint256[8]));
        for (uint8 i = 0; i < p.length; i++) {
            // Make sure that each element in the proof is less than the prime q
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Pairing.G1Point memory proofA = Pairing.G1Point(p[0], p[1]);
        Pairing.G2Point memory proofB = Pairing.G2Point([p[2], p[3]], [p[4], p[5]]);
        Pairing.G1Point memory proofC = Pairing.G1Point(p[6], p[7]);

        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vkX
        Pairing.G1Point memory vkX = vk.IC[0];
        for (uint256 i = 0; i < input.length; i++) {
            // Make sure that every input is less than the snark scalar field
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-input-gte-snark-scalar-field");
            vkX = Pairing.plus(vkX, Pairing.scalarMul(vk.IC[i + 1], input[i]));
        }

        return Pairing.pairing(
            Pairing.negate(proofA),
            proofB,
            vk.alfa1,
            vk.beta2,
            vkX,
            vk.gamma2,
            proofC,
            vk.delta2
        );
    }
}