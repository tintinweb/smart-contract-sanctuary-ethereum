pragma solidity 0.8.16;

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

library SSZ {
    uint256 internal constant HISTORICAL_ROOTS_LIMIT = 16777216;
    uint256 internal constant SLOTS_PER_HISTORICAL_ROOT = 8192;

    function toLittleEndian(uint256 v) internal pure returns (bytes32) {
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        v = (v >> 128) | (v << 128);
        return bytes32(v);
    }

    function restoreMerkleRoot(bytes32 leaf, uint256 index, bytes32[] memory branch)
        internal
        pure
        returns (bytes32)
    {
        require(2 ** (branch.length + 1) > index);
        bytes32 value = leaf;
        uint256 i = 0;
        while (index != 1) {
            if (index % 2 == 1) {
                value = sha256(bytes.concat(branch[i], value));
            } else {
                value = sha256(bytes.concat(value, branch[i]));
            }
            index /= 2;
            i++;
        }
        return value;
    }

    function isValidMerkleBranch(bytes32 leaf, uint256 index, bytes32[] memory branch, bytes32 root)
        internal
        pure
        returns (bool)
    {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

    function sszBeaconBlockHeader(BeaconBlockHeader memory header)
        internal
        pure
        returns (bytes32)
    {
        bytes32 left = sha256(
            bytes.concat(
                sha256(
                    bytes.concat(toLittleEndian(header.slot), toLittleEndian(header.proposerIndex))
                ),
                sha256(bytes.concat(header.parentRoot, header.stateRoot))
            )
        );
        bytes32 right = sha256(
            bytes.concat(
                sha256(bytes.concat(header.bodyRoot, bytes32(0))),
                sha256(bytes.concat(bytes32(0), bytes32(0)))
            )
        );

        return sha256(bytes.concat(left, right));
    }

    function computeDomain(bytes4 forkVersion, bytes32 genesisValidatorsRoot)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(uint256(0x07 << 248))
            | (sha256(abi.encode(forkVersion, genesisValidatorsRoot)) >> 32);
    }

    function verifyReceiptsRoot(
        bytes32 receiptsRoot,
        bytes32[] memory receiptsRootProof,
        bytes32 headerRoot,
        uint64 srcSlot,
        uint64 txSlot
    ) internal pure returns (bool) {
        uint256 index;
        if (srcSlot == txSlot) {
            index = 8 + 3;
            index = index * 2 ** 9 + 387;
        } else if (srcSlot - txSlot <= SLOTS_PER_HISTORICAL_ROOT) {
            index = 8 + 3;
            index = index * 2 ** 5 + 6;
            index = index * SLOTS_PER_HISTORICAL_ROOT + txSlot % SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 ** 9 + 387;
        } else if (txSlot < srcSlot) {
            index = 8 + 3;
            index = index * 2 ** 5 + 7;
            index = index * 2 + 0;
            index = index * HISTORICAL_ROOTS_LIMIT + txSlot / SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 + 1;
            index = index * SLOTS_PER_HISTORICAL_ROOT + txSlot % SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 ** 9 + 387;
        } else {
            revert("TrustlessAMB: invalid target slot");
        }
        return isValidMerkleBranch(receiptsRoot, index, receiptsRootProof, headerRoot);
    }
}

pragma solidity 0.8.16;

import {SSZ} from "src/libraries/SimpleSerialize.sol";

import {ILightClient} from "./interfaces/ILightClient.sol";
import {StepVerifier} from "./StepVerifier.sol";
import {RotateVerifier} from "./RotateVerifier.sol";

struct Groth16Proof {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
}

struct LightClientStep {
    uint256 attestedSlot;
    uint256 finalizedSlot;
    uint256 participation;
    bytes32 finalizedHeaderRoot;
    bytes32 executionStateRoot;
    Groth16Proof proof;
}

