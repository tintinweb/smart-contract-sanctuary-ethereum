/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity  0.8.7;

contract simpleWallets {

    struct wallet {

        uint balance;

        uint lastDepot;
        uint nbrDepot;

        uint lastWithdraw;
        uint nbrWithdraw;
    }

    mapping   ( address => wallet ) public  wallets;

    //on recoit sur le smart contract
    receive() external payable {
        wallets[msg.sender].balance += msg.value;
        wallets[msg.sender].lastDepot = msg.value;
        wallets[msg.sender].nbrDepot +=1;
    } 


    // combien le smart contract à en tout
    function getContractBalance() public view returns (uint){
        return address(this).balance;
    }

    //on envoi smart contract vers exterieur
    function transfert ( address payable  _to, uint _money ) public {

        if ( wallets[msg.sender].balance   - _money  >= 0 ){

            _to.transfer(_money);

            wallets[msg.sender].balance -= _money;

            wallets[msg.sender].lastWithdraw = _money;

            wallets[msg.sender].nbrWithdraw += 1; 
        }
    }


}