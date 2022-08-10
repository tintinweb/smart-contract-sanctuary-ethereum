/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/cryptography/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/lockDesire/LockData.sol

pragma solidity ^0.8.4;

contract LockData {
    // merkle root to verify a nft
    bytes32 public immutable luckRoot;
    bytes32 public immutable desire1Root;
    bytes32 public immutable desire2Root;
    bytes32 public immutable desire3Root;
    bytes32 public immutable desire4Root;

    constructor(
        bytes32 luckRoot_,
        bytes32 desire1Root_,
        bytes32 desire2Root_,
        bytes32 desire3Root_,
        bytes32 desire4Root_
    ) {
        luckRoot = luckRoot_;
        desire1Root = desire1Root_;
        desire2Root = desire2Root_;
        desire3Root = desire3Root_;
        desire4Root = desire4Root_;
    }

    // function _initDesire1() internal {
    //     desire1 = [
    //         210,
    //         215,
    //         218,
    //         219,
    //         230,
    //         232,
    //         234,
    //         235,
    //         266,
    //         268,
    //         272,
    //         275,
    //         276,
    //         287,
    //         292,
    //         298,
    //         308,
    //         310,
    //         315,
    //         316,
    //         318,
    //         321,
    //         326,
    //         336,
    //         348,
    //         365,
    //         366,
    //         372,
    //         380,
    //         396,
    //         398,
    //         399,
    //         406,
    //         416,
    //         420,
    //         421,
    //         431,
    //         433,
    //         434,
    //         435,
    //         442,
    //         447,
    //         452,
    //         458,
    //         463,
    //         472,
    //         475,
    //         478,
    //         479,
    //         483,
    //         488,
    //         497,
    //         501,
    //         502,
    //         507,
    //         512,
    //         513,
    //         522,
    //         524,
    //         527,
    //         528,
    //         535,
    //         541,
    //         549,
    //         563,
    //         570,
    //         571,
    //         573,
    //         579,
    //         581,
    //         594,
    //         600,
    //         606,
    //         608,
    //         615,
    //         617,
    //         641,
    //         647,
    //         648,
    //         650,
    //         651,
    //         657,
    //         659,
    //         660,
    //         661,
    //         669,
    //         682,
    //         688,
    //         689,
    //         698,
    //         705,
    //         706,
    //         711,
    //         713,
    //         715,
    //         732,
    //         737,
    //         739,
    //         741,
    //         743,
    //         744,
    //         750,
    //         759,
    //         766,
    //         767,
    //         780,
    //         789,
    //         793,
    //         797,
    //         802,
    //         807,
    //         818,
    //         836,
    //         848,
    //         859,
    //         861,
    //         875,
    //         877,
    //         887,
    //         888,
    //         904,
    //         1037,
    //         1038,
    //         1059,
    //         1062,
    //         1066,
    //         1068,
    //         1072,
    //         1075,
    //         1081,
    //         1084,
    //         1088,
    //         1091,
    //         1104,
    //         1115,
    //         1119,
    //         1130,
    //         1133,
    //         1134,
    //         1151,
    //         1155,
    //         1163,
    //         1165,
    //         1174,
    //         1177,
    //         1185,
    //         1186,
    //         1188,
    //         1194,
    //         1198,
    //         1209,
    //         1217,
    //         1221,
    //         1230,
    //         1236,
    //         1238,
    //         1251,
    //         1253,
    //         1260,
    //         1263,
    //         1264,
    //         1276,
    //         1283,
    //         1284,
    //         1286,
    //         1293,
    //         1307,
    //         1309,
    //         1315,
    //         1318,
    //         2,
    //         3,
    //         4,
    //         5,
    //         6,
    //         7,
    //         8,
    //         9,
    //         10,
    //         11,
    //         12,
    //         13,
    //         14,
    //         15,
    //         16,
    //         17,
    //         18,
    //         19,
    //         20,
    //         21,
    //         22,
    //         23,
    //         24,
    //         25,
    //         26,
    //         27,
    //         28,
    //         29,
    //         30,
    //         31,
    //         32,
    //         33,
    //         34
    //     ];
    //     desire2 = [
    //         202,
    //         211,
    //         216,
    //         220,
    //         226,
    //         227,
    //         239,
    //         240,
    //         241,
    //         242,
    //         252,
    //         253,
    //         256,
    //         263,
    //         274,
    //         282,
    //         285,
    //         290,
    //         295,
    //         296,
    //         297,
    //         299,
    //         301,
    //         303,
    //         304,
    //         307,
    //         309,
    //         312,
    //         313,
    //         323,
    //         325,
    //         327,
    //         328,
    //         331,
    //         333,
    //         337,
    //         339,
    //         344,
    //         346,
    //         347,
    //         349,
    //         356,
    //         369,
    //         370,
    //         376,
    //         379,
    //         384,
    //         385,
    //         386,
    //         405,
    //         422,
    //         428,
    //         432,
    //         436,
    //         443,
    //         449,
    //         453,
    //         456,
    //         460,
    //         465,
    //         471,
    //         498,
    //         499,
    //         510,
    //         518,
    //         521,
    //         529,
    //         533,
    //         539,
    //         542,
    //         546,
    //         550,
    //         551,
    //         561,
    //         565,
    //         568,
    //         574,
    //         575,
    //         585,
    //         588,
    //         589,
    //         593,
    //         598,
    //         607,
    //         612,
    //         614,
    //         623,
    //         627,
    //         628,
    //         636,
    //         639,
    //         646,
    //         655,
    //         670,
    //         677,
    //         678,
    //         686,
    //         687,
    //         693,
    //         695,
    //         699,
    //         702,
    //         708,
    //         710,
    //         714,
    //         725,
    //         727,
    //         733,
    //         734,
    //         735,
    //         740,
    //         745,
    //         746,
    //         748,
    //         752,
    //         753,
    //         754,
    //         756,
    //         764,
    //         768,
    //         773,
    //         778,
    //         781,
    //         783,
    //         796,
    //         798,
    //         801,
    //         803,
    //         804,
    //         806,
    //         811,
    //         813,
    //         817,
    //         820,
    //         821,
    //         835,
    //         837,
    //         840,
    //         841,
    //         846,
    //         847,
    //         856,
    //         858,
    //         863,
    //         870,
    //         871,
    //         876,
    //         884,
    //         892,
    //         893,
    //         896,
    //         897,
    //         905,
    //         908,
    //         911,
    //         912,
    //         914,
    //         916,
    //         917,
    //         920,
    //         933,
    //         935,
    //         940,
    //         942,
    //         944,
    //         945,
    //         946,
    //         947,
    //         950,
    //         951,
    //         954,
    //         955,
    //         957,
    //         962,
    //         963,
    //         964,
    //         965,
    //         966,
    //         968,
    //         969,
    //         971,
    //         972,
    //         975,
    //         976,
    //         979,
    //         980,
    //         1022,
    //         1025,
    //         1028,
    //         1031,
    //         1032,
    //         1033,
    //         1034,
    //         1040,
    //         1043,
    //         1044,
    //         1047,
    //         1051,
    //         1054,
    //         1055,
    //         1061,
    //         1064,
    //         1067,
    //         1069,
    //         1071,
    //         1073,
    //         1076,
    //         1087,
    //         1092,
    //         1093,
    //         1098,
    //         1114,
    //         1116,
    //         1125,
    //         1127,
    //         1132,
    //         1139,
    //         1141,
    //         1143,
    //         1145,
    //         1149,
    //         1150,
    //         1152,
    //         1156,
    //         1157,
    //         1158,
    //         1160,
    //         1166,
    //         1169,
    //         1170,
    //         1172,
    //         1173,
    //         1175,
    //         1178,
    //         1179,
    //         1183,
    //         1193,
    //         1197,
    //         1211,
    //         1219,
    //         1220,
    //         1225,
    //         1228,
    //         1233,
    //         1243,
    //         1257,
    //         1265,
    //         1267,
    //         1268,
    //         1270,
    //         1274,
    //         1287,
    //         1288,
    //         1302,
    //         1305,
    //         1306,
    //         1310,
    //         1312,
    //         1313,
    //         1319,
    //         35,
    //         36,
    //         37,
    //         38,
    //         39,
    //         40,
    //         41,
    //         42,
    //         43,
    //         44,
    //         45,
    //         46,
    //         47,
    //         48,
    //         49,
    //         50,
    //         51,
    //         52,
    //         53,
    //         54,
    //         55,
    //         56,
    //         57,
    //         58,
    //         59,
    //         60,
    //         61,
    //         62,
    //         63,
    //         64,
    //         65,
    //         66,
    //         67,
    //         68,
    //         69,
    //         70,
    //         71,
    //         72,
    //         73,
    //         74,
    //         75,
    //         76,
    //         77,
    //         78,
    //         79
    //     ];
    //     desire3 = [
    //         203,
    //         204,
    //         205,
    //         207,
    //         213,
    //         214,
    //         221,
    //         224,
    //         228,
    //         229,
    //         231,
    //         233,
    //         236,
    //         237,
    //         244,
    //         245,
    //         246,
    //         247,
    //         250,
    //         254,
    //         255,
    //         258,
    //         259,
    //         260,
    //         261,
    //         262,
    //         269,
    //         270,
    //         273,
    //         277,
    //         278,
    //         280,
    //         281,
    //         283,
    //         286,
    //         289,
    //         294,
    //         300,
    //         306,
    //         311,
    //         314,
    //         320,
    //         322,
    //         330,
    //         334,
    //         338,
    //         340,
    //         341,
    //         345,
    //         354,
    //         357,
    //         360,
    //         361,
    //         363,
    //         367,
    //         368,
    //         373,
    //         374,
    //         375,
    //         377,
    //         378,
    //         382,
    //         383,
    //         387,
    //         389,
    //         390,
    //         391,
    //         392,
    //         393,
    //         395,
    //         400,
    //         401,
    //         403,
    //         404,
    //         407,
    //         409,
    //         410,
    //         411,
    //         413,
    //         423,
    //         425,
    //         430,
    //         437,
    //         438,
    //         445,
    //         450,
    //         451,
    //         454,
    //         455,
    //         457,
    //         459,
    //         461,
    //         466,
    //         467,
    //         470,
    //         473,
    //         474,
    //         481,
    //         484,
    //         486,
    //         487,
    //         489,
    //         490,
    //         491,
    //         492,
    //         503,
    //         505,
    //         508,
    //         514,
    //         515,
    //         516,
    //         519,
    //         520,
    //         523,
    //         526,
    //         530,
    //         532,
    //         537,
    //         538,
    //         540,
    //         544,
    //         552,
    //         553,
    //         556,
    //         557,
    //         564,
    //         566,
    //         586,
    //         590,
    //         591,
    //         592,
    //         596,
    //         599,
    //         601,
    //         604,
    //         605,
    //         611,
    //         618,
    //         620,
    //         621,
    //         629,
    //         630,
    //         631,
    //         634,
    //         637,
    //         638,
    //         640,
    //         643,
    //         653,
    //         664,
    //         665,
    //         666,
    //         667,
    //         668,
    //         675,
    //         679,
    //         680,
    //         684,
    //         691,
    //         692,
    //         694,
    //         701,
    //         704,
    //         707,
    //         709,
    //         717,
    //         720,
    //         721,
    //         723,
    //         724,
    //         726,
    //         728,
    //         730,
    //         742,
    //         747,
    //         758,
    //         760,
    //         761,
    //         765,
    //         769,
    //         770,
    //         772,
    //         776,
    //         782,
    //         784,
    //         786,
    //         790,
    //         791,
    //         794,
    //         795,
    //         799,
    //         800,
    //         805,
    //         808,
    //         810,
    //         812,
    //         815,
    //         819,
    //         822,
    //         825,
    //         827,
    //         831,
    //         839,
    //         843,
    //         844,
    //         845,
    //         849,
    //         851,
    //         853,
    //         854,
    //         857,
    //         860,
    //         864,
    //         865,
    //         868,
    //         869,
    //         873,
    //         879,
    //         880,
    //         881,
    //         883,
    //         889,
    //         890,
    //         891,
    //         898,
    //         901,
    //         906,
    //         907,
    //         909,
    //         913,
    //         915,
    //         922,
    //         924,
    //         925,
    //         927,
    //         928,
    //         936,
    //         939,
    //         943,
    //         958,
    //         960,
    //         967,
    //         970,
    //         973,
    //         974,
    //         977,
    //         981,
    //         982,
    //         983,
    //         984,
    //         985,
    //         986,
    //         990,
    //         992,
    //         993,
    //         995,
    //         996,
    //         997,
    //         1018,
    //         1021,
    //         1023,
    //         1024,
    //         1027,
    //         1029,
    //         1030,
    //         1039,
    //         1045,
    //         1046,
    //         1049,
    //         1052,
    //         1057,
    //         1060,
    //         1065,
    //         1070,
    //         1077,
    //         1078,
    //         1080,
    //         1086,
    //         1094,
    //         1095,
    //         1100,
    //         1103,
    //         1105,
    //         1106,
    //         1107,
    //         1111,
    //         1113,
    //         1117,
    //         1121,
    //         1123,
    //         1126,
    //         1128,
    //         1129,
    //         1136,
    //         1138,
    //         1140,
    //         1159,
    //         1162,
    //         1181,
    //         1184,
    //         1187,
    //         1190,
    //         1195,
    //         1199,
    //         1202,
    //         1205,
    //         1207,
    //         1213,
    //         1215,
    //         1218,
    //         1223,
    //         1226,
    //         1229,
    //         1232,
    //         1239,
    //         1240,
    //         1242,
    //         1245,
    //         1250,
    //         1252,
    //         1254,
    //         1255,
    //         1258,
    //         1259,
    //         1262,
    //         1269,
    //         1271,
    //         1272,
    //         1277,
    //         1278,
    //         1279,
    //         1280,
    //         1282,
    //         1285,
    //         1289,
    //         1295,
    //         1296,
    //         1297,
    //         1299,
    //         1300,
    //         1301,
    //         1314,
    //         1316,
    //         1320,
    //         1321,
    //         80,
    //         81,
    //         82,
    //         83,
    //         84,
    //         85,
    //         86,
    //         87,
    //         88,
    //         89,
    //         90,
    //         91,
    //         92,
    //         93,
    //         94,
    //         95,
    //         96,
    //         97,
    //         98,
    //         99,
    //         100,
    //         101,
    //         102,
    //         103,
    //         104,
    //         105,
    //         106,
    //         107,
    //         108,
    //         109,
    //         110,
    //         111,
    //         112,
    //         113,
    //         114,
    //         115,
    //         116,
    //         117,
    //         118,
    //         119,
    //         120,
    //         121,
    //         122,
    //         123,
    //         124,
    //         125,
    //         126,
    //         127,
    //         128,
    //         129,
    //         130,
    //         131,
    //         132,
    //         133,
    //         134,
    //         135,
    //         136,
    //         137,
    //         138,
    //         139,
    //         140
    //     ];
    //     desire4 = [
    //         206,
    //         208,
    //         209,
    //         212,
    //         217,
    //         222,
    //         223,
    //         225,
    //         238,
    //         243,
    //         248,
    //         249,
    //         251,
    //         257,
    //         264,
    //         265,
    //         267,
    //         271,
    //         279,
    //         284,
    //         288,
    //         291,
    //         293,
    //         302,
    //         305,
    //         317,
    //         319,
    //         324,
    //         329,
    //         332,
    //         335,
    //         342,
    //         343,
    //         350,
    //         351,
    //         352,
    //         353,
    //         355,
    //         358,
    //         359,
    //         362,
    //         364,
    //         371,
    //         381,
    //         388,
    //         394,
    //         397,
    //         402,
    //         408,
    //         412,
    //         414,
    //         415,
    //         417,
    //         418,
    //         419,
    //         424,
    //         426,
    //         427,
    //         429,
    //         439,
    //         440,
    //         441,
    //         444,
    //         446,
    //         448,
    //         462,
    //         464,
    //         468,
    //         469,
    //         476,
    //         477,
    //         480,
    //         482,
    //         485,
    //         493,
    //         494,
    //         495,
    //         496,
    //         500,
    //         504,
    //         506,
    //         509,
    //         511,
    //         517,
    //         525,
    //         531,
    //         534,
    //         536,
    //         543,
    //         545,
    //         547,
    //         548,
    //         554,
    //         555,
    //         558,
    //         559,
    //         560,
    //         562,
    //         567,
    //         569,
    //         572,
    //         576,
    //         577,
    //         578,
    //         580,
    //         582,
    //         583,
    //         584,
    //         587,
    //         595,
    //         597,
    //         602,
    //         603,
    //         609,
    //         610,
    //         613,
    //         616,
    //         619,
    //         622,
    //         624,
    //         625,
    //         626,
    //         632,
    //         633,
    //         635,
    //         642,
    //         644,
    //         645,
    //         649,
    //         652,
    //         654,
    //         656,
    //         658,
    //         662,
    //         663,
    //         671,
    //         672,
    //         673,
    //         674,
    //         676,
    //         681,
    //         683,
    //         685,
    //         690,
    //         696,
    //         697,
    //         700,
    //         703,
    //         712,
    //         716,
    //         718,
    //         719,
    //         722,
    //         729,
    //         731,
    //         736,
    //         738,
    //         749,
    //         751,
    //         755,
    //         757,
    //         762,
    //         763,
    //         771,
    //         774,
    //         775,
    //         777,
    //         779,
    //         785,
    //         787,
    //         788,
    //         792,
    //         809,
    //         814,
    //         816,
    //         823,
    //         824,
    //         826,
    //         828,
    //         829,
    //         830,
    //         832,
    //         833,
    //         834,
    //         838,
    //         842,
    //         850,
    //         852,
    //         855,
    //         862,
    //         866,
    //         867,
    //         872,
    //         874,
    //         878,
    //         882,
    //         885,
    //         886,
    //         894,
    //         895,
    //         899,
    //         900,
    //         902,
    //         903,
    //         910,
    //         918,
    //         919,
    //         921,
    //         923,
    //         926,
    //         929,
    //         930,
    //         931,
    //         932,
    //         934,
    //         937,
    //         938,
    //         941,
    //         948,
    //         949,
    //         952,
    //         953,
    //         956,
    //         959,
    //         961,
    //         978,
    //         987,
    //         988,
    //         989,
    //         991,
    //         994,
    //         998,
    //         999,
    //         1000,
    //         1001,
    //         1002,
    //         1003,
    //         1004,
    //         1005,
    //         1006,
    //         1007,
    //         1008,
    //         1009,
    //         1010,
    //         1011,
    //         1012,
    //         1013,
    //         1014,
    //         1015,
    //         1016,
    //         1017,
    //         1019,
    //         1020,
    //         1026,
    //         1035,
    //         1036,
    //         1041,
    //         1042,
    //         1048,
    //         1050,
    //         1053,
    //         1056,
    //         1058,
    //         1063,
    //         1074,
    //         1079,
    //         1082,
    //         1083,
    //         1085,
    //         1089,
    //         1090,
    //         1096,
    //         1097,
    //         1099,
    //         1101,
    //         1102,
    //         1108,
    //         1109,
    //         1110,
    //         1112,
    //         1118,
    //         1120,
    //         1122,
    //         1124,
    //         1131,
    //         1135,
    //         1137,
    //         1142,
    //         1144,
    //         1146,
    //         1147,
    //         1148,
    //         1153,
    //         1154,
    //         1161,
    //         1164,
    //         1167,
    //         1168,
    //         1171,
    //         1176,
    //         1180,
    //         1182,
    //         1189,
    //         1191,
    //         1192,
    //         1196,
    //         1200,
    //         1201,
    //         1203,
    //         1204,
    //         1206,
    //         1208,
    //         1210,
    //         1212,
    //         1214,
    //         1216,
    //         1222,
    //         1224,
    //         1227,
    //         1231,
    //         1234,
    //         1235,
    //         1237,
    //         1241,
    //         1244,
    //         1246,
    //         1247,
    //         1248,
    //         1249,
    //         1256,
    //         1261,
    //         1266,
    //         1273,
    //         1275,
    //         1281,
    //         1290,
    //         1291,
    //         1292,
    //         1294,
    //         1298,
    //         1303,
    //         1304,
    //         1308,
    //         1311,
    //         1317,
    //         141,
    //         142,
    //         143,
    //         144,
    //         145,
    //         146,
    //         147,
    //         148,
    //         149,
    //         150,
    //         151,
    //         152,
    //         153,
    //         154,
    //         155,
    //         156,
    //         157,
    //         158,
    //         159,
    //         160,
    //         161,
    //         162,
    //         163,
    //         164,
    //         165,
    //         166,
    //         167,
    //         168,
    //         169,
    //         170,
    //         171,
    //         172,
    //         173,
    //         174,
    //         175,
    //         176,
    //         177,
    //         178,
    //         179,
    //         180,
    //         181,
    //         182,
    //         183,
    //         184,
    //         185,
    //         186,
    //         187,
    //         188,
    //         189,
    //         190,
    //         191,
    //         192,
    //         193,
    //         194,
    //         195,
    //         196,
    //         197,
    //         198,
    //         199,
    //         200,
    //         201
    //     ];
    // }

    // function _initDesireType() internal {
    //     // type 1
    //     desireType[210] = 1;
    //     desireType[215] = 1;
    //     desireType[218] = 1;
    //     desireType[219] = 1;
    //     desireType[230] = 1;
    //     desireType[232] = 1;
    //     desireType[234] = 1;
    //     desireType[235] = 1;
    //     desireType[266] = 1;
    //     desireType[268] = 1;
    //     desireType[272] = 1;
    //     desireType[275] = 1;
    //     desireType[276] = 1;
    //     desireType[287] = 1;
    //     desireType[292] = 1;
    //     desireType[298] = 1;
    //     desireType[308] = 1;
    //     desireType[310] = 1;
    //     desireType[315] = 1;
    //     desireType[316] = 1;
    //     desireType[318] = 1;
    //     desireType[321] = 1;
    //     desireType[326] = 1;
    //     desireType[336] = 1;
    //     desireType[348] = 1;
    //     desireType[365] = 1;
    //     desireType[366] = 1;
    //     desireType[372] = 1;
    //     desireType[380] = 1;
    //     desireType[396] = 1;
    //     desireType[398] = 1;
    //     desireType[399] = 1;
    //     desireType[406] = 1;
    //     desireType[416] = 1;
    //     desireType[420] = 1;
    //     desireType[421] = 1;
    //     desireType[431] = 1;
    //     desireType[433] = 1;
    //     desireType[434] = 1;
    //     desireType[435] = 1;
    //     desireType[442] = 1;
    //     desireType[447] = 1;
    //     desireType[452] = 1;
    //     desireType[458] = 1;
    //     desireType[463] = 1;
    //     desireType[472] = 1;
    //     desireType[475] = 1;
    //     desireType[478] = 1;
    //     desireType[479] = 1;
    //     desireType[483] = 1;
    //     desireType[488] = 1;
    //     desireType[497] = 1;
    //     desireType[501] = 1;
    //     desireType[502] = 1;
    //     desireType[507] = 1;
    //     desireType[512] = 1;
    //     desireType[513] = 1;
    //     desireType[522] = 1;
    //     desireType[524] = 1;
    //     desireType[527] = 1;
    //     desireType[528] = 1;
    //     desireType[535] = 1;
    //     desireType[541] = 1;
    //     desireType[549] = 1;
    //     desireType[563] = 1;
    //     desireType[570] = 1;
    //     desireType[571] = 1;
    //     desireType[573] = 1;
    //     desireType[579] = 1;
    //     desireType[581] = 1;
    //     desireType[594] = 1;
    //     desireType[600] = 1;
    //     desireType[606] = 1;
    //     desireType[608] = 1;
    //     desireType[615] = 1;
    //     desireType[617] = 1;
    //     desireType[641] = 1;
    //     desireType[647] = 1;
    //     desireType[648] = 1;
    //     desireType[650] = 1;
    //     desireType[651] = 1;
    //     desireType[657] = 1;
    //     desireType[659] = 1;
    //     desireType[660] = 1;
    //     desireType[661] = 1;
    //     desireType[669] = 1;
    //     desireType[682] = 1;
    //     desireType[688] = 1;
    //     desireType[689] = 1;
    //     desireType[698] = 1;
    //     desireType[705] = 1;
    //     desireType[706] = 1;
    //     desireType[711] = 1;
    //     desireType[713] = 1;
    //     desireType[715] = 1;
    //     desireType[732] = 1;
    //     desireType[737] = 1;
    //     desireType[739] = 1;
    //     desireType[741] = 1;
    //     desireType[743] = 1;
    //     desireType[744] = 1;
    //     desireType[750] = 1;
    //     desireType[759] = 1;
    //     desireType[766] = 1;
    //     desireType[767] = 1;
    //     desireType[780] = 1;
    //     desireType[789] = 1;
    //     desireType[793] = 1;
    //     desireType[797] = 1;
    //     desireType[802] = 1;
    //     desireType[807] = 1;
    //     desireType[818] = 1;
    //     desireType[836] = 1;
    //     desireType[848] = 1;
    //     desireType[859] = 1;
    //     desireType[861] = 1;
    //     desireType[875] = 1;
    //     desireType[877] = 1;
    //     desireType[887] = 1;
    //     desireType[888] = 1;
    //     desireType[904] = 1;
    //     desireType[1037] = 1;
    //     desireType[1038] = 1;
    //     desireType[1059] = 1;
    //     desireType[1062] = 1;
    //     desireType[1066] = 1;
    //     desireType[1068] = 1;
    //     desireType[1072] = 1;
    //     desireType[1075] = 1;
    //     desireType[1081] = 1;
    //     desireType[1084] = 1;
    //     desireType[1088] = 1;
    //     desireType[1091] = 1;
    //     desireType[1104] = 1;
    //     desireType[1115] = 1;
    //     desireType[1119] = 1;
    //     desireType[1130] = 1;
    //     desireType[1133] = 1;
    //     desireType[1134] = 1;
    //     desireType[1151] = 1;
    //     desireType[1155] = 1;
    //     desireType[1163] = 1;
    //     desireType[1165] = 1;
    //     desireType[1174] = 1;
    //     desireType[1177] = 1;
    //     desireType[1185] = 1;
    //     desireType[1186] = 1;
    //     desireType[1188] = 1;
    //     desireType[1194] = 1;
    //     desireType[1198] = 1;
    //     desireType[1209] = 1;
    //     desireType[1217] = 1;
    //     desireType[1221] = 1;
    //     desireType[1230] = 1;
    //     desireType[1236] = 1;
    //     desireType[1238] = 1;
    //     desireType[1251] = 1;
    //     desireType[1253] = 1;
    //     desireType[1260] = 1;
    //     desireType[1263] = 1;
    //     desireType[1264] = 1;
    //     desireType[1276] = 1;
    //     desireType[1283] = 1;
    //     desireType[1284] = 1;
    //     desireType[1286] = 1;
    //     desireType[1293] = 1;
    //     desireType[1307] = 1;
    //     desireType[1309] = 1;
    //     desireType[1315] = 1;
    //     desireType[1318] = 1;

    //     // type 2
    //     desireType[202] = 2;
    //     desireType[211] = 2;
    //     desireType[216] = 2;
    //     desireType[220] = 2;
    //     desireType[226] = 2;
    //     desireType[227] = 2;
    //     desireType[239] = 2;
    //     desireType[240] = 2;
    //     desireType[241] = 2;
    //     desireType[242] = 2;
    //     desireType[252] = 2;
    //     desireType[253] = 2;
    //     desireType[256] = 2;
    //     desireType[263] = 2;
    //     desireType[274] = 2;
    //     desireType[282] = 2;
    //     desireType[285] = 2;
    //     desireType[290] = 2;
    //     desireType[295] = 2;
    //     desireType[296] = 2;
    //     desireType[297] = 2;
    //     desireType[299] = 2;
    //     desireType[301] = 2;
    //     desireType[303] = 2;
    //     desireType[304] = 2;
    //     desireType[307] = 2;
    //     desireType[309] = 2;
    //     desireType[312] = 2;
    //     desireType[313] = 2;
    //     desireType[323] = 2;
    //     desireType[325] = 2;
    //     desireType[327] = 2;
    //     desireType[328] = 2;
    //     desireType[331] = 2;
    //     desireType[333] = 2;
    //     desireType[337] = 2;
    //     desireType[339] = 2;
    //     desireType[344] = 2;
    //     desireType[346] = 2;
    //     desireType[347] = 2;
    //     desireType[349] = 2;
    //     desireType[356] = 2;
    //     desireType[369] = 2;
    //     desireType[370] = 2;
    //     desireType[376] = 2;
    //     desireType[379] = 2;
    //     desireType[384] = 2;
    //     desireType[385] = 2;
    //     desireType[386] = 2;
    //     desireType[405] = 2;
    //     desireType[422] = 2;
    //     desireType[428] = 2;
    //     desireType[432] = 2;
    //     desireType[436] = 2;
    //     desireType[443] = 2;
    //     desireType[449] = 2;
    //     desireType[453] = 2;
    //     desireType[456] = 2;
    //     desireType[460] = 2;
    //     desireType[465] = 2;
    //     desireType[471] = 2;
    //     desireType[498] = 2;
    //     desireType[499] = 2;
    //     desireType[510] = 2;
    //     desireType[518] = 2;
    //     desireType[521] = 2;
    //     desireType[529] = 2;
    //     desireType[533] = 2;
    //     desireType[539] = 2;
    //     desireType[542] = 2;
    //     desireType[546] = 2;
    //     desireType[550] = 2;
    //     desireType[551] = 2;
    //     desireType[561] = 2;
    //     desireType[565] = 2;
    //     desireType[568] = 2;
    //     desireType[574] = 2;
    //     desireType[575] = 2;
    //     desireType[585] = 2;
    //     desireType[588] = 2;
    //     desireType[589] = 2;
    //     desireType[593] = 2;
    //     desireType[598] = 2;
    //     desireType[607] = 2;
    //     desireType[612] = 2;
    //     desireType[614] = 2;
    //     desireType[623] = 2;
    //     desireType[627] = 2;
    //     desireType[628] = 2;
    //     desireType[636] = 2;
    //     desireType[639] = 2;
    //     desireType[646] = 2;
    //     desireType[655] = 2;
    //     desireType[670] = 2;
    //     desireType[677] = 2;
    //     desireType[678] = 2;
    //     desireType[686] = 2;
    //     desireType[687] = 2;
    //     desireType[693] = 2;
    //     desireType[695] = 2;
    //     desireType[699] = 2;
    //     desireType[702] = 2;
    //     desireType[708] = 2;
    //     desireType[710] = 2;
    //     desireType[714] = 2;
    //     desireType[725] = 2;
    //     desireType[727] = 2;
    //     desireType[733] = 2;
    //     desireType[734] = 2;
    //     desireType[735] = 2;
    //     desireType[740] = 2;
    //     desireType[745] = 2;
    //     desireType[746] = 2;
    //     desireType[748] = 2;
    //     desireType[752] = 2;
    //     desireType[753] = 2;
    //     desireType[754] = 2;
    //     desireType[756] = 2;
    //     desireType[764] = 2;
    //     desireType[768] = 2;
    //     desireType[773] = 2;
    //     desireType[778] = 2;
    //     desireType[781] = 2;
    //     desireType[783] = 2;
    //     desireType[796] = 2;
    //     desireType[798] = 2;
    //     desireType[801] = 2;
    //     desireType[803] = 2;
    //     desireType[804] = 2;
    //     desireType[806] = 2;
    //     desireType[811] = 2;
    //     desireType[813] = 2;
    //     desireType[817] = 2;
    //     desireType[820] = 2;
    //     desireType[821] = 2;
    //     desireType[835] = 2;
    //     desireType[837] = 2;
    //     desireType[840] = 2;
    //     desireType[841] = 2;
    //     desireType[846] = 2;
    //     desireType[847] = 2;
    //     desireType[856] = 2;
    //     desireType[858] = 2;
    //     desireType[863] = 2;
    //     desireType[870] = 2;
    //     desireType[871] = 2;
    //     desireType[876] = 2;
    //     desireType[884] = 2;
    //     desireType[892] = 2;
    //     desireType[893] = 2;
    //     desireType[896] = 2;
    //     desireType[897] = 2;
    //     desireType[905] = 2;
    //     desireType[908] = 2;
    //     desireType[911] = 2;
    //     desireType[912] = 2;
    //     desireType[914] = 2;
    //     desireType[916] = 2;
    //     desireType[917] = 2;
    //     desireType[920] = 2;
    //     desireType[933] = 2;
    //     desireType[935] = 2;
    //     desireType[940] = 2;
    //     desireType[942] = 2;
    //     desireType[944] = 2;
    //     desireType[945] = 2;
    //     desireType[946] = 2;
    //     desireType[947] = 2;
    //     desireType[950] = 2;
    //     desireType[951] = 2;
    //     desireType[954] = 2;
    //     desireType[955] = 2;
    //     desireType[957] = 2;
    //     desireType[962] = 2;
    //     desireType[963] = 2;
    //     desireType[964] = 2;
    //     desireType[965] = 2;
    //     desireType[966] = 2;
    //     desireType[968] = 2;
    //     desireType[969] = 2;
    //     desireType[971] = 2;
    //     desireType[972] = 2;
    //     desireType[975] = 2;
    //     desireType[976] = 2;
    //     desireType[979] = 2;
    //     desireType[980] = 2;
    //     desireType[1022] = 2;
    //     desireType[1025] = 2;
    //     desireType[1028] = 2;
    //     desireType[1031] = 2;
    //     desireType[1032] = 2;
    //     desireType[1033] = 2;
    //     desireType[1034] = 2;
    //     desireType[1040] = 2;
    //     desireType[1043] = 2;
    //     desireType[1044] = 2;
    //     desireType[1047] = 2;
    //     desireType[1051] = 2;
    //     desireType[1054] = 2;
    //     desireType[1055] = 2;
    //     desireType[1061] = 2;
    //     desireType[1064] = 2;
    //     desireType[1067] = 2;
    //     desireType[1069] = 2;
    //     desireType[1071] = 2;
    //     desireType[1073] = 2;
    //     desireType[1076] = 2;
    //     desireType[1087] = 2;
    //     desireType[1092] = 2;
    //     desireType[1093] = 2;
    //     desireType[1098] = 2;
    //     desireType[1114] = 2;
    //     desireType[1116] = 2;
    //     desireType[1125] = 2;
    //     desireType[1127] = 2;
    //     desireType[1132] = 2;
    //     desireType[1139] = 2;
    //     desireType[1141] = 2;
    //     desireType[1143] = 2;
    //     desireType[1145] = 2;
    //     desireType[1149] = 2;
    //     desireType[1150] = 2;
    //     desireType[1152] = 2;
    //     desireType[1156] = 2;
    //     desireType[1157] = 2;
    //     desireType[1158] = 2;
    //     desireType[1160] = 2;
    //     desireType[1166] = 2;
    //     desireType[1169] = 2;
    //     desireType[1170] = 2;
    //     desireType[1172] = 2;
    //     desireType[1173] = 2;
    //     desireType[1175] = 2;
    //     desireType[1178] = 2;
    //     desireType[1179] = 2;
    //     desireType[1183] = 2;
    //     desireType[1193] = 2;
    //     desireType[1197] = 2;
    //     desireType[1211] = 2;
    //     desireType[1219] = 2;
    //     desireType[1220] = 2;
    //     desireType[1225] = 2;
    //     desireType[1228] = 2;
    //     desireType[1233] = 2;
    //     desireType[1243] = 2;
    //     desireType[1257] = 2;
    //     desireType[1265] = 2;
    //     desireType[1267] = 2;
    //     desireType[1268] = 2;
    //     desireType[1270] = 2;
    //     desireType[1274] = 2;
    //     desireType[1287] = 2;
    //     desireType[1288] = 2;
    //     desireType[1302] = 2;
    //     desireType[1305] = 2;
    //     desireType[1306] = 2;
    //     desireType[1310] = 2;
    //     desireType[1312] = 2;
    //     desireType[1313] = 2;
    //     desireType[1319] = 2;

    //     // type 3
    //     desireType[203] = 3;
    //     desireType[204] = 3;
    //     desireType[205] = 3;
    //     desireType[207] = 3;
    //     desireType[213] = 3;
    //     desireType[214] = 3;
    //     desireType[221] = 3;
    //     desireType[224] = 3;
    //     desireType[228] = 3;
    //     desireType[229] = 3;
    //     desireType[231] = 3;
    //     desireType[233] = 3;
    //     desireType[236] = 3;
    //     desireType[237] = 3;
    //     desireType[244] = 3;
    //     desireType[245] = 3;
    //     desireType[246] = 3;
    //     desireType[247] = 3;
    //     desireType[250] = 3;
    //     desireType[254] = 3;
    //     desireType[255] = 3;
    //     desireType[258] = 3;
    //     desireType[259] = 3;
    //     desireType[260] = 3;
    //     desireType[261] = 3;
    //     desireType[262] = 3;
    //     desireType[269] = 3;
    //     desireType[270] = 3;
    //     desireType[273] = 3;
    //     desireType[277] = 3;
    //     desireType[278] = 3;
    //     desireType[280] = 3;
    //     desireType[281] = 3;
    //     desireType[283] = 3;
    //     desireType[286] = 3;
    //     desireType[289] = 3;
    //     desireType[294] = 3;
    //     desireType[300] = 3;
    //     desireType[306] = 3;
    //     desireType[311] = 3;
    //     desireType[314] = 3;
    //     desireType[320] = 3;
    //     desireType[322] = 3;
    //     desireType[330] = 3;
    //     desireType[334] = 3;
    //     desireType[338] = 3;
    //     desireType[340] = 3;
    //     desireType[341] = 3;
    //     desireType[345] = 3;
    //     desireType[354] = 3;
    //     desireType[357] = 3;
    //     desireType[360] = 3;
    //     desireType[361] = 3;
    //     desireType[363] = 3;
    //     desireType[367] = 3;
    //     desireType[368] = 3;
    //     desireType[373] = 3;
    //     desireType[374] = 3;
    //     desireType[375] = 3;
    //     desireType[377] = 3;
    //     desireType[378] = 3;
    //     desireType[382] = 3;
    //     desireType[383] = 3;
    //     desireType[387] = 3;
    //     desireType[389] = 3;
    //     desireType[390] = 3;
    //     desireType[391] = 3;
    //     desireType[392] = 3;
    //     desireType[393] = 3;
    //     desireType[395] = 3;
    //     desireType[400] = 3;
    //     desireType[401] = 3;
    //     desireType[403] = 3;
    //     desireType[404] = 3;
    //     desireType[407] = 3;
    //     desireType[409] = 3;
    //     desireType[410] = 3;
    //     desireType[411] = 3;
    //     desireType[413] = 3;
    //     desireType[423] = 3;
    //     desireType[425] = 3;
    //     desireType[430] = 3;
    //     desireType[437] = 3;
    //     desireType[438] = 3;
    //     desireType[445] = 3;
    //     desireType[450] = 3;
    //     desireType[451] = 3;
    //     desireType[454] = 3;
    //     desireType[455] = 3;
    //     desireType[457] = 3;
    //     desireType[459] = 3;
    //     desireType[461] = 3;
    //     desireType[466] = 3;
    //     desireType[467] = 3;
    //     desireType[470] = 3;
    //     desireType[473] = 3;
    //     desireType[474] = 3;
    //     desireType[481] = 3;
    //     desireType[484] = 3;
    //     desireType[486] = 3;
    //     desireType[487] = 3;
    //     desireType[489] = 3;
    //     desireType[490] = 3;
    //     desireType[491] = 3;
    //     desireType[492] = 3;
    //     desireType[503] = 3;
    //     desireType[505] = 3;
    //     desireType[508] = 3;
    //     desireType[514] = 3;
    //     desireType[515] = 3;
    //     desireType[516] = 3;
    //     desireType[519] = 3;
    //     desireType[520] = 3;
    //     desireType[523] = 3;
    //     desireType[526] = 3;
    //     desireType[530] = 3;
    //     desireType[532] = 3;
    //     desireType[537] = 3;
    //     desireType[538] = 3;
    //     desireType[540] = 3;
    //     desireType[544] = 3;
    //     desireType[552] = 3;
    //     desireType[553] = 3;
    //     desireType[556] = 3;
    //     desireType[557] = 3;
    //     desireType[564] = 3;
    //     desireType[566] = 3;
    //     desireType[586] = 3;
    //     desireType[590] = 3;
    //     desireType[591] = 3;
    //     desireType[592] = 3;
    //     desireType[596] = 3;
    //     desireType[599] = 3;
    //     desireType[601] = 3;
    //     desireType[604] = 3;
    //     desireType[605] = 3;
    //     desireType[611] = 3;
    //     desireType[618] = 3;
    //     desireType[620] = 3;
    //     desireType[621] = 3;
    //     desireType[629] = 3;
    //     desireType[630] = 3;
    //     desireType[631] = 3;
    //     desireType[634] = 3;
    //     desireType[637] = 3;
    //     desireType[638] = 3;
    //     desireType[640] = 3;
    //     desireType[643] = 3;
    //     desireType[653] = 3;
    //     desireType[664] = 3;
    //     desireType[665] = 3;
    //     desireType[666] = 3;
    //     desireType[667] = 3;
    //     desireType[668] = 3;
    //     desireType[675] = 3;
    //     desireType[679] = 3;
    //     desireType[680] = 3;
    //     desireType[684] = 3;
    //     desireType[691] = 3;
    //     desireType[692] = 3;
    //     desireType[694] = 3;
    //     desireType[701] = 3;
    //     desireType[704] = 3;
    //     desireType[707] = 3;
    //     desireType[709] = 3;
    //     desireType[717] = 3;
    //     desireType[720] = 3;
    //     desireType[721] = 3;
    //     desireType[723] = 3;
    //     desireType[724] = 3;
    //     desireType[726] = 3;
    //     desireType[728] = 3;
    //     desireType[730] = 3;
    //     desireType[742] = 3;
    //     desireType[747] = 3;
    //     desireType[758] = 3;
    //     desireType[760] = 3;
    //     desireType[761] = 3;
    //     desireType[765] = 3;
    //     desireType[769] = 3;
    //     desireType[770] = 3;
    //     desireType[772] = 3;
    //     desireType[776] = 3;
    //     desireType[782] = 3;
    //     desireType[784] = 3;
    //     desireType[786] = 3;
    //     desireType[790] = 3;
    //     desireType[791] = 3;
    //     desireType[794] = 3;
    //     desireType[795] = 3;
    //     desireType[799] = 3;
    //     desireType[800] = 3;
    //     desireType[805] = 3;
    //     desireType[808] = 3;
    //     desireType[810] = 3;
    //     desireType[812] = 3;
    //     desireType[815] = 3;
    //     desireType[819] = 3;
    //     desireType[822] = 3;
    //     desireType[825] = 3;
    //     desireType[827] = 3;
    //     desireType[831] = 3;
    //     desireType[839] = 3;
    //     desireType[843] = 3;
    //     desireType[844] = 3;
    //     desireType[845] = 3;
    //     desireType[849] = 3;
    //     desireType[851] = 3;
    //     desireType[853] = 3;
    //     desireType[854] = 3;
    //     desireType[857] = 3;
    //     desireType[860] = 3;
    //     desireType[864] = 3;
    //     desireType[865] = 3;
    //     desireType[868] = 3;
    //     desireType[869] = 3;
    //     desireType[873] = 3;
    //     desireType[879] = 3;
    //     desireType[880] = 3;
    //     desireType[881] = 3;
    //     desireType[883] = 3;
    //     desireType[889] = 3;
    //     desireType[890] = 3;
    //     desireType[891] = 3;
    //     desireType[898] = 3;
    //     desireType[901] = 3;
    //     desireType[906] = 3;
    //     desireType[907] = 3;
    //     desireType[909] = 3;
    //     desireType[913] = 3;
    //     desireType[915] = 3;
    //     desireType[922] = 3;
    //     desireType[924] = 3;
    //     desireType[925] = 3;
    //     desireType[927] = 3;
    //     desireType[928] = 3;
    //     desireType[936] = 3;
    //     desireType[939] = 3;
    //     desireType[943] = 3;
    //     desireType[958] = 3;
    //     desireType[960] = 3;
    //     desireType[967] = 3;
    //     desireType[970] = 3;
    //     desireType[973] = 3;
    //     desireType[974] = 3;
    //     desireType[977] = 3;
    //     desireType[981] = 3;
    //     desireType[982] = 3;
    //     desireType[983] = 3;
    //     desireType[984] = 3;
    //     desireType[985] = 3;
    //     desireType[986] = 3;
    //     desireType[990] = 3;
    //     desireType[992] = 3;
    //     desireType[993] = 3;
    //     desireType[995] = 3;
    //     desireType[996] = 3;
    //     desireType[997] = 3;
    //     desireType[1018] = 3;
    //     desireType[1021] = 3;
    //     desireType[1023] = 3;
    //     desireType[1024] = 3;
    //     desireType[1027] = 3;
    //     desireType[1029] = 3;
    //     desireType[1030] = 3;
    //     desireType[1039] = 3;
    //     desireType[1045] = 3;
    //     desireType[1046] = 3;
    //     desireType[1049] = 3;
    //     desireType[1052] = 3;
    //     desireType[1057] = 3;
    //     desireType[1060] = 3;
    //     desireType[1065] = 3;
    //     desireType[1070] = 3;
    //     desireType[1077] = 3;
    //     desireType[1078] = 3;
    //     desireType[1080] = 3;
    //     desireType[1086] = 3;
    //     desireType[1094] = 3;
    //     desireType[1095] = 3;
    //     desireType[1100] = 3;
    //     desireType[1103] = 3;
    //     desireType[1105] = 3;
    //     desireType[1106] = 3;
    //     desireType[1107] = 3;
    //     desireType[1111] = 3;
    //     desireType[1113] = 3;
    //     desireType[1117] = 3;
    //     desireType[1121] = 3;
    //     desireType[1123] = 3;
    //     desireType[1126] = 3;
    //     desireType[1128] = 3;
    //     desireType[1129] = 3;
    //     desireType[1136] = 3;
    //     desireType[1138] = 3;
    //     desireType[1140] = 3;
    //     desireType[1159] = 3;
    //     desireType[1162] = 3;
    //     desireType[1181] = 3;
    //     desireType[1184] = 3;
    //     desireType[1187] = 3;
    //     desireType[1190] = 3;
    //     desireType[1195] = 3;
    //     desireType[1199] = 3;
    //     desireType[1202] = 3;
    //     desireType[1205] = 3;
    //     desireType[1207] = 3;
    //     desireType[1213] = 3;
    //     desireType[1215] = 3;
    //     desireType[1218] = 3;
    //     desireType[1223] = 3;
    //     desireType[1226] = 3;
    //     desireType[1229] = 3;
    //     desireType[1232] = 3;
    //     desireType[1239] = 3;
    //     desireType[1240] = 3;
    //     desireType[1242] = 3;
    //     desireType[1245] = 3;
    //     desireType[1250] = 3;
    //     desireType[1252] = 3;
    //     desireType[1254] = 3;
    //     desireType[1255] = 3;
    //     desireType[1258] = 3;
    //     desireType[1259] = 3;
    //     desireType[1262] = 3;
    //     desireType[1269] = 3;
    //     desireType[1271] = 3;
    //     desireType[1272] = 3;
    //     desireType[1277] = 3;
    //     desireType[1278] = 3;
    //     desireType[1279] = 3;
    //     desireType[1280] = 3;
    //     desireType[1282] = 3;
    //     desireType[1285] = 3;
    //     desireType[1289] = 3;
    //     desireType[1295] = 3;
    //     desireType[1296] = 3;
    //     desireType[1297] = 3;
    //     desireType[1299] = 3;
    //     desireType[1300] = 3;
    //     desireType[1301] = 3;
    //     desireType[1314] = 3;
    //     desireType[1316] = 3;
    //     desireType[1320] = 3;
    //     desireType[1321] = 3;

    //     // type 4
    //     desireType[206] = 4;
    //     desireType[208] = 4;
    //     desireType[209] = 4;
    //     desireType[212] = 4;
    //     desireType[217] = 4;
    //     desireType[222] = 4;
    //     desireType[223] = 4;
    //     desireType[225] = 4;
    //     desireType[238] = 4;
    //     desireType[243] = 4;
    //     desireType[248] = 4;
    //     desireType[249] = 4;
    //     desireType[251] = 4;
    //     desireType[257] = 4;
    //     desireType[264] = 4;
    //     desireType[265] = 4;
    //     desireType[267] = 4;
    //     desireType[271] = 4;
    //     desireType[279] = 4;
    //     desireType[284] = 4;
    //     desireType[288] = 4;
    //     desireType[291] = 4;
    //     desireType[293] = 4;
    //     desireType[302] = 4;
    //     desireType[305] = 4;
    //     desireType[317] = 4;
    //     desireType[319] = 4;
    //     desireType[324] = 4;
    //     desireType[329] = 4;
    //     desireType[332] = 4;
    //     desireType[335] = 4;
    //     desireType[342] = 4;
    //     desireType[343] = 4;
    //     desireType[350] = 4;
    //     desireType[351] = 4;
    //     desireType[352] = 4;
    //     desireType[353] = 4;
    //     desireType[355] = 4;
    //     desireType[358] = 4;
    //     desireType[359] = 4;
    //     desireType[362] = 4;
    //     desireType[364] = 4;
    //     desireType[371] = 4;
    //     desireType[381] = 4;
    //     desireType[388] = 4;
    //     desireType[394] = 4;
    //     desireType[397] = 4;
    //     desireType[402] = 4;
    //     desireType[408] = 4;
    //     desireType[412] = 4;
    //     desireType[414] = 4;
    //     desireType[415] = 4;
    //     desireType[417] = 4;
    //     desireType[418] = 4;
    //     desireType[419] = 4;
    //     desireType[424] = 4;
    //     desireType[426] = 4;
    //     desireType[427] = 4;
    //     desireType[429] = 4;
    //     desireType[439] = 4;
    //     desireType[440] = 4;
    //     desireType[441] = 4;
    //     desireType[444] = 4;
    //     desireType[446] = 4;
    //     desireType[448] = 4;
    //     desireType[462] = 4;
    //     desireType[464] = 4;
    //     desireType[468] = 4;
    //     desireType[469] = 4;
    //     desireType[476] = 4;
    //     desireType[477] = 4;
    //     desireType[480] = 4;
    //     desireType[482] = 4;
    //     desireType[485] = 4;
    //     desireType[493] = 4;
    //     desireType[494] = 4;
    //     desireType[495] = 4;
    //     desireType[496] = 4;
    //     desireType[500] = 4;
    //     desireType[504] = 4;
    //     desireType[506] = 4;
    //     desireType[509] = 4;
    //     desireType[511] = 4;
    //     desireType[517] = 4;
    //     desireType[525] = 4;
    //     desireType[531] = 4;
    //     desireType[534] = 4;
    //     desireType[536] = 4;
    //     desireType[543] = 4;
    //     desireType[545] = 4;
    //     desireType[547] = 4;
    //     desireType[548] = 4;
    //     desireType[554] = 4;
    //     desireType[555] = 4;
    //     desireType[558] = 4;
    //     desireType[559] = 4;
    //     desireType[560] = 4;
    //     desireType[562] = 4;
    //     desireType[567] = 4;
    //     desireType[569] = 4;
    //     desireType[572] = 4;
    //     desireType[576] = 4;
    //     desireType[577] = 4;
    //     desireType[578] = 4;
    //     desireType[580] = 4;
    //     desireType[582] = 4;
    //     desireType[583] = 4;
    //     desireType[584] = 4;
    //     desireType[587] = 4;
    //     desireType[595] = 4;
    //     desireType[597] = 4;
    //     desireType[602] = 4;
    //     desireType[603] = 4;
    //     desireType[609] = 4;
    //     desireType[610] = 4;
    //     desireType[613] = 4;
    //     desireType[616] = 4;
    //     desireType[619] = 4;
    //     desireType[622] = 4;
    //     desireType[624] = 4;
    //     desireType[625] = 4;
    //     desireType[626] = 4;
    //     desireType[632] = 4;
    //     desireType[633] = 4;
    //     desireType[635] = 4;
    //     desireType[642] = 4;
    //     desireType[644] = 4;
    //     desireType[645] = 4;
    //     desireType[649] = 4;
    //     desireType[652] = 4;
    //     desireType[654] = 4;
    //     desireType[656] = 4;
    //     desireType[658] = 4;
    //     desireType[662] = 4;
    //     desireType[663] = 4;
    //     desireType[671] = 4;
    //     desireType[672] = 4;
    //     desireType[673] = 4;
    //     desireType[674] = 4;
    //     desireType[676] = 4;
    //     desireType[681] = 4;
    //     desireType[683] = 4;
    //     desireType[685] = 4;
    //     desireType[690] = 4;
    //     desireType[696] = 4;
    //     desireType[697] = 4;
    //     desireType[700] = 4;
    //     desireType[703] = 4;
    //     desireType[712] = 4;
    //     desireType[716] = 4;
    //     desireType[718] = 4;
    //     desireType[719] = 4;
    //     desireType[722] = 4;
    //     desireType[729] = 4;
    //     desireType[731] = 4;
    //     desireType[736] = 4;
    //     desireType[738] = 4;
    //     desireType[749] = 4;
    //     desireType[751] = 4;
    //     desireType[755] = 4;
    //     desireType[757] = 4;
    //     desireType[762] = 4;
    //     desireType[763] = 4;
    //     desireType[771] = 4;
    //     desireType[774] = 4;
    //     desireType[775] = 4;
    //     desireType[777] = 4;
    //     desireType[779] = 4;
    //     desireType[785] = 4;
    //     desireType[787] = 4;
    //     desireType[788] = 4;
    //     desireType[792] = 4;
    //     desireType[809] = 4;
    //     desireType[814] = 4;
    //     desireType[816] = 4;
    //     desireType[823] = 4;
    //     desireType[824] = 4;
    //     desireType[826] = 4;
    //     desireType[828] = 4;
    //     desireType[829] = 4;
    //     desireType[830] = 4;
    //     desireType[832] = 4;
    //     desireType[833] = 4;
    //     desireType[834] = 4;
    //     desireType[838] = 4;
    //     desireType[842] = 4;
    //     desireType[850] = 4;
    //     desireType[852] = 4;
    //     desireType[855] = 4;
    //     desireType[862] = 4;
    //     desireType[866] = 4;
    //     desireType[867] = 4;
    //     desireType[872] = 4;
    //     desireType[874] = 4;
    //     desireType[878] = 4;
    //     desireType[882] = 4;
    //     desireType[885] = 4;
    //     desireType[886] = 4;
    //     desireType[894] = 4;
    //     desireType[895] = 4;
    //     desireType[899] = 4;
    //     desireType[900] = 4;
    //     desireType[902] = 4;
    //     desireType[903] = 4;
    //     desireType[910] = 4;
    //     desireType[918] = 4;
    //     desireType[919] = 4;
    //     desireType[921] = 4;
    //     desireType[923] = 4;
    //     desireType[926] = 4;
    //     desireType[929] = 4;
    //     desireType[930] = 4;
    //     desireType[931] = 4;
    //     desireType[932] = 4;
    //     desireType[934] = 4;
    //     desireType[937] = 4;
    //     desireType[938] = 4;
    //     desireType[941] = 4;
    //     desireType[948] = 4;
    //     desireType[949] = 4;
    //     desireType[952] = 4;
    //     desireType[953] = 4;
    //     desireType[956] = 4;
    //     desireType[959] = 4;
    //     desireType[961] = 4;
    //     desireType[978] = 4;
    //     desireType[987] = 4;
    //     desireType[988] = 4;
    //     desireType[989] = 4;
    //     desireType[991] = 4;
    //     desireType[994] = 4;
    //     desireType[998] = 4;
    //     desireType[999] = 4;
    //     desireType[1000] = 4;
    //     desireType[1001] = 4;
    //     desireType[1002] = 4;
    //     desireType[1003] = 4;
    //     desireType[1004] = 4;
    //     desireType[1005] = 4;
    //     desireType[1006] = 4;
    //     desireType[1007] = 4;
    //     desireType[1008] = 4;
    //     desireType[1009] = 4;
    //     desireType[1010] = 4;
    //     desireType[1011] = 4;
    //     desireType[1012] = 4;
    //     desireType[1013] = 4;
    //     desireType[1014] = 4;
    //     desireType[1015] = 4;
    //     desireType[1016] = 4;
    //     desireType[1017] = 4;
    //     desireType[1019] = 4;
    //     desireType[1020] = 4;
    //     desireType[1026] = 4;
    //     desireType[1035] = 4;
    //     desireType[1036] = 4;
    //     desireType[1041] = 4;
    //     desireType[1042] = 4;
    //     desireType[1048] = 4;
    //     desireType[1050] = 4;
    //     desireType[1053] = 4;
    //     desireType[1056] = 4;
    //     desireType[1058] = 4;
    //     desireType[1063] = 4;
    //     desireType[1074] = 4;
    //     desireType[1079] = 4;
    //     desireType[1082] = 4;
    //     desireType[1083] = 4;
    //     desireType[1085] = 4;
    //     desireType[1089] = 4;
    //     desireType[1090] = 4;
    //     desireType[1096] = 4;
    //     desireType[1097] = 4;
    //     desireType[1099] = 4;
    //     desireType[1101] = 4;
    //     desireType[1102] = 4;
    //     desireType[1108] = 4;
    //     desireType[1109] = 4;
    //     desireType[1110] = 4;
    //     desireType[1112] = 4;
    //     desireType[1118] = 4;
    //     desireType[1120] = 4;
    //     desireType[1122] = 4;
    //     desireType[1124] = 4;
    //     desireType[1131] = 4;
    //     desireType[1135] = 4;
    //     desireType[1137] = 4;
    //     desireType[1142] = 4;
    //     desireType[1144] = 4;
    //     desireType[1146] = 4;
    //     desireType[1147] = 4;
    //     desireType[1148] = 4;
    //     desireType[1153] = 4;
    //     desireType[1154] = 4;
    //     desireType[1161] = 4;
    //     desireType[1164] = 4;
    //     desireType[1167] = 4;
    //     desireType[1168] = 4;
    //     desireType[1171] = 4;
    //     desireType[1176] = 4;
    //     desireType[1180] = 4;
    //     desireType[1182] = 4;
    //     desireType[1189] = 4;
    //     desireType[1191] = 4;
    //     desireType[1192] = 4;
    //     desireType[1196] = 4;
    //     desireType[1200] = 4;
    //     desireType[1201] = 4;
    //     desireType[1203] = 4;
    //     desireType[1204] = 4;
    //     desireType[1206] = 4;
    //     desireType[1208] = 4;
    //     desireType[1210] = 4;
    //     desireType[1212] = 4;
    //     desireType[1214] = 4;
    //     desireType[1216] = 4;
    //     desireType[1222] = 4;
    //     desireType[1224] = 4;
    //     desireType[1227] = 4;
    //     desireType[1231] = 4;
    //     desireType[1234] = 4;
    //     desireType[1235] = 4;
    //     desireType[1237] = 4;
    //     desireType[1241] = 4;
    //     desireType[1244] = 4;
    //     desireType[1246] = 4;
    //     desireType[1247] = 4;
    //     desireType[1248] = 4;
    //     desireType[1249] = 4;
    //     desireType[1256] = 4;
    //     desireType[1261] = 4;
    //     desireType[1266] = 4;
    //     desireType[1273] = 4;
    //     desireType[1275] = 4;
    //     desireType[1281] = 4;
    //     desireType[1290] = 4;
    //     desireType[1291] = 4;
    //     desireType[1292] = 4;
    //     desireType[1294] = 4;
    //     desireType[1298] = 4;
    //     desireType[1303] = 4;
    //     desireType[1304] = 4;
    //     desireType[1308] = 4;
    //     desireType[1311] = 4;
    //     desireType[1317] = 4;

    //     // type 1
    //     desireType[2] = 1;
    //     desireType[3] = 1;
    //     desireType[4] = 1;
    //     desireType[5] = 1;
    //     desireType[6] = 1;
    //     desireType[7] = 1;
    //     desireType[8] = 1;
    //     desireType[9] = 1;
    //     desireType[10] = 1;
    //     desireType[11] = 1;
    //     desireType[12] = 1;
    //     desireType[13] = 1;
    //     desireType[14] = 1;
    //     desireType[15] = 1;
    //     desireType[16] = 1;
    //     desireType[17] = 1;
    //     desireType[18] = 1;
    //     desireType[19] = 1;
    //     desireType[20] = 1;
    //     desireType[21] = 1;
    //     desireType[22] = 1;
    //     desireType[23] = 1;
    //     desireType[24] = 1;
    //     desireType[25] = 1;
    //     desireType[26] = 1;
    //     desireType[27] = 1;
    //     desireType[28] = 1;
    //     desireType[29] = 1;
    //     desireType[30] = 1;
    //     desireType[31] = 1;
    //     desireType[32] = 1;
    //     desireType[33] = 1;
    //     desireType[34] = 1;

    //     // type 2
    //     desireType[35] = 2;
    //     desireType[36] = 2;
    //     desireType[37] = 2;
    //     desireType[38] = 2;
    //     desireType[39] = 2;
    //     desireType[40] = 2;
    //     desireType[41] = 2;
    //     desireType[42] = 2;
    //     desireType[43] = 2;
    //     desireType[44] = 2;
    //     desireType[45] = 2;
    //     desireType[46] = 2;
    //     desireType[47] = 2;
    //     desireType[48] = 2;
    //     desireType[49] = 2;
    //     desireType[50] = 2;
    //     desireType[51] = 2;
    //     desireType[52] = 2;
    //     desireType[53] = 2;
    //     desireType[54] = 2;
    //     desireType[55] = 2;
    //     desireType[56] = 2;
    //     desireType[57] = 2;
    //     desireType[58] = 2;
    //     desireType[59] = 2;
    //     desireType[60] = 2;
    //     desireType[61] = 2;
    //     desireType[62] = 2;
    //     desireType[63] = 2;
    //     desireType[64] = 2;
    //     desireType[65] = 2;
    //     desireType[66] = 2;
    //     desireType[67] = 2;
    //     desireType[68] = 2;
    //     desireType[69] = 2;
    //     desireType[70] = 2;
    //     desireType[71] = 2;
    //     desireType[72] = 2;
    //     desireType[73] = 2;
    //     desireType[74] = 2;
    //     desireType[75] = 2;
    //     desireType[76] = 2;
    //     desireType[77] = 2;
    //     desireType[78] = 2;
    //     desireType[79] = 2;

    //     // type 3
    //     desireType[80] = 3;
    //     desireType[81] = 3;
    //     desireType[82] = 3;
    //     desireType[83] = 3;
    //     desireType[84] = 3;
    //     desireType[85] = 3;
    //     desireType[86] = 3;
    //     desireType[87] = 3;
    //     desireType[88] = 3;
    //     desireType[89] = 3;
    //     desireType[90] = 3;
    //     desireType[91] = 3;
    //     desireType[92] = 3;
    //     desireType[93] = 3;
    //     desireType[94] = 3;
    //     desireType[95] = 3;
    //     desireType[96] = 3;
    //     desireType[97] = 3;
    //     desireType[98] = 3;
    //     desireType[99] = 3;
    //     desireType[100] = 3;
    //     desireType[101] = 3;
    //     desireType[102] = 3;
    //     desireType[103] = 3;
    //     desireType[104] = 3;
    //     desireType[105] = 3;
    //     desireType[106] = 3;
    //     desireType[107] = 3;
    //     desireType[108] = 3;
    //     desireType[109] = 3;
    //     desireType[110] = 3;
    //     desireType[111] = 3;
    //     desireType[112] = 3;
    //     desireType[113] = 3;
    //     desireType[114] = 3;
    //     desireType[115] = 3;
    //     desireType[116] = 3;
    //     desireType[117] = 3;
    //     desireType[118] = 3;
    //     desireType[119] = 3;
    //     desireType[120] = 3;
    //     desireType[121] = 3;
    //     desireType[122] = 3;
    //     desireType[123] = 3;
    //     desireType[124] = 3;
    //     desireType[125] = 3;
    //     desireType[126] = 3;
    //     desireType[127] = 3;
    //     desireType[128] = 3;
    //     desireType[129] = 3;
    //     desireType[130] = 3;
    //     desireType[131] = 3;
    //     desireType[132] = 3;
    //     desireType[133] = 3;
    //     desireType[134] = 3;
    //     desireType[135] = 3;
    //     desireType[136] = 3;
    //     desireType[137] = 3;
    //     desireType[138] = 3;
    //     desireType[139] = 3;
    //     desireType[140] = 3;

    //     // type 4
    //     desireType[141] = 4;
    //     desireType[142] = 4;
    //     desireType[143] = 4;
    //     desireType[144] = 4;
    //     desireType[145] = 4;
    //     desireType[146] = 4;
    //     desireType[147] = 4;
    //     desireType[148] = 4;
    //     desireType[149] = 4;
    //     desireType[150] = 4;
    //     desireType[151] = 4;
    //     desireType[152] = 4;
    //     desireType[153] = 4;
    //     desireType[154] = 4;
    //     desireType[155] = 4;
    //     desireType[156] = 4;
    //     desireType[157] = 4;
    //     desireType[158] = 4;
    //     desireType[159] = 4;
    //     desireType[160] = 4;
    //     desireType[161] = 4;
    //     desireType[162] = 4;
    //     desireType[163] = 4;
    //     desireType[164] = 4;
    //     desireType[165] = 4;
    //     desireType[166] = 4;
    //     desireType[167] = 4;
    //     desireType[168] = 4;
    //     desireType[169] = 4;
    //     desireType[170] = 4;
    //     desireType[171] = 4;
    //     desireType[172] = 4;
    //     desireType[173] = 4;
    //     desireType[174] = 4;
    //     desireType[175] = 4;
    //     desireType[176] = 4;
    //     desireType[177] = 4;
    //     desireType[178] = 4;
    //     desireType[179] = 4;
    //     desireType[180] = 4;
    //     desireType[181] = 4;
    //     desireType[182] = 4;
    //     desireType[183] = 4;
    //     desireType[184] = 4;
    //     desireType[185] = 4;
    //     desireType[186] = 4;
    //     desireType[187] = 4;
    //     desireType[188] = 4;
    //     desireType[189] = 4;
    //     desireType[190] = 4;
    //     desireType[191] = 4;
    //     desireType[192] = 4;
    //     desireType[193] = 4;
    //     desireType[194] = 4;
    //     desireType[195] = 4;
    //     desireType[196] = 4;
    //     desireType[197] = 4;
    //     desireType[198] = 4;
    //     desireType[199] = 4;
    //     desireType[200] = 4;
    //     desireType[201] = 4;
    // }

    // function _initDesireLuck() internal {
    //     desireLuck[210] = true;
    //     desireLuck[226] = true;
    //     desireLuck[251] = true;
    //     desireLuck[276] = true;
    //     desireLuck[280] = true;
    //     desireLuck[287] = true;
    //     desireLuck[291] = true;
    //     desireLuck[297] = true;
    //     desireLuck[298] = true;
    //     desireLuck[309] = true;
    //     desireLuck[317] = true;
    //     desireLuck[326] = true;
    //     desireLuck[335] = true;
    //     desireLuck[341] = true;
    //     desireLuck[345] = true;
    //     desireLuck[358] = true;
    //     desireLuck[372] = true;
    //     desireLuck[373] = true;
    //     desireLuck[377] = true;
    //     desireLuck[380] = true;
    //     desireLuck[390] = true;
    //     desireLuck[399] = true;
    //     desireLuck[402] = true;
    //     desireLuck[404] = true;
    //     desireLuck[433] = true;
    //     desireLuck[436] = true;
    //     desireLuck[440] = true;
    //     desireLuck[449] = true;
    //     desireLuck[450] = true;
    //     desireLuck[461] = true;
    //     desireLuck[469] = true;
    //     desireLuck[506] = true;
    //     desireLuck[507] = true;
    //     desireLuck[510] = true;
    //     desireLuck[536] = true;
    //     desireLuck[540] = true;
    //     desireLuck[546] = true;
    //     desireLuck[556] = true;
    //     desireLuck[565] = true;
    //     desireLuck[569] = true;
    //     desireLuck[573] = true;
    //     desireLuck[576] = true;
    //     desireLuck[578] = true;
    //     desireLuck[585] = true;
    //     desireLuck[616] = true;
    //     desireLuck[617] = true;
    //     desireLuck[647] = true;
    //     desireLuck[675] = true;
    //     desireLuck[677] = true;
    //     desireLuck[694] = true;
    //     desireLuck[723] = true;
    //     desireLuck[729] = true;
    //     desireLuck[733] = true;
    //     desireLuck[743] = true;
    //     desireLuck[745] = true;
    //     desireLuck[767] = true;
    //     desireLuck[773] = true;
    //     desireLuck[782] = true;
    //     desireLuck[799] = true;
    //     desireLuck[802] = true;
    //     desireLuck[825] = true;
    //     desireLuck[833] = true;
    //     desireLuck[838] = true;
    //     desireLuck[842] = true;
    //     desireLuck[850] = true;
    //     desireLuck[852] = true;
    //     desireLuck[856] = true;
    //     desireLuck[862] = true;
    //     desireLuck[872] = true;
    //     desireLuck[877] = true;
    //     desireLuck[904] = true;
    //     desireLuck[942] = true;
    //     desireLuck[945] = true;
    //     desireLuck[949] = true;
    //     desireLuck[990] = true;
    //     desireLuck[1006] = true;
    //     desireLuck[1022] = true;
    //     desireLuck[1025] = true;
    //     desireLuck[1036] = true;
    //     desireLuck[1041] = true;
    //     desireLuck[1047] = true;
    //     desireLuck[1052] = true;
    //     desireLuck[1059] = true;
    //     desireLuck[1103] = true;
    //     desireLuck[1122] = true;
    //     desireLuck[1127] = true;
    //     desireLuck[1208] = true;
    //     desireLuck[1231] = true;
    //     desireLuck[1264] = true;
    //     desireLuck[1268] = true;
    //     desireLuck[1275] = true;
    //     desireLuck[1283] = true;
    //     desireLuck[1300] = true;
    //     desireLuck[1302] = true;
    // }
}


