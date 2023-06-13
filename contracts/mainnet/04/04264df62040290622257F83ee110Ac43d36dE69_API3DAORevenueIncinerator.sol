/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

//SPDX-License-Identifier: MIT

/***** 
 ***** 
 ***** CAUTION: this code and deployment are provided strictly as-is 
 ***** with no guarantee, representation nor warranty (express or implied) of any kind as to safety or any attribute;
 ***** any users, callers, or senders of value of any kind, or any party related in any way to the foregoing assume all risks of using this code and deployment
 *****
 ***** OSS Technologies Ltd. publicly broadcasts this bytecode to the participants in the Ethereum mainnet network as a public good, and retains no control hereover
 *****

               /\   
              /__\ 
             /\  /\    
            /__\/__\
           /\  /\  /\   
          /__\/__\/__\ 
         /\  /\  /\  /\ 
        /__\/__\/__\/__\
       /\  /\  /\  /\  /\ 
      /__\/__\/  \/__\/__\ 
     /\  /\  /    \  /\  /\
    /__\/__\/______\/__\/__\
   /\  /\  /\  /\  /\  /\  /\  
  /__\/__\/__\/__\/__\/__\/__\ 
 /\  /\  /\  /\  /\  /\  /\  /\
/__\/__\/__\/__\/__\/__\/__\/__\

 
⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ 

   API3DAO REVENUE INCINERATOR 

⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ ⟁ 


*/

pragma solidity 0.8.18;

/// @title API3DAO Revenue Incinerator

/** @notice immutable burn of excess USDC revenue by buying and burning API3 tokens per API3DAO whitepaper:
 *** swaps USDC sent to this contract for API3 tokens and ETH to LP in UniswapV2; each LP is then queued chronologically.
 *** LP position is redeemable to this contract after one year by any caller, which is swapped to API3 tokens via UniswapV2 and burned via the API3 token contract.
 *** ETH sent directly to this contract is auto-swapped to API3 tokens, which are then burned via the API3 token contract,
 *** providing an optional method for automated ETH revenue burning.
 ***
 *** no aspect of this contract is functionally controllable nor reclaimable by any external address(es) or centralised party, 
 *** and therefore any value or assets sent to this contract or 
 *** controlled by this contract (such as LP tokens) is abandoned */

/** @dev be advised there is inherent slippage risk for large amounts, with some protection via '_getApi3MinAmountOut'
 *** so it is more favourable to use swapUSDCToAPI3AndLpWithETHPair() with a divisor > 1 to swap and LP less than the
 *** total balance of USDC at a time and further avoid such risks. */

/// ⟁ ⟁ ⟁ /// INTERFACES /// ⟁ ⟁ ⟁ ///

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IAPI3 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;

    function updateBurnerStatus(bool burnerStatus) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/// ⟁ ⟁ ⟁ /// CONTRACT /// ⟁ ⟁ ⟁ ///

