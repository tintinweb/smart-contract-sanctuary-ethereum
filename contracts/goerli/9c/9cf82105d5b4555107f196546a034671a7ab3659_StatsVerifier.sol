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
pragma solidity ^0.8.13;
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
contract StatsVerifier {
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
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing2.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing2.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing2.G2Point(
            [21202840743514253315933271572249505425454722607656947449290521984700388767620,
             13482396594239990267307324287211745348633431480462499851730009766383282370341],
            [3901697140919890325635705403066884241756851120918152428998624244667241409886,
             5844052804296807340691086574680613213355012646846186119090274672950962159475]
        );
        vk.IC = new Pairing2.G1Point[](32);
        
        vk.IC[0] = Pairing2.G1Point( 
            4824097385034124576426229567791807706070762077745790741439891080049276906977,
            8906501212922373993246790669289175821742771925467810834241402132711872641959
        );                                      
        
        vk.IC[1] = Pairing2.G1Point( 
            1688554140148414207531946058159561306869867950473636756758378530784409232850,
            16272743001726012192627523122534964089699339069260441762885880297652303116579
        );                                      
        
        vk.IC[2] = Pairing2.G1Point( 
            21115701265905377737951421486224183704578075352599766472456112820678184931607,
            6111625150883125208328807389679547243494774837394725485875193319204943897932
        );                                      
        
        vk.IC[3] = Pairing2.G1Point( 
            19978490366764774816174741298875354308820455107568957720774866306102980426239,
            10810562905347231728411602550763224918417660513104135268125615085628874005211
        );                                      
        
        vk.IC[4] = Pairing2.G1Point( 
            21192129521851816727960912394254871021528048289790873427992408578907039803977,
            20974759307692295500989392099920465159429006835317688535268358484857746872901
        );                                      
        
        vk.IC[5] = Pairing2.G1Point( 
            21522423808948962833179657535552904251648926681757042862293502844925507041153,
            3345246915513779404687639210920897062272562680646442884312711923154763823308
        );                                      
        
        vk.IC[6] = Pairing2.G1Point( 
            18192190647178722376593892718254805270094328737484371082294439035495345644349,
            10460490688709244996047949104868263383882135417067600117388978521286831569482
        );                                      
        
        vk.IC[7] = Pairing2.G1Point( 
            4743853020240984589719043461621464963986406515749477129645477914799535674147,
            16556854087536624459029916363764131836912225180685165352866113131303204727705
        );                                      
        
        vk.IC[8] = Pairing2.G1Point( 
            19592732072787242993390059027330351182748003477480626569436415166066721080504,
            1764897457266232511215651949734982008465067454087933159625192912820819582339
        );                                      
        
        vk.IC[9] = Pairing2.G1Point( 
            4672168778917917719180331877964072094548070428535822976350657841322455220368,
            1943712250817981896405729322002249095573106377078658401552481263589920376150
        );                                      
        
        vk.IC[10] = Pairing2.G1Point( 
            16835652544544231609043488979694397413377705899676365634615724756945567158583,
            3959254858119258398003418284591328007227066046870887297855437028238368583710
        );                                      
        
        vk.IC[11] = Pairing2.G1Point( 
            11453675543597003168861390351523035369122218905963826144672287715755061463689,
            12542230406051839943215610824238078500353846731637894078398219350035991709618
        );                                      
        
        vk.IC[12] = Pairing2.G1Point( 
            9471652200187838842102558751796889680114888304668946654438225175077968677219,
            4986805264915748914601280537284238484796083592123581719463240140870671466120
        );                                      
        
        vk.IC[13] = Pairing2.G1Point( 
            14590211984082491259113090548456874738794634948326085199925337938910472715948,
            13354297900276531062415014788925844145436723254458954361462051500541572704849
        );                                      
        
        vk.IC[14] = Pairing2.G1Point( 
            19850641374752491415753330062488354332934820719241446450703437538206412961541,
            1299716949796839596427329659845609731895014818467448650222195579288853639236
        );                                      
        
        vk.IC[15] = Pairing2.G1Point( 
            4047710651084358182206041178379049451348328396098618788827822756094035812093,
            12512192345544048919355432199903352221357715838986571279158774494573970680421
        );                                      
        
        vk.IC[16] = Pairing2.G1Point( 
            10976564305103794036291254683061620242910965097451178405120470605385277149545,
            14438513798597123256348591592468135309860634645435552360048508648899553095770
        );                                      
        
        vk.IC[17] = Pairing2.G1Point( 
            21026056226914007745773892945904818590418321426695060826311327857738121345740,
            1207748265095954553517710719437637888236177427750223091635380665496152645922
        );                                      
        
        vk.IC[18] = Pairing2.G1Point( 
            5335972904360619966977236729013272085930982429049868216316350988364509818842,
            18361296610271552801455851287629160344482167228809694454115770426303182020739
        );                                      
        
        vk.IC[19] = Pairing2.G1Point( 
            17288542892797138452088494839951073954504748003100249869271962871532940864154,
            11532991406555189800414477183720888220884177303182202174860478928342363545682
        );                                      
        
        vk.IC[20] = Pairing2.G1Point( 
            16656899985844638635662532012427576794985273090521741124429436524111249432541,
            7062357802303730393473464597586544010800424760397667428897317441480921676464
        );                                      
        
        vk.IC[21] = Pairing2.G1Point( 
            7859057772268849684713194939078015410216075063094240303112110536164042687116,
            14391100026310923148751619368130347252149679821868029778289107188986421402679
        );                                      
        
        vk.IC[22] = Pairing2.G1Point( 
            21669717279350763220856210199344767501850716703240304676040061980136430008883,
            18141662175367137375822138290342436245383689821971380736148418601021841105433
        );                                      
        
        vk.IC[23] = Pairing2.G1Point( 
            5147886789564016786648929013490815488721070009805246315594775573322027987871,
            19744367773021866193988053683936232737556344064292084985111294690171568487935
        );                                      
        
        vk.IC[24] = Pairing2.G1Point( 
            18836354201610472338855671297077832533157105757202590750600400384755493873543,
            15539648420730476509165962530921526257882644450128507778299744116849520771890
        );                                      
        
        vk.IC[25] = Pairing2.G1Point( 
            21299149283355114916990007536910701509549777715340853583353046064622964836520,
            9550213359635958847017550917510996669688458576232560332632642390040211867263
        );                                      
        
        vk.IC[26] = Pairing2.G1Point( 
            15675340952720637657650554159681273058636382008766652621184227800846767295788,
            9283747118614067112207525492306586951308009403736991713727876780939796851681
        );                                      
        
        vk.IC[27] = Pairing2.G1Point( 
            21796576014332826912824351309852689834376038595587259418758789576619264988494,
            18606426584461858222741662031091802216538332552940059289989897795803712731493
        );                                      
        
        vk.IC[28] = Pairing2.G1Point( 
            346194942545022307094433460120165482948410055600410174259351328960247389314,
            20990256153332551354738235758108185194860784944936710540730975761119526870035
        );                                      
        
        vk.IC[29] = Pairing2.G1Point( 
            20387859242663777303204410152605153526271515712419666160679072839981730550264,
            1016245967509344336029767264664243797219481176976428972111922185451503580095
        );                                      
        
        vk.IC[30] = Pairing2.G1Point( 
            387124767353954742041913371855946493496218534749506324001056192281882129069,
            10321974597725459940745933853836992635692890870719362973734877069619014131296
        );                                      
        
        vk.IC[31] = Pairing2.G1Point( 
            126418064824618766674502603836279692794544897695228285722993675384275802158,
            14748388087378171507324646580083818016542168662344032857703587670513567335524
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
            uint[31] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing2.G1Point(a[0], a[1]);
        proof.B = Pairing2.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing2.G1Point(c[0], c[1]);
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