pragma solidity 0.8.15;

import "./MerkleTreeWithHistory.sol";
//import "hardhat/console.sol";
import "./Verifier.sol";

//import "./MintVerifier.sol";
//import "./ShieldVerifier.sol";
//import "./UnshieldVerifier.sol";
//import "./TransferVerifier.sol";

struct character {
    uint256 attribute1;
    uint256 attribute2;
    uint256 attribute3;
}

interface IVerifier {
    function verifyMintProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[1] calldata input
    ) external returns (bool);

    function verifyShieldProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[2] calldata input
    ) external returns (bool);

    function verifyUnshieldProof(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[4] calldata input
    ) external returns (bool);

    function verifyTransferProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) external returns (bool);

    function verifySellProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[7] memory input
    ) external returns (bool);
}

contract ZkCards is MerkleTreeWithHistory {
    event Statue(uint256 id);

    IVerifier public verifier;

    //MintVerifier public mintVerifier;
    //TransferVerifier public transferVerifier;
    //ShieldVerifier public shieldVerifier;
    //UnshieldVerifier public unshieldVerifier;

    mapping(uint256 => address) public ownerOf;

    // 0: not minted, 1: minted, 2: shielded
    mapping(uint256 => uint8) public status;

    mapping(uint256 => bool) public commitments;

    mapping(uint256 => bool) public nullifiers;

    mapping(uint256 => mapping(uint256 => uint256)) public bids; //This will not work is attributes are == 10

    constructor(
        IVerifier _verifier,
        //MintVerifier _mintVerifier,
        uint32 levels,
        address hasher
    ) MerkleTreeWithHistory(levels, IHasher(hasher)) {
        verifier = _verifier;
        //mintVerifier = _mintVerifier;
    }

    function mint(
        //uint256 id,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public {
        //_mint(id, msg.sender, a, b, c, input);
        _mint(input[0], msg.sender, a, b, c, input);
    }

    function mintTo(
        uint256 id,
        address recipient,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public {
        _mint(id, recipient, a, b, c, input);
    }

    function _mint(
        uint256 id,
        address recipient,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) private {
        require(status[id] == 0, "Token already minted");
        //require(mintVerifier.verifyProof(a, b, c, input), "Failure of proof of mint verification");
        require(
            verifier.verifyMintProof(a, b, c, input),
            "Failure of proof of mint verification"
        );
        status[id] = 1;
        ownerOf[id] = recipient;
    }

    function shield(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) public {
        uint256 commitment = input[0];
        uint256 id = input[1];

        //emit Statue(id);
        //console.log(id);
        require(
            status[id] == 1,
            "Only minted and unshielded tokens can be shielded"
        );
        require(ownerOf[id] == msg.sender, "Only owner can shield a token");
        require(!commitments[commitment], "Commitment already exists");
        require(
            verifier.verifyShieldProof(a, b, c, input),
            "Invalid shield proof"
        );

        _insert(bytes32(commitment));
        commitments[commitment] = true;
        ownerOf[id] = address(this);
    }

    function unshield(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) public {
        uint256 nullifier = input[0];
        uint256 id = input[1];
        uint256 ownerUint = input[2];
        uint256 root = input[3];
        address owner = address(uint160(ownerUint));

        require(!nullifiers[nullifier], "Nullifier was already used");
        nullifiers[nullifier] = true;
        require(isKnownRoot(bytes32(root)), "Cannot find your merkle root");

        require(
            verifier.verifyUnshieldProof(a, b, c, input),
            "Invalid unshield proof"
        );

        ownerOf[id] = owner;
        status[id] = 1;
    }

    function transfer(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) public {
        uint256 nullifier = input[0];
        uint256 newCommitment = input[1];
        uint256 root = input[2];
        //uint256 pubKey = input[3];

        require(!nullifiers[nullifier], "Nullifier was already used");

        require(isKnownRoot(bytes32(root)), "Cannot find your merkle root");

        require(
            verifier.verifyTransferProof(a, b, c, input),
            "Invalid unshield proof"
        );

        nullifiers[nullifier] = true;
        require(!commitments[newCommitment], "Commitment already exists");
        _insert(bytes32(newCommitment));
        commitments[newCommitment] = true;
    }

    function makeBid(
        uint256 pubKey,
        uint256 attribute1,
        uint256 attribute2,
        uint256 attribute3
    ) public payable {
        //console.log(attribute1);
        require(int(attribute1) <= 10, "Greater than 10");
        require(attribute1 >= 0, "Smaller than 0");
        require(attribute2 <= 10, "Greater than 10");
        require(attribute2 >= 0, "Smaller than 0");
        require(attribute3 <= 10, "Greater than 10");
        require(attribute3 >= 0, "Smaller than 0");
        //require(msg.sender.balance - msg.value > 0);
        //msg.sender.balance -= msg.value;
        //console.log("Sender's balance before sell");
        //console.log(msg.sender.balance);
        //console.log("Sender's balance after sell");
        //console.log(msg.sender.balance);
        //console.log("msg.value");
        //console.log(msg.value);
        bids[pubKey][attribute1 * 100 + attribute2 * 10 + attribute3] = msg.value;
        // Should add the msg.value to a map of balances so that when the bidder wants to
        // cancel the bid, she can get the msg.value refunded
    }

    function sell(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[7] memory input
    ) public {
        uint256 nullifier = input[0];
        uint256 newCommitment = input[1];
        uint256 root = input[2];
        uint256 pubKeyReceiver = input[3];
        uint256 attribute1 = input[4];
        uint256 attribute2 = input[5];
        uint256 attribute3 = input[6];
        uint256 total = attribute1 * 100 + attribute2 * 10 + attribute3;
        uint256 amount = bids[pubKeyReceiver][total];
        // Check that pubKeyReceiver has made an ask and that the has not been matched yet.
        //require(amount != 0);

        require(!nullifiers[nullifier], "Nullifier was already used");

        require(isKnownRoot(bytes32(root)), "Cannot find your merkle root");

        //Verify that the seller has indeed made a shielded transfer to pubKeyReceiver and that the conditions
        //of the sell are satisfied.
        require(
            verifier.verifySellProof(a, b, c, input),
            "Invalid unshield proof"
        );

        nullifiers[nullifier] = true;
        require(!commitments[newCommitment], "Commitment already exists");
        _insert(bytes32(newCommitment));
        commitments[newCommitment] = true;

        //console.log("amount to be given to seller");
        //console.log(amount);
        bids[pubKeyReceiver][total] -= amount;
        payable(msg.sender).transfer(amount);
        //console.log("Sender of sell transaction");
        //console.log(msg.sender);

    }
}

// https://tornado.cash
/*
 * d888888P                                           dP              a88888b.                   dP
 *    88                                              88             d8'   `88                   88
 *    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
 *    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
 *    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
 *    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
 * ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IHasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) external pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE
  IHasher public immutable hasher;

  uint32 public levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code

  // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
  // it removes index range check on every interaction
  mapping(uint256 => bytes32) public filledSubtrees;
  mapping(uint256 => bytes32) public roots;
  uint32 public constant ROOT_HISTORY_SIZE = 30;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;

  constructor(uint32 _levels, IHasher _hasher) {
    require(_levels > 0, "_levels should be greater than zero");
    require(_levels < 32, "_levels should be less than 32");
    levels = _levels;
    hasher = _hasher;

    for (uint32 i = 0; i < _levels; i++) {
      filledSubtrees[i] = zeros(i);
    }

    roots[0] = zeros(_levels - 1);
  }

  /**
    @dev Hash 2 tree leaves, returns MiMC(_left, _right)
  */
  function hashLeftRight(
    IHasher _hasher,
    bytes32 _left,
    bytes32 _right
  ) public pure returns (bytes32) {
    require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
    require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
    uint256 R = uint256(_left);
    uint256 C = 0;
    (R, C) = _hasher.MiMCSponge(R, C);
    R = addmod(R, uint256(_right), FIELD_SIZE);
    (R, C) = _hasher.MiMCSponge(R, C);
    return bytes32(R);
  }

  function _insert(bytes32 _leaf) internal returns (uint32 index) {
    uint32 _nextIndex = nextIndex;
    require(_nextIndex != uint32(2)**levels, "Merkle tree is full. No more leaves can be added");
    uint32 currentIndex = _nextIndex;
    bytes32 currentLevelHash = _leaf;
    bytes32 left;
    bytes32 right;

    for (uint32 i = 0; i < levels; i++) {
      if (currentIndex % 2 == 0) {
        left = currentLevelHash;
        right = zeros(i);
        filledSubtrees[i] = currentLevelHash;
      } else {
        left = filledSubtrees[i];
        right = currentLevelHash;
      }
      currentLevelHash = hashLeftRight(hasher, left, right);
      currentIndex /= 2;
    }

    uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
    currentRootIndex = newRootIndex;
    roots[newRootIndex] = currentLevelHash;
    nextIndex = _nextIndex + 1;
    return _nextIndex;
  }

  /**
    @dev Whether the root is present in the root history
  */
  function isKnownRoot(bytes32 _root) public view returns (bool) {
    if (_root == 0) {
      return false;
    }
    uint32 _currentRootIndex = currentRootIndex;
    uint32 i = _currentRootIndex;
    do {
      if (_root == roots[i]) {
        return true;
      }
      if (i == 0) {
        i = ROOT_HISTORY_SIZE;
      }
      i--;
    } while (i != _currentRootIndex);
    return false;
  }

  /**
    @dev Returns the last root
  */
  function getLastRoot() public view returns (bytes32) {
    return roots[currentRootIndex];
  }

  /// @dev provides Zero (Empty) elements for a MiMC MerkleTree. Up to 32 levels
  function zeros(uint256 i) public pure returns (bytes32) {
    if (i == 0) return bytes32(0x2fe54c60d3acabf3343a35b6eba15db4821b340f76e741e2249685ed4899af6c);
    else if (i == 1) return bytes32(0x256a6135777eee2fd26f54b8b7037a25439d5235caee224154186d2b8a52e31d);
    else if (i == 2) return bytes32(0x1151949895e82ab19924de92c40a3d6f7bcb60d92b00504b8199613683f0c200);
    else if (i == 3) return bytes32(0x20121ee811489ff8d61f09fb89e313f14959a0f28bb428a20dba6b0b068b3bdb);
    else if (i == 4) return bytes32(0x0a89ca6ffa14cc462cfedb842c30ed221a50a3d6bf022a6a57dc82ab24c157c9);
    else if (i == 5) return bytes32(0x24ca05c2b5cd42e890d6be94c68d0689f4f21c9cec9c0f13fe41d566dfb54959);
    else if (i == 6) return bytes32(0x1ccb97c932565a92c60156bdba2d08f3bf1377464e025cee765679e604a7315c);
    else if (i == 7) return bytes32(0x19156fbd7d1a8bf5cba8909367de1b624534ebab4f0f79e003bccdd1b182bdb4);
    else if (i == 8) return bytes32(0x261af8c1f0912e465744641409f622d466c3920ac6e5ff37e36604cb11dfff80);
    else if (i == 9) return bytes32(0x0058459724ff6ca5a1652fcbc3e82b93895cf08e975b19beab3f54c217d1c007);
    else if (i == 10) return bytes32(0x1f04ef20dee48d39984d8eabe768a70eafa6310ad20849d4573c3c40c2ad1e30);
    else if (i == 11) return bytes32(0x1bea3dec5dab51567ce7e200a30f7ba6d4276aeaa53e2686f962a46c66d511e5);
    else if (i == 12) return bytes32(0x0ee0f941e2da4b9e31c3ca97a40d8fa9ce68d97c084177071b3cb46cd3372f0f);
    else if (i == 13) return bytes32(0x1ca9503e8935884501bbaf20be14eb4c46b89772c97b96e3b2ebf3a36a948bbd);
    else if (i == 14) return bytes32(0x133a80e30697cd55d8f7d4b0965b7be24057ba5dc3da898ee2187232446cb108);
    else if (i == 15) return bytes32(0x13e6d8fc88839ed76e182c2a779af5b2c0da9dd18c90427a644f7e148a6253b6);
    else if (i == 16) return bytes32(0x1eb16b057a477f4bc8f572ea6bee39561098f78f15bfb3699dcbb7bd8db61854);
    else if (i == 17) return bytes32(0x0da2cb16a1ceaabf1c16b838f7a9e3f2a3a3088d9e0a6debaa748114620696ea);
    else if (i == 18) return bytes32(0x24a3b3d822420b14b5d8cb6c28a574f01e98ea9e940551d2ebd75cee12649f9d);
    else if (i == 19) return bytes32(0x198622acbd783d1b0d9064105b1fc8e4d8889de95c4c519b3f635809fe6afc05);
    else if (i == 20) return bytes32(0x29d7ed391256ccc3ea596c86e933b89ff339d25ea8ddced975ae2fe30b5296d4);
    else if (i == 21) return bytes32(0x19be59f2f0413ce78c0c3703a3a5451b1d7f39629fa33abd11548a76065b2967);
    else if (i == 22) return bytes32(0x1ff3f61797e538b70e619310d33f2a063e7eb59104e112e95738da1254dc3453);
    else if (i == 23) return bytes32(0x10c16ae9959cf8358980d9dd9616e48228737310a10e2b6b731c1a548f036c48);
    else if (i == 24) return bytes32(0x0ba433a63174a90ac20992e75e3095496812b652685b5e1a2eae0b1bf4e8fcd1);
    else if (i == 25) return bytes32(0x019ddb9df2bc98d987d0dfeca9d2b643deafab8f7036562e627c3667266a044c);
    else if (i == 26) return bytes32(0x2d3c88b23175c5a5565db928414c66d1912b11acf974b2e644caaac04739ce99);
    else if (i == 27) return bytes32(0x2eab55f6ae4e66e32c5189eed5c470840863445760f5ed7e7b69b2a62600f354);
    else if (i == 28) return bytes32(0x002df37a2642621802383cf952bf4dd1f32e05433beeb1fd41031fb7eace979d);
    else if (i == 29) return bytes32(0x104aeb41435db66c3e62feccc1d6f5d98d0a0ed75d1374db457cf462e3a1f427);
    else if (i == 30) return bytes32(0x1f3c6fd858e9a7d4b0d1f38e256a09d81d5a5e3c963987e2d4b814cfab7c6ebb);
    else if (i == 31) return bytes32(0x2c7a07d20dff79d01fecedc1134284a8d08436606c93693b67e333f671bf69cc);
    else revert("Index out of bounds");
  }
}

