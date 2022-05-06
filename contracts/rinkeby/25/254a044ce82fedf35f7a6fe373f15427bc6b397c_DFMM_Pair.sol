/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
// \author: Silas Rutschmann (Mercedes-Benz Group AG) - 01.05.2022
pragma solidity ^0.8.0;

//import './libraries/Math.sol';      (only Pair Contract in PoC)
//import './libraries/SafeMath.sol';  // (OpenZeppelin's Safe Math Library -> library for performing overflow-safe math
//import './interfaces/IERC20.sol';  (only Pair Contract in PoC)

contract DFMM_Pair{
    
    address public factory;

    // represent the pair tokens
    address public token0;    // represents one of the Tokens in Pair (Assumption: Stablecoin)
    address public token1;    // represents onn of the Tokens in Pair (Assumption: CO2-Token)
    
    uint amount0Out = 0;
    uint amount0In = 0;
    uint112 private wallet_reserve0 = 50000;         // reserves - number of Tokens of token0 in SmartContract -> Simulated in chapter 5.2
    uint112 private wallet_reserve1 = 10000;          // reserves - number of Tokens of token1 in SmartContract -> Simulated in chapter 5.2
    uint p_oracle = 40;                             // oracle/ reference price -> market price of EU Allowances -> Simulated in chapter 5.2
    uint baseFee = 1; 

    uint dfmm_balance0 = 100000;                     // virtual balances in trader's wallet
    uint dfmm_balance1 = 10000;                      // virtual balances in trader's wallet
    uint eN = 2718;                            // e Numerator (Approximation to Euler's "e")
    uint basisPoints = 100;   // many calculations in basis points due to the lack of fixed point calculations in solidity
    //uint32  private blockTimestampLast; // last time where reserve0 and reserve1 was updated

    // Declaration of the necessary variable to avoid "deep stack" errors in functions
    uint virtual_p_market;       // market price based on CFMM formula (x*y=k) -> without slippage included
    uint real_p_market;          // real market price based on CFMM formula (x*y=k) -> with slippage included
    uint k;                      // CFMM's invariant
    uint d;                      // dynamic parameter of dynamic fee model -> quantifies distance between oracle and market price

    constructor () payable {
        factory = msg.sender;
    }

     // transfer Tokens to specific addresses (with some security measures)
    function _safeTransfer(address token, address to, uint value) private {
        //tbd
    }

    // returns reserve amounts (variables are private)
    function getReserves() public view returns (uint112 _wallet_reserve0, uint112 _wallet_reserve1) {
        _wallet_reserve0 = wallet_reserve0;
        _wallet_reserve1 = wallet_reserve1;
    }

    // Manage "direction" of Swap -> Calculation of fees // CO2TokenToERC20() = Selling CO2-Tokens for ERC20-Token
    function CO2TokentoERC20(uint amount1In) public returns (uint f_C02_Sell, uint swapAmount_CO2_Sell)  {
        // dfmm_amount0In (CO2-Token) is set to 100 in the simulations in chapter 5.2 

        address wallet_owner = msg.sender;                          // wallet address of trader
        (uint _dfmm_reserve0, uint _dfmm_reserve1) = getReserves(); // gas savings
        // check amounts and liquidiy
        //require(dfmm_amount0Out > 0 || dfmm_amount1Out > 0, 'DFMM: INSUFFICIENNT_OUTPUT_AMOUNT'); // check amounts
        //require(dfmm_amount0Out < _dfmm_reserve0 && dfmm_amounnt1Out < _dfmm_reserve1, 'DFMM: INSUFFICIENT_LIQUIDITY'); // check liquidity

        address dfmm_token0 = token0;   // CO2-Token
        address dfmm_token1 = token1;   // ERC20-Token (Assumption: Stablecoin)

        require(amount1In > 0, 'DFMM: INSUFFICIENT_INPUT_AMOUNT'); // check before calculations to safe gas

        // calculation of virtual_p_market
        virtual_p_market = _dfmm_reserve0 / _dfmm_reserve1;

        // calculation of real_p_market
        k = _dfmm_reserve0 * _dfmm_reserve1;
        real_p_market = (_dfmm_reserve0 * basisPoints) - (k / ((_dfmm_reserve1 + amount1In) / basisPoints));   

        // calculation of parameter d (formula in chapter 4.2)
        d = 100 - ((virtual_p_market * basisPoints) / p_oracle);                            // divide by basisPoints to get true values

        //dynamic calculation of fees (formula in chapter 4.2)
        if (d <= 0 ) {
            f_C02_Sell = baseFee;
        }
        else {
            f_C02_Sell = baseFee * (((1 * basisPoints) + d) ** 4);   
        }
        
        // // calculate final amount of token0 one gets for dfmm_amount1In -> divide by basispoints to get true values (roundet to 2 digits) 
        swapAmount_CO2_Sell = (real_p_market * ((basisPoints ** 4) - (f_C02_Sell / basisPoints)) / (basisPoints ** 4));    

        require(wallet_owner != dfmm_token0 && wallet_owner != dfmm_token1, 'DFMM: INVALID_TO');  // check sender address

        // CHECK WHETHER THE TRADERS WALLET IS SUFFICIENTLY COVERED: 
        uint dfmm_balance0Adjusted = (dfmm_balance0 * 1000) - (amount0In * 3);
        uint dfmm_balance1Adjusted = (dfmm_balance1 * 1000) - (amount1In * 3);
        require((dfmm_balance0Adjusted * dfmm_balance1Adjusted) >= uint(wallet_reserve0) * (wallet_reserve1) * (1000**2), 'DFMM: WALLET NOT SUFFICIENTLY OVERED!');
            // -> assumed to be true in simulations (can't be controled in an isolated pair contract)
        
        // transfer swapAmount to wallet owner 
        //_safeTransfer(token0, address to, swapAmount);

        // transfer fees to protocol (factory address)
        //_safeTransfer(token1, factory, f);

        // update new reserves and balances
        //_update(dfmm_balance0, dfmm_balance1, _dfmm_reserve0, _dfmm_reserve1);
    }


    // Manage "direction" of Swap -> Calculation of fees // ERC20ToCO2Token() = Buying a fixed ammount of CO2-Tokens with an ERC20-Token
    function ERC20ToCO2Token(uint amount1Out) public returns (uint f_C02_Buy, uint swapAmount_CO2_Buy) {     
        // calculates how many ERC one has to pay for a certain amount of CO2 (dfmm_amount1Out) (token1 is leaving the liquidity pool)

        address wallet_owner = msg.sender;                          // wallet address of trader
        require(amount0Out > 0 || amount1Out > 0, 'DFMM: INSUFFICIENNT_OUTPUT_AMOUNT'); // check amounts
        (uint _dfmm_reserve0, uint _dfmm_reserve1) = getReserves(); // gas savings
        //require(amount0Out < _dfmm_reserve0 && amounnt1Out < _dfmm_reserve1, 'DFMM: INSUFFICIENT_LIQUIDITY'); // check liquidity

        address dfmm_token0 = token0;   // CO2-Token
        address dfmm_token1 = token1;   // ERC20-Token (Assumption: Stablecoin)

        require(amount1Out > 0, 'DFMM: INSUFFICIENT_INPUT_AMOUNT'); // check before calculations to safe gas

        // calculation of virtual_p_market
        virtual_p_market = _dfmm_reserve0 / _dfmm_reserve1;

        // calculation of real_p_market
        k = _dfmm_reserve0 * _dfmm_reserve1;
        real_p_market = (k / ((_dfmm_reserve1 - amount1Out) / basisPoints)) - (_dfmm_reserve0 * basisPoints);   // divide bybasisPoints to get true values
                
        // calculation of parameter d (formula in chapter 4.2)
        d = 100 - ((virtual_p_market * basisPoints) / p_oracle);                     // divide by basisPoints to get true values

        //dynamic calculation of fees (formula in chapter 4.2)
        if (d <= 0 ) {
            f_C02_Buy = baseFee;
        }
        else {
            f_C02_Buy = (baseFee * (basisPoints ** 16)) / ((eN) ** (d/10));           // Transform term to avoid negative numbers -> baseFee * e ^(-10 * d) = (baseFee) / (e^(10 * d)) -> use d/basisPoints instead of 10*d to avoid overflows
             // divide by basisPoints ^4 to get real f [%]                                                          
        }
        
        // // calculate final amount of token0 one gets for dfmm_amount1In -> divide by basispoints to get true values (roundet to 2 digits) 
        swapAmount_CO2_Buy = (real_p_market * ((basisPoints ** 4) - (f_C02_Buy / basisPoints)) / (basisPoints ** 4)); 
         
        require(wallet_owner != dfmm_token0 && wallet_owner != dfmm_token1, 'DFMM: INVALID_TO');  // check sender address
           
        // CHECK WHETHER THE TRADERS WALLET IS SUFFICIENTLY COVERED: 
        uint amount1In = 0;
        uint dfmm_balance0Adjusted = (dfmm_balance0 * 1000) - (amount0In * 3);
        uint dfmm_balance1Adjusted = (dfmm_balance1 * 1000) - (amount1In * 3);
        require((dfmm_balance0Adjusted * dfmm_balance1Adjusted) >= uint(wallet_reserve0) * (wallet_reserve1) * (1000**2));
            // -> assumed to be true in simulations (can't be controled in an isolated pair contract)
        
        // transfer swapAmount to wallet owner 
        //_safeTransfer(token0, address to, swapAmount);

        // transfer fees to protocol (factory address)
        //_safeTransfer(token1, factory, f);

        // update new reserves and balances
        //_update(dfmm_balance0, dfmm_balance1, _dfmm_reserve0, _dfmm_reserve1);
    }

}