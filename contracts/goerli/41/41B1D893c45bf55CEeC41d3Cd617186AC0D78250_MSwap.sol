/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
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

// File: contracts/app/MSwap.sol


pragma solidity ^0.8.0;

interface PancakeSwap {
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
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

library TransferLib {
    function transferFrom(IERC20 erc20,address from,address to,uint value) internal {
        if(from==address(this)){
            bool success = erc20.transfer(to,value);
            require(success,'TransferLib: transfer error');
        } else{
            bool success = erc20.transferFrom(from,to,value);
            require(success,'TransferLib: transfer error');
        }
    }
}

contract MSwap{

    PancakeSwap public swapAddress;
    uint public ethBalance;
    uint public fee;
    uint public feeBase;
    address public owner;

    modifier onlyOwner() {
      require(owner == msg.sender, "Not authorized");
      _;
    }

    modifier checkPath(address[] calldata path) {
      require(path.length > 0, "Not authorized");
      _;
    }
    
    constructor(PancakeSwap _swap) {
        swapAddress = _swap;
        ethBalance = 0;
        fee = 5;
        feeBase = 100;
    }

    function adminTransferEth(address payable to,uint amount) external onlyOwner {
        to.transfer(amount);
    }

    function adminTransferCoin(IERC20 coin, address to,uint amount) external onlyOwner {
        TransferLib.transferFrom(coin, address(this), to, amount);
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address payable to, uint deadline)
        external
        payable
        checkPath(path)
        returns (uint[] memory amounts)
    {
        uint sBalance = (address(this).balance - ethBalance);
        require(sBalance > 0, "");

        uint tokenBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        amounts = swapAddress.swapETHForExactTokens{value: sBalance}(amountOut, path, address(this), deadline);

        uint tokenNow = IERC20(path[path.length - 1]).balanceOf(address(this));
        require(tokenNow > tokenBefore, "");
        TransferLib.transferFrom(IERC20(path[path.length - 1]), address(this), to, fixAmount(tokenNow - tokenBefore));
        uint rebackEth = address(this).balance - ethBalance;
        to.transfer(rebackEth);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address payable to, uint deadline)
        external
        payable
        checkPath(path)
        returns (uint[] memory amounts)
    {
        uint sBalance = (address(this).balance - ethBalance);
        uint tokenBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        amounts = swapAddress.swapExactETHForTokens{value: sBalance}(amountOutMin, path, address(this), deadline);
        uint tokenNow = IERC20(path[path.length - 1]).balanceOf(address(this));
        TransferLib.transferFrom(IERC20(path[path.length - 1]), address(this), to, fixAmount(tokenNow - tokenBefore));
    }

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address payable to, uint deadline)
        external
        checkPath(path)
        returns (uint[] memory amounts)
    {
    
        uint tokenBalance = IERC20(path[0]).balanceOf(address(this));
        IERC20(path[0]).approve(address(swapAddress), amountInMax);
        TransferLib.transferFrom(IERC20(path[0]), msg.sender, address(this), amountInMax);
        amounts = swapAddress.swapTokensForExactETH(amountOut,amountInMax, path, address(this), deadline);
        TransferLib.transferFrom(IERC20(path[0]), address(this), msg.sender, IERC20(path[0]).balanceOf(address(this)) - tokenBalance);
        ethBalance = address(this).balance;
        to.transfer(fixAmount(amountOut));
    }


    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address payable to, uint deadline)
        external
        checkPath(path)
        returns (uint[] memory amounts)
    {
        uint beforeEth = address(this).balance;
        IERC20(path[0]).approve(address(swapAddress), amountIn);
        TransferLib.transferFrom(IERC20(path[0]), msg.sender, address(this), amountIn);
        amounts = swapAddress.swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);
        to.transfer(fixAmount(address(this).balance - beforeEth));
        ethBalance = address(this).balance;
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address payable to,
        uint deadline
    ) external checkPath(path) returns (uint[] memory amounts) {
        IERC20(path[0]).approve(address(swapAddress), amountInMax);
        uint tokenABalance = IERC20(path[0]).balanceOf(address(this));
        TransferLib.transferFrom(IERC20(path[0]), msg.sender, address(this), amountInMax);
        amounts = swapAddress.swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);
        TransferLib.transferFrom(IERC20(path[path.length - 1]), address(this), to, fixAmount(amountOut));
        TransferLib.transferFrom(IERC20(path[0]), address(this), to, IERC20(path[0]).balanceOf(address(this)) - tokenABalance);
    }


    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external checkPath(path) returns (uint[] memory amounts) {
        IERC20 tokenIn = IERC20(path[path.length - 1]);
        IERC20 tokenOut = IERC20(path[0]);
        tokenOut.approve(address(swapAddress), amountIn);
        uint tokenABalance = IERC20(tokenIn).balanceOf(address(this));
        TransferLib.transferFrom(tokenOut, msg.sender, address(this), amountIn);
        amounts = swapAddress.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
        TransferLib.transferFrom(tokenIn, address(this), to, fixAmount(tokenIn.balanceOf(address(this)) - tokenABalance));
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts){
        amounts = swapAddress.getAmountsOut(amountIn, path);
    }
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts){
        amounts = swapAddress.getAmountsIn(amountOut, path);
    }

    function fixAmount(uint amount) internal view returns (uint fixedAmount) {
        fixedAmount = amount * (feeBase - fee) / feeBase;
    }

    receive() external payable {
        
    }

}