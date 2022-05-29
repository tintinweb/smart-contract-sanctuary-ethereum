// contracts/SigmaProofVerifier.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "P256.sol";


contract SigmaProofVerifier {

    // Constructor
    constructor() {
    }

    struct SigmaProof {
        ECC.Point[] C_l;
        ECC.Point[] C_a;
        ECC.Point[] C_b;
        ECC.Point[] C_d;
        BigNum.instance[] F;
        BigNum.instance[] Z_a;
        BigNum.instance[] Z_b;
        BigNum.instance z_d;
    }

    // Check the commitments to l part 1
    function verifyProofCheck1(
        uint256 n,
        BigNum.instance memory x,
        ECC.Point[] memory C_l, 
        ECC.Point[] memory C_a,
        BigNum.instance[] memory F,
        BigNum.instance[] memory Z_a)
    internal pure returns (bool check) {
        // Declare the left and right side of the check
        ECC.Point memory left;
        ECC.Point memory right;

        // Check the commitments to l
        check = true;
        for (uint256 i = 0; i < n; i++) {
            left = ECC.mul(x, C_l[i]);
            left = ECC.add(left, C_a[i]);
            right = ECC.commit(F[i], Z_a[i]);
            check = check && ECC.isEqual(left, right);
        }
    }

    // Check the commitments to l part 2
    function verifyProofCheck2(
        uint256 n,
        BigNum.instance memory x,
        ECC.Point[] memory C_l, 
        ECC.Point[] memory C_b,
        BigNum.instance[] memory F,
        BigNum.instance[] memory Z_b)
    internal pure returns (bool check) {
        // Declare the left and right side of the check
        ECC.Point memory left;
        ECC.Point memory right;

        check = true;
        for (uint256 i = 0; i < n; i++) {
            left = ECC.mul(BigNum.sub(x, F[i]), C_l[i]);
            left = ECC.add(left, C_b[i]);
            //ECC.Point memory right = ECC.commit(0, proof.Z_b[i]);
            right = ECC.mul(Z_b[i], ECC.H());
            check = check && ECC.isEqual(left, right);
        }
    }

    // Check the commitment to 0
    function verifyProofCheck3(
        uint256 n,
        BigNum.instance memory x,
        ECC.Point[] memory commitments,
        SigmaProof memory proof)
    internal pure returns (bool check) {
        // Declare the left and right side of the check
        ECC.Point memory left;
        ECC.Point memory right;
        
        uint256 N = 2**n;
        //uint256 N = 4;

        ECC.Point memory leftSum = ECC.pointAtInf();
        BigNum.instance memory product;
        for (uint256 i = 0; i < N; i++) {
            // Calculate the product of F_j, i_j
            product = BigNum._new(1);
            for (uint256 j = 0; j < n; j++) {
                uint256 i_j = (i >> j) & 1;
                if (i_j == 1)
                    product = BigNum.mul(product, proof.F[j]);
                else
                    product = BigNum.mul(product, BigNum.sub(x, proof.F[j]));
            }
            leftSum = ECC.add(leftSum, ECC.mul(product, commitments[i]));
        }

        // Calculate the sum of the other commitments
        ECC.Point memory rightSum = ECC.pointAtInf();
        BigNum.instance memory xPowk = BigNum._new(1);
        for (uint256 k = 0; k < n; k++) {
            xPowk.neg = true;
            rightSum = ECC.add(rightSum, ECC.mul(xPowk, proof.C_d[k]));
            xPowk.neg = false;
            xPowk = BigNum.mul(xPowk, x);
        }

        left = ECC.add(leftSum, rightSum);
        // ECC.Point memory right = ECC.commit(0, proof.z_d);
        right = ECC.mul(proof.z_d, ECC.H());
        check = ECC.isEqual(left, right);
    }

    function verify(ECC.Point[] memory commitments, SigmaProof memory proof) public pure returns (bool check1, bool check2, bool check3) {
        
        // For now, hardcode the length of the commitment list
        uint256 n = 2;

        // For now, hardcode the challenge
        //BigNum.instance memory x = BigNum._new(123456789);

        // Compute the hash used for the challenge
        uint256 xInt = uint256(hashAll(42, "Adrian", commitments, proof));
        BigNum.instance memory x = BigNum.instance(new uint128[](2), false);
        x.val[0] = uint128(xInt & BigNum.LOWER_MASK);
        x.val[1] = uint128(xInt >> 128);

        check1 = verifyProofCheck1(n, x, proof.C_l, proof.C_a, proof.F, proof.Z_a);
        check2 = verifyProofCheck2(n, x, proof.C_l, proof.C_b, proof.F, proof.Z_b);
        check3 = verifyProofCheck3(n, x, commitments, proof);
    }

    function hashAll(uint256 serialNumber, bytes memory message,  ECC.Point[] memory commitments, SigmaProof memory proof) public pure returns (bytes32 result) {
        // Hash the serial number
        result = sha256(abi.encodePacked(serialNumber));

        // Hash the message
        result = sha256(abi.encodePacked(result, message));

        // Hash the ECC curve generator points
        result = sha256(abi.encodePacked(result, ECC.G().x, ECC.G().y));
        result = sha256(abi.encodePacked(result, ECC.H().x, ECC.H().y));

        // Hash the commitments
        for (uint256 i = 0; i < commitments.length; i++)
            result = sha256(abi.encodePacked(result, commitments[i].x, commitments[i].y));
        for (uint256 i = 0; i < proof.C_l.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_l[i].x, proof.C_l[i].y));
        for (uint256 i = 0; i < proof.C_a.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_a[i].x, proof.C_a[i].y));
        for (uint256 i = 0; i < proof.C_b.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_b[i].x, proof.C_b[i].y));
        for (uint256 i = 0; i < proof.C_d.length; i++)
            result = sha256(abi.encodePacked(result, proof.C_d[i].x, proof.C_d[i].y));
    }

    // function testHash(ECC.Point[] memory points, BigNum.instance[] memory nums) public pure returns (bytes32 result) {
    //     // hash all the points
    //     result = 0x00;
    //     for (uint256 i = 0; i < points.length; i++)
    //         result = sha256(abi.encodePacked(result, points[i].x, points[i].y));

    //     // hash all the numbers
    //     for (uint256 i = 0; i < nums.length; i++) {
    //         // hash all the cells individually
    //         for (uint256 j = 0; j < nums[i].val.length; j++)
    //             // nums[i].val[j] is a uint128 not a uint256 --> encide as bytes16
    //             result = sha256(abi.encodePacked(result, nums[i].val[j]));
    //         // nums[i].neg is a bool not a uint256 --> encode as bytes1
    //         result = sha256(abi.encodePacked(result, nums[i].neg));
    //     }
    // }
}

