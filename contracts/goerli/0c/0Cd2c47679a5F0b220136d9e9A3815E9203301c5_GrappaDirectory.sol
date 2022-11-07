// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Poseidon5} from './lib/Hash.sol';

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/SparseMerkleTreeWithHistory.sol";
import "./SendVerifier.sol";
import "./ReceiveVerifier.sol";
import "./interfaces/IGrappaDirectory.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract GrappaDirectory is IGrappaDirectory, Ownable, ERC2771Recipient {

  using SparseMerkleTreeWithHistory for SparseTreeWithHistoryData;

  mapping(address => bool) public grappaContracts;
  mapping(uint256 => UserData) public usersData;
  mapping(address => uint256) public walletUserId;
  mapping(address => bool) public blacklist;

  SparseTreeWithHistoryData public idTree;
  uint256 userInitialPrice;
  uint256 nextUserId;


  event IDUpdated(uint256 indexed key, uint256 value);


  constructor(
  
    address _trustedForwarder,
    uint256 _userInitialPrice,
    uint256 _idTreeDepth,
    uint8 _idTreeRootHistory
  ) Ownable()
   {
  
  
    SparseMerkleTreeWithHistory.init(idTree, _idTreeDepth, 0, _idTreeRootHistory);
    nextUserId = 1000;
    userInitialPrice = _userInitialPrice;

    _setTrustedForwarder(_trustedForwarder);
  }

  modifier onlyGrappaContracts() {
    require(grappaContracts[msg.sender] == true, 'Not authorized!');
    _;
  }
  function enroll(BasePoint calldata metaPublicKey, BasePoint calldata tokenPublicKey, BasePoint calldata msgPublicKey ) external {
    address sender = _msgSender();

    require(blacklist[sender] == false, "user is blacklisted!");
    require(walletUserId[sender] == 0, "user already exists!");
    uint256 newUserId = nextUserId;
    walletUserId[sender] = newUserId;
    UserData memory userData = UserData(metaPublicKey, tokenPublicKey, msgPublicKey, userInitialPrice, block.number);
    usersData[newUserId] = userData;
    updateIDTree(newUserId, sender, metaPublicKey.x, tokenPublicKey.x, userInitialPrice, block.number);
    nextUserId++;
  }

  function updateKeys(BasePoint calldata metaPublicKey, BasePoint calldata tokenPublicKey, BasePoint calldata msgPublicKey) external {
    address sender = _msgSender();

    require(blacklist[sender] == false, "user is blacklisted!");
    require(walletUserId[sender] != 0, "user already exists!");
    uint256 userId = walletUserId[sender];
    UserData storage currentUserData = usersData[userId];
    updateIDTree(userId, sender, metaPublicKey.x, tokenPublicKey.x, currentUserData.price, block.number);
    currentUserData.lastUpdateBlock = block.number;
    currentUserData.metaPublicKey = metaPublicKey;
    currentUserData.tokenPublicKey = tokenPublicKey;
    currentUserData.msgPublicKey = msgPublicKey;
  }
  function updateIDTree( uint256 userId, address userAddress, uint256 metaPublicKeyX, uint256 tokenPublicKeyX, uint256 price, uint256 updateBlock) internal {
    uint256 _value = Poseidon5.poseidon([uint160(userAddress), metaPublicKeyX, tokenPublicKeyX, price, updateBlock]);
    idTree.update(userId, _value);
    emit IDUpdated(userId, _value);
  }

  function updateUserPrice(address _user, uint256 newPrice) external onlyGrappaContracts {
    uint256 userId = walletUserId[_user];
    UserData storage currentUserData = usersData[userId];
    currentUserData.lastUpdateBlock = block.number;
    currentUserData.price = newPrice;
    updateIDTree(userId, _user, currentUserData.metaPublicKey.x, currentUserData.tokenPublicKey.x, currentUserData.price, block.number);
  }
  

  function getIDTreeRoot() external view returns (uint256) {
    return idTree.getLastRoot();
  }
  function setUserInitialPrice(uint256 _userInitialPrice) external onlyOwner {
    userInitialPrice = _userInitialPrice;
  }

  function isKnownRoot(uint256 root) external view returns (bool) {
    return idTree.isKnownRoot(root);
  }


  /** @dev whether a note is already spent */

  function getUserIdAndData(address userAddress) external view returns (UserIdAndData memory) {
    uint256 userId = walletUserId[userAddress];
    return UserIdAndData(userId, usersData[userId]);
  }

  function setBlacklist(address _address, bool isBlacklisted ) external onlyOwner {
    blacklist[_address] = isBlacklisted;
  }

  /// @inheritdoc IERC2771Recipient
  function _msgSender() internal override(Context, ERC2771Recipient) virtual view returns (address ret) {
      if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
          // At this point we know that the sender is a trusted forwarder,
          // so we trust that the last bytes of msg.data are the verified sender address.
          // extract sender address from the end of msg.data
          assembly {
              ret := shr(96,calldataload(sub(calldatasize(),20)))
          }
      } else {
          ret = msg.sender;
      }
  }

  /// @inheritdoc IERC2771Recipient
  function _msgData() internal override(Context, ERC2771Recipient) virtual view returns (bytes calldata ret) {
      if (msg.data.length >= 20 && getTrustedForwarder() != address(0) && isTrustedForwarder(msg.sender)) {
          return msg.data[0:msg.data.length-20];
      } else {
          return msg.data;
      }
  }
  function setTrustedForwarder(address _forwarder) external onlyOwner {
    _setTrustedForwarder(_forwarder);
  }
  function setGrappaContract(address _moderator, bool allowed ) external onlyOwner {
    grappaContracts[_moderator] = allowed;
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
library SendVerifierPairing {
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
contract SendVerifier {
    using SendVerifierPairing for *;
    struct VerifyingKey {
        SendVerifierPairing.G1Point alfa1;
        SendVerifierPairing.G2Point beta2;
        SendVerifierPairing.G2Point gamma2;
        SendVerifierPairing.G2Point delta2;
        SendVerifierPairing.G1Point[] IC;
    }
    struct Proof {
        SendVerifierPairing.G1Point A;
        SendVerifierPairing.G2Point B;
        SendVerifierPairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = SendVerifierPairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = SendVerifierPairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = SendVerifierPairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = SendVerifierPairing.G2Point(
            [12599857379517512478445603412764121041984228075771497593287716170335433683702,
             7912208710313447447762395792098481825752520616755888860068004689933335666613],
            [11502426145685875357967720478366491326865907869902181704031346886834786027007,
             21679208693936337484429571887537508926366191105267550375038502782696042114705]
        );
        vk.IC = new SendVerifierPairing.G1Point[](14);
        
        vk.IC[0] = SendVerifierPairing.G1Point( 
            14625076645765386312065598230284459114164610219547175791686459626235118382516,
            18635954001659709486706461575472790056846554857567908583929438048179830700206
        );                                      
        
        vk.IC[1] = SendVerifierPairing.G1Point( 
            16242424369256705426327026153064682224930861305566994851139555826786894098588,
            10526260340457625685517121538434684372577274095109884851059074648911680664584
        );                                      
        
        vk.IC[2] = SendVerifierPairing.G1Point( 
            9886656609837559877060134871937548767441983662615703624139602599894955636884,
            16764227409553490503472127875358732027523139622956394942754572191782713939712
        );                                      
        
        vk.IC[3] = SendVerifierPairing.G1Point( 
            21806379734339263756114744908530525067965182590566710193406123263316457495291,
            5606693010521106483500078401859181894527197376157572795357110177770186194920
        );                                      
        
        vk.IC[4] = SendVerifierPairing.G1Point( 
            2749399997019033486723723888315102303390386651431406264752900707527282669307,
            17298212483772407354459295614010165708807241508054101251514776577124872806540
        );                                      
        
        vk.IC[5] = SendVerifierPairing.G1Point( 
            16120716911915097720542255164020224588513880052333409484846184338698441392861,
            3252458089718947609128479054975484718212675126646346318556462420821914474420
        );                                      
        
        vk.IC[6] = SendVerifierPairing.G1Point( 
            14005737207420807159221822264233985973460188570706943217390687886097674884474,
            14648908447116008485652260131050797209986739987755563534803764971205763534410
        );                                      
        
        vk.IC[7] = SendVerifierPairing.G1Point( 
            2460989668935105753372497516414159464956877379055253546652688457997448720203,
            6936387403369887050140908525506707325182966515966904385303559850714246950932
        );                                      
        
        vk.IC[8] = SendVerifierPairing.G1Point( 
            10526525605562348861764483696456993516236770057671681587035991799983165208458,
            13825315747848774956460552679947999655305306256059801610930650435421272746641
        );                                      
        
        vk.IC[9] = SendVerifierPairing.G1Point( 
            15558418877474642748237473682891461129849420507135609460415166290047782063722,
            5126723972347608358461986039366178368865158314057482027588243803675037265485
        );                                      
        
        vk.IC[10] = SendVerifierPairing.G1Point( 
            6028324135531590440395553242503777536702100466169804092138426733276564612075,
            12518137867211150820199383124855788404197437586050179648422636708516785939258
        );                                      
        
        vk.IC[11] = SendVerifierPairing.G1Point( 
            15260013347951399473269014155374331855719551071037382682229408914339678389046,
            6631943560418788254954700314464107935624519903651373468113423658144287448094
        );                                      
        
        vk.IC[12] = SendVerifierPairing.G1Point( 
            12259544732815172490486734963981533538222306282761354440703560234861742003882,
            7572180160923906119397262522332409330560623915032861810763863429561774740002
        );                                      
        
        vk.IC[13] = SendVerifierPairing.G1Point( 
            5267696244989055466804825265563405774290108573758255195894748025381342184579,
            5381352461652355387804003744321710183253232836604640458297356150861334515988
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        SendVerifierPairing.G1Point memory vk_x = SendVerifierPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = SendVerifierPairing.addition(vk_x, SendVerifierPairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = SendVerifierPairing.addition(vk_x, vk.IC[0]);
        if (!SendVerifierPairing.pairingProd4(
            SendVerifierPairing.negate(proof.A), proof.B,
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
            uint[13] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = SendVerifierPairing.G1Point(a[0], a[1]);
        proof.B = SendVerifierPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = SendVerifierPairing.G1Point(c[0], c[1]);
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
library ReceiveVerifierPairing {
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
contract ReceiveVerifier {
    using ReceiveVerifierPairing for *;
    struct VerifyingKey {
        ReceiveVerifierPairing.G1Point alfa1;
        ReceiveVerifierPairing.G2Point beta2;
        ReceiveVerifierPairing.G2Point gamma2;
        ReceiveVerifierPairing.G2Point delta2;
        ReceiveVerifierPairing.G1Point[] IC;
    }
    struct Proof {
        ReceiveVerifierPairing.G1Point A;
        ReceiveVerifierPairing.G2Point B;
        ReceiveVerifierPairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = ReceiveVerifierPairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = ReceiveVerifierPairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = ReceiveVerifierPairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = ReceiveVerifierPairing.G2Point(
            [12599857379517512478445603412764121041984228075771497593287716170335433683702,
             7912208710313447447762395792098481825752520616755888860068004689933335666613],
            [11502426145685875357967720478366491326865907869902181704031346886834786027007,
             21679208693936337484429571887537508926366191105267550375038502782696042114705]
        );
        vk.IC = new ReceiveVerifierPairing.G1Point[](6);
        
        vk.IC[0] = ReceiveVerifierPairing.G1Point( 
            21589039209533773514998716376204053874555894100467608915094214384989330665749,
            14437680012265551771718396794285651096842115823364556636153677378348501462644
        );                                      
        
        vk.IC[1] = ReceiveVerifierPairing.G1Point( 
            9884232863619544239536223970790514955895864562440343852568651962544042773502,
            7018563130944604046938766682647167155228528658295987503935103246805349965978
        );                                      
        
        vk.IC[2] = ReceiveVerifierPairing.G1Point( 
            3498202059321630103995880974202997353450370713680339653816132104430870064071,
            1578385481903801379030879118278378497147077495464603182852514929281727311530
        );                                      
        
        vk.IC[3] = ReceiveVerifierPairing.G1Point( 
            9372735123438586194057265501626897841184382520188593861440998420241685400652,
            18843628467151470141523025465754821184870309533755589486321375727452388553022
        );                                      
        
        vk.IC[4] = ReceiveVerifierPairing.G1Point( 
            14691434860388565986273408911466764228846814622773507664376905180553257122029,
            16744442126843625603077297786907904351977091649731351441720581062460720078818
        );                                      
        
        vk.IC[5] = ReceiveVerifierPairing.G1Point( 
            19846581869748499010856966706915715336129168933737484467061426322840124285401,
            17057419672854561758501180131211665902451138237547848477033763375944584420938
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        ReceiveVerifierPairing.G1Point memory vk_x = ReceiveVerifierPairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = ReceiveVerifierPairing.addition(vk_x, ReceiveVerifierPairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = ReceiveVerifierPairing.addition(vk_x, vk.IC[0]);
        if (!ReceiveVerifierPairing.pairingProd4(
            ReceiveVerifierPairing.negate(proof.A), proof.B,
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
            uint[5] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = ReceiveVerifierPairing.G1Point(a[0], a[1]);
        proof.B = ReceiveVerifierPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = ReceiveVerifierPairing.G1Point(c[0], c[1]);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Poseidon2 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library Poseidon3 {
    function poseidon(uint256[3] memory) public pure returns (uint256) {}
}

library Poseidon4 {
    function poseidon(uint256[4] memory) public pure returns (uint256) {}
}

library Poseidon5 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Poseidon2} from './Hash.sol';

struct SparseTreeWithHistoryData {
    uint256 depth;
    uint8 rootHistorySize;
    mapping(uint256 => uint256) roots;
    uint256 currentRootIndex;

    // depth to zero node
    mapping(uint256 => uint256) zeroes;
    // depth to index to leaf
    mapping(uint256 => mapping(uint256 => uint256)) leaves;
}

library SparseMerkleTreeWithHistory {
    uint8 internal constant MAX_DEPTH = 255;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    function init(
        SparseTreeWithHistoryData storage self,
        uint256 depth,
        uint256 _zero,
        uint8 _rootHistorySize
    ) public {
        require(_zero < SNARK_SCALAR_FIELD);
        require(depth > 0 && depth <= MAX_DEPTH);
        require(_rootHistorySize > 0 && _rootHistorySize <= 32);
        self.depth = depth;
        self.rootHistorySize = _rootHistorySize;
        self.zeroes[0] = _zero;
        for (uint8 i = 1; i < depth; i++) {
            self.zeroes[i] = Poseidon2.poseidon([self.zeroes[i-1], self.zeroes[i-1]]);

        }
        self.roots[0] = Poseidon2.poseidon([self.zeroes[depth-1], self.zeroes[depth-1]]);
    }

    function update(
        SparseTreeWithHistoryData storage self,
        uint256 index,
        uint256 leaf
    ) public {
        uint256 depth = self.depth;
        require(leaf < SNARK_SCALAR_FIELD, 'field too big');
        require(index < 2**depth, 'index too big');
        uint256 hash = leaf;
        uint256 lastLeftElement;
        uint256 lastRightElement;

        for (uint8 i = 0; i < depth; ) {
            self.leaves[i][index] = hash;
            if (index & 1 == 0) {
                uint256 siblingLeaf = self.leaves[i][index + 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                lastLeftElement = hash;
                lastRightElement = siblingLeaf;
            } else {
                uint256 siblingLeaf = self.leaves[i][index - 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                lastLeftElement = siblingLeaf;
                lastRightElement = hash;
            }

            hash = Poseidon2.poseidon([lastLeftElement, lastRightElement]);
            index >>= 1;

            unchecked {
                i++;
            }
        }
        uint256 newRootIndex = (self.currentRootIndex + 1) % self.rootHistorySize;
        self.currentRootIndex = newRootIndex;
        self.roots[newRootIndex] = hash;
    }
    function isKnownRoot(SparseTreeWithHistoryData storage self, uint256 _root) public view returns (bool) {
        if (_root == 0) {
            return false;
        }
        uint256 _currentRootIndex = self.currentRootIndex;
        uint256 i = _currentRootIndex;
        do {
            if (_root == self.roots[i]) {
                return true;
            }
            if (i == 0) {
                i = self.rootHistorySize;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    /**
        @dev Returns the last root
    */
    function getLastRoot(SparseTreeWithHistoryData storage self) public view returns (uint256) {
        return self.roots[self.currentRootIndex];
    }
        function generateProof(SparseTreeWithHistoryData storage self, uint256 index)
        public
        view
        returns (uint256[] memory)
    {
        require(index < 2**self.depth);
        uint256[] memory proof = new uint256[](self.depth);
        for (uint8 i = 0; i < self.depth; ) {
            if (index & 1 == 0) {
                uint256 siblingLeaf = self.leaves[i][index + 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                proof[i] = siblingLeaf;
            } else {
                uint256 siblingLeaf = self.leaves[i][index - 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                proof[i] = siblingLeaf;
            }
            index >>= 1;
            unchecked {
                i++;
            }
        }
        return proof;
    }

    function computeRoot(
        SparseTreeWithHistoryData storage self,
        uint256 index,
        uint256 leaf
    ) public view returns (uint256) {
        uint256 depth = self.depth;
        require(leaf < SNARK_SCALAR_FIELD);
        require(index < 2**depth);

        uint256 hash = leaf;
        uint256 lastLeftElement;
        uint256 lastRightElement;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                uint256 siblingLeaf = self.zeroes[i];
                lastLeftElement = hash;
                lastRightElement = siblingLeaf;
            } else {
                uint256 siblingLeaf = self.zeroes[i];
                lastLeftElement = siblingLeaf;
                lastRightElement = hash;
                }

            hash = Poseidon2.poseidon([lastLeftElement, lastRightElement]);
            index >>= 1;

            unchecked {
                i++;
      	}
    }

        return hash;
	}
    
}

pragma solidity ^0.8.0;

interface IGrappaDirectory {

    struct BasePoint {
        uint256 x;
        uint256 y;
    }
    struct UserData {
        BasePoint metaPublicKey;
        BasePoint tokenPublicKey;
        BasePoint msgPublicKey;
        uint256 price;
        uint256 lastUpdateBlock;

    }
    struct UserIdAndData {
        uint256 userId;
        UserData userData;
    }
    function enroll(BasePoint calldata metaPublicKey, BasePoint calldata tokenPublicKey, BasePoint calldata msgPublicKey ) external;

    function updateKeys(BasePoint calldata metaPublicKey, BasePoint calldata tokenPublicKey, BasePoint calldata msgPublicKey) external;
  
    function walletUserId(address userAddress) external view returns (uint256);

    function getIDTreeRoot() external view returns (uint256);

    function isKnownRoot(uint256 root) external view returns (bool);

    function blacklist(address _address) external view returns (bool);

    function getUserIdAndData(address userAddress) external view returns (UserIdAndData memory);

    function setBlacklist(address _address, bool isBlacklisted ) external;

    function updateUserPrice(address _user, uint256 newPrice) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

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
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
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