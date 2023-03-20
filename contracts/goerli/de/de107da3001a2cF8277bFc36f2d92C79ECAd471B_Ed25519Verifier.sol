// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
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

    /*
     * Same as plus but accepts raw input instead of struct
     * @return The sum of two points of G1, one is represented as array
     */
    function plus_raw(uint256[4] memory input, G1Point memory r) internal view {
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

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
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

    /*
     * Same as scalar_mul but accepts raw input instead of struct,
     * Which avoid extra allocation. provided input can be allocated outside and re-used multiple times
     */
    function scalar_mul_raw(uint256[3] memory input, G1Point memory r) internal view {
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

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract Ed25519Verifier {
    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        // []G1Point IC (K in gnark) appears directly in verifyProof
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
        Pairing.G1Point Commit;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            uint256(16537564926561257518103578528440315215453761258292367362288728531966371995874),
            uint256(17745573146004211534248579212526935789334969204993357645263388924661264974187)
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(18681724724964420256656295617462445194520232343683657023020438565197998259673),
                uint256(12193837689525487485139416036830252517228166559922434453026243184766751424223)
            ],
            [
                uint256(1142689458690077585879713419885020952718961581248594394197708921155425831615),
                uint256(21176592749741182389767016778519001156128344286592614375719960199144776585881)
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(19799290104465580933750348548810731188007606239377683243716104715153013203241),
                uint256(11029356377690007782073139603897274721732913650225177555357052135977173817932)
            ],
            [
                uint256(14853413044533073822755393458984382667328640010571213879456567827440818416559),
                uint256(1410171095280489347779850966561512432991607061868962673896369110725284404185)
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(14033331354156232558698818931400566889727401262494703861181881854810319611656),
                uint256(1803778019251118312050232705802652879152144501576771122000761003085527364548)
            ],
            [
                uint256(19177018991900245360077248204991378509575348272931358571227777389261756980021),
                uint256(13491338816347045964487197971132020169975241104757177444019867803073686189354)
            ]
        );
    }

    // accumulate scalarMul(mul_input) into q
    // that is computes sets q = (mul_input[0:2] * mul_input[3]) + q
    function accumulate(
        uint256[3] memory mul_input,
        Pairing.G1Point memory p,
        uint256[4] memory buffer,
        Pairing.G1Point memory q
    ) internal view {
        // computes p = mul_input[0:2] * mul_input[3]
        Pairing.scalar_mul_raw(mul_input, p);

        // point addition inputs
        buffer[0] = q.X;
        buffer[1] = q.Y;
        buffer[2] = p.X;
        buffer[3] = p.Y;

        // q = p + q
        Pairing.plus_raw(buffer, q);
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory commit,
        uint256[57] calldata input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.Commit = Pairing.G1Point(commit[0], commit[1]);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-gte-snark-scalar-field");
        }

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Buffer reused for addition p1 + p2 to avoid memory allocations
        // [0:2] -> p1.X, p1.Y ; [2:4] -> p2.X, p2.Y
        uint256[4] memory add_input;

        // Buffer reused for multiplication p1 * s
        // [0:2] -> p1.X, p1.Y ; [3] -> s
        uint256[3] memory mul_input;

        // temporary point to avoid extra allocations in accumulate
        Pairing.G1Point memory q = Pairing.G1Point(0, 0);

        vk_x.X = uint256(9462447710939432742848424196697728822687813011479891122131648160830275921458); // vk.K[0].X
        vk_x.Y = uint256(11473376488241810165831757536366836850027784981839089792021378256861687455964); // vk.K[0].Y
        mul_input[0] = uint256(2648510173551830043068139172354933052408112984889271406750039349551232576549); // vk.K[1].X
        mul_input[1] = uint256(12122054635554892818275346487442913112730051679642997892313491753063522521582); // vk.K[1].Y
        mul_input[2] = input[0];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[1] * input[0]
        mul_input[0] = uint256(7061394255936047678059253317568688117856036320639226956214975754160049295333); // vk.K[2].X
        mul_input[1] = uint256(14145671141784595839380141874940651481054054987062620771942604522524338984737); // vk.K[2].Y
        mul_input[2] = input[1];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[2] * input[1]
        mul_input[0] = uint256(8218011998118573873686464766508340825013181970169509029207170044008261486193); // vk.K[3].X
        mul_input[1] = uint256(4808589679893008233603109916014512606401750471929338771914335778004460444360); // vk.K[3].Y
        mul_input[2] = input[2];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[3] * input[2]
        mul_input[0] = uint256(6078662146959222742143128212552101384988335461422265821062667538426926541518); // vk.K[4].X
        mul_input[1] = uint256(14225787497847862685225784260006515346740700745306082959617044081310626314439); // vk.K[4].Y
        mul_input[2] = input[3];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[4] * input[3]
        mul_input[0] = uint256(15225699490833575811570520695447458343846017972639836494871931441485526096787); // vk.K[5].X
        mul_input[1] = uint256(15569415315038112005525705058718435821481109166559557245122292405605719408925); // vk.K[5].Y
        mul_input[2] = input[4];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[5] * input[4]
        mul_input[0] = uint256(3942281303299556918937442887343925623486733341136969568571582227745440173807); // vk.K[6].X
        mul_input[1] = uint256(4138173571813503741513576149284418571266189111210058243046675207337729400955); // vk.K[6].Y
        mul_input[2] = input[5];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[6] * input[5]
        mul_input[0] = uint256(723953850260184913681651686455204823265776604606646409438367197633827064461); // vk.K[7].X
        mul_input[1] = uint256(20977669267739599281940138230527850695064911563027213490970977450491160080036); // vk.K[7].Y
        mul_input[2] = input[6];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[7] * input[6]
        mul_input[0] = uint256(15017582390282569744856651205092622236708068694757044392807758501545223739943); // vk.K[8].X
        mul_input[1] = uint256(1265991120483539619897036121722423769988535691692111441020055552301420911354); // vk.K[8].Y
        mul_input[2] = input[7];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[8] * input[7]
        mul_input[0] = uint256(5221873433181937410686676698706306071488292331003715940336123836669316677478); // vk.K[9].X
        mul_input[1] = uint256(14426879645470087966651542997861483039122804778202333350123336907198495445103); // vk.K[9].Y
        mul_input[2] = input[8];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[9] * input[8]
        mul_input[0] = uint256(20573069687094669083259174171204052569713827743866845162450148699057547764918); // vk.K[10].X
        mul_input[1] = uint256(19125182916367006002072229187347273947735042422948150051314675975432464674658); // vk.K[10].Y
        mul_input[2] = input[9];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[10] * input[9]
        mul_input[0] = uint256(653108268157101410313141643706313813985558592438699399282213422712029889715); // vk.K[11].X
        mul_input[1] = uint256(920655015136053252820652067829010626746362759835559920517492343709532195466); // vk.K[11].Y
        mul_input[2] = input[10];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[11] * input[10]
        mul_input[0] = uint256(20917639943585713768528304284726936606521085966431546157561891168025022757887); // vk.K[12].X
        mul_input[1] = uint256(8262496391990750367129442871845474963121866167295779784485121209123609128682); // vk.K[12].Y
        mul_input[2] = input[11];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[12] * input[11]
        mul_input[0] = uint256(21382382741426387778276445265980446660720522906365157168723787305555966928178); // vk.K[13].X
        mul_input[1] = uint256(20304725605418784279352839016897739647529600560330484467516988594075783844854); // vk.K[13].Y
        mul_input[2] = input[12];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[13] * input[12]
        mul_input[0] = uint256(6205744815043738292440949022257329596826099473730575848275490097888497842377); // vk.K[14].X
        mul_input[1] = uint256(14621389881302722659870997782918885566955239423536368018214245647671237084390); // vk.K[14].Y
        mul_input[2] = input[13];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[14] * input[13]
        mul_input[0] = uint256(15814307705747507442630842462045602926477319899462506430805053181751486077929); // vk.K[15].X
        mul_input[1] = uint256(20719845899119367288065102841494811826814842176184748936398855427173476589603); // vk.K[15].Y
        mul_input[2] = input[14];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[15] * input[14]
        mul_input[0] = uint256(13115514590566800662313134167308526149064497604562804026503299495382170121521); // vk.K[16].X
        mul_input[1] = uint256(1332307969280655731716061244811863427539380178344062557717239827752566800649); // vk.K[16].Y
        mul_input[2] = input[15];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[16] * input[15]
        mul_input[0] = uint256(21831548148156992003553031892913267462010789037401082515443630438407722663969); // vk.K[17].X
        mul_input[1] = uint256(6734282036223126997206695046254381537591284089119495472525380311105692037149); // vk.K[17].Y
        mul_input[2] = input[16];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[17] * input[16]
        mul_input[0] = uint256(19824054054568150451544715245329533752342566872920996747743887644800176138756); // vk.K[18].X
        mul_input[1] = uint256(17444883232483823314330637172782524563336237772974332017836978912923943288044); // vk.K[18].Y
        mul_input[2] = input[17];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[18] * input[17]
        mul_input[0] = uint256(11203846533369587519929291820435945242235455090413432458828659220572895771832); // vk.K[19].X
        mul_input[1] = uint256(16148158018136729384412794294904585957329060422316919194693060478106477584261); // vk.K[19].Y
        mul_input[2] = input[18];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[19] * input[18]
        mul_input[0] = uint256(21371926577928441304164289543024513366951022486217703908520862772671592138220); // vk.K[20].X
        mul_input[1] = uint256(18107932227339892218168366645185506844179114579625951614458742714985063933868); // vk.K[20].Y
        mul_input[2] = input[19];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[20] * input[19]
        mul_input[0] = uint256(2078836125811363606455079208654269542518183191401138318514557936552194691549); // vk.K[21].X
        mul_input[1] = uint256(20289036517453961776720656852506924474500493189617637737320825721964408623696); // vk.K[21].Y
        mul_input[2] = input[20];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[21] * input[20]
        mul_input[0] = uint256(20684528615338806451021356191176017140605638913507543305045224022571493583399); // vk.K[22].X
        mul_input[1] = uint256(3903056905414345066553250327072636225389082733080503032794283501727725353966); // vk.K[22].Y
        mul_input[2] = input[21];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[22] * input[21]
        mul_input[0] = uint256(13854622650680331791998959936965711435732154320243563610773598319176375507733); // vk.K[23].X
        mul_input[1] = uint256(1293023507593941743631670346894908106668220179131184101706263206018361614455); // vk.K[23].Y
        mul_input[2] = input[22];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[23] * input[22]
        mul_input[0] = uint256(3806178131996244443364939020206141693542459073159601454749540496458558677609); // vk.K[24].X
        mul_input[1] = uint256(11373982291360652938998008416691951950539326147900435417838815437650728107752); // vk.K[24].Y
        mul_input[2] = input[23];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[24] * input[23]
        mul_input[0] = uint256(2956423360991834768742742798077214208812640276852161493833529280831095074781); // vk.K[25].X
        mul_input[1] = uint256(1036790067266635965218530400023441211296511606457139237137911024262932772523); // vk.K[25].Y
        mul_input[2] = input[24];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[25] * input[24]
        mul_input[0] = uint256(3522982602799278288450494299627381578769489328186449628808472144237402446412); // vk.K[26].X
        mul_input[1] = uint256(13124545182856888320922946645561369145471456600466254299605996043152521299609); // vk.K[26].Y
        mul_input[2] = input[25];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[26] * input[25]
        mul_input[0] = uint256(10203021712642579290406260398074627148768959317126130666994877932179153487975); // vk.K[27].X
        mul_input[1] = uint256(19220206362979524452868254497284191194377622625329987254755474419246348464504); // vk.K[27].Y
        mul_input[2] = input[26];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[27] * input[26]
        mul_input[0] = uint256(13656479319858575241396965583832757201969209361023293619085267873236508281324); // vk.K[28].X
        mul_input[1] = uint256(18653894887361004227161091206020531090371042692329436200109497793456818170297); // vk.K[28].Y
        mul_input[2] = input[27];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[28] * input[27]
        mul_input[0] = uint256(20667457304256598973369559213600706490691854322307004623522066355950536986052); // vk.K[29].X
        mul_input[1] = uint256(10166524048179842305027932295420555626140631584017768928975471213820747864954); // vk.K[29].Y
        mul_input[2] = input[28];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[29] * input[28]
        mul_input[0] = uint256(14451586832169158165406346103518705733160542436336769287947890488919305713536); // vk.K[30].X
        mul_input[1] = uint256(15677358351240766490224933957331428778606486522363230169083418720895728674937); // vk.K[30].Y
        mul_input[2] = input[29];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[30] * input[29]
        mul_input[0] = uint256(8815343788891391302884218656640023092689342750375488785771313089418754129780); // vk.K[31].X
        mul_input[1] = uint256(13009618795398702701706372843804296988960880281370027843016246576371783417574); // vk.K[31].Y
        mul_input[2] = input[30];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[31] * input[30]
        mul_input[0] = uint256(7794542304670317906972413815443657110555785749184277557959662453473304832135); // vk.K[32].X
        mul_input[1] = uint256(13613183423982157012686848485088999158423912294590394357601874166998596036708); // vk.K[32].Y
        mul_input[2] = input[31];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[32] * input[31]
        mul_input[0] = uint256(13829063270265614122932776384418402417255253559219713892264763147960420595663); // vk.K[33].X
        mul_input[1] = uint256(1394492787369205690940389079323334412434996525623614329408676573910762151803); // vk.K[33].Y
        mul_input[2] = input[32];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[33] * input[32]
        mul_input[0] = uint256(13250480124160751683662026425319692126614649754704623898304284468074453566914); // vk.K[34].X
        mul_input[1] = uint256(5842667319974085537473375237026886465714130878203887186671280383692949371367); // vk.K[34].Y
        mul_input[2] = input[33];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[34] * input[33]
        mul_input[0] = uint256(4244396663084445939427850030230353204559612848770696182862006916130063961075); // vk.K[35].X
        mul_input[1] = uint256(5567117583761251190183987315357290694204768312790348596534705058755423324166); // vk.K[35].Y
        mul_input[2] = input[34];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[35] * input[34]
        mul_input[0] = uint256(16468214890309010196842237213567005731971554524310253342503592222181911831216); // vk.K[36].X
        mul_input[1] = uint256(13015440355627709680447076370593216495840212097545614001751347318260304962870); // vk.K[36].Y
        mul_input[2] = input[35];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[36] * input[35]
        mul_input[0] = uint256(1710502514829787762068790998518593585732164832507101474241328558660469459552); // vk.K[37].X
        mul_input[1] = uint256(6641523787174944064207070430739280224248149581740606756642107112326594132092); // vk.K[37].Y
        mul_input[2] = input[36];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[37] * input[36]
        mul_input[0] = uint256(13873688322349022545411654259743538242310790895509577137595893668751435535182); // vk.K[38].X
        mul_input[1] = uint256(2743144454147776739466147084712345009024223781055121185226575029717710864182); // vk.K[38].Y
        mul_input[2] = input[37];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[38] * input[37]
        mul_input[0] = uint256(5515207890157998771775835819329897799964342326708529575708915192914192717763); // vk.K[39].X
        mul_input[1] = uint256(6830846512538057603246995968366818367160206190590285682644456335384380744224); // vk.K[39].Y
        mul_input[2] = input[38];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[39] * input[38]
        mul_input[0] = uint256(12084319035206948715397631350220429569745624512314143843439943565130003131475); // vk.K[40].X
        mul_input[1] = uint256(19823940921149166526761280180611360195654754479337467436765527950957403100421); // vk.K[40].Y
        mul_input[2] = input[39];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[40] * input[39]
        mul_input[0] = uint256(1707966742483292923663665240004271093118893352464133867701833789750341568293); // vk.K[41].X
        mul_input[1] = uint256(2059830066597637963266616577934465643861703524384620495213365657208172372127); // vk.K[41].Y
        mul_input[2] = input[40];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[41] * input[40]
        mul_input[0] = uint256(4335683960535202743801100378397366667909285456099227829020337934512681970900); // vk.K[42].X
        mul_input[1] = uint256(7163760264613823569250071408872840488100394969233714572137432343600611323243); // vk.K[42].Y
        mul_input[2] = input[41];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[42] * input[41]
        mul_input[0] = uint256(18579130060975771189412379077269037710625635418528267671299513425013575199707); // vk.K[43].X
        mul_input[1] = uint256(7413439674648248746853580336851465886481116161464911636828558414649648473619); // vk.K[43].Y
        mul_input[2] = input[42];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[43] * input[42]
        mul_input[0] = uint256(16042514199832592968247672418295024202640592240955629633937928114942675433499); // vk.K[44].X
        mul_input[1] = uint256(9176210646934564968216912647498279795139899070579664859952976743279140133749); // vk.K[44].Y
        mul_input[2] = input[43];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[44] * input[43]
        mul_input[0] = uint256(4605826036674863045915848920224687279865356012358913781882485214370608375866); // vk.K[45].X
        mul_input[1] = uint256(16433469797022838005221089589473953566885756258639853768294415623922164207114); // vk.K[45].Y
        mul_input[2] = input[44];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[45] * input[44]
        mul_input[0] = uint256(21291606718216838223612806394353023159167853021188903625675694115824239986243); // vk.K[46].X
        mul_input[1] = uint256(13861976516244796326502185111204736567218465632382198677006716558365310272234); // vk.K[46].Y
        mul_input[2] = input[45];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[46] * input[45]
        mul_input[0] = uint256(13608539239013691835986711410119733227388008030702193689279242935664405256689); // vk.K[47].X
        mul_input[1] = uint256(21464993448394658273854216484684266808321160947909209851055873325887050492293); // vk.K[47].Y
        mul_input[2] = input[46];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[47] * input[46]
        mul_input[0] = uint256(14508762627123999549076601587501227009682636970076636367483491513461822793735); // vk.K[48].X
        mul_input[1] = uint256(13086806823222303647760776079580932758835172518633536905189386855031527005867); // vk.K[48].Y
        mul_input[2] = input[47];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[48] * input[47]
        mul_input[0] = uint256(19620443629871450449905318328661357670363144885276650727854684127004979439411); // vk.K[49].X
        mul_input[1] = uint256(13512145302109135260648622069026293634594965443783681487284540332451024150941); // vk.K[49].Y
        mul_input[2] = input[48];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[49] * input[48]
        mul_input[0] = uint256(20059550415468532205827328714175420183638104824341229821332085226225097782116); // vk.K[50].X
        mul_input[1] = uint256(12050042602361465175864197068892829808531398334073641526653775817012796904920); // vk.K[50].Y
        mul_input[2] = input[49];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[50] * input[49]
        mul_input[0] = uint256(13306511629433317473594641621219799176423215443967411203563081150777664297203); // vk.K[51].X
        mul_input[1] = uint256(675454852156663320769111000409074913392067853038809175892444203322319080285); // vk.K[51].Y
        mul_input[2] = input[50];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[51] * input[50]
        mul_input[0] = uint256(12076096047127155639652324319628370078197547570757038002713853288385847397853); // vk.K[52].X
        mul_input[1] = uint256(20063073818109035475283913336465472637670645911136973171672153316960017020047); // vk.K[52].Y
        mul_input[2] = input[51];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[52] * input[51]
        mul_input[0] = uint256(7070926176971266168429945375853092488155813841418560246899144119253540102350); // vk.K[53].X
        mul_input[1] = uint256(18608632252819735218114751983460803259577541150988320712643403458973379890618); // vk.K[53].Y
        mul_input[2] = input[52];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[53] * input[52]
        mul_input[0] = uint256(8787738969091605771927429510050738225462363969120867850034866515919420616153); // vk.K[54].X
        mul_input[1] = uint256(280860041417881042842953968111093793049575926737744905886029164850711931023); // vk.K[54].Y
        mul_input[2] = input[53];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[54] * input[53]
        mul_input[0] = uint256(17470729458746471811553625923859580633403777304482076029136929287269138561286); // vk.K[55].X
        mul_input[1] = uint256(11077695780520668039728878524992441159739768910332004302025495828550310823044); // vk.K[55].Y
        mul_input[2] = input[54];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[55] * input[54]
        mul_input[0] = uint256(18820732662126470829529155830450341599504017356119489964316929892787212659148); // vk.K[56].X
        mul_input[1] = uint256(18398462213470099652091858533789910876899706114418611429055433371437676169588); // vk.K[56].Y
        mul_input[2] = input[55];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[56] * input[55]
        mul_input[0] = uint256(10979958723839781582509983389549268556375745246890018812028152329350660809099); // vk.K[57].X
        mul_input[1] = uint256(8614377901484706884530978841565040782347190141813157341928120361805065861265); // vk.K[57].Y
        mul_input[2] = input[56];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[57] * input[56]
        if (commit[0] != 0 || commit[1] != 0) {
            vk_x = Pairing.plus(vk_x, proof.Commit);
        }

        return
            Pairing.pairing(Pairing.negate(proof.A), proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, proof.C, vk.delta2);
    }
}