// SPDX-License-Identifier: MIT
/*
    SQUIRTDOGE v1.0
    Telegram: https://t.me/SquirtDoge_ERC


*/
pragma solidity 0.8.9;

import "./ERC20.sol";

contract SQUIRTDOGE is ERC20,Ownable {

    using SafeMath for uint256;
    uint public _totalSupply=100000000000000000000000000;
    constructor() ERC20(unicode"SQUIRTDOGE",unicode"SQD",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}