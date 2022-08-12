/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

contract UniV3Oracle {
    uint256 public priceA;
    uint256 public priceB;
    uint256 public decimalA;
    uint256 public decimalB;
    
    function setValue(uint256 _priceA, uint256 _priceB, uint256 _decimalA, uint256 _decimalB) external {
        priceA = _priceA;
        priceB = _priceB;
        decimalA = _decimalA;
        decimalB = _decimalB;
    }
    
    function readValue() public view returns(uint256 _priceA, uint256 _priceB, uint256 _decimalA, uint256 _decimalB) {
        _priceA = _priceA;
        _priceB = priceB;
        _decimalA = decimalA;
        _decimalB = decimalB;
    }

    function complexWay() public view returns(uint160 sqrtPriceX96) {
        if (decimalA == decimalB) {
            // multiply by 10^18 then divide by 10^9 to preserve price in wei
            sqrtPriceX96 = uint160(
                (sqrt(
                    ((priceA * (10**18)) / (priceB))
                ) * 2**96) / 10**9
            );
        } else if (decimalB > decimalA) {
            // multiple by 10^(decimalB - decimalA) to preserve price in wei
            sqrtPriceX96 = uint160(
                sqrt(
                    (priceA * (10 ** (decimalB - decimalA))) / priceB
                ) * 2**96
            );
        } else {
            // multiple by 10^(decimalA - decimalB) to preserve price in wei then divide by the same number
            sqrtPriceX96 = uint160(
                (sqrt(
                    (priceA * (10 ** (decimalA - decimalB))) / priceB
                ) * 2**96) /
                10 ** (decimalA - decimalB)
            );
        }
    }

    function simpleWay() public view returns(uint160 sqrtPriceX96) {
        uint256 _priceA = priceA * decimalB;
        uint256 _priceB = priceB * decimalA;

        sqrtPriceX96 = uint160(
            sqrt(_priceA * (2 ** 192) / _priceB)
        );
    }

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
        // This segment is to get a reasonable initial estimate for the Babylonian method.
        // If the initial estimate is bad, the number of correct bits increases ~linearly
        // each iteration instead of ~quadratically.
        // The idea is to get z*z*y within a small factor of x.
        // More iterations here gets y in a tighter range. Currently, we will have
        // y in [256, 256*2^16). We ensure y>= 256 so that the relative difference
        // between y and y+1 is small. If x < 256 this is not possible, but those cases
        // are easy enough to verify exhaustively.
            z := 181 // The 'correct' value is 1, but this saves a multiply later
            let y := x
        // Note that we check y>= 2^(k + 8) but shift right by k bits each branch,
        // this is to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }
        // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8),
        // and either y >= 256, or x < 256.
        // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
        // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of x, or about 20bps.

        // The estimate sqrt(x) = (181/1024) * (x+1) is off by a factor of ~2.83 both when x=1
        // and when x = 256 or 1/256. In the worst case, this needs seven Babylonian iterations.
            z := shr(18, mul(z, add(y, 65536))) // A multiply is saved from the initial z := 181

        // Run the Babylonian method seven times. This should be enough given initial estimate.
        // Possibly with a quadratic/cubic polynomial above we could get 4-6.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

        // See https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division.
        // If x+1 is a perfect square, the Babylonian method cycles between
        // floor(sqrt(x)) and ceil(sqrt(x)). This check ensures we return floor.
        // The solmate implementation assigns zRoundDown := div(x, z) first, but
        // since this case is rare, we choose to save gas on the assignment and
        // repeat division in the rare case.
        // If you don't care whether floor or ceil is returned, you can skip this.
            if lt(div(x, z), z) {
                z := div(x, z)
            }
        }
    }
}