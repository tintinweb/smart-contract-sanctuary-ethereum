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



import './APM.sol';
import './DebondData.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAPM.sol";
import "./interfaces/IData.sol";
import "./interfaces/IDebondBond.sol";
import "./interfaces/IDebondToken.sol";
import "./libraries/CDP.sol";


contract Bank {

    using CDP for uint256;
    using SafeERC20 for IERC20;

    IAPM apm;
    IData debondData;
    IDebondBond bond;
    enum PurchaseMethod {Buying, Staking}
    uint public constant BASE_TIMESTAMP = 1646089200; // 2022-03-01 00:00
    uint public constant DIFF_TIME_NEW_NONCE = 24 * 3600; // every 24h we crate a new nonce.
    uint public constant RATE = 5; // every 24h we crate a new nonce.

    constructor(address apmAddress, address dataAddress, address bondAddress) {
        apm = IAPM(apmAddress);
        debondData = IData(dataAddress);
        bond = IDebondBond(bondAddress);
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // **** BUY BONDS ****

    function buyBond(
        uint _purchaseTokenClassId, // token added
        uint _debondTokenClassId, // token to mint
        uint _purchaseTokenAmount,
        uint _debondTokenMinAmount,
        PurchaseMethod purchaseMethod
    ) external {

        uint purchaseTokenClassId = _purchaseTokenClassId;
        uint debondTokenClassId = _debondTokenClassId;
        uint purchaseTokenAmount = _purchaseTokenAmount;
        uint debondTokenMinAmount = _debondTokenMinAmount;
        (,,address purchaseTokenAddress,) = debondData.getClassFromId(purchaseTokenClassId);
        (,,address debondTokenAddress,) = debondData.getClassFromId(debondTokenClassId);


        require(debondData.isPairAllowed(purchaseTokenAddress, debondTokenAddress), "Pair not Allowed");

        uint amountBToMint = calculateDebondTokenToMint(
//            purchaseTokenAddress,
//            debondTokenAddress,
            purchaseTokenAmount
        );

//        require(debondTokenMinAmount <= amountBToMint, "Not enough debond token in minting calculation");


        IERC20(purchaseTokenAddress).transferFrom(msg.sender, address(apm), purchaseTokenAmount);
        //see uniswap : transferhelper,ierc202
        IDebondToken(debondTokenAddress).mint(address(apm), amountBToMint);
        // be aware that tokenB is a DebondToken, maybe add it to the class model


        if (purchaseMethod == PurchaseMethod.Staking) {
            issueBonds(msg.sender, purchaseTokenClassId, purchaseTokenAmount);
            (uint reserveA, uint reserveB) = (apm.getReserve(purchaseTokenAddress), apm.getReserve(debondTokenAddress));
            uint amount = CDP.quote(purchaseTokenAmount, reserveA, reserveB);
            issueBonds(msg.sender, debondTokenClassId, amount * RATE / 100);
            //msg.sender or to??
        }
        else
            if (purchaseMethod == PurchaseMethod.Buying) {
                (uint reserveA, uint reserveB) = (apm.getReserve(purchaseTokenAddress), apm.getReserve(debondTokenAddress));
                uint amount = CDP.quote(purchaseTokenAmount, reserveA, reserveB);
                issueBonds(msg.sender, debondTokenClassId, amount + amount * RATE / 100); // here the interest calculation is hardcoded
            }

            apm.updaReserveAfterAddingLiquidity(debondTokenAddress, amountBToMint);
            apm.updaReserveAfterAddingLiquidity(purchaseTokenAddress, purchaseTokenAmount);
            apm.updateRatioAfterAddingLiquidity(debondTokenAddress, purchaseTokenAddress, amountBToMint, purchaseTokenAmount);


    }

    // **** REDEEM BONDS ****

    function redeemBonds(
        uint _TokenClassId,
        uint _TokenNonceId,
        uint amount
        //uint amountMin?
    ) external {
        IDebondBond(address(bond)).redeem(msg.sender, _TokenClassId,  _TokenNonceId, amount);
	    //require(redeemable) is already done in redeem function for liquidity, but still has to be done for time redemption

        (, IData.InterestRateType interestRateType ,address TokenAddress,) = debondData.getClassFromId(_TokenClassId);
        //require(reserves[TokenAddress]>amountIn);

        if(interestRateType == IData.InterestRateType.FixedRate) {
            IERC20(TokenAddress).transferFrom(address(apm), msg.sender, amount);


        }
        else if (interestRateType == IData.InterestRateType.FloatingRate){
            //to be implemented later
        }



	    
        //how do we know if we have to burn (or put in reserves) dbit or dbgt?


	    //APM.removeLiquidity(tokenAddress, amountIn);
//        apm.updaReserveAfterRemovingLiquidity(tokenAddress, amountIn);
        //emit

    }

    // **** Swaps ****







    // TODO External to the Bank maybe
    function calculateDebondTokenToMint(
//        address purchaseTokenAddress, // token added
//        address debondTokenAddress, //token minted
        uint purchaseTokenAmount
    ) internal pure returns (uint amountB) {

        uint amountBOptimal = amountOfDBITToMint(purchaseTokenAmount);
        //change this later
        amountB = amountBOptimal;

    }


    function amountOfDBITToMint(uint256 amountA) public pure returns (uint256 amountToMint) {
        return amountA;
    }

    function issueBonds(address to, uint256 classId, uint256 amount) private {
        manageNonceId(classId);
        (uint nonceId,) = debondData.getLastNonceCreated(classId);
        bond.issue(to, classId, nonceId, amount);
    }

    function manageNonceId(uint classId) private {
        uint timestampToCheck = block.timestamp;
        (uint lastNonceId, uint createdAt) = debondData.getLastNonceCreated(classId);
        if ((timestampToCheck - createdAt) >= DIFF_TIME_NEW_NONCE) {
            createNewNonce(classId, lastNonceId, timestampToCheck);
            return;
        }

        uint tDay = (timestampToCheck - BASE_TIMESTAMP) % DIFF_TIME_NEW_NONCE;
        if ((tDay + (timestampToCheck - createdAt)) >= DIFF_TIME_NEW_NONCE) {
            createNewNonce(classId, lastNonceId, timestampToCheck);
            return;
        }
    }

    function createNewNonce(uint classId, uint lastNonceId, uint creationTimestamp) private {
        uint _newNonceId = lastNonceId++;
        (,,, uint period) = debondData.getClassFromId(classId);
        bond.createNonce(classId, _newNonceId, creationTimestamp + period, 500);
        debondData.updateLastNonce(classId, _newNonceId, creationTimestamp);
        //here 500 is liquidity info hard coded for now
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

// SPDX-License-Identifier: MIT



interface IERC3475 {

    // WRITE

    /**
     * @dev allows the transfer of a bond type from an address to another.
     * @param from argument is the address of the holder whose balance about to decrees.
     * @param to argument is the address of the recipient whose balance is about to increased.
     * @param classId is the classId of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that will be transferred from "_from" address to "_to" address.
     */
    function transferFrom(address from, address to, uint256 classId, uint256 nonceId, uint256 amount) external;


    /**
     * @dev  allows issuing any number of bond types to an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param to is the address to which the bond will be issued.
     * @param classId is the classId of the bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that "to" address will receive.
     */
    function issue(address to, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev  allows redemption of any number of bond types from an address.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param from is the address from which the bond will be redeemed.
     * @param classId is the class nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonce of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that "from" address will redeem.
     */
    function redeem(address from, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev  allows the transfer of any number of bond types from an address to another.
     * The calling of this function needs to be restricted to bond issuer contract.
     * @param from argument is the address of the holder whose balance about to decrees.
     * @param classId is the class nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonce of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond, that will be transferred from "_from"address to "_to" address.
     */
    function burn(address from, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
     * @dev Allows spender to withdraw from your account multiple times, up to the amount.
     * @notice If this function is called again it overwrites the current allowance with amount.
     * @param spender is the address the caller approve for his bonds
     * @param classId is the classId nonce of bond, the first bond class created will be 0, and so on.
     * @param nonceId is the nonceId of the given bond class. This param is for distinctions of the issuing conditions of the bond.
     * @param amount is the amount of the bond that the spender is approved for.
     */
    function approve(address spender, uint256 classId, uint256 nonceId, uint256 amount) external;

    /**
      * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
      * @dev MUST emit the ApprovalForAll event on success.
      * @param operator  Address to add to the set of authorized operators
      * @param classId is the classId nonce of bond, the first bond class created will be 0, and so on.
      * @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalFor(address operator, uint256 classId, bool approved) external;

    /**
     * @dev Allows spender to withdraw bonds from your account multiple times, up to the amount.
     * @notice If this function is called again it overwrites the current allowance with amount.
     * @param spender is the address the caller approve for his bonds.
     * @param classIds is the list of classIds of bond.
     * @param nonceIds is the list of nonceIds of the given bond class.
     * @param amounts is the list of amounts of the bond that the spender is approved for.
     */
    function batchApprove(address spender, uint256[] calldata classIds, uint256[] calldata nonceIds, uint256[] calldata amounts) external;


    // READ

    /**
     * @dev Returns the total supply of the bond in question
     */
    function totalSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the redeemed supply of the bond in question
     */
    function redeemedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the active supply of the bond in question
     */
    function activeSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the burned supply of the bond in question
     */
    function burnedSupply(uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the balance of the giving bond classId and bond nonce
     */
    function balanceOf(address account, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
     * @dev Returns the symbol of the giving bond classId
     */
    function symbol(uint256 classId) external view returns (string memory);

    /**
     * @dev Returns the informations for the class of given classId
     * @notice Every bond contract can have their own list of class informations
     */
    function classInfos(uint256 classId) external view returns (uint256[] memory);

    /**
     * @dev Returns the information description for a given class info
     * @notice Every bond contract can have their own list of class informations
     */
    function classInfoDescription(uint256 classInfo) external view returns (string memory);

    /**
     * @dev Returns the information description for a given nonce info
     * @notice Every bond contract can have their own list of nonce informations
     */
    function nonceInfoDescription(uint256 nonceInfo) external view returns (string memory);

    /**
     * @dev Returns the informations for the nonce of given classId and nonceId
     * @notice Every bond contract can have their own list. But the first uint256 in the list MUST be the UTC time code of the issuing time.
     */
    function nonceInfos(uint256 classId, uint256 nonceId) external view returns (uint256[] memory);

    /**
     * @dev  allows anyone to check if a bond is redeemable.
     * @notice the conditions of redemption can be specified with one or several internal functions.
     */
    function isRedeemable(uint256 classId, uint256 nonceId) external view returns (bool);

    /**
     * @notice  Returns the amount which spender is still allowed to withdraw from owner.
     */
    function allowance(address owner, address spender, uint256 classId, uint256 nonceId) external view returns (uint256);

    /**
    * @notice Queries the approval status of an operator for a given owner.
    * @return True if the operator is approved, false if not
    */
    function isApprovedFor(address owner, address operator, uint256 classId) external view returns (bool);

    /**
    * @notice MUST trigger when tokens are transferred, including zero value transfers.
    */
    event Transfer(address indexed _operator, address indexed _from, address indexed _to, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are issued
    */
    event Issue(address indexed _operator, address indexed _to, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are redeemed
    */
    event Redeem(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @notice MUST trigger when tokens are burned
    */
    event Burn(address indexed _operator, address indexed _from, uint256 classId, uint256 nonceId, uint256 amount);

    /**
    * @dev MUST emit when approval for a second party/operator address to manage all bonds from a classId given for an owner address is enabled or disabled (absence of an event assumes disabled).
    */
    event ApprovalFor(address indexed _owner, address indexed _operator, uint256 classId, bool _approved);

}

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

interface IDebondToken is IERC20 {

    function mint(address _to, uint256 _amount) external;


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

import "./IERC3475.sol";
import "./IData.sol";


interface IDebondBond is IERC3475 {

    function createNonce(uint256 classId, uint256 nonceId, uint256 maturityTime, uint256 liqT) external;

    function createClass(uint256 classId, string memory symbol, IData.InterestRateType interestRateType, address tokenAddress, uint256 periodTimestamp) external;

    function classExists(uint256 classId) external returns (bool);

    function nonceExists(uint256 classId, uint256 nonceId) external returns (bool);

    function bondDetails(uint256 classId, uint256 nonceId) external view returns (string memory _symbol, IData.InterestRateType _interestRateType, address _tokenAddress, uint256 _periodTimestamp, uint256 _maturityDate, uint256 _issuanceDate);

    function isActive() external returns (bool);


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

interface IAPM {

    function updaReserveAfterAddingLiquidity(
        address _token,
        uint256 _amount
    ) external;

    function updaReserveAfterRemovingLiquidity(
        address _token,
        uint256 _amount
    ) external;

    function updateRatioAfterAddingLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) external;

    function updateRatioAfterRemovingLiquidity(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) external;

    function getReserve(
        address _token
    ) external view returns(uint256 _reserve);

    function getRatios(
        address _token0,
        address _token1
    ) external view returns(uint256 _ratio01, uint256 _ratio10);

    function getPrices(
        address _token0,
        address _token1
    ) external view returns(uint256 _price01, uint256 _price10);
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

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAPM.sol";
import "./libraries/SafeMath.sol";


contract APM is IAPM {
    using SafeMath for uint256;

    mapping(address => uint256) internal reserve;
    mapping(address => mapping(address => uint256)) internal ratio;
    mapping(address => mapping(address => uint256)) internal price;
    mapping(address => address[]) internal tokenPairs;  // This must be retrieved from Bank

    /**
    * @dev update revserve of tokens after adding liquidity
    * @param _token address of the token
    * @param _amount amount of the tokens to add
    */
    function updaReserveAfterAddingLiquidity(address _token, uint256 _amount) external {
        require(_token != address(0), "Not valid token address");
        require(_amount > 0, "Debond: No liquidity sent");

        uint256 _reserve = reserve[_token];
		reserve[_token] = _reserve + _amount;
	}

    /**
    * @dev update revserve of tokens after removing liquidity
    * @param _token address of the token
    * @param _amount amount of the tokens to add
    */
    function updaReserveAfterRemovingLiquidity(address _token, uint256 _amount) external {
        require(_token != address(0), "Notr valid token address");
        require(_amount > 0, "Debond: No liquidity sent");

        uint256 _reserve0 = reserve[_token];
		reserve[_token] = _reserve0 - _amount;
	}

    /**
    * @dev update rations of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _amount0 amount of first tokens to add
    * @param _amount1 amount of second tokens to add
    */
    function updateRatioAfterAddingLiquidity(address _token0, address _token1, uint256 _amount0, uint256 _amount1) external {
        require(_token0 != address(0) && _token1 != address(0), "Notr valid token address");
        require(_amount0 > 0 && _amount1 > 0, "Debond: No liquidity sent");

        (uint256 _ratio0, uint256 _ratio1) = (ratio[_token0][_token1], ratio[_token1][_token0]);

		(ratio[_token0][_token1], ratio[_token1][_token0]) = (_ratio0 + _amount0 , _ratio1 + _amount1);
	}

    /**
    * @dev update rations of a token pair after removing liquidity
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _amount0 amount of first tokens to add
    * @param _amount1 amount of second tokens to add
    */
    function updateRatioAfterRemovingLiquidity(address _token0, address _token1, uint256 _amount0, uint256 _amount1) external {
        require(_token0 != address(0) && _token1 != address(0), "Notr valid token address");
        require(_amount0 > 0 && _amount1 > 0, "Debond: No liquidity sent");

        (uint256 _ratio0, uint256 _ratio1) = (ratio[_token0][_token1], ratio[_token1][_token0]);

		(ratio[_token0][_token1], ratio[_token1][_token0]) = (_ratio0 - _amount0 , _ratio1 - _amount1);
	}

    /**
    * @dev get revserve of a token pair
    * @param _token address of the first token
    * @param _reserve the total liquidity of _token in the APM
    */
    function getReserve(address _token) external view returns(uint256 _reserve) {
        _reserve = reserve[_token];
    }

    /**
    * @dev get ratios of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _ratio01 ratio of token0: The amount of tokens _token0 in the pool (token0, token1)
    * @param _ratio10 ratio of token1: The amount of tokens _token1 in the pool (token0, token1)
    */
    function getRatios(address _token0, address _token1) external view returns(uint256 _ratio01, uint256 _ratio10) {
		return (ratio[_token0][_token1], ratio[_token1][_token0]);
	}

     /**
    * @dev get prices of a token pair
    * @param _token0 address of the first token
    * @param _token1 address of the second token
    * @param _price01 price: ratio[_token1] / ratio[_token0]
    * @param _price10 price: ratio[_token0] / ratio[_token1]
    */
    function getPrices(address _token0, address _token1) external view returns(uint256 _price01, uint256 _price10) {
		return (
            (ratio[_token1][_token0] / ratio[_token0][_token1]) * 1 ether,
            (ratio[_token0][_token1] / ratio[_token1][_token0]) * 1 ether
        );
	} 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}