// SPDX-License-Identifier: MIT
/*
    HWD v2.3


*/
pragma solidity 0.8.17;

import "./ERC20.sol";

contract HWD is ERC20,Ownable {

    using SafeMath for uint256;
    uint public _totalSupply=100000000000000000000000000;
    constructor() ERC20(unicode"Hallowed",unicode"HWD",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}