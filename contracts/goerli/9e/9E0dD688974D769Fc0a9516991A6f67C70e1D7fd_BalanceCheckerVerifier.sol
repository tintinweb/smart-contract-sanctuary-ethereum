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

import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

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

contract BalanceCheckerVerifier is Versioned {
  constructor(string memory _version) Versioned(_version) {}

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
      [
        4252822878758300859123897981450591353533073413197771768651442665752259397132,
        6375614351688725206403948262868962793625744043794305715222011528459656738731
      ],
      [
        21847035105528745403288232691147584728191162732299865338377159692350059136679,
        10505242626370262277552901082094356697409835680220590971873171140371331206856
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
        12599857379517512478445603412764121041984228075771497593287716170335433683702,
        7912208710313447447762395792098481825752520616755888860068004689933335666613
      ],
      [
        11502426145685875357967720478366491326865907869902181704031346886834786027007,
        21679208693936337484429571887537508926366191105267550375038502782696042114705
      ]
    );
    vk.IC = new Pairing.G1Point[](47);

    vk.IC[0] = Pairing.G1Point(
      17375844436295330557333070582533219027769569500683235367186702966276917715266,
      18797630901362817124008287165772065346869620789268562451083221478064357603990
    );

    vk.IC[1] = Pairing.G1Point(
      9709899260006706388432217061703486542922542675923412630824484399762195573890,
      10477007334125356304063085423454352024926708008307197603675921598904879331724
    );

    vk.IC[2] = Pairing.G1Point(
      18890389211983513001596771224196445338597744873196084851361114642096951304166,
      9862714932750366868018238803127451597582031393493389565102841200981881172848
    );

    vk.IC[3] = Pairing.G1Point(
      18958249030705872809138917860521167471239963354448477603609304149505032198231,
      7077099737845950176146301751117534878447048417113301735419191018727524136206
    );

    vk.IC[4] = Pairing.G1Point(
      12310748009288373589457699634094144092640647836365878620654536694595036920087,
      6733549147840761484020292279226358239562304330695157701258523132897207541892
    );

    vk.IC[5] = Pairing.G1Point(
      16924363467531342466476197968408950657263996998310331101933674100706560080775,
      6163728693209126290710810395921096145223756610600551174850689892462692237824
    );

    vk.IC[6] = Pairing.G1Point(
      9497728218120805722450587629833287658878598038999397918439335838164203948959,
      20143985698549596564261615814267912660660682524890617382688024914844710759945
    );

    vk.IC[7] = Pairing.G1Point(
      20096842142209193854349186852168086921071275146361742818461503163627788406395,
      20537001189370163399015433118111029644154310183052785320269621771298628109139
    );

    vk.IC[8] = Pairing.G1Point(
      841601384466861342877902531481306784923035147172395775571737210513537226083,
      5954751430159519622816640772002266116414358498724078757994843308389421871802
    );

    vk.IC[9] = Pairing.G1Point(
      14470610026064490244945037682819860330942006130768682391581046976170044785483,
      5673201058892877902428128592432031034566862720435431016307043110760344544878
    );

    vk.IC[10] = Pairing.G1Point(
      16564821061720249735707589071457676783521639428295474472122467951786241970634,
      10201922245331814861407350814860476247648271170676998696263716581933297873345
    );

    vk.IC[11] = Pairing.G1Point(
      17851899681344552644125571310555648506910143477428885706365235299960248988698,
      19536277958203558082548646279745830377312242571418296458826203225349961525750
    );

    vk.IC[12] = Pairing.G1Point(
      16090956489716429662698078392392115747129761543717085023926296653998986453752,
      81926976232327537763535292903144089075291662619946481441848141650072991801
    );

    vk.IC[13] = Pairing.G1Point(
      14703242861159487403951593305993617371824822944081417315245375091773054183099,
      5648015905371105914946186969355294165801916731040639493342308418063740523478
    );

    vk.IC[14] = Pairing.G1Point(
      1274593245212752132420974138588485045890374862159874102741398715580309711973,
      13505123183402364486984391094675863417771941044381403362043125819172402863655
    );

    vk.IC[15] = Pairing.G1Point(
      11285578465859326758894887583723454895095716828598014645703041823669449068246,
      16802660048035723640416875065853787164668578768052248780297897074211273996325
    );

    vk.IC[16] = Pairing.G1Point(
      11775422115011035171781989347241721536862597924860897690047306002565227665608,
      12447618175198066526777516357479642099207762369912665082861931000973190486005
    );

    vk.IC[17] = Pairing.G1Point(
      17924885550958337576798834930063461296984237120687072302309635855103682985576,
      9190308903432589118704170894896983079023223128564336851364035025844444883716
    );

    vk.IC[18] = Pairing.G1Point(
      20194194004802685216135742736188212650079082843453315162133917625121350794893,
      6575077745974834216760443123152825096037609128111422692950963077493349662259
    );

    vk.IC[19] = Pairing.G1Point(
      14738617629999241047842963398166054878805912338515939525906010279853866642007,
      10996996799659856771789854432590308657625682495416550450487532283318182904528
    );

    vk.IC[20] = Pairing.G1Point(
      1374755457063742750488858672228743871120856917041341685626606148241801798346,
      11157189225123072616836083705685464029272854022854332100165458866109581734492
    );

    vk.IC[21] = Pairing.G1Point(
      7021243039254781391784511707950703747403356361171472438374746289554534767275,
      20331444734353056754668562430064780631859498410088133755738601771319898661504
    );

    vk.IC[22] = Pairing.G1Point(
      19789477574844802393584500912595593523074049781326018330885488439276040733647,
      20146852934564191748472523142367645470443220998500705424624602867377907430080
    );

    vk.IC[23] = Pairing.G1Point(
      4125650654043255080950516692025328322319566301138577202920213696737244755738,
      8247333663186081509755009030606432030617899067283735907398390157685900494388
    );

    vk.IC[24] = Pairing.G1Point(
      7734737511167339329682027144458900500436599751783505031597348109337344428268,
      19585063690600052448218294339529571257475775910329337035489330653695135518203
    );

    vk.IC[25] = Pairing.G1Point(
      10561039906628860381827814946659380345815603233467583678678329457856101375007,
      714568403174075669393958234044383540563325910312574978858682735267324670199
    );

    vk.IC[26] = Pairing.G1Point(
      21624867353213653939532028298856700850422242854124215546140250197641586886028,
      17079269484123141300094641868773562006950594368620329547541312807820856949701
    );

    vk.IC[27] = Pairing.G1Point(
      14377735603664089199474676024026796268466199248252430718188440649705391903753,
      15589060338416043968254410332465602050550691026823038418783729517184129253472
    );

    vk.IC[28] = Pairing.G1Point(
      7743091071239732170531778852005442711884926117841277596828095960664295000538,
      13455207351788265816036444578093962941922813537414831367415523390172658949367
    );

    vk.IC[29] = Pairing.G1Point(
      21275894749505955519368877857336963100426487201292327318716044780955407645912,
      8350154554852891200327508938678162908459672584755965963314502532647384237286
    );

    vk.IC[30] = Pairing.G1Point(
      13155615601515705794106959964662319752932425399695647850226354116197313607647,
      17380594124209639223666755869903888230766353282070117051572459359580958148032
    );

    vk.IC[31] = Pairing.G1Point(
      14593303196539333548487220413366453172323087337629969221012601730440427464796,
      9991144295963277124223807034747577036562917196545751142447721569926095135992
    );

    vk.IC[32] = Pairing.G1Point(
      16406577183125378738319440004822367167735519090304063523890313689294479805483,
      7305615728173305564878724467371114332948783525291236577897154339090517571152
    );

    vk.IC[33] = Pairing.G1Point(
      18712570309778101853260894053908812751646340476979226374348832457732550099497,
      4797761914796602263324538076907763372565653669153506701568166627931235973764
    );

    vk.IC[34] = Pairing.G1Point(
      3481639947595376554422132585912086352960322582824918446639103243775730172109,
      15590512940712897403284298951784820949233865331376079877337867687317391330405
    );

    vk.IC[35] = Pairing.G1Point(
      1941269004198832303856441811621017209615979446247882453860556143487492732922,
      12536759716682303310862804935769764038932000030751625553847235606458438643031
    );

    vk.IC[36] = Pairing.G1Point(
      7137559795327266571505246196318364924506362427401237405208145610067397394681,
      17253732295662418228761584846289625402398993637852046855392008961246591075805
    );

    vk.IC[37] = Pairing.G1Point(
      16206311619863044904121106789957604135971938592420128525124897430943864858921,
      5779142545706434995856104214201566198601883631626682629223603379433667019208
    );

    vk.IC[38] = Pairing.G1Point(
      5876522118385761206874751088866804290207720046449649795768590917579711187755,
      19101082457385788024854421107307222848006306374782606428952198538508975243328
    );

    vk.IC[39] = Pairing.G1Point(
      19751389137594434993969397031511981638655923818390150325687930270854723435561,
      9857498233518384413775757394025484806305829863096059618238458717920869851534
    );

    vk.IC[40] = Pairing.G1Point(
      11138660729370146289711984098799531255677129775506394865256046256464589537039,
      14787218104357443148747730423619385284933026831697426641026886945663797480102
    );

    vk.IC[41] = Pairing.G1Point(
      3525809652220195266604922991556676914041985417205825062141807721541247595548,
      10633593639736654562521097979232118445859032603027049067252414915501386010477
    );

    vk.IC[42] = Pairing.G1Point(
      10646479333123964280898139659893689811095865084669861648955371991200940893329,
      15089729165651789271302746758202993557661995505034864541480091836842732170253
    );

    vk.IC[43] = Pairing.G1Point(
      10429933451945267238814877896442652014708499698631890638598123845858163201303,
      7768185508471419548539236187977519829532147396431888103818916467589842679708
    );

    vk.IC[44] = Pairing.G1Point(
      12103784287516349815429071931087535989242812720150729783478627860668897930871,
      21389611829693345605381953150518839930803402060146443990181447739014394567040
    );

    vk.IC[45] = Pairing.G1Point(
      6344597559643142895462690127310713847339083065405843055509187609585793162020,
      15688182978907721120065413451145514059680856455933379919665653935603913417271
    );

    vk.IC[46] = Pairing.G1Point(
      9152906688292407119042089162801388227122609764464422772461794669483040570633,
      3213109015994408845065788505277928867516506449193436736878175220659366369155
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
      require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
      vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
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
    uint256[46] memory input
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

//                                                                        ,-,
//                            *                      .                   /.(              .
//                                       \|/                             \ {
//    .                 _    .  ,   .    -*-       .                      `-`
//     ,'-.         *  / \_ *  / \_      /|\         *   /\'__        *.                 *
//    (____".         /    \  /    \,     __      .    _/  /  \  * .               .
//               .   /\/\  /\/ :' __ \_  /  \       _^/  ^/    `—./\    /\   .
//   *       _      /    \/  \  _/  \-‘\/  ` \ /\  /.' ^_   \_   .’\\  /_/\           ,'-.
//          /_\   /\  .-   `. \/     \ /.     /  \ ;.  _/ \ -. `_/   \/.   \   _     (____".    *
//     .   /   \ /  `-.__ ^   / .-'.--\      -    \/  _ `--./ .-'  `-/.     \ / \             .
//        /     /.       `.  / /       `.   /   `  .-'      '-._ `._         /.  \
// ~._,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'2_,-'
// ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~ ~~~~~~~~
// ~~    ~~~~    ~~~~     ~~~~   ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~~~    ~~
//     ~~     ~~      ~~      ~~      ~~      ~~      ~~      ~~       ~~     ~~      ~~      ~~
//                          ๐
//                                                                              _
//                                                  ₒ                         ><_>
//                                  _______     __      _______
//          .-'                    |   _  "\   |" \    /" _   "|                               ๐
//     '--./ /     _.---.          (. |_)  :)  ||  |  (: ( \___)
//     '-,  (__..-`       \        |:     \/   |:  |   \/ \
//        \          .     |       (|  _  \\   |.  |   //  \ ___
//         `,.__.   ,__.--/        |: |_)  :)  |\  |   (:   _(  _|
//           '._/_.'___.-`         (_______/   |__\|    \_______)                 ๐
//
//                  __   __  ___   __    __         __       ___         _______
//                 |"  |/  \|  "| /" |  | "\       /""\     |"  |       /"     "|
//      ๐          |'  /    \:  |(:  (__)  :)     /    \    ||  |      (: ______)
//                 |: /'        | \/      \/     /' /\  \   |:  |   ₒ   \/    |
//                  \//  /\'    | //  __  \\    //  __'  \   \  |___    // ___)_
//                  /   /  \\   |(:  (  )  :)  /   /  \\  \ ( \_|:  \  (:      "|
//                 |___/    \___| \__|  |__/  (___/    \___) \_______)  \_______)
//                                                                                     ₒ৹
//                          ___             __       _______     ________
//         _               |"  |     ₒ     /""\     |   _  "\   /"       )
//       ><_>              ||  |          /    \    (. |_)  :) (:   \___/
//                         |:  |         /' /\  \   |:     \/   \___  \
//                          \  |___     //  __'  \  (|  _  \\    __/  \\          \_____)\_____
//                         ( \_|:  \   /   /  \\  \ |: |_)  :)  /" \   :)         /--v____ __`<
//                          \_______) (___/    \___)(_______/  (_______/                  )/
//                                                                                        '
//
//            ๐                          .    '    ,                                           ₒ
//                         ₒ               _______
//                                 ____  .`_|___|_`.  ____
//                                        \ \   / /                        ₒ৹
//                                          \ ' /                         ๐
//   ₒ                                        \/
//                                   ₒ     /      \       )                                 (
//           (   ₒ৹               (                      (                                  )
//            )                   )               _      )                )                (
//           (        )          (       (      ><_>    (       (        (                  )
//     )      )      (     (      )       )              )       )        )         )      (
//    (      (        )     )    (       (              (       (        (         (        )
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Versioned {
  string public version;

  constructor(string memory _version) {
    version = _version;
  }
}