// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interface/IEcdsaVerifier.sol";
import "./ecdsa_verifier.sol";

contract BSCBlockUpdaterBatch is Verifier {
    event MerkleRootRecorded(
        bytes32 parentMerkleRoot,
        bytes32 currentMerkleRoot,
        uint256 blockNumber
    );

    struct MerkleRootInfo {
        uint256 index;
        uint256 blockNumber;
        uint256 totalDifficulty;
    }

    uint256 public constant BATCH_SIZE = 32;

    uint256 public irreversibleSize = 1;

    uint256 public genesisBlockNumber;

    bytes32[] public canonical;

    IEcdsaVerifier public ecdsaVerifier;

    mapping(bytes32 => MerkleRootInfo) public merkleRoots;

    constructor(address ecdsaVerifierAddress) {
        ecdsaVerifier = IEcdsaVerifier(ecdsaVerifierAddress);
    }

    struct ParsedInput {
        bytes32 parentMerkleRoot;
        bytes32 currentMerkleRoot;
        uint256 validatorSetHash;
        uint256 totalDifficulty;
        uint256 lastBlockNumber;
    }

    function updateBlock(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory inputs
    ) public {
        ParsedInput memory parsedInput = _parseInput(inputs);
        uint256 totalDifficulty = parsedInput.totalDifficulty;
        bytes32 parentMerkleRoot = parsedInput.parentMerkleRoot;
        bytes32 currentMerkleRoot = parsedInput.currentMerkleRoot;
        uint256 blockNumber = parsedInput.lastBlockNumber;

        require(verifyProof(a, b, c, inputs), "verifyProof failed");

        if (canonical.length == 0) {
            // init
            _setGenesisBlock(currentMerkleRoot, blockNumber, totalDifficulty);
        } else {
            // make sure the known block
            MerkleRootInfo storage parentInfo = merkleRoots[parentMerkleRoot];
            require(
                parentMerkleRoot == canonical[0] || parentInfo.index != 0,
                "Cannot find parent"
            );
            uint256 currentIndex = parentInfo.index + 1;
            require(
                parentInfo.totalDifficulty < totalDifficulty,
                "Check totalDifficulty"
            );
            if (currentIndex >= canonical.length) {
                canonical.push(currentMerkleRoot);
            } else {
                //reorg
                require(
                    canonical[currentIndex] != currentMerkleRoot,
                    "Block header already exist"
                );
                require(
                    canonical.length - currentIndex <= irreversibleSize,
                    "Block header irreversible"
                );

                canonical[currentIndex] = currentMerkleRoot;
                for (uint256 i = canonical.length - 1; i > currentIndex; i--) {
                    delete merkleRoots[canonical[i]];
                    canonical.pop();
                }
            }
            MerkleRootInfo memory tempInfo = MerkleRootInfo(
                currentIndex,
                blockNumber,
                totalDifficulty
            );
            merkleRoots[currentMerkleRoot] = tempInfo;
        }
        emit MerkleRootRecorded(
            parentMerkleRoot,
            currentMerkleRoot,
            blockNumber
        );
    }

    function getHighestBlockInfo() public view returns (MerkleRootInfo memory) {
        uint256 index = canonical.length - 1;
        bytes32 merkleRoot = canonical[index];
        return merkleRoots[merkleRoot];
    }

    function checkBlockHash(
        bytes32 blockHash,
        bytes32 receiptsRoot,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        bytes32 merkleRoot = MerkleProof.processProof(
            merkleProof,
            keccak256(abi.encode(blockHash, receiptsRoot))
        );
        MerkleRootInfo memory merkleRootInfo = merkleRoots[merkleRoot];

        if (merkleRoot != canonical[merkleRootInfo.index]) {
            return false;
        }

        if (canonical.length - merkleRootInfo.index <= irreversibleSize) {
            return false;
        }

        return true;
    }

    function _setGenesisBlock(
        bytes32 merkleRoot,
        uint256 blockNumber,
        uint256 totalDifficulty
    ) internal {
        require(canonical.length == 0);
        MerkleRootInfo memory tempInfo = MerkleRootInfo(
            0,
            blockNumber,
            totalDifficulty
        );
        merkleRoots[merkleRoot] = tempInfo;
        canonical.push(merkleRoot);
        genesisBlockNumber = blockNumber - BATCH_SIZE + 1;
    }

    function _parseInput(uint256[8] memory inputs)
        internal
        pure
        returns (ParsedInput memory)
    {
        ParsedInput memory result;
        uint256 parentMTRoot = (inputs[1] << 128) | inputs[0];
        result.parentMerkleRoot = bytes32(parentMTRoot);

        uint256 currentMTRoot = (inputs[3] << 128) | inputs[2];
        result.currentMerkleRoot = bytes32(currentMTRoot);
        result.totalDifficulty = inputs[4];
        uint256 valSetHash = (inputs[6] << 128) | inputs[5];
        result.validatorSetHash = uint256(valSetHash);
        result.lastBlockNumber = inputs[7];
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEcdsaVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) external view returns (bool);
}

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
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

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
            switch success case 0 { invalid() }
        }

        require(success,"pairing-add-failed");
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
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
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
            switch success case 0 { invalid() }
        }

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract Verifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[9] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(12441151969386891262360661741730976569725956377357832128403512306977589068052), uint256(4101314235649177613421868521127299696934769195951735690420754995200949812688));
        vk.beta2 = Pairing.G2Point([uint256(6303960417058363542349196410383791520148888993829786500867654954855663507077), uint256(15088353784503865815306769930912067092414870543524098039196611052715882371193)], [uint256(17946196795363427683299280350807094507830444906721761420691130921511603085645), uint256(19660149512515491287894475944804889476270634811618303136615554077175336954940)]);
        vk.gamma2 = Pairing.G2Point([uint256(309384335809459689500695266233856169866266784836859123706069993041567716879), uint256(12545212714881110494697837460138306181935327902820896796644330770121640056346)], [uint256(2292663596877958428869729711497147993718429452011240306030251110496552253949), uint256(10138473508189105030255935382655336625009340227023152845647189982915446855791)]);
        vk.delta2 = Pairing.G2Point([uint256(7353681524080713135799032991354567629566297258463664656318494825486485083116), uint256(15145468506322990571612433377080861627657136155876196538542952518644891406680)], [uint256(2855489839418285575757575483075320040662713686927208827329644686028150652634), uint256(1658566715530061285437679868546778714938913539727478164185081826180085801707)]);   
        vk.IC[0] = Pairing.G1Point(uint256(5788553118853413002933622268017781160492591238903643428536856872209898517765), uint256(13076039976199393493248045220700464290596747935695877606549987597480452526346));   
        vk.IC[1] = Pairing.G1Point(uint256(16980069556096921540015641732308105600616892078961764772349376706398661158689), uint256(3995863168406974279812496967341324422047489621681670688948589957748135234841));   
        vk.IC[2] = Pairing.G1Point(uint256(16844848858240562567006934780169163070861828171218005552879850894171863695319), uint256(20446163090315869974851402738735824552981284143018349585097183103744335180951));   
        vk.IC[3] = Pairing.G1Point(uint256(3006051405312321851517862425807718412636971810985102260786770073401354393955), uint256(16832125553656004297497992064059065859292795861525062175906383270741183807485));   
        vk.IC[4] = Pairing.G1Point(uint256(20693849520049857386255208854362696113258360864352613275753447796758932242703), uint256(7871740235788638910889061065622238884574583350951992165081886129703577550636));   
        vk.IC[5] = Pairing.G1Point(uint256(4831436245474918116549548025698609853892551978216783672363425470087542950017), uint256(88624094046517820892942662020019291222299451354772809262183818681911329018));   
        vk.IC[6] = Pairing.G1Point(uint256(440923009093218765199820559016715674689370211659545743527443490103247082309), uint256(20631736506291706378443128986844822858037458318140753697661834330241189716553));   
        vk.IC[7] = Pairing.G1Point(uint256(19965310400812235940682633063673586810319850094324087696994982852457252278213), uint256(10125802807222608793839523566225597699839235908707197572785101230985791697720));   
        vk.IC[8] = Pairing.G1Point(uint256(9529973035165405606676221626734292987687615170847487216741295278007546314923), uint256(16995012525951582112603673398909699875718430586387867206319151598517280059844));
    }
    
    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[8] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

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
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}