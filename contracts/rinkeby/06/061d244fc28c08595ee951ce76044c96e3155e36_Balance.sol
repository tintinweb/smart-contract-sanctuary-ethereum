/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity ^0.6.0;

//Ce contrat devra voir le montant en ETH d'un utilisateur
contract Balance{
    
    uint256 montant;

    function eBal(uint256 _montant) public returns(uint256) {
        address(0x718509d1d5319bca1Ce9b01667691e7FcDFb0Fb6).balance;
        montant = _montant;
        return montant;
    }
}