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
            16415333598406383564946370257946434084091055755466764772750572939933650876745,
            19569267032701676210451818058522825905418572730488791555110064655598247529894
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(6954187240847134810870195021635050508129656958165868066470584227631646421414),
                7656767970067776180069742919266871513683533867539042569876683203778578843267
            ],
            [
                uint256(10486810671649156082661940730087855697964597781057159395151160433842566322885),
                10704551051609509426544187118133040608510870066752365680903532318659101682209
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(5864461098662574330331199589790554756494955359205316455460219402103560729652),
                15563272389648123460540613887608784299883246239362977557406696313913585019654
            ],
            [
                uint256(5788922245585123724514755871409000832960934210886405576012815252196070793227),
                12997410743375410116701045098927048055198722397408207395382156844936211037088
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(10058172113941100839787937189677141384858738004165763541333559715727336460325),
                20694658911299777738591784658668812603960514949596861905143395056149630980859
            ],
            [
                uint256(21017077219480329155269875821472917725021668138518593347682376729503906968557),
                339344190381389459373110638247405994807378432291728518540960111930912183937
            ]
        );
        vk.IC[0] = Pairing.G1Point(
            13681503752480992573250352015848552162102608362547340099997219700665468758453,
            18469704668724091986374834862248402328048274352668914566106446103203506757641
        );
        vk.IC[1] = Pairing.G1Point(
            5155141369322066499278075863042430869544434741756379439243668273532815361129,
            2312873225682507959632290935214039425568005579554508047051914812550270696461
        );
        vk.IC[2] = Pairing.G1Point(
            17623176542374429378173870485590593259940536593021247755302831306365505283326,
            15723292920514100065446005981039341178905183871620876336145446389142408706608
        );
        vk.IC[3] = Pairing.G1Point(
            13256181884832958327758753647626491924224790825584471487154780936921189140075,
            143620660870185322878733907655091189916032872209768616441723239824503336732
        );
        vk.IC[4] = Pairing.G1Point(
            2308768762988917597544863203901527483352649822720217849124235107029439500053,
            12367429489746330595134351102962650713941428606357609766362271810012098427021
        );
        vk.IC[5] = Pairing.G1Point(
            6470459293635020254901488214917055840856289969593467761437994719694745664589,
            12572499958960059574765133211094539533943848360923796483566126241304617361821
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