// SPDX-License-Identifier: MIT


pragma solidity 0.8.17;

import "./ERC20.sol";

contract MST is ERC20,Ownable {
    using SafeMath for uint256;
    uint public _totalSupply=10000000000000000000000000;
    constructor() ERC20(unicode"Missed Tsuka",unicode"MST",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}