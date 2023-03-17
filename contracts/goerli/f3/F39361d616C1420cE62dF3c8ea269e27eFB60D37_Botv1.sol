/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);  
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Botv1 is Ownable {

    IUniswapV2Router02 private constant router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private immutable WETH;

    uint256 private _tip;                  // tip amount to give validator

    constructor() {
        
        WETH = router.WETH();
        IERC20(router.WETH()).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, type(uint256).max);
    }

    function setParam(uint256 tip) external onlyOwner {
        _tip = tip;
    }

    function getParam() external view returns(uint256){
        return(_tip);
    }

    function swap() external {
        IWETH(WETH).withdraw(_tip);
        block.coinbase.transfer(_tip);
    }

    function deposit() external onlyOwner {
        IWETH(WETH).deposit{value: address(this).balance}();
    }
    
    function withdraw() external onlyOwner {
        _withdraw(IERC20(WETH).balanceOf(address(this)));
    }

    function _withdraw(uint256 amount) internal{
        IWETH(WETH).withdraw(amount);
        payable(owner()).transfer(amount);
    }

    receive() external payable{}
}