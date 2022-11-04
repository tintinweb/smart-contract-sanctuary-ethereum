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

library mReg_Pairing {
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

contract mReg_Verifier {
    using mReg_Pairing for *;
    struct VerifyingKey {
        mReg_Pairing.G1Point alfa1;
        mReg_Pairing.G2Point beta2;
        mReg_Pairing.G2Point gamma2;
        mReg_Pairing.G2Point delta2;
        mReg_Pairing.G1Point[] IC;
    }
    struct Proof {
        mReg_Pairing.G1Point A;
        mReg_Pairing.G2Point B;
        mReg_Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = mReg_Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = mReg_Pairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = mReg_Pairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = mReg_Pairing.G2Point(
            [
                1269577951906520865646856870823795342289168363713424507181224037166240419057,
                20880925857127902814833759191805671338973989258038000503166211600383476992028
            ],
            [
                13596585801456338472722096176853144037651376534900578948907107134565215481740,
                15861245297211362358524635162159044085170137784918394827631821487164004784937
            ]
        );
        vk.IC = new mReg_Pairing.G1Point[](43);

        vk.IC[0] = mReg_Pairing.G1Point(
            18059116144558224812872337173323873528492429635923883772130507154384500345743,
            4190301413911327556871605662732744913257233349723084444082170804498909167087
        );

        vk.IC[1] = mReg_Pairing.G1Point(
            11837939800179076022266585357582103323927374104015045295171776574081728034940,
            18498447098312113088835279323212893095521008767509151776211509393823131758210
        );

        vk.IC[2] = mReg_Pairing.G1Point(
            4541982112099564108954489319440880081800755820053921954442405263572638436191,
            3344894758323544058552749330329641059253881166296968735111307765529751366587
        );

        vk.IC[3] = mReg_Pairing.G1Point(
            19756753405366693666258521488568800576463598875160389291051117617892625728062,
            14598904990893624049322820750005012213046952328235868553997060346832947123686
        );

        vk.IC[4] = mReg_Pairing.G1Point(
            14319951378046684319909515198468741882584055632871090277430005057658375320599,
            17817246086129028798576452322865837555091093312565128261210679994504462569152
        );

        vk.IC[5] = mReg_Pairing.G1Point(
            17225879854582249225999108130370188116139068040967009832117682278838773680379,
            17898269721641277452277234846024413922628888462874206590224505900779776152181
        );

        vk.IC[6] = mReg_Pairing.G1Point(
            16990696166805651814496416983710874085471384254542865223775566285335312577398,
            19210884858486689203329650318193148226782845469642234692452848015089123392333
        );

        vk.IC[7] = mReg_Pairing.G1Point(
            5783361110124884465707688697545720816841100276346792536130440339291799104058,
            20080551041181028680980214787172068309904505245237229262678330313111827632115
        );

        vk.IC[8] = mReg_Pairing.G1Point(
            11730811994202523535142224156908148135365110101045520411170269967905172305052,
            2057073434119221045325882529860532780693931468613640400526150692558202815988
        );

        vk.IC[9] = mReg_Pairing.G1Point(
            11473642234430113454041243661677807238582099069403511467186249303349951716134,
            3135780082405974714287735938321957209555251747619794331057480044886361077326
        );

        vk.IC[10] = mReg_Pairing.G1Point(
            4721047277232506101008926899095416406404714521438937114205894261948334542250,
            2603203964914145864764788239398277113023809506801274970255644407250570775670
        );

        vk.IC[11] = mReg_Pairing.G1Point(
            17983604283967129457398274645401705702663763595434213864304925020890689789221,
            4890800248254282731744254342068998384733011274132420503920262022940037368476
        );

        vk.IC[12] = mReg_Pairing.G1Point(
            8025911515508673720443600551608414919737763675595749699929672515565825774020,
            8151757332485914987334584980859684810397150996881057752849948243949792065633
        );

        vk.IC[13] = mReg_Pairing.G1Point(
            17961494328029377330626009311195516541944118697698447409077065565577892551350,
            19239883594146159355550062248208583721253300030047281123032713394913192886476
        );

        vk.IC[14] = mReg_Pairing.G1Point(
            8073261097107983342213219474316670504047905436936162907556473449619600797425,
            756217943374098209424762602017583174980352473689889681212152563722735017340
        );

        vk.IC[15] = mReg_Pairing.G1Point(
            4692859430498478039718847196084520341781629609692566675923800661486754976823,
            9788396319649729294013770526492088408479495558418997335346060766672360698364
        );

        vk.IC[16] = mReg_Pairing.G1Point(
            15403632858509591496469111676790694638524505758143771233301454787972074847603,
            14518448102776243361043401717779850915610037125733571292416349646426638740688
        );

        vk.IC[17] = mReg_Pairing.G1Point(
            20240126562829531835344612445986906158500207778666178397126417913860219971725,
            10665706097884967605894336849563969418606535251220100738941513492220576363571
        );

        vk.IC[18] = mReg_Pairing.G1Point(
            973314270055451013762799803618816553648887616569713999171839399223045647221,
            21878273953105352388169774729291949926290903744144348163993751217042741160798
        );

        vk.IC[19] = mReg_Pairing.G1Point(
            2621418510138506293925020315314870952553621614453074950088201887301361369221,
            9730843013577717460248952245307819798720929916199985115703015751103132932455
        );

        vk.IC[20] = mReg_Pairing.G1Point(
            14850151123280226240209748930017100510578829191918054498362563223845102456226,
            18735261321345789942494690012711530406384637402175514593479193822928726908819
        );

        vk.IC[21] = mReg_Pairing.G1Point(
            5379729101298042384068294328923020958450306172799176762127915570883804420505,
            10426372808976300479860172251771510515105114302657372088046320958874754325053
        );

        vk.IC[22] = mReg_Pairing.G1Point(
            6774362059021370523922688304587962905396365230958289589405322023039410351357,
            11169160189991568928946434995001157848419573947400892595970687217791793400910
        );

        vk.IC[23] = mReg_Pairing.G1Point(
            7059967169998699757507645628307862290220464227504170367326937328078384501179,
            6154540243546242481455864755650133240179593470558687381437098375076767851265
        );

        vk.IC[24] = mReg_Pairing.G1Point(
            20306908754566241393135040978839444563687144510884530800838138043288984702870,
            19894790072084161088126312234327515172637676171131471949717188880399039282980
        );

        vk.IC[25] = mReg_Pairing.G1Point(
            21375794144474101970816792499790636019969735365298012840201155692279375655883,
            2437404565121839456390797989140047941635490931048308568547287603220971327105
        );

        vk.IC[26] = mReg_Pairing.G1Point(
            5598731833366896763156984007871692002335785952988298444205438421059404319123,
            11431473575027240865945658146865051482489689888968631056029609924987787977072
        );

        vk.IC[27] = mReg_Pairing.G1Point(
            8939201274533554856802823323887312515127270479217886499537634354696263168771,
            20308728018118177506321561013252561048759829386194489090755920459690797921134
        );

        vk.IC[28] = mReg_Pairing.G1Point(
            6146536022755034889226891683420192488261809254020089813859713176102828539704,
            7847607342559414457257899506732098234417414282215890441830816776965625941807
        );

        vk.IC[29] = mReg_Pairing.G1Point(
            2011864686931358992113900234266530200059947340757428073136369021751423296590,
            12450596662642405442828613239485401162981820692109152070397663526462540256984
        );

        vk.IC[30] = mReg_Pairing.G1Point(
            12702562566124803966412356231165620414051471681600704714842782669112643659668,
            9223111326231355778448862744135206310354644131547390247647271688342899288773
        );

        vk.IC[31] = mReg_Pairing.G1Point(
            5777800942057985427076219126072374648358764067799580829988034861428439480618,
            2596714544947778275336240373785238259293952977913094177882572657932940769013
        );

        vk.IC[32] = mReg_Pairing.G1Point(
            4843064281018328041275449564767275051407602490204824827531618700376485632027,
            16837507061917646294658814322570144784844160458283932741974940138591299365371
        );

        vk.IC[33] = mReg_Pairing.G1Point(
            4088954637678877829931209611095448211262216748588834508238753342004843466534,
            7734662752673814910133793666427517883600217383189459276340395285496944595263
        );

        vk.IC[34] = mReg_Pairing.G1Point(
            6531977023558336604810707031431332234643869457798386041605195812539614847714,
            18024724433241805138101864185592013712430230379646338984516515488650716236263
        );

        vk.IC[35] = mReg_Pairing.G1Point(
            14954387997113082777117872638119756339667680239444821478680879218300548186438,
            16062640167472703623439091502099345060457406789274962638233845369305727222471
        );

        vk.IC[36] = mReg_Pairing.G1Point(
            12468907508790791383604319905856923517914661051493428233022285872283056911502,
            5787968598128897339318000945904574120249344015542024268338636190841008243365
        );

        vk.IC[37] = mReg_Pairing.G1Point(
            7206023723067198418954451435708795057698487118497481361616895736947391590520,
            20932654269968038549667150474766693722321620682991407039328312275499916576604
        );

        vk.IC[38] = mReg_Pairing.G1Point(
            7426694019556104350623189583199556068775803738015807129397655033039848591016,
            1028031943883954731840195632857323294575549714284056258655814233440606056940
        );

        vk.IC[39] = mReg_Pairing.G1Point(
            6924340296279557175507419250773954178901972757186273601489632327298652480615,
            19202170633925746786216819852493588131575594954453080260141154099437876910631
        );

        vk.IC[40] = mReg_Pairing.G1Point(
            7619517304869744669474346371707313907025617434333216209316485145630427146672,
            4206170540867487574633806179124592410188587869717308211081779568232666289546
        );

        vk.IC[41] = mReg_Pairing.G1Point(
            7674405583742113321878355986926383697265030969269552908379080053283050872312,
            8701217012065686136107469169944324945595824634232462383958659414453922197970
        );

        vk.IC[42] = mReg_Pairing.G1Point(
            16381206669931649222329607233107084593874229301264197531606570544570138946508,
            18621766509907536782954051388155814832188135142496870976206051205489211632798
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
        mReg_Pairing.G1Point memory vk_x = mReg_Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = mReg_Pairing.addition(
                vk_x,
                mReg_Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = mReg_Pairing.addition(vk_x, vk.IC[0]);
        if (
            !mReg_Pairing.pairingProd4(
                mReg_Pairing.negate(proof.A),
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
        proof.A = mReg_Pairing.G1Point(a[0], a[1]);
        proof.B = mReg_Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = mReg_Pairing.G1Point(c[0], c[1]);
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