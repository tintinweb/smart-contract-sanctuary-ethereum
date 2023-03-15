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

import {ILightClient} from "src/lightclient/interfaces/ILightClient.sol";
import {StepVerifier} from "src/lightclient/StepVerifier.sol";
import {RotateVerifier} from "src/lightclient/RotateVerifier.sol";

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

        if (update.finalizedSlot < head) {
            revert("Update slot less than current head");
        }

        if (finalized) {
            setSlotRoots(
                update.finalizedSlot, update.finalizedHeaderRoot, update.executionStateRoot
            );
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
    /// @dev Checks if roots exists for the slot already. If there is, check for a conflict between
    ///      the given roots and the existing roots. If there is an existing header but no
    ///      conflict, do nothing. This avoids timestamp renewal DoS attacks.
    function setSlotRoots(uint256 slot, bytes32 finalizedHeaderRoot, bytes32 executionStateRoot)
        internal
    {
        if (headers[slot] != bytes32(0)) {
            if (headers[slot] != finalizedHeaderRoot) {
                consistent = false;
            }
            return;
        }
        if (executionStateRoots[slot] != bytes32(0)) {
            if (executionStateRoots[slot] != executionStateRoot) {
                consistent = false;
            }
            return;
        }

        head = slot;
        headers[slot] = finalizedHeaderRoot;
        executionStateRoots[slot] = executionStateRoot;
        timestamps[slot] = block.timestamp;
        emit HeadUpdate(slot, finalizedHeaderRoot);
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
                3675012114472141823353431748838492474116965167545797868888004981062438761191,
                10919016225287729772152561895455637785621917546560571464331102379931789733219
            ],
            [
                102187551240741282923570240607013148086072939956192338710607906886896151404,
                5367848349839033463131482183036431902292883341608111320084976497150816008676
            ]
        );
        vk.IC = new PairingRotate.G1Point[](66);

        vk.IC[0] = PairingRotate.G1Point(
            5470815004869339708023881485772068204912771757179007890054204256558850581949,
            4017097656779998741510710628117295954432749941107635696146110442372218605472
        );

        vk.IC[1] = PairingRotate.G1Point(
            14277312075960031085375048071612101555372035286672331734392395085201225041149,
            14239461345455039302866813666954330449685909886390271856241643488739478373512
        );

        vk.IC[2] = PairingRotate.G1Point(
            10256748840775250798022727853625820196139372710211008731654522604490787003459,
            20397352715193589290244696330476579119048823352961807809477137990763045264186
        );

        vk.IC[3] = PairingRotate.G1Point(
            550075104891859430074462590592661684892297605480719920050615275015711508540,
            9032201165211335469461508008237078579797938193755295864092980796424301990237
        );

        vk.IC[4] = PairingRotate.G1Point(
            21713013256553006628611706827565089795369588919207450378979275353062640142109,
            2661645625997626369569922372169772081437758044104248909618957550337440494139
        );

        vk.IC[5] = PairingRotate.G1Point(
            13691767371801378227924059456388428035967164647023292694391180919564712627486,
            756065770973511865243597601390091557217745613563990150676273724294507448431
        );

        vk.IC[6] = PairingRotate.G1Point(
            17210984791838145359466867649558462207089918294097343317284442476101568076903,
            16563042484294402555802035774580866281492939197308313773740452628469640810440
        );

        vk.IC[7] = PairingRotate.G1Point(
            21652367622408977882130185948903917467398782152573572688460517452235184585130,
            9456717250971867942266744925479122316030416863980640923048259745172637366725
        );

        vk.IC[8] = PairingRotate.G1Point(
            12428061968345789072069730074981543994872620840107009832818380903947462784731,
            9628665618463208783319788804477124615643602805991242396517345043087341128847
        );

        vk.IC[9] = PairingRotate.G1Point(
            7591606751456480272207358723930527667946792703046687083257839541887230600513,
            5066738728275003710178607972725262923032117471343419051299425541173384033812
        );

        vk.IC[10] = PairingRotate.G1Point(
            14488917807089011281047272726099875150571238692019113219825028192575284509581,
            3883496032433938548361294112846837895152012388047964931324198754228797877220
        );

        vk.IC[11] = PairingRotate.G1Point(
            12645787598395228725171373471935087818337812765671916073026450852525761450287,
            16769199208517164707037753561119296273327233703340885518231256382074870981084
        );

        vk.IC[12] = PairingRotate.G1Point(
            8215460069747363365580846005818022489493268911061609705064972529404961966716,
            6669659888215141314967540985998609102937810373447651153074209742694609294095
        );

        vk.IC[13] = PairingRotate.G1Point(
            2844997831056636120836911709923266133367730601282518816015648606919944680684,
            19610199208595789435810978810597614274285858402731872359124459788255937025996
        );

        vk.IC[14] = PairingRotate.G1Point(
            7040110845525952900598881769658949052341010642995548224350638317552310576665,
            1487161644887832968957801290134731353444352051595741879812259993583216090066
        );

        vk.IC[15] = PairingRotate.G1Point(
            12405805793275046993325239811828128198882824151112347193213908986231709070096,
            15492255937493657362746399833085165717154406677433505821519002161530391720647
        );

        vk.IC[16] = PairingRotate.G1Point(
            13285062575679713300238666842781712613277259978595375037257266736470472693734,
            17488882217616287673270345118177467195439036242880051293611907165945370393183
        );

        vk.IC[17] = PairingRotate.G1Point(
            8603566731019335023634627293889179299668875390582323005277165715690663545281,
            9408560403310074111063179066628126101341395210067416861794078835499868816389
        );

        vk.IC[18] = PairingRotate.G1Point(
            1181542675746324377871278475651244460118791808050795628097423364071136531210,
            16597581308801947899138241527753298624973308153461725212655837446361686781341
        );

        vk.IC[19] = PairingRotate.G1Point(
            14408564907247179976621631573939251801623056626888588761518947695781661259431,
            7271292981933539395227276416353020454175202289781663739615258142432056594341
        );

        vk.IC[20] = PairingRotate.G1Point(
            17597295579129750685222005163149670289164331266400199650162523758546359081430,
            242419869317119527452900448830763183657743377412973281248624953969503788017
        );

        vk.IC[21] = PairingRotate.G1Point(
            20124047720139252459109468495559408458493639360052211576952318590325892917503,
            14008316510305876208122551501589871272450059356861116352652762997086093688531
        );

        vk.IC[22] = PairingRotate.G1Point(
            13429010226287571463999973230050502318483188103767219746698970525082092429630,
            17607024931072105555190552501851311614700269454441117491038856897846484505559
        );

        vk.IC[23] = PairingRotate.G1Point(
            627964571426933641572058300878809182262081368423265694511023550606724723852,
            7373605622742653003693203193757662230639533270431368245427885795203201424820
        );

        vk.IC[24] = PairingRotate.G1Point(
            12161353119779742822520962020173667675809269149216188936907052577149093111204,
            6555344721078959891495725261309309757730705617249729308378872092562368473988
        );

        vk.IC[25] = PairingRotate.G1Point(
            9942573813465654211107291217854629923255602950622362298703894692342235427207,
            20021572331775129788719437837166754838257663222479115248088091028568806131147
        );

        vk.IC[26] = PairingRotate.G1Point(
            17910544130511298533517349900760876063185744881593759677884881699548930171332,
            7566195441873811040992078749824142377659424688172946587073369650740370382053
        );

        vk.IC[27] = PairingRotate.G1Point(
            10294006571004095925349367164151343983622516668137117545981916220159082857404,
            11051424065788213828967323053142067453752210885728523770440122057870479709783
        );

        vk.IC[28] = PairingRotate.G1Point(
            17278283156969428338635046359226820440103033906261666777410408218807934373990,
            12630385670559989967675890775741481340979991232084884378562333580112758868739
        );

        vk.IC[29] = PairingRotate.G1Point(
            20719773367000423770103787495754469795737917431647832647547093626506779924857,
            12241894457863621777618930601757821502077084227388402933846144913385339154274
        );

        vk.IC[30] = PairingRotate.G1Point(
            7825569666207241575453093795025524306505131449824573801763077037005575843172,
            11788956260734339141039890691640575434794809354675227814118671978630056270161
        );

        vk.IC[31] = PairingRotate.G1Point(
            10256922205896585948010363832994059866678392695752778911179274200873680504486,
            20710849495413331015027530557092065338191984434697780936325111489762998359394
        );

        vk.IC[32] = PairingRotate.G1Point(
            7572217948185872545017456144279759157591242738079606265720395393961675644333,
            6192765399438435590717647536649376957292802732415532034804257875057712415415
        );

        vk.IC[33] = PairingRotate.G1Point(
            15391560451656587100602586684457458735941689200752320075626947497705342829876,
            7469915732140427004149238203533591322565954801326586011976294165439258678171
        );

        vk.IC[34] = PairingRotate.G1Point(
            2253212938086582304814193274897683117304874968223660198987155742236380011435,
            3363542076064470851126434129047206220947052523506353352971821345125367070063
        );

        vk.IC[35] = PairingRotate.G1Point(
            17987318395821359901152963133368311889165569699804937933016037339230070642262,
            1022889512148181894044975791615851243035079161202273448049368472740702704664
        );

        vk.IC[36] = PairingRotate.G1Point(
            2595191674370476748249132758864046203842783028970388255482808886766485458335,
            15999872848065408374250027264594185256390522888165323431229975753580595435412
        );

        vk.IC[37] = PairingRotate.G1Point(
            17310802424312407177327231604308398662368636546188087853824155787735954852657,
            17492267087305379320377201137032057700653202094081338764785614411379003265135
        );

        vk.IC[38] = PairingRotate.G1Point(
            19692305970501129432989117858162812421089112183797295270345301988227225701596,
            13407066371238340125981115105014778822174694414863209614311286575950290183122
        );

        vk.IC[39] = PairingRotate.G1Point(
            10280280821816150338698341999809174508877893892146508999367975655101013502337,
            12873664672144000638692091121716563297523913813351462683381257837764257361266
        );

        vk.IC[40] = PairingRotate.G1Point(
            15269942102931108304861180822000044831078625258211177465421373923889797003713,
            315941659904404805162515697500885926641592106285202599044695865981944934148
        );

        vk.IC[41] = PairingRotate.G1Point(
            18720117707393600985668734258470788963109345994486804125334415623779965685579,
            17610066291159506858109565731510415537915008213026426702411450752803499563945
        );

        vk.IC[42] = PairingRotate.G1Point(
            17473387575701915793165316810554838264284294799431693872192608671518586775589,
            11046638250273238988420881477549685125663400537658322931163724522834081071681
        );

        vk.IC[43] = PairingRotate.G1Point(
            1131444062811679831409684930556592770674157096923417994117545757895843843257,
            14806880463376902602792568628979400757229760418808213797901706596473177402855
        );

        vk.IC[44] = PairingRotate.G1Point(
            3333565255438508727133914474431341407114665924124016209746252498172716323458,
            1349287382207655945922193622904780432125650897659617214713798793227947453335
        );

        vk.IC[45] = PairingRotate.G1Point(
            13940028459121008532016253983362465702704402122643253107590554855038192214997,
            3225433852783273107896062941479423211005648219618800554123220051023809342710
        );

        vk.IC[46] = PairingRotate.G1Point(
            19717004403074439755349281295381478852157253003797216955970992000449301302719,
            3186328678318977319722138906369583685190567800290840806157855829071842708219
        );

        vk.IC[47] = PairingRotate.G1Point(
            16642147433186556950008995817628233060579719469362516887521909650865254862277,
            17897379145764357424229771761211803103403399226293603355593766947402488749261
        );

        vk.IC[48] = PairingRotate.G1Point(
            14166167796010346344607806834057017465158432711277897940882635412943787832957,
            1466421523646102279306143855466046078434093416565439179577859342596077968495
        );

        vk.IC[49] = PairingRotate.G1Point(
            9121323577197934089656479126834443288009296095992819343687934158311952648102,
            20838803026465071526824216109672143097735131861681728912431346891805254673021
        );

        vk.IC[50] = PairingRotate.G1Point(
            16527506110553414978978752440663074476403014249564253944322759266695960317283,
            20784110511802989598239803900829001702846512565882851871209620824570342959741
        );

        vk.IC[51] = PairingRotate.G1Point(
            21239710915708343421769893254944423412302146109622846670164778866011467089334,
            21673205856698640090132731274991397146356957558897797067201376224645693508319
        );

        vk.IC[52] = PairingRotate.G1Point(
            8077054060841997795055664844350639621813278263496855282589846327672529047441,
            7836528458814616258001093258469921488745632058376319287462221490756158150755
        );

        vk.IC[53] = PairingRotate.G1Point(
            14516329420235345440149324792936235254195325657174837822744049638896307191009,
            20722856186071063267009035722206599642529515584360229343481151178919568667656
        );

        vk.IC[54] = PairingRotate.G1Point(
            2669418772363680637663665025335332245703927178960036706320145551701239085099,
            21877663481941323417151526405025523153611074545818563846226114918852433289787
        );

        vk.IC[55] = PairingRotate.G1Point(
            5741991653539626114303961719014055119659011005869852659937084977252640589389,
            18376104754519076330669694554115737208000577444106874582540891451657284147033
        );

        vk.IC[56] = PairingRotate.G1Point(
            8028575798791411367183643439532739195517530885357926087717772517691790990720,
            18883759566594356674404094589651421579134482900437360695545733243237480747440
        );

        vk.IC[57] = PairingRotate.G1Point(
            16855740526826858784404294435476672051544769847039765832010554156813731500735,
            659320399176788531847946680054100455785626824551846564053384763521994791623
        );

        vk.IC[58] = PairingRotate.G1Point(
            19988225821830608710578630073688777389429278183733539199536068639850161003968,
            13955046145626853781355698616181858322515747170102298011267491749553021068605
        );

        vk.IC[59] = PairingRotate.G1Point(
            15410537293735377459773895058434203425750985393204437521319290173095968032576,
            12169824789351460419228154813849731234386233054285207598923427959734874612330
        );

        vk.IC[60] = PairingRotate.G1Point(
            2159062713955330031251957758273078405414148150460871899054446806500793547230,
            5879182752663104625737625098296688013210189092653213235878521327556194561168
        );

        vk.IC[61] = PairingRotate.G1Point(
            4174895122075502369038039999781532490288044058012153099254766261447417221242,
            10002098427920629174530381032587014535008462144357498361035555806129992916818
        );

        vk.IC[62] = PairingRotate.G1Point(
            15335284926841897062681527472356815727299146551895045501122685010036931177370,
            15836442636274538856030584403981280347198833751029912415192018487311436469357
        );

        vk.IC[63] = PairingRotate.G1Point(
            15162884727148196758524310643047361429630186986459976124858953592650939212470,
            21420261991093949703915232730226827651029889087964456544705761681774879713164
        );

        vk.IC[64] = PairingRotate.G1Point(
            11897567539623576790784466821129399882362071349295534039069611825756071290043,
            13382525927073502847360453300076919468700768256030677349337425404866209364848
        );

        vk.IC[65] = PairingRotate.G1Point(
            1770704955919074560139787492400225011230234734329412973959714160679435405051,
            1103550123340193874347219466412240366118503028463942223452924232215815583842
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
                9148034046527158989101020029579194033324545680690921079621927354300102378298,
                10428510773771669101337698551840898995662926411592295461427040701160903222524
            ],
            [
                2059005959130125518966387482690762396878640026867853728991912122619823366140,
                8608655831713798153467395128429618873818784843644748205739399791673552717322
            ]
        );
        vk.IC = new PairingStep.G1Point[](2);

        vk.IC[0] = PairingStep.G1Point(
            21097338684422677437460982984988891660959866360162656316176294386916372703826,
            3398895913860087272363404566039149647887053857985313627926493221433540324753
        );

        vk.IC[1] = PairingStep.G1Point(
            17453610618095138353005253409143141334272691316524473752585732650144486997453,
            17395545982498249053105146333634640028536711052867181025149351332882425139542
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