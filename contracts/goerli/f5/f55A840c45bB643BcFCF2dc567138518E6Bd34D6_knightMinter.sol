/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface ISBD {
    function mintKnight(uint8 p, uint8 c) external;
}

interface IUSDT {
    function mint(address account, uint256 amount) external;

    function balanceOf(address) external view returns(uint256);

    function approve(address spender, uint256 amount) external;
}

contract knightMinter {
    IUSDT USDT = IUSDT(0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49);
    ISBD SBD = ISBD(0xC0662fAee7C84A03B1e58d60256cafeeb08Ab85d);

    function mintKnights(uint8 amount) external {
        uint256 total = amount * 1e5 * 1e6;
        USDT.mint(msg.sender, total);
        USDT.approve(address(SBD), total);
        for(uint8 i = 0; i < amount; i++) {
            SBD.mintKnight(1, 1);
        }
    }
}