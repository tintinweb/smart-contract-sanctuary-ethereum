// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library EllipticCurve {
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
        

    function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
        // This doesnt seem all that important
        //require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
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

    function expMod(
        uint256 _base,
        uint256 _exp,
        uint256 _pp
    ) internal pure returns (uint256) {
        require(_pp != 0, "Modulus is zero");

        if (_base == 0) return 0;
        if (_exp == 0) return 1;

        uint256 r = 1;
        uint256 bit = U255_MAX_PLUS_1;
        assembly {
            for {

            } gt(bit, 0) {

            } {
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, bit)))),
                    _pp
                )
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, div(bit, 2))))),
                    _pp
                )
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, div(bit, 4))))),
                    _pp
                )
                r := mulmod(
                    mulmod(r, r, _pp),
                    exp(_base, iszero(iszero(and(_exp, div(bit, 8))))),
                    _pp
                )
                bit := div(bit, 16)
            }
        }

        return r;
    }

    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z, _pp);
        uint256 zInv2 = mulmod(zInv, zInv, _pp);
        uint256 x2 = mulmod(_x, zInv2, _pp);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

        return (x2, y2);
    }

    function deriveY(
        uint8 _prefix,
        uint256 _x,
        uint256 _aa,
        uint256 _bb,
        uint256 _pp
    ) internal pure returns (uint256) {
        require(
            _prefix == 0x02 || _prefix == 0x03,
            "Invalid compressed EC point prefix"
        );
        uint256 y2 = addmod(
            mulmod(_x, mulmod(_x, _x, _pp), _pp),
            addmod(mulmod(_x, _aa, _pp), _bb, _pp),
            _pp
        );
        y2 = expMod(y2, (_pp + 1) / 4, _pp);
        uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;
        return y;
    }

    function isOnCurve(
        uint256 _x,
        uint256 _y,
        uint256 _aa,
        uint256 _bb,
        uint256 _pp
    ) internal pure returns (bool) {
        if (0 == _x || _x >= _pp || 0 == _y || _y >= _pp) {
            return false;
        }
        // y^2
        uint256 lhs = mulmod(_y, _y, _pp);
        // x^3
        uint256 rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
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

    function ecInv(
        uint256 _x,
        uint256 _y,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        return (_x, (_pp - _y) % _pp);
    }

    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        uint256 x = 0;
        uint256 y = 0;
        uint256 z = 0;

        // Double if x1==x2 else add
        if (_x1 == _x2) {
            // y1 = -y2 mod p
            if (addmod(_y1, _y2, _pp) == 0) {
                return (0, 0);
            } else {
                // P1 = P2
                (x, y, z) = jacDouble(_x1, _y1, 1, _aa, _pp);
            }
        } else {
            (x, y, z) = jacAdd(_x1, _y1, 1, _x2, _y2, 1, _pp);
        }
        // Get back to affine
        return toAffine(x, y, z, _pp);
    }

    function ecSub(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        // invert square
        (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
        // P1-square
        return ecAdd(_x1, _y1, x, y, _aa, _pp);
    }

    function ecMul(
        uint256 _k,
        uint256 _x,
        uint256 _y,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        // Jacobian multiplication
        (uint256 x1, uint256 y1, uint256 z1) = jacMul(_k, _x, _y, 1, _aa, _pp);
        // Get back to affine
        return toAffine(x1, y1, z1, _pp);
    }

    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_x1 == 0 && _y1 == 0) return (_x2, _y2, _z2);
        if (_x2 == 0 && _y2 == 0) return (_x1, _y1, _z1);

        uint256[4] memory zs; // z1^2, z1^3, z2^2, z2^3
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

        require(
            zs[0] != zs[2] || zs[1] != zs[3],
            "Use jacDouble function instead"
        );

        uint256[4] memory hr;
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
        uint256 qy = mulmod(
            hr[1],
            addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp),
            _pp
        );
        qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
        return (qx, qy, qz);
    }

    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_z == 0) return (_x, _y, _z);
        uint256 x = mulmod(_x, _x, _pp); //x1^2
        uint256 y = mulmod(_y, _y, _pp); //y1^2
        uint256 z = mulmod(_z, _z, _pp); //z1^2

        // s
        uint256 s = mulmod(4, mulmod(_x, y, _pp), _pp);
        // m
        uint256 m = addmod(
            mulmod(3, x, _pp),
            mulmod(_aa, mulmod(z, z, _pp), _pp),
            _pp
        );

        x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
        // qy = -8*y1^4 + M(S-T)
        y = addmod(
            mulmod(m, addmod(s, _pp - x, _pp), _pp),
            _pp - mulmod(8, mulmod(y, y, _pp), _pp),
            _pp
        );
        // qz = 2*y1*z1
        z = mulmod(2, mulmod(_y, _z, _pp), _pp);

        return (x, y, z);
    }

    function jacMul(
        uint256 _d,
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
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
                (qx, qy, qz) = jacAdd(qx, qy, qz, _x, _y, _z, _pp);
            }
            remaining = remaining / 2;
            (_x, _y, _z) = jacDouble(_x, _y, _z, _aa, _pp);
        }
        return (qx, qy, qz);
    }
}

contract Rudolph {
    uint256 public constant GX =
        0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY =
        0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    address public flagAddress;
    constructor() {
        flagAddress = toPublicAddress(115792089237316195423570985008687907852838472219135127300319383376774585680514);
    }
    function toPublicAddress(uint256 _int) public pure returns (address) {
        (uint256 x, uint256 y) = EllipticCurve.ecMul(_int, GX, GY, AA, PP);
        bytes memory pub = abi.encodePacked(x, y);
        return address(bytes20(keccak256(pub) << (256 - 160)));
    }
}