/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: ResetTaxSwap.sol


pragma solidity 0.8.7;



// Create a contract called ResetTaxSwap
// The contract will have an owner address
// The contract will have a method that can be called only by the owner. This method will accept two parameters (amount of tokens to swap and the reference transaction hash)
contract ResetTaxSwap {
    address public owner;

    // Create an array called "SwapHistory" that will store the amount of tokens swapped and the reference transaction hash, the status of the swap
    struct SwapHistory {
        uint256 amount;
        bytes32 txHash;
        bool status;
    }

    SwapHistory[] public swapHistory;

    // Create a reference index to store the index of the array so that we can search for the swap history
    mapping(bytes32 => uint256) public swapHistoryIndex;
    
     //Create an interface for the Uniswap v2 router
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    //Create an interface for the token received
    IERC20 token = IERC20(0x30df7D7EE52c1b03cd009e656F00AB875AdCEeD2);

    //Write a function to getPathForTokentoETH. Token contract address is 0x30df7D7EE52c1b03cd009e656F00AB875AdCEeD2
    function getPathForTokentoETH() public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = 0x30df7D7EE52c1b03cd009e656F00AB875AdCEeD2;
        path[1] = uniswapV2Router.WETH();
        return path;
    } 

    // Create a constructor function that sets the owner address
    constructor() {
        owner = msg.sender;
    }

    // Fallback function to receive ETH and store in the contract
    receive() external payable {}

    // Function to withdraw ETH from the contract only by the owner. Do not withdraw all ETH from the contract. Leave 0.1 ETH in the contract
    function withdrawETH() public {
        require(msg.sender == owner, "Only owner can call this function.");
        payable(owner).transfer(address(this).balance - 0.1 ether);
    }


    // Create a function that can be called only by the owner. This function will accept two parameters (amount of tokens to swap and the reference transaction hash)
    function swap(uint256 amount, bytes32 txHash) public {
        
        //throw an error if the caller is not the owner
        require(msg.sender == owner, "Only owner can call this function.");

        //check if the swap has been done before
        require(swapHistoryIndex[txHash] == 0, "Swap has been done before.");

        //add the swap to the swap history
        swapHistory.push(SwapHistory(amount, txHash, true));

        //update the swap history index
        swapHistoryIndex[txHash] = swapHistory.length;

        //Now write the logic to swap the tokens for ETH using Uniswap v2 router. The contract address of the token received is 0x30df7D7EE52c1b03cd009e656F00AB875AdCEeD2
        //The contract address of the Uniswap v2 router is 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

        //Approve the Uniswap v2 router to spend the tokens received
        token.approve(address(uniswapV2Router), amount);

        //Swap the tokens for ETH
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, getPathForTokentoETH(), address(this), block.timestamp);

        //Send the ETH to the owner
        payable(owner).transfer(address(this).balance);

        //Now find the object in the swap history array and update the status to true
        for (uint256 i = 0; i < swapHistory.length; i++) {
            if (swapHistory[i].txHash == txHash) {
                swapHistory[i].status = true;
            }
        }
    }
}