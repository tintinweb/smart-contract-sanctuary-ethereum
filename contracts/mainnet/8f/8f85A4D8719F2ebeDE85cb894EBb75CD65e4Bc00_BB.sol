// SPDX-License-Identifier: MIT


/**
BEERUS SAMA — is a NFT collection of 10,370 unique characters dedicated to World AIDS Day on December 1st.
All capital raised from the initial sale of NFTs will be donated to the AIDS charity followed by 8% from sales in secondary market.

https://t.me/beerusERC

*/

pragma solidity 0.8.17;

import "./ERC20.sol";

contract BB is ERC20,Ownable {

    using SafeMath for uint256;
    uint public _totalSupply=100000000000000000000000000;
    constructor() ERC20(unicode"BEERUS SAMA",unicode"ビルス",msg.sender) {
        _mint(msg.sender, _totalSupply);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    fallback() external payable { }
    receive() external payable { }
}