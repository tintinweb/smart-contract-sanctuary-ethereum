pragma solidity 0.8.13;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/


import './interfaces/IData.sol';
import './libraries/CDP.sol';

contract DebondData is IData {

    uint public constant SIX_M_PERIOD = 0; // 1 min period for tests

    struct Class {
        uint id;
        bool exists;
        string symbol;
        InterestRateType interestRateType;
        address tokenAddress;
        uint periodTimestamp;
        uint lastNonceIdCreated;
        uint lastNonceIdCreatedTimestamp;
    }

    mapping(uint => Class) classes; // mapping from classId to class

    mapping(address => mapping( address => bool)) public tokenAllowed;

    // data to be exclusively for the front end (for now)
    mapping(uint => uint[]) public purchasableClasses;
    uint[] debondClasses;

    constructor(
        address DBIT,
        address USDC,
        address USDT,
        address DAI
//        address governance
    ) {

        addClass(0, "D/BIT", InterestRateType.FixedRate, DBIT, SIX_M_PERIOD);
        addClass(1, "USDC", InterestRateType.FixedRate, USDC, SIX_M_PERIOD);
        addClass(2, "USDT", InterestRateType.FixedRate, USDT, SIX_M_PERIOD);
        addClass(3, "DAI", InterestRateType.FixedRate, DAI, SIX_M_PERIOD);

        purchasableClasses[0].push(1);
        purchasableClasses[0].push(2);
        purchasableClasses[0].push(3);
        debondClasses.push(0);

        (address token1, address token2) = CDP.sortTokens(DBIT,USDC);
        tokenAllowed[token1][token2] = true;

        (token1, token2) = CDP.sortTokens(DBIT,USDT);
        tokenAllowed[token1][token2] = true;

        (token1, token2) = CDP.sortTokens(DBIT,DAI);
        tokenAllowed[token1][token2] = true;
        

    }

    /**
     * @notice this method should only be called by the governance contract TODO Only Governance
     */
    function addClass(uint classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) public override {
        Class storage class = classes[classId];
        require(!class.exists, "DebondData: cannot add an existing classId");
        class.id = classId;
        class.exists = true;
        class.symbol = symbol;
        class.interestRateType = interestRateType;
        class.tokenAddress = tokenAddress;
        class.periodTimestamp = periodTimestamp;

        // should maybe add an event
    }

    // TODO Only Governance
    function updateTokenAllowed (
        address tokenA,
        address tokenB,
        bool allowed
    ) external override {
        tokenAllowed[tokenA][tokenB] = allowed;
        tokenAllowed[tokenB][tokenA] = allowed;
    }

    function isPairAllowed (
        address _tokenA,
        address _tokenB) public view returns (bool) {
        (address tokenA, address tokenB) = sortTokens(_tokenA, _tokenB);
        return tokenAllowed[tokenA][tokenB];
    }

    function getClassFromId(
        uint classId
    ) external view returns(string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) {
        Class storage class = classes[classId];
        symbol = class.symbol;
        periodTimestamp = class.periodTimestamp;
        tokenAddress = class.tokenAddress;
        interestRateType = class.interestRateType;
        return (symbol, interestRateType, tokenAddress, periodTimestamp);
    }

    // TODO Only Bank
    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt) {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        nonceId = class.lastNonceIdCreated;
        createdAt = class.lastNonceIdCreatedTimestamp;
        return (nonceId, createdAt);
    }

    // TODO Only Bank
    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external {
        Class storage class = classes[classId];
        require(class.exists, "Debond Data: class id given not found");
        class.lastNonceIdCreated = nonceId;
        class.lastNonceIdCreatedTimestamp = createdAt;
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DebondLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DebondLibrary: ZERO_ADDRESS');
    }





}

pragma solidity 0.8.13;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

// DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul0(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }
    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function ln(uint256 x) public pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * 1e18) / 1_442695040888963407;
        }
    }

    function pow(uint256 x, uint256 y) public pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? 1e18 : uint256(0);
        } else {
            result = exp2(mul2(log2(x), y));
        }
    }

    function mul2(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = mulDivFixedPoint(x, y);
    }

    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= 1e18) {
            revert();
        }

        uint256 remainder;
        uint256 roundUpUnit;
        uint SCALE = 1e18;
        uint256 SCALE_LPOTD = 262144;
        uint256 SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / 1e18) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    function exp2(uint256 x) public pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert();
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / 1e18;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = exp2p(x192x64);
        }
    }

    function log2(uint256 x) public pure returns (uint256 result) {

        if (x < 1e18) {
            revert();
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = mostSignificantBit(x / 1e18);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * 1e18;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == 1e18) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = 5e17; delta > 0; delta >>= 1) {
                y = (y * y) / 1e18;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * 1e18) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
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

    function exp2p(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= 1e18;
            result >>= (191 - (x >> 64));
        }
    }
}

pragma solidity 0.8.13;

// SPDX-License-Identifier: apache 2.0

import "./SafeMath.sol";
/**
functions for determining the amount of DBIT to be mint and pricing 
*/ 
library CDP {
 using SafeMath for uint256;

  function BondExchangeRate(uint256 _dbitTotalSupply) public pure returns (uint256 amount_bond) {
        if (_dbitTotalSupply < 1e5) {
            amount_bond = 1 ether;
        } else {
            uint256 logTotalSupply = SafeMath.ln(_dbitTotalSupply * 1e13);
            amount_bond = SafeMath.pow(1.05 * 1 ether, logTotalSupply);
        }
    }

    /**
    * @dev convert a given amount of DBIT in USD and trhen this amount of USD in DBIT
    * @param _amountToken the amount of token
    * @param amountDBIT The amount of DBIT returned
    */
    function _conversionTokenToDBIT(uint256 _amountToken) internal pure returns(uint256 amountDBIT) {
        // This must be done later when the oracle will be implemented
        // Convert _amoutToken to USD and calculate how much DBIT we can buy with this amount of USD
        // For now we suppose both tokens are tading at 1:1

        amountDBIT = _amountToken;
    }

    /**
    * @dev given the amount of tokens, returns the amout of DBIT to mint
    * @param _amountToken the amount of token
    * @param _dbitTotalSupply the total supply of DBIT
    * @param amountDBIT The amount of DBIT to mint
    */
    function amountOfDBIT(uint256 _amountToken, uint256 _dbitTotalSupply) external pure returns(uint256 amountDBIT) {
        require(_amountToken > 0, "Debond: Provide some tokens");

        uint256 tokenToDBIT = _conversionTokenToDBIT(_amountToken);
        uint256 rate = BondExchangeRate(_dbitTotalSupply);

        amountDBIT = tokenToDBIT * rate;
    }

    function _amountOfDebondToMint(uint256 _dbitIn) internal pure returns (uint256 amountDBIT) {
        // todo: mock token contract.
        uint256 dbitMaxSupply = 10000;
        uint256 dbitTotalSupply = 1000000;

        require(_dbitIn > 0, "SigmoidBank/NULL_VALUE");
        require(dbitTotalSupply.add(_dbitIn) <= dbitMaxSupply, "insufficient value");
        // amount of of DBIT to mint
        amountDBIT = _dbitIn * 10;
    }

    
//    function _dbitUSDPrice() internal  returns(uint256) {
//        return 100;
//    }
    
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'DebondLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'DebondLibrary: ZERO_ADDRESS');
    }
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) { /// use uint?? int256???
        require(amountA > 0, 'DebondLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'DebondLibrary: INSUFFICIENT_LIQUIDITY');
        //amountB = amountA.mul(reserveB) / reserveA;
        amountB = SafeMath.div(amountA * reserveB, reserveA);

    }

}

pragma solidity 0.8.13;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IData {

    enum InterestRateType {FixedRate, FloatingRate}

    function addClass(uint classId, string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp) external;

    function updateTokenAllowed(address tokenA, address tokenB, bool allowed) external;

    function isPairAllowed(address tokenA, address tokenB) external view returns (bool);

    function getClassFromId(uint classId) external view returns(string memory symbol, InterestRateType interestRateType, address tokenAddress, uint periodTimestamp);

    function getLastNonceCreated(uint classId) external view returns(uint nonceId, uint createdAt);

    function updateLastNonce(uint classId, uint nonceId, uint createdAt) external;
}