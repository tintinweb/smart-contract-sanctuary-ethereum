/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

pragma solidity ^0.4.25;

contract EqrInserimentoDati {


struct Notarizzazione {
    string NotarizzazioneEqrlablock_;
}
    
address Eqrlablock;

constructor() public {
  Eqrlablock = msg.sender;
} 


    
modifier EqrLab() {
     if (msg.sender == Eqrlablock) {
        _;
    }
}
    
Notarizzazione[] public leggiEqrlablock;

function InserireDati(string NotarizzazioneEqrlablock_) public EqrLab {

         leggiEqrlablock.push(Notarizzazione(NotarizzazioneEqrlablock_));
    
    }
}