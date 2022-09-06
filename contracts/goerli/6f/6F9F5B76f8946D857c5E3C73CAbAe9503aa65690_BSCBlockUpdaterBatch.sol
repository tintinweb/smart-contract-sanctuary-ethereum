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

        //require(verifyProof(a, b, c, inputs), "verifyProof failed");

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
        vk.alfa1 = Pairing.G1Point(uint256(5223377260428183758066973022908171974011931899852156098381182388038852588019), uint256(13193271244750604400357122233798406414361669749158511417150295103636512201796));
        vk.beta2 = Pairing.G2Point([uint256(5391156278880472905993954072976571779620670891056473357535670129795829090655), uint256(9311568949028840842475511303247653858246648933891628039738756062343224920904)], [uint256(18702585324151356057199032188373113367817154979527849870650570036345337143617), uint256(138772206157302791238901491001189579771820290740939951300846236148284611090)]);
        vk.gamma2 = Pairing.G2Point([uint256(16979418803232304617814019478033594806029057460771342548392039921964074905334), uint256(2372904428283060689535472947794972042078176908679189973681521609981387891092)], [uint256(14986819382143128992351734169568147729448609951830192229433400344041498174765), uint256(1875585436111009868060571848717856349561945120535167957088700605104069095090)]);
        vk.delta2 = Pairing.G2Point([uint256(9148032479281689951105431728749979093202105012577263851021760253481684900819), uint256(16216501632638339214769405861756316009849204680321731592603324969333464534627)], [uint256(10118014442888948080760991364461458706231287690292760609131873719780684559318), uint256(5665617472979733503708054479723176505258219335670738459186383951562351245407)]);   
        vk.IC[0] = Pairing.G1Point(uint256(934039552970685224391818973391097081989077311193445793633856333413924030335), uint256(2321194507166708327845523880760550192160946695726304506317610206505284750721));   
        vk.IC[1] = Pairing.G1Point(uint256(908780565603541955581683288986852028537154164779486679192239062261313624040), uint256(18391291663760436132590344001510207832507855031029502459582849219561013651435));   
        vk.IC[2] = Pairing.G1Point(uint256(873122347593552574452843139518478137746159373280205505487952824304112300919), uint256(11878549480571116845513170613314477094911257775935692362880116061233121332106));   
        vk.IC[3] = Pairing.G1Point(uint256(1186547887336617507220404899167728672009006016383678217708282244067732124303), uint256(14922682520571482938881210206868402991206224903191223887298163594872640152174));   
        vk.IC[4] = Pairing.G1Point(uint256(16462010963897774650441086837549014539598301484794996756446127313822246524730), uint256(21348223343836096997951052925857643295837978852743728946126144999307893437414));   
        vk.IC[5] = Pairing.G1Point(uint256(6766946045990707620791735126413861176556885070101864945758500512177907315105), uint256(11763027978962729661815423786163982849759575311455159770337149901325434319485));   
        vk.IC[6] = Pairing.G1Point(uint256(6788914461869679853401272683445561322429086715335733976068368199532802879013), uint256(12155705305848767114814105155286243677955275968143818110203859062004904103676));   
        vk.IC[7] = Pairing.G1Point(uint256(21267068075263538766307419413590205820447135768217112671058532006904118340131), uint256(9584861537237839645978916012625760585017891049575726610512597178910188635887));   
        vk.IC[8] = Pairing.G1Point(uint256(19884862303496634484894851926269170741042650336983487148709848187690479632345), uint256(19627773775073774697434111160147709340409405239200142240368221044322156546623));
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