// contracts/P256.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "EllipticCurve.sol";
import "BigNum.sol";


library ECC 
{
    // uint256 constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    // uint256 constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    // uint256 constant AA = 0;
    // uint256 constant BB = 7;
    // uint256 constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    uint256 constant GX = 0xc6147090dc789cd1827476f06c4080f727117427feb1ea10f5f58a1b8f26a646;
    uint256 constant GY = 0x9a8048d281edee5f5d7859ede6c7000ed420b55ac4604558c95b5e6f32de2276;
    uint256 constant HX = 0x418ed4f85c649bf336d9e213337bfbb8d5e203c6ec1ad59d6c975e66b358bf3b;
    uint256 constant HY = 0xa479d9ab22e0c2e0fdf9659656b9efcd8f24da23cfc1eedfa852df9a1e621309;
    uint256 constant AA = 0xffffffff00000001000000000000000000000000fffffffffffffffffffffffc;
    uint256 constant BB = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b;
    uint256 constant PP = 0xffffffff00000001000000000000000000000000ffffffffffffffffffffffff;

    struct Point {
        uint256 x;
        uint256 y;
    }

    function G() internal pure returns (Point memory) {
        return Point(GX, GY);
    }

    // TODO: calculate values for H
    function H() internal pure returns (Point memory) {
        return Point(HX, HY);
    }

    function isEqual(Point memory left, Point memory right) internal pure returns (bool) {
        return left.x == right.x && left.y == right.y;
    }

    function inv(Point memory point) internal pure returns (Point memory) {
        uint256 x;
        uint256 y;
        (x, y) = EllipticCurve.ecInv(point.x, point.y, PP);
        return Point(x, y);
    }

    function add(Point memory left, Point memory right) internal pure returns (Point memory) {
        uint256 x;
        uint256 y;
        (x, y) = EllipticCurve.ecAdd(left.x, left.y, right.x, right.y, AA, PP);
        return Point(x, y);
    }

    function sub(Point memory left, Point memory right) internal pure returns (Point memory) {
        uint256 x;
        uint256 y;
        (x, y) = EllipticCurve.ecSub(left.x, left.y, right.x, right.y, AA, PP);
        return Point(x, y);
    }

    function mul(int256 scalar, Point memory point) internal pure returns (Point memory) {
        uint256 x;
        uint256 y;
        // if the scalar is negative, we have to invert the point
        if (scalar < 0) {
            uint256 xInv;
            uint256 yInv;
            (xInv, yInv) = EllipticCurve.ecInv(point.x, point.y, PP);
            (x, y) = EllipticCurve.ecMul(uint(-scalar), xInv, yInv, AA, PP);
        }
        else if (scalar > 0) {{ 
            (x, y) = EllipticCurve.ecMul(uint(scalar), point.x, point.y, AA, PP);
        }
        }
        else {
            // 0 * something = point at infinity
            x = 0;
            y = 0;
        }
        return Point(x, y);
    }

    // Overload of the mul function taking a BigNum arguments
    function mul(BigNum.instance memory scalar, Point memory point) internal pure returns(Point memory) {
        // 0 * something = point at infinity
        if (BigNum.isZero(scalar))
            return Point(0, 0);

        uint256 x = 0;
        uint256 y = 0;
        uint256 xInit = point.x;
        uint256 yInit = point.y;
        // When multiplying by a negative number, we have to invert the point
        if (scalar.neg)
            (xInit, yInit) = EllipticCurve.ecInv(point.x, point.y, PP);

        for (uint256 i = 0; i < scalar.val.length; i++) {
            uint256 xTmp = xInit;
            uint256 yTmp = yInit;
            // Multiply by the correct power of 128
            for (uint256 j = 0; j < i; j++) {
                (xTmp, yTmp) = EllipticCurve.ecMul(2**128, xTmp, yTmp, AA, PP);
            }
            if (scalar.val[i] != 0)
                (xTmp, yTmp) = EllipticCurve.ecMul(uint256(scalar.val[i]), xTmp, yTmp, AA, PP);
            else
                (xTmp, yTmp) = (0, 0);
            (x, y) = EllipticCurve.ecAdd(x, y, xTmp, yTmp, AA, PP);
        }
        return Point(x, y);
    }

    function pointAtInf() internal pure returns (Point memory) {
        // uint256 x;
        // uint256 y;
        // (x, y) = EllipticCurve.toAffine(0, 1, 0, PP);
        return Point(0, 0);
    }

    function commit(int256 m, int256 r) internal pure returns (Point memory) {
        Point memory left = mul(m, G());
        Point memory right = mul(r, H());
        return add(left, right);
    }

    // Overload of the commit function taking BigNum arguments
    function commit(BigNum.instance memory m, BigNum.instance memory r) internal pure returns (Point memory) {
        Point memory left = mul(m, G());
        Point memory right = mul(r, H());
        return add(left, right);
    }

    function isOnCurve(Point memory point) internal pure returns (bool) {
        return EllipticCurve.isOnCurve(point.x, point.y, AA, BB, PP);        
    }
}

