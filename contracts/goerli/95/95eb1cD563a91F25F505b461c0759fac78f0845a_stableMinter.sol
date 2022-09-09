/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

interface IERC20Mint {
    function mint(address account, uint256 amount) external;
}

enum Coin {
    USDT,
    USDC
}

contract stableMinter {
    address public constant USDT = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49;
    address public constant USDC = 0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43;

    function mintStables(Coin coin, uint256 amount) public {
        if (coin == Coin.USDT) {
            IERC20Mint(USDT).mint(msg.sender, amount * 1e6);
        }
        if (coin == Coin.USDC) {
            IERC20Mint(USDC).mint(msg.sender, amount * 1e6);
        }
    }

    function mint100kUSDT() external {
        mintStables(Coin.USDT, 100000);
    }

    function mint100kUSDC() external {
        mintStables(Coin.USDC, 100000);
    }
}