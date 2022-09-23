// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20.sol";

contract ASCAM is ERC20,Ownable {

    using SafeMath for uint256;
    uint8 _decimals=18;
    uint public _totalSupply=1000000000000000000000000;

    constructor() ERC20(unicode"AntiScam",unicode"ASCAM",msg.sender) {
    _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setAntiBot(bool value) public onlyOwner{
        antiBotSystemEnabled=value;
    }

    fallback() external payable { }
    receive() external payable { }
}