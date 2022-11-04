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
pragma solidity ^0.8.7;

library mNormal_Pairing {
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

contract mNormal_Verifier {
    using mNormal_Pairing for *;
    struct VerifyingKey {
        mNormal_Pairing.G1Point alfa1;
        mNormal_Pairing.G2Point beta2;
        mNormal_Pairing.G2Point gamma2;
        mNormal_Pairing.G2Point delta2;
        mNormal_Pairing.G1Point[] IC;
    }
    struct Proof {
        mNormal_Pairing.G1Point A;
        mNormal_Pairing.G2Point B;
        mNormal_Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = mNormal_Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = mNormal_Pairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = mNormal_Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = mNormal_Pairing.G2Point(
            [
                10209194495723733784665975767390890030780642807759038305400344053600710278714,
                2221348928858645609745795888965668359877708708059529116240219876687842833757
            ],
            [
                16392402606748926850428712026749804172123560603290167247653399902243272608034,
                18626407957217604716177771260285750852400787301400533970441594277567183328686
            ]
        );
        vk.IC = new mNormal_Pairing.G1Point[](51);

        vk.IC[0] = mNormal_Pairing.G1Point(
            5021752680132241101026423794825569158454512744251602880733944209401350806689,
            20457540896854040618689661355044881406230161607523306691833724634680421790955
        );

        vk.IC[1] = mNormal_Pairing.G1Point(
            21369334606353161575629315634332780322287672125747114602583364774607994660718,
            20829518985523107720707037473455248498878534343486982101910404884628923971124
        );

        vk.IC[2] = mNormal_Pairing.G1Point(
            3456254443595257184490728163674696541256837328636795505729481769372312790368,
            14198215241830837012815162264588502687271371736960550391232320558463842041311
        );

        vk.IC[3] = mNormal_Pairing.G1Point(
            6296319625775842432915869377889405772824648867843156372843239430197260790027,
            6056721960439352925954666529817663603120296921022440211143591526406893219424
        );

        vk.IC[4] = mNormal_Pairing.G1Point(
            8277925247511774338370087023673585109930660908732743668732496915122304428035,
            10511989261651827745298261962016601508825874290813151543644579237244092172156
        );

        vk.IC[5] = mNormal_Pairing.G1Point(
            11731784310496493242315979785967457155434971821202071145994113714988345711850,
            14186990839186670933359660620638849565417207455496577125230794706355005351857
        );

        vk.IC[6] = mNormal_Pairing.G1Point(
            11197497994690138959150893686737053062721712823253652301277398848049870824719,
            7061789708463691188108232793437404580471047957670822394265880791482357268082
        );

        vk.IC[7] = mNormal_Pairing.G1Point(
            5173466919954549976650958167046789673600785403023731269115978460477991904858,
            20098834095314438313873712555930792729121398027255181508182176014173685604060
        );

        vk.IC[8] = mNormal_Pairing.G1Point(
            20090539769890118249406238388391335805573569370284785606603888017519672210768,
            8685267475459089807602813516204974960925499059846179310446919222518594911797
        );

        vk.IC[9] = mNormal_Pairing.G1Point(
            14029126691467899797245865992743486886920114308990539601074567052102570813654,
            13372434026880097497287664676415388350204371336481822520026289293798065511052
        );

        vk.IC[10] = mNormal_Pairing.G1Point(
            15945513143867899699327940990404077637030063597911487694231148259221598310168,
            12036927278370701971826337063527692883018484620387621998751445568781785812824
        );

        vk.IC[11] = mNormal_Pairing.G1Point(
            10616436273908137206517825827016535991143753581354348872276455093178933335897,
            8338902031842247866587596395652470021617836504532475957945428532211402108208
        );

        vk.IC[12] = mNormal_Pairing.G1Point(
            1929436627476043192817288490631642196092104678635935348694793193455475127135,
            18150650377506496863087897898111903422796194225703437343849236020587558259967
        );

        vk.IC[13] = mNormal_Pairing.G1Point(
            6625521130504465028189133547899594544670455127238795491241653775176309306484,
            8535104089096350846411235641213650220901589857362592876521022187648913006700
        );

        vk.IC[14] = mNormal_Pairing.G1Point(
            21134700827960776432762612485035885829618338731126781179502936929205914986656,
            20651090080924454869331779930422947833617000338492879171955906129293646256130
        );

        vk.IC[15] = mNormal_Pairing.G1Point(
            6172688352884450741751885881294491314759828310233271249791140371319928320384,
            18817607942988076392979407632193108978293221735987074565296903711709323331437
        );

        vk.IC[16] = mNormal_Pairing.G1Point(
            11412708421126261584317242133616289863593781498451322787834708510310015005321,
            19360059901036636941402252879281728756444457256323088846008296031200280982789
        );

        vk.IC[17] = mNormal_Pairing.G1Point(
            13923339213034821547491671102251706103266405276941522319719490585923685740664,
            9296938680669643204309377354007992204981070356378904210338896483712363690057
        );

        vk.IC[18] = mNormal_Pairing.G1Point(
            5711771861098367513317198581002834837820819900662873684257416049149225303091,
            9808741201375496271246691074122009947716951213272605198243090612693391944283
        );

        vk.IC[19] = mNormal_Pairing.G1Point(
            21544324982740664609366913396295150265842747313609805698797831738726291643033,
            12701011044702970322545486714574494586091761554159955955481065258399561873626
        );

        vk.IC[20] = mNormal_Pairing.G1Point(
            20525907212821174017265628887059135983598631938822226303179396130049372365322,
            1875692109579369177871293560953045712899142545606216108800691437260551131793
        );

        vk.IC[21] = mNormal_Pairing.G1Point(
            181687615942017553719229462639722871918321372034737224061142233416637456090,
            221919787070961340441466883685525252963490805600431641305264482151972501419
        );

        vk.IC[22] = mNormal_Pairing.G1Point(
            21801999615974121522024014326548384477449769983398140238076736793021845736324,
            20897214958087921057481022638550415894663325020220019914893664802461680682171
        );

        vk.IC[23] = mNormal_Pairing.G1Point(
            3081559051716935058469234918151537218471459778961163735558096511975410789526,
            8119848033342780601130409795666651671048154541542566622880100134271703261408
        );

        vk.IC[24] = mNormal_Pairing.G1Point(
            17173996381116487158569849958651593733499218444442292483808856413743965854828,
            6739374734015987259567798845872906151671139040565486131191826278080255508561
        );

        vk.IC[25] = mNormal_Pairing.G1Point(
            21673726182737256645987597212231579253018717611171207928311893402332487120493,
            19234648482492649606029751213105145860412200525486513400548813013776420109007
        );

        vk.IC[26] = mNormal_Pairing.G1Point(
            304768459185463674666529419233738893457300725156055058205332176326040677431,
            18509576759853798894366867272555854691491238806441107315878590404550556053348
        );

        vk.IC[27] = mNormal_Pairing.G1Point(
            13459329436608550718691609886494110131542791579764185427298694756614915604571,
            2107594973200260735858096030600356090811044150235713267322805659133435266447
        );

        vk.IC[28] = mNormal_Pairing.G1Point(
            7323273798576631011624524758469845630105204301172255544126811168288386957395,
            6057707973636399084118825933110366831149932357949118605299600382673278393196
        );

        vk.IC[29] = mNormal_Pairing.G1Point(
            8271663772436259647271286187569624555561851835925327891300361344652882731562,
            18746008936340335587604135844237387448560935306138221411199394743177631612958
        );

        vk.IC[30] = mNormal_Pairing.G1Point(
            7589961364293275645162697080237307920483622897542389270598136760335687780650,
            1981182055761233380913406794476667773867102742887647249867756117453019904636
        );

        vk.IC[31] = mNormal_Pairing.G1Point(
            21502857002753212717374072352193400957950358737645970170078635266193511518129,
            9850083979335757828485407636777811086820841375762299218969925467187130028150
        );

        vk.IC[32] = mNormal_Pairing.G1Point(
            8413225278692685835470906533176714701358124492764060299450632746168658642223,
            19414424676093140197842915032320808685050195566863915985491739760931057656175
        );

        vk.IC[33] = mNormal_Pairing.G1Point(
            19775190775517800475043421171026802288202898760902210501626188170510143884017,
            13094983189787398033669868272238427027016401336357058060334567886495265555690
        );

        vk.IC[34] = mNormal_Pairing.G1Point(
            2091504830375339125903100748529029982078563585156081900275184686618633593568,
            10685002857553831153281073118114179192376646370961708080280776887381237863318
        );

        vk.IC[35] = mNormal_Pairing.G1Point(
            9840604849396096074043930622999181449649453009070350150041815672161402336427,
            13427662538912041065836079300667690345217811090880761328830638159867842609380
        );

        vk.IC[36] = mNormal_Pairing.G1Point(
            8130079377031815898650328616049318818312942837502560919330081669767964017792,
            12840087454843255278473003776815936527809069625888133157275360702731711643075
        );

        vk.IC[37] = mNormal_Pairing.G1Point(
            21542064419556894597791994299128644146701244674799039682732827676004295968788,
            6989023555557205731418957053584278001271292534940997407572047275525862378397
        );

        vk.IC[38] = mNormal_Pairing.G1Point(
            16972821073855796379307718514093607878942428164943955243238511767297161830674,
            1428925346100073414657711681274969844924671682376420569575884149432898802129
        );

        vk.IC[39] = mNormal_Pairing.G1Point(
            15933006160334051651648248537921526975134001460249743031199565130100440255844,
            10226042160892536076484290403594536021170962228155409787949732145223318003164
        );

        vk.IC[40] = mNormal_Pairing.G1Point(
            14258006549095269536413156659131818138191062989873068496072013971661562355157,
            12819262818529802971052002735101519508572383065321195481303437560847242074360
        );

        vk.IC[41] = mNormal_Pairing.G1Point(
            20307566927645696554435673773688514745902915521488306185583137767188138389296,
            2360430140626780829971928800551176890605113445873904768121505484818448237310
        );

        vk.IC[42] = mNormal_Pairing.G1Point(
            13479122558196885739699732657258332978681988896224873094917747640990602399331,
            13687428792760454199119182463788945733259499366021555575956733271646346504754
        );

        vk.IC[43] = mNormal_Pairing.G1Point(
            11130284044244195759959790163375923793802126667393628284294748812070717518476,
            9209891671273928005764228711223475645760921907046658086603668590676076934232
        );

        vk.IC[44] = mNormal_Pairing.G1Point(
            20558580932335992030141390361555862154751452363179905026253839107145669747983,
            4349723318148863307452604265879990093487715217558675668338214539542189220651
        );

        vk.IC[45] = mNormal_Pairing.G1Point(
            21128640101108414545353390151049140226264457858336220200370908361666834773196,
            17536479035961199439951846037979757955820616435480831568000947779225897978398
        );

        vk.IC[46] = mNormal_Pairing.G1Point(
            8181220260741479052733235569091087402501754327845489721716135780652421340366,
            13036724607273833212467173753897684588476807471709956892392333067388781685623
        );

        vk.IC[47] = mNormal_Pairing.G1Point(
            3260106863381642676336807626109715357802924644736039625107301609560956085400,
            19319619119172235212195982683471920727089666171920348468711100674672610334870
        );

        vk.IC[48] = mNormal_Pairing.G1Point(
            5910317743093481031938835096328340880602710926498013218777709558443951962170,
            8449248700901013456166242771893429373004216086008698185459825935585466673791
        );

        vk.IC[49] = mNormal_Pairing.G1Point(
            13663689572811087474128649574584280745093313675598236072433597444799182764525,
            19280084105112503860201351574653860062091421105658886461933217423563530589754
        );

        vk.IC[50] = mNormal_Pairing.G1Point(
            12216962080619457713453492912767933705702815744155449995691531194064933316890,
            11544136228626593593090222410094167606086415033372732115649556042217676788501
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
        mNormal_Pairing.G1Point memory vk_x = mNormal_Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = mNormal_Pairing.addition(
                vk_x,
                mNormal_Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = mNormal_Pairing.addition(vk_x, vk.IC[0]);
        if (
            !mNormal_Pairing.pairingProd4(
                mNormal_Pairing.negate(proof.A),
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
        proof.A = mNormal_Pairing.G1Point(a[0], a[1]);
        proof.B = mNormal_Pairing.G2Point(
            [b[0][0], b[0][1]],
            [b[1][0], b[1][1]]
        );
        proof.C = mNormal_Pairing.G1Point(c[0], c[1]);
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