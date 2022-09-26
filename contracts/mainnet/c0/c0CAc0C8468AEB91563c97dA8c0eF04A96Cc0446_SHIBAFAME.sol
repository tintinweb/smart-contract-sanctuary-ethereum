// SPDX-License-Identifier: MIT

/*

Telegram: https://t.me/SHIBAFAMETOKEN_E

*/
pragma solidity 0.8.17;

import "./ERC20.sol";

contract SHIBAFAME is ERC20,Ownable {
    using SafeMath for uint256;
    uint8 dec = 9;
    uint public _totalSupply=5000000*(10**dec);
    constructor() ERC20(unicode"SHIBAFAME",unicode"SAFE",dec,false) {
        _mint(msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}