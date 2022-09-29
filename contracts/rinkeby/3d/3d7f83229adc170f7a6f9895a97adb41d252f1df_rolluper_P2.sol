/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// File: Reg_Verifier.sol

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

pragma solidity >=0.6.11 <0.9.0;
library Pairing2 {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
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
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed..");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
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
contract Reg_Verifier {
    using Pairing2 for *;
    struct VerifyingKey {
        Pairing2.G1Point alfa1;
        Pairing2.G2Point beta2;
        Pairing2.G2Point gamma2;
        Pairing2.G2Point delta2;
        Pairing2.G1Point[] IC;
    }
    struct Proof {
        Pairing2.G1Point A;
        Pairing2.G2Point B;
        Pairing2.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing2.G1Point(
            4015971214601274450582101135234403977948829308494056514325025916553484348525,
            11789912012887439061740017382543741713717193756194819373236584508249107661673
        );

        vk.beta2 = Pairing2.G2Point(
            [20255323772829801273420091817897198918239028838425965777612542038169123419508,
             3932073073691051474925814736979819662971431136358536406781793245616612078183],
            [20315184067271392694795858456192746192780612986629659565241454598731903404551,
             1817538646234672822961599988535674980504573755905895828151514219476194302891]
        );
        vk.gamma2 = Pairing2.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing2.G2Point(
            [12548161227238359556021957256769530722905988401603202767636026093398030203310,
             15553706886354425090031097151907306347612542013475810050805480691156561316105],
            [16652140852987545104306778975212832995648190202010693439932108943369257637551,
             19212185480755987181444499463828643889867271363504812109969887517275428155375]
        );
        vk.IC = new Pairing2.G1Point[](12);
        
        vk.IC[0] = Pairing2.G1Point( 
            19321648622158999614197354779352877703317026493802980775138164547531179039580,
            491295568835180872839595301249149686934215794072861967481523868328442717309
        );                                      
        
        vk.IC[1] = Pairing2.G1Point( 
            29292340926518490856732150589824216924852530565567349700614092929742594504,
            3605705859584611860692046913371169140651580649974362770735804301557513717451
        );                                      
        
        vk.IC[2] = Pairing2.G1Point( 
            16360656694551577108156022833619585556024004569932237292639019665967367048015,
            1095528198642778934504777553610997764045812257524869599296936347402673791763
        );                                      
        
        vk.IC[3] = Pairing2.G1Point( 
            8265077391584071439274844930199509120073386449130532269748631058897721006772,
            3413666823100860124352222318000255565292217958658311112371322705569850155387
        );                                      
        
        vk.IC[4] = Pairing2.G1Point( 
            2542545583714447541797028677245404460275159187217554545574319930114571435038,
            18511297084697960322502124408647562619165275234115301190672132003848697561288
        );                                      
        
        vk.IC[5] = Pairing2.G1Point( 
            18211101168406672483916881838992631344128240369477362232505857876394896379233,
            17931160234582473572555606766640442338911614141406696509499692575018923654353
        );                                      
        
        vk.IC[6] = Pairing2.G1Point( 
            11335158981227607941963016772608829371902218105163326715754890895739154137651,
            13683255667568335349113016845443976847568206796397092661907822854214921117051
        );                                      
        
        vk.IC[7] = Pairing2.G1Point( 
            14134492058957931445962702383843842583141008710613047655331400206989072538133,
            21203155814018425704019170327911911497246323811518499731201524018616557853993
        );                                      
        
        vk.IC[8] = Pairing2.G1Point( 
            18364209662211304575217045265794528227336365139717916499937541364831583411158,
            8823963477792204657731389660376851340106312088020590215731402328200018977255
        );                                      
        
        vk.IC[9] = Pairing2.G1Point( 
            13382458347180261977303736806729623347728212258774596244024538447918234869023,
            12293530290970849288073150801656639888457107253739148017132026423273892554918
        );                                      
        
        vk.IC[10] = Pairing2.G1Point( 
            12077054205214126629863505980184633894050227457637608945348163184453902414697,
            12128094514492871297478865527449748223331679091528871717420360061043132474331
        );                                      
        
        vk.IC[11] = Pairing2.G1Point( 
            17074504323824497014847592072569665068827236373122239624354207641191257137728,
            14960254617796839431839393543444875527028652150599697128737849756804827756711
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing2.G1Point memory vk_x = Pairing2.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing2.addition(vk_x, Pairing2.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing2.addition(vk_x, vk.IC[0]);
        if (!Pairing2.pairingProd4(
            Pairing2.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[3] memory input
        ) public view returns (bool r) {
        // Proof memory proof;
        // proof.A = Pairing.G1Point(a[0], a[1]);
        // proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        // proof.C = Pairing.G1Point(c[0], c[1]);
        // uint[] memory inputValues = new uint[](input.length);
        // for(uint i = 0; i < input.length; i++){
        //     inputValues[i] = input[i];
        // }
        // if (verify(inputValues, proof) == 0) {
        //     return true;
        // } else {
        //     return false;
        // }
        return true;
    }
}
// File: Tx_Verifier.sol

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

pragma solidity ^0.8.8;

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
        require(success, "pairing-add-failed");
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
        require(success, "pairing-mul-failed");
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
        require(p1.length == p2.length, "pairing-lengths-failed");
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
        require(success, "pairing-opcode-failed");
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

contract Tx_Verifier {
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
            18523247163333788565124916083587968851599436456746567810913195688456048256614,
            521474907290236622143206043513568941331256179814234310146541844730292868920
        );

        vk.beta2 = Pairing.G2Point(
            [
                7989490878007999290244299040647938599517311754093517742724240564262197497603,
                3929881642289669017145693425691774683914758873790694223226162320907776934310
            ],
            [
                17810637242258864984702073598426503286172584374189503442813120090872271617291,
                11175503489632540088930284018855287068573078167129168829464797255029375465698
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
                11372612564448757388364063330662295344738451664162760223653601215862932645812,
                21034695022898420851341655841722417034289115132311794566443522480550238970552
            ],
            [
                4174795505130317274293806035912064616876279049736772478458707905701383444097,
                14895387618084513942975735947732012343211770765980544385758536463727259625719
            ]
        );
        vk.IC = new Pairing.G1Point[](9);

        vk.IC[0] = Pairing.G1Point(
            13868954497106666715124755499372275788743193469892172268690393405079712926707,
            8744182351507911499337126700932055213692292178311492443751793274042570930817
        );

        vk.IC[1] = Pairing.G1Point(
            8187510149291767670561949704966117423918951847501206086127516648998412039322,
            15348030522104475106157445056772642376808356647714170422101833152696272185331
        );

        vk.IC[2] = Pairing.G1Point(
            11162579173431865880609830235328224991479180620910386471018136870483009813343,
            12802065772863944196660040154367126437377295663628656636587038581033306228712
        );

        vk.IC[3] = Pairing.G1Point(
            17808604375367802698687590955058952559683734493414546801886996765490289721655,
            9326635665600233900431367334751083416538232158041309546795670155326132580850
        );

        vk.IC[4] = Pairing.G1Point(
            3846319592761846932991254238944243053310594854215173151840826346038457195826,
            15563024093872080335048586461393133291403242761707332811527872373039968189480
        );

        vk.IC[5] = Pairing.G1Point(
            15455550092631395619064636537038025285877213418480999294833776668851633706392,
            2585721886267379536591088897717025705023964555829296548941115459969084875112
        );

        vk.IC[6] = Pairing.G1Point(
            10164120671871867047642715086759796764085395474606867265753812771592983722251,
            6138164553590670610319619550536174046273516566875024104942790943580290994768
        );

        vk.IC[7] = Pairing.G1Point(
            4445812408848041207042544303056452368245814537918819995901420127713695930776,
            15523265648570801603476728562117988203360223504021466178538298612275747801077
        );

        vk.IC[8] = Pairing.G1Point(
            14145851812838122955920538325476456259555702953396014336458416338868345129442,
            16297434929956340699517534234847638339376328125227393129497540754200408526776
        );
    }

    function verify(uint256[] memory input, Proof memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
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
        uint256[] memory input
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Rolluper.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;






error Insufficient_Account_Balance();
error Error_OnlyOwner();
error ERC20_Transfer_failed();

contract rolluper_P2 is Ownable {
    // L2Addr, L1Addr, amount
    event newUserEnrolled(uint256, address, uint256);
    // L2Addr, amount
    event memberDeposit(uint256, uint256);

    // Declare verifier variable
    Tx_Verifier public txVerifier;
    Reg_Verifier public regVerifier;

    // Default accounts (Optimizable)
    uint256 public constant MINT_ACC = 0;
    uint256 public constant BURN_ACC = 1;
    uint256 public constant AUCTION_ACC = 2;

    // stateRoot & UpdateTime
    struct State {
        uint256 stateRoot;
        uint256 updateTime;
    }

    // Init state variable (stateRoot = 0 / UpdateTime = current block number)
    State state = State(0, block.number);

    // Transaction roots (not using right now)
    // uint256[] public txRoot;

    // Addresses mapping table (L2 <--> L1)
    mapping(uint256 => address) public L2ToL1Addr;
    mapping(address => uint256) public L1ToL2Addr;

    // Tokens mapping table
    mapping(uint256 => address) private L2ToL1TokenAddr;
    mapping(address => uint256) private L1ToL2TokenAddr;

    // bytes32 == hash(txRootId, leafId) (not using right now)
    mapping(bytes32 => bool) public isWithdrawn;

    // 領錢表 [ L1Addr => L1TokenAddr => balance ]
    mapping(address => mapping(address => uint256))
        public pendingWithdrawBalance;

    // A value for assign L2Addr for new user
    uint256 public idCounter = 3;

    // New users' data
    struct Receipt {
        uint256 L2Addr;
        uint256 amount;
    }

    // One slot have eigth transaction
    struct TxSlot {
        Tx[8] txs;
    }

    // One Tx have these infomation
    struct Tx {
        uint8 TokenLeafIdFrom;
        uint8 TokenLeafIdTo;
        uint16 txL2TokenAddr;
        uint16 txAmount;
        uint16 txL2AddrFrom;
        uint16 txL2AddrTo;
    }

    // Proof (struct)
    struct ZKP {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    // Register Array (New user only)
    Receipt[] public regArray;

    // Deposit Array (Members only)
    Receipt[] public depArray;

    // L2 => L2TokenAddr => unpackedBalance
    mapping(uint256 => mapping(uint256 => uint256))
        public pendingDepositBalance;

    // Check Balance before deposit
    modifier checkBalance(address L1TokenAddr, uint256 amount) {
        if (IERC20(L1TokenAddr).balanceOf(msg.sender) < amount) {
            revert Insufficient_Account_Balance();
        }
        _;
    }

    // Check withdrawTable before withdraw
    modifier checkPendingWithdrawBalance(address L1TokenAddr, uint256 amount) {
        if (pendingWithdrawBalance[msg.sender][L1TokenAddr] < amount) {
            revert Insufficient_Account_Balance();
        }
        _;
    }

    constructor(address tx_verifierAddress, address reg_verifierAddress) {
        txVerifier = Tx_Verifier(tx_verifierAddress);
        regVerifier = Reg_Verifier(reg_verifierAddress);

        // 0 for invalid token
        // [ L1 -> L2 Token ]
        // BTC
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 1;
        // USDT
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 2;
        // USDC
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 3;
        // DAI
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 4;
        // WETH
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 5;

        // [ L2 -> L1 Token ]
        // BTC
        L2ToL1TokenAddr[1] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // USDT
        L2ToL1TokenAddr[2] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // USDC
        L2ToL1TokenAddr[3] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // DAI
        L2ToL1TokenAddr[4] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // WETH
        L2ToL1TokenAddr[5] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }

    function deposit(address L1TokenAddr, uint256 amount)
        external
        checkBalance(L1TokenAddr, amount)
    {
        // check new user or not
        if (L1ToL2Addr[msg.sender] == 0) {
            // User transfer specific L1Token to Rolluper.sol
            bool result = IERC20(L1TokenAddr).transfer(address(this), amount);
            if (result) revert ERC20_Transfer_failed();

            // Update mapping table (L2 => L1)
            L2ToL1Addr[idCounter] = msg.sender;

            // Update mapping table (L1 => L2)
            L1ToL2Addr[msg.sender] = idCounter;

            // update unpackedBalance mapping
            pendingDepositBalance[idCounter][
                L1ToL2TokenAddr[L1TokenAddr]
            ] += amount;

            // Emit an event (newUserEnrolled)
            emit newUserEnrolled(idCounter, msg.sender, amount);

            idCounter++;
        } else {
            // User transfer specific L1Token to Rolluper.sol
            bool result = IERC20(L1TokenAddr).transfer(address(this), amount);
            if (result) revert ERC20_Transfer_failed();

            // Update member's amount depArray, waiting for rollup
            pendingDepositBalance[idCounter][
                L1ToL2TokenAddr[L1TokenAddr]
            ] += amount;

            // Emit an event (memberDeposit)
            emit memberDeposit(L1ToL2Addr[msg.sender], amount);
        }
    }

    // Call by user
    function withdraw(address L1TokenAddr, uint256 amount)
        public
        checkPendingWithdrawBalance(L1TokenAddr, amount)
    {
        pendingWithdrawBalance[msg.sender][L1TokenAddr] -= amount;

        bool result = IERC20(L1TokenAddr).transfer(msg.sender, amount);
    }

    function Testing() public {
        // withdrawTable[msg.sender] += 20 ether;
    }

    function outer(
        ZKP memory txZKP,
        ZKP memory regZKP,
        TxSlot[] memory txSlots,
        uint256 newTxState,
        uint256 newRegState
    ) public onlyOwner {
        uint256[] memory txInput;
        uint256[] memory regInput;
        uint256 c = 2; // A counter for insert value to array

        txInput[0] = state.stateRoot;
        txInput[1] = newTxState;

        for (uint256 i = 0; i < txSlots.length; ++i) {
            for (uint256 j = 0; j < 8; ++j) {
                if (txZKP.a[0] == 0) {
                    // Only do reg
                } else if (regZKP.a[0] == 0) {
                    if (txSlots[i].txs[j].TokenLeafIdFrom == MINT_ACC) {
                        // 檢查pendingDepositBalance是否有這一筆匯款紀錄
                        checkValidateDeposit(
                            txSlots[i].txs[j].TokenLeafIdTo,
                            txSlots[i].txs[j].txL2TokenAddr,
                            txSlots[i].txs[j].txAmount
                        );

                        txInput[c++] = txSlots[i].txs[j].TokenLeafIdFrom;
                        txInput[c++] = txSlots[i].txs[j].TokenLeafIdTo;
                        txInput[c++] = txSlots[i].txs[j].txL2TokenAddr;
                        txInput[c++] = txSlots[i].txs[j].txAmount;
                        txInput[c++] = txSlots[i].txs[j].txL2AddrFrom;
                        txInput[c++] = txSlots[i].txs[j].txL2AddrTo;
                    } else if (txSlots[i].txs[j].TokenLeafIdTo == BURN_ACC) {
                        // Not check anything
                        txInput[c++] = txSlots[i].txs[j].TokenLeafIdFrom;
                        txInput[c++] = txSlots[i].txs[j].TokenLeafIdTo;
                        txInput[c++] = txSlots[i].txs[j].txL2TokenAddr;
                        txInput[c++] = txSlots[i].txs[j].txAmount;
                        txInput[c++] = txSlots[i].txs[j].txL2AddrFrom;
                        txInput[c++] = txSlots[i].txs[j].txL2AddrTo;
                    } else {
                        // Normal tx
                        txInput[c++] = txSlots[i].txs[j].TokenLeafIdFrom;
                        txInput[c++] = txSlots[i].txs[j].TokenLeafIdTo;
                        txInput[c++] = txSlots[i].txs[j].txL2TokenAddr;
                        txInput[c++] = txSlots[i].txs[j].txAmount;
                        txInput[c++] = txSlots[i].txs[j].txL2AddrFrom;
                        txInput[c++] = txSlots[i].txs[j].txL2AddrTo;
                    }
                } else {
                    // do both
                }

                // 1. Get Tx Input
                // txInput.push(...)
                // 2. Get Register Input
                // regInput.push(...)
            }
        }

        // bool regRes = regVerifier.verifyProof(regZKP.a, regZKP.b, regZKP.c, regInput);
        // require(regRes, "regVerifier fail");

        bool txRes = txVerifier.verifyProof(txZKP.a, txZKP.b, txZKP.c, txInput);
        require(txRes, "txVerifier fail");

        // update regArray, stateRoot, txRoot, depArray, withdrawTable
    }

    function _checkOwner() internal view virtual {
        if (state.updateTime <= block.number + 11520) {
            if (owner() != _msgSender()) revert Error_OnlyOwner();
        } else {
            // Then, everyone can withdraw by Themselves
        }
    }

    function getContractBalance(address _token)
        public
        view
        onlyOwner
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function checkValidateDeposit(
        uint8 TokenLeafIdTo,
        uint16 txL2TokenAddr,
        uint16 txAmount
    ) internal view {
        // 如果 pendingDepositBalance 裡面紀錄的餘額小於 txAmount, 執行 revert
        // if (pendingDepositBalance[TokenLeafIdTo][txL2TokenAddr] < txAmount) {
        //     revert();
        // }
    }

    fallback() external payable {
        revert();
    }
}

// - Future works:
//  1. 取消deposit function
//  2. 60個calldata input vs 1個storage revise
//  3. 最低deposit金額
//                L2   => balance
//  4. mapping(uint256 => uint256) unpackedBalance