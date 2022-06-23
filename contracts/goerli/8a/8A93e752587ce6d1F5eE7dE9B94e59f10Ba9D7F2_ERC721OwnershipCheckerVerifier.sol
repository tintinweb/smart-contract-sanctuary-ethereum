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
contract ERC721OwnershipCheckerVerifier {
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
        vk.IC = new Pairing.G1Point[](58);
        
        vk.IC[0] = Pairing.G1Point( 
            19915619029488557051015703440041688910410410092074497289203482808482160820628,
            18945315995039948098551037215256899767496856339313023739683410771944393237194
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            11600785647932177484981218929878705553553604145160385588887575189840066797102,
            15148567371951787016455919951323515907563027805821350332335146573871990051608
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            1014366623246979195645906032263972215334331836404485926065484358261840825496,
            15130564187569847433663796594526050619611449222269720375341236918554726478688
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            21746832502766852856333382887330514796497559328081686672967927943538548816546,
            13820919471750689378786547470916161105548951660302206080388883967782531017743
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            6530829897630262537537759717055368327173334238153904758228914156263540994380,
            13548029221135940703713417893628757734985173271062538249777164222659499740607
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            20132302037577767368492475236829008251527727493412811447418249198385719419195,
            6958115188188996373304808817091637198742878622849325200147756235846009538700
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            16070410914901220975568787361267672404903174053182993910997442000133212355823,
            11845097920370147153229294414076662284995645355182093758302890929391995608026
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            6481861626403530903796231697199778329875834877772564802552468158140142792147,
            11219920146621989923424709845581530292134557307117844772987551261694262902759
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            155411633381071717244783056164750877535236579532691285055392929173345129609,
            1120334578974215342066615207847594517672829602672443094442618536608198411978
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            2087556994434901146092860821072609542921144323027145119749377040681410728435,
            7690808602209650728803400334350211089281236337297687714689950862255911658568
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            16757126799561074969846165751842215110113595244822987504724923289891663120228,
            20266998171658630887539310991561875194582548579769720230338687931904499100477
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            15536143176232369775089202354283067548332496744024441331092427282675492050668,
            18848030717453099393022643139532867202312687617516517427441713037457055545832
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            3114939588864341841097162589068165985570622292151781327959588396518037220521,
            6668933371243104226085868871039751455765670762780742827725600423674636146032
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            6408279367042157662222318061840459407286211807067008530971024784801854024649,
            2970236900312087499749005646439758785868972802075650812397749849981464896287
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            8440667022640693388453461389682142201442400191684534817724341653154912612386,
            12118132723158603079191170105226360814733791115521219521866829743801728000177
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            8994927227671557345503749378838774615800178494115667903441326011807704604943,
            10546240792053957098304728029230527459812519904912079420128748836627577099071
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            4914754344332155262763885059339160163577334890078591597325518848969027917149,
            12174280057940312647154495847563308987559386194226785435231790195934564601197
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            10827220573329140616748369695247692596060867358540368985304571619697942430096,
            3481725445592494854729163021157896184268811622187951793070505554963795880827
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            5590903699392592696321411722529990027996984258568838472664610192113297806289,
            14911071785620181003037013144286069963055350521482163354275217362820459598866
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            18270196087066756765512955507147994071225505162875449697565808515394140880216,
            4148689652455550314912833901887103140471442810696104466467207531448616097776
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            7932345678438961880008517928908270299860118135635584004800300694804268589373,
            4553897600888797680561061982262218004176418795704605965423123594892342779537
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            20541476359103924962588550559000150697516762982782697901881844057674823260312,
            1796602648648747657786622742477482753439246093312245167931584669950747910350
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            11202668020106288908899189528690878079062717165966085600376601735519850270511,
            17119426481118643119744790703830119377296507987497862561968402700933322810337
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            12715366150406684213590997808388370857572018689357781584824225086541974085748,
            20927181974901474613777990457046654744967586705181998864813132159349029369744
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            19234706835801761124782154776188960214640066330947038420660583739831617287984,
            11834152587504295418862689633192284764090887407408015868787839207964505333100
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            19491232748658661415698983345760218183836275771323592214235796249168225569771,
            3646919021653344735561779397134873612089946674810352109096042151500087298300
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            10415034778779755487592286429887756478571542258257966582540875936159173664196,
            21218865112574461399717418526419718698912044019027214822479805520351759690383
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            15323164273664832337312474858803419253132234852939664725909949862308853692521,
            13094780817836603201768123914184763019618412504410242934800836439723916755282
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            2200403136564475027158129196284381379489434265776967127625498841482037516163,
            1079805709905949305292059958836546690830620163438238286725756037842519235159
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            19409317188773700305455470804698588096170393269145991938734335573106555620154,
            9835675700824658157803242452204948575658443747901018351357730257901280620921
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            2041983283960527248831548200792273663167797660922939842091651366067900999351,
            11054537616103910266357856171891736246543482302708421978860449822216875038765
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            6421874588201045802572069647155639915630913573388845961522880371071302750942,
            21713295945960614350069684309374516206813029404126896632899550845372351010766
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            16903170603988675906032577824855130948819466181510622343206918392829512234119,
            14549870522884911399218233102425520093075494554132735608922563481226931854270
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            20330256742101992499650628696089273351420407737228078835527443651995950797208,
            2714373346779528348109703044374895096671632979586428969631502194019521099737
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            6873632656990647815970295829969442247366828905066368943770087381315848001614,
            7610759864188659915838370637958488219990082876996808412437452662880872600307
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            987816384398920382882337432892200920795859457178464530232235465989008687097,
            13077208850169300905171115512859753851978688735858992467655764722231041871496
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            7542252919985199198059814553794844298825959278287233303998929536849415181306,
            10989367317974874988762506186087105286139881382509547965128104039968281169013
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            19780148458428570990075470179035124332855894047320372049050936136602757567240,
            17579051548531979974907308474064268178919454128848397321682554678380613081932
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            21354154861817123776165112449072330297354133177096115158832679773240963417215,
            14196871159705793856497829207700695976616567893036249686073706743551889788499
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            21837684411312422773545991203985202145122520091561896617759958924001396529781,
            12679568874594953573361355563770150473520275032922755895105037415235069127602
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            11827807532160167555181808306038656077337228999459132475991732027309708374783,
            5042130067820180095930892349702797987983386734635226966055855920665700088480
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            13700347545237329418490130248650591027740272915987079688485538949872826299072,
            5780908037981766567141627215646842920849200755874480072424364987750686712192
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            14620846037932349015371897214941460707628645817697049705971528674592605448253,
            17845387484924700144219977342003619313565743425177035233016353279476152233810
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            20694197162639072187951917472300492208947175373475191389607647614993245827341,
            14408198257844528613553356504340162195104132437030585872941693916422543790006
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            123505226343604207735114089515212195172035994673719212949125358465809143716,
            6532243762694396671014499679365854883609214716624072264302794553001425908581
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            15934796836738398983107406917311463833898253015562731043559150245447574935867,
            18808321035927810738442683859759284883945003701261218857495644290366614647727
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            10037176434646842363370698765796038074506456691367633806968735325282825843765,
            577464686176366195185823435315249648412626795952842862170053396339287312762
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            11921340448527608528716080177363817122307680159005709982509465705514975663495,
            1724980575714748304553718012675912313776914554688187241252752772403332093265
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            20017242619721163547627254880838954039795666692344524054641090418880176067814,
            8328456975262631699020705527449652493865488000239312362483063864746491636227
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            14137502594614960830769008297201411674031776855230806704694007122573620256073,
            9287897093992191680274277482449132593218361890759730868504215263903304670063
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            15716832792328038559993083420828340946879303983808713283287062844159477647740,
            9678027433734577015490134316120856889527717924771468761871274564420419167108
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            10218038666119053378095372857103785034057965702990655327384344826831683997886,
            19568013022863892365730527262376625795895000445104852175139420188312951284287
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            2791195862747224042842736597788405082874438414319427122810654536476995175963,
            20329806785000908657089078278353095779684170774519775765528960478306497622184
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            14209728927770668342800798904422325962280222256160660208034991469349035134491,
            5435102931350898269191096388508227519355051395235432084572073114389434118568
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            10693044467315465895257992928779885163491284302987492913636594671011289777971,
            11827063260126556064024696166218528164145112201535664307841774532679932810090
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            19233618162554501998205447608669827561260848771882747983406407782702947655675,
            13865702326502028966081314544746362169332549895765810682568019754752938136602
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            10482796147470994780355837151073127142047521610170456156527842994023236197128,
            14939167650175435762359945726190804498125285794847691679129173218455246901631
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            17802975588266217911224121147579441205615459898880118261789504911468312658867,
            21713219663610648004907158859267230098338921967927307339065272543940563886700
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
            uint[57] memory input
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