/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

pragma solidity >=0.8.0;

contract MaBanque{

    uint256 fondsTotaux = 0;

    function recupFondTotaux() public view returns(uint){
        return fondsTotaux;
    }

    mapping(address => uint) fonds;

    function ajoutFonds() public payable {
        fonds[msg.sender]= fonds[msg.sender] + msg.value;
        fondsTotaux = fondsTotaux + msg.value;
    }

    function recupUserBalance(address userAddress) public view returns(uint){
        uint valeur = fonds[userAddress];
        return valeur;
    }

    function retireFonds() public payable {
        address payable retireVers = payable(msg.sender);
        uint montant = recupUserBalance(msg.sender);
        retireVers.transfer(montant);
        fondsTotaux = fondsTotaux - montant;
        fonds[msg.sender] = 0;
    }
}