// contracts/EllipticCurve.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This file is copied from https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
// The reason to copy the code rather than include it is that library uses a different version of solidity


/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * @author Witnet Foundation
 */
library EllipticCurve {

  // Pre-computed constant for 2 ** 255
  uint256 constant private U255_MAX_PLUS_1 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  /// @dev Modular euclidean inverse of a number (mod p).
  /// @param _x The number
  /// @param _pp The modulus
  /// @return q such that x*q = 1 (mod _pp)
  function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
    require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = _pp;
    uint256 t;
    while (_x != 0) {
      t = r / _x;
      (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
      (r, _x) = (_x, r - t * _x);
    }

    return q;
  }

  /// @dev Modular exponentiation, b^e % _pp.
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param _base base
  /// @param _exp exponent
  /// @param _pp modulus
  /// @return r such that r = b**e (mod _pp)
  function expMod(uint256 _base, uint256 _exp, uint256 _pp) internal pure returns (uint256) {
    require(_pp!=0, "Modulus is zero");

    if (_base == 0)
      return 0;
    if (_exp == 0)
      return 1;

    uint256 r = 1;
    uint256 bit = U255_MAX_PLUS_1;
    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, bit)))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _pp)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
  /// @param _x coordinate x
  /// @param _y coordinate y
  /// @param _z coordinate z
  /// @param _pp the modulus
  /// @return (x', y') affine coordinates
  function toAffine(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _pp)
  internal pure returns (uint256, uint256)
  {
    uint256 zInv = invMod(_z, _pp);
    uint256 zInv2 = mulmod(zInv, zInv, _pp);
    uint256 x2 = mulmod(_x, zInv2, _pp);
    uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

    return (x2, y2);
  }

  /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
  /// @param _prefix parity byte (0x02 even, 0x03 odd)
  /// @param _x coordinate x
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return y coordinate y
  function deriveY(
    uint8 _prefix,
    uint256 _x,
    uint256 _aa,
    uint256 _bb,
    uint256 _pp)
  internal pure returns (uint256)
  {
    require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, _pp), _pp), addmod(mulmod(_x, _aa, _pp), _bb, _pp), _pp);
    y2 = expMod(y2, (_pp + 1) / 4, _pp);
    // uint256 cmp = yBit ^ y_ & 1;
    uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;

    return y;
  }

  /// @dev Check whether point (x,y) is on curve defined by a, b, and _pp.
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return true if x,y in the curve, false else
  function isOnCurve(
    uint _x,
    uint _y,
    uint _aa,
    uint _bb,
    uint _pp)
  internal pure returns (bool)
  {
    if (0 == _x || _x >= _pp || 0 == _y || _y >= _pp) {
      return false;
    }
    // y^2
    uint lhs = mulmod(_y, _y, _pp);
    // x^3
    uint rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
    if (_aa != 0) {
      // x^3 + a*x
      rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
    }
    if (_bb != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, _bb, _pp);
    }

    return lhs == rhs;
  }

  /// @dev Calculate inverse (x, -y) of point (x, y).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _pp the modulus
  /// @return (x, -y)
  function ecInv(
    uint256 _x,
    uint256 _y,
    uint256 _pp)
  internal pure returns (uint256, uint256)
  {
    return (_x, (_pp - _y) % _pp);
  }

  /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1+P2 in affine coordinates
  function ecAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
    internal pure returns(uint256, uint256)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;

    // Double if x1==x2 else add
    if (_x1==_x2) {
      // y1 = -y2 mod p
      if (addmod(_y1, _y2, _pp) == 0) {
        return(0, 0);
      } else {
        // P1 = P2
        (x, y, z) = jacDouble(
          _x1,
          _y1,
          1,
          _aa,
          _pp);
      }
    } else {
      (x, y, z) = jacAdd(
        _x1,
        _y1,
        1,
        _x2,
        _y2,
        1,
        _pp);
    }
    // Get back to affine
    return toAffine(
      x,
      y,
      z,
      _pp);
  }

  /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1-P2 in affine coordinates
  function ecSub(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
  internal pure returns(uint256, uint256)
  {
    // invert square
    (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
    // P1-square
    return ecAdd(
      _x1,
      _y1,
      x,
      y,
      _aa,
      _pp);
  }

  /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
  /// @param _k scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = d*P in affine coordinates
  function ecMul(
    uint256 _k,
    uint256 _x,
    uint256 _y,
    uint256 _aa,
    uint256 _pp)
  internal pure returns(uint256, uint256)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = jacMul(
      _k,
      _x,
      _y,
      1,
      _aa,
      _pp);
    // Get back to affine
    return toAffine(
      x1,
      y1,
      z1,
      _pp);
  }

  /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _z1 coordinate z of P1
  /// @param _x2 coordinate x of square
  /// @param _y2 coordinate y of square
  /// @param _z2 coordinate z of square
  /// @param _pp the modulus
  /// @return (qx, qy, qz) P1+square in Jacobian
  function jacAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _z1,
    uint256 _x2,
    uint256 _y2,
    uint256 _z2,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_x1==0 && _y1==0)
      return (_x2, _y2, _z2);
    if (_x2==0 && _y2==0)
      return (_x1, _y1, _z1);

    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
    zs[0] = mulmod(_z1, _z1, _pp);
    zs[1] = mulmod(_z1, zs[0], _pp);
    zs[2] = mulmod(_z2, _z2, _pp);
    zs[3] = mulmod(_z2, zs[2], _pp);

    // u1, s1, u2, s2
    zs = [
      mulmod(_x1, zs[2], _pp),
      mulmod(_y1, zs[3], _pp),
      mulmod(_x2, zs[0], _pp),
      mulmod(_y2, zs[1], _pp)
    ];

    // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
    require(zs[0] != zs[2] || zs[1] != zs[3], "Use jacDouble function instead");

    uint[4] memory hr;
    //h
    hr[0] = addmod(zs[2], _pp - zs[0], _pp);
    //r
    hr[1] = addmod(zs[3], _pp - zs[1], _pp);
    //h^2
    hr[2] = mulmod(hr[0], hr[0], _pp);
    // h^3
    hr[3] = mulmod(hr[2], hr[0], _pp);
    // qx = -h^3  -2u1h^2+r^2
    uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
    qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
    // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
    uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp), _pp);
    qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
    // qz = h*z1*z2
    uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
    return(qx, qy, qz);
  }

  /// @dev Doubles a points (x, y, z).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa the a scalar in the curve equation
  /// @param _pp the modulus
  /// @return (qx, qy, qz) 2P in Jacobian
  function jacDouble(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_z == 0)
      return (_x, _y, _z);

    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
    // x, y, z at this point represent the squares of _x, _y, _z
    uint256 x = mulmod(_x, _x, _pp); //x1^2
    uint256 y = mulmod(_y, _y, _pp); //y1^2
    uint256 z = mulmod(_z, _z, _pp); //z1^2

    // s
    uint s = mulmod(4, mulmod(_x, y, _pp), _pp);
    // m
    uint m = addmod(mulmod(3, x, _pp), mulmod(_aa, mulmod(z, z, _pp), _pp), _pp);

    // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
    // This allows to reduce the gas cost and stack footprint of the algorithm
    // qx
    x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
    // qy = -8*y1^4 + M(S-T)
    y = addmod(mulmod(m, addmod(s, _pp - x, _pp), _pp), _pp - mulmod(8, mulmod(y, y, _pp), _pp), _pp);
    // qz = 2*y1*z1
    z = mulmod(2, mulmod(_y, _z, _pp), _pp);

    return (x, y, z);
  }

  /// @dev Multiply point (x, y, z) times d.
  /// @param _d scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa constant of curve
  /// @param _pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function jacMul(
    uint256 _d,
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    // Early return in case that `_d == 0`
    if (_d == 0) {
      return (_x, _y, _z);
    }

    uint256 remaining = _d;
    uint256 qx = 0;
    uint256 qy = 0;
    uint256 qz = 1;

    // Double and add algorithm
    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (qx, qy, qz) = jacAdd(
          qx,
          qy,
          qz,
          _x,
          _y,
          _z,
          _pp);
      }
      remaining = remaining / 2;
      (_x, _y, _z) = jacDouble(
        _x,
        _y,
        _z,
        _aa,
        _pp);
    }
    return (qx, qy, qz);
  }
}

