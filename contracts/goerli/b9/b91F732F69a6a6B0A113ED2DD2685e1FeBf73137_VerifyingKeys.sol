// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./Transfer1In2Out24DepthVk.sol";
import "./Transfer2In2Out24DepthVk.sol";
import "./Transfer2In3Out24DepthVk.sol";
import "./Transfer3In3Out24DepthVk.sol";
import "./Mint1In2Out24DepthVk.sol";
import "./Freeze2In2Out24DepthVk.sol";
import "./Freeze3In3Out24DepthVk.sol";

library VerifyingKeys {
    function getVkById(uint256 encodedId)
        external
        pure
        returns (IPlonkVerifier.VerifyingKey memory)
    {
        if (encodedId == getEncodedId(0, 1, 2, 24)) {
            // transfer/burn-1-input-2-output-24-depth
            return Transfer1In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 2, 2, 24)) {
            // transfer/burn-2-input-2-output-24-depth
            return Transfer2In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 2, 3, 24)) {
            // transfer/burn-2-input-3-output-24-depth
            return Transfer2In3Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 3, 3, 24)) {
            // transfer/burn-3-input-3-output-24-depth
            return Transfer3In3Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(1, 1, 2, 24)) {
            // mint-1-input-2-output-24-depth
            return Mint1In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(2, 2, 2, 24)) {
            // freeze-2-input-2-output-24-depth
            return Freeze2In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(2, 3, 3, 24)) {
            // freeze-3-input-3-output-24-depth
            return Freeze3In3Out24DepthVk.getVk();
        } else {
            revert("Unknown vk ID");
        }
    }

    // returns (noteType, numInput, numOutput, treeDepth) as a 4*8 = 32 byte = uint256
    // as the encoded ID.
    function getEncodedId(
        uint8 noteType,
        uint8 numInput,
        uint8 numOutput,
        uint8 treeDepth
    ) public pure returns (uint256 encodedId) {
        assembly {
            encodedId := add(
                shl(24, noteType),
                add(shl(16, numInput), add(shl(8, numOutput), treeDepth))
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "../libraries/BN254.sol";

interface IPlonkVerifier {
    // Flatten out TurboPlonk proof
    struct PlonkProof {
        // the first 5 are 4 inputs and 1 output wire poly commmitments
        // i.e., batch_proof.wires_poly_comms_vec.iter()
        // wire0 is 32 bytes which is a pointer to BN254.G1Point
        BN254.G1Point wire0; // 0x00
        BN254.G1Point wire1; // 0x20
        BN254.G1Point wire2; // 0x40
        BN254.G1Point wire3; // 0x60
        BN254.G1Point wire4; // 0x80
        // the next one is the  product permutation poly commitment
        // i.e., batch_proof.prod_perm_poly_comms_vec.iter()
        BN254.G1Point prodPerm; // 0xA0
        // the next 5 are split quotient poly commmitments
        // i.e., batch_proof.split_quot_poly_comms
        BN254.G1Point split0; // 0xC0
        BN254.G1Point split1; // 0xE0
        BN254.G1Point split2; // 0x100
        BN254.G1Point split3; // 0x120
        BN254.G1Point split4; // 0x140
        // witness poly com for aggregated opening at `zeta`
        // i.e., batch_proof.opening_proof
        BN254.G1Point zeta; // 0x160
        // witness poly com for shifted opening at `zeta * \omega`
        // i.e., batch_proof.shifted_opening_proof
        BN254.G1Point zetaOmega; // 0x180
        // wire poly eval at `zeta`
        uint256 wireEval0; // 0x1A0
        uint256 wireEval1; // 0x1C0
        uint256 wireEval2; // 0x1E0
        uint256 wireEval3; // 0x200
        uint256 wireEval4; // 0x220
        // extended permutation (sigma) poly eval at `zeta`
        // last (sigmaEval4) is saved by Maller Optimization
        uint256 sigmaEval0; // 0x240
        uint256 sigmaEval1; // 0x260
        uint256 sigmaEval2; // 0x280
        uint256 sigmaEval3; // 0x2A0
        // product permutation poly eval at `zeta * \omega`
        uint256 prodPermZetaOmegaEval; // 0x2C0
    }

    // The verifying key for Plonk proofs.
    struct VerifyingKey {
        uint256 domainSize; // 0x00
        uint256 numInputs; // 0x20
        // commitment to extended perm (sigma) poly
        BN254.G1Point sigma0; // 0x40
        BN254.G1Point sigma1; // 0x60
        BN254.G1Point sigma2; // 0x80
        BN254.G1Point sigma3; // 0xA0
        BN254.G1Point sigma4; // 0xC0
        // commitment to selector poly
        // first 4 are linear combination selector
        BN254.G1Point q1; // 0xE0
        BN254.G1Point q2; // 0x100
        BN254.G1Point q3; // 0x120
        BN254.G1Point q4; // 0x140
        // multiplication selector for 1st, 2nd wire
        BN254.G1Point qM12; // 0x160
        // multiplication selector for 3rd, 4th wire
        BN254.G1Point qM34; // 0x180
        // output selector
        BN254.G1Point qO; // 0x1A0
        // constant term selector
        BN254.G1Point qC; // 0x1C0
        // rescue selector qH1 * w_ai^5
        BN254.G1Point qH1; // 0x1E0
        // rescue selector qH2 * w_bi^5
        BN254.G1Point qH2; // 0x200
        // rescue selector qH3 * w_ci^5
        BN254.G1Point qH3; // 0x220
        // rescue selector qH4 * w_di^5
        BN254.G1Point qH4; // 0x240
        // elliptic curve selector
        BN254.G1Point qEcc; // 0x260
    }

    /// @dev Batch verify multiple TurboPlonk proofs.
    /// @param verifyingKeys An array of verifying keys
    /// @param publicInputs A two-dimensional array of public inputs.
    /// @param proofs An array of Plonk proofs
    /// @param extraTranscriptInitMsgs An array of bytes from
    /// transcript initialization messages
    /// @return _ A boolean that is true for successful verification, false otherwise
    function batchVerify(
        VerifyingKey[] memory verifyingKeys,
        uint256[][] memory publicInputs,
        PlonkProof[] memory proofs,
        bytes[] memory extraTranscriptInitMsgs
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer1In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 14)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                6451930258054036397165544866644311272180786776693649154889113517935138989324
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15824498031290932840309269587075035510403426361110328301862825820425402064333
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                16567945706248183214406921539823721483157024902030706018155219832331943151521
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                14506648136467119081958160505454685757895812203258866143116417397069305366174
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                16908805137848644970538829805684573945187052776129406508429516788865993229946
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                13370902069114408370627021011309095482019563080650295231694581484651030202227
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                11385428061273012554614867838291301202096376350855764984558871671579621291507
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                18938480909096008246537758317235530495583632544865390355616243879170108311037
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                7250836052061444170671162428779548720754588271620290284029438087321333136859
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                9774478170511284714380468511107372909275276960243638784016266344709965751507
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                2164661706057106993702119971892524764909406587180616475316536801798272746351
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                7993083931046493938644389635874939373576598203553188654440768055247347522377
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                17875027092910639802264620931724329796279457509298747494670931666396434012177
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                12276180841132702377773827582398158204508221552359644390751974783173207949116
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                6923045257159434019788850173231395134054684072354814328515094196682490129996
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                10297389981574891432841377306749459633586002482842974197875786670892058142179
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                13566140293342467207563198706820126266175769850278450464476746689910443370750
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                4337013617009771491102950113766314929630396941539697665107262932887431611820
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                19545356440018631139549838928930231615194677294299230322568967706100221743452
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                3905268653568739552774781017975590296651581349403516285498718251384231803637
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                3633513776458243190609011598510312470369153119749343878250857605063953894824
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                10348854780537633653024803962077925757963724802390956695225993897601858375068
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                10515123958235902109894586452633863486298290064878690665500349352367945576213
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                20835963785046732330293306231553834880816750576829504030205004088050809531737
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                10349250837084111252673833558497412287345352572732754388450385078539897036072
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                1295954576893766564415821998145161393110346678014886452040838119568563355556
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                18595738613642013642528283665640490180800278502934355301953048187579782737773
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                5708601727819525671780050950771464619626673626810479676243974296923430650735
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                8105844768413379370590866345497514518639783589779028631263566798017351944465
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                13767799708582015119198203890136804463714948257729839866946279972890684141171
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                13976995316216184532948677497270469464100744949177652840098916826286666391978
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                8782060747227562892357029272916715317651514559557103332761644499318601665300
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                10423258206189675762927713311069351374538317153673220039972782365668263479097
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                12712089727236847935392559371166622501626155101609755726562266635070650647609
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                3447947975392962233948092031223758925923495365282112464857270024948603045088
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                4655198050073279486560411245172865913095816956325221266986314415391129730949
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer2In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 27)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                2353344940323935826134936223947938042521909475033774928828281661731550798722
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                9746655158250922067275109215926891774244956160343543537816404835253168644024
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                15455409296542685326830249024223724266624290984578410657713086954481835262616
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                18311379816054123251097409624258299432408683566103718315014121691958807960547
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                3595102568308999621710931895728700858137670894580826466196432246884451756647
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                5971868016111020985417776938700261612639243638290968867440360355753182506016
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                12443289603239702012200478229424802817855243081906319312702825218898138895946
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                14108881420049829870828878537593066975275378607590487898362908473190089969939
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                19679657199741651524390089978450662678686454680964744364368691879627016432652
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                17114067594856558864780849616452660298251042000563020846487894545389438664806
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                4521205613646422234630873762189179209607994647697100090154823061235920789353
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                16106449496625400183304424755719536524421029289605758534728292280016648447637
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                15558337488326969806891656016031810341177100586194811207644366322955582958290
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                154404024660163916069895563430486111291743096749375581648108814279740019496
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                10968315091130697826739702003431871061194509005508422925553623050382577326217
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                15427520064071248215056685014173235486104450904391795026852773491856938894709
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                18552120566932429867086353275996329695634259700395564758868503989836119743976
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                3758067104786429430903075307629079520236919298153864746942709833835554967358
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                15572105585408879365916525794377657194208962207139936775774251314043834098564
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                6020958592977720912767721649577520866900127639444801108025166566775601659967
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                7222736374399006211510699304087942059126683193629769887877014686905908945806
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                3206829195840321731462512861208486643839466222481973961857037286401683735687
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                3354591448826521438380040598853232839565248677422944332090180952953080366288
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                19963668090281374431317017250026510351550118984869870738585126468447913244591
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                17974807300702948996049252322259229942746003444136224778640009295566243156501
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                12052046477897583522878740699736101759681160588792932192885758224246430725626
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                4921034593166626300651198249205635549101612701433540517476055976860959484949
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                10185405862489710856496932329182422458788356942668474473592359869600739434412
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                5878093886505576171449048465070377785955067968838740459103515014923390639639
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                15259888626953734049577795735967576333281508824947666542918638019623811781546
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                19643669610230135658961129468905806322162637394453939877922249528939594418232
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                12224852444220822793589818921506014057813793178254991680570188956045824616826
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                6641963433101155753834035944397107424954075034582038862756599997819459513127
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                3589782713125700501109156506560851754947305163593203470270968608024453926281
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                12330486534063835148740124350008103247243211222952306312071501975705307117092
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                20509504091296584456523257770792088853619865130173628006197630419037120651742
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer2In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 32)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                11238918059962060895836660665905685183821438171673788872298187887301460117949
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                10312536098428436059770058647883007948230826032311055958980103002216444398029
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                3069296210454062532812049058888182398466997742713116483712055777740542557095
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                10585452901889142818220136732592206035573929406563129602198941778025261934559
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                49796010413150322443747223871067686918728570624660232645490911700120682624
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                19418979289570937603858876101332413214999751685423780259104815571219376501897
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                5017549683124968830897329522528615084825569869584518140023215913256996665369
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                6904459746270415738591583761210331008369254540754508554401155557939093240173
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                15294346261666962115813163162624127728984137808463913539428567756274357657589
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                6335459220235140110171052568798094575702073047123843498885605762024671566976
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3447729854865352811909348476580581256116229886577313169808953699321178547567
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                10391923178665150678480226437763860904879593811452327022884721625331046561649
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                21331037483834702908326522885638199264097608653827628146912836859219217391521
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                17700979571500030343918100715185217716266526246917146097813330984808052588149
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                19231315187566819499805706567670055518295048760424962411545826184537652443122
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                1786951957014031658307434161704132339929023647859863721152324287915947831283
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                891318259297166657950777135402426115367536796891436125685210585889035809375
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                19080042747384460176894767057995469942920956949014313980914237214240134307208
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                8600864573298799022763786653218006387353791810267845686055695121259061041328
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                16693779427169671344028720673356223282089909563990595319572224701304611776922
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                9157681660736307225301034938839156685740016704526090406950858434609030225480
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                8030757918449598333025173041225419314601924784825356372892442933863889091921
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                13640927194155719878577037989318164230713264172921393074620679102349279698839
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                6900604409783116559678606532527525488965021296050678826316410961047810748517
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                5252746067177671060986834545182465389119363624955154280966570801582394785840
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                9195131821976884258765963928166452788332100806625752840914173681395711439614
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                14977645969508065057243931947507598769856801213808952261859994787935726005589
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                5096294777527669951530261927053173270421982090354495165464932330992574194565
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                3545567189598828405425832938456307851398759232755240447556204001745014820301
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                1941523779920680020402590579224743136261147114116204389037553310789640138016
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                18752226702425153987309996103585848095327330331398325134534482624274124156372
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                11041340585339071070596363521057299677913989755036511157364732122494432877984
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                14590850366538565268612154711126247437677807588903705071677135475079401886274
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                18590050088847501728340953044790139366495591524471631048198965975345765148219
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                21704590671982347430816904792389667189857927953663414983186296915645026530922
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                20891693206558394293557033642999941159043782671912221870570329299710569824990
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer3In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 65536)
            // num of public inputs
            mstore(add(vk, 0x20), 45)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                6745569324574292840123998773726184666805725845966057344477780763812378175216
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15674359264100532117390420549335759541287602785521062799291583384533749901741
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                3882047939060472482494153851462770573213675187290765799393847015027127043523
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                7630821036627726874781987389422412327209162597154025595018731571961516169947
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                21225224708013383300469954369858606000505504678178518510917526718672976749965
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                16365929799382131762072204211493784381011606251973921052275294268694891754790
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                18816028553810513067728270242942259651783354986329945635353859047149476279687
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                11882680851945303658063593837716037756293837416752296611477056121789431777064
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                21510097154791711734296287821852281209791416779989865544015434367940075374914
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                3430102751397774877173034066414871678821827985103146314887340992082993984329
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                19869597504326919094166107694290620558808748604476313005465666228287903414344
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                7150111322568846997819037419437132637225578315562663408823282538527304893394
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                15160992848460929858090744745540508270198264712727437471403260552347088002356
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                14658479685250391207452586531545916785099257310771621120220342224985727703397
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                8235204123369855002620633544318875073465201482729570929826842086900101734240
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                1315782571791013709741742522230010040948540142932666264718230624795003912658
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                7021080634443416008459948952678027962506306501245829421538884411847588184010
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                6584493294015254847476792897094566004873857428175399671267891995703671301938
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                19199743165408884046745846028664619315169170959180153012829728401858950581623
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                14838749009602762930836652487207610572239367359059811743491751753845995666312
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                10248259393969855960972127876087560001222739594880062140977367664638629457979
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                3405469462517204071666729973707416410254082166076974198995581327928518673875
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                9259807925511910228709408577417518144465439748546649497440413244416264053909
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                4349742126987923639436565898601499377373071260693932114899380098788981806520
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                195924708408078159303893377539882303047203274957430754688974876101940076523
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                2730242103617344574903225508726280194241425124842703262405260488972083367491
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                20219387287202350426068670038890996732790822982376234641416083193417653609683
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                4712902992473903996354956065401616044154872569903741964754702810524685939510
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                20606018511516306199576247848201856706631620007530428100607004704631466340548
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                3431535724436156106895017518971445784357440465218022981124980111332355382620
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                16926802729258759088538388518776752987858809292908095720269836387951179849328
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                17982233223518308144739071673627895392237126231063756253762501987899411496611
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                2769108222659962988853179530681878069454558991374977224908414446449310780711
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                1229799452453481995415811771099188864368739763357472273935665649735041438448
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                4813470345909172814186147928188285492437945113396806975178500704379725081570
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                5911983361843136694947821727682990071782684402361679071602671084421707986423
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Mint1In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 16384)
            // num of public inputs
            mstore(add(vk, 0x20), 22)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                18715857233450097233566665862469612667705408112918632327151254517366615510853
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                12056659507165533739511169991607046566607546589228993432633519678105063191994
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                14824195002671574468331715635494727121571793218927771429557442195822888294112
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15545363005844852395434066542267547241977074468438704526560481952507920680442
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                12730937992652390663908670084945912580250489721157445258662047611384656062589
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                13922972325643955705903067190275250069235823502347080251607855678412413832655
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                11205515283341717493374802581094446196264159623530455592177314841729924213298
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                21626228139140341994554265888140425084500331880890693761295353772893134873176
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                1297892505212470170669591175924901147071008882331974691087297632739019966869
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                5046998337256619649328073625306172605427225136111531257681027197976756517579
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3416126502361838053757816729968531801453964981226124461039874315717193603949
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                13457539169423794765649307630863376252412201646715715024708233511728175887361
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                14560725448400229197269899568322480538530865768296597131421754928016376186765
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                948706310326485520368947730671484733882983133515374382612890953953178516965
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                3629576662585230443325226017156907801568659344982452092584030101519414013585
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                11755059153403672321764085695058203755528587063932979109812536973510125660021
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                11004655709419206490244680738164512138236779409731663166100876015592834374329
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                3075086625849477481019461602494583874758896233088021555313650923393327170396
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                5116214943488395672472205024247672892505731883467355177124324350502474270399
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                5862627121952215177093377764664762757373132220173512585597211838016077936314
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                17591159830764396623974345916017368127032492198578190405514161605820133619635
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                21823861194811124564815272373053730365073236057851878678286985577859771922838
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                4270340305067371269951830198578603793146745643909898988425564374444309637164
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                3429516859933338020020014748205944416226065682096817012737681215798779959358
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                18140449432973717159678873762584078749849242918610972566667541337332136871548
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                9496973080403650076452512345486781056144944295333639818676842964799046293494
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                2679601553769052076036509170798838073426403353317218807312666276919478214029
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                8104020893469546307958011379600482565107943832349081304458473817724197756534
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                15359849857211682094089890949757251089555853826462724721381029431330976452771
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                16491566299722544741678927866350154870498939946959249271831955257228312538659
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                12100931690223724084472313998885551549102209045806672061992493151022394323721
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                789632069622495739311692844331711309820973570859008137449744966665497183364
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                9372499437356245507830218065264333778849228240985893278867565670067559001476
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                5071314442263159884139201702429590502916613589463313571011317767821015131114
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                13714688610643446356217590887080562811494820054657712165894734861828853586333
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                1823119861575201921550763026703044012616621870847156108104965194178825195245
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Freeze2In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 7)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                5118137774697846205332813764527928981094534629179826197661885163309718792664
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                21444510867008360096097791654924066970628086592132286765149218644570218218958
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                8803078987858664729272498900762799875194584982758288268215987493230494163132
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                2433303804972293717223914306424233027859258355453999879123493306111951897773
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                3260803333275595200572169884988811547059839215101652317716205725226978273005
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                3613466037895382109608881276133312019690204476510004381563636709063308697093
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                2899439069156777615431510251772750434873724497570948892914993632800602868003
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                8379069052308825781842073463279139505822176676050290986587894691217284563176
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                11732815069861807091165298838511758216456754114248634732985660813617441774658
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                13166648630773672378735632573860809427570624939066078822309995911184719468349
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3491113372305405096734724369052497193940883294098266073462122391919346338715
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                9827940866231584614489847721346069816554104560301469101889136447541239075558
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                13435736629650136340196094187820825115318808951343660439499146542480924445056
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                17982003639419860944219119425071532203644939147988825284644182004036282633420
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9420441314344923881108805693844267870391289724837370305813596950535269618889
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                14052028114719021167053334693322209909986772869796949309216011765205181071250
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                5993794253539477186956400554691260472169114800994727061541419240125118730670
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                7932960467420473760327919608797843731121974235494949218022535850994096308221
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                20429406452243707916630058273965650451352739230543746812138739882954609124362
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                19692763177526054221606086118119451355223254880919552106296824049356634107628
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                5116116081275540865026368436909879211124168610156815899416152073819842308833
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                19842614482623746480218449373220727139999815807703100436601033251034509288020
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                3222495709067365879961349438698872943831082393186134710609177690951286365439
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                3703532585269560394637679600890000571417416525562741673639173852507841008896
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                14390471925844384916287376853753782482889671388409569687933776522892272411453
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                12261059506574689542871751331715340905672203590996080541963527436628201655551
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                212133813390818941086614328570019936880884093617125797928913969643819686094
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                2058275687345409085609950154451527352761528547310163982911053914079075244754
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                7507728187668840967683000771945777493711131652056583548804845913578647015848
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                15764897865018924692970368330703479768257677759902236501992745661340099646248
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                18302496468173370667823199324779836313672317342261283918121073083547306893947
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                8286815911028648157724790867291052312955947067988434001008620797971639607610
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                3470304694844212768511296992238419575123994956442939632524758781128057967608
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                9660892985889164184033149081062412611630238705975373538019042544308335432760
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                2964316839877400858567376484261923751031240259689039666960763176068018735519
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                12811532772714855857084788747474913882317963037829729036129619334772557515102
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Freeze3In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 9)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                13960731824189571867091334541157339805012676983241098249236778497915465352053
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15957967148909612161116218663566087497068811688498797226467515095325657152045
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                10072587287838607559866316765624459623039578259829899225485734337870604479821
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15609102652788964903340031795269302405421393375766454476378251576322947285858
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                6565707169634610873662073730120423414251877113110818166564470784428289496576
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                9611712776953584296612678707999788907754017999002246476393974258810867124564
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                19122400063214294010991425447556532201595762243736666161415050184531098654161
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                8531074110951311734071734321378003618052738734286317677359289798683215129985
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                18914674706112982859579196036464470962561796494057486369943014188445892675591
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                8521550178820292984099911306615540388090622911114862049753515592863829430736
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                14630335835391046544786473024276900306274085179180854494149987003151236405693
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                11927636740621831793456799535735389934490350641107279163802406976389995490906
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                12724914112829888521503996001370933887413324349676112061904353298191125761834
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                3433370683786676509006167821257247081483834358490691629467376279251656650897
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9566744544381523978155846140753126684369534823789897373672815695046810310988
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                260017699035964770662690666115311602214922546306804012310168827438556483441
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                18742890127040989288898023133652949889864689947035150783791742574000686319400
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                18749161983189150319356152659011703669863797011859087161475368338926038180308
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                20773233313791930222139945008080890514898946888819625041024291924369611870607
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                13521724424975535658347353167027580945107539483287924982357298371687877483981
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                10660982607928179139814177842882617778440401746692506684983260589289268170379
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                15139413484465466645149010003574654339361200137557967877891360282092282891685
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                17250558007005834955604250406579207360748810924758511953913092810009135851470
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11258418978437321501318046240697776859180107275977030400553604411488978149668
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                18952078950487788846193130112459018587473354670050028821020889375362878213321
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                17193026626593699161155564126784943150078109362562131961513990003707313130311
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                14543481681504505345294846715453463092188884601462120536722150134676588633429
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                18051927297986484527611703191585266713528321784715802343699150271856051244721
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                17183091890960203175777065490726876011944304977299231686457191186480347944964
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                4490401529426574565331238171714181866458606184922225399124187058005801778892
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                1221754396433704762941109064372027557900417150628742839724350141274324105531
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                5852202975250895807153833762470523277935452126865915206223172229093142057204
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                15942219407079940317108327336758085920828255563342347502490598820248118460133
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                13932908789216121516788648116401360726086794781411868046768741292235436938527
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                11253921189643581015308547816247612243572238063440388125238308675751100437670
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                21538818198962061056994656088458979220103547193654086011201760604068846580076
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