struct LightClientRotate {
    LightClientStep step;
    bytes32 syncCommitteeSSZ;
    bytes32 syncCommitteePoseidon;
    Groth16Proof proof;
}

/// @title Light Client
/// @author Succinct Labs
/// @notice Uses Ethereum 2's Sync Committee Protocol to keep up-to-date with block headers from a
///         Beacon Chain. This is done in a gas-efficient manner using zero-knowledge proofs.
contract LightClient is ILightClient, StepVerifier, RotateVerifier {
    bytes32 public immutable GENESIS_VALIDATORS_ROOT;
    uint256 public immutable GENESIS_TIME;
    uint256 public immutable SECONDS_PER_SLOT;
    uint256 public immutable SLOTS_PER_PERIOD;
    uint32 public immutable SOURCE_CHAIN_ID;
    uint16 public immutable FINALITY_THRESHOLD;

    uint256 internal constant MIN_SYNC_COMMITTEE_PARTICIPANTS = 10;
    uint256 internal constant SYNC_COMMITTEE_SIZE = 512;
    uint256 internal constant FINALIZED_ROOT_INDEX = 105;
    uint256 internal constant NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint256 internal constant EXECUTION_STATE_ROOT_INDEX = 402;

    /// @notice Whether the light client has had conflicting variables for the same slot.
    bool public consistent = true;

    /// @notice The latest slot the light client has a finalized header for.
    uint256 public head = 0;

    /// @notice Maps from a slot to a beacon block header root.
    mapping(uint256 => bytes32) public headers;

    /// @notice Maps from a slot to the timestamp of when the headers mapping was updated with slot as a key
    mapping(uint256 => uint256) public timestamps;

    /// @notice Maps from a slot to the current finalized ethereum1 execution state root.
    mapping(uint256 => bytes32) public executionStateRoots;

    /// @notice Maps from a period to the poseidon commitment for the sync committee.
    mapping(uint256 => bytes32) public syncCommitteePoseidons;

    event HeadUpdate(uint256 indexed slot, bytes32 indexed root);
    event SyncCommitteeUpdate(uint256 indexed period, bytes32 indexed root);

    constructor(
        bytes32 genesisValidatorsRoot,
        uint256 genesisTime,
        uint256 secondsPerSlot,
        uint256 slotsPerPeriod,
        uint256 syncCommitteePeriod,
        bytes32 syncCommitteePoseidon,
        uint32 sourceChainId,
        uint16 finalityThreshold
    ) {
        GENESIS_VALIDATORS_ROOT = genesisValidatorsRoot;
        GENESIS_TIME = genesisTime;
        SECONDS_PER_SLOT = secondsPerSlot;
        SLOTS_PER_PERIOD = slotsPerPeriod;
        SOURCE_CHAIN_ID = sourceChainId;
        FINALITY_THRESHOLD = finalityThreshold;
        setSyncCommitteePoseidon(syncCommitteePeriod, syncCommitteePoseidon);
    }

    /// @notice Updates the head of the light client to the provided slot.
    /// @dev The conditions for updating the head of the light client involve checking:
    ///      1) Enough signatures from the current sync committee for n=512
    ///      2) A valid finality proof
    ///      3) A valid execution state root proof
    function step(LightClientStep memory update) external {
        bool finalized = processStep(update);

        if (getCurrentSlot() < update.attestedSlot) {
            revert("Update slot is too far in the future");
        }

        if (finalized) {
            setHead(update.finalizedSlot, update.finalizedHeaderRoot);
            setExecutionStateRoot(update.finalizedSlot, update.executionStateRoot);
            setTimestamp(update.finalizedSlot, block.timestamp);
        } else {
            revert("Not enough participants");
        }
    }

    /// @notice Sets the sync committee for the next sync committeee period.
    /// @dev A commitment to the the next sync committeee is signed by the current sync committee.
    function rotate(LightClientRotate memory update) external {
        LightClientStep memory stepUpdate = update.step;
        bool finalized = processStep(update.step);
        uint256 currentPeriod = getSyncCommitteePeriod(stepUpdate.finalizedSlot);
        uint256 nextPeriod = currentPeriod + 1;

        zkLightClientRotate(update);

        if (finalized) {
            setSyncCommitteePoseidon(nextPeriod, update.syncCommitteePoseidon);
        }
    }

    /// @notice Verifies that the header has enough signatures for finality.
    function processStep(LightClientStep memory update) internal view returns (bool) {
        uint256 currentPeriod = getSyncCommitteePeriod(update.attestedSlot);

        if (syncCommitteePoseidons[currentPeriod] == 0) {
            revert("Sync committee for current period is not initialized.");
        } else if (update.participation < MIN_SYNC_COMMITTEE_PARTICIPANTS) {
            revert("Less than MIN_SYNC_COMMITTEE_PARTICIPANTS signed.");
        }

        zkLightClientStep(update);

        return update.participation > FINALITY_THRESHOLD;
    }

    /// @notice Serializes the public inputs into a compressed form and verifies the step proof.
    function zkLightClientStep(LightClientStep memory update) internal view {
        bytes32 attestedSlotLE = SSZ.toLittleEndian(update.attestedSlot);
        bytes32 finalizedSlotLE = SSZ.toLittleEndian(update.finalizedSlot);
        bytes32 participationLE = SSZ.toLittleEndian(update.participation);
        uint256 currentPeriod = getSyncCommitteePeriod(update.attestedSlot);
        bytes32 syncCommitteePoseidon = syncCommitteePoseidons[currentPeriod];

        bytes32 h;
        h = sha256(bytes.concat(attestedSlotLE, finalizedSlotLE));
        h = sha256(bytes.concat(h, update.finalizedHeaderRoot));
        h = sha256(bytes.concat(h, participationLE));
        h = sha256(bytes.concat(h, update.executionStateRoot));
        h = sha256(bytes.concat(h, syncCommitteePoseidon));
        uint256 t = uint256(SSZ.toLittleEndian(uint256(h)));
        t = t & ((uint256(1) << 253) - 1);

        Groth16Proof memory proof = update.proof;
        uint256[1] memory inputs = [uint256(t)];
        require(verifyProofStep(proof.a, proof.b, proof.c, inputs));
    }

    /// @notice Serializes the public inputs and verifies the rotate proof.
    function zkLightClientRotate(LightClientRotate memory update) internal view {
        Groth16Proof memory proof = update.proof;
        uint256[65] memory inputs;

        uint256 syncCommitteeSSZNumeric = uint256(update.syncCommitteeSSZ);
        for (uint256 i = 0; i < 32; i++) {
            inputs[32 - 1 - i] = syncCommitteeSSZNumeric % 2 ** 8;
            syncCommitteeSSZNumeric = syncCommitteeSSZNumeric / 2 ** 8;
        }
        uint256 finalizedHeaderRootNumeric = uint256(update.step.finalizedHeaderRoot);
        for (uint256 i = 0; i < 32; i++) {
            inputs[64 - i] = finalizedHeaderRootNumeric % 2 ** 8;
            finalizedHeaderRootNumeric = finalizedHeaderRootNumeric / 2 ** 8;
        }
        inputs[32] = uint256(SSZ.toLittleEndian(uint256(update.syncCommitteePoseidon)));

        require(verifyProofRotate(proof.a, proof.b, proof.c, inputs));
    }

    /// @notice Gets the sync committee period from a slot.
    function getSyncCommitteePeriod(uint256 slot) internal view returns (uint256) {
        return slot / SLOTS_PER_PERIOD;
    }

    /// @notice Gets the current slot for the chain the light client is reflecting.
    function getCurrentSlot() internal view returns (uint256) {
        return (block.timestamp - GENESIS_TIME) / SECONDS_PER_SLOT;
    }

    /// @notice Sets the current slot for the chain the light client is reflecting.
    function setHead(uint256 slot, bytes32 root) internal {
        if (headers[slot] != bytes32(0) && headers[slot] != root) {
            consistent = false;
            return;
        }
        head = slot;
        headers[slot] = root;
        emit HeadUpdate(slot, root);
    }

    /// @notice Sets the execution state root for a given slot.
    function setExecutionStateRoot(uint256 slot, bytes32 root) internal {
        if (executionStateRoots[slot] != bytes32(0) && executionStateRoots[slot] != root) {
            consistent = false;
            return;
        }
        executionStateRoots[slot] = root;
    }

    /// @notice Sets the sync committee poseidon for a given period.
    function setSyncCommitteePoseidon(uint256 period, bytes32 poseidon) internal {
        if (
            syncCommitteePoseidons[period] != bytes32(0)
                && syncCommitteePoseidons[period] != poseidon
        ) {
            consistent = false;
            return;
        }
        syncCommitteePoseidons[period] = poseidon;
        emit SyncCommitteeUpdate(period, poseidon);
    }

    function setTimestamp(uint256 slot, uint256 timestamp) internal {
        timestamps[slot] = timestamp;
    }
}

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

