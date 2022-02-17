//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./Verifier.sol";
import {IncrementalQuinTree} from "./IncrementalMerkleTree.sol";
import "./Ownable.sol";


//interface for logicV1 contract
interface INounsAnonDAOLogicV1 {
  function castAnonVote(uint256 proposalId, uint8 support, string calldata reason) external;
}


contract Semaphore is Verifier, Ownable, IncrementalQuinTree {
  // The external nullifier helps to prevent double-signalling by the same
  // user. An external nullifier can be active or deactivated.

  // Each node in the linked list
  struct ExternalNullifierNode {
    uint232 next;
    bool exists;
    bool isActive;
  }

  //address of NounsLogicV1 contract
  address logicAddr = 0x6CC655b204C093BcD2B3b3eBC531E86E953563d1;

  // We store the external nullifiers using a mapping of the form:
  // enA => { next external nullifier; if enA exists; if enA is active }
  // Think of it as a linked list.
  mapping(uint232 => ExternalNullifierNode) public externalNullifierLinkedList;

  uint256 public numExternalNullifiers = 0;

  // First and last external nullifiers for linked list enumeration
  uint232 public firstExternalNullifier = 0;
  uint232 public lastExternalNullifier = 0;

  // Whether broadcastSignal() can only be called by the owner of this
  // contract. This is the case as a safe default.
  bool public isBroadcastPermissioned = true;

  // Whether the contract has already seen a particular nullifier hash
  mapping(uint256 => bool) public nullifierHashHistory;

  event Voter(address voter);
  event PermissionSet(bool indexed newPermission);
  event ExternalNullifierAdd(uint232 indexed externalNullifier);
  event ExternalNullifierChangeStatus(uint232 indexed externalNullifier, bool indexed active);

  // This value should be equal to
  // 0x7d10c03d1f7884c85edee6353bd2b2ffbae9221236edde3778eac58089912bc0
  // which you can calculate using the following ethersjs code:
  // ethers.utils.solidityKeccak256(['bytes'], [ethers.utils.toUtf8Bytes('Semaphore')])
  // By setting the value of unset (empty) tree leaves to this
  // nothing-up-my-sleeve value, the authors hope to demonstrate that they do
  // not have its preimage and therefore cannot spend funds they do not own.

  uint256 public NOTHING_UP_MY_SLEEVE_ZERO = uint256(keccak256(abi.encodePacked("Semaphore"))) % SNARK_SCALAR_FIELD;

  /*
   * If broadcastSignal is permissioned, check if msg.sender is the contract
   * owner
   */
  modifier onlyOwnerIfPermissioned() {
    require(!isBroadcastPermissioned || isOwner(), "Semaphore: broadcast permission denied");

    _;
  }

  /*
   * @param _treeLevels The depth of the identity tree.
   * @param _firstExternalNullifier The first identity nullifier to add.
   */
  constructor(uint8 _treeLevels, uint232 _firstExternalNullifier)
    IncrementalQuinTree(_treeLevels, NOTHING_UP_MY_SLEEVE_ZERO)
    Ownable()
  {
    addEn(_firstExternalNullifier, true);
  }

  /*
   * Registers a new user.
   * @param _identity_commitment The user's identity commitment, which is the
   *                            hash of their public key and their identity
   *                            nullifier (a random 31-byte value). It should
   *                            be the output of a Pedersen hash. It is the
   *                            responsibility of the caller to verify this.
   */

  function insertIdentity(uint256 _identityCommitment) public onlyOwner returns (uint256) {
    // Ensure that the given identity commitment is not the zero value
    require(
      _identityCommitment != NOTHING_UP_MY_SLEEVE_ZERO,
      "Semaphore: identity commitment cannot be the nothing-up-my-sleeve-value"
    );

    return insertLeaf(_identityCommitment);
  }

  /*
     * Checks if all values within pi_a, pi_b, and pi_c of a zk-SNARK are less
     * than the scalar field.
     * @param _a The corresponding `a` parameter to verifier.sol's
     *           verifyProof()
     * @param _b The corresponding `b` parameter to verifier.sol's
     *           verifyProof()
     * @param _c The corresponding `c` parameter to verifier.sol's
                 verifyProof()
     */
  function areAllValidFieldElements(uint256[8] memory _proof) internal pure returns (bool) {
    return
      _proof[0] < SNARK_SCALAR_FIELD &&
      _proof[1] < SNARK_SCALAR_FIELD &&
      _proof[2] < SNARK_SCALAR_FIELD &&
      _proof[3] < SNARK_SCALAR_FIELD &&
      _proof[4] < SNARK_SCALAR_FIELD &&
      _proof[5] < SNARK_SCALAR_FIELD &&
      _proof[6] < SNARK_SCALAR_FIELD &&
      _proof[7] < SNARK_SCALAR_FIELD;
  }

  /*
   * Produces a keccak256 hash of the given signal, shifted right by 8 bits.
   * @param _signal The signal to hash
   */
  function hashSignal(bytes memory _signal) internal pure returns (uint256) {
    return uint256(keccak256(_signal)) >> 8;
  }

  /*
   * A convenience function which returns a uint256 array of 8 elements which
   * comprise a Groth16 zk-SNARK proof's pi_a, pi_b, and pi_c  values.
   * @param _a The corresponding `a` parameter to verifier.sol's
   *           verifyProof()
   * @param _b The corresponding `b` parameter to verifier.sol's
   *           verifyProof()
   * @param _c The corresponding `c` parameter to verifier.sol's
   *           verifyProof()
   */
  function packProof(
    uint256[2] memory _a,
    uint256[2][2] memory _b,
    uint256[2] memory _c
  ) public pure returns (uint256[8] memory) {
    return [_a[0], _a[1], _b[0][0], _b[0][1], _b[1][0], _b[1][1], _c[0], _c[1]];
  }

  /*
   * A convenience function which converts an array of 8 elements, generated
   * by packProof(), into a format which verifier.sol's verifyProof()
   * accepts.
   * @param _proof The proof elements.
   */
  function unpackProof(uint256[8] memory _proof)
    public
    pure
    returns (
      uint256[2] memory,
      uint256[2][2] memory,
      uint256[2] memory
    )
  {
    return ([_proof[0], _proof[1]], [[_proof[2], _proof[3]], [_proof[4], _proof[5]]], [_proof[6], _proof[7]]);
  }

  /*
   * A convenience view function which helps operators to easily verify all
   * inputs to broadcastSignal() using a single contract call. This helps
   * them to save gas by detecting invalid inputs before they invoke
   * broadcastSignal(). Note that this function does the same checks as
   * `isValidSignalAndProof` but returns a bool instead of using require()
   * statements.
   * @param _signal The signal to broadcast
   * @param _proof The proof elements.
   * @param _root The Merkle tree root
   * @param _nullifiersHash The nullifiers hash
   * @param _signalHash The signal hash. This is included so as to verify in
   *                    Solidity that the signal hash computed off-chain
   *                    matches.
   * @param _externalNullifier The external nullifier
   */
  function preBroadcastCheck(
    bytes memory _signal,
    uint256[8] memory _proof,
    uint256 _root,
    uint256 _nullifiersHash,
    uint256 _signalHash,
    uint232 _externalNullifier
  ) public view returns (bool) {
    uint256[4] memory publicSignals = [_root, _nullifiersHash, _signalHash, _externalNullifier];

    (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) = unpackProof(_proof);

    return
      nullifierHashHistory[_nullifiersHash] == false &&
      hashSignal(_signal) == _signalHash &&
      _signalHash == hashSignal(_signal) &&
      isExternalNullifierActive(_externalNullifier) &&
      rootHistory[_root] &&
      areAllValidFieldElements(_proof) &&
      _root < SNARK_SCALAR_FIELD &&
      _nullifiersHash < SNARK_SCALAR_FIELD &&
      verifyProof(a, b, c, publicSignals);
  }

  /*
   * A modifier which ensures that the signal and proof are valid.
   * @param _signal The signal to broadcast
   * @param _proof The proof elements.
   * @param _root The Merkle tree root
   * @param _nullifiersHash The nullifiers hash
   * @param _signalHash The signal hash
   * @param _externalNullifier The external nullifier
   */
  modifier isValidSignalAndProof(
    bytes memory _signal,
    uint256[8] memory _proof,
    uint256 _root,
    uint256 _nullifiersHash,
    uint232 _externalNullifier
  ) {
    // Check whether each element in _proof is a valid field element. Even
    // if verifier.sol does this check too, it is good to do so here for
    // the sake of good protocol design.
    require(areAllValidFieldElements(_proof), "Semaphore: invalid field element(s) in proof");

    // Check whether the nullifier hash has been seen
    require(nullifierHashHistory[_nullifiersHash] == false, "Semaphore: nullifier already seen");

    // Check whether the nullifier hash is active
    //require(isExternalNullifierActive(_externalNullifier), "Semaphore: external nullifier not found");

    // Check whether the given Merkle root has been seen previously
    //require(rootHistory[_root], "Semaphore: root not seen");

    uint256 signalHash = hashSignal(_signal);

    // Check whether _nullifiersHash is a valid field element.
    require(_nullifiersHash < SNARK_SCALAR_FIELD, "Semaphore: the nullifiers hash must be lt the snark scalar field");


    uint256[4] memory publicSignals = [_root, _nullifiersHash, signalHash, _externalNullifier];

    (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) = unpackProof(_proof);

    //require(verifyProof(a, b, c, publicSignals), "Semaphore: invalid proof");

    nullifierHashHistory[_nullifiersHash] = true;

    // Note that we don't need to check if signalHash is less than
    // SNARK_SCALAR_FIELD because it always holds true due to the
    // definition of hashSignal()

    _;
  }

  /*
   * Broadcasts the signal.
   * @param _signal The signal to broadcast
   * @param _proof The proof elements.
   * @param _root The root of the Merkle tree (the 1st public signal)
   * @param _nullifiersHash The nullifiers hash (the 2nd public signal)
   * @param _externalNullifier The nullifiers hash (the 4th public signal)
   */


  function broadcastSignal(
    bytes memory _signal,
    uint256[8] memory _proof,
    uint256 _root,
    uint256 _nullifiersHash,
    uint232 _externalNullifier,
    uint256 proposalId, 
    string calldata reason
  ) public onlyOwnerIfPermissioned isValidSignalAndProof(_signal, _proof, _root, _nullifiersHash, _externalNullifier){
    
    //cast vote in the logic contract

    castVote(proposalId, 0, reason);

  }

  /*
   * A private helper function which adds an external nullifier.
   * @param _externalNullifier The external nullifier to add.
   * @param _isFirst Whether _externalNullifier is the first external
   * nullifier. Only the constructor should set _isFirst to true when it
   * calls addEn().
   */
  function addEn(uint232 _externalNullifier, bool isFirst) private {
    if (isFirst) {
      firstExternalNullifier = _externalNullifier;
    } else {
      // The external nullifier must not have already been set
      require(
        externalNullifierLinkedList[_externalNullifier].exists == false,
        "Semaphore: external nullifier already set"
      );

      // Connect the previously added external nullifier node to this one
      externalNullifierLinkedList[lastExternalNullifier].next = _externalNullifier;
    }

    // Add a new external nullifier
    externalNullifierLinkedList[_externalNullifier].next = 0;
    externalNullifierLinkedList[_externalNullifier].isActive = true;
    externalNullifierLinkedList[_externalNullifier].exists = true;

    // Set the last external nullifier to this one
    lastExternalNullifier = _externalNullifier;

    numExternalNullifiers++;

    emit ExternalNullifierAdd(_externalNullifier);
  }

  /*
   * Adds an external nullifier to the contract. This external nullifier is
   * active once it is added. Only the owner can do this.
   * @param _externalNullifier The new external nullifier to set.
   */
  function addExternalNullifier(uint232 _externalNullifier) public onlyOwner {
    addEn(_externalNullifier, false);
  }

  /*
   * Deactivate an external nullifier. The external nullifier must already be
   * active for this function to work. Only the owner can do this.
   * @param _externalNullifier The new external nullifier to deactivate.
   */
  function deactivateExternalNullifier(uint232 _externalNullifier) public onlyOwner {
    // The external nullifier must already exist
    require(externalNullifierLinkedList[_externalNullifier].exists, "Semaphore: external nullifier not found");

    // The external nullifier must already be active
    require(
      externalNullifierLinkedList[_externalNullifier].isActive == true,
      "Semaphore: external nullifier already deactivated"
    );

    // Deactivate the external nullifier. Note that we don't change the
    // value of nextEn.
    externalNullifierLinkedList[_externalNullifier].isActive = false;

    emit ExternalNullifierChangeStatus(_externalNullifier, false);
  }

  /*
   * Reactivate an external nullifier. The external nullifier must already be
   * inactive for this function to work. Only the owner can do this.
   * @param _externalNullifier The new external nullifier to reactivate.
   */
  function reactivateExternalNullifier(uint232 _externalNullifier) public onlyOwner {
    // The external nullifier must already exist
    require(externalNullifierLinkedList[_externalNullifier].exists, "Semaphore: external nullifier not found");

    // The external nullifier must already have been deactivated
    require(
      externalNullifierLinkedList[_externalNullifier].isActive == false,
      "Semaphore: external nullifier is already active"
    );

    // Reactivate the external nullifier
    externalNullifierLinkedList[_externalNullifier].isActive = true;

    emit ExternalNullifierChangeStatus(_externalNullifier, true);
  }

  /*
   * Returns true if and only if the specified external nullifier is active
   * @param _externalNullifier The specified external nullifier.
   */
  function isExternalNullifierActive(uint232 _externalNullifier) public view returns (bool) {
    return externalNullifierLinkedList[_externalNullifier].isActive;
  }

  /*
   * Returns the next external nullifier after the specified external
   * nullifier in the linked list.
   * @param _externalNullifier The specified external nullifier.
   */
  function getNextExternalNullifier(uint232 _externalNullifier) public view returns (uint232) {
    require(externalNullifierLinkedList[_externalNullifier].exists, "Semaphore: no such external nullifier");

    uint232 n = externalNullifierLinkedList[_externalNullifier].next;

    require(
      numExternalNullifiers > 1 && externalNullifierLinkedList[n].exists,
      "Semaphore: no external nullifier exists after the specified one"
    );

    return n;
  }

  /*
   * Returns the number of inserted identity commitments.
   */
  function getNumIdentityCommitments() public view returns (uint256) {
    return nextLeafIndex;
  }

  /*
   * Sets the `isBroadcastPermissioned` storage variable, which determines
   * whether broadcastSignal can or cannot be called by only the contract
   * owner.
   * @param _newPermission True if the broadcastSignal can only be called by
   *                       the contract owner; and False otherwise.
   */
  function setPermissioning(bool _newPermission) public onlyOwner {
    isBroadcastPermissioned = _newPermission;

    emit PermissionSet(_newPermission);
  }

  function sender () public returns(address) {
    return msg.sender;
  }

  //sets the address of the Logic contract as the Proxy
  function setLogicAddyasProxy(address _logic) public payable {
    logicAddr = _logic;
  }

  function castVote(uint256 proposalId, uint8 support, string calldata reason) public {
    INounsAnonDAOLogicV1(logicAddr).castAnonVote(proposalId, support, reason);
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
pragma solidity ^0.8.4;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
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
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
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
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
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
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
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
contract Verifier {
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
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12599857379517512478445603412764121041984228075771497593287716170335433683702,
             7912208710313447447762395792098481825752520616755888860068004689933335666613],
            [11502426145685875357967720478366491326865907869902181704031346886834786027007,
             21679208693936337484429571887537508926366191105267550375038502782696042114705]
        );
        vk.IC = new Pairing.G1Point[](5);
        
        vk.IC[0] = Pairing.G1Point( 
            6798612449082656503815755355587081131823424053550567824095086325098814807267,
            10922387391090562175173254146651022038748851042571194621887994576421226148206
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            12662614337597259281681831466109801408573248760290949498411141006913735295376,
            20929413653076789987932455531345192901026753516438231308434671945057476778152
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            1298894759089832047498053007614215899852232252455754937108080194675118357631,
            20788998468704186699041744235303941297782916066437539199331730359065352217561
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            10329000392374585496324061098155540910794003511313787564886710517788746462398,
            1464484335118668586046523366905616109678209964305155855087847705644192267715
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            7959437798659104818412550163551707381765094675454666950876377303101377901291,
            19443358725838409736528146998779620286845267826809766750893720257233238916012
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[4] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import {SnarkConstants} from "./SnarkConstants.sol";
import {Hasher} from "./Hasher.sol";
import {Ownable} from "./Ownable.sol";

/*
 * An incremental Merkle tree which supports up to 5 leaves per node.
 */
contract IncrementalQuinTree is Ownable, Hasher {
  // The maximum tree depth
  uint8 internal constant MAX_DEPTH = 32;

  // The number of leaves per node
  uint8 internal constant LEAVES_PER_NODE = 5;

  // The tree depth
  uint8 internal treeLevels;

  // The number of inserted leaves
  uint256 internal nextLeafIndex = 0;

  // The Merkle root
  uint256 public root;

  // The zero value per level
  mapping(uint256 => uint256) internal zeros;

  // Allows you to compute the path to the element (but it's not the path to
  // the elements). Caching these values is essential to efficient appends.
  mapping(uint256 => mapping(uint256 => uint256)) internal filledSubtrees;

  // Whether the contract has already seen a particular Merkle tree root
  mapping(uint256 => bool) public rootHistory;

  event LeafInsertion(uint256 indexed leaf, uint256 indexed leafIndex);

  /*
   * Stores the Merkle root and intermediate values (the Merkle path to the
   * the first leaf) assuming that all leaves are set to _zeroValue.
   * @param _treeLevels The number of levels of the tree
   * @param _zeroValue The value to set for every leaf. Ideally, this should
   *                   be a nothing-up-my-sleeve value, so that nobody can
   *                   say that the deployer knows the preimage of an empty
   *                   leaf.
   */
  constructor(uint8 _treeLevels, uint256 _zeroValue) {
    // Limit the Merkle tree to MAX_DEPTH levels
    require(_treeLevels > 0 && _treeLevels <= MAX_DEPTH, "IncrementalQuinTree: _treeLevels must be between 0 and 33");

    /*
           To initialise the Merkle tree, we need to calculate the Merkle root
           assuming that each leaf is the zero value.
           `zeros` and `filledSubtrees` will come in handy later when we do
           inserts or updates. e.g when we insert a value in index 1, we will
           need to look up values from those arrays to recalculate the Merkle
           root.
         */
    treeLevels = _treeLevels;

    uint256 currentZero = _zeroValue;

    // hash5 requires a uint256[] memory input, so we have to use temp
    uint256[LEAVES_PER_NODE] memory temp;

    for (uint8 i = 0; i < _treeLevels; i++) {
      for (uint8 j = 0; j < LEAVES_PER_NODE; j++) {
        temp[j] = currentZero;
      }

      zeros[i] = currentZero;
      currentZero = hash5(temp);
    }

    root = currentZero;
  }

  /*
   * Inserts a leaf into the Merkle tree and updates its root.
   * Also updates the cached values which the contract requires for efficient
   * insertions.
   * @param _leaf The value to insert. It must be less than the snark scalar
   *              field or this function will throw.
   * @return The leaf index.
   */
  function insertLeaf(uint256 _leaf) public onlyOwner returns (uint256) {
    require(_leaf < SNARK_SCALAR_FIELD, "IncrementalQuinTree: insertLeaf argument must be < SNARK_SCALAR_FIELD");

    // Ensure that the tree is not full
    require(nextLeafIndex < uint256(LEAVES_PER_NODE)**uint256(treeLevels), "IncrementalQuinTree: tree is full");

    uint256 currentIndex = nextLeafIndex;

    uint256 currentLevelHash = _leaf;

    // hash5 requires a uint256[] memory input, so we have to use temp
    uint256[LEAVES_PER_NODE] memory temp;

    // The leaf's relative position within its node
    uint256 m = currentIndex % LEAVES_PER_NODE;

    for (uint8 i = 0; i < treeLevels; i++) {
      // If the leaf is at relative index 0, zero out the level in
      // filledSubtrees
      if (m == 0) {
        for (uint8 j = 1; j < LEAVES_PER_NODE; j++) {
          filledSubtrees[i][j] = zeros[i];
        }
      }

      // Set the leaf in filledSubtrees
      filledSubtrees[i][m] = currentLevelHash;

      // Hash the level
      for (uint8 j = 0; j < LEAVES_PER_NODE; j++) {
        temp[j] = filledSubtrees[i][j];
      }
      currentLevelHash = hash5(temp);

      currentIndex /= LEAVES_PER_NODE;
      m = currentIndex % LEAVES_PER_NODE;
    }

    root = currentLevelHash;
    rootHistory[root] = true;

    uint256 n = nextLeafIndex;
    nextLeafIndex += 1;

    emit LeafInsertion(_leaf, n);

    return currentIndex;
  }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * > Note: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SnarkConstants {
  // The scalar field
  uint256 internal constant SNARK_SCALAR_FIELD =
    21888242871839275222246405745257275088548364400416034343698204186575808495617;
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import {PoseidonT3, PoseidonT6} from "./Poseidon.sol";
import {SnarkConstants} from "./SnarkConstants.sol";

/*
 * Poseidon hash functions for 2, 5, and 11 input elements.
 */
contract Hasher is SnarkConstants {
  function hash5(uint256[5] memory array) public pure returns (uint256) {
    return PoseidonT6.poseidon(array);
  }

  function hash11(uint256[] memory array) public pure returns (uint256) {
    uint256[] memory input11 = new uint256[](11);
    uint256[5] memory first5;
    uint256[5] memory second5;
    for (uint256 i = 0; i < array.length; i++) {
      input11[i] = array[i];
    }

    for (uint256 i = array.length; i < 11; i++) {
      input11[i] = 0;
    }

    for (uint256 i = 0; i < 5; i++) {
      first5[i] = input11[i];
      second5[i] = input11[i + 5];
    }

    uint256[2] memory first2;
    first2[0] = PoseidonT6.poseidon(first5);
    first2[1] = PoseidonT6.poseidon(second5);
    uint256[2] memory second2;
    second2[0] = PoseidonT3.poseidon(first2);
    second2[1] = input11[10];
    return PoseidonT3.poseidon(second2);
  }

  function hashLeftRight(uint256 _left, uint256 _right) public pure returns (uint256) {
    uint256[2] memory input;
    input[0] = _left;
    input[1] = _right;
    return PoseidonT3.poseidon(input);
  }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

library PoseidonT3 {
  function poseidon(uint256[2] memory input) public pure returns (uint256) {}
}

library PoseidonT6 {
  function poseidon(uint256[5] memory input) public pure returns (uint256) {}
}