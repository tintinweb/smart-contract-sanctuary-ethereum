// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

enum GameStage {
    Uncreated,
    GatheringPlayers,
    Shuffle,
    PreFlopReveal, // in pre-flop, every gets 2 cards, and everyone must provide proofs
    PreFlopBet,
    FlopReveal, // in flop, everyone must provide proofs for community cards
    FlopBet,
    TurnReveal, // need reveal
    TurnBet,
    RiverReveal, // need reveal
    RiverBet,
    PostRound, // waiting to announce winner
    Ended
}

enum Rank {
    Spades, 
    Hearts,
    Diamonds,
    Clubs
}

// example: 
// card value: 50
// card info: rank: 50 / 13 = 3 (Clubs), value: 50 % 13 = 11 (2,3,4,5,6,7,8,9,j,>>Q<<,k,a)
struct CardInfo {
    Rank rank;
    uint256 value;
}

// the board state
struct Board {
    // the current game status
    GameStage stage;

    // player infos
    address[] playerAddresses;
    uint256[][] playerHands;
    uint256[] playerBets;
    uint256[] playerStacks;
    bool[] playersDoneForCurrentStage;
    bool[] playerInPots;

    uint256[] communityCards;

    // next player index to player
    uint256 nextPlayerToPlay;

    uint256 dealerIndex;

    uint256 bigBlindSize;

    // zero address before game ends
    address winner;

    // the required amount of players for this board
    uint256 requiredPlayers;

    // total stack in the pot
    uint256 potSize;
}

// SPDX-License-Identifier: MIT

/**
 * This contract contain all the cryptographic logic
 */
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BoardManagerStorage.sol";


import "./encrypt_verifier.sol";
import "./decrypt_verifier.sol";
interface IEncryptVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[209] memory input
    ) external view;
}

interface IDEcryptVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view;
}

struct ShuffleProof {
    uint256[8] proof;
    uint256[104] deck;
}

struct RevealProof {
    uint256[8] proof;
    // 1st is the card value, 2nd and 3rd is the Y, 4th is the personal public key.
    uint256[4] card;
}

contract Verifier is Ownable {
    // ========================== data fields ==========================
    ShuffleProof private shuffleProof;
    uint pk;

    // key: cardIndex
    mapping(uint256 => RevealProof) revealProofs;

    address public game;

    // ========================== Events ==========================

    event Setup();

    IEncryptVerifier public encrypt_verifier;
    IDEcryptVerifier public decrypt_verifier;

    constructor(
        IEncryptVerifier encrypt_verifier_, 
        IDEcryptVerifier decrypt_verifier_
    ) {
        encrypt_verifier = encrypt_verifier_;
        decrypt_verifier = decrypt_verifier_;
    }

    function getShuffleProof() public view returns (ShuffleProof memory) {
        return shuffleProof;
    }

    function getRevealProof(uint256 cardIndex)
        public
        view
        returns (RevealProof memory)
    {
        return revealProofs[cardIndex];
    }

    function setupPK(uint256 pk_) external {
        pk = pk_;
    }

    function setup(uint256[104] calldata startingDeck) external returns (bool) {
        // set the initial proof and deck for this round
        uint256[8] memory proof = [
            uint256(0), uint256(0),
            uint256(0), uint256(0),
            uint256(0), uint256(0),
            uint256(0), uint256(0)
        ];
        shuffleProof = ShuffleProof({proof: proof, deck: startingDeck});

        // revealProofs[0] = RevealProof({proof: proof, card: [0, pk]);

        return true;
    }

    // verify shuffle proof with the last saved deck, and going on
    function verifyShuffleAndSave(ShuffleProof calldata proof)
        external
        returns (bool)
    {
        // uint[209] memory input;
        // for (uint i = 0; i < 104; i++) {
        //     input[i] = proof.deck[i];
        // }

        // for (uint i = 0; i < 104; i++) {
        //     input[i + 104] = shuffleProof.deck[i];
        // }

        // input[208] = pk;

        // encrypt_verifier.verifyProof(
        //     [proof.proof[0], proof.proof[1]],
        //     [[proof.proof[2], proof.proof[3]], [proof.proof[4], proof.proof[5]]],
        //     [proof.proof[6], proof.proof[7]],
        //     input
        // );

        // save
        shuffleProof = proof;
        return true;
    }

    //
    function verifyRevealAndSave(
        uint256 cardStartIndex,
        RevealProof calldata proof)
        external
        returns (bool)
    {
    //    decrypt_verifier.verifyProof(
    //         [proof.proof[0], proof.proof[1]],
    //         [[proof.proof[2], proof.proof[3]], [proof.proof[4], proof.proof[5]]],
    //         [proof.proof[6], proof.proof[7]],
    //         proof.card
    //     );

        revealProofs[cardStartIndex] = proof;
        // shuffleProof.deck[cardStartIndex + 52] = proof.card[0];
        
        return true;
    }

    // ========================== internals ==========================
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
// 2021 Remco Bloemen
//       cleaned up code
//       added InvalidProve() error
//       always revert with InvalidProof() on invalid proof
//       make decryptPairing strict
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library decryptPairing {
  error InvalidProof();

  // The prime q in the base field F_q for G1
  uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  // The prime moludus of the scalar field of G1.
  uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

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
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    // Validate input or revert
    if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) revert InvalidProof();
    // We know p.Y > 0 and p.Y < BASE_MODULUS.
    return G1Point(p.X, BASE_MODULUS - p.Y);
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
    // on the curve.
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
    }
    if (!success) revert InvalidProof();
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    // By EIP-196 the values p.X and p.Y are verified to less than the BASE_MODULUS and
    // form a valid point on the curve. But the scalar is not verified, so we do that explicitelly.
    if (s >= SCALAR_MODULUS) revert InvalidProof();
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
    }
    if (!success) revert InvalidProof();
  }

  /// Asserts the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
  function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) internal view {
    // By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
    // respective groups of the right order.
    if (p1.length != p2.length) revert InvalidProof();
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
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
    }
    if (!success || out[0] != 1) revert InvalidProof();
  }
}

