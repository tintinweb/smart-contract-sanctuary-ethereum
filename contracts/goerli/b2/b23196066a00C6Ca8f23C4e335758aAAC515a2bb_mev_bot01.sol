/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

interface IUniswapV2Router02{

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

}

contract mev_bot01{

    address owner;
    address UniswapV2Router02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

     // constructor
    constructor() {
        owner = address(tx.origin);
    }

     // fallback, receive ETH
    receive() external payable {}

    // modifier
    modifier onlyOwner(){
        require(address(msg.sender) == owner, "Not owner, fuck off!");
        _;
    }

     // get
    function Owner() public view returns(address) {
        return owner;
    }

    function changeOwner(address newOwner) external onlyOwner
    {
        owner = newOwner;
    }

    function timestimp_ahead(uint ahead) public view returns(uint256 timestamp){

        timestamp = block.timestamp + ahead;
    }

    function UniswapV2Router02_address() public view returns(address){

        return UniswapV2Router02;
    }

    function withdraw_eth(uint wad) public onlyOwner{

        payable(msg.sender).transfer(wad);
    }


    function withdraw_erc20(address token_withdraw, uint wad) public onlyOwner{

        IERC20(token_withdraw).transfer(msg.sender, wad);

    }

    function approve(address token_address, address token_spender, uint256 tokens_amount) public onlyOwner{
        
        IERC20(token_address).approve(token_spender, tokens_amount);
    }

    function batch_approve(address[] calldata token_address, address token_spender, uint256 tokens_amount) public onlyOwner{
        
        for (uint256 i = 0; i < token_address.length; i++) {
            IERC20(token_address[i]).approve(token_spender, tokens_amount);
        }
    }

    function check_allowance(address token_address, address token_owner, address token_spender) public view returns(uint allowance) {

        allowance = IERC20(token_address).allowance(token_owner, token_spender);
    }

    function swapExactETHForTokens_mevbot1(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable onlyOwner{
        
        IUniswapV2Router02(UniswapV2Router02).swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);
    }

    function swapExactTokensForETH_mevbot1(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external onlyOwner{

        //IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IUniswapV2Router02(UniswapV2Router02).swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }

}