//
// Based on:
// - Christian Reitwiessner: https://gist.githubusercontent.com/chriseth/f9be9d9391efc5beb9704255a8e2989d/raw/4d0fb90847df1d4e04d507019031888df8372239/snarktest.solidity
// - Aztec: https://github.com/AztecProtocol/aztec-2-bug-bounty

pragma solidity ^0.8.0;

import "./Utils.sol";

/// @notice Barreto-Naehrig curve over a 254 bit prime field
library BN254 {
    // use notation from https://datatracker.ietf.org/doc/draft-irtf-cfrg-pairing-friendly-curves/
    //
    // Elliptic curve is defined over a prime field GF(p), with embedding degree k.
    // Short Weierstrass (SW form) is, for a, b \in GF(p^n) for some natural number n > 0:
    //   E: y^2 = x^3 + a * x + b
    //
    // Pairing is defined over cyclic subgroups G1, G2, both of which are of order r.
    // G1 is a subgroup of E(GF(p)), G2 is a subgroup of E(GF(p^k)).
    //
    // BN family are parameterized curves with well-chosen t,
    //   p = 36 * t^4 + 36 * t^3 + 24 * t^2 + 6 * t + 1
    //   r = 36 * t^4 + 36 * t^3 + 18 * t^2 + 6 * t + 1
    // for some integer t.
    // E has the equation:
    //   E: y^2 = x^3 + b
    // where b is a primitive element of multiplicative group (GF(p))^* of order (p-1).
    // A pairing e is defined by taking G1 as a subgroup of E(GF(p)) of order r,
    // G2 as a subgroup of E'(GF(p^2)),
    // and G_T as a subgroup of a multiplicative group (GF(p^12))^* of order r.
    //
    // BN254 is defined over a 254-bit prime order p, embedding degree k = 12.
    uint256 public constant P_MOD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 public constant R_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fp2 = x0 * z + x1
    struct G2Point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    /// @return the generator of G1
    // solhint-disable-next-line func-name-mixedcase
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    // solhint-disable-next-line func-name-mixedcase
    function P2() internal pure returns (G2Point memory) {
        return
            G2Point({
                x0: 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                x1: 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed,
                y0: 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                y1: 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            });
    }

    /// @dev check if a G1 point is Infinity
    /// @notice precompile bn256Add at address(6) takes (0, 0) as Point of Infinity,
    /// some crypto libraries (such as arkwork) uses a boolean flag to mark PoI, and
    /// just use (0, 1) as affine coordinates (not on curve) to represents PoI.
    function isInfinity(G1Point memory point) internal pure returns (bool result) {
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))
            result := and(iszero(x), iszero(y))
        }
    }

    /// @return r the negation of p, i.e. p.add(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        if (isInfinity(p)) {
            return p;
        }
        return G1Point(p.x, P_MOD - (p.y % P_MOD));
    }

    /// @return res = -fr the negation of scalar field element.
    function negate(uint256 fr) internal pure returns (uint256 res) {
        return R_MOD - (fr % R_MOD);
    }

    /// @return r the sum of two points of G1
    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(0, 0)
            }
        }
        require(success, "Bn254: group addition failed!");
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.mul(1) and p.add(p) == p.mul(2) for all points p.
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(0, 0)
            }
        }
        require(success, "Bn254: scalar mul failed!");
    }

    /// @dev Multi-scalar Mulitiplication (MSM)
    /// @return r = \Prod{B_i^s_i} where {s_i} are `scalars` and {B_i} are `bases`
    function multiScalarMul(G1Point[] memory bases, uint256[] memory scalars)
        internal
        view
        returns (G1Point memory r)
    {
        require(scalars.length == bases.length, "MSM error: length does not match");

        r = scalarMul(bases[0], scalars[0]);
        for (uint256 i = 1; i < scalars.length; i++) {
            r = add(r, scalarMul(bases[i], scalars[i]));
        }
    }

    /// @dev Compute f^-1 for f \in Fr scalar field
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function invert(uint256 fr) internal view returns (uint256 output) {
        bool success;
        uint256 p = R_MOD;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), fr)
            mstore(add(mPtr, 0x80), sub(p, 2))
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            output := mload(0x00)
        }
        require(success, "Bn254: pow precompile failed!");
    }

    /**
     * validate the following:
     *   x != 0
     *   y != 0
     *   x < p
     *   y < p
     *   y^2 = x^3 + 3 mod p
     */
    /// @dev validate G1 point and check if it is on curve
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function validateG1Point(G1Point memory point) internal pure {
        bool isWellFormed;
        uint256 p = P_MOD;
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))

            isWellFormed := and(
                and(and(lt(x, p), lt(y, p)), not(or(iszero(x), iszero(y)))),
                eq(mulmod(y, y, p), addmod(mulmod(x, mulmod(x, x, p), p), 3, p))
            )
        }
        require(isWellFormed, "Bn254: invalid G1 point");
    }

    /// @dev Validate scalar field, revert if invalid (namely if fr > r_mod).
    /// @notice Writing this inline instead of calling it might save gas.
    function validateScalarField(uint256 fr) internal pure {
        bool isValid;
        assembly {
            isValid := lt(fr, R_MOD)
        }
        require(isValid, "Bn254: invalid scalar field");
    }

    /// @dev Evaluate the following pairing product:
    /// @dev e(a1, a2).e(-b1, b2) == 1
    /// @dev caller needs to ensure that a1, a2, b1 and b2 are within proper group
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        uint256 out;
        bool success;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, mload(a1))
            mstore(add(mPtr, 0x20), mload(add(a1, 0x20)))
            mstore(add(mPtr, 0x40), mload(a2))
            mstore(add(mPtr, 0x60), mload(add(a2, 0x20)))
            mstore(add(mPtr, 0x80), mload(add(a2, 0x40)))
            mstore(add(mPtr, 0xa0), mload(add(a2, 0x60)))

            mstore(add(mPtr, 0xc0), mload(b1))
            mstore(add(mPtr, 0xe0), mload(add(b1, 0x20)))
            mstore(add(mPtr, 0x100), mload(b2))
            mstore(add(mPtr, 0x120), mload(add(b2, 0x20)))
            mstore(add(mPtr, 0x140), mload(add(b2, 0x40)))
            mstore(add(mPtr, 0x160), mload(add(b2, 0x60)))
            success := staticcall(gas(), 8, mPtr, 0x180, 0x00, 0x20)
            out := mload(0x00)
        }
        require(success, "Bn254: Pairing check failed!");
        return (out != 0);
    }

    function fromLeBytesModOrder(bytes memory leBytes) internal pure returns (uint256 ret) {
        for (uint256 i = 0; i < leBytes.length; i++) {
            ret = mulmod(ret, 256, R_MOD);
            ret = addmod(ret, uint256(uint8(leBytes[leBytes.length - 1 - i])), R_MOD);
        }
    }

    /// @dev Check if y-coordinate of G1 point is negative.
    function isYNegative(G1Point memory point) internal pure returns (bool) {
        return (point.y << 1) < P_MOD;
    }

    // @dev Perform a modular exponentiation.
    // @return base^exponent (mod modulus)
    // This method is ideal for small exponents (~64 bits or less), as it is cheaper than using the pow precompile
    // @notice credit: credit: Aztec, Spilsbury Holdings Ltd
    function powSmall(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 input = base;
        uint256 count = 1;

        assembly {
            let endpoint := add(exponent, 0x01)
            for {

            } lt(count, endpoint) {
                count := add(count, count)
            } {
                if and(exponent, count) {
                    result := mulmod(result, input, modulus)
                }
                input := mulmod(input, input, modulus)
            }
        }

        return result;
    }

    function g1Serialize(G1Point memory point) internal pure returns (bytes memory) {
        uint256 mask = 0;

        // Set the 254-th bit to 1 for infinity
        // https://docs.rs/ark-serialize/0.3.0/src/ark_serialize/flags.rs.html#117
        if (isInfinity(point)) {
            mask |= 0x4000000000000000000000000000000000000000000000000000000000000000;
        }

        // Set the 255-th bit to 1 for positive Y
        // https://docs.rs/ark-serialize/0.3.0/src/ark_serialize/flags.rs.html#118
        if (!isYNegative(point)) {
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
        }

        return abi.encodePacked(Utils.reverseEndianness(point.x | mask));
    }

    function g1Deserialize(bytes32 input) internal view returns (G1Point memory point) {
        uint256 mask = 0x4000000000000000000000000000000000000000000000000000000000000000;
        uint256 x = Utils.reverseEndianness(uint256(input));
        uint256 y;
        bool isQuadraticResidue;
        bool isYPositive;
        if (x & mask != 0) {
            // the 254-th bit == 1 for infinity
            x = 0;
            y = 0;
        } else {
            // Set the 255-th bit to 1 for positive Y
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
            isYPositive = (x & mask != 0);
            // mask off the first two bits of x
            mask = 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            x &= mask;

            // solve for y where E: y^2 = x^3 + 3
            y = mulmod(x, x, P_MOD);
            y = mulmod(y, x, P_MOD);
            y = addmod(y, 3, P_MOD);
            (isQuadraticResidue, y) = quadraticResidue(y);

            require(isQuadraticResidue, "deser fail: not on curve");

            if (isYPositive) {
                y = P_MOD - y;
            }
        }

        point = G1Point(x, y);
    }

    function quadraticResidue(uint256 x)
        internal
        view
        returns (bool isQuadraticResidue, uint256 a)
    {
        bool success;
        // e = (p+1)/4
        uint256 e = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;
        uint256 p = P_MOD;

        // we have p == 3 mod 4 therefore
        // a = x^((p+1)/4)
        assembly {
            // credit: Aztec
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), x)
            mstore(add(mPtr, 0x80), e)
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            a := mload(0x00)
        }
        require(success, "pow precompile call failed!");

        // ensure a < p/2
        if (a << 1 > p) {
            a = p - a;
        }

        // check if a^2 = x, if not x is not a quadratic residue
        e = mulmod(a, a, p);

        isQuadraticResidue = (e == x);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library Utils {
    function reverseEndianness(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v =
            ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v =
            ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v =
            ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v =
            ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }
}