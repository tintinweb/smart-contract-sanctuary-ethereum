// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*

        \\      //   |||||||||||   |\      ||       A CRYPTOCURRENCY FOR THE MASSES
         \\    //    ||            |\\     ||
          \\  //     ||            ||\\    ||       PRINCIPLES OF XEN:
           \\//      ||            || \\   ||       - No pre-mint; starts with zero supply
            XX       ||||||||      ||  \\  ||       - No admin keys
           //\\      ||            ||   \\ ||       - Immutable contract
          //  \\     ||            ||    \\||
         //    \\    ||            ||     \\|
        //      \\   |||||||||||   ||      \|       Copyright (C) FairCrypto Foundation 2022-2023

 */

library MagicNumbers {

    uint256 constant VERSION = 1;
    string public constant AUTHORS = "@MrJackLevin @lbelyaev faircrypto.org";

    // There's 370 fibs that fit in uint256 number
    uint256 constant MAX_UINT256_FIB_IDX = 370;
    // Max fib number that fits into uint256 size
    uint256 constant MAX_UINT256_FIB = 94611056096305838013295371573764256526437182762229865607320618320601813254535;
    // Max fib index supported by this Library
    uint256 constant MAX_FIB_IDX = 90;
    // Max number that could be safely tested by this Library
    uint256 constant MAX_SUPPORTED_FIB_CANDIDATE = 2 ** 62 - 1;

    /**
        @dev First 60 Fibonacci numbers, which fit into uint64
    */
    function fibs64() internal pure returns (uint64[60] memory) {
        return [
            uint64(0),            1,                     1,
            2,                    3,                     5,
            8,                    13,                    21,
            34,                   55,                    89,
            144,                  233,                   377,
            610,                  987,                   1597,
            2584,                 4181,                  6765,
            10946,                17711,                 28657,
            46368,                75025,                 121393,
            196418,               317811,                514229,
            832040,               1346269,               2178309,
            3524578,              5702887,               9227465,
            14930352,             24157817,              39088169,
            63245986,             102334155,             165580141,
            267914296,            433494437,             701408733,
            1134903170,           1836311903,            2971215073,
            4807526976,           7778742049,            12586269025,
            20365011074,          32951280099,           53316291173,
            86267571272,          139583862445,          225851433717,
            365435296162,         591286729879,          956722026041
        ];
    }

    /**
        @dev Tests if number is a fib via a linear lookup in the table above
    */
    function isFibs64(uint256 n) internal pure returns (bool) {
        for(uint i = 0; i < 60; i++) if (fibs64()[i] == n) return true;
        return false;
    }

    /**
        @dev Next 38 Fibonacci numbers, which fit into uint128
    */
    function fibs128() internal pure returns (uint128[39] memory) {
        return [
            uint128(1548008755920),2504730781961,        4052739537881,
            6557470319842,        10610209857723,        17167680177565,
            27777890035288,       44945570212853,        72723460248141,
            117669030460994,      190392490709135,       308061521170129,
            498454011879264,      806515533049393,       1304969544928657,
            2111485077978050,     3416454622906707,      5527939700884757,
            8944394323791464,     14472334024676221,     23416728348467685,
            37889062373143906,    61305790721611591,     99194853094755497,
            160500643816367088,   259695496911122585,    420196140727489673,
            679891637638612258,   1100087778366101931,   1779979416004714189,
            2880067194370816120,  4660046610375530309,   7540113804746346429,
            12200160415121876738, 19740274219868223167,  31940434634990099905,
            51680708854858323072, 83621143489848422977,  135301852344706746049
        ];
    }

    /**
        @dev Tests if number is a fib via a linear lookup in the table above
    */
    function isFibs128(uint256 n) internal pure returns (bool) {
        for(uint i = 0; i < 39; i++) if (fibs128()[i] == n) return true;
        return false;
    }

    /**
        @dev Helper for Miller-Rabin probabilistic primality test
    */
    // Write (n - 1) as 2^s * d
    function getValues(uint256 n) internal pure returns (uint256[2] memory) {
        uint256 s = 0;
        uint256 d = n - 1;
        while (d % 2 == 0) {
            d = d / 2;
            s++;
        }
        uint256[2] memory ret;
        ret[0] = s;
        ret[1] = d;
        return ret;
    }

    /**
        @dev Wrapper around EVM precompiled function for modular exponentiation, deployed at 0x05 address
    */
    function modExp(uint256 base, uint256 e, uint256 m) internal view returns (uint o) {
        assembly {
        // define pointer
            let p := mload(0x40)
        // store data assembly-favouring ways
            mstore(p, 0x20)             // Length of Base
            mstore(add(p, 0x20), 0x20)  // Length of Exponent
            mstore(add(p, 0x40), 0x20)  // Length of Modulus
            mstore(add(p, 0x60), base)  // Base
            mstore(add(p, 0x80), e)     // Exponent
            mstore(add(p, 0xa0), m)     // Modulus
        if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) {
           revert(0, 0)
        }
        // data
            o := mload(p)
        }
    }

    /**
      @dev  Miller-Rabin test probabilistic primality test
            see https://en.wikipedia.org/wiki/Miller–Rabin_primality_test
    */
    function probablyPrime(uint256 n, uint256 prime) internal view returns (bool) {
        if (n == 2 || n == 3) {
            return true;
        }

        if (n % 2 == 0 || n < 2) {
            return false;
        }

        uint256[2] memory values = getValues(n);
        uint256 s = values[0];
        uint256 d = values[1];

        uint256 x = modExp(prime, d, n);

        if (x == 1 || x == n - 1) {
            return true;
        }

        for (uint256 i = s - 1; i > 0; i--) {
            x = modExp(x, 2, n);
            if (x == 1) {
                return false;
            }
            if (x == n - 1) {
                return true;
            }
        }
        return false;
    }

    /**
      @dev  Determines if a number is prime, using Miller-Rabin test probabilistic primality test
            plus deterministic checking to sift out pseudo-primes
            see https://en.wikipedia.org/wiki/Miller–Rabin_primality_test
    */
    function isPrime(uint256 n) public view returns (bool) {
        if (n < 2_047)
            return probablyPrime(n, 2);
        else if (n < 1_373_653)
            return probablyPrime(n, 2) && probablyPrime(n, 3);
        else if (n < 9_080_191)
            return probablyPrime(n, 31) && probablyPrime(n, 73);
        else if (n < 25_326_001)
            return probablyPrime(n, 2) && probablyPrime(n, 3)
            && probablyPrime(n, 5);
        else if (n < 3_215_031_751)
            return probablyPrime(n, 2) && probablyPrime(n, 3)
            && probablyPrime(n, 5) && probablyPrime(n, 7);
        else if (n < 4_759_123_141)
            return probablyPrime(n, 2) && probablyPrime(n, 7)
            && probablyPrime(n, 61);
        else if (n < 1_122_004_669_633)
            return probablyPrime(n, 2) && probablyPrime(n, 13)
            && probablyPrime(n, 23) && probablyPrime(n, 1662803);
        else if (n < 2_152_302_898_747)
            return probablyPrime(n, 2) && probablyPrime(n, 3)
            && probablyPrime(n, 5) && probablyPrime(n, 7)
            && probablyPrime(n, 11);
        else if (n < 3_474_749_660_383)
            return probablyPrime(n, 2) && probablyPrime(n, 3)
            && probablyPrime(n, 5) && probablyPrime(n, 7)
            && probablyPrime(n, 11) && probablyPrime(n, 13);
        else if (n < 341_550_071_728_321)
            return probablyPrime(n, 2) && probablyPrime(n, 3)
            && probablyPrime(n, 5) && probablyPrime(n, 7)
            && probablyPrime(n, 11) && probablyPrime(n, 13)
            && probablyPrime(n, 17);
        return false;
        // TODO: consider reverting ???
        // revert('number too big');
    }

    /**
        @dev Count prime numbers occurring between `from` and `to` numbers
    */
    function findPrimes(uint256 from, uint256 to) external view returns (uint256 count) {
        require(to > 0, "findPrimes: to should be natural");
        require(to > from, "findPrimes: to should be larger than from");
        count = 0;
        for(uint i = from; i < to; i++) {
            if (isPrime(i)) count++;
        }
    }

    /**
        @dev Helper to get N-th Fibonacci number (0 returns 0)
    */
    function getFib(uint256 n) internal pure returns (uint256 a) {
        if (n == 0) {
            return 0;
        }
        uint256 h = n / 2;
        uint256 mask = 1;
        // find highest set bit in n
        while(mask <= h) {
            mask <<= 1;
        }
        mask >>= 1;
        a = 1;
        uint256 b = 1;
        uint256 c;
        while(mask > 0) {
            c = a * a+b * b;
            if (n & mask > 0) {
                b = b * (b + 2 * a);
                a = c;
            } else {
                a = a * (2 * b - a);
                b = c;
            }
            mask >>= 1;
        }
        return a;
    }

    /**
        @dev Helper to check if a number is a perfect square
    */
    function isPerfectSquare(uint256 n) internal pure returns (bool) {
       uint256 low = 0;
       uint256 high = n;
       while (low <= high) {
           uint mid = (low + high) / 2;
           uint square = mid * mid;
           if (square == n) {
               return true;
           } else if (square > n) {
               high = mid - 1;
           } else {
               low = mid + 1;
           }
       }
       return false;
   }

    /**
        @dev Test if the number is a fib
        note the upper limit of 2 ** 62 - 1, to avoid overflow while preforming tests
    */
   function isFib(uint256 n) public pure returns (bool) {
       if (n == 0) return false;
       require(n < MAX_SUPPORTED_FIB_CANDIDATE, 'isFib: number too big');
       uint256 base = n * n * 5;
       uint256 p1 = base + 4;
       uint256 p2 = base - 4;
       return (isPerfectSquare(p1) || isPerfectSquare(p2));
    }
}