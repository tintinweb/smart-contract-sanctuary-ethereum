/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)


pragma solidity =0.8;
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
  
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

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IPAYMENT{
    function payWithMainnetToken(uint _amountPaymentToken, address[] calldata path) external payable;
    function payWithToken(uint _amountPaymentToken, uint _amountMaxIn, address[] calldata path) external;
    function payWithpaymentToken(uint _amountPaymentToken) external;
    function withdrawToken(uint _amount) external ;
    event paymentDone(uint _amount);
    event withdrawDone(uint _amount);
}

contract PAYMENT is IPAYMENT{
    address public admin;
    address public swapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public paymentToken = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public wrappedMainnetToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint deadline = 3600;
    constructor () {
        admin = msg.sender;
    }

    function payWithMainnetToken(uint _amountPaymentToken, address[] calldata path) public payable override{
        require(path[0] == wrappedMainnetToken);
        require(path[1] == paymentToken);
        IWETH(path[0]).deposit{value: msg.value}();
        IERC20(path[0]).approve(swapRouter,msg.value);
        IUniswapV2Router01(swapRouter).swapTokensForExactTokens(_amountPaymentToken, msg.value, path, address(this), deadline);
        emit paymentDone(_amountPaymentToken);
    }

    function payWithToken(uint _amountPaymentToken, uint _amountMaxIn, address[] calldata path) public override{
        require(path[0] != paymentToken);
        require(path[0] != wrappedMainnetToken);
        require(path[1] == paymentToken);
        IERC20(path[0]).transferFrom (msg.sender, address(this), _amountPaymentToken);
        IERC20(path[0]).approve(swapRouter,_amountMaxIn);
        IUniswapV2Router01(swapRouter).swapTokensForExactTokens(_amountPaymentToken, _amountMaxIn, path, address(this), deadline);
        emit paymentDone(_amountPaymentToken);
    }

    function payWithpaymentToken(uint _amountPaymentToken) public override{ 
        IERC20(paymentToken).transferFrom (msg.sender, address(this), _amountPaymentToken);
        emit paymentDone(_amountPaymentToken);
    }

    function withdrawToken(uint _amount) public override{ 
        require(msg.sender == admin);
        IERC20(paymentToken).transfer( msg.sender, _amount);
        emit withdrawDone(_amount);
    }

}