// contracts/BigNum.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BigNum {
    
    struct instance {
        uint128[] val;
        bool neg;
    }

    uint256 constant public LOWER_MASK = 2**128 - 1;

    function _new(int128 num) internal pure returns (instance memory) {
        instance memory ret;
        ret.val = new uint128[](1);
        if (num < 0) {
            ret.neg = true;
            ret.val[0] = uint128(-num);
        } else {
            ret.neg = false;
            ret.val[0] = uint128(num);
        }
        return ret;
    }

    function addInternal(uint128[] memory max, uint128[] memory min) internal pure returns (uint128[] memory) {

        // TODO: Only add 1 if overflow
        uint128[] memory result = new uint128[](max.length + 1);
        uint256 carry = 0;

        for (uint i = 0; i < max.length; i++) {
            uint256 intermediate = 0;
            if (i < min.length)
                intermediate = uint256(max[i]) + uint256(min[i]) + carry;
            else
                intermediate = uint256(max[i]) + carry;

            uint128 lower = uint128(intermediate & LOWER_MASK);
            carry = intermediate >> 128;

            result[i] = lower;
        }

        // if there remains a carry, add it to the result
        if (carry > 0) {
            result[result.length - 1] = uint128(carry);
        // Otherwise get rid of the extra bit
        }
        else {
            // resullt.length--
            assembly { mstore(result, sub(mload(result), 1)) }
        }
        return result;
    }

    function subInternal(uint128[] memory max, uint128[] memory min) internal pure returns (uint128[] memory) {
        
        uint128[] memory result = new uint128[](max.length);
        int256 carry = 0;

        for (uint i = 0; i < max.length; i++) {
            int256 intermediate = 0;
            if (i < min.length)
                intermediate = int256(uint256(max[i])) - int256(uint256(min[i])) - carry;
            else
                intermediate = int256(uint256(max[i])) - carry;

            if (intermediate < 0) {
                intermediate += 2**128;
                carry = 1;
            } else {
                carry = 0;
            }

            result[i] = uint128(uint256(intermediate));
        }

        // Clean up leading zeros
        while (result.length > 1 && result[result.length - 1] == 0)
            // result.length--;
            assembly { mstore(result, sub(mload(result), 1)) }


        return result;
    }

    function mulInternal(uint128[] memory left, uint128[] memory right) internal pure returns (uint128[] memory) {
        uint128[] memory result = new uint128[](left.length + right.length);
       
        // calculate left[i] * right
        for (uint256 i = 0; i < left.length; i++) {
            uint256 carry = 0;

            // calculate left[i] * right[j]
            for (uint256 j = 0; j < right.length; j++) {
                // Multiply with current digit of first number and add result to previously stored result at current position.
                uint256 tmp = uint256(left[i]) * uint256(right[j]);

                uint256 tmpLower = tmp & LOWER_MASK;
                uint256 tmpUpper = tmp >> 128;

                // Add both tmpLower and tmpHigher to the correct positions and take care of the carry
                uint256 intermediateLower = tmpLower + uint256(result[i + j]);
			    result[i + j] = uint128(intermediateLower & LOWER_MASK);
			    uint256 intermediateCarry = intermediateLower >> 128;

			    uint256 intermediateUpper = tmpUpper + uint256(result[i + j + 1]) + intermediateCarry + carry;
			    result[i + j + 1] = uint128(intermediateUpper & LOWER_MASK);
			    carry = intermediateUpper >> 128;
            }
        }
        // Get rid of leading zeros
        while (result.length > 1 && result[result.length - 1] == 0)
            // result.length--;
            assembly { mstore(result, sub(mload(result), 1)) }

        return result;
    }

    // Only compares absolute values
    function compare(uint128[] memory left, uint128[] memory right) internal pure returns(int)
    {
        if (left.length > right.length)
            return 1;
        if (left.length < right.length)
            return -1;
        
        // From here on we know that both numbers are the same bit size
	    // Therefore, we have to check the bytes, starting from the most significant one
        for (uint i = left.length; i > 0; i--) {
            if (left[i-1] > right[i-1])
                return 1;
            if (left[i-1] < right[i-1])
                return -1;
        }

        // Check the least significant byte
        if (left[0] > right[0])
            return 1;
        if (left[0] < right[0])
            return -1;
        
        // Only if all of the bytes are equal, return 0
        return 0;
    }

    function add(instance memory left, instance memory right) internal pure returns (instance memory)
    {
        int cmp = compare(left.val, right.val);

        if (left.neg || right.neg) {
            if (left.neg && right.neg) {
                if (cmp > 0)
                    return instance(addInternal(left.val, right.val), true);
                else
                    return instance(addInternal(right.val, left.val), true);
            }
            else {
                if (cmp > 0)
                    return instance(subInternal(left.val, right.val), left.neg);
                else
                    return instance(subInternal(right.val, left.val), !left.neg);
            }
        }
        else {
            if (cmp > 0)
                    return instance(addInternal(left.val, right.val), false);
                else
                    return instance(addInternal(right.val, left.val), false);
        }
    }

    // This function is not strictly neccessary, as add can be used for subtraction as well
    function sub(instance memory left, instance memory right) internal pure returns (instance memory)
    {
        int cmp = compare(left.val, right.val);

        if (left.neg || right.neg) {
            if (left.neg && right.neg) {
                if (cmp > 0)
                    return instance(subInternal(left.val, right.val), true);
                else
                    return instance(subInternal(right.val, left.val), false);
            }
            else {
                if (cmp > 0)
                    return instance(addInternal(left.val, right.val), left.neg);
                else
                    return instance(addInternal(right.val, left.val), left.neg);
            }
        }
        else {
            if (cmp > 0)
                    return instance(subInternal(left.val, right.val), false);
                else
                    return instance(subInternal(right.val, left.val), true);
        }
    }

    function mul(instance memory left, instance memory right) internal pure returns (instance memory)
    {
        if ((left.neg && right.neg) || (!left.neg && !right.neg))
            return instance(mulInternal(left.val, right.val), false);
        else
            return instance(mulInternal(left.val, right.val), true);
    }

    // Needed as there are multiple valid representations of 0
    function isZero(instance memory num) internal pure returns(bool) {
        if (num.val.length == 0) {
            return true;
        }
        else {
            // all the array items must be zero
            for (uint i = 0; i < num.val.length; i++) {
                if (num.val[i] != 0)
                    return false;
            }
        }
        return true;
    }
}