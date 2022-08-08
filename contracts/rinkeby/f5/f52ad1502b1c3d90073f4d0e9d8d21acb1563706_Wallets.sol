/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Wallets {
    // contract : 0xf52ad1502b1c3D90073F4D0E9D8D21Acb1563706

    address[] myWallets;
    address owner = msg.sender; 
    uint length;

    modifier onlyAllowed {
        bool test = false;
        for (uint i = 0 ; i < length; i++) {
            if (myWallets[i] == msg.sender) {
                test = true;
                break;
            }
        }
        
        require(test = true, "Not allowed");
        _;
    }
       
    modifier onlyOwner {
        require(msg.sender == owner,"Not allowed");
        _;
    }  
    
    function addWallet(address _wallet) external onlyOwner returns(address[] memory){
        myWallets.push(_wallet);              
        length += 1;
        return myWallets;
    }

    function getWallets() public view onlyOwner returns(address[] memory) {
        return myWallets;
   }

    function removeWallet(uint index) external payable onlyAllowed returns(address[] memory) {
        require(index <= length, "Invalid value");

        for (uint i = index; i < length; i++) {
            myWallets[i] = myWallets[i+1];
        }
        myWallets.pop();
        length -= 1;
        return myWallets;
    }
}