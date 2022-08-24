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
        * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
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
    function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
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
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }

    /*
        * @return r the product of a point on G1 and a scalar, i.e.
        *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
        *         points p.
        */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
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
            case 0 { invalid() }
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
    )
        internal
        view
        returns (bool)
    {
        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
        }
        require(success, "pairing-opcode-failed");
        return out[0] != 0;
    }
}

contract TransferVerifier {
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    using Pairing for *;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[6] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            16988803876455401728118921265024775569720342714900171398627154983201753057368,
            5259321097325446461647920261894059216643325950919155029566337830243385196539
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(5516119072320083013351408169046273192599550192988586794273073388807841689446),
                319305504431458311582579567726499241285572233810383274665829683762803415215
            ],
            [
                uint256(11734090293334846977592194717841703651197637225018499772936854046791657874144),
                594846986757926784586414115408697824652885026264135436951483524722983324956
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(3814143100336589537693106125281378575059105236614765293559877298888766985825),
                21040789521638946151102283720589041472702118346518837661742047423393082384415
            ],
            [
                uint256(16205113285061610718650579704436838030598868893343160591081101636174308622356),
                10816214316476743713973025173895327759457766655328225341978068783964794500202
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(6801354414243688737298731692309295074061062002133649967939179054912897110546),
                8265038963944325394566424202721426707086044801724106695057116244957050015095
            ],
            [
                uint256(14525510148420645058339568346494684593835900023701708057746664178874198043606),
                19908544026743735520564480366579985049648832720658428550897450965561480305744
            ]
        );
        vk.IC[0] = Pairing.G1Point(
            21181527846060603916718681698789334284955905012514223518539076715759345421787,
            15323340205781858569864795057936146892483275533985450851399467601369066796864
        );
        vk.IC[1] = Pairing.G1Point(
            783956195321084311878520383020014039587775400577305886537252959416334856093,
            18727839594476432203802259673426759797136370290937304410654812334892413557437
        );
        vk.IC[2] = Pairing.G1Point(
            5078495009196174878223212564064984820122871915873999301655571500014148160086,
            8714762362785827986229568793273698304269961197095998542071654468547174139327
        );
        vk.IC[3] = Pairing.G1Point(
            2951904321387916185898324607958815021637688276514819595716453653281796706953,
            13738183871376848186508752020798166580978465972769393642501272262635448588952
        );
        vk.IC[4] = Pairing.G1Point(
            8811249165492651179791669030464980448792413315568936841552237475387982657225,
            1869580813864525107621651814849153942044410150542822088661406348114114278009
        );
        vk.IC[5] = Pairing.G1Point(
            20050729035056607939446605238642695320594635294135723757178066160471839675115,
            15294048989160410760810640316350551145943178929943445716494093015261588382454
        );
    }

    /*
        * @returns Whether the proof is valid given the hardcoded verifying key
        *          above and the public inputs
        */
    function verifyProof(uint256[5] memory input, uint256[8] memory p) public view returns (bool) {
        // Make sure that each element in the proof is less than the prime q
        for (uint8 i = 0; i < p.length; i++) {
            require(p[i] < PRIME_Q, "verifier-proof-element-gte-prime-q");
        }
        Proof memory _proof;
        _proof.A = Pairing.G1Point(p[0], p[1]);
        _proof.B = Pairing.G2Point([p[3], p[2]], [p[5], p[4]]);
        _proof.C = Pairing.G1Point(p[6], p[7]);
        VerifyingKey memory vk = verifyingKey();
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        vk_x = Pairing.plus(vk_x, vk.IC[0]);
        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        return Pairing.pairing(Pairing.negate(_proof.A), _proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, _proof.C, vk.delta2);
    }
}