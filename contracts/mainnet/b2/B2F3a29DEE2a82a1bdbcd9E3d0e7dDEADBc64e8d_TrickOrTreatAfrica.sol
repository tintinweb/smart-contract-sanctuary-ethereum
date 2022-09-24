// SPDX-License-Identifier: MIT
/*
    TG: https://t.me/trickortreateth

*/
pragma solidity 0.8.17;

import "./ERC20.sol";

contract TrickOrTreatAfrica is ERC20,Ownable {

    using SafeMath for uint256;
    uint public _totalSupply=100000000000000000000000000;
    constructor() ERC20(unicode"Trick Or Treat Africa",unicode"TOTA",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}