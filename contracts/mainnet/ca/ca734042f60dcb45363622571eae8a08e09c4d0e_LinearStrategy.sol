// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IFaucetStrategy} from "./IFaucetStrategy.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title A linear vesting strategy for faucets.
/// @author tbtstl <[email protected]>
contract LinearStrategy is IFaucetStrategy {
    /// @notice The total amount of token that could be claimable at a particular timestamp
    /// @param _totalAmt The total amount of token that exists in the faucet
    /// @param _faucetStart The timestamp that the faucet was created on
    /// @param _faucetExpiry The timestamp that the faucet will finish vesting on
    /// @param _timestamp The current timestamp to check against
    function claimableAtTimestamp(
        uint256 _totalAmt,
        uint256 _faucetStart,
        uint256 _faucetExpiry,
        uint256 _timestamp
    ) external pure returns (uint256) {
        if (_timestamp <= _faucetStart) {
            return 0;
        } else if (_timestamp >= _faucetExpiry) {
            return _totalAmt;
        } else {
            return mulDiv(_timestamp - _faucetStart, _totalAmt, _faucetExpiry - _faucetStart);
        }
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IFaucetStrategy).interfaceId;
    }

    // compute x * y / b without overflow,
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 b
    ) private pure returns (uint256) {
        // store x * y in 512-bit
        (uint256 a0, uint256 a1) = mul512(x, y);

        // We now have a 512-bit numerator and a 256-bit denominator, which we can represent as
        // z = floor((a1*2^256 + a0) / b)
        // Note that 2^256 can be represented as div256(b) * b + mod256(b) -> q*b + r – where b is constant and both div256(b) and mod256(b) < 2^256
        // This means that this representation can fit in one word.
        // We then reconstruct the formula as
        // x = floor((a1 * (q*b+r) + a0) / b) = a1*q + floor((a1*r + a0) / b)
        // We've now removed a piece of the fraction, and have a smaller numerator (because r < 2^256)
        // If we recursively fragment pieces of this fraction via this method, we can sum up all the fragments into the final representation
        // Eventually, a1 will be 0 (since A will eventually be < 2^256), and we can do normal integer division
        uint256 q = div256(b);
        uint256 r = mod256(b);
        uint256 t0;
        uint256 t1;
        uint256 z0;
        uint256 z1;
        // The cost of this function scales with the size of (b), and in practice should run very few times
        // In the worst case (b == 2^256 - 1), this loop runs 256 times.
        while (a1 != 0) {
            (t0, t1) = mul512(a1, q); // store (a_1 * q) in T
            (z0, z1) = add512(z0, z1, t0, t1); // add T to X
            (t0, t1) = mul512(a1, r); // store (a_1 * r) in T (we've already added to X above so it's safe to overwrite)
            (a0, a1) = add512(t0, t1, a0, 0); // store (a_1*r + a_0) in A again, for next cycle of computation
        }

        (z0, z1) = add512(z0, z1, a0 / b, 0);

        // return only the lowest half of the 512-bit number because for our case this will always be < 2^256
        return z0;
    }

    // overflow safe multiplication by storing the product of multiplication into 512-bits, via Chinese Remainder Theorem
    // from: https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
    function mul512(uint256 a, uint256 b) private pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    // divide 2^256 by a
    function div256(uint256 a) private pure returns (uint256 r) {
        require(a > 1);
        assembly {
            r := add(div(sub(0, a), a), 1)
        }
    }

    // compute 2^256 mod a
    function mod256(uint256 a) private pure returns (uint256 r) {
        require(a != 0);
        assembly {
            r := mod(sub(0, a), a)
        }
    }

    // add 2 512-bit numbers
    function add512(
        uint256 a0,
        uint256 a1,
        uint256 b0,
        uint256 b1
    ) private pure returns (uint256 r0, uint256 r1) {
        assembly {
            r0 := add(a0, b0)
            r1 := add(add(a1, b1), lt(r0, a0))
        }
    }

    // subtract two 512-bit numbers
    function sub512(
        uint256 a0,
        uint256 a1,
        uint256 b0,
        uint256 b1
    ) private pure returns (uint256 r0, uint256 r1) {
        assembly {
            r0 := sub(a0, b0)
            r1 := sub(sub(a1, b1), lt(a0, b0))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IFaucetStrategy is IERC165 {
    function claimableAtTimestamp(
        uint256 _totalAmt,
        uint256 _faucetStart,
        uint256 _faucetExpiry,
        uint256 _timestamp
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}