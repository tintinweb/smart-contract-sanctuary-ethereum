/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

pragma solidity ^0.8.17;
/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // https://ethereum.stackexchange.com/a/96646
            uint256 twos = denominator & (~denominator + 1);
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// @dev https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// @dev Like `mul512`, but multiply a number by itself
    function square512(uint256 a) internal pure returns (uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, a, not(0))
            r0 := mul(a, a)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// @dev https://github.com/hifi-finance/prb-math/blob/main/contracts/PRBMathCommon.sol
    function log2floor(uint256 x) internal pure returns (uint256 msb) {
        unchecked {
            if (x >= 2**128) {
                x >>= 128;
                msb += 128;
            }
            if (x >= 2**64) {
                x >>= 64;
                msb += 64;
            }
            if (x >= 2**32) {
                x >>= 32;
                msb += 32;
            }
            if (x >= 2**16) {
                x >>= 16;
                msb += 16;
            }
            if (x >= 2**8) {
                x >>= 8;
                msb += 8;
            }
            if (x >= 2**4) {
                x >>= 4;
                msb += 4;
            }
            if (x >= 2**2) {
                x >>= 2;
                msb += 2;
            }
            if (x >= 2**1) {
                // No need to shift x any more.
                msb += 1;
            }
        }
    }

    /// @dev https://graphics.stanford.edu/~seander/bithacks.html#IntegerLogDeBruijn
    function log2ceil(uint256 x) internal pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m, 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m, 0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m, 0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m, 0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m, 0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m, 0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m, 0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m, 0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }
}


struct UINT512 {
    // Least significant bits
    uint256 LS;
    // Most significant bits
    uint256 MS;
}

library SafeMath {
    /// @dev Adds an (LS, MS) pair in place. Assumes result fits in uint512
    function iadd(
        UINT512 storage self,
        uint256 LS,
        uint256 MS
    ) internal {
        unchecked {
            if (self.LS > type(uint256).max - LS) {
                self.LS = addmod(self.LS, LS, type(uint256).max);
                self.MS += 1 + MS;
            } else {
                self.LS += LS;
                self.MS += MS;
            }
        }
    }

    /// @dev Adds an (LS, MS) pair to self. Assumes result fits in uint512
    function add(
        UINT512 memory self,
        uint256 LS,
        uint256 MS
    ) internal pure returns (uint256, uint256) {
        unchecked {
            return
                (self.LS > type(uint256).max - LS)
                    ? (addmod(self.LS, LS, type(uint256).max), self.MS + MS + 1)
                    : (self.LS + LS, self.MS + MS);
        }
    }

    /// @dev Subtracts an (LS, MS) pair in place. Assumes result > 0
    function isub(
        UINT512 storage self,
        uint256 LS,
        uint256 MS
    ) internal {
        unchecked {
            if (self.LS < LS) {
                self.LS = type(uint256).max + self.LS - LS;
                self.MS -= 1 + MS;
            } else {
                self.LS -= LS;
                self.MS -= MS;
            }
        }
    }

    /// @dev Subtracts an (LS, MS) pair from self. Assumes result > 0
    function sub(
        UINT512 memory self,
        uint256 LS,
        uint256 MS
    ) internal pure returns (uint256, uint256) {
        unchecked {
            return (self.LS < LS) ? (type(uint256).max + self.LS - LS, self.MS - MS - 1) : (self.LS - LS, self.MS - MS);
        }
    }

    /// @dev Multiplies self by single uint256, s. Assumes result fits in uint512
    function muls(UINT512 memory self, uint256 s) internal pure returns (uint256, uint256) {
        unchecked {
            self.MS *= s;
            (self.LS, s) = FullMath.mul512(self.LS, s);
            return (self.LS, self.MS + s);
        }
    }
}




pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (UINT512 memory);
    function balanceOf(address account) external view returns (UINT512 memory);
    function allowance(address owner, address spender) external view returns (UINT512 memory);

    function transfer(address recipient, UINT512 memory amount) external returns (bool);
    function approve(address spender, UINT512 memory amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, UINT512 value);
    event Approval(address indexed owner, address indexed spender, UINT512 value);
}


contract SampleToken is IERC20 {
    using SafeMath for UINT512;

    string public constant name = "SampleToken";
    string public constant symbol = "SMT";
    uint8 public constant decimals = 18;

    mapping(address => UINT512) balances;
    mapping(address => mapping (address => UINT512)) allowed;

    UINT512 totalSupply_;
    UINT512 total;

    constructor(UINT512 memory total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (UINT512 memory) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (UINT512 memory) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, UINT512 memory numTokens) public override returns (bool) {
//        require(numTokens <= balances[msg.sender]);
//        balances[msg.sender] = balances[msg.sender].sub(numTokens);
//        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, UINT512 memory numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns ( UINT512 memory) {
        return allowed[owner][delegate];
    }

}