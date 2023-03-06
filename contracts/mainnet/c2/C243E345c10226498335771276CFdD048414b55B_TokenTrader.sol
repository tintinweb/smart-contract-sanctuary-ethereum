/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenTrader {
    address private constant tokenAddress = 0x13E7006cF58857efD24Ab1F5a90DF2df07DFec5b; // Enter token address here
    
    // Enter wallet addresses here
    address[] private wallets = [
        0x51615129C0ae326902490567886BfD3666707633, 
        0x29101e9b08f83015aF67D5aCD1cc6E4F98265BFA,
        0xeAE429456BF701974137cB6a16a18454a44Ba430,
        0x37Fbd3673f5cdd56c9Da747D11593895EA4b121f,
        0x993Ed5F86e66443e50fBe545c8e304b1b1c98e53,
        0x46049c19e3246deEC989cD40aF455d850EF8EA84,
        0x33724362429883E14b6b0e829Bc31b0d5a7ca205,
        0xBa1C860E8476DAC312739229921205DaD555BD0F,
        0xd09b2CBf2D71594c8071502c8f5f02eC9706dEf4,
        0x03E7274498699B88042621aFceC146902aB2Ea47
    ];

    uint private constant maxBuyPercent = 70;
    uint private constant sellPercent = 5;
    uint private constant sellInterval = 10 minutes;
    uint private buyAmount = 0;
    uint private sellAmount = 0;
    uint private nextSellTime = 0;
    uint private nextBuyTime = 0;
    uint private currentWalletIndex = 0;

    function buy() external {
        require(nextBuyTime <= block.timestamp, "Buy interval not elapsed");
        
        IERC20 token = IERC20(tokenAddress);
        uint balance = token.balanceOf(address(this));
        uint maxBuy = (balance * maxBuyPercent) / 100;

        if (buyAmount < maxBuy) {
            uint amount = maxBuy - buyAmount;
            require(token.transferFrom(wallets[currentWalletIndex], address(this), amount), "Token transfer failed");
            buyAmount += amount;
        }
        
        currentWalletIndex = (currentWalletIndex + 1) % wallets.length;
        nextBuyTime = block.timestamp + sellInterval;
    }

    function sell() external {
        require(nextSellTime <= block.timestamp, "Sell interval not elapsed");
        
        IERC20 token = IERC20(tokenAddress);
        uint balance = token.balanceOf(address(this));
        
        require(balance > 0, "No tokens to sell");
        
        uint sellTotal = (balance * sellPercent) / 100;
        uint amount = sellTotal / wallets.length;
        
        for (uint i = 0; i < wallets.length; i++) {
            require(token.transfer(wallets[i], amount), "Token transfer failed");
        }
        
        sellAmount += sellTotal;
        nextSellTime = block.timestamp + sellInterval;
    }
}