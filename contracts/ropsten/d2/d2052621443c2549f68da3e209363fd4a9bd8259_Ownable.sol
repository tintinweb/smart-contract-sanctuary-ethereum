/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Ownable{
    address public owner; 

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "l'utente non e' il proprietario");
        _;
    }

    function setOwner(address _nuovoOwner) external onlyOwner{
        require(_nuovoOwner != address(0), "indirizzo non valido");
        owner = _nuovoOwner;
    }

    function onlyOwnerCanCall() external onlyOwner{
        // questa funzione sarà invocabile solo dal proprietario
    }

    function everyoneCanCall() external{
        // funzione invocabile da chiunque
    }
}