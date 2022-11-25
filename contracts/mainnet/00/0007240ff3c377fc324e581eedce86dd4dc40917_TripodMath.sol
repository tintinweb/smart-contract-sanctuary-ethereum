/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// File: .deps/TripodMath.sol


pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;





interface IFeedRegistry {
    function getFeed(address, address) external view returns (address);
    function latestRoundData(address, address) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}





// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)



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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}






interface ITripod{
    function pool() external view returns(address);
    function tokenA() external view returns (address);
    function balanceOfA() external view returns(uint256);
    function tokenB() external view returns (address);
    function balanceOfB() external view returns(uint256);
    function tokenC() external view returns (address);
    function balanceOfC() external view returns(uint256);
    function invested(address) external view returns(uint256);
    function totalLpBalance() external view returns(uint256);
    function investedWeight(address)external view returns(uint256);
    function quote(address, address, uint256) external view returns(uint256);
    function usingReference() external view returns(bool);
    function referenceToken() external view returns(address);
    function balanceOfTokensInLP() external view returns(uint256, uint256, uint256);
    function getRewardTokens() external view returns(address[] memory);
    function pendingRewards() external view returns(uint256[] memory);
}

interface IBalancerTripod is ITripod{
    //Struct for each bb pool that makes up the main pool
    struct PoolInfo {
        address token;
        address bbPool;
        bytes32 poolId;
    }
    function poolInfo(uint256) external view returns(PoolInfo memory);
    function curveIndex(address) external view returns(int128);
    function poolId() external view returns(bytes32);
    function toSwapToIndex() external view returns(uint256); 
    function toSwapToPoolId() external view returns(bytes32);
}

