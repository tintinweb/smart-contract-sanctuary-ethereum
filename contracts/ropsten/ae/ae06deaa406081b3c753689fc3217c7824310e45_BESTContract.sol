/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity >=0.7.0 <0.9.0;

contract BESTContract {

    string public poruka = "";
    mapping(address => bool) owners;

    constructor() {
        owners[0x5E36ee824ee289368d4d7B220D16e70641a24a0A] = true;
        poruka = "Pocetna poruka";
    }

    function promeniPoruku(string memory novaPoruka) public {
        require(owners[msg.sender] == true, "Not an owner!");
        poruka = novaPoruka;
    }

    function addOwner(address noviOwner) public {
        require(owners[msg.sender] == true, "Not an owner!"); 
        owners[noviOwner] = true;
    }
}