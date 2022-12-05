/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

// Bank Auth contract
// All DAPP deposits and withdrawals should go via this contract
// Holds a minimum amount of liquid ether in the bank balance contract
// DAPP will maintain the bank balance by depositing or withdrawing funds as necessary. 


contract BankAuthorizer{

    address public ContractOwner;
    uint256 public BankBalanceLimit = 2 ether;
    address public BankBalanceContract = 0xBBDb7D3785ED91981e72E4ADB47380ae6008eb33;

    constructor() {
        ContractOwner = tx.origin;
    }

    // DAPP deposits user funds into the bank balance contract.
    function DepositUserFunds() external payable {
        //require(tx.origin == ContractOwner);
        payable(BankBalanceContract).transfer(address(this).balance);
    }

    // Check if the banks balance is too high. If it is then we withdraw it all to store it in the dapps wallet who is the message sender. 
    function WithdrawExcessFunds() external payable {
        //require(tx.origin == ContractOwner);
        
        if(BankBalanceContract.balance > BankBalanceLimit) {
            _withdrawAllFunds(tx.origin);
        }
    }

    function _withdrawAllFunds(address addressToPay) private {
        BankBalanceContract.delegatecall(abi.encodeWithSignature("withdrawAllFunds(address)", addressToPay));
    }

    function SetBankBalanceContract(address contractAddress) external {
        require(tx.origin == ContractOwner);
        BankBalanceContract = contractAddress;
    }

    function SetBankBalanceLimit(uint256 weiLimit) external {
        require(tx.origin == ContractOwner);
        BankBalanceLimit = weiLimit;
    }


}