// THIS FILE IS GENERATED BY HARDHAT-CIRCOM. DO NOT EDIT THIS FILE.

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.5
//      fixed linter warnings
//      added requiere error messages
//
pragma solidity 0.8.15;

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

library Verifier {
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

    function verify(
        uint256[] memory input,
        Proof memory proof,
        VerifyingKey memory vk
    ) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(input.length + 1 == vk.IC.length, "verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(
                input[i] < snark_scalar_field,
                "verifier-gte-snark-scalar-field"
            );
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.IC[i + 1], input[i])
            );
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

    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[] memory input,
        VerifyingKey memory vk
    ) internal view returns (bool) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        if (verify(input, proof, vk) == 0) {
            return true;
        } else {
            return false;
        }
    }

    function mintVerifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            19642524115522290447760970021746675789341356000653265441069630957431566301675,
            15809037446102219312954435152879098683824559980020626143453387822004586242317
        );

        vk.beta2 = Pairing.G2Point(
            [6402738102853475583969787773506197858266321704623454181848954418090577674938,
             3306678135584565297353192801602995509515651571902196852074598261262327790404],
            [15158588411628049902562758796812667714664232742372443470614751812018801551665,
             4983765881427969364617654516554524254158908221590807345159959200407712579883]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [11920509847703859450715350074104307254486457024775956217520710879789738227635,
             8798972628953645741105836061652452774803230927989692477673708841587013866087],
            [4030859315509324265199274659915429386903832997559505699922919403980917032771,
             20439335881748762525972462608376406569275710781810348748385563269609887845928]
        );
        vk.IC = new Pairing.G1Point[](2);
        
        vk.IC[0] = Pairing.G1Point( 
            6986605725258062671023080196761436904122120477288400033753388663385297165978,
            4171740692960812301966019120219135454052875044568492727802583957640434015449
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            4733835539242805435404796529048029383234667383519270466160785809770547069038,
            4556690063822445327467678786718264101588555888327628755193586577055941249979
        );
    }

    function verifyMintProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, mintVerifyingKey());
    }

    function unshieldVerifyingKey()
        internal
        pure
        returns (VerifyingKey memory vk)
    {
        vk.alfa1 = Pairing.G1Point(
            19642524115522290447760970021746675789341356000653265441069630957431566301675,
            15809037446102219312954435152879098683824559980020626143453387822004586242317
        );

        vk.beta2 = Pairing.G2Point(
            [6402738102853475583969787773506197858266321704623454181848954418090577674938,
             3306678135584565297353192801602995509515651571902196852074598261262327790404],
            [15158588411628049902562758796812667714664232742372443470614751812018801551665,
             4983765881427969364617654516554524254158908221590807345159959200407712579883]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [15726880928522076198907811574515239827591529328294094027721719033051116465555,
             19873990760661388184138973378759262715517387532169366717335387282594424214112],
            [12691659159414229812071474070238663030369680676879876499577484303208371937730,
             20976720310214171392087317572426758344796906063630871202157495114506109242892]
        );
        vk.IC = new Pairing.G1Point[](5);
        
        vk.IC[0] = Pairing.G1Point( 
            3614207991030308149296292741438890648249204644250872547091300745694346320947,
            1951411415321726649444908847537938975577369139439515969027851098310528302700
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            21277731604454929310780976792288357257477691246718802775403000095340674497861,
            1476865530441379022813720135971280172724885152571429647364307856674798034328
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            13726844780787034698458146924210977147119976974430201834359311184074067640332,
            2486722076721734898943363407513757787143014163621911946023746808481968019278
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            17428875291644943548799377629406738525333655689326001600352747342597064649077,
            4059487221929148448489949294794527809058747605351539066605642342129207335687
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            4423518742643282692644162657589900651268176993015051574127748972911559794727,
            12183049125056181318294913415072675575668322321126462220067072225354587373834
        ); 
    }

    function verifyUnshieldProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, unshieldVerifyingKey());
    }

    function shieldVerifyingKey()
        internal
        pure
        returns (VerifyingKey memory vk)
    {
        vk.alfa1 = Pairing.G1Point(
            19642524115522290447760970021746675789341356000653265441069630957431566301675,
            15809037446102219312954435152879098683824559980020626143453387822004586242317
        );

        vk.beta2 = Pairing.G2Point(
            [6402738102853475583969787773506197858266321704623454181848954418090577674938,
             3306678135584565297353192801602995509515651571902196852074598261262327790404],
            [15158588411628049902562758796812667714664232742372443470614751812018801551665,
             4983765881427969364617654516554524254158908221590807345159959200407712579883]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [8642751758375509683606551837347970534527897370984104902232059801460780414969,
             21202658745391254909919789006969096716649628677664885001274345839421878452740],
            [319652346677984223168611526229059653103237863602092701003291075432104020897,
             15826712485462251396259544505600989935751857081924652258832192625559944187488]
        );
        vk.IC = new Pairing.G1Point[](3);
        
        vk.IC[0] = Pairing.G1Point( 
            10322006744844272731617750396987407839197230056159897658434953125506860822365,
            16244596943573450500482324267041921284926679952074356393652648949337155452884
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            19279850499141752982273416819842933568963270143607857041974862025709802845596,
            17457299992668341229097431759977233284708023024693515316333443878366741148600
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            1592851044687130553392522512122862300628328704776357888360509562495210563807,
            7666801710196815489302623457622138527637036351131240210414361011354690411673
        ); 
    }

    function verifyShieldProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, shieldVerifyingKey());
    }

    function transferVerifyingKey()
        internal
        pure
        returns (VerifyingKey memory vk)
    {
        vk.alfa1 = Pairing.G1Point(
            19642524115522290447760970021746675789341356000653265441069630957431566301675,
            15809037446102219312954435152879098683824559980020626143453387822004586242317
        );

        vk.beta2 = Pairing.G2Point(
            [6402738102853475583969787773506197858266321704623454181848954418090577674938,
             3306678135584565297353192801602995509515651571902196852074598261262327790404],
            [15158588411628049902562758796812667714664232742372443470614751812018801551665,
             4983765881427969364617654516554524254158908221590807345159959200407712579883]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12049143427542599999603140022344440186078939907201224953321178269814294784295,
             7865668112636632299578262264203741402108203283186165858915321451032648123071],
            [11202995402560242495837316187726395036163899621320470295431434620252956722874,
             21760069743329645408098333558150497343111284512447461761003089237794980561970]
        );
        vk.IC = new Pairing.G1Point[](4);
        
        vk.IC[0] = Pairing.G1Point( 
            1628512973155402903414034504450282007003290376164218300459205965235765141948,
            12305264785916518188843213100686541396515142976839856814395144915675837474729
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            2519280568234909763635832957315049454309478683476181395884424527130932374821,
            20942973239244789292376295410151477462051337492092831535815493679806979187017
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            3121357841606112331145081947775424473583443687785962751788583979082623174573,
            16120949249855710669688593741696723712954938782920082075331608496263177786728
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            12502230834696454139761718151049688681105184060376166520570506187470503526005,
            972220229666088311207081497310254357077740126313152331032910231142159855128
        );                                      
        
    }

    function verifyTransferProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, transferVerifyingKey());
    }


    function sellVerifyingKey()
        internal
        pure
        returns (VerifyingKey memory vk)
    {
        vk.alfa1 = Pairing.G1Point(
            19642524115522290447760970021746675789341356000653265441069630957431566301675,
            15809037446102219312954435152879098683824559980020626143453387822004586242317
        );

        vk.beta2 = Pairing.G2Point(
            [6402738102853475583969787773506197858266321704623454181848954418090577674938,
             3306678135584565297353192801602995509515651571902196852074598261262327790404],
            [15158588411628049902562758796812667714664232742372443470614751812018801551665,
             4983765881427969364617654516554524254158908221590807345159959200407712579883]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [21642098641671947412043620351840588250016267760122068195527089006613101802417,
             7477067339658621497361503871686308469901276841137909254121021131802179557710],
            [14639266884973892400331285739631351806870690149329482068800255456202287777896,
             31534692519291152934767871677095972997167331184442712960006852505438920232]
        );
        vk.IC = new Pairing.G1Point[](8);
        
        vk.IC[0] = Pairing.G1Point( 
            19342196191797911703106831532455221421037177690162344498310239852668933028961,
            10602061725706036340653016002068004258149591801561120026557548301986455174306
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            17732759424425565801583395310274324620906666737264928057799988141645235177288,
            17739046154601714007674511708495629188759396794173916532674937312867862477508
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            6708178484999240721132514165551467415951612007629129393574397234727734849691,
            16665895910756088364937367872107524768739441087297782119165297874565815474871
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            5743975349001027854292706462754917139780685398535535112778920735038853886657,
            20499089578683907176787251933193398763739772875388144809637031435100159959145
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            19425576653695109896441649107387968312218197789157326702074124802824417234061,
            1100022912492865303688902862641017604567781881947940268473771981367510689824
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            7338957595950796300475142584442804516992689344135965200567591976614293730926,
            7770050106511201626366241885246959830750223317626784342220355237345955198746
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            12505232945813486665329864839395300798905672798291071143614082341503582161660,
            4120736852355207266008495857759535731093365492069723214004621695340445238085
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            17636418489746195408484433759008728803981544797388632363487321927029409645121,
            8659327200409436946302654502258470098498272015934768871467912245115184981404
        );  
    }

    function verifySellProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[7] memory input
    ) public view returns (bool) {
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        return verifyProof(a, b, c, inputValues, sellVerifyingKey());
    }
}