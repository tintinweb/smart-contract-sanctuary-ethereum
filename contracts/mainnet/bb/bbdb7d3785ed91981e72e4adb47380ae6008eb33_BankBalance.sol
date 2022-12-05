/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;


contract BankBalance {

    address public BankAuthorizerContractAddress;
    address public OwnerB;

    constructor() payable {
        OwnerB = payable(msg.sender);
    }

    receive() external payable {

    }

    // Sends all funds to the tx.origin. tx.origin will be the initial caller from the BankAuthorizer contract so will only be authorized users. 
    function withdrawAllFunds() external {
        require(msg.sender == BankAuthorizerContractAddress || msg.sender == OwnerB);

        payable(tx.origin).transfer(address(this).balance);
    } 

    function SetBankAuthorizer(address addr) external {
        require(msg.sender == BankAuthorizerContractAddress || msg.sender == OwnerB);
        BankAuthorizerContractAddress = addr;
    }

}