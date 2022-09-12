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
        vk.alfa1 = Pairing.G1Point(uint256(8425843469658846114783068193388988637556187704708931404628586037032652331953), uint256(19741194310193101055264300079091796940831917976209077589868201286876693324815));
        vk.beta2 = Pairing.G2Point([uint256(21424060357513579406589434308749305886062125960980948974200066198172050503835), uint256(15216836125727414053270880546980968350410445762929836604669666748278954599401)], [uint256(12747611835187745353841977761253312597078600092627133195107851262525045826842), uint256(15346456060909353460230681550252840399454577807957576370091774246555371319498)]);
        vk.gamma2 = Pairing.G2Point([uint256(5759273610079894231451705034144966825239634471278008578211421363421554345801), uint256(37131332188893991948613633812677796899235428314131354368993185785565948181)], [uint256(2988911328519409625617338089155097912490529277162486574795529771300830739779), uint256(15319139371388956990161914171958330401638289960148884480020789153081710113360)]);
        vk.delta2 = Pairing.G2Point([uint256(17647536277394512517723669662491552286848685940558750876714168843911381025831), uint256(14595580376164290309091361954042980228583339388623757388779843322970599095958)], [uint256(1921071149694661022516256604000891133825623782628336503628874274257808529248), uint256(1821550388131964532369425249736267066851747136542465740183336262790161934404)]);
        vk.IC[0] = Pairing.G1Point(uint256(12395362144742713942742453057224637274274251955743830710263275102123032460185), uint256(19961279312847321371245408597620107994959496192948368018251624375120876100227));
        vk.IC[1] = Pairing.G1Point(uint256(12553996773408232348609231678273897343371938895939039847183719140743373076234), uint256(52014146372950709516490427282244649866797128907468723173013056796190721404));
        vk.IC[2] = Pairing.G1Point(uint256(12603567781789211986872452676687486502759231221889717727440650750554761819898), uint256(15359625086209100048686628511640335894023993005114501822272531745873118453993));
        vk.IC[3] = Pairing.G1Point(uint256(17029616104522039203523317242758835821539958179443417089076820185114420723122), uint256(19984527259629834020816989949206361640899783188479221325144195187460583722093));
        vk.IC[4] = Pairing.G1Point(uint256(5741990749522205946776388335368486474355254316782654603581255393331158286287), uint256(7226721383285327908619006218802200496382615095439182406606283924264357516453));
        vk.IC[5] = Pairing.G1Point(uint256(14418541793202015615383547380082808469657002748532449231696559461217808759923), uint256(20381566874922109251251748133994246253559553620632006753271502977964535827326));
        vk.IC[6] = Pairing.G1Point(uint256(14795209009907541409718174845397797810880166713706197820015153143717223694910), uint256(3716031822761170048824722207383337566912897168170055338675468883298047193826));

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