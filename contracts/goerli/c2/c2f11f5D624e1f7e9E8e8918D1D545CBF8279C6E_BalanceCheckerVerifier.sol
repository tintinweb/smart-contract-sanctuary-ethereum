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
pragma solidity ^0.8.14;
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
contract BalanceCheckerVerifier {
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
            [12599857379517512478445603412764121041984228075771497593287716170335433683702,
             7912208710313447447762395792098481825752520616755888860068004689933335666613],
            [11502426145685875357967720478366491326865907869902181704031346886834786027007,
             21679208693936337484429571887537508926366191105267550375038502782696042114705]
        );
        vk.IC = new Pairing.G1Point[](47);
        
        vk.IC[0] = Pairing.G1Point( 
            13876776013036260863361900549292902466190949272610145625726971238233946605993,
            2216878607621640593293326431334033091412856565172322867945420077039072787395
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            6210821438438502603705486849330637264491487610739390159317725617489922744166,
            14883630429746977869752910634045277158915600865707942366556228265518618895213
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            46518491776221048682074200371904749624974697415919506847885706945158435798,
            11411448548245211401928694008445875286047149733107541367317228641451856890043
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            15263513624399888961252232642681020964644754080753498572329719297776585594446,
            167853071444546440832540812704084927315984341724976905256490500804178635004
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            16984998096914211397806599201828589571986041341881946208630291104477377039614,
            21885706682458985597710896158913918128610143103580664796550165471160785842806
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            2472663376883480601651200105084110628820675224429041916831576279662925152409,
            4252061343275866762013515276864844806234867667609386214905916168426520878768
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            8091579206441854704896933837584651700474564161646830491461263473533794238637,
            19659534030056723201329195372969368769663771668455548359067846784349120252186
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            10463812443872950037212679238492508006082859257373713909239539238054747546656,
            19124022590518597523952218990211195692442506060951337438220652148256558356752
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            12146529469042109221683101534559110062869138936306013831820170454743120999629,
            20917905484205824847039735741203663898876166522860373575843565629014878527306
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            3306873913323685861948314029731460024945358485926233797476834279652264948919,
            8330487619935783089994248047400405640809350528177485260822288318317204552530
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            16141970679042566299300792422719315262067183031684212859973108391688888089046,
            8915801092633476374647052651858973432848410078359079632837595052634258211654
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            14179589689534341073867192119588685211589285886624239812137800096881910910288,
            20100690231774780099042584243541558119262389423334877966973066574600138355551
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            6184367789150117823753505976614942498752132530153380228679469001832626552953,
            18985882791333685978402011449967141103105110311337611753670013630387982812775
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            21362532537264751384405741412686645399451845225086263925855799354101633526976,
            15144864410086269902518005723294089360025091257868333580723685481722325980864
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            17259627840501593643729359796818133606571395204465810051350721462177551179679,
            21616139380229007674746535860748278882988922382811530598500858987433907076176
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            9339351411115903911589749048383962975202662091388861319970205206364963588691,
            2196181425233025705455705014504055167704776418693475606042823482406092619764
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            5878201681852960959007026283174910235698595489899995608893193406008926650388,
            7994117838670687850645606311012680401611946117398235604537027185512358297141
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            6355858704072651100171706737588700967849728559162404797777415728029792292899,
            10025577871398424641542017270173284364123797319073257213325397584449339995453
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            15619330720953539762608527549089526311106170438272577723504648215993953850180,
            375608567443708957978895223993617244112156024603667964552818072130544321807
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            18456817234458789283979196841495808050676437294835031771414249669782876053667,
            7326176195670232311971235102559175145173284392957400198893902140449660822372
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            19515208888350673772460898169236840091628378700983673740290134331468853079075,
            2144194282294413568156804337553972586561440234078264374700710335911542361957
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            17911569313495242075533768600966485414689465697796155631610313542571833507418,
            18099287184468446764010472740942566262221863667557855323089076208340395980575
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            5464320192052636490139650886591976078822654481535113140041315038913363189220,
            16724256735194221926229005270872039946939847521047092772303589484169866573768
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            13759899565663560718276797707464079087463566689363558892112325573425078297824,
            21316862742646262212842478784902592454143672744272216842834576248802346290815
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            6516102211667813332673551902940461356362409635062508660708287055652557993034,
            21793156624890684615564769631647226191420184922157695992456572201004217931667
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            21089295346702289629749164199753235858175051519699992289164593621431434912739,
            19132044676111090156559625045274762547684779690085834738718683399550844359038
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            15830874755260791989888034310492284950345308571133039130166256279347111156041,
            16952781140115926591846254148112877449544096107173845684732022490663680318996
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            19747822400654750157656901111622738229152069388590328216706156688111346979179,
            21861965877600506659728322638714807419226373152682753558465149643064580878877
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            2156966389072568661729302905161729384637748328729405279374861613572562311332,
            4516786033176073405318250367730652786563537564116867344715855153060069452173
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            16730983406284556046727565281441312205040274473093650081521059686511749948905,
            16579066711625405638340743592486757248488097157696395772295814789619261144985
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            11882144244312763180254414889416300816399339448929017246819898553386197872789,
            16893972750646225518458980447996827037291634221539160379043581443346427015236
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            18935968616787178236744694854987263252730732007922192537740069056704978273211,
            21165479882067015447914880413626941715933486261414158965747468087726664388539
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            16595979050071838509918062493505062659164688930961858893100720335308364710957,
            2813966914233710174512803653155106145417631609078820075283038315987429111122
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            1138282936771101521273252796399150015662839336984585697666359569304403800939,
            3027741130943600764436223689823902970573627672380757202358126473850131943967
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            4598213997968074583812406650298405627964353026955940000080783969606657157048,
            9182847381865409988323652278551884949436537754898210182416189434425648772286
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            20540755014367079292208250016689506312979728922984280695496124185258473798889,
            20135072315018046086071200119032852224344782261781972271970879806791222221901
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            11076389810730053741624079988204365913287732524353986232769885593420844792773,
            17365535210992803498823580299738905290687753977392109746530763976891657552821
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            14337393806136107719306627536633586260988812175423922269673591960750426655166,
            18724036408494515021270604783329203620137611212234560957986667116126865371283
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            13554573564848819291968952995575567401323394398226352263301409791174558900382,
            12287111486319564752381746749454280480792340819237401730619106422389267476273
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            17789564178307323061456985017460432758679133200836456680256005838252037496074,
            9521646214808458054426555906448734689949054361219174646312180624477652825237
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            16207651441904358489364175473640042929220905350198573856873469111524965036313,
            21675517505498794181254515514286243606911048156156395399308757608863657016591
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            21787629884399998683701748456982649545188847711168097499385327907816278395082,
            12172909231905653808738407164731680260580242001696467792529267005108231959948
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            14394447777654046227540115938968165855458706371910610558444905131428768151726,
            11256572784277112502371950073914507323814627166814785304060037012852846784685
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            8141961117253522455800083416078775769352024869957026647080249641224293934231,
            20173404236698380738545365059136459775463081375516623696903415675392114402897
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            13995081212959907348334068725436466547509118819993484762398111535732537964541,
            14573258791477080401047523850203693192794961333579728456308965727917974232475
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            1400843567111567736844092466884006082040216025155850736142605857805069096710,
            14033390247395545811290763102632136723389193321568363870528567046035437012279
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            3763063645225343381811405060885102796752170098076380963753108079562162838842,
            8862470095230709985949172201422888311737458619519305837908682624344967626974
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
            uint[46] memory input
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