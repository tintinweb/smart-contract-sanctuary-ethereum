//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./library/Bn254.sol";
import "./library/BalanceSumVerifier.sol";

contract Greeter {

    // constructor(string memory _greeting) {
    // }

    function verify(
        BalanceSumVerifier.Proof memory proof,
        Bn254.Fr memory balanceSum
    ) public view returns (bool) {
        return BalanceSumVerifier.verify(proof, balanceSum);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./Bn254.sol";
import "./Domain.sol";
import "./KZGChecker.sol";
import "./TranscriptProtocol.sol";

library BalanceSumVerifier {
    using Bn254 for Bn254.Fr;
    using Bn254 for Bn254.G1Point;
    using TranscriptProtocol for TranscriptProtocol.Transcript;

    struct Proof {
        // Evluations
        Bn254.Fr b;
        Bn254.Fr t;
        Bn254.Fr h1;
        Bn254.Fr h2;
        Bn254.Fr sNext;
        Bn254.Fr zNext;
        Bn254.Fr h1Next;
        Bn254.Fr h2Next;

        // Commitments
        Bn254.G1Point bCommit;
        Bn254.G1Point sCommit;
        Bn254.G1Point h1Commit;
        Bn254.G1Point h2Commit;
        Bn254.G1Point zCommit;
        Bn254.G1Point q1Commit;
        Bn254.G1Point q2Commit;
        Bn254.G1Point opening1;
        Bn254.G1Point opening2;
    }

    struct Challenges {
        Bn254.Fr gamma;
        Bn254.Fr z;
        Bn254.Fr lambda;
        Bn254.Fr[] deltas;
        Bn254.Fr[] etas;
    }

    // Precomputed [t(X)]
    function tCommit() internal pure returns (Bn254.G1Point memory) {
        return Bn254.G1Point(
            0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b,
            0x0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b
        );
    }

    function validateProof(Proof memory proof) internal pure {
        proof.b.validateFr();
        proof.t.validateFr();
        proof.h1.validateFr();
        proof.h2.validateFr();
        proof.sNext.validateFr();
        proof.zNext.validateFr();
        proof.h1Next.validateFr();
        proof.h2Next.validateFr();

        proof.bCommit.validateG1();
        proof.sCommit.validateG1();
        proof.h1Commit.validateG1();
        proof.h2Commit.validateG1();
        proof.zCommit.validateG1();
        proof.q1Commit.validateG1();
        proof.q2Commit.validateG1();
        proof.opening1.validateG1();
        proof.opening2.validateG1();
    }
    
    function evaluateVanishingPoly(Bn254.Fr memory tau) internal view returns (Bn254.Fr memory) {
        Bn254.Fr memory tmp = tau.pow(Domain.SIZE);
        tmp.subAssign(Bn254.Fr(1));
        return tmp;
    }

    function evaluateFirstLagrangePoly(
        Bn254.Fr memory tau,
        Bn254.Fr memory zh
    ) internal view returns (Bn254.Fr memory) {
        Bn254.Fr memory tmp = tau.sub(Bn254.Fr(1));
        tmp.mulAssign(Bn254.Fr(Domain.SIZE));
        tmp.inverseAssign();
        tmp.mulAssign(zh);
        return tmp;
    }

    function evaluateLastLagrangePoly(
        Bn254.Fr memory tau,
        Bn254.Fr memory zh
    ) internal view returns (Bn254.Fr memory) {
        Bn254.Fr memory omegaInv = Domain.domainGeneratorInv();
        Bn254.Fr memory tmp = tau.sub(omegaInv);
        tmp.mulAssign(Bn254.Fr(Domain.SIZE));
        tmp.inverseAssign();
        tmp.mulAssign(zh);
        tmp.mulAssign(omegaInv);
        return tmp;
    }

    function computeEvaluation1(
        Proof memory proof,
        Challenges memory challenges,
        Bn254.Fr memory firstLagEval,
        Bn254.Fr memory lastLagEval,
        Bn254.Fr memory m
    ) internal pure returns (Bn254.Fr memory) {
        Bn254.Fr memory evaluation = Bn254.Fr(0).sub(proof.sNext);
        Bn254.Fr memory tmp = m.mul(firstLagEval);
        evaluation.subAssign(tmp);

        tmp.copyFromFr(challenges.gamma);
        tmp.addAssign(proof.h1);
        tmp.mulAssign(proof.zNext);
        tmp.mulAssign(challenges.gamma);
        tmp.mulAssign(challenges.deltas[0]);
        evaluation.addAssign(tmp);

        tmp.copyFromFr(firstLagEval);
        tmp.mulAssign(challenges.deltas[1]);
        evaluation.addAssign(tmp);

        Bn254.Fr memory lastLagEvalSubOne = lastLagEval.sub(Bn254.Fr(1));
        tmp.copyFromFr(proof.h1Next);
        tmp.subAssign(proof.h1);
        tmp.subAssign(Bn254.Fr(1));
        tmp.mulAssign(proof.h1Next);
        tmp.mulAssign(lastLagEvalSubOne);
        tmp.mulAssign(challenges.deltas[2]);
        evaluation.subAssign(tmp);

        tmp.copyFromFr(proof.h2Next);  
        tmp.subAssign(proof.h2);
        tmp.subAssign(Bn254.Fr(1));
        tmp.mulAssign(proof.h2Next);
        tmp.mulAssign(lastLagEvalSubOne);
        tmp.mulAssign(challenges.deltas[3]);
        evaluation.subAssign(tmp);

        tmp.copyFromFr(proof.h2Next);
        tmp.subAssign(proof.h1);
        tmp.subAssign(Bn254.Fr(1));
        tmp.mulAssign(proof.h2Next);
        tmp.mulAssign(lastLagEval);
        tmp.mulAssign(challenges.deltas[4]);
        evaluation.subAssign(tmp);

        tmp.copyFromFr(Bn254.Fr(Domain.SIZE - 1));
        tmp.mulAssign(lastLagEval);
        tmp.mulAssign(challenges.deltas[6]);
        evaluation.addAssign(tmp);

        tmp.copyFromFr(proof.b);
        tmp.mulAssign(challenges.etas[0]);
        evaluation.addAssign(tmp);

        tmp.copyFromFr(proof.t);
        tmp.mulAssign(challenges.etas[1]);
        evaluation.addAssign(tmp);

        tmp.copyFromFr(proof.h1);
        tmp.mulAssign(challenges.etas[2]);
        evaluation.addAssign(tmp);

        tmp.copyFromFr(proof.h2);
        tmp.mulAssign(challenges.etas[3]);
        evaluation.addAssign(tmp);
        
        return evaluation;
    }

    function computeEvaluation2(
        Proof memory proof,
        Challenges memory challenges
    ) pure internal returns (Bn254.Fr memory) {
        Bn254.Fr memory evaluation = proof.sNext.cloneFr();
        Bn254.Fr memory tmp = proof.zNext.mul(challenges.etas[0]);
        evaluation.addAssign(tmp);
        tmp.copyFromFr(proof.h1Next);
        tmp.mulAssign(challenges.etas[1]);
        evaluation.addAssign(tmp);
        tmp.copyFromFr(proof.h2Next);
        tmp.mulAssign(challenges.etas[2]);
        evaluation.addAssign(tmp);

        return evaluation;
    }

    function linearisationCommitments1(
        Proof memory proof,
        Challenges memory challenges,
        Bn254.Fr memory zh,
        Bn254.Fr memory firstLagEval,
        Bn254.Fr memory lastLagEval
    ) internal view returns (Bn254.G1Point memory) {
        // -[s(X)]
        Bn254.G1Point memory commitment = proof.sCommit.pointNegate();

        // eta * [t(X)]
        Bn254.G1Point memory tmpPoint = tCommit().pointMul(challenges.etas[0]);
        commitment.pointAddAssign(tmpPoint);

        // (eta^2 - 1) * [B(X)]
        Bn254.Fr memory scalar = challenges.etas[1].sub(Bn254.Fr(1));
        tmpPoint.copyFromG1(proof.bCommit);
        tmpPoint.pointMul(scalar);
        commitment.pointAddAssign(tmpPoint);

        // scalar = (gamma + b) * (gamma + t) * delta + firstLag * delta^2
        Bn254.Fr memory tmp = challenges.gamma.add(proof.b);
        scalar.copyFromFr(tmp);
        tmp.copyFromFr(challenges.gamma);
        tmp.addAssign(proof.t);
        scalar.mulAssign(tmp);
        scalar.mulAssign(challenges.deltas[0]);
        tmp.copyFromFr(firstLagEval);
        tmp.mulAssign(challenges.deltas[1]);
        scalar.addAssign(tmp);
        // scalar * [z(X)]
        tmpPoint.copyFromG1(proof.zCommit);
        tmpPoint.pointMulAssign(scalar);
        commitment.pointAddAssign(tmpPoint);

        // scalar = firstLag * delta^6 + eta^3
        //          - (h1Next - h1 - 1) * (lastLag - 1) * delta^3
        //          - (h2Next - h1 - 1) * lastLag * delta^5
        Bn254.Fr memory h1PlusOne = proof.h1.add(Bn254.Fr(1));
        Bn254.Fr memory lastLagEvalSubOne = lastLagEval.sub(Bn254.Fr(1));
        scalar.copyFromFr(firstLagEval);
        scalar.mulAssign(challenges.deltas[5]);
        scalar.addAssign(challenges.etas[2]);
        tmp.copyFromFr(proof.h1Next);
        tmp.subAssign(h1PlusOne);
        tmp.mulAssign(lastLagEvalSubOne);
        tmp.mulAssign(challenges.deltas[2]);
        scalar.subAssign(tmp);
        tmp.copyFromFr(proof.h2Next);
        tmp.subAssign(h1PlusOne);
        tmp.mulAssign(lastLagEval);
        tmp.mulAssign(challenges.deltas[4]);
        scalar.subAssign(tmp);
        // scalar * [h1(X)]
        tmpPoint.copyFromG1(proof.h1Commit);
        tmpPoint.pointMulAssign(scalar);
        commitment.pointAddAssign(tmpPoint);

        // scalar = lastLag * delta^7 + eta^4
        //          - zNext * (gamma + h1) * delta
        //          - (h2Next - h2 - 1) * (lastLag - 1) * delta^4
        scalar.copyFromFr(lastLagEval);
        scalar.mulAssign(challenges.deltas[6]);
        scalar.addAssign(challenges.etas[3]);
        tmp.copyFromFr(challenges.gamma);
        tmp.addAssign(proof.h1);
        tmp.mulAssign(proof.zNext);
        tmp.mulAssign(challenges.deltas[0]);
        scalar.subAssign(tmp);
        tmp.copyFromFr(proof.h2Next);
        tmp.subAssign(proof.h2);
        tmp.subAssign(Bn254.Fr(1));
        tmp.mulAssign(lastLagEvalSubOne);
        tmp.mulAssign(challenges.deltas[3]);
        scalar.subAssign(tmp);
        // scalar * [h2(X)]
        tmpPoint.copyFromG1(proof.h2Commit);
        tmpPoint.pointMulAssign(scalar);
        commitment.pointAddAssign(tmpPoint);

        // -zh * [q1(X)]
        tmpPoint.copyFromG1(proof.q1Commit);
        tmpPoint.pointMulAssign(zh);
        commitment.pointSubAssign(tmpPoint);

        // scalar = -zh * (zh + 1) * z^3
        scalar.copyFromFr(zh);
        scalar.addAssign(Bn254.Fr(1));
        scalar.mulAssign(zh);
        scalar.mulAssign(challenges.z);
        scalar.mulAssign(challenges.z);
        scalar.mulAssign(challenges.z);
        // scalar * [q2(X)]
        tmpPoint.copyFromG1(proof.q2Commit);
        tmpPoint.pointMulAssign(scalar);
        commitment.pointSubAssign(tmpPoint);

        return commitment;
    }

    function linearisationCommitments2(
        Proof memory proof,
        Challenges memory challenges
    ) internal view returns (Bn254.G1Point memory) {
        // [S(X)]
        Bn254.G1Point memory commitment = proof.sCommit.cloneG1();

        // eta * [z(X)]
        Bn254.G1Point memory tmpPoint = proof.zCommit.pointMul(challenges.etas[0]);
        commitment.pointAddAssign(tmpPoint);

        // eta^2 * [h1(X)]
        tmpPoint.copyFromG1(proof.h1Commit);
        tmpPoint.pointMulAssign(challenges.etas[1]);
        commitment.pointAddAssign(tmpPoint);

        // eta^3 * [h2(X)]
        tmpPoint.copyFromG1(proof.h2Commit);
        tmpPoint.pointMulAssign(challenges.etas[2]);
        commitment.pointAddAssign(tmpPoint);

        return commitment;
    }

    function generateChallenges(
        Proof memory proof,
        Bn254.Fr memory m
    ) internal pure returns (Challenges memory) {
        // Initialize transcript
        TranscriptProtocol.Transcript memory transcript = TranscriptProtocol.newTranscript();
        transcript.appendUint256(Domain.SIZE);

        transcript.appendFr(m);
        transcript.appendG1(proof.bCommit);
        transcript.appendG1(proof.sCommit);
        transcript.appendG1(proof.h1Commit);
        transcript.appendG1(proof.h2Commit);
        // Compute challenge gamma
        Bn254.Fr memory gamma = transcript.challengeFr();

        transcript.appendG1(proof.zCommit);
        // Compute challenge delta
        Bn254.Fr memory delta = transcript.challengeFr();

        transcript.appendG1(proof.q1Commit);
        transcript.appendG1(proof.q2Commit);
        // Compute challenge z
        Bn254.Fr memory z = transcript.challengeFr();

        transcript.appendFr(proof.t);
        transcript.appendFr(proof.b);
        transcript.appendFr(proof.h1);
        transcript.appendFr(proof.h2);
        transcript.appendFr(proof.sNext);
        transcript.appendFr(proof.h1Next);
        transcript.appendFr(proof.h2Next);
        transcript.appendFr(proof.zNext);
        // Compute challenge eta
        Bn254.Fr memory eta = transcript.challengeFr();

        transcript.appendG1(proof.opening1);
        transcript.appendG1(proof.opening2);
        // Compute challenge lambda
        Bn254.Fr memory lambda = transcript.challengeFr();

        // Expand deltas vector
        Bn254.Fr[] memory deltas = new Bn254.Fr[](7);
        deltas[0].copyFromFr(delta);
        for (uint256 i = 1; i < 7; i++) {
            deltas[i].copyFromFr(deltas[i - 1].mul(delta));
        }
        // Expand etas vectors
        Bn254.Fr[] memory etas = new Bn254.Fr[](4);
        etas[0].copyFromFr(eta);
        for (uint256 i = 1; i < 7; i++) {
            deltas[i].copyFromFr(deltas[i - 1].mul(delta));
        }

        return Challenges(gamma, z, lambda, deltas, etas);
    }

    function verify(Proof memory proof, Bn254.Fr memory m) internal view returns (bool) {
        m.validateFr();
        validateProof(proof);

        // Generate challenges via Fiat-Shamir algorithm
        Challenges memory challenges = generateChallenges(proof, m);

        // Compute vanishing polynomial evaluation
        Bn254.Fr memory zh = evaluateVanishingPoly(challenges.z);
        // Compute first Lagrange polynomial evaluation
        Bn254.Fr memory firstLagEval = evaluateFirstLagrangePoly(challenges.z, zh);
        // Compute last Lagrange polynomial evaluation
        Bn254.Fr memory lastLagEval = evaluateLastLagrangePoly(challenges.z, zh);

        // Compute evaluation 1
        Bn254.Fr memory evaluation1 = computeEvaluation1(
            proof,
            challenges,
            firstLagEval,
            lastLagEval,
            m
        );
        // Compute commitment 1
        Bn254.G1Point memory commitment1 = linearisationCommitments1(
            proof,
            challenges,
            zh,
            firstLagEval,
            lastLagEval
        );
        
        // Compute evaluation 2
        Bn254.Fr memory evaluation2 = computeEvaluation2(proof, challenges);
        // Compute commitment 2
        Bn254.G1Point memory commitment2 = linearisationCommitments2(proof, challenges);

        // KZG batch check
        Bn254.Fr[] memory points = new Bn254.Fr[](2);
        points[0].copyFromFr(challenges.z);
        points[1].copyFromFr(Domain.domainGenerator().mul(challenges.z));
        Bn254.Fr[] memory evals = new Bn254.Fr[](2);
        evals[0].copyFromFr(evaluation1);
        evals[1].copyFromFr(evaluation2);
        Bn254.G1Point[] memory openings = new Bn254.G1Point[](2);
        openings[0].copyFromG1(proof.opening1);
        openings[1].copyFromG1(proof.opening2);
        Bn254.G1Point[] memory commitments = new Bn254.G1Point[](2);
        commitments[0].copyFromG1(commitment1);
        commitments[1].copyFromG1(commitment2);

        return KZGChecker.batchCheck(
            challenges.lambda,
            points,
            evals,
            openings,
            commitments
        );
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

library Bn254 {
    uint256 constant private Q_MOD = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant private R_MOD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant private BN254_B_COEFF = 3;

    struct Fr {
        uint256 value;
    }

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function validateFr(Fr memory self) internal pure {
        require(self.value < R_MOD, "Fr is invalid");
    }

    function cloneFr(Fr memory self) internal pure returns (Fr memory) {
        return Fr({value: self.value});
    }

    function copyFromFr(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory result) {
        require(fr.value != 0);
        powIntoDest(fr, result, R_MOD - 2);
    }

    function inverseAssign(Fr memory fr) internal view {
        require(fr.value != 0);
        powIntoDest(fr, fr, R_MOD - 2);
    }

    function add(Fr memory self, Fr memory other) internal pure returns (Fr memory) {
        return Fr({value: addmod(self.value, other.value, R_MOD)});
    }

    function addAssign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, R_MOD);
    }

    function sub(Fr memory self, Fr memory other) internal pure returns (Fr memory) {
        return Fr({value: addmod(self.value, R_MOD - other.value, R_MOD)});
    }

    function subAssign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, R_MOD - other.value, R_MOD);
    }

    function mul(Fr memory self, Fr memory other) internal pure returns (Fr memory) {
        return Fr({value: mulmod(self.value, other.value, R_MOD)});
    }

    function mulAssign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, R_MOD);
    }

    function pow(Fr memory self, uint256 power) internal view returns (Fr memory result) {
        powIntoDest(self, result, power);
    }

    function powIntoDest(Fr memory self, Fr memory dest, uint256 power) internal view {
        uint256[6] memory input = [32, 32, 32, self.value, power, R_MOD];
        uint256[1] memory result;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success);
        dest.value = result[0];
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function validateG1(G1Point memory self) internal pure {
        if (self.X == 0 && self.Y == 0) {
            return;
        }

        // check encoding
        require(self.X < Q_MOD, "x axis isn't valid");
        require(self.Y < Q_MOD, "y axis isn't valid");
        // check on curve
        uint256 lhs = mulmod(self.Y, self.Y, Q_MOD); // y^2

        uint256 rhs = mulmod(self.X, self.X, Q_MOD); // x^2
        rhs = mulmod(rhs, self.X, Q_MOD); // x^3
        rhs = addmod(rhs, BN254_B_COEFF, Q_MOD); // x^3 + b
        require(lhs == rhs, "is not on curve");
    }

    function copyFromG1(G1Point memory self, G1Point memory other) internal pure {
        self.X = other.X;
        self.Y = other.Y;
    }

    function cloneG1(G1Point memory self) internal pure returns (G1Point memory result) {
        return G1Point(self.X, self.Y);
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form
        return G2Point(
            [
                0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            ],
            [
                0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            ]
        );
    }

    function pointNegate(G1Point memory self) internal pure returns (G1Point memory result) {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
        } else {
            result.X = self.X;
            result.Y = Q_MOD - self.Y;
        }
    }

    function pointNegateAssign(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0);
        } else {
            self.Y = Q_MOD - self.Y;
        }
    }

    function pointAdd(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        pointAddIntoDest(p1, p2, r);
        return r;
    }

    function pointAddAssign(G1Point memory p1, G1Point memory p2) internal view {
        pointAddIntoDest(p1, p2, p1);
    }

    function pointAddIntoDest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function pointSub(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        pointSubIntoDest(p1, p2, r);
        return r;
    }

    function pointSubAssign(G1Point memory p1, G1Point memory p2) internal view {
        pointSubIntoDest(p1, p2, p1);
    }

    function pointSubIntoDest(G1Point memory p1, G1Point memory p2, G1Point memory dest) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = Q_MOD - p2.Y;
            return;
        } else {
            uint256[4] memory input;
            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = Q_MOD - p2.Y;

            bool success = false;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success);
        }
    }

    function pointMul(G1Point memory p, Fr memory s) internal view returns (G1Point memory r) {
        pointMulIntoDest(p, s, r);
        return r;
    }

    function pointMulAssign(G1Point memory p, Fr memory s) internal view {
        pointMulIntoDest(p, s, p);
    }

    function pointMulIntoDest(G1Point memory p, Fr memory s, G1Point memory dest) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success);
    }

    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
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
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := staticcall(gas(), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        require(success);
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
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./Bn254.sol";

library Domain {
    uint256 constant public SIZE = 2 ** 26;

    function domainGenerator() internal pure returns (Bn254.Fr memory) {
        return Bn254.Fr(0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0);
    }

    function domainGeneratorInv() internal pure returns (Bn254.Fr memory) {
        return Bn254.Fr(0x0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0e0);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./Bn254.sol";

library KZGChecker {
    using Bn254 for Bn254.Fr;
    using Bn254 for Bn254.G1Point;

    function X2() internal pure returns (Bn254.G2Point memory) {
        return Bn254.G2Point(
            [
                0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
            ],
            [
                0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            ]
        );
    }

    function check(
        Bn254.Fr memory point,
        Bn254.Fr memory eval,
        Bn254.G1Point memory opening,
        Bn254.G1Point memory commitment
    ) view internal returns (bool) {
        Bn254.G1Point memory p1 = Bn254.P1();
        Bn254.G2Point memory p2 = Bn254.P2();
        Bn254.G2Point memory x2 = X2();

        Bn254.G1Point memory g1 = p1.pointMul(eval);
        g1.pointSubAssign(commitment);
        g1.pointSubAssign(opening.pointMul(point));

        return Bn254.pairingProd2(opening, x2, g1, p2);
    }

    function batchCheck(
        Bn254.Fr memory challenge,
        Bn254.Fr[] memory points,
        Bn254.Fr[] memory evals,
        Bn254.G1Point[] memory openings,
        Bn254.G1Point[] memory commitments
    ) view internal returns (bool) {
        require(points.length == evals.length, "Unmatched length");
        require(points.length == openings.length, "Unmatched length");
        require(points.length == commitments.length, "Unmatched length");
        
        Bn254.G1Point memory p1 = Bn254.P1();
        Bn254.G2Point memory p2 = Bn254.P2();
        Bn254.G2Point memory x2 = X2();

        Bn254.Fr memory u = Bn254.Fr(1);
        Bn254.Fr memory tmpFr = Bn254.Fr(0);
        Bn254.G1Point memory partA = Bn254.G1Point(0, 0);
        Bn254.G1Point memory partB = Bn254.G1Point(0, 0);
        Bn254.G1Point memory tmpG1 = Bn254.G1Point(0, 0);
        for (uint256 i = 0; i < points.length; i++) {
            tmpG1.copyFromG1(openings[i]);
            tmpG1.pointMulAssign(u);
            partA.pointAddAssign(tmpG1);

            tmpFr.copyFromFr(evals[i]);
            tmpFr.mulAssign(u);
            tmpG1.copyFromG1(p1);
            tmpG1.pointMulAssign(tmpFr);
            partB.pointAddAssign(tmpG1);
            tmpG1.copyFromG1(commitments[i]);
            tmpG1.pointMulAssign(u);
            partB.pointSubAssign(tmpG1);
            tmpFr.copyFromFr(points[i]);
            tmpFr.mulAssign(u);
            tmpG1.copyFromG1(openings[i]);
            tmpG1.pointMulAssign(tmpFr);
            partB.pointSubAssign(tmpG1);

            u.mulAssign(challenge);
        }
        // Pairing check
        return Bn254.pairingProd2(partA, x2, partB, p2);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

import "./Bn254.sol";

library TranscriptProtocol {
    using Bn254 for Bn254.Fr;

    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant private FR_MASK = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant private DST_0 = 0;
    uint32 constant private DST_1 = 1;
    uint32 constant private DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state0;
        bytes32 state1;
        uint32 counter;
    }

    function newTranscript() internal pure returns (Transcript memory t) {
        t.state0 = bytes32(0);
        t.state1 = bytes32(0);
        t.counter = 0;
    }

    function appendUint256(Transcript memory self, uint256 value) internal pure {
        bytes32 oldState = self.state0;
        self.state0 = keccak256(abi.encodePacked(DST_0, oldState, self.state1, value));
        self.state1 = keccak256(abi.encodePacked(DST_1, oldState, self.state1, value));
    }

    function appendFr(Transcript memory self, Bn254.Fr memory value) internal pure {
        appendUint256(self, value.value);
    }

    function appendG1(Transcript memory self, Bn254.G1Point memory p) internal pure {
        appendUint256(self, p.X);
        appendUint256(self, p.Y);
    }

    function challengeFr(Transcript memory self) internal pure returns (Bn254.Fr memory) {
        bytes32 query = keccak256(abi.encodePacked(DST_CHALLENGE, self.state0, self.state1, self.counter));
        self.counter += 1;
        return Bn254.Fr(uint256(query) & FR_MASK);
    }
}