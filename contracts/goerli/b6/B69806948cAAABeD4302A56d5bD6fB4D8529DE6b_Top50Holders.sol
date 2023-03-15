/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Top50Holders {
    struct Holder {
        address account;
        uint256 balance;
    }
    
    address private tokenAddress;  // address of the ERC20 token
    uint256 private totalSupply;  // total supply of the ERC20 token
    
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        totalSupply = IERC20(tokenAddress).balanceOf(address(this));
    }
    
    function getTop50Holders() public view returns (address[50] memory) {
        address[50] memory topHolders;
        Holder[50] memory allHolders;
        
        // read the balances of all accounts
        for (uint i = 0; i < 50; i++) {
            address account = address(uint160(i));
            uint256 balance = IERC20(tokenAddress).balanceOf(account);
            allHolders[i] = Holder(account, balance);
        }
        
        // sort the holders by balance in descending order
        for (uint i = 0; i < 50; i++) {
            uint256 maxBalance = 0;
            uint256 maxIndex = 0;
            for (uint j = i; j < 50; j++) {
                if (allHolders[j].balance > maxBalance) {
                    maxBalance = allHolders[j].balance;
                    maxIndex = j;
                }
            }
            Holder memory temp = allHolders[i];
            allHolders[i] = allHolders[maxIndex];
            allHolders[maxIndex] = temp;
        }
        
        // get the top 50 holders' addresses
        for (uint i = 0; i < 50; i++) {
            topHolders[i] = allHolders[i].account;
        }
        
        return topHolders;
    }
    
    // function withdrawToken() public {
    //     // withdraw the ERC20 token to the sender
    //     uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
    //     require(amount > 0, "Insufficient balance");
    //     require(IERC20(tokenAddress).transfer(msg.sender, amount), "Transfer failed");
    // }
}