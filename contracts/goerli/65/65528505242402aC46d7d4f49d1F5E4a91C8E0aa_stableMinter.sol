/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.10;

enum Coin {
    USDT,
    USDC,
    EURS
}

contract stableMinter {
    address public constant USDT = 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49;
    address public constant USDC = 0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43;
    address public constant EURS = 0xc31E63CB07209DFD2c7Edb3FB385331be2a17209;

    function mintStables(Coin coin, uint256 amount) public {
        if (coin == Coin.USDT) {
            USDT.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
        }
        if (coin == Coin.USDC) {
            USDC.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
        }
        if (coin == Coin.EURS) {
            EURS.call(abi.encodeWithSignature("mint(address,uint256)", msg.sender, amount));
        }
    }

    function mintUSDT() external {
        mintStables(Coin.USDT, 10000);
    }

    function mintUSDC() external {
        mintStables(Coin.USDC, 10000);
    }

    function mintEURS() external {
        mintStables(Coin.EURS, 10000);
    }
}