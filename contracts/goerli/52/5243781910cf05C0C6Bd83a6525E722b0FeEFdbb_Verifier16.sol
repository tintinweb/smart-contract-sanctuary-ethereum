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
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.11;
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
contract Verifier16 {
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
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [6924471648396524093935173050478738324048249457562824249640360531501093071680,
             21596556335306877074129619579169203367433417076970899446672814915178958412843],
            [4647562278500425078232343655594279217013970392796996701108631464769989680576,
             16197520839592670708701804801683674566924553744160287880461248131771391285039]
        );
        vk.IC = new Pairing.G1Point[](23);
        
        vk.IC[0] = Pairing.G1Point( 
            13939112916394032417718727047549177542470632403627277046187499305779267483280,
            4399715964200888303120075486612184252485151405773319462457237166002409850381
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            98860812902084802315610696442240287529279563739336503898644643857260900341,
            10953368384496586656275334954975207000533381179621110506673617106634755755269
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            9734544369230971642317258945816551498513811563873554031002121542521950853181,
            20965216897325969446541320349412643563593131446830585657696158782789446954706
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            20392867369793184080732561408902851672335833914162004804132435554643484388910,
            230221794829351868756005448119274031584535155887333551010649818171844700678
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            7758914704198172818862044866196611550575079658948823314175393521553841069667,
            20893980483531145400442420219272506461028215986783745374913297718368230434446
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            21430823075028231592573805459407347035673238367511332916863487946239430472704,
            13966468730778069675658958782893507011158590532858377506913904702352093171127
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            11728378436413310822724757492108096985060044252702893511280801789443044208779,
            3788982394829819059766537728225184563122328307805271950409546260879411359566
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            3340927841323476488172451429876465655099293619477171731699543484496184926081,
            9385147590271727736500508875020113314596071543277322475478392124996691520579
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            19414246427502919848827463113172680746096645574152825308208310447948171591035,
            17440243899748488779720773730311513358620733718424795349228562274637419009970
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            1976538232841319737241251548517417134455055069621918381587078149535739338519,
            3005105457616935223397151597440068121487272792172018289555815187664213014489
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            537641130129138051650938785376094157056017731151457381921945131570467620968,
            16612061596801653878023545451322478233987998200637125193904371495262863315557
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            12424466020699488549432788693902955607985626078786981892661818185500151847755,
            238284945778366888858334575963984330118089853046767276032203493002183300121
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            18336023376562636512204746469389839048888211653954195096224041896327415901313,
            19847688898215494091715693752654703007156871164589161731552903246743614340499
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            1337813151205053813801527452865500981055704577391591374704710558580034282368,
            7273806172307776571125589109456723228775382752223778296489630810455524768092
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            14274319931352337449146343664102467616992862964287669547857117275079148994689,
            21796093498122736220117601116125298570601668357590598638349428362613154421081
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            3060159126193720202170891402228552351788180983614884056836603241609022090397,
            7125241868148326473773356389737006184186155556491816019764878560267256772552
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            2161586435268485587734828149416242207685716602961590262559104187978021761934,
            4911350234233450151464878231564636701489068237195395436940489854584382087940
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            21817969986040551729599948882052163291539723506254906970028607260412166363500,
            12992374438680217606639159920729910515404016744959970274858736578308939220102
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            18662327461440599869886954638277897891306939064122472507832360691542730831382,
            19775347252181506234650654638251517654550351345749356464814075752191557185638
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            12985790071912781559522523503244113092310093658048609030461158462384320552981,
            11170203476103574302539675724892340910822248616352960696379278440373073671465
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            6055200319597259034382840591155948395444628456519314885191515996358186450169,
            4815285695029270813804658934236012920279428100449710487003790531735322882422
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            13167131297758093818295137482942999676995084776201096325791836369193524099084,
            3492268340889091376574233278672139831251220103550247756206783349400741610962
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            8602488513013001864842116251615622873594921964551173767199380068756770419151,
            19249643339011065878594922939982487660478291492224684713756323096407622232236
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
            uint[22] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}