/// @title Tripod Math
/// @notice Contains the Rebalancing Logic and Math for the Tripod Base. Used during both the rebalance and quote rebalance functions
library TripodMath {

    /*
    * @notice
    *   The rebalancing math aims to have each tokens relative return be equal after the rebalance irregardless of the strating weights or exchange rates
    *   These functions are called during swapOneToTwo() or swapTwoToOne() in the Tripod.sol https://github.com/Schlagonia/Tripod/blob/master/src/Tripod.sol
    *   All math was adopted from the original joint strategies https://github.com/fp-crypto/joint-strategy

        All equations will use the following variables:
            a0 = The invested balance of the first token
            a1 = The ending balance of the first token
            b0 = The invested balance of the second token
            b1 = The ending balance of the second token
            c0 = the invested balance of the third token
            c1 = The ending balance of the third token
            eOfB = The exchange rate of either a => b or b => a depending on which way we are swapping
            eOfC = The exchange rate of either a => c or c => a depending on which way we are swapping
            precision = 10 ** first token decimals
            precisionB = 10 ** second token decimals
            precisionC = 10 ** third token decimals

            Variables specific to swapOneToTwo()
            n = The amount of a token we will be selling
            p = The % of n we will be selling from a => b

            Variables specific to swapTwoToOne()
            nb = The amount of b we will be swapping to a
            nc = The amount of c we will be swapping to a 

        The starting equations that all of the following are derived from is:

         a1 - n       b1 + eOfB*n*p      c1 + eOfC*n*(1-p) 
        --------  =  --------------  =  -------------------
           a0              b0                   c0

    */

    struct RebalanceInfo {
        uint256 precisionA;
        uint256 a0;
        uint256 a1;
        uint256 b0;
        uint256 b1;
        uint256 eOfB;
        uint256 precisionB;
        uint256 c0;
        uint256 c1;
        uint256 eOfC;
        uint256 precisionC;
    }   

    struct Tokens {
        address tokenA;
        uint256 ratioA;
        address tokenB;
        uint256 ratioB;
        address tokenC;
        uint256 ratioC;
    }
    
    uint256 private constant RATIO_PRECISION = 1e18;
    /*
    * @notice
    *   Internal function to be called during swapOneToTwo to return n: the amount of a to sell and p: the % of n to sell to b
    * @param info, Rebalance info struct with all needed variables
    * @return n, The amount of a to sell
    * @return p, The percent of a we will sell to b repersented as 1e18. i.e. 50% == .5e18
    */
    function getNandP(RebalanceInfo memory info) public pure returns(uint256 n, uint256 p) {
        p = getP(info);
        n = getN(info, p);
    }

    /*
    * @notice
    *   Internal function used to calculate the percent of n that will be sold to b
    *   p is repersented as 1e18
    * @param info, RebalanceInfo stuct
    * @return the percent of a to sell to b as 1e18
    */
    function getP(RebalanceInfo memory info) public pure returns (uint256 p) {
        /*
        *             a1*b0*eOfC + b0c1 - b1c0 - a0*b1*eOfC
        *   p = ----------------------------------------------------
        *        a1*c0*eOfB + a1*b0*eOfC - a0*c1*eOfB - a0*b1*eOfC
        */
        unchecked {
            //pre-calculate a couple of parts that are used twice
            //var1 = a0*b1*eOfC
            uint256 var1 = info.a0 * info.b1 * info.eOfC / info.precisionA;
            //var2 = a1*b0*eOfC
            uint256 var2 = info.a1 * info.b0 * info.eOfC / info.precisionA;

            uint256 numerator = var2 + (info.b0 * info.c1) - (info.b1 * info.c0) - var1;

            uint256 denominator = 
                (info.a1 * info.c0 * info.eOfB / info.precisionA) + 
                    var2 - 
                        (info.a0 * info.c1 * info.eOfB / info.precisionA) - 
                            var1;
    
            p = numerator * 1e18 / denominator;
        }
    }

    /*
    * @notice
    *   Internal function used to calculate the amount of a to sell once p has been calculated
    *   Converts all uint's to int's because the numerator will be negative
    * @param info, RebalanceInfo stuct
    * @param p, % calculated to of b to sell to a in 1e18
    * @return The amount of a to sell
    */
    function getN(RebalanceInfo memory info, uint256 p) public pure returns(uint256) {
        /*
        *          (a1*b0) - (a0*b1)  
        *    n = -------------------- 
        *           b0 + eOfB*a0*P
        */
        unchecked{
            uint256 numerator = 
                (info.a1 * info.b0) -
                    (info.a0 * info.b1);

            uint256 denominator = 
                (info.b0 * 1e18) + 
                    (info.eOfB * info.a0 / info.precisionA * p);

            return numerator * 1e18 / denominator;
        }
    }

    /*
    * @notice
    *   Internal function used to calculate the _nb: the amount of b to sell to a
    *       and nc : the amount of c to sell to a. For the swapTwoToOne() function.
    *   The calculations for both b and c use the same denominator and the numerator is the same consturction but the variables for b or c are swapped 
    * @param info, RebalanceInfo stuct
    * @return _nb, the amount of b to sell to a in terms of b
    * @return nc, the amount of c to sell to a in terms of c 
    */
    function getNbAndNc(RebalanceInfo memory info) public pure returns(uint256 nb, uint256 nc) {
        /*
        *          a0*x1 + y0*eOfy*x1 - a1*x0 - y1*eOfy*x0
        *   nx = ------------------------------------------
        *               a0 + eOfc*c0 + b0*eOfb
        */
        unchecked {
            uint256 numeratorB = 
                (info.a0 * info.b1) + 
                    (info.c0 * info.eOfC * info.b1 / info.precisionC) - 
                        (info.a1 * info.b0) - 
                            (info.c1 * info.eOfC * info.b0 / info.precisionC);

            uint256 numeratorC = 
                (info.a0 * info.c1) + 
                    (info.b0 * info.eOfB * info.c1 / info.precisionB) - 
                        (info.a1 * info.c0) - 
                            (info.b1 * info.eOfB * info.c0 / info.precisionB);

            uint256 denominator = 
                info.a0 + 
                    (info.eOfC * info.c0 / info.precisionC) + 
                        (info.b0 * info.eOfB / info.precisionB);

            nb = numeratorB / denominator;
            nc = numeratorC / denominator;
        }
    }

    /*
     * @notice
     *  Function available publicly estimating the balancing ratios for the tokens in the form:
     * ratio = currentBalance / invested Balance
     * @param startingA, the invested balance of TokenA
     * @param currentA, current balance of tokenA
     * @param startingB, the invested balance of TokenB
     * @param currentB, current balance of tokenB
     * @param startingC, the invested balance of TokenC
     * @param currentC, current balance of tokenC
     * @return _a, _b _c, ratios for tokenA tokenB and tokenC. Will return 0's if there is nothing invested
     */
    function getRatios(
        uint256 startingA,
        uint256 currentA,
        uint256 startingB,
        uint256 currentB,
        uint256 startingC,
        uint256 currentC
    ) public pure returns (uint256 _a, uint256 _b, uint256 _c) {
        unchecked {
            _a = (currentA * RATIO_PRECISION) / startingA;
            _b = (currentB * RATIO_PRECISION) / startingB;
            _c = (currentC * RATIO_PRECISION) / startingC;
        }
    }

    /*
    * @notice 
    *   Internal function called when a new position has been opened to store the relative weights of each token invested
    *   uses the most recent oracle price to get the dollar value of the amount invested. This is so the rebalance function
    *   can work with different dollar amounts invested upon lp creation
    * @param investedA, the amount of tokenA that was invested
    * @param investedB, the amount of tokenB that was invested
    * @param investedC, the amoun of tokenC that was invested
    * @return, the relative weight for each token expressed as 1e18
    */
    function getWeights(
        uint256 investedA,
        uint256 investedB,
        uint256 investedC
    ) public view returns (uint256 wA, uint256 wB, uint256 wC) {
        ITripod tripod = ITripod(address(this));
        unchecked {
            uint256 adjustedA = getOraclePrice(tripod.tokenA(), investedA);
            uint256 adjustedB = getOraclePrice(tripod.tokenB(), investedB);
            uint256 adjustedC = getOraclePrice(tripod.tokenC(), investedC);
            uint256 total = adjustedA + adjustedB + adjustedC; 
                        
            wA = adjustedA * RATIO_PRECISION / total;
            wB = adjustedB * RATIO_PRECISION / total;
            wC = adjustedC * RATIO_PRECISION / total;
        }
    }

    /*
    * @notice
    *   Returns the oracle adjusted price for a specific token and amount expressed in the oracle terms of 1e8
    *   This uses the chainlink feed Registry and returns in terms of the USD
    * @param _token, the address of the token to get the price for
    * @param _amount, the amount of the token we have
    * @return USD price of the _amount of the token as 1e8
    */
    function getOraclePrice(address _token, uint256 _amount) public view returns(uint256) {
        address token = _token;
        //Adjust if we are using WETH of WBTC for chainlink to work
        if(_token == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        if(_token == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) token = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

        (uint80 roundId, int256 price,, uint256 updateTime, uint80 answeredInRound) = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf).latestRoundData(
                token,
                address(0x0000000000000000000000000000000000000348) // USD
            );

        require(price > 0 && updateTime != 0 && answeredInRound >= roundId);
        //return the dollar amount to 1e8
        return uint256(price) * _amount / (10 ** IERC20Extended(_token).decimals());
    }

    /*
    * @notice
    *   Function to be called during harvests that attempts to rebalance all 3 tokens evenly
    *   in comparision to the amounts the started with, i.e. return the same % return
    * @return uint8 that corresponds to what action Tripod should take, 0 means no swaps,
    *   1 means swap one token to the other two and 2 means swap two to the other one
    *   The tokens are returned in order of how they should be swapped
    */
    function rebalance() public view returns(uint8, address, address, address){
        ITripod tripod = ITripod(address(this));
        //We use the tokens struct to cache our variables and avoid stack to deep
        Tokens memory tokens = Tokens(tripod.tokenA(), 0, tripod.tokenB(), 0, tripod.tokenC(), 0);

        (tokens.ratioA, tokens.ratioB, tokens.ratioC) = getRatios(
                    tripod.invested(tokens.tokenA),
                    tripod.balanceOfA(),
                    tripod.invested(tokens.tokenB),
                    tripod.balanceOfB(),
                    tripod.invested(tokens.tokenC),
                    tripod.balanceOfC()
                );
        
        //If they are all the same or very close we dont need to do anything
        if(isCloseEnough(tokens.ratioA, tokens.ratioB) && isCloseEnough(tokens.ratioB, tokens.ratioC)) {
            //Return a 0 for direction to do nothing
            return(0, tokens.tokenA, tokens.tokenB, tokens.tokenC);
        }
        // Calculate the average ratio. Could be at a loss does not matter here
        uint256 avgRatio;
        unchecked{
            avgRatio = (tokens.ratioA * tripod.investedWeight(tokens.tokenA) + 
                            tokens.ratioB * tripod.investedWeight(tokens.tokenB) + 
                                tokens.ratioC * tripod.investedWeight(tokens.tokenC)) / 
                                    RATIO_PRECISION;
        }
        //If only one is higher than the average ratio, then ratioX - avgRatio is split between the other two in relation to their diffs
        //If two are higher than the average each has its diff traded to the third
        //We know all three cannot be above the avg
        //This flow allows us to keep track of exactly what tokens need to be swapped from and to 
        //as well as how much with little extra memory/storage used and a max of 3 if() checks
        if(tokens.ratioA > avgRatio) {

            if (tokens.ratioB > avgRatio) {
                //Swapping A and B -> C
                return(2, tokens.tokenA, tokens.tokenB, tokens.tokenC);
            } else if (tokens.ratioC > avgRatio) {
                //swapping A and C -> B
                return(2, tokens.tokenA, tokens.tokenC, tokens.tokenB);
            } else {
                //Swapping A -> B and C
                return(1, tokens.tokenA, tokens.tokenB, tokens.tokenC);
            }
            
        } else if (tokens.ratioB > avgRatio) {
            //We know A is below avg so we just need to check C
            if (tokens.ratioC > avgRatio) {
                //Swap B and C -> A
                return(2, tokens.tokenB, tokens.tokenC, tokens.tokenA);
            } else {
                //swapping B -> C and A
                return(1, tokens.tokenB, tokens.tokenA, tokens.tokenC);
            }

        } else {
            //We know A and B are below so C has to be the only one above the avg
            //swap C -> A and B
            return(1, tokens.tokenC, tokens.tokenA, tokens.tokenB);
        }
    }

    /*
     * @notice
     *  Function estimating the current assets in the tripod, taking into account:
     * - current balance of tokens in the LP
     * - pending rewards from the LP (if any)
     * - hedge profit (if any)
     * - rebalancing of tokens to maintain token ratios
     * @return estimated tokenA tokenB and tokenC balances
     */
    function estimatedTotalAssetsAfterBalance()
        public
        view
        returns (uint256, uint256, uint256)
    {
        ITripod tripod = ITripod(address(this));
        // Current status of tokens in LP (includes potential IL)
        (uint256 _aBalance, uint256 _bBalance, uint256 _cBalance) = tripod.balanceOfTokensInLP();

        // Add remaining balance in tripod (if any)
        unchecked{
            _aBalance += tripod.balanceOfA();
            _bBalance += tripod.balanceOfB();
            _cBalance += tripod.balanceOfC();
        }

        // Include rewards (swapping them if not one of the LP tokens)
        uint256[] memory _rewardsPending = tripod.pendingRewards();
        address[] memory _rewardTokens = tripod.getRewardTokens();
        address reward;
        for (uint256 i; i < _rewardsPending.length; ++i) {
            reward = _rewardTokens[i];
            if (reward == tripod.tokenA()) {
                _aBalance += _rewardsPending[i];
            } else if (reward == tripod.tokenB()) {
                _bBalance += _rewardsPending[i];
            } else if (reward == tripod.tokenC()) {
                _cBalance += _rewardsPending[i];
            } else if (_rewardsPending[i] != 0) {
                //If we are using the reference token swap to that otherwise use A
                address swapTo = tripod.usingReference() ? tripod.referenceToken() : tripod.tokenA();
                uint256 outAmount = tripod.quote(
                    reward,
                    swapTo,
                    _rewardsPending[i]
                );

                if (swapTo == tripod.tokenA()) { 
                    _aBalance += outAmount;
                } else if (swapTo == tripod.tokenB()) {
                    _bBalance += outAmount;
                } else if (swapTo == tripod.tokenC()) {
                    _cBalance += outAmount;
                }
            }
        }
        return quoteRebalance(_aBalance, _bBalance, _cBalance);
    }

    /*
    * @notice 
    *    This function is a fucking disaster.
    *    But it works...
    */
    function quoteRebalance(
        uint256 startingA,
        uint256 startingB,
        uint256 startingC
    ) public view returns(uint256, uint256, uint256) {
        ITripod tripod = ITripod(address(this));
        //Use tokens struct to avoid stack to deep error
        Tokens memory tokens = Tokens(tripod.tokenA(), 0, tripod.tokenB(), 0, tripod.tokenC(), 0);

        //We cannot rebalance with a 0 starting position, should only be applicable if called when everything is 0 so just return
        if(tripod.invested(tokens.tokenA) == 0 || tripod.invested(tokens.tokenB) == 0 || tripod.invested(tokens.tokenC) == 0) {
            return (startingA, startingB, startingC);
        }

        (tokens.ratioA, tokens.ratioB, tokens.ratioC) = getRatios(
                    tripod.invested(tokens.tokenA),
                    startingA,
                    tripod.invested(tokens.tokenB),
                    startingB,
                    tripod.invested(tokens.tokenC),
                    startingC
                );
        
        //If they are all the same or very close we dont need to do anything
        if(isCloseEnough(tokens.ratioA, tokens.ratioB) && isCloseEnough(tokens.ratioB, tokens.ratioC)) {
            return(startingA, startingB, startingC);
        }
        // Calculate the average ratio. Could be at a loss does not matter here
        uint256 avgRatio;
        unchecked{
            avgRatio = (tokens.ratioA * tripod.investedWeight(tokens.tokenA) + 
                            tokens.ratioB * tripod.investedWeight(tokens.tokenB) + 
                                tokens.ratioC * tripod.investedWeight(tokens.tokenC)) / 
                                    RATIO_PRECISION;
        }
        
        uint256 change0;
        uint256 change1;
        uint256 change2;
        RebalanceInfo memory info;
        //See Rebalance() for explanation
        if(tokens.ratioA > avgRatio) {
            if (tokens.ratioB > avgRatio) {
                //Swapping A and B -> C
                info = RebalanceInfo(0, 0, startingC, 0, startingA, 0, 0, 0, startingB, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapTwoToOne(tripod, info, tokens.tokenA, tokens.tokenB, tokens.tokenC);
                return ((startingA - change0), 
                            (startingB - change1), 
                                (startingC + change2));
            } else if (tokens.ratioC > avgRatio) {
                //swapping A and C -> B
                info = RebalanceInfo(0, 0, startingB, 0, startingA, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapTwoToOne(tripod, info, tokens.tokenA, tokens.tokenC, tokens.tokenB);
                return ((startingA - change0), 
                            (startingB + change2), 
                                (startingC - change1));
            } else {
                //Swapping A -> B and C
                info = RebalanceInfo(0, 0, startingA, 0, startingB, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapOneToTwo(tripod, info, tokens.tokenA, tokens.tokenB, tokens.tokenC);
                return ((startingA - change0), 
                            (startingB + change1), 
                                (startingC + change2));
            }
        } else if (tokens.ratioB > avgRatio) {
            //We know A is below avg so we just need to check C
            if (tokens.ratioC > avgRatio) {
                //Swap B and C -> A
                info = RebalanceInfo(0, 0, startingA, 0, startingB, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapTwoToOne(tripod, info, tokens.tokenB, tokens.tokenC, tokens.tokenA);
                return ((startingA + change2), 
                            (startingB - change0), 
                                (startingC - change1));
            } else {
                //swapping B -> A and C
                info = RebalanceInfo(0, 0, startingB, 0, startingA, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapOneToTwo(tripod, info, tokens.tokenB, tokens.tokenA, tokens.tokenC);
                return ((startingA + change1), 
                            (startingB - change0), 
                                (startingC + change2));
            }
        } else {
            //We know A and B are below so C has to be the only one above the avg
            //swap C -> A and B
            info = RebalanceInfo(0, 0, startingC, 0, startingA, 0, 0, 0, startingB, 0, 0);
            (change0, change1, change2) = 
                _quoteSwapOneToTwo(tripod, info, tokens.tokenC, tokens.tokenA, tokens.tokenB);
            return ((startingA + change1), 
                        (startingB + change2), 
                            (startingC - change0));
        }   
    }
    
    
    /*
     * @notice
     *  Function to be called during mock rebalancing.
     *  This will quote swapping the extra tokens from the one that has returned the highest amount to the other two
     *  in relation to what they need attempting to make everything as equal as possible
     *  will return the absolute changes expected for each token, accounting will take place in parent function
     * @param tripod, the instance of the tripod to use
     * @param info, struct of all needed info OF token addresses and amounts
     * @param toSwapToken, the token we will be swapping from to the other two
     * @param token0Address, address of one of the tokens we are swapping to
     * @param token1Address, address of the second token we are swapping to
     * @return negative change in toSwapToken, positive change for token0, positive change for token1
    */
    function _quoteSwapOneToTwo(
        ITripod tripod,
        RebalanceInfo memory info, 
        address toSwapFrom, 
        address toSwapTo0, 
        address toSwapTo1
    ) internal view returns (uint256 n, uint256 amountOut, uint256 amountOut2) {
        uint256 swapTo0;
        uint256 swapTo1;

        unchecked {
            uint256 precisionA = 10 ** IERC20Extended(toSwapFrom).decimals();
            
            uint256 p;

            (n, p) = getNandP(RebalanceInfo({
                precisionA : precisionA,
                a0 : tripod.invested(toSwapFrom),
                a1 : info.a1,
                b0 : tripod.invested(toSwapTo0),
                b1 : info.b1,
                eOfB : tripod.quote(toSwapFrom, toSwapTo0, precisionA),
                precisionB : 0, //Not needed for this calculation
                c0 : tripod.invested(toSwapTo1),
                c1 : info.c1,
                eOfC : tripod.quote(toSwapFrom, toSwapTo1, precisionA),
                precisionC : 0 // Not needed
            }));

            swapTo0 = n * p / RATIO_PRECISION;
            //To assure we dont sell to much 
            swapTo1 = n - swapTo0;
        }

        amountOut = tripod.quote(
            toSwapFrom, 
            toSwapTo0, 
            swapTo0
        );

        amountOut2 = tripod.quote(
            toSwapFrom, 
            toSwapTo1, 
            swapTo1
        );
    }   

    /*
     * @notice
     *  Function to be called during mock rebalancing.
     *  This will quote swap the extra tokens from the two that returned raios higher than target return to the other one
     *  in relation to what they gained attempting to make everything as equal as possible
     *  will return the absolute changes expected for each token, accounting will take place in parent function
     * @param tripod, the instance of the tripod to use
     * @param info, struct of all needed info OF token addresses and amounts
     * @param token0Address, address of one of the tokens we are swapping from
     * @param token1Address, address of the second token we are swapping from
     * @param toTokenAddress, address of the token we are swapping to
     * @return negative change for token0, negative change for token1, positive change for toTokenAddress
    */
    function _quoteSwapTwoToOne(
        ITripod tripod,
        RebalanceInfo memory info,
        address token0Address,
        address token1Address,
        address toTokenAddress
    ) internal view returns(uint256, uint256, uint256) {

        (uint256 toSwapFrom0, uint256 toSwapFrom1) = 
            getNbAndNc(RebalanceInfo({
                precisionA : 0, //Not needed
                a0 : tripod.invested(toTokenAddress),
                a1 : info.a1,
                b0 : tripod.invested(token0Address),
                b1 : info.b1,
                eOfB : tripod.quote(token0Address, toTokenAddress, 10 ** IERC20Extended(token0Address).decimals()),
                precisionB : 10 ** IERC20Extended(token0Address).decimals(),
                c0 : tripod.invested(token1Address),
                c1 : info.c1,
                eOfC : tripod.quote(token1Address, toTokenAddress, 10 ** IERC20Extended(token1Address).decimals()),
                precisionC : 10 ** IERC20Extended(token1Address).decimals()
            }));

        uint256 amountOut = tripod.quote(
            token0Address, 
            toTokenAddress, 
            toSwapFrom0
        );

        uint256 amountOut2 = tripod.quote(
            token1Address, 
            toTokenAddress, 
            toSwapFrom1
        );

        return (toSwapFrom0, toSwapFrom1, (amountOut + amountOut2));
    }
    
    /*
    * @notice
    *   Function used to determine wether or not the ratios between the 3 tokens are close enough 
    *       that it is not worth the cost to do any rebalancing
    * @param ratio0, the current ratio of the first token to check
    * @param ratio1, the current ratio of the second token to check
    * @return boolean repersenting true if the ratios are withen the range to not need to rebalance 
    */
    function isCloseEnough(uint256 ratio0, uint256 ratio1) public pure returns(bool) {
        if(ratio0 == 0 && ratio1 == 0) return true;

        uint256 delta = ratio0 > ratio1 ? ratio0 - ratio1 : ratio1 - ratio0;
        //We wont rebalance withen .01
        uint256 maxRelDelta = ratio1 / 10_000;

        if (delta < maxRelDelta) return true;
    }

}