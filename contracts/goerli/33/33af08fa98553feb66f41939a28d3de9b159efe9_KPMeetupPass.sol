// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";
import "./MerkleTreeWithHistory.sol";
import "./Verifier.sol";

contract KPMeetupPass is ERC721, MerkleTreeWithHistory, Verifier {

  struct ProofInner {
    uint256[2] a;
    uint256[2][2] b;
    uint256[2] c;
  }

  uint256 private tokenId;

  // 活動
  mapping(uint256 => bool) public meetups;
  // 已報到移除 nullifier
  mapping(uint256 => bool) private nullifierHashAttended;

  event JoinMeetup(
    bytes32 indexed commitment,
    uint32 indexed leafIndex,
    uint256 indexed timestamp
  );

  event Attended(
    uint256 indexed nullifierHash
  );

  constructor(string memory _name, string memory _symbol, uint32 _treeLevels, address _hasher)
    ERC721(_name, _symbol)
    MerkleTreeWithHistory(_treeLevels, _hasher)
  {
    meetups[0] = true;
  }

  function mintPass() public {
    address minter = msg.sender;
    require(balanceOf(minter) == 0, "only mint one time");
    _mint(msg.sender, tokenId++);
  }

  function tokenURI(
    uint256
  ) public pure override returns (string memory) {
    return "KryptoCamp Meetup Pass";
  }

  function joinMeetup(bytes32 _commitment, uint256 _tokenId, uint256 _meetupId) external {
    require(meetups[_meetupId], "meetup not open");
    require(ownerOf(_tokenId) == msg.sender, "not token owner");
    uint32 insertIndex = _insert(_commitment);

    emit JoinMeetup(_commitment, insertIndex, block.timestamp);
  }

  function memberAttend(
    ProofInner memory _proof,
    bytes32 _root,
    uint256 _tokenId,
    bytes32 _nullifierHash
  ) external {
    require(!nullifierHashAttended[uint256(_nullifierHash)], "already attended");

    nullifierHashAttended[uint256(_nullifierHash)] = true;

    require(verifyProof(
      _proof.a, _proof.b, _proof.c,
      [
        uint256(_root),
        uint256(_nullifierHash),
        uint256(uint160(msg.sender)),
        uint256(_tokenId)
      ]), "Invalid attend proof"
    );

    emit Attended(uint256(_nullifierHash));
  }

  function approve(address,uint256) public pure override { revert(); }
  function transferFrom(address,address,uint256) public pure override { revert(); }
  function _burn(uint256) internal pure override { revert(); }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Hasher {
  function poseidon(bytes32[2] calldata leftRight)
      external
      pure
      returns (bytes32);
}

contract MerkleTreeWithHistory {
  uint256 public constant FIELD_SIZE =
      21888242871839275222246405745257275088548364400416034343698204186575808495617;
  uint256 public constant ZERO_VALUE =
      21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

  Hasher public hasher;

  uint32 public immutable levels;

  // the following variables are made public for easier testing and debugging and
  // are not supposed to be accessed in regular code
  bytes32[] public filledSubtrees;
  bytes32[] public zeros;
  uint32 public currentRootIndex = 0;
  uint32 public nextIndex = 0;
  uint32 public constant ROOT_HISTORY_SIZE = 100;
  bytes32[ROOT_HISTORY_SIZE] public roots;

  constructor(uint32 _treeLevels, address _hasher) {
      require(_treeLevels > 0, "_treeLevels should be greater than zero");
      require(_treeLevels < 32, "_treeLevels should be less than 32");

      hasher = Hasher(_hasher);
      levels = _treeLevels;

      bytes32 currentZero = bytes32(ZERO_VALUE);
      zeros.push(currentZero);
      filledSubtrees.push(currentZero);

      for (uint32 i = 1; i < _treeLevels; i++) {
          currentZero = hashLeftRight(currentZero, currentZero);
          zeros.push(currentZero);
          filledSubtrees.push(currentZero);
      }

      roots[0] = hashLeftRight(currentZero, currentZero);
  }

  /**
  @dev Hash 2 tree leaves, returns MiMC(_left, _right)
*/
  function hashLeftRight(bytes32 _left, bytes32 _right)
      public
      view
      returns (bytes32)
  {
      require(
          uint256(_left) < FIELD_SIZE,
          "_left should be inside the field"
      );
      require(
          uint256(_right) < FIELD_SIZE,
          "_right should be inside the field"
      );
      bytes32[2] memory leftright = [_left, _right];
      return hasher.poseidon(leftright);
  }

  function _insert(bytes32 _leaf) internal returns (uint32 index) {
      uint32 currentIndex = nextIndex;
      require(
          currentIndex != uint32(2)**levels,
          "Merkle tree is full. No more leafs can be added"
      );
      nextIndex += 1;
      bytes32 currentLevelHash = _leaf;
      bytes32 left;
      bytes32 right;

      for (uint32 i = 0; i < levels; i++) {
          if (currentIndex % 2 == 0) {
              left = currentLevelHash;
              right = zeros[i];

              filledSubtrees[i] = currentLevelHash;
          } else {
              left = filledSubtrees[i];
              right = currentLevelHash;
          }

          currentLevelHash = hashLeftRight(left, right);

          currentIndex /= 2;
      }

      currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
      roots[currentRootIndex] = currentLevelHash;
      return nextIndex - 1;
  }

  /**
  @dev Whether the root is present in the root history
*/
  function isKnownRoot(bytes32 _root) public view returns (bool) {
      if (_root == 0) return false;

      uint32 i = currentRootIndex;
      do {
          if (_root == roots[i]) return true;
          if (i == 0) i = ROOT_HISTORY_SIZE;
          i--;
      } while (i != currentRootIndex);
      return false;
  }

  /**
  @dev Returns the last root
*/
  function getLastRoot() public view returns (bytes32) {
      return roots[currentRootIndex];
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
pragma solidity ^0.8.3;
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
            6352245544304808051499583774300187049663953467761500164652853246642486529116,
            4086784377164327043918391789455455953200632842915202865481829629196944671651
        );

        vk.beta2 = Pairing.G2Point(
            [19561648548934536074377819693066732262024312365434961575570226888842497144368,
             20532670398064844625811922562061275739231001369945722654299304482952588940571],
            [14097341713770753466776429017426996210477473921392243520651371495448596580450,
             20802411451151299174210951655285706104548537334183688666535160949976205529934]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [8742263407319352364178426315076587988838610736263541787035561826861706874093,
             15039401127068378004625602519834984559998957411635435686202456823224750518767],
            [12199557146299461423759295977418425375714157058398112079722323195814486003997,
             10399146333369491262584717566998195824735785170966961839004228968768679973503]
        );
        vk.IC = new Pairing.G1Point[](5);
        
        vk.IC[0] = Pairing.G1Point( 
            15597237114019626242787763674381131684525325578603974480206306730333494447513,
            12256338699667583613780461395466905919527039934847444348763520950093755126094
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            6797346616254648794874517057844896289545513724458303213533116163792738411986,
            2686289028558585696624501784001048800044636966408257571570220629553534223626
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            11786156592791676575333492103042495574723760230615673962754256770360546314216,
            18916442812858767157921924403501195787789568120816034801469301527130971948150
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            16263239072703511793111425452038045947984704716625183818971578413412346944821,
            588641065778974376670151888553329054666123659565277240257627454707255759868
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            10318205502163241836961485633275200680709283558479020103239547899577654436405,
            18772039553047212810350051039665912556401258976937159196671638518956811804328
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