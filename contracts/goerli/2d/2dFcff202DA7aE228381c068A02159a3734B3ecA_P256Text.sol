//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ModExp {

    // address constant MODEXP_BUILTIN = 0x0000000000000000000000000000000000000005;

    function modexp(uint256 b, uint256 e, uint256 m) internal view returns(uint256 result) {
        assembly {
            let freemem := mload(0x40)
            mstore(freemem, 0x20)
            mstore(add(freemem,0x20), 0x20)
            mstore(add(freemem,0x40), 0x20)
            mstore(add(freemem,0x60), b)
            mstore(add(freemem,0x80), e)
            mstore(add(freemem,0xA0), m)
            result := staticcall(39240, 0x0000000000000000000000000000000000000005, freemem, 0xC0, freemem, 0x20)
            result := mload(freemem)
        }
    }

}


// Library for secp256r1, forked from https://github.com/tls-n/tlsnutils/blob/master/contracts/ECMath.sol
contract P256Text is ModExp, Ownable {

    //curve parameters secp256r1
    uint256 constant A  = 115792089210356248762697446949407573530086143415290314195533631308867097853948;
    uint256 constant B  = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
    uint256 constant GX = 48439561293906451759052585252797914202762949526041747995844080717082404635286;
    uint256 constant GY = 36134250956749795798585127919587881956611106672985015071877198253568414405109;
    uint256 constant P  = 115792089210356248762697446949407573530086143415290314195533631308867097853951;
    uint256 constant N  = 115792089210356248762697446949407573529996955224135760342422259061068512044369;
    uint256 constant H  = 1;


    function verify(uint256 qx, uint256 qy, uint256 e, uint256 r, uint256 s) public view returns(bool) {

        uint256 w = invmod(s, N);
        uint256 u1 = mulmod(e, w, N);
        uint256 u2 = mulmod(r, w, N);

        uint256[3] memory comb = calcPointShamir(u1, u2, qx, qy);

        uint256 zInv2 = modexp(comb[2], P - 3, P);
        uint256 x = mulmod(comb[0], zInv2, P); // JtoA(comb)[0];
        return r == x;
    }


    function check(uint256 e, uint8 v, uint256 r, uint256 s, uint256 p1, uint256 p2) public view returns(bool) {

        uint256 eInv = N - e;
        uint256 rInv = invmod(r, N);
        uint256 srInv = mulmod(rInv, s, N);
        uint256 eInvrInv = mulmod(rInv, eInv, N);

        uint256 ry = decompressPoint(r, v);
        uint256[3] memory q = calcPointShamir(eInvrInv, srInv, r, ry);

        uint256[2] memory res = JtoA(q);
        return res[0] == p1 && res[1] == p2;
    }

    address public last_successful_address1 = address(0x0);
    function test1(uint256 e, uint8 v, uint256 r, uint256 s, uint256 p1, uint256 p2) public returns(bool) {
        bool isok = check(e, v, r, s, p1, p2);
        if (isok) {
            last_successful_address1 = msg.sender;
        }
        return isok;
    }



    uint256 private p1_saved = 0x0;
    uint256 private p2_saved = 0x0;
    function set_saved_ps(uint256 _p1, uint256 _p2) public onlyOwner {
        p1_saved = _p1;
        p1_saved = _p2;
    }

    address public last_successful_address2 = address(0x0);
    function test2(uint256 blockid, uint8 v, uint256 r, uint256 s) public returns(bool) {
        require(block.number > blockid, "faulty blockid");
        require(block.number - blockid < 256, "too old blockid");
        bytes32 blockHash = blockhash(blockid);

        bytes32 e = keccak256(abi.encodePacked(msg.sender, blockHash));

        bool isok = check(uint256(e), v, r, s, p1_saved, p2_saved);
        if (isok) {
            last_successful_address2 = msg.sender;
        }
        return isok;
    }

    function calcPointShamir(uint256 u1, uint256 u2, uint256 qx, uint256 qy) private pure returns(uint256[3] memory R) {
        uint256[3] memory G = [GX, GY, 1];
        uint256[3] memory Q = [qx, qy, 1];
        uint256[3] memory Z = ecadd(Q, G);

        uint256 mask = 2**255;

        // Skip leading zero bits
        uint256 or = u1 | u2;
        while (or & mask == 0) {
            mask = mask / 2;
        }

        // Initialize output
        if (u1 & mask != 0) {
            if (u2 & mask != 0) {
                R = Z;
            }
            else {
                R = G;
            }
        }
        else {
            R = Q;
        }

        while (true) {

            mask = mask / 2;
            if (mask == 0) {
                break;
            }

            R = ecdouble(R);

            if (u1 & mask != 0) {
                if (u2 & mask != 0) {
                    R = ecadd(Z, R);
                }
                else {
                    R = ecadd(G, R);
                }
            }
            else {
                if (u2 & mask != 0) {
                    R = ecadd(Q, R);
                }
            }
        }
    }


    function getSqrY(uint256 x) private pure returns(uint256) {
        //return y^2=x^3+Ax+B
        return addmod(mulmod(x, mulmod(x, x, P), P), addmod(mulmod(A, x, P), B, P), P);
    }


    //function checks if point (x, y) is on curve, x and y affine coordinate parameters
    function isPoint(uint256 x, uint256 y) public pure returns(bool) {
        //point fulfills y^2=x^3+Ax+B?
        return mulmod(y, y, P) == getSqrY(x);
    }


    function decompressPoint(uint256 x, uint8 yBit) private view returns(uint256) {
        //return sqrt(x^3+Ax+B)
        uint256 absy = modexp(getSqrY(x), 1+(P-3)/4, P);
        return yBit == 0 ? absy : uint256(-1 * int256(absy));
    }


    // point addition for elliptic curve in jacobian coordinates
    // formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
    function ecadd(uint256[3] memory _p, uint256[3] memory _q) private pure returns(uint256[3] memory R) {

        // if (_q[0] == 0 && _q[1] == 0 && _q[2] == 0) {
        // 	return _p;
        // }

        uint256 z2 = mulmod(_q[2], _q[2], P);
        uint256 u1 = mulmod(_p[0], z2, P);
        uint256 s1 = mulmod(_p[1], mulmod(z2, _q[2], P), P);
        z2 = mulmod(_p[2], _p[2], P);
        uint256 u2 = mulmod(_q[0], z2, P);
        uint256 s2 = mulmod(_q[1], mulmod(z2, _p[2], P), P);

        if (u1 == u2) {
            if (s1 != s2) {
                //return point at infinity
                return [uint256(1), 1, 0];
            }
            else {
                return ecdouble(_p);
            }
        }

        u2 = addmod(u2, P - u1, P);
        z2 = mulmod(u2, u2, P);
        uint256 t2 = mulmod(u1, z2, P);
        z2 = mulmod(u2, z2, P);
        s2 = addmod(s2, P - s1, P);
        R[0] = addmod(addmod(mulmod(s2, s2, P), P - z2, P), P - mulmod(2, t2, P), P);
        R[1] = addmod(mulmod(s2, addmod(t2, P - R[0], P), P), P - mulmod(s1, z2, P), P);
        R[2] = mulmod(u2, mulmod(_p[2], _q[2], P), P);
    }


    //point doubling for elliptic curve in jacobian coordinates
    //formula from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates
    function ecdouble(uint256[3] memory _p) private pure returns(uint256[3] memory R) {

        if (_p[1] == 0) {
            //return point at infinity
            return [uint256(1), 1, 0];
        }

        uint256 z2 = mulmod(_p[2], _p[2], P);
        uint256 m = addmod(mulmod(A, mulmod(z2, z2, P), P), mulmod(3, mulmod(_p[0], _p[0], P), P), P);
        uint256 y2 = mulmod(_p[1], _p[1], P);
        uint256 s = mulmod(4, mulmod(_p[0], y2, P), P);

        R[0] = addmod(mulmod(m, m, P), P - mulmod(s, 2, P), P);
        R[2] = mulmod(2, mulmod(_p[1], _p[2], P), P);	// consider R might alias _p
        R[1] = addmod(mulmod(m, addmod(s, P - R[0], P), P), P - mulmod(8, mulmod(y2, y2, P), P), P);
    }


    //jacobian to affine coordinates transformation
    function JtoA(uint256[3] memory p) private view returns(uint256[2] memory Pnew) {
        uint zInv = invmod(p[2], P);
        uint zInv2 = mulmod(zInv, zInv, P);
        Pnew[0] = mulmod(p[0], zInv2, P);
        Pnew[1] = mulmod(p[1], mulmod(zInv, zInv2, P), P);
    }


    //computing inverse by using fermat's theorem
    function invmod(uint256 _a, uint _p) private view returns(uint256 invA) {
        invA = modexp(_a, _p - 2, _p);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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