contract API3DAORevenueIncinerator {
    struct Liquidity {
        uint256 withdrawTime;
        uint256 amount;
    }

    address internal constant API3_TOKEN_ADDR =
        0x0b38210ea11411557c13457D4dA7dC6ea731B88a;
    address internal constant LP_TOKEN_ADDR =
        0x4Dd26482738bE6C06C31467a19dcdA9AD781e8C4;
    address internal constant UNI_ROUTER_ADDR =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal constant USDC_TOKEN_ADDR =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WETH_TOKEN_ADDR =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // a year is 365 days 6 hours, (365 * 24 * 60 * 60) + (6 * 60 * 60)
    uint256 internal constant YEAR_IN_SECONDS = 31557600;

    IUniswapV2Router02 internal constant router =
        IUniswapV2Router02(UNI_ROUTER_ADDR);
    IAPI3 internal constant iAPI3Token = IAPI3(API3_TOKEN_ADDR);

    uint256 public lpAddIndex;
    uint256 public lpRedeemIndex;

    mapping(uint256 => Liquidity) public liquidityAdds;

    /// ⟁ ⟁ ⟁ /// ERRORS /// ⟁ ⟁ ⟁ ///

    error NoAPI3Tokens();
    error NoRedeemableLPTokens();
    error NoUSDCTokens();
    error PairUpdateDelay();
    error ZeroDivisor();

    /// ⟁⟁⟁ /// EVENTS /// ⟁⟁⟁ ///

    event API3Burned(uint256 amountBurned);
    event LiquidityProvided(
        uint256 liquidityAdded,
        uint256 indexed lpIndex,
        uint256 indexed timestamp
    );
    event LiquidityRemoved(
        uint256 liquidityRemoved,
        uint256 indexed lpIndex,
        uint256 indexed timestamp
    );

    /// ⟁ ⟁ ⟁ /// FUNCTIONS /// ⟁ ⟁ ⟁ ///

    /// @notice set interfaces, API3 token burner status for address(this) and approve Uniswap router for address(this) for API3, USDC, and API3/ETH LP tokens
    constructor() payable {
        iAPI3Token.updateBurnerStatus(true);
        iAPI3Token.approve(UNI_ROUTER_ADDR, type(uint256).max);
        IERC20(USDC_TOKEN_ADDR).approve(UNI_ROUTER_ADDR, type(uint256).max);
        IERC20(LP_TOKEN_ADDR).approve(UNI_ROUTER_ADDR, type(uint256).max);
    }

    /// @notice receives ETH sent to address(this), and if msg.sender is not the Uniswap V2 router address, swaps for API3 tokens, and calls '_burnAPI3'
    /// also useful for burning any leftover/dust API3 tokens held by or sent to this contract. Small amounts advisable to avoid MEV trouble.
    receive() external payable {
        if (msg.sender != UNI_ROUTER_ADDR) {
            router.swapExactETHForTokens{value: msg.value}(
                _getApi3MinAmountOut(msg.value),
                _getPathForETHtoAPI3(),
                address(this),
                block.timestamp
            );
            _burnAPI3();
        }
    }

    /// @notice swaps this address's USDC divided by '_divisor' for ETH, then swaps 1/2 of the ETH for API3 tokens, and LPs API3/ETH. Pass '1' to use entire USDC balance.
    /** @dev no authorisation restriction, callable by anyone. Implemented to further avoid substantial slippage risks
     ** by permitting < 100% of this contract's USDC be swapped at a time */
    /// @param _divisor: divisor for division operation of this contract's USDC balance to then swap and LP, which must be > 0.
    /// for example, if '_divisor' = 2, 50% of USDC will be swapped, if '_divisor' = 4, 25%, etc.
    function swapUSDCToAPI3AndLpWithETHPair(uint256 _divisor) external {
        if (_divisor == 0) revert ZeroDivisor();
        uint256 _swapAmount = IERC20(USDC_TOKEN_ADDR).balanceOf(address(this)) /
            _divisor;
        if (_swapAmount == 0) revert NoUSDCTokens();

        // swap USDC/_divisor for ETH
        router.swapExactTokensForETH(
            _swapAmount,
            1,
            _getPathForUSDCtoETH(),
            payable(address(this)),
            block.timestamp
        );

        uint256 _ethSwapAmount = address(this).balance / 2;

        // swap half of ETH for API3
        router.swapExactETHForTokens{value: _ethSwapAmount}(
            _getApi3MinAmountOut(_ethSwapAmount),
            _getPathForETHtoAPI3(),
            address(this),
            block.timestamp
        );

        // LP
        _lpApi3Eth();
    }

    /** @dev checks earliest Liquidity struct to see if any LP tokens are redeemable,
     ** then redeems that amount of liquidity to this address (which is entirely converted and burned in API3 tokens via '_burnAPI3'),
     ** then deletes that mapped struct in 'liquidityAdds' and increments 'lpRedeemIndex' */
    /// @notice redeems the earliest available liquidity; redeemed API3 tokens are burned and redeemed ETH is converted to API3 tokens and burned
    function redeemLP() external {
        if (liquidityAdds[lpRedeemIndex].withdrawTime > block.timestamp)
            revert NoRedeemableLPTokens();
        uint256 _redeemableLpTokens = liquidityAdds[lpRedeemIndex].amount;

        // if 'lpRedeemIndex' returns zero, increment the index; otherwise call '_redeemLP' and then increment
        if (_redeemableLpTokens == 0) {
            delete liquidityAdds[lpRedeemIndex];
        } else {
            _redeemLP(_redeemableLpTokens, lpRedeemIndex);
        }
        unchecked {
            ++lpRedeemIndex;
        }
    }

    /** @dev checks applicable Liquidity struct to see if any LP tokens are redeemable,
     ** then redeems that amount of liquidity to this address (which is entirely converted and burned in API3 tokens via '_burnAPI3'),
     ** then deletes that mapped struct in 'liquidityAdds'. Implemented in case of lpAddIndex--lpRedeemIndex mismatch */
    /// @notice redeems specifically indexed liquidity; redeemed API3 tokens are burned and redeemed ETH is converted to API3 tokens and burned
    /// @param _lpRedeemIndex: index of liquidity in 'liquidityAdds' mapping to be redeemed
    function redeemSpecificLP(uint256 _lpRedeemIndex) external {
        if (liquidityAdds[_lpRedeemIndex].withdrawTime > block.timestamp)
            revert NoRedeemableLPTokens();
        uint256 _redeemableLpTokens = liquidityAdds[_lpRedeemIndex].amount;

        // if '_lpRedeemIndex' returns zero, delete mapping; otherwise call '_redeemLP'. Do not increment the global 'lpRedeemIndex'
        if (_redeemableLpTokens == 0) {
            delete liquidityAdds[_lpRedeemIndex];
        } else {
            _redeemLP(_redeemableLpTokens, _lpRedeemIndex);
        }
    }

    /// @notice burns all API3 tokens held by this contract
    function _burnAPI3() internal {
        uint256 _api3Bal = iAPI3Token.balanceOf(address(this));
        if (_api3Bal == 0) revert NoAPI3Tokens();
        iAPI3Token.burn(_api3Bal);
        emit API3Burned(_api3Bal);
    }

    /// @notice LPs ETH and API3 tokens to Uniswapv2's API3/ETH pair
    /// @dev LP has 10% buffer. Liquidity locked for one year and queued chronologically.
    function _lpApi3Eth() internal {
        uint256 _api3Bal = iAPI3Token.balanceOf(address(this));
        if (_api3Bal == 0) revert NoAPI3Tokens();
        uint256 _ethBal = address(this).balance;
        (, , uint256 liquidity) = router.addLiquidityETH{value: _ethBal}(
            API3_TOKEN_ADDR,
            _api3Bal,
            (_api3Bal * 9) / 10, // 90% of the '_api3Bal'
            (_ethBal * 9) / 10, // 90% of the '_ethBal'
            payable(address(this)),
            block.timestamp
        );
        emit LiquidityProvided(liquidity, lpAddIndex, block.timestamp);
        unchecked {
            liquidityAdds[lpAddIndex] = Liquidity(
                block.timestamp + YEAR_IN_SECONDS, // will not overflow on human timelines
                liquidity
            );
            ++lpAddIndex;
        }
    }

    /// @notice redeems the LP for the corresponding 'lpRedeemIndex', swaps redeemed ETH for API3 tokens, and burns all API3 tokens
    /// @param _redeemableLpTokens: amount of LP tokens available to redeem
    /// @param _lpRedeemIndex: LP index being redeemed
    function _redeemLP(
        uint256 _redeemableLpTokens,
        uint256 _lpRedeemIndex
    ) internal {
        router.removeLiquidityETH(
            API3_TOKEN_ADDR,
            _redeemableLpTokens,
            1,
            1,
            payable(address(this)),
            block.timestamp
        );
        delete liquidityAdds[_lpRedeemIndex];
        emit LiquidityRemoved(
            _redeemableLpTokens,
            _lpRedeemIndex,
            block.timestamp
        );

        // removed liquidity is 50/50 ETH and API3; swap all newly received ETH for API3, then burn all the API3 tokens
        router.swapExactETHForTokens{value: address(this).balance}(
            _getApi3MinAmountOut(address(this).balance),
            _getPathForETHtoAPI3(),
            address(this),
            block.timestamp
        );
        _burnAPI3();
    }

    /// @notice calculate a minimum amount of API3 tokens out, as 90% of the price in wei as of the last update
    /// @dev exclude pair updates in this block to prevent sandwiching (i.e. that the most recent timestamp returned by 'getReserves()' is not the same timestamp as this attempted swap)
    /// @param _amountIn: amount of wei to be swapped for API3 tokens
    function _getApi3MinAmountOut(
        uint256 _amountIn
    ) internal view returns (uint256) {
        (
            uint112 _api3Reserve,
            uint112 _ethReserve,
            uint32 _timestamp
        ) = IUniswapV2Pair(LP_TOKEN_ADDR).getReserves();

        // compare current block timestamp within the range of uint32 to last pair update; must be > 0 in order to prevent sandwiching
        if (block.timestamp - uint256(_timestamp) == 0)
            revert PairUpdateDelay();

        // minimum amount of API3 tokens out is 90% of the quoted price
        // though API3 is token0 for the 'getReserves()' call, it is reserveB here because the '_amountIn' is wei, so we want 'quote()' to return amount denominated in API3 tokens
        return
            (router.quote(
                _amountIn,
                uint256(_ethReserve),
                uint256(_api3Reserve)
            ) * 9) / 10;
    }

    /// @return path: the router path for ETH/API3 swap
    function _getPathForETHtoAPI3() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = WETH_TOKEN_ADDR;
        path[1] = API3_TOKEN_ADDR;
        return path;
    }

    /// @return path: the router path for USDC/ETH swap
    function _getPathForUSDCtoETH() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = USDC_TOKEN_ADDR;
        path[1] = WETH_TOKEN_ADDR;
        return path;
    }
}