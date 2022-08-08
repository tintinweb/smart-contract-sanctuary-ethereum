/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Wallets {
    // contract : 0x16d03b8db78bb0dd0bb59b7d8ebf16be4fe30834
    address private owner;
    constructor(){
        owner = msg.sender;
    }
        
    address[] private myWallets;   
    uint private length;

    modifier onlyAllowed {
        bool test = false;
        for (uint i = 0 ; i < length -1; i++) {
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
    
    function addWallet(address _wallet) external onlyOwner {
        myWallets.push(_wallet);              
        length += 1;
    }

    function getWallets() public view onlyOwner returns(address[] memory) {
        return myWallets;
   }

    function removeWallet(uint _index) external payable onlyAllowed {
        require(_index <= length -1, "Invalid value");

        for (uint i = _index; i < length -1; i++) {
            myWallets[i] = myWallets[i+1];
        }
        myWallets.pop();
        length -= 1;
    }
}