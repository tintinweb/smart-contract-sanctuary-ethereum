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
            [10788543609542667868119335663166833533827038804393898508379664729554921054322,
             3470335554053587399690566036871662413294927776999294150244186584768205927917],
            [1080576264399443943967352941529346494795059075416648064414453915772124939033,
             9557103733131487055176522820401770090743782846128108345656419298646887993520]
        );
        vk.IC = new Pairing.G1Point[](23);
        
        vk.IC[0] = Pairing.G1Point( 
            831046074840120129112705391296950334959180927944991517226441490733168148683,
            722703922245253355642023669039686809182052098182991517754621954621868350195
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            921428393646220767212455227489793232872623920428934659581198272481138356354,
            9140947142624722360531324622240125088800114901927077054908891926772353389746
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            14073087109509028885803616010956276400312812312616435399817641912678306358216,
            1019015430283296660809173652264839946342389006366779343422910852228223723031
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            19534133466736918118763643159338367077535984917995318379761037225320000988363,
            7754865531710103515398743346271086237319884600914560166242875498214279020767
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            1766857253915084977294409709515821741219671362552409096240910576587778685361,
            4866917946017992320762944047929251494875894712922134795736469186927433557212
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            12965990607817231692613208072818167739362596688318338678486808697236813550883,
            17429759553331255224615030628365597022011748228424156337132847611022716905138
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            14240438884386329702712252677976307902252659593346977315741732620706002148868,
            5717736834636300909370961575837417673619700264003388757996967812937495879624
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            20768679571601844916020753955417958361986628536738317331298979867157284913662,
            4006718078142086035405276558375651377597142776172050154822277598363387912064
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            18024154326592217870627920221438681525974722484007380645503878938428077592328,
            2168845799986298344445292483533311636645425134819819290746808047293977835659
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            14737162511241541633896855086408604496810261753314311965819109829159333586339,
            4820635658924921589570079806054847196496124707408945288055537850732043310310
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            7863199283061034744960545496518781782829242175071720206282919831357080486543,
            16705535384295932142810507446975455499285987712325859897658371099714658639328
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            15476004148280750160784202774633820881424797663291375341201306543605162554693,
            6702117795176065956497282846266626547039856683728257622017738057183917304030
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            1285852302347941635397645053327841846656670837354609858518595530627867502408,
            11829179531988679881767361087904276253964759462719226316925619530012629166384
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            14190310730486464236034096315896549736721801818080272183418513290653089495981,
            10472301685196002077196699512325579737985629402133209265055796732506315480506
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            98427672700722236178871619711180883545922177757157111606424950433319195900,
            18484026097287515641640337139106982283076539878124928007499193631010775430455
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            20037656445231700246379759195111652941825273207633997705592318298347060666898,
            15566026307039568464719220801231826771207350805004814859503461562013635071797
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            2613714552868909392156341264329649247592797067595609759241254389218369720976,
            4815153518412518130494551329876470264895591029265902659586777855531299819998
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            1839747716555059984002948008907838734400016564991029824149390358694864746874,
            19977833626681428598131296965111672061187384748646163459488142410857518531865
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            13903356048578221233650085180513276492576835493075050857839398321807614929172,
            18346482273637098239582513921755226714245390554690724942734248777970519213248
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            18006946124812375156821283423722216835461879425172743231018211943571618026848,
            12121962097714191035731894515186832714268332174503529367756531352857804082236
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            17726527457806320525798037437348325309727592599981596461494832423427479294069,
            3300943823614574167700835712402424120582517432910460443469544992804628862842
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            14275417243453968303526084421790711869013699858140361129202493517069427233645,
            14661595785436601920883010853428258089869524586031510229078411948124801269248
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            11965609222616417919649021445926697106486626914005857510553276130136574310679,
            21732826736281677056114385623184604529210937275884333226663054536643222757856
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