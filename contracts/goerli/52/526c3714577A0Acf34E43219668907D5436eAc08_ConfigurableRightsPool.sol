// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "../base/Math.sol";
import "../base/Num.sol";

// Contract to wrap internal functions for testing

contract TMath is Math {
    function calc_btoi(uint a) external pure returns (uint) {
        return btoi(a);
    }

    function calc_bfloor(uint a) external pure returns (uint) {
        return bfloor(a);
    }

    function calc_badd(uint a, uint b) external pure returns (uint) {
        return badd(a, b);
    }

    function calc_bsub(uint a, uint b) external pure returns (uint) {
        return bsub(a, b);
    }

    function calc_bsubSign(uint a, uint b) external pure returns (uint, bool) {
        return bsubSign(a, b);
    }

    function calc_bmul(uint a, uint b) external pure returns (uint) {
        return bmul(a, b);
    }

    function calc_bdiv(uint a, uint b) external pure returns (uint) {
        return bdiv(a, b);
    }

    function calc_bpowi(uint a, uint n) external pure returns (uint) {
        return bpowi(a, n);
    }

    function calc_bpow(uint base, uint exp) external pure returns (uint) {
        return bpow(base, exp);
    }

    function calc_bpowApprox(
        uint base,
        uint exp,
        uint precision
    ) external pure returns (uint) {
        return bpowApprox(base, exp, precision);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import "./Num.sol";

contract Math is BBronze, Const, Num {
    /**********************************************************************************************
    // calcSpotPrice                                                                             //
    // sP = spotPrice                                                                            //
    // bI = tokenBalanceIn                ( bI / wI )         1                                  //
    // bO = tokenBalanceOut         sP =  -----------  *  ----------                             //
    // wI = tokenWeightIn                 ( bO / wO )     ( 1 - sF )                             //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcSpotPrice(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint swapFee
    ) public pure returns (uint spotPrice) {
        uint numer = bdiv(tokenBalanceIn, tokenWeightIn);
        uint denom = bdiv(tokenBalanceOut, tokenWeightOut);
        uint ratio = bdiv(numer, denom);
        uint scale = bdiv(BONE, bsub(BONE, swapFee));
        return (spotPrice = bmul(ratio, scale));
    }

    /**********************************************************************************************
    // calcOutGivenIn                                                                            //
    // aO = tokenAmountOut                                                                       //
    // bO = tokenBalanceOut                                                                      //
    // bI = tokenBalanceIn              /      /            bI             \    (wI / wO) \      //
    // aI = tokenAmountIn    aO = bO * |  1 - | --------------------------  | ^            |     //
    // wI = tokenWeightIn               \      \ ( bI + ( aI * ( 1 - sF )) /              /      //
    // wO = tokenWeightOut                                                                       //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcOutGivenIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountIn,
        uint swapFee
    ) public pure returns (uint tokenAmountOut) {
        uint weightRatio = bdiv(tokenWeightIn, tokenWeightOut);
        uint adjustedIn = bsub(BONE, swapFee);
        adjustedIn = bmul(tokenAmountIn, adjustedIn);
        uint y = bdiv(tokenBalanceIn, badd(tokenBalanceIn, adjustedIn));
        uint foo = bpow(y, weightRatio);
        uint bar = bsub(BONE, foo);
        tokenAmountOut = bmul(tokenBalanceOut, bar);
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcInGivenOut                                                                            //
    // aI = tokenAmountIn                                                                        //
    // bO = tokenBalanceOut               /  /     bO      \    (wO / wI)      \                 //
    // bI = tokenBalanceIn          bI * |  | ------------  | ^            - 1  |                //
    // aO = tokenAmountOut    aI =        \  \ ( bO - aO ) /                   /                 //
    // wI = tokenWeightIn           --------------------------------------------                 //
    // wO = tokenWeightOut                          ( 1 - sF )                                   //
    // sF = swapFee                                                                              //
    **********************************************************************************************/
    function calcInGivenOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint tokenAmountOut,
        uint swapFee
    ) public pure returns (uint tokenAmountIn) {
        uint weightRatio = bdiv(tokenWeightOut, tokenWeightIn);
        uint diff = bsub(tokenBalanceOut, tokenAmountOut);
        uint y = bdiv(tokenBalanceOut, diff);
        uint foo = bpow(y, weightRatio);
        foo = bsub(foo, BONE);
        tokenAmountIn = bsub(BONE, swapFee);
        tokenAmountIn = bdiv(bmul(tokenBalanceIn, foo), tokenAmountIn);
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcPoolOutGivenSingleIn                                                                  //
    // pAo = poolAmountOut         /                                              \              //
    // tAi = tokenAmountIn        ///      /     //    wI \      \\       \     wI \             //
    // wI = tokenWeightIn        //| tAi *| 1 - || 1 - --  | * sF || + tBi \    --  \            //
    // tW = totalWeight     pAo=||  \      \     \\    tW /      //         | ^ tW   | * pS - pS //
    // tBi = tokenBalanceIn      \\  ------------------------------------- /        /            //
    // pS = poolSupply            \\                    tBi               /        /             //
    // sF = swapFee                \                                              /              //
    **********************************************************************************************/
    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) public pure returns (uint poolAmountOut) {
        // Charge the trading fee for the proportion of tokenAi
        //  which is implicitly traded to the other pool tokens.
        // That proportion is (1- weightTokenIn)
        // tokenAiAfterFee = tAi * (1 - (1-weightTi) * poolFee);
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        uint tokenAmountInAfterFee = bmul(tokenAmountIn, bsub(BONE, zaz));

        uint newTokenBalanceIn = badd(tokenBalanceIn, tokenAmountInAfterFee);
        uint tokenInRatio = bdiv(newTokenBalanceIn, tokenBalanceIn);

        // uint newPoolSupply = (ratioTi ^ weightTi) * poolSupply;
        uint poolRatio = bpow(tokenInRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        poolAmountOut = bsub(newPoolSupply, poolSupply);
        return poolAmountOut;
    }

    /**********************************************************************************************
    // calcSingleInGivenPoolOut                                                                  //
    // tAi = tokenAmountIn              //(pS + pAo)\     /    1    \\                           //
    // pS = poolSupply                 || ---------  | ^ | --------- || * bI - bI                //
    // pAo = poolAmountOut              \\    pS    /     \(wI / tW)//                           //
    // bI = balanceIn          tAi =  --------------------------------------------               //
    // wI = weightIn                              /      wI  \                                   //
    // tW = totalWeight                          |  1 - ----  |  * sF                            //
    // sF = swapFee                               \      tW  /                                   //
    **********************************************************************************************/
    function calcSingleInGivenPoolOut(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountOut,
        uint swapFee
    ) public pure returns (uint tokenAmountIn) {
        uint normalizedWeight = bdiv(tokenWeightIn, totalWeight);
        uint newPoolSupply = badd(poolSupply, poolAmountOut);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        //uint newBalTi = poolRatio^(1/weightTi) * balTi;
        uint boo = bdiv(BONE, normalizedWeight);
        uint tokenInRatio = bpow(poolRatio, boo);
        uint newTokenBalanceIn = bmul(tokenInRatio, tokenBalanceIn);
        uint tokenAmountInAfterFee = bsub(newTokenBalanceIn, tokenBalanceIn);
        // Do reverse order of fees charged in joinswap_ExternAmountIn, this way
        //     ``` pAo == joinswap_ExternAmountIn(Ti, joinswap_PoolAmountOut(pAo, Ti)) ```
        //uint tAi = tAiAfterFee / (1 - (1-weightTi) * swapFee) ;
        uint zar = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountIn = bdiv(tokenAmountInAfterFee, bsub(BONE, zar));
        return tokenAmountIn;
    }

    /**********************************************************************************************
    // calcSingleOutGivenPoolIn                                                                  //
    // tAo = tokenAmountOut            /      /                                             \\   //
    // bO = tokenBalanceOut           /      // pS - (pAi * (1 - eF)) \     /    1    \      \\  //
    // pAi = poolAmountIn            | bO - || ----------------------- | ^ | --------- | * b0 || //
    // ps = poolSupply                \      \\          pS           /     \(wO / tW)/      //  //
    // wI = tokenWeightIn      tAo =   \      \                                             //   //
    // tW = totalWeight                    /     /      wO \       \                             //
    // sF = swapFee                    *  | 1 - |  1 - ---- | * sF  |                            //
    // eF = exitFee                        \     \      tW /       /                             //
    **********************************************************************************************/
    function calcSingleOutGivenPoolIn(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint poolAmountIn,
        uint swapFee
    ) public pure returns (uint tokenAmountOut) {
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        // charge exit fee on the pool token side
        // pAiAfterExitFee = pAi*(1-exitFee)
        uint poolAmountInAfterExitFee = bmul(poolAmountIn, bsub(BONE, EXIT_FEE));
        uint newPoolSupply = bsub(poolSupply, poolAmountInAfterExitFee);
        uint poolRatio = bdiv(newPoolSupply, poolSupply);

        // newBalTo = poolRatio^(1/weightTo) * balTo;
        uint tokenOutRatio = bpow(poolRatio, bdiv(BONE, normalizedWeight));
        uint newTokenBalanceOut = bmul(tokenOutRatio, tokenBalanceOut);

        uint tokenAmountOutBeforeSwapFee = bsub(tokenBalanceOut, newTokenBalanceOut);

        // charge swap fee on the output token side
        //uint tAo = tAoBeforeSwapFee * (1 - (1-weightTo) * swapFee)
        uint zaz = bmul(bsub(BONE, normalizedWeight), swapFee);
        tokenAmountOut = bmul(tokenAmountOutBeforeSwapFee, bsub(BONE, zaz));
        return tokenAmountOut;
    }

    /**********************************************************************************************
    // calcPoolInGivenSingleOut                                                                  //
    // pAi = poolAmountIn               // /               tAo             \\     / wO \     \   //
    // bO = tokenBalanceOut            // | bO - -------------------------- |\   | ---- |     \  //
    // tAo = tokenAmountOut      pS - ||   \     1 - ((1 - (tO / tW)) * sF)/  | ^ \ tW /  * pS | //
    // ps = poolSupply                 \\ -----------------------------------/                /  //
    // wO = tokenWeightOut  pAi =       \\               bO                 /                /   //
    // tW = totalWeight           -------------------------------------------------------------  //
    // sF = swapFee                                        ( 1 - eF )                            //
    // eF = exitFee                                                                              //
    **********************************************************************************************/
    function calcPoolInGivenSingleOut(
        uint tokenBalanceOut,
        uint tokenWeightOut,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountOut,
        uint swapFee
    ) public pure returns (uint poolAmountIn) {
        // charge swap fee on the output token side
        uint normalizedWeight = bdiv(tokenWeightOut, totalWeight);
        //uint tAoBeforeSwapFee = tAo / (1 - (1-weightTo) * swapFee) ;
        uint zoo = bsub(BONE, normalizedWeight);
        uint zar = bmul(zoo, swapFee);
        uint tokenAmountOutBeforeSwapFee = bdiv(tokenAmountOut, bsub(BONE, zar));

        uint newTokenBalanceOut = bsub(tokenBalanceOut, tokenAmountOutBeforeSwapFee);
        uint tokenOutRatio = bdiv(newTokenBalanceOut, tokenBalanceOut);

        //uint newPoolSupply = (ratioTo ^ weightTo) * poolSupply;
        uint poolRatio = bpow(tokenOutRatio, normalizedWeight);
        uint newPoolSupply = bmul(poolRatio, poolSupply);
        uint poolAmountInAfterExitFee = bsub(poolSupply, newPoolSupply);

        // charge exit fee on the pool token side
        // pAi = pAiAfterExitFee/(1-exitFee)
        poolAmountIn = bdiv(poolAmountInAfterExitFee, bsub(BONE, EXIT_FEE));
        return poolAmountIn;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./Const.sol";

// Core contract; can't be changed. So disable solhint (reminder for v2)

/* solhint-disable private-vars-leading-underscore */

contract Num is Const {
    function btoi(uint a) internal pure returns (uint) {
        return a / BONE;
    }

    function bfloor(uint a) internal pure returns (uint) {
        return btoi(a) * BONE;
    }

    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool flag) = bsubSign(a, b);
        require(!flag, "ERR_SUB_UNDERFLOW");
        return c;
    }

    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (a >= b) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    function bmul(uint a, uint b) internal pure returns (uint) {
        uint c0 = a * b;
        require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
        uint c1 = c0 + (BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / BONE;
        return c2;
    }

    function bdiv(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "ERR_DIV_ZERO");
        uint c0 = a * BONE;
        require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
        uint c1 = c0 + (b / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
        uint c2 = c1 / b;
        return c2;
    }

    // DSMath.wpow
    function bpowi(uint a, uint n) internal pure returns (uint) {
        uint z = n % 2 != 0 ? a : BONE;

        for (n /= 2; n != 0; n /= 2) {
            a = bmul(a, a);

            if (n % 2 != 0) {
                z = bmul(z, a);
            }
        }
        return z;
    }

    // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
    // Use `bpowi` for `b^e` and `bpowK` for k iterations
    // of approximation of b^0.w
    function bpow(uint base, uint exp) internal pure returns (uint) {
        require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
        require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

        uint whole = bfloor(exp);
        uint remain = bsub(exp, whole);

        uint wholePow = bpowi(base, btoi(whole));

        if (remain == 0) {
            return wholePow;
        }

        uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
        return bmul(wholePow, partialResult);
    }

    function bpowApprox(
        uint base,
        uint exp,
        uint precision
    ) internal pure returns (uint) {
        // term 0:
        uint a = exp;
        (uint x, bool xneg) = bsubSign(base, BONE);
        uint term = BONE;
        uint sum = term;
        bool negative = false;

        // term(k) = numer / denom
        //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
        // each iteration, multiply previous term by (a-(k-1)) * x / k
        // continue until term is less than precision
        for (uint i = 1; term >= precision; i++) {
            uint bigK = i * BONE;
            (uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
            term = bmul(term, bmul(c, x));
            term = bdiv(term, bigK);
            if (term == 0) break;

            if (xneg) negative = !negative;
            if (cneg) negative = !negative;
            if (negative) {
                sum = bsub(sum, term);
            } else {
                sum = badd(sum, term);
            }
        }

        return sum;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

import "./Color.sol";

contract Const is BBronze {
    uint public constant BONE = 10**18;

    uint public constant MIN_BOUND_TOKENS = 1;
    uint public constant MAX_BOUND_TOKENS = 16;

    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    uint public constant EXIT_FEE = 0;

    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = 0;

    uint public constant INIT_POOL_SUPPLY = BONE * 100;

    uint public constant MIN_BPOW_BASE = 1 wei;
    uint public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION = BONE / 10**10;

    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// abstract contract BColor {
//     function getColor()
//         external view virtual
//         returns (bytes32);
// }

contract BBronze {
    function getColor() external pure returns (bytes32) {
        return bytes32("BRONZE");
    }
}

pragma solidity 0.6.12;

import "../base/Num.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/AggregatorV2V3Interface.sol";
import "../interfaces/IUniswapOracle.sol";

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function abs(uint a, uint b) internal pure returns(uint result, bool isFirstBigger) {
        uint result;
        bool isFirstBigger;
        if(a > b){
            result = a - b;
            isFirstBigger = true;
        } else {
            result = b - a;
            isFirstBigger = false;
        }
    }
}

contract DesynChainlinkOracle is Num {
    address public admin;
    using SafeMath for uint;
    IUniswapOracle public twapOracle;
    mapping(address => uint) internal prices;
    mapping(bytes32 => AggregatorV2V3Interface) internal feeds;
    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);
    event NewAdmin(address oldAdmin, address newAdmin);
    event FeedSet(address feed, string symbol);

    constructor(address twapOracle_) public {
        admin = msg.sender;
        twapOracle = IUniswapOracle(twapOracle_);
    }

    function getPrice(address tokenAddress) public returns (uint price) {
        IERC20 token = IERC20(tokenAddress);
        AggregatorV2V3Interface feed = getFeed(token.symbol());
        if (prices[address(token)] != 0) {
            price = prices[address(token)];
        } else if (address(feed) != address(0)) {
            price = getChainlinkPrice(feed);
        } else {
            try twapOracle.update(address(token)) {} catch {}
            price = getUniswapPrice(tokenAddress);
        }

        (uint decimalDelta, bool isUnderFlow18) = uint(18).abs(uint(token.decimals()));

        if(isUnderFlow18){
            return price.mul(10**decimalDelta);
        }

        if(!isUnderFlow18){
            return price.div(10**decimalDelta);
        }
    }

    function getAllPrice(address[] calldata poolTokens, uint[] calldata actualAmountsOut) external returns (uint fundAll) {
        require(poolTokens.length == actualAmountsOut.length, "Invalid Length");
        
        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenAmountOut = actualAmountsOut[i];
            fundAll = badd(fundAll, bmul(getPrice(t), tokenAmountOut));
        }
    }

    function getChainlinkPrice(AggregatorV2V3Interface feed) internal view returns (uint) {
        // Chainlink USD-denominated feeds store answers at 8 decimals
        uint decimalDelta = bsub(uint(18), feed.decimals());
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return uint(feed.latestAnswer()).mul(10**decimalDelta);
        } else {
            return uint(feed.latestAnswer());
        }
    }

    function getUniswapPrice(address tokenAddress) internal view returns (uint) {
        IERC20 token = IERC20(tokenAddress);
        uint price = twapOracle.consult(tokenAddress, token.decimals());
        return price;
    }

    function setDirectPrice(address asset, uint price) external onlyAdmin {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function setFeed(string calldata symbol, address feed) external onlyAdmin {
        require(feed != address(0) && feed != address(this), "invalid feed address");
        emit FeedSet(feed, symbol);
        feeds[keccak256(abi.encodePacked(symbol))] = AggregatorV2V3Interface(feed);
    }

    function getFeed(string memory symbol) public view returns (AggregatorV2V3Interface) {
        return feeds[keccak256(abi.encodePacked(symbol))];
    }

    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        address oldAdmin = admin;
        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin may call");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the decimals of tokens
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

pragma solidity 0.6.12;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
    //
    // V2 Interface:
    //
    function latestAnswer() external view returns (int);

    function latestTimestamp() external view returns (uint);

    function latestRound() external view returns (uint);

    function getAnswer(uint roundId) external view returns (int);

    function getTimestamp(uint roundId) external view returns (uint);

    event AnswerUpdated(int indexed current, uint indexed roundId, uint timestamp);
    event NewRound(uint indexed roundId, address indexed startedBy, uint startedAt);

    //
    // V3 Interface:
    //
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int answer,
            uint startedAt,
            uint updatedAt,
            uint80 answeredInRound
        );
}

pragma solidity 0.6.12;

interface IUniswapOracle {
    function update(address token) external;

    function consult(address token, uint amountIn) external view returns (uint amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

// Imports

import "../interfaces/IERC20.sol";
import "../interfaces/IConfigurableRightsPool.sol";
import "../interfaces/IBFactory.sol"; // unused
import "./DesynSafeMath.sol"; // unused
import "./SafeApprove.sol";

/**
 * @author Desyn Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    using SafeApprove for IERC20;
    using DesynSafeMath for uint;

    //kol pool params
    struct levelParams {
        uint level;
        uint ratio;
    }

    struct feeParams {
        levelParams firstLevel;
        levelParams secondLevel;
        levelParams thirdLevel;
        levelParams fourLevel;
    }
    struct KolPoolParams {
        feeParams managerFee;
        feeParams issueFee;
        feeParams redeemFee;
        feeParams perfermanceFee;
    }

    // Type declarations
    enum Etypes {
        OPENED,
        CLOSED
    }

    enum Period {
        HALF,
        ONE,
        TWO
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */
    struct Status {
        uint collectPeriod;
        uint collectEndTime;
        uint closurePeriod;
        uint closureEndTime;
        uint upperCap;
        uint floorCap;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        uint startClaimFeeTime;
    }

    struct PoolParams {
        // Desyn Pool Token (representing shares of the pool)
        string poolTokenSymbol;
        string poolTokenName;
        // Tokens inside the Pool
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        Etypes etype;
    }

    struct PoolTokenRange {
        uint bspFloor;
        uint bspCap;
    }

    struct Fund {
        uint etfAmount;
        uint fundAmount;
    }

    function initRequire(
        uint swapFee,
        uint managerFee,
        uint issueFee,
        uint redeemFee,
        uint perfermanceFee,
        uint tokenBalancesLength,
        uint tokenWeightsLength,
        uint constituentTokensLength,
        bool initBool
    ) external pure {
        // We don't have a pool yet; check now or it will fail later (in order of likelihood to fail)
        // (and be unrecoverable if they don't have permission set to change it)
        // Most likely to fail, so check first
        require(!initBool, "Init fail");
        require(swapFee >= DesynConstants.MIN_FEE, "ERR_INVALID_SWAP_FEE");
        require(swapFee <= DesynConstants.MAX_FEE, "ERR_INVALID_SWAP_FEE");
        require(managerFee >= DesynConstants.MANAGER_MIN_FEE, "ERR_INVALID_MANAGER_FEE");
        require(managerFee <= DesynConstants.MANAGER_MAX_FEE, "ERR_INVALID_MANAGER_FEE");
        require(issueFee >= DesynConstants.ISSUE_MIN_FEE, "ERR_INVALID_ISSUE_MIN_FEE");
        require(issueFee <= DesynConstants.ISSUE_MAX_FEE, "ERR_INVALID_ISSUE_MAX_FEE");
        require(redeemFee >= DesynConstants.REDEEM_MIN_FEE, "ERR_INVALID_REDEEM_MIN_FEE");
        require(redeemFee <= DesynConstants.REDEEM_MAX_FEE, "ERR_INVALID_REDEEM_MAX_FEE");
        require(perfermanceFee >= DesynConstants.PERFERMANCE_MIN_FEE, "ERR_INVALID_PERFERMANCE_MIN_FEE");
        require(perfermanceFee <= DesynConstants.PERFERMANCE_MAX_FEE, "ERR_INVALID_PERFERMANCE_MAX_FEE");

        // Arrays must be parallel
        require(tokenBalancesLength == constituentTokensLength, "ERR_START_BALANCES_MISMATCH");
        require(tokenWeightsLength == constituentTokensLength, "ERR_START_WEIGHTS_MISMATCH");
        // Cannot have too many or too few - technically redundant, since BPool.bind() would fail later
        // But if we don't check now, we could have a useless contract with no way to create a pool

        require(constituentTokensLength >= DesynConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");
        require(constituentTokensLength <= DesynConstants.MAX_ASSET_LIMIT, "ERR_TOO_MANY_TOKENS");
        // There are further possible checks (e.g., if they use the same token twice), but
        // we can let bind() catch things like that (i.e., not things that might reasonably work)
    }

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenA - token to sell
     * @param tokenB - token to buy
     */
    function rebalance(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external {
        uint currentWeightA = bPool.getDenormalizedWeight(tokenA);
        uint currentBalanceA = bPool.getBalance(tokenA);
        // uint currentWeightB = bPool.getDenormalizedWeight(tokenB);

        require(deltaWeight <= currentWeightA, "ERR_DELTA_WEIGHT_TOO_BIG");

        // deltaBalance = currentBalance * (deltaWeight / currentWeight)
        uint deltaBalanceA = DesynSafeMath.bmul(currentBalanceA, DesynSafeMath.bdiv(deltaWeight, currentWeightA));

        // uint currentBalanceB = bPool.getBalance(tokenB);

        // uint deltaWeight = DesynSafeMath.bsub(newWeight, currentWeightA);

        // uint newWeightB = DesynSafeMath.bsub(currentWeightB, deltaWeight);
        // require(newWeightB >= 0, "ERR_INCORRECT_WEIGHT_B");
        bool soldout;
        if (deltaWeight == currentWeightA) {
            // reduct token A
            bPool.unbindPure(tokenA);
            soldout = true;
        }

        // Now with the tokens this contract can bind them to the pool it controls
        bPool.rebindSmart(tokenA, tokenB, deltaWeight, deltaBalanceA, soldout, minAmountOut);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
        }
    }

    function createPoolInternalHandle(IBPool bPool, uint initialSupply) external view {
        require(initialSupply >= DesynConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        require(initialSupply <= DesynConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");
        require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        require(DesynConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");
    }

    function createPoolHandle(
        uint collectPeriod,
        uint upperCap,
        uint initialSupply
    ) external pure {
        require(collectPeriod <= DesynConstants.MAX_COLLECT_PERIOD, "ERR_EXCEEDS_FUND_RAISING_PERIOD");
        require(upperCap >= initialSupply, "ERR_CAP_BIGGER_THAN_INITSUPPLY");
    }

    function exitPoolHandle(
        uint _endEtfAmount,
        uint _endFundAmount,
        uint _beginEtfAmount,
        uint _beginFundAmount,
        uint poolAmountIn,
        uint totalEnd
    )
        external
        pure
        returns (
            uint endEtfAmount,
            uint endFundAmount,
            uint profitRate
        )
    {
        endEtfAmount = DesynSafeMath.badd(_endEtfAmount, poolAmountIn);
        endFundAmount = DesynSafeMath.badd(_endFundAmount, totalEnd);
        uint amount1 = DesynSafeMath.bdiv(endFundAmount, endEtfAmount);
        uint amount2 = DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount);
        if (amount1 > amount2) {
            profitRate = DesynSafeMath.bdiv(
                DesynSafeMath.bmul(DesynSafeMath.bsub(DesynSafeMath.bdiv(endFundAmount, endEtfAmount), DesynSafeMath.bdiv(_beginFundAmount, _beginEtfAmount)), poolAmountIn),
                totalEnd
            );
        }
    }

    function exitPoolHandleA(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint _tokenAmountOut,
        uint redeemFee,
        uint profitRate,
        uint perfermanceFee
    )
        external
        returns (
            uint redeemAndPerformanceFeeReceived,
            uint finalAmountOut,
            uint redeemFeeReceived
        )
    {
        // redeem fee
        redeemFeeReceived = DesynSafeMath.bmul(_tokenAmountOut, redeemFee);

        // performance fee
        uint performanceFeeReceived = DesynSafeMath.bmul(DesynSafeMath.bmul(_tokenAmountOut, profitRate), perfermanceFee);
        
        // redeem fee and performance fee
        redeemAndPerformanceFeeReceived = DesynSafeMath.badd(performanceFeeReceived, redeemFeeReceived);

        // final amount the user got
        finalAmountOut = DesynSafeMath.bsub(_tokenAmountOut, redeemAndPerformanceFeeReceived);

        _pushUnderlying(bPool, poolToken, msg.sender, finalAmountOut);

        if (redeemFee != 0 || (profitRate > 0 && perfermanceFee != 0)) {
            _pushUnderlying(bPool, poolToken, address(this), redeemAndPerformanceFeeReceived);
            IERC20(poolToken).safeApprove(self.vaultAddress(), redeemAndPerformanceFeeReceived);
        }
    }

    function exitPoolHandleB(
        IConfigurableRightsPool self,
        bool bools,
        bool isCompletedCollect,
        uint closureEndTime,
        uint collectEndTime,
        uint _etfAmount,
        uint _fundAmount,
        uint poolAmountIn
    ) external view returns (uint etfAmount, uint fundAmount, uint actualPoolAmountIn) {
        actualPoolAmountIn = poolAmountIn;
        if (bools) {
            bool isCloseEtfCollectEndWithFailure = isCompletedCollect == false && block.timestamp >= collectEndTime;
            bool isCloseEtfClosureEnd = block.timestamp >= closureEndTime;
            require(isCloseEtfCollectEndWithFailure || isCloseEtfClosureEnd, "ERR_CLOSURE_TIME_NOT_ARRIVED!");

            actualPoolAmountIn = self.balanceOf(msg.sender);
        }
        fundAmount = _fundAmount;
        etfAmount = _etfAmount;
    }

    function joinPoolHandle(
        bool canWhitelistLPs,
        bool isList,
        bool bools,
        uint collectEndTime
    ) external view {
        require(!canWhitelistLPs || isList, "ERR_NOT_ON_WHITELIST");

        if (bools) {
            require(block.timestamp <= collectEndTime, "ERR_COLLECT_PERIOD_FINISHED!");
        }
    }

    function rebalanceHandle(
        IBPool bPool,
        bool isCompletedCollect,
        bool bools,
        uint collectEndTime,
        uint closureEndTime,
        bool canChangeWeights,
        address tokenA,
        address tokenB
    ) external {
        require(bPool.isBound(tokenA), "ERR_TOKEN_NOT_BOUND");
        if (bools) {
            require(isCompletedCollect, "ERROR_COLLECTION_FAILED");
            require(block.timestamp > collectEndTime && block.timestamp < closureEndTime, "ERR_NOT_REBALANCE_PERIOD");
        }

        if (!bPool.isBound(tokenB)) {
            bool returnValue = IERC20(tokenB).safeApprove(address(bPool), DesynConstants.MAX_UINT);
            require(returnValue, "ERR_ERC20_FALSE");
        }

        require(canChangeWeights, "ERR_NOT_CONFIGURABLE_WEIGHTS");
        require(tokenA != tokenB, "ERR_TOKENS_SAME");
    }

    /**
     * @notice Join a pool
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        uint issueFee
    ) external view returns (uint[] memory actualAmountsIn) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint ratio = DesynSafeMath.bdiv(poolAmountOut, DesynSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        uint issueFeeRate = issueFee.bmul(1000);
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint virtualTokenAmountIn = DesynSafeMath.bmul(ratio, DesynSafeMath.badd(bal, 1));
            uint base = bal.badd(1).bmul(poolAmountOut * uint(1000));
            uint tokenAmountIn = base.bdiv(poolTotal.bsub(1) * (uint(1000).bsub(issueFeeRate)));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - ConfigurableRightsPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint poolAmountIn,
        uint[] calldata minAmountsOut
    ) external view returns (uint[] memory actualAmountsOut) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint poolTotal = self.totalSupply();

        uint ratio = DesynSafeMath.bdiv(poolAmountIn, DesynSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint tokenAmountOut = DesynSafeMath.bmul(ratio, DesynSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    // Internal functions
    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }

    function handleTransferInTokens(
        IConfigurableRightsPool self,
        IBPool bPool,
        address poolToken,
        uint actualAmountIn,
        uint _actualIssueFee
    ) external returns (uint issueFeeReceived) {
        issueFeeReceived = DesynSafeMath.bmul(actualAmountIn, _actualIssueFee);
        uint amount = DesynSafeMath.bsub(actualAmountIn, issueFeeReceived);

        _pullUnderlying(bPool, poolToken, msg.sender, amount);

        if (_actualIssueFee != 0) {
            bool xfer = IERC20(poolToken).transferFrom(msg.sender, address(this), issueFeeReceived);
            require(xfer, "ERR_ERC20_FALSE");

            IERC20(poolToken).safeApprove(self.vaultAddress(), issueFeeReceived);
        }
    }

    function handleClaim(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint managerFee,
        uint time
    ) external returns (uint[] memory tokensAmount) {
        for (uint i = 0; i < poolTokens.length; i++) {
            address t = poolTokens[i];
            uint tokenBalance = bPool.getBalance(t);
            uint tokenAmountOut = DesynSafeMath.bmul(tokenBalance, (managerFee * time) / 12);
            _pushUnderlying(bPool, t, msg.sender, tokenAmountOut);

            IERC20(t).safeApprove(self.vaultAddress(), tokenAmountOut);
            tokensAmount[i] = tokenAmountOut;
        }
    }

    function handleCollectionCompleted(
        IConfigurableRightsPool self,
        IBPool bPool,
        address[] calldata poolTokens,
        uint issueFee
    ) external {
        if (issueFee != 0) {
            uint[] memory tokensAmount = new uint[](poolTokens.length);

            for (uint i = 0; i < poolTokens.length; i++) {
                address t = poolTokens[i];
                uint currentAmount = bPool.getBalance(t);
                uint currentAmountFee = DesynSafeMath.bmul(currentAmount, issueFee);

                _pushUnderlying(bPool, t, address(this), currentAmountFee);
                tokensAmount[i] = currentAmountFee;
                IERC20(t).safeApprove(self.vaultAddress(), currentAmountFee);
            }

            IVault(self.vaultAddress()).depositIssueRedeemPToken(poolTokens, tokensAmount, tokensAmount, false);
        }
    }

    function WhitelistHandle(
        bool bool1,
        bool bool2,
        address adr
    ) external pure {
        require(bool1, "ERR_CANNOT_WHITELIST_LPS");
        require(bool2, "ERR_LP_NOT_WHITELISTED");
        require(adr != address(0), "ERR_INVALID_ADDRESS");
    }

    function _pullUnderlying(
        IBPool bPool,
        address erc20,
        address from,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, DesynSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    function _pushUnderlying(
        IBPool bPool,
        address erc20,
        address to,
        uint amount
    ) internal {
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, DesynSafeMath.bsub(tokenBalance, amount), tokenWeight);

        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

// Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
// Removing circularity allows flattener tools to work, which enables Etherscan verification
interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint amount) external;

    function pushPoolShareFromLib(address to, uint amount) external;

    function pullPoolShareFromLib(address from, uint amount) external;

    function burnPoolShareFromLib(uint amount) external;

    function balanceOf(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

    function getController() external view returns (address);

    function vaultAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../libraries/SmartPoolManager.sol";

interface IBPool {
    function rebind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function rebindSmart(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint deltaBalance,
        bool isSoldout,
        uint minAmountOut
    ) external;

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external returns (bytes memory _returnValue);

    function bind(
        address token,
        uint balance,
        uint denorm
    ) external;

    function unbind(address token) external;

    function unbindPure(address token) external;

    function isBound(address token) external view returns (bool);

    function getBalance(address token) external view returns (uint);

    function totalSupply() external view returns (uint);

    function getSwapFee() external view returns (uint);

    function isPublicSwap() external view returns (bool);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function EXIT_FEE() external view returns (uint);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function setController(address owner) external;
}

interface IBFactory {
    function newLiquidityPool() external returns (IBPool);

    function setBLabs(address b) external;

    function collect(IBPool pool) external;

    function isBPool(address b) external view returns (bool);

    function getBLabs() external view returns (address);

    function getSwapRouter() external view returns (address);

    function getVault() external view returns (address);

    function getUserVault() external view returns (address);

    function getVaultAddress() external view returns (address);

    function getOracleAddress() external view returns (address);

    function getManagerOwner() external view returns (address);

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool);

    function isTokenWhitelistedForVerify(address token) external view returns (bool);

    function getModuleStatus(address etf, address module) external view returns (bool);

    function isPaused() external view returns (bool);
}

interface IVault {
    function depositManagerToken(address[] calldata poolTokens, uint[] calldata tokensAmount) external;

    function depositIssueRedeemPToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountP,
        bool isPerfermance
    ) external;

    function managerClaim(address pool) external;

    function getManagerClaimBool(address pool) external view returns (bool);
}

interface IUserVault {
    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface Oracles {
    function getPrice(address tokenAddress) external returns (uint price);

    function getAllPrice(address[] calldata poolTokens, uint[] calldata tokensAmount) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "./DesynConstants.sol";

/**
 * @author Desyn Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library DesynSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint a, uint b) internal pure returns (uint) {
        (uint c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint c1 = c0 + (DesynConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint c2 = c1 / DesynConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0) {
            return 0;
        }

        uint c0 = dividend * DesynConstants.BONE;
        require(c0 / dividend == DesynConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint dividend, uint divisor) internal pure returns (uint) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint a, uint b) internal pure returns (uint) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "../interfaces/IERC20.sol";

// Libraries

/**
 * @author PieDAO (ported to Desyn Labs)
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice handle approvals of tokens that require approving from a base of 0
     * @param token - the token we're approving
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint amount
    ) internal returns (bool) {
        uint currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @author Desyn Labs
 * @title Put all the constants in one place
 */

library DesynConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint public constant BONE = 10**18;
    uint public constant MIN_WEIGHT = BONE;
    uint public constant MAX_WEIGHT = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint public constant MIN_BALANCE = 0;
    uint public constant MAX_BALANCE = BONE * 10**12;
    uint public constant MIN_POOL_SUPPLY = BONE * 100;
    uint public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint public constant MIN_FEE = BONE / 10**6;
    uint public constant MAX_FEE = BONE / 10;
    //Fee Set
    uint public constant MANAGER_MIN_FEE = 0;
    uint public constant MANAGER_MAX_FEE = BONE / 10;
    uint public constant ISSUE_MIN_FEE = BONE / 1000;
    uint public constant ISSUE_MAX_FEE = BONE / 10;
    uint public constant REDEEM_MIN_FEE = 0;
    uint public constant REDEEM_MAX_FEE = BONE / 10;
    uint public constant PERFERMANCE_MIN_FEE = 0;
    uint public constant PERFERMANCE_MAX_FEE = BONE / 2;
    // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
    uint public constant EXIT_FEE = 0;
    uint public constant MAX_IN_RATIO = BONE / 2;
    uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint public constant MIN_ASSET_LIMIT = 1;
    uint public constant MAX_ASSET_LIMIT = 16;
    uint public constant MAX_UINT = uint(-1);
    uint public constant MAX_COLLECT_PERIOD = 60 days;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
// Needed to handle structures externally
pragma experimental ABIEncoderV2;

import "./PCToken.sol";
import "../utils/DesynReentrancyGuard.sol";
import "../utils/DesynOwnable.sol";
import "../interfaces/IBFactory.sol";
import {RightsManager} from "../libraries/RightsManager.sol";
import "../libraries/SmartPoolManager.sol";
import "../libraries/SafeApprove.sol";
import "./WhiteToken.sol";

/**
 * @author Desyn Labs
 * @title Smart Pool with customizable features
 * @notice PCToken is the "Desyn Smart Pool" token (transferred upon finalization)
 * @dev Rights are defined as follows (index values into the array)
 * Note that functions called on bPool and bFactory may look like internal calls,
 *   but since they are contracts accessed through an interface, they are really external.
 * To make this explicit, we could write "IBPool(address(bPool)).function()" everywhere,
 *   instead of "bPool.function()".
 */
contract ConfigurableRightsPool is PCToken, DesynOwnable, DesynReentrancyGuard, WhiteToken {
    using DesynSafeMath for uint;
    using SafeApprove for IERC20;

    // State variables
    IBFactory public bFactory;
    IBPool public bPool;

    // Struct holding the rights configuration
    RightsManager.Rights public rights;

    SmartPoolManager.Status public etfStatus;

    // Fee is initialized on creation, and can be changed if permission is set
    // Only needed for temporary storage between construction and createPool
    // Thereafter, the swap fee should always be read from the underlying pool
    uint private _initialSwapFee;

    // Store the list of tokens in the pool, and balances
    // NOTE that the token list is *only* used to store the pool tokens between
    //   construction and createPool - thereafter, use the underlying BPool's list
    //   (avoids synchronization issues)
    address[] private _initialTokens;
    uint[] private _initialBalances;
    uint[] private _initialWeights;

    // Whitelist of LPs (if configured)
    mapping(address => bool) private _liquidityProviderWhitelist;

    // Cap on the pool size (i.e., # of tokens minted when joining)
    // Limits the risk of experimental pools; failsafe/backup for fixed-size pools
    // uint public claimPeriod = 60 * 60 * 24 * 30;
    uint public claimPeriod = 30 minutes;

    address public vaultAddress;
    address public oracleAddress;

    bool hasSetWhiteTokens;
    bool public initBool;
    bool public isCompletedCollect;

    mapping(address => SmartPoolManager.Fund) public beginFund;
    mapping(address => SmartPoolManager.Fund) public endFund;
    SmartPoolManager.Etypes public etype;

    // Event declarations
    // Anonymous logger event - can only be filtered by contract address
    event LogCall(bytes4 indexed sig, address indexed caller, bytes data) anonymous;
    event LogJoin(address indexed caller, address indexed tokenIn, uint tokenAmountIn);
    event LogExit(address indexed caller, address indexed tokenOut, uint tokenAmountOut);
    event sizeChanged(address indexed caller, string indexed sizeType, uint oldSize, uint newSize);
    // event FloorChanged(address indexed caller, uint oldFloor, uint newFloor);
    // event setRangeOfToken(address indexed caller, address pool, address token, uint floor, uint cap);
    event SetManagerFee(uint indexed managerFee, uint indexed issueFee, uint indexed redeemFee, uint perfermanceFee);
    // event CloseETFColletdCompleted(address indexed caller, address indexed pool, uint monent);

    // Modifiers
    modifier onlyManager() {
        require(bFactory.getManagerOwner() == msg.sender, "OwnableN");
        _;
    }

    // Modifiers
    modifier logs() {
        emit LogCall(msg.sig, msg.sender, msg.data);
        _;
    }

    // Mark functions that require delegation to the underlying Pool
    modifier needsBPool() {
        require(address(bPool) != address(0), "ERR_NOT_CREATED");
        _;
    }

    modifier notPaused() {
        require(!bFactory.isPaused(), "!paused");
        _;
    }

    // modifier lockUnderlyingPool() {
    //     // Turn off swapping on the underlying pool during joins
    //     // Otherwise tokens with callbacks would enable attacks involving simultaneous swaps and joins
    //     bool origSwapState = bPool.isPublicSwap();
    //     bPool.setPublicSwap(false);
    //     _;
    //     bPool.setPublicSwap(origSwapState);
    // }

    constructor(string memory tokenSymbol, string memory tokenName) public PCToken(tokenSymbol, tokenName) {}

    /**
     * @notice Construct a new Configurable Rights Pool (wrapper around BPool)
     * @dev _initialTokens and _swapFee are only used for temporary storage between construction
     *      and create pool, and should not be used thereafter! _initialTokens is destroyed in
     *      createPool to prevent this, and _swapFee is kept in sync (defensively), but
     *      should never be used except in this constructor and createPool()
     * @param factoryAddress - the BPoolFactory used to create the underlying pool
     * @param poolParams - struct containing pool parameters
     * @param rightsStruct - Set of permissions we are assigning to this smart pool
     */

    function init(
        address factoryAddress,
        SmartPoolManager.PoolParams memory poolParams,
        RightsManager.Rights memory rightsStruct
    ) public {
        SmartPoolManager.initRequire(
            poolParams.swapFee,
            poolParams.managerFee,
            poolParams.issueFee,
            poolParams.redeemFee,
            poolParams.perfermanceFee,
            poolParams.tokenBalances.length,
            poolParams.tokenWeights.length,
            poolParams.constituentTokens.length,
            initBool
        );
        initBool = true;
        rights = rightsStruct;
        _initialTokens = poolParams.constituentTokens;
        _initialBalances = poolParams.tokenBalances;
        _initialWeights = poolParams.tokenWeights;

        etfStatus = SmartPoolManager.Status({
            collectPeriod: 0,
            collectEndTime: 0,
            closurePeriod: 0,
            closureEndTime: 0,
            upperCap: DesynConstants.MAX_UINT,
            floorCap: 0,
            managerFee: poolParams.managerFee,
            redeemFee: poolParams.redeemFee,
            issueFee: poolParams.issueFee,
            perfermanceFee: poolParams.perfermanceFee,
            startClaimFeeTime: block.timestamp
        });

        etype = poolParams.etype;

        bFactory = IBFactory(factoryAddress);
        oracleAddress = bFactory.getOracleAddress();
        vaultAddress = bFactory.getVault();
        emit SetManagerFee(etfStatus.managerFee, etfStatus.issueFee, etfStatus.redeemFee, etfStatus.perfermanceFee);
    }

    /**
     * @notice Set the cap (max # of pool tokens)
     * @dev _bspCap defaults in the constructor to unlimited
     *      Can set to 0 (or anywhere below the current supply), to halt new investment
     *      Prevent setting it before creating a pool, since createPool sets to intialSupply
     *      (it does this to avoid an unlimited cap window between construction and createPool)
     *      Therefore setting it before then has no effect, so should not be allowed
     * @param newCap - new value of the cap
     */
    function setCap(uint newCap) external logs lock needsBPool onlyOwner {
        require(etype == SmartPoolManager.Etypes.OPENED, "ERR_MUST_OPEN_ETF");
        // emit CapChanged(msg.sender, etfStatus.upperCap, newCap);
        emit sizeChanged(msg.sender, "UPPER", etfStatus.upperCap, newCap);
        etfStatus.upperCap = newCap;
    }

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external logs lock needsBPool returns (bytes memory _returnValue) {
        require(bFactory.getModuleStatus(address(this), msg.sender), "MODULE IS NOT REGISTER");

        _returnValue = bPool.execute(_target, _value, _data);
    }

    function claimManagerFee() external virtual logs lock onlyManager needsBPool {
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            require(isCompletedCollect, "Collection failed!");
        }
        uint lastClaimTime = DesynSafeMath.bsub(block.timestamp, etfStatus.startClaimFeeTime);
        require(lastClaimTime >= claimPeriod, "The collection cycle is not reached");
        uint time = lastClaimTime / claimPeriod;
        address[] memory poolTokens = bPool.getCurrentTokens();
        uint[] memory tokensAmount = SmartPoolManager.handleClaim(IConfigurableRightsPool(address(this)), bPool, poolTokens, etfStatus.managerFee, time);
        IVault(vaultAddress).depositManagerToken(poolTokens, tokensAmount);
        etfStatus.startClaimFeeTime = etfStatus.startClaimFeeTime + time * claimPeriod;
    }

    /**
     * @notice Create a new Smart Pool
     * @dev Delegates to internal function
     * @param initialSupply starting token balance
     * @param closurePeriod the etf closure period
     */
    function createPool(
        uint initialSupply,
        uint collectPeriod,
        SmartPoolManager.Period closurePeriod,
        SmartPoolManager.PoolTokenRange memory tokenRange
    ) external virtual onlyOwner logs lock notPaused {
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            // require(collectPeriod <= DesynConstants.MAX_COLLECT_PERIOD, "ERR_EXCEEDS_FUND_RAISING_PERIOD");
            // require(etfStatus.upperCap >= initialSupply, "ERR_CAP_BIGGER_THAN_INITSUPPLY");
            SmartPoolManager.createPoolHandle(collectPeriod, etfStatus.upperCap, initialSupply);

            uint oldCap = etfStatus.upperCap;
            uint oldFloor = etfStatus.floorCap;
            etfStatus.upperCap = initialSupply.bmul(tokenRange.bspCap).bdiv(_initialBalances[0]);
            etfStatus.floorCap = initialSupply.bmul(tokenRange.bspFloor).bdiv(_initialBalances[0]);
            emit sizeChanged(msg.sender, "UPPER", oldCap, etfStatus.upperCap);
            emit sizeChanged(msg.sender, "FLOOR", oldFloor, etfStatus.floorCap);

            uint period;
            uint collectEndTime = block.timestamp + collectPeriod;
            if (closurePeriod == SmartPoolManager.Period.HALF) {
                // TODO
                period = 1 hours;
                // period = 1 seconds; // TEST CONFIG：for test only
            } else if (closurePeriod == SmartPoolManager.Period.ONE) {
                period = 180 days;
            } else {
                period = 360 days;
            }
            uint closureEndTime = collectEndTime + period;
            //   (uint period,uint collectEndTime,uint closureEndTime) = SmartPoolManager.createPoolHandle(collectPeriod, closurePeriod == Period.HALF, closurePeriod == Period.ONE);

            // etfStatus = SmartPoolManager.Status(collectPeriod, collectEndTime, period, closureEndTime);
            etfStatus.collectPeriod = collectPeriod;
            etfStatus.collectEndTime = collectEndTime;
            etfStatus.closurePeriod = period;
            etfStatus.closureEndTime = closureEndTime;

            // _addPoolRangeConfig(poolRange);

            uint totalBegin = Oracles(oracleAddress).getAllPrice(_initialTokens, _initialBalances);
            IUserVault(bFactory.getUserVault()).recordTokenInfo(msg.sender, msg.sender, _initialTokens, _initialBalances);
            if (totalBegin > 0) {
                SmartPoolManager.Fund storage fund = beginFund[msg.sender];
                fund.etfAmount = initialSupply;
                fund.fundAmount = totalBegin;
            }
        }

        createPoolInternal(initialSupply);
    }

    function rebalance(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external virtual logs lock onlyAdmin needsBPool notPaused {
        SmartPoolManager.rebalanceHandle(bPool, isCompletedCollect, etype == SmartPoolManager.Etypes.CLOSED, etfStatus.collectEndTime, etfStatus.closureEndTime, rights.canChangeWeights, tokenA, tokenB);

        _verifyWhiteToken(tokenB);
        bool bools = IVault(vaultAddress).getManagerClaimBool(address(this));
        if (bools) {
            IVault(vaultAddress).managerClaim(address(this));
        }

        // Delegate to library to save space
        SmartPoolManager.rebalance(IConfigurableRightsPool(address(this)), bPool, tokenA, tokenB, deltaWeight, minAmountOut);
    }

    /**
     * @notice Join a pool
     * @dev Emits a LogJoin event (for each token)
     *      bPool is a contract interface; function calls on it are external
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     */
    function joinPool(
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        address kol
    ) external logs lock needsBPool notPaused {
        SmartPoolManager.joinPoolHandle(rights.canWhitelistLPs, _liquidityProviderWhitelist[msg.sender], etype == SmartPoolManager.Etypes.CLOSED, etfStatus.collectEndTime);
        
        if(rights.canTokenWhiteLists) {
            require(_initWhiteTokenState(),"ERR_SHOULD_SET_WHITETOKEN");
        }
        // Delegate to library to save space

        // Library computes actualAmountsIn, and does many validations
        // Cannot call the push/pull/min from an external library for
        // any of these pool functions. Since msg.sender can be anybody,
        // they must be internal
        uint[] memory actualAmountsIn = SmartPoolManager.joinPool(IConfigurableRightsPool(address(this)), bPool, poolAmountOut, maxAmountsIn, etfStatus.issueFee);

        // After createPool, token list is maintained in the underlying BPool
        address[] memory poolTokens = bPool.getCurrentTokens();
        uint[] memory issueFeesReceived = new uint[](poolTokens.length);

        uint totalBegin;
        uint _actualIssueFee = etfStatus.issueFee;
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            totalBegin = Oracles(oracleAddress).getAllPrice(poolTokens, actualAmountsIn);
            IUserVault(bFactory.getUserVault()).recordTokenInfo(kol, msg.sender, poolTokens, actualAmountsIn);
            if (isCompletedCollect == false) {
                _actualIssueFee = 0;
            }
        }

        for (uint i = 0; i < poolTokens.length; i++) {
            uint issueFeeReceived = SmartPoolManager.handleTransferInTokens(
                IConfigurableRightsPool(address(this)),
                bPool,
                poolTokens[i],
                actualAmountsIn[i],
                _actualIssueFee
            );

            emit LogJoin(msg.sender, poolTokens[i], actualAmountsIn[i]);
            issueFeesReceived[i] = issueFeeReceived;
        }

        if (_actualIssueFee != 0) {
            IVault(vaultAddress).depositIssueRedeemPToken(poolTokens, issueFeesReceived, issueFeesReceived, false);
        }
        // uint actualPoolAmountOut = DesynSafeMath.bsub(poolAmountOut, DesynSafeMath.bmul(poolAmountOut, etfStatus.issueFee));
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
        if (totalBegin > 0) {
            SmartPoolManager.Fund storage fund = beginFund[msg.sender];
            fund.etfAmount = DesynSafeMath.badd(beginFund[msg.sender].etfAmount, poolAmountOut);
            fund.fundAmount = DesynSafeMath.badd(beginFund[msg.sender].fundAmount, totalBegin);
        }

        // checkout the state that elose ETF collect completed and claime fee.
        bool isCompletedMoment = etype == SmartPoolManager.Etypes.CLOSED && this.totalSupply() >= etfStatus.floorCap && isCompletedCollect == false;
        if (isCompletedMoment) {
            isCompletedCollect = true;
            SmartPoolManager.handleCollectionCompleted(
                IConfigurableRightsPool(address(this)), bPool,
                poolTokens,
                etfStatus.issueFee
            );
        }
    }

    // @notice Claime issueFee fee when close ETF collect completed moment.
    // function _closeEtfCollectCompletedToClaimeIssueFee() internal {
    //     if (etfStatus.issueFee != 0) {
    //         address[] memory poolTokens = bPool.getCurrentTokens(); // get all token
    //         uint[] memory tokensAmount = new uint[](poolTokens.length); // all amount temp

    //         for (uint i = 0; i < poolTokens.length; i++) {
    //             address t = poolTokens[i];
    //             uint currentAmount = bPool.getBalance(t);
    //             uint currentAmountFee = DesynSafeMath.bmul(currentAmount, etfStatus.issueFee);

    //             _pushUnderlying(t, address(this), currentAmountFee);
    //             tokensAmount[i] = currentAmountFee;
    //             IERC20(t).safeApprove(vaultAddress, currentAmountFee);
    //         }

    //         IVault(vaultAddress).depositIssueRedeemPToken(poolTokens, tokensAmount, tokensAmount, false);
    //     }
    // }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @dev Emits a LogExit event for each token
     *      bPool is a contract interface; function calls on it are external
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     */
    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external logs lock needsBPool notPaused {
        uint actualPoolAmountIn;
        (beginFund[msg.sender].etfAmount, beginFund[msg.sender].fundAmount, actualPoolAmountIn) = SmartPoolManager.exitPoolHandleB(
            IConfigurableRightsPool(address(this)),
            etype == SmartPoolManager.Etypes.CLOSED,
            isCompletedCollect,
            etfStatus.closureEndTime,
            etfStatus.collectEndTime,
            beginFund[msg.sender].etfAmount,
            beginFund[msg.sender].fundAmount,
            poolAmountIn
        );
        // Library computes actualAmountsOut, and does many validations
        uint[] memory actualAmountsOut = SmartPoolManager.exitPool(IConfigurableRightsPool(address(this)), bPool, actualPoolAmountIn, minAmountsOut);
        _pullPoolShare(msg.sender, actualPoolAmountIn);
        _burnPoolShare(actualPoolAmountIn);

        // After createPool, token list is maintained in the underlying BPool
        address[] memory poolTokens = bPool.getCurrentTokens();
        uint[] memory redeemAndPerformanceFeesReceived = new uint[](poolTokens.length);
        //perfermance fee
        uint totalEnd;
        uint profitRate;
        if (etype == SmartPoolManager.Etypes.CLOSED && block.timestamp >= etfStatus.closureEndTime) {
            totalEnd = Oracles(oracleAddress).getAllPrice(poolTokens, actualAmountsOut);
        }

        uint _actualRedeemFee = etfStatus.redeemFee;
        if (etype == SmartPoolManager.Etypes.CLOSED) {
            bool isCloseEtfCollectEndWithFailure = isCompletedCollect == false && block.timestamp >= etfStatus.collectEndTime;
            if (isCloseEtfCollectEndWithFailure) {
                _actualRedeemFee = 0;
            }
        }

        if (totalEnd > 0) {
            uint _poolAmountIn = actualPoolAmountIn;
            (endFund[msg.sender].etfAmount, endFund[msg.sender].fundAmount, profitRate) = SmartPoolManager.exitPoolHandle(
                endFund[msg.sender].etfAmount,
                endFund[msg.sender].fundAmount,
                beginFund[msg.sender].etfAmount,
                beginFund[msg.sender].fundAmount,
                _poolAmountIn,
                totalEnd
            );
        }
        uint[] memory redeemFeesReceived = new uint[](poolTokens.length);
        for (uint i = 0; i < poolTokens.length; i++) {
            (uint redeemAndPerformanceFeeReceived, uint finalAmountOut, uint redeemFeeReceived) = SmartPoolManager.exitPoolHandleA(
                IConfigurableRightsPool(address(this)),
                bPool,
                poolTokens[i],
                actualAmountsOut[i],
                _actualRedeemFee,
                profitRate,
                etfStatus.perfermanceFee
            );
            redeemFeesReceived[i] = redeemFeeReceived;
            redeemAndPerformanceFeesReceived[i] = redeemAndPerformanceFeeReceived;

            emit LogExit(msg.sender, poolTokens[i], finalAmountOut);
            // _pushUnderlying(t, msg.sender, finalAmountOut);

            // if (_actualRedeemFee != 0 || (profitRate > 0 && etfStatus.perfermanceFee != 0)) {
            //     _pushUnderlying(t, address(this), redeemAndPerformanceFeeReceived);
            //     IERC20(t).safeApprove(vaultAddress, redeemAndPerformanceFeeReceived);
            //     redeemAndPerformanceFeesReceived[i] = redeemAndPerformanceFeeReceived;
            // }
        }

        if (_actualRedeemFee != 0 || (profitRate > 0 && etfStatus.perfermanceFee != 0)) {
            IVault(vaultAddress).depositIssueRedeemPToken(poolTokens, redeemAndPerformanceFeesReceived, redeemFeesReceived, true);
        }
    }

    /**
     * @notice Add to the whitelist of liquidity providers (if enabled)
     * @param provider - address of the liquidity provider
     */
    function whitelistLiquidityProvider(address provider) external onlyOwner lock logs {
        SmartPoolManager.WhitelistHandle(rights.canWhitelistLPs, true, provider);
        //  require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        // require(provider != address(0), "ERR_INVALID_ADDRESS");
        _liquidityProviderWhitelist[provider] = true;
    }

    /**
     * @notice Remove from the whitelist of liquidity providers (if enabled)
     * @param provider - address of the liquidity provider
     */
    function removeWhitelistedLiquidityProvider(address provider) external onlyOwner lock logs {
        SmartPoolManager.WhitelistHandle(rights.canWhitelistLPs, _liquidityProviderWhitelist[provider], provider);
        //  require(rights.canWhitelistLPs, "ERR_CANNOT_WHITELIST_LPS");
        // require(_liquidityProviderWhitelist[provider], "ERR_LP_NOT_WHITELISTED");
        // require(provider != address(0), "ERR_INVALID_ADDRESS");
        _liquidityProviderWhitelist[provider] = false;
    }

    /**
     * @notice Check if an address is a liquidity provider
     * @dev If the whitelist feature is not enabled, anyone can provide liquidity (assuming finalized)
     * @return boolean value indicating whether the address can join a pool
     */
    function canProvideLiquidity(address provider) external view returns (bool) {
        if (rights.canWhitelistLPs) {
            return _liquidityProviderWhitelist[provider];
        } else {
            // Probably don't strictly need this (could just return true)
            // But the null address can't provide funds
            return provider != address(0);
        }
    }

    /**
     * @notice Getter for specific permissions
     * @dev value of the enum is just the 0-based index in the enumeration
     *      For instance canPauseSwapping is 0; canChangeWeights is 2
     * @return token boolean true if we have the given permission
     */
    function hasPermission(RightsManager.Permissions permission) external view virtual returns (bool) {
        return RightsManager.hasPermission(rights, permission);
    }

    /**
     * @notice Getter for the RightsManager contract
     * @dev Convenience function to get the address of the RightsManager library (so clients can check version)
     * @return address of the RightsManager library
     */
    function getRightsManagerVersion() external pure returns (address) {
        return address(RightsManager);
    }

    /**
     * @notice Getter for the DesynSafeMath contract
     * @dev Convenience function to get the address of the DesynSafeMath library (so clients can check version)
     * @return address of the DesynSafeMath library
     */
    function getDesynSafeMathVersion() external pure returns (address) {
        return address(DesynSafeMath);
    }

    /**
     * @notice Getter for the SmartPoolManager contract
     * @dev Convenience function to get the address of the SmartPoolManager library (so clients can check version)
     * @return address of the SmartPoolManager library
     */
    function getSmartPoolManagerVersion() external pure returns (address) {
        return address(SmartPoolManager);
    }

    // "Public" versions that can safely be called from SmartPoolManager
    // Allows only the contract itself to call them (not the controller or any external account)

    function mintPoolShareFromLib(uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _mint(amount);
    }

    function pushPoolShareFromLib(address to, uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _push(to, amount);
    }

    function pullPoolShareFromLib(address from, uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _pull(from, amount);
    }

    function burnPoolShareFromLib(uint amount) public {
        require(msg.sender == address(this), "ERR_NOT_CONTROLLER");

        _burn(amount);
    }

    /**
     * @notice Create a new Smart Pool
     * @dev Initialize the swap fee to the value provided in the CRP constructor
     *      Can be changed if the canChangeSwapFee permission is enabled
     * @param initialSupply starting token balance
     */
    function createPoolInternal(uint initialSupply) internal {
        require(address(bPool) == address(0), "ERR_IS_CREATED");
        // require(initialSupply >= DesynConstants.MIN_POOL_SUPPLY, "ERR_INIT_SUPPLY_MIN");
        // require(initialSupply <= DesynConstants.MAX_POOL_SUPPLY, "ERR_INIT_SUPPLY_MAX");

        // require(DesynConstants.EXIT_FEE == 0, "ERR_NONZERO_EXIT_FEE");

        // To the extent possible, modify state variables before calling functions
        _mintPoolShare(initialSupply);
        _pushPoolShare(msg.sender, initialSupply);

        // Deploy new BPool (bFactory and bPool are interfaces; all calls are external)
        bPool = bFactory.newLiquidityPool();
        // EXIT_FEE must always be zero, or ConfigurableRightsPool._pushUnderlying will fail
        //   require(bPool.EXIT_FEE() == 0, "ERR_NONZERO_EXIT_FEE");
        SmartPoolManager.createPoolInternalHandle(bPool, initialSupply);
        for (uint i = 0; i < _initialTokens.length; i++) {
            address t = _initialTokens[i];
            uint bal = _initialBalances[i];
            uint denorm = _initialWeights[i];

            // require(this.isTokenWhitelisted(t), "ERR_TOKEN_NOT_IN_WHITELIST");
            _verifyWhiteToken(t);

            bool returnValue = IERC20(t).transferFrom(msg.sender, address(this), bal);
            require(returnValue, "ERR_ERC20_FALSE");

            IERC20(t).safeApprove(address(bPool), DesynConstants.MAX_UINT);

            bPool.bind(t, bal, denorm);
        }

        while (_initialTokens.length > 0) {
            // Modifying state variable after external calls here,
            // but not essential, so not dangerous
            _initialTokens.pop();
        }
    }

    function addTokenToWhitelist(uint[] memory sort, address[] memory token) external onlyOwner {
        require(rights.canTokenWhiteLists && hasSetWhiteTokens == false, "ERR_NO_RIGHTS");
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < token.length; i++) {
            bool inRange = bFactory.isTokenWhitelistedForVerify(sort[i], token[i]);
            require(inRange, "TOKEN_MUST_IN_WHITE_LISTS");
            _addTokenToWhitelist(sort[i], token[i]);
        }
        hasSetWhiteTokens = true;
    }

    function _verifyWhiteToken(address token) internal view {
        require(bFactory.isTokenWhitelistedForVerify(token), "ERR_NOT_WHITE_TOKEN_IN_FACTORY");

        if (hasSetWhiteTokens) {
            require(_queryIsTokenWhitelisted(token), "ERR_NOT_WHITE_TOKEN_IN_POOL");
        }
    }

    // Rebind BPool and pull tokens from address
    // bPool is a contract interface; function calls on it are external
    function _pullUnderlying(
        address erc20,
        address from,
        uint amount
    ) internal needsBPool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);

        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
        bPool.rebind(erc20, DesynSafeMath.badd(tokenBalance, amount), tokenWeight);
    }

    // Rebind BPool and push tokens to address
    // bPool is a contract interface; function calls on it are external
    function _pushUnderlying(
        address erc20,
        address to,
        uint amount
    ) internal needsBPool {
        // Gets current Balance of token i, Bi, and weight of token i, Wi, from BPool.
        uint tokenBalance = bPool.getBalance(erc20);
        uint tokenWeight = bPool.getDenormalizedWeight(erc20);
        bPool.rebind(erc20, DesynSafeMath.bsub(tokenBalance, amount), tokenWeight);

        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    // Wrappers around corresponding core functions

    function _mint(uint amount) internal override {
        super._mint(amount);
        require(varTotalSupply <= etfStatus.upperCap, "ERR_CAP_LIMIT_REACHED");
    }

    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    function _pullPoolShare(address from, uint amount) internal {
        _pull(from, amount);
    }

    function _burnPoolShare(uint amount) internal {
        _burn(amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Imports

import "../libraries/DesynSafeMath.sol";
import "../interfaces/IERC20.sol";

// Contracts

/* solhint-disable func-order */

/**
 * @author Desyn Labs
 * @title Highly opinionated token implementation
 */
contract PCToken is IERC20 {
    using DesynSafeMath for uint;

    // State variables
    string public constant NAME = "Desyn Smart Pool";
    uint8 public constant DECIMALS = 18;

    // No leading underscore per naming convention (non-private)
    // Cannot call totalSupply (name conflict)
    // solhint-disable-next-line private-vars-leading-underscore
    uint internal varTotalSupply;

    mapping(address => uint) private _balance;
    mapping(address => mapping(address => uint)) private _allowance;

    string private _symbol;
    string private _name;

    // Event declarations

    // See definitions above; must be redeclared to be emitted from this contract
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    // Function declarations

    /**
     * @notice Base token constructor
     * @param tokenSymbol - the token symbol
     */
    constructor(string memory tokenSymbol, string memory tokenName) public {
        _symbol = tokenSymbol;
        _name = tokenName;
    }

    // External functions

    /**
     * @notice Getter for allowance: amount spender will be allowed to spend on behalf of owner
     * @param owner - owner of the tokens
     * @param spender - entity allowed to spend the tokens
     * @return uint - remaining amount spender is allowed to transfer
     */
    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowance[owner][spender];
    }

    /**
     * @notice Getter for current account balance
     * @param account - address we're checking the balance of
     * @return uint - token balance in the account
     */
    function balanceOf(address account) external view override returns (uint) {
        return _balance[account];
    }

    /**
     * @notice Approve owner (sender) to spend a certain amount
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function approve(address spender, uint amount) external override returns (bool) {
        /* In addition to the increase/decreaseApproval functions, could
           avoid the "approval race condition" by only allowing calls to approve
           when the current approval amount is 0
        
           require(_allowance[msg.sender][spender] == 0, "ERR_RACE_CONDITION");

           Some token contracts (e.g., KNC), already revert if you call approve 
           on a non-zero allocation. To deal with these, we use the SafeApprove library
           and safeApprove function when adding tokens to the pool.
        */

        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Increase the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function increaseApproval(address spender, uint amount) external returns (bool) {
        _allowance[msg.sender][spender] = DesynSafeMath.badd(_allowance[msg.sender][spender], amount);

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Decrease the amount the spender is allowed to spend on behalf of the owner (sender)
     * @dev emits an Approval event
     * @dev If you try to decrease it below the current limit, it's just set to zero (not an error)
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     * @return bool - result of the approval (will always be true if it doesn't revert)
     */
    function decreaseApproval(address spender, uint amount) external returns (bool) {
        uint oldValue = _allowance[msg.sender][spender];
        // Gas optimization - if amount == oldValue (or is larger), set to zero immediately
        if (amount >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = DesynSafeMath.bsub(oldValue, amount);
        }

        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender (caller) to recipient
     * @dev _move emits a Transfer event if successful
     * @param recipient - entity receiving the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transfer(address recipient, uint amount) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");

        _move(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @notice Transfer the given amount from sender to recipient
     * @dev _move emits a Transfer event if successful; may also emit an Approval event
     * @param sender - entity sending the tokens (must be caller or allowed to spend on behalf of caller)
     * @param recipient - recipient of the tokens
     * @param amount - number of tokens being transferred
     * @return bool - result of the transfer (will always be true if it doesn't revert)
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        require(recipient != address(0), "ERR_ZERO_ADDRESS");
        require(msg.sender == sender || amount <= _allowance[sender][msg.sender], "ERR_PCTOKEN_BAD_CALLER");

        _move(sender, recipient, amount);

        // memoize for gas optimization
        uint oldAllowance = _allowance[sender][msg.sender];

        // If the sender is not the caller, adjust the allowance by the amount transferred
        if (msg.sender != sender && oldAllowance != uint(-1)) {
            _allowance[sender][msg.sender] = DesynSafeMath.bsub(oldAllowance, amount);

            emit Approval(sender, msg.sender, _allowance[sender][msg.sender]);
        }

        return true;
    }

    // public functions

    /**
     * @notice Getter for the total supply
     * @dev declared external for gas optimization
     * @return uint - total number of tokens in existence
     */
    function totalSupply() external view override returns (uint) {
        return varTotalSupply;
    }

    // Public functions

    /**
     * @dev Returns the name of the token.
     *      We allow the user to set this name (as well as the symbol).
     *      Alternatives are 1) A fixed string (original design)
     *                       2) A fixed string plus the user-defined symbol
     *                          return string(abi.encodePacked(NAME, "-", _symbol));
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override returns (uint8) {
        return DECIMALS;
    }

    // internal functions

    // Mint an amount of new tokens, and add them to the balance (and total supply)
    // Emit a transfer amount from the null address to this contract
    function _mint(uint amount) internal virtual {
        _balance[address(this)] = DesynSafeMath.badd(_balance[address(this)], amount);
        varTotalSupply = DesynSafeMath.badd(varTotalSupply, amount);

        emit Transfer(address(0), address(this), amount);
    }

    // Burn an amount of new tokens, and subtract them from the balance (and total supply)
    // Emit a transfer amount from this contract to the null address
    function _burn(uint amount) internal virtual {
        // Can't burn more than we have
        // Remove require for gas optimization - bsub will revert on underflow
        // require(_balance[address(this)] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[address(this)] = DesynSafeMath.bsub(_balance[address(this)], amount);
        varTotalSupply = DesynSafeMath.bsub(varTotalSupply, amount);

        emit Transfer(address(this), address(0), amount);
    }

    // Transfer tokens from sender to recipient
    // Adjust balances, and emit a Transfer event
    function _move(
        address sender,
        address recipient,
        uint amount
    ) internal virtual {
        // Can't send more than sender has
        // Remove require for gas optimization - bsub will revert on underflow
        // require(_balance[sender] >= amount, "ERR_INSUFFICIENT_BAL");

        _balance[sender] = DesynSafeMath.bsub(_balance[sender], amount);
        _balance[recipient] = DesynSafeMath.badd(_balance[recipient], amount);

        emit Transfer(sender, recipient, amount);
    }

    // Transfer from this contract to recipient
    // Emits a transfer event if successful
    function _push(address recipient, uint amount) internal {
        _move(address(this), recipient, amount);
    }

    // Transfer from recipient to this contract
    // Emits a transfer event if successful
    function _pull(address sender, uint amount) internal {
        _move(sender, address(this), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

/**
 * @author Desyn Labs (and OpenZeppelin)
 * @title Protect against reentrant calls (and also selectively protect view functions)
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {_lock_} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `_lock_` guard, functions marked as
 * `_lock_` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `_lock_` entry
 * points to them.
 *
 * Also adds a _lockview_ modifier, which doesn't create a lock, but fails
 *   if another _lock_ call is in progress
 */
contract DesynReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `_lock_` function from another `_lock_`
     * function is not supported. It is possible to prevent this from happening
     * by making the `_lock_` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier lock() {
        // On the first call to _lock_, _notEntered will be true
        require(_status != _ENTERED, "ERR_REENTRY");

        // Any calls to _lock_ after this point will fail
        _status = _ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Also add a modifier that doesn't create a lock, but protects functions that
     *      should not be called while a _lock_ function is running
     */
    modifier viewlock() {
        require(_status != _ENTERED, "ERR_REENTRY_VIEW");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

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
contract DesynOwnable {
    // State variables

    address private _owner;
    mapping(address => bool) public adminList;
    address[] public owners;
    uint[] public ownerPercentage;
    uint public allOwnerPercentage;
    bool private initialized;
    // Event declarations

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddAdmin(address indexed newAdmin, uint indexed amount);
    event RemoveAdmin(address indexed oldAdmin, uint indexed amount);

    // Modifiers

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    modifier onlyAdmin() {
        require(adminList[msg.sender] || msg.sender == _owner, "onlyAdmin");
        _;
    }

    // Function declarations

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
    }

    function initHandle(address[] memory _owners, uint[] memory _ownerPercentage) external onlyOwner {
        require(_owners.length == _ownerPercentage.length, "ownerP");
        require(!initialized, "initialized!");
        for (uint i = 0; i < _owners.length; i++) {
            allOwnerPercentage += _ownerPercentage[i];
            adminList[_owners[i]] = true;
        }
        owners = _owners;
        ownerPercentage = _ownerPercentage;

        initialized = true;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     * @dev external for gas optimization
     * @param newOwner - address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     * @dev external for gas optimization
     * @param newOwner - address of new owner
     */
    function setAddAdminList(address newOwner, uint _ownerPercentage) external onlyOwner {
        require(!adminList[newOwner], "Address is Owner");

        adminList[newOwner] = true;
        owners.push(newOwner);
        ownerPercentage.push(_ownerPercentage);
        allOwnerPercentage += _ownerPercentage;
        emit AddAdmin(newOwner, _ownerPercentage);
    }

    /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
    /// @param owner Address of owner.
    function removeOwner(address owner) external onlyOwner {
        adminList[owner] = false;
        uint amount = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                amount = ownerPercentage[i];
                ownerPercentage[i] = ownerPercentage[ownerPercentage.length - 1];
                break;
            }
        }
        owners.pop();
        ownerPercentage.pop();
        allOwnerPercentage -= amount;
        emit RemoveAdmin(owner, amount);
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // @dev Returns list of owners.
    // @return List of owner addresses.
    function getOwnerPercentage() public view returns (uint[] memory) {
        return ownerPercentage;
    }

    /**
     * @notice Returns the address of the current owner
     * @dev external for gas optimization
     * @return address - of the owner (AKA controller)
     */
    function getController() external view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

/**
 * @author Desyn Labs
 * @title Manage Configurable Rights for the smart pool
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the BSP cap (max # of pool tokens)
 *      canChangeFloor - can change the BSP floor for Closure ETF (min # of pool tokens)
 */
library RightsManager {
    // Type declarations

    enum Permissions {
        PAUSE_SWAPPING,
        CHANGE_SWAP_FEE,
        CHANGE_WEIGHTS,
        ADD_REMOVE_TOKENS,
        WHITELIST_LPS,
        TOKEN_WHITELISTS
        // CHANGE_CAP,
        // CHANGE_FLOOR
    }

    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canTokenWhiteLists;
        // bool canChangeCap;
        // bool canChangeFloor;
    }

    // State variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_TOKEN_WHITELISTS = false;

    // bool public constant DEFAULT_CAN_CHANGE_CAP = false;
    // bool public constant DEFAULT_CAN_CHANGE_FLOOR = false;

    // Functions

    /**
     * @notice create a struct from an array (or return defaults)
     * @dev If you pass an empty array, it will construct it using the defaults
     * @param a - array input
     * @return Rights struct
     */
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length < 6) {
            return
                Rights(
                    DEFAULT_CAN_PAUSE_SWAPPING,
                    DEFAULT_CAN_CHANGE_SWAP_FEE,
                    DEFAULT_CAN_CHANGE_WEIGHTS,
                    DEFAULT_CAN_ADD_REMOVE_TOKENS,
                    DEFAULT_CAN_WHITELIST_LPS,
                    DEFAULT_CAN_TOKEN_WHITELISTS
                    // DEFAULT_CAN_CHANGE_CAP,
                    // DEFAULT_CAN_CHANGE_FLOOR
                );
        } else {
            // return Rights(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
            return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
        }
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     * @dev avoids multiple calls to hasPermission
     * @param rights - the rights struct to convert
     * @return boolean array containing the rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canTokenWhiteLists;
        // result[5] = rights.canChangeCap;
        // result[6] = rights.canChangeFloor;

        return result;
    }

    // Though it is actually simple, the number of branches triggers code-complexity
    /* solhint-disable code-complexity */

    /**
     * @notice Externally check permissions using the Enum
     * @param self - Rights struct containing the permissions
     * @param permission - The permission to check
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.PAUSE_SWAPPING == permission) {
            return self.canPauseSwapping;
        } else if (Permissions.CHANGE_SWAP_FEE == permission) {
            return self.canChangeSwapFee;
        } else if (Permissions.CHANGE_WEIGHTS == permission) {
            return self.canChangeWeights;
        } else if (Permissions.ADD_REMOVE_TOKENS == permission) {
            return self.canAddRemoveTokens;
        } else if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        } else if (Permissions.TOKEN_WHITELISTS == permission) {
            return self.canTokenWhiteLists;
        }
        // else if (Permissions.CHANGE_CAP == permission) {
        //     return self.canChangeCap;
        // } else if (Permissions.CHANGE_FLOOR == permission) {
        //     return self.canChangeFloor;
        // }
    }

    /* solhint-enable code-complexity */
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

contract WhiteToken {
    // add token log
    event LOG_WHITELIST(address indexed spender, uint indexed sort, address indexed caller, address token);
    // del token log
    event LOG_DEL_WHITELIST(address indexed spender, uint indexed sort, address indexed caller, address token);

    // record the number of whitelists.
    uint private _whiteTokenCount;
    // token address => is white token.
    mapping(address => bool) private _isTokenWhitelisted;
    // Multi level white token.
    // type => token address => is white token.
    mapping(uint => mapping(address => bool)) private _tokenWhitelistedInfo;

    function _queryIsTokenWhitelisted(address token) internal view returns (bool) {
        return _isTokenWhitelisted[token];
    }

    // for factory to verify
    function _isTokenWhitelistedForVerify(uint sort, address token) internal view returns (bool) {
        return _tokenWhitelistedInfo[sort][token];
    }

    // add sort token
    function _addTokenToWhitelist(uint sort, address token) internal {
        require(token != address(0), "ERR_INVALID_TOKEN_ADDRESS");
        require(_queryIsTokenWhitelisted(token) == false, "ERR_HAS_BEEN_ADDED_WHITE");

        _tokenWhitelistedInfo[sort][token] = true;
        _isTokenWhitelisted[token] = true;
        _whiteTokenCount++;

        emit LOG_WHITELIST(address(this), sort, msg.sender, token);
    }

    // remove sort token
    function _removeTokenFromWhitelist(uint sort, address token) internal {
        require(_queryIsTokenWhitelisted(token) == true, "ERR_NOT_WHITE_TOKEN");

        require(_tokenWhitelistedInfo[sort][token], "ERR_SORT_NOT_MATCHED");

        _tokenWhitelistedInfo[sort][token] = false;
        _isTokenWhitelisted[token] = false;
        _whiteTokenCount--;
        emit LOG_DEL_WHITELIST(address(this), sort, msg.sender, token);
    }

    // already has init
    function _initWhiteTokenState() internal view returns (bool) {
        return _whiteTokenCount == 0 ?  false : true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;
import "../base/WhiteToken.sol";
import "../base/LiquidityPool.sol";
import "../interfaces/IBFactory.sol";

contract Factory is BBronze, WhiteToken {
    event LOG_NEW_POOL(address indexed caller, address indexed pool);
    event LOG_BLABS(address indexed caller, address indexed blabs);
    event LOG_ROUTER(address indexed caller, address indexed router);
    event LOG_VAULT(address indexed vault, address indexed caller);
    event LOG_USER_VAULT(address indexed vault, address indexed caller);
    event LOG_MANAGER(address indexed manager, address indexed caller);
    event LOG_ORACLE(address indexed caller, address indexed oracle);
    event MODULE_STATUS_CHANGE(address etf, address module, bool status);
    event PAUSED_STATUS(bool state);

    mapping(address => bool) private _isLiquidityPool;
    mapping(address => mapping(address => bool)) private _isModuleRegistered;
    uint private counters;
    bytes public bytecodes = type(LiquidityPool).creationCode;
    bool public isPaused;

    function addTokenToWhitelist(uint[] memory sort, address[] memory token) external onlyBlabs {
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < sort.length; i++) {
            _addTokenToWhitelist(sort[i], token[i]);
        }
    }

    function removeTokenFromWhitelist(uint[] memory sort, address[] memory token) external onlyBlabs {
        require(sort.length == token.length, "ERR_SORT_TOKEN_MISMATCH");
        for (uint i = 0; i < sort.length; i++) {
            _removeTokenFromWhitelist(sort[i], token[i]);
        }
    }

    function isTokenWhitelistedForVerify(uint sort, address token) external view returns (bool) {
        return _isTokenWhitelistedForVerify(sort, token);
    }

    function isTokenWhitelistedForVerify(address token) external view returns (bool) {
        return _queryIsTokenWhitelisted(token);
    }

    function isLiquidityPool(address b) external view returns (bool) {
        return _isLiquidityPool[b];
    }

    function createPool() internal returns (address base) {
        bytes memory bytecode = bytecodes;
        bytes32 salt = keccak256(abi.encodePacked(counters++));

        assembly {
            base := create2(0, add(bytecode, 32), mload(bytecode), salt)
            if iszero(extcodesize(base)) {
                revert(0, 0)
            }
        }
        counters++;
    }

    function newLiquidityPool() external returns (IBPool) {
        address lpool = createPool();
        _isLiquidityPool[lpool] = true;
        emit LOG_NEW_POOL(msg.sender, lpool);
        IBPool(lpool).setController(msg.sender);
        return IBPool(lpool);
    }

    address private _blabs;
    address private _swapRouter;
    address private _vault;
    address private _oracle;
    address private _managerOwner;
    address private _vaultAddress;
    address private _userVaultAddress;

    constructor() public {
        _blabs = msg.sender;
    }

    function getBLabs() external view returns (address) {
        return _blabs;
    }

    function setBLabs(address b) external onlyBlabs {
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function getSwapRouter() external view returns (address) {
        return _swapRouter;
    }

    function getModuleStatus(address etf, address module) external view returns (bool) {
        return _isModuleRegistered[etf][module];
    }

    function getOracleAddress() external view returns (address) {
        return _oracle;
    }

    function setSwapRouter(address router) external onlyBlabs {
        emit LOG_ROUTER(msg.sender, router);
        _swapRouter = router;
    }

    function registerModule(address etf, address module) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");

        require(etf != address(0), "ZERO ETF ADDRESS");

        require(module != address(0), "ZERO ADDRESS");

        _isModuleRegistered[etf][module] = true;

        emit MODULE_STATUS_CHANGE(etf, module, true);
    }

    function removeModule(address etf, address module) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");

        require(etf != address(0), "ZERO ETF ADDRESS");

        require(module != address(0), "ZERO ADDRESS");

        _isModuleRegistered[etf][module] = false;

        emit MODULE_STATUS_CHANGE(etf, module, false);
    }

    function setOracle(address oracle) external {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        emit LOG_ORACLE(msg.sender, oracle);
        _oracle = oracle;
    }

    function collect(IERC20 token) external onlyBlabs {
        uint collected = token.balanceOf(address(this));
        bool xfer = token.transfer(_blabs, collected);
        require(xfer, "ERR_ERC20_FAILED");
    }

    function getVault() external view returns (address) {
        return _vaultAddress;
    }

    function setVault(address newVault) external onlyBlabs {
        _vaultAddress = newVault;
        emit LOG_VAULT(newVault, msg.sender);
    }

    function getUserVault() external view returns (address) {
        return _userVaultAddress;
    }

    function setUserVault(address newVault) external onlyBlabs {
        _userVaultAddress = newVault;
        emit LOG_USER_VAULT(newVault, msg.sender);
    }

    function getManagerOwner() external view returns (address) {
        return _managerOwner;
    }

    function setManagerOwner(address newManagerOwner) external onlyBlabs {
        _managerOwner = newManagerOwner;
        emit LOG_MANAGER(newManagerOwner, msg.sender);
    }

    function setProtocolPaused(bool state) external onlyBlabs {
        isPaused = state;
        emit PAUSED_STATUS(state);
    }

    modifier onlyBlabs() {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.6.12;

import "./LpToken.sol";
import "./Math.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IBFactory.sol";
import "../libraries/Address.sol";

contract LiquidityPool is BBronze, LpToken, Math {
    using Address for address;

    struct Record {
        bool bound; // is token bound to pool
        uint index; // private
        uint denorm; // denormalized weight
        uint balance;
    }

    event LOG_JOIN(address indexed caller, address indexed tokenIn, uint tokenAmountIn);

    event LOG_EXIT(address indexed caller, address indexed tokenOut, uint tokenAmountOut);

    event LOG_REBALANCE(address indexed tokenA, address indexed tokenB, uint newWeightA, uint newWeightB, uint newBalanceA, uint newBalanceB, bool isSoldout);

    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }

    modifier _lock_() {
        require(!_mutex, "ERR_REENTRY");
        _mutex = true;
        _;
        _mutex = false;
    }

    modifier _viewlock_() {
        require(!_mutex, "ERR_REENTRY");
        _;
    }

    bool private _mutex;

    IBFactory private _factory; // Factory address to push token exitFee to
    address private _controller; // has CONTROL role
    bool private _publicSwap; // true if PUBLIC can call SWAP functions

    // `setSwapFee` and `finalize` require CONTROL
    // `finalize` sets `PUBLIC can SWAP`, `PUBLIC can JOIN`
    uint private _swapFee;
    bool private _finalized;

    address[] private _tokens;
    mapping(address => Record) private _records;
    uint private _totalWeight;

    Oracles private oracle;

    constructor() public {
        _controller = msg.sender;
        _factory = IBFactory(msg.sender);
        _swapFee = MIN_FEE;
        _publicSwap = false;
        _finalized = false;

        oracle = Oracles(_factory.getOracleAddress());
    }

    function isPublicSwap() external view returns (bool) {
        return _publicSwap;
    }

    function isFinalized() external view returns (bool) {
        return _finalized;
    }

    function isBound(address t) external view returns (bool) {
        return _records[t].bound;
    }

    function getNumTokens() external view returns (uint) {
        return _tokens.length;
    }

    function getCurrentTokens() external view _viewlock_ returns (address[] memory tokens) {
        return _tokens;
    }

    function getFinalTokens() external view _viewlock_ returns (address[] memory tokens) {
        require(_finalized, "ERR_NOT_FINALIZED");
        return _tokens;
    }

    function getDenormalizedWeight(address token) external view _viewlock_ returns (uint) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].denorm;
    }

    function getTotalDenormalizedWeight() external view _viewlock_ returns (uint) {
        return _totalWeight;
    }

    function getNormalizedWeight(address token) external _viewlock_ returns (uint) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        uint denorm = _records[token].denorm;
        uint price = oracle.getPrice(token);

        uint[] memory _balances = new uint[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            _balances[i] = getBalance(_tokens[i]);
        }
        uint totalValue = oracle.getAllPrice(_tokens, _balances);
        uint currentValue = bmul(price, getBalance(token));
        return bdiv(currentValue, totalValue);
    }

    function getBalance(address token) public view _viewlock_ returns (uint) {
        require(_records[token].bound, "ERR_NOT_BOUND");
        return _records[token].balance;
    }

    function getSwapFee() external view _viewlock_ returns (uint) {
        return _swapFee;
    }

    function getController() external view _viewlock_ returns (address) {
        return _controller;
    }

    function setSwapFee(uint swapFee) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(swapFee >= MIN_FEE, "ERR_MIN_FEE");
        require(swapFee <= MAX_FEE, "ERR_MAX_FEE");
        _swapFee = swapFee;
    }

    function setController(address manager) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _controller = manager;
    }

    function setPublicSwap(bool public_) external _logs_ _lock_ {
        require(!_finalized, "ERR_IS_FINALIZED");
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        _publicSwap = public_;
    }

    function finalize() external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");
        require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");

        _finalized = true;
        _publicSwap = true;

        _mintPoolShare(INIT_POOL_SUPPLY);
        _pushPoolShare(msg.sender, INIT_POOL_SUPPLY);
    }

    function bind(
        address token,
        uint balance,
        uint denorm
    )
        external
        _logs_ // _lock_  Bind does not lock because it jumps to `rebind`, which does
    {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_records[token].bound, "ERR_IS_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

        _records[token] = Record({
            bound: true,
            index: _tokens.length,
            denorm: 0, // balance and denorm will be validated
            balance: 0 // and set by `rebind`
        });
        _tokens.push(token);
        rebind(token, balance, denorm);
    }

    function rebind(
        address token,
        uint balance,
        uint denorm
    ) public _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        require(denorm >= MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(denorm <= MAX_WEIGHT, "ERR_MAX_WEIGHT");
        require(balance >= MIN_BALANCE, "ERR_MIN_BALANCE");

        // Adjust the denorm and totalWeight
        uint oldWeight = _records[token].denorm;
        if (denorm > oldWeight) {
            _totalWeight = badd(_totalWeight, bsub(denorm, oldWeight));
            require(_totalWeight <= MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");
        } else if (denorm < oldWeight) {
            _totalWeight = bsub(_totalWeight, bsub(oldWeight, denorm));
        }
        _records[token].denorm = denorm;

        // Adjust the balance record and actual token balance
        uint oldBalance = _records[token].balance;
        _records[token].balance = balance;
        if (balance > oldBalance) {
            _pullUnderlying(token, msg.sender, bsub(balance, oldBalance));
        } else if (balance < oldBalance) {
            // In this case liquidity is being withdrawn, so charge EXIT_FEE
            uint tokenBalanceWithdrawn = bsub(oldBalance, balance);
            _pushUnderlying(token, msg.sender, tokenBalanceWithdrawn);
        }
    }

    function rebindSmart(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint deltaBalance,
        bool isSoldout,
        uint minAmountOut
    ) public _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");

        address[] memory paths = new address[](2);
        paths[0] = tokenA;
        paths[1] = tokenB;

        IUniswapV2Router02 swapRouter = IUniswapV2Router02(_factory.getSwapRouter());
        // tokenB is inside the etf
        if (_records[tokenB].bound) {
            uint oldWeightB = _records[tokenB].denorm;
            uint oldBalanceB = _records[tokenB].balance;
            uint newWeightB = badd(oldWeightB, deltaWeight);

            require(newWeightB <= MAX_WEIGHT, "ERR_MAX_WEIGHT_B");

            if (isSoldout) {
                require(_tokens.length >= MIN_BOUND_TOKENS, "ERR_MIN_TOKENS");
            } else {
                require(_records[tokenA].bound, "ERR_NOT_BOUND_A");

                uint newWeightA = bsub(_records[tokenA].denorm, deltaWeight);
                uint newBalanceA = bsub(_records[tokenA].balance, deltaBalance);
                require(newWeightA >= MIN_WEIGHT, "ERR_MIN_WEIGHT_A");
                require(newBalanceA >= MIN_BALANCE, "ERR_MIN_BALANCE_A");

                _records[tokenA].balance = newBalanceA;
                _records[tokenA].denorm = newWeightA;
            }

            // sell tokenA to get tokenB
            uint balanceBBefore = IERC20(tokenB).balanceOf(address(this));

            _safeApprove(IERC20(tokenA), address(swapRouter), uint(-1));

            swapRouter.swapExactTokensForTokens(deltaBalance, minAmountOut, paths, address(this), badd(block.timestamp, 1800));
            uint balanceBAfter = IERC20(tokenB).balanceOf(address(this));

            uint newBalanceB = badd(oldBalanceB, bsub(balanceBAfter, balanceBBefore));

            _records[tokenB].balance = newBalanceB;
            _records[tokenB].denorm = newWeightB;
        }
        // tokenB is outside the etf
        else {
            if (!isSoldout) {
                require(_records[tokenA].bound, "ERR_NOT_BOUND_A");

                uint newWeightA = bsub(_records[tokenA].denorm, deltaWeight);
                uint newBalanceA = bsub(_records[tokenA].balance, deltaBalance);

                require(newWeightA >= MIN_WEIGHT, "ERR_MIN_WEIGHT_A");
                require(newBalanceA >= MIN_BALANCE, "ERR_MIN_BALANCE_A");
                require(_tokens.length < MAX_BOUND_TOKENS, "ERR_MAX_TOKENS");

                _records[tokenA].balance = newBalanceA;
                _records[tokenA].denorm = newWeightA;
            }

            // sell all tokenA to get tokenB
            uint balanceBBefore = IERC20(tokenB).balanceOf(address(this));

            _safeApprove(IERC20(tokenA), address(swapRouter), uint(-1));

            swapRouter.swapExactTokensForTokens(deltaBalance, minAmountOut, paths, address(this), badd(block.timestamp, 1800));
            uint balanceBAfter = IERC20(tokenB).balanceOf(address(this));

            uint newBalanceB = bsub(balanceBAfter, balanceBBefore);
            require(newBalanceB >= MIN_BALANCE, "ERR_MIN_BALANCE");
            require(deltaWeight >= MIN_WEIGHT, "ERR_MIN_WEIGHT_DELTA");

            _records[tokenB] = Record({bound: true, index: _tokens.length, denorm: deltaWeight, balance: newBalanceB});
            _tokens.push(tokenB);
        }

        emit LOG_REBALANCE(tokenA, tokenB, _records[tokenA].denorm, _records[tokenB].denorm, _records[tokenA].balance, _records[tokenB].balance, isSoldout);
    }

    function execute(
        address _target,
        uint _value,
        bytes calldata _data
    ) external _logs_ _lock_ returns (bytes memory _returnValue) {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(!_finalized, "ERR_IS_FINALIZED");

        _returnValue = _target.functionCallWithValue(_data, _value);

        return _returnValue;
    }

    function unbind(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        uint tokenBalance = _records[token].balance;

        _totalWeight = bsub(_totalWeight, _records[token].denorm);

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});

        _pushUnderlying(token, msg.sender, tokenBalance);
    }

    function unbindPure(address token) external _logs_ _lock_ {
        require(msg.sender == _controller, "ERR_NOT_CONTROLLER");
        require(_records[token].bound, "ERR_NOT_BOUND");
        require(!_finalized, "ERR_IS_FINALIZED");

        // Swap the token-to-unbind with the last token,
        // then delete the last token
        uint index = _records[token].index;
        uint last = _tokens.length - 1;
        _tokens[index] = _tokens[last];
        _records[_tokens[index]].index = index;
        _tokens.pop();
        _records[token] = Record({bound: false, index: 0, denorm: 0, balance: 0});
    }

    // Absorb any tokens that have been sent to this contract into the pool
    function gulp(address token) external _logs_ _lock_ {
        require(_records[token].bound, "ERR_NOT_BOUND");
        _records[token].balance = IERC20(token).balanceOf(address(this));
    }

    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountOut, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountIn = bmul(ratio, bal);
            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");
            _records[t].balance = badd(_records[t].balance, tokenAmountIn);
            emit LOG_JOIN(msg.sender, t, tokenAmountIn);
            _pullUnderlying(t, msg.sender, tokenAmountIn);
        }
        _mintPoolShare(poolAmountOut);
        _pushPoolShare(msg.sender, poolAmountOut);
    }

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external _logs_ _lock_ {
        require(_finalized, "ERR_NOT_FINALIZED");

        uint poolTotal = totalSupply();
        uint ratio = bdiv(poolAmountIn, poolTotal);
        require(ratio != 0, "ERR_MATH_APPROX");

        _pullPoolShare(msg.sender, poolAmountIn);
        _burnPoolShare(poolAmountIn);

        for (uint i = 0; i < _tokens.length; i++) {
            address t = _tokens[i];
            uint bal = _records[t].balance;
            uint tokenAmountOut = bmul(ratio, bal);
            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");
            _records[t].balance = bsub(_records[t].balance, tokenAmountOut);
            emit LOG_EXIT(msg.sender, t, tokenAmountOut);
            _pushUnderlying(t, msg.sender, tokenAmountOut);
        }
    }

    // 'Underlying' token-manipulation functions make external calls but are NOT locked
    // You must `_lock_` or otherwise ensure reentry-safety
    function _safeApprove(
        IERC20 token,
        address spender,
        uint amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.approve(spender, 0);
        }
        token.approve(spender, amount);
    }

    function _pullUnderlying(
        address erc20,
        address from,
        uint amount
    ) internal {
        bool xfer = IERC20(erc20).transferFrom(from, address(this), amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pushUnderlying(
        address erc20,
        address to,
        uint amount
    ) internal {
        bool xfer = IERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }

    function _pullPoolShare(address from, uint amount) internal {
        _pull(from, amount);
    }

    function _pushPoolShare(address to, uint amount) internal {
        _push(to, amount);
    }

    function _mintPoolShare(uint amount) internal {
        _mint(amount);
    }

    function _burnPoolShare(uint amount) internal {
        _burn(amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.12;

import "./Num.sol";
import "../interfaces/IERC20.sol";

// Highly opinionated token implementation

contract LpTokenBase is Num {
    mapping(address => uint) internal _balance;
    mapping(address => mapping(address => uint)) internal _allowance;
    uint internal _totalSupply;

    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function _mint(uint amt) internal {
        _balance[address(this)] = badd(_balance[address(this)], amt);
        _totalSupply = badd(_totalSupply, amt);
        emit Transfer(address(0), address(this), amt);
    }

    function _burn(uint amt) internal {
        require(_balance[address(this)] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[address(this)] = bsub(_balance[address(this)], amt);
        _totalSupply = bsub(_totalSupply, amt);
        emit Transfer(address(this), address(0), amt);
    }

    function _move(
        address src,
        address dst,
        uint amt
    ) internal {
        require(_balance[src] >= amt, "ERR_INSUFFICIENT_BAL");
        _balance[src] = bsub(_balance[src], amt);
        _balance[dst] = badd(_balance[dst], amt);
        emit Transfer(src, dst, amt);
    }

    function _push(address to, uint amt) internal {
        _move(address(this), to, amt);
    }

    function _pull(address from, uint amt) internal {
        _move(from, address(this), amt);
    }
}

contract LpToken is LpTokenBase, IERC20 {
    string private _name = "Desyn Pool Token";
    string private _symbol = "DPT";
    uint8 private _decimals = 18;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function allowance(address src, address dst) external view override returns (uint) {
        return _allowance[src][dst];
    }

    function balanceOf(address whom) external view override returns (uint) {
        return _balance[whom];
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    function approve(address dst, uint amt) external override returns (bool) {
        _allowance[msg.sender][dst] = amt;
        emit Approval(msg.sender, dst, amt);
        return true;
    }

    function increaseApproval(address dst, uint amt) external returns (bool) {
        _allowance[msg.sender][dst] = badd(_allowance[msg.sender][dst], amt);
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function decreaseApproval(address dst, uint amt) external returns (bool) {
        uint oldValue = _allowance[msg.sender][dst];
        if (amt > oldValue) {
            _allowance[msg.sender][dst] = 0;
        } else {
            _allowance[msg.sender][dst] = bsub(oldValue, amt);
        }
        emit Approval(msg.sender, dst, _allowance[msg.sender][dst]);
        return true;
    }

    function transfer(address dst, uint amt) external override returns (bool) {
        _move(msg.sender, dst, amt);
        return true;
    }

    function transferFrom(
        address src,
        address dst,
        uint amt
    ) external override returns (bool) {
        require(msg.sender == src || amt <= _allowance[src][msg.sender], "ERR_LPTOKEN_BAD_CALLER");
        _move(src, dst, amt);
        if (msg.sender != src && _allowance[src][msg.sender] != uint(-1)) {
            _allowance[src][msg.sender] = bsub(_allowance[src][msg.sender], amt);
            emit Approval(src, msg.sender, _allowance[src][msg.sender]);
        }
        return true;
    }
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity 0.6.12;

interface IUniswapV2Router02 {
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        uint value
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
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.6.12;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";

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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
import {RightsManager} from "../libraries/RightsManager.sol";
import {SmartPoolManager} from "../libraries/SmartPoolManager.sol";
// Needed to handle structures externally
pragma experimental ABIEncoderV2;

// Imports
abstract contract IConfigurableRightsPool {
    enum Etypes {
        OPENED,
        CLOSED
    }
    enum Period {
        HALF,
        ONE,
        TWO
    }

    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        Etypes etype;
    }

    struct CrpParams {
        uint initialSupply;
        uint collectPeriod;
        Period period;
    }

    function setController(address owner) external virtual;

    function init(
        address factoryAddress,
        IConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights
    ) external virtual;

    function initHandle(address[] memory owners, uint[] memory ownerPercentage) external virtual;
}

interface IUserVault {
    function setPoolParams(address pool, SmartPoolManager.KolPoolParams memory kolPoolParams) external;
}

// Contracts

/**
 * @author Desyn Labs
 * @title Configurable Rights Pool Factory - create parameterized smart pools
 * @dev Rights are held in a corresponding struct in ConfigurableRightsPool
 *      Index values are as follows:
 *      0: canPauseSwapping - can setPublicSwap back to false after turning it on
 *                            by default, it is off on initialization and can only be turned on
 *      1: canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      2: canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      3: canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      4: canWhitelistLPs - if set, only whitelisted addresses can join pools
 *                           (enables private pools with more than one LP)
 *      5: canChangeCap - can change the BSP cap (max # of pool tokens)
 */
contract CRPFactory {
    // State variables

    // Keep a list of all Configurable Rights Pools
    mapping(address => bool) private _isCrp;

    // Event declarations

    // Log the address of each new smart pool, and its creator
    event LogNewCrp(address indexed caller, address indexed pool);
    event LOG_USER_VAULT(address indexed vault, address indexed caller);
    event LOG_MIDDLEWARE(address indexed middleware, address indexed caller);
    uint private counters;

    bytes public bytecodes;
    address private _blabs;
    address public userVault;

    constructor(bytes memory _bytecode) public {
        bytecodes = _bytecode;
        _blabs = msg.sender;
    }

    function createPool(IConfigurableRightsPool.PoolParams calldata poolParams) internal returns (address base) {
        bytes memory bytecode = bytecodes;
        bytes memory deploymentData = abi.encodePacked(bytecode, abi.encode(poolParams.poolTokenSymbol, poolParams.poolTokenName));
        bytes32 salt = keccak256(abi.encodePacked(counters++));
        assembly {
            base := create2(0, add(deploymentData, 32), mload(deploymentData), salt)
            if iszero(extcodesize(base)) {
                revert(0, 0)
            }
        }
    }

    // Function declarations
    /**
     * @notice Create a new CRP
     * @dev emits a LogNewCRP event
     * @param factoryAddress - the BFactory instance used to create the underlying pool
     * @param poolParams - struct containing the names, tokens, weights, balances, and swap fee
     * @param rights - struct of permissions, configuring this CRP instance (see above for definitions)
     */
    function newCrp(
        address factoryAddress,
        IConfigurableRightsPool.PoolParams calldata poolParams,
        RightsManager.Rights calldata rights,
        SmartPoolManager.KolPoolParams calldata kolPoolParams,
        address[] memory owners,
        uint[] memory ownerPercentage
    ) external returns (IConfigurableRightsPool) {
        // require(poolParams.constituentTokens.length >= DesynConstants.MIN_ASSET_LIMIT, "ERR_TOO_FEW_TOKENS");

        // Arrays must be parallel
        // require(poolParams.tokenBalances.length == poolParams.constituentTokens.length, "ERR_START_BALANCES_MISMATCH");
        // require(poolParams.tokenWeights.length == poolParams.constituentTokens.length, "ERR_START_WEIGHTS_MISMATCH");

        address crp = createPool(poolParams);
        emit LogNewCrp(msg.sender, crp);

        _isCrp[crp] = true;
        IConfigurableRightsPool(crp).init(factoryAddress, poolParams, rights);
        IUserVault(userVault).setPoolParams(crp, kolPoolParams);
        // The caller is the controller of the CRP
        // The CRP will be the controller of the underlying Core BPool
        IConfigurableRightsPool(crp).initHandle(owners, ownerPercentage);
        IConfigurableRightsPool(crp).setController(msg.sender);

        return IConfigurableRightsPool(crp);
    }

    modifier onlyBlabs() {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        _;
    }

    function setUserVault(address newVault) external onlyBlabs {
        userVault = newVault;
        emit LOG_USER_VAULT(newVault, msg.sender);
    }

    function setByteCodes(bytes memory _bytecodes) external onlyBlabs {
        bytecodes = _bytecodes;
    }

    /**
     * @notice Check to see if a given address is a CRP
     * @param addr - address to check
     * @return boolean indicating whether it is a CRP
     */
    function isCrp(address addr) external view returns (bool) {
        return _isCrp[addr];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;
import {RightsManager} from "../libraries/RightsManager.sol";
import {SmartPoolManager} from "../libraries/SmartPoolManager.sol";

abstract contract ERC20 {
    function approve(address spender, uint amount) external virtual returns (bool);

    function transfer(address dst, uint amt) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external virtual returns (bool);

    function balanceOf(address whom) external view virtual returns (uint);

    function allowance(address, address) external view virtual returns (uint);
}

abstract contract DesynOwnable {
    function setController(address controller) external virtual;
}

abstract contract AbstractPool is ERC20, DesynOwnable {
    function setSwapFee(uint swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function joinPool(
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        address kol
    ) external virtual;
}

abstract contract LiquidityPoolActions is AbstractPool {
    function finalize() external virtual;

    function bind(
        address token,
        uint balance,
        uint denorm
    ) external virtual;

    function rebind(
        address token,
        uint balance,
        uint denorm
    ) external virtual;

    function unbind(address token) external virtual;

    function isBound(address t) external view virtual returns (bool);

    function getCurrentTokens() external view virtual returns (address[] memory);

    function getFinalTokens() external view virtual returns (address[] memory);

    function getBalance(address token) external view virtual returns (uint);
}

abstract contract FactoryActions {
    function newLiquidityPool() external virtual returns (LiquidityPoolActions);
}

abstract contract IConfigurableRightsPool is AbstractPool {
    enum Etypes {
        OPENED,
        CLOSED
    }
    enum Period {
        HALF,
        ONE,
        TWO
    }

    struct PoolTokenRange {
        uint bspFloor;
        uint bspCap;
    }

    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint[] tokenBalances;
        uint[] tokenWeights;
        uint swapFee;
        uint managerFee;
        uint redeemFee;
        uint issueFee;
        uint perfermanceFee;
        Etypes etype;
    }

    struct CrpParams {
        uint initialSupply;
        uint collectPeriod;
        Period period;
    }

    function createPool(
        uint initialSupply,
        uint collectPeriod,
        Period period,
        PoolTokenRange memory tokenRange
    ) external virtual;

    function createPool(uint initialSupply) external virtual;

    function setCap(uint newCap) external virtual;

    function rebalance(
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external virtual;

    function commitAddToken(
        address token,
        uint balance,
        uint denormalizedWeight
    ) external virtual;

    function applyAddToken() external virtual;

    function whitelistLiquidityProvider(address provider) external virtual;

    function removeWhitelistedLiquidityProvider(address provider) external virtual;

    function bPool() external view virtual returns (LiquidityPoolActions);
}

abstract contract ICRPFactory {
    function newCrp(
        address factoryAddress,
        IConfigurableRightsPool.PoolParams calldata params,
        RightsManager.Rights calldata rights,
        SmartPoolManager.KolPoolParams calldata kolPoolParams,
        address[] memory owners,
        uint[] memory ownerPercentage
    ) external virtual returns (IConfigurableRightsPool);
}

abstract contract IUserVault {
    function claimKolReward(address pool) external virtual;

    function managerClaim(address pool) external virtual;
}

/********************************** WARNING **********************************/
//                                                                           //
// This contract is only meant to be used in conjunction with ds-proxy.      //
// Calling this contract directly will lead to loss of funds.                //
//                                                                           //
/********************************** WARNING **********************************/

contract Actions {
    // --- Pool Creation ---

    function create(
        FactoryActions factory,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata weights,
        uint swapFee,
        bool finalize
    ) external returns (LiquidityPoolActions pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == weights.length, "ERR_LENGTH_MISMATCH");

        pool = factory.newLiquidityPool();
        pool.setSwapFee(swapFee);

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
            _safeApprove(token, address(pool), balances[i]);
            pool.bind(tokens[i], balances[i], weights[i]);
        }

        if (finalize) {
            pool.finalize();
            require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        } else {
            pool.setPublicSwap(true);
        }
    }

    function createSmartPool(
        ICRPFactory factory,
        FactoryActions coreFactory,
        IConfigurableRightsPool.PoolParams calldata poolParams,
        IConfigurableRightsPool.CrpParams calldata crpParams,
        RightsManager.Rights calldata rights,
        SmartPoolManager.KolPoolParams calldata kolPoolParams,
        address[] memory owners,
        uint[] memory ownerPercentage,
        IConfigurableRightsPool.PoolTokenRange memory tokenRange
    ) external returns (IConfigurableRightsPool crp) {
        require(poolParams.constituentTokens.length == poolParams.tokenBalances.length, "ERR_LENGTH_MISMATCH");
        require(poolParams.constituentTokens.length == poolParams.tokenWeights.length, "ERR_LENGTH_MISMATCH");

        crp = factory.newCrp(address(coreFactory), poolParams, rights, kolPoolParams, owners, ownerPercentage);
        for (uint i = 0; i < poolParams.constituentTokens.length; i++) {
            ERC20 token = ERC20(poolParams.constituentTokens[i]);
            require(token.transferFrom(msg.sender, address(this), poolParams.tokenBalances[i]), "ERR_TRANSFER_FAILED");
            _safeApprove(token, address(crp), poolParams.tokenBalances[i]);
        }

        crp.createPool(crpParams.initialSupply, crpParams.collectPeriod, crpParams.period, tokenRange);
        require(crp.transfer(msg.sender, crpParams.initialSupply), "ERR_TRANSFER_FAILED");
        // DSProxy instance keeps pool ownership to enable management
    }

    // --- Joins ---

    function joinPool(
        LiquidityPoolActions pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = pool.getFinalTokens();
        _join(pool, tokens, poolAmountOut, maxAmountsIn, msg.sender);
    }

    function joinSmartPool(
        IConfigurableRightsPool pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn,
        address kol
    ) external {
        address[] memory tokens = pool.bPool().getCurrentTokens();
        _join(pool, tokens, poolAmountOut, maxAmountsIn, kol);
    }

    // --- Pool management (common) ---

    function setPublicSwap(AbstractPool pool, bool publicSwap) external {
        pool.setPublicSwap(publicSwap);
    }

    function setSwapFee(AbstractPool pool, uint newFee) external {
        pool.setSwapFee(newFee);
    }

    function setController(AbstractPool pool, address newController) external {
        pool.setController(newController);
    }

    // --- Private pool management ---

    function setTokens(
        LiquidityPoolActions pool,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata denorms
    ) external {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (pool.isBound(tokens[i])) {
                if (balances[i] > pool.getBalance(tokens[i])) {
                    require(token.transferFrom(msg.sender, address(this), balances[i] - pool.getBalance(tokens[i])), "ERR_TRANSFER_FAILED");
                    _safeApprove(token, address(pool), balances[i] - pool.getBalance(tokens[i]));
                }
                if (balances[i] > 10**6) {
                    pool.rebind(tokens[i], balances[i], denorms[i]);
                } else {
                    pool.unbind(tokens[i]);
                }
            } else {
                require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
                _safeApprove(token, address(pool), balances[i]);
                pool.bind(tokens[i], balances[i], denorms[i]);
            }

            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }
        }
    }

    function finalize(LiquidityPoolActions pool) external {
        pool.finalize();
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    // --- Smart pool management ---

    function rebalance(
        IConfigurableRightsPool crp,
        address tokenA,
        address tokenB,
        uint deltaWeight,
        uint minAmountOut
    ) external {
        crp.rebalance(tokenA, tokenB, deltaWeight, minAmountOut);
    }

    function setCap(IConfigurableRightsPool crp, uint newCap) external {
        crp.setCap(newCap);
    }

    function whitelistLiquidityProvider(IConfigurableRightsPool crp, address provider) external {
        crp.whitelistLiquidityProvider(provider);
    }

    function removeWhitelistedLiquidityProvider(IConfigurableRightsPool crp, address provider) external {
        crp.removeWhitelistedLiquidityProvider(provider);
    }

    // --- Internals ---

    function _safeApprove(
        ERC20 token,
        address spender,
        uint amount
    ) internal {
        if (token.allowance(address(this), spender) > 0) {
            token.approve(spender, 0);
        }
        token.approve(spender, amount);
    }

    function _join(
        AbstractPool pool,
        address[] memory tokens,
        uint poolAmountOut,
        uint[] memory maxAmountsIn,
        address kol
    ) internal {
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), maxAmountsIn[i]), "ERR_TRANSFER_FAILED");
            _safeApprove(token, address(pool), maxAmountsIn[i]);
        }
        pool.joinPool(poolAmountOut, maxAmountsIn, kol);
        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }
        }
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function claimKolReward(address _userVault, address pool) public {
        IUserVault(_userVault).claimKolReward(pool);
    }

    function claimManagersReward(address _userVault, address pool) public {
        IUserVault(_userVault).managerClaim(pool);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";
import "../utils/DesynOwnable.sol";
import "../interfaces/IDSProxy.sol";
// Contracts
pragma experimental ABIEncoderV2;

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);
}

interface IToken {
    function decimals() external view returns (uint);
}

interface IUserVault {
    function depositToken(
        address pool,
        uint types,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface IDesynOwnable {
    function getOwners() external view returns (address[] memory);

    function getOwnerPercentage() external view returns (uint[] memory);

    function allOwnerPercentage() external view returns (uint);
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract Vault is DesynOwnable {
    using SafeMath for uint;
    using Address for address;

    ICRPFactory crpFactory;
    address public userVault;

    event ManagerRatio(address indexed caller, uint indexed amount);
    event LOGUserVaultAdr(address indexed manager, address indexed caller);
    event IssueRatio(address indexed caller, uint indexed amount);
    event RedeemRatio(address indexed caller, uint indexed amount);

    struct ClaimTokenInfo {
        address token;
        uint decimals;
        uint amount;
    }

    struct ClaimRecordInfo {
        uint time;
        ClaimTokenInfo[] tokens;
    }

    // pool of tokens
    struct PoolTokens {
        address[] tokenList;
        address[] issueTokens;
        address[] redeemTokens;
        address[] perfermanceTokens;
        uint[] managerAmount;
        uint[] issueAmount;
        uint[] redeemAmount;
        uint[] perfermanceAmount;
    }

    struct PoolStatus {
        bool couldManagerClaim;
        bool isBlackList;
    }

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) public poolsStatus;

    //history record
    mapping(address => uint) public record_number;
    mapping(address => mapping(uint => ClaimRecordInfo)) public record_List;

    //pool=>manager
    mapping(address => address) public pool_manager;

    // default ratio config
    uint public RATIO_TOTAL = 1000;
    uint public RATIO_MANAGER = 800;
    uint public RATIO_ISSUE = 800;
    uint public RATIO_REDEEM = 800;
    uint public RATIO_PERFERMANCE = 800;

    receive() external payable {}

    // 存入token
    function depositManagerToken(address[] calldata poolTokens, uint[] calldata tokensAmount) external {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(poolTokens.length == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        if (pool_manager[pool] == address(0)) {
            pool_manager[pool] = ICRPPool(pool).getController();
        }

        PoolTokens storage tokens = poolsTokens[pool];

        (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) = communaldepositToken(
            poolTokens,
            tokensAmount,
            pool,
            tokens.tokenList,
            tokens.managerAmount
        );
        tokens.tokenList = new_pool_tokenList;
        tokens.managerAmount = new_pool_tokenAmount;
        poolsStatus[pool].couldManagerClaim = true;
        if (this.isClosePool(pool)) {
            try this.managerClaim(pool) {} catch {}
        }
    }

    // 存入token
    function depositIssueRedeemPToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountIR,
        bool isPerfermance
    ) external {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(poolTokens.length == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        if (pool_manager[pool] == address(0)) {
            pool_manager[pool] = ICRPPool(pool).getController();
        }
        PoolTokens storage tokens = poolsTokens[pool];

        if (!isPerfermance) {
            (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) = communaldepositToken(
                poolTokens,
                tokensAmount,
                pool,
                tokens.issueTokens,
                tokens.issueAmount
            );
            tokens.issueTokens = new_pool_tokenList;
            tokens.issueAmount = new_pool_tokenAmount;
        } 
        if (isPerfermance) {
            (
                address[] memory new_pool_tokenList,
                uint[] memory new_pool_tokenAmount,
                address[] memory new_pool_tokenListP,
                uint[] memory new_pool_tokenAmountP
            ) = communaldepositTokenNew(poolTokens, tokensAmount, tokensAmountIR, pool);
            tokens.redeemTokens = new_pool_tokenList;
            tokens.redeemAmount = new_pool_tokenAmount;
            tokens.perfermanceTokens = new_pool_tokenListP;
            tokens.perfermanceAmount = new_pool_tokenAmountP;
        }

        poolsStatus[pool].couldManagerClaim = true;
        if (this.isClosePool(pool)) {
            try this.managerClaim(pool) {} catch {}
        }
    }

    function communaldepositToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        address poolAdr,
        address[] memory _pool_tokenList,
        uint[] memory _pool_tokenAmount
    ) internal returns (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) {
        uint len = poolTokens.length;
        //old
        //new
        new_pool_tokenList = new address[](len);
        new_pool_tokenAmount = new uint[](len);
        if ((_pool_tokenList.length == _pool_tokenAmount.length && _pool_tokenList.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < len; i++) {
                address t = poolTokens[i];
                uint tokenBalance = tokensAmount[i];
                IERC20(t).transferFrom(msg.sender, address(this), tokenBalance);
                new_pool_tokenList[i] = poolTokens[i];
                new_pool_tokenAmount[i] = tokensAmount[i];
            }
        } else {
            for (uint k = 0; k < len; k++) {
                if (_pool_tokenList[k] == poolTokens[k]) {
                    address t = poolTokens[k];
                    uint tokenBalance = tokensAmount[k];
                    IERC20(t).transferFrom(msg.sender, address(this), tokenBalance);
                    new_pool_tokenList[k] = poolTokens[k];
                    new_pool_tokenAmount[k] = _pool_tokenAmount[k].add(tokenBalance);
                }
            }
        }
        return (new_pool_tokenList, new_pool_tokenAmount);
    }

    function communaldepositTokenNew(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountIR,
        address poolAdr
    )
        internal
        returns (
            address[] memory new_pool_tokenList,
            uint[] memory new_pool_tokenAmount,
            address[] memory new_pool_tokenListP,
            uint[] memory new_pool_tokenAmountP
        )
    {
        uint len = poolTokens.length;
        //old
        //new
        new_pool_tokenList = new address[](len);
        new_pool_tokenAmount = new uint[](len);
        new_pool_tokenListP = new address[](len);
        new_pool_tokenAmountP = new uint[](len);

        PoolTokens storage tokens = poolsTokens[poolAdr];

        //issue_redeem
        if ((tokens.redeemTokens.length == tokens.redeemAmount.length && tokens.redeemTokens.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < len; i++) {
                uint tokenBalance = tokensAmount[i];
                IERC20(poolTokens[i]).transferFrom(msg.sender, address(this), tokenBalance);
                new_pool_tokenList[i] = poolTokens[i];
                new_pool_tokenAmount[i] = tokensAmountIR[i];
            }
        } else {
            for (uint k = 0; k < len; k++) {
                if (tokens.redeemTokens[k] == poolTokens[k]) {
                    uint tokenBalance = tokensAmount[k];
                    IERC20(poolTokens[k]).transferFrom(msg.sender, address(this), tokenBalance);
                    new_pool_tokenList[k] = poolTokens[k];
                    new_pool_tokenAmount[k] = tokens.perfermanceAmount[k].add(tokensAmountIR[k]);
                }
            }
        }
        //perfermance
        if ((tokens.perfermanceTokens.length == tokens.perfermanceAmount.length && tokens.perfermanceTokens.length == 0) || !poolsStatus[poolAdr].couldManagerClaim) {
            for (uint i = 0; i < len; i++) {
                new_pool_tokenListP[i] = poolTokens[i];
                new_pool_tokenAmountP[i] = tokensAmount[i].sub(tokensAmountIR[i]);
            }
        } else {
            for (uint k = 0; k < len; k++) {
                new_pool_tokenListP[k] = poolTokens[k];
                new_pool_tokenAmountP[k] = tokens.perfermanceAmount[k].add(tokensAmount[k].sub(tokensAmountIR[k]));
            }
        }

        return (new_pool_tokenList, new_pool_tokenAmount, new_pool_tokenListP, new_pool_tokenAmountP);
    }

    function poolManagerTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].tokenList;
    }

    function poolManagerTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].managerAmount;
    }

    function poolIssueTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].issueTokens;
    }

    function poolRedeemTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].redeemTokens;
    }

    function poolIssueTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].issueAmount;
    }

    function poolRedeemTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].redeemAmount;
    }

    function poolPerfermanceTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].perfermanceTokens;
    }

    function poolPerfermanceTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].perfermanceAmount;
    }

    function getManagerClaimBool(address pool) external view returns (bool bools) {
        bools = poolsStatus[pool].couldManagerClaim;
    }

    function setBlackList(address pool, bool bools) external onlyOwner {
        poolsStatus[pool].isBlackList = bools;
    }

    function setUserVaultAdr(address adr) external onlyOwner {
        require(adr != address(0), "ERR_INVALID_USERVAULT_ADDRESS");
        userVault = adr;
        emit LOGUserVaultAdr(adr, msg.sender);
    }

    function setCrpFactory(address adr) external onlyOwner {
        crpFactory = ICRPFactory(adr);
    }

    function adminClaimToken(
        address token,
        address user,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(user, amount);
    }

    function getBNB() external payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setManagerRatio(uint amount) external onlyOwner {
        require(amount <= RATIO_TOTAL, "Maximum limit exceeded");
        RATIO_MANAGER = amount;
        emit ManagerRatio(msg.sender, amount);
    }

    function setIssueRatio(uint amount) external onlyOwner {
        require(amount <= RATIO_TOTAL, "Maximum limit exceeded");
        RATIO_ISSUE = amount;
        emit IssueRatio(msg.sender, amount);
    }

    function setRedeemRatio(uint amount) external onlyOwner {
        require(amount <= RATIO_TOTAL, "Maximum limit exceeded");
        RATIO_REDEEM = amount;
        emit RedeemRatio(msg.sender, amount);
    }

    function setPerfermanceRatio(uint amount) external onlyOwner {
        RATIO_PERFERMANCE = amount;
    }

    function managerClaim(address pool) external {
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        address manager_address = ICRPPool(pool).getController();

        PoolTokens memory tokens = poolsTokens[pool];
        PoolStatus storage status = poolsStatus[pool];

        address[] memory _pool_manager_tokenList = tokens.tokenList.length != 0
            ? tokens.tokenList
            : (tokens.issueTokens.length != 0 ? tokens.issueTokens : (tokens.redeemTokens.length != 0 ? tokens.redeemTokens : tokens.perfermanceTokens));
        uint len = _pool_manager_tokenList.length;
        require(!status.isBlackList, "ERR_POOL_IS_BLACKLIST");
        require(pool_manager[pool] == manager_address, "ERR_IS_NOT_MANAGER");
        require(len > 0, "ERR_NOT_MANGER_FEE");
        require(status.couldManagerClaim, "ERR_MANAGER_COULD_NOT_CLAIM");
        status.couldManagerClaim = false;
        //record
        ClaimRecordInfo storage recordInfo = record_List[pool][record_number[pool].add(1)];
        delete recordInfo.time;
        delete recordInfo.tokens;
        recordInfo.time = block.timestamp;
        uint[] memory managerTokenAmount = new uint[](len);
        uint[] memory issueTokenAmount = new uint[](len);
        uint[] memory redeemTokenAmount = new uint[](len);
        uint[] memory perfermanceTokenAmount = new uint[](len);
        for (uint i = 0; i < len; i++) {
            uint balance;
            ClaimTokenInfo memory tokenInfo;
            (balance, managerTokenAmount[i], issueTokenAmount[i], redeemTokenAmount[i], perfermanceTokenAmount[i]) = computeBalance(i, pool);
            address t = _pool_manager_tokenList[i];
            tokenInfo.token = t;
            tokenInfo.amount = balance;
            tokenInfo.decimals = IToken(t).decimals();
            recordInfo.tokens.push(tokenInfo);
            transferHandle(pool, manager_address, t, balance);
        }
        if (this.isClosePool(pool)) {
            recordUserVault(pool, _pool_manager_tokenList, managerTokenAmount, issueTokenAmount, redeemTokenAmount, perfermanceTokenAmount);
        }

        record_number[pool] = record_number[pool].add(1);
        record_List[pool][record_number[pool]] = recordInfo;
        clearPool(pool);
    }

    function recordUserVault(
        address pool,
        address[] memory tokenList,
        uint[] memory managerTokenAmount,
        uint[] memory issueTokenAmount,
        uint[] memory redeemTokenAmount,
        uint[] memory perfermanceTokenAmount
    ) internal {
        PoolTokens memory tokens = poolsTokens[pool];

        if (tokens.managerAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 0, tokenList, managerTokenAmount);
        }
        if (tokens.issueAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 1, tokenList, issueTokenAmount);
        }
        if (tokens.redeemAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 2, tokenList, redeemTokenAmount);
        }
        if (tokens.perfermanceAmount.length != 0) {
            IUserVault(userVault).depositToken(pool, 3, tokenList, perfermanceTokenAmount);
        }
    }

    function transferHandle(
        address pool,
        address manager_address,
        address t,
        uint balance
    ) internal {
        bool isCloseETF = this.isClosePool(pool);
        bool isOpenETF = !isCloseETF;
        bool isContractManager = manager_address.isContract();

        if(isCloseETF){
            IERC20(t).transfer(userVault, balance);
        }

        if(isOpenETF && isContractManager){
            address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
            uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
            uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

            for (uint k = 0; k < managerAddressList.length; k++) {
                address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
                IERC20(t).transfer(reciver, balance.mul(ownerPercentage[k]).div(allOwnerPercentage));
            }
        }

        if(isOpenETF && !isContractManager){
            IERC20(t).transfer(manager_address, balance);
        }
    }

    function computeBalance(uint i, address pool)
        internal
        view
        returns (
            uint balance,
            uint balanceOne,
            uint balanceTwo,
            uint balanceThree,
            uint balanceFour
        )
    {
        PoolTokens memory tokens = poolsTokens[pool];

        //manager fee
        if (tokens.managerAmount.length != 0) {
            balanceOne = tokens.managerAmount[i].mul(RATIO_MANAGER).div(RATIO_TOTAL);
            balance = balance.add(balanceOne);
        }
        if (tokens.issueAmount.length != 0) {
            balanceTwo = tokens.issueAmount[i].mul(RATIO_ISSUE).div(RATIO_TOTAL);
            balance = balance.add(balanceTwo);
        }
        if (tokens.redeemAmount.length != 0) {
            balanceThree = tokens.redeemAmount[i].mul(RATIO_REDEEM).div(RATIO_TOTAL);
            balance = balance.add(balanceThree);
        }
        if (tokens.perfermanceAmount.length != 0) {
            balanceFour = tokens.perfermanceAmount[i].mul(RATIO_PERFERMANCE).div(RATIO_TOTAL);
            balance = balance.add(balanceFour);
        }
    }

    function isClosePool(address pool) external view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function clearPool(address pool) internal {
        delete poolsTokens[pool];
    }

    function managerClaimRecordList(address pool) external view returns (ClaimRecordInfo[] memory claimRecordInfos) {
        uint num = record_number[pool];
        ClaimRecordInfo[] memory records = new ClaimRecordInfo[](num);
        for (uint i = 1; i < num + 1; i++) {
            ClaimRecordInfo memory record;
            record = record_List[pool][i];
            records[i.sub(1)] = record;
        }
        return records;
    }

    function managerClaimList(address pool) external view returns (ClaimTokenInfo[] memory claimTokenInfos) {
        PoolTokens memory tokens = poolsTokens[pool];
        address[] memory _pool_manager_tokenList = tokens.tokenList.length != 0
            ? tokens.tokenList
            : (tokens.issueTokens.length != 0 ? tokens.issueTokens : (tokens.redeemTokens.length != 0 ? tokens.redeemTokens : tokens.perfermanceTokens));
        uint len = _pool_manager_tokenList.length;

        ClaimTokenInfo[] memory infos = new ClaimTokenInfo[](len);
        for (uint i = 0; i < len; i++) {
            {
                ClaimTokenInfo memory tokenInfo;
                tokenInfo.token = _pool_manager_tokenList[i];

                (uint balance,,,,) = computeBalance(i,pool);
                tokenInfo.amount = balance;
                tokenInfo.decimals = IToken(_pool_manager_tokenList[i]).decimals();
                
                infos[i] = tokenInfo;
            }
        }

        return infos;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IDSProxy {
    function owner() external view returns(address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint toDeleteIndex = valueIndex - 1;
            uint lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function addValue(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint index) internal view returns (address) {
        return address(uint160(uint(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";
import "../utils/DesynOwnable.sol";
import "../libraries/SmartPoolManager.sol";
// Contracts
pragma experimental ABIEncoderV2;

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);

    function isCompletedCollect() external view returns (bool);
}

interface IToken {
    function decimals() external view returns (uint);
}

interface IDesynOwnable {
    function adminList(address adr) external view returns (bool);

    function getController() external view returns (address);

    function getOwners() external view returns (address[] memory);

    function getOwnerPercentage() external view returns (uint[] memory);

    function allOwnerPercentage() external view returns (uint);
}

interface IDSProxy {
    function owner() external view returns (address);
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract UserVault is DesynOwnable {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    ICRPFactory crpFactory;
    address public vaultAddress;

    event LOGVaultAdr(address indexed manager, address indexed caller);

    struct ClaimTokenInfo {
        address token;
        uint decimals;
        uint amount;
    }

    struct ClaimRecordInfo {
        uint time;
        ClaimTokenInfo[] tokens;
    }

    // pool of tokens
    struct PoolTokens {
        address[] tokenList;
        address[] issueTokens;
        address[] redeemTokens;
        address[] perfermanceTokens;
        uint[] managerAmount;
        uint[] issueAmount;
        uint[] redeemAmount;
        uint[] perfermanceAmount;
    }

    struct PoolStatus {
        bool couldManagerClaim;
        bool isBlackList;
        bool isSetParams;
        SmartPoolManager.KolPoolParams kolPoolConfig;
    }

    // kol list
    struct KolUserInfo {
        address userAdr;
        uint[] userAmount;
    }

    //pool=>manager
    mapping(address => address) public pool_manager;

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) poolsStatus;

    //history record
    mapping(address => uint) public record_number;
    mapping(address => mapping(uint => ClaimRecordInfo)) public record_List;

    //pool => tokenList
    mapping(address => address[]) public kol_token_list;

    //pool => initTotalAmount[]
    mapping(address => uint) public init_totalAmount_list;
    //pool => manager => uint
    mapping(address => mapping(address => uint)) public manager_claimed_list;
    mapping(address => uint) public pool_manangerHasClaimed;

    //pool => kol[]
    mapping(address => EnumerableSet.AddressSet) kols_list;
    //pool => kol =>uint
    mapping(address => mapping(address => uint)) public kol_claimed_list;
    //pool => kol => totalAmount[]
    mapping(address => mapping(address => uint[])) public kol_totalAmount_list;
    // pool => kol => KolUserInfo[]
    mapping(address => mapping(address => KolUserInfo[])) public kol_user_info;

    //pool => user => index
    mapping(address => mapping(address => uint)) public user_index_list;
    // pool => user => kol
    mapping(address => mapping(address => address)) public user_kol_list;

    uint public RATIO_TOTAL = 100;

    receive() external payable {}

    function depositToken(
        address pool,
        uint types,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external onlyVault {
        require(poolTokens.length == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        if (pool_manager[pool] == address(0)) {
            pool_manager[pool] = ICRPPool(pool).getController();
        }
        (address[] memory _pool_tokenList, uint[] memory _pool_tokenAmount) = createTokenParams(pool, types);
        (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) = communaldepositToken(poolTokens, tokensAmount, pool, _pool_tokenList, _pool_tokenAmount);
        setResult(pool, types, new_pool_tokenList, new_pool_tokenAmount);
        poolsStatus[pool].couldManagerClaim = true;
    }

    function claimKolReward(address pool) external {
        try IVault(vaultAddress).managerClaim(pool) {} catch {}
        if (this.isClosePool(pool)) {
            require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
            require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
            uint totalAmount = this.kolUnClaimAmount(pool, msg.sender);
            require(totalAmount > 0, "ERR_HAS_NO_REWARD");

            kol_claimed_list[pool][msg.sender] += totalAmount;
            if (address(msg.sender).isContract()) {
                IERC20(kol_token_list[pool][0]).transfer(IDSProxy(msg.sender).owner(), totalAmount);
            } else {
                IERC20(kol_token_list[pool][0]).transfer(msg.sender, totalAmount);
            }
        }
    }
    // for the mananger
    // function managerClaim(address pool) external {
    //     try IVault(vaultAddress).managerClaim(pool) {} catch {}
    //     if (this.isClosePool(pool)) {
    //         require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
    //         require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
    //         require(IDesynOwnable(pool).adminList(msg.sender) || IDesynOwnable(pool).getController() == msg.sender, "Not Owner");
    //         uint totalAmount = this.getUnManagerReward(pool, msg.sender);
    //         require(totalAmount > 0, "ERR_HAS_NO_REWARD");
    //         poolsStatus[pool].couldManagerClaim = false;
    //         manager_claimed_list[pool][msg.sender] += totalAmount; // for the manager
            
    //         uint newIndex = record_number[pool].add(1);
    //         address issueToken = kol_token_list[pool][0];
    //         address receiver = address(msg.sender).isContract()? IDSProxy(msg.sender).owner(): msg.sender;

    //         ClaimTokenInfo memory recordToken;
    //         recordToken.decimals = IERC20(issueToken).decimals();
    //         recordToken.token = issueToken;
    //         recordToken.amount = totalAmount;
            
    //         IERC20(issueToken).transfer(receiver, totalAmount);
    //         // record manager claim history
    //         record_number[pool] = newIndex;
    //         record_List[pool][newIndex].time = block.timestamp;
    //         record_List[pool][newIndex].tokens.push(recordToken);
    //     }
    // }
    // for all manager
    function managerClaim(address pool) external {
        try IVault(vaultAddress).managerClaim(pool) {} catch {}
        if (this.isClosePool(pool)) {
            require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
            require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
            require(IDesynOwnable(pool).adminList(msg.sender) || IDesynOwnable(pool).getController() == msg.sender, "Not Owner");
            uint totalAmount = this.getUnManagerReward(pool); // for all manager unclaim
            require(totalAmount > 0, "ERR_HAS_NO_REWARD");
            poolsStatus[pool].couldManagerClaim = false;

            pool_manangerHasClaimed[pool] += totalAmount; // for all manager
            
            uint newIndex = record_number[pool].add(1);
            address issueToken = kol_token_list[pool][0];

            ClaimTokenInfo memory recordToken;
            recordToken.decimals = IERC20(issueToken).decimals();
            recordToken.token = issueToken;
            recordToken.amount = totalAmount;
            
            _transferHandle(pool, msg.sender, issueToken, totalAmount);
            // record manager claim history
            record_number[pool] = newIndex;
            record_List[pool][newIndex].time = block.timestamp;
            record_List[pool][newIndex].tokens.push(recordToken);
        }
    }

    function _transferHandle(
        address pool,
        address manager_address,
        address t,
        uint balance
    ) internal {
        address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
        uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
        uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

        for (uint k = 0; k < managerAddressList.length; k++) {
            address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
            IERC20(t).transfer(reciver, balance.mul(ownerPercentage[k]).div(allOwnerPercentage));
        }
    }

    function managerClaimRecordList(address pool) external view returns (ClaimRecordInfo[] memory claimRecordInfos) {
        uint num = record_number[pool];
        ClaimRecordInfo[] memory records = new ClaimRecordInfo[](num);
        for (uint i = 1; i < num + 1; i++) {
            ClaimRecordInfo memory record;
            record = record_List[pool][i];
            records[i.sub(1)] = record;
        }
        return records;
    }

    // for all manager
    function getManagerReward(address pool) external view returns (uint) {
        return this.getPoolAllFee(pool).sub(this.getAllKolReward(pool));
    }
    // for all manager
    function getUnManagerReward(address pool) external view returns (uint) {
        return this.getManagerReward(pool).sub(pool_manangerHasClaimed[pool]);
    }
    // for all manager
    function managerClaimList(address pool) external view returns (ClaimTokenInfo[1] memory) {
        ClaimTokenInfo memory token;
        address issueToken = kol_token_list[pool][0];

        token.token = issueToken;
        token.amount = this.getUnManagerReward(pool);
        token.decimals = IERC20(issueToken).decimals();
        ClaimTokenInfo[1] memory tokens = [token]; // for front-end call same as vault
        return tokens;
    }

    // for the manager
    function getManagerReward(address pool, address maragerAdr) external view returns (uint) {
        uint totalAmount = this.getManagerReward(pool);
        address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
        uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
        uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();
        for (uint k = 0; k < managerAddressList.length; k++) {
            if (maragerAdr == managerAddressList[k]) {
                return totalAmount.mul(ownerPercentage[k]).div(allOwnerPercentage);
            }
        }
    }
    // for the manager
    function getUnManagerReward(address pool, address maragerAdr) external view returns (uint) {
        return this.getManagerReward(pool, maragerAdr).sub(manager_claimed_list[pool][maragerAdr]);
    }
    // for the manager
    // function managerClaimList(address pool, address userProxy) external view returns (ClaimTokenInfo[1] memory) {
    //     ClaimTokenInfo memory token;
    //     address issueToken = kol_token_list[pool][0];

    //     token.token = issueToken;
    //     token.amount = this.getUnManagerReward(pool, userProxy);
    //     token.decimals = IERC20(issueToken).decimals();
    //     ClaimTokenInfo[1] memory tokens = [token]; // for front-end call same as vault
    //     return tokens;
    // }

    function getPoolAllFee(address pool) external view returns (uint totalAmount) {
        PoolTokens memory tokens = poolsTokens[pool];
        totalAmount += tokens.managerAmount.length > 0 ? tokens.managerAmount[0] : 0;
        totalAmount += tokens.issueAmount.length > 0 ? tokens.issueAmount[0] : 0;
        totalAmount += tokens.redeemAmount.length > 0 ? tokens.redeemAmount[0] : 0;
        totalAmount += tokens.perfermanceAmount.length > 0 ? tokens.perfermanceAmount[0] : 0;
    }

    function getAllKolReward(address pool) external view returns (uint totalAmount) {
        EnumerableSet.AddressSet storage list = kols_list[pool];
        uint len = list.length();
        for (uint i = 0; i < len; i++) {
            totalAmount += this.kolClaimTotal(pool, list.at(i));
        }
    }

    function kolUnClaimAmount(address pool, address kol) external view returns (uint) {
        uint totalClaim = this.kolClaimTotal(pool, kol);
        uint totalClaimed = kol_claimed_list[pool][kol];
        return totalClaim.sub(totalClaimed);
    }

    function kolClaimTotal(address pool, address kol) external view returns (uint) {
        uint totalFee;
        if (kol_totalAmount_list[pool][kol].length == 0) return totalFee;
        totalFee = totalFee.add(this._computeReward(pool, kol, 0));
        totalFee = totalFee.add(this._computeReward(pool, kol, 1));
        totalFee = totalFee.add(this._computeReward(pool, kol, 2));
        totalFee = totalFee.add(this._computeReward(pool, kol, 3));
        totalFee = totalFee.mul(kol_totalAmount_list[pool][kol][0]).div(init_totalAmount_list[pool]);
        return totalFee;
    }

    function _computeReward(
        address pool,
        address kol,
        uint types
    ) external view returns (uint) {
        uint kolTotalAmount = kol_totalAmount_list[pool][kol].length > 0 ? kol_totalAmount_list[pool][kol][0] : 0;
        SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;
        uint totalFee;

        PoolTokens memory tokens = poolsTokens[pool];

        if(kolTotalAmount == 0){
            return 0;
        }

        if (types == 0 && tokens.managerAmount.length > 0) {
            totalFee = tokens.managerAmount[0].mul(levelJudge(kolTotalAmount, params.managerFee)).div(RATIO_TOTAL);
        }  
        if (types == 1 && tokens.issueAmount.length > 0) {
            totalFee = tokens.issueAmount[0].mul(levelJudge(kolTotalAmount, params.issueFee)).div(RATIO_TOTAL);
        } 
        if (types == 2 && tokens.redeemAmount.length > 0) {
            totalFee = tokens.redeemAmount[0].mul(levelJudge(kolTotalAmount, params.redeemFee)).div(RATIO_TOTAL);
        }  
        if (types == 3 && tokens.perfermanceAmount.length > 0) {
            totalFee = tokens.perfermanceAmount[0].mul(levelJudge(kolTotalAmount, params.perfermanceFee)).div(RATIO_TOTAL);
        }
        return totalFee;
    }

    function levelJudge(uint amount, SmartPoolManager.feeParams memory _feeParams) internal view returns (uint) {
        for (uint i = 0; i < 4; i++) {
            if (i == 0) {
                if (_feeParams.firstLevel.level <= amount && amount < _feeParams.secondLevel.level) {
                    return _feeParams.firstLevel.ratio;
                }
            }
            if (i == 1) {
                if (_feeParams.secondLevel.level <= amount && amount < _feeParams.thirdLevel.level) {
                    return _feeParams.secondLevel.ratio;
                }
            }
            if (i == 2) {
                if (_feeParams.thirdLevel.level <= amount && amount < _feeParams.fourLevel.level) {
                    return _feeParams.thirdLevel.ratio;
                }
            }
            if (i == 3) {
                if (_feeParams.fourLevel.level <= amount) {
                    return _feeParams.fourLevel.ratio;
                }
            }
        }
    }

    function setResult(
        address pool,
        uint types,
        address[] memory new_pool_tokenList,
        uint[] memory new_pool_tokenAmount
    ) internal {
        PoolTokens storage tokens = poolsTokens[pool];
        if (types == 0) {
            tokens.tokenList = new_pool_tokenList;
            tokens.managerAmount = new_pool_tokenAmount;
        }  
        if (types == 1) {
            tokens.issueTokens = new_pool_tokenList;
            tokens.issueAmount = new_pool_tokenAmount;
        }  
        if (types == 2) {
            tokens.redeemTokens = new_pool_tokenList;
            tokens.redeemAmount = new_pool_tokenAmount;
        }  
        if (types == 3) {
            tokens.perfermanceTokens = new_pool_tokenList;
            tokens.perfermanceAmount = new_pool_tokenAmount;
        }
    }

    function createTokenParams(address pool, uint types) internal view returns (address[] memory _pool_tokenList, uint[] memory _pool_tokenAmount) {
        require(0 <= types && types < 4, "ERR_TYPES");
        
        PoolTokens memory tokens = poolsTokens[pool];
        if (types == 0) {
            _pool_tokenList = tokens.tokenList;
            _pool_tokenAmount = tokens.managerAmount;
        }
        if (types == 1) {
            _pool_tokenList = tokens.issueTokens;
            _pool_tokenAmount = tokens.issueAmount;
        }
        if (types == 2) {
            _pool_tokenList = tokens.redeemTokens;
            _pool_tokenAmount = tokens.redeemAmount;
        }
        if (types == 3) {
            _pool_tokenList = tokens.perfermanceTokens;
            _pool_tokenAmount = tokens.perfermanceAmount;
        }
    }

    function communaldepositToken(
        address[] calldata poolTokens,
        uint[] calldata tokensAmount,
        address poolAdr,
        address[] memory _pool_tokenList,
        uint[] memory _pool_tokenAmount
    ) internal view returns (address[] memory new_pool_tokenList, uint[] memory new_pool_tokenAmount) {
        uint len = poolTokens.length;
        //old
        //new
        new_pool_tokenList = new address[](len);
        new_pool_tokenAmount = new uint[](len);
        
        if (_pool_tokenAmount.length == 0  && _pool_tokenList.length == 0) {
            for (uint i = 0; i < len; i++) {
                // uint tokenBalance = tokensAmount[i];
                new_pool_tokenList[i] = poolTokens[i];
                new_pool_tokenAmount[i] = tokensAmount[i];
            }
        } else {
            for (uint k = 0; k < len; k++) {
                if (_pool_tokenList[k] == poolTokens[k]) {
                    uint tokenBalance = tokensAmount[k];
                    new_pool_tokenList[k] = poolTokens[k];
                    new_pool_tokenAmount[k] = _pool_tokenAmount[k].add(tokenBalance);
                }
            }
        }
        return (new_pool_tokenList, new_pool_tokenAmount);
    }

    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external {
        address pool = msg.sender;
        uint len = poolTokens.length;
        require(len == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        if (kol_token_list[pool].length == 0) {
            kol_token_list[pool] = poolTokens;
        }
        address newKol = user_kol_list[pool][user];
        if (user_kol_list[pool][user] == address(0)) {
            user_kol_list[pool][user] = kol;
            if (!kols_list[pool].contains(kol)) {
                kols_list[pool].addValue(kol);
            }
            newKol = kol;
        }
        require(newKol != address(0), "ERR_INVALID_KOL_ADDRESS");
        //total amount record
        init_totalAmount_list[pool] = init_totalAmount_list[pool].add(tokensAmount[0]);
        uint[] memory totalAmounts = new uint[](len);
        for (uint i = 0; i < len; i++) {
            if (kol_totalAmount_list[pool][newKol].length == 0) {
                totalAmounts[i] = tokensAmount[i];
            } else {
                totalAmounts[i] = tokensAmount[i].add(kol_totalAmount_list[pool][newKol][i]);
            }
        }
        kol_totalAmount_list[pool][newKol] = totalAmounts;
        //kol user info record
        KolUserInfo[] storage userInfoArray = kol_user_info[pool][newKol];
        uint index = user_index_list[pool][user];
        if (index == 0) {
            KolUserInfo memory userInfo;
            userInfo.userAdr = user;
            userInfo.userAmount = tokensAmount;
            userInfoArray.push(userInfo);
            user_index_list[pool][user] = userInfoArray.length;
        } else {
            KolUserInfo storage userInfo = kol_user_info[pool][newKol][index - 1];
            for (uint a = 0; a < userInfo.userAmount.length; a++) {
                userInfo.userAmount[a] = userInfo.userAmount[a].add(tokensAmount[a]);
            }
        }
    }

    function setPoolParams(address pool, SmartPoolManager.KolPoolParams memory _poolParams) external onlyCrpFactory {
        PoolStatus storage status = poolsStatus[pool];
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(!status.isSetParams, "ERR_HAS_SETED");

        status.isSetParams = true;
        status.kolPoolConfig = _poolParams;
    }

    function isClosePool(address pool) external view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function getKolsAdr(address pool) external view returns (address[] memory) {
        return kols_list[pool].values();
    }

    function getPoolUserList(address pool) external view returns (address[] memory tokenList) {
        return kol_token_list[pool];
    }

    function getPoolUserKolAdr(address pool, address user) external view returns (address tokenAddress) {
        return user_kol_list[pool][user];
    }

    function getPoolKolUserInfo(address pool, address kol) external view returns (KolUserInfo[] memory info) {
        return kol_user_info[pool][kol];
    }

    function getPoolKolTotalAmounts(address pool, address kol) external view returns (uint[] memory) {
        return kol_totalAmount_list[pool][kol];
    }

    function poolManagerTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].tokenList;
    }

    function poolManagerTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].managerAmount;
    }

    function poolIssueTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].issueTokens;
    }

    function poolRedeemTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].redeemTokens;
    }

    function poolIssueTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].issueAmount;
    }

    function poolRedeemTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].redeemAmount;
    }

    function poolPerfermanceTokenList(address pool) external view returns (address[] memory tokens) {
        return poolsTokens[pool].perfermanceTokens;
    }

    function poolPerfermanceTokenAmount(address pool) external view returns (uint[] memory tokenAmount) {
        return poolsTokens[pool].perfermanceAmount;
    }

    function getManagerClaimBool(address pool) external view returns (bool bools) {
        bools = poolsStatus[pool].couldManagerClaim;
    }

    function setBlackList(address pool, bool bools) external onlyOwner {
        poolsStatus[pool].isBlackList = bools;
    }

    function setCrpFactory(address adr) external onlyOwner {
        crpFactory = ICRPFactory(adr);
    }

    function adminClaimToken(
        address token,
        address user,
        uint amount
    ) external onlyOwner {
        IERC20(token).transfer(user, amount);
    }

    function getBNB() external payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setVaultAdr(address adr) external onlyOwner {
        require(adr != address(0), "ERR_INVALID_VAULT_ADDRESS");
        vaultAddress = adr;
        emit LOGVaultAdr(adr, msg.sender);
    }

    modifier onlyCrpFactory() {
        require(address(crpFactory) == msg.sender, "ERR_NOT_CRP_FACTORY");
        _;
    }

    modifier onlyVault() {
        require(vaultAddress == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }
}