// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
                    ███████╗██████╗  ██████╗██████╗  ██████╗                         
                    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔═████╗                        
                    █████╗  ██████╔╝██║      █████╔╝██║██╔██║                        
                    ██╔══╝  ██╔══██╗██║     ██╔═══╝ ████╔╝██║                        
                    ███████╗██║  ██║╚██████╗███████╗╚██████╔╝                        
                    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝                         
                                                                                     
████████╗ █████╗ ██╗  ██╗     ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗███████╗██████╗ 
╚══██╔══╝██╔══██╗╚██╗██╔╝    ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔════╝██╔══██╗
   ██║   ███████║ ╚███╔╝     ██║     ███████║█████╗  ██║     █████╔╝ █████╗  ██████╔╝
   ██║   ██╔══██║ ██╔██╗     ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██╔══╝  ██╔══██╗
   ██║   ██║  ██║██╔╝ ██╗    ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗███████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                                                                     
                                                        ██╗   ██╗██████╗     ██████╗ 
                                                        ██║   ██║╚════██╗   ██╔═████╗
                                                        ██║   ██║ █████╔╝   ██║██╔██║
                                                        ╚██╗ ██╔╝██╔═══╝    ████╔╝██║
                                                         ╚████╔╝ ███████╗██╗╚██████╔╝
                                                          ╚═══╝  ╚══════╝╚═╝ ╚═════╝ 
                                                                                     
*/

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function decimals() external view returns (uint256);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint256, uint256);
    function token0() external view returns (address);
}

interface IUniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
}

contract TaxChecker {
    address public owner;

    IUniswapV2Factory Factory;
    IUniswapV2Router Router;
    address public WETH;

    event eth_in(address from, uint256 amount);

    constructor() {
        owner = msg.sender;
        Factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = Router.WETH();
    }

    function getPair(address tokenAddr) public view returns (address) {
        return Factory.getPair(tokenAddr, WETH);
    }
    
    // Returns the price with 9 decimals
    function getReserves(address tokenAddr) public view returns (uint256, uint256) {
        IUniswapV2Pair Pair = IUniswapV2Pair(getPair(tokenAddr));
        address token0 = Pair.token0();
        (uint256 res0, uint256 res1) = Pair.getReserves();
        uint256 res_token;
        uint256 res_weth;
        if (token0==tokenAddr) {
            // token, weth
            res_token = res0;
            res_weth  = res1;
        } else {
            // eth, token
            res_token = res1;
            res_weth  = res0;
        }
        return (res_token, res_weth);
    }

    function getBalance(address tokenAddr) public view returns (uint256) {
        ERC20 token = ERC20(tokenAddr);
        return token.balanceOf(address(this));
    }

    function getDecimals(address tokenAddr) public view returns (uint256) {
        ERC20 token = ERC20(tokenAddr);
        return token.decimals();
    }

    function buy(address tokenAddr) public payable returns (uint[] memory amounts) {
        address[] memory p = new address[](2);
        p[0] = WETH;
        p[1] = tokenAddr;
        return Router.swapExactETHForTokens{value: msg.value}(0, p, address(this), block.timestamp+60);
    }

    function sell(uint256 balance, address tokenAddr) public payable returns (bool) {
        ERC20 token = ERC20(tokenAddr);
        if (balance==0) {
            // Sell everything
            balance = getBalance(tokenAddr);
        }
        token.approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, balance);
        address[] memory p = new address[](2);
        p[0] = tokenAddr;
        p[1] = WETH;
        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, p, address(this), block.timestamp+60);
        return true;
    }

    function getExpectedTokens(address tokenAddr, uint256 value) public view returns (uint256) {
        (uint256 res_token, uint256 res_weth) = getReserves(tokenAddr);
        return Router.getAmountOut(value, res_weth, res_token);
    }

    function getExpectedEth(address tokenAddr, uint256 value) public view returns (uint256) {
        (uint256 res_token, uint256 res_weth) = getReserves(tokenAddr);
        return Router.getAmountOut(value, res_token, res_weth);
    }

    function cashout() public {
        payable(owner).transfer(address(this).balance);
    }
    
    function swap(address[] memory path) public payable returns (uint256) {
        address tokenAddress = path[0];
        // Buy the tokens
        address[] memory buyPath = new address[](2);
        buyPath[0] = WETH;
        buyPath[1] = tokenAddress;
        Router.swapExactETHForTokens{value: msg.value}(0, buyPath, address(this), block.timestamp);
        uint256 token_balance = getBalance(tokenAddress);
        // Sell the tokens
        ERC20(tokenAddress).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, token_balance);
        Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(token_balance, 0, path, address(this), block.timestamp);
        uint256 WETH_balance = getBalance(WETH);
        if (WETH_balance > 0) {
            ERC20(WETH).transfer(owner, WETH_balance);
        }
        return WETH_balance;
    }

    function getTokenTax(address tokenAddr) public payable returns(uint256[4] memory, int256[2] memory) {
        uint256 expected_tokens = getExpectedTokens(tokenAddr, msg.value);
        buy(tokenAddr);
        uint256 tok_balance_buy = getBalance(tokenAddr);
        int256 buy_tax = (10**11) - ((int256(tok_balance_buy)*(10**11))/int256(expected_tokens));

        uint256 expected_eth = getExpectedEth(tokenAddr, tok_balance_buy);
        sell(0, tokenAddr);
        uint256 eth_balance = address(this).balance;
        int256 sell_tax = (10**11) - ((int256(eth_balance)*(10**11))/int256(expected_eth));
        payable(owner).transfer(eth_balance);
        return ([tok_balance_buy, expected_tokens, eth_balance, expected_eth], [buy_tax, sell_tax]);
    }
    
    receive() external payable {
        emit eth_in(msg.sender, msg.value);
    }
    
    fallback() external payable {
        emit eth_in(msg.sender, msg.value);
    }
}