library PairingRotate {
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
        return G2Point(
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
        );*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
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
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.

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
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint[](inputSize);
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
            success :=
                staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
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

contract RotateVerifier {
    using PairingRotate for *;

    struct VerifyingKeyRotate {
        PairingRotate.G1Point alfa1;
        PairingRotate.G2Point beta2;
        PairingRotate.G2Point gamma2;
        PairingRotate.G2Point delta2;
        PairingRotate.G1Point[] IC;
    }

    struct ProofRotate {
        PairingRotate.G1Point A;
        PairingRotate.G2Point B;
        PairingRotate.G1Point C;
    }

    function verifyingKeyRotate() internal pure returns (VerifyingKeyRotate memory vk) {
        vk.alfa1 = PairingRotate.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );
        vk.beta2 = PairingRotate.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = PairingRotate.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = PairingRotate.G2Point(
            [
                17428334686573470114374904781607058544019589635942701782877693881064105870254,
                21309941043521319018947447375776689581054141107669089348728854725745064794356
            ],
            [
                3909770230468595205364929984498661804923207203503700149096592482998765250448,
                13247979133541506454870379206641027391108786157520034127531738121828102286590
            ]
        );
        vk.IC = new PairingRotate.G1Point[](66);
        vk.IC[0] = PairingRotate.G1Point(
            10782707541849503820997056858059047451533152477018057573635234109094388254787,
            1573409178978397905444651596345462440433662344339606507345108768815154161544
        );
        vk.IC[1] = PairingRotate.G1Point(
            19126218257033334621577014107068259309364198490767409227679267817166336640450,
            5287462191872344787041302664403546860287482577375847979891306396449850907764
        );
        vk.IC[2] = PairingRotate.G1Point(
            21597379586769470165331195450796853847377198802552279291440451419382078662901,
            4988754703118042550562608714183077971497997208687027071322697098924456292278
        );
        vk.IC[3] = PairingRotate.G1Point(
            11188089939758430427874195857241331151523799244518013816594749073946965426296,
            12693012311510544366423779710616910971788112972571939957151962983864749074416
        );
        vk.IC[4] = PairingRotate.G1Point(
            4538463311672189961100479893053096171966719687509951047137983400113166483254,
            19737817297801171792097426377175350482062323509653008751314437097343252212844
        );
        vk.IC[5] = PairingRotate.G1Point(
            14656370181547867887359420533813586598459417252751519548700501609141983917140,
            11160282111625387112679471854538630473790629688184509821799859591882121154460
        );
        vk.IC[6] = PairingRotate.G1Point(
            13053176491618134652213679155484339049600600385101535086326952140035018474762,
            15124409222741406620855265772186227843008617627646262891933541255011710983277
        );
        vk.IC[7] = PairingRotate.G1Point(
            17025130486161637031783005486019964863969699835243114290665928505315023332663,
            18960494684779151665179004247322410891789666930345036133271105474309141549484
        );
        vk.IC[8] = PairingRotate.G1Point(
            17616521930147258379630379438929344727200479952128054731596558989477916803431,
            7502257884021889679971035509967993389116347859574598902521521528804265570109
        );
        vk.IC[9] = PairingRotate.G1Point(
            11993682566921486599164600569207668466138801568031172129212549604668216101866,
            4307838883189218424961133882970039602520916920371727568985501795041713996589
        );
        vk.IC[10] = PairingRotate.G1Point(
            19033619702717570439163906757438227966747475675281540826953085870670996700976,
            14923392291023948833633116933643897705420278452738065963513860495493850956593
        );
        vk.IC[11] = PairingRotate.G1Point(
            10460104312010080088714485945877101290391672193105244980127759995723350551134,
            10693151337794732386183687516987826377570412811537544490944549826768147376184
        );
        vk.IC[12] = PairingRotate.G1Point(
            2605291304429719334906797699037454593619903524367227612349318646683776906991,
            4033333227710455372641450681109028433378489457452221778904320030890360407618
        );
        vk.IC[13] = PairingRotate.G1Point(
            1038838954634694002919754162790789324233892081248191233355557663106798628133,
            3196489427484783556838185935725745381170263537640688520701606664908369740437
        );
        vk.IC[14] = PairingRotate.G1Point(
            9350672147031522720250993948666510323620512384945953721984775897330906370248,
            10869187917740443485654079389898853668190096116516587220793802557689228390710
        );
        vk.IC[15] = PairingRotate.G1Point(
            12860654143106574948892285782358586992192926341377308837117714388980870643303,
            19599153058620337454945284563277240550072901904916653261021424666179319028576
        );
        vk.IC[16] = PairingRotate.G1Point(
            1234810897757844397911651261639535019139166354067660975543682822814144799522,
            14724095446347732543007923715531912976941991645966752022043553658969288101967
        );
        vk.IC[17] = PairingRotate.G1Point(
            4710163865743316699548221823308717737280500578987863028295614007270748694449,
            12492253859750539290093041978515405913780606216752394315288547565490439506287
        );
        vk.IC[18] = PairingRotate.G1Point(
            11559828121161457975482432843597195018030984739983894099123789551924974467993,
            10098729832362290647243975913349993943310025261447628703612875967157755123662
        );
        vk.IC[19] = PairingRotate.G1Point(
            12396088633328427030710942681521397009565020515910401485478156472878117248796,
            7179314862650101550415752072109801028918866606112016618078085603860209284794
        );
        vk.IC[20] = PairingRotate.G1Point(
            12215771479813544685012792594988237867493262661432304076324260078558163952768,
            165748835961318750663828895776501402174822951206695664882005600661303002777
        );
        vk.IC[21] = PairingRotate.G1Point(
            4663541734127458525449023888354024164080585603046669210439103751783814708096,
            18593992181616981770554141758040257924158904980711644617057922174039131683064
        );
        vk.IC[22] = PairingRotate.G1Point(
            14754129572809918305013696555579556055915060072237803877375825843011176752437,
            21313148501164171677922243197444249565823851942575292475389542235151137569595
        );
        vk.IC[23] = PairingRotate.G1Point(
            6910874731363535729661547015444697809707382315347986346298123599995488855015,
            19367260440277567067129523473208479074546734082449347546192089959309692346324
        );
        vk.IC[24] = PairingRotate.G1Point(
            4048667692986461094210364186787545463731790686754481925001156432834561524904,
            5463119202833755134850682486224869316641913228481242781775963059084147307953
        );
        vk.IC[25] = PairingRotate.G1Point(
            15890000335959239275273924440820071904126919921494378723520158448058350431441,
            5834293037870381374289742864660364934918797006380243178480736232619275043074
        );
        vk.IC[26] = PairingRotate.G1Point(
            18972186930126072874641240782338066005131478581962020484913427055857363012872,
            7201754577682108259674307630472991615944801960010316346316714082741195502794
        );
        vk.IC[27] = PairingRotate.G1Point(
            5566515511849666370409947790677918631037884062133762150032949706525207089744,
            12109541154566324109971148332250595817571693286936543306800357118124822466124
        );
        vk.IC[28] = PairingRotate.G1Point(
            14581791666491046317317704880448080857010676509893127542169952543481679519864,
            5856387661269877339266891449954489952170645463516718373195863023391676035328
        );
        vk.IC[29] = PairingRotate.G1Point(
            20164734517209103264399075584888700070591724993444294155510748361926019965076,
            9724767275049551551872849066769993503255831739487068595866801245254926922298
        );
        vk.IC[30] = PairingRotate.G1Point(
            728992903745184126529042525673423004313241148349473090159901053322917857107,
            10479596723766618710501059002161375394300536745127177284188094986078790651537
        );
        vk.IC[31] = PairingRotate.G1Point(
            1668559599741722719219220352744284168123629141975599303107551032802125907853,
            5399379185332102584612582021601824585168919913253713774162163852056775142209
        );
        vk.IC[32] = PairingRotate.G1Point(
            6028254937064599429606045988921614374349431847909626991463214364202403108658,
            15058962167422423718902560571850152000420153720840697536494443257718812452557
        );
        vk.IC[33] = PairingRotate.G1Point(
            14792141062006903077365354015372092808359641746536571659498773924505080582884,
            18845725837835825372663899949867171709050701894084519233240929842961468602084
        );
        vk.IC[34] = PairingRotate.G1Point(
            6688088141526568137135168272876918774457897675450767265807881185041632914026,
            4170353893171508437165871712015500776754766527915113103499271810377581920465
        );
        vk.IC[35] = PairingRotate.G1Point(
            16257990256381088990711359825576825844246359020973740444784284012165195011841,
            10109311120905184731657438526181431364043106558690226425386927785769672984651
        );
        vk.IC[36] = PairingRotate.G1Point(
            2201109116820374599671945959740074393278164234474986116767000428464075273154,
            15718391897142990105783018551945845768253271550763424251763692503158779658372
        );
        vk.IC[37] = PairingRotate.G1Point(
            2442082394543913231837197093863194789674488023679709848317901339721666480055,
            13912061645906525032771985233058358556663490517863437498951187728131532707286
        );
        vk.IC[38] = PairingRotate.G1Point(
            20021640748270314982260593910940845484032084879611403852250497160153657208030,
            8351149572236207824967461088480097809760560556990207347769540371717913375418
        );
        vk.IC[39] = PairingRotate.G1Point(
            4803793232904313220730573077490239821177556416393461126639315510372422550482,
            17894508885414327195518082730315870423709020821038087243874522562821820966408
        );
        vk.IC[40] = PairingRotate.G1Point(
            2054136258609212837133247550209152671996635175264824149329329425060052206755,
            16458201654719953421102057089204904331533802121651710556659604508328146767087
        );
        vk.IC[41] = PairingRotate.G1Point(
            619303700298495112060909106918906589080391698809330730004052173207824330354,
            16403429646863987259369539913548300011544320008774973183136826765002978748233
        );
        vk.IC[42] = PairingRotate.G1Point(
            7276479393294721348749042077027894345738811073498598970677782267378528337573,
            6952572822898762506321930653029376948447982065807945896544397233873302564905
        );
        vk.IC[43] = PairingRotate.G1Point(
            16598311062603724231114119423618626898407869069783124065683339444547923694520,
            2552588262201476628819851148366253677898263866151624939782153617121810654171
        );
        vk.IC[44] = PairingRotate.G1Point(
            7813567780418394214484855285668375390382922412056866990468004385114635736288,
            11873670082875545623686459181994723276783312763630344215115282503310797231836
        );
        vk.IC[45] = PairingRotate.G1Point(
            15332876103747788292370736884388438292651950507887471832285409092097066953149,
            1320668325217796561934038876776500446187270878205745950836137212361838166045
        );
        vk.IC[46] = PairingRotate.G1Point(
            18522518211636264894898373232857348703503009383752879205163742233382365616850,
            11931415328869586410469720169521437004076124831148375451325082420171903687246
        );
        vk.IC[47] = PairingRotate.G1Point(
            19297964269722214106851893660081452230928952543473071372998897823298053698208,
            17439643370636479959650289967965787306214835685109299875585631109500677626794
        );
        vk.IC[48] = PairingRotate.G1Point(
            4769034263136383428213948067230428161432500030785104009496226156474861026987,
            5196852594981366955150022068777988507794390294723766528172545506150418606875
        );
        vk.IC[49] = PairingRotate.G1Point(
            834976519900980388447932766072244323005895091844099611785650248399509383460,
            9049751434489624145834511499418016873671137177323336081141300700106635621373
        );
        vk.IC[50] = PairingRotate.G1Point(
            13859938176309241668779353721336378256529140589553560542869868947829505155038,
            7071671029505295682642877120390177243312290861847364832255380469132068753190
        );
        vk.IC[51] = PairingRotate.G1Point(
            16414415296923177997745817530720548605237746182698540598341139068479293048435,
            2354295433508178096223429827868679919751515880852253134723357532680302794394
        );
        vk.IC[52] = PairingRotate.G1Point(
            15080617309623346161507553236748337292640076459886618415205389843544337042073,
            11231447329651876423559441641903613570364401346187318668668542125544484659136
        );
        vk.IC[53] = PairingRotate.G1Point(
            18051216444590891845931649060902989339006359740291417391369661348006119743191,
            12336318092249273905900025837756685633078979859092316888034212418415064574024
        );
        vk.IC[54] = PairingRotate.G1Point(
            20803130126955462904108351236273223882258338007494144898411957261429410295485,
            16335739402337861078574880451715446295155273378677247465968956358447399628975
        );
        vk.IC[55] = PairingRotate.G1Point(
            15891420178052988458702004766575871103447646948414160296778949854295512865769,
            15536632769061846154687390391825617104981746825560163217247069960514147353258
        );
        vk.IC[56] = PairingRotate.G1Point(
            15092710008032197537309422017464992219745883902876974203090602925723168364716,
            21471482379194911879075773781208476898292069033060989434069242897746759477079
        );
        vk.IC[57] = PairingRotate.G1Point(
            11434732261002885103732698408145951304503405746603241860628961313261794466466,
            12776996603892035537659292835461374878653655839811699851864042607748609149946
        );
        vk.IC[58] = PairingRotate.G1Point(
            13494242262243069330341012325472675140741819192535267811324895904028512054449,
            3221922947391463613422878687743896375686711797384202385073215609847578810348
        );
        vk.IC[59] = PairingRotate.G1Point(
            9999416334607765997307082078400204027609453096129500807971128921893249625672,
            19880001321946868007565685330975925735067214611621514351758003633530408654625
        );
        vk.IC[60] = PairingRotate.G1Point(
            11370629782038204662068410934524023069021879161834626342031780142031091932938,
            3078485805697871737578412050392923870275870234756137910799597258611514208218
        );
        vk.IC[61] = PairingRotate.G1Point(
            1770640188416742878027779137904560870503007450908605566817336718213246050927,
            18476063386687390177822483088721418382980227980190754756082179481962090778947
        );
        vk.IC[62] = PairingRotate.G1Point(
            19084698607675946161890514331199562878511339894862018872070715202704802677912,
            16170700189869402453746701970880219063510848656967141613415616239583402584004
        );
        vk.IC[63] = PairingRotate.G1Point(
            7531233085220584485731940488356047975472934361138522999036310359584425436395,
            11589655766015847328402978361540523748893290080123371301978422156445683797858
        );
        vk.IC[64] = PairingRotate.G1Point(
            19198006038212060133070831345450428453893453766928245609380941869984467436079,
            20165876257527356156187025902331287079194032031160715893710867822277193951116
        );
        vk.IC[65] = PairingRotate.G1Point(
            13867831575502154867964714363343678043301675750078605674851460415130544458955,
            555623215669585806120709944965158556987931087451437846676466547681867450011
        );
    }

    function verifyRotate(uint256[] memory input, ProofRotate memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKeyRotate memory vk = verifyingKeyRotate();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        PairingRotate.G1Point memory vk_x = PairingRotate.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = PairingRotate.addition(vk_x, PairingRotate.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = PairingRotate.addition(vk_x, vk.IC[0]);
        if (
            !PairingRotate.pairingProd4(
                PairingRotate.negate(proof.A),
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

    function verifyProofRotate(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[65] memory input
    ) public view returns (bool r) {
        ProofRotate memory proof;
        proof.A = PairingRotate.G1Point(a[0], a[1]);
        proof.B = PairingRotate.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingRotate.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verifyRotate(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

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

library PairingStep {
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
        return G2Point(
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
        );*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.

    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        }
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
            case 0 { invalid() }
        }
        require(success, "pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.

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
            case 0 { invalid() }
        }
        require(success, "pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, "pairing-lengths-failed");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint[](inputSize);
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
            success :=
                staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 { invalid() }
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

contract StepVerifier {
    using PairingStep for *;

    struct VerifyingKeyStep {
        PairingStep.G1Point alfa1;
        PairingStep.G2Point beta2;
        PairingStep.G2Point gamma2;
        PairingStep.G2Point delta2;
        PairingStep.G1Point[] IC;
    }

    struct ProofStep {
        PairingStep.G1Point A;
        PairingStep.G2Point B;
        PairingStep.G1Point C;
    }

    function verifyingKeyStep() internal pure returns (VerifyingKeyStep memory vk) {
        vk.alfa1 = PairingStep.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );
        vk.beta2 = PairingStep.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = PairingStep.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = PairingStep.G2Point(
            [
                6234393032850437631975413940411769827516095496163952099321951004826179832619,
                17805432178925476167081200277285241905917422159137155045547232195893813661987
            ],
            [
                11032389332271190094564174107824630427217162562293851501350830524211166138819,
                1499717376798499257024920800589175312903649319662746006039783380030250925640
            ]
        );
        vk.IC = new PairingStep.G1Point[](2);
        vk.IC[0] = PairingStep.G1Point(
            18581490348268366459486038311398136069286693201853340996599009982405671959827,
            1345916112533385981081100262426892476224742650298147103945553608867487064592
        );
        vk.IC[1] = PairingStep.G1Point(
            8325959768672458329204135658777635095314539205238326522567623643819699069822,
            3171583752822271832447387976975085241930689617737859324116789970045268651954
        );
    }

    function verifyStep(uint256[] memory input, ProofStep memory proof)
        internal
        view
        returns (uint256)
    {
        uint256 snark_scalar_field =
            21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKeyStep memory vk = verifyingKeyStep();
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        PairingStep.G1Point memory vk_x = PairingStep.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
            vk_x = PairingStep.addition(vk_x, PairingStep.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = PairingStep.addition(vk_x, vk.IC[0]);
        if (
            !PairingStep.pairingProd4(
                PairingStep.negate(proof.A),
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

    function verifyProofStep(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {
        ProofStep memory proof;
        proof.A = PairingStep.G1Point(a[0], a[1]);
        proof.B = PairingStep.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingStep.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verifyStep(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

pragma solidity ^0.8.0;

interface ILightClient {
    function consistent() external view returns (bool);

    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function timestamps(uint256 slot) external view returns (uint256);
}