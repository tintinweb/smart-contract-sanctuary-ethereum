// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6 || ^0.8.0;
import './interface/IbalancerV2.sol';
import './interface/IERC20.sol';
import './interface/IAsset.sol';
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

//all assigment from one variable to other variable is done to avoid stack-too-deep error 

contract aggregator{
    //reason for using multiple variable is: that each variable should have one purpose to serve
    //reason for global variables is too avoid stack too deep error:    
    address private constant ETH =  0x0000000000000000000000000000000000000000;
    address private constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
     event BeeSwap(
        address sender,
        address tokenIn,
        address tokenOut,
        uint256 tokenInAmount,
        uint256 tokenOutAmount,
        uint256 timeStamp
    );

    uint optionIndex = 0;
    uint amountOut  = 0; 
    uint pathindex = 0;
    uint amountIn = 0;
    uint balOutput;
    address sender;
    address tokenOut;
    address tokenIn;
    address[]  updPath;
    
    fallback() external payable {
    //get facet from function selector
    //for receiving eth from Uniswap & balancer
    }
    
    function dex(
        
        address [] memory tokenInOut,
        uint[] memory dexRoute,   
        uint[] memory amountInOut,  
        int[] memory options,           
        address[] memory path,
        Ibal.SingleSwap memory singleswap,
        uint limit,
        Ibal.BatchSwapStep [] memory swaps,
        IAsset[] memory assets,
        Ibal.SwapKind kind,
        int256[] memory limits,
        uint deadline
        
        )
        external payable{
            uint [] memory dexRoute1 = dexRoute;
            uint256 [] memory output;
            //filling up Balanacer's Funds Struct
            Ibal.FundManagement memory funds; 
            funds.sender=address(this);
            funds.fromInternalBalance = false;
            funds.recipient = payable(address(this));
            funds.toInternalBalance = false;
            sender = msg.sender;
            amountIn  = amountInOut[0];
            amountOut = amountInOut[1];
            tokenIn  = tokenInOut[0];
            tokenOut = tokenInOut[1];

            for(uint i=0; i<dexRoute1.length; i++){

                if(dexRoute1[i] == 0)
                {    
                    //getting amountin. amounout & path for swapping two tokens    
                    updPath = [path[pathindex], path[pathindex+1]];                
                    
                    if(i==0)
                    {
                        if(options[optionIndex]==0){
                            IERC20(updPath[0]).transferFrom(sender, address(this), amountIn);
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(amountIn,amountOut,updPath,address(this),deadline);    
                        }

                        if(options[optionIndex]==1){
                            IERC20(updPath[0]).transferFrom(sender, address(this), amountIn);
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(amountIn,amountOut,updPath,address(this),deadline);    
                        }

                        if(options[optionIndex]==2){
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: msg.value }(amountOut,updPath,address(this),deadline);
                        }

                        else if(options[optionIndex]>2){
                            revert('invalid option');
                        }     
                    }

                    else if(i==1 || i == 2){
                        
                        if(options[optionIndex]==0){
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(amountIn,amountOut,updPath,address(this),deadline);
                        }

                        if(options[optionIndex]==1){
                            IERC20(updPath[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn);
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(amountIn,amountOut,updPath,address(this),deadline);
                        }

                        if(options[optionIndex]==2){
                            output=IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: amountIn }(amountOut,updPath,address(this),deadline);    
                        }

                        else if(options[optionIndex]>2){
                            revert('invalid option');
                        }
                    }
                    
                    else {
                        revert('invalid dexRoute');
                    }

                    if(dexRoute1.length == 3 && dexRoute1[1]==1){
                        pathindex++;  
                    }
                   
                   amountIn = output[1];  
                   pathindex++; 
                   optionIndex++;
                }

            if(dexRoute1[i] == 1)
            { 
                if(i==0){

                    if(address(singleswap.assetIn) == ETH){
                        balOutput= Ibal(balancerVault).swap{value: msg.value}(singleswap, funds, limit, deadline);    
                    }

                    else{
                        IERC20(address(singleswap.assetIn)).transferFrom(sender, address(this), singleswap.amount);
                        IERC20(address(singleswap.assetIn)).approve(balancerVault,  singleswap.amount);
                        balOutput=Ibal(balancerVault).swap(singleswap, funds, limit, deadline);
                    }
                    amountIn = balOutput;
                }
                else if(i==1 || i == 2){
                    if(address(singleswap.assetIn) == ETH){
                        singleswap.amount = output[1];
                        balOutput= Ibal(balancerVault).swap{value:  output[1]}(singleswap, funds, limit, deadline);         
                    }

                    else{
                        singleswap.amount = output[1];
                        IERC20(address(singleswap.assetIn)).approve(balancerVault,  output[1]);
                        balOutput=Ibal(balancerVault).swap(singleswap, funds, limit, deadline);   
                    }
                    amountIn = balOutput;
                }
                else {
                    revert('invalid dexRoute');            
                }
            }  

            if(dexRoute1[i] == 2)
            {
                if(i==0){
                    
                    if(address(assets[0]) == ETH){
                    Ibal(balancerVault).batchSwap { value: msg.value }(kind, swaps, assets, funds, limits, deadline);
                    }

                    else{
                        IERC20(address(assets[0])).transferFrom(sender, address(this),  swaps[0].amount);
                        IERC20(address(assets[0])).approve(balancerVault,  swaps[0].amount);
                        Ibal(balancerVault).batchSwap(kind, swaps, assets, funds, limits, deadline);
                    }    
                }

                else if(i==1 || i==2){
                    
                    if(address(assets[0]) == ETH){
                        swaps[0].amount = output[1];
                        limits[0] = int256(output[1]);    
                        Ibal(balancerVault).batchSwap { value: output[1] }(kind, swaps, assets, funds, limits, deadline);
                    }

                    else{
                        swaps[0].amount = output[1];
                        limits[0] = int256(output[1]);
                        IERC20(address(assets[0])).approve(balancerVault,  swaps[0].amount);
                        Ibal(balancerVault).batchSwap(kind, swaps, assets, funds, limits, deadline);
                    }
                }
                if(dexRoute1[0] == 2 && dexRoute1.length>1){
                    if(address(assets[0]) == ETH){
                        Ibal(balancerVault).batchSwap { value: msg.value }(kind, swaps, assets, funds, limits, deadline);
                        amountIn=IERC20(address(assets[2])).balanceOf(address(this));
                    }
                    else{

                        IERC20(address(assets[0])).transferFrom(sender, address(this),  swaps[0].amount);
                        IERC20(address(assets[0])).approve(balancerVault,  swaps[0].amount);
                        Ibal(balancerVault).batchSwap(kind, swaps, assets, funds, limits, deadline);
                        if(address(assets[2])==ETH){
                            amountIn = address(this).balance;
                        }
                        else{
                            amountIn=IERC20(address(assets[2])).balanceOf(address(this));
                        }
                    
                    } 
                }
            }
        }
        
           
        transfer(amountIn,tokenIn,tokenOut,msg.sender);
        
        //ressetting all used global variables to zero
        optionIndex = 0;
        pathindex = 0;
        amountOut=0;
        
    }

    
    function transfer(uint amountIn0, address TokenIn, address TokenOut, address msgSender) internal{
        uint amountReceived;
        if(TokenOut==ETH)
        {   
            amountReceived =address(this).balance;
            payable(msgSender).transfer(address(this).balance);
            emit BeeSwap(msgSender, TokenIn, TokenOut, amountIn0, amountReceived, block.timestamp); 
        }
        else{

            amountReceived = IERC20(TokenOut).balanceOf(address(this));
            IERC20(TokenOut).transfer(msgSender,amountReceived);
            emit BeeSwap(msgSender, TokenIn, TokenOut, amountIn0, amountReceived, block.timestamp);
        }
            
    }
    
    //if all route coming of Uniswap
    
    function swapV2Router(
        uint256 amountIn0,
        uint256 amountOut1,
        uint256 deadline,
        address[] calldata path,
        uint8 option
    ) external payable {
        require(path.length >= 2, "RouterInteraction:: Invalid Path length");
        require(
            path[0] != address(0) || path[path.length - 1] != address(0),
            "RouterInteraction:: Invalid token address"
        );

        address sender1 = msg.sender;
        uint[] memory amounts;

        if (option == 0) {
            IERC20(path[0]).transferFrom(sender, address(this), amountIn0);
            IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn0);
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForTokens(
                amountIn0,
                amountOut1,
                path,
                sender1,
                deadline
            );
        } else if (option == 1) {
            IERC20(path[0]).transferFrom(sender, address(this), amountIn0);
            IERC20(path[0]).approve(UNISWAP_ROUTER_ADDRESS, amountIn0);
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactTokensForETH(
                amountIn0,
                amountOut1,
                path,
                sender1,
                deadline
            );
        } else if (option == 2) {
            require(msg.value > 0, 'Invalid Eth amount.');
            require(amountIn0 == msg.value, 'Invalid input amounts.');
            amounts = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).swapExactETHForTokens{ value: msg.value }(
                amountOut1,
                path,
                sender1,
                deadline
            );
        } else {
            revert('Invalid option.');
        }

        amountOut1 = amounts[amounts.length-1];
        emit BeeSwap(sender, path[0], path[path.length - 1], amountIn0, amountOut1, block.timestamp);
    }       
}

