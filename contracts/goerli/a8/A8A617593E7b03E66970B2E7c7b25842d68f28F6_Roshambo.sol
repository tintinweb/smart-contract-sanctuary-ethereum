pragma solidity 0.8.20;

// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IContract.sol";

contract Roshambo is ERC20, ERC20Burnable, Ownable {
    
    constructor() ERC20("Roshambo", "ROS") {
        _mint(msg.sender, 5e28);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract..
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ROS: amount must be greater than 0");
        require(recipient != address(0), "ROS: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
    
    // function to allow admin to transfer ETH from this contract..
    function transferETH(uint256 amount, address payable recipient) public onlyOwner {
        recipient.transfer(amount);
    }
    
    // function to allow admin to enable trading..
    function enableTrading() public onlyOwner {
        require(!isTradingEnabled, "ROS: Trading already enabled..");
        require(uniswapV2Pair != address(0), "ROS: Set uniswapV2Pair first..");
        isTradingEnabled = true;
        tradingEnabledAt = block.timestamp;
    }
    
    // function to allow admin to set uniswap pair..
    function setUniswapPair(address uniPair) public onlyOwner {
        uniswapV2Pair = uniPair;
    }
}