// File contracts/lockDesire/IERC721.sol

pragma solidity ^0.8.4;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeMint(address to, uint256 tokenId) external;
}


// File contracts/lockDesire/IERC1155.sol

pragma solidity ^0.8.4;

interface IERC1155 {
    function mint(
        address to_,
        uint256 id_,
        uint256 amount_
    ) external;
}


// File contracts/lockDesire/LockDesire.sol

pragma solidity ^0.8.4;


// import "@openzeppelin/contracts/utils/Strings.sol";



// import "hardhat/console.sol";

contract LockDesire is LockData, IERC721Receiver {
    address public immutable desireToken;
    address public immutable passToken;

    uint256 public immutable lockStart;
    uint256 public immutable lockEnd;

    uint256 public immutable lockPeriod;

    uint256 public passId;

    uint256 constant typeGroup = 1;
    uint256 constant typeLuck = 2;

    struct LockInfo {
        address locker;
        uint256 lockTime;
        uint256[] ids;
    }

    // locker => id => LockInfo
    mapping(address => mapping(uint256 => LockInfo)) public lockInfos;
    // locker => lock id (never decrease)
    mapping(address => uint256) public lockId;

    event Lock(address indexed locker, uint256 indexed id, uint256[] ids);
    event Unlock(address indexed locker, uint256 indexed id, uint256[] ids);

    function checkIds(uint256[] calldata ids_, bytes32[][] calldata proofs_)
        internal
        view
    {
        require(ids_.length == 4, "id length error");
        require(proofs_.length == 4, "proof length error");

        // verify desire 1
        // bytes32 leaf1 = keccak256(abi.encodePacked(ids_[0]));
        bytes32 leaf1 = keccak256(abi.encodePacked((ids_[0])));

        require(
            MerkleProof.verify(proofs_[0], desire1Root, leaf1),
            "verify desire1 error"
        );

        // verify desire 2
        bytes32 leaf2 = keccak256(abi.encodePacked((ids_[1])));

        require(
            MerkleProof.verify(proofs_[1], desire2Root, leaf2),
            "verify desire2 error"
        );

        // verify desire 3
        bytes32 leaf3 = keccak256(abi.encodePacked((ids_[2])));
        require(
            MerkleProof.verify(proofs_[2], desire3Root, leaf3),
            "verify desire3 error"
        );

        // verify desire 4
        bytes32 leaf4 = keccak256(abi.encodePacked((ids_[3])));
        require(
            MerkleProof.verify(proofs_[3], desire4Root, leaf4),
            "verify desire4 error"
        );
    }

    modifier checkLockTime() {
        require(block.timestamp >= lockStart, "lock not begin");
        require(block.timestamp < lockEnd, "lock over");
        _;
    }

    modifier checkLockInfo(uint256 lockId_) {
        LockInfo memory info = lockInfos[msg.sender][lockId_];
        require(info.locker == msg.sender, "locker not match");
        require(block.timestamp >= info.lockTime + lockPeriod, "time error");
        _;
    }

    constructor(
        address desire_,
        address pass_,
        uint256 lockStart_,
        uint256 lockEnd_,
        uint256 lockPeriod_,
        bytes32 luckRoot_,
        bytes32 desire1Root_,
        bytes32 desire2Root_,
        bytes32 desire3Root_,
        bytes32 desire4Root_
    )
        LockData(
            luckRoot_,
            desire1Root_,
            desire2Root_,
            desire3Root_,
            desire4Root_
        )
    {
        lockStart = lockStart_;
        lockEnd = lockEnd_;
        desireToken = desire_;
        passToken = pass_;
        lockPeriod = lockPeriod_;
        passId = 11;
    }

    function _lockToken(uint256[] calldata ids_) internal {
        // Lock nft to this contract
        for (uint256 i = 0; i < ids_.length; i++) {
            IERC721(desireToken).safeTransferFrom(
                msg.sender,
                address(this),
                ids_[i]
            );
        }
    }

    function _register(uint256[] calldata ids_) internal returns (uint256) {
        // Register lock info
        uint256 id = lockId[msg.sender];
        lockInfos[msg.sender][id] = LockInfo({
            locker: msg.sender,
            lockTime: block.timestamp,
            ids: ids_
        });
        lockId[msg.sender] += 1;
        return id;
    }

    function lockLuck(uint256[] calldata ids_, bytes32[][] calldata proofs_)
        public
        checkLockTime
    {
        require(ids_.length == proofs_.length, "_luckLuck length");
        for (uint256 i = 0; i < ids_.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked((ids_[i])));
            require(
                MerkleProof.verify(proofs_[i], luckRoot, leaf),
                "verify luck root failed"
            );
        }
        // lock nft
        _lockToken(ids_);

        // register
        uint256 id_ = _register(ids_);

        // Mint Pass token to locker
        // IERC1155(passToken).mint(msg.sender, passId, ids_.length);
        for (uint256 i = 0; i < ids_.length; i++) {
            IERC721(passToken).safeMint(msg.sender, passId++);
        }

        emit Lock(msg.sender, id_, ids_);
    }

    function lock(
        uint256[] calldata ids_,
        bytes32[][] calldata proofs_,
        /*optional luckids*/
        uint256[] calldata luckIds_,
        bytes32[][] calldata luckProofs_
    ) public checkLockTime {
        checkIds(ids_, proofs_);
        require(luckIds_.length == luckProofs_.length, "luck length error");

        // Lock nft to this contract
        _lockToken(ids_);

        // register
        uint256 id_ = _register(ids_);

        for (uint256 i = 0; i < luckIds_.length; i++) {
            bool contains = false;
            for (uint256 j = 0; j < ids_.length; j++) {
                if (luckIds_[i] == ids_[j]) {
                    contains = true;
                    break;
                }
            }
            require(contains, "luck must be subset");

            bytes32 leaf = keccak256(abi.encodePacked((luckIds_[i])));
            require(
                MerkleProof.verify(luckProofs_[i], luckRoot, leaf),
                "verify luck root failed"
            );
        }

        // Mint Pass token to locker
        // IERC1155(passToken).mint(msg.sender, passId, 1 + luckIds_.length);
        for (uint256 i = 0; i < 1 + luckIds_.length; i++) {
            IERC721(passToken).safeMint(msg.sender, passId++);
        }

        emit Lock(msg.sender, id_, ids_);
    }

    function unlock(uint256 lockId_) public checkLockInfo(lockId_) {
        // transfer nft to locker
        LockInfo memory info = lockInfos[msg.sender][lockId_];
        for (uint256 i = 0; i < info.ids.length; i++) {
            IERC721(desireToken).safeTransferFrom(
                address(this),
                msg.sender,
                info.ids[i]
            );
        }

        // remove lock info
        delete lockInfos[msg.sender][lockId_];

        emit Unlock(msg.sender, lockId_, info.ids);
    }

    function getLockInfos(address locker_, uint256 id_)
        public
        view
        returns (LockInfo memory)
    {
        LockInfo memory info = lockInfos[locker_][id_];
        return info;
    }

    function onERC721Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}