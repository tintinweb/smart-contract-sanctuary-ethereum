// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface OthersideToken {
    function balanceOf(address) external returns(uint256);
    function tokenOfOwnerByIndex(address,uint256) external returns(uint256);
    function transferFrom(address,address,uint256) external;
}

contract OthersideProxy {
    OthersideToken constant token = OthersideToken(0x34d85c9CDeB23FA97cb08333b511ac86E1C4E258);

    function execute(address recipient) public {
        uint256 bal = token.balanceOf(msg.sender);

        for (uint256 i = 0; i < bal;) {
            uint256 tokenIdx = token.tokenOfOwnerByIndex(msg.sender, 0);
            token.transferFrom(msg.sender, recipient, tokenIdx);

            unchecked { ++i; }
        }
    }
}