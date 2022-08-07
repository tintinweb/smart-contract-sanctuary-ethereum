/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

pragma solidity ^0.8.0;

interface IERC20{
    function transferFrom(address from, address to, uint256 amount) external;
}

contract CrossChainBurner{
    IERC20 public immutable fromToken;
    IERC20 public immutable toToken;
    uint256 public immutable toChainId;
    
    event CrossChainBurn(address indexed from, address indexed to, uint256 amount);
    
    constructor(IERC20 _fromToken, IERC20 _toToken, uint256 _toChainId){
        fromToken = _fromToken;
        toToken = _toToken;
        toChainId = _toChainId;
    }
    
    function crossChainBurn(address to, uint256 amount) external {
        require(to != address(0) && amount > 0, "Burn:invalid args");
        fromToken.transferFrom(msg.sender, address(this), amount);
        emit CrossChainBurn(msg.sender, to, amount);
    }
}