contract decryptVerifier {
  using decryptPairing for *;

  struct VerifyingKey {
    decryptPairing.G1Point alfa1;
    decryptPairing.G2Point beta2;
    decryptPairing.G2Point gamma2;
    decryptPairing.G2Point delta2;
    decryptPairing.G1Point[] IC;
  }

  struct Proof {
    decryptPairing.G1Point A;
    decryptPairing.G2Point B;
    decryptPairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alfa1 = decryptPairing.G1Point(
      14378794661994809316668936077887579852844330409586136188493910229510707683568,
      19007180918058273234125706522281291487787880146734549337345180962710738215208
    );

    vk.beta2 = decryptPairing.G2Point(
      [5920706861016946300912146506670818945013737603659177373891149557636543490740, 12055325713222300848813253111985210672218263044214498326157766255150057128762],
      [9700420230412290932994502491200547761155381189822684608735830492099336040170, 14277278647337675353039880797101698215986155900184787257566473040310971051502]
    );

    vk.gamma2 = decryptPairing.G2Point(
      [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781],
      [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]
    );

    vk.delta2 = decryptPairing.G2Point(
      [14775193340486106785412518097791831523220390171193689425927766312700613407698, 2639006974166104660735007617629115075610687006489787811483101253678053727965],
      [7033699777372929539950951174758152219641620046403661899994547705056627996272, 12757135341281669891528138934607500598040384987778485246835950609094761223515]
    );

    vk.IC = new decryptPairing.G1Point[](5);

    
      vk.IC[0] = decryptPairing.G1Point(
        9666425137086650662037336904385157031772055490977677744261137988127815787584,
        5394407372917647524486917008691392485984315432533679388723049511191446329374
      );
    
      vk.IC[1] = decryptPairing.G1Point(
        1029880746318880647873272012935051622608590720430145823323385938643967970819,
        10519815370211771276212315568191981797045710057898860151276042150960108246790
      );
    
      vk.IC[2] = decryptPairing.G1Point(
        18679496006835754091909636639352593958358012713658166038623643889897044251963,
        4195574608657694158130023234645666213596440321409392981763827641454293624821
      );
    
      vk.IC[3] = decryptPairing.G1Point(
        21233915107006272243099839554591143807433705314036839416373945066186606306898,
        16302219708944780223707653399805613424179877972668265811493690905270060414617
      );
    
      vk.IC[4] = decryptPairing.G1Point(
        90263583263356702511448915611918453627788815788836443948321726965197381648,
        1295786833271608162503943377766741245832505007368535148970418800924473144110
      );
    
  }

  /// @dev Verifies a Semaphore proof. Reverts with InvalidProof if the proof is invalid.
  function verifyProof(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[4] memory input
  ) public view {
    // If the values are not in the correct range, the decryptPairing contract will revert.
    Proof memory proof;
    proof.A = decryptPairing.G1Point(a[0], a[1]);
    proof.B = decryptPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = decryptPairing.G1Point(c[0], c[1]);

    VerifyingKey memory vk = verifyingKey();

    // Compute the linear combination vk_x of inputs times IC
    if (input.length + 1 != vk.IC.length) revert decryptPairing.InvalidProof();
    decryptPairing.G1Point memory vk_x = vk.IC[0];
    for (uint i = 0; i < input.length; i++) {
      vk_x = decryptPairing.addition(vk_x, decryptPairing.scalar_mul(vk.IC[i+1], input[i]));
    }

    // Check pairing
    decryptPairing.G1Point[] memory p1 = new decryptPairing.G1Point[](4);
    decryptPairing.G2Point[] memory p2 = new decryptPairing.G2Point[](4);
    p1[0] = decryptPairing.negate(proof.A);
    p2[0] = proof.B;
    p1[1] = vk.alfa1;
    p2[1] = vk.beta2;
    p1[2] = vk_x;
    p2[2] = vk.gamma2;
    p1[3] = proof.C;
    p2[3] = vk.delta2;
    decryptPairing.pairingCheck(p1, p2);
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
// 2021 Remco Bloemen
//       cleaned up code
//       added InvalidProve() error
//       always revert with InvalidProof() on invalid proof
//       make encryptPairing strict
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library encryptPairing {
  error InvalidProof();

  // The prime q in the base field F_q for G1
  uint256 constant BASE_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

  // The prime moludus of the scalar field of G1.
  uint256 constant SCALAR_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

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
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    // Validate input or revert
    if (p.X >= BASE_MODULUS || p.Y >= BASE_MODULUS) revert InvalidProof();
    // We know p.Y > 0 and p.Y < BASE_MODULUS.
    return G1Point(p.X, BASE_MODULUS - p.Y);
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
    // By EIP-196 all input is validated to be less than the BASE_MODULUS and form points
    // on the curve.
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
    }
    if (!success) revert InvalidProof();
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
    // By EIP-196 the values p.X and p.Y are verified to less than the BASE_MODULUS and
    // form a valid point on the curve. But the scalar is not verified, so we do that explicitelly.
    if (s >= SCALAR_MODULUS) revert InvalidProof();
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
    }
    if (!success) revert InvalidProof();
  }

  /// Asserts the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should succeed
  function pairingCheck(G1Point[] memory p1, G2Point[] memory p2) internal view {
    // By EIP-197 all input is verified to be less than the BASE_MODULUS and form elements in their
    // respective groups of the right order.
    if (p1.length != p2.length) revert InvalidProof();
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
      success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
    }
    if (!success || out[0] != 1) revert InvalidProof();
    //if (!success) revert InvalidProof();
  }
}

  struct VerifyingKey {
    encryptPairing.G1Point alfa1;
    encryptPairing.G2Point beta2;
    encryptPairing.G2Point gamma2;
    encryptPairing.G2Point delta2;
    encryptPairing.G1Point[] IC;
  }

