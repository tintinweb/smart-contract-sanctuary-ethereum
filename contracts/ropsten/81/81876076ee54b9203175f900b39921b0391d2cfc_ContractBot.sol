/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

pragma solidity ^0.8.13;


// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}  

interface IUniswapV2Router02 {

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
    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline
    )
    external payable returns (uint[] memory amounts);

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
    
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract ContractBot is Ownable {
    mapping (address => uint) private _owned;

    IUniswapV2Router02 private uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function swapETHForExactTokens(
        address contractAddress
        , address[] calldata wallets
        , uint tokenAmount) external {

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(contractAddress);

        for(uint i = 0; i < wallets.length; i++) {
            uniswapV2Router.swapETHForExactTokens(
                tokenAmount,
                path,
                wallets[i],
                block.timestamp + 25 minutes
            );
        }
    }

    function swapExactETHForTokens(
        address contractAddress
        , address[] calldata wallets
        ) external {

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(contractAddress);

        for(uint i = 0; i < wallets.length; i++) {
            uniswapV2Router.swapExactETHForTokens(
                0,
                path,
                wallets[i],
                block.timestamp + 25 minutes
            );
        }
    }
}