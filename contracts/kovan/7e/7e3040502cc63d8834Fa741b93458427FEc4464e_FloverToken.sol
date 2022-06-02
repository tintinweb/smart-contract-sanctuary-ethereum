/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity ^0.5.7;

contract FloverToken {
    /* this creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    /* initializes contract with initial supply tokens to the creator of the contract */
    constructor( uint256 initialSupply ) public {
        balanceOf[msg.sender] = initialSupply;
    }

    // Send coins
    function transfer(address _to, uint256 _value) public returns (bool succes) {
        require(balanceOf[msg.sender] >= _value);               //Vérification si l'envoiyeur a la somme
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;                        //Retrait de la somme dans le wallet de l'envoyeur
        balanceOf[_to] += _value;                               //Ajout de la somme dans le wallet du receveur
        return true;
    }
}