/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract MonContrat {

address proprio;
string montexte;

constructor () {
    proprio = msg.sender ;
    montexte='';
}

    function MetTexte (string memory nouveautexte) public {
        require(proprio == msg.sender) ;
        montexte = nouveautexte ;
    }

    function DonneTexte () public view returns (string memory) {
        return montexte;
    }
    
    function ChangeProprio (address nouveauproprio) public {
        require(proprio == msg.sender) ;
        proprio = nouveauproprio ;

    }

    
}