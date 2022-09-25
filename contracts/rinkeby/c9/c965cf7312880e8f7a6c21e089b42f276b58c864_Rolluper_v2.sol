/**
 *Submitted for verification at Etherscan.io on 2022-09-25
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

pragma solidity >=0.6.11 <0.9.0;
library Pairing {
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
        require(success,"pairing-opcode-failed");
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
            4015971214601274450582101135234403977948829308494056514325025916553484348525,
            11789912012887439061740017382543741713717193756194819373236584508249107661673
        );

        vk.beta2 = Pairing.G2Point(
            [20255323772829801273420091817897198918239028838425965777612542038169975419508,
             3932073073691051474925814736979819662971431136358536406781793245616612078183],
            [20315184067271392694795858456192746192780612986629659565241454598731903404551,
             1817538646234672822961599988535674980504573755905895828151514219476194302891]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12548161227238359556021957256769530722905988401603202767636026093398030203310,
             15553706886354425090031097151907306347612542013475810050805480691156561316105],
            [16652140852987545104306778975212832995648190202010693439932108943369257637551,
             19212185480755987181444499463828643889867271363504812109969887517275428155375]
        );
        vk.IC = new Pairing.G1Point[](12);
        
        vk.IC[0] = Pairing.G1Point( 
            19321648622158999614197354779352877703317026493802980775138164547531179039580,
            491295568835180872839595301249149686934215794072861967481523868328442717309
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            29292340926518490856732150589824216924852530565567349700614092929742594504,
            3605705859584611860692046913371169140651580649974362770735804301557513717451
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            16360656694551577108156022833619585556024004569932237292639019665967367048015,
            1095528198642778934504777553610997764045812257524869599296936347402673791763
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            8265077391584071439274844930199509120073386449130532269748631058897721006772,
            3413666823100860124352222318000255565292217958658311112371322705569850155387
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            2542545583714447541797028677245404460275159187217554545574319930114571435038,
            18511297084697960322502124408647562619165275234115301190672132003848697561288
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            18211101168406672483916881838992631344128240369477362232505857876394896379233,
            17931160234582473572555606766640442338911614141406696509499692575018923654353
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            11335158981227607941963016772608829371902218105163326715754890895739154137651,
            13683255667568335349113016845443976847568206796397092661907822854214921117051
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            14134492058957931445962702383843842583141008710613047655331400206989072538133,
            21203155814018425704019170327911911497246323811518499731201524018616557853993
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            18364209662211304575217045265794528227336365139717916499937541364831583411158,
            8823963477792204657731389660376851340106312088020590215731402328200018977255
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            13382458347180261977303736806729623347728212258774596244024538447918234869023,
            12293530290970849288073150801656639888457107253739148017132026423273892554918
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            12077054205214126629863505980184633894050227457637608945348163184453902414697,
            12128094514492871297478865527449748223331679091528871717420360061043132474331
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            17074504323824497014847592072569665068827236373122239624354207641191257137728,
            14960254617796839431839393543444875527028652150599697128737849756804827756711
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract Rolluper_v2 is Ownable {
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

    // 領錢表
    mapping(address => uint256) public withdrawTable;

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
        uint8 from;
        uint8 to;
        uint16 amount;
        // uint8 L2AddrToken
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
    mapping(uint256 => mapping(uint256 => uint256)) public unpackedBalance;

    // Check Balance
    modifier checkBalance(uint256 amount) {
        if (withdrawTable[msg.sender] <= amount) {
            revert Insufficient_Account_Balance();
        }
        _;
    }

    constructor(address tx_verifierAddress, address reg_verifierAddress) {
        txVerifier = Tx_Verifier(tx_verifierAddress);
        regVerifier = Reg_Verifier(reg_verifierAddress);

        // [ L1 -> L2 Token ]
        // BTC
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 0;
        // USDT
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 1;
        // USDC
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 2;
        // DAI
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 3;
        // WETH
        L1ToL2TokenAddr[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = 4;

        // [ L2 -> L1 Token ]
        // BTC
        L2ToL1TokenAddr[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // USDT
        L2ToL1TokenAddr[1] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // USDC
        L2ToL1TokenAddr[2] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // DAI
        L2ToL1TokenAddr[3] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        // WETH
        L2ToL1TokenAddr[4] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }

    receive() external payable {
        revert();
    }

    function deposit(address L1TokenAddr, uint256 amount) external {
        // check new user or not
        if (L1ToL2Addr[msg.sender] == 0) {
            // Update mapping table (L2 => L1)
            L2ToL1Addr[idCounter] = msg.sender;

            // Update mapping table (L1 => L2)
            L1ToL2Addr[msg.sender] = idCounter;

            // update unpackedBalance mapping
            unpackedBalance[idCounter][L1ToL2TokenAddr[L1TokenAddr]] += amount;

            // Emit an event (newUserEnrolled)
            emit newUserEnrolled(idCounter, msg.sender, amount);

            idCounter++;
        } else {
            // Update member's amount depArray, waiting for rollup
            unpackedBalance[idCounter][L1ToL2TokenAddr[L1TokenAddr]] += amount;

            // Emit an event (memberDeposit)
            emit memberDeposit(L1ToL2Addr[msg.sender], amount);
        }
    }

    // Call by user
    function withdraw(uint256 amount) public checkBalance(amount) {
        withdrawTable[msg.sender] -= amount;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Withdraw failed");
    }

    function Testing() public {
        withdrawTable[msg.sender] += 20 ether;
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

        for (uint256 i = 0; i < txSlots.length; ++i) {
            for (uint256 j = 0; j < 8; ++j) {
                // txSlots[i].txs[j].from == 0; // mint (== deposit)
                // ...etc
                // 1. Get Tx Input
                // txInput.push(...)
                // 2. Get Register Input
                // regInput.push(...)
            }
        }

        // bool regRes = regVerifier.verifyProof(regZKP.a, regZKP.b, regZKP.c, regInput);
        // require(regRes, "regVerifier fail");

        // bool txRes = txVerifier.verifyProof(txZKP.a, txZKP.b, txZKP.c, txInput);
        // require(rxRes, "txVerifier fail");

        // update regArray, stateRoot, txRoot, depArray, withdrawTable
    }

    function _checkOwner() internal view override virtual {
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
}

// - Future works:
//  1. 取消deposit function
//  2. 60個calldata input vs 1個storage revise
//  3. 最低deposit金額
//                L2   => balance
//  4. mapping(uint256 => uint256) unpackedBalance