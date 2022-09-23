// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";

contract Ryuk is ERC20,Ownable {

    using SafeMath for uint256;
    uint public _totalSupply=1000000000000000000000000;

    constructor() ERC20(unicode"Ryuk",unicode"リューク",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setAntiBot(bool value) public onlyOwner{
        antiBotSystemEnabled=value;
    }

    fallback() external payable { }
    receive() external payable { }
}