// SPDX-License-Identifier: MIT

 pragma solidity ^0.8.0 || ^0.6.6;
// pragma experimental ABIEncoderV2;
// import "./IAsset.sol";
// interface Ibal{
//    enum SwapKind { GIVEN_IN, GIVEN_OUT }

//    struct SingleSwap{
//         bytes32 poolId;
//         SwapKind kind;
//         IAsset assetIn;
//         IAsset assetOut;
//         uint256 amount;
//         bytes userData;
//     }

//     struct FundManagement{
//         address sender;
//         bool fromInternalBalance;
//         address payable recipient;
//         bool toInternalBalance;
//     }

    
//     function swap(
//         SingleSwap memory singleSwap,
//         FundManagement memory funds,
//         uint256 limit,
//         uint256 deadline
//     )
//         external
//         payable
//         returns (uint256 amountCalculated);

//     struct BatchSwapStep{
//         bytes32 poolId;
//         uint256 assetInIndex;
//         uint256 assetOutIndex;
//         uint256 amount;
//         bytes userData;
//     }
//     struct Extra{
//         //address TokenIn;
//         //address TokenOut;
//         uint256 AmountIn;
//         //uint deadline;
//         //Ibal.SwapKind kind; 
//     }
//     function setRelayerApproval(
//         address send,
//         address cont,
//         bool approved
//     )
//     external returns(bool approv);    

//     function batchSwap(
//         SwapKind kind,
//         BatchSwapStep[] calldata swaps,
//         IAsset[] calldata assets,
//         FundManagement calldata funds,
//         uint256[] calldata limits,
//         uint256 deadline
//     )
//         external
//         payable
//         returns (int256[] memory assetDeltas);
    

// }

//pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./IAsset.sol";
interface Ibal{
   enum SwapKind { GIVEN_IN, GIVEN_OUT }

   struct SingleSwap{
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement{
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountCalculated);

    struct BatchSwapStep{
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }    

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    )
        external
        payable
        returns (int256[] memory assetDeltas);
    

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function name() external view returns (string memory) ;

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view  returns (string memory) ;

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view  returns (uint8);
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
    function transfer(address recipient, uint256 amount) external;

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
    function approve(address spender, uint256 amount) external;

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

pragma solidity >0.6.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks

}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}