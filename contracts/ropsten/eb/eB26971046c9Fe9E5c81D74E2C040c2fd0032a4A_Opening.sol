// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {Params} from "Params.sol";

contract Opening {

    Params private params;
    address private owner;
    constructor(Params _params) {
        owner = msg.sender;
        params = _params;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function set_params(address addr) public onlyOwner {
        params = Params(addr);
    }

    mapping(address => bool) private openers;
    function addOpener(address opener_address) public onlyOwner {
        openers[opener_address] = true;
    }
    function removeOpener(address opener_address) public onlyOwner {
        openers[opener_address] = false;
    }
    modifier onlyOpeners {
        require(openers[msg.sender]);
        _;
    }
    
    event emitOpening(uint256 indexed id, uint256 opening_session_id, address opener_address, uint256[13][] openingshares);
    function SendOpeningInfo(string memory name, uint256 opening_session_id,  uint256[13][] memory openingshares) public onlyOpeners {
        uint256 id = params.getMapCredentials(name);
        require(id != 0, "No such AC.");
        emit emitOpening(id, opening_session_id, msg.sender, openingshares);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {G} from "G.sol";

contract Params {
    
    address private owner;  
    constructor() {    
        owner = msg.sender;
    }

    uint256 private credentialCount = 0;

    mapping(string => uint256) private mapCredentials;
    function setMapCredentials(string memory name) private {
        credentialCount += 1;
        mapCredentials[name] = credentialCount;  
    }

    function getMapCredentials(string memory name) public view returns (uint256) {
        return mapCredentials[name];
    }

    mapping(uint256 => G.G2Point) private alpha;
    mapping(uint256 => G.G1Point[]) private g1_beta;
    mapping(uint256 => G.G2Point[]) private beta;
    mapping(uint256 => G.G1Point[]) private hs;
    mapping(uint256 => uint256[]) private public_m_encoding;
    mapping(uint256 => G.G2Point[]) private opk;
    mapping(uint256 =>  mapping(string => uint256[])) private include_indexes;
    mapping(uint256 => string[][]) private ttp_combinations;

    uint256 private TTPCount = 0;
    mapping(string => uint256) private mapTTPs;
    function setMapTTPs(string memory name) private {
        TTPCount += 1;
        mapTTPs[name] = TTPCount;  
    }

    function getMapTTPs(string memory name) public view returns (uint256) {
        return mapTTPs[name];
    }

    mapping(uint256 => G.G1Point[]) private ttp_hs;
    mapping(uint256 => G.G1Point) private ttp_pk;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function set_params(string memory _name, G.G1Point[] memory _hs, G.G2Point memory _alpha, G.G1Point[] memory _g1_beta, G.G2Point[] memory _beta, G.G2Point[] memory _opk, string[][] memory _combinations, string[] memory _dependent_ttps, uint256[][] memory _include_indexes, uint256[] memory _public_m_encoding) public onlyOwner {
        require (getMapCredentials(_name) == 0, "AC name already exists.");
        setMapCredentials(_name);
        uint256 id = getMapCredentials(_name);
        for(uint256 i=0; i < _hs.length; i++) {
            hs[id].push(_hs[i]);
        }
        public_m_encoding[id] = _public_m_encoding;
        alpha[id] = _alpha;
        for(uint256 i=0; i < _beta.length; i++) {
            beta[id].push(_beta[i]);
        }
        for(uint256 i=0; i < _g1_beta.length; i++) {
            g1_beta[id].push(_g1_beta[i]);
        }
        for(uint256 i=0; i < _opk.length; i++) {
            opk[id].push(_opk[i]);
        }
        for(uint256 i=0; i < _include_indexes.length; i++) {
            include_indexes[id][_dependent_ttps[i]] = _include_indexes[i];
        }
        for(uint256 i=0; i < _combinations.length; i++) {
            ttp_combinations[id].push(_combinations[i]);
        }
        
    }

    function set_ttp_params(string memory _name, G.G1Point memory _ttp_pk, G.G1Point[] memory _hs) public onlyOwner {
        require (getMapTTPs(_name) == 0, "TTP name already exists.");
        setMapTTPs(_name);
        uint256 id = getMapTTPs(_name);
        for(uint256 i=0; i < _hs.length; i++) {
            ttp_hs[id].push(_hs[i]);
        }
        ttp_pk[id] = _ttp_pk;
    }
        
    function get_hs(string memory _name) public view returns (G.G1Point[] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return hs[id];
    }

    function get_public_m_encoding(string memory _name) public view returns (uint256[] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return public_m_encoding[id];
    }

    function get_alpha(string memory _name) public view returns (G.G2Point memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return alpha[id];
    }
    
    function get_beta(string memory _name) public view returns (G.G2Point[] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return beta[id];
    }

    function get_g1_beta(string memory _name) public view returns (G.G1Point[] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return g1_beta[id];
    }
    
    function get_opk(string memory _name) public view returns (G.G2Point[] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return opk[id];
    }

    function checkCombination(uint256 id, string[] memory combination) public view returns(bool) {
        string[][] memory all_combinations = ttp_combinations[id];
        for(uint256 i = 0; i < all_combinations.length; i++ ) {
            if(all_combinations[i].length == combination.length) {
                uint256 j = 0;
                for(j = 0; j < combination.length; j++ ) {
                    if (keccak256(bytes(all_combinations[i][j])) != keccak256(bytes(combination[j]))) {
                        break;
                    }
                }
                if ( j == combination.length) {
                    return true;
                }
            }
        }
        return false;
    }

    function get_include_indexes(string memory _name, string[] memory combination) public view returns(uint256[][] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        require(checkCombination(id, combination), "Such a combination is not possible.");
        uint256[][] memory _include_indexes = new uint256[][](combination.length);
        for(uint256 i = 0; i < combination.length; i++ ) {
            _include_indexes[i] = new uint256[](include_indexes[id][combination[i]].length); 
            _include_indexes[i] = include_indexes[id][combination[i]];
        }
        return _include_indexes;
    }

    function get_ttp_combinations(string memory _name) public view returns(string[][] memory) {
        uint256 id = getMapCredentials(_name);
        require(id != 0, "No such AC.");
        return ttp_combinations[id];
    }

    function get_ttpKeys(string memory _name) public view returns(G.G1Point memory) {
        uint256 id = getMapTTPs(_name);
        require(id != 0, "No such TTP.");
        return ttp_pk[id];
    }

    function get_ttp_params(string memory _name) public view returns(G.G1Point[] memory) {
        uint256 id = getMapTTPs(_name);
        require(id != 0, "No such TTP");
        return ttp_hs[id];
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {BN256G2} from "BN256G2.sol";

library G {

   	// p = p(u) = 36u^4 + 36u^3 + 24u^2 + 6u + 1
    uint256 internal constant FIELD_ORDER = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // Number of elements in the field (often called `q`)
    // n = n(u) = 36u^4 + 36u^3 + 18u^2 + 6u + 1
    uint256 internal constant GEN_ORDER = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    uint256 internal constant CURVE_B = 3;

    // a = (p+1) / 4
    uint256 internal constant CURVE_A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;

	struct G1Point {
		uint256 X;
		uint256 Y;
	}

	// Encoding of field elements is: X[0] * z + X[1]
	struct G2Point {
		uint256[2] X;
		uint256[2] Y;
	}

	// (P+1) / 4
	function A() pure internal returns (uint256) {
		return CURVE_A;
	}

	function P() pure internal returns (uint256) {
		return FIELD_ORDER;
	}

	function N() pure internal returns (uint256) {
		return GEN_ORDER;
	}

	/// @return the generator of G1
	function P1() pure internal returns (G1Point memory) {
		return G1Point(1, 2);
	}

	function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

	function do_ecdsa_verify(G1Point memory commit, G1Point memory pk, uint256[2] memory sign) view internal returns(bool){
	    bytes32 hash_digest = G1_to_binary256(commit);
	    uint256 s1 = _modInv(sign[1], N());
	    uint256 x1 = mulmod(uint256(hash_digest), s1, N());
	    uint256 x2 = mulmod(sign[0], s1, N());
	    G1Point memory tmp = g1mul(P1(), x1);
	    tmp = g1add(tmp, g1mul(pk, x2));
	    return tmp.X == sign[0];
  }

  function HashToPoint(uint256 s)
        internal view returns (G1Point memory)
    {
        uint256 beta = 0;
        uint256 y = 0;

        // XXX: Gen Order (n) or Field Order (p) ?
        uint256 x = s % GEN_ORDER;

        while( true ) {
            (beta, y) = FindYforX(x);

            // y^2 == beta
            if( beta == mulmod(y, y, FIELD_ORDER) ) {
                return G1Point(x, y);
            }

            x = addmod(x, 1, FIELD_ORDER);
        }
    }

    /**
    * Given X, find Y
    *
    *   where y = sqrt(x^3 + b)
    *
    * Returns: (x^3 + b), y
    */
    function FindYforX(uint256 x)
        internal view returns (uint256, uint256)
    {
        // beta = (x^3 + b) % p
        uint256 beta = addmod(mulmod(mulmod(x, x, FIELD_ORDER), x, FIELD_ORDER), CURVE_B, FIELD_ORDER);

        // y^2 = x^3 + b
        // this acts like: y = sqrt(beta)
        uint256 y = expMod(beta, CURVE_A, FIELD_ORDER);

        return (beta, y);
    }


    // a - b = c;
    function submod(uint a, uint b) internal pure returns (uint){
        uint a_nn;
        if(a>b) {
            a_nn = a;
        } else {
            a_nn = a+GEN_ORDER;
        }
        return addmod(a_nn - b, 0, GEN_ORDER);
    }


    function expMod(uint256 _base, uint256 _exponent, uint256 _modulus)
        internal view returns (uint256 retval)
    {
        bool success;
        uint256[1] memory output;
        uint[6] memory input;
        input[0] = 0x20;        // baseLen = new(big.Int).SetBytes(getData(input, 0, 32))
        input[1] = 0x20;        // expLen  = new(big.Int).SetBytes(getData(input, 32, 32))
        input[2] = 0x20;        // modLen  = new(big.Int).SetBytes(getData(input, 64, 32))
        input[3] = _base;
        input[4] = _exponent;
        input[5] = _modulus;
        assembly{
            success := staticcall(sub(gas(), 2000), 5, input, 0xc0, output, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
        return output[0];
    }


	/// @return the generator of G2
	function P2() pure internal returns (G2Point memory) {
		return G2Point(
			[11559732032986387107991004021392285783925812861821192530917403151452391805634,
			 10857046999023057135944570762232829481370756359578518086990519993285655852781],
			[4082367875863433681332203403145435568316851327593401208105741076214120093531,
			 8495653923123431417604973247489272438418190587263600148770280649306958101930]
		);
	}

	/// @return the negation of p, i.e. p.add(p.negate()) should be zero.
	function g1neg(G1Point memory p) pure internal returns (G1Point memory) {
		// The prime q in the base field F_q for G1
		uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
		if (p.X == 0 && p.Y == 0)
			return G1Point(0, 0);
		return G1Point(p.X, q - (p.Y % q));
	}

	function isinf(G1Point memory p) pure internal returns (bool) {
		if (p.X == 0 && p.Y == 0) {
			return true;
		}
		return false;
	}

	function g1add(G1Point memory p1, G1Point memory p2) view internal returns (G1Point memory r) {
		uint[4] memory input;
		input[0] = p1.X;
		input[1] = p1.Y;
		input[2] = p2.X;
		input[3] = p2.Y;
		bool success;
		assembly {
			success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
			// Use "invalid" to make gas estimation work
			switch success case 0 { invalid() }
		}
		require(success);
	}

	function g2add(G2Point memory p1, G2Point memory p2) view internal returns (G2Point memory r) {
		(r.X[1], r.X[0], r.Y[1], r.Y[0]) = BN256G2.ECTwistAdd(p1.X[1], p1.X[0], p1.Y[1], p1.Y[0], p2.X[1], p2.X[0], p2.Y[1], p2.Y[0]);
		return r;
	}

	function g1mul(G1Point memory p, uint s) view internal returns (G1Point memory r) {
		uint[3] memory input;
		input[0] = p.X;
		input[1] = p.Y;
		input[2] = s;
		bool success;
		assembly {
			success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
			// Use "invalid" to make gas estimation work
			switch success case 0 { invalid() }
		}
		require (success);
	}


	/// @return the result of computing the pairing check
	/// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
	/// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
	/// return true.
	function pairing(G1Point[] memory p1, G2Point[] memory p2) view internal returns (bool) {
		require(p1.length == p2.length);
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
		assembly {
			success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
			// Use "invalid" to make gas estimation work
			switch success case 0 { invalid() }
		}
		require(success);
		return out[0] != 0;
	}
	
	function G1_to_binary256(G1Point memory point) internal pure returns (bytes32) {
      bytes32 X = bytes32(point.X);
      bytes32 Y = bytes32(point.Y);
      bytes memory result = new bytes(64);
      uint i = 0;
      for (i=0; i< 32 ; i++) {
          result[i] = X[i];
      }
      for (i=0; i< 32 ; i++) {
          result[32 + i] = Y[i];
      }
     return sha256(result);
  }

  function G2_to_binary256(G2Point memory point) internal pure returns (bytes32) {
      
      bytes memory result = new bytes(128);
      bytes32 X = bytes32(point.X[1]);
      uint i = 0;
      for (i=0; i< 32 ; i++) {
          result[i] = X[i];
      }
      X = bytes32(point.X[0]);
      for (i=0; i< 32 ; i++) {
          result[32 + i] = X[i];
      }
      X = bytes32(point.Y[1]);
      for (i=0; i< 32 ; i++) {
          result[64 + i] = X[i];
      }
      X = bytes32(point.Y[0]);
      for (i=0; i< 32 ; i++) {
          result[96 + i] = X[i];
      }
      return sha256(result);
  }

  function EC_to_binary256(uint256 _X, uint256 _Y) internal pure returns(bytes32) {
      bytes32 X = bytes32(_X);
      bytes32 Y = bytes32(_Y);
      bytes memory result = new bytes(64);
      uint i = 0;
      for (i=0; i< 32 ; i++) {
          result[i] = X[i];
      }
      for (i=0; i< 32 ; i++) {
          result[32 + i] = Y[i];
      }
     return sha256(result);
  }
  
  function ec_sum(G2Point[] memory points) internal view returns(G2Point memory) {
  G2Point memory result = G2Point([uint256(0),0],[uint256(0),0]);
  uint i = 0;
  for(i=0; i<points.length; i++) 
  {
    result = g2add(result, points[i]);
  }
  return result;
}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


library BN256G2 {
    uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
    uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
    uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
    uint internal constant PTXX = 0;
    uint internal constant PTXY = 1;
    uint internal constant PTYX = 2;
    uint internal constant PTYY = 3;
    uint internal constant PTZX = 4;
    uint internal constant PTZY = 5;

    /**
     * @notice Add two twist points
     * @param pt1xx Coefficient 1 of x on point 1
     * @param pt1xy Coefficient 2 of x on point 1
     * @param pt1yx Coefficient 1 of y on point 1
     * @param pt1yy Coefficient 2 of y on point 1
     * @param pt2xx Coefficient 1 of x on point 2
     * @param pt2xy Coefficient 2 of x on point 2
     * @param pt2yx Coefficient 1 of y on point 2
     * @param pt2yy Coefficient 2 of y on point 2
     * @return (pt3xx, pt3xy, pt3yx, pt3yy)
     */
    function ECTwistAdd(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) public view returns (
        uint256, uint256,
        uint256, uint256
    ) {
        if (
            pt1xx == 0 && pt1xy == 0 &&
            pt1yx == 0 && pt1yy == 0
        ) {
            if (!(
                pt2xx == 0 && pt2xy == 0 &&
                pt2yx == 0 && pt2yy == 0
            )) {
                assert(_isOnCurve(
                    pt2xx, pt2xy,
                    pt2yx, pt2yy
                ));
            }
            return (
                pt2xx, pt2xy,
                pt2yx, pt2yy
            );
        } else if (
            pt2xx == 0 && pt2xy == 0 &&
            pt2yx == 0 && pt2yy == 0
        ) {
            assert(_isOnCurve(
                pt1xx, pt1xy,
                pt1yx, pt1yy
            ));
            return (
                pt1xx, pt1xy,
                pt1yx, pt1yy
            );
        }

        assert(_isOnCurve(
            pt1xx, pt1xy,
            pt1yx, pt1yy
        ));
        assert(_isOnCurve(
            pt2xx, pt2xy,
            pt2yx, pt2yy
        ));

        uint256[6] memory pt3 = _ECTwistAddJacobian(
            pt1xx, pt1xy,
            pt1yx, pt1yy,
            1,     0,
            pt2xx, pt2xy,
            pt2yx, pt2yy,
            1,     0
        );

        return _fromJacobian(
            pt3[PTXX], pt3[PTXY],
            pt3[PTYX], pt3[PTYY],
            pt3[PTZX], pt3[PTZY]
        );
    }

    /**
     * @notice Get the field modulus
     * @return The field modulus
     */

    function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256) {
        return addmod(a, n - b, n);
    }

    function _FQ2Mul(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256, uint256) {
        return (
            submod(mulmod(xx, yx, FIELD_MODULUS), mulmod(xy, yy, FIELD_MODULUS), FIELD_MODULUS),
            addmod(mulmod(xx, yy, FIELD_MODULUS), mulmod(xy, yx, FIELD_MODULUS), FIELD_MODULUS)
        );
    }

    function _FQ2Muc(
        uint256 xx, uint256 xy,
        uint256 c
    ) internal pure returns (uint256, uint256) {
        return (
            mulmod(xx, c, FIELD_MODULUS),
            mulmod(xy, c, FIELD_MODULUS)
        );
    }

    function _FQ2Sub(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (uint256 rx, uint256 ry) {
        return (
            submod(xx, yx, FIELD_MODULUS),
            submod(xy, yy, FIELD_MODULUS)
        );
    }

    function _FQ2Inv(uint256 x, uint256 y) internal view returns (uint256, uint256) {
        uint256 inv = _modInv(addmod(mulmod(y, y, FIELD_MODULUS), mulmod(x, x, FIELD_MODULUS), FIELD_MODULUS), FIELD_MODULUS);
        return (
            mulmod(x, inv, FIELD_MODULUS),
            FIELD_MODULUS - mulmod(y, inv, FIELD_MODULUS)
        );
    }

    function _isOnCurve(
        uint256 xx, uint256 xy,
        uint256 yx, uint256 yy
    ) internal pure returns (bool) {
        uint256 yyx;
        uint256 yyy;
        uint256 xxxx;
        uint256 xxxy;
        (yyx, yyy) = _FQ2Mul(yx, yy, yx, yy);
        (xxxx, xxxy) = _FQ2Mul(xx, xy, xx, xy);
        (xxxx, xxxy) = _FQ2Mul(xxxx, xxxy, xx, xy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, xxxx, xxxy);
        (yyx, yyy) = _FQ2Sub(yyx, yyy, TWISTBX, TWISTBY);
        return yyx == 0 && yyy == 0;
    }

    function _modInv(uint256 a, uint256 n) internal view returns (uint256 result) {
        bool success;
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), a)
            mstore(add(freemem,0x80), sub(n, 2))
            mstore(add(freemem,0xA0), n)
            success := staticcall(sub(gas(), 2000), 5, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
        require(success);
    }

    function _fromJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal view returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy
    ) {
        uint256 invzx;
        uint256 invzy;
        (invzx, invzy) = _FQ2Inv(pt1zx, pt1zy);
        (pt2xx, pt2xy) = _FQ2Mul(pt1xx, pt1xy, invzx, invzy);
        (pt2yx, pt2yy) = _FQ2Mul(pt1yx, pt1yy, invzx, invzy);
    }

    function _ECTwistAddJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy,
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy) internal pure returns (uint256[6] memory pt3) {
            if (pt1zx == 0 && pt1zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt2xx, pt2xy,
                    pt2yx, pt2yy,
                    pt2zx, pt2zy
                );
                return pt3;
            } else if (pt2zx == 0 && pt2zy == 0) {
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    pt1xx, pt1xy,
                    pt1yx, pt1yy,
                    pt1zx, pt1zy
                );
                return pt3;
            }

            (pt2yx,     pt2yy)     = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // U1 = y2 * z1
            (pt3[PTYX], pt3[PTYY]) = _FQ2Mul(pt1yx, pt1yy, pt2zx, pt2zy); // U2 = y1 * z2
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // V1 = x2 * z1
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1xx, pt1xy, pt2zx, pt2zy); // V2 = x1 * z2

            if (pt2xx == pt3[PTZX] && pt2xy == pt3[PTZY]) {
                if (pt2yx == pt3[PTYX] && pt2yy == pt3[PTYY]) {
                    (
                        pt3[PTXX], pt3[PTXY],
                        pt3[PTYX], pt3[PTYY],
                        pt3[PTZX], pt3[PTZY]
                    ) = _ECTwistDoubleJacobian(pt1xx, pt1xy, pt1yx, pt1yy, pt1zx, pt1zy);
                    return pt3;
                }
                (
                    pt3[PTXX], pt3[PTXY],
                    pt3[PTYX], pt3[PTYY],
                    pt3[PTZX], pt3[PTZY]
                ) = (
                    1, 0,
                    1, 0,
                    0, 0
                );
                return pt3;
            }

            (pt2zx,     pt2zy)     = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // W = z1 * z2
            (pt1xx,     pt1xy)     = _FQ2Sub(pt2yx, pt2yy, pt3[PTYX], pt3[PTYY]); // U = U1 - U2
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2xx, pt2xy, pt3[PTZX], pt3[PTZY]); // V = V1 - V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1yx, pt1yy, pt1yx,     pt1yy);     // V_squared = V * V
            (pt2yx,     pt2yy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTZX], pt3[PTZY]); // V_squared_times_V2 = V_squared * V2
            (pt1zx,     pt1zy)     = _FQ2Mul(pt1zx, pt1zy, pt1yx,     pt1yy);     // V_cubed = V * V_squared
            (pt3[PTZX], pt3[PTZY]) = _FQ2Mul(pt1zx, pt1zy, pt2zx,     pt2zy);     // newz = V_cubed * W
            (pt2xx,     pt2xy)     = _FQ2Mul(pt1xx, pt1xy, pt1xx,     pt1xy);     // U * U
            (pt2xx,     pt2xy)     = _FQ2Mul(pt2xx, pt2xy, pt2zx,     pt2zy);     // U * U * W
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt1zx,     pt1zy);     // U * U * W - V_cubed
            (pt2zx,     pt2zy)     = _FQ2Muc(pt2yx, pt2yy, 2);                    // 2 * V_squared_times_V2
            (pt2xx,     pt2xy)     = _FQ2Sub(pt2xx, pt2xy, pt2zx,     pt2zy);     // A = U * U * W - V_cubed - 2 * V_squared_times_V2
            (pt3[PTXX], pt3[PTXY]) = _FQ2Mul(pt1yx, pt1yy, pt2xx,     pt2xy);     // newx = V * A
            (pt1yx,     pt1yy)     = _FQ2Sub(pt2yx, pt2yy, pt2xx,     pt2xy);     // V_squared_times_V2 - A
            (pt1yx,     pt1yy)     = _FQ2Mul(pt1xx, pt1xy, pt1yx,     pt1yy);     // U * (V_squared_times_V2 - A)
            (pt1xx,     pt1xy)     = _FQ2Mul(pt1zx, pt1zy, pt3[PTYX], pt3[PTYY]); // V_cubed * U2
            (pt3[PTYX], pt3[PTYY]) = _FQ2Sub(pt1yx, pt1yy, pt1xx,     pt1xy);     // newy = U * (V_squared_times_V2 - A) - V_cubed * U2
    }

    function _ECTwistDoubleJacobian(
        uint256 pt1xx, uint256 pt1xy,
        uint256 pt1yx, uint256 pt1yy,
        uint256 pt1zx, uint256 pt1zy
    ) internal pure returns (
        uint256 pt2xx, uint256 pt2xy,
        uint256 pt2yx, uint256 pt2yy,
        uint256 pt2zx, uint256 pt2zy
    ) {
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 3);            // 3 * x
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1xx, pt1xy); // W = 3 * x * x
        (pt1zx, pt1zy) = _FQ2Mul(pt1yx, pt1yy, pt1zx, pt1zy); // S = y * z
        (pt2yx, pt2yy) = _FQ2Mul(pt1xx, pt1xy, pt1yx, pt1yy); // x * y
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt1zx, pt1zy); // B = x * y * S
        (pt1xx, pt1xy) = _FQ2Mul(pt2xx, pt2xy, pt2xx, pt2xy); // W * W
        (pt2zx, pt2zy) = _FQ2Muc(pt2yx, pt2yy, 8);            // 8 * B
        (pt1xx, pt1xy) = _FQ2Sub(pt1xx, pt1xy, pt2zx, pt2zy); // H = W * W - 8 * B
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt1zx, pt1zy); // S_squared = S * S
        (pt2yx, pt2yy) = _FQ2Muc(pt2yx, pt2yy, 4);            // 4 * B
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt1xx, pt1xy); // 4 * B - H
        (pt2yx, pt2yy) = _FQ2Mul(pt2yx, pt2yy, pt2xx, pt2xy); // W * (4 * B - H)
        (pt2xx, pt2xy) = _FQ2Muc(pt1yx, pt1yy, 8);            // 8 * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1yx, pt1yy); // 8 * y * y
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt2zx, pt2zy); // 8 * y * y * S_squared
        (pt2yx, pt2yy) = _FQ2Sub(pt2yx, pt2yy, pt2xx, pt2xy); // newy = W * (4 * B - H) - 8 * y * y * S_squared
        (pt2xx, pt2xy) = _FQ2Muc(pt1xx, pt1xy, 2);            // 2 * H
        (pt2xx, pt2xy) = _FQ2Mul(pt2xx, pt2xy, pt1zx, pt1zy); // newx = 2 * H * S
        (pt2zx, pt2zy) = _FQ2Mul(pt1zx, pt1zy, pt2zx, pt2zy); // S * S_squared
        (pt2zx, pt2zy) = _FQ2Muc(pt2zx, pt2zy, 8);            // newz = 8 * S * S_squared
    }
}