library encryptKeyFirstHalf {
  function verifyingKey() public pure returns (VerifyingKey memory vk) {
    vk.alfa1 = encryptPairing.G1Point(
      14378794661994809316668936077887579852844330409586136188493910229510707683568,
      19007180918058273234125706522281291487787880146734549337345180962710738215208
    );

    vk.beta2 = encryptPairing.G2Point(
      [5920706861016946300912146506670818945013737603659177373891149557636543490740, 12055325713222300848813253111985210672218263044214498326157766255150057128762],
      [9700420230412290932994502491200547761155381189822684608735830492099336040170, 14277278647337675353039880797101698215986155900184787257566473040310971051502]
    );

    vk.gamma2 = encryptPairing.G2Point(
      [11559732032986387107991004021392285783925812861821192530917403151452391805634, 10857046999023057135944570762232829481370756359578518086990519993285655852781],
      [4082367875863433681332203403145435568316851327593401208105741076214120093531, 8495653923123431417604973247489272438418190587263600148770280649306958101930]
    );

    vk.delta2 = encryptPairing.G2Point(
      [15416166490785395106276701378819499360808020701472216425918396243173800454713, 163449396295182247720023575482215853144909379359521393782489670998832185593],
      [18050293563330412952915457967693723007653965703167951046542738888239878779321, 15463229414353227275274535145797178750698779279765271261521760282093356404415]
    );

    vk.IC = new encryptPairing.G1Point[](104);

    
      vk.IC[0] = encryptPairing.G1Point(
        14592727775733262519998007842562394043305210694830141845877465535190185366716,
        8516334610681481305419856826318787763618996543581856173319619908345541061517
      );
    
      vk.IC[1] = encryptPairing.G1Point(
        10805126477549885085176064279491885579489486964078777369672094005936564133822,
        6123985083616755070146697035380998016657737514865996401108163326824100195595
      );
    
      vk.IC[2] = encryptPairing.G1Point(
        3686027374065919644898243231192453370069543382288042495312202519725886740574,
        9495394099263831170906298129131430873528733649883722007752644644180645581975
      );
    
      vk.IC[3] = encryptPairing.G1Point(
        1236663899755434444548770717424268680980783805875281111856012035362016853487,
        17963354510050717452033127132353961623161340386545253947615815604074287569358
      );
    
      vk.IC[4] = encryptPairing.G1Point(
        17552860724746907131755251600969479607419427877341161394016090628378967033251,
        20760806642203932765514919656083358494307121745620572584957261284352889834185
      );
    
      vk.IC[5] = encryptPairing.G1Point(
        6342083480871303787726321084949171392582938341765810510103943036971446876470,
        19844772878045546164041920980905655487285316034955219990730503325847917563793
      );
    
      vk.IC[6] = encryptPairing.G1Point(
        3533927074876648547797362902048808492300902627836448130970102380971392901631,
        19495503670579781111463503450660275220746995532253162194053497542797808672787
      );
    
      vk.IC[7] = encryptPairing.G1Point(
        6529506370917939266705810122174187832319121168572402966512756990384493026244,
        20780393905885120105038377621188885495292816365003406611374634093854929483067
      );
    
      vk.IC[8] = encryptPairing.G1Point(
        15230555264426458571189820793278510921578551846867928589984740331804270992234,
        4226196862068629703835312975514673018909202265636276077442830081354029681154
      );
    
      vk.IC[9] = encryptPairing.G1Point(
        7193575343237360390856867088682389068275527256661899065176450593286985831092,
        21697269425734114793105577435869406785743446674535118515449993247492909396937
      );
    
      vk.IC[10] = encryptPairing.G1Point(
        14098754775242329406365897925239645511611674371457005375160085785165414414189,
        20150953984347934925947432274515841065114411550302657350648437543705608549916
      );
    
      vk.IC[11] = encryptPairing.G1Point(
        4427724200821055385122216825517845909008372073841279705769479000742271541836,
        16116425037495582200791344480490750448850150581745537145742903600283545149920
      );
    
      vk.IC[12] = encryptPairing.G1Point(
        11320094397105990171005925014578224988931520352669097375384724082269029492949,
        445601458796430688493533687898924777113505813375029022218136790769970015824
      );
    
      vk.IC[13] = encryptPairing.G1Point(
        11840725463379550639611679346522373697764179882780670730602538360814851391257,
        8141864374068234392324923769398266386624472627740324801492911325358341134605
      );
    
      vk.IC[14] = encryptPairing.G1Point(
        14107900332550044175607299982124342730682267845524746349129703484801189053426,
        1192602549044592599397236512482706868601546135462695228376865864198302358505
      );
    
      vk.IC[15] = encryptPairing.G1Point(
        21435937061458301835413742543313659338655762107146503332962312709377675547233,
        2908758188677609637189897407417077192823024312421188856772890351569144302218
      );
    
      vk.IC[16] = encryptPairing.G1Point(
        2017463481830074077479594468228652781012773210870610350548779426758690314120,
        2737973337799843510393244573056544536917977721511739143502024769208328967537
      );
    
      vk.IC[17] = encryptPairing.G1Point(
        18775844896041465299530739799494848369601569967461337810087931461082239594616,
        9648529137416180986166777209898898175316042553006834797612373688997726828164
      );
    
      vk.IC[18] = encryptPairing.G1Point(
        5795886612624421049917942233976057226711403878349085446900491371758539009600,
        3675713480715479515982381241821057633013419670099139419164648254585720718379
      );
    
      vk.IC[19] = encryptPairing.G1Point(
        3483456206450310233382387783632016495305478257020322110110215531351598508271,
        7347880234761859779373402350343363457554226564822455985004646136115042324208
      );
    
      vk.IC[20] = encryptPairing.G1Point(
        2271154196542746858395693151233357057088453590665339761856084360374117904945,
        8261887061501655554158848824879769530902935636951211432818735804521670184743
      );
    
      vk.IC[21] = encryptPairing.G1Point(
        18326180100834328755061819783709762097324197780899386136132525025219448871877,
        19124777939645835400053790322211089821594004267238651620237626519322886698310
      );
    
      vk.IC[22] = encryptPairing.G1Point(
        6262698861420859777657387549039553242300042396292066496352874228809184936386,
        8470358991284933857188980328451547825328321435597523904166856009782121013186
      );
    
      vk.IC[23] = encryptPairing.G1Point(
        17290071383001477493773187859201045615235250271643166485877474480350454793353,
        11813526994456226869039731849414108644408555179350645888365687629082299273609
      );
    
      vk.IC[24] = encryptPairing.G1Point(
        8473177585333951093879101108166008963677284912083360341021470299207872544955,
        6762208806740647908918315774609826869543256070502274359428319321181169820883
      );
    
      vk.IC[25] = encryptPairing.G1Point(
        15423537135989017677514937577988476625250288099125001283596068715347610271599,
        821925959645403286791205242794051438611408679076769829754481786417239696260
      );
    
      vk.IC[26] = encryptPairing.G1Point(
        7719400255102484779439795353011029132491402439573598829070767333211249948423,
        7371039177408436105661482664267174799260586925148400223883208445311733453107
      );
    
      vk.IC[27] = encryptPairing.G1Point(
        11419707184766790025977101270482190365229346600437560547303509722912751442897,
        21518522312340965713182854081080044499960224247638955997650760442678632843162
      );
    
      vk.IC[28] = encryptPairing.G1Point(
        2625239762007889488522025959569643265266185659815709670734290876942706814806,
        16033408547877588825794275150683480852045046335841463917448393937698859427013
      );
    
      vk.IC[29] = encryptPairing.G1Point(
        235197569812105149837172017118547747784918647598958710823160289258677263236,
        17482028633607720847758669785173708204071208091466433964947134098209503515534
      );
    
      vk.IC[30] = encryptPairing.G1Point(
        3207923082866899175033030884729017018136622864940117006728761296070995023026,
        2133429243885629192137228849628564317596488989104770481423046347802480469418
      );
    
      vk.IC[31] = encryptPairing.G1Point(
        6812793631843655167906864644163616860745687623847956980455148463987377936260,
        3280476608452559038446556145942680482681617363576461588168955044651770938600
      );
    
      vk.IC[32] = encryptPairing.G1Point(
        19967925397803828221123333024102771566373474104427153457965315131583070965025,
        13580115777136607681345463275992143768475779788323021710105043937027161840709
      );
    
      vk.IC[33] = encryptPairing.G1Point(
        21343478020453417367337456347841455130253757932365491605876876923567623303210,
        5555321713397914197501750546870226689457324278446157319644129851976309114563
      );
    
      vk.IC[34] = encryptPairing.G1Point(
        5175614910221740454910904583812930124651938466027594464871729988478916843596,
        19655528588043120101285110450240747225500002316132594349048576561728864221801
      );
    
      vk.IC[35] = encryptPairing.G1Point(
        16001524833978567998995077939976108181322341904263287749243804747226169608447,
        5030281413860076419398512434974897371595713632341369144203243976761295617098
      );
    
      vk.IC[36] = encryptPairing.G1Point(
        14317131571521282205579917309604322836814115963212166402233247715185600027514,
        19340690265242932721776630635149980153441860590794951953318323151120634721786
      );
    
      vk.IC[37] = encryptPairing.G1Point(
        4034764043533385580396788718873635722715935318647672753526863322478395973960,
        2886160452034740026920318812357813704727104440996045304034650312110475668443
      );
    
      vk.IC[38] = encryptPairing.G1Point(
        19902127082756141778290304270845375930611804892378059422864299160391751366990,
        99188875799934284911990718364207389151718780806198113576257633136864157494
      );
    
      vk.IC[39] = encryptPairing.G1Point(
        10643035622186123155387015148284702506043449742614176759017417964897501193386,
        11322013303728391955213480670816849055755202090028364281570165111447178215760
      );
    
      vk.IC[40] = encryptPairing.G1Point(
        13596314928445532973721643286992420416631270380313528123141196454016962631956,
        15424665761095802689047957680310726490740832627452359623056388630215940717536
      );
    
      vk.IC[41] = encryptPairing.G1Point(
        6408286156582307845341459668803353466141051492735632960388262500643948112132,
        20776237620904246788847198443525229714563398744082083813343565173447411243400
      );
    
      vk.IC[42] = encryptPairing.G1Point(
        14862115877552714424866405808159117277846117648531071857256164862204035019493,
        20904405759989598016090479126988716982989016684011983019251551470757889066704
      );
    
      vk.IC[43] = encryptPairing.G1Point(
        11808230995969390902350650287690092855225863102842877519657158100348312500292,
        9131835233259870814914633764921584439572408468065824044221751012225433503667
      );
    
      vk.IC[44] = encryptPairing.G1Point(
        18674546621279050508217428948698280502967020071986671259832267118108276611016,
        5754212094318872092589606649827831960428156506394611588582831338409036768971
      );
    
      vk.IC[45] = encryptPairing.G1Point(
        4423147508226858753015347004401234443829123924427281016959014140936524713809,
        14827289558872894214590597361517691540825413130046754550885321882130466562898
      );
    
      vk.IC[46] = encryptPairing.G1Point(
        7055712613650167689317099611064588379368216497446158966460789633850624892791,
        15205916915448946251847226717516147765419013215578211041626414047817529289512
      );
    
      vk.IC[47] = encryptPairing.G1Point(
        21284379041006093386957779823120452884236357431287707215172214830848888962757,
        20941593556490895298963453930215607082030897869677544695344257023703090366251
      );
    
      vk.IC[48] = encryptPairing.G1Point(
        7187968933388884324554345425361655655332286100865578202729009462310399785664,
        15331388868845104874493469449289300283245786039472822535139079567298483799016
      );
    
      vk.IC[49] = encryptPairing.G1Point(
        11088858797164998758945450815782319165952864801133524910522260482933889779521,
        21249744507752241324783347119042293961177688214576229208780959444250619110471
      );
    
      vk.IC[50] = encryptPairing.G1Point(
        10786314908969564246818473221850397858440172693112286605865765455842551427924,
        4443419412653532342859220687545477453332053037169781730643067713100674626360
      );
    
      vk.IC[51] = encryptPairing.G1Point(
        6983986715756363575212756886501020534168920247212932027296261286429247394911,
        1424193511100838123477958906182308617999375663407962905818192321257792940725
      );
    
      vk.IC[52] = encryptPairing.G1Point(
        3650676417449067846986205681751087233844639774183242348595966662537795622452,
        11822369973821733347605044376599582950752206917594358146545304181236267301588
      );
    
      vk.IC[53] = encryptPairing.G1Point(
        12060271643658631283129950823333337497828437032576293937306959349725268072732,
        17382073355402307795681487502367673489045705588766000712393330950513974212147
      );
    
      vk.IC[54] = encryptPairing.G1Point(
        8901359503433915089781204674493673653132415352725093073159727562001731433368,
        12358895924622215248664581227360407147175225059741965569398445892680006686830
      );
    
      vk.IC[55] = encryptPairing.G1Point(
        78762817052005148475557119791425667352254639313709313235172550239841497018,
        19953082868265619658017013152462754022539806087569376931245790444221008042671
      );
    
      vk.IC[56] = encryptPairing.G1Point(
        5861801675337959266627977280547531691962743603633233740716811030645013750463,
        584549086874697194244312251078152051104848535011241093336273350624682201124
      );
    
      vk.IC[57] = encryptPairing.G1Point(
        8332493441044995205606592034372470996564171010851565302551983895123573591918,
        1367650294948199799510048672622835763480864205577898002785300172269045197528
      );
    
      vk.IC[58] = encryptPairing.G1Point(
        11879966425913905883517331492338438651525814953896456424487677648710404186724,
        18740274001712633917855230972064136923067878108521963685707992600953884107630
      );
    
      vk.IC[59] = encryptPairing.G1Point(
        19723943865423209846739000079932163001332859111395042950062280514554826810331,
        6795430942754205855962998384086843702256365191064844856656530011964227287806
      );
    
      vk.IC[60] = encryptPairing.G1Point(
        4430897792340736104401042996372525434683609849300635682866399959912599369317,
        16334688315528525316771073086277872588541743840969570355699428310521344999334
      );
    
      vk.IC[61] = encryptPairing.G1Point(
        21007164995559009024471398981352962392416492561285761251370290785397225595957,
        11672437384650218587180902727424041087087501859592340687380013374048072359958
      );
    
      vk.IC[62] = encryptPairing.G1Point(
        6774807365098388082431468614848035664564641492936613682687734183196530758983,
        18515057948896988646867384333466502524501390203432968951171163129746066977740
      );
    
      vk.IC[63] = encryptPairing.G1Point(
        21354264777816122092923916809773494416440519507315650773469110020767391085693,
        12928486359092386194593378961923530722669130130694595577878944096045679809832
      );
    
      vk.IC[64] = encryptPairing.G1Point(
        16204911443959801493190326532918388062578644431942446511765016795182962351613,
        4152735663785768808615684987918861360052245384655284461045510385965987995495
      );
    
      vk.IC[65] = encryptPairing.G1Point(
        6188942348915625613066359134243994138440825238460704836139145005684927953402,
        8233140870967856143437823111333787632532118704266585163880199025355234705373
      );
    
      vk.IC[66] = encryptPairing.G1Point(
        19626284806863454498186490054974860220281263693145418875710924234349016461549,
        7111193807332430088233350412324387504256685007834085459812787411916936540531
      );
    
      vk.IC[67] = encryptPairing.G1Point(
        15970240461902222558805010216482156882256670502781958899269454754835580662139,
        4934360400409902867687360269833129454874322786143232302734404128739788875089
      );
    
      vk.IC[68] = encryptPairing.G1Point(
        7169019016723699206734673584679234547375659135572063100962850956770653944875,
        7368760365028610843052945281319485986083220093405382963826479228969034226787
      );
    
      vk.IC[69] = encryptPairing.G1Point(
        15932876827545835192805885765914475944547219221428641697467412724564402121408,
        8329234192826868853241832795885181173945788907548243475692928186866897953540
      );
    
      vk.IC[70] = encryptPairing.G1Point(
        5921001623173257438819615675412368529718206190993422173513992532049468861157,
        7110844431289299311171393261571808652352361127870787530622152020614628268647
      );
    
      vk.IC[71] = encryptPairing.G1Point(
        4600943458266749525920238572648069216171871321407650802034792323392165063665,
        15826008989425229962318535499684661499009231472915808075056830090511608526478
      );
    
      vk.IC[72] = encryptPairing.G1Point(
        13068574748276003649454384647806515501148832236972945618201503188151860010970,
        14691464400329334900872413066714719640543222830027391298459334062295810312330
      );
    
      vk.IC[73] = encryptPairing.G1Point(
        9396789976103152914379737603994400960701207465281205793788131313680289398157,
        7174182847571322613055872614863563150948233580147685848194574433652838354784
      );
    
      vk.IC[74] = encryptPairing.G1Point(
        11539293459246324620206800792300063648639384352337331897602001210957793975543,
        19787432931920238523947745183564669818705212224284541459443125836093327532554
      );
    
      vk.IC[75] = encryptPairing.G1Point(
        15080990737641815326921669894549567525590492561409057923611315487374098990023,
        19858317306486872976991966323786835265479537379391880093595722343546732466915
      );
    
      vk.IC[76] = encryptPairing.G1Point(
        3584540728649842992174043263111814830363848163151093243926692582951459719082,
        639257643616640250884926787342302819305364884792806243612384721559765504263
      );
    
      vk.IC[77] = encryptPairing.G1Point(
        4273241058190310796643999316382402752650071001496301711368730136597250298840,
        19369321142790161733618046373183682310178655945018806057872741610380372452827
      );
    
      vk.IC[78] = encryptPairing.G1Point(
        272499841877690166576840558481600920856967565767432408172882063329839573281,
        17921725769880795946605711378148237042208445859677237025714402011448763998251
      );
    
      vk.IC[79] = encryptPairing.G1Point(
        21721465111017321769830920393485089516764363533717217882697503355372111989088,
        15341671821372685199984448074874897372211991096768906428104547357257172366627
      );
    
      vk.IC[80] = encryptPairing.G1Point(
        21768319318420986984531018788897774033372473270507301419646898728644768996751,
        19544472155316731280937860644410361973181649931746582546359401265126921524852
      );
    
      vk.IC[81] = encryptPairing.G1Point(
        11079352023219504017374863003510165131795499075208564469090382026260635416447,
        210648695442196307462428514997047551745773545472900105743575759407753682837
      );
    
      vk.IC[82] = encryptPairing.G1Point(
        16358825899671514762650034591817362521206620275156477096138224114003420428585,
        3003054706801688450869090242731979376694271832103157082033166263097412013049
      );
    
      vk.IC[83] = encryptPairing.G1Point(
        20320980866069142452071742746289721607189572189703557923160979214318310494950,
        18981556558254714810539878215105181680590735157643600062561896134619917686724
      );
    
      vk.IC[84] = encryptPairing.G1Point(
        21116060871833286236478147202582360715365174088469988336664706637381472128439,
        7095982631271336663853751008959804661066795302248558656488461672040944209032
      );
    
      vk.IC[85] = encryptPairing.G1Point(
        16446089718099676813365301231032291382128348869187412090154137632640656703008,
        18373343652688711936662350574868117966981079711419602404765053358241758204277
      );
    
      vk.IC[86] = encryptPairing.G1Point(
        2269214023714049907313091000901681947061091020717905036960672922762538112117,
        12110022698799468317591046938543803902476695073491463486087257878724434327824
      );
    
      vk.IC[87] = encryptPairing.G1Point(
        17885767837306866608249337286245290609385762690125108824411172128063193807211,
        8829784480628493241258666416794722978349649294567547873387748687165277559777
      );
    
      vk.IC[88] = encryptPairing.G1Point(
        10218689470749034835496971517047878923055871140573461901166504759903216344519,
        13390587051111066470853184754112101323747574039949291309233674739531239781525
      );
    
      vk.IC[89] = encryptPairing.G1Point(
        19286208953893311262326460345551941281024068392610940500260811300261406674102,
        17938604108642151734940284251406741554937831762410638858730073109376419879943
      );
    
      vk.IC[90] = encryptPairing.G1Point(
        3539762868537136405124279530211863984802804456936509332728846905466221241497,
        18935243619428274906405782136948748724906542507707896532521863374659928462461
      );
    
      vk.IC[91] = encryptPairing.G1Point(
        3306573722266519317025782898165114313922492724417921620068555576309709911348,
        458272975385361683867812583849145967603457956651334476457200352597644638723
      );
    
      vk.IC[92] = encryptPairing.G1Point(
        18525152771895395035846876226579142187512541853544192567547847673585017455031,
        21059867567611660273299804517125971799761022325985241251360869259153865392222
      );
    
      vk.IC[93] = encryptPairing.G1Point(
        753153315949457372244801422754897538495755480182132887902068442847845734186,
        17989775825350174722987066480224866248670738469945301096990333971582755345794
      );
    
      vk.IC[94] = encryptPairing.G1Point(
        16429838277767362986864868930272845566571137744420059103232463623360418529756,
        18914148445199994482357040302032377476214149463830198108222527007673843856049
      );
    
      vk.IC[95] = encryptPairing.G1Point(
        3082802264337218435637908240298185076398652788859025201311276800747878229721,
        7223254470795586304912156553007433004884806001438329369470741850197035882089
      );
    
      vk.IC[96] = encryptPairing.G1Point(
        12154291980291375215580708701580795787452057661798323503325611201924275398210,
        5422816588602484833031951175918619249597894060396236293586624492959720265064
      );
    
      vk.IC[97] = encryptPairing.G1Point(
        8801682358769366940704340935211975674852289440901630293034680436267583475488,
        1288430432637759639440732611549897651706018461785254153683050314802643842802
      );
    
      vk.IC[98] = encryptPairing.G1Point(
        21778949033853638296811015253740147586044172438064130491627355461942764550018,
        13939650572101082001670661822457557589309458512681923054782440470752803461847
      );
    
      vk.IC[99] = encryptPairing.G1Point(
        2284757465065495943461937566384667294940215912191333887586823780719086861305,
        15464262726499527705189075697500722484203305353221675768498737906446027534197
      );
    
      vk.IC[100] = encryptPairing.G1Point(
        21147610927872807704403092947448468143192317419686144859024280524312903567757,
        17772190396543631789959257949427829936026259685257937607010092324492586255464
      );
    
      vk.IC[101] = encryptPairing.G1Point(
        20385314557372324264152761267033012343561212904977507062968109871005700418880,
        9722510406540939537073933791642696541257246241443327460101218493760427833660
      );
    
      vk.IC[102] = encryptPairing.G1Point(
        20266300797648446923940870515381391801789628086949732566336921566513567286957,
        12497236662813943375036297617634616380246240355783498701570104965345596931278
      );
    
      vk.IC[103] = encryptPairing.G1Point(
        18133830790226201543946340805907666844607481233037212668395969040315898651321,
        11382866975236709480952558448775036371285051504259104863426225686370251888116
      );
    
   
  }

}

library encryptKeySecondHalf {

  function verifyingKey() public pure returns (VerifyingKey memory vk) {
    vk.IC = new encryptPairing.G1Point[](210);
      vk.IC[104] = encryptPairing.G1Point(
        21323510843110474161288875565374584586603956720209998234901128544499577622046,
        20430522108461987251920058992906310529743685940924016417033628707483282889512
      );
    
      vk.IC[105] = encryptPairing.G1Point(
        6497720137237237525061487326489667416527064448657396454232369242755448738272,
        8361413934417462639763933102327867735440740313521226905203814836801837717288
      );
    
      vk.IC[106] = encryptPairing.G1Point(
        2839322325619902825099875280452182065164425408487637615267779917940714294033,
        8559665848348054430333260557771861344916900745246164109509364706073632106086
      );
    
      vk.IC[107] = encryptPairing.G1Point(
        3637379476434176046283959865411631664695522657179649562928046905059942820928,
        13905393848617410596321789221701564173207881878963042213680618213055046091893
      );
    
      vk.IC[108] = encryptPairing.G1Point(
        21714539525643515964916345627215003871274472023987649631322554011518144945004,
        19622165495584042856177666280301135993457567447276917562817041143070373008899
      );
    
      vk.IC[109] = encryptPairing.G1Point(
        4588615366324889064479428653189211998355142723802105862381768655358368894975,
        14336798481487057410408125731308212224441680514126573463281324400130422407578
      );
    
      vk.IC[110] = encryptPairing.G1Point(
        928027114539968520693294659252413283591411288095991249303815541579630690501,
        8217194294342483687753277698208983636805528735721894875236431756986591780976
      );
    
      vk.IC[111] = encryptPairing.G1Point(
        13408672821862254000861332155009577546601197739716849973862176454510910763251,
        20262628886256846888236176015467659412812847706935055673295001612355473648514
      );
    
      vk.IC[112] = encryptPairing.G1Point(
        12316164149782623461036675094418852000771054076492652165678775263894292952396,
        12705956329018384864793534256888354536436259361485253019573500651986392364249
      );
    
      vk.IC[113] = encryptPairing.G1Point(
        6624566619179617148554181388881599955719777281797445032778336516695825118365,
        17745785773832764337325572883242506216041495477150301048566890534950062698908
      );
    
      vk.IC[114] = encryptPairing.G1Point(
        20359084141577165831508264604072368466497634108122033005058873137704150394861,
        6715451819382122414740042859371957758214280917861401516870109493077540652437
      );
    
      vk.IC[115] = encryptPairing.G1Point(
        11615304638921870474756683331797582028451562953362364512723627896419746825460,
        20893899662546769613950494602007524621854436629744596727521068103554238084674
      );
    
      vk.IC[116] = encryptPairing.G1Point(
        3882054065150451821676196620786633651105500180483175175104128560208064339416,
        11960429157011880935128221110766801609728859385294695018604042359093657934438
      );
    
      vk.IC[117] = encryptPairing.G1Point(
        8457452990939444971924686117953943319878718522958444166326719729038636762549,
        5600009663433519654759420207242376965852316335747823027182742059461947808517
      );
    
      vk.IC[118] = encryptPairing.G1Point(
        20949992463711200249710884440277312724275103498376474686091291539037147067189,
        15157143775932475382536467939303614720170233386819304763560512065576447674940
      );
    
      vk.IC[119] = encryptPairing.G1Point(
        1478920072850447549124265161007302216638705664894884727949229548545462715436,
        13807652199881986017629781311223328682568418002423955368907580471590603400207
      );
    
      vk.IC[120] = encryptPairing.G1Point(
        1422008260060096352530933049707291438043703272964573483722981457576281583825,
        1662117051146751833604750340996831162823052647928078777523546939196164480553
      );
    
      vk.IC[121] = encryptPairing.G1Point(
        18254030897803798521809027973488199378123956052221358696941351654327268309141,
        5643558544176520758984974013254063045296607657258566058070613809147136657013
      );
    
      vk.IC[122] = encryptPairing.G1Point(
        6741177670979725744112950856251654765050874055408525466173245066673356428321,
        19056776893262589159485033604784967595823828454413924502284626766977186379962
      );
    
      vk.IC[123] = encryptPairing.G1Point(
        19892589373704724484566284977208385804458920451023602463648553239914881210043,
        4469356706727324737819724152071838430664127769335011616933027038371171249681
      );
    
      vk.IC[124] = encryptPairing.G1Point(
        21338653159054417694546282761506369589540267232985556106385507377102226487177,
        1014206782250379799587947549473683564827507936919554987183309342692965529850
      );
    
      vk.IC[125] = encryptPairing.G1Point(
        20329415554516877375217113870828644526746503543174947927856324253323347548006,
        6449372889176304047154786871724291433870641783039538876936928626351282015218
      );
    
      vk.IC[126] = encryptPairing.G1Point(
        8703370927531146208105442970194299997309910427227005940989431524621541886301,
        8481724521060081718547154630362864992339159690989979234424148015529107392488
      );
    
      vk.IC[127] = encryptPairing.G1Point(
        2444063919204377383395120723185081427943827868492127049128940541986852190222,
        14128046871354720723874020003371592896633362026947614149140629591768067619770
      );
    
      vk.IC[128] = encryptPairing.G1Point(
        8415627394285483855270393575330671580483384768115516646376243496615517665285,
        17644250029756010211665215078161309230078129129422746340462618360803298035600
      );
    
      vk.IC[129] = encryptPairing.G1Point(
        3420544616848538080940579776042340612990256087250742231081119638072428787117,
        15124713204400782044487885678782213517451323200335820284578836659250889041892
      );
    
      vk.IC[130] = encryptPairing.G1Point(
        1564245801997425718382280489724836850822750300017393477443244818389780663290,
        6120586977629499327202774577167097825581522585133459360495375352839903607783
      );
    
      vk.IC[131] = encryptPairing.G1Point(
        17519320847990329914497575615358210065555098199222222296918421182380766941772,
        8328259405730347914371477093866729706175195925006858503722041189640571342595
      );
    
      vk.IC[132] = encryptPairing.G1Point(
        9710880389477840553981285873098159392153275967605466458685637424578131491646,
        2230054815264577522743867991619715034814361480365371282957018775706781647816
      );
    
      vk.IC[133] = encryptPairing.G1Point(
        9482925022341053498277608830000986498334292434665425781410041121467500002837,
        3800395987897034845032050473194666530533101792719476488145327140138397251846
      );
    
      vk.IC[134] = encryptPairing.G1Point(
        12507214322024030786577470202868531407233108157860452579063868060396902861570,
        15820304496516292799914080383874882076864929634625874051166404986966832704665
      );
    
      vk.IC[135] = encryptPairing.G1Point(
        20763081988280083412769462956242780799179670317114865944659859005519456636676,
        15691375105487753870608273069484019486572828314750781926152488377221798653035
      );
    
      vk.IC[136] = encryptPairing.G1Point(
        19214220891652655352367947936662890279525050992003302662813131246715340292214,
        8273506224413326931382118460887469456861316079898107978940780286835666042566
      );
    
      vk.IC[137] = encryptPairing.G1Point(
        16250361512863769595445016252743329205704071149126001191390826108914219814108,
        8019520753159772201972857326664781623639074605942469221086732660026352808370
      );
    
      vk.IC[138] = encryptPairing.G1Point(
        13142614938465375189297423121200020262080315005619266714070808906077519018391,
        12766753482027313142000309387276376312049967353534764966326335896181372210468
      );
    
      vk.IC[139] = encryptPairing.G1Point(
        11165396909176963524756185443660089444666063011116415892360286686305516936712,
        6448474579388660045651398791349495885431228346088260227092662612371516722683
      );
    
      vk.IC[140] = encryptPairing.G1Point(
        8004331101119352321105917835536091383244019353664408456901847281024468415761,
        15928714708247704075117754281752307831966145592939095644722166259338263921402
      );
    
      vk.IC[141] = encryptPairing.G1Point(
        14633046731513846800157105757528455046351879444800905791824016223289541479387,
        4052709342794477689976682518815260631741515038890413663553774696540272979697
      );
    
      vk.IC[142] = encryptPairing.G1Point(
        471534000739620818721070583904871392402221859064961313553516405751987681541,
        7462162538905481599933975841507716253363517741825227348286674212380221922431
      );
    
      vk.IC[143] = encryptPairing.G1Point(
        19517077519713811100974676477419000426152107126131547585252423045748715490954,
        16063722676969714572917706503446535930102124082067383549971364803573902488882
      );
    
      vk.IC[144] = encryptPairing.G1Point(
        16419563611779525677348755977707850698148350983888578599701286782310390565962,
        7676917752061601119236277994108436379449681093759289717560034181428793225676
      );
    
      vk.IC[145] = encryptPairing.G1Point(
        17502424156508850673280085372582527771092623816579547692603884498914053942690,
        18423457500046903195915923643475899077535790258332615337551773426030781924142
      );
    
      vk.IC[146] = encryptPairing.G1Point(
        19220228106183079778777410209769023183629038709280886176339115148328506277329,
        4574298308341651074113391366204930341988816468233178025942726981109749720371
      );
    
      vk.IC[147] = encryptPairing.G1Point(
        21742977272516357250199281137117853063877507593824048567161250299117175800812,
        18482212082094354206459407842061248009547184606101385582745606431164391617352
      );
    
      vk.IC[148] = encryptPairing.G1Point(
        16290556965944364442982273105004343271731313331573959068954388305485342335724,
        15807273274067135680145240025807252954114599844494108869765971882330523266145
      );
    
      vk.IC[149] = encryptPairing.G1Point(
        10805657209575878945866474272499309737386574426903046910064316056174857422526,
        6058328211874488315423481654895429210041524171067672128014494964700315589963
      );
    
      vk.IC[150] = encryptPairing.G1Point(
        9063414810167568151701542929850626647008947373911425483677001686604255890187,
        16338796767808429355045569786644614555756848296223144582208445259715641226922
      );
    
      vk.IC[151] = encryptPairing.G1Point(
        13496925187633690674019437755832604662820805947256323161480077256715161319894,
        20035215720820269483295550804856788956656545052276313719338715669330646147795
      );
    
      vk.IC[152] = encryptPairing.G1Point(
        18765966381262750278484753551777096045342623413180053451012811077175931561799,
        11796266525650843616535605772197570632414959889519321131559917053251050460892
      );
    
      vk.IC[153] = encryptPairing.G1Point(
        17442877458278119104926012558382097236620236886870314485482616825907285024869,
        11940605756826624838218304712496520992038981954475591837668546790429982265499
      );
    
      vk.IC[154] = encryptPairing.G1Point(
        11134871309381083816596724750211617452008881167217841358827456519462616268204,
        14057457932644240612707744994223745949767688310133526083501335345076991976914
      );
    
      vk.IC[155] = encryptPairing.G1Point(
        4941348211937120433839766690409269776702249909217310196550086255032697563681,
        5432582764187564298867775799410512330247279391180406107858752163480030295631
      );
    
      vk.IC[156] = encryptPairing.G1Point(
        21782525233881664739009709468194144874622293618252951763669244734739593735205,
        21312136762871903232364300303547806266575721667135187728014057861204533080858
      );
    
      vk.IC[157] = encryptPairing.G1Point(
        17380149958687738505520548619665418539190296370998648966756702476762492982275,
        20522149316755984264279027013039048394987054617834994407767815316367594470384
      );
    
      vk.IC[158] = encryptPairing.G1Point(
        2582218068341216336213497298044236157779910564694347890528355806565020810568,
        17119519632377543486922998160754386915918297475956639389316301234138807353927
      );
    
      vk.IC[159] = encryptPairing.G1Point(
        13274115116838299054158922388420425008313236376713424589822192721350293218134,
        9207618440296471432332155677680960207598201865140698773141886746960618528245
      );
    
      vk.IC[160] = encryptPairing.G1Point(
        20749414462129553176864664895313322584803170481450286528002182723334344549848,
        18390118547490696549018775907585334192921262672644643958359267900029434132106
      );
    
      vk.IC[161] = encryptPairing.G1Point(
        19594727287236983928182875724292950896041140720338569347123192092400459795668,
        1447089770585005670899930255249475548398824138156450274378044792072258045296
      );
    
      vk.IC[162] = encryptPairing.G1Point(
        14783430521342404579236610313946536304206668110142112114096818531141884325330,
        20809814492866748878018344467013961882552579076797322264209800162322425757378
      );
    
      vk.IC[163] = encryptPairing.G1Point(
        12289900779305463023012085213976252312766565696149115580870272479769049120074,
        6056585194303160688786687176847081370852126543130698431753701442086647031138
      );
    
      vk.IC[164] = encryptPairing.G1Point(
        6950499730711305377117434941889701884279626388402598243856216882963591313518,
        19052280146997920569958923596769928092628900129958376457064641703697834711880
      );
    
      vk.IC[165] = encryptPairing.G1Point(
        15066117095365527540588576605266705006307924000518038923257277021551635281845,
        16969928170546248252904591059982117643119971190833252948906469945625707690180
      );
    
      vk.IC[166] = encryptPairing.G1Point(
        21256575457741255522070731429214522144863710439972604086169883510586427819283,
        11334987487528641100471547945902133506134944935423212951037781023427132737944
      );
    
      vk.IC[167] = encryptPairing.G1Point(
        6175276742736845490781433049451289219471942771816711833809108746848312120812,
        16231369018441045162425068719653748720588382558717659735443052430382145991104
      );
    
      vk.IC[168] = encryptPairing.G1Point(
        12423284640810708714425995864819356819775325091959957280232485819022240658269,
        12759929181739440354987332212004991972236026326998900088875335171811059533194
      );
    
      vk.IC[169] = encryptPairing.G1Point(
        9103932002748017153340735353939155270686357657906124262667421870786428491580,
        19438862684548149751346552208528285443592200020729940710726767285449583470480
      );
    
      vk.IC[170] = encryptPairing.G1Point(
        6382027586862376306855308928329787784291281261288450623266799775262693688774,
        17366139362667013512081327848683933829974924859271099078854376118995848577708
      );
    
      vk.IC[171] = encryptPairing.G1Point(
        9147431376956806103778529157659075421734217076246356863936167697146790416940,
        21628315825739849457950092190205197276685177413377698509187151889941122594238
      );
    
      vk.IC[172] = encryptPairing.G1Point(
        758303348416511383395803334324848914017474163845119582192317881000006691320,
        11350560771711338338713572553327837055354349380376356552730751040886900625679
      );
    
      vk.IC[173] = encryptPairing.G1Point(
        5309646695200013560310571549408285951873160802900077759703120556169051744086,
        8347883785714374670787819638066831203156160861076048718433399875707768005125
      );
    
      vk.IC[174] = encryptPairing.G1Point(
        17674454940492559839735282084096117299451565174497635484593017432544329719057,
        14133183194844463136475167639822626091693511305715024700926991353622243241121
      );
    
      vk.IC[175] = encryptPairing.G1Point(
        815180562706050532896921303617466322858383844326400937427021357334931469970,
        3603345675314353737403469436406427706997978194268398562800618314628855617409
      );
    
      vk.IC[176] = encryptPairing.G1Point(
        3213325337336154546626494971576575791010853731489416888148124340874709125343,
        7695264536083474038512759673495598044362614741237231880971462986152387111975
      );
    
      vk.IC[177] = encryptPairing.G1Point(
        12115023249888021438270504966833913761164274193400915684796241993578195206526,
        11527208988816979929874778672079402829297155649170584564639302158758200011481
      );
    
      vk.IC[178] = encryptPairing.G1Point(
        3803306692538553179345317235873037999770920578701313888228405043823655835003,
        11131226839114979436275380840139750835216115734782626510181135405095141877688
      );
    
      vk.IC[179] = encryptPairing.G1Point(
        10974316634300737151067032253479063898439671834369132649583908171740468895556,
        6347817652291327629071711289159895029463719873645175996277811878215237492453
      );
    
      vk.IC[180] = encryptPairing.G1Point(
        9237886916455579684322539335972769740098370169774562268645496857848127426002,
        2448917225022557983705369437697493453986309585998570543984953234410734301478
      );
    
      vk.IC[181] = encryptPairing.G1Point(
        2035450513051207153000660638346860773076862622882761254103070537213352756628,
        18471912403571568484945329367609084826262950345950895821409094632318997526672
      );
    
      vk.IC[182] = encryptPairing.G1Point(
        18648445434368678816314988969889262590481108937132931876931504041755071632162,
        14006384079198825473376100115117081406287245236646779681050915056227512843883
      );
    
      vk.IC[183] = encryptPairing.G1Point(
        19050173660058773952134982833156283534854983496915498874946401436275613967320,
        7641231471867894592016369942064765602650277806793243774109236528925915794224
      );
    
      vk.IC[184] = encryptPairing.G1Point(
        7153761688521924775322507836306567166711669564523940842734855791353643048829,
        13995802104266178711526070885875640765111235847382571060483964780033185406986
      );
    
      vk.IC[185] = encryptPairing.G1Point(
        17807743541243785483845692929364090891007718824039092754311548533697095181705,
        12247491845696401979098323058465018486994049062537522066575462211455076395677
      );
    
      vk.IC[186] = encryptPairing.G1Point(
        9709899624799746124433657031322655993206186474905498096981946907459253112529,
        16812692079254346882145344973048552530218143039043947823052397810738895992295
      );
    
      vk.IC[187] = encryptPairing.G1Point(
        7971673182969114449916575087673907972750587128810636232958293656027741313820,
        6356638681566705155984797598695874002883229851425799430432845555566782269644
      );
    
      vk.IC[188] = encryptPairing.G1Point(
        2484387865555363668284602040467284126910436828644270703430972900669948840262,
        6610652364042234297270557085690667771633801657030495701978085619650010224868
      );
    
      vk.IC[189] = encryptPairing.G1Point(
        13861755832886637946006548880453807404864149801408340163048426568736625186339,
        2488244185072796578933233508222928031560347536497545773127275016330279015650
      );
    
      vk.IC[190] = encryptPairing.G1Point(
        8666725742553028838132589176577663876959852024010152822535871693260329145920,
        5187911047401203406208661366134673805726101306916079710034017222873503113144
      );
    
      vk.IC[191] = encryptPairing.G1Point(
        9723992786834440260730805082746436125619614999894452411915070430914398081304,
        1897148851701936029849940538793243572698595483589264183157033667463129997129
      );
    
      vk.IC[192] = encryptPairing.G1Point(
        16367647283358955453385734166925455364976916504840874457379047837610952566431,
        961098168482770753315847839487414602349222232313989353383128687705372805306
      );
    
      vk.IC[193] = encryptPairing.G1Point(
        20581925539391657110761170510137227208618105349712652240011608678630237946389,
        2600452436541804237790918337089820615575634767191787217235585978718016668416
      );
    
      vk.IC[194] = encryptPairing.G1Point(
        4214894207212119749871603838823307300603412521668557028989526286118705608792,
        11453108674828775033289988529519661641600758060607479200468950960744829611864
      );
    
      vk.IC[195] = encryptPairing.G1Point(
        9377351413770291006347526992866802658576881023050033875967437744698883020053,
        2555068492670184634387004747394880984449735651802536357626944026206198824340
      );
    
      vk.IC[196] = encryptPairing.G1Point(
        2770232625666425186950349789391413648724053036461582852389040430398731225972,
        5891454879435550054773468925969580713590851634052194930240680813482274442148
      );
    
      vk.IC[197] = encryptPairing.G1Point(
        15158176006563958244783181153677977406320092148168262530302393453800976482458,
        19209549539193590903618417924255924733809462953887611296488600436541785890658
      );
    
      vk.IC[198] = encryptPairing.G1Point(
        14412082379332044441775083831073073440808915359486805035951263062665589328725,
        17600014154743899319640548135934150299253267839813540518261941688368655458581
      );
    
      vk.IC[199] = encryptPairing.G1Point(
        3042574576746369060440224614351421367702625821230761209039868787244933257229,
        10699198662208357435767194474612657428623379293847595234033336579848925017386
      );
    
      vk.IC[200] = encryptPairing.G1Point(
        15486819044941297610026620108975688692062481051374981480977563128694785618429,
        18256550769867198130662538651383817628842982629464463421577944744541912956681
      );
    
      vk.IC[201] = encryptPairing.G1Point(
        18290935890005924924490609178625119633592629854281176556312078898412857905236,
        1756468293661298825540730783768689844381631764658681966238863989018919357692
      );
    
      vk.IC[202] = encryptPairing.G1Point(
        21885070803126830188659844722140141547866430817970793275673595415187473428886,
        1864784967439042433878913751377832634646075619049743629751303109896218757777
      );
    
      vk.IC[203] = encryptPairing.G1Point(
        19888808124687106408406515667004918131268959442191778302423299253148904550786,
        5078580933297778001401802334136607234253372793719076028865870429396280697451
      );
    
      vk.IC[204] = encryptPairing.G1Point(
        1546812530759592280872248769951684251561743460905832234277149578079105768983,
        18949634306967764873478268296192866556859380581604002106903659528458223060364
      );
    
      vk.IC[205] = encryptPairing.G1Point(
        2355938056270955136987471745214380105513522881415560353772001559875544277569,
        18228406330960076550938016904314803092748445565148127179380695631632135624120
      );
    
      vk.IC[206] = encryptPairing.G1Point(
        12317702608519302955265662793052063276685019275368871764423898207780621195038,
        2689966208835539749200647566267678100614069228011512520577951516814108275282
      );
    
      vk.IC[207] = encryptPairing.G1Point(
        8482650065548896723881376444891325091580548078537065886249763244016389218054,
        18802716648612834110499102905813730747803553597329049166976220139412811775703
      );
    
      vk.IC[208] = encryptPairing.G1Point(
        18683696331853725610490424639141191435719943009194781882850397063945982234449,
        7104863278286764120902860784369172352315548922533193889495933944843289278774
      );
    
      vk.IC[209] = encryptPairing.G1Point(
        10968081318080001847237182282294616910372332691112259601317623961400947256933,
        11158166639632076427842176993886477064494841886928929897176217416581100711727
      );
  }

}

contract encryptVerifier {
  using encryptPairing for *;

  struct Proof {
    encryptPairing.G1Point A;
    encryptPairing.G2Point B;
    encryptPairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    VerifyingKey memory vk1 = encryptKeyFirstHalf.verifyingKey();
    vk.alfa1 = vk1.alfa1;
    vk.beta2 = vk1.beta2;
    vk.gamma2 = vk1.gamma2;
    vk.delta2 = vk1.delta2;
    vk.IC = new encryptPairing.G1Point[](210);
    for (uint i = 0; i < 104; i++) {
      vk.IC[i] = vk1.IC[i];
    }

    VerifyingKey memory vk2 = encryptKeySecondHalf.verifyingKey();
    for (uint i = 104; i < 210; i++) {
      vk.IC[i] = vk2.IC[i];
    }
  }

  /// @dev Verifies a Semaphore proof. Reverts with InvalidProof if the proof is invalid.
  function verifyProof(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[209] memory input
  ) public view {
    // If the values are not in the correct range, the encryptPairing contract will revert.
    Proof memory proof;
    proof.A = encryptPairing.G1Point(a[0], a[1]);
    proof.B = encryptPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = encryptPairing.G1Point(c[0], c[1]);

    VerifyingKey memory vk = verifyingKey();

    // Compute the linear combination vk_x of inputs times IC
    if (input.length + 1 != vk.IC.length) revert encryptPairing.InvalidProof();
    encryptPairing.G1Point memory vk_x = vk.IC[0];
    for (uint i = 0; i < input.length; i++) {
      vk_x = encryptPairing.addition(vk_x, encryptPairing.scalar_mul(vk.IC[i+1], input[i]));
    }

    // Check pairing
    encryptPairing.G1Point[] memory p1 = new encryptPairing.G1Point[](4);
    encryptPairing.G2Point[] memory p2 = new encryptPairing.G2Point[](4);
    p1[0] = encryptPairing.negate(proof.A);
    p2[0] = proof.B;
    p1[1] = vk.alfa1;
    p2[1] = vk.beta2;
    p1[2] = vk_x;
    p2[2] = vk.gamma2;
    p1[3] = proof.C;
    p2[3] = vk.delta2;
    encryptPairing.pairingCheck